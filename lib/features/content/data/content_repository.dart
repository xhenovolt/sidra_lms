import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/network/postgres_api.dart';
import '../../../shared/models/json.dart';

/// A language a course or lesson can be taught in.
class Language {
  const Language(this.code, this.name, this.nativeName, {this.rtl = false});
  factory Language.fromJson(Json j) => Language(
    j.str('code'),
    j.str('name'),
    j.strOrNull('native_name'),
    rtl: j.strOrNull('direction') == 'rtl',
  );
  final String code;
  final String name;
  final String? nativeName;
  final bool rtl;
}

class LearningTrack {
  const LearningTrack(this.key, this.name, this.description);
  factory LearningTrack.fromJson(Json j) =>
      LearningTrack(j.str('key'), j.str('name'), j.strOrNull('description'));
  final String key;
  final String name;
  final String? description;
}

/// Where a resource is attached.
enum ResourceTarget { course, unit, book, node, lesson, assignment }

/// A file or link attached to course material.
class Resource {
  const Resource(this.j, {this.linkId, this.linkStatus});
  final Json j;
  final String? linkId;
  final String? linkStatus;

  String get id => j.str('id');
  String get kind => j.strOrNull('kind') ?? 'other';
  String get title => j.strOrNull('title') ?? '';
  String? get description => j.strOrNull('description');
  String? get language => j.strOrNull('language');
  String get provider => j.strOrNull('provider') ?? 'external';
  String? get mediaAssetId => j.strOrNull('media_asset_id');
  String? get url => j.strOrNull('url');
  String? get fileName => j.strOrNull('file_name');
  String? get mimeType => j.strOrNull('mime_type');
  int? get bytes => j.intOrNull('bytes');
  Json? get preview => (j['preview'] as Map?)?.cast<String, dynamic>();
  bool get verified => j.strOrNull('verified_at') != null;
  bool get isLink => provider == 'external';
  bool get published => (linkStatus ?? 'published') == 'published';
}

class Assignment {
  const Assignment(this.j);
  final Json j;
  String get id => j.str('id');
  String get courseId => j.str('course_id');
  String? get lessonId => j.strOrNull('lesson_id');
  String get title => j.strOrNull('title') ?? '';
  String? get instructions => j.strOrNull('instructions');
  List<String> get submissionTypes => j.strList('submission_types');
  int get maxFiles => j.integer('max_files', fallback: 5);
  double? get maxScore => j.numOrNull('max_score');
  DateTime? get dueAt => j.dateOrNull('due_at');
  bool get published => j.strOrNull('status') == 'published';
}

class SubmissionFile {
  const SubmissionFile(this.j);
  final Json j;
  String get mediaAssetId => j.str('media_asset_id');
  String get fileName => j.strOrNull('file_name') ?? 'file';
  String? get mimeType => j.strOrNull('mime_type');
  String get kind => j.strOrNull('kind') ?? 'document';
}

class Submission {
  const Submission(this.j);
  final Json j;
  String get id => j.str('id');
  String get assignmentId => j.str('assignment_id');
  String get status => j.strOrNull('status') ?? 'submitted';
  String? get learner => j.strOrNull('learner');
  String? get assignmentTitle => j.strOrNull('assignment_title');
  String? get lessonTitle => j.strOrNull('lesson_title');
  String? get courseTitle => j.strOrNull('course_title');
  String? get text => j.strOrNull('text_answer');
  String? get feedback => j.strOrNull('feedback');
  double? get score => j.numOrNull('score');
  String? get reviewer => j.strOrNull('reviewer');
  int get attempt => j.integer('attempt', fallback: 1);
  DateTime? get submittedAt => j.dateOrNull('submitted_at');
  DateTime? get reviewedAt => j.dateOrNull('reviewed_at');
  List<SubmissionFile> get files => [
    for (final f in (j['files'] as List? ?? const []))
      SubmissionFile(Map<String, dynamic>.from(f as Map)),
  ];
  bool get awaitingTeacher =>
      status == 'submitted' || status == 'received' || status == 'under_review';
  bool get canResubmit =>
      status == 'resubmission_requested' || status == 'returned';
}

class ContentRepository {
  ContentRepository(this.api);
  final PostgresApi api;

  Future<List<Language>> languages() async => (await api.select(
    'languages',
    filters: {'is_active': Pg.eq(true)},
    order: 'position.asc',
  )).map(Language.fromJson).toList();

  Future<List<LearningTrack>> tracks() async => (await api.select(
    'learning_tracks',
    order: 'position.asc',
  )).map(LearningTrack.fromJson).toList();

  // ------------------------------------------------------------ resources --

  static String _column(ResourceTarget t) => switch (t) {
    ResourceTarget.course => 'course_id',
    ResourceTarget.unit => 'unit_id',
    ResourceTarget.book => 'book_id',
    ResourceTarget.node => 'node_id',
    ResourceTarget.lesson => 'lesson_id',
    ResourceTarget.assignment => 'assignment_id',
  };

  /// Resources attached to one course, unit, lesson… in display order.
  Future<List<Resource>> resourcesFor(ResourceTarget target, String id) async {
    final links = await api.select(
      'resource_links',
      filters: {_column(target): Pg.eq(id)},
      order: 'position.asc',
    );
    if (links.isEmpty) return const [];
    final rows = await api.select(
      'resources',
      filters: {
        'id': Pg.inList([for (final l in links) l['resource_id'] as String]),
      },
    );
    final byId = {for (final r in rows) r['id'] as String: r};
    return [
      for (final l in links)
        if (byId[l['resource_id']] case final r?)
          Resource(
            r,
            linkId: l['id'] as String,
            linkStatus: l['status'] as String?,
          ),
    ];
  }

  /// Creates a resource and attaches it.
  Future<String> addResource({
    required ResourceTarget target,
    required String targetId,
    required Json values,
    required String uploaderId,
    int position = 0,
  }) async {
    final row = (await api.insert('resources', {
      ...values,
      'uploaded_by': uploaderId,
    })).first;
    final id = row['id'] as String;
    await api.insert('resource_links', {
      'resource_id': id,
      _column(target): targetId,
      'position': position,
    });
    return id;
  }

  Future<void> updateResource(String id, Json values) =>
      api.update('resources', values, filters: {'id': Pg.eq(id)});

  Future<void> setLinkStatus(String linkId, bool published) => api.update(
    'resource_links',
    {'status': published ? 'published' : 'draft'},
    filters: {'id': Pg.eq(linkId)},
  );

  Future<void> detach(String linkId) =>
      api.delete('resource_links', filters: {'id': Pg.eq(linkId)});

  Future<void> reorderLinks(List<String> linkIds) async {
    for (final (i, id) in linkIds.indexed) {
      await api.update(
        'resource_links',
        {'position': i},
        filters: {'id': Pg.eq(id)},
      );
    }
  }

  /// A signed URL for an uploaded file the caller may open.
  Future<String> mediaUrl(String assetId) async =>
      (await api.rpc('media_url', params: {'p_asset_id': assetId})) as String;

  // ---------------------------------------------------------- assignments --

  Future<List<Assignment>> assignmentsForLesson(String lessonId) async =>
      (await api.select(
        'assignments',
        filters: {'lesson_id': Pg.eq(lessonId)},
        order: 'position.asc',
      )).map(Assignment.new).toList();

  Future<void> saveAssignment(Json values, {String? id}) async {
    if (id == null) {
      await api.insert('assignments', values);
    } else {
      await api.update('assignments', values, filters: {'id': Pg.eq(id)});
    }
  }

  Future<void> deleteAssignment(String id) =>
      api.delete('assignments', filters: {'id': Pg.eq(id)});

  // ---------------------------------------------------------- submissions --

  Future<Submission> submitWork({
    required String submissionId,
    required String assignmentId,
    String? text,
    List<Json> files = const [],
  }) async {
    final res = await api.rpc(
      'submit_work',
      params: {
        'p_submission_id': submissionId,
        'p_assignment_id': assignmentId,
        'p_text': ?text,
        'p_files': files,
      },
    );
    return Submission(Map<String, dynamic>.from(res as Map));
  }

  Future<List<Submission>> mySubmissions(String assignmentId) async => [
    for (final r in await api.rpcRows(
      'my_submissions',
      params: {'p_assignment_id': assignmentId},
    ))
      Submission(_unwrap(r, 'my_submissions')),
  ];

  Future<List<Submission>> teacherSubmissions({
    String? courseId,
    String? lessonId,
    String? status,
  }) async => [
    for (final r in await api.rpcRows(
      'teacher_submissions',
      params: {
        'p_course_id': ?courseId,
        'p_lesson_id': ?lessonId,
        'p_status': ?status,
        'p_limit': 100,
      },
    ))
      Submission(_unwrap(r, 'teacher_submissions')),
  ];

  Future<Submission> review(
    String submissionId,
    String status, {
    String? feedback,
    double? score,
  }) async {
    final res = await api.rpc(
      'review_submission',
      params: {
        'p_submission_id': submissionId,
        'p_status': status,
        'p_feedback': ?feedback,
        'p_score': ?score,
      },
    );
    return Submission(Map<String, dynamic>.from(res as Map));
  }

  // ------------------------------------------------------ lesson moves --

  Future<void> moveLesson(String lessonId, {String? unitId, String? nodeId}) =>
      api.rpc(
        'move_lesson',
        params: {
          'p_lesson_id': lessonId,
          'p_unit_id': ?unitId,
          'p_node_id': ?nodeId,
        },
      );

  Future<String> copyLesson(
    String lessonId,
    String courseId, {
    String? unitId,
  }) async {
    final res = await api.rpc(
      'copy_lesson',
      params: {
        'p_lesson_id': lessonId,
        'p_course_id': courseId,
        'p_unit_id': ?unitId,
      },
    );
    return (res as Map)['id'] as String;
  }

  Future<void> setPrerequisites(String courseId, List<String> requires) async {
    await api.delete(
      'course_prerequisites',
      filters: {'course_id': Pg.eq(courseId)},
    );
    for (final r in requires) {
      await api.insert('course_prerequisites', {
        'course_id': courseId,
        'requires_course_id': r,
      });
    }
  }

  Future<List<String>> prerequisites(String courseId) async => [
    for (final r in await api.select(
      'course_prerequisites',
      filters: {'course_id': Pg.eq(courseId)},
    ))
      r['requires_course_id'] as String,
  ];

  static Json _unwrap(Json row, String fn) =>
      Map<String, dynamic>.from((row[fn] ?? row) as Map);
}

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(ref.watch(postgresApiProvider)),
);

final languagesProvider = FutureProvider<List<Language>>(
  (ref) => ref.watch(contentRepositoryProvider).languages(),
);

final tracksProvider = FutureProvider<List<LearningTrack>>(
  (ref) => ref.watch(contentRepositoryProvider).tracks(),
);

/// Display name of a language code (falls back to the code).
String languageName(List<Language>? all, String code) =>
    all?.where((l) => l.code == code).firstOrNull?.name ?? code;
