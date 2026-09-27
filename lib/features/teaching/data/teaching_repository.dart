import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/cache_first.dart';
import '../../../core/data/data_providers.dart';
import '../../../core/network/postgres_api.dart';
import '../../../shared/models/json.dart';

// ------------------------------------------------------------- states --

/// A learner's standing on one portion (mirrors participation_status).
enum Participation {
  assigned,
  opened,
  submitted,
  underReview,
  correctionRequired,
  completed,
}

/// A teacher's verdict (mirrors review_result).
enum ReviewResult {
  excellent,
  correct,
  minorCorrection,
  correctionRequired,
  needsExplanation;

  bool get passed =>
      this == excellent || this == correct || this == minorCorrection;
}

Participation participationOf(String? s) =>
    enumByName(Participation.values, s, Participation.assigned);
ReviewResult? reviewResultOf(String? s) =>
    s == null ? null : enumByName(ReviewResult.values, s, ReviewResult.correct);

// ------------------------------------------------------------- models --

class PortionResource {
  const PortionResource(this.j);
  final Json j;
  String get id => j.str('id');
  String get role => j.strOrNull('role') ?? 'other';
  String get kind => j.strOrNull('kind') ?? 'other';
  String get title => j.strOrNull('title') ?? '';
  String? get mediaAssetId => j.strOrNull('media_asset_id');
  String? get url => j.strOrNull('url');
}

class Review {
  const Review(this.j);
  final Json j;
  ReviewResult get result => reviewResultOf(j.strOrNull('result'))!;
  String? get feedback => j.strOrNull('feedback');
  String? get reviewer => j.strOrNull('reviewer');
  DateTime? get at => j.dateOrNull('created_at');
  String? get correctionAssetId => j.strOrNull('correction_asset_id');
  Json? get correction => (j['correction'] as Map?)?.cast<String, dynamic>();
}

class Attempt {
  const Attempt(this.j);
  final Json j;
  String get id => j.str('id');
  int get number => j.integer('attempt', fallback: 1);
  DateTime? get submittedAt => j.dateOrNull('submitted_at');
  String? get text => j.strOrNull('text');
  List<Json> get files => [
    for (final f in (j['files'] as List? ?? const []))
      Map<String, dynamic>.from(f as Map),
  ];
  List<Review> get reviews => [
    for (final r in (j['reviews'] as List? ?? const []))
      Review(Map<String, dynamic>.from(r as Map)),
  ];
  Review? get latestReview => reviews.firstOrNull;
}

/// A teaching portion as one learner sees it (learner_today / open_portion).
class LearnerPortion {
  const LearnerPortion(this.j);
  final Json j;
  String get id => j.str('id');
  String get title => j.str('title');
  String? get instructions => j.strOrNull('instructions');
  String? get instructionLanguage => j.strOrNull('instruction_language');
  String? get courseTitle => j.strOrNull('course_title');
  String? get courseLanguage => j.strOrNull('course_language');
  String? get groupName => j.strOrNull('group_name');
  List<String> get submissionTypes => j.strList('submission_types');
  DateTime? get assignedAt => j.dateOrNull('assigned_at');
  List<PortionResource> get resources => [
    for (final r in (j['resources'] as List? ?? const []))
      PortionResource(Map<String, dynamic>.from(r as Map)),
  ];
  Iterable<PortionResource> withRole(String role) =>
      resources.where((r) => r.role == role);
  Participation get status =>
      participationOf((j['participation'] as Map?)?['status'] as String?);
  List<Attempt> get attempts => [
    for (final a in (j['attempts'] as List? ?? const []))
      Attempt(Map<String, dynamic>.from(a as Map)),
  ];
  Review? get latestReview => attempts.firstOrNull?.latestReview;

  /// The learner may record / hand in now.
  bool get canSubmit =>
      status == Participation.assigned ||
      status == Participation.opened ||
      status == Participation.correctionRequired;
}

class TeachingGroup {
  const TeachingGroup(this.j);
  final Json j;
  String get id => j.str('id');
  String get name => j.str('name');
  String get courseId => j.str('course_id');
  String get courseTitle => j.strOrNull('course_title') ?? '';
  int get learners => j.integer('learners', fallback: 0);
  int get waiting => j.integer('waiting', fallback: 0);
  Json? get latestPortion =>
      (j['latest_portion'] as Map?)?.cast<String, dynamic>();
}

/// One learner's row on a portion's review board.
class BoardRow {
  const BoardRow(this.j);
  final Json j;
  String get userId => j.str('user_id');
  String get name => j.strOrNull('name') ?? '—';
  Participation get status => participationOf(j.strOrNull('status'));
  ReviewResult? get lastResult => reviewResultOf(j.strOrNull('last_result'));
  int get attempts => j.integer('attempts', fallback: 0);
  Json? get latest => (j['latest'] as Map?)?.cast<String, dynamic>();
  String? get latestSubmissionId => latest?['id'] as String?;
  List<Json> get latestFiles => [
    for (final f in (latest?['files'] as List? ?? const []))
      Map<String, dynamic>.from(f as Map),
  ];
  bool get waiting =>
      status == Participation.submitted || status == Participation.underReview;
}

class PortionBoard {
  const PortionBoard(this.portion, this.rows);
  final Json portion;
  final List<BoardRow> rows;
  String get title => portion['title'] as String? ?? '';
  List<PortionResource> get resources => [
    for (final r in (portion['resources'] as List? ?? const []))
      PortionResource(Map<String, dynamic>.from(r as Map)),
  ];
}

class Correction {
  const Correction(this.j);
  final Json j;
  String get id => j.str('id');
  String get title => j.str('title');
  String? get explanation => j.strOrNull('explanation');
  String? get category => j.strOrNull('category');
  String? get parentCategory => j.strOrNull('parent_category');
  String? get mediaAssetId => j.strOrNull('media_asset_id');
  List<String> get tags => j.strList('tags');
  int get useCount => j.integer('use_count', fallback: 0);
  String? get createdBy => j.strOrNull('created_by');
}

class CorrectionCategory {
  const CorrectionCategory(this.id, this.name, this.parentId, this.position);
  factory CorrectionCategory.fromJson(Json j) => CorrectionCategory(
    j.str('id'),
    j.str('name'),
    j.strOrNull('parent_id'),
    j.integer('position', fallback: 0),
  );
  final String id;
  final String name;
  final String? parentId;
  final int position;
}

class AppNotification {
  const AppNotification(this.j);
  final Json j;
  String get id => j.str('id');
  String get kind => j.str('kind');
  String get title => j.str('title');
  String? get body => j.strOrNull('body');
  DateTime? get at => j.dateOrNull('created_at');
  bool get read => j.strOrNull('read_at') != null;
  String? get portionId => (j['data'] as Map?)?['portion_id'] as String?;
}

// --------------------------------------------------------- repository --

class TeachingRepository {
  TeachingRepository(this.api);
  final PostgresApi api;

  static Json _map(Object? v) => Map<String, dynamic>.from(v! as Map);
  static List<Json> _set(List<Json> rows, String fn) => [
    for (final r in rows) Map<String, dynamic>.from((r[fn] ?? r) as Map),
  ];

  // learners
  Future<List<LearnerPortion>> today() async => _set(
    await api.rpcRows('learner_today'),
    'learner_today',
  ).map(LearnerPortion.new).toList();

  Future<LearnerPortion> open(String portionId) async => LearnerPortion(
    _map(await api.rpc('open_portion', params: {'p_portion_id': portionId})),
  );

  Future<Json> submit({
    required String submissionId,
    required String portionId,
    String? text,
    List<Json> files = const [],
  }) async => _map(
    await api.rpc(
      'submit_portion',
      params: {
        'p_submission_id': submissionId,
        'p_portion_id': portionId,
        'p_text': ?text,
        'p_files': files,
      },
    ),
  );

  // teachers
  Future<List<TeachingGroup>> myGroups() async => _set(
    await api.rpcRows('my_teaching_groups'),
    'my_teaching_groups',
  ).map(TeachingGroup.new).toList();

  Future<Json> saveGroup({
    required String courseId,
    required String name,
    required List<String> learnerIds,
    String? groupId,
  }) async => _map(
    await api.rpc(
      'save_teaching_group',
      params: {
        'p_course_id': courseId,
        'p_name': name,
        'p_learner_ids': learnerIds,
        'p_group_id': ?groupId,
      },
    ),
  );

  Future<List<Json>> groupMembers(String groupId) async {
    final members = await api.select(
      'teaching_group_members',
      filters: {'group_id': Pg.eq(groupId)},
    );
    if (members.isEmpty) return const [];
    return api.select(
      'users',
      columns: 'id,display_name,phone,username',
      filters: {
        'id': Pg.inList([for (final m in members) m['user_id'] as String]),
      },
      order: 'display_name.asc',
    );
  }

  Future<List<Json>> groupPortions(String groupId) => api.select(
    'teaching_portions',
    filters: {'group_id': Pg.eq(groupId)},
    order: 'sequence.desc',
    limit: 60,
  );

  Future<Json> savePortion({
    required String courseId,
    required String title,
    String? groupId,
    String? lessonId,
    String? instructions,
    String? instructionLanguage,
    List<String> submissionTypes = const ['audio'],
    String? portionId,
  }) async => _map(
    await api.rpc(
      'save_portion',
      params: {
        'p_course_id': courseId,
        'p_title': title,
        'p_group_id': ?groupId,
        'p_lesson_id': ?lessonId,
        'p_instructions': ?instructions,
        'p_instruction_language': ?instructionLanguage,
        'p_submission_types': submissionTypes,
        'p_portion_id': ?portionId,
      },
    ),
  );

  Future<void> setResource(
    String portionId,
    String resourceId,
    String role, {
    bool remove = false,
  }) => api.rpc(
    'set_portion_resource',
    params: {
      'p_portion_id': portionId,
      'p_resource_id': resourceId,
      'p_role': role,
      'p_remove': remove,
    },
  );

  /// Everyone in the group (null) or chosen learners. Returns how many
  /// learners received it.
  Future<int> assign(
    String portionId, {
    List<String>? userIds,
  }) async => int.parse(
    '${await api.rpc('assign_portion', params: {'p_portion_id': portionId, 'p_user_ids': ?userIds})}',
  );

  Future<Json> nextPortion(String previousId) async => _map(
    await api.rpc('next_portion', params: {'p_previous_id': previousId}),
  );

  Future<PortionBoard> board(String portionId) async {
    final res = _map(
      await api.rpc('portion_board', params: {'p_portion_id': portionId}),
    );
    return PortionBoard(Map<String, dynamic>.from(res['portion'] as Map), [
      for (final r in (res['learners'] as List? ?? const []))
        BoardRow(Map<String, dynamic>.from(r as Map)),
    ]);
  }

  Future<void> markUnderReview(String submissionId) =>
      api.rpc('mark_under_review', params: {'p_submission_id': submissionId});

  Future<Json> review({
    required String submissionId,
    required ReviewResult result,
    String? feedback,
    String? correctionId,
    String? correctionAssetId,
    Json? saveAs,
  }) async => _map(
    await api.rpc(
      'review_attempt',
      params: {
        'p_submission_id': submissionId,
        'p_result': enumToDb(result),
        'p_feedback': ?feedback,
        'p_correction_id': ?correctionId,
        'p_correction_asset_id': ?correctionAssetId,
        'p_save_as': ?saveAs,
      },
    ),
  );

  Future<Json> attention() async => _map(await api.rpc('teacher_attention'));

  Future<List<Correction>> searchCorrections({
    String? query,
    String? categoryId,
  }) async => _set(
    await api.rpcRows(
      'search_corrections',
      params: {
        if (query != null && query.trim().isNotEmpty) 'p_query': query.trim(),
        'p_category_id': ?categoryId,
      },
    ),
    'search_corrections',
  ).map(Correction.new).toList();

  Future<List<CorrectionCategory>> categories() async => (await api.select(
    'correction_categories',
    order: 'position.asc',
  )).map(CorrectionCategory.fromJson).toList();

  Future<Json> saveCorrection({
    required String title,
    String? mediaAssetId,
    String? explanation,
    String? categoryId,
    List<String> tags = const [],
  }) async => _map(
    await api.rpc(
      'save_correction',
      params: {
        'p_title': title,
        'p_media_asset_id': ?mediaAssetId,
        'p_explanation': ?explanation,
        'p_category_id': ?categoryId,
        'p_tags': tags,
      },
    ),
  );

  Future<void> saveCategory({
    required String name,
    String? parentId,
    String? id,
    int? position,
  }) async {
    if (id == null) {
      await api.insert('correction_categories', {
        'name': name,
        'parent_id': parentId,
        'position': ?position,
      });
    } else {
      await api.update(
        'correction_categories',
        {'name': name, 'position': ?position},
        filters: {'id': Pg.eq(id)},
      );
    }
  }

  /// Deleting a category keeps its corrections (they become uncategorised);
  /// its sub-categories are deleted with it.
  Future<void> deleteCategory(String id) =>
      api.delete('correction_categories', filters: {'id': Pg.eq(id)});

  Future<void> archiveCorrection(String id) => api.update(
    'corrections',
    {'archived_at': DateTime.now().toUtc().toIso8601String()},
    filters: {'id': Pg.eq(id)},
  );

  Future<void> addNote(String learnerId, String body, {String? courseId}) =>
      api.rpc(
        'add_teacher_note',
        params: {
          'p_learner_id': learnerId,
          'p_body': body,
          'p_course_id': ?courseId,
        },
      );

  Future<List<Json>> notes(String learnerId) async => _set(
    await api.rpcRows('learner_notes', params: {'p_learner_id': learnerId}),
    'learner_notes',
  );

  Future<Json> analytics({int days = 30}) async =>
      _map(await api.rpc('teaching_analytics', params: {'p_days': days}));

  Future<List<Json>> audioLibrary({String? query, bool mine = true}) async =>
      _set(
        await api.rpcRows(
          'audio_library',
          params: {
            if (query != null && query.trim().isNotEmpty)
              'p_query': query.trim(),
            'p_mine': mine,
          },
        ),
        'audio_library',
      );

  Future<List<Json>> contentLibrary({String? kind, String? query}) async =>
      _set(
        await api.rpcRows(
          'content_library',
          params: {
            'p_kind': ?kind,
            if (query != null && query.trim().isNotEmpty)
              'p_query': query.trim(),
          },
        ),
        'content_library',
      );

  // notifications
  Future<List<AppNotification>> notifications() async => [
    for (final r in await api.rpcRows('my_notifications')) AppNotification(r),
  ];

  Future<void> markRead({List<String>? ids}) =>
      api.rpc('mark_notifications_read', params: {'p_ids': ?ids});
}

final teachingRepositoryProvider = Provider<TeachingRepository>(
  (ref) => TeachingRepository(ref.watch(postgresApiProvider)),
);

final learnerTodayProvider = StreamProvider.autoDispose<List<LearnerPortion>>(
  (ref) => cacheFirst<List<LearnerPortion>>(
    ref,
    key: 'learner_today',
    fetch: () => ref.read(teachingRepositoryProvider).today(),
    encode: (v) => [for (final p in v) p.j],
    decode: (j) => [
      for (final p in j! as List)
        LearnerPortion(Map<String, dynamic>.from(p as Map)),
    ],
  ),
);

final myGroupsProvider = StreamProvider.autoDispose<List<TeachingGroup>>(
  (ref) => cacheFirst<List<TeachingGroup>>(
    ref,
    key: 'my_groups',
    fetch: () => ref.read(teachingRepositoryProvider).myGroups(),
    encode: (v) => [for (final g in v) g.j],
    decode: (j) => [
      for (final g in j! as List)
        TeachingGroup(Map<String, dynamic>.from(g as Map)),
    ],
  ),
);

final attentionProvider = StreamProvider.autoDispose<Json>(
  (ref) => cacheFirst<Json>(
    ref,
    key: 'teacher_attention',
    fetch: () => ref.read(teachingRepositoryProvider).attention(),
    encode: (v) => v,
    decode: (j) => Map<String, dynamic>.from(j! as Map),
  ),
);

final portionBoardProvider = FutureProvider.autoDispose
    .family<PortionBoard, String>(
      (ref, id) => ref.watch(teachingRepositoryProvider).board(id),
    );

final notificationsProvider = StreamProvider.autoDispose<List<AppNotification>>(
  (ref) => cacheFirst<List<AppNotification>>(
    ref,
    key: 'notifications',
    fetch: () => ref.read(teachingRepositoryProvider).notifications(),
    encode: (v) => [for (final n in v) n.j],
    decode: (j) => [
      for (final n in j! as List)
        AppNotification(Map<String, dynamic>.from(n as Map)),
    ],
  ),
);

final correctionCategoriesProvider =
    FutureProvider.autoDispose<List<CorrectionCategory>>(
      (ref) => ref.watch(teachingRepositoryProvider).categories(),
    );
