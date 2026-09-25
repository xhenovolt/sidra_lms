import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/database/local_database.dart';
import 'package:sidra_lms/core/errors/app_failure.dart';
import 'package:sidra_lms/features/courses/data/course_repository.dart';
import 'package:sidra_lms/features/lessons/data/lesson_repository.dart';
import 'package:sidra_lms/features/lessons/domain/content_blocks.dart';

import '../helpers/fake_postgres_api.dart';

Map<String, dynamic> courseRow() => {
  'id': 'c1',
  'slug': 'quran',
  'title': 'Quran for Beginners',
  'subject': 'Quran',
  'status': 'published',
  'access': 'free',
  'progression': 'teacher_gated',
  'content_version': 3,
};

void main() {
  late LocalDatabase db;
  late FakePostgresApi api;
  late CourseRepository courses;
  late LessonRepository lessons;
  var unlocked = {'l1'};

  setUp(() async {
    db = await openTestDatabase();
    api = FakePostgresApi();
    courses = CourseRepository(db, api);
    lessons = LessonRepository(db, api);
    unlocked = {'l1'};
    api.selectHandlers['courses'] = (_) => [courseRow()];
    api.selectHandlers['lessons'] = (_) => [
      for (final id in ['l1', 'l2'])
        {
          'id': id,
          'course_id': 'c1',
          'title': id,
          'position': id == 'l1' ? 0 : 1,
          'status': 'published',
        },
    ];
    api.rpcHandlers['course_lesson_order'] = (_) => [
      {'lesson_id': 'l1', 'seq': 1, 'is_unlocked': unlocked.contains('l1')},
      {'lesson_id': 'l2', 'seq': 2, 'is_unlocked': unlocked.contains('l2')},
    ];
    api.selectHandlers['lesson_content_blocks'] = (f) =>
        f['lesson_id'] == 'eq.l1'
        ? [
            {
              'id': 'b1',
              'position': 0,
              'block_type': 'quran_text',
              'body': {'arabic': 'بِسْمِ ٱللَّهِ'},
            },
          ]
        : const [];
  });

  tearDown(() => db.close());

  test('catalogue: empty cache + offline surfaces the error', () async {
    api.failAll = const OfflineFailure();
    await expectLater(
      courses.watchCatalogue().toList(),
      throwsA(isA<OfflineFailure>()),
    );
  });

  test('catalogue: cached copy is served when offline', () async {
    await courses.watchCatalogue().toList();
    api.failAll = const OfflineFailure();
    final emitted = await courses.watchCatalogue().toList();
    expect(emitted, hasLength(1));
    expect(emitted.single.single.title, 'Quran for Beginners');
  });

  test('outline + downloaded lesson readable offline', () async {
    final outline = await courses.fetchOutline('c1');
    expect(outline.isUnlocked('l1'), isTrue);
    expect(outline.isUnlocked('l2'), isFalse);
    await lessons.fetch(lessonId: 'l1', courseId: 'c1', version: 1);

    api.failAll = const OfflineFailure();
    final offlineOutline = await courses.watchOutline('c1').toList();
    expect(offlineOutline.single.lessons, hasLength(2));
    final content = await lessons
        .watch(lessonId: 'l1', courseId: 'c1', expectedVersion: 1)
        .toList();
    expect(content.first.blocks.single, isA<QuranTextBlock>());
    expect(content.first.fromCache, isTrue);
  });

  test('revoked unlock purges cached lesson content on refresh', () async {
    await courses.fetchOutline('c1');
    await lessons.fetch(lessonId: 'l1', courseId: 'c1', version: 1);
    expect(await lessons.cached('l1'), isNotNull);

    unlocked = {}; // teacher revoked access
    await courses.fetchOutline('c1');
    expect(await lessons.cached('l1'), isNull);
  });

  test('unpublished course drops its cached outline', () async {
    await courses.fetchOutline('c1');
    api.selectHandlers['courses'] = (_) => const [];
    await expectLater(
      courses.fetchOutline('c1'),
      throwsA(isA<NotFoundFailure>()),
    );
    expect(await courses.cachedOutline('c1'), isNull);
  });

  test('cached lesson at current version skips the network', () async {
    await lessons.fetch(lessonId: 'l1', courseId: 'c1', version: 2);
    api.failAll = StateError('network must not be used');
    final out = await lessons
        .watch(lessonId: 'l1', courseId: 'c1', expectedVersion: 2)
        .toList();
    expect(out, hasLength(2)); // cache, then "remote" = same cache
  });
}
