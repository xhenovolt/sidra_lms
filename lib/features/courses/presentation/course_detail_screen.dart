import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/repository_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/settings/public_settings.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../curriculum/domain/curriculum_tree.dart';
import '../../content/data/content_repository.dart';
import '../../content/presentation/resource_widgets.dart';
import '../../downloads/presentation/download_button.dart';
import '../../payments/presentation/course_payment_card.dart';
import '../../progress/domain/progress_models.dart';
import '../data/course_repository.dart';
import 'course_widgets.dart';
import 'outline_view.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final outline = ref.watch(courseOutlineProvider(courseId));
    return Scaffold(
      appBar: AppBar(
        title: Text(outline.value?.course.title ?? l10n.courseTitle),
      ),
      body: switch (outline) {
        AsyncData(:final value) => _CourseBody(outline: value),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(courseOutlineProvider(courseId)),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _CourseBody extends ConsumerStatefulWidget {
  const _CourseBody({required this.outline});
  final CourseOutline outline;

  @override
  ConsumerState<_CourseBody> createState() => _CourseBodyState();
}

class _CourseBodyState extends ConsumerState<_CourseBody> {
  bool _enrolling = false;

  Course get course => widget.outline.course;

  Future<void> _enrol() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _enrolling = true);
    try {
      final repo = await ref.read(courseRepositoryProvider.future);
      await repo.enrol(course.id);
      ref.invalidate(myCoursesProvider);
      ref.invalidate(courseOutlineProvider(course.id));
    } on AppFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is OfflineFailure ? l10n.offlineError : l10n.enrolFailed,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  void _openLesson(String lessonId) =>
      context.push(Routes.lessonDetail(course.id, lessonId));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final outline = widget.outline;
    final enrolment = ref
        .watch(myCoursesProvider)
        .value
        ?.where((s) => s.courseId == course.id)
        .firstOrNull;
    final progress =
        ref.watch(courseProgressProvider(course.id)).value ?? const {};
    final completed = {
      for (final e in progress.entries)
        if (e.value.isCompleted) e.key,
    };
    final tree = CurriculumTree.build(
      units: outline.units,
      nodes: outline.nodes,
      lessons: outline.lessons,
      order: outline.order,
      completedLessonIds: completed,
      levelLabels: outline.levelLabels,
    );
    final enrolled = enrolment?.isActive ?? false;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(courseProgressProvider(course.id));
        ref.invalidate(courseOutlineProvider(course.id));
        await ref.read(courseOutlineProvider(course.id).future);
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          CourseCover(course: course, height: 180),
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(course.title, style: theme.textTheme.headlineSmall),
                if (course.subtitle != null) ...[
                  const SizedBox(height: Space.xxs),
                  Text(
                    course.subtitle!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xs,
                  children: [
                    InfoChip(course.subject, icon: Icons.bookmark_outline),
                    InfoChip(course.difficultyLabel(l10n)),
                    InfoChip(
                      course.accessLabel(l10n),
                      emphasis: !course.isFree,
                    ),
                    InfoChip(l10n.lessonsCount(tree.orderedLessons.length)),
                    InfoChip(
                      l10n.taughtIn(
                        course.languages
                            .map(
                              (c) => languageName(
                                ref.watch(languagesProvider).value,
                                c,
                              ),
                            )
                            .join(', '),
                      ),
                      icon: Icons.translate,
                    ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                if (enrolled) ...[
                  ProgressLine(
                    percent: enrolment!.progressPercent,
                    label: l10n.percentComplete(enrolment.progressPercent),
                  ),
                  const SizedBox(height: Space.md),
                  _ContinueAction(
                    tree: tree,
                    summary: enrolment,
                    onOpen: _openLesson,
                  ),
                  const SizedBox(height: Space.sm),
                  DownloadCourseButton(courseId: course.id),
                ] else if (course.access == CourseAccess.paid)
                  CoursePaymentCard(
                    course: course,
                    onPaid: () {
                      ref.invalidate(myCoursesProvider);
                      ref.invalidate(courseOutlineProvider(course.id));
                    },
                  )
                else if (course.isFree && course.selfEnrol)
                  FilledButton.icon(
                    onPressed: _enrolling ? null : _enrol,
                    icon: _enrolling
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_enrolling ? l10n.enrolling : l10n.startCourse),
                  )
                else
                  _NoticeCard(
                    icon: Icons.verified_user_outlined,
                    title: l10n.accessRequiredTitle(orgFor(l10n)),
                    body: l10n.accessRequiredBody(orgFor(l10n)),
                  ),
                if (course.targetLearner != null) ...[
                  const SizedBox(height: Space.md),
                  Text(
                    l10n.courseForWhom(course.targetLearner!),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: Space.md),
                ResourceListView(target: ResourceTarget.course, id: course.id),
                if (course.description != null) ...[
                  const SizedBox(height: Space.lg),
                  Text(course.description!, style: theme.textTheme.bodyLarge),
                ],
                if (course.learningObjectives.isNotEmpty) ...[
                  const SizedBox(height: Space.lg),
                  Text(
                    l10n.learningObjectives,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: Space.xs),
                  for (final o in course.learningObjectives)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xxs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: Space.xs),
                          Expanded(child: Text(o)),
                        ],
                      ),
                    ),
                ],
                if (course.prerequisites != null) ...[
                  const SizedBox(height: Space.lg),
                  Text(
                    l10n.prerequisitesTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(course.prerequisites!),
                ],
                if (outline.books.isNotEmpty) ...[
                  const SizedBox(height: Space.lg),
                  Text(l10n.booksTitle, style: theme.textTheme.titleMedium),
                  for (final b in outline.books)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(b.title),
                      subtitle: b.author == null ? null : Text(b.author!),
                    ),
                ],
                const SizedBox(height: Space.lg),
                Text(l10n.courseOutline, style: theme.textTheme.titleMedium),
                OutlineView(
                  items: tree.items,
                  onOpenLesson: (i) => _openLesson(i.lesson.id),
                  onLockedLesson: (_) =>
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            enrolled
                                ? l10n.lockedLessonBody
                                : l10n.notEnrolledLessonBody,
                          ),
                        ),
                      ),
                ),
                const SizedBox(height: Space.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueAction extends StatelessWidget {
  const _ContinueAction({
    required this.tree,
    required this.summary,
    required this.onOpen,
  });

  final CurriculumTree tree;
  final CourseProgressSummary summary;
  final void Function(String lessonId) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final next = summary.nextLessonId;
    if (next != null) {
      return FilledButton.icon(
        onPressed: () => onOpen(next),
        icon: const Icon(Icons.play_arrow),
        label: Text(l10n.continueAction),
      );
    }
    if (summary.awaitingTeacher) {
      return _NoticeCard(
        icon: Icons.hourglass_top_rounded,
        title: l10n.awaitingTeacherTitle,
        body: l10n.awaitingTeacherBody,
      );
    }
    return const SizedBox.shrink();
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: Space.xxs),
                  Text(body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
