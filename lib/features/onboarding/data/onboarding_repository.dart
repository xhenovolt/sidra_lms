import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/network/postgres_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';

/// What the server found for one row before anything is written.
class PreviewRow {
  const PreviewRow(this.j);
  final Json j;
  int get row => j.integer('row', fallback: 0);
  String get name => j.strOrNull('name') ?? '';
  String? get phone => j.strOrNull('phone');
  String? get rawPhone => j.strOrNull('raw_phone');
  String? get email => j.strOrNull('email');

  /// new | existing | possible_duplicate | repeated | invalid
  String get status => j.strOrNull('status') ?? 'invalid';
  List<String> get reasons => j.strList('reasons');
  List<Json> get matches => [
    for (final m in (j['matches'] as List? ?? const []))
      Map<String, dynamic>.from(m as Map),
  ];
}

/// One learner's place in a course ({"kind":"unknown"} included).
typedef Position = Map<String, dynamic>;

String positionLabel(AppLocalizations l10n, Position? p) {
  if (p == null || p['kind'] == 'unknown') return l10n.obPositionUnknown;
  int? n(String k) => (p[k] as num?)?.toInt();
  final label = p['label'] as String?;
  return switch (p['kind']) {
    'page_line' => n('line') == null
        ? l10n.targetPage(n('page') ?? 0)
        : l10n.targetPageLine(n('page') ?? 0, n('line')!),
    'ayah' => n('ayah_end') != null && n('ayah_end') != n('ayah_start')
        ? l10n.targetAyahRange(n('surah') ?? 0, n('ayah_start') ?? 0, n('ayah_end')!)
        : l10n.targetAyah(n('surah') ?? 0, n('ayah_start') ?? 0),
    'exercise' => '${p['exercise'] ?? ''}',
    'lesson' => label ?? l10n.obPositionLesson,
    _ => label ?? l10n.obPositionUnknown,
  };
}

String learnerStatusLabel(AppLocalizations l10n, String? s) => switch (s) {
  'not_started' => l10n.obStatusNotStarted,
  'in_progress' => l10n.obStatusInProgress,
  'correction_required' => l10n.obStatusCorrection,
  'completed' => l10n.obStatusCompleted,
  _ => l10n.obStatusUnknown,
};

String sourceLabel(AppLocalizations l10n, String? s) => switch (s) {
  'whatsapp' => 'WhatsApp',
  'contacts' => l10n.obSourceContacts,
  'csv' => 'CSV',
  'excel' => 'Excel',
  'manual' => l10n.obSourceManual,
  'other_lms' => l10n.obSourceOtherLms,
  'api' => 'API',
  _ => 'Sidra',
};

class OnboardingRepository {
  OnboardingRepository(this.api);
  final PostgresApi api;

  Future<List<PreviewRow>> preview(
    List<Map<String, Object?>> rows, {
    String? courseId,
  }) async => [
    for (final r in await api.rpcRows(
      'onboarding_preview',
      params: {'p_rows': rows, 'p_course_id': courseId},
    ))
      PreviewRow(Map<String, dynamic>.from((r['onboarding_preview'] ?? r) as Map)),
  ];

  Future<Json> onboard(Map<String, Object?> options, List<Map<String, Object?>> rows) async =>
      Map<String, dynamic>.from(
        await api.rpc('onboard_learners', params: {'p_options': options, 'p_rows': rows}) as Map,
      );

  Future<List<Json>> history() async => [
    for (final r in await api.rpcRows('import_history', params: {'p_limit': 100}))
      Map<String, dynamic>.from((r['import_history'] ?? r) as Map),
  ];

  Future<List<Json>> batchItems(String batchId) async => [
    for (final r in await api.rpcRows('import_batch_items', params: {'p_batch_id': batchId}))
      Map<String, dynamic>.from((r['import_batch_items'] ?? r) as Map),
  ];

  Future<Json> rollback(String batchId) async => Map<String, dynamic>.from(
    await api.rpc('rollback_import', params: {'p_batch_id': batchId, 'p_confirm': 'UNDO'}) as Map,
  );

  Future<Json> issueInvitation(String userId) async => Map<String, dynamic>.from(
    await api.rpc('issue_invitation', params: {'p_user_id': userId}) as Map,
  );

  Future<List<Json>> board(String courseId, {String? groupId}) async => [
    for (final r in await api.rpcRows(
      'migration_board',
      params: {'p_course_id': courseId, 'p_group_id': groupId},
    ))
      Map<String, dynamic>.from((r['migration_board'] ?? r) as Map),
  ];

  Future<List<Json>> continuity({String? userId, String? courseId}) async => [
    for (final r in await api.rpcRows(
      'learner_continuity',
      params: {'p_user_id': userId, 'p_course_id': courseId},
    ))
      Map<String, dynamic>.from((r['learner_continuity'] ?? r) as Map),
  ];

  Future<void> setPositions(String courseId, List<Map<String, Object?>> entries) =>
      api.rpc('set_learner_positions', params: {'p_course_id': courseId, 'p_entries': entries});

  Future<void> addAttachment({
    required String userId,
    required String? courseId,
    required String mediaAssetId,
    String? title,
    String source = 'whatsapp',
    DateTime? originalDate,
    String? note,
  }) => api.rpc(
    'add_migration_attachment',
    params: {
      'p_user_id': userId,
      'p_course_id': courseId,
      'p_media_asset_id': mediaAssetId,
      'p_title': title,
      'p_source': source,
      'p_original_date': originalDate?.toIso8601String().substring(0, 10),
      'p_note': note,
    },
  );

  /// Teaching groups of a course (to add the imported learners to).
  Future<List<Json>> groups(String courseId) async => [
    for (final r in await api.select(
      'teaching_groups',
      filters: {'course_id': 'eq.$courseId', 'archived_at': 'is.null'},
    ))
      Map<String, dynamic>.from(r),
  ];
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(postgresApiProvider)),
);

/// "Where did this learner stop?" — per course (learner = null: me).
final continuityProvider = FutureProvider.autoDispose
    .family<List<Json>, ({String? userId, String? courseId})>(
      (ref, k) => ref
          .watch(onboardingRepositoryProvider)
          .continuity(userId: k.userId, courseId: k.courseId),
    );
