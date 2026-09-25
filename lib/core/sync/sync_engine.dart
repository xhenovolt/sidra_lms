import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/local_database.dart';
import '../errors/app_failure.dart';
import '../logging/app_logger.dart';
import '../network/postgres_api.dart';

/// A queued write waiting to reach the server.
class OutboxOp {
  const OutboxOp({
    required this.opId,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
    this.state = 'pending',
  });

  factory OutboxOp.fromRow(Map<String, Object?> r) => OutboxOp(
    opId: r['op_id']! as String,
    type: r['op_type']! as String,
    payload: LocalDatabase.decodeMap(r['payload']),
    createdAt: DateTime.parse(r['created_at']! as String),
    attempts: r['attempts']! as int,
    lastError: r['last_error'] as String?,
    state: r['state']! as String,
  );

  final String opId;

  /// Name of the SQL function to call (e.g. `record_progress`).
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
  final String state;

  bool get isRejected => state == 'rejected';
}

/// Applies a successful server result to local state.
typedef ResultApplier = Future<void> Function(
  DatabaseExecutor db,
  Map<String, dynamic> payload,
  Object? result,
);

class SyncReport {
  const SyncReport({
    this.sent = 0,
    this.rejected = 0,
    this.remaining = 0,
    this.stoppedBy,
  });
  final int sent;
  final int rejected;
  final int remaining;

  /// Why the run stopped early (offline, signed out…), if it did.
  final AppFailure? stoppedBy;
}

class SyncStatus {
  const SyncStatus({
    this.pending = 0,
    this.rejected = 0,
    this.running = false,
    this.lastError,
  });
  final int pending;
  final int rejected;
  final bool running;
  final AppFailure? lastError;

  bool get isClean => pending == 0 && rejected == 0;
}

/// Replays the outbox against PostgreSQL.
///
/// Guarantees:
///  * ops are sent oldest-first, one at a time
///  * every op carries a unique id the server de-duplicates on, so a request
///    that succeeded but whose response was lost is safe to resend
///  * offline / timeout / 5xx → op kept, exponential backoff, run stops
///  * expired session → op kept untouched, run stops until re-auth
///  * server refusal (403/404/409/4xx) → op marked `rejected` and KEPT, so
///    learner work is never silently discarded; the UI surfaces it
///  * only one run at a time; triggers during a run are coalesced
class SyncEngine {
  SyncEngine({
    required this.local,
    required this.api,
    required this.appliers,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LocalDatabase local;
  final PostgresApi api;
  /// Per op type: how to apply a successful server result locally.
  final Map<String, ResultApplier> appliers;
  final DateTime Function() _clock;
  static const _log = AppLogger('sync');
  static const _uuid = Uuid();

  final status = ValueNotifier(const SyncStatus());
  Future<SyncReport>? _running;
  bool _rerun = false;

  static String newOpId() => _uuid.v4();

  /// Adds an op inside [txn] (same transaction as the local change it
  /// represents, so the two can never diverge).
  static Future<void> enqueue(
    DatabaseExecutor txn, {
    required String opId,
    required String type,
    required Map<String, dynamic> payload,
  }) => txn.insert('outbox', {
    'op_id': opId,
    'op_type': type,
    'payload': LocalDatabase.encode(payload),
    'created_at': LocalDatabase.now(),
  });

  Future<List<OutboxOp>> ops({bool includeRejected = true}) async {
    final rows = await local.db.query(
      'outbox',
      where: includeRejected ? null : "state = 'pending'",
      orderBy: 'created_at, rowid',
    );
    return rows.map(OutboxOp.fromRow).toList();
  }

  Future<void> refreshStatus({AppFailure? error}) async {
    final rows = await local.db.rawQuery(
      'select state, count(*) c from outbox group by state',
    );
    final counts = {for (final r in rows) r['state']: r['c']! as int};
    status.value = SyncStatus(
      pending: counts['pending'] ?? 0,
      rejected: counts['rejected'] ?? 0,
      running: _running != null,
      lastError: error,
    );
  }

  /// Runs the outbox. Concurrent calls share one run; a call made during a
  /// run schedules exactly one follow-up run.
  Future<SyncReport> run() {
    if (_running != null) {
      _rerun = true;
      return _running!;
    }
    final future = _runOnce().whenComplete(() {
      _running = null;
      if (_rerun) {
        _rerun = false;
        unawaited(run());
      }
    });
    _running = future;
    return future;
  }

  Future<SyncReport> _runOnce() async {
    await refreshStatus();
    var sent = 0;
    var rejected = 0;
    AppFailure? stop;
    final now = _clock().toUtc();

    for (final op in await ops(includeRejected: false)) {
      final due = await _isDue(op.opId, now);
      if (!due) continue;
      try {
        final result = await api.rpc(op.type, params: op.payload);
        await local.db.transaction((txn) async {
          await appliers[op.type]?.call(txn, op.payload, result);
          await txn.delete('outbox', where: 'op_id = ?', whereArgs: [op.opId]);
        });
        sent++;
      } on AppFailure catch (f) {
        switch (f) {
          case UnauthenticatedFailure():
            stop = f; // leave op untouched; retried after sign-in
          case OfflineFailure() || TimeoutFailure():
            await _backoff(op, f);
            stop = f;
          case ServerFailure(:final statusCode)
              when statusCode == null || statusCode >= 500:
            await _backoff(op, f);
            stop = f;
          default:
            await _reject(op, f);
            rejected++;
        }
        if (stop != null) break;
      }
    }

    final remaining =
        Sqflite.firstIntValue(
          await local.db.rawQuery(
            "select count(*) from outbox where state = 'pending'",
          ),
        ) ??
        0;
    if (sent > 0 || rejected > 0 || stop != null) {
      _log.info('sync run', {
        'sent': sent,
        'rejected': rejected,
        'remaining': remaining,
        'stoppedBy': stop?.runtimeType.toString(),
      });
    }
    await refreshStatus(error: stop);
    return SyncReport(
      sent: sent,
      rejected: rejected,
      remaining: remaining,
      stoppedBy: stop,
    );
  }

  Future<bool> _isDue(String opId, DateTime now) async {
    final r = await local.db.query(
      'outbox',
      columns: ['next_attempt_at'],
      where: 'op_id = ?',
      whereArgs: [opId],
    );
    final next = r.isEmpty ? null : r.first['next_attempt_at'] as String?;
    return next == null || !DateTime.parse(next).isAfter(now);
  }

  /// 5s, 10s, 20s … capped at 10 minutes.
  static Duration backoffFor(int attempts) => Duration(
    seconds: math.min(600, 5 * math.pow(2, math.max(0, attempts - 1)).toInt()),
  );

  Future<void> _backoff(OutboxOp op, AppFailure f) async {
    final attempts = op.attempts + 1;
    await local.db.update(
      'outbox',
      {
        'attempts': attempts,
        'next_attempt_at': _clock()
            .toUtc()
            .add(backoffFor(attempts))
            .toIso8601String(),
        'last_error': f.message,
      },
      where: 'op_id = ?',
      whereArgs: [op.opId],
    );
  }

  Future<void> _reject(OutboxOp op, AppFailure f) async {
    _log.warning('op rejected by server', {
      'type': op.type,
      'reason': f.runtimeType.toString(),
    });
    await local.db.update(
      'outbox',
      {
        'state': 'rejected',
        'attempts': op.attempts + 1,
        'last_error': f.message,
      },
      where: 'op_id = ?',
      whereArgs: [op.opId],
    );
  }

  /// Puts a rejected op back in the queue (e.g. after a teacher re-unlocks).
  Future<void> retryRejected(String opId) async {
    await local.db.update(
      'outbox',
      {'state': 'pending', 'next_attempt_at': null},
      where: 'op_id = ?',
      whereArgs: [opId],
    );
    await refreshStatus();
  }

  /// Clears backoff so the next run tries immediately (connectivity back).
  Future<void> resetBackoff() => local.db.update('outbox', {
    'next_attempt_at': null,
  }, where: "state = 'pending'");

  void dispose() => status.dispose();
}
