import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import 'teaching_repository.dart';

/// What an attempt or reply is about (0044 valid_work_target).
class WorkTarget {
  const WorkTarget(this.j);
  factory WorkTarget.whole() => const WorkTarget({'kind': 'whole'});
  factory WorkTarget.ayah(int surah, int from, [int? to, String? label]) =>
      WorkTarget({
        'kind': 'ayah',
        'surah': surah,
        'ayah_start': from,
        'ayah_end': to ?? from,
        'label': ?label,
      });
  factory WorkTarget.pageLine(int page, int? line, [int? lineEnd]) =>
      WorkTarget({
        'kind': 'page_line',
        'page': page,
        'line': ?line,
        'line_end': ?lineEnd,
      });
  factory WorkTarget.exercise(String name) =>
      WorkTarget({'kind': 'exercise', 'exercise': name});
  factory WorkTarget.block(
    String blockId,
    int start,
    int end,
    String quote, [
    String? label,
  ]) => WorkTarget({
    'kind': 'block',
    'block_id': blockId,
    'start': start,
    'end': end,
    'quote': quote.length > 1000 ? quote.substring(0, 1000) : quote,
    'label': ?label,
  });

  final Map<String, dynamic> j;
  String get kind => j['kind'] as String? ?? 'whole';
  bool get isWhole => kind == 'whole';

  /// "2:255", "2:255–257", "Page 14, line 3", "Question 4", "“…quote…”".
  String describe(AppLocalizations l10n) {
    int? n(String k) => (j[k] as num?)?.toInt();
    final label = j['label'] as String?;
    return switch (kind) {
      'ayah' => n('ayah_end') != null && n('ayah_end') != n('ayah_start')
          ? l10n.targetAyahRange(n('surah') ?? 0, n('ayah_start') ?? 0, n('ayah_end')!)
          : l10n.targetAyah(n('surah') ?? 0, n('ayah_start') ?? 0),
      'page_line' => n('line') == null
          ? l10n.targetPage(n('page') ?? 0)
          : n('line_end') != null && n('line_end') != n('line')
          ? l10n.targetPageLines(n('page') ?? 0, n('line')!, n('line_end')!)
          : l10n.targetPageLine(n('page') ?? 0, n('line')!),
      'exercise' => '${j['exercise'] ?? ''}',
      'block' => label ?? '“${j['quote'] ?? ''}”',
      'other' => label ?? l10n.targetOther,
      _ => l10n.targetWhole,
    };
  }
}

/// One thing in a work thread, oldest first.
sealed class WorkEvent {
  const WorkEvent(this.j);
  final Json j;
  DateTime? get at => j.dateOrNull('at');
  String get submissionId => j.str('submission_id');

  static WorkEvent fromJson(Json j) => switch (j['type']) {
    'attempt' => WorkAttempt(j),
    'review' => WorkVerdict(j),
    _ => WorkMessage(j),
  };
}

/// A learner's attempt: files, text, and what it was for.
class WorkAttempt extends WorkEvent {
  const WorkAttempt(super.j);
  int get number => j.integer('attempt', fallback: 1);
  String get status => j.strOrNull('status') ?? 'submitted';
  bool get superseded => status == 'superseded';
  bool get waiting =>
      status == 'submitted' || status == 'received' || status == 'under_review';
  String? get text => j.strOrNull('text');
  WorkTarget? get target => (j['target'] as Map?) == null
      ? null
      : WorkTarget((j['target'] as Map).cast<String, dynamic>());
  List<Json> get files => [
    for (final f in (j['files'] as List? ?? const []))
      Map<String, dynamic>.from(f as Map),
  ];
}

/// A teacher's verdict on an attempt.
class WorkVerdict extends WorkEvent {
  const WorkVerdict(super.j);
  ReviewResult get result => reviewResultOf(j.strOrNull('result'))!;
  String? get feedback => j.strOrNull('feedback');
  String? get author => j.strOrNull('author');
  String? get correctionAssetId => j.strOrNull('correction_asset_id');
  Json? get correction => (j['correction'] as Map?)?.cast<String, dynamic>();
}

/// A reply without a verdict: teacher's voice / text / file / library
/// correction, or the learner's answer.
class WorkMessage extends WorkEvent {
  const WorkMessage(super.j);
  bool get fromTeacher => j.strOrNull('author_role') == 'teacher';
  String? get author => j.strOrNull('author');
  String get kind => j.strOrNull('kind') ?? 'text';
  String? get body => j.strOrNull('body');
  String? get mediaAssetId => j.strOrNull('media_asset_id');
  String? get mediaKind => j.strOrNull('media_kind');
  Json? get correction => (j['correction'] as Map?)?.cast<String, dynamic>();
  WorkTarget? get target => (j['target'] as Map?) == null
      ? null
      : WorkTarget((j['target'] as Map).cast<String, dynamic>());
}

/// One learner's whole work on one portion / lesson / assignment.
class WorkThread {
  const WorkThread(this.j);
  final Json j;
  bool get asTeacher => j.strOrNull('role') == 'teacher';
  String get kind => j.str('kind');
  String get targetId => j.str('target_id');
  Json get learner => (j['learner'] as Map?)?.cast<String, dynamic>() ?? {};
  String get learnerId => '${learner['id'] ?? ''}';
  String get learnerName => '${learner['name'] ?? ''}';
  Participation? get participation => (j['participation'] as Map?) == null
      ? null
      : participationOf((j['participation'] as Map)['status'] as String?);
  List<WorkEvent> get events => [
    for (final e in (j['events'] as List? ?? const []))
      WorkEvent.fromJson(Map<String, dynamic>.from(e as Map)),
  ];
  List<WorkAttempt> get attempts => events.whereType<WorkAttempt>().toList();
  WorkAttempt? get latest => attempts.lastOrNull;

  /// The latest verdict on the latest attempt (null while waiting).
  WorkVerdict? get verdict {
    final l = latest;
    if (l == null) return null;
    return events
        .whereType<WorkVerdict>()
        .where((v) => v.submissionId == l.submissionId)
        .lastOrNull;
  }

  /// Accepted: nothing more to send.
  bool get completed =>
      participation == Participation.completed ||
      (participation == null && verdict != null && verdict!.result.passed);
}

typedef WorkKey = (String kind, String targetId, String? learnerId);

/// A thread by (kind, target id, learner) — learner null means "mine".
final workThreadProvider = FutureProvider.autoDispose.family<WorkThread, WorkKey>(
  (ref, k) async => WorkThread(
    Map<String, dynamic>.from(
      await ref
              .watch(postgresApiProvider)
              .rpc(
                'work_thread',
                params: {
                  'p_kind': k.$1,
                  'p_target_id': k.$2,
                  'p_user_id': k.$3,
                },
              )
          as Map,
    ),
  ),
);
