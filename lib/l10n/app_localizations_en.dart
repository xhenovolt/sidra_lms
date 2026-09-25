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

  @override
  String get accessFree => 'Free';

  @override
  String get accessPaid => 'Paid';

  @override
  String get accessRestricted => 'By invitation';

  @override
  String get difficultyBeginner => 'Beginner';

  @override
  String get difficultyIntermediate => 'Intermediate';

  @override
  String get difficultyAdvanced => 'Advanced';

  @override
  String lessonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: '1 lesson',
      zero: 'No lessons yet',
    );
    return '$_temp0';
  }

  @override
  String hoursShort(String hours) {
    return '$hours h';
  }

  @override
  String percentComplete(int percent) {
    return '$percent% complete';
  }

  @override
  String get startCourse => 'Start this course';

  @override
  String get continueAction => 'Continue';

  @override
  String get enrolling => 'Enrolling…';

  @override
  String get accessRequiredTitle => 'Enrolment by Almuntahha';

  @override
  String get accessRequiredBody =>
      'This course is opened for learners by the Almuntahha team. Please contact your teacher or Almuntahha to join.';

  @override
  String get courseOutline => 'Course outline';

  @override
  String get learningObjectives => 'What you will learn';

  @override
  String get prerequisitesTitle => 'Before you start';

  @override
  String get booksTitle => 'Books';

  @override
  String get lockedLessonTitle => 'Waiting for your teacher';

  @override
  String get lockedLessonBody =>
      'Your teacher opens this lesson after reviewing your progress on the previous one.';

  @override
  String get notEnrolledLessonBody =>
      'Enrol in this course to open its lessons.';

  @override
  String get markComplete => 'I have finished this lesson';

  @override
  String get completedLabel => 'Completed';

  @override
  String get previousLesson => 'Previous';

  @override
  String get nextLesson => 'Next';

  @override
  String get awaitingTeacherTitle => 'Well done!';

  @override
  String get awaitingTeacherBody =>
      'You have finished everything open to you. Your teacher will review your work and open the next lesson.';

  @override
  String get savedOnDevice =>
      'Saved on this device · will sync when you are online';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes were not accepted',
      one: '1 change was not accepted',
    );
    return '$_temp0';
  }

  @override
  String get offlineShowingSaved => 'Offline · showing saved content';

  @override
  String get courseUnavailable => 'This course is not available.';

  @override
  String get lessonEmpty => 'This lesson has no content yet.';

  @override
  String get continueWhereLeft => 'Continue where you left off';

  @override
  String get nextUp => 'Next up';

  @override
  String get teacherConsole => 'Teacher console';

  @override
  String get roleLearner => 'Learner';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get downloadCourse => 'Download for offline';

  @override
  String get downloadedLabel => 'Available offline';

  @override
  String get removeDownload => 'Remove download';

  @override
  String downloadingProgress(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get downloadFailed =>
      'Download stopped. Check your connection and storage, then try again.';

  @override
  String get storageFull => 'Your device is out of storage space.';

  @override
  String sizeMb(String mb) {
    return '$mb MB';
  }

  @override
  String get quizTitle => 'Quiz';

  @override
  String get submitAnswers => 'Submit answers';

  @override
  String get quizPassed => 'Passed';

  @override
  String get quizNotPassed => 'Not yet passed';

  @override
  String quizScore(String score, String max) {
    return 'Score: $score / $max';
  }

  @override
  String get quizAwaitingTeacher =>
      'Submitted. Your teacher will mark the written answers.';

  @override
  String get quizOfflineNote =>
      'Scored on this device. It will be confirmed when you are back online.';

  @override
  String get quizNeedsConnection => 'This quiz needs an internet connection.';

  @override
  String get yourAnswer => 'Your answer';

  @override
  String get recitationInClass => 'Recite this to your teacher in class.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get done => 'Done';

  @override
  String get enrolFailed => 'Could not enrol. Please try again.';

  @override
  String get teacherFeedback => 'Teacher feedback';
}
