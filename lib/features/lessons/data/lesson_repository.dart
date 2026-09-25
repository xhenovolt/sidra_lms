import 'package:sqflite/sqflite.dart';

import '../../../core/data/cached_stream.dart';
import '../../../core/database/local_database.dart';
import '../../../core/network/postgres_api.dart';
import '../../../shared/models/json.dart';
import '../domain/content_blocks.dart';

class LessonContent {
  const LessonContent({
    required this.lessonId,
    required this.contentVersion,
    required this.blocks,
    this.fromCache = false,
  });

  final String lessonId;
  final int contentVersion;
  final List<ContentBlock> blocks;
  final bool fromCache;
}

/// Lesson content (blocks). Postgres RLS returns rows only for lessons the
/// learner has unlocked, so an empty result for a locked lesson is expected;
/// lock state itself comes from the course outline.
class LessonRepository {
  LessonRepository(this._local, this._api);

  final LocalDatabase _local;
  final PostgresApi _api;

  Stream<LessonContent> watch({
    required String lessonId,
    required String courseId,
    required int expectedVersion,
  }) => cachedThenRemote(
    label: 'lesson',
    cached: () => cached(lessonId),
    remote: () async {
      // Skip the network when the cached copy is already current.
      final c = await cached(lessonId);
      if (c != null && c.contentVersion >= expectedVersion) return c;
      return fetch(
        lessonId: lessonId,
        courseId: courseId,
        version: expectedVersion,
      );
    },
  );

  Future<LessonContent?> cached(String lessonId) async {
    final rows = await _local.db.query(
      'lesson_content',
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );
    if (rows.isEmpty) return null;
    return _decode(
      lessonId,
      rows.first['content_version']! as int,
      LocalDatabase.decodeMap(rows.first['json']),
      fromCache: true,
    );
  }

  Future<LessonContent> fetch({
    required String lessonId,
    required String courseId,
    required int version,
  }) async {
    final rows = await _api.select(
      'lesson_content_blocks',
      filters: {'lesson_id': Pg.eq(lessonId)},
      order: 'position.asc',
    );
    final json = {'blocks': rows};
    await _local.db.insert('lesson_content', {
      'lesson_id': lessonId,
      'course_id': courseId,
      'content_version': version,
      'json': LocalDatabase.encode(json),
      'fetched_at': LocalDatabase.now(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return _decode(lessonId, version, json);
  }

  Future<Set<String>> cachedLessonIds(String courseId) async {
    final rows = await _local.db.query(
      'lesson_content',
      columns: ['lesson_id'],
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    return {for (final r in rows) r['lesson_id']! as String};
  }

  LessonContent _decode(
    String lessonId,
    int version,
    Json json, {
    bool fromCache = false,
  }) {
    final blocks = [
      for (final b in json['blocks'] as List)
        ContentBlock.fromJson(Json.from(b as Map)),
    ]..sort((a, b) => a.position.compareTo(b.position));
    return LessonContent(
      lessonId: lessonId,
      contentVersion: version,
      blocks: blocks,
      fromCache: fromCache,
    );
  }
}
