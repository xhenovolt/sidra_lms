import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../errors/app_failure.dart';
import '../logging/app_logger.dart';
import 'sql_runner.dart';

/// The app's connections to PostgreSQL (Neon, pooled endpoint), as the
/// low-privilege `sidra_app` login.
///
/// * Speed (Phase 6): the database is far away (~300 ms a round trip from
///   Uganda) and a call takes several round trips, so calls must not wait
///   for each other: up to [maxConnections] connections share one queue
///   and a screen's calls run side by side. Extra connections open only
///   while calls are waiting.
/// * Each call is its own transaction, so the session binding
///   (`app_private.authenticate`) can't leak between calls.
/// * Reconnects after network drops; every error comes out as a typed
///   [AppFailure].
class PgClient implements SqlRunner {
  PgClient(
    String url, {
    this.connectTimeout,
    this.queryTimeout,
    this.maxConnections = 3,
  }) : _endpoint = _endpointFrom(url);

  final Endpoint _endpoint;
  final Duration? connectTimeout;
  final Duration? queryTimeout;
  final int maxConnections;
  static const _log = AppLogger('pg');

  final _slots = <_Slot>[];
  final _jobs = Queue<_Job>();
  int _opening = 0;
  bool _closed = false;

  /// Phones drop idle sockets silently (screen off, Wi-Fi to mobile data,
  /// Neon idle close): a dead socket would make the next query hang until
  /// the query timeout, which is what showed up as uploads "timing out".
  /// After this long unused, a connection is checked before use.
  static const _idleCheckAfter = Duration(seconds: 30);
  static const _pingTimeout = Duration(seconds: 5);

  static Endpoint _endpointFrom(String url) {
    final uri = Uri.parse(url);
    final user = uri.userInfo.split(':');
    return Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: uri.pathSegments.first,
      username: Uri.decodeComponent(user.first),
      password: Uri.decodeComponent(user.skip(1).join(':')),
    );
  }

  /// Opens the first connection ahead of need (app start), so the first
  /// screen doesn't also pay for connecting (~3 s). Never throws.
  void warmUp() {
    if (_slots.isEmpty && _opening == 0 && !_closed) {
      _opening++;
      unawaited(_openSlot());
    }
  }

  @override
  Future<List<String?>> run(String? token, String sql, List<String?> params) =>
      transaction((tx) async {
        if (token != null) {
          await tx.execute(
            r'select app_private.authenticate($1)',
            parameters: [TypedValue(Type.unspecified, token)],
          );
        }
        final r = await tx.execute(
          sql,
          parameters: [for (final p in params) TypedValue(Type.unspecified, p)],
        );
        return [for (final row in r) row.first as String?];
      });

  /// Runs [body] in one transaction. Queued until a connection is free.
  Future<T> transaction<T>(Future<T> Function(TxSession tx) body) =>
      _enqueue((c) => c.runTx(body));

  Future<T> _enqueue<T>(Future<T> Function(Connection c) body) {
    if (_closed) return Future.error(const OfflineFailure('Closed'));
    final done = Completer<T>();
    _jobs.add(
      _Job((c) async => done.complete(await body(c)), done.completeError),
    );
    _pump();
    return done.future;
  }

  /// Hands waiting calls to free connections; opens another connection
  /// while calls are waiting and the limit allows.
  void _pump() {
    for (final s in _slots) {
      if (_jobs.isEmpty) return;
      if (!s.busy) unawaited(_runOn(s, _jobs.removeFirst()));
    }
    if (_jobs.length > _opening && _slots.length + _opening < maxConnections) {
      _opening++;
      unawaited(_openSlot());
    }
  }

  Future<void> _openSlot() async {
    try {
      final conn = await Connection.open(
        _endpoint,
        settings: ConnectionSettings(
          sslMode: SslMode.require,
          applicationName: 'sidra-app',
          connectTimeout: connectTimeout ?? const Duration(seconds: 12),
          queryTimeout: queryTimeout ?? const Duration(seconds: 25),
        ),
      );
      if (_closed) {
        await conn.close();
        return;
      }
      _slots.add(_Slot(conn));
    } catch (e, st) {
      // Nothing can carry the waiting calls: they fail now (offline…)
      // instead of waiting forever.
      if (_slots.isEmpty && _opening == 1) {
        final failure = mapPgError(e);
        while (_jobs.isNotEmpty) {
          _jobs.removeFirst().fail(failure, st);
        }
      }
    } finally {
      _opening--;
      _pump();
    }
  }

  Future<void> _runOn(_Slot slot, _Job job) async {
    slot.busy = true;
    try {
      if (DateTime.now().difference(slot.lastUsed) >= _idleCheckAfter) {
        // Idle for a while: make sure it is still alive (one quick round
        // trip), otherwise replace it instead of hanging.
        try {
          await slot.conn.execute('select 1').timeout(_pingTimeout);
        } catch (_) {
          _log.debug('stale connection replaced');
          await _drop(slot);
          _jobs.addFirst(job);
          return;
        }
      }
      try {
        await job.run(slot.conn);
        slot.lastUsed = DateTime.now();
      } catch (e, st) {
        final failure = mapPgError(e);
        if (failure is OfflineFailure || failure is TimeoutFailure) {
          await _drop(slot);
        }
        job.fail(failure, st);
      }
    } finally {
      slot.busy = false;
      _pump();
    }
  }

  Future<void> _drop(_Slot slot) async {
    _slots.remove(slot);
    try {
      await slot.conn.close(force: true);
    } catch (_) {}
  }

  Future<void> close() async {
    _closed = true;
    for (final s in [..._slots]) {
      await _drop(s);
    }
  }

  /// Maps driver/network errors to [AppFailure]. SQLSTATE `PTnnn` raised by
  /// Sidra's database functions become the matching HTTP-like failure.
  static AppFailure mapPgError(Object e) {
    if (e is AppFailure) return e;
    if (e is ServerException) return mapSqlState(e.code, e.message);
    if (e is TimeoutException) return const TimeoutFailure();
    if (e is SocketException || e is HandshakeException || e is TlsException) {
      return const OfflineFailure();
    }
    if (e is PgException) {
      // Connection closed / broken pipe and similar transport problems.
      _log.debug('pg transport error', {'type': e.runtimeType.toString()});
      return const OfflineFailure('Connection lost');
    }
    return UnexpectedFailure('Database error', cause: e);
  }

  /// SQLSTATE → failure. `PTnnn` codes raised by Sidra's SQL functions map
  /// like HTTP statuses; the database message is kept for the UI.
  static AppFailure mapSqlState(String? sqlState, String msg) {
    final code = sqlState ?? '';
    return switch (code) {
      'PT401' => UnauthenticatedFailure(msg),
      'PT403' || '42501' => ForbiddenFailure(msg),
      'PT404' => NotFoundFailure(msg),
      'PT409' || '23505' => ConflictFailure(msg),
      '57014' => const TimeoutFailure(),
      final c
          when c.startsWith('PT4') ||
              c.startsWith('22') ||
              c.startsWith('23') =>
        ServerFailure(msg, statusCode: 400),
      final c when c.startsWith('PT5') => ServerFailure(msg, statusCode: 503),
      _ => ServerFailure(msg, statusCode: 500),
    };
  }
}

class _Slot {
  _Slot(this.conn);
  final Connection conn;
  bool busy = false;
  DateTime lastUsed = DateTime.now();
}

class _Job {
  _Job(this.run, this.fail);
  final Future<void> Function(Connection c) run;
  final void Function(Object error, StackTrace st) fail;
}
