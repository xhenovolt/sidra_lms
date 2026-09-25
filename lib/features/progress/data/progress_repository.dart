import 'package:sqflite/sqflite.dart';

import '../../../core/database/local_database.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/postgres_api.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../shared/models/json.dart';
import '../domain/progress_models.dart';

/// Lesson progress, local-first.
///
/// Every change is written to SQLite AND queued in the outbox in the same
/// transaction, so it works offline and is never lost. The server merges
/// with the same rules as [LessonProgress.mergeWith].
class ProgressRepository {
  ProgressRepository(this._local, this._api, {this.onQueued});

  final LocalDatabase _local;
  final PostgresApi _api;

  /// Called after a change is queued (used to trigger a sync run).
  final void Function()? onQueued;

  Future<Map<String, LessonProgress>> forCourse(String courseId) async {
    final rows = await _local.db.query(
      'progress',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    return {for (final r in rows) r['lesson_id']! as String: _fromRow(r)};
  }

  Future<LessonProgress?> forLesson(String lessonId) async {
    final rows = await _local.db.query(
      'progress',
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  static LessonProgress _fromRow(Map<String, Object?> r) {
    final j = LocalDatabase.decodeMap(r['json']);
    j['synced'] = (r['synced']! as int) == 1;
    return LessonProgress.fromJson(j);
  }

  /// Records progress locally and queues it for the server.
  Future<LessonProgress> record({
    required String lessonId,
    required String courseId,
    required ProgressStatus status,
    Json lastPosition = const {},
    DateTime? at,
  }) async {
    final when = (at ?? DateTime.now()).toUtc();
    final change = LessonProgress(
      lessonId: lessonId,
      courseId: courseId,
      status: status,
      lastPosition: lastPosition,
      completedAt: status == ProgressStatus.completed ? when : null,
      updatedAt: when,
      synced: false,
    );
    late LessonProgress merged;
    await _local.guard(
      () => _local.db.transaction((txn) async {
        final existing = await txn.query(
          'progress',
          where: 'lesson_id = ?',
          whereArgs: [lessonId],
        );
        merged = existing.isEmpty
            ? change
            : _fromRow(existing.first).mergeWith(change);
        await _write(txn, merged, synced: false);
        final opId = SyncEngine.newOpId();
        await SyncEngine.enqueue(
          txn,
          opId: opId,
          type: 'record_progress',
          refKey: lessonId,
          payload: {
            'p_op_id': opId,
            'p_lesson_id': lessonId,
            'p_status': enumToDb(status),
            'p_last_position': lastPosition,
            'p_client_updated_at': when.toIso8601String(),
          },
        );
      }),
    );
    onQueued?.call();
    return merged;
  }

  /// Pulls server progress for a course and merges it in. Local changes
  /// still waiting in the outbox stay marked unsynced.
  Future<Map<String, LessonProgress>> refresh(String courseId) async {
    try {
      final rows = await _api.select(
        'learner_progress',
        filters: {'course_id': Pg.eq(courseId)},
      );
      await _local.db.transaction((txn) async {
        for (final r in rows) {
          await _mergeServerRow(txn, r);
        }
      });
    } on OfflineFailure {
      // Local data is still valid; caller shows cached progress.
    } on TimeoutFailure {
      // Same.
    }
    return forCourse(courseId);
  }

  static Future<void> _mergeServerRow(
    DatabaseExecutor txn,
    Map<String, dynamic> row,
  ) async {
    final server = LessonProgress.fromJson({...row, 'synced': true});
    final existing = await txn.query(
      'progress',
      where: 'lesson_id = ?',
      whereArgs: [server.lessonId],
    );
    final pending = await _hasPendingOp(txn, server.lessonId);
    final merged = existing.isEmpty
        ? server
        : _fromRow(existing.first).mergeWith(server);
    await _write(txn, merged, synced: !pending);
  }

  static Future<bool> _hasPendingOp(
    DatabaseExecutor txn,
    String lessonId,
  ) async {
    final r = await txn.rawQuery(
      "select count(*) c from outbox where op_type = 'record_progress' "
      'and ref_key = ?',
      [lessonId],
    );
    return (r.first['c']! as int) > 0;
  }

  static Future<void> _write(
    DatabaseExecutor txn,
    LessonProgress p, {
    required bool synced,
  }) => txn.insert('progress', {
    'lesson_id': p.lessonId,
    'course_id': p.courseId,
    'json': LocalDatabase.encode(p.toJson()..remove('synced')),
    'synced': synced ? 1 : 0,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  /// Outbox applier: server accepted a record_progress op.
  static Future<void> applyServerResult(
    DatabaseExecutor txn,
    Map<String, dynamic> payload,
    Object? result,
  ) async {
    if (result is! Map) return;
    // The op being applied is still in the outbox during this call; it is
    // deleted right after. Count only OTHER pending ops for this lesson.
    final others = await txn.rawQuery(
      "select count(*) c from outbox where op_type = 'record_progress' "
      'and ref_key = ? and op_id <> ?',
      [payload['p_lesson_id'], payload['p_op_id']],
    );
    final server = LessonProgress.fromJson({
      ...Map<String, dynamic>.from(result),
      'synced': true,
    });
    final existing = await txn.query(
      'progress',
      where: 'lesson_id = ?',
      whereArgs: [server.lessonId],
    );
    final merged = existing.isEmpty
        ? server
        : _fromRow(existing.first).mergeWith(server);
    await _write(txn, merged, synced: (others.first['c']! as int) == 0);
  }
}
