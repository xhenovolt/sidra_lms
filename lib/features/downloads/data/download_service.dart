import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/local_database.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/postgres_api.dart';
import '../../assessments/data/assessment_repository.dart';
import '../../courses/data/course_repository.dart';
import '../../lessons/data/lesson_repository.dart';
import '../../lessons/domain/content_blocks.dart';
import '../../media/data/media_repository.dart';

enum DownloadState { none, downloading, done, failed }

class CourseDownload {
  const CourseDownload({
    required this.courseId,
    required this.state,
    this.totalBytes = 0,
    this.doneBytes = 0,
    this.error,
  });

  final String courseId;
  final DownloadState state;
  final int totalBytes;
  final int doneBytes;
  final String? error;

  int get percent =>
      totalBytes == 0 ? 0 : (doneBytes * 100 ~/ totalBytes).clamp(0, 100);
}

/// Downloads a course for offline study, on explicit request only.
///
/// Scope: lesson content and media for lessons the learner has UNLOCKED
/// (locked content isn't accessible anyway), plus practice quizzes. Assets
/// an admin marked non-downloadable are streamed only. Already-downloaded
/// files are skipped, so a retry after an interruption resumes.
class DownloadService {
  DownloadService({
    required this.local,
    required this.api,
    required this.courses,
    required this.lessons,
    required this.media,
    required this.assessments,
  });

  final LocalDatabase local;
  final PostgresApi api;
  final CourseRepository courses;
  final LessonRepository lessons;
  final MediaRepository media;
  final AssessmentRepository assessments;

  Future<CourseDownload> status(String courseId) => statusIn(local, courseId);

  Future<List<CourseDownload>> all() => allIn(local);

  /// Stored state, readable without constructing the full service.
  static Future<CourseDownload> statusIn(
    LocalDatabase local,
    String courseId,
  ) async {
    final r = await local.db.query(
      'downloads',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    if (r.isEmpty) {
      return CourseDownload(courseId: courseId, state: DownloadState.none);
    }
    final row = r.first;
    return CourseDownload(
      courseId: courseId,
      state: DownloadState.values.byName(row['state']! as String),
      totalBytes: (row['total_bytes'] as int?) ?? 0,
      doneBytes: (row['done_bytes'] as int?) ?? 0,
      error: row['error'] as String?,
    );
  }

  static Future<List<CourseDownload>> allIn(LocalDatabase local) async {
    final rows = await local.db.query('downloads', orderBy: 'updated_at desc');
    return [
      for (final r in rows) await statusIn(local, r['course_id']! as String),
    ];
  }

  Future<void> _save(CourseDownload d) => local.db.insert('downloads', {
    'course_id': d.courseId,
    'state': d.state.name,
    'total_bytes': d.totalBytes,
    'done_bytes': d.doneBytes,
    'error': d.error,
    'updated_at': LocalDatabase.now(),
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Stream<CourseDownload> download(
    String courseId, {
    CancelToken? cancelToken,
  }) async* {
    var d = CourseDownload(
      courseId: courseId,
      state: DownloadState.downloading,
    );
    await _save(d);
    yield d;
    try {
      final outline = await courses.fetchOutline(courseId);
      final mediaIds = <String>{?outline.course.thumbnailAssetId};
      final assessmentIds = <String>{};
      for (final o in outline.order.where((o) => o.isUnlocked)) {
        final lesson = outline.lesson(o.lessonId);
        if (lesson == null) continue;
        final content = await lessons.fetch(
          lessonId: lesson.id,
          courseId: courseId,
          version: lesson.contentVersion,
        );
        for (final b in content.blocks) {
          if (b.mediaAssetId != null) mediaIds.add(b.mediaAssetId!);
          if (b is AssessmentBlock) assessmentIds.add(b.assessmentId);
        }
      }
      for (final a in assessmentIds) {
        try {
          await assessments.load(a);
        } on NotFoundFailure {
          // Locked or removed; skip.
        }
      }

      // Sizes and download permission from the database.
      final assets = mediaIds.isEmpty
          ? const <Map<String, dynamic>>[]
          : await api.select(
              'media_assets',
              columns: 'id,bytes,downloadable',
              filters: {'id': Pg.inList(mediaIds)},
            );
      final wanted = [
        for (final a in assets)
          if (a['downloadable'] != false) a,
      ];
      final total = wanted.fold<int>(
        0,
        (s, a) => s + ((a['bytes'] as num?)?.toInt() ?? 0),
      );
      var done = 0;
      d = CourseDownload(
        courseId: courseId,
        state: DownloadState.downloading,
        totalBytes: total,
      );
      await _save(d);
      yield d;

      for (final a in wanted) {
        final expected = (a['bytes'] as num?)?.toInt() ?? 0;
        await media.download(
          a['id'] as String,
          courseId: courseId,
          cancelToken: cancelToken,
        );
        done += expected;
        d = CourseDownload(
          courseId: courseId,
          state: DownloadState.downloading,
          totalBytes: total,
          doneBytes: done,
        );
        yield d;
      }
      d = CourseDownload(
        courseId: courseId,
        state: DownloadState.done,
        totalBytes: total,
        doneBytes: total,
      );
      await _save(d);
      yield d;
    } on AppFailure catch (e) {
      d = CourseDownload(
        courseId: courseId,
        state: DownloadState.failed,
        totalBytes: d.totalBytes,
        doneBytes: d.doneBytes,
        error: e is InsufficientStorageFailure ? 'storage' : 'network',
      );
      await _save(d);
      yield d;
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) rethrow;
      d = CourseDownload(
        courseId: courseId,
        state: DownloadState.failed,
        totalBytes: d.totalBytes,
        doneBytes: d.doneBytes,
        error: 'cancelled',
      );
      await _save(d);
      yield d;
    }
  }

  /// Courses with something downloaded on this phone.
  Future<List<String>> downloadedCourseIds() async => [
    for (final r in await local.db.rawQuery(
      'select distinct course_id from downloads where course_id is not null',
    ))
      r['course_id']! as String,
  ];

  Future<void> remove(String courseId) async {
    await media.removeCourse(courseId);
    await local.db.delete(
      'downloads',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
  }
}
