import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../curriculum/domain/curriculum_models.dart';
import 'course_browsing.dart';
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

/// Explore tab: the published catalogue — top courses (most enrolled) in
/// a carousel, then every course as a grid or a list.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalogue = ref.watch(catalogueProvider);
    final grid = ref.watch(courseLayoutProvider('catalogue'));
    final top = ref.watch(topCoursesProvider).value ?? const [];
    void open(Course c) => context.push(Routes.courseDetail(c.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exploreTitle),
        actions: const [CourseLayoutToggle(screen: 'catalogue')],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(topCoursesProvider);
          ref.invalidate(catalogueProvider);
          await ref.read(catalogueProvider.future);
        },
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
          AsyncData(value: final List<Course> courses) => LayoutBuilder(
            builder: (context, box) {
              final byId = {for (final c in courses) c.id: c};
              final featured = [
                for (final (id, n) in top)
                  if (byId[id] case final c?) (c, n),
              ];
              return CustomScrollView(
                slivers: [
                  if (featured.isNotEmpty)
                    SliverToBoxAdapter(
                      child: TopCoursesCarousel(
                        courses: featured,
                        onOpen: open,
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.md,
                      Space.md,
                      Space.md,
                      Space.xs,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        l10n.allCourses,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.md,
                      0,
                      Space.md,
                      Space.xl,
                    ),
                    sliver: grid
                        ? SliverGrid.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: courseGridColumns(
                                    box.maxWidth,
                                  ),
                                  mainAxisSpacing: Space.sm,
                                  crossAxisSpacing: Space.sm,
                                  mainAxisExtent: 200,
                                ),
                            itemCount: courses.length,
                            itemBuilder: (_, i) => CourseTile(
                              course: courses[i],
                              onTap: () => open(courses[i]),
                            ),
                          )
                        : SliverList.separated(
                            itemCount: courses.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: Space.sm),
                            itemBuilder: (_, i) => CourseCard(
                              course: courses[i],
                              onTap: () => open(courses[i]),
                            ),
                          ),
                  ),
                ],
              );
            },
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
