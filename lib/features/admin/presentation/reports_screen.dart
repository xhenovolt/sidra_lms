import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';

final _reportsProvider = FutureProvider.autoDispose.family<Json, int>((
  ref,
  days,
) async {
  final res = await ref
      .watch(postgresApiProvider)
      .rpc('admin_reports', params: {'p_days': days});
  return Map<String, dynamic>.from(res! as Map);
});

List<Json> _list(Json j, String k) => [
  for (final e in (j[k] as List? ?? const []))
    Map<String, dynamic>.from(e as Map),
];

/// Course completion, learner activity, teacher activity.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = ref.watch(_reportsProvider(_days));
    final date = DateFormat.yMMMd(l10n.localeName);

    Widget stat(String label, Object? value, String question) => SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${value ?? '—'}', style: theme.textTheme.headlineSmall),
              Text(label, style: theme.textTheme.labelLarge),
              Text(question, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );

    Widget heading(String title, String question) => Padding(
      padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          Text(question, style: theme.textTheme.bodySmall),
        ],
      ),
    );

    return RefreshIndicator(
      onRefresh: () => ref.refresh(_reportsProvider(_days).future),
      child: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          SegmentedButton<int>(
            segments: [
              for (final d in [7, 30, 90])
                ButtonSegment(value: d, label: Text(l10n.analyticsDays(d))),
            ],
            selected: {_days},
            onSelectionChanged: (s) => setState(() => _days = s.first),
          ),
          switch (data) {
            AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Space.md),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    stat(
                      l10n.repLearners,
                      value['totals']?['learners'],
                      l10n.repLearnersQ,
                    ),
                    stat(
                      l10n.repActive,
                      value['totals']?['active'],
                      l10n.repActiveQ,
                    ),
                    stat(l10n.repNew, value['totals']?['new'], l10n.repNewQ),
                    stat(
                      l10n.repCompletions,
                      value['totals']?['completions'],
                      l10n.repCompletionsQ,
                    ),
                  ],
                ),
                heading(l10n.repCourses, l10n.repCoursesQ),
                for (final c in _list(value, 'courses'))
                  Card(
                    child: ListTile(
                      title: Text('${c['title']}'),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: Space.xxs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: ((c['avg_progress'] as num?) ?? 0) / 100,
                            ),
                            const SizedBox(height: Space.xxs),
                            Text(
                              l10n.repCourseLine(
                                (c['enrolled'] as num?)?.toInt() ?? 0,
                                (c['completed'] as num?)?.toInt() ?? 0,
                                (c['avg_progress'] as num?)?.toInt() ?? 0,
                                (c['active'] as num?)?.toInt() ?? 0,
                                (c['stalled'] as num?)?.toInt() ?? 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () => context.push('/teach/courses/${c['id']}'),
                    ),
                  ),
                heading(l10n.repQuiet, l10n.repQuietQ(_days)),
                if (_list(value, 'inactive_learners').isEmpty)
                  Text(l10n.anNone, style: theme.textTheme.bodySmall)
                else
                  for (final q in _list(value, 'inactive_learners'))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bedtime_outlined),
                      title: Text('${q['name'] ?? '—'}'),
                      subtitle: Text(
                        [
                          '${q['course']}',
                          if (q['progress'] != null) '${q['progress']}%',
                          q['last_activity'] == null
                              ? l10n.repNeverStarted
                              : l10n.repLastSeen(
                                  date.format(
                                    DateTime.parse('${q['last_activity']}')
                                        .toLocal(),
                                  ),
                                ),
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push('/teach/people/${q['user_id']}'),
                    ),
                heading(l10n.repTeachers, l10n.repTeachersQ),
                if (_list(value, 'teachers').isEmpty)
                  Text(l10n.anNone, style: theme.textTheme.bodySmall)
                else
                  for (final t in _list(value, 'teachers'))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.co_present_outlined),
                      title: Text('${t['name'] ?? '—'}'),
                      subtitle: Text(
                        [
                          l10n.repTeacherReviews(
                            (t['reviews'] as num?)?.toInt() ?? 0,
                          ),
                          if (t['avg_review_hours'] != null)
                            l10n.repTeacherTurnaround(
                              '${t['avg_review_hours']}',
                            ),
                          l10n.repTeacherWaiting(
                            (t['waiting'] as num?)?.toInt() ?? 0,
                          ),
                          t['last_sign_in'] == null
                              ? l10n.personNeverSignedIn
                              : l10n.personLastSignIn(
                                  date.format(
                                    DateTime.parse('${t['last_sign_in']}')
                                        .toLocal(),
                                  ),
                                ),
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push('/teach/people/${t['user_id']}'),
                    ),
              ],
            ),
            AsyncError(:final error) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(_reportsProvider(_days)),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(Space.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}
