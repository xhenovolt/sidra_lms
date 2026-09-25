import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/features/curriculum/domain/curriculum_models.dart';
import 'package:sidra_lms/features/curriculum/domain/curriculum_tree.dart';

CurriculumNode node(
  String id, {
  String? parent,
  String? unit,
  int pos = 0,
  String type = 'section',
  String? level,
  int? surah,
  int? vs,
  int? ve,
  int? page,
}) => CurriculumNode.fromJson({
  'id': id,
  'course_id': 'c',
  'parent_id': parent,
  'unit_id': unit,
  'node_type': type,
  'title': id,
  'position': pos,
  'structure_level_id': level,
  'surah_number': surah,
  'verse_start': vs,
  'verse_end': ve,
  'page_start': page,
  'status': 'published',
});

Lesson lesson(String id, {String? nodeId, String? unit, int pos = 0}) =>
    Lesson.fromJson({
      'id': id,
      'course_id': 'c',
      'node_id': nodeId,
      'unit_id': unit,
      'title': id,
      'position': pos,
      'status': 'published',
    });

void main() {
  group('CurriculumTree', () {
    test('Surah → Verse book renders as nested tree with lessons', () {
      final tree = CurriculumTree.build(
        units: [
          CourseUnit.fromJson({
            'id': 'u1',
            'course_id': 'c',
            'title': 'Unit 1',
            'position': 0,
            'status': 'published',
          }),
        ],
        nodes: [
          node('fatiha', unit: 'u1', type: 'surah', level: 'L1', surah: 1),
          node(
            'v1-3',
            parent: 'fatiha',
            type: 'verse',
            level: 'L2',
            vs: 1,
            ve: 3,
          ),
        ],
        lessons: [
          lesson('l2', nodeId: 'v1-3', pos: 1),
          lesson('l1', nodeId: 'v1-3', pos: 0),
        ],
        order: [
          const LessonOrderEntry(lessonId: 'l1', seq: 1, isUnlocked: true),
          const LessonOrderEntry(lessonId: 'l2', seq: 2, isUnlocked: false),
        ],
        levelLabels: const {'L1': 'Surah', 'L2': 'Verse'},
      );

      final unit = tree.items.single as UnitItem;
      final surah = unit.children.single as NodeItem;
      expect(surah.levelLabel, 'Surah');
      final verses = surah.children.single as NodeItem;
      expect(verses.node.locator, 'Verses 1–3');
      final lessons = verses.children.cast<LessonItem>();
      expect(lessons.map((l) => l.lesson.id), ['l1', 'l2']);
      expect(lessons.map((l) => l.access), [
        LessonAccess.unlocked,
        LessonAccess.locked,
      ]);
    });

    test('Page → Lesson book (different structure) needs no code change', () {
      final tree = CurriculumTree.build(
        units: const [],
        nodes: [
          node('p2', pos: 1, type: 'page', page: 2),
          node('p1', type: 'page', page: 1),
        ],
        lessons: [
          lesson('a', nodeId: 'p1'),
          lesson('b', nodeId: 'p2'),
        ],
        order: const [
          LessonOrderEntry(lessonId: 'a', seq: 1, isUnlocked: true),
          LessonOrderEntry(lessonId: 'b', seq: 2, isUnlocked: true),
        ],
        completedLessonIds: const {'a'},
      );
      final pages = tree.items.cast<NodeItem>();
      expect(pages.map((p) => p.node.locator), ['Page 1', 'Page 2']);
      expect(
        (pages.first.children.single as LessonItem).access,
        LessonAccess.completed,
      );
    });

    test('nodes and lessons interleave by position under one parent', () {
      final tree = CurriculumTree.build(
        units: const [],
        nodes: [node('chapter', pos: 1)],
        lessons: [lesson('intro', pos: 0), lesson('outro', pos: 2)],
        order: const [],
      );
      expect(tree.items.map((i) => i.runtimeType), [
        LessonItem,
        NodeItem,
        LessonItem,
      ]);
    });

    test('lessons missing from server order are shown locked', () {
      final tree = CurriculumTree.build(
        units: const [],
        nodes: const [],
        lessons: [lesson('x')],
        order: const [],
      );
      final item = tree.items.single as LessonItem;
      expect(item.access, LessonAccess.locked);
      expect(item.seq, isNull);
      expect(tree.orderedLessons, isEmpty);
    });

    test('previous / next follow server sequence', () {
      final tree = CurriculumTree.build(
        units: const [],
        nodes: const [],
        lessons: [lesson('a'), lesson('b', pos: 1), lesson('c', pos: 2)],
        order: const [
          LessonOrderEntry(lessonId: 'c', seq: 3, isUnlocked: false),
          LessonOrderEntry(lessonId: 'a', seq: 1, isUnlocked: true),
          LessonOrderEntry(lessonId: 'b', seq: 2, isUnlocked: true),
        ],
      );
      expect(tree.previousOf('a'), isNull);
      expect(tree.nextOf('a')?.id, 'b');
      expect(tree.previousOf('c')?.id, 'b');
      expect(tree.nextOf('c'), isNull);
    });

    test('a corrupt cycle in cached data does not hang', () {
      final tree = CurriculumTree.build(
        units: const [],
        nodes: [
          node('x', parent: 'y'),
          node('y', parent: 'x'),
        ],
        lessons: const [],
        order: const [],
      );
      expect(tree.items, isEmpty); // no roots; nothing recursed forever
    });
  });

  test('Course parses Postgres enums and numeric strings', () {
    final c = Course.fromJson({
      'id': '1',
      'slug': 'aqeedah',
      'title': 'Aqeedah',
      'subject': 'Theology',
      'access': 'paid',
      'price_amount': '20.00',
      'progression': 'teacher_gated',
      'status': 'published',
      'learning_objectives': ['Tawhid'],
      'difficulty': 'some_future_level',
    });
    expect(c.access, CourseAccess.paid);
    expect(c.priceAmount, 20.0);
    expect(c.progression, Progression.teacherGated);
    expect(c.difficulty, Difficulty.beginner); // unknown label → fallback
    expect(Course.fromJson(c.toJson()).progression, Progression.teacherGated);
  });
}
