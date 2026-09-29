import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../../content/data/content_repository.dart';
import '../data/admin_repository.dart';
import 'admin_common.dart';
import 'people_tab.dart';
import 'sessions_screens.dart';
import '../../../shared/widgets/user_avatar.dart';

final personProfileProvider = FutureProvider.autoDispose
    .family<PersonProfile, String>(
      (ref, userId) => ref.watch(adminRepositoryProvider).personProfile(userId),
    );

/// One person's record: who they are, their courses and progress, what
/// they teach, teacher reviews, quiz results and recent activity. Actions
/// (edit, role, reset password, access, disable) open from the app bar.
class PersonProfileScreen extends ConsumerWidget {
  const PersonProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(personProfileProvider(userId));
    return Scaffold(
      appBar: AppBar(
        title: Text(profile.value?.user.name ?? l10n.personTitle),
        actions: [
          if (profile.value case final p?)
            TextButton.icon(
              onPressed: () async {
                final result = await showModalBottomSheet<Object?>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => PersonSheet(person: p.user),
                );
                if (result == 'deleted') {
                  if (context.mounted) Navigator.of(context).pop();
                  return;
                }
                ref.invalidate(personProfileProvider(userId));
              },
              icon: const Icon(Icons.more_horiz),
              label: Text(l10n.personActions),
            ),
        ],
      ),
      body: switch (profile) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(personProfileProvider(userId).future),
          child: _Profile(profile: value),
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(personProfileProvider(userId)),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile({required this.profile});
  final PersonProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = profile.user;
    final date = DateFormat.yMMMd(l10n.localeName);
    String when(DateTime? d) => d == null ? '—' : date.format(d.toLocal());

    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      avatarUrl: profile.avatarUrl,
                      name: user.name,
                      radius: 28,
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: theme.textTheme.titleLarge),
                          Text(
                            profile.roles.isNotEmpty
                                ? profile.roles.join(', ')
                                : roleLabel(
                                    l10n,
                                    user.role,
                                    superadmin: user.isSuperadmin,
                                  ),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!user.isActive)
                      Chip(
                        label: Text(l10n.adminDisabled),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: Space.sm),
                if (user.phone != null)
                  _Line(Icons.phone_outlined, user.phone!),
                if (user.email != null)
                  _Line(Icons.email_outlined, user.email!),
                if (user.username != null)
                  _Line(Icons.alternate_email, user.username!),
                _Line(
                  Icons.event_outlined,
                  l10n.personJoined(when(user.createdAt)),
                ),
                _Line(
                  Icons.login,
                  profile.lastSignIn == null
                      ? l10n.personNeverSignedIn
                      : l10n.personLastSignIn(when(profile.lastSignIn)),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: Text(l10n.devicesTitle),
            subtitle: Text(l10n.devicesPersonHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DevicesScreen(userId: user.id, name: user.name),
              ),
            ),
          ),
        ),
        if (profile.teaching.isNotEmpty || user.role.name != 'learner') ...[
          _Heading(l10n.personTeaching),
          _TeachingLanguages(userId: user.id, languages: profile.languages),
          if (profile.teaching.isEmpty)
            _Empty(l10n.personNoTeaching)
          else
            for (final t in profile.teaching)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.co_present_outlined),
                  title: Text(t.courseTitle),
                  subtitle: Text(
                    [
                      if (t.units.isEmpty)
                        l10n.staffWholeCourse
                      else
                        l10n.staffTeachesUnits(t.units.join(', ')),
                      l10n.personLearnerCount(t.learners),
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/teach/courses/${t.courseId}'),
                ),
              ),
        ],
        _Heading(l10n.personCourses),
        if (profile.enrolments.isEmpty)
          _Empty(l10n.personNoCourses)
        else
          for (final e in profile.enrolments)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.courseTitle,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          enrolmentStatusLabel(l10n, e.status),
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xs),
                    LinearProgressIndicator(value: e.progress),
                    const SizedBox(height: Space.xs),
                    Text(
                      [
                        l10n.personLessonsDone(
                          e.completedLessons,
                          e.totalLessons,
                        ),
                        _sourceLabel(l10n, e.source),
                        if (e.lastActivity != null)
                          l10n.personLastActive(when(e.lastActivity)),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
        if (user.role.name == 'learner' || profile.reviews.isNotEmpty) ...[
          _Heading(l10n.personReviews),
          if (profile.reviews.isEmpty)
            _Empty(l10n.personNoReviews)
          else
            for (final r in profile.reviews)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  r['outcome'] == 'passed'
                      ? Icons.check_circle_outline
                      : Icons.replay,
                  color: r['outcome'] == 'passed'
                      ? theme.colorScheme.primary
                      : theme.colorScheme.tertiary,
                ),
                title: Text('${r['lesson_title']} · ${r['course_title']}'),
                subtitle: Text(
                  [
                    r['outcome'] == 'passed'
                        ? l10n.reviewPassed
                        : l10n.reviewNeedsRevision,
                    if (r['teacher'] != null) r['teacher'] as String,
                    when(r.dateOrNull('created_at')),
                    if ((r['feedback'] as String?)?.isNotEmpty ?? false)
                      '“${r['feedback']}”',
                  ].join(' · '),
                ),
              ),
        ],
        if (profile.quizAttempts.isNotEmpty) ...[
          _Heading(l10n.personQuizzes),
          for (final q in profile.quizAttempts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.quiz_outlined),
              title: Text(q['assessment_title'] as String),
              subtitle: Text(
                [
                  if (q['status'] != 'graded' && q['score'] == null)
                    l10n.personQuizPending
                  else
                    '${_num(q['score'])} / ${_num(q['max_score'])}',
                  if (q['passed'] == true) l10n.reviewPassed,
                  when(q.dateOrNull('submitted_at')),
                ].join(' · '),
              ),
            ),
        ],
        if (profile.activity case final activity?) ...[
          _Heading(l10n.personActivity),
          if (activity.isEmpty)
            _Empty(l10n.auditEmpty)
          else
            for (final a in activity)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, size: 20),
                title: Text(a['action'] as String),
                subtitle: Text(
                  [
                    ?a['actor'] as String?,
                    DateFormat.yMMMd(l10n.localeName)
                        .add_jm()
                        .format(a.dateOrNull('at')!.toLocal()),
                  ].join(' · '),
                ),
              ),
        ],
        const SizedBox(height: Space.xxl),
      ],
    );
  }
}

String _num(Object? v) => switch (v) {
  num n when n == n.roundToDouble() => n.toInt().toString(),
  num n => n.toStringAsFixed(1),
  _ => '—',
};

String _sourceLabel(AppLocalizations l10n, String s) => switch (s) {
  'self_free' => l10n.sourceSelf,
  'admin_grant' => l10n.sourceStaff,
  'payment' => l10n.sourcePayment,
  _ => s,
};

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.xs, Space.lg, Space.xs, Space.xs),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Space.xs),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// The languages a teacher teaches in, editable.
class _TeachingLanguages extends ConsumerWidget {
  const _TeachingLanguages({required this.userId, required this.languages});
  final String userId;
  final List<String> languages;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final all = await ref.read(languagesProvider.future);
    if (!context.mounted) return;
    final chosen = {...languages};
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.personTeachesIn),
          content: Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final l in all)
                FilterChip(
                  label: Text(l.name),
                  selected: chosen.contains(l.code),
                  onSelected: (v) => setState(
                    () => v ? chosen.add(l.code) : chosen.remove(l.code),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.adminCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.adminSave),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    if (await runAdminAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .setLanguages(userId, chosen.toList()),
      success: l10n.adminSaved,
    )) {
      ref.invalidate(personProfileProvider(userId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final langs = ref.watch(languagesProvider).value;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.translate),
        title: Text(l10n.personTeachesIn),
        subtitle: Text(
          languages.isEmpty
              ? l10n.personTeachesInNone
              : languages.map((c) => languageName(langs, c)).join(', '),
        ),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => _edit(context, ref),
      ),
    );
  }
}
