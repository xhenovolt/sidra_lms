import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_shell.dart';
import '../../features/admin/presentation/assessment_editor_screen.dart';
import '../../features/admin/presentation/books_people_tabs.dart';
import '../../features/admin/presentation/course_builder_screen.dart';
import '../../features/admin/presentation/courses_tab.dart';
import '../../features/admin/presentation/finance_screen.dart';
import '../../features/admin/presentation/learners_tab.dart';
import '../../features/admin/presentation/lesson_editor_screen.dart';
import '../../features/admin/presentation/people_tab.dart';
import '../../features/admin/presentation/person_profile_screen.dart';
import '../../features/admin/presentation/roles_audit_screens.dart';
import '../../features/admin/presentation/settings_screen.dart';
import '../../features/admin/presentation/staff_pages.dart';
import '../../features/assessments/presentation/quiz_screen.dart';
import '../../features/about/presentation/about_screen.dart';
import '../splash_screen.dart';
import '../../features/admin/presentation/reports_screen.dart';
import '../../features/content/presentation/assignment_widgets.dart';
import '../../features/teaching/data/lesson_work.dart';
import '../../features/teaching/presentation/learner_portion_screen.dart';
import '../../features/teaching/presentation/inbox_screen.dart';
import '../../features/teaching/presentation/lesson_work_widgets.dart';
import '../../features/teaching/presentation/library_screens.dart';
import '../../features/teaching/presentation/teacher_screens.dart';
import '../../features/teaching/presentation/work_issue_widgets.dart';
import '../../features/chat/chat_screens.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/courses/presentation/course_detail_screen.dart';
import '../../features/courses/presentation/tab_screens.dart';
import '../../features/curriculum/domain/curriculum_models.dart';
import '../../features/downloads/presentation/downloads_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/lessons/presentation/lesson_screen.dart';
import '../../features/onboarding/data/onboarding_controller.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../l10n/app_localizations.dart';
import 'app_shell.dart';
import 'routes.dart';
import 'learner_preview.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);
  final onboarding = ref.watch(onboardingControllerProvider);
  final preview = ref.watch(learnerPreviewProvider);
  final splashHold = ref.watch(splashHoldProvider);

  Widget titled(String Function(AppLocalizations) title, Widget child) =>
      Builder(
        builder: (context) =>
            StaffPage(title: title(AppLocalizations.of(context)), child: child),
      );

  final router = GoRouter(
    initialLocation: Routes.home,
    refreshListenable: Listenable.merge([
      auth,
      onboarding,
      preview,
      splashHold,
    ]),
    redirect: (context, state) => authRedirect(
      splashHold.holding ? AuthStatus.initializing : auth.session.status,
      state.matchedLocation,
      onboarded: onboarding.completed,
      mustChangePassword: auth.session.user?.mustChangePassword ?? false,
      // Previewing administrators get the learner's screens.
      role: preview.on && auth.session.user?.role == 'admin'
          ? 'learner'
          : auth.session.user?.role,
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpScreen()),
      GoRoute(
        path: Routes.changePassword,
        builder: (_, _) => ChangePasswordScreen(
          forced: auth.session.user?.mustChangePassword ?? false,
        ),
      ),

      // ------------------------------------------------ learner navigation
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell, items: learnerNav),
        branches: [
          _branch(Routes.home, const HomeScreen()),
          _branch(Routes.myLearning, const MyLearningScreen()),
          _branch(Routes.explore, const ExploreScreen()),
          _branch(Routes.downloads, const DownloadsScreen()),
          _branch(Routes.profile, const ProfileScreen()),
        ],
      ),

      // ------------------------------------------------ teacher navigation
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell, items: teacherNav),
        branches: [
          _branch(
            Routes.teacherTeaching,
            Builder(
              builder: (context) => StaffPage(
                title: AppLocalizations.of(context).navTeaching,
                actions: const [NotificationBell()],
                child: const TeachingHomeScreen(),
              ),
            ),
          ),
          _branch(
            Routes.teacherLearners,
            titled((l) => l.adminTabLearners, const LearnersTab()),
          ),
          _branch(
            Routes.teacherCourses,
            titled(
              (l) => l.adminTabCourses,
              const CoursesTab(canCreate: false),
            ),
          ),
          _branch(Routes.teacherMore, const StaffMoreScreen()),
        ],
      ),

      // ---------------------------------------- admin console (drawer)
      ShellRoute(
        builder: (_, state, child) =>
            AdminShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: Routes.adminDashboard,
            builder: (_, _) => const OverviewTab(),
          ),
          GoRoute(
            path: Routes.adminCourses,
            builder: (_, _) => const CoursesTab(canCreate: true),
          ),
          GoRoute(path: Routes.adminBooks, builder: (_, _) => const BooksTab()),
          GoRoute(
            path: Routes.adminLearners,
            builder: (_, _) => const LearnersTab(),
          ),
          GoRoute(
            path: Routes.adminPeopleLearners,
            builder: (_, _) => const PeopleTab(persona: UserRole.learner),
          ),
          GoRoute(
            path: Routes.adminPeopleTeachers,
            builder: (_, _) => const PeopleTab(persona: UserRole.teacher),
          ),
          GoRoute(
            path: Routes.adminPeopleAdmins,
            builder: (_, _) => const PeopleTab(persona: UserRole.admin),
          ),
          GoRoute(
            path: Routes.adminRoles,
            builder: (_, _) => const RolesScreen(),
          ),
          GoRoute(
            path: Routes.adminAudit,
            builder: (_, _) => const AuditScreen(),
          ),
          GoRoute(
            path: Routes.adminTeaching,
            builder: (_, _) => const TeachingHomeScreen(),
          ),
          GoRoute(
            path: Routes.adminReports,
            builder: (_, _) => const ReportsScreen(),
          ),
          GoRoute(
            path: Routes.adminCorrections,
            builder: (_, _) => const CorrectionLibraryScreen(),
          ),
          GoRoute(
            path: Routes.adminLibrary,
            builder: (_, _) => const ContentLibraryScreen(),
          ),
          GoRoute(
            path: Routes.adminSubmissions,
            builder: (_, _) => const SubmissionsList(),
          ),
          GoRoute(
            path: Routes.adminFinance,
            builder: (_, _) => const FinanceScreen(),
          ),
          GoRoute(
            path: Routes.adminSettings,
            builder: (_, _) => const SettingsScreen(),
          ),
          GoRoute(
            path: Routes.adminMore,
            builder: (_, _) => const StaffMoreScreen(embedded: true),
          ),
        ],
      ),
      GoRoute(path: Routes.catalogue, builder: (_, _) => const ExploreScreen()),

      // --------------------------------------------------- shared screens
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
      GoRoute(
        path: Routes.quizPath,
        builder: (_, state) =>
            QuizScreen(assessmentId: state.pathParameters['assessmentId']!),
      ),

      // ------------------------------------------- staff editing screens
      GoRoute(
        path: '/teach/courses/new',
        builder: (_, _) => const CourseFormScreen(),
      ),
      GoRoute(
        path: '/teach/courses/:courseId',
        builder: (_, state) =>
            CourseBuilderScreen(courseId: state.pathParameters['courseId']!),
      ),
      GoRoute(
        path: '/teach/courses/:courseId/edit',
        builder: (_, state) => CourseFormScreen(course: state.extra as Course?),
      ),
      GoRoute(
        path: '/teach/lessons/:lessonId',
        builder: (_, state) =>
            LessonEditorScreen(lessonId: state.pathParameters['lessonId']!),
      ),
      GoRoute(
        path: Routes.teachSubmissions,
        builder: (_, _) => const SubmissionsScreen(),
      ),
      GoRoute(path: Routes.about, builder: (_, _) => const AboutScreen()),
      GoRoute(
        path: Routes.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/learn/issues',
        builder: (_, _) => const MyWorkIssuesScreen(),
      ),
      GoRoute(
        path: '/learn/portions/:portionId',
        builder: (_, state) =>
            LearnerPortionScreen(portionId: state.pathParameters['portionId']!),
      ),
      GoRoute(
        path: '/teach/groups/:groupId',
        builder: (_, state) =>
            GroupScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/teach/portions/new',
        builder: (_, state) => PortionEditorScreen(
          groupId: state.uri.queryParameters['group'],
          courseId: state.uri.queryParameters['course'],
        ),
      ),
      GoRoute(
        path: '/teach/portions/:portionId',
        builder: (_, state) =>
            PortionBoardScreen(portionId: state.pathParameters['portionId']!),
      ),
      GoRoute(
        path: '/teach/portions/:portionId/edit',
        builder: (_, state) =>
            PortionEditorScreen(portionId: state.pathParameters['portionId']!),
      ),
      GoRoute(
        path: '/teach/inbox',
        builder: (_, _) => const TeacherInboxScreen(),
      ),
      GoRoute(path: '/chats', builder: (_, _) => const ChatsScreen()),
      GoRoute(
        path: '/chats/:conversationId',
        builder: (_, state) =>
            ChatScreen(conversationId: state.pathParameters['conversationId']!),
      ),
      GoRoute(
        path: '/teach/issues',
        builder: (_, _) => const TeacherIssuesScreen(),
      ),
      GoRoute(
        path: '/teach/late',
        builder: (context, _) => LateWorkScreen(
          canRunNow:
              ProviderScope.containerOf(context)
                  .read(authSessionProvider)
                  .user
                  ?.role ==
              'admin',
        ),
      ),
      GoRoute(
        path: '/teach/submissions/:submissionId',
        builder: (_, state) => AssignmentWorkScreen(
          submissionId: state.pathParameters['submissionId']!,
        ),
      ),
      GoRoute(
        path: '/teach/work',
        builder: (_, _) => const LessonWorkQueueScreen(),
      ),
      GoRoute(
        path: '/teach/work/:submissionId',
        builder: (_, state) => LessonWorkReviewScreen(
          submissionId: state.pathParameters['submissionId']!,
          work: state.extra is LessonWork ? state.extra! as LessonWork : null,
        ),
      ),
      GoRoute(
        path: '/teach/corrections',
        builder: (_, _) => const CorrectionLibraryScreen(),
      ),
      GoRoute(
        path: '/teach/audio',
        builder: (_, _) => const AudioLibraryScreen(),
      ),
      GoRoute(
        path: '/teach/analytics',
        builder: (_, _) => const TeachingAnalyticsScreen(),
      ),
      GoRoute(
        path: '/teach/people/:userId',
        builder: (_, state) =>
            PersonProfileScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: '/teach/assessments/:assessmentId',
        builder: (_, state) => AssessmentEditorScreen(
          assessmentId: state.pathParameters['assessmentId']!,
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

/// Which roles may open a location (navigation RBAC). PostgreSQL still
/// authorises every action; this keeps each role in its own app.
bool roleAllows(String? role, String location) {
  final staff = role == 'teacher' || role == 'admin';
  if (location.startsWith('/admin/')) return role == 'admin';
  if (location.startsWith('/teacher/')) return role == 'teacher';
  if (location.startsWith('/teach/')) return staff;
  if (location == Routes.catalogue) return staff;
  if (Routes.learnerTabs.contains(location)) return !staff;
  return true; // shared: course/lesson/quiz views, change password
}

/// Pure redirect rule, unit-tested in isolation.
///
/// Order: restore session → first-launch onboarding → sign-in/up → the
/// signed-in person's own home (by role). A person whose password was
/// reset by staff must choose a new one before anything else.
String? authRedirect(
  AuthStatus status,
  String location, {
  required bool onboarded,
  bool mustChangePassword = false,
  String? role,
}) {
  String? to(String target) => location == target ? null : target;
  return switch (status) {
    AuthStatus.initializing => to(Routes.splash),
    AuthStatus.signedOut =>
      !onboarded
          ? to(Routes.onboarding)
          : (location == Routes.signIn || location == Routes.signUp)
          ? null
          : Routes.signIn,
    AuthStatus.signedIn =>
      mustChangePassword
          ? to(Routes.changePassword)
          : Routes.public.contains(location) || !roleAllows(role, location)
          ? Routes.homeFor(role)
          : null,
  };
}
