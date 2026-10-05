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
  /// **'Islamic learning by {org}'**
  String appTagline(String org);

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
  /// **'Published courses from {org} will be listed here.'**
  String exploreEmptyBody(String org);

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
  /// **'Sign in with your phone number, email or username to continue your studies.'**
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
  /// **'Courses prepared by {org} teachers — from Quran reading for beginners to Islamic theology — organised into clear units and lessons.'**
  String onboard1Body(String org);

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
  /// **'This build of Sidra has not been connected to its sign-in service. Please install the latest version or contact {org}.'**
  String signInUnavailableBody(String org);

  /// No description provided for @signInUnavailableDevHint.
  ///
  /// In en, this message translates to:
  /// **'Developer: run  dart run tool/db.dart app-role  then  dart run tool/gen_config.dart'**
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
  /// **'Enrolment by {org}'**
  String accessRequiredTitle(String org);

  /// No description provided for @accessRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This course is opened for learners by the {org} team. Please contact your teacher or {org} to join.'**
  String accessRequiredBody(String org);

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

  /// No description provided for @adminAccess.
  ///
  /// In en, this message translates to:
  /// **'Who can join'**
  String get adminAccess;

  /// No description provided for @adminAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get adminAdd;

  /// No description provided for @adminAddContent.
  ///
  /// In en, this message translates to:
  /// **'Add content'**
  String get adminAddContent;

  /// No description provided for @adminAddLesson.
  ///
  /// In en, this message translates to:
  /// **'Add lesson'**
  String get adminAddLesson;

  /// No description provided for @adminAddLevel.
  ///
  /// In en, this message translates to:
  /// **'Add level'**
  String get adminAddLevel;

  /// No description provided for @adminAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get adminAddOption;

  /// No description provided for @adminAddQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add question'**
  String get adminAddQuestion;

  /// No description provided for @adminAddSection.
  ///
  /// In en, this message translates to:
  /// **'Add section'**
  String get adminAddSection;

  /// No description provided for @adminAddSubsection.
  ///
  /// In en, this message translates to:
  /// **'Add part inside'**
  String get adminAddSubsection;

  /// No description provided for @adminAddUnit.
  ///
  /// In en, this message translates to:
  /// **'Add unit'**
  String get adminAddUnit;

  /// No description provided for @adminAllLearners.
  ///
  /// In en, this message translates to:
  /// **'All learners'**
  String get adminAllLearners;

  /// No description provided for @adminArabicText.
  ///
  /// In en, this message translates to:
  /// **'Arabic text'**
  String get adminArabicText;

  /// No description provided for @adminAssignTeacher.
  ///
  /// In en, this message translates to:
  /// **'Make teacher of a course'**
  String get adminAssignTeacher;

  /// No description provided for @adminAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get adminAuthor;

  /// No description provided for @adminAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your review'**
  String get adminAwaitingReview;

  /// No description provided for @adminBlockAttachment.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get adminBlockAttachment;

  /// No description provided for @adminBlockAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get adminBlockAudio;

  /// No description provided for @adminBlockCallout.
  ///
  /// In en, this message translates to:
  /// **'Highlight box'**
  String get adminBlockCallout;

  /// No description provided for @adminBlockDivider.
  ///
  /// In en, this message translates to:
  /// **'Divider'**
  String get adminBlockDivider;

  /// No description provided for @adminBlockHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get adminBlockHeading;

  /// No description provided for @adminBlockImage.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get adminBlockImage;

  /// No description provided for @adminBlockQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get adminBlockQuiz;

  /// No description provided for @adminBlockQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran text'**
  String get adminBlockQuran;

  /// No description provided for @adminBlockReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get adminBlockReference;

  /// No description provided for @adminBlockText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get adminBlockText;

  /// No description provided for @adminBlockTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get adminBlockTranslation;

  /// No description provided for @adminBlockTransliteration.
  ///
  /// In en, this message translates to:
  /// **'Transliteration'**
  String get adminBlockTransliteration;

  /// No description provided for @adminBlockVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get adminBlockVideo;

  /// No description provided for @adminBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get adminBook;

  /// No description provided for @adminCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminCancel;

  /// No description provided for @adminCaption.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get adminCaption;

  /// No description provided for @adminChangeRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Change role?'**
  String get adminChangeRoleTitle;

  /// No description provided for @adminChapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get adminChapter;

  /// No description provided for @adminChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file from this device'**
  String get adminChooseFile;

  /// No description provided for @adminCitation.
  ///
  /// In en, this message translates to:
  /// **'Citation'**
  String get adminCitation;

  /// No description provided for @adminConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get adminConfirm;

  /// No description provided for @adminContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get adminContent;

  /// No description provided for @adminCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright / usage notes'**
  String get adminCopyright;

  /// No description provided for @adminCourseTitle.
  ///
  /// In en, this message translates to:
  /// **'Course name'**
  String get adminCourseTitle;

  /// No description provided for @adminCover.
  ///
  /// In en, this message translates to:
  /// **'Cover picture'**
  String get adminCover;

  /// No description provided for @adminCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get adminCreate;

  /// No description provided for @adminCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get adminCurrency;

  /// No description provided for @adminCurrentLesson.
  ///
  /// In en, this message translates to:
  /// **'Current lesson'**
  String get adminCurrentLesson;

  /// No description provided for @adminCustomStructure.
  ///
  /// In en, this message translates to:
  /// **'My own levels'**
  String get adminCustomStructure;

  /// No description provided for @adminDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminDelete;

  /// No description provided for @adminDeleteBlockBody.
  ///
  /// In en, this message translates to:
  /// **'This content will be removed from the lesson.'**
  String get adminDeleteBlockBody;

  /// No description provided for @adminDeleteLessonBody.
  ///
  /// In en, this message translates to:
  /// **'The lesson, its content and learners\' progress on it will be deleted.'**
  String get adminDeleteLessonBody;

  /// No description provided for @adminDeleteNodeBody.
  ///
  /// In en, this message translates to:
  /// **'This part and everything inside it (including lessons) will be deleted.'**
  String get adminDeleteNodeBody;

  /// No description provided for @adminDeleteQuestionBody.
  ///
  /// In en, this message translates to:
  /// **'This question will be removed from the quiz.'**
  String get adminDeleteQuestionBody;

  /// No description provided for @adminDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get adminDeleteTitle;

  /// No description provided for @adminDeleteUnitBody.
  ///
  /// In en, this message translates to:
  /// **'The unit and everything inside it will be deleted.'**
  String get adminDeleteUnitBody;

  /// No description provided for @adminDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminDescription;

  /// No description provided for @adminDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get adminDifficulty;

  /// No description provided for @adminDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get adminDraft;

  /// No description provided for @adminEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminEdit;

  /// No description provided for @adminEditCourse.
  ///
  /// In en, this message translates to:
  /// **'Edit course details'**
  String get adminEditCourse;

  /// No description provided for @adminEditQuestions.
  ///
  /// In en, this message translates to:
  /// **'Edit questions'**
  String get adminEditQuestions;

  /// No description provided for @adminEdition.
  ///
  /// In en, this message translates to:
  /// **'Edition'**
  String get adminEdition;

  /// No description provided for @adminEmptyLessonBody.
  ///
  /// In en, this message translates to:
  /// **'Tap “Add content” to write text, add Quran verses, pictures, audio or a quiz.'**
  String get adminEmptyLessonBody;

  /// No description provided for @adminEmptyLessonTitle.
  ///
  /// In en, this message translates to:
  /// **'This lesson is empty'**
  String get adminEmptyLessonTitle;

  /// No description provided for @adminEstimatedHours.
  ///
  /// In en, this message translates to:
  /// **'Estimated hours'**
  String get adminEstimatedHours;

  /// No description provided for @adminExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation shown after answering'**
  String get adminExplanation;

  /// No description provided for @adminFalse.
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get adminFalse;

  /// No description provided for @adminFileUploaded.
  ///
  /// In en, this message translates to:
  /// **'File uploaded'**
  String get adminFileUploaded;

  /// No description provided for @adminFromBook.
  ///
  /// In en, this message translates to:
  /// **'Comes from book'**
  String get adminFromBook;

  /// No description provided for @adminGradedQuiz.
  ///
  /// In en, this message translates to:
  /// **'Graded quiz'**
  String get adminGradedQuiz;

  /// No description provided for @adminGradedQuizHint.
  ///
  /// In en, this message translates to:
  /// **'Counts for the learner. Needs internet; answers stay hidden.'**
  String get adminGradedQuizHint;

  /// No description provided for @adminGrantCourse.
  ///
  /// In en, this message translates to:
  /// **'Give access to a course'**
  String get adminGrantCourse;

  /// No description provided for @adminHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden from learners'**
  String get adminHidden;

  /// No description provided for @adminLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get adminLanguage;

  /// No description provided for @adminLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get adminLevel;

  /// No description provided for @adminLevelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Surah, Page, Chapter'**
  String get adminLevelHint;

  /// No description provided for @adminLink.
  ///
  /// In en, this message translates to:
  /// **'Web link'**
  String get adminLink;

  /// No description provided for @adminLinkBook.
  ///
  /// In en, this message translates to:
  /// **'Link a book'**
  String get adminLinkBook;

  /// No description provided for @adminMakeRole.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get adminMakeRole;

  /// No description provided for @adminMaxAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts allowed'**
  String get adminMaxAttempts;

  /// No description provided for @adminMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes to complete'**
  String get adminMinutes;

  /// No description provided for @adminMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get adminMoveDown;

  /// No description provided for @adminMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get adminMoveUp;

  /// No description provided for @adminNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'This needs an internet connection.'**
  String get adminNeedsConnection;

  /// No description provided for @adminNeedsRevision.
  ///
  /// In en, this message translates to:
  /// **'Needs revision'**
  String get adminNeedsRevision;

  /// No description provided for @adminNewBook.
  ///
  /// In en, this message translates to:
  /// **'New book'**
  String get adminNewBook;

  /// No description provided for @adminNewCourse.
  ///
  /// In en, this message translates to:
  /// **'New course'**
  String get adminNewCourse;

  /// No description provided for @adminNoBook.
  ///
  /// In en, this message translates to:
  /// **'Not from a book'**
  String get adminNoBook;

  /// No description provided for @adminNoBooksBody.
  ///
  /// In en, this message translates to:
  /// **'Add the books your courses teach from, then choose how each book is organised.'**
  String get adminNoBooksBody;

  /// No description provided for @adminNoBooksTitle.
  ///
  /// In en, this message translates to:
  /// **'No books yet'**
  String get adminNoBooksTitle;

  /// No description provided for @adminNoBooksToLink.
  ///
  /// In en, this message translates to:
  /// **'All books are already linked. Add books in the Books tab.'**
  String get adminNoBooksToLink;

  /// No description provided for @adminNoCoursesBody.
  ///
  /// In en, this message translates to:
  /// **'Create your first course to start building the curriculum.'**
  String get adminNoCoursesBody;

  /// No description provided for @adminNoCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'No courses yet'**
  String get adminNoCoursesTitle;

  /// No description provided for @adminNoLearnersBody.
  ///
  /// In en, this message translates to:
  /// **'Learners enrolled in your courses will appear here.'**
  String get adminNoLearnersBody;

  /// No description provided for @adminNoLearnersTitle.
  ///
  /// In en, this message translates to:
  /// **'No learners yet'**
  String get adminNoLearnersTitle;

  /// No description provided for @adminNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions yet. Tap “Add question”.'**
  String get adminNoQuestions;

  /// No description provided for @adminNoStructure.
  ///
  /// In en, this message translates to:
  /// **'Organisation not set'**
  String get adminNoStructure;

  /// No description provided for @adminNoUnit.
  ///
  /// In en, this message translates to:
  /// **'No unit'**
  String get adminNoUnit;

  /// No description provided for @adminNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission for this.'**
  String get adminNotAllowed;

  /// No description provided for @adminOnePerLine.
  ///
  /// In en, this message translates to:
  /// **'One per line'**
  String get adminOnePerLine;

  /// No description provided for @adminOpenNextLesson.
  ///
  /// In en, this message translates to:
  /// **'Open the next lesson for this learner'**
  String get adminOpenNextLesson;

  /// No description provided for @adminOption.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get adminOption;

  /// No description provided for @adminOptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Tick the correct answer(s):'**
  String get adminOptionsHint;

  /// No description provided for @adminOutlineHint.
  ///
  /// In en, this message translates to:
  /// **'Add sections (like a Surah, a page or a chapter) and lessons inside them.'**
  String get adminOutlineHint;

  /// No description provided for @adminPageFrom.
  ///
  /// In en, this message translates to:
  /// **'Page from'**
  String get adminPageFrom;

  /// No description provided for @adminPageTo.
  ///
  /// In en, this message translates to:
  /// **'Page to'**
  String get adminPageTo;

  /// No description provided for @adminPassMark.
  ///
  /// In en, this message translates to:
  /// **'Pass mark'**
  String get adminPassMark;

  /// No description provided for @adminPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get adminPassed;

  /// No description provided for @adminPickCorrect.
  ///
  /// In en, this message translates to:
  /// **'Tick at least one correct answer.'**
  String get adminPickCorrect;

  /// No description provided for @adminPracticeQuizHint.
  ///
  /// In en, this message translates to:
  /// **'For practice. Works offline; learners see correct answers.'**
  String get adminPracticeQuizHint;

  /// No description provided for @adminPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get adminPreview;

  /// No description provided for @adminPreviewAsLearner.
  ///
  /// In en, this message translates to:
  /// **'See it as a learner'**
  String get adminPreviewAsLearner;

  /// No description provided for @adminPreviewLesson.
  ///
  /// In en, this message translates to:
  /// **'Free preview'**
  String get adminPreviewLesson;

  /// No description provided for @adminPreviewLessonHint.
  ///
  /// In en, this message translates to:
  /// **'Every enrolled learner can open it without unlocking'**
  String get adminPreviewLessonHint;

  /// No description provided for @adminPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get adminPrice;

  /// No description provided for @adminProgression.
  ///
  /// In en, this message translates to:
  /// **'How learners move forward'**
  String get adminProgression;

  /// No description provided for @adminProgressionOpen.
  ///
  /// In en, this message translates to:
  /// **'All lessons open'**
  String get adminProgressionOpen;

  /// No description provided for @adminProgressionSequential.
  ///
  /// In en, this message translates to:
  /// **'Next lesson opens after finishing'**
  String get adminProgressionSequential;

  /// No description provided for @adminProgressionTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher opens each next lesson'**
  String get adminProgressionTeacher;

  /// No description provided for @adminPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get adminPublish;

  /// No description provided for @adminPublishCourse.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get adminPublishCourse;

  /// No description provided for @adminPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get adminPublished;

  /// No description provided for @adminQMultiple.
  ///
  /// In en, this message translates to:
  /// **'Choose all that apply'**
  String get adminQMultiple;

  /// No description provided for @adminQRecitation.
  ///
  /// In en, this message translates to:
  /// **'Recitation (marked in class)'**
  String get adminQRecitation;

  /// No description provided for @adminQShort.
  ///
  /// In en, this message translates to:
  /// **'Written answer'**
  String get adminQShort;

  /// No description provided for @adminQSingle.
  ///
  /// In en, this message translates to:
  /// **'Choose one'**
  String get adminQSingle;

  /// No description provided for @adminQTrueFalse.
  ///
  /// In en, this message translates to:
  /// **'True or false'**
  String get adminQTrueFalse;

  /// No description provided for @adminQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get adminQuestion;

  /// No description provided for @adminQuestionType.
  ///
  /// In en, this message translates to:
  /// **'Question type'**
  String get adminQuestionType;

  /// No description provided for @adminReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference shown to learners'**
  String get adminReferenceLabel;

  /// No description provided for @adminReferenceLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Al-Fatihah 1–3, p. 12'**
  String get adminReferenceLabelHint;

  /// No description provided for @adminRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get adminRequired;

  /// No description provided for @adminReviewSaved.
  ///
  /// In en, this message translates to:
  /// **'Review saved'**
  String get adminReviewSaved;

  /// No description provided for @adminReviewSavedUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Review saved and the next lesson is open'**
  String get adminReviewSavedUnlocked;

  /// No description provided for @adminSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminSave;

  /// No description provided for @adminSaveReview.
  ///
  /// In en, this message translates to:
  /// **'Save review'**
  String get adminSaveReview;

  /// No description provided for @adminSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get adminSaved;

  /// No description provided for @adminScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get adminScore;

  /// No description provided for @adminSectionType.
  ///
  /// In en, this message translates to:
  /// **'Kind of section'**
  String get adminSectionType;

  /// No description provided for @adminSectionTypeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chapter, Page, Topic'**
  String get adminSectionTypeHint;

  /// No description provided for @adminSetStructure.
  ///
  /// In en, this message translates to:
  /// **'How is this book organised?'**
  String get adminSetStructure;

  /// No description provided for @adminSetStructureHint.
  ///
  /// In en, this message translates to:
  /// **'Choose levels such as Surah → Verse or Page'**
  String get adminSetStructureHint;

  /// No description provided for @adminSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get adminSource;

  /// No description provided for @adminStructureExplain.
  ///
  /// In en, this message translates to:
  /// **'Pick how this book is divided. Lessons are placed inside the smallest part.'**
  String get adminStructureExplain;

  /// No description provided for @adminSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get adminSubject;

  /// No description provided for @adminSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Quran, Aqeedah, Fiqh, Arabic'**
  String get adminSubjectHint;

  /// No description provided for @adminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Short tagline'**
  String get adminSubtitle;

  /// No description provided for @adminSummary.
  ///
  /// In en, this message translates to:
  /// **'Short summary'**
  String get adminSummary;

  /// No description provided for @adminSurah.
  ///
  /// In en, this message translates to:
  /// **'Surah no.'**
  String get adminSurah;

  /// No description provided for @adminTabCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get adminTabCourses;

  /// No description provided for @adminTabLearners.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get adminTabLearners;

  /// No description provided for @adminTabPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get adminTabPeople;

  /// No description provided for @adminText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get adminText;

  /// No description provided for @adminTextHint.
  ///
  /// In en, this message translates to:
  /// **'Use **bold**, *italic*, and start lines with - for bullet points'**
  String get adminTextHint;

  /// No description provided for @adminThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Course picture'**
  String get adminThumbnail;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adminTitle;

  /// No description provided for @adminToneInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get adminToneInfo;

  /// No description provided for @adminToneNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get adminToneNote;

  /// No description provided for @adminToneWarning.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get adminToneWarning;

  /// No description provided for @adminTranscript.
  ///
  /// In en, this message translates to:
  /// **'Transcript (optional)'**
  String get adminTranscript;

  /// No description provided for @adminTranslator.
  ///
  /// In en, this message translates to:
  /// **'Translator'**
  String get adminTranslator;

  /// No description provided for @adminTrue.
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get adminTrue;

  /// No description provided for @adminUnitOptional.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get adminUnitOptional;

  /// No description provided for @adminUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get adminUnits;

  /// No description provided for @adminUnitsHint.
  ///
  /// In en, this message translates to:
  /// **'Units group your course into big steps. They are optional.'**
  String get adminUnitsHint;

  /// No description provided for @adminUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get adminUnlimited;

  /// No description provided for @adminUnpublish.
  ///
  /// In en, this message translates to:
  /// **'Hide from learners'**
  String get adminUnpublish;

  /// No description provided for @adminVerseFrom.
  ///
  /// In en, this message translates to:
  /// **'Verse from'**
  String get adminVerseFrom;

  /// No description provided for @adminVerseTo.
  ///
  /// In en, this message translates to:
  /// **'Verse to'**
  String get adminVerseTo;

  /// No description provided for @adminVisibleToLearners.
  ///
  /// In en, this message translates to:
  /// **'Visible to learners'**
  String get adminVisibleToLearners;

  /// No description provided for @adminWholeCourse.
  ///
  /// In en, this message translates to:
  /// **'Whole course'**
  String get adminWholeCourse;

  /// No description provided for @adminChangeRoleBody.
  ///
  /// In en, this message translates to:
  /// **'Change the role of {name}? Their permissions change immediately.'**
  String adminChangeRoleBody(String name);

  /// No description provided for @authPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get authPhone;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 0772 123 456, or +256 772 123 456'**
  String get authPhoneHint;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmailLabel;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullName;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUp;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New to Sidra? Create an account'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authSignUpTitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your phone number or email. You will sign in with it and your password.'**
  String get authSignUpSubtitle;

  /// No description provided for @authForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get authForgot;

  /// No description provided for @authForgotBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your teacher or {org} to reset it. You will get a temporary password and choose a new one when you sign in.'**
  String authForgotBody(String org);

  /// No description provided for @authChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get authChangePasswordTitle;

  /// No description provided for @authChangePasswordForced.
  ///
  /// In en, this message translates to:
  /// **'Your password was reset. Please choose a new one to continue.'**
  String get authChangePasswordForced;

  /// No description provided for @authCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current (or temporary) password'**
  String get authCurrentPassword;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authSavePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get authSavePassword;

  /// No description provided for @authPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get authPasswordChanged;

  /// No description provided for @authChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get authChangePassword;

  /// No description provided for @authRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get authRequired;

  /// No description provided for @authPasswordRule.
  ///
  /// In en, this message translates to:
  /// **'At least {n} characters'**
  String authPasswordRule(int n);

  /// No description provided for @authPasswordsDiffer.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDiffer;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a mobile number like 0772 123 456, or with the country code (+…)'**
  String get authPhoneInvalid;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Those sign-in details and password don\'t match.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorTaken.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this phone/email. Try signing in.'**
  String get authErrorTaken;

  /// No description provided for @authErrorWeak.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get authErrorWeak;

  /// No description provided for @authErrorIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Check the phone number (with country code) or email.'**
  String get authErrorIdentifier;

  /// No description provided for @authErrorLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait 15 minutes and try again.'**
  String get authErrorLocked;

  /// No description provided for @authErrorDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account is disabled. Contact {org}.'**
  String authErrorDisabled(String org);

  /// No description provided for @authErrorSamePassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a password different from the current one.'**
  String get authErrorSamePassword;

  /// No description provided for @authErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get authErrorOffline;

  /// No description provided for @adminResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get adminResetPassword;

  /// No description provided for @adminResetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Give this temporary password to the learner. They must choose a new one when they sign in.'**
  String get adminResetPasswordBody;

  /// No description provided for @adminTemporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get adminTemporaryPassword;

  /// No description provided for @adminPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Password reset. Share the temporary password with the learner.'**
  String get adminPasswordReset;

  /// No description provided for @roleSuperadmin.
  ///
  /// In en, this message translates to:
  /// **'Superadmin'**
  String get roleSuperadmin;

  /// No description provided for @authUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsername;

  /// No description provided for @authUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'3–30 letters, numbers, dots or underscores'**
  String get authUsernameInvalid;

  /// No description provided for @adminTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminTabOverview;

  /// No description provided for @adminStatLearners.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get adminStatLearners;

  /// No description provided for @adminStatTeachers.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get adminStatTeachers;

  /// No description provided for @adminStatAdmins.
  ///
  /// In en, this message translates to:
  /// **'Administrators'**
  String get adminStatAdmins;

  /// No description provided for @adminStatPublished.
  ///
  /// In en, this message translates to:
  /// **'Published courses'**
  String get adminStatPublished;

  /// No description provided for @adminStatDrafts.
  ///
  /// In en, this message translates to:
  /// **'Draft courses'**
  String get adminStatDrafts;

  /// No description provided for @adminStatEnrolments.
  ///
  /// In en, this message translates to:
  /// **'Active enrolments'**
  String get adminStatEnrolments;

  /// No description provided for @adminStatActive7d.
  ///
  /// In en, this message translates to:
  /// **'Active learners (7 days)'**
  String get adminStatActive7d;

  /// No description provided for @adminStatCompleted7d.
  ///
  /// In en, this message translates to:
  /// **'Lessons completed (7 days)'**
  String get adminStatCompleted7d;

  /// No description provided for @adminQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get adminQuickActions;

  /// No description provided for @adminAddPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get adminAddPerson;

  /// No description provided for @adminSearchPeople.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone, email or username'**
  String get adminSearchPeople;

  /// No description provided for @adminEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get adminEveryone;

  /// No description provided for @adminNoPeople.
  ///
  /// In en, this message translates to:
  /// **'No one found'**
  String get adminNoPeople;

  /// No description provided for @adminDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get adminDisabled;

  /// No description provided for @adminDisabledNote.
  ///
  /// In en, this message translates to:
  /// **'This account is disabled and cannot sign in.'**
  String get adminDisabledNote;

  /// No description provided for @adminEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get adminEditDetails;

  /// No description provided for @adminSuperadminHint.
  ///
  /// In en, this message translates to:
  /// **'Can create and manage other administrators'**
  String get adminSuperadminHint;

  /// No description provided for @adminDisableAccount.
  ///
  /// In en, this message translates to:
  /// **'Disable account'**
  String get adminDisableAccount;

  /// No description provided for @adminEnableAccount.
  ///
  /// In en, this message translates to:
  /// **'Enable account'**
  String get adminEnableAccount;

  /// No description provided for @adminDisableHint.
  ///
  /// In en, this message translates to:
  /// **'They are signed out everywhere and cannot sign in until enabled again. Nothing is deleted.'**
  String get adminDisableHint;

  /// No description provided for @adminUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Optional, e.g. ustadh_ali'**
  String get adminUsernameHint;

  /// No description provided for @adminOneIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Give at least one of phone, email or username. They sign in with it.'**
  String get adminOneIdentifier;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get adminRole;

  /// No description provided for @adminPersonCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get adminPersonCreated;

  /// No description provided for @adminPersonCreatedBody.
  ///
  /// In en, this message translates to:
  /// **'Give this temporary password to the person. They must choose their own password the first time they sign in.'**
  String get adminPersonCreatedBody;

  /// No description provided for @adminCourseTeachers.
  ///
  /// In en, this message translates to:
  /// **'Teachers of this course'**
  String get adminCourseTeachers;

  /// No description provided for @adminAddTeacher.
  ///
  /// In en, this message translates to:
  /// **'Add teacher'**
  String get adminAddTeacher;

  /// No description provided for @adminAddLearner.
  ///
  /// In en, this message translates to:
  /// **'Add learner'**
  String get adminAddLearner;

  /// No description provided for @adminNoTeachersYet.
  ///
  /// In en, this message translates to:
  /// **'No teachers assigned yet. Administrators can always review learners.'**
  String get adminNoTeachersYet;

  /// No description provided for @adminRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get adminRemove;

  /// No description provided for @adminEnrolActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminEnrolActive;

  /// No description provided for @adminEnrolSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get adminEnrolSuspended;

  /// No description provided for @adminEnrolWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get adminEnrolWithdrawn;

  /// No description provided for @adminEnrolPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminEnrolPending;

  /// No description provided for @adminDeleteCourse.
  ///
  /// In en, this message translates to:
  /// **'Delete course'**
  String get adminDeleteCourse;

  /// No description provided for @adminDeleteCourseBody.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}” permanently? It has never been published and has no learners. This cannot be undone.'**
  String adminDeleteCourseBody(String title);

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @moreBrowseCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Browse the catalogue'**
  String get moreBrowseCatalogue;

  /// No description provided for @moreBrowseCatalogueHint.
  ///
  /// In en, this message translates to:
  /// **'See published courses as learners see them'**
  String get moreBrowseCatalogueHint;

  /// No description provided for @drawerAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get drawerAcademic;

  /// No description provided for @drawerTeaching.
  ///
  /// In en, this message translates to:
  /// **'Teaching'**
  String get drawerTeaching;

  /// No description provided for @drawerReview.
  ///
  /// In en, this message translates to:
  /// **'Review learners'**
  String get drawerReview;

  /// No description provided for @drawerPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get drawerPeople;

  /// No description provided for @drawerRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles & permissions'**
  String get drawerRoles;

  /// No description provided for @drawerOversight.
  ///
  /// In en, this message translates to:
  /// **'Oversight'**
  String get drawerOversight;

  /// No description provided for @drawerActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get drawerActivity;

  /// No description provided for @drawerAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get drawerAccount;

  /// No description provided for @rolesNew.
  ///
  /// In en, this message translates to:
  /// **'New role'**
  String get rolesNew;

  /// No description provided for @rolesIntro.
  ///
  /// In en, this message translates to:
  /// **'A role is a job in Sidra. Each person has one role; its permissions decide what they can see and do. Built-in roles can be adjusted; Super Admin always has everything.'**
  String get rolesIntro;

  /// No description provided for @rolesDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete this role? It must not be assigned to anyone.'**
  String get rolesDeleteBody;

  /// No description provided for @rolesSuperAdminLocked.
  ///
  /// In en, this message translates to:
  /// **'Super Admin always has every permission and cannot be changed.'**
  String get rolesSuperAdminLocked;

  /// No description provided for @areaEnrolment.
  ///
  /// In en, this message translates to:
  /// **'Enrolment'**
  String get areaEnrolment;

  /// No description provided for @areaFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get areaFinance;

  /// No description provided for @areaContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get areaContent;

  /// No description provided for @areaReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get areaReports;

  /// No description provided for @areaSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get areaSettings;

  /// No description provided for @auditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded yet'**
  String get auditEmpty;

  /// No description provided for @auditSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get auditSystem;

  /// No description provided for @auditCreated.
  ///
  /// In en, this message translates to:
  /// **'created'**
  String get auditCreated;

  /// No description provided for @auditRemoved.
  ///
  /// In en, this message translates to:
  /// **'removed'**
  String get auditRemoved;

  /// No description provided for @auditChanged.
  ///
  /// In en, this message translates to:
  /// **'changed'**
  String get auditChanged;

  /// No description provided for @auditEnrolment.
  ///
  /// In en, this message translates to:
  /// **'Enrolment'**
  String get auditEnrolment;

  /// No description provided for @auditTeacherAssignment.
  ///
  /// In en, this message translates to:
  /// **'Teacher assignment'**
  String get auditTeacherAssignment;

  /// No description provided for @auditAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get auditAccount;

  /// No description provided for @auditUnlock.
  ///
  /// In en, this message translates to:
  /// **'Lesson unlock'**
  String get auditUnlock;

  /// No description provided for @auditReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get auditReview;

  /// No description provided for @rolesSummary.
  ///
  /// In en, this message translates to:
  /// **'{permissions} permissions · {members} people'**
  String rolesSummary(int permissions, int members);

  /// No description provided for @statusInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get statusInReview;

  /// No description provided for @statusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get statusArchived;

  /// No description provided for @lifecycleTitle.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get lifecycleTitle;

  /// No description provided for @lifecycleMoved.
  ///
  /// In en, this message translates to:
  /// **'Course is now: {status}'**
  String lifecycleMoved(String status);

  /// No description provided for @lifecycleSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get lifecycleSubmit;

  /// No description provided for @lifecycleSubmitNote.
  ///
  /// In en, this message translates to:
  /// **'Note for the reviewer'**
  String get lifecycleSubmitNote;

  /// No description provided for @lifecycleReturn.
  ///
  /// In en, this message translates to:
  /// **'Return to draft'**
  String get lifecycleReturn;

  /// No description provided for @lifecycleReturnNote.
  ///
  /// In en, this message translates to:
  /// **'What needs fixing'**
  String get lifecycleReturnNote;

  /// No description provided for @lifecycleArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get lifecycleArchive;

  /// No description provided for @lifecycleRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore to draft'**
  String get lifecycleRestore;

  /// No description provided for @lifecycleArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this course?'**
  String get lifecycleArchiveTitle;

  /// No description provided for @lifecycleArchiveBody.
  ///
  /// In en, this message translates to:
  /// **'It leaves the catalogue and learners can no longer open it. Nothing is deleted: enrolments, progress and payments are kept, and you can restore it later.'**
  String get lifecycleArchiveBody;

  /// No description provided for @lifecyclePublishedOn.
  ///
  /// In en, this message translates to:
  /// **'Visible to learners · published {date}'**
  String lifecyclePublishedOn(String date);

  /// No description provided for @lifecycleArchivedHint.
  ///
  /// In en, this message translates to:
  /// **'Archived. Learners cannot see it; its records are kept.'**
  String get lifecycleArchivedHint;

  /// No description provided for @lifecycleInReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a reviewer to publish it or send it back.'**
  String get lifecycleInReviewHint;

  /// No description provided for @lifecycleReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to publish'**
  String get lifecycleReady;

  /// No description provided for @lifecycleNotReady.
  ///
  /// In en, this message translates to:
  /// **'Before publishing:'**
  String get lifecycleNotReady;

  /// No description provided for @issueNoPublishedLessons.
  ///
  /// In en, this message translates to:
  /// **'Publish at least one lesson'**
  String get issueNoPublishedLessons;

  /// No description provided for @issueNoDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a course description'**
  String get issueNoDescription;

  /// No description provided for @issueNoThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Add a cover image'**
  String get issueNoThumbnail;

  /// No description provided for @issueEmptyLessons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 published lesson has no content} other{{count} published lessons have no content}}'**
  String issueEmptyLessons(int count);

  /// No description provided for @issueDraftLessons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lesson is still a draft} other{{count} lessons are still drafts}}'**
  String issueDraftLessons(int count);

  /// No description provided for @issueNoTeacher.
  ///
  /// In en, this message translates to:
  /// **'Assign a teacher: learners wait for a teacher to open each next lesson'**
  String get issueNoTeacher;

  /// No description provided for @coursesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title, subject, category or tag'**
  String get coursesSearchHint;

  /// No description provided for @coursesFilterCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get coursesFilterCurrent;

  /// No description provided for @coursesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No courses match'**
  String get coursesNoMatch;

  /// No description provided for @courseCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get courseCategory;

  /// No description provided for @courseCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Quran, Arabic, Fiqh'**
  String get courseCategoryHint;

  /// No description provided for @courseTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get courseTags;

  /// No description provided for @courseTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Separate with commas, e.g. tajweed, beginners'**
  String get courseTagsHint;

  /// No description provided for @courseSelfEnrol.
  ///
  /// In en, this message translates to:
  /// **'Learners can enrol themselves'**
  String get courseSelfEnrol;

  /// No description provided for @courseSelfEnrolHint.
  ///
  /// In en, this message translates to:
  /// **'Turn off to enrol learners yourself, even though the course is free.'**
  String get courseSelfEnrolHint;

  /// No description provided for @adminBlockLink.
  ///
  /// In en, this message translates to:
  /// **'Link (YouTube, Telegram, website)'**
  String get adminBlockLink;

  /// No description provided for @linkUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Link address'**
  String get linkUrlLabel;

  /// No description provided for @linkUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a full web link, e.g. https://youtu.be/…'**
  String get linkUrlInvalid;

  /// No description provided for @linkTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get linkTitleLabel;

  /// No description provided for @linkDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Short description (optional)'**
  String get linkDescriptionLabel;

  /// No description provided for @linkPreview.
  ///
  /// In en, this message translates to:
  /// **'What learners will see'**
  String get linkPreview;

  /// No description provided for @linkOpen.
  ///
  /// In en, this message translates to:
  /// **'Opens outside Sidra'**
  String get linkOpen;

  /// No description provided for @linkProviderYoutube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get linkProviderYoutube;

  /// No description provided for @linkProviderTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get linkProviderTelegram;

  /// No description provided for @adminStatInReview.
  ///
  /// In en, this message translates to:
  /// **'Courses in review'**
  String get adminStatInReview;

  /// No description provided for @personTitle.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get personTitle;

  /// No description provided for @personActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get personActions;

  /// No description provided for @personJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String personJoined(String date);

  /// No description provided for @personLastSignIn.
  ///
  /// In en, this message translates to:
  /// **'Last signed in {date}'**
  String personLastSignIn(String date);

  /// No description provided for @personNeverSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Has not signed in yet'**
  String get personNeverSignedIn;

  /// No description provided for @personTeaching.
  ///
  /// In en, this message translates to:
  /// **'Teaching'**
  String get personTeaching;

  /// No description provided for @personNoTeaching.
  ///
  /// In en, this message translates to:
  /// **'Not assigned to any course yet'**
  String get personNoTeaching;

  /// No description provided for @personLearnerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 learner} other{{count} learners}}'**
  String personLearnerCount(int count);

  /// No description provided for @personCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get personCourses;

  /// No description provided for @personNoCourses.
  ///
  /// In en, this message translates to:
  /// **'Not enrolled in any course'**
  String get personNoCourses;

  /// No description provided for @personLessonsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} lessons done'**
  String personLessonsDone(int done, int total);

  /// No description provided for @personLastActive.
  ///
  /// In en, this message translates to:
  /// **'last active {date}'**
  String personLastActive(String date);

  /// No description provided for @personReviews.
  ///
  /// In en, this message translates to:
  /// **'Teacher reviews'**
  String get personReviews;

  /// No description provided for @personNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get personNoReviews;

  /// No description provided for @personQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Quiz results'**
  String get personQuizzes;

  /// No description provided for @personQuizPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for grading'**
  String get personQuizPending;

  /// No description provided for @personActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get personActivity;

  /// No description provided for @reviewPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get reviewPassed;

  /// No description provided for @reviewNeedsRevision.
  ///
  /// In en, this message translates to:
  /// **'Needs more practice'**
  String get reviewNeedsRevision;

  /// No description provided for @sourceSelf.
  ///
  /// In en, this message translates to:
  /// **'enrolled themselves'**
  String get sourceSelf;

  /// No description provided for @sourceStaff.
  ///
  /// In en, this message translates to:
  /// **'added by staff'**
  String get sourceStaff;

  /// No description provided for @sourcePayment.
  ///
  /// In en, this message translates to:
  /// **'paid'**
  String get sourcePayment;

  /// No description provided for @peopleActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get peopleActive;

  /// No description provided for @peopleShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total}'**
  String peopleShowing(int shown, int total);

  /// No description provided for @peopleLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get peopleLoadMore;

  /// No description provided for @staffWholeCourse.
  ///
  /// In en, this message translates to:
  /// **'Whole course'**
  String get staffWholeCourse;

  /// No description provided for @staffTeachesUnits.
  ///
  /// In en, this message translates to:
  /// **'Teaches {units}'**
  String staffTeachesUnits(String units);

  /// No description provided for @staffLimitUnits.
  ///
  /// In en, this message translates to:
  /// **'Limit to units…'**
  String get staffLimitUnits;

  /// No description provided for @staffLimitUnitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Which units does {name} teach?'**
  String staffLimitUnitsTitle(String name);

  /// No description provided for @staffLimitUnitsHint.
  ///
  /// In en, this message translates to:
  /// **'They review and unlock learners only in the ticked units. Tick none for the whole course.'**
  String get staffLimitUnitsHint;

  /// No description provided for @navReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get navReview;

  /// No description provided for @drawerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your menu. Check your connection and try again.'**
  String get drawerLoadFailed;

  /// No description provided for @payCourseFee.
  ///
  /// In en, this message translates to:
  /// **'Course fee'**
  String get payCourseFee;

  /// No description provided for @payAlreadyCovered.
  ///
  /// In en, this message translates to:
  /// **'{covered} of {fee} already covered'**
  String payAlreadyCovered(String covered, String fee);

  /// No description provided for @payWithMobileMoney.
  ///
  /// In en, this message translates to:
  /// **'Pay with mobile money'**
  String get payWithMobileMoney;

  /// No description provided for @payOtherWay.
  ///
  /// In en, this message translates to:
  /// **'Paid another way? Tell us'**
  String get payOtherWay;

  /// No description provided for @payPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'We will send a payment request to this MTN or Airtel number. Keep the phone with you.'**
  String get payPhoneHint;

  /// No description provided for @payPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile money number'**
  String get payPhoneLabel;

  /// No description provided for @payPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an MTN or Airtel Uganda number, e.g. 0772 123456'**
  String get payPhoneInvalid;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get payNow;

  /// No description provided for @payCheckPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your phone'**
  String get payCheckPhoneTitle;

  /// No description provided for @payCheckPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile money PIN to pay {amount} from {phone}. This page updates by itself.'**
  String payCheckPhoneBody(String amount, String phone);

  /// No description provided for @payReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get payReceivedTitle;

  /// No description provided for @payReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you. The course is now open.'**
  String get payReceivedBody;

  /// No description provided for @payPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation'**
  String get payPendingTitle;

  /// No description provided for @payPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Our finance team will confirm your payment and open the course.'**
  String get payPendingBody;

  /// No description provided for @payNoAnswerTitle.
  ///
  /// In en, this message translates to:
  /// **'No answer yet'**
  String get payNoAnswerTitle;

  /// No description provided for @payNoAnswerBody.
  ///
  /// In en, this message translates to:
  /// **'If you entered your PIN, the course opens as soon as the payment is confirmed. Otherwise, try again.'**
  String get payNoAnswerBody;

  /// No description provided for @payFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment not completed'**
  String get payFailedTitle;

  /// No description provided for @payFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The request was declined, cancelled or timed out. Nothing was taken. You can try again.'**
  String get payFailedBody;

  /// No description provided for @payMethodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get payMethodBank;

  /// No description provided for @payMethodMobileMoney.
  ///
  /// In en, this message translates to:
  /// **'Mobile money'**
  String get payMethodMobileMoney;

  /// No description provided for @payAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount paid ({currency})'**
  String payAmountLabel(String currency);

  /// No description provided for @payAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount you paid'**
  String get payAmountInvalid;

  /// No description provided for @payReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID or deposit slip number'**
  String get payReferenceLabel;

  /// No description provided for @payReferenceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the transaction ID or slip number'**
  String get payReferenceRequired;

  /// No description provided for @payNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get payNoteLabel;

  /// No description provided for @paySubmitReport.
  ///
  /// In en, this message translates to:
  /// **'Send for confirmation'**
  String get paySubmitReport;

  /// No description provided for @paySubmitReportHint.
  ///
  /// In en, this message translates to:
  /// **'The course opens once our finance team has checked the payment.'**
  String get paySubmitReportHint;

  /// No description provided for @drawerFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get drawerFinance;

  /// No description provided for @drawerFinancePage.
  ///
  /// In en, this message translates to:
  /// **'Payments & finance'**
  String get drawerFinancePage;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @financeOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get financeOverview;

  /// No description provided for @financePayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get financePayments;

  /// No description provided for @financeOwing.
  ///
  /// In en, this message translates to:
  /// **'Owing'**
  String get financeOwing;

  /// No description provided for @financeWaivers.
  ///
  /// In en, this message translates to:
  /// **'Waivers'**
  String get financeWaivers;

  /// No description provided for @financeExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get financeExpenses;

  /// No description provided for @periodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get periodThisMonth;

  /// No description provided for @periodLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get periodLastMonth;

  /// No description provided for @periodThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get periodThisYear;

  /// No description provided for @periodAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get periodAllTime;

  /// No description provided for @financePendingBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment waiting for verification} other{{count} payments waiting for verification}}'**
  String financePendingBanner(int count);

  /// No description provided for @financeCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get financeCollected;

  /// No description provided for @financeOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get financeOutstanding;

  /// No description provided for @financeExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get financeExpected;

  /// No description provided for @financeWaived.
  ///
  /// In en, this message translates to:
  /// **'Waived'**
  String get financeWaived;

  /// No description provided for @financeRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get financeRefunded;

  /// No description provided for @financeProviderFees.
  ///
  /// In en, this message translates to:
  /// **'MarzPay fees'**
  String get financeProviderFees;

  /// No description provided for @financeRetained.
  ///
  /// In en, this message translates to:
  /// **'Retained'**
  String get financeRetained;

  /// No description provided for @financeHowRetained.
  ///
  /// In en, this message translates to:
  /// **'How “Retained” is worked out'**
  String get financeHowRetained;

  /// No description provided for @financeFormula.
  ///
  /// In en, this message translates to:
  /// **'Retained = Collected − Refunds − MarzPay fees − Expenses'**
  String get financeFormula;

  /// No description provided for @financeWaiverNote.
  ///
  /// In en, this message translates to:
  /// **'Waivers reduce what learners owe; they are never counted as money collected.'**
  String get financeWaiverNote;

  /// No description provided for @financeByMethod.
  ///
  /// In en, this message translates to:
  /// **'Collected by method'**
  String get financeByMethod;

  /// No description provided for @financeByCourse.
  ///
  /// In en, this message translates to:
  /// **'By course'**
  String get financeByCourse;

  /// No description provided for @financeCourseLine.
  ///
  /// In en, this message translates to:
  /// **'{learners, plural, =1{1 learner} other{{learners} learners}} · collected {collected} · owing {outstanding}'**
  String financeCourseLine(int learners, String collected, String outstanding);

  /// No description provided for @methodMarzPay.
  ///
  /// In en, this message translates to:
  /// **'Mobile money (MarzPay)'**
  String get methodMarzPay;

  /// No description provided for @methodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get methodCash;

  /// No description provided for @methodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get methodOther;

  /// No description provided for @paymentInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get paymentInProgress;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'To verify'**
  String get paymentPending;

  /// No description provided for @paymentVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get paymentVerified;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get paymentFailed;

  /// No description provided for @paymentRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get paymentRejected;

  /// No description provided for @paymentReversed.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get paymentReversed;

  /// No description provided for @financeRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get financeRecordPayment;

  /// No description provided for @financeSearchPayments.
  ///
  /// In en, this message translates to:
  /// **'Search name, phone or transaction ID'**
  String get financeSearchPayments;

  /// No description provided for @financeNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments here'**
  String get financeNoPayments;

  /// No description provided for @financeLearner.
  ///
  /// In en, this message translates to:
  /// **'Learner'**
  String get financeLearner;

  /// No description provided for @financeCourse.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get financeCourse;

  /// No description provided for @financeMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get financeMethod;

  /// No description provided for @financeRecordedBy.
  ///
  /// In en, this message translates to:
  /// **'Recorded by'**
  String get financeRecordedBy;

  /// No description provided for @financeVerifiedBy.
  ///
  /// In en, this message translates to:
  /// **'Checked by'**
  String get financeVerifiedBy;

  /// No description provided for @financeCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get financeCreated;

  /// No description provided for @financeOpenLearner.
  ///
  /// In en, this message translates to:
  /// **'Open learner record'**
  String get financeOpenLearner;

  /// No description provided for @financeVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify: money received'**
  String get financeVerify;

  /// No description provided for @financeReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get financeReject;

  /// No description provided for @financeRefund.
  ///
  /// In en, this message translates to:
  /// **'Record a refund'**
  String get financeRefund;

  /// No description provided for @financeReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse (money not received)'**
  String get financeReverse;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @financeNobodyOwes.
  ///
  /// In en, this message translates to:
  /// **'Nobody owes anything'**
  String get financeNobodyOwes;

  /// No description provided for @financeOwingLine.
  ///
  /// In en, this message translates to:
  /// **'{course} · fee {fee} · paid {paid} · waived {waived}'**
  String financeOwingLine(
    String course,
    String fee,
    String paid,
    String waived,
  );

  /// No description provided for @financeGrantWaiver.
  ///
  /// In en, this message translates to:
  /// **'Grant waiver'**
  String get financeGrantWaiver;

  /// No description provided for @financeNoWaivers.
  ///
  /// In en, this message translates to:
  /// **'No waivers'**
  String get financeNoWaivers;

  /// No description provided for @financeFullFee.
  ///
  /// In en, this message translates to:
  /// **'Whole fee'**
  String get financeFullFee;

  /// No description provided for @financeRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke waiver'**
  String get financeRevoke;

  /// No description provided for @financeRecordExpense.
  ///
  /// In en, this message translates to:
  /// **'Record expense'**
  String get financeRecordExpense;

  /// No description provided for @financeNoExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period'**
  String get financeNoExpenses;

  /// No description provided for @financeVoid.
  ///
  /// In en, this message translates to:
  /// **'Void expense'**
  String get financeVoid;

  /// No description provided for @financeChooseLearner.
  ///
  /// In en, this message translates to:
  /// **'Choose learner'**
  String get financeChooseLearner;

  /// No description provided for @financeChooseCourse.
  ///
  /// In en, this message translates to:
  /// **'Choose course'**
  String get financeChooseCourse;

  /// No description provided for @financeCourseChosen.
  ///
  /// In en, this message translates to:
  /// **'Course chosen'**
  String get financeCourseChosen;

  /// No description provided for @financeNoPaidCourses.
  ///
  /// In en, this message translates to:
  /// **'No paid courses yet'**
  String get financeNoPaidCourses;

  /// No description provided for @financeChooseBoth.
  ///
  /// In en, this message translates to:
  /// **'Choose the learner and the course'**
  String get financeChooseBoth;

  /// No description provided for @financeCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get financeCategory;

  /// No description provided for @financeCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rent, Salaries, Transport'**
  String get financeCategoryHint;

  /// No description provided for @financePayee.
  ///
  /// In en, this message translates to:
  /// **'Paid to (optional)'**
  String get financePayee;

  /// No description provided for @financeRecordHint.
  ///
  /// In en, this message translates to:
  /// **'Recorded payments wait for a finance officer to verify them before they count.'**
  String get financeRecordHint;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Organisation settings'**
  String get settingsTitle;

  /// No description provided for @settingsOrgName.
  ///
  /// In en, this message translates to:
  /// **'Organisation name'**
  String get settingsOrgName;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsSupportPhone.
  ///
  /// In en, this message translates to:
  /// **'Support phone'**
  String get settingsSupportPhone;

  /// No description provided for @settingsSupportEmail.
  ///
  /// In en, this message translates to:
  /// **'Support email'**
  String get settingsSupportEmail;

  /// No description provided for @settingsBank.
  ///
  /// In en, this message translates to:
  /// **'How to pay by bank'**
  String get settingsBank;

  /// No description provided for @settingsBankHint.
  ///
  /// In en, this message translates to:
  /// **'Bank, account name and number. Learners see this.'**
  String get settingsBankHint;

  /// No description provided for @settingsMobileMoney.
  ///
  /// In en, this message translates to:
  /// **'How to pay by mobile money (outside the app)'**
  String get settingsMobileMoney;

  /// No description provided for @settingsMarzPay.
  ///
  /// In en, this message translates to:
  /// **'Mobile-money payments in the app (MarzPay)'**
  String get settingsMarzPay;

  /// No description provided for @settingsMarzPayHint.
  ///
  /// In en, this message translates to:
  /// **'Learners pay with a PIN prompt on their phone.'**
  String get settingsMarzPayHint;

  /// No description provided for @enrolMany.
  ///
  /// In en, this message translates to:
  /// **'Enrol several learners'**
  String get enrolMany;

  /// No description provided for @enrolUntil.
  ///
  /// In en, this message translates to:
  /// **'Access until (optional)'**
  String get enrolUntil;

  /// No description provided for @enrolNoEnd.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get enrolNoEnd;

  /// No description provided for @enrolSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Enrol 1 learner} other{Enrol {count} learners}}'**
  String enrolSelected(int count);

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @adminUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get adminUnitLabel;

  /// No description provided for @assignmentAccepts.
  ///
  /// In en, this message translates to:
  /// **'Learners may hand in:'**
  String get assignmentAccepts;

  /// No description provided for @assignmentAdd.
  ///
  /// In en, this message translates to:
  /// **'Add assignment'**
  String get assignmentAdd;

  /// No description provided for @assignmentAudio.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get assignmentAudio;

  /// No description provided for @assignmentDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete this assignment? It cannot be deleted once learners have handed in work.'**
  String get assignmentDeleteBody;

  /// No description provided for @assignmentDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get assignmentDocuments;

  /// No description provided for @assignmentDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String assignmentDue(String date);

  /// No description provided for @assignmentHint.
  ///
  /// In en, this message translates to:
  /// **'Work learners do and hand in here: photos of written work, documents, recordings. Their teacher reviews it and replies.'**
  String get assignmentHint;

  /// No description provided for @assignmentInstructions.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get assignmentInstructions;

  /// No description provided for @assignmentMaxScore.
  ///
  /// In en, this message translates to:
  /// **'Maximum score (optional)'**
  String get assignmentMaxScore;

  /// No description provided for @assignmentPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get assignmentPhotos;

  /// No description provided for @assignmentText.
  ///
  /// In en, this message translates to:
  /// **'Written answer'**
  String get assignmentText;

  /// No description provided for @assignmentVideo.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get assignmentVideo;

  /// No description provided for @assignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignmentsTitle;

  /// No description provided for @blockLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language of this content'**
  String get blockLanguage;

  /// No description provided for @blockLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'For example, Qur\'an text is Arabic even when the lesson is taught in English.'**
  String get blockLanguageHint;

  /// No description provided for @blockShowLearners.
  ///
  /// In en, this message translates to:
  /// **'Show to learners'**
  String get blockShowLearners;

  /// No description provided for @blockTeachersOnly.
  ///
  /// In en, this message translates to:
  /// **'Teachers only'**
  String get blockTeachersOnly;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @courseAlsoTaughtIn.
  ///
  /// In en, this message translates to:
  /// **'Also taught in'**
  String get courseAlsoTaughtIn;

  /// No description provided for @courseForWhom.
  ///
  /// In en, this message translates to:
  /// **'Who it is for: {who}'**
  String courseForWhom(String who);

  /// No description provided for @courseHidden.
  ///
  /// In en, this message translates to:
  /// **'Hide from the catalogue'**
  String get courseHidden;

  /// No description provided for @courseHiddenHint.
  ///
  /// In en, this message translates to:
  /// **'Only enrolled learners and staff see it.'**
  String get courseHiddenHint;

  /// No description provided for @courseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Main language of teaching'**
  String get courseLanguage;

  /// No description provided for @courseLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'The language explanations are given in. Arabic or Qur\'anic text inside lessons does not make Arabic the teaching language.'**
  String get courseLanguageHint;

  /// No description provided for @coursePrerequisites.
  ///
  /// In en, this message translates to:
  /// **'Must finish first'**
  String get coursePrerequisites;

  /// No description provided for @coursePrerequisitesNone.
  ///
  /// In en, this message translates to:
  /// **'No prerequisites'**
  String get coursePrerequisitesNone;

  /// No description provided for @courseTargetLearner.
  ///
  /// In en, this message translates to:
  /// **'Who it is for'**
  String get courseTargetLearner;

  /// No description provided for @courseTargetLearnerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Complete beginners who cannot yet read Arabic'**
  String get courseTargetLearnerHint;

  /// No description provided for @courseTrack.
  ///
  /// In en, this message translates to:
  /// **'Learning track'**
  String get courseTrack;

  /// No description provided for @courseTrackHint.
  ///
  /// In en, this message translates to:
  /// **'Reading, recitation, tajwīd, Qur\'anic Arabic… are different goals.'**
  String get courseTrackHint;

  /// No description provided for @languageNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get languageNotSet;

  /// No description provided for @lessonCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to {course} as a draft'**
  String lessonCopied(String course);

  /// No description provided for @lessonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy to another course…'**
  String get lessonCopy;

  /// No description provided for @lessonCopyTo.
  ///
  /// In en, this message translates to:
  /// **'Copy \"{lesson}\" to…'**
  String lessonCopyTo(String lesson);

  /// No description provided for @lessonEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get lessonEditDetails;

  /// No description provided for @lessonLanguage.
  ///
  /// In en, this message translates to:
  /// **'Taught in'**
  String get lessonLanguage;

  /// No description provided for @lessonLanguageFromCourse.
  ///
  /// In en, this message translates to:
  /// **'Same as the course: {languages}'**
  String lessonLanguageFromCourse(String languages);

  /// No description provided for @lessonLanguageSameAsCourse.
  ///
  /// In en, this message translates to:
  /// **'Same as the course'**
  String get lessonLanguageSameAsCourse;

  /// No description provided for @lessonLocation.
  ///
  /// In en, this message translates to:
  /// **'Where this lesson is'**
  String get lessonLocation;

  /// No description provided for @lessonMove.
  ///
  /// In en, this message translates to:
  /// **'Move…'**
  String get lessonMove;

  /// No description provided for @lessonMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move \"{lesson}\" to…'**
  String lessonMoveTo(String lesson);

  /// No description provided for @lessonMoveTop.
  ///
  /// In en, this message translates to:
  /// **'Top of the course (no unit)'**
  String get lessonMoveTop;

  /// No description provided for @lessonMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved to {place}'**
  String lessonMoved(String place);

  /// No description provided for @lessonNoOutcomes.
  ///
  /// In en, this message translates to:
  /// **'No learning outcomes yet. Add what the learner will be able to do.'**
  String get lessonNoOutcomes;

  /// No description provided for @lessonOutcomes.
  ///
  /// In en, this message translates to:
  /// **'Learning outcomes'**
  String get lessonOutcomes;

  /// No description provided for @lessonOutcomesHint.
  ///
  /// In en, this message translates to:
  /// **'One per line, e.g. \"Reads letters with fatḥah correctly\"'**
  String get lessonOutcomesHint;

  /// No description provided for @lessonOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get lessonOverview;

  /// No description provided for @lessonQuranReference.
  ///
  /// In en, this message translates to:
  /// **'Qur\'an reference'**
  String get lessonQuranReference;

  /// No description provided for @lessonQuranReferenceOptional.
  ///
  /// In en, this message translates to:
  /// **'Qur\'an reference (optional)'**
  String get lessonQuranReferenceOptional;

  /// No description provided for @lessonYouWill.
  ///
  /// In en, this message translates to:
  /// **'In this lesson you will'**
  String get lessonYouWill;

  /// No description provided for @marzExplain.
  ///
  /// In en, this message translates to:
  /// **'These tests run on the payments server, the only place that holds the MarzPay secret. No money moves: collections are tested with a request MarzPay must refuse. A real payment can only be proved by paying for a course and entering the PIN.'**
  String get marzExplain;

  /// No description provided for @marzLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String marzLastSeen(String time);

  /// No description provided for @marzNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'The payments server did not answer. Is it running?'**
  String get marzNoAnswer;

  /// No description provided for @marzResultsFrom.
  ///
  /// In en, this message translates to:
  /// **'Results from {time}'**
  String marzResultsFrom(String time);

  /// No description provided for @marzRunTests.
  ///
  /// In en, this message translates to:
  /// **'Test integration'**
  String get marzRunTests;

  /// No description provided for @marzRunning.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get marzRunning;

  /// No description provided for @marzServerOffline.
  ///
  /// In en, this message translates to:
  /// **'Payments server is not running: learners\' mobile-money payments wait until it is'**
  String get marzServerOffline;

  /// No description provided for @marzServerOnline.
  ///
  /// In en, this message translates to:
  /// **'Payments server is running'**
  String get marzServerOnline;

  /// No description provided for @marzTitle.
  ///
  /// In en, this message translates to:
  /// **'MarzPay (mobile money)'**
  String get marzTitle;

  /// No description provided for @provisionalBody.
  ///
  /// In en, this message translates to:
  /// **'Seeded as a starting point. A teacher or scholar should check it before learners use it.'**
  String get provisionalBody;

  /// No description provided for @provisionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get provisionalTitle;

  /// No description provided for @quranAyahFrom.
  ///
  /// In en, this message translates to:
  /// **'From āyah'**
  String get quranAyahFrom;

  /// No description provided for @quranAyahTo.
  ///
  /// In en, this message translates to:
  /// **'To āyah'**
  String get quranAyahTo;

  /// No description provided for @quranRef.
  ///
  /// In en, this message translates to:
  /// **'Qur\'an {ref}'**
  String quranRef(String ref);

  /// No description provided for @quranSurah.
  ///
  /// In en, this message translates to:
  /// **'Sūrah no.'**
  String get quranSurah;

  /// No description provided for @resourceAddLink.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get resourceAddLink;

  /// No description provided for @resourceCheckLink.
  ///
  /// In en, this message translates to:
  /// **'Check link'**
  String get resourceCheckLink;

  /// No description provided for @resourceFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get resourceFile;

  /// No description provided for @resourceHide.
  ///
  /// In en, this message translates to:
  /// **'Hide from learners'**
  String get resourceHide;

  /// No description provided for @resourceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get resourceLanguage;

  /// No description provided for @resourceLocked.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this file.'**
  String get resourceLocked;

  /// No description provided for @resourceLooksRight.
  ///
  /// In en, this message translates to:
  /// **'Looks right: save'**
  String get resourceLooksRight;

  /// No description provided for @resourceNotVerified.
  ///
  /// In en, this message translates to:
  /// **'not checked'**
  String get resourceNotVerified;

  /// No description provided for @resourceOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get resourceOpen;

  /// No description provided for @resourcePreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No automatic preview ({reason}). Check the address yourself before saving.'**
  String resourcePreviewUnavailable(String reason);

  /// No description provided for @resourceRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get resourceRemove;

  /// No description provided for @resourceRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from here? The file itself is kept.'**
  String resourceRemoveBody(String title);

  /// No description provided for @resourceSaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'I trust it: save'**
  String get resourceSaveAnyway;

  /// No description provided for @resourceShow.
  ///
  /// In en, this message translates to:
  /// **'Show to learners'**
  String get resourceShow;

  /// No description provided for @resourceSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get resourceSize;

  /// No description provided for @resourceType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get resourceType;

  /// No description provided for @resourceUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload file'**
  String get resourceUpload;

  /// No description provided for @resourceUploadNow.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get resourceUploadNow;

  /// No description provided for @resourceUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {name}'**
  String resourceUploading(String name);

  /// No description provided for @resourceVerified.
  ///
  /// In en, this message translates to:
  /// **'checked'**
  String get resourceVerified;

  /// No description provided for @resourcesNone.
  ///
  /// In en, this message translates to:
  /// **'No files or links yet.'**
  String get resourcesNone;

  /// No description provided for @resourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resourcesTitle;

  /// No description provided for @settingsPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get settingsPayments;

  /// No description provided for @subAttachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get subAttachFile;

  /// No description provided for @subAttempt.
  ///
  /// In en, this message translates to:
  /// **'attempt {n}'**
  String subAttempt(int n);

  /// No description provided for @subFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback for the learner'**
  String get subFeedback;

  /// No description provided for @subFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no files} =1{1 file} other{{count} files}}'**
  String subFilesCount(int count);

  /// No description provided for @subFromGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get subFromGallery;

  /// No description provided for @subHandIn.
  ///
  /// In en, this message translates to:
  /// **'Hand in'**
  String get subHandIn;

  /// No description provided for @subHandedIn.
  ///
  /// In en, this message translates to:
  /// **'Handed in. Your teacher has it.'**
  String get subHandedIn;

  /// No description provided for @subMarkReviewed.
  ///
  /// In en, this message translates to:
  /// **'Mark reviewed'**
  String get subMarkReviewed;

  /// No description provided for @subMarkUnderReview.
  ///
  /// In en, this message translates to:
  /// **'I\'m looking at it (under review)'**
  String get subMarkUnderReview;

  /// No description provided for @subNoneToReview.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get subNoneToReview;

  /// No description provided for @subPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Only you and your teachers can see what you hand in.'**
  String get subPrivacyNote;

  /// No description provided for @subReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get subReceived;

  /// No description provided for @subRequestResubmission.
  ///
  /// In en, this message translates to:
  /// **'Ask for a new try'**
  String get subRequestResubmission;

  /// No description provided for @subResubmit.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get subResubmit;

  /// No description provided for @subReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get subReturned;

  /// No description provided for @subReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get subReviewed;

  /// No description provided for @subSavedForLater.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. It will upload when you are online; tap Try again.'**
  String get subSavedForLater;

  /// No description provided for @subScoreOptional.
  ///
  /// In en, this message translates to:
  /// **'Score (optional)'**
  String get subScoreOptional;

  /// No description provided for @subSubmitAgain.
  ///
  /// In en, this message translates to:
  /// **'Hand in again'**
  String get subSubmitAgain;

  /// No description provided for @subSubmitWork.
  ///
  /// In en, this message translates to:
  /// **'Submit work'**
  String get subSubmitWork;

  /// No description provided for @subSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Handed in'**
  String get subSubmitted;

  /// No description provided for @subTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get subTakePhoto;

  /// No description provided for @subTeacherHint.
  ///
  /// In en, this message translates to:
  /// **'Work learners handed in to your lessons'**
  String get subTeacherHint;

  /// No description provided for @subTitle.
  ///
  /// In en, this message translates to:
  /// **'Submitted work'**
  String get subTitle;

  /// No description provided for @subUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get subUnderReview;

  /// No description provided for @subUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get subUploadFailed;

  /// No description provided for @subWaitingToUpload.
  ///
  /// In en, this message translates to:
  /// **'Waiting to upload (not handed in yet)'**
  String get subWaitingToUpload;

  /// No description provided for @subWorkTab.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get subWorkTab;

  /// No description provided for @subYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get subYourAnswer;

  /// No description provided for @subYourWork.
  ///
  /// In en, this message translates to:
  /// **'Your work: {status} (attempt {attempt})'**
  String subYourWork(String status, int attempt);

  /// No description provided for @taughtIn.
  ///
  /// In en, this message translates to:
  /// **'Taught in {languages}'**
  String taughtIn(String languages);

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @uploadUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploadUploading;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Sidra'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Sidra is {org}\'s learning app for the Qur\'an and the Islamic sciences. Teachers give each day\'s portion once, learners read, listen and record, and every learner still gets their teacher\'s personal correction.'**
  String aboutBody(String org);

  /// No description provided for @aboutBy.
  ///
  /// In en, this message translates to:
  /// **'Made for {org} by Xhenvolt.'**
  String aboutBy(String org);

  /// No description provided for @aboutLicences.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get aboutLicences;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (build {build})'**
  String aboutVersion(String version, String build);

  /// No description provided for @aboutWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get aboutWhatsNew;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Teaching insights'**
  String get analyticsTitle;

  /// No description provided for @analyticsDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String analyticsDays(int days);

  /// No description provided for @anWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get anWaiting;

  /// No description provided for @anWaitingQ.
  ///
  /// In en, this message translates to:
  /// **'Work not yet reviewed'**
  String get anWaitingQ;

  /// No description provided for @anTurnaround.
  ///
  /// In en, this message translates to:
  /// **'Review time'**
  String get anTurnaround;

  /// No description provided for @anTurnaroundQ.
  ///
  /// In en, this message translates to:
  /// **'Average time until first review'**
  String get anTurnaroundQ;

  /// No description provided for @anFirstTry.
  ///
  /// In en, this message translates to:
  /// **'Right first time'**
  String get anFirstTry;

  /// No description provided for @anFirstTryQ.
  ///
  /// In en, this message translates to:
  /// **'First attempts marked correct'**
  String get anFirstTryQ;

  /// No description provided for @anSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get anSubmissions;

  /// No description provided for @anSubmissionsQ.
  ///
  /// In en, this message translates to:
  /// **'Recordings and work handed in'**
  String get anSubmissionsQ;

  /// No description provided for @anIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Not finished'**
  String get anIncomplete;

  /// No description provided for @anIncompleteQ.
  ///
  /// In en, this message translates to:
  /// **'Portions still open after 3 days'**
  String get anIncompleteQ;

  /// No description provided for @anTopCorrections.
  ///
  /// In en, this message translates to:
  /// **'Most used corrections'**
  String get anTopCorrections;

  /// No description provided for @anTopCategories.
  ///
  /// In en, this message translates to:
  /// **'Most common mistakes'**
  String get anTopCategories;

  /// No description provided for @anRepeat.
  ///
  /// In en, this message translates to:
  /// **'Learners trying many times'**
  String get anRepeat;

  /// No description provided for @anByTeacher.
  ///
  /// In en, this message translates to:
  /// **'Reviews by teacher'**
  String get anByTeacher;

  /// No description provided for @anNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get anNone;

  /// No description provided for @attNew.
  ///
  /// In en, this message translates to:
  /// **'New work'**
  String get attNew;

  /// No description provided for @attResubmissions.
  ///
  /// In en, this message translates to:
  /// **'Tried again'**
  String get attResubmissions;

  /// No description provided for @attCorrection.
  ///
  /// In en, this message translates to:
  /// **'Waiting to try again'**
  String get attCorrection;

  /// No description provided for @attNotSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Not sent yet'**
  String get attNotSubmitted;

  /// No description provided for @attBehind.
  ///
  /// In en, this message translates to:
  /// **'Falling behind'**
  String get attBehind;

  /// No description provided for @attOpenPortions.
  ///
  /// In en, this message translates to:
  /// **'{count} portions open'**
  String attOpenPortions(int count);

  /// No description provided for @attAllClear.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs you right now.'**
  String get attAllClear;

  /// No description provided for @audioPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get audioPlay;

  /// No description provided for @audioPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get audioPause;

  /// No description provided for @audioRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get audioRecord;

  /// No description provided for @audioRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get audioRecording;

  /// No description provided for @audioPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get audioPaused;

  /// No description provided for @audioPauseRecording.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get audioPauseRecording;

  /// No description provided for @audioResume.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get audioResume;

  /// No description provided for @audioStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get audioStop;

  /// No description provided for @audioDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get audioDiscard;

  /// No description provided for @audioRecordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get audioRecordAgain;

  /// No description provided for @audioYourRecording.
  ///
  /// In en, this message translates to:
  /// **'Your recording ({duration})'**
  String audioYourRecording(String duration);

  /// No description provided for @audioNeedsMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Sidra needs the microphone to record. Allow it in your phone\'s settings.'**
  String get audioNeedsMicrophone;

  /// No description provided for @audioRecordFailed.
  ///
  /// In en, this message translates to:
  /// **'Recording did not work. Please try again.'**
  String get audioRecordFailed;

  /// No description provided for @audioCannotPlay.
  ///
  /// In en, this message translates to:
  /// **'This recording cannot be played.'**
  String get audioCannotPlay;

  /// No description provided for @audioLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio library'**
  String get audioLibraryTitle;

  /// No description provided for @audioSearch.
  ///
  /// In en, this message translates to:
  /// **'Search recordings'**
  String get audioSearch;

  /// No description provided for @audioOnlyMine.
  ///
  /// In en, this message translates to:
  /// **'Only mine'**
  String get audioOnlyMine;

  /// No description provided for @audioNone.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet'**
  String get audioNone;

  /// No description provided for @correctionLibrary.
  ///
  /// In en, this message translates to:
  /// **'Correction library'**
  String get correctionLibrary;

  /// No description provided for @correctionLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'Corrections saved while reviewing appear here, ready to reuse.'**
  String get correctionLibraryHint;

  /// No description provided for @correctionAdd.
  ///
  /// In en, this message translates to:
  /// **'New correction'**
  String get correctionAdd;

  /// No description provided for @correctionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search: ص, shaddah, madd…'**
  String get correctionSearch;

  /// No description provided for @correctionNone.
  ///
  /// In en, this message translates to:
  /// **'No corrections found'**
  String get correctionNone;

  /// No description provided for @correctionTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get correctionTitle;

  /// No description provided for @correctionTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Difference between ص and س'**
  String get correctionTitleHint;

  /// No description provided for @correctionCategory.
  ///
  /// In en, this message translates to:
  /// **'Mistake category'**
  String get correctionCategory;

  /// No description provided for @correctionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Short explanation (optional)'**
  String get correctionExplanation;

  /// No description provided for @correctionUsed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{not used yet} =1{used once} other{used {count} times}}'**
  String correctionUsed(int count);

  /// No description provided for @correctionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get correctionArchive;

  /// No description provided for @correctionForYou.
  ///
  /// In en, this message translates to:
  /// **'Correction for you'**
  String get correctionForYou;

  /// No description provided for @groupNew.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get groupNew;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @groupLearners.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No learners} =1{1 learner} other{{count} learners}}'**
  String groupLearners(int count);

  /// No description provided for @groupNoLearners.
  ///
  /// In en, this message translates to:
  /// **'No learners are enrolled in this course yet.'**
  String get groupNoLearners;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get groupMembers;

  /// No description provided for @groupWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String groupWaiting(int count);

  /// No description provided for @groupsNone.
  ///
  /// In en, this message translates to:
  /// **'No groups yet. Create one for a class you teach.'**
  String get groupsNone;

  /// No description provided for @myGroups.
  ///
  /// In en, this message translates to:
  /// **'My groups'**
  String get myGroups;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs my attention'**
  String get needsAttention;

  /// No description provided for @navTeaching.
  ///
  /// In en, this message translates to:
  /// **'Teaching'**
  String get navTeaching;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Content library'**
  String get libraryTitle;

  /// No description provided for @librarySearch.
  ///
  /// In en, this message translates to:
  /// **'Search files and links'**
  String get librarySearch;

  /// No description provided for @libraryRenameTag.
  ///
  /// In en, this message translates to:
  /// **'Rename or tag'**
  String get libraryRenameTag;

  /// No description provided for @libraryReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace with a new version'**
  String get libraryReplace;

  /// No description provided for @libraryReplaced.
  ///
  /// In en, this message translates to:
  /// **'New version saved. Work already assigned keeps the old one.'**
  String get libraryReplaced;

  /// No description provided for @libraryUsedIn.
  ///
  /// In en, this message translates to:
  /// **'in {lessons} lessons, {portions} portions'**
  String libraryUsedIn(int lessons, int portions);

  /// No description provided for @listenTeacher.
  ///
  /// In en, this message translates to:
  /// **'Listen to your teacher'**
  String get listenTeacher;

  /// No description provided for @listenModel.
  ///
  /// In en, this message translates to:
  /// **'Listen to the model reading'**
  String get listenModel;

  /// No description provided for @notSentYet.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. Your teacher has not received it yet.'**
  String get notSentYet;

  /// No description provided for @noteAdd.
  ///
  /// In en, this message translates to:
  /// **'Private note'**
  String get noteAdd;

  /// No description provided for @notePrivate.
  ///
  /// In en, this message translates to:
  /// **'Note (only teachers see it)'**
  String get notePrivate;

  /// No description provided for @notePrivateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Still confusing ض and ظ'**
  String get notePrivateHint;

  /// No description provided for @notesAbout.
  ///
  /// In en, this message translates to:
  /// **'Notes about {name}'**
  String notesAbout(String name);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsNone.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsNone;

  /// No description provided for @notificationsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkRead;

  /// No description provided for @partNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get partNew;

  /// No description provided for @partToDo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get partToDo;

  /// No description provided for @partWaiting.
  ///
  /// In en, this message translates to:
  /// **'Sent · waiting'**
  String get partWaiting;

  /// No description provided for @partUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Teacher is listening'**
  String get partUnderReview;

  /// No description provided for @partTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get partTryAgain;

  /// No description provided for @partDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get partDone;

  /// No description provided for @portionDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Page '**
  String get portionDefaultTitle;

  /// No description provided for @portionCreateToday.
  ///
  /// In en, this message translates to:
  /// **'Create today\'s portion'**
  String get portionCreateToday;

  /// No description provided for @portionCreateNext.
  ///
  /// In en, this message translates to:
  /// **'Next after {title}'**
  String portionCreateNext(String title);

  /// No description provided for @portionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Portions'**
  String get portionsTitle;

  /// No description provided for @portionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit portion'**
  String get portionEdit;

  /// No description provided for @portionTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get portionTitle;

  /// No description provided for @portionTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Page 12'**
  String get portionTitleHint;

  /// No description provided for @portionTask.
  ///
  /// In en, this message translates to:
  /// **'What learners should do'**
  String get portionTask;

  /// No description provided for @portionTaskHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Read this page three times. Watch the shaddah.'**
  String get portionTaskHint;

  /// No description provided for @portionExplainedIn.
  ///
  /// In en, this message translates to:
  /// **'Instructions given in'**
  String get portionExplainedIn;

  /// No description provided for @portionLearnersSend.
  ///
  /// In en, this message translates to:
  /// **'Learners send'**
  String get portionLearnersSend;

  /// No description provided for @portionPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get portionPage;

  /// No description provided for @portionAddPage.
  ///
  /// In en, this message translates to:
  /// **'Add page (photo, image or PDF)'**
  String get portionAddPage;

  /// No description provided for @portionInstruction.
  ///
  /// In en, this message translates to:
  /// **'Teacher instruction'**
  String get portionInstruction;

  /// No description provided for @portionRecordInstruction.
  ///
  /// In en, this message translates to:
  /// **'Record instruction'**
  String get portionRecordInstruction;

  /// No description provided for @portionModel.
  ///
  /// In en, this message translates to:
  /// **'Model recitation'**
  String get portionModel;

  /// No description provided for @portionRecordModel.
  ///
  /// In en, this message translates to:
  /// **'Record model'**
  String get portionRecordModel;

  /// No description provided for @portionFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'From my audio'**
  String get portionFromLibrary;

  /// No description provided for @portionUseRecording.
  ///
  /// In en, this message translates to:
  /// **'Use this recording'**
  String get portionUseRecording;

  /// No description provided for @portionAssignGroup.
  ///
  /// In en, this message translates to:
  /// **'Assign to the group'**
  String get portionAssignGroup;

  /// No description provided for @portionAssignChosen.
  ///
  /// In en, this message translates to:
  /// **'Assign to chosen learners'**
  String get portionAssignChosen;

  /// No description provided for @portionAssignCount.
  ///
  /// In en, this message translates to:
  /// **'Assign to {count}'**
  String portionAssignCount(int count);

  /// No description provided for @portionAssigned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Everyone already had it} =1{1 learner received it} other{{count} learners received it}}'**
  String portionAssigned(int count);

  /// No description provided for @portionSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get portionSaveDraft;

  /// No description provided for @portionNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned to anyone yet'**
  String get portionNotAssigned;

  /// No description provided for @portionBoardHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a learner to listen and review.'**
  String get portionBoardHint;

  /// No description provided for @recordHint.
  ///
  /// In en, this message translates to:
  /// **'Read the page aloud and record yourself.'**
  String get recordHint;

  /// No description provided for @recordAgainBelow.
  ///
  /// In en, this message translates to:
  /// **'Listen, then record again below.'**
  String get recordAgainBelow;

  /// No description provided for @resExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get resExcellent;

  /// No description provided for @resCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get resCorrect;

  /// No description provided for @resMinor.
  ///
  /// In en, this message translates to:
  /// **'Correct, small note'**
  String get resMinor;

  /// No description provided for @resCorrection.
  ///
  /// In en, this message translates to:
  /// **'Correction required'**
  String get resCorrection;

  /// No description provided for @resExplain.
  ///
  /// In en, this message translates to:
  /// **'Needs explanation'**
  String get resExplain;

  /// No description provided for @reviewCorrectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get reviewCorrectionTitle;

  /// No description provided for @reviewUseExisting.
  ///
  /// In en, this message translates to:
  /// **'Existing correction'**
  String get reviewUseExisting;

  /// No description provided for @reviewRecordNew.
  ///
  /// In en, this message translates to:
  /// **'Record new'**
  String get reviewRecordNew;

  /// No description provided for @reviewSaveToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to correction library'**
  String get reviewSaveToLibrary;

  /// No description provided for @reviewSaveToLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'Reuse it for the next learner with this mistake.'**
  String get reviewSaveToLibraryHint;

  /// No description provided for @reviewFeedbackOptional.
  ///
  /// In en, this message translates to:
  /// **'Written feedback (optional)'**
  String get reviewFeedbackOptional;

  /// No description provided for @reviewSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to the learner'**
  String get reviewSent;

  /// No description provided for @sendToTeacher.
  ///
  /// In en, this message translates to:
  /// **'Send to teacher'**
  String get sendToTeacher;

  /// No description provided for @sentToTeacher.
  ///
  /// In en, this message translates to:
  /// **'Sent. Your teacher has it.'**
  String get sentToTeacher;

  /// No description provided for @sentWaiting.
  ///
  /// In en, this message translates to:
  /// **'Sent: waiting for your teacher'**
  String get sentWaiting;

  /// No description provided for @sentWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'You will be told when your teacher replies.'**
  String get sentWaitingBody;

  /// No description provided for @teacherSays.
  ///
  /// In en, this message translates to:
  /// **'Your teacher: {text}'**
  String teacherSays(String text);

  /// No description provided for @theirRecording.
  ///
  /// In en, this message translates to:
  /// **'Their recording'**
  String get theirRecording;

  /// No description provided for @todayLearning.
  ///
  /// In en, this message translates to:
  /// **'Today\'s learning'**
  String get todayLearning;

  /// No description provided for @useThis.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get useThis;

  /// No description provided for @yourAttempts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Your attempt} other{Your {count} attempts}}'**
  String yourAttempts(int count);

  /// No description provided for @yourTask.
  ///
  /// In en, this message translates to:
  /// **'Your task'**
  String get yourTask;

  /// No description provided for @deleteLearner.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteLearner;

  /// No description provided for @deleteLearnerHint.
  ///
  /// In en, this message translates to:
  /// **'Erase this learner and everything about them'**
  String get deleteLearnerHint;

  /// No description provided for @deleteLearnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteLearnerTitle(String name);

  /// No description provided for @deleteLearnerBody.
  ///
  /// In en, this message translates to:
  /// **'This erases their account, enrolments, progress, recordings, photos, teacher notes and notifications. It cannot be undone. If they have made payments, the payments are kept for the accounts under \"Removed learner\", with no name or contact details.'**
  String get deleteLearnerBody;

  /// No description provided for @deleteLearnerTypeName.
  ///
  /// In en, this message translates to:
  /// **'Type \"{name}\" to confirm'**
  String deleteLearnerTypeName(String name);

  /// No description provided for @deleteReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional, kept in the activity log)'**
  String get deleteReason;

  /// No description provided for @deleteLearnerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteLearnerConfirm;

  /// No description provided for @deleteLearnerDone.
  ///
  /// In en, this message translates to:
  /// **'Learner deleted.'**
  String get deleteLearnerDone;

  /// No description provided for @deleteLearnerKept.
  ///
  /// In en, this message translates to:
  /// **'Learner deleted. Their payments are kept for the accounts as \"Removed learner\".'**
  String get deleteLearnerKept;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Mistake categories organise the correction library. Rename, reorder or add your own; deleting a category keeps its corrections.'**
  String get categoriesHint;

  /// No description provided for @categoryAdd.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoryAdd;

  /// No description provided for @categoryAddSub.
  ///
  /// In en, this message translates to:
  /// **'Add sub-category'**
  String get categoryAddSub;

  /// No description provided for @categoryRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get categoryRename;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoryName;

  /// No description provided for @categoryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get categoryDelete;

  /// No description provided for @categoryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and its sub-categories? Corrections in it are kept, without a category.'**
  String categoryDeleteBody(String name);

  /// No description provided for @resourcesForSection.
  ///
  /// In en, this message translates to:
  /// **'Resources for this section'**
  String get resourcesForSection;

  /// No description provided for @resourcesForUnit.
  ///
  /// In en, this message translates to:
  /// **'Resources for this unit'**
  String get resourcesForUnit;

  /// No description provided for @libraryUsageAccess.
  ///
  /// In en, this message translates to:
  /// **'Where used & who can see'**
  String get libraryUsageAccess;

  /// No description provided for @libraryWhoCanSee.
  ///
  /// In en, this message translates to:
  /// **'Who can see it'**
  String get libraryWhoCanSee;

  /// No description provided for @libraryAccessLearners.
  ///
  /// In en, this message translates to:
  /// **'Learners with access'**
  String get libraryAccessLearners;

  /// No description provided for @libraryAccessLearnersHint.
  ///
  /// In en, this message translates to:
  /// **'Only learners allowed into the lesson or course where it is used, and staff.'**
  String get libraryAccessLearnersHint;

  /// No description provided for @libraryAccessPublic.
  ///
  /// In en, this message translates to:
  /// **'Anyone viewing the course page'**
  String get libraryAccessPublic;

  /// No description provided for @libraryAccessPublicHint.
  ///
  /// In en, this message translates to:
  /// **'Also signed-in people not enrolled yet, e.g. a brochure or sample page.'**
  String get libraryAccessPublicHint;

  /// No description provided for @libraryUsedWhere.
  ///
  /// In en, this message translates to:
  /// **'Where it is used'**
  String get libraryUsedWhere;

  /// No description provided for @libraryAddTo.
  ///
  /// In en, this message translates to:
  /// **'Add to…'**
  String get libraryAddTo;

  /// No description provided for @libraryMoveHint.
  ///
  /// In en, this message translates to:
  /// **'To move it, add it to the new place, then remove it from the old one. Daily portions keep the files they were given.'**
  String get libraryMoveHint;

  /// No description provided for @libraryNotUsed.
  ///
  /// In en, this message translates to:
  /// **'Not used anywhere yet.'**
  String get libraryNotUsed;

  /// No description provided for @libraryAddToCourse.
  ///
  /// In en, this message translates to:
  /// **'Add to which course?'**
  String get libraryAddToCourse;

  /// No description provided for @libraryAddWhere.
  ///
  /// In en, this message translates to:
  /// **'Where in {course}?'**
  String libraryAddWhere(String course);

  /// No description provided for @libraryCoursePage.
  ///
  /// In en, this message translates to:
  /// **'Course page'**
  String get libraryCoursePage;

  /// No description provided for @librarySection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get librarySection;

  /// No description provided for @personTeachesIn.
  ///
  /// In en, this message translates to:
  /// **'Teaches in'**
  String get personTeachesIn;

  /// No description provided for @personTeachesInNone.
  ///
  /// In en, this message translates to:
  /// **'Not set. Tap to choose languages.'**
  String get personTeachesInNone;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @repLearners.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get repLearners;

  /// No description provided for @repLearnersQ.
  ///
  /// In en, this message translates to:
  /// **'Active accounts'**
  String get repLearnersQ;

  /// No description provided for @repActive.
  ///
  /// In en, this message translates to:
  /// **'Studying'**
  String get repActive;

  /// No description provided for @repActiveQ.
  ///
  /// In en, this message translates to:
  /// **'Learners who did something in this period'**
  String get repActiveQ;

  /// No description provided for @repNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get repNew;

  /// No description provided for @repNewQ.
  ///
  /// In en, this message translates to:
  /// **'Learners who joined in this period'**
  String get repNewQ;

  /// No description provided for @repCompletions.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get repCompletions;

  /// No description provided for @repCompletionsQ.
  ///
  /// In en, this message translates to:
  /// **'Courses completed in this period'**
  String get repCompletionsQ;

  /// No description provided for @repCourses.
  ///
  /// In en, this message translates to:
  /// **'Course completion'**
  String get repCourses;

  /// No description provided for @repCoursesQ.
  ///
  /// In en, this message translates to:
  /// **'Are learners getting through each course?'**
  String get repCoursesQ;

  /// No description provided for @repCourseLine.
  ///
  /// In en, this message translates to:
  /// **'{enrolled} enrolled · {completed} finished · {progress}% average progress · {active} active · {stalled} stalled'**
  String repCourseLine(
    int enrolled,
    int completed,
    int progress,
    int active,
    int stalled,
  );

  /// No description provided for @repQuiet.
  ///
  /// In en, this message translates to:
  /// **'Gone quiet'**
  String get repQuiet;

  /// No description provided for @repQuietQ.
  ///
  /// In en, this message translates to:
  /// **'Enrolled learners with no activity in {days} days: who should we follow up?'**
  String repQuietQ(int days);

  /// No description provided for @repNeverStarted.
  ///
  /// In en, this message translates to:
  /// **'never started'**
  String get repNeverStarted;

  /// No description provided for @repLastSeen.
  ///
  /// In en, this message translates to:
  /// **'last active {date}'**
  String repLastSeen(String date);

  /// No description provided for @repTeachers.
  ///
  /// In en, this message translates to:
  /// **'Teacher activity'**
  String get repTeachers;

  /// No description provided for @repTeachersQ.
  ///
  /// In en, this message translates to:
  /// **'Who is reviewing, how fast, and what is waiting on them?'**
  String get repTeachersQ;

  /// No description provided for @repTeacherReviews.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String repTeacherReviews(int count);

  /// No description provided for @repTeacherTurnaround.
  ///
  /// In en, this message translates to:
  /// **'{hours} h to review'**
  String repTeacherTurnaround(String hours);

  /// No description provided for @repTeacherWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String repTeacherWaiting(int count);

  /// No description provided for @avatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get avatarTitle;

  /// No description provided for @avatarChange.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get avatarChange;

  /// No description provided for @avatarTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get avatarTakePhoto;

  /// No description provided for @avatarUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload from the phone'**
  String get avatarUpload;

  /// No description provided for @avatarChoose.
  ///
  /// In en, this message translates to:
  /// **'Or choose an avatar'**
  String get avatarChoose;

  /// No description provided for @avatarRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get avatarRemove;

  /// No description provided for @avatarSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get avatarSaved;

  /// No description provided for @viewerDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get viewerDownloading;

  /// No description provided for @viewerOpenAgain.
  ///
  /// In en, this message translates to:
  /// **'Open again'**
  String get viewerOpenAgain;

  /// No description provided for @viewerNoApp.
  ///
  /// In en, this message translates to:
  /// **'No app on this phone can open this kind of document. Install a document app (e.g. Microsoft Word, WPS Office) and try again.'**
  String get viewerNoApp;

  /// No description provided for @capPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get capPhoto;

  /// No description provided for @capVideo.
  ///
  /// In en, this message translates to:
  /// **'Record video'**
  String get capVideo;

  /// No description provided for @capScan.
  ///
  /// In en, this message translates to:
  /// **'Scan pages (PDF)'**
  String get capScan;

  /// No description provided for @capAudio.
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get capAudio;

  /// No description provided for @capGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get capGallery;

  /// No description provided for @capFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get capFile;

  /// No description provided for @capPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste text'**
  String get capPaste;

  /// No description provided for @capFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open: {reason}'**
  String capFailed(String reason);

  /// No description provided for @capSize.
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String capSize(String size);

  /// No description provided for @capPages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String capPages(int count);

  /// No description provided for @capLarge.
  ///
  /// In en, this message translates to:
  /// **'This is a large file. Uploading it uses a lot of mobile data; Wi-Fi is better.'**
  String get capLarge;

  /// No description provided for @capUse.
  ///
  /// In en, this message translates to:
  /// **'Upload this'**
  String get capUse;

  /// No description provided for @capAddContent.
  ///
  /// In en, this message translates to:
  /// **'Add: take, record, scan or choose'**
  String get capAddContent;

  /// No description provided for @capAddWork.
  ///
  /// In en, this message translates to:
  /// **'Add photo, scan or file'**
  String get capAddWork;

  /// No description provided for @capClipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is no text to paste. Copy some text first.'**
  String get capClipboardEmpty;

  /// No description provided for @capPasted.
  ///
  /// In en, this message translates to:
  /// **'Text added. Tap it to edit.'**
  String get capPasted;

  /// No description provided for @layoutGrid.
  ///
  /// In en, this message translates to:
  /// **'Show as grid'**
  String get layoutGrid;

  /// No description provided for @layoutList.
  ///
  /// In en, this message translates to:
  /// **'Show as list'**
  String get layoutList;

  /// No description provided for @topCourses.
  ///
  /// In en, this message translates to:
  /// **'Top courses'**
  String get topCourses;

  /// No description provided for @topCoursesLearners.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 learner} other{{count} learners}}'**
  String topCoursesLearners(int count);

  /// No description provided for @allCourses.
  ///
  /// In en, this message translates to:
  /// **'All courses'**
  String get allCourses;

  /// No description provided for @previewAsLearner.
  ///
  /// In en, this message translates to:
  /// **'Preview as learner'**
  String get previewAsLearner;

  /// No description provided for @previewAsLearnerHint.
  ///
  /// In en, this message translates to:
  /// **'See the app exactly as learners see it'**
  String get previewAsLearnerHint;

  /// No description provided for @previewBanner.
  ///
  /// In en, this message translates to:
  /// **'You are previewing as a learner'**
  String get previewBanner;

  /// No description provided for @previewExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get previewExit;

  /// No description provided for @previewNoProgress.
  ///
  /// In en, this message translates to:
  /// **'Preview: progress is recorded for learners only'**
  String get previewNoProgress;

  /// No description provided for @rulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson rules'**
  String get rulesTitle;

  /// No description provided for @rulesHint.
  ///
  /// In en, this message translates to:
  /// **'How a learner moves from one lesson to the next. The database enforces this: learners cannot open locked lessons.'**
  String get rulesHint;

  /// No description provided for @ruleApproval.
  ///
  /// In en, this message translates to:
  /// **'After the teacher approves the work'**
  String get ruleApproval;

  /// No description provided for @ruleApprovalHint.
  ///
  /// In en, this message translates to:
  /// **'The learner hands in work; the teacher marks it (word by word if wished). A score at or above the pass mark unlocks the next lesson.'**
  String get ruleApprovalHint;

  /// No description provided for @ruleSubmission.
  ///
  /// In en, this message translates to:
  /// **'After handing in work'**
  String get ruleSubmission;

  /// No description provided for @ruleSubmissionHint.
  ///
  /// In en, this message translates to:
  /// **'Handing in the lesson\'s work unlocks the next lesson; the teacher reviews it afterwards.'**
  String get ruleSubmissionHint;

  /// No description provided for @ruleTeacherHint.
  ///
  /// In en, this message translates to:
  /// **'The teacher unlocks each next lesson by hand.'**
  String get ruleTeacherHint;

  /// No description provided for @ruleSequentialHint.
  ///
  /// In en, this message translates to:
  /// **'Finishing (reading) a lesson unlocks the next.'**
  String get ruleSequentialHint;

  /// No description provided for @ruleOpenHint.
  ///
  /// In en, this message translates to:
  /// **'All lessons are open in any order.'**
  String get ruleOpenHint;

  /// No description provided for @rulePassMark.
  ///
  /// In en, this message translates to:
  /// **'Pass mark: {percent}%'**
  String rulePassMark(int percent);

  /// No description provided for @ruleMaxAttempts.
  ///
  /// In en, this message translates to:
  /// **'Maximum attempts per lesson (optional)'**
  String get ruleMaxAttempts;

  /// No description provided for @ruleMaxAttemptsHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for unlimited tries.'**
  String get ruleMaxAttemptsHint;

  /// No description provided for @courseNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications for this course'**
  String get courseNotifications;

  /// No description provided for @courseNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Switch off what this course should not send. Switches under Settings apply to every course.'**
  String get courseNotificationsHint;

  /// No description provided for @notifyLessonWork.
  ///
  /// In en, this message translates to:
  /// **'New work for teachers'**
  String get notifyLessonWork;

  /// No description provided for @notifyReviewed.
  ///
  /// In en, this message translates to:
  /// **'Work approved (to learners)'**
  String get notifyReviewed;

  /// No description provided for @notifyCorrection.
  ///
  /// In en, this message translates to:
  /// **'Corrections (to learners)'**
  String get notifyCorrection;

  /// No description provided for @notifyPortionAssigned.
  ///
  /// In en, this message translates to:
  /// **'New daily portion (to learners)'**
  String get notifyPortionAssigned;

  /// No description provided for @notifySubmission.
  ///
  /// In en, this message translates to:
  /// **'Portion recordings (to teachers)'**
  String get notifySubmission;

  /// No description provided for @notifyResubmission.
  ///
  /// In en, this message translates to:
  /// **'Tried again (to teachers)'**
  String get notifyResubmission;

  /// No description provided for @lessonWorkRequired.
  ///
  /// In en, this message translates to:
  /// **'Needs handed-in work'**
  String get lessonWorkRequired;

  /// No description provided for @lessonWorkFollowsCourse.
  ///
  /// In en, this message translates to:
  /// **'Follows the course rule ({answer})'**
  String lessonWorkFollowsCourse(String answer);

  /// No description provided for @lessonWorkFollowCourse.
  ///
  /// In en, this message translates to:
  /// **'Follow the course rule'**
  String get lessonWorkFollowCourse;

  /// No description provided for @lessonWorkYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, learners hand in work'**
  String get lessonWorkYes;

  /// No description provided for @lessonWorkNo.
  ///
  /// In en, this message translates to:
  /// **'No work for this lesson'**
  String get lessonWorkNo;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @workSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit work'**
  String get workSubmit;

  /// No description provided for @workSubmitAgain.
  ///
  /// In en, this message translates to:
  /// **'Submit again'**
  String get workSubmitAgain;

  /// No description provided for @workTitle.
  ///
  /// In en, this message translates to:
  /// **'Your work'**
  String get workTitle;

  /// No description provided for @workHint.
  ///
  /// In en, this message translates to:
  /// **'Record your reading, or add a photo, scan or file of your work, then send it to your teacher.'**
  String get workHint;

  /// No description provided for @workAnswer.
  ///
  /// In en, this message translates to:
  /// **'Written answer (optional)'**
  String get workAnswer;

  /// No description provided for @workWaiting.
  ///
  /// In en, this message translates to:
  /// **'Handed in: waiting for your teacher'**
  String get workWaiting;

  /// No description provided for @workApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved. The next lesson is open.'**
  String get workApproved;

  /// No description provided for @workApprovedNoUnlock.
  ///
  /// In en, this message translates to:
  /// **'Approved.'**
  String get workApprovedNoUnlock;

  /// No description provided for @workTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Your teacher asks you to try again'**
  String get workTryAgain;

  /// No description provided for @workScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}% (pass mark {pass}%)'**
  String workScore(String score, int pass);

  /// No description provided for @workNeededToFinish.
  ///
  /// In en, this message translates to:
  /// **'Hand in your work to finish this lesson'**
  String get workNeededToFinish;

  /// No description provided for @workQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson work'**
  String get workQueueTitle;

  /// No description provided for @workQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No lesson work waiting'**
  String get workQueueEmpty;

  /// No description provided for @workMarkWords.
  ///
  /// In en, this message translates to:
  /// **'Mark word by word'**
  String get workMarkWords;

  /// No description provided for @workMarkWordsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a word: correct → weak → wrong. The score follows your marks; you can still adjust it.'**
  String get workMarkWordsHint;

  /// No description provided for @workScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall score: {score}%'**
  String workScoreLabel(int score);

  /// No description provided for @workWillPass.
  ///
  /// In en, this message translates to:
  /// **'Passes (pass mark {pass}%): the next lesson will open'**
  String workWillPass(int pass);

  /// No description provided for @workWillFail.
  ///
  /// In en, this message translates to:
  /// **'Below the pass mark ({pass}%): the learner will be asked to try again'**
  String workWillFail(int pass);

  /// No description provided for @workApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get workApprove;

  /// No description provided for @workNeedsCorrection.
  ///
  /// In en, this message translates to:
  /// **'Needs correction'**
  String get workNeedsCorrection;

  /// No description provided for @workNoText.
  ///
  /// In en, this message translates to:
  /// **'This lesson has no Qur\'anic text to mark word by word; give an overall score.'**
  String get workNoText;

  /// No description provided for @workLegend.
  ///
  /// In en, this message translates to:
  /// **'correct · weak · wrong'**
  String get workLegend;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Switch off a kind of notification for every course. Courses can also switch them off one by one.'**
  String get settingsNotificationsHint;

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inboxTitle;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting for you'**
  String get inboxEmpty;

  /// No description provided for @inboxWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 piece of work waiting} other{{count} pieces of work waiting}}'**
  String inboxWaiting(int count);

  /// No description provided for @inboxAutoNext.
  ///
  /// In en, this message translates to:
  /// **'Review next automatically'**
  String get inboxAutoNext;

  /// No description provided for @inboxAutoNextHint.
  ///
  /// In en, this message translates to:
  /// **'After you finish one, the next opens so you can mark a whole class in one go.'**
  String get inboxAutoNextHint;

  /// No description provided for @authErrorSignupClosed.
  ///
  /// In en, this message translates to:
  /// **'{org} is not taking new sign-ups right now. Ask them to add you.'**
  String authErrorSignupClosed(String org);

  /// No description provided for @settingsOrgNameAr.
  ///
  /// In en, this message translates to:
  /// **'Organisation name in Arabic'**
  String get settingsOrgNameAr;

  /// No description provided for @settingsSignupSecurity.
  ///
  /// In en, this message translates to:
  /// **'Sign-up and security'**
  String get settingsSignupSecurity;

  /// No description provided for @settingsAllowSignup.
  ///
  /// In en, this message translates to:
  /// **'Anyone can create an account'**
  String get settingsAllowSignup;

  /// No description provided for @settingsAllowSignupHint.
  ///
  /// In en, this message translates to:
  /// **'When off, only staff can add learners.'**
  String get settingsAllowSignupHint;

  /// No description provided for @settingsMinPassword.
  ///
  /// In en, this message translates to:
  /// **'Shortest password allowed (6–64)'**
  String get settingsMinPassword;

  /// No description provided for @settingsLockoutAttempts.
  ///
  /// In en, this message translates to:
  /// **'Wrong passwords before an account is locked (3–20)'**
  String get settingsLockoutAttempts;

  /// No description provided for @settingsLockoutMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes an account stays locked'**
  String get settingsLockoutMinutes;

  /// No description provided for @settingsTeachingDefaults.
  ///
  /// In en, this message translates to:
  /// **'Teaching defaults'**
  String get settingsTeachingDefaults;

  /// No description provided for @settingsTeachingDefaultsHint.
  ///
  /// In en, this message translates to:
  /// **'Used for new courses and for teachers\' attention lists.'**
  String get settingsTeachingDefaultsHint;

  /// No description provided for @settingsStaleDays.
  ///
  /// In en, this message translates to:
  /// **'Days before unreviewed work needs attention'**
  String get settingsStaleDays;

  /// No description provided for @settingsFallingBehind.
  ///
  /// In en, this message translates to:
  /// **'Portions behind before a learner is flagged'**
  String get settingsFallingBehind;

  /// No description provided for @settingsDefaultRule.
  ///
  /// In en, this message translates to:
  /// **'Lesson rule for new courses'**
  String get settingsDefaultRule;

  /// No description provided for @settingsDefaultPassMark.
  ///
  /// In en, this message translates to:
  /// **'Pass mark for new courses: {n}%'**
  String settingsDefaultPassMark(int n);

  /// No description provided for @settingsAppUpdates.
  ///
  /// In en, this message translates to:
  /// **'App updates'**
  String get settingsAppUpdates;

  /// No description provided for @settingsAppUpdatesHint.
  ///
  /// In en, this message translates to:
  /// **'When you publish a new version, phones with an older one are asked to update.'**
  String get settingsAppUpdatesHint;

  /// No description provided for @settingsLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'Newest version (e.g. 2.27.0)'**
  String get settingsLatestVersion;

  /// No description provided for @settingsLatestBuild.
  ///
  /// In en, this message translates to:
  /// **'Newest build number'**
  String get settingsLatestBuild;

  /// No description provided for @settingsDownloadUrl.
  ///
  /// In en, this message translates to:
  /// **'Download link (https://…)'**
  String get settingsDownloadUrl;

  /// No description provided for @settingsMinBuild.
  ///
  /// In en, this message translates to:
  /// **'Oldest build still allowed'**
  String get settingsMinBuild;

  /// No description provided for @settingsMinBuildHint.
  ///
  /// In en, this message translates to:
  /// **'Older phones must update before continuing. Leave empty to allow all.'**
  String get settingsMinBuildHint;

  /// No description provided for @settingsThisBuild.
  ///
  /// In en, this message translates to:
  /// **'This phone has version {version} (build {build}).'**
  String settingsThisBuild(String version, String build);

  /// No description provided for @settingsLanguagesTracks.
  ///
  /// In en, this message translates to:
  /// **'Languages and learning tracks'**
  String get settingsLanguagesTracks;

  /// No description provided for @settingsLanguagesTracksHint.
  ///
  /// In en, this message translates to:
  /// **'What courses are taught in and grouped by'**
  String get settingsLanguagesTracksHint;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get settingsExport;

  /// No description provided for @settingsExportHint.
  ///
  /// In en, this message translates to:
  /// **'Learners, enrolments, payments and progress as spreadsheets'**
  String get settingsExportHint;

  /// No description provided for @langTitle.
  ///
  /// In en, this message translates to:
  /// **'Languages and tracks'**
  String get langTitle;

  /// No description provided for @langLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get langLanguages;

  /// No description provided for @langTracks.
  ///
  /// In en, this message translates to:
  /// **'Learning tracks'**
  String get langTracks;

  /// No description provided for @langAdd.
  ///
  /// In en, this message translates to:
  /// **'Add language'**
  String get langAdd;

  /// No description provided for @trackAdd.
  ///
  /// In en, this message translates to:
  /// **'Add track'**
  String get trackAdd;

  /// No description provided for @langCode.
  ///
  /// In en, this message translates to:
  /// **'Code (e.g. fr)'**
  String get langCode;

  /// No description provided for @langName.
  ///
  /// In en, this message translates to:
  /// **'Name in English'**
  String get langName;

  /// No description provided for @langNative.
  ///
  /// In en, this message translates to:
  /// **'Name in the language itself'**
  String get langNative;

  /// No description provided for @langRtl.
  ///
  /// In en, this message translates to:
  /// **'Written right to left'**
  String get langRtl;

  /// No description provided for @langActive.
  ///
  /// In en, this message translates to:
  /// **'Available for courses'**
  String get langActive;

  /// No description provided for @langHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get langHidden;

  /// No description provided for @langCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 2–3 lowercase letters, like fr'**
  String get langCodeInvalid;

  /// No description provided for @trackKey.
  ///
  /// In en, this message translates to:
  /// **'Short key (e.g. fiqh)'**
  String get trackKey;

  /// No description provided for @trackKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Lowercase letters, digits and _, starting with a letter'**
  String get trackKeyInvalid;

  /// No description provided for @trackName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get trackName;

  /// No description provided for @trackDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get trackDescription;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportTitle;

  /// No description provided for @exportLearners.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get exportLearners;

  /// No description provided for @exportLearnersHint.
  ///
  /// In en, this message translates to:
  /// **'Every learner with contacts and number of courses'**
  String get exportLearnersHint;

  /// No description provided for @exportEnrolments.
  ///
  /// In en, this message translates to:
  /// **'Enrolments'**
  String get exportEnrolments;

  /// No description provided for @exportEnrolmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Who is in which course and how far they are'**
  String get exportEnrolmentsHint;

  /// No description provided for @exportPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get exportPayments;

  /// No description provided for @exportPaymentsHint.
  ///
  /// In en, this message translates to:
  /// **'Every payment and its status'**
  String get exportPaymentsHint;

  /// No description provided for @exportProgress.
  ///
  /// In en, this message translates to:
  /// **'Lesson progress'**
  String get exportProgress;

  /// No description provided for @exportProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Each learner\'s progress lesson by lesson'**
  String get exportProgressHint;

  /// No description provided for @exportSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} rows'**
  String exportSaved(int count);

  /// No description provided for @exportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export yet'**
  String get exportEmpty;

  /// No description provided for @exportNote.
  ///
  /// In en, this message translates to:
  /// **'Files open in Excel, Google Sheets or any spreadsheet app.'**
  String get exportNote;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'A new version is ready'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'Sidra {version} is available with the latest improvements.'**
  String updateAvailableBody(String version);

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Please update Sidra'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported. Download the new one to continue.'**
  String get updateRequiredBody;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @authErrorTryLater.
  ///
  /// In en, this message translates to:
  /// **'Too many sign-in attempts right now. Please wait a minute and try again.'**
  String get authErrorTryLater;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String timeHoursAgo(int n);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{yesterday} other{{n} days ago}}'**
  String timeDaysAgo(int n);

  /// No description provided for @presenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Who\'s online'**
  String get presenceTitle;

  /// No description provided for @presenceMenuHint.
  ///
  /// In en, this message translates to:
  /// **'Signed-in phones, last seen and last used'**
  String get presenceMenuHint;

  /// No description provided for @presenceHint.
  ///
  /// In en, this message translates to:
  /// **'Signed in, online and using the app are different: a phone can be signed in but offline, or online with nobody using it.'**
  String get presenceHint;

  /// No description provided for @presenceSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get presenceSearch;

  /// No description provided for @presenceSignedIn.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Signed in on 1 phone} other{Signed in on {n} phones}}'**
  String presenceSignedIn(int n);

  /// No description provided for @presenceSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get presenceSignedOut;

  /// No description provided for @presenceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get presenceOnline;

  /// No description provided for @presenceActiveNow.
  ///
  /// In en, this message translates to:
  /// **'Using Sidra now'**
  String get presenceActiveNow;

  /// No description provided for @presenceLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {when}'**
  String presenceLastSeen(String when);

  /// No description provided for @presenceLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last used {when}'**
  String presenceLastActive(String when);

  /// No description provided for @presenceNeverSeen.
  ///
  /// In en, this message translates to:
  /// **'Not seen yet'**
  String get presenceNeverSeen;

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices and sign-ins'**
  String get devicesTitle;

  /// No description provided for @devicesMine.
  ///
  /// In en, this message translates to:
  /// **'Your devices'**
  String get devicesMine;

  /// No description provided for @devicesPersonHint.
  ///
  /// In en, this message translates to:
  /// **'Phones, who is online, sign-in history; sign out a lost phone'**
  String get devicesPersonHint;

  /// No description provided for @devicesHint.
  ///
  /// In en, this message translates to:
  /// **'Every phone that signed in to this account. Signing out a phone ends it at once; the password is needed to use it again.'**
  String get devicesHint;

  /// No description provided for @devicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No devices yet. Phones appear after they sign in with Sidra 2.28 or newer.'**
  String get devicesEmpty;

  /// No description provided for @devicesEndAll.
  ///
  /// In en, this message translates to:
  /// **'Sign out everywhere'**
  String get devicesEndAll;

  /// No description provided for @devicesEndAllBody.
  ///
  /// In en, this message translates to:
  /// **'Every phone signed in to this account is signed out at once. The password is needed to sign in again.'**
  String get devicesEndAllBody;

  /// No description provided for @devicesEndAllDone.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No phone was signed in} =1{Signed out 1 phone} other{Signed out {n} phones}}'**
  String devicesEndAllDone(int n);

  /// No description provided for @deviceThis.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get deviceThis;

  /// No description provided for @deviceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown phone'**
  String get deviceUnknown;

  /// No description provided for @deviceApp.
  ///
  /// In en, this message translates to:
  /// **'Sidra {version} (build {build})'**
  String deviceApp(String version, String build);

  /// No description provided for @deviceAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android {version} (API {sdk})'**
  String deviceAndroid(String version, String sdk);

  /// No description provided for @deviceNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network: {network}'**
  String deviceNetwork(String network);

  /// No description provided for @deviceNotificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications blocked'**
  String get deviceNotificationsOff;

  /// No description provided for @deviceMicOff.
  ///
  /// In en, this message translates to:
  /// **'Microphone not allowed'**
  String get deviceMicOff;

  /// No description provided for @deviceLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last synced {when}'**
  String deviceLastSync(String when);

  /// No description provided for @deviceFirstSeen.
  ///
  /// In en, this message translates to:
  /// **'First seen {when}'**
  String deviceFirstSeen(String when);

  /// No description provided for @deviceRevoke.
  ///
  /// In en, this message translates to:
  /// **'Sign out this phone'**
  String get deviceRevoke;

  /// No description provided for @deviceRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out this phone?'**
  String get deviceRevokeTitle;

  /// No description provided for @deviceRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'It stops working at once and needs the password to sign in again. Use this for a lost or stolen phone.'**
  String get deviceRevokeBody;

  /// No description provided for @deviceRevokeReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get deviceRevokeReason;

  /// No description provided for @deviceRevokedBy.
  ///
  /// In en, this message translates to:
  /// **'Signed out by {name} {when}. {reason}'**
  String deviceRevokedBy(String name, String when, String reason);

  /// No description provided for @authHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-in history'**
  String get authHistoryTitle;

  /// No description provided for @authEventSignIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get authEventSignIn;

  /// No description provided for @authEventSignedUp.
  ///
  /// In en, this message translates to:
  /// **'Created the account'**
  String get authEventSignedUp;

  /// No description provided for @authEventFailed.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get authEventFailed;

  /// No description provided for @authEventLocked.
  ///
  /// In en, this message translates to:
  /// **'Tried while locked'**
  String get authEventLocked;

  /// No description provided for @authEventDisabled.
  ///
  /// In en, this message translates to:
  /// **'Tried while the account was disabled'**
  String get authEventDisabled;

  /// No description provided for @authEventSignOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get authEventSignOut;

  /// No description provided for @authEventRefreshRejected.
  ///
  /// In en, this message translates to:
  /// **'An ended sign-in was used again (refused)'**
  String get authEventRefreshRejected;

  /// No description provided for @authEventDeviceRevoked.
  ///
  /// In en, this message translates to:
  /// **'A phone was signed out'**
  String get authEventDeviceRevoked;

  /// No description provided for @authEventSessionsEnded.
  ///
  /// In en, this message translates to:
  /// **'Signed out everywhere'**
  String get authEventSessionsEnded;

  /// No description provided for @authEventPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed the password'**
  String get authEventPasswordChanged;

  /// No description provided for @issueReport.
  ///
  /// In en, this message translates to:
  /// **'I have a problem with this work'**
  String get issueReport;

  /// No description provided for @issueReportHint.
  ///
  /// In en, this message translates to:
  /// **'Tell your teacher what is stopping you. The deadline waits while your report is open.'**
  String get issueReportHint;

  /// No description provided for @issueDontUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I don\'t understand the work'**
  String get issueDontUnderstand;

  /// No description provided for @issueClarification.
  ///
  /// In en, this message translates to:
  /// **'I need clarification'**
  String get issueClarification;

  /// No description provided for @issueMoreTime.
  ///
  /// In en, this message translates to:
  /// **'I need more time'**
  String get issueMoreTime;

  /// No description provided for @issueUnavailable.
  ///
  /// In en, this message translates to:
  /// **'I am sick or unavailable'**
  String get issueUnavailable;

  /// No description provided for @issueTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical problem'**
  String get issueTechnical;

  /// No description provided for @issueCannotAccess.
  ///
  /// In en, this message translates to:
  /// **'I can\'t open the material'**
  String get issueCannotAccess;

  /// No description provided for @issueCannotRecord.
  ///
  /// In en, this message translates to:
  /// **'I can\'t record audio'**
  String get issueCannotRecord;

  /// No description provided for @issueCannotUpload.
  ///
  /// In en, this message translates to:
  /// **'I can\'t upload'**
  String get issueCannotUpload;

  /// No description provided for @issueOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get issueOther;

  /// No description provided for @issueMessage.
  ///
  /// In en, this message translates to:
  /// **'Explain (optional)'**
  String get issueMessage;

  /// No description provided for @issueAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get issueAttach;

  /// No description provided for @issueAttachHint.
  ///
  /// In en, this message translates to:
  /// **'Add a photo, recording or file if it helps'**
  String get issueAttachHint;

  /// No description provided for @issueSend.
  ///
  /// In en, this message translates to:
  /// **'Send to my teacher'**
  String get issueSend;

  /// No description provided for @issueSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. Your teacher will answer here.'**
  String get issueSent;

  /// No description provided for @issueSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Problem reported: waiting for your teacher'**
  String get issueSentTitle;

  /// No description provided for @issueAnsweredTitle.
  ///
  /// In en, this message translates to:
  /// **'Your teacher answered'**
  String get issueAnsweredTitle;

  /// No description provided for @issueNewDue.
  ///
  /// In en, this message translates to:
  /// **'New due time: {when}'**
  String issueNewDue(String when);

  /// No description provided for @issuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Problem reports'**
  String get issuesTitle;

  /// No description provided for @issuesOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get issuesOpen;

  /// No description provided for @issuesResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get issuesResolved;

  /// No description provided for @issuesNone.
  ///
  /// In en, this message translates to:
  /// **'No problem reports'**
  String get issuesNone;

  /// No description provided for @issuesWaiting.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 learner reported a problem} other{{n} learners reported problems}}'**
  String issuesWaiting(int n);

  /// No description provided for @issueOpenAttachment.
  ///
  /// In en, this message translates to:
  /// **'Open attachment'**
  String get issueOpenAttachment;

  /// No description provided for @issueRespond.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get issueRespond;

  /// No description provided for @issueYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get issueYourAnswer;

  /// No description provided for @issueGiveMoreTime.
  ///
  /// In en, this message translates to:
  /// **'Give more time (optional)'**
  String get issueGiveMoreTime;

  /// No description provided for @issueMarkResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark as resolved'**
  String get issueMarkResolved;

  /// No description provided for @issueSendAnswer.
  ///
  /// In en, this message translates to:
  /// **'Send answer'**
  String get issueSendAnswer;

  /// No description provided for @lateWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Late work'**
  String get lateWorkTitle;

  /// No description provided for @lateWorkHint.
  ///
  /// In en, this message translates to:
  /// **'Created automatically by the learner policies in Settings. Handing in the work closes them.'**
  String get lateWorkHint;

  /// No description provided for @lateWorkNone.
  ///
  /// In en, this message translates to:
  /// **'Nobody is late'**
  String get lateWorkNone;

  /// No description provided for @lateWorkCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 late-work alert} other{{n} late-work alerts}}'**
  String lateWorkCount(int n);

  /// No description provided for @lateWorkHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h late'**
  String lateWorkHours(int n);

  /// No description provided for @lateWorkReinstate.
  ///
  /// In en, this message translates to:
  /// **'Reinstate'**
  String get lateWorkReinstate;

  /// No description provided for @lateWorkRunNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get lateWorkRunNow;

  /// No description provided for @policyNotOpened.
  ///
  /// In en, this message translates to:
  /// **'Hasn\'t opened the work'**
  String get policyNotOpened;

  /// No description provided for @policyNotSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Opened, not handed in'**
  String get policyNotSubmitted;

  /// No description provided for @policyOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get policyOverdue;

  /// No description provided for @policyEscalated.
  ///
  /// In en, this message translates to:
  /// **'Escalated to administrators'**
  String get policyEscalated;

  /// No description provided for @policySuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended from the course'**
  String get policySuspended;

  /// No description provided for @policyInactive.
  ///
  /// In en, this message translates to:
  /// **'Not using Sidra'**
  String get policyInactive;

  /// No description provided for @policyReinstated.
  ///
  /// In en, this message translates to:
  /// **'Reinstated'**
  String get policyReinstated;

  /// No description provided for @policyTitle.
  ///
  /// In en, this message translates to:
  /// **'Learner policies'**
  String get policyTitle;

  /// No description provided for @policyHint.
  ///
  /// In en, this message translates to:
  /// **'Reminders and late-work rules. Times count from the due time; a problem report pauses them and a teacher\'s extension moves them.'**
  String get policyHint;

  /// No description provided for @policyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Send reminders and late-work alerts'**
  String get policyEnabled;

  /// No description provided for @policyWarnHours.
  ///
  /// In en, this message translates to:
  /// **'Remind the learner after (hours late)'**
  String get policyWarnHours;

  /// No description provided for @policyWarnHoursHint.
  ///
  /// In en, this message translates to:
  /// **'Tells them whether they haven\'t opened the work or haven\'t handed it in.'**
  String get policyWarnHoursHint;

  /// No description provided for @policyOverdueHours.
  ///
  /// In en, this message translates to:
  /// **'Tell the teacher after (hours late)'**
  String get policyOverdueHours;

  /// No description provided for @policyEscalateDays.
  ///
  /// In en, this message translates to:
  /// **'Tell administrators after (days late)'**
  String get policyEscalateDays;

  /// No description provided for @policyGraceHours.
  ///
  /// In en, this message translates to:
  /// **'Grace period (hours)'**
  String get policyGraceHours;

  /// No description provided for @policyReminderHours.
  ///
  /// In en, this message translates to:
  /// **'Repeat reminders every (hours)'**
  String get policyReminderHours;

  /// No description provided for @policyCountWeekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends count'**
  String get policyCountWeekends;

  /// No description provided for @policyCountWeekendsHint.
  ///
  /// In en, this message translates to:
  /// **'When off, Saturdays and Sundays don\'t count. Holidays never count.'**
  String get policyCountWeekendsHint;

  /// No description provided for @policyInactiveDays.
  ///
  /// In en, this message translates to:
  /// **'Inactive after (days without using Sidra)'**
  String get policyInactiveDays;

  /// No description provided for @policyInactiveDaysHint.
  ///
  /// In en, this message translates to:
  /// **'Separate from late work: the learner gets a gentle reminder.'**
  String get policyInactiveDaysHint;

  /// No description provided for @policyAutoSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend automatically'**
  String get policyAutoSuspend;

  /// No description provided for @policyAutoSuspendHint.
  ///
  /// In en, this message translates to:
  /// **'Off by default. Only after a warning at least a day earlier, never with an open problem report or extension, and only if the learner has used Sidra since the work was given. Work and progress are kept.'**
  String get policyAutoSuspendHint;

  /// No description provided for @policySuspendDays.
  ///
  /// In en, this message translates to:
  /// **'Suspend after (days late)'**
  String get policySuspendDays;

  /// No description provided for @policyPaymentDays.
  ///
  /// In en, this message translates to:
  /// **'Keep checking unanswered mobile-money payments for (days)'**
  String get policyPaymentDays;

  /// No description provided for @policyPaymentDaysHint.
  ///
  /// In en, this message translates to:
  /// **'After this, a payment MarzPay never answered counts as failed.'**
  String get policyPaymentDaysHint;

  /// No description provided for @policyRunning.
  ///
  /// In en, this message translates to:
  /// **'Policies are running.'**
  String get policyRunning;

  /// No description provided for @policyPausedUntil.
  ///
  /// In en, this message translates to:
  /// **'Paused until {when}'**
  String policyPausedUntil(String when);

  /// No description provided for @policyLastRun.
  ///
  /// In en, this message translates to:
  /// **'Last checked {when}'**
  String policyLastRun(String when);

  /// No description provided for @policyResume.
  ///
  /// In en, this message translates to:
  /// **'Resume now'**
  String get policyResume;

  /// No description provided for @policyPauseDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Pause for a day} other{Pause for {n} days}}'**
  String policyPauseDays(int n);

  /// No description provided for @holidaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get holidaysTitle;

  /// No description provided for @holidaysHint.
  ///
  /// In en, this message translates to:
  /// **'Days that don\'t count towards deadlines'**
  String get holidaysHint;

  /// No description provided for @holidaysAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a holiday'**
  String get holidaysAdd;

  /// No description provided for @holidaysName.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Eid al-Fitr)'**
  String get holidaysName;

  /// No description provided for @holidaysNone.
  ///
  /// In en, this message translates to:
  /// **'No holidays added'**
  String get holidaysNone;

  /// No description provided for @transferChannel.
  ///
  /// In en, this message translates to:
  /// **'Uploads and downloads'**
  String get transferChannel;

  /// No description provided for @transferChannelHint.
  ///
  /// In en, this message translates to:
  /// **'Progress of your uploads and downloads'**
  String get transferChannelHint;

  /// No description provided for @uploadingWork.
  ///
  /// In en, this message translates to:
  /// **'Uploading your work'**
  String get uploadingWork;

  /// No description provided for @uploadDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Work sent'**
  String get uploadDoneTitle;

  /// No description provided for @uploadDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your teacher has received it.'**
  String get uploadDoneBody;

  /// No description provided for @uploadWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Work saved: waiting for internet'**
  String get uploadWaitingTitle;

  /// No description provided for @uploadWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'It will be sent when you\'re back online.'**
  String get uploadWaitingBody;

  /// No description provided for @uploadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailedTitle;

  /// No description provided for @uploadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your work is kept on the phone. Open Sidra to try again.'**
  String get uploadFailedBody;

  /// No description provided for @uploadFileMissing.
  ///
  /// In en, this message translates to:
  /// **'{name} is no longer on this phone. Remove it and add it again.'**
  String uploadFileMissing(String name);

  /// No description provided for @chatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatsTitle;

  /// No description provided for @chatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatsEmpty;

  /// No description provided for @chatsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Start a chat with a colleague, or create a group for your team.'**
  String get chatsEmptyHint;

  /// No description provided for @chatNew.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get chatNew;

  /// No description provided for @chatNewGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get chatNewGroup;

  /// No description provided for @chatGroupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get chatGroupName;

  /// No description provided for @chatGroupNameNeeded.
  ///
  /// In en, this message translates to:
  /// **'Give the group a name'**
  String get chatGroupNameNeeded;

  /// No description provided for @chatCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get chatCreateGroup;

  /// No description provided for @chatAddPeople.
  ///
  /// In en, this message translates to:
  /// **'Add people'**
  String get chatAddPeople;

  /// No description provided for @chatMembers.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 member} other{{n} members}}'**
  String chatMembers(int n);

  /// No description provided for @chatGroupAdmin.
  ///
  /// In en, this message translates to:
  /// **'Group admin'**
  String get chatGroupAdmin;

  /// No description provided for @chatRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get chatRemove;

  /// No description provided for @chatLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get chatLeave;

  /// No description provided for @chatMute.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get chatMute;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatMessageHint;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get chatAttach;

  /// No description provided for @chatAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get chatAttachment;

  /// No description provided for @chatPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatPhoto;

  /// No description provided for @chatVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get chatVideo;

  /// No description provided for @chatAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get chatAudio;

  /// No description provided for @chatFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get chatFile;

  /// No description provided for @chatVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Voice note'**
  String get chatVoiceNote;

  /// No description provided for @chatRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get chatRecording;

  /// No description provided for @chatMicNeeded.
  ///
  /// In en, this message translates to:
  /// **'Allow the microphone for Sidra to send voice notes.'**
  String get chatMicNeeded;

  /// No description provided for @chatReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatReply;

  /// No description provided for @chatCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatCopy;

  /// No description provided for @chatDeleteForAll.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get chatDeleteForAll;

  /// No description provided for @chatDeleted.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get chatDeleted;

  /// No description provided for @chatNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent. Tap to retry'**
  String get chatNotSent;

  /// No description provided for @chatToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatToday;

  /// No description provided for @chatYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatYesterday;

  /// No description provided for @photoEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust photo'**
  String get photoEditTitle;

  /// No description provided for @photoEditHint.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom and drag to place your face in the circle.'**
  String get photoEditHint;

  /// No description provided for @photoRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get photoRotate;

  /// No description provided for @photoReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get photoReset;

  /// No description provided for @photoUse.
  ///
  /// In en, this message translates to:
  /// **'Use photo'**
  String get photoUse;

  /// No description provided for @photoView.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get photoView;

  /// No description provided for @dashSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name} · {role}'**
  String dashSignedInAs(String name, String role);

  /// No description provided for @dashOrgTitle.
  ///
  /// In en, this message translates to:
  /// **'{org} at a glance'**
  String dashOrgTitle(String org);

  /// No description provided for @dashOrgHint.
  ///
  /// In en, this message translates to:
  /// **'Numbers for the whole organisation, not for you. Tap any number to see exactly who or what it counts.'**
  String get dashOrgHint;

  /// No description provided for @dashThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get dashThisWeek;

  /// No description provided for @dashPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get dashPeople;

  /// No description provided for @dashCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get dashCourses;

  /// No description provided for @dashLearnersInCourses.
  ///
  /// In en, this message translates to:
  /// **'Learners in courses'**
  String get dashLearnersInCourses;

  /// No description provided for @dashCoursePlaces.
  ///
  /// In en, this message translates to:
  /// **'Course places (a learner in 3 courses = 3)'**
  String get dashCoursePlaces;

  /// No description provided for @dashListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get dashListEmpty;

  /// No description provided for @dashListCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 in this list} other{{n} in this list}}'**
  String dashListCount(int n);

  /// No description provided for @dashLearnersGlance.
  ///
  /// In en, this message translates to:
  /// **'Learners at a glance'**
  String get dashLearnersGlance;

  /// No description provided for @dashSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all {n}'**
  String dashSeeAll(int n);

  /// No description provided for @dashGlanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'You can\'t see learners with your role.'**
  String get dashGlanceUnavailable;

  /// No description provided for @dashNoCourses.
  ///
  /// In en, this message translates to:
  /// **'Not in any course'**
  String get dashNoCourses;

  /// No description provided for @dashNeverUsed.
  ///
  /// In en, this message translates to:
  /// **'Hasn\'t used Sidra yet'**
  String get dashNeverUsed;

  /// No description provided for @dashLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used Sidra {when}'**
  String dashLastUsed(String when);

  /// No description provided for @dashLateWork.
  ///
  /// In en, this message translates to:
  /// **'{n} late'**
  String dashLateWork(int n);

  /// No description provided for @dashOpenReports.
  ///
  /// In en, this message translates to:
  /// **'{n} problem reported'**
  String dashOpenReports(int n);

  /// No description provided for @ccGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get ccGeneral;

  /// No description provided for @ccGeneralHint.
  ///
  /// In en, this message translates to:
  /// **'Organisation name, time zone, contacts and messaging.'**
  String get ccGeneralHint;

  /// No description provided for @ccAccess.
  ///
  /// In en, this message translates to:
  /// **'Users and access'**
  String get ccAccess;

  /// No description provided for @ccAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Who may sign up, password rules, lock-out and sign-in protection.'**
  String get ccAccessHint;

  /// No description provided for @ccTeaching.
  ///
  /// In en, this message translates to:
  /// **'Teaching'**
  String get ccTeaching;

  /// No description provided for @ccSecurity.
  ///
  /// In en, this message translates to:
  /// **'Devices and security'**
  String get ccSecurity;

  /// No description provided for @ccSecurityHint.
  ///
  /// In en, this message translates to:
  /// **'Phones signed in, sessions, failed sign-ins and sign-outs.'**
  String get ccSecurityHint;

  /// No description provided for @ccPaymentsHint.
  ///
  /// In en, this message translates to:
  /// **'Payment methods, instructions for manual payment, and tracing a payment.'**
  String get ccPaymentsHint;

  /// No description provided for @ccMarzpayHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile money through MarzPay: its real status, test centre and safety limits.'**
  String get ccMarzpayHint;

  /// No description provided for @ccStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage and media'**
  String get ccStorage;

  /// No description provided for @ccStorageHint.
  ///
  /// In en, this message translates to:
  /// **'Where files are kept (Cloudinary), upload limit and storage checks.'**
  String get ccStorageHint;

  /// No description provided for @ccDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get ccDatabase;

  /// No description provided for @ccDatabaseHint.
  ///
  /// In en, this message translates to:
  /// **'Connection and schema version. Changes to the structure are made by the release process, not here.'**
  String get ccDatabaseHint;

  /// No description provided for @ccSync.
  ///
  /// In en, this message translates to:
  /// **'Offline and sync'**
  String get ccSync;

  /// No description provided for @ccSyncHint.
  ///
  /// In en, this message translates to:
  /// **'Work saved on this phone and waiting to be sent.'**
  String get ccSyncHint;

  /// No description provided for @ccAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit and history'**
  String get ccAudit;

  /// No description provided for @ccAuditHint.
  ///
  /// In en, this message translates to:
  /// **'Who changed which setting, when and why; data export.'**
  String get ccAuditHint;

  /// No description provided for @ccApplication.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get ccApplication;

  /// No description provided for @ccAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get ccAdvanced;

  /// No description provided for @ccAdvancedHint.
  ///
  /// In en, this message translates to:
  /// **'Run checks when something breaks, with a history of results.'**
  String get ccAdvancedHint;

  /// No description provided for @ccTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone (e.g. Africa/Kampala)'**
  String get ccTimeZone;

  /// No description provided for @ccTimeZoneHint.
  ///
  /// In en, this message translates to:
  /// **'Used for deadlines, weekends and holidays.'**
  String get ccTimeZoneHint;

  /// No description provided for @ccMessagingOn.
  ///
  /// In en, this message translates to:
  /// **'Messaging for staff'**
  String get ccMessagingOn;

  /// No description provided for @ccMessagingLearners.
  ///
  /// In en, this message translates to:
  /// **'Learners can use messaging too'**
  String get ccMessagingLearners;

  /// No description provided for @ccSigninBrake.
  ///
  /// In en, this message translates to:
  /// **'System-wide brake: failed sign-ins per minute'**
  String get ccSigninBrake;

  /// No description provided for @ccSigninBrakeHint.
  ///
  /// In en, this message translates to:
  /// **'Above this, sign-in answers \"try later\" for a minute (stops someone guessing many accounts).'**
  String get ccSigninBrakeHint;

  /// No description provided for @ccPresenceMinutes.
  ///
  /// In en, this message translates to:
  /// **'\"Online\" means seen within (minutes)'**
  String get ccPresenceMinutes;

  /// No description provided for @ccAuthKeepDays.
  ///
  /// In en, this message translates to:
  /// **'Keep sign-in history for (days)'**
  String get ccAuthKeepDays;

  /// No description provided for @ccDefaultPassMark.
  ///
  /// In en, this message translates to:
  /// **'Pass mark for new courses (%)'**
  String get ccDefaultPassMark;

  /// No description provided for @ccMarzTestsOn.
  ///
  /// In en, this message translates to:
  /// **'MarzPay tests allowed (emergency stop)'**
  String get ccMarzTestsOn;

  /// No description provided for @ccMarzTestsOnHint.
  ///
  /// In en, this message translates to:
  /// **'Off stops every test at once, including ones waiting to run.'**
  String get ccMarzTestsOnHint;

  /// No description provided for @ccMarzTestMax.
  ///
  /// In en, this message translates to:
  /// **'Largest test amount (UGX)'**
  String get ccMarzTestMax;

  /// No description provided for @ccMarzDisbursementOn.
  ///
  /// In en, this message translates to:
  /// **'Allow sending-money tests'**
  String get ccMarzDisbursementOn;

  /// No description provided for @ccMarzDisbursementOnHint.
  ///
  /// In en, this message translates to:
  /// **'Money leaves the MarzPay wallet. Off by default.'**
  String get ccMarzDisbursementOnHint;

  /// No description provided for @ccUploadMax.
  ///
  /// In en, this message translates to:
  /// **'Largest upload (MB)'**
  String get ccUploadMax;

  /// No description provided for @ccUploadMaxHint.
  ///
  /// In en, this message translates to:
  /// **'Phones refuse bigger files before sending. Cloudinary\'s own plan limit also applies.'**
  String get ccUploadMaxHint;

  /// No description provided for @ccSendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send me a test notification'**
  String get ccSendTestNotification;

  /// No description provided for @ccPaymentTrace.
  ///
  /// In en, this message translates to:
  /// **'Trace a payment'**
  String get ccPaymentTrace;

  /// No description provided for @ccMarzCenter.
  ///
  /// In en, this message translates to:
  /// **'MarzPay test centre'**
  String get ccMarzCenter;

  /// No description provided for @ccDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get ccDiagnostics;

  /// No description provided for @ccSettingsHistory.
  ///
  /// In en, this message translates to:
  /// **'Settings history'**
  String get ccSettingsHistory;

  /// No description provided for @ccSecurityEvents.
  ///
  /// In en, this message translates to:
  /// **'Security events'**
  String get ccSecurityEvents;

  /// No description provided for @ccOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ccOk;

  /// No description provided for @ccWarning.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get ccWarning;

  /// No description provided for @ccFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get ccFailed;

  /// No description provided for @ccUntested.
  ///
  /// In en, this message translates to:
  /// **'Untested'**
  String get ccUntested;

  /// No description provided for @ccDisabled.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get ccDisabled;

  /// No description provided for @ccSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search settings: password, payment, notification…'**
  String get ccSearchHint;

  /// No description provided for @ccHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Is Sidra healthy right now?'**
  String get ccHealthTitle;

  /// No description provided for @ccHealthHint.
  ///
  /// In en, this message translates to:
  /// **'Live status of each part. Tap one for details.'**
  String get ccHealthHint;

  /// No description provided for @ccHealthNoPermission.
  ///
  /// In en, this message translates to:
  /// **'Your role can\'t see system health.'**
  String get ccHealthNoPermission;

  /// No description provided for @ccSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get ccSections;

  /// No description provided for @ccMarzDisabled.
  ///
  /// In en, this message translates to:
  /// **'Switched off by an administrator'**
  String get ccMarzDisabled;

  /// No description provided for @ccMarzConnFailed.
  ///
  /// In en, this message translates to:
  /// **'The last connection test failed'**
  String get ccMarzConnFailed;

  /// No description provided for @ccMarzServerDown.
  ///
  /// In en, this message translates to:
  /// **'Payments server offline: payments can\'t be sent'**
  String get ccMarzServerDown;

  /// No description provided for @ccMarzVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified: money has been collected through Sidra'**
  String get ccMarzVerified;

  /// No description provided for @ccMarzAuthOnly.
  ///
  /// In en, this message translates to:
  /// **'Connected and authenticated; a real collection not yet proven'**
  String get ccMarzAuthOnly;

  /// No description provided for @ccMarzUntested.
  ///
  /// In en, this message translates to:
  /// **'Not tested yet'**
  String get ccMarzUntested;

  /// No description provided for @ccDbLine.
  ///
  /// In en, this message translates to:
  /// **'Schema {have} (this app expects {expected})'**
  String ccDbLine(String have, String expected);

  /// No description provided for @ccPaymentsServer.
  ///
  /// In en, this message translates to:
  /// **'Payments server'**
  String get ccPaymentsServer;

  /// No description provided for @ccServerOnline.
  ///
  /// In en, this message translates to:
  /// **'Online (version {version})'**
  String ccServerOnline(Object version);

  /// No description provided for @ccServerNever.
  ///
  /// In en, this message translates to:
  /// **'Never seen: it isn\'t running anywhere'**
  String get ccServerNever;

  /// No description provided for @ccServerLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Offline, last seen {when}'**
  String ccServerLastSeen(String when);

  /// No description provided for @ccStorageLine.
  ///
  /// In en, this message translates to:
  /// **'{n} uploads today; last {when}'**
  String ccStorageLine(Object n, String when);

  /// No description provided for @ccStorageMissing.
  ///
  /// In en, this message translates to:
  /// **'Cloudinary keys are missing: uploads will fail'**
  String get ccStorageMissing;

  /// No description provided for @ccNotifLine.
  ///
  /// In en, this message translates to:
  /// **'{sent} sent today · {phones} phones registered · {blocked} phones block notifications'**
  String ccNotifLine(Object sent, Object phones, Object blocked);

  /// No description provided for @ccSecurityLine.
  ///
  /// In en, this message translates to:
  /// **'{failed} failed sign-ins today · {locked} locked · {many} accounts on many phones'**
  String ccSecurityLine(Object failed, Object locked, Object many);

  /// No description provided for @ccLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get ccLearning;

  /// No description provided for @ccLearningLine.
  ///
  /// In en, this message translates to:
  /// **'{active} active this week · {reports} problem reports · {late} late · {review} waiting review 2+ days'**
  String ccLearningLine(
    Object active,
    Object reports,
    Object late,
    Object review,
  );

  /// No description provided for @ccPaymentsLine.
  ///
  /// In en, this message translates to:
  /// **'{manual} manual payments to verify · {stuck} mobile-money payments stuck'**
  String ccPaymentsLine(Object manual, Object stuck);

  /// No description provided for @ccAppLine.
  ///
  /// In en, this message translates to:
  /// **'This phone {version} ({build}) · newest build {latest}'**
  String ccAppLine(String version, String build, Object latest);

  /// No description provided for @ccDiagLine.
  ///
  /// In en, this message translates to:
  /// **'{n} failed checks in the last day'**
  String ccDiagLine(Object n);

  /// No description provided for @ccCheckedAt.
  ///
  /// In en, this message translates to:
  /// **'Checked {when}'**
  String ccCheckedAt(String when);

  /// No description provided for @ccSaved.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 setting saved} other{{n} settings saved}}'**
  String ccSaved(int n);

  /// No description provided for @ccSavedSome.
  ///
  /// In en, this message translates to:
  /// **'{ok} saved, {failed} refused: see the red messages'**
  String ccSavedSome(int ok, int failed);

  /// No description provided for @ccReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for the change (recorded)'**
  String get ccReason;

  /// No description provided for @ccSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save {n}'**
  String ccSaveChanges(int n);

  /// No description provided for @ccRange.
  ///
  /// In en, this message translates to:
  /// **'Between {min} and {max}.'**
  String ccRange(int min, int max);

  /// No description provided for @ccLastChanged.
  ///
  /// In en, this message translates to:
  /// **'Last changed by {name}, {when}'**
  String ccLastChanged(String name, String when);

  /// No description provided for @ccSystem.
  ///
  /// In en, this message translates to:
  /// **'the system'**
  String get ccSystem;

  /// No description provided for @ccYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get ccYes;

  /// No description provided for @ccNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get ccNo;

  /// No description provided for @ccDbConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get ccDbConnected;

  /// No description provided for @ccDbLatest.
  ///
  /// In en, this message translates to:
  /// **'Newest applied change'**
  String get ccDbLatest;

  /// No description provided for @ccDbAppExpects.
  ///
  /// In en, this message translates to:
  /// **'This app expects'**
  String get ccDbAppExpects;

  /// No description provided for @ccDbCount.
  ///
  /// In en, this message translates to:
  /// **'Changes applied'**
  String get ccDbCount;

  /// No description provided for @ccDbBackups.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get ccDbBackups;

  /// No description provided for @ccDbBackupsHint.
  ///
  /// In en, this message translates to:
  /// **'Kept by Neon (see its console; paid plans restore to any moment)'**
  String get ccDbBackupsHint;

  /// No description provided for @ccStorageProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get ccStorageProvider;

  /// No description provided for @ccConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get ccConfigured;

  /// No description provided for @ccLastUpload.
  ///
  /// In en, this message translates to:
  /// **'Last upload'**
  String get ccLastUpload;

  /// No description provided for @ccUploads24h.
  ///
  /// In en, this message translates to:
  /// **'Uploads today'**
  String get ccUploads24h;

  /// No description provided for @ccPurgeWaiting.
  ///
  /// In en, this message translates to:
  /// **'Files waiting to be deleted'**
  String get ccPurgeWaiting;

  /// No description provided for @ccPublicAddress.
  ///
  /// In en, this message translates to:
  /// **'Public address for callbacks'**
  String get ccPublicAddress;

  /// No description provided for @ccNoPollingOnly.
  ///
  /// In en, this message translates to:
  /// **'No (payments are checked every 20 s)'**
  String get ccNoPollingOnly;

  /// No description provided for @ccVerifiedPayments.
  ///
  /// In en, this message translates to:
  /// **'Verified mobile-money payments'**
  String get ccVerifiedPayments;

  /// No description provided for @ccStuckPayments.
  ///
  /// In en, this message translates to:
  /// **'Stuck over an hour'**
  String get ccStuckPayments;

  /// No description provided for @ccThisPhone.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get ccThisPhone;

  /// No description provided for @ccBuildsInUse.
  ///
  /// In en, this message translates to:
  /// **'Builds in use (build: phones)'**
  String get ccBuildsInUse;

  /// No description provided for @ccFailedSignIns.
  ///
  /// In en, this message translates to:
  /// **'Failed sign-ins (24 h)'**
  String get ccFailedSignIns;

  /// No description provided for @ccThrottled.
  ///
  /// In en, this message translates to:
  /// **'Brake applied (24 h)'**
  String get ccThrottled;

  /// No description provided for @ccLockedNow.
  ///
  /// In en, this message translates to:
  /// **'Accounts locked now'**
  String get ccLockedNow;

  /// No description provided for @ccRevoked7d.
  ///
  /// In en, this message translates to:
  /// **'Phones signed out by admins (7 days)'**
  String get ccRevoked7d;

  /// No description provided for @ccManyDevices.
  ///
  /// In en, this message translates to:
  /// **'Accounts signed in on more than 3 phones'**
  String get ccManyDevices;

  /// No description provided for @ccSyncThisPhone.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get ccSyncThisPhone;

  /// No description provided for @ccSyncLine.
  ///
  /// In en, this message translates to:
  /// **'{pending} progress changes waiting · {rejected} refused · {queued} submissions queued'**
  String ccSyncLine(int pending, int rejected, int queued);

  /// No description provided for @ccSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get ccSyncNow;

  /// No description provided for @ccHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Every change to a setting: old value, new value, who, when and why. Tap one to see only that setting.'**
  String get ccHistoryHint;

  /// No description provided for @ccNoSecurityEvents.
  ///
  /// In en, this message translates to:
  /// **'No security events'**
  String get ccNoSecurityEvents;

  /// No description provided for @ccUnknownAccount.
  ///
  /// In en, this message translates to:
  /// **'unknown number (no account)'**
  String get ccUnknownAccount;

  /// No description provided for @ccTraceHint.
  ///
  /// In en, this message translates to:
  /// **'Search by learner name or phone, Sidra payment id, MarzPay id or reference. Each result follows the payment from request to MarzPay to Sidra\'s record.'**
  String get ccTraceHint;

  /// No description provided for @ccTraceSearch.
  ///
  /// In en, this message translates to:
  /// **'Name, phone, id or reference'**
  String get ccTraceSearch;

  /// No description provided for @ccTraceNone.
  ///
  /// In en, this message translates to:
  /// **'No payment matches'**
  String get ccTraceNone;

  /// No description provided for @ccTraceStep1.
  ///
  /// In en, this message translates to:
  /// **'1 · The request in Sidra'**
  String get ccTraceStep1;

  /// No description provided for @ccTraceStep2.
  ///
  /// In en, this message translates to:
  /// **'2 · At MarzPay'**
  String get ccTraceStep2;

  /// No description provided for @ccTraceStep3.
  ///
  /// In en, this message translates to:
  /// **'3 · Callbacks received'**
  String get ccTraceStep3;

  /// No description provided for @ccTraceStep4.
  ///
  /// In en, this message translates to:
  /// **'4 · Sidra\'s record and access'**
  String get ccTraceStep4;

  /// No description provided for @ccTraceMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get ccTraceMethod;

  /// No description provided for @ccTraceCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get ccTraceCreated;

  /// No description provided for @ccTraceSidraId.
  ///
  /// In en, this message translates to:
  /// **'Sidra id'**
  String get ccTraceSidraId;

  /// No description provided for @ccTraceReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get ccTraceReference;

  /// No description provided for @ccTraceProviderId.
  ///
  /// In en, this message translates to:
  /// **'MarzPay id'**
  String get ccTraceProviderId;

  /// No description provided for @ccTraceProviderStatus.
  ///
  /// In en, this message translates to:
  /// **'MarzPay\'s last answer'**
  String get ccTraceProviderStatus;

  /// No description provided for @ccTraceAttempts.
  ///
  /// In en, this message translates to:
  /// **'Send attempts'**
  String get ccTraceAttempts;

  /// No description provided for @ccTraceCallbacks.
  ///
  /// In en, this message translates to:
  /// **'Callbacks'**
  String get ccTraceCallbacks;

  /// No description provided for @ccTraceNoCallbacks.
  ///
  /// In en, this message translates to:
  /// **'None (checked by polling)'**
  String get ccTraceNoCallbacks;

  /// No description provided for @ccTraceSidraStatus.
  ///
  /// In en, this message translates to:
  /// **'Sidra status'**
  String get ccTraceSidraStatus;

  /// No description provided for @ccTraceVerifiedAt.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get ccTraceVerifiedAt;

  /// No description provided for @ccTraceBalance.
  ///
  /// In en, this message translates to:
  /// **'Still owed'**
  String get ccTraceBalance;

  /// No description provided for @ccTraceOutstanding.
  ///
  /// In en, this message translates to:
  /// **'outstanding'**
  String get ccTraceOutstanding;

  /// No description provided for @ccTraceEnrolment.
  ///
  /// In en, this message translates to:
  /// **'Course access'**
  String get ccTraceEnrolment;

  /// No description provided for @ccTraceHistory.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get ccTraceHistory;

  /// No description provided for @ccTraceAskMarzPay.
  ///
  /// In en, this message translates to:
  /// **'Ask MarzPay now'**
  String get ccTraceAskMarzPay;

  /// No description provided for @ccDiagnosticsHint.
  ///
  /// In en, this message translates to:
  /// **'Each check says what it tested, what should happen, what happened and what to do next. Results are kept.'**
  String get ccDiagnosticsHint;

  /// No description provided for @ccRunAll.
  ///
  /// In en, this message translates to:
  /// **'Run all checks'**
  String get ccRunAll;

  /// No description provided for @ccRunCheck.
  ///
  /// In en, this message translates to:
  /// **'Run the check'**
  String get ccRunCheck;

  /// No description provided for @ccTested.
  ///
  /// In en, this message translates to:
  /// **'Tested'**
  String get ccTested;

  /// No description provided for @ccExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get ccExpected;

  /// No description provided for @ccHappened.
  ///
  /// In en, this message translates to:
  /// **'Happened'**
  String get ccHappened;

  /// No description provided for @ccNextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get ccNextAction;

  /// No description provided for @ccDiagHistory.
  ///
  /// In en, this message translates to:
  /// **'Earlier results'**
  String get ccDiagHistory;

  /// No description provided for @ccSafetySettings.
  ///
  /// In en, this message translates to:
  /// **'Safety settings'**
  String get ccSafetySettings;

  /// No description provided for @diagDbTested.
  ///
  /// In en, this message translates to:
  /// **'A round trip to the database from this phone'**
  String get diagDbTested;

  /// No description provided for @diagDbExpected.
  ///
  /// In en, this message translates to:
  /// **'An answer within a few seconds'**
  String get diagDbExpected;

  /// No description provided for @diagDbHappened.
  ///
  /// In en, this message translates to:
  /// **'Answered in {ms} ms'**
  String diagDbHappened(int ms);

  /// No description provided for @diagSession.
  ///
  /// In en, this message translates to:
  /// **'Sign-in session'**
  String get diagSession;

  /// No description provided for @diagSessionTested.
  ///
  /// In en, this message translates to:
  /// **'Renewing this phone\'s session'**
  String get diagSessionTested;

  /// No description provided for @diagSessionExpected.
  ///
  /// In en, this message translates to:
  /// **'A fresh session'**
  String get diagSessionExpected;

  /// No description provided for @diagSessionOk.
  ///
  /// In en, this message translates to:
  /// **'Session renewed'**
  String get diagSessionOk;

  /// No description provided for @diagSessionNone.
  ///
  /// In en, this message translates to:
  /// **'No session: this phone is signed out'**
  String get diagSessionNone;

  /// No description provided for @diagDevice.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get diagDevice;

  /// No description provided for @diagDeviceTested.
  ///
  /// In en, this message translates to:
  /// **'Registration, permissions and app version'**
  String get diagDeviceTested;

  /// No description provided for @diagDeviceExpected.
  ///
  /// In en, this message translates to:
  /// **'Registered, with notifications and microphone allowed'**
  String get diagDeviceExpected;

  /// No description provided for @diagDeviceLinked.
  ///
  /// In en, this message translates to:
  /// **'Registered as {model}, Sidra {version}'**
  String diagDeviceLinked(String model, String version);

  /// No description provided for @diagDeviceNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked to this session yet (sign out and in once)'**
  String get diagDeviceNotLinked;

  /// No description provided for @diagStorageTested.
  ///
  /// In en, this message translates to:
  /// **'Uploading a tiny file to Cloudinary, then downloading it'**
  String get diagStorageTested;

  /// No description provided for @diagStorageExpected.
  ///
  /// In en, this message translates to:
  /// **'The same content comes back'**
  String get diagStorageExpected;

  /// No description provided for @diagStorageOk.
  ///
  /// In en, this message translates to:
  /// **'Uploaded, signed and downloaded intact'**
  String get diagStorageOk;

  /// No description provided for @diagStorageMismatch.
  ///
  /// In en, this message translates to:
  /// **'The downloaded file differs from what was uploaded'**
  String get diagStorageMismatch;

  /// No description provided for @diagNotifTested.
  ///
  /// In en, this message translates to:
  /// **'Creating a notification for you'**
  String get diagNotifTested;

  /// No description provided for @diagNotifExpected.
  ///
  /// In en, this message translates to:
  /// **'It appears in the app and on the notification bar'**
  String get diagNotifExpected;

  /// No description provided for @diagNotifSent.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get diagNotifSent;

  /// No description provided for @diagNotifNext.
  ///
  /// In en, this message translates to:
  /// **'It should appear on the notification bar within a minute while Sidra is open (15 minutes when closed). If not, check this phone\'s notification permission.'**
  String get diagNotifNext;

  /// No description provided for @diagSyncTested.
  ///
  /// In en, this message translates to:
  /// **'Work waiting on this phone'**
  String get diagSyncTested;

  /// No description provided for @diagSyncExpected.
  ///
  /// In en, this message translates to:
  /// **'Nothing stuck'**
  String get diagSyncExpected;

  /// No description provided for @diagServerTested.
  ///
  /// In en, this message translates to:
  /// **'The payments server\'s heartbeat'**
  String get diagServerTested;

  /// No description provided for @diagServerExpected.
  ///
  /// In en, this message translates to:
  /// **'Seen in the last 90 seconds'**
  String get diagServerExpected;

  /// No description provided for @diagMarzTested.
  ///
  /// In en, this message translates to:
  /// **'MarzPay\'s status from the latest tests'**
  String get diagMarzTested;

  /// No description provided for @diagMarzExpected.
  ///
  /// In en, this message translates to:
  /// **'Connected, and a real collection proven'**
  String get diagMarzExpected;

  /// No description provided for @diagAppTested.
  ///
  /// In en, this message translates to:
  /// **'This app\'s build against the newest published'**
  String get diagAppTested;

  /// No description provided for @diagAppExpected.
  ///
  /// In en, this message translates to:
  /// **'The newest build'**
  String get diagAppExpected;

  /// No description provided for @diagAppCurrent.
  ///
  /// In en, this message translates to:
  /// **'Up to date: {version} ({build})'**
  String diagAppCurrent(String version, String build);

  /// No description provided for @diagAppOld.
  ///
  /// In en, this message translates to:
  /// **'Build {build}, newest is {latest}'**
  String diagAppOld(String build, int latest);

  /// No description provided for @diagNextCheckNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check this phone\'s internet, then run again.'**
  String get diagNextCheckNetwork;

  /// No description provided for @diagNextSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in again.'**
  String get diagNextSignIn;

  /// No description provided for @diagNextPermissions.
  ///
  /// In en, this message translates to:
  /// **'Allow them in the phone\'s settings → Apps → Sidra.'**
  String get diagNextPermissions;

  /// No description provided for @diagNextStorage.
  ///
  /// In en, this message translates to:
  /// **'Check Cloudinary\'s status and plan limits; ask the developer if it continues.'**
  String get diagNextStorage;

  /// No description provided for @diagNextSync.
  ///
  /// In en, this message translates to:
  /// **'Open Offline and sync and retry the failed items.'**
  String get diagNextSync;

  /// No description provided for @diagNextServer.
  ///
  /// In en, this message translates to:
  /// **'Start the payments server on its host (see docs/OPERATIONS.md). Until then, mobile-money payments wait.'**
  String get diagNextServer;

  /// No description provided for @diagNextMarz.
  ///
  /// In en, this message translates to:
  /// **'Open the MarzPay test centre and run the connection test.'**
  String get diagNextMarz;

  /// No description provided for @diagNextUpdate.
  ///
  /// In en, this message translates to:
  /// **'Install the newest APK.'**
  String get diagNextUpdate;

  /// No description provided for @mcConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get mcConnection;

  /// No description provided for @mcConnectionHint.
  ///
  /// In en, this message translates to:
  /// **'Network, TLS, credentials, account, environment, latency.'**
  String get mcConnectionHint;

  /// No description provided for @mcCapabilities.
  ///
  /// In en, this message translates to:
  /// **'What MarzPay offers this account'**
  String get mcCapabilities;

  /// No description provided for @mcCapabilitiesHint.
  ///
  /// In en, this message translates to:
  /// **'Reads the collection and disbursement services, balance access and webhooks.'**
  String get mcCapabilitiesHint;

  /// No description provided for @mcBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get mcBalance;

  /// No description provided for @mcBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'The MarzPay wallet balance.'**
  String get mcBalanceHint;

  /// No description provided for @mcCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection (receive money)'**
  String get mcCollection;

  /// No description provided for @mcCollectionHint.
  ///
  /// In en, this message translates to:
  /// **'A real prompt on a phone; proven from MarzPay\'s own ledger.'**
  String get mcCollectionHint;

  /// No description provided for @mcDisbursement.
  ///
  /// In en, this message translates to:
  /// **'Disbursement (send money)'**
  String get mcDisbursement;

  /// No description provided for @mcDisbursementHint.
  ///
  /// In en, this message translates to:
  /// **'Money leaves the wallet to a phone. Off until switched on.'**
  String get mcDisbursementHint;

  /// No description provided for @mcLookup.
  ///
  /// In en, this message translates to:
  /// **'Transaction lookup'**
  String get mcLookup;

  /// No description provided for @mcLookupHint.
  ///
  /// In en, this message translates to:
  /// **'Compare Sidra\'s record with MarzPay\'s for one payment.'**
  String get mcLookupHint;

  /// No description provided for @mcLookupField.
  ///
  /// In en, this message translates to:
  /// **'Sidra id, MarzPay id or reference'**
  String get mcLookupField;

  /// No description provided for @mcCallbacks.
  ///
  /// In en, this message translates to:
  /// **'Callbacks'**
  String get mcCallbacks;

  /// No description provided for @mcCallbacksHint.
  ///
  /// In en, this message translates to:
  /// **'Can MarzPay notify Sidra? Lists what was received.'**
  String get mcCallbacksHint;

  /// No description provided for @mcReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Reconciliation'**
  String get mcReconciliation;

  /// No description provided for @mcReconciliationHint.
  ///
  /// In en, this message translates to:
  /// **'Every Sidra mobile-money payment (30 days) against MarzPay\'s ledger.'**
  String get mcReconciliationHint;

  /// No description provided for @mcAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get mcAuthentication;

  /// No description provided for @mcCollectionMm.
  ///
  /// In en, this message translates to:
  /// **'Mobile money collection (MTN, Airtel)'**
  String get mcCollectionMm;

  /// No description provided for @mcCard.
  ///
  /// In en, this message translates to:
  /// **'Card payments'**
  String get mcCard;

  /// No description provided for @mcDisbursementMm.
  ///
  /// In en, this message translates to:
  /// **'Mobile money disbursement'**
  String get mcDisbursementMm;

  /// No description provided for @mcBank.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get mcBank;

  /// No description provided for @mcWallet.
  ///
  /// In en, this message translates to:
  /// **'Account-to-account (wallet transfer)'**
  String get mcWallet;

  /// No description provided for @mcRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund / reversal'**
  String get mcRefund;

  /// No description provided for @mcMatrix.
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get mcMatrix;

  /// No description provided for @mcMatrixHint.
  ///
  /// In en, this message translates to:
  /// **'Provider: offered by MarzPay for this account. Sidra: built in Sidra. The badge shows the latest evidence.'**
  String get mcMatrixHint;

  /// No description provided for @mcProvider.
  ///
  /// In en, this message translates to:
  /// **'MarzPay'**
  String get mcProvider;

  /// No description provided for @mcSidra.
  ///
  /// In en, this message translates to:
  /// **'Sidra'**
  String get mcSidra;

  /// No description provided for @mcUnsupportedByProvider.
  ///
  /// In en, this message translates to:
  /// **'Not offered by MarzPay'**
  String get mcUnsupportedByProvider;

  /// No description provided for @mcRunCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Run the capabilities test'**
  String get mcRunCapabilities;

  /// No description provided for @mcSidraMissing.
  ///
  /// In en, this message translates to:
  /// **'MarzPay offers it; Sidra doesn\'t use it yet'**
  String get mcSidraMissing;

  /// No description provided for @mcImplementedUntested.
  ///
  /// In en, this message translates to:
  /// **'Built, not tested yet'**
  String get mcImplementedUntested;

  /// No description provided for @mcImplementedBlocked.
  ///
  /// In en, this message translates to:
  /// **'Built; verification blocked'**
  String get mcImplementedBlocked;

  /// No description provided for @mcVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get mcVerified;

  /// No description provided for @mcAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted, not proven'**
  String get mcAccepted;

  /// No description provided for @mcFailedR.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get mcFailedR;

  /// No description provided for @mcCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get mcCancelled;

  /// No description provided for @mcPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get mcPending;

  /// No description provided for @mcUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get mcUnknown;

  /// No description provided for @mcBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get mcBlocked;

  /// No description provided for @mcUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported'**
  String get mcUnsupported;

  /// No description provided for @mcRunning.
  ///
  /// In en, this message translates to:
  /// **'Running…'**
  String get mcRunning;

  /// No description provided for @mcRealMoney.
  ///
  /// In en, this message translates to:
  /// **'REAL MONEY'**
  String get mcRealMoney;

  /// No description provided for @mcLast.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get mcLast;

  /// No description provided for @mcIntro.
  ///
  /// In en, this message translates to:
  /// **'Tests run on the payments server (the only place with MarzPay\'s keys). Each ends with proof or an honest reason why not. Opening this page never starts a test.'**
  String get mcIntro;

  /// No description provided for @mcWhatTesting.
  ///
  /// In en, this message translates to:
  /// **'What are you testing?'**
  String get mcWhatTesting;

  /// No description provided for @mcTestTab.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get mcTestTab;

  /// No description provided for @mcHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get mcHistoryTab;

  /// No description provided for @mcCallbacksList.
  ///
  /// In en, this message translates to:
  /// **'Every call MarzPay made to Sidra, and what Sidra did with it.'**
  String get mcCallbacksList;

  /// No description provided for @mcNoCallbacks.
  ///
  /// In en, this message translates to:
  /// **'No callbacks received yet'**
  String get mcNoCallbacks;

  /// No description provided for @mcDuplicate.
  ///
  /// In en, this message translates to:
  /// **'duplicate'**
  String get mcDuplicate;

  /// No description provided for @mcNoTests.
  ///
  /// In en, this message translates to:
  /// **'No tests yet'**
  String get mcNoTests;

  /// No description provided for @mcRunTest.
  ///
  /// In en, this message translates to:
  /// **'Run test'**
  String get mcRunTest;

  /// No description provided for @mcFormInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an MTN or Airtel Uganda number and an amount.'**
  String get mcFormInvalid;

  /// No description provided for @mcRealTitle.
  ///
  /// In en, this message translates to:
  /// **'This moves real money'**
  String get mcRealTitle;

  /// No description provided for @mcRealCollect.
  ///
  /// In en, this message translates to:
  /// **'{amount} UGX will be requested from {phone}. The phone owner must enter their PIN. The money goes into the MarzPay wallet.'**
  String mcRealCollect(int amount, String phone);

  /// No description provided for @mcRealSend.
  ///
  /// In en, this message translates to:
  /// **'{amount} UGX will be sent from the MarzPay wallet to {phone}. This can\'t be undone by Sidra.'**
  String mcRealSend(int amount, String phone);

  /// No description provided for @mcContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get mcContinue;

  /// No description provided for @mcTypeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type exactly this to confirm'**
  String get mcTypeToConfirm;

  /// No description provided for @mcCollectWarning.
  ///
  /// In en, this message translates to:
  /// **'A real payment prompt will appear on the phone you enter. Use your own phone and the smallest amount.'**
  String get mcCollectWarning;

  /// No description provided for @mcSendWarning.
  ///
  /// In en, this message translates to:
  /// **'Real money will leave the MarzPay wallet. The recipient should confirm receipt.'**
  String get mcSendWarning;

  /// No description provided for @mcPayerPhone.
  ///
  /// In en, this message translates to:
  /// **'Payer\'s phone (MTN or Airtel)'**
  String get mcPayerPhone;

  /// No description provided for @mcRecipientPhone.
  ///
  /// In en, this message translates to:
  /// **'Recipient\'s phone (MTN or Airtel)'**
  String get mcRecipientPhone;

  /// No description provided for @mcAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount (UGX)'**
  String get mcAmount;

  /// No description provided for @mcAmountHint.
  ///
  /// In en, this message translates to:
  /// **'At least 500; at most the limit in Safety settings.'**
  String get mcAmountHint;

  /// No description provided for @mcDescription.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get mcDescription;

  /// No description provided for @mcStartCollection.
  ///
  /// In en, this message translates to:
  /// **'Request the payment'**
  String get mcStartCollection;

  /// No description provided for @mcStartDisbursement.
  ///
  /// In en, this message translates to:
  /// **'Send the money'**
  String get mcStartDisbursement;

  /// No description provided for @mcQueuedLong.
  ///
  /// In en, this message translates to:
  /// **'Still waiting: the payments server may be offline. The test starts as soon as it is running.'**
  String get mcQueuedLong;

  /// No description provided for @mcEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get mcEvidence;

  /// No description provided for @mcEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get mcEnvironment;

  /// No description provided for @ccMarzSelfChecks.
  ///
  /// In en, this message translates to:
  /// **'Integration self-checks (duplicates, timeouts, validation)'**
  String get ccMarzSelfChecks;

  /// No description provided for @issuesMine.
  ///
  /// In en, this message translates to:
  /// **'My problem reports'**
  String get issuesMine;

  /// No description provided for @issuesMineHint.
  ///
  /// In en, this message translates to:
  /// **'Problems you reported and your teachers\' answers'**
  String get issuesMineHint;

  /// No description provided for @issuesMineEmpty.
  ///
  /// In en, this message translates to:
  /// **'To report a problem, open the lesson or work and tap \"Report a problem\".'**
  String get issuesMineEmpty;

  /// No description provided for @contactsImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from contacts'**
  String get contactsImportTitle;

  /// No description provided for @contactsImportHint.
  ///
  /// In en, this message translates to:
  /// **'Pick many learners from this phone at once'**
  String get contactsImportHint;

  /// No description provided for @contactsAddOne.
  ///
  /// In en, this message translates to:
  /// **'Add one person'**
  String get contactsAddOne;

  /// No description provided for @contactsDenied.
  ///
  /// In en, this message translates to:
  /// **'Sidra can\'t read your contacts'**
  String get contactsDenied;

  /// No description provided for @contactsDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Allow contacts access (Settings → Apps → Sidra → Permissions) and try again.'**
  String get contactsDeniedBody;

  /// No description provided for @contactsNone.
  ///
  /// In en, this message translates to:
  /// **'No contacts with a phone number'**
  String get contactsNone;

  /// No description provided for @contactsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search name or number'**
  String get contactsSearch;

  /// No description provided for @contactsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} contacts · {created} added'**
  String contactsSummary(int count, int created);

  /// No description provided for @contactsSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get contactsSelectAll;

  /// No description provided for @contactsSelectNone.
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get contactsSelectNone;

  /// No description provided for @contactsAlready.
  ///
  /// In en, this message translates to:
  /// **'already in Sidra'**
  String get contactsAlready;

  /// No description provided for @contactsCreated.
  ///
  /// In en, this message translates to:
  /// **'added · password {password}'**
  String contactsCreated(String password);

  /// No description provided for @contactsImportN.
  ///
  /// In en, this message translates to:
  /// **'Import {count} as learners'**
  String contactsImportN(int count);

  /// No description provided for @contactsImporting.
  ///
  /// In en, this message translates to:
  /// **'Adding {done} of {count}…'**
  String contactsImporting(int done, int count);

  /// No description provided for @contactsImportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add {count} learners?'**
  String contactsImportConfirm(int count);

  /// No description provided for @contactsImportConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Each gets an account with their phone number and a temporary password, shown here after import. Copy the list and send each person theirs; they choose a new password at first sign-in.'**
  String get contactsImportConfirmBody;

  /// No description provided for @contactsCopyPasswords.
  ///
  /// In en, this message translates to:
  /// **'Copy names and passwords'**
  String get contactsCopyPasswords;

  /// No description provided for @contactsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied. Send each learner their password.'**
  String get contactsCopied;

  /// No description provided for @targetWhole.
  ///
  /// In en, this message translates to:
  /// **'The whole work'**
  String get targetWhole;

  /// No description provided for @targetOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get targetOther;

  /// No description provided for @targetAyah.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah}, ayah {ayah}'**
  String targetAyah(int surah, int ayah);

  /// No description provided for @targetAyahRange.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah}, ayat {from}–{to}'**
  String targetAyahRange(int surah, int from, int to);

  /// No description provided for @targetPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String targetPage(int page);

  /// No description provided for @targetPageLine.
  ///
  /// In en, this message translates to:
  /// **'Page {page}, line {line}'**
  String targetPageLine(int page, int line);

  /// No description provided for @targetPageLines.
  ///
  /// In en, this message translates to:
  /// **'Page {page}, lines {line}–{lineEnd}'**
  String targetPageLines(int page, int line, int lineEnd);

  /// No description provided for @wtWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for teacher'**
  String get wtWaiting;

  /// No description provided for @wtUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Teacher is reviewing'**
  String get wtUnderReview;

  /// No description provided for @wtSuperseded.
  ///
  /// In en, this message translates to:
  /// **'Replaced by a newer attempt'**
  String get wtSuperseded;

  /// No description provided for @wtTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get wtTryAgain;

  /// No description provided for @wtAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get wtAccepted;

  /// No description provided for @wtLearnerTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s work'**
  String wtLearnerTitle(String name);

  /// No description provided for @wtMyWork.
  ///
  /// In en, this message translates to:
  /// **'My work'**
  String get wtMyWork;

  /// No description provided for @wtNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing sent yet. Record, photograph or write your work below.'**
  String get wtNothingYet;

  /// No description provided for @wtCompleted.
  ///
  /// In en, this message translates to:
  /// **'Accepted by your teacher. Well done!'**
  String get wtCompleted;

  /// No description provided for @wtYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get wtYou;

  /// No description provided for @wtTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get wtTeacher;

  /// No description provided for @wtLearner.
  ///
  /// In en, this message translates to:
  /// **'Learner'**
  String get wtLearner;

  /// No description provided for @wtFor.
  ///
  /// In en, this message translates to:
  /// **'For: {what}'**
  String wtFor(String what);

  /// No description provided for @wtAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get wtAttachment;

  /// No description provided for @wtUploadingPlain.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get wtUploadingPlain;

  /// No description provided for @wtUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading… {percent}%'**
  String wtUploading(int percent);

  /// No description provided for @wtSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Uploaded ✓ Sending to your teacher…'**
  String get wtSubmitting;

  /// No description provided for @wtFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get wtFailed;

  /// No description provided for @wtQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a connection'**
  String get wtQueued;

  /// No description provided for @wtDiscard.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get wtDiscard;

  /// No description provided for @wtDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this from the phone? It has not been sent.'**
  String get wtDiscardBody;

  /// No description provided for @wtUploadedFile.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get wtUploadedFile;

  /// No description provided for @wtFileQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get wtFileQueued;

  /// No description provided for @wtCorrectionDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get wtCorrectionDefaultTitle;

  /// No description provided for @wtReplySent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent.'**
  String get wtReplySent;

  /// No description provided for @wtNewAttempt.
  ///
  /// In en, this message translates to:
  /// **'New attempt'**
  String get wtNewAttempt;

  /// No description provided for @wtReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get wtReply;

  /// No description provided for @wtMarkLatest.
  ///
  /// In en, this message translates to:
  /// **'Mark attempt {number}:'**
  String wtMarkLatest(int number);

  /// No description provided for @wtTryAgainAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get wtTryAgainAction;

  /// No description provided for @wtTeacherReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Voice, text, a file or a saved correction. Send as many as you need.'**
  String get wtTeacherReplyHint;

  /// No description provided for @wtLearnerReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Answer your teacher about this attempt.'**
  String get wtLearnerReplyHint;

  /// No description provided for @wtNewAttemptHint.
  ///
  /// In en, this message translates to:
  /// **'Send your work: a recording, photos, files or text.'**
  String get wtNewAttemptHint;

  /// No description provided for @wtChooseTargetShort.
  ///
  /// In en, this message translates to:
  /// **'What is it for?'**
  String get wtChooseTargetShort;

  /// No description provided for @wtRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get wtRecord;

  /// No description provided for @wtTeacherTextHint.
  ///
  /// In en, this message translates to:
  /// **'Write a correction or note'**
  String get wtTeacherTextHint;

  /// No description provided for @wtTextHint.
  ///
  /// In en, this message translates to:
  /// **'Write something (optional)'**
  String get wtTextHint;

  /// No description provided for @wtSendReply.
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get wtSendReply;

  /// No description provided for @wtAyahInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a surah (1–114) and ayah numbers.'**
  String get wtAyahInvalid;

  /// No description provided for @wtPageInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a page number (and lines, from – to).'**
  String get wtPageInvalid;

  /// No description provided for @wtExerciseInvalid.
  ///
  /// In en, this message translates to:
  /// **'Name the exercise or question.'**
  String get wtExerciseInvalid;

  /// No description provided for @wtChooseTarget.
  ///
  /// In en, this message translates to:
  /// **'What is this for?'**
  String get wtChooseTarget;

  /// No description provided for @wtTargetAyah.
  ///
  /// In en, this message translates to:
  /// **'An ayah or ayat'**
  String get wtTargetAyah;

  /// No description provided for @wtSurah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get wtSurah;

  /// No description provided for @wtAyahFrom.
  ///
  /// In en, this message translates to:
  /// **'From ayah'**
  String get wtAyahFrom;

  /// No description provided for @wtAyahTo.
  ///
  /// In en, this message translates to:
  /// **'To ayah'**
  String get wtAyahTo;

  /// No description provided for @wtTargetPageLine.
  ///
  /// In en, this message translates to:
  /// **'A page or line'**
  String get wtTargetPageLine;

  /// No description provided for @wtPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get wtPage;

  /// No description provided for @wtLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get wtLine;

  /// No description provided for @wtLineTo.
  ///
  /// In en, this message translates to:
  /// **'To line'**
  String get wtLineTo;

  /// No description provided for @wtTargetExercise.
  ///
  /// In en, this message translates to:
  /// **'An exercise or question'**
  String get wtTargetExercise;

  /// No description provided for @wtExerciseName.
  ///
  /// In en, this message translates to:
  /// **'Exercise or question'**
  String get wtExerciseName;

  /// No description provided for @wtExerciseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Question 4'**
  String get wtExerciseHint;

  /// No description provided for @wtTargetText.
  ///
  /// In en, this message translates to:
  /// **'Highlight part of the lesson'**
  String get wtTargetText;

  /// No description provided for @wtUseTarget.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get wtUseTarget;

  /// No description provided for @wtSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Press and hold on the words, drag to highlight them, then tap Use.'**
  String get wtSelectHint;

  /// No description provided for @wtSelected.
  ///
  /// In en, this message translates to:
  /// **'Highlighted'**
  String get wtSelected;

  /// No description provided for @wtUseWholePassage.
  ///
  /// In en, this message translates to:
  /// **'Use the whole passage ({what})'**
  String wtUseWholePassage(String what);

  /// No description provided for @wtUseSelection.
  ///
  /// In en, this message translates to:
  /// **'Use the highlighted words'**
  String get wtUseSelection;

  /// No description provided for @accountMenu.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountMenu;

  /// No description provided for @wtSendAgainHint.
  ///
  /// In en, this message translates to:
  /// **'Sent. Noticed a mistake? Send a new attempt below; it replaces this one.'**
  String get wtSendAgainHint;

  /// No description provided for @wtSeeHistory.
  ///
  /// In en, this message translates to:
  /// **'See my work and feedback'**
  String get wtSeeHistory;

  /// No description provided for @wtOpenWork.
  ///
  /// In en, this message translates to:
  /// **'My work ({count} attempts): send, reply, see feedback'**
  String wtOpenWork(int count);

  /// No description provided for @wtHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get wtHistory;

  /// No description provided for @billPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{price} / week'**
  String billPerWeek(String price);

  /// No description provided for @billPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price} / month'**
  String billPerMonth(String price);

  /// No description provided for @billPerTerm.
  ///
  /// In en, this message translates to:
  /// **'{price} / term'**
  String billPerTerm(String price);

  /// No description provided for @billPerDays.
  ///
  /// In en, this message translates to:
  /// **'{price} every {days} days'**
  String billPerDays(String price, int days);

  /// No description provided for @billPeriodsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} payments in all'**
  String billPeriodsTotal(int count);

  /// No description provided for @billPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused: a fee is overdue. Pay below to continue learning.'**
  String get billPaused;

  /// No description provided for @billCovered.
  ///
  /// In en, this message translates to:
  /// **'Paid {covered} of {due} so far'**
  String billCovered(int covered, int due);

  /// No description provided for @billNextDue.
  ///
  /// In en, this message translates to:
  /// **'next due {date}'**
  String billNextDue(String date);

  /// No description provided for @billPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'How often is it paid?'**
  String get billPeriodLabel;

  /// No description provided for @billOnce.
  ///
  /// In en, this message translates to:
  /// **'Once (one payment)'**
  String get billOnce;

  /// No description provided for @billWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get billWeekly;

  /// No description provided for @billMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get billMonthly;

  /// No description provided for @billTermly.
  ///
  /// In en, this message translates to:
  /// **'Every term'**
  String get billTermly;

  /// No description provided for @billCustom.
  ///
  /// In en, this message translates to:
  /// **'Every … days'**
  String get billCustom;

  /// No description provided for @billEveryDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Every how many days?'**
  String get billEveryDaysLabel;

  /// No description provided for @billDaysInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter 1 to 730 days.'**
  String get billDaysInvalid;

  /// No description provided for @billPeriodsLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of payments (optional)'**
  String get billPeriodsLabel;

  /// No description provided for @billPeriodsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 3 terms; empty = for as long as enrolled'**
  String get billPeriodsHint;

  /// No description provided for @billPeriodsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter 1 to 520, or leave empty.'**
  String get billPeriodsInvalid;

  /// No description provided for @billHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'The price above is charged each period from the day a learner first pays. Learners are reminded when a period starts; one left unpaid past the grace days (Settings) pauses the course for them until they pay. Term length is in Settings.'**
  String get billHowItWorks;

  /// No description provided for @billTermDaysSetting.
  ///
  /// In en, this message translates to:
  /// **'Length of a term (days)'**
  String get billTermDaysSetting;

  /// No description provided for @billTermDaysSettingHint.
  ///
  /// In en, this message translates to:
  /// **'For courses paid every term.'**
  String get billTermDaysSettingHint;

  /// No description provided for @billGraceSetting.
  ///
  /// In en, this message translates to:
  /// **'Days to pay a repeating fee'**
  String get billGraceSetting;

  /// No description provided for @billGraceSettingHint.
  ///
  /// In en, this message translates to:
  /// **'After a new week, month or term begins, learners have this many days to pay before the course pauses for them.'**
  String get billGraceSettingHint;

  /// No description provided for @wtAttemptN.
  ///
  /// In en, this message translates to:
  /// **'Attempt {n}'**
  String wtAttemptN(int n);

  /// No description provided for @ttTitle.
  ///
  /// In en, this message translates to:
  /// **'Test transactions'**
  String get ttTitle;

  /// No description provided for @ttConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Real money will move'**
  String get ttConfirmTitle;

  /// No description provided for @ttConfirmCollect.
  ///
  /// In en, this message translates to:
  /// **'Ask {phone} ({network}) to pay {amount} UGX into Sidra\'s MarzPay wallet? The phone will show a PIN prompt.'**
  String ttConfirmCollect(int amount, String phone, String network);

  /// No description provided for @ttConfirmDisburse.
  ///
  /// In en, this message translates to:
  /// **'Send {amount} UGX from Sidra\'s MarzPay wallet to {phone} ({network})? This cannot be undone.'**
  String ttConfirmDisburse(int amount, String phone, String network);

  /// No description provided for @ttCollectNow.
  ///
  /// In en, this message translates to:
  /// **'Collect now'**
  String get ttCollectNow;

  /// No description provided for @ttDisburseNow.
  ///
  /// In en, this message translates to:
  /// **'Send money now'**
  String get ttDisburseNow;

  /// No description provided for @ttMtn.
  ///
  /// In en, this message translates to:
  /// **'MTN MoMo'**
  String get ttMtn;

  /// No description provided for @ttAirtel.
  ///
  /// In en, this message translates to:
  /// **'Airtel Money'**
  String get ttAirtel;

  /// No description provided for @ttRealMoney.
  ///
  /// In en, this message translates to:
  /// **'For admins and developers. These are REAL transactions through MarzPay, not a simulation. Keep amounts small (the maximum is set in Settings → MarzPay).'**
  String get ttRealMoney;

  /// No description provided for @ttNoKeys.
  ///
  /// In en, this message translates to:
  /// **'This build has no MarzPay keys, so the test waits for the payments server.'**
  String get ttNoKeys;

  /// No description provided for @ttCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect (money in)'**
  String get ttCollect;

  /// No description provided for @ttDisburse.
  ///
  /// In en, this message translates to:
  /// **'Disburse (money out)'**
  String get ttDisburse;

  /// No description provided for @ttCollectHint.
  ///
  /// In en, this message translates to:
  /// **'Pulls money from the phone into Sidra\'s MarzPay wallet. The payer approves with their PIN.'**
  String get ttCollectHint;

  /// No description provided for @ttDisburseHint.
  ///
  /// In en, this message translates to:
  /// **'Sends money from Sidra\'s MarzPay wallet to the phone. Needs money in the wallet, sending tests switched on (Settings → MarzPay), and MarzPay\'s IP whitelist, which a phone usually does not pass: the response will show it.'**
  String get ttDisburseHint;

  /// No description provided for @ttPayerPhone.
  ///
  /// In en, this message translates to:
  /// **'Payer\'s number'**
  String get ttPayerPhone;

  /// No description provided for @ttRecipientPhone.
  ///
  /// In en, this message translates to:
  /// **'Recipient\'s number'**
  String get ttRecipientPhone;

  /// No description provided for @ttPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'MTN (076–079) or Airtel (070, 074, 075)'**
  String get ttPhoneHelp;

  /// No description provided for @ttPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an MTN MoMo or Airtel Money number, e.g. 0772 123456'**
  String get ttPhoneInvalid;

  /// No description provided for @ttAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get ttAmount;

  /// No description provided for @ttAmountHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 500 UGX'**
  String get ttAmountHelp;

  /// No description provided for @ttAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole amount of at least 500 UGX'**
  String get ttAmountInvalid;

  /// No description provided for @ttHistory.
  ///
  /// In en, this message translates to:
  /// **'Past test transactions'**
  String get ttHistory;

  /// No description provided for @ttHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Tap one to see its full response. Numbers are stored masked.'**
  String get ttHistoryHint;

  /// No description provided for @ttResultSuccess.
  ///
  /// In en, this message translates to:
  /// **'Succeeded (proven)'**
  String get ttResultSuccess;

  /// No description provided for @ttResultAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted, not proven'**
  String get ttResultAccepted;

  /// No description provided for @ttResultFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get ttResultFailed;

  /// No description provided for @ttResultCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ttResultCancelled;

  /// No description provided for @ttResultPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get ttResultPending;

  /// No description provided for @ttResultBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get ttResultBlocked;

  /// No description provided for @ttResponse.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get ttResponse;

  /// No description provided for @ttClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get ttClose;

  /// No description provided for @ttProviderStatus.
  ///
  /// In en, this message translates to:
  /// **'MarzPay status'**
  String get ttProviderStatus;

  /// No description provided for @ttErrorCode.
  ///
  /// In en, this message translates to:
  /// **'Error code'**
  String get ttErrorCode;

  /// No description provided for @ttHttpStatus.
  ///
  /// In en, this message translates to:
  /// **'HTTP'**
  String get ttHttpStatus;

  /// No description provided for @ttReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get ttReference;

  /// No description provided for @ttRawResponse.
  ///
  /// In en, this message translates to:
  /// **'MarzPay\'s answer to the request (raw)'**
  String get ttRawResponse;

  /// No description provided for @ttRawFinal.
  ///
  /// In en, this message translates to:
  /// **'MarzPay\'s final answer (raw)'**
  String get ttRawFinal;

  /// No description provided for @ttEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Collect or send a real amount and see MarzPay\'s exact response'**
  String get ttEntryHint;

  /// No description provided for @activateEntry.
  ///
  /// In en, this message translates to:
  /// **'I have an invitation code'**
  String get activateEntry;

  /// No description provided for @activateTitle.
  ///
  /// In en, this message translates to:
  /// **'Join with your invitation'**
  String get activateTitle;

  /// No description provided for @activateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your teacher added you to Sidra. Enter your number, the code they sent you, and choose your own password.'**
  String get activateSubtitle;

  /// No description provided for @activateCode.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get activateCode;

  /// No description provided for @activateCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'The code has 8 letters and numbers, like ABCD-2345'**
  String get activateCodeInvalid;

  /// No description provided for @activateNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a password'**
  String get activateNewPassword;

  /// No description provided for @activateRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat the password'**
  String get activateRepeat;

  /// No description provided for @activateMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords are not the same'**
  String get activateMismatch;

  /// No description provided for @activateButton.
  ///
  /// In en, this message translates to:
  /// **'Join Sidra'**
  String get activateButton;

  /// No description provided for @authErrorInvited.
  ///
  /// In en, this message translates to:
  /// **'Your school already added this number. Tap \"I have an invitation code\" and use the code from your teacher.'**
  String get authErrorInvited;

  /// No description provided for @authErrorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code is not right, or it has expired. Ask your teacher for a new one.'**
  String get authErrorInvalidCode;

  /// No description provided for @authErrorAlreadyActive.
  ///
  /// In en, this message translates to:
  /// **'This account is already active. Sign in with your password.'**
  String get authErrorAlreadyActive;

  /// No description provided for @obCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Import & onboard learners'**
  String get obCenterTitle;

  /// No description provided for @obCenterEntryHint.
  ///
  /// In en, this message translates to:
  /// **'From WhatsApp, contacts, Excel/CSV or a list — keep where each learner is'**
  String get obCenterEntryHint;

  /// No description provided for @obCenterIntro.
  ///
  /// In en, this message translates to:
  /// **'Bring a whole class into Sidra in one go. Sidra checks everyone against existing learners first, then places them in a course and group with their teacher, keeps where each one stopped, and gives each an invitation code. Nothing is saved until the last step.'**
  String get obCenterIntro;

  /// No description provided for @obFromWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'From a WhatsApp group'**
  String get obFromWhatsApp;

  /// No description provided for @obFromWhatsAppHint.
  ///
  /// In en, this message translates to:
  /// **'In WhatsApp: open the group → ⋮ → More → Export chat → Without media. Save or share the file, then choose it here.'**
  String get obFromWhatsAppHint;

  /// No description provided for @obFromContacts.
  ///
  /// In en, this message translates to:
  /// **'From this phone\'s contacts'**
  String get obFromContacts;

  /// No description provided for @obFromContactsHint.
  ///
  /// In en, this message translates to:
  /// **'Choose exactly who to bring; nothing else is read or sent.'**
  String get obFromContactsHint;

  /// No description provided for @obFromFile.
  ///
  /// In en, this message translates to:
  /// **'From an Excel or CSV file'**
  String get obFromFile;

  /// No description provided for @obFromFileHint.
  ///
  /// In en, this message translates to:
  /// **'Columns like Name, Phone, Email, Learner ID, Page, Line, Status, Notes.'**
  String get obFromFileHint;

  /// No description provided for @obFromPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste a list'**
  String get obFromPaste;

  /// No description provided for @obFromPasteHint.
  ///
  /// In en, this message translates to:
  /// **'One learner per line: name and number in any order.'**
  String get obFromPasteHint;

  /// No description provided for @obFromOne.
  ///
  /// In en, this message translates to:
  /// **'One learner'**
  String get obFromOne;

  /// No description provided for @obFromOneHint.
  ///
  /// In en, this message translates to:
  /// **'Add one learner with their course, group and current position.'**
  String get obFromOneHint;

  /// No description provided for @obWhatsAppTruth.
  ///
  /// In en, this message translates to:
  /// **'About WhatsApp: WhatsApp does not let any app read your groups, members or messages, and Sidra never tries to. The exported chat is a file YOU create and choose; Sidra reads only the names and numbers of the people who wrote in it, and keeps the file with each learner as history.'**
  String get obWhatsAppTruth;

  /// No description provided for @obNothingFound.
  ///
  /// In en, this message translates to:
  /// **'No learners were found in that.'**
  String get obNothingFound;

  /// No description provided for @obNotAnExport.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a WhatsApp chat export.'**
  String get obNotAnExport;

  /// No description provided for @obFileTypes.
  ///
  /// In en, this message translates to:
  /// **'Choose an .xlsx, .csv or .txt file.'**
  String get obFileTypes;

  /// No description provided for @obFileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'That file could not be read.'**
  String get obFileUnreadable;

  /// No description provided for @obPasteTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste learners'**
  String get obPasteTitle;

  /// No description provided for @obPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Ahmed Musa, 0772 123 456\nFatuma Ali 0701 234 567'**
  String get obPasteHint;

  /// No description provided for @obContactsWhy.
  ///
  /// In en, this message translates to:
  /// **'To bring learners from this phone\'s contacts, Sidra needs to read your contacts. You then choose exactly who to bring in; Sidra keeps only the people you choose, and only their name and number.'**
  String get obContactsWhy;

  /// No description provided for @obContactsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow access to contacts'**
  String get obContactsAllow;

  /// No description provided for @obContactsCount.
  ///
  /// In en, this message translates to:
  /// **'{total} contacts · {picked} chosen'**
  String obContactsCount(int total, int picked);

  /// No description provided for @obContinueWithN.
  ///
  /// In en, this message translates to:
  /// **'Continue with {count}'**
  String obContinueWithN(int count);

  /// No description provided for @obStepChoose.
  ///
  /// In en, this message translates to:
  /// **'Who to bring'**
  String get obStepChoose;

  /// No description provided for @obStepMatch.
  ///
  /// In en, this message translates to:
  /// **'Check against Sidra'**
  String get obStepMatch;

  /// No description provided for @obStepPlace.
  ///
  /// In en, this message translates to:
  /// **'Course, group, teacher'**
  String get obStepPlace;

  /// No description provided for @obStepPositions.
  ///
  /// In en, this message translates to:
  /// **'Where each learner is'**
  String get obStepPositions;

  /// No description provided for @obStepDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get obStepDone;

  /// No description provided for @obBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get obBack;

  /// No description provided for @obNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get obNext;

  /// No description provided for @obCheck.
  ///
  /// In en, this message translates to:
  /// **'Check {count} against Sidra'**
  String obCheck(int count);

  /// No description provided for @obImportN.
  ///
  /// In en, this message translates to:
  /// **'Import {count}'**
  String obImportN(int count);

  /// No description provided for @obWarnColumns.
  ///
  /// In en, this message translates to:
  /// **'This file has no clear Name or Phone column. Check the rows below and fix them.'**
  String get obWarnColumns;

  /// No description provided for @obWarnSeveralCourses.
  ///
  /// In en, this message translates to:
  /// **'This file lists several courses. Import one course at a time (choose the course in the next steps).'**
  String get obWarnSeveralCourses;

  /// No description provided for @obWarnNoNumbers.
  ///
  /// In en, this message translates to:
  /// **'{count} have no phone number or email (in a WhatsApp export, people saved in your phone show by name only). Tap ✎ to add their number, or untick them.'**
  String obWarnNoNumbers(int count);

  /// No description provided for @obSelected.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} chosen'**
  String obSelected(int selected, int total);

  /// No description provided for @obNoName.
  ///
  /// In en, this message translates to:
  /// **'(no name)'**
  String get obNoName;

  /// No description provided for @obNoNumber.
  ///
  /// In en, this message translates to:
  /// **'no number'**
  String get obNoNumber;

  /// No description provided for @obLastWrote.
  ///
  /// In en, this message translates to:
  /// **'last wrote {date}'**
  String obLastWrote(String date);

  /// No description provided for @obEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get obEdit;

  /// No description provided for @obFix.
  ///
  /// In en, this message translates to:
  /// **'Fix and check again'**
  String get obFix;

  /// No description provided for @obInclude.
  ///
  /// In en, this message translates to:
  /// **'Include'**
  String get obInclude;

  /// No description provided for @obSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get obSkip;

  /// No description provided for @obPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} checked'**
  String obPreviewTitle(int count);

  /// No description provided for @obCountNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get obCountNew;

  /// No description provided for @obCountExisting.
  ///
  /// In en, this message translates to:
  /// **'Already in Sidra'**
  String get obCountExisting;

  /// No description provided for @obCountDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get obCountDuplicate;

  /// No description provided for @obCountRepeated.
  ///
  /// In en, this message translates to:
  /// **'Twice in the list'**
  String get obCountRepeated;

  /// No description provided for @obCountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Needs fixing'**
  String get obCountInvalid;

  /// No description provided for @obDecideDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Some look like learners already in Sidra. Choose for each: use the existing learner, create a separate one, or skip.'**
  String get obDecideDuplicates;

  /// No description provided for @obMatch.
  ///
  /// In en, this message translates to:
  /// **'Matches {name} · {contact} ({why})'**
  String obMatch(String name, String contact, String why);

  /// No description provided for @obWhyPhone.
  ///
  /// In en, this message translates to:
  /// **'same number'**
  String get obWhyPhone;

  /// No description provided for @obWhyEmail.
  ///
  /// In en, this message translates to:
  /// **'same email'**
  String get obWhyEmail;

  /// No description provided for @obWhyName.
  ///
  /// In en, this message translates to:
  /// **'same name'**
  String get obWhyName;

  /// No description provided for @obUseExisting.
  ///
  /// In en, this message translates to:
  /// **'Use {name}'**
  String obUseExisting(String name);

  /// No description provided for @obCreateSeparate.
  ///
  /// In en, this message translates to:
  /// **'A different person: create'**
  String get obCreateSeparate;

  /// No description provided for @obReasonName.
  ///
  /// In en, this message translates to:
  /// **'missing name'**
  String get obReasonName;

  /// No description provided for @obReasonPhone.
  ///
  /// In en, this message translates to:
  /// **'not a valid phone number'**
  String get obReasonPhone;

  /// No description provided for @obReasonEmail.
  ///
  /// In en, this message translates to:
  /// **'not a valid email'**
  String get obReasonEmail;

  /// No description provided for @obReasonNoContact.
  ///
  /// In en, this message translates to:
  /// **'needs a phone number or email'**
  String get obReasonNoContact;

  /// No description provided for @obReasonRepeated.
  ///
  /// In en, this message translates to:
  /// **'already earlier in this list'**
  String get obReasonRepeated;

  /// No description provided for @obCourse.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get obCourse;

  /// No description provided for @obNoCourseYet.
  ///
  /// In en, this message translates to:
  /// **'No course yet'**
  String get obNoCourseYet;

  /// No description provided for @obNoCourseHint.
  ///
  /// In en, this message translates to:
  /// **'Without a course, learners are only added (and invited); you can enrol them and set their positions later.'**
  String get obNoCourseHint;

  /// No description provided for @obGroup.
  ///
  /// In en, this message translates to:
  /// **'Teaching group'**
  String get obGroup;

  /// No description provided for @obNewGroup.
  ///
  /// In en, this message translates to:
  /// **'A new group'**
  String get obNewGroup;

  /// No description provided for @obGroupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get obGroupName;

  /// No description provided for @obExistingGroup.
  ///
  /// In en, this message translates to:
  /// **'An existing group'**
  String get obExistingGroup;

  /// No description provided for @obTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get obTeacher;

  /// No description provided for @obTeacherLater.
  ///
  /// In en, this message translates to:
  /// **'Choose later'**
  String get obTeacherLater;

  /// No description provided for @obWhereFrom.
  ///
  /// In en, this message translates to:
  /// **'Where they came from'**
  String get obWhereFrom;

  /// No description provided for @obPrevPlatform.
  ///
  /// In en, this message translates to:
  /// **'Previous platform'**
  String get obPrevPlatform;

  /// No description provided for @obPrevGroup.
  ///
  /// In en, this message translates to:
  /// **'Previous group'**
  String get obPrevGroup;

  /// No description provided for @obLastKnownOn.
  ///
  /// In en, this message translates to:
  /// **'Last known date'**
  String get obLastKnownOn;

  /// No description provided for @obNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get obNotSet;

  /// No description provided for @obInvite.
  ///
  /// In en, this message translates to:
  /// **'Give each learner an invitation code'**
  String get obInvite;

  /// No description provided for @obInviteHint.
  ///
  /// In en, this message translates to:
  /// **'They use it once to join and choose their own password. No default passwords.'**
  String get obInviteHint;

  /// No description provided for @obPositionsNeedCourse.
  ///
  /// In en, this message translates to:
  /// **'Choose a course (previous step) to record where learners are.'**
  String get obPositionsNeedCourse;

  /// No description provided for @obEveryone.
  ///
  /// In en, this message translates to:
  /// **'For everyone'**
  String get obEveryone;

  /// No description provided for @obEveryoneHint.
  ///
  /// In en, this message translates to:
  /// **'Where most of this group is. Change individual learners below. \"Unknown\" is fine: you can confirm later.'**
  String get obEveryoneHint;

  /// No description provided for @obEachLearner.
  ///
  /// In en, this message translates to:
  /// **'Each learner (tap to change)'**
  String get obEachLearner;

  /// No description provided for @obSameAsEveryone.
  ///
  /// In en, this message translates to:
  /// **'as everyone ({where})'**
  String obSameAsEveryone(String where);

  /// No description provided for @obUseEveryone.
  ///
  /// In en, this message translates to:
  /// **'Same as everyone'**
  String get obUseEveryone;

  /// No description provided for @obLastFeedback.
  ///
  /// In en, this message translates to:
  /// **'Last teacher feedback'**
  String get obLastFeedback;

  /// No description provided for @obConfirm.
  ///
  /// In en, this message translates to:
  /// **'Ready: {created} new learners, {linked} existing linked, {skipped} skipped.'**
  String obConfirm(int created, int linked, int skipped);

  /// No description provided for @obPositionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown — needs confirming'**
  String get obPositionUnknown;

  /// No description provided for @obPositionUnknownShort.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get obPositionUnknownShort;

  /// No description provided for @obPositionUnknownHint.
  ///
  /// In en, this message translates to:
  /// **'Sidra will show \"needs confirming\" until you set it. Nothing is guessed.'**
  String get obPositionUnknownHint;

  /// No description provided for @obPositionNeedsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Position needs confirming'**
  String get obPositionNeedsConfirm;

  /// No description provided for @obPositionLesson.
  ///
  /// In en, this message translates to:
  /// **'A lesson'**
  String get obPositionLesson;

  /// No description provided for @obAyah.
  ///
  /// In en, this message translates to:
  /// **'Ayah'**
  String get obAyah;

  /// No description provided for @obExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get obExercise;

  /// No description provided for @obLineOptional.
  ///
  /// In en, this message translates to:
  /// **'Line (optional)'**
  String get obLineOptional;

  /// No description provided for @obStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get obStatus;

  /// No description provided for @obStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Status unknown'**
  String get obStatusUnknown;

  /// No description provided for @obStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get obStatusNotStarted;

  /// No description provided for @obStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get obStatusInProgress;

  /// No description provided for @obStatusCorrection.
  ///
  /// In en, this message translates to:
  /// **'Correction required'**
  String get obStatusCorrection;

  /// No description provided for @obStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get obStatusCompleted;

  /// No description provided for @obDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Learners imported'**
  String get obDoneTitle;

  /// No description provided for @obDoneCounts.
  ///
  /// In en, this message translates to:
  /// **'{created} created · {matched} linked · {skipped} skipped · {rejected} not imported'**
  String obDoneCounts(int created, int matched, int skipped, int rejected);

  /// No description provided for @obRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not imported, and why'**
  String get obRejectedTitle;

  /// No description provided for @obCopyErrors.
  ///
  /// In en, this message translates to:
  /// **'Copy the list of problems'**
  String get obCopyErrors;

  /// No description provided for @obInvitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get obInvitationsTitle;

  /// No description provided for @obInvitationsHint.
  ///
  /// In en, this message translates to:
  /// **'Send each learner their code. Codes work once and expire in 30 days; you can make a new one any time.'**
  String get obInvitationsHint;

  /// No description provided for @obCopyAllInvites.
  ///
  /// In en, this message translates to:
  /// **'Copy all invitations'**
  String get obCopyAllInvites;

  /// No description provided for @obSendWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Send on WhatsApp'**
  String get obSendWhatsApp;

  /// No description provided for @obInviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum {name}. Our class has moved to Sidra. Install the Sidra app, tap \"I have an invitation code\", enter your number {phone} and the code {code}, then choose your password.'**
  String obInviteMessage(String name, String code, String phone);

  /// No description provided for @obInvitationFor.
  ///
  /// In en, this message translates to:
  /// **'Invitation for {name}'**
  String obInvitationFor(String name);

  /// No description provided for @obInvitationHintOne.
  ///
  /// In en, this message translates to:
  /// **'Works once, for 30 days. Earlier codes for this learner no longer work.'**
  String get obInvitationHintOne;

  /// No description provided for @obCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get obCopy;

  /// No description provided for @obNewCode.
  ///
  /// In en, this message translates to:
  /// **'New invitation code'**
  String get obNewCode;

  /// No description provided for @obHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Import history'**
  String get obHistoryTitle;

  /// No description provided for @obHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Every import: who, when, from where, what happened — and undo'**
  String get obHistoryHint;

  /// No description provided for @obHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing imported yet'**
  String get obHistoryEmpty;

  /// No description provided for @obBatchCounts.
  ///
  /// In en, this message translates to:
  /// **'{processed} rows · {created} new · {matched} linked · {rejected} not imported'**
  String obBatchCounts(int processed, int created, int matched, int rejected);

  /// No description provided for @obUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get obUndo;

  /// No description provided for @obUndone.
  ///
  /// In en, this message translates to:
  /// **'Undone'**
  String get obUndone;

  /// No description provided for @obUndoTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo this import?'**
  String get obUndoTitle;

  /// No description provided for @obUndoBody.
  ///
  /// In en, this message translates to:
  /// **'Removes the learners this import created who have not signed in or done anything yet, and the course and group places it added to existing learners. Learners who already joined, and every learner who existed before, stay.'**
  String get obUndoBody;

  /// No description provided for @obUndoReport.
  ///
  /// In en, this message translates to:
  /// **'{removed} removed · {kept} kept (already active) · {unlinked} existing learners unlinked'**
  String obUndoReport(int removed, int kept, int unlinked);

  /// No description provided for @obOutcomeCreated.
  ///
  /// In en, this message translates to:
  /// **'created'**
  String get obOutcomeCreated;

  /// No description provided for @obOutcomeMatched.
  ///
  /// In en, this message translates to:
  /// **'linked to existing'**
  String get obOutcomeMatched;

  /// No description provided for @obOutcomeSkipped.
  ///
  /// In en, this message translates to:
  /// **'skipped'**
  String get obOutcomeSkipped;

  /// No description provided for @obOutcomeRejected.
  ///
  /// In en, this message translates to:
  /// **'not imported'**
  String get obOutcomeRejected;

  /// No description provided for @obStateImported.
  ///
  /// In en, this message translates to:
  /// **'not invited'**
  String get obStateImported;

  /// No description provided for @obStateInvited.
  ///
  /// In en, this message translates to:
  /// **'invited'**
  String get obStateInvited;

  /// No description provided for @obStateActive.
  ///
  /// In en, this message translates to:
  /// **'joined'**
  String get obStateActive;

  /// No description provided for @obBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Where learners are'**
  String get obBoardTitle;

  /// No description provided for @obBoardHint.
  ///
  /// In en, this message translates to:
  /// **'Per course: each learner\'s position, who still needs setting up'**
  String get obBoardHint;

  /// No description provided for @obChooseCourse.
  ///
  /// In en, this message translates to:
  /// **'Choose a course'**
  String get obChooseCourse;

  /// No description provided for @obBoardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Everyone here is set up'**
  String get obBoardEmpty;

  /// No description provided for @obOnlyNeeds.
  ///
  /// In en, this message translates to:
  /// **'Only those needing something'**
  String get obOnlyNeeds;

  /// No description provided for @obNeedsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} still need their position'**
  String obNeedsCount(int count);

  /// No description provided for @obSetPosition.
  ///
  /// In en, this message translates to:
  /// **'Set position'**
  String get obSetPosition;

  /// No description provided for @obSetPositionFor.
  ///
  /// In en, this message translates to:
  /// **'Set position for {count}'**
  String obSetPositionFor(int count);

  /// No description provided for @obWhereStopped.
  ///
  /// In en, this message translates to:
  /// **'Where did this learner stop?'**
  String get obWhereStopped;

  /// No description provided for @obContinueTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue where you left off'**
  String get obContinueTitle;

  /// No description provided for @obLastPortion.
  ///
  /// In en, this message translates to:
  /// **'Last portion'**
  String get obLastPortion;

  /// No description provided for @obLastSubmission.
  ///
  /// In en, this message translates to:
  /// **'Last work sent'**
  String get obLastSubmission;

  /// No description provided for @obNextAction.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get obNextAction;

  /// No description provided for @obNextRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat {where}'**
  String obNextRepeat(String where);

  /// No description provided for @obNextContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue from {where}'**
  String obNextContinue(String where);

  /// No description provided for @obNextConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm where this learner is'**
  String get obNextConfirm;

  /// No description provided for @obMigrationSource.
  ///
  /// In en, this message translates to:
  /// **'Came from'**
  String get obMigrationSource;

  /// No description provided for @obImported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get obImported;

  /// No description provided for @obNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get obNote;

  /// No description provided for @obHistoricalFrom.
  ///
  /// In en, this message translates to:
  /// **'Historical, from {source} · imported {date}'**
  String obHistoricalFrom(String source, String date);

  /// No description provided for @obSourceContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get obSourceContacts;

  /// No description provided for @obSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Entered by hand'**
  String get obSourceManual;

  /// No description provided for @obSourceOtherLms.
  ///
  /// In en, this message translates to:
  /// **'Another system'**
  String get obSourceOtherLms;

  /// No description provided for @aboutWhatItDoes.
  ///
  /// In en, this message translates to:
  /// **'What Sidra does'**
  String get aboutWhatItDoes;

  /// No description provided for @aboutFeatureTeach.
  ///
  /// In en, this message translates to:
  /// **'Teachers give each day\'s portion once; every learner reads, listens, records and gets a personal correction.'**
  String get aboutFeatureTeach;

  /// No description provided for @aboutFeatureOffline.
  ///
  /// In en, this message translates to:
  /// **'Works on Wi-Fi, on mobile data and offline; your work is sent when you are back online.'**
  String get aboutFeatureOffline;

  /// No description provided for @aboutFeatureWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Moving from WhatsApp keeps each learner\'s place and recordings.'**
  String get aboutFeatureWhatsApp;

  /// No description provided for @aboutFeaturePay.
  ///
  /// In en, this message translates to:
  /// **'Pay fees with MTN or Airtel mobile money; paid courses open once payment is confirmed.'**
  String get aboutFeaturePay;

  /// No description provided for @aboutLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get aboutLatest;

  /// No description provided for @aboutEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier versions ({count})'**
  String aboutEarlier(int count);

  /// No description provided for @lgFinanceHome.
  ///
  /// In en, this message translates to:
  /// **'Finance home'**
  String get lgFinanceHome;

  /// No description provided for @lgWhatWeHave.
  ///
  /// In en, this message translates to:
  /// **'What Almuntahha has'**
  String get lgWhatWeHave;

  /// No description provided for @lgMarzPayShareNote.
  ///
  /// In en, this message translates to:
  /// **'MarzPay wallet is Almuntahha\'s own share: the MarzPay account is shared with DRAIS, so its dashboard total is not all ours.'**
  String get lgMarzPayShareNote;

  /// No description provided for @lgEnterOpening.
  ///
  /// In en, this message translates to:
  /// **'Enter the starting amounts (cash, bank, MarzPay share) so these totals are real'**
  String get lgEnterOpening;

  /// No description provided for @lgNotInBooks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record is not in the books (another currency)} other{{count} records are not in the books (another currency)}}'**
  String lgNotInBooks(int count);

  /// No description provided for @lgNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'{amount} needs an account: fix it with a journal entry'**
  String lgNeedsReview(String amount);

  /// No description provided for @lgTestMoneyHeld.
  ///
  /// In en, this message translates to:
  /// **'Test money held: {amount} (not income)'**
  String lgTestMoneyHeld(String amount);

  /// No description provided for @lgMonthIn.
  ///
  /// In en, this message translates to:
  /// **'Income this month'**
  String get lgMonthIn;

  /// No description provided for @lgMonthOut.
  ///
  /// In en, this message translates to:
  /// **'Expenses this month'**
  String get lgMonthOut;

  /// No description provided for @lgOwedToUs.
  ///
  /// In en, this message translates to:
  /// **'Owed to us by learners'**
  String get lgOwedToUs;

  /// No description provided for @lgBillsToPay.
  ///
  /// In en, this message translates to:
  /// **'Bills to pay'**
  String get lgBillsToPay;

  /// No description provided for @lgClosedThrough.
  ///
  /// In en, this message translates to:
  /// **'Books closed up to {date}'**
  String lgClosedThrough(String date);

  /// No description provided for @lgDoSomething.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get lgDoSomething;

  /// No description provided for @lgPages.
  ///
  /// In en, this message translates to:
  /// **'Finance pages'**
  String get lgPages;

  /// No description provided for @lgPaymentsPage.
  ///
  /// In en, this message translates to:
  /// **'Payments and fees'**
  String get lgPaymentsPage;

  /// No description provided for @lgPaymentsPageHint.
  ///
  /// In en, this message translates to:
  /// **'Check payments, who owes, waivers, refunds'**
  String get lgPaymentsPageHint;

  /// No description provided for @lgAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get lgAccounts;

  /// No description provided for @lgAccountsHint.
  ///
  /// In en, this message translates to:
  /// **'Every account and its balance; opening balances'**
  String get lgAccountsHint;

  /// No description provided for @lgAccountsIntro.
  ///
  /// In en, this message translates to:
  /// **'Every shilling is recorded twice: once where it went and once where it came from, so the books always balance. Tap an account to see its movements.'**
  String get lgAccountsIntro;

  /// No description provided for @lgJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get lgJournal;

  /// No description provided for @lgJournalHint.
  ///
  /// In en, this message translates to:
  /// **'Every entry, debits and credits'**
  String get lgJournalHint;

  /// No description provided for @lgBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get lgBills;

  /// No description provided for @lgBillsHint.
  ///
  /// In en, this message translates to:
  /// **'Bills received and what is still owed'**
  String get lgBillsHint;

  /// No description provided for @lgAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get lgAssets;

  /// No description provided for @lgAssetsHint.
  ///
  /// In en, this message translates to:
  /// **'Equipment and furniture, and their value'**
  String get lgAssetsHint;

  /// No description provided for @lgReports.
  ///
  /// In en, this message translates to:
  /// **'Financial reports'**
  String get lgReports;

  /// No description provided for @lgReportsHint.
  ///
  /// In en, this message translates to:
  /// **'Income and expenses, balance sheet, cash flow, budget'**
  String get lgReportsHint;

  /// No description provided for @lgCounts.
  ///
  /// In en, this message translates to:
  /// **'Counting money'**
  String get lgCounts;

  /// No description provided for @lgCountsHint.
  ///
  /// In en, this message translates to:
  /// **'Check cash, bank and MarzPay against the books'**
  String get lgCountsHint;

  /// No description provided for @lgTypeAsset.
  ///
  /// In en, this message translates to:
  /// **'What we own'**
  String get lgTypeAsset;

  /// No description provided for @lgTypeLiability.
  ///
  /// In en, this message translates to:
  /// **'What we owe'**
  String get lgTypeLiability;

  /// No description provided for @lgTypeEquity.
  ///
  /// In en, this message translates to:
  /// **'Capital'**
  String get lgTypeEquity;

  /// No description provided for @lgTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get lgTypeIncome;

  /// No description provided for @lgTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get lgTypeExpense;

  /// No description provided for @lgNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No suitable account'**
  String get lgNoAccounts;

  /// No description provided for @lgChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose: {what}'**
  String lgChoose(String what);

  /// No description provided for @lgExpenseIntro.
  ///
  /// In en, this message translates to:
  /// **'What it was for and where the money came from.'**
  String get lgExpenseIntro;

  /// No description provided for @lgWhatFor.
  ///
  /// In en, this message translates to:
  /// **'What it was for'**
  String get lgWhatFor;

  /// No description provided for @lgPaidFrom.
  ///
  /// In en, this message translates to:
  /// **'Paid from'**
  String get lgPaidFrom;

  /// No description provided for @lgDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get lgDate;

  /// No description provided for @lgMoneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get lgMoneyIn;

  /// No description provided for @lgMoneyInIntro.
  ///
  /// In en, this message translates to:
  /// **'Money received that is not a course fee: a donation, a loan, or money put in by the owners.'**
  String get lgMoneyInIntro;

  /// No description provided for @lgReceivedInto.
  ///
  /// In en, this message translates to:
  /// **'Received into'**
  String get lgReceivedInto;

  /// No description provided for @lgKindOfMoney.
  ///
  /// In en, this message translates to:
  /// **'Kind of money'**
  String get lgKindOfMoney;

  /// No description provided for @lgDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get lgDescription;

  /// No description provided for @lgMoneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get lgMoneyOut;

  /// No description provided for @lgMoneyOutIntro.
  ///
  /// In en, this message translates to:
  /// **'Money paid that is not a recorded expense or bill: repaying a loan, or buying something kept.'**
  String get lgMoneyOutIntro;

  /// No description provided for @lgTransfer.
  ///
  /// In en, this message translates to:
  /// **'Move money'**
  String get lgTransfer;

  /// No description provided for @lgTransferIntro.
  ///
  /// In en, this message translates to:
  /// **'Between two of our own accounts, e.g. MarzPay withdrawn to the bank.'**
  String get lgTransferIntro;

  /// No description provided for @lgFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get lgFromAccount;

  /// No description provided for @lgToAccount.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get lgToAccount;

  /// No description provided for @lgTransferCharge.
  ///
  /// In en, this message translates to:
  /// **'Charge for the move (optional)'**
  String get lgTransferCharge;

  /// No description provided for @lgRecordBill.
  ///
  /// In en, this message translates to:
  /// **'Record a bill'**
  String get lgRecordBill;

  /// No description provided for @lgBillIntro.
  ///
  /// In en, this message translates to:
  /// **'A bill received but not paid yet. Pay it later, in full or in parts.'**
  String get lgBillIntro;

  /// No description provided for @lgSupplier.
  ///
  /// In en, this message translates to:
  /// **'Who it is from'**
  String get lgSupplier;

  /// No description provided for @lgBillDate.
  ///
  /// In en, this message translates to:
  /// **'Bill date'**
  String get lgBillDate;

  /// No description provided for @lgDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date (optional)'**
  String get lgDueDate;

  /// No description provided for @lgRecordAsset.
  ///
  /// In en, this message translates to:
  /// **'Record an asset'**
  String get lgRecordAsset;

  /// No description provided for @lgAssetIntro.
  ///
  /// In en, this message translates to:
  /// **'Something bought to use for years. Its cost is spread over its useful life.'**
  String get lgAssetIntro;

  /// No description provided for @lgAssetName.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get lgAssetName;

  /// No description provided for @lgCost.
  ///
  /// In en, this message translates to:
  /// **'Cost (UGX)'**
  String get lgCost;

  /// No description provided for @lgPurchasedOn.
  ///
  /// In en, this message translates to:
  /// **'Bought on'**
  String get lgPurchasedOn;

  /// No description provided for @lgPaidHow.
  ///
  /// In en, this message translates to:
  /// **'Paid how'**
  String get lgPaidHow;

  /// No description provided for @lgUsefulLife.
  ///
  /// In en, this message translates to:
  /// **'Useful life in months (optional)'**
  String get lgUsefulLife;

  /// No description provided for @lgUsefulLifeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 36 for a laptop'**
  String get lgUsefulLifeHint;

  /// No description provided for @lgCountMoney.
  ///
  /// In en, this message translates to:
  /// **'Count money'**
  String get lgCountMoney;

  /// No description provided for @lgCountIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter what an account really holds (cash counted, bank statement, MarzPay share) to compare with the books.'**
  String get lgCountIntro;

  /// No description provided for @lgMoneyAccount.
  ///
  /// In en, this message translates to:
  /// **'Money account'**
  String get lgMoneyAccount;

  /// No description provided for @lgCounted.
  ///
  /// In en, this message translates to:
  /// **'Amount counted (UGX)'**
  String get lgCounted;

  /// No description provided for @lgCountNote.
  ///
  /// In en, this message translates to:
  /// **'Explanation of any difference'**
  String get lgCountNote;

  /// No description provided for @lgPostDifference.
  ///
  /// In en, this message translates to:
  /// **'Post the difference'**
  String get lgPostDifference;

  /// No description provided for @lgPostDifferenceHint.
  ///
  /// In en, this message translates to:
  /// **'Records it under Cash differences so the books match what was counted'**
  String get lgPostDifferenceHint;

  /// No description provided for @lgCountResult.
  ///
  /// In en, this message translates to:
  /// **'Count result'**
  String get lgCountResult;

  /// No description provided for @lgCountMatches.
  ///
  /// In en, this message translates to:
  /// **'It matches the books ({books}).'**
  String lgCountMatches(String books);

  /// No description provided for @lgCountDiffers.
  ///
  /// In en, this message translates to:
  /// **'The books say {books}; the difference is {difference}.'**
  String lgCountDiffers(String books, String difference);

  /// No description provided for @lgOpeningFor.
  ///
  /// In en, this message translates to:
  /// **'Opening balance: {account}'**
  String lgOpeningFor(String account);

  /// No description provided for @lgOpeningIntro.
  ///
  /// In en, this message translates to:
  /// **'What this account held when Almuntahha started using these books, from a real record (cash count, bank statement, MarzPay). Changing it replaces the earlier one.'**
  String get lgOpeningIntro;

  /// No description provided for @lgOpeningAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount (UGX)'**
  String get lgOpeningAmount;

  /// No description provided for @lgOpeningDate.
  ///
  /// In en, this message translates to:
  /// **'As of'**
  String get lgOpeningDate;

  /// No description provided for @lgPayBill.
  ///
  /// In en, this message translates to:
  /// **'Pay {supplier}'**
  String lgPayBill(String supplier);

  /// No description provided for @lgStillOwed.
  ///
  /// In en, this message translates to:
  /// **'Still owed: {amount}'**
  String lgStillOwed(String amount);

  /// No description provided for @lgSetBudget.
  ///
  /// In en, this message translates to:
  /// **'Set budget'**
  String get lgSetBudget;

  /// No description provided for @lgBudgetIntro.
  ///
  /// In en, this message translates to:
  /// **'Plan how much you expect to receive or spend in a month, then compare with what really happened.'**
  String get lgBudgetIntro;

  /// No description provided for @lgBudgetAccount.
  ///
  /// In en, this message translates to:
  /// **'Income or expense'**
  String get lgBudgetAccount;

  /// No description provided for @lgBudgetMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get lgBudgetMonth;

  /// No description provided for @lgAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get lgAddAccount;

  /// No description provided for @lgEditAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get lgEditAccount;

  /// No description provided for @lgBuiltInNote.
  ///
  /// In en, this message translates to:
  /// **'A built-in account: its number and kind stay the same.'**
  String get lgBuiltInNote;

  /// No description provided for @lgAccountCode.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get lgAccountCode;

  /// No description provided for @lgAccountCodeHint.
  ///
  /// In en, this message translates to:
  /// **'3 to 6 digits, e.g. 5250'**
  String get lgAccountCodeHint;

  /// No description provided for @lgAccountName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get lgAccountName;

  /// No description provided for @lgAccountType.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get lgAccountType;

  /// No description provided for @lgIsMoney.
  ///
  /// In en, this message translates to:
  /// **'Holds money'**
  String get lgIsMoney;

  /// No description provided for @lgIsMoneyHint.
  ///
  /// In en, this message translates to:
  /// **'Cash, a bank account or a wallet: counted in what Almuntahha has'**
  String get lgIsMoneyHint;

  /// No description provided for @lgInUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get lgInUse;

  /// No description provided for @lgJournalEntry.
  ///
  /// In en, this message translates to:
  /// **'Journal entry'**
  String get lgJournalEntry;

  /// No description provided for @lgJournalIntro.
  ///
  /// In en, this message translates to:
  /// **'For corrections and anything the other forms don\'t cover. The debits must equal the credits.'**
  String get lgJournalIntro;

  /// No description provided for @lgChooseAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose account'**
  String get lgChooseAccount;

  /// No description provided for @lgRemoveLine.
  ///
  /// In en, this message translates to:
  /// **'Remove line'**
  String get lgRemoveLine;

  /// No description provided for @lgDebit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get lgDebit;

  /// No description provided for @lgCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get lgCredit;

  /// No description provided for @lgAddLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get lgAddLine;

  /// No description provided for @lgTotals.
  ///
  /// In en, this message translates to:
  /// **'Debits {debits} · Credits {credits}'**
  String lgTotals(String debits, String credits);

  /// No description provided for @lgSetOpening.
  ///
  /// In en, this message translates to:
  /// **'Set opening balance'**
  String get lgSetOpening;

  /// No description provided for @lgNoMovements.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded yet'**
  String get lgNoMovements;

  /// No description provided for @lgBalanceNow.
  ///
  /// In en, this message translates to:
  /// **'Balance now'**
  String get lgBalanceNow;

  /// No description provided for @lgDr.
  ///
  /// In en, this message translates to:
  /// **'Dr {amount}'**
  String lgDr(String amount);

  /// No description provided for @lgCr.
  ///
  /// In en, this message translates to:
  /// **'Cr {amount}'**
  String lgCr(String amount);

  /// No description provided for @lgSrcPayment.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get lgSrcPayment;

  /// No description provided for @lgSrcRefund.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get lgSrcRefund;

  /// No description provided for @lgSrcExpense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get lgSrcExpense;

  /// No description provided for @lgSrcTest.
  ///
  /// In en, this message translates to:
  /// **'MarzPay tests'**
  String get lgSrcTest;

  /// No description provided for @lgSrcOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening balances'**
  String get lgSrcOpening;

  /// No description provided for @lgSrcBill.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get lgSrcBill;

  /// No description provided for @lgSrcBillPayment.
  ///
  /// In en, this message translates to:
  /// **'Bill payments'**
  String get lgSrcBillPayment;

  /// No description provided for @lgSrcAsset.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get lgSrcAsset;

  /// No description provided for @lgSrcDepreciation.
  ///
  /// In en, this message translates to:
  /// **'Depreciation'**
  String get lgSrcDepreciation;

  /// No description provided for @lgSrcManual.
  ///
  /// In en, this message translates to:
  /// **'Journal entries'**
  String get lgSrcManual;

  /// No description provided for @lgSrcReversal.
  ///
  /// In en, this message translates to:
  /// **'Reversals'**
  String get lgSrcReversal;

  /// No description provided for @lgAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get lgAll;

  /// No description provided for @lgNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get lgNoEntries;

  /// No description provided for @lgReversed.
  ///
  /// In en, this message translates to:
  /// **'reversed'**
  String get lgReversed;

  /// No description provided for @lgReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse this entry'**
  String get lgReverse;

  /// No description provided for @lgEntryBalanced.
  ///
  /// In en, this message translates to:
  /// **'Debits equal credits.'**
  String get lgEntryBalanced;

  /// No description provided for @lgNoBills.
  ///
  /// In en, this message translates to:
  /// **'No bills'**
  String get lgNoBills;

  /// No description provided for @lgDue.
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String lgDue(String date);

  /// No description provided for @lgOwed.
  ///
  /// In en, this message translates to:
  /// **'owed {amount}'**
  String lgOwed(String amount);

  /// No description provided for @lgPaid.
  ///
  /// In en, this message translates to:
  /// **'paid'**
  String get lgPaid;

  /// No description provided for @lgVoidBill.
  ///
  /// In en, this message translates to:
  /// **'Void this bill'**
  String get lgVoidBill;

  /// No description provided for @lgRunDepreciation.
  ///
  /// In en, this message translates to:
  /// **'Write off last month\'s wear'**
  String get lgRunDepreciation;

  /// No description provided for @lgRunDepreciationHint.
  ///
  /// In en, this message translates to:
  /// **'Spreads each asset\'s cost over its useful life; safe to run again'**
  String get lgRunDepreciationHint;

  /// No description provided for @lgDepreciationPosted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to write off for {month}} =1{1 asset written off for {month}} other{{count} assets written off for {month}}}'**
  String lgDepreciationPosted(int count, String month);

  /// No description provided for @lgNoAssets.
  ///
  /// In en, this message translates to:
  /// **'No assets recorded'**
  String get lgNoAssets;

  /// No description provided for @lgBoughtFor.
  ///
  /// In en, this message translates to:
  /// **'{cost} on {date}'**
  String lgBoughtFor(String cost, String date);

  /// No description provided for @lgOverMonths.
  ///
  /// In en, this message translates to:
  /// **'over {months} months'**
  String lgOverMonths(int months);

  /// No description provided for @lgValueNow.
  ///
  /// In en, this message translates to:
  /// **'value now'**
  String get lgValueNow;

  /// No description provided for @lgNoCounts.
  ///
  /// In en, this message translates to:
  /// **'No counts yet'**
  String get lgNoCounts;

  /// No description provided for @lgCountLine.
  ///
  /// In en, this message translates to:
  /// **'counted {counted}, books {books}'**
  String lgCountLine(String counted, String books);

  /// No description provided for @lgDifferencePosted.
  ///
  /// In en, this message translates to:
  /// **'difference posted'**
  String get lgDifferencePosted;

  /// No description provided for @lgIncomeStatement.
  ///
  /// In en, this message translates to:
  /// **'Income and expenses'**
  String get lgIncomeStatement;

  /// No description provided for @lgBalanceSheet.
  ///
  /// In en, this message translates to:
  /// **'Balance sheet'**
  String get lgBalanceSheet;

  /// No description provided for @lgCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash flow'**
  String get lgCashFlow;

  /// No description provided for @lgTrialBalance.
  ///
  /// In en, this message translates to:
  /// **'Trial balance'**
  String get lgTrialBalance;

  /// No description provided for @lgBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get lgBudget;

  /// No description provided for @lgCloseBooks.
  ///
  /// In en, this message translates to:
  /// **'Close the books'**
  String get lgCloseBooks;

  /// No description provided for @lgCloseBooksHelp.
  ///
  /// In en, this message translates to:
  /// **'Close the books up to'**
  String get lgCloseBooksHelp;

  /// No description provided for @lgCloseBooksConfirm.
  ///
  /// In en, this message translates to:
  /// **'No entry can then be dated on or before {date}. Payments confirmed later for those days are booked on the next open day. You can reopen if needed.'**
  String lgCloseBooksConfirm(String date);

  /// No description provided for @lgSurplus.
  ///
  /// In en, this message translates to:
  /// **'Surplus'**
  String get lgSurplus;

  /// No description provided for @lgDeficit.
  ///
  /// In en, this message translates to:
  /// **'Deficit'**
  String get lgDeficit;

  /// No description provided for @lgSurplusSoFar.
  ///
  /// In en, this message translates to:
  /// **'Surplus so far'**
  String get lgSurplusSoFar;

  /// No description provided for @lgBalanceSheetCheck.
  ///
  /// In en, this message translates to:
  /// **'What we own = what we owe + capital (including the surplus so far).'**
  String get lgBalanceSheetCheck;

  /// No description provided for @lgOpeningMoney.
  ///
  /// In en, this message translates to:
  /// **'Money at the start'**
  String get lgOpeningMoney;

  /// No description provided for @lgMoneyCameIn.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get lgMoneyCameIn;

  /// No description provided for @lgMoneyWentOut.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get lgMoneyWentOut;

  /// No description provided for @lgClosingMoney.
  ///
  /// In en, this message translates to:
  /// **'Money at the end'**
  String get lgClosingMoney;

  /// No description provided for @lgNoBudget.
  ///
  /// In en, this message translates to:
  /// **'No budget for this period'**
  String get lgNoBudget;

  /// No description provided for @lgBudgetLine.
  ///
  /// In en, this message translates to:
  /// **'{actual} of {budget}'**
  String lgBudgetLine(String actual, String budget);

  /// No description provided for @rcMyPayments.
  ///
  /// In en, this message translates to:
  /// **'My payments'**
  String get rcMyPayments;

  /// No description provided for @rcMyPaymentsHint.
  ///
  /// In en, this message translates to:
  /// **'Payments and receipts'**
  String get rcMyPaymentsHint;

  /// No description provided for @rcNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get rcNoPayments;

  /// No description provided for @rcCovers.
  ///
  /// In en, this message translates to:
  /// **'covers {from} – {until}'**
  String rcCovers(String from, String until);

  /// No description provided for @rcRefunded.
  ///
  /// In en, this message translates to:
  /// **'{amount} refunded'**
  String rcRefunded(String amount);

  /// No description provided for @rcReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get rcReceipt;

  /// No description provided for @rcCancelled.
  ///
  /// In en, this message translates to:
  /// **'This payment was reversed: the receipt is cancelled.'**
  String get rcCancelled;

  /// No description provided for @rcSavePdf.
  ///
  /// In en, this message translates to:
  /// **'Save as PDF'**
  String get rcSavePdf;

  /// No description provided for @rcSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get rcSaved;

  /// No description provided for @rcIssuedNote.
  ///
  /// In en, this message translates to:
  /// **'Issued by Sidra when the payment was confirmed.'**
  String get rcIssuedNote;

  /// No description provided for @rcReceivedFrom.
  ///
  /// In en, this message translates to:
  /// **'Received from'**
  String get rcReceivedFrom;

  /// No description provided for @rcPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get rcPhone;

  /// No description provided for @rcFor.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get rcFor;

  /// No description provided for @rcPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period paid for'**
  String get rcPeriod;

  /// No description provided for @rcAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get rcAmount;

  /// No description provided for @rcRefundedLabel.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get rcRefundedLabel;

  /// No description provided for @rcMethod.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get rcMethod;

  /// No description provided for @rcTransactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get rcTransactionId;

  /// No description provided for @rcPaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get rcPaidOn;

  /// No description provided for @rcConfirmedBy.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by'**
  String get rcConfirmedBy;

  /// No description provided for @rcSidraRef.
  ///
  /// In en, this message translates to:
  /// **'Sidra reference'**
  String get rcSidraRef;

  /// No description provided for @ppPayAhead.
  ///
  /// In en, this message translates to:
  /// **'Pay for several {periods} at once'**
  String ppPayAhead(String periods);

  /// No description provided for @ppTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay ahead'**
  String get ppTitle;

  /// No description provided for @ppIntro.
  ///
  /// In en, this message translates to:
  /// **'Pay for several periods now and learn without paying again until they end.'**
  String get ppIntro;

  /// No description provided for @ppCovers.
  ///
  /// In en, this message translates to:
  /// **'Covers {from} to {until}'**
  String ppCovers(String from, String until);

  /// No description provided for @ppWeeks.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 week} other{{n} weeks}}'**
  String ppWeeks(int n);

  /// No description provided for @ppMonths.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 month} other{{n} months}}'**
  String ppMonths(int n);

  /// No description provided for @ppTerms.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 term} other{{n} terms}}'**
  String ppTerms(int n);

  /// No description provided for @ppPeriods.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 period} other{{n} periods}}'**
  String ppPeriods(int n);

  /// No description provided for @rfTab.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get rfTab;

  /// No description provided for @rfIntro.
  ///
  /// In en, this message translates to:
  /// **'A refund is owed to the learner when agreed, and cleared when the money is sent back. Send it by mobile money, bank or cash, then record the transaction ID here.'**
  String get rfIntro;

  /// No description provided for @rfNone.
  ///
  /// In en, this message translates to:
  /// **'No refunds'**
  String get rfNone;

  /// No description provided for @rfOwedSince.
  ///
  /// In en, this message translates to:
  /// **'owed since {date}'**
  String rfOwedSince(String date);

  /// No description provided for @rfPaidOut.
  ///
  /// In en, this message translates to:
  /// **'paid {date} from {account} ({reference})'**
  String rfPaidOut(String date, String account, String reference);

  /// No description provided for @rfPayOut.
  ///
  /// In en, this message translates to:
  /// **'Pay out'**
  String get rfPayOut;

  /// No description provided for @rfPayOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund to {learner}'**
  String rfPayOutTitle(String learner);

  /// No description provided for @rfPayOutIntro.
  ///
  /// In en, this message translates to:
  /// **'Send {amount} back (their number: {phone}), then record it here.'**
  String rfPayOutIntro(String amount, String phone);

  /// No description provided for @rfMethod.
  ///
  /// In en, this message translates to:
  /// **'Sent by'**
  String get rfMethod;

  /// No description provided for @rfMethodHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. MTN, Airtel, bank, cash'**
  String get rfMethodHint;

  /// No description provided for @rfReference.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID or receipt'**
  String get rfReference;

  /// No description provided for @rfOwedAlert.
  ///
  /// In en, this message translates to:
  /// **'Refunds still to pay back: {amount}'**
  String rfOwedAlert(String amount);

  /// No description provided for @mkTitle.
  ///
  /// In en, this message translates to:
  /// **'MarzPay check'**
  String get mkTitle;

  /// No description provided for @mkIntro.
  ///
  /// In en, this message translates to:
  /// **'Sidra compares each of its MarzPay payments with MarzPay\'s own records (money in, amount, fee) every few minutes.'**
  String get mkIntro;

  /// No description provided for @mkCounts.
  ///
  /// In en, this message translates to:
  /// **'{matched} agree · {mismatched} differ · {waiting} waiting · {notChecked} not checked yet'**
  String mkCounts(int matched, int mismatched, int waiting, int notChecked);

  /// No description provided for @mkLast.
  ///
  /// In en, this message translates to:
  /// **'Last checked {when}'**
  String mkLast(String when);

  /// No description provided for @exDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get exDownloadPdf;

  /// No description provided for @exDownloadExcel.
  ///
  /// In en, this message translates to:
  /// **'Download Excel'**
  String get exDownloadExcel;

  /// No description provided for @exAsOf.
  ///
  /// In en, this message translates to:
  /// **'as of {date}'**
  String exAsOf(String date);

  /// No description provided for @exItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get exItem;

  /// No description provided for @exActual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get exActual;

  /// No description provided for @exHeader.
  ///
  /// In en, this message translates to:
  /// **'Almuntahha · Sidra financial records'**
  String get exHeader;

  /// No description provided for @arTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounting rules'**
  String get arTitle;

  /// No description provided for @arHint.
  ///
  /// In en, this message translates to:
  /// **'How the books work, for the accountant to confirm'**
  String get arHint;

  /// No description provided for @arIntro.
  ///
  /// In en, this message translates to:
  /// **'These are the rules Sidra\'s books follow. Whoever keeps Almuntahha\'s accounts should read them and confirm, or ask for a change.'**
  String get arIntro;

  /// No description provided for @arNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'The accounting rules are not yet confirmed by the accountant'**
  String get arNotConfirmed;

  /// No description provided for @arConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by {by} on {date}'**
  String arConfirmed(String by, String date);

  /// No description provided for @arSendPdf.
  ///
  /// In en, this message translates to:
  /// **'Save as PDF for the accountant'**
  String get arSendPdf;

  /// No description provided for @arConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Record confirmation'**
  String get arConfirmTitle;

  /// No description provided for @arConfirmIntro.
  ///
  /// In en, this message translates to:
  /// **'Record who confirmed these rules (name of the accountant) and any comment.'**
  String get arConfirmIntro;

  /// No description provided for @arConfirmedBy.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by (name)'**
  String get arConfirmedBy;

  /// No description provided for @arNote.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get arNote;

  /// No description provided for @arRule.
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get arRule;

  /// No description provided for @arWhat.
  ///
  /// In en, this message translates to:
  /// **'What it means'**
  String get arWhat;

  /// No description provided for @arPdfHeader.
  ///
  /// In en, this message translates to:
  /// **'Almuntahha · Sidra accounting rules for review'**
  String get arPdfHeader;

  /// No description provided for @arCashTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash basis'**
  String get arCashTitle;

  /// No description provided for @arCash.
  ///
  /// In en, this message translates to:
  /// **'Income is counted when money is received. What learners still owe is shown separately and is not counted as income.'**
  String get arCash;

  /// No description provided for @arOpeningTitle.
  ///
  /// In en, this message translates to:
  /// **'Starting amounts from real records'**
  String get arOpeningTitle;

  /// No description provided for @arOpening.
  ///
  /// In en, this message translates to:
  /// **'Each money account starts at the amount staff enter from a real record (cash count, bank statement, MarzPay). Sidra never guesses a balance.'**
  String get arOpening;

  /// No description provided for @arMarzPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Almuntahha\'s MarzPay share only'**
  String get arMarzPayTitle;

  /// No description provided for @arMarzPay.
  ///
  /// In en, this message translates to:
  /// **'The MarzPay account is shared with DRAIS. The books count only Almuntahha\'s own MarzPay payments, fees and payouts.'**
  String get arMarzPay;

  /// No description provided for @arFeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Actual provider fees'**
  String get arFeesTitle;

  /// No description provided for @arFees.
  ///
  /// In en, this message translates to:
  /// **'Each payment\'s fee is the amount MarzPay actually charged on it, never an assumed rate. Fees are an expense.'**
  String get arFees;

  /// No description provided for @arTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Test money is not income'**
  String get arTestTitle;

  /// No description provided for @arTest.
  ///
  /// In en, this message translates to:
  /// **'Real-money MarzPay tests are held in \'Test money\' (a liability), not counted as income. Their fees are an expense.'**
  String get arTest;

  /// No description provided for @arRefundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get arRefundsTitle;

  /// No description provided for @arRefunds.
  ///
  /// In en, this message translates to:
  /// **'An agreed refund reduces income at once and is owed to the learner until it is paid back from a money account.'**
  String get arRefunds;

  /// No description provided for @arClosingTitle.
  ///
  /// In en, this message translates to:
  /// **'Closing months'**
  String get arClosingTitle;

  /// No description provided for @arClosing.
  ///
  /// In en, this message translates to:
  /// **'Finance staff close a month when it is final. Nothing can be dated into a closed month; late automatic entries go to the next open day.'**
  String get arClosing;

  /// No description provided for @arAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get arAccountsTitle;

  /// No description provided for @arAccounts.
  ///
  /// In en, this message translates to:
  /// **'Staff may add accounts. Built-in accounts keep their number and kind; an account holding money cannot be retired.'**
  String get arAccounts;

  /// No description provided for @arCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'One currency (UGX)'**
  String get arCurrencyTitle;

  /// No description provided for @arCurrency.
  ///
  /// In en, this message translates to:
  /// **'The books are kept in UGX. A record in another currency is listed on the finance home, not converted.'**
  String get arCurrency;

  /// No description provided for @arPermanentTitle.
  ///
  /// In en, this message translates to:
  /// **'Entries are permanent'**
  String get arPermanentTitle;

  /// No description provided for @arPermanent.
  ///
  /// In en, this message translates to:
  /// **'Every entry balances (debits = credits) and can never be edited or deleted. Mistakes are corrected with a reversing entry.'**
  String get arPermanent;

  /// No description provided for @mvPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get mvPlay;

  /// No description provided for @mvView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get mvView;

  /// No description provided for @apTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get apTitle;

  /// No description provided for @apHint.
  ///
  /// In en, this message translates to:
  /// **'Theme, wallpaper and text size'**
  String get apHint;

  /// No description provided for @apMode.
  ///
  /// In en, this message translates to:
  /// **'Light or dark'**
  String get apMode;

  /// No description provided for @apModeOrg.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get apModeOrg;

  /// No description provided for @apModeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow the phone'**
  String get apModeSystem;

  /// No description provided for @apModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get apModeLight;

  /// No description provided for @apModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get apModeDark;

  /// No description provided for @apThemes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get apThemes;

  /// No description provided for @apThemesHint.
  ///
  /// In en, this message translates to:
  /// **'Themes with a lock come with premium themes.'**
  String get apThemesHint;

  /// No description provided for @apOrgDefault.
  ///
  /// In en, this message translates to:
  /// **'Almuntahha\'s'**
  String get apOrgDefault;

  /// No description provided for @apAnyColour.
  ///
  /// In en, this message translates to:
  /// **'Any colour'**
  String get apAnyColour;

  /// No description provided for @apPremiumOnly.
  ///
  /// In en, this message translates to:
  /// **'With premium themes'**
  String get apPremiumOnly;

  /// No description provided for @apWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get apWallpaper;

  /// No description provided for @apWallpaperHint.
  ///
  /// In en, this message translates to:
  /// **'Your own photo stays on this phone.'**
  String get apWallpaperHint;

  /// No description provided for @apWpNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get apWpNone;

  /// No description provided for @apWpPhoto.
  ///
  /// In en, this message translates to:
  /// **'Your photo'**
  String get apWpPhoto;

  /// No description provided for @apWpDawn.
  ///
  /// In en, this message translates to:
  /// **'Dawn'**
  String get apWpDawn;

  /// No description provided for @apWpDunes.
  ///
  /// In en, this message translates to:
  /// **'Dunes'**
  String get apWpDunes;

  /// No description provided for @apWpMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get apWpMint;

  /// No description provided for @apWpSky.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get apWpSky;

  /// No description provided for @apWpDusk.
  ///
  /// In en, this message translates to:
  /// **'Dusk'**
  String get apWpDusk;

  /// No description provided for @apWpNightSky.
  ///
  /// In en, this message translates to:
  /// **'Night sky'**
  String get apWpNightSky;

  /// No description provided for @apWpForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get apWpForest;

  /// No description provided for @apWpRose.
  ///
  /// In en, this message translates to:
  /// **'Rose garden'**
  String get apWpRose;

  /// No description provided for @apCover.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper behind pages'**
  String get apCover;

  /// No description provided for @apCoverHint.
  ///
  /// In en, this message translates to:
  /// **'Left: more wallpaper, right: plainer pages'**
  String get apCoverHint;

  /// No description provided for @apTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get apTextSize;

  /// No description provided for @apFont.
  ///
  /// In en, this message translates to:
  /// **'Heading font'**
  String get apFont;

  /// No description provided for @apFontSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone\'s font'**
  String get apFontSystem;

  /// No description provided for @apCorners.
  ///
  /// In en, this message translates to:
  /// **'Rounded corners'**
  String get apCorners;

  /// No description provided for @apReset.
  ///
  /// In en, this message translates to:
  /// **'Back to Almuntahha\'s look'**
  String get apReset;

  /// No description provided for @apPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium themes'**
  String get apPremiumTitle;

  /// No description provided for @apPremiumWhat.
  ///
  /// In en, this message translates to:
  /// **'All themes, any colour, heading fonts, rounded corners and how much wallpaper shows. Paid once with mobile money; yours on every phone you sign in on.'**
  String get apPremiumWhat;

  /// No description provided for @apPremiumOffer.
  ///
  /// In en, this message translates to:
  /// **'More themes, any colour and more: {price}, once'**
  String apPremiumOffer(String price);

  /// No description provided for @apPremiumNotOnSale.
  ///
  /// In en, this message translates to:
  /// **'Premium themes are not on sale yet.'**
  String get apPremiumNotOnSale;

  /// No description provided for @apUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get apUnlock;

  /// No description provided for @apUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Premium themes are yours'**
  String get apUnlocked;

  /// No description provided for @apApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve {price} on your phone'**
  String apApprove(String price);

  /// No description provided for @apPay.
  ///
  /// In en, this message translates to:
  /// **'Pay {price} with mobile money'**
  String apPay(String price);

  /// No description provided for @apOrgLook.
  ///
  /// In en, this message translates to:
  /// **'Organisation look'**
  String get apOrgLook;

  /// No description provided for @apOrgLookHint.
  ///
  /// In en, this message translates to:
  /// **'What every phone shows (superadmin)'**
  String get apOrgLookHint;

  /// No description provided for @apOrgLookIntro.
  ///
  /// In en, this message translates to:
  /// **'Everyone starts with this look. People may still choose the free themes and their own wallpaper; premium themes need payment.'**
  String get apOrgLookIntro;

  /// No description provided for @apMainColour.
  ///
  /// In en, this message translates to:
  /// **'Main colour'**
  String get apMainColour;

  /// No description provided for @apAccentColour.
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get apAccentColour;

  /// No description provided for @apWallpaperLink.
  ///
  /// In en, this message translates to:
  /// **'Or a link to a picture (https)'**
  String get apWallpaperLink;

  /// No description provided for @apFreeThemes.
  ///
  /// In en, this message translates to:
  /// **'Free themes'**
  String get apFreeThemes;

  /// No description provided for @apPremiumPrice.
  ///
  /// In en, this message translates to:
  /// **'Price of premium themes'**
  String get apPremiumPrice;

  /// No description provided for @apPremiumPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to keep them off sale'**
  String get apPremiumPriceHint;

  /// No description provided for @apThTeal.
  ///
  /// In en, this message translates to:
  /// **'Sidra teal'**
  String get apThTeal;

  /// No description provided for @apThNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get apThNight;

  /// No description provided for @apThSand.
  ///
  /// In en, this message translates to:
  /// **'Sand'**
  String get apThSand;

  /// No description provided for @apThOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get apThOcean;

  /// No description provided for @apThEmerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get apThEmerald;

  /// No description provided for @apThRoyal.
  ///
  /// In en, this message translates to:
  /// **'Royal'**
  String get apThRoyal;

  /// No description provided for @apThRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get apThRose;

  /// No description provided for @apThGoldNight.
  ///
  /// In en, this message translates to:
  /// **'Gold night'**
  String get apThGoldNight;

  /// No description provided for @apThOlive.
  ///
  /// In en, this message translates to:
  /// **'Olive'**
  String get apThOlive;

  /// No description provided for @apThSky.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get apThSky;

  /// No description provided for @apThCrimson.
  ///
  /// In en, this message translates to:
  /// **'Crimson'**
  String get apThCrimson;

  /// No description provided for @apThSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get apThSlate;
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
