import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../courses/presentation/course_widgets.dart';
import '../data/admin_repository.dart';
import 'admin_common.dart';

final teacherLearnersProvider = FutureProvider.autoDispose<List<LearnerStatus>>(
  (ref) => ref.watch(adminRepositoryProvider).learners(),
);

final staffCoursesProvider = FutureProvider.autoDispose((ref) async {
  final courses = await ref.watch(adminRepositoryProvider).allCourses();
  return {for (final c in courses) c.id: c};
});

/// Teacher's queue: learners waiting for review first.
class LearnersTab extends ConsumerWidget {
  const LearnersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final learners = ref.watch(teacherLearnersProvider);
    final courses = ref.watch(staffCoursesProvider).value ?? const {};
    return RefreshIndicator(
      onRefresh: () => ref.refresh(teacherLearnersProvider.future),
      child: switch (learners) {
        AsyncData(:final value) when value.isEmpty => ListView(
          children: [
            EmptyView(
              icon: Icons.groups_outlined,
              title: l10n.adminNoLearnersTitle,
              message: l10n.adminNoLearnersBody,
            ),
          ],
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.only(bottom: Space.xl),
          children: [
            if (value.any((l) => l.awaitingReview))
              _Header(l10n.adminAwaitingReview),
            for (final l in value.where((l) => l.awaitingReview))
              _LearnerTile(learner: l, courseTitle: courses[l.courseId]?.title),
            if (value.any((l) => !l.awaitingReview))
              _Header(l10n.adminAllLearners),
            for (final l in value.where((l) => !l.awaitingReview))
              _LearnerTile(learner: l, courseTitle: courses[l.courseId]?.title),
          ],
        ),
        AsyncError(:final error) => ListView(
          children: [
            ErrorView(
              error: error,
              onRetry: () => ref.invalidate(teacherLearnersProvider),
            ),
          ],
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.md, Space.lg, Space.md, Space.xs),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _LearnerTile extends ConsumerWidget {
  const _LearnerTile({required this.learner, this.courseTitle});
  final LearnerStatus learner;
  final String? courseTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final percent = learner.totalLessons == 0
        ? 0
        : learner.completedLessons * 100 ~/ learner.totalLessons;
    return ListTile(
      leading: CircleAvatar(
        child: Text(learner.name.characters.first.toUpperCase()),
      ),
      title: Text(learner.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (courseTitle != null) Text(courseTitle!),
          if (learner.currentLessonTitle != null)
            Text(
              '${l10n.adminCurrentLesson}: ${learner.currentLessonTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: Space.xxs),
          ProgressLine(percent: percent),
        ],
      ),
      isThreeLine: true,
      trailing: learner.awaitingReview
          ? Icon(
              Icons.rate_review,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.chevron_right),
      onTap: learner.currentLessonId == null
          ? null
          : () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => ReviewSheet(learner: learner),
            ),
    );
  }
}

/// Teacher marks a learner's current lesson and (optionally) opens the next.
class ReviewSheet extends ConsumerStatefulWidget {
  const ReviewSheet({super.key, required this.learner});
  final LearnerStatus learner;

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  bool _passed = true;
  bool _unlockNext = true;
  double? _score;
  final _feedback = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    final ok = await runAdminAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .reviewLesson(
            userId: widget.learner.userId,
            lessonId: widget.learner.currentLessonId!,
            passed: _passed,
            score: _score,
            feedback: _feedback.text,
            unlockNext: _passed && _unlockNext,
          ),
      success: _passed && _unlockNext
          ? l10n.adminReviewSavedUnlocked
          : l10n.adminReviewSaved,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ref.invalidate(teacherLearnersProvider);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final l = widget.learner;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.lg,
        0,
        Space.lg,
        Space.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.name, style: theme.textTheme.titleLarge),
            Text(
              l.currentLessonTitle ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.lg),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.check),
                  label: Text(l10n.adminPassed),
                ),
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.replay),
                  label: Text(l10n.adminNeedsRevision),
                ),
              ],
              selected: {_passed},
              onSelectionChanged: (s) => setState(() => _passed = s.first),
            ),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Text(l10n.adminScore),
                Expanded(
                  child: Slider(
                    value: _score ?? 0,
                    max: 100,
                    divisions: 20,
                    label: _score == null ? '–' : '${_score!.round()}',
                    onChanged: (v) => setState(() => _score = v),
                  ),
                ),
                Text(_score == null ? '–' : '${_score!.round()}'),
              ],
            ),
            TextField(
              controller: _feedback,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(labelText: l10n.teacherFeedback),
            ),
            if (_passed && l.nextLessonId != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _unlockNext,
                onChanged: (v) => setState(() => _unlockNext = v),
                title: Text(l10n.adminOpenNextLesson),
              ),
            const SizedBox(height: Space.md),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.adminSaveReview),
            ),
          ],
        ),
      ),
    );
  }
}
