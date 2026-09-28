import 'package:sqflite/sqflite.dart';

import '../../../core/data/cached_stream.dart';
import '../../../core/database/local_database.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/postgres_api.dart';
import '../../../shared/models/json.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../progress/domain/progress_models.dart';

/// Everything needed to render a course's outline, whatever its structure.
class CourseOutline {
  const CourseOutline({
    required this.course,
    required this.units,
    required this.nodes,
    required this.lessons,
    required this.order,
    required this.books,
    required this.levelLabels,
  });

  factory CourseOutline.fromJson(Json j) => CourseOutline(
    course: Course.fromJson(j.obj('course')),
    units: [
      for (final u in j['units'] as List) CourseUnit.fromJson(Json.from(u)),
    ],
    nodes: [
      for (final n in j['nodes'] as List) CurriculumNode.fromJson(Json.from(n)),
    ],
    lessons: [
      for (final l in j['lessons'] as List) Lesson.fromJson(Json.from(l)),
    ],
    order: [
      for (final o in j['order'] as List)
        LessonOrderEntry.fromJson(Json.from(o)),
    ],
    books: [for (final b in j['books'] as List) Book.fromJson(Json.from(b))],
    levelLabels: Map<String, String>.from(j['level_labels'] as Map),
  );

  final Course course;
  final List<CourseUnit> units;
  final List<CurriculumNode> nodes;
  final List<Lesson> lessons;
  final List<LessonOrderEntry> order;
  final List<Book> books;

  /// structure_level_id → admin label ("Surah", "Page"…).
  final Map<String, String> levelLabels;

  Lesson? lesson(String id) {
    for (final l in lessons) {
      if (l.id == id) return l;
    }
    return null;
  }

  bool isUnlocked(String lessonId) =>
      order.any((o) => o.lessonId == lessonId && o.isUnlocked);

  /// The course as a brand-new learner sees it: only the first lesson
  /// (plus free previews, or everything in an open course) is unlocked.
  /// Used when an administrator previews the learner app.
  CourseOutline asNewLearner() {
    final previews = {
      for (final l in lessons)
        if (l.isPreview) l.id,
    };
    final first = order.isEmpty
        ? null
        : order.reduce((a, b) => a.seq <= b.seq ? a : b).lessonId;
    return CourseOutline(
      course: course,
      units: units,
      nodes: nodes,
      lessons: lessons,
      books: books,
      levelLabels: levelLabels,
      order: [
        for (final o in order)
          LessonOrderEntry(
            lessonId: o.lessonId,
            seq: o.seq,
            isUnlocked:
                course.progression == Progression.open ||
                o.lessonId == first ||
                previews.contains(o.lessonId),
          ),
      ],
    );
  }

  Json toJson() => {
    'course': course.toJson(),
    'units': [for (final u in units) u.toJson()],
    'nodes': [for (final n in nodes) n.toJson()],
    'lessons': [for (final l in lessons) l.toJson()],
    'order': [for (final o in order) o.toJson()],
    'books': [for (final b in books) b.toJson()],
    'level_labels': levelLabels,
  };
}

class CourseRepository {
  CourseRepository(this._local, this._api);

  final LocalDatabase _local;
  final PostgresApi _api;

  // ----------------------------------------------------------- catalogue --

  Stream<List<Course>> watchCatalogue() => cachedThenRemote(
    label: 'catalogue',
    cached: () async {
      final rows = await _local.db.query('courses', where: 'in_catalogue = 1');
      if (rows.isEmpty) return null;
      return _sortedCourses(rows);
    },
    remote: () async {
      final rows = await _api.select(
        'courses',
        filters: {
          'status': Pg.eq('published'),
          'visibility': Pg.eq('catalogue'),
        },
        order: 'title.asc',
      );
      final courses = rows.map(Course.fromJson).toList();
      await _local.db.transaction((txn) async {
        await txn.update('courses', {'in_catalogue': 0});
        for (final c in courses) {
          await _saveCourse(txn, c, inCatalogue: true);
        }
      });
      return courses;
    },
  );

  List<Course> _sortedCourses(List<Map<String, Object?>> rows) =>
      rows
          .map((r) => Course.fromJson(LocalDatabase.decodeMap(r['json'])))
          .toList()
        ..sort((a, b) => a.title.compareTo(b.title));

  Future<void> _saveCourse(
    DatabaseExecutor db,
    Course c, {
    bool? inCatalogue,
  }) async {
    final existing = await db.query(
      'courses',
      columns: ['in_catalogue'],
      where: 'id = ?',
      whereArgs: [c.id],
    );
    await db.insert('courses', {
      'id': c.id,
      'json': LocalDatabase.encode(c.toJson()),
      'content_version': c.contentVersion,
      'in_catalogue': inCatalogue == null
          ? (existing.isEmpty ? 0 : existing.first['in_catalogue'])
          : (inCatalogue ? 1 : 0),
      'fetched_at': LocalDatabase.now(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---------------------------------------------------------- my courses --

  Stream<List<CourseProgressSummary>> watchMyCourses() => cachedThenRemote(
    label: 'my_courses',
    cached: () async {
      final rows = await _local.db.query('my_courses');
      if (rows.isEmpty) return null;
      return rows
          .map(
            (r) => CourseProgressSummary.fromJson(
              LocalDatabase.decodeMap(r['json']),
            ),
          )
          .toList()
        ..sort(_byRecency);
    },
    remote: fetchMyCourses,
  );

  static int _byRecency(CourseProgressSummary a, CourseProgressSummary b) {
    final at = a.lastAccessedAt, bt = b.lastAccessedAt;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  }

  Future<List<CourseProgressSummary>> fetchMyCourses() async {
    final rows = await _api.rpcRows('my_courses');
    final list = rows.map(CourseProgressSummary.fromJson).toList();
    // Make sure enrolled courses are cached even if not in the catalogue.
    final missing = [
      for (final s in list)
        if ((await _local.db.query(
          'courses',
          where: 'id = ?',
          whereArgs: [s.courseId],
        )).isEmpty)
          s.courseId,
    ];
    final fetched = missing.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _api.select('courses', filters: {'id': Pg.inList(missing)});
    await _local.db.transaction((txn) async {
      await txn.delete('my_courses');
      for (final s in list) {
        await txn.insert('my_courses', {
          'course_id': s.courseId,
          'json': LocalDatabase.encode(s.toJson()),
          'fetched_at': LocalDatabase.now(),
        });
      }
      for (final c in fetched) {
        await _saveCourse(txn, Course.fromJson(c));
      }
    });
    return list;
  }

  Future<Course?> cachedCourse(String id) async {
    final rows = await _local.db.query(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty
        ? null
        : Course.fromJson(LocalDatabase.decodeMap(rows.first['json']));
  }

  // ------------------------------------------------------------- outline --

  Stream<CourseOutline> watchOutline(String courseId) => cachedThenRemote(
    label: 'outline',
    cached: () => cachedOutline(courseId),
    remote: () => fetchOutline(courseId),
  );

  Future<CourseOutline?> cachedOutline(String courseId) async {
    final rows = await _local.db.query(
      'course_outlines',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    return rows.isEmpty
        ? null
        : CourseOutline.fromJson(LocalDatabase.decodeMap(rows.first['json']));
  }

  Future<CourseOutline> fetchOutline(String courseId) async {
    final byCourse = {'course_id': Pg.eq(courseId)};
    final results = await Future.wait([
      _api.selectOne('courses', filters: {'id': Pg.eq(courseId)}),
      _api.select('course_units', filters: byCourse, order: 'position'),
      _api.select('curriculum_nodes', filters: byCourse, order: 'position'),
      _api.select('lessons', filters: byCourse, order: 'position'),
      _api.rpcRows('course_lesson_order', params: {'p_course_id': courseId}),
      _api.select('course_books', filters: byCourse, order: 'position'),
    ]);
    final courseRow = results[0] as Map<String, dynamic>?;
    if (courseRow == null) {
      // Unpublished or no longer visible: drop stale cache.
      await _local.db.delete(
        'course_outlines',
        where: 'course_id = ?',
        whereArgs: [courseId],
      );
      throw const NotFoundFailure('Course is not available');
    }
    final nodes = (results[2] as List<Map<String, dynamic>>)
        .map(CurriculumNode.fromJson)
        .toList();

    final bookIds = [
      for (final cb in results[5] as List<Map<String, dynamic>>)
        cb['book_id'] as String,
    ];
    final bookRows = bookIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _api.select('books', filters: {'id': Pg.inList(bookIds)});
    final booksById = {for (final b in bookRows) b['id'] as String: b};

    final levelIds = {
      for (final n in nodes)
        if (n.structureLevelId != null) n.structureLevelId!,
    };
    final levels = levelIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _api.select(
            'book_structure_levels',
            filters: {'id': Pg.inList(levelIds)},
          );

    final outline = CourseOutline(
      course: Course.fromJson(courseRow),
      units: (results[1] as List<Map<String, dynamic>>)
          .map(CourseUnit.fromJson)
          .toList(),
      nodes: nodes,
      lessons: (results[3] as List<Map<String, dynamic>>)
          .map(Lesson.fromJson)
          .toList(),
      order: (results[4] as List<Map<String, dynamic>>)
          .map(LessonOrderEntry.fromJson)
          .toList(),
      books: [
        for (final id in bookIds)
          if (booksById[id] != null) Book.fromJson(booksById[id]!),
      ],
      levelLabels: {
        for (final l in levels.map(BookStructureLevel.fromJson))
          l.id: l.labelSingular,
      },
    );

    await _local.db.transaction((txn) async {
      await _saveCourse(txn, outline.course);
      await txn.insert('course_outlines', {
        'course_id': courseId,
        'json': LocalDatabase.encode(outline.toJson()),
        'fetched_at': LocalDatabase.now(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      // Content of lessons that are no longer unlocked (teacher revoked, or
      // lesson unpublished) must not stay readable offline.
      final unlocked = {
        for (final o in outline.order)
          if (o.isUnlocked) o.lessonId,
      };
      final cached = await txn.query(
        'lesson_content',
        columns: ['lesson_id'],
        where: 'course_id = ?',
        whereArgs: [courseId],
      );
      for (final r in cached) {
        final id = r['lesson_id']! as String;
        if (!unlocked.contains(id)) {
          await txn.delete(
            'lesson_content',
            where: 'lesson_id = ?',
            whereArgs: [id],
          );
        }
      }
    });
    return outline;
  }

  // ----------------------------------------------------------- enrolment --

  /// Self-enrolment in a free course (server refuses paid ones).
  Future<void> enrol(String courseId) async {
    await _api.rpc('enrol_in_course', params: {'p_course_id': courseId});
    await Future.wait([fetchMyCourses(), fetchOutline(courseId)]);
  }
}
