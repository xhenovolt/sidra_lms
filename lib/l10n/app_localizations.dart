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
  /// **'Sign in with your phone number or email to continue your studies.'**
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
  /// **'Developer: add AUTH_URL to .env, then run  dart run tool/gen_config.dart'**
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
  /// **'Include your country code, e.g. +256 700 123 456'**
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
  /// **'Ask your teacher or Almuntahha to reset it. You will get a temporary password and choose a new one when you sign in.'**
  String get authForgotBody;

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
  /// **'At least 8 characters'**
  String get authPasswordRule;

  /// No description provided for @authPasswordsDiffer.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDiffer;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Start with + and your country code'**
  String get authPhoneInvalid;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'That phone/email and password don\'t match.'**
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
  /// **'This account is disabled. Contact Almuntahha.'**
  String get authErrorDisabled;

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
