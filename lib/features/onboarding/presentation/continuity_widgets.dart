import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../media/presentation/media_viewer.dart';
import '../../teaching/presentation/learner_portion_screen.dart' show resultLabel;
import '../../teaching/data/teaching_repository.dart' show reviewResultOf;
import '../data/onboarding_repository.dart';
import 'onboarding_center.dart' show MigrationBoardScreen;

String _date(AppLocalizations l10n, Object? v) {
  final d = DateTime.tryParse('${v ?? ''}');
  return d == null ? '' : DateFormat.yMMMd(l10n.localeName).format(d.toLocal());
}

/// What the teacher should do next, from what Sidra knows (never invented).
String nextAction(AppLocalizations l10n, Json c) {
  final pos = (c['position'] as Map?)?.cast<String, dynamic>();
  final verdict = (c['last_verdict'] as Map?)?.cast<String, dynamic>();
  final where = positionLabel(l10n, pos);
  if (verdict?['result'] == 'correction_required') {
    final t = (verdict?['target'] as Map?)?.cast<String, dynamic>();
    return l10n.obNextRepeat(t == null ? where : positionLabel(l10n, t));
  }
  if (pos == null || pos['kind'] == 'unknown') return l10n.obNextConfirm;
  if (c['position_status'] == 'correction_required') return l10n.obNextRepeat(where);
  return l10n.obNextContinue(where);
}

/// Staff: "Where did this learner stop?" for each of their courses —
/// position, last portion / work / feedback, next step, where they came
/// from and any history brought along.
class WhereStoppedCard extends ConsumerWidget {
  const WhereStoppedCard({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = ref.watch(continuityProvider((userId: userId, courseId: null)));
    final list = data.value ?? const <Json>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.obWhereStopped, style: theme.textTheme.titleMedium),
        for (final c in list) _CourseContinuity(c: c, staff: true),
      ],
    );
  }
}

/// Learner, on a course page: continue where you left off.
class ContinueWhereLeftOffCard extends ConsumerWidget {
  const ContinueWhereLeftOffCard({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(continuityProvider((userId: null, courseId: courseId))).value?.firstOrNull;
    final pos = (c?['position'] as Map?)?.cast<String, dynamic>();
    if (c == null || pos == null || pos['kind'] == 'unknown') return const SizedBox.shrink();
    return _CourseContinuity(c: c, staff: false);
  }
}

class _CourseContinuity extends ConsumerWidget {
  const _CourseContinuity({required this.c, required this.staff});
  final Json c;
  final bool staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pos = (c['position'] as Map?)?.cast<String, dynamic>();
    final verdict = (c['last_verdict'] as Map?)?.cast<String, dynamic>();
    final portion = (c['last_portion'] as Map?)?.cast<String, dynamic>();
    final m = (c['migration'] as Map?)?.cast<String, dynamic>();
    final files = [for (final a in (c['attachments'] as List? ?? const [])) Map<String, dynamic>.from(a as Map)];
    Widget row(String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 130, child: Text(label, style: theme.textTheme.bodySmall)),
                Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
              ],
            ),
          );
    final unknown = pos == null || pos['kind'] == 'unknown';
    return Card(
      color: staff ? null : theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(staff ? Icons.place_outlined : Icons.play_circle_outline),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(
                    staff ? '${c['course_title'] ?? ''}' : l10n.obContinueTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (staff && c['course_id'] != null)
                  IconButton(
                    tooltip: l10n.obBoardTitle,
                    icon: const Icon(Icons.map_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MigrationBoardScreen(courseId: c['course_id'] as String),
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              unknown ? l10n.obPositionNeedsConfirm : positionLabel(l10n, pos),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: unknown ? theme.colorScheme.error : null,
              ),
            ),
            Text(learnerStatusLabel(l10n, c['position_status'] as String?), style: theme.textTheme.labelMedium),
            if (staff) ...[
              const SizedBox(height: Space.xs),
              row(l10n.obLastPortion, portion?['title'] as String?),
              row(l10n.obLastSubmission, _date(l10n, c['last_submission_at'])),
              row(
                l10n.obLastFeedback,
                verdict == null
                    ? (m?['last_feedback'] as String?)
                    : [
                        resultLabel(l10n, reviewResultOf(verdict['result'] as String?)!),
                        if (verdict['feedback'] case final String f) f,
                      ].join(' · '),
              ),
              row(l10n.obNextAction, nextAction(l10n, c)),
              if (m != null) ...[
                const Divider(),
                row(l10n.obMigrationSource, sourceLabel(l10n, m['source'] as String?)),
                row(l10n.obPrevGroup, m['previous_group'] as String?),
                row(l10n.obLastKnownOn, _date(l10n, m['last_known_on'])),
                row(l10n.obImported, [
                  _date(l10n, m['imported_at']),
                  ?m['imported_by_name'] as String?,
                ].join(' · ')),
                row(l10n.obNote, m['note'] as String?),
              ],
              for (final a in files)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history_edu_outlined),
                  title: Text('${a['title'] ?? l10n.wtAttachment}'),
                  subtitle: Text(l10n.obHistoricalFrom(
                    sourceLabel(l10n, a['source'] as String?),
                    _date(l10n, a['imported_at']),
                  )),
                  onTap: () => openInApp(
                    context,
                    assetId: a['media_asset_id'] as String,
                    kind: a['kind'] as String?,
                    fileName: a['title'] as String?,
                    title: '${a['title'] ?? ''}',
                  ),
                ),
            ] else if (verdict?['feedback'] != null || m?['last_feedback'] != null)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Text(l10n.teacherSays('${verdict?['feedback'] ?? m?['last_feedback']}')),
              ),
          ],
        ),
      ),
    );
  }
}
