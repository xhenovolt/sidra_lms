import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/courses/presentation/tab_screens.dart';
import '../../features/downloads/presentation/downloads_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/data/onboarding_controller.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../shared/widgets/state_views.dart';
import 'app_shell.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);
  final onboarding = ref.watch(onboardingControllerProvider);
  final router = GoRouter(
    initialLocation: Routes.home,
    refreshListenable: Listenable.merge([auth, onboarding]),
    redirect: (context, state) => authRedirect(
      auth.session.status,
      state.matchedLocation,
      onboarded: onboarding.completed,
    ),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) => const Scaffold(body: LoadingView()),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          _branch(Routes.home, const HomeScreen()),
          _branch(Routes.myLearning, const MyLearningScreen()),
          _branch(Routes.explore, const ExploreScreen()),
          _branch(Routes.downloads, const DownloadsScreen()),
          _branch(Routes.profile, const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: Routes.course,
        builder: (_, state) =>
            CourseDetailScreen(courseId: state.pathParameters['courseId']!),
      ),
      GoRoute(
        path: Routes.lesson,
        builder: (_, state) => LessonScreen(
          courseId: state.pathParameters['courseId']!,
          lessonId: state.pathParameters['lessonId']!,
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => screen)],
);

/// Pure redirect rule, unit-tested in isolation.
///
/// Order: restore session → first-launch onboarding → sign-in → app.
/// Signed-in learners never see onboarding again.
String? authRedirect(
  AuthStatus status,
  String location, {
  required bool onboarded,
}) {
  String? to(String target) => location == target ? null : target;
  return switch (status) {
    AuthStatus.initializing => to(Routes.splash),
    AuthStatus.signedOut =>
      onboarded ? to(Routes.signIn) : to(Routes.onboarding),
    AuthStatus.signedIn =>
      Routes.public.contains(location) ? Routes.home : null,
  };
}
