import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';

/// My Learning tab — enrolled courses with progress (data wired in Phase 3).
class MyLearningScreen extends StatelessWidget {
  const MyLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMyLearning)),
      body: EmptyView(
        icon: Icons.menu_book_outlined,
        title: l10n.myLearningEmptyTitle,
        message: l10n.myLearningEmptyBody,
        action: OutlinedButton(
          onPressed: () => context.go(Routes.explore),
          child: Text(l10n.exploreCourses),
        ),
      ),
    );
  }
}

/// Explore tab — published course catalogue (data wired in Phase 3).
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.exploreTitle)),
      body: EmptyView(
        icon: Icons.explore_outlined,
        title: l10n.exploreEmptyTitle,
        message: l10n.exploreEmptyBody,
      ),
    );
  }
}

/// Course detail — structure rendered from curriculum nodes in Phase 3.
class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.courseTitle)),
      body: EmptyView(
        icon: Icons.construction_outlined,
        title: l10n.courseTitle,
        message: l10n.comingSoon,
      ),
    );
  }
}

/// Lesson reader — content blocks rendered in Phase 3.
class LessonScreen extends StatelessWidget {
  const LessonScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  final String courseId;
  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.lessonTitle)),
      body: EmptyView(
        icon: Icons.construction_outlined,
        title: l10n.lessonTitle,
        message: l10n.comingSoon,
      ),
    );
  }
}
