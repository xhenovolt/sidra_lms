import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../curriculum/domain/curriculum_models.dart';
import 'course_widgets.dart';

/// Responsive grid of course cards (1 column on phones, more on tablets).
class _CourseGrid extends StatelessWidget {
  const _CourseGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = (c.maxWidth / 380).floor().clamp(1, 4);
        return GridView.builder(
          padding: const EdgeInsets.all(Space.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: Space.md,
            crossAxisSpacing: Space.md,
            mainAxisExtent: 300,
          ),
          itemCount: children.length,
          itemBuilder: (_, i) => children[i],
        );
      },
    );
  }
}

/// Explore tab: the published catalogue.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalogue = ref.watch(catalogueProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.exploreTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(catalogueProvider.future),
        child: switch (catalogue) {
          AsyncData(value: final List<Course> courses) when courses.isEmpty =>
            ListView(
              children: [
                EmptyView(
                  icon: Icons.explore_outlined,
                  title: l10n.exploreEmptyTitle,
                  message: l10n.exploreEmptyBody,
                ),
              ],
            ),
          AsyncData(value: final List<Course> courses) => _CourseGrid(
            children: [
              for (final c in courses)
                CourseCard(
                  course: c,
                  onTap: () => context.push(Routes.courseDetail(c.id)),
                ),
            ],
          ),
          AsyncError(:final error) => ListView(
            children: [
              ErrorView(
                error: error,
                onRetry: () => ref.invalidate(catalogueProvider),
              ),
            ],
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}

/// My Learning tab: enrolled courses with server-computed progress.
class MyLearningScreen extends ConsumerWidget {
  const MyLearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mine = ref.watch(myCoursesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMyLearning)),
      body: Column(
        children: [
          const SyncBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(myCoursesProvider.future),
              child: switch (mine) {
                AsyncData(:final value) when value.isEmpty => ListView(
                  children: [
                    EmptyView(
                      icon: Icons.menu_book_outlined,
                      title: l10n.myLearningEmptyTitle,
                      message: l10n.myLearningEmptyBody,
                      action: OutlinedButton(
                        onPressed: () => context.go(Routes.explore),
                        child: Text(l10n.exploreCourses),
                      ),
                    ),
                  ],
                ),
                AsyncData(:final value) => _CourseGrid(
                  children: [
                    for (final s in value)
                      _EnrolledCourseCard(
                        courseId: s.courseId,
                        percent: s.progressPercent,
                      ),
                  ],
                ),
                AsyncError(:final error) => ListView(
                  children: [
                    ErrorView(
                      error: error,
                      onRetry: () => ref.invalidate(myCoursesProvider),
                    ),
                  ],
                ),
                _ => const LoadingView(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrolledCourseCard extends ConsumerWidget {
  const _EnrolledCourseCard({required this.courseId, required this.percent});
  final String courseId;
  final int percent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(cachedCourseProvider(courseId)).value;
    if (course == null) return const Card(child: LoadingView());
    return CourseCard(
      course: course,
      progressPercent: percent,
      onTap: () => context.push(Routes.courseDetail(courseId)),
    );
  }
}
