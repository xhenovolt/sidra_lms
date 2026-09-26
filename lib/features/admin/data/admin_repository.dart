import 'package:dio/dio.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/postgres_api.dart';
import '../../../shared/models/json.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../profile/data/profile_repository.dart';

/// A row of `teacher_learners()`.
class LearnerStatus {
  const LearnerStatus({
    required this.courseId,
    required this.userId,
    required this.completedLessons,
    required this.totalLessons,
    required this.awaitingReview,
    this.displayName,
    this.email,
    this.currentLessonId,
    this.currentLessonTitle,
    this.currentLessonStatus,
    this.nextLessonId,
    this.lastActivityAt,
  });

  factory LearnerStatus.fromJson(Json j) => LearnerStatus(
    courseId: j.str('course_id'),
    userId: j.str('user_id'),
    displayName: j.strOrNull('display_name'),
    email: j.strOrNull('email'),
    currentLessonId: j.strOrNull('current_lesson_id'),
    currentLessonTitle: j.strOrNull('current_lesson_title'),
    currentLessonStatus: j.strOrNull('current_lesson_status'),
    nextLessonId: j.strOrNull('next_lesson_id'),
    completedLessons: j.integer('completed_lessons', fallback: 0),
    totalLessons: j.integer('total_lessons', fallback: 0),
    awaitingReview: j.boolean('awaiting_review'),
    lastActivityAt: j.dateOrNull('last_activity_at'),
  );

  final String courseId;
  final String userId;
  final String? displayName;
  final String? email;
  final String? currentLessonId;
  final String? currentLessonTitle;
  final String? currentLessonStatus;
  final String? nextLessonId;
  final int completedLessons;
  final int totalLessons;
  final bool awaitingReview;
  final DateTime? lastActivityAt;

  String get name => displayName ?? email ?? 'Learner';
}

class AppUserRow {
  const AppUserRow({
    required this.id,
    required this.role,
    this.displayName,
    this.phone,
    this.email,
    this.username,
    this.isSuperadmin = false,
    this.isActive = true,
  });

  factory AppUserRow.fromJson(Json j) => AppUserRow(
    id: j.str('id'),
    role: enumByName(UserRole.values, j.strOrNull('role'), UserRole.learner),
    displayName: j.strOrNull('display_name'),
    phone: j.strOrNull('phone'),
    email: j.strOrNull('email'),
    username: j.strOrNull('username'),
    isSuperadmin: j.boolean('is_superadmin'),
    isActive: j.boolean('is_active', fallback: true),
  );

  final String id;
  final UserRole role;
  final String? displayName;
  final String? phone;
  final String? email;
  final String? username;
  final bool isSuperadmin;
  final bool isActive;

  String get name =>
      displayName ?? username ?? phone ?? email ?? id.substring(0, 8);

  /// Phone, email or username, whichever exist.
  String get contact =>
      [?phone, ?email, if (username != null) '@$username'].join(' · ');
}

/// A role (a job in Sidra) and the permissions it grants.
class RoleRow {
  const RoleRow({
    required this.key,
    required this.name,
    required this.persona,
    required this.isSystem,
    required this.permissions,
    required this.members,
    this.description,
  });

  factory RoleRow.fromJson(Json j) => RoleRow(
    key: j.str('key'),
    name: j.str('name'),
    description: j.strOrNull('description'),
    persona: j.strOrNull('persona') ?? 'admin',
    isSystem: j.boolean('is_system'),
    permissions: j.strList('permissions').toSet(),
    members: j.integer('members', fallback: 0),
  );

  final String key;
  final String name;
  final String? description;

  /// Which app the role uses: admin console, teaching app or learner app.
  final String persona;
  final bool isSystem;
  final Set<String> permissions;
  final int members;
}

class PermissionRow {
  const PermissionRow(this.key, this.area, this.description);
  factory PermissionRow.fromJson(Json j) =>
      PermissionRow(j.str('key'), j.str('area'), j.str('description'));
  final String key;
  final String area;
  final String description;
}

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.at,
    required this.action,
    required this.entity,
    this.actorName,
    this.entityId,
    this.changes = const {},
  });

  factory AuditEntry.fromJson(Json j) => AuditEntry(
    id: j.integer('id'),
    at: j.dateOrNull('at') ?? DateTime.now(),
    actorName: j.strOrNull('actor_name'),
    action: j.str('action'),
    entity: j.str('entity'),
    entityId: j.strOrNull('entity_id'),
    changes: j.obj('changes'),
  );

  final int id;
  final DateTime at;
  final String? actorName;
  final String action;
  final String entity;
  final String? entityId;
  final Json changes;
}

/// A person on a course (learner enrolment or staff assignment).
class CoursePerson {
  const CoursePerson({
    required this.userId,
    required this.isStaff,
    required this.status,
    this.displayName,
    this.contact,
    this.enrolmentId,
  });

  factory CoursePerson.fromJson(Json j) => CoursePerson(
    userId: j.str('user_id'),
    displayName: j.strOrNull('display_name'),
    contact: j.strOrNull('contact'),
    isStaff: j.strOrNull('kind') == 'staff',
    status: j.strOrNull('status') ?? '',
    enrolmentId: j.strOrNull('enrolment_id'),
  );

  final String userId;
  final String? displayName;
  final String? contact;
  final bool isStaff;

  /// Enrolment status (learners) or staff role (teacher / editor).
  final String status;
  final String? enrolmentId;

  String get name => displayName ?? contact ?? '—';
}

/// Staff operations. Every call is re-authorised by PostgreSQL (RLS and
/// SECURITY DEFINER checks). The UI only decides what to OFFER.
/// Authoring requires a connection; it is deliberately not queued offline.
class AdminRepository {
  AdminRepository(this.api, {Dio? uploader}) : _uploader = uploader ?? Dio();

  final PostgresApi api;
  final Dio _uploader;

  // ------------------------------------------------------------ teaching --

  Future<List<LearnerStatus>> learners({String? courseId}) async {
    final rows = await api.rpcRows(
      'teacher_learners',
      params: {'p_course_id': courseId},
    );
    return rows.map(LearnerStatus.fromJson).toList();
  }

  Future<String?> reviewLesson({
    required String userId,
    required String lessonId,
    required bool passed,
    double? score,
    String? feedback,
    bool unlockNext = true,
  }) async {
    final r = await api.rpc(
      'review_lesson',
      params: {
        'p_user_id': userId,
        'p_lesson_id': lessonId,
        'p_outcome': passed ? 'passed' : 'needs_revision',
        'p_score': score,
        'p_feedback': (feedback?.trim().isEmpty ?? true) ? null : feedback,
        'p_unlock_next': unlockNext,
      },
    );
    return (r as Map)['unlocked_lesson_id'] as String?;
  }

  Future<void> unlockLesson(String userId, String lessonId, {String? note}) =>
      api.rpc(
        'unlock_lesson',
        params: {'p_user_id': userId, 'p_lesson_id': lessonId, 'p_note': note},
      );

  Future<void> revokeUnlock(String userId, String lessonId) => api.rpc(
    'revoke_lesson_unlock',
    params: {'p_user_id': userId, 'p_lesson_id': lessonId},
  );

  Future<List<Json>> pendingAttempts(String courseId) async {
    final assessments = await api.select(
      'assessments',
      columns: 'id,title,lesson_id',
      filters: {'course_id': Pg.eq(courseId)},
    );
    if (assessments.isEmpty) return const [];
    return api.select(
      'quiz_attempts',
      filters: {
        'assessment_id': Pg.inList([for (final a in assessments) a['id']]),
        'status': Pg.eq('submitted'),
      },
      order: 'submitted_at.asc',
    );
  }

  // ------------------------------------------------------------- courses --

  Future<List<Course>> allCourses() async => (await api.select(
    'courses',
    order: 'updated_at.desc',
  )).map(Course.fromJson).toList();

  Future<Course> saveCourse(Json values, {String? id}) async {
    final rows = id == null
        ? await api.insert('courses', values)
        : await api.update('courses', values, filters: {'id': Pg.eq(id)});
    if (rows.isEmpty) throw const ForbiddenFailure('Not allowed to edit');
    return Course.fromJson(rows.first);
  }

  /// Moves a course through draft → in review → published → archived.
  /// The database checks permissions and readiness.
  Future<void> setCourseStatus(
    String courseId,
    PublishStatus status, {
    String? note,
  }) => api.rpc(
    'set_course_status',
    params: {
      'p_course_id': courseId,
      'p_status': enumToDb(status),
      if (note != null && note.trim().isNotEmpty) 'p_note': note.trim(),
    },
  );

  Future<PublishCheck> publishCheck(String courseId) async {
    final res = await api.rpc(
      'course_publish_check',
      params: {'p_course_id': courseId},
    );
    return PublishCheck.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> deleteRow(String table, String id) =>
      api.delete(table, filters: {'id': Pg.eq(id)});

  /// Generic insert/update for curriculum tables (RLS: editors only).
  Future<Json> save(String table, Json values, {String? id}) async {
    final rows = id == null
        ? await api.insert(table, values)
        : await api.update(table, values, filters: {'id': Pg.eq(id)});
    if (rows.isEmpty) throw const ForbiddenFailure('Not allowed to edit');
    return rows.first;
  }

  Future<List<Json>> rows(
    String table, {
    Map<String, String> filters = const {},
    String? order = 'position.asc',
  }) => api.select(table, filters: filters, order: order);

  /// Rewrites sibling positions 0..n in the given order.
  Future<void> reorder(String table, List<String> idsInOrder) async {
    for (final (i, id) in idsInOrder.indexed) {
      await api.update(table, {'position': i}, filters: {'id': Pg.eq(id)});
    }
  }

  /// Swaps two rows' positions. Each API call is its own
  /// transaction, so for tables with UNIQUE (parent, position) a temporary
  /// position is used to avoid a transient duplicate.
  Future<void> swapPositions(
    String table,
    ({String id, int position}) a,
    ({String id, int position}) b,
  ) async {
    const temp = 1000000;
    await api.update(
      table,
      {'position': temp + a.position},
      filters: {'id': Pg.eq(a.id)},
    );
    await api.update(
      table,
      {'position': a.position},
      filters: {'id': Pg.eq(b.id)},
    );
    await api.update(
      table,
      {'position': b.position},
      filters: {'id': Pg.eq(a.id)},
    );
  }

  // --------------------------------------------------------------- books --

  Future<List<Book>> books() async => (await api.select(
    'books',
    order: 'title.asc',
  )).map(Book.fromJson).toList();

  /// Creates a structure from level definitions (depth order).
  Future<String> createStructure({
    required String bookId,
    required String name,
    required List<BookLevelDraft> levels,
    bool makeDefault = true,
  }) async {
    if (makeDefault) {
      await api.update(
        'book_structures',
        {'is_default': false},
        filters: {'book_id': Pg.eq(bookId), 'is_default': Pg.eq(true)},
      );
    }
    final s = (await api.insert('book_structures', {
      'book_id': bookId,
      'name': name,
      'is_default': makeDefault,
    })).first;
    final structureId = s['id'] as String;
    await api.insert('book_structure_levels', [
      for (final (i, l) in levels.indexed)
        {
          'structure_id': structureId,
          'depth': i + 1,
          'node_type': l.nodeType,
          'label_singular': l.singular,
          'label_plural': l.plural,
          'uses_page': l.usesPage,
          'uses_chapter': l.usesChapter,
          'uses_surah': l.usesSurah,
          'uses_verses': l.usesVerses,
        },
    ]);
    return structureId;
  }

  Future<List<BookStructureLevel>> levelsForBook(String bookId) async {
    final structures = await api.select(
      'book_structures',
      filters: {'book_id': Pg.eq(bookId)},
      order: 'is_default.desc',
    );
    if (structures.isEmpty) return const [];
    final levels = await api.select(
      'book_structure_levels',
      filters: {'structure_id': Pg.eq(structures.first['id'] as String)},
      order: 'depth.asc',
    );
    return levels.map(BookStructureLevel.fromJson).toList();
  }

  // -------------------------------------------------------------- people --

  /// Everyone (admins only), with contact details. [search] matches name,
  /// phone, email or username.
  Future<List<AppUserRow>> users({String? search}) async => (await api.rpcRows(
    'admin_list_users',
    params: {'p_search': ?search},
  )).map(AppUserRow.fromJson).toList();

  /// Creates an account with a temporary password (must change at first
  /// sign-in). Admins/superadmins can only be created by a superadmin.
  Future<void> createUser({
    required String displayName,
    required UserRole role,
    required String temporaryPassword,
    String? phone,
    String? email,
    String? username,
    bool superadmin = false,
  }) => api.rpc(
    'admin_create_user',
    params: {
      'p_display_name': displayName,
      'p_role': role.name,
      'p_temporary_password': temporaryPassword,
      'p_phone': phone,
      'p_email': email,
      'p_username': username,
      'p_superadmin': superadmin,
    },
  );

  Future<void> updateUser(
    String userId, {
    required String displayName,
    String? phone,
    String? email,
    String? username,
  }) => api.rpc(
    'admin_update_user',
    params: {
      'p_user_id': userId,
      'p_display_name': displayName,
      'p_phone': phone,
      'p_email': email,
      'p_username': username,
    },
  );

  Future<void> setActive(String userId, bool active) => api.rpc(
    'set_user_active',
    params: {'p_user_id': userId, 'p_active': active},
  );

  Future<void> setSuperadmin(String userId, bool value) => api.rpc(
    'set_superadmin',
    params: {'p_user_id': userId, 'p_superadmin': value},
  );

  Future<Json> overview() async =>
      Json.from((await api.rpc('admin_overview') as Map?) ?? const {});

  Future<List<CoursePerson>> coursePeople(String courseId) async =>
      (await api.rpcRows(
        'course_people',
        params: {'p_course_id': courseId},
      )).map(CoursePerson.fromJson).toList();

  Future<void> setEnrolmentStatus(String enrolmentId, String status) => api.rpc(
    'set_enrolment_status',
    params: {'p_enrolment_id': enrolmentId, 'p_status': status},
  );

  Future<void> removeStaff(String courseId, String userId) => api.delete(
    'course_staff',
    filters: {'course_id': Pg.eq(courseId), 'user_id': Pg.eq(userId)},
  );

  Future<void> setRole(String userId, UserRole role) => api.rpc(
    'set_user_role',
    params: {'p_user_id': userId, 'p_role': role.name},
  );

  /// Sets a temporary password; the learner must change it at sign-in.
  /// Teachers may reset learners in their courses, admins anyone.
  Future<void> resetPassword(String userId, String temporary) => api.rpc(
    'reset_password',
    params: {'p_user_id': userId, 'p_temporary': temporary},
  );

  Future<void> grantEnrolment(String userId, String courseId) => api.rpc(
    'grant_enrolment',
    params: {'p_user_id': userId, 'p_course_id': courseId},
  );

  Future<void> assignStaff(String courseId, String userId, String role) =>
      api.insert(
        'course_staff',
        {'course_id': courseId, 'user_id': userId, 'role': role},
        upsert: true,
        onConflict: 'course_id,user_id',
      );

  // ------------------------------------------------- roles & permissions --

  Future<Set<String>> myPermissions() async {
    final rows = await api.rpcRows('my_permissions');
    if (rows.isEmpty) return const {};
    return {
      for (final p in (rows.first['my_permissions'] as List? ?? const []))
        p as String,
    };
  }

  Future<List<RoleRow>> roles() async =>
      (await api.rpcRows('admin_roles')).map(RoleRow.fromJson).toList();

  Future<List<PermissionRow>> permissionCatalog() async =>
      (await api.rpcRows('admin_permissions'))
          .map(PermissionRow.fromJson)
          .toList();

  Future<void> saveRole({
    required String key,
    required String name,
    String? description,
    required Set<String> permissions,
  }) => api.rpc(
    'save_role',
    params: {
      'p_key': key,
      'p_name': name,
      'p_description': description,
      'p_permissions': permissions.toList(),
    },
  );

  Future<void> deleteRole(String key) =>
      api.rpc('delete_role', params: {'p_key': key});

  /// Gives a person exactly one role (their job).
  Future<void> setUserRole(String userId, String roleKey) => api.rpc(
    'set_user_primary_role',
    params: {'p_user_id': userId, 'p_role_key': roleKey},
  );

  Future<void> createUserWithRole({
    required String displayName,
    required String roleKey,
    required String temporaryPassword,
    String? phone,
    String? email,
    String? username,
  }) => api.rpc(
    'admin_create_user_with_role',
    params: {
      'p_display_name': displayName,
      'p_role_key': roleKey,
      'p_temporary_password': temporaryPassword,
      'p_phone': phone,
      'p_email': email,
      'p_username': username,
    },
  );

  Future<List<AuditEntry>> auditLog({String? entity, int? before}) async =>
      (await api.rpcRows(
        'admin_audit_log',
        params: {'p_entity': entity, 'p_before': before, 'p_limit': 50},
      )).map(AuditEntry.fromJson).toList();

  // --------------------------------------------------------------- media --

  /// Uploads a file to Cloudinary with a database-issued signature and
  /// registers it in `media_assets`. Returns the new asset id.
  Future<String> uploadMedia({
    required String filePath,
    required String fileName,
    required String kind, // image | audio | video | document
    required String uploaderId,
    String folder = 'content',
    String? title,
    void Function(int sent, int total)? onProgress,
  }) async {
    final sig = Json.from(
      await api.rpc('sign_media_upload', params: {'p_folder': folder}) as Map,
    );
    final resourceType = switch (kind) {
      'image' => 'image',
      'audio' || 'video' => 'video',
      _ => 'raw',
    };
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'api_key': sig['api_key'],
      'timestamp': sig['timestamp'],
      'signature': sig['signature'],
      'folder': sig['folder'],
      'type': sig['type'],
    });
    final Response<Map<String, dynamic>> res;
    try {
      res = await _uploader.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/${sig['cloud_name']}/$resourceType/upload',
        data: form,
        onSendProgress: onProgress,
      );
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? ((e.response!.data as Map)['error']?['message'] as String?)
          : null;
      throw ServerFailure(msg ?? 'Upload failed');
    }
    final c = res.data!;
    final row = (await api.insert('media_assets', {
      'kind': kind,
      'resource_type': c['resource_type'],
      'delivery': 'authenticated',
      'public_id': c['public_id'],
      'format': c['format'],
      'version': c['version'],
      'bytes': c['bytes'],
      'duration_seconds': c['duration'],
      'width': c['width'],
      'height': c['height'],
      'title': title ?? fileName,
      'uploaded_by': uploaderId,
    })).first;
    return row['id'] as String;
  }
}

/// A level in a book-structure template.
class BookLevelDraft {
  const BookLevelDraft(
    this.nodeType,
    this.singular,
    this.plural, {
    this.usesPage = false,
    this.usesChapter = false,
    this.usesSurah = false,
    this.usesVerses = false,
  });

  final String nodeType;
  final String singular;
  final String plural;
  final bool usesPage;
  final bool usesChapter;
  final bool usesSurah;
  final bool usesVerses;
}

/// Ready-made structures so admins pick instead of design. Lessons always
/// sit under the deepest level; "Custom" lets admins define their own.
const bookStructureTemplates = <String, List<BookLevelDraft>>{
  'Surah → Verse': [
    BookLevelDraft('surah', 'Surah', 'Surahs', usesSurah: true),
    BookLevelDraft('verse', 'Verse range', 'Verse ranges', usesVerses: true),
  ],
  'Page by page': [BookLevelDraft('page', 'Page', 'Pages', usesPage: true)],
  'Chapter → Section': [
    BookLevelDraft('chapter', 'Chapter', 'Chapters', usesChapter: true),
    BookLevelDraft('section', 'Section', 'Sections', usesPage: true),
  ],
  'Level → Unit → Chapter': [
    BookLevelDraft('level', 'Level', 'Levels'),
    BookLevelDraft('unit', 'Unit', 'Units'),
    BookLevelDraft('chapter', 'Chapter', 'Chapters', usesChapter: true),
  ],
  'Section → Topic': [
    BookLevelDraft('section', 'Section', 'Sections'),
    BookLevelDraft('topic', 'Topic', 'Topics', usesPage: true),
  ],
};
