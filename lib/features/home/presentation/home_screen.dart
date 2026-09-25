import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../courses/presentation/course_widgets.dart';
import '../../progress/domain/progress_models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.now});

  /// Injectable clock for tests.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authSessionProvider).user;
    final name = user?.firstName ?? l10n.learnerFallbackName;
    final hour = (now ?? DateTime.now)().hour;
    final greeting = hour < 12
        ? l10n.greetingMorning(name)
        : hour < 17
        ? l10n.greetingAfternoon(name)
        : l10n.greetingEvening(name);
    final mine = ref.watch(myCoursesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SyncBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(myCoursesProvider.future),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        Space.lg,
                        Space.lg,
                        Space.lg,
                        Space.md,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          greeting,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                    ...switch (mine) {
                      AsyncData(:final value) when value.isEmpty => [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyView(
                            icon: Icons.auto_stories_outlined,
                            title: l10n.noEnrolmentsTitle,
                            message: l10n.noEnrolmentsBody,
                            action: FilledButton(
                              onPressed: () => context.go(Routes.explore),
                              child: Text(l10n.exploreCourses),
                            ),
                          ),
                        ),
                      ],
                      AsyncData(:final value) => _dashboard(context, value),
                      AsyncError(:final error) => [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: ErrorView(
                            error: error,
                            onRetry: () => ref.invalidate(myCoursesProvider),
                          ),
                        ),
                      ],
                      _ => [
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: LoadingView(),
                        ),
                      ],
                    },
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _dashboard(
    BuildContext context,
    List<CourseProgressSummary> courses,
  ) {
    final l10n = AppLocalizations.of(context);
    final resume = courses.where((c) => c.nextLessonId != null).firstOrNull;
    return [
      if (resume != null)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          sliver: SliverToBoxAdapter(child: _ContinueCard(summary: resume)),
        ),
      SliverPadding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Space.lg,
          Space.lg,
          Space.lg,
          Space.xs,
        ),
        sliver: SliverToBoxAdapter(
          child: Text(
            l10n.enrolledCourses,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
      SliverList.builder(
        itemCount: courses.length,
        itemBuilder: (context, i) => _CourseRow(summary: courses[i]),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
    ];
  }
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard({required this.summary});
  final CourseProgressSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final course = ref.watch(cachedCourseProvider(summary.courseId)).value;
    final outline = ref.watch(courseOutlineProvider(summary.courseId)).value;
    final next = outline?.lesson(summary.nextLessonId!);
    return Card(
      color: theme.colorScheme.primary,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () => context.push(
          Routes.lessonDetail(summary.courseId, summary.nextLessonId!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.continueWhereLeft,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                next?.title ?? course?.title ?? '…',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              if (next != null && course != null)
                Text(
                  course.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              const SizedBox(height: Space.md),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.pill),
                      child: LinearProgressIndicator(
                        value: summary.progressPercent / 100,
                        minHeight: 6,
                        color: theme.colorScheme.onPrimary,
                        backgroundColor: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Icon(
                    Icons.play_circle_fill,
                    color: theme.colorScheme.onPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseRow extends ConsumerWidget {
  const _CourseRow({required this.summary});
  final CourseProgressSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final course = ref.watch(cachedCourseProvider(summary.courseId)).value;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
      title: Text(course?.title ?? '…'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: Space.xs),
        child: ProgressLine(
          percent: summary.progressPercent,
          label: summary.awaitingTeacher
              ? l10n.lockedLessonTitle
              : l10n.percentComplete(summary.progressPercent),
        ),
      ),
      trailing: summary.awaitingTeacher
          ? const Icon(Icons.hourglass_top_rounded)
          : const Icon(Icons.chevron_right),
      onTap: () => context.push(Routes.courseDetail(summary.courseId)),
    );
  }
}
