import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sidra'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Islamic learning by Almuntahha'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMyLearning.
  ///
  /// In en, this message translates to:
  /// **'My Learning'**
  String get navMyLearning;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get navDownloads;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String greetingMorning(String name);

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String greetingAfternoon(String name);

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String greetingEvening(String name);

  /// No description provided for @learnerFallbackName.
  ///
  /// In en, this message translates to:
  /// **'learner'**
  String get learnerFallbackName;

  /// No description provided for @continueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get continueLearning;

  /// No description provided for @enrolledCourses.
  ///
  /// In en, this message translates to:
  /// **'Your courses'**
  String get enrolledCourses;

  /// No description provided for @noEnrolmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Begin your journey'**
  String get noEnrolmentsTitle;

  /// No description provided for @noEnrolmentsBody.
  ///
  /// In en, this message translates to:
  /// **'You are not enrolled in any course yet. Explore the catalogue to find a course to start.'**
  String get noEnrolmentsBody;

  /// No description provided for @exploreCourses.
  ///
  /// In en, this message translates to:
  /// **'Explore courses'**
  String get exploreCourses;

  /// No description provided for @myLearningEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get myLearningEmptyTitle;

  /// No description provided for @myLearningEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Courses you enrol in will appear here with your progress.'**
  String get myLearningEmptyBody;

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// No description provided for @exploreEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalogue coming soon'**
  String get exploreEmptyTitle;

  /// No description provided for @exploreEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Published courses from Almuntahha will be listed here.'**
  String get exploreEmptyBody;

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// No description provided for @downloadsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No downloads'**
  String get downloadsEmptyTitle;

  /// No description provided for @downloadsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Download a course to study it without an internet connection.'**
  String get downloadsEmptyBody;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @adminConsole.
  ///
  /// In en, this message translates to:
  /// **'Teacher & admin console'**
  String get adminConsole;

  /// No description provided for @courseTitle.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get courseTitle;

  /// No description provided for @lessonTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get lessonTitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'This section is being built.'**
  String get comingSoon;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sidra'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to continue your studies.'**
  String get signInSubtitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get genericError;

  /// No description provided for @offlineError.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline.'**
  String get offlineError;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @onboard1Title.
  ///
  /// In en, this message translates to:
  /// **'Learn with structure'**
  String get onboard1Title;

  /// No description provided for @onboard1Body.
  ///
  /// In en, this message translates to:
  /// **'Courses prepared by Almuntahha teachers — from Quran reading for beginners to Islamic theology — organised into clear units and lessons.'**
  String get onboard1Body;

  /// No description provided for @onboard2Title.
  ///
  /// In en, this message translates to:
  /// **'Guided by your teacher'**
  String get onboard2Title;

  /// No description provided for @onboard2Body.
  ///
  /// In en, this message translates to:
  /// **'Your teacher reviews your progress and opens each next lesson when you are ready, so you always know what to study next.'**
  String get onboard2Body;

  /// No description provided for @onboard3Title.
  ///
  /// In en, this message translates to:
  /// **'Study anywhere'**
  String get onboard3Title;

  /// No description provided for @onboard3Body.
  ///
  /// In en, this message translates to:
  /// **'Download your lessons and keep learning without an internet connection. Your progress syncs when you are back online.'**
  String get onboard3Body;

  /// No description provided for @signInUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is not available yet'**
  String get signInUnavailableTitle;

  /// No description provided for @signInUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This build of Sidra has not been connected to its sign-in service. Please install the latest version or contact Almuntahha.'**
  String get signInUnavailableBody;

  /// No description provided for @signInUnavailableDevHint.
  ///
  /// In en, this message translates to:
  /// **'Developer: add these to .env, then run  dart run tool/gen_config.dart'**
  String get signInUnavailableDevHint;

  /// No description provided for @accessFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get accessFree;

  /// No description provided for @accessPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get accessPaid;

  /// No description provided for @accessRestricted.
  ///
  /// In en, this message translates to:
  /// **'By invitation'**
  String get accessRestricted;

  /// No description provided for @difficultyBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get difficultyBeginner;

  /// No description provided for @difficultyIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get difficultyIntermediate;

  /// No description provided for @difficultyAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get difficultyAdvanced;

  /// No description provided for @lessonsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No lessons yet} =1{1 lesson} other{{count} lessons}}'**
  String lessonsCount(int count);

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String hoursShort(String hours);

  /// No description provided for @percentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String percentComplete(int percent);

  /// No description provided for @startCourse.
  ///
  /// In en, this message translates to:
  /// **'Start this course'**
  String get startCourse;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @enrolling.
  ///
  /// In en, this message translates to:
  /// **'Enrolling…'**
  String get enrolling;

  /// No description provided for @accessRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrolment by Almuntahha'**
  String get accessRequiredTitle;

  /// No description provided for @accessRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This course is opened for learners by the Almuntahha team. Please contact your teacher or Almuntahha to join.'**
  String get accessRequiredBody;

  /// No description provided for @courseOutline.
  ///
  /// In en, this message translates to:
  /// **'Course outline'**
  String get courseOutline;

  /// No description provided for @learningObjectives.
  ///
  /// In en, this message translates to:
  /// **'What you will learn'**
  String get learningObjectives;

  /// No description provided for @prerequisitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get prerequisitesTitle;

  /// No description provided for @booksTitle.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get booksTitle;

  /// No description provided for @lockedLessonTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your teacher'**
  String get lockedLessonTitle;

  /// No description provided for @lockedLessonBody.
  ///
  /// In en, this message translates to:
  /// **'Your teacher opens this lesson after reviewing your progress on the previous one.'**
  String get lockedLessonBody;

  /// No description provided for @notEnrolledLessonBody.
  ///
  /// In en, this message translates to:
  /// **'Enrol in this course to open its lessons.'**
  String get notEnrolledLessonBody;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'I have finished this lesson'**
  String get markComplete;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @previousLesson.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousLesson;

  /// No description provided for @nextLesson.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLesson;

  /// No description provided for @awaitingTeacherTitle.
  ///
  /// In en, this message translates to:
  /// **'Well done!'**
  String get awaitingTeacherTitle;

  /// No description provided for @awaitingTeacherBody.
  ///
  /// In en, this message translates to:
  /// **'You have finished everything open to you. Your teacher will review your work and open the next lesson.'**
  String get awaitingTeacherBody;

  /// No description provided for @savedOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device · will sync when you are online'**
  String get savedOnDevice;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String syncPending(int count);

  /// No description provided for @syncRejected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change was not accepted} other{{count} changes were not accepted}}'**
  String syncRejected(int count);

  /// No description provided for @offlineShowingSaved.
  ///
  /// In en, this message translates to:
  /// **'Offline · showing saved content'**
  String get offlineShowingSaved;

  /// No description provided for @courseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This course is not available.'**
  String get courseUnavailable;

  /// No description provided for @lessonEmpty.
  ///
  /// In en, this message translates to:
  /// **'This lesson has no content yet.'**
  String get lessonEmpty;

  /// No description provided for @continueWhereLeft.
  ///
  /// In en, this message translates to:
  /// **'Continue where you left off'**
  String get continueWhereLeft;

  /// No description provided for @nextUp.
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get nextUp;

  /// No description provided for @teacherConsole.
  ///
  /// In en, this message translates to:
  /// **'Teacher console'**
  String get teacherConsole;

  /// No description provided for @roleLearner.
  ///
  /// In en, this message translates to:
  /// **'Learner'**
  String get roleLearner;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @downloadCourse.
  ///
  /// In en, this message translates to:
  /// **'Download for offline'**
  String get downloadCourse;

  /// No description provided for @downloadedLabel.
  ///
  /// In en, this message translates to:
  /// **'Available offline'**
  String get downloadedLabel;

  /// No description provided for @removeDownload.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get removeDownload;

  /// No description provided for @downloadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String downloadingProgress(int percent);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download stopped. Check your connection and storage, then try again.'**
  String get downloadFailed;

  /// No description provided for @storageFull.
  ///
  /// In en, this message translates to:
  /// **'Your device is out of storage space.'**
  String get storageFull;

  /// No description provided for @sizeMb.
  ///
  /// In en, this message translates to:
  /// **'{mb} MB'**
  String sizeMb(String mb);

  /// No description provided for @quizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizTitle;

  /// No description provided for @submitAnswers.
  ///
  /// In en, this message translates to:
  /// **'Submit answers'**
  String get submitAnswers;

  /// No description provided for @quizPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get quizPassed;

  /// No description provided for @quizNotPassed.
  ///
  /// In en, this message translates to:
  /// **'Not yet passed'**
  String get quizNotPassed;

  /// No description provided for @quizScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score} / {max}'**
  String quizScore(String score, String max);

  /// No description provided for @quizAwaitingTeacher.
  ///
  /// In en, this message translates to:
  /// **'Submitted. Your teacher will mark the written answers.'**
  String get quizAwaitingTeacher;

  /// No description provided for @quizOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Scored on this device. It will be confirmed when you are back online.'**
  String get quizOfflineNote;

  /// No description provided for @quizNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'This quiz needs an internet connection.'**
  String get quizNeedsConnection;

  /// No description provided for @yourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get yourAnswer;

  /// No description provided for @recitationInClass.
  ///
  /// In en, this message translates to:
  /// **'Recite this to your teacher in class.'**
  String get recitationInClass;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @enrolFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not enrol. Please try again.'**
  String get enrolFailed;

  /// No description provided for @teacherFeedback.
  ///
  /// In en, this message translates to:
  /// **'Teacher feedback'**
  String get teacherFeedback;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
