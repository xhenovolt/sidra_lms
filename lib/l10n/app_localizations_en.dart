// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sidra';

  @override
  String get appTagline => 'Islamic learning by Almuntahha';

  @override
  String get navHome => 'Home';

  @override
  String get navMyLearning => 'My Learning';

  @override
  String get navExplore => 'Explore';

  @override
  String get navDownloads => 'Downloads';

  @override
  String get navProfile => 'Profile';

  @override
  String greetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get learnerFallbackName => 'learner';

  @override
  String get continueLearning => 'Continue learning';

  @override
  String get enrolledCourses => 'Your courses';

  @override
  String get noEnrolmentsTitle => 'Begin your journey';

  @override
  String get noEnrolmentsBody =>
      'You are not enrolled in any course yet. Explore the catalogue to find a course to start.';

  @override
  String get exploreCourses => 'Explore courses';

  @override
  String get myLearningEmptyTitle => 'Nothing here yet';

  @override
  String get myLearningEmptyBody =>
      'Courses you enrol in will appear here with your progress.';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get exploreEmptyTitle => 'Catalogue coming soon';

  @override
  String get exploreEmptyBody =>
      'Published courses from Almuntahha will be listed here.';

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get downloadsEmptyTitle => 'No downloads';

  @override
  String get downloadsEmptyBody =>
      'Download a course to study it without an internet connection.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get signOut => 'Sign out';

  @override
  String get adminConsole => 'Teacher & admin console';

  @override
  String get courseTitle => 'Course';

  @override
  String get lessonTitle => 'Lesson';

  @override
  String get comingSoon => 'This section is being built.';

  @override
  String get signInTitle => 'Welcome to Sidra';

  @override
  String get signInSubtitle =>
      'Sign in or create an account to continue your studies.';

  @override
  String get retry => 'Try again';

  @override
  String get genericError => 'Something went wrong.';

  @override
  String get offlineError => 'You appear to be offline.';

  @override
  String get loading => 'Loading…';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get onboard1Title => 'Learn with structure';

  @override
  String get onboard1Body =>
      'Courses prepared by Almuntahha teachers — from Quran reading for beginners to Islamic theology — organised into clear units and lessons.';

  @override
  String get onboard2Title => 'Guided by your teacher';

  @override
  String get onboard2Body =>
      'Your teacher reviews your progress and opens each next lesson when you are ready, so you always know what to study next.';

  @override
  String get onboard3Title => 'Study anywhere';

  @override
  String get onboard3Body =>
      'Download your lessons and keep learning without an internet connection. Your progress syncs when you are back online.';

  @override
  String get signInUnavailableTitle => 'Sign-in is not available yet';

  @override
  String get signInUnavailableBody =>
      'This build of Sidra has not been connected to its sign-in service. Please install the latest version or contact Almuntahha.';

  @override
  String get signInUnavailableDevHint =>
      'Developer: add these to .env, then run  dart run tool/gen_config.dart';
}
