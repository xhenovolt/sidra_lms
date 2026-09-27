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
      'Sign in with your phone number, email or username to continue your studies.';

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
      'Developer: run  dart run tool/db.dart app-role  then  dart run tool/gen_config.dart';

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

  @override
  String get adminAccess => 'Who can join';

  @override
  String get adminAdd => 'Add';

  @override
  String get adminAddContent => 'Add content';

  @override
  String get adminAddLesson => 'Add lesson';

  @override
  String get adminAddLevel => 'Add level';

  @override
  String get adminAddOption => 'Add option';

  @override
  String get adminAddQuestion => 'Add question';

  @override
  String get adminAddSection => 'Add section';

  @override
  String get adminAddSubsection => 'Add part inside';

  @override
  String get adminAddUnit => 'Add unit';

  @override
  String get adminAllLearners => 'All learners';

  @override
  String get adminArabicText => 'Arabic text';

  @override
  String get adminAssignTeacher => 'Make teacher of a course';

  @override
  String get adminAuthor => 'Author';

  @override
  String get adminAwaitingReview => 'Waiting for your review';

  @override
  String get adminBlockAttachment => 'File';

  @override
  String get adminBlockAudio => 'Audio';

  @override
  String get adminBlockCallout => 'Highlight box';

  @override
  String get adminBlockDivider => 'Divider';

  @override
  String get adminBlockHeading => 'Heading';

  @override
  String get adminBlockImage => 'Picture';

  @override
  String get adminBlockQuiz => 'Quiz';

  @override
  String get adminBlockQuran => 'Quran text';

  @override
  String get adminBlockReference => 'Reference';

  @override
  String get adminBlockText => 'Text';

  @override
  String get adminBlockTranslation => 'Translation';

  @override
  String get adminBlockTransliteration => 'Transliteration';

  @override
  String get adminBlockVideo => 'Video';

  @override
  String get adminBook => 'Book';

  @override
  String get adminCancel => 'Cancel';

  @override
  String get adminCaption => 'Caption';

  @override
  String get adminChangeRoleTitle => 'Change role?';

  @override
  String get adminChapter => 'Chapter';

  @override
  String get adminChooseFile => 'Choose a file from this device';

  @override
  String get adminCitation => 'Citation';

  @override
  String get adminConfirm => 'Confirm';

  @override
  String get adminContent => 'Content';

  @override
  String get adminCopyright => 'Copyright / usage notes';

  @override
  String get adminCourseTitle => 'Course name';

  @override
  String get adminCover => 'Cover picture';

  @override
  String get adminCreate => 'Create';

  @override
  String get adminCurrency => 'Currency';

  @override
  String get adminCurrentLesson => 'Current lesson';

  @override
  String get adminCustomStructure => 'My own levels';

  @override
  String get adminDelete => 'Delete';

  @override
  String get adminDeleteBlockBody =>
      'This content will be removed from the lesson.';

  @override
  String get adminDeleteLessonBody =>
      'The lesson, its content and learners\' progress on it will be deleted.';

  @override
  String get adminDeleteNodeBody =>
      'This part and everything inside it (including lessons) will be deleted.';

  @override
  String get adminDeleteQuestionBody =>
      'This question will be removed from the quiz.';

  @override
  String get adminDeleteTitle => 'Delete?';

  @override
  String get adminDeleteUnitBody =>
      'The unit and everything inside it will be deleted.';

  @override
  String get adminDescription => 'Description';

  @override
  String get adminDifficulty => 'Level';

  @override
  String get adminDraft => 'Draft';

  @override
  String get adminEdit => 'Edit';

  @override
  String get adminEditCourse => 'Edit course details';

  @override
  String get adminEditQuestions => 'Edit questions';

  @override
  String get adminEdition => 'Edition';

  @override
  String get adminEmptyLessonBody =>
      'Tap “Add content” to write text, add Quran verses, pictures, audio or a quiz.';

  @override
  String get adminEmptyLessonTitle => 'This lesson is empty';

  @override
  String get adminEstimatedHours => 'Estimated hours';

  @override
  String get adminExplanation => 'Explanation shown after answering';

  @override
  String get adminFalse => 'False';

  @override
  String get adminFileUploaded => 'File uploaded';

  @override
  String get adminFromBook => 'Comes from book';

  @override
  String get adminGradedQuiz => 'Graded quiz';

  @override
  String get adminGradedQuizHint =>
      'Counts for the learner. Needs internet; answers stay hidden.';

  @override
  String get adminGrantCourse => 'Give access to a course';

  @override
  String get adminHidden => 'Hidden from learners';

  @override
  String get adminLanguage => 'Language';

  @override
  String get adminLevel => 'Level';

  @override
  String get adminLevelHint => 'e.g. Surah, Page, Chapter';

  @override
  String get adminLink => 'Web link';

  @override
  String get adminLinkBook => 'Link a book';

  @override
  String get adminMakeRole => 'Make';

  @override
  String get adminMaxAttempts => 'Attempts allowed';

  @override
  String get adminMinutes => 'Minutes to complete';

  @override
  String get adminMoveDown => 'Move down';

  @override
  String get adminMoveUp => 'Move up';

  @override
  String get adminNeedsConnection => 'This needs an internet connection.';

  @override
  String get adminNeedsRevision => 'Needs revision';

  @override
  String get adminNewBook => 'New book';

  @override
  String get adminNewCourse => 'New course';

  @override
  String get adminNoBook => 'Not from a book';

  @override
  String get adminNoBooksBody =>
      'Add the books your courses teach from, then choose how each book is organised.';

  @override
  String get adminNoBooksTitle => 'No books yet';

  @override
  String get adminNoBooksToLink =>
      'All books are already linked. Add books in the Books tab.';

  @override
  String get adminNoCoursesBody =>
      'Create your first course to start building the curriculum.';

  @override
  String get adminNoCoursesTitle => 'No courses yet';

  @override
  String get adminNoLearnersBody =>
      'Learners enrolled in your courses will appear here.';

  @override
  String get adminNoLearnersTitle => 'No learners yet';

  @override
  String get adminNoQuestions => 'No questions yet. Tap “Add question”.';

  @override
  String get adminNoStructure => 'Organisation not set';

  @override
  String get adminNoUnit => 'No unit';

  @override
  String get adminNotAllowed => 'You don\'t have permission for this.';

  @override
  String get adminOnePerLine => 'One per line';

  @override
  String get adminOpenNextLesson => 'Open the next lesson for this learner';

  @override
  String get adminOption => 'Option';

  @override
  String get adminOptionsHint => 'Tick the correct answer(s):';

  @override
  String get adminOutlineHint =>
      'Add sections (like a Surah, a page or a chapter) and lessons inside them.';

  @override
  String get adminPageFrom => 'Page from';

  @override
  String get adminPageTo => 'Page to';

  @override
  String get adminPassMark => 'Pass mark';

  @override
  String get adminPassed => 'Passed';

  @override
  String get adminPickCorrect => 'Tick at least one correct answer.';

  @override
  String get adminPracticeQuizHint =>
      'For practice. Works offline; learners see correct answers.';

  @override
  String get adminPreview => 'Preview';

  @override
  String get adminPreviewAsLearner => 'See it as a learner';

  @override
  String get adminPreviewLesson => 'Free preview';

  @override
  String get adminPreviewLessonHint =>
      'Every enrolled learner can open it without unlocking';

  @override
  String get adminPrice => 'Price';

  @override
  String get adminProgression => 'How learners move forward';

  @override
  String get adminProgressionOpen => 'All lessons open';

  @override
  String get adminProgressionSequential => 'Next lesson opens after finishing';

  @override
  String get adminProgressionTeacher => 'Teacher opens each next lesson';

  @override
  String get adminPublish => 'Publish';

  @override
  String get adminPublishCourse => 'Published';

  @override
  String get adminPublished => 'Published';

  @override
  String get adminQMultiple => 'Choose all that apply';

  @override
  String get adminQRecitation => 'Recitation (marked in class)';

  @override
  String get adminQShort => 'Written answer';

  @override
  String get adminQSingle => 'Choose one';

  @override
  String get adminQTrueFalse => 'True or false';

  @override
  String get adminQuestion => 'Question';

  @override
  String get adminQuestionType => 'Question type';

  @override
  String get adminReferenceLabel => 'Reference shown to learners';

  @override
  String get adminReferenceLabelHint => 'e.g. Al-Fatihah 1–3, p. 12';

  @override
  String get adminRequired => 'Required';

  @override
  String get adminReviewSaved => 'Review saved';

  @override
  String get adminReviewSavedUnlocked =>
      'Review saved and the next lesson is open';

  @override
  String get adminSave => 'Save';

  @override
  String get adminSaveReview => 'Save review';

  @override
  String get adminSaved => 'Saved';

  @override
  String get adminScore => 'Score';

  @override
  String get adminSectionType => 'Kind of section';

  @override
  String get adminSectionTypeHint => 'e.g. Chapter, Page, Topic';

  @override
  String get adminSetStructure => 'How is this book organised?';

  @override
  String get adminSetStructureHint =>
      'Choose levels such as Surah → Verse or Page';

  @override
  String get adminSource => 'Source';

  @override
  String get adminStructureExplain =>
      'Pick how this book is divided. Lessons are placed inside the smallest part.';

  @override
  String get adminSubject => 'Subject';

  @override
  String get adminSubjectHint => 'e.g. Quran, Aqeedah, Fiqh, Arabic';

  @override
  String get adminSubtitle => 'Short tagline';

  @override
  String get adminSummary => 'Short summary';

  @override
  String get adminSurah => 'Surah no.';

  @override
  String get adminTabCourses => 'Courses';

  @override
  String get adminTabLearners => 'Learners';

  @override
  String get adminTabPeople => 'People';

  @override
  String get adminText => 'Text';

  @override
  String get adminTextHint =>
      'Use **bold**, *italic*, and start lines with - for bullet points';

  @override
  String get adminThumbnail => 'Course picture';

  @override
  String get adminTitle => 'Title';

  @override
  String get adminToneInfo => 'Info';

  @override
  String get adminToneNote => 'Note';

  @override
  String get adminToneWarning => 'Important';

  @override
  String get adminTranscript => 'Transcript (optional)';

  @override
  String get adminTranslator => 'Translator';

  @override
  String get adminTrue => 'True';

  @override
  String get adminUnitOptional => 'Unit';

  @override
  String get adminUnits => 'Units';

  @override
  String get adminUnitsHint =>
      'Units group your course into big steps. They are optional.';

  @override
  String get adminUnlimited => 'Unlimited';

  @override
  String get adminUnpublish => 'Hide from learners';

  @override
  String get adminVerseFrom => 'Verse from';

  @override
  String get adminVerseTo => 'Verse to';

  @override
  String get adminVisibleToLearners => 'Visible to learners';

  @override
  String get adminWholeCourse => 'Whole course';

  @override
  String adminChangeRoleBody(String name) {
    return 'Change the role of $name? Their permissions change immediately.';
  }

  @override
  String get authPhone => 'Phone';

  @override
  String get authEmail => 'Email';

  @override
  String get authPhoneLabel => 'Phone number';

  @override
  String get authPhoneHint =>
      'Include your country code, e.g. +256 700 123 456';

  @override
  String get authEmailLabel => 'Email address';

  @override
  String get authPassword => 'Password';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authFullName => 'Full name';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Create account';

  @override
  String get authNoAccount => 'New to Sidra? Create an account';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get authSignUpTitle => 'Create your account';

  @override
  String get authSignUpSubtitle =>
      'Use your phone number or email. You will sign in with it and your password.';

  @override
  String get authForgot => 'Forgot your password?';

  @override
  String get authForgotBody =>
      'Ask your teacher or Almuntahha to reset it. You will get a temporary password and choose a new one when you sign in.';

  @override
  String get authChangePasswordTitle => 'Choose a new password';

  @override
  String get authChangePasswordForced =>
      'Your password was reset. Please choose a new one to continue.';

  @override
  String get authCurrentPassword => 'Current (or temporary) password';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authSavePassword => 'Save password';

  @override
  String get authPasswordChanged => 'Password changed';

  @override
  String get authChangePassword => 'Change password';

  @override
  String get authRequired => 'Required';

  @override
  String get authPasswordRule => 'At least 8 characters';

  @override
  String get authPasswordsDiffer => 'Passwords do not match';

  @override
  String get authPhoneInvalid => 'Start with + and your country code';

  @override
  String get authEmailInvalid => 'Enter a valid email address';

  @override
  String get authErrorInvalidCredentials =>
      'Those sign-in details and password don\'t match.';

  @override
  String get authErrorTaken =>
      'An account already exists with this phone/email. Try signing in.';

  @override
  String get authErrorWeak => 'Password must be at least 8 characters.';

  @override
  String get authErrorIdentifier =>
      'Check the phone number (with country code) or email.';

  @override
  String get authErrorLocked =>
      'Too many attempts. Please wait 15 minutes and try again.';

  @override
  String get authErrorDisabled =>
      'This account is disabled. Contact Almuntahha.';

  @override
  String get authErrorSamePassword =>
      'Choose a password different from the current one.';

  @override
  String get authErrorOffline =>
      'No connection. Check your internet and try again.';

  @override
  String get adminResetPassword => 'Reset password';

  @override
  String get adminResetPasswordBody =>
      'Give this temporary password to the learner. They must choose a new one when they sign in.';

  @override
  String get adminTemporaryPassword => 'Temporary password';

  @override
  String get adminPasswordReset =>
      'Password reset. Share the temporary password with the learner.';

  @override
  String get roleSuperadmin => 'Superadmin';

  @override
  String get authUsername => 'Username';

  @override
  String get authUsernameInvalid =>
      '3–30 letters, numbers, dots or underscores';

  @override
  String get adminTabOverview => 'Overview';

  @override
  String get adminStatLearners => 'Learners';

  @override
  String get adminStatTeachers => 'Teachers';

  @override
  String get adminStatAdmins => 'Administrators';

  @override
  String get adminStatPublished => 'Published courses';

  @override
  String get adminStatDrafts => 'Draft courses';

  @override
  String get adminStatEnrolments => 'Active enrolments';

  @override
  String get adminStatActive7d => 'Active learners (7 days)';

  @override
  String get adminStatCompleted7d => 'Lessons completed (7 days)';

  @override
  String get adminQuickActions => 'Quick actions';

  @override
  String get adminAddPerson => 'Add person';

  @override
  String get adminSearchPeople => 'Search by name, phone, email or username';

  @override
  String get adminEveryone => 'Everyone';

  @override
  String get adminNoPeople => 'No one found';

  @override
  String get adminDisabled => 'Disabled';

  @override
  String get adminDisabledNote =>
      'This account is disabled and cannot sign in.';

  @override
  String get adminEditDetails => 'Edit details';

  @override
  String get adminSuperadminHint =>
      'Can create and manage other administrators';

  @override
  String get adminDisableAccount => 'Disable account';

  @override
  String get adminEnableAccount => 'Enable account';

  @override
  String get adminDisableHint =>
      'They are signed out everywhere and cannot sign in until enabled again. Nothing is deleted.';

  @override
  String get adminUsernameHint => 'Optional, e.g. ustadh_ali';

  @override
  String get adminOneIdentifier =>
      'Give at least one of phone, email or username. They sign in with it.';

  @override
  String get adminRole => 'Role';

  @override
  String get adminPersonCreated => 'Account created';

  @override
  String get adminPersonCreatedBody =>
      'Give this temporary password to the person. They must choose their own password the first time they sign in.';

  @override
  String get adminCourseTeachers => 'Teachers of this course';

  @override
  String get adminAddTeacher => 'Add teacher';

  @override
  String get adminAddLearner => 'Add learner';

  @override
  String get adminNoTeachersYet =>
      'No teachers assigned yet. Administrators can always review learners.';

  @override
  String get adminRemove => 'Remove';

  @override
  String get adminEnrolActive => 'Active';

  @override
  String get adminEnrolSuspended => 'Suspended';

  @override
  String get adminEnrolWithdrawn => 'Withdrawn';

  @override
  String get adminEnrolPending => 'Pending';

  @override
  String get adminDeleteCourse => 'Delete course';

  @override
  String adminDeleteCourseBody(String title) {
    return 'Delete “$title” permanently? It has never been published and has no learners. This cannot be undone.';
  }

  @override
  String get navMore => 'More';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get moreBrowseCatalogue => 'Browse the catalogue';

  @override
  String get moreBrowseCatalogueHint =>
      'See published courses as learners see them';

  @override
  String get drawerAcademic => 'Academic';

  @override
  String get drawerTeaching => 'Teaching';

  @override
  String get drawerReview => 'Review learners';

  @override
  String get drawerPeople => 'People';

  @override
  String get drawerRoles => 'Roles & permissions';

  @override
  String get drawerOversight => 'Oversight';

  @override
  String get drawerActivity => 'Activity log';

  @override
  String get drawerAccount => 'My account';

  @override
  String get rolesNew => 'New role';

  @override
  String get rolesIntro =>
      'A role is a job in Sidra. Each person has one role; its permissions decide what they can see and do. Built-in roles can be adjusted; Super Admin always has everything.';

  @override
  String get rolesDeleteBody =>
      'Delete this role? It must not be assigned to anyone.';

  @override
  String get rolesSuperAdminLocked =>
      'Super Admin always has every permission and cannot be changed.';

  @override
  String get areaEnrolment => 'Enrolment';

  @override
  String get areaFinance => 'Finance';

  @override
  String get areaContent => 'Content';

  @override
  String get areaReports => 'Reports';

  @override
  String get areaSettings => 'Settings';

  @override
  String get auditEmpty => 'No activity recorded yet';

  @override
  String get auditSystem => 'System';

  @override
  String get auditCreated => 'created';

  @override
  String get auditRemoved => 'removed';

  @override
  String get auditChanged => 'changed';

  @override
  String get auditEnrolment => 'Enrolment';

  @override
  String get auditTeacherAssignment => 'Teacher assignment';

  @override
  String get auditAccount => 'Account';

  @override
  String get auditUnlock => 'Lesson unlock';

  @override
  String get auditReview => 'Review';

  @override
  String rolesSummary(int permissions, int members) {
    return '$permissions permissions · $members people';
  }

  @override
  String get statusInReview => 'In review';

  @override
  String get statusArchived => 'Archived';

  @override
  String get lifecycleTitle => 'Status';

  @override
  String lifecycleMoved(String status) {
    return 'Course is now: $status';
  }

  @override
  String get lifecycleSubmit => 'Submit for review';

  @override
  String get lifecycleSubmitNote => 'Note for the reviewer';

  @override
  String get lifecycleReturn => 'Return to draft';

  @override
  String get lifecycleReturnNote => 'What needs fixing';

  @override
  String get lifecycleArchive => 'Archive';

  @override
  String get lifecycleRestore => 'Restore to draft';

  @override
  String get lifecycleArchiveTitle => 'Archive this course?';

  @override
  String get lifecycleArchiveBody =>
      'It leaves the catalogue and learners can no longer open it. Nothing is deleted: enrolments, progress and payments are kept, and you can restore it later.';

  @override
  String lifecyclePublishedOn(String date) {
    return 'Visible to learners · published $date';
  }

  @override
  String get lifecycleArchivedHint =>
      'Archived. Learners cannot see it; its records are kept.';

  @override
  String get lifecycleInReviewHint =>
      'Waiting for a reviewer to publish it or send it back.';

  @override
  String get lifecycleReady => 'Ready to publish';

  @override
  String get lifecycleNotReady => 'Before publishing:';

  @override
  String get issueNoPublishedLessons => 'Publish at least one lesson';

  @override
  String get issueNoDescription => 'Add a course description';

  @override
  String get issueNoThumbnail => 'Add a cover image';

  @override
  String issueEmptyLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count published lessons have no content',
      one: '1 published lesson has no content',
    );
    return '$_temp0';
  }

  @override
  String issueDraftLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons are still drafts',
      one: '1 lesson is still a draft',
    );
    return '$_temp0';
  }

  @override
  String get issueNoTeacher =>
      'Assign a teacher: learners wait for a teacher to open each next lesson';

  @override
  String get coursesSearchHint => 'Search by title, subject, category or tag';

  @override
  String get coursesFilterCurrent => 'Current';

  @override
  String get coursesNoMatch => 'No courses match';

  @override
  String get courseCategory => 'Category';

  @override
  String get courseCategoryHint => 'e.g. Quran, Arabic, Fiqh';

  @override
  String get courseTags => 'Tags';

  @override
  String get courseTagsHint => 'Separate with commas, e.g. tajweed, beginners';

  @override
  String get courseSelfEnrol => 'Learners can enrol themselves';

  @override
  String get courseSelfEnrolHint =>
      'Turn off to enrol learners yourself, even though the course is free.';

  @override
  String get adminBlockLink => 'Link (YouTube, Telegram, website)';

  @override
  String get linkUrlLabel => 'Link address';

  @override
  String get linkUrlInvalid => 'Enter a full web link, e.g. https://youtu.be/…';

  @override
  String get linkTitleLabel => 'Title (optional)';

  @override
  String get linkDescriptionLabel => 'Short description (optional)';

  @override
  String get linkPreview => 'What learners will see';

  @override
  String get linkOpen => 'Opens outside Sidra';

  @override
  String get linkProviderYoutube => 'YouTube';

  @override
  String get linkProviderTelegram => 'Telegram';

  @override
  String get adminStatInReview => 'Courses in review';

  @override
  String get personTitle => 'Person';

  @override
  String get personActions => 'Actions';

  @override
  String personJoined(String date) {
    return 'Joined $date';
  }

  @override
  String personLastSignIn(String date) {
    return 'Last signed in $date';
  }

  @override
  String get personNeverSignedIn => 'Has not signed in yet';

  @override
  String get personTeaching => 'Teaching';

  @override
  String get personNoTeaching => 'Not assigned to any course yet';

  @override
  String personLearnerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count learners',
      one: '1 learner',
    );
    return '$_temp0';
  }

  @override
  String get personCourses => 'Courses';

  @override
  String get personNoCourses => 'Not enrolled in any course';

  @override
  String personLessonsDone(int done, int total) {
    return '$done of $total lessons done';
  }

  @override
  String personLastActive(String date) {
    return 'last active $date';
  }

  @override
  String get personReviews => 'Teacher reviews';

  @override
  String get personNoReviews => 'No reviews yet';

  @override
  String get personQuizzes => 'Quiz results';

  @override
  String get personQuizPending => 'Waiting for grading';

  @override
  String get personActivity => 'Recent activity';

  @override
  String get reviewPassed => 'Passed';

  @override
  String get reviewNeedsRevision => 'Needs more practice';

  @override
  String get sourceSelf => 'enrolled themselves';

  @override
  String get sourceStaff => 'added by staff';

  @override
  String get sourcePayment => 'paid';

  @override
  String get peopleActive => 'Active';

  @override
  String peopleShowing(int shown, int total) {
    return 'Showing $shown of $total';
  }

  @override
  String get peopleLoadMore => 'Load more';

  @override
  String get staffWholeCourse => 'Whole course';

  @override
  String staffTeachesUnits(String units) {
    return 'Teaches $units';
  }

  @override
  String get staffLimitUnits => 'Limit to units…';

  @override
  String staffLimitUnitsTitle(String name) {
    return 'Which units does $name teach?';
  }

  @override
  String get staffLimitUnitsHint =>
      'They review and unlock learners only in the ticked units. Tick none for the whole course.';

  @override
  String get navReview => 'Review';

  @override
  String get drawerLoadFailed =>
      'Could not load your menu. Check your connection and try again.';

  @override
  String get payCourseFee => 'Course fee';

  @override
  String payAlreadyCovered(String covered, String fee) {
    return '$covered of $fee already covered';
  }

  @override
  String get payWithMobileMoney => 'Pay with mobile money';

  @override
  String get payOtherWay => 'Paid another way? Tell us';

  @override
  String get payPhoneHint =>
      'We will send a payment request to this MTN or Airtel number. Keep the phone with you.';

  @override
  String get payPhoneLabel => 'Mobile money number';

  @override
  String get payPhoneInvalid =>
      'Enter an MTN or Airtel Uganda number, e.g. 0772 123456';

  @override
  String get payNow => 'Pay';

  @override
  String get payCheckPhoneTitle => 'Check your phone';

  @override
  String payCheckPhoneBody(String amount, String phone) {
    return 'Enter your mobile money PIN to pay $amount from $phone. This page updates by itself.';
  }

  @override
  String get payReceivedTitle => 'Payment received';

  @override
  String get payReceivedBody => 'Thank you. The course is now open.';

  @override
  String get payPendingTitle => 'Waiting for confirmation';

  @override
  String get payPendingBody =>
      'Our finance team will confirm your payment and open the course.';

  @override
  String get payNoAnswerTitle => 'No answer yet';

  @override
  String get payNoAnswerBody =>
      'If you entered your PIN, the course opens as soon as the payment is confirmed. Otherwise, try again.';

  @override
  String get payFailedTitle => 'Payment not completed';

  @override
  String get payFailedBody =>
      'The request was declined, cancelled or timed out. Nothing was taken. You can try again.';

  @override
  String get payMethodBank => 'Bank';

  @override
  String get payMethodMobileMoney => 'Mobile money';

  @override
  String payAmountLabel(String currency) {
    return 'Amount paid ($currency)';
  }

  @override
  String get payAmountInvalid => 'Enter the amount you paid';

  @override
  String get payReferenceLabel => 'Transaction ID or deposit slip number';

  @override
  String get payReferenceRequired => 'Enter the transaction ID or slip number';

  @override
  String get payNoteLabel => 'Note (optional)';

  @override
  String get paySubmitReport => 'Send for confirmation';

  @override
  String get paySubmitReportHint =>
      'The course opens once our finance team has checked the payment.';

  @override
  String get drawerFinance => 'Finance';

  @override
  String get drawerFinancePage => 'Payments & finance';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get financeOverview => 'Overview';

  @override
  String get financePayments => 'Payments';

  @override
  String get financeOwing => 'Owing';

  @override
  String get financeWaivers => 'Waivers';

  @override
  String get financeExpenses => 'Expenses';

  @override
  String get periodThisMonth => 'This month';

  @override
  String get periodLastMonth => 'Last month';

  @override
  String get periodThisYear => 'This year';

  @override
  String get periodAllTime => 'All time';

  @override
  String financePendingBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments waiting for verification',
      one: '1 payment waiting for verification',
    );
    return '$_temp0';
  }

  @override
  String get financeCollected => 'Collected';

  @override
  String get financeOutstanding => 'Outstanding';

  @override
  String get financeExpected => 'Expected';

  @override
  String get financeWaived => 'Waived';

  @override
  String get financeRefunded => 'Refunded';

  @override
  String get financeProviderFees => 'MarzPay fees';

  @override
  String get financeRetained => 'Retained';

  @override
  String get financeHowRetained => 'How “Retained” is worked out';

  @override
  String get financeFormula =>
      'Retained = Collected − Refunds − MarzPay fees − Expenses';

  @override
  String get financeWaiverNote =>
      'Waivers reduce what learners owe; they are never counted as money collected.';

  @override
  String get financeByMethod => 'Collected by method';

  @override
  String get financeByCourse => 'By course';

  @override
  String financeCourseLine(int learners, String collected, String outstanding) {
    String _temp0 = intl.Intl.pluralLogic(
      learners,
      locale: localeName,
      other: '$learners learners',
      one: '1 learner',
    );
    return '$_temp0 · collected $collected · owing $outstanding';
  }

  @override
  String get methodMarzPay => 'Mobile money (MarzPay)';

  @override
  String get methodCash => 'Cash';

  @override
  String get methodOther => 'Other';

  @override
  String get paymentInProgress => 'In progress';

  @override
  String get paymentPending => 'To verify';

  @override
  String get paymentVerified => 'Verified';

  @override
  String get paymentFailed => 'Failed';

  @override
  String get paymentRejected => 'Rejected';

  @override
  String get paymentReversed => 'Reversed';

  @override
  String get financeRecordPayment => 'Record payment';

  @override
  String get financeSearchPayments => 'Search name, phone or transaction ID';

  @override
  String get financeNoPayments => 'No payments here';

  @override
  String get financeLearner => 'Learner';

  @override
  String get financeCourse => 'Course';

  @override
  String get financeMethod => 'Method';

  @override
  String get financeRecordedBy => 'Recorded by';

  @override
  String get financeVerifiedBy => 'Checked by';

  @override
  String get financeCreated => 'Created';

  @override
  String get financeOpenLearner => 'Open learner record';

  @override
  String get financeVerify => 'Verify: money received';

  @override
  String get financeReject => 'Reject';

  @override
  String get financeRefund => 'Record a refund';

  @override
  String get financeReverse => 'Reverse (money not received)';

  @override
  String get reason => 'Reason';

  @override
  String get financeNobodyOwes => 'Nobody owes anything';

  @override
  String financeOwingLine(
    String course,
    String fee,
    String paid,
    String waived,
  ) {
    return '$course · fee $fee · paid $paid · waived $waived';
  }

  @override
  String get financeGrantWaiver => 'Grant waiver';

  @override
  String get financeNoWaivers => 'No waivers';

  @override
  String get financeFullFee => 'Whole fee';

  @override
  String get financeRevoke => 'Revoke waiver';

  @override
  String get financeRecordExpense => 'Record expense';

  @override
  String get financeNoExpenses => 'No expenses in this period';

  @override
  String get financeVoid => 'Void expense';

  @override
  String get financeChooseLearner => 'Choose learner';

  @override
  String get financeChooseCourse => 'Choose course';

  @override
  String get financeCourseChosen => 'Course chosen';

  @override
  String get financeNoPaidCourses => 'No paid courses yet';

  @override
  String get financeChooseBoth => 'Choose the learner and the course';

  @override
  String get financeCategory => 'Category';

  @override
  String get financeCategoryHint => 'e.g. Rent, Salaries, Transport';

  @override
  String get financePayee => 'Paid to (optional)';

  @override
  String get financeRecordHint =>
      'Recorded payments wait for a finance officer to verify them before they count.';

  @override
  String get settingsTitle => 'Organisation settings';

  @override
  String get settingsOrgName => 'Organisation name';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsSupportPhone => 'Support phone';

  @override
  String get settingsSupportEmail => 'Support email';

  @override
  String get settingsBank => 'How to pay by bank';

  @override
  String get settingsBankHint =>
      'Bank, account name and number. Learners see this.';

  @override
  String get settingsMobileMoney =>
      'How to pay by mobile money (outside the app)';

  @override
  String get settingsMarzPay => 'Mobile-money payments in the app (MarzPay)';

  @override
  String get settingsMarzPayHint =>
      'Learners pay with a PIN prompt on their phone.';

  @override
  String get enrolMany => 'Enrol several learners';

  @override
  String get enrolUntil => 'Access until (optional)';

  @override
  String get enrolNoEnd => 'No end date';

  @override
  String enrolSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enrol $count learners',
      one: 'Enrol 1 learner',
    );
    return '$_temp0';
  }

  @override
  String get fieldRequired => 'Required';

  @override
  String get adminUnitLabel => 'Unit';

  @override
  String get assignmentAccepts => 'Learners may hand in:';

  @override
  String get assignmentAdd => 'Add assignment';

  @override
  String get assignmentAudio => 'Recordings';

  @override
  String get assignmentDeleteBody =>
      'Delete this assignment? It cannot be deleted once learners have handed in work.';

  @override
  String get assignmentDocuments => 'Documents';

  @override
  String assignmentDue(String date) {
    return 'Due $date';
  }

  @override
  String get assignmentHint =>
      'Work learners do and hand in here: photos of written work, documents, recordings. Their teacher reviews it and replies.';

  @override
  String get assignmentInstructions => 'What to do';

  @override
  String get assignmentMaxScore => 'Maximum score (optional)';

  @override
  String get assignmentPhotos => 'Photos';

  @override
  String get assignmentText => 'Written answer';

  @override
  String get assignmentVideo => 'Videos';

  @override
  String get assignmentsTitle => 'Assignments';

  @override
  String get blockLanguage => 'Language of this content';

  @override
  String get blockLanguageHint =>
      'For example, Qur\'an text is Arabic even when the lesson is taught in English.';

  @override
  String get blockShowLearners => 'Show to learners';

  @override
  String get blockTeachersOnly => 'Teachers only';

  @override
  String get close => 'Close';

  @override
  String get courseAlsoTaughtIn => 'Also taught in';

  @override
  String courseForWhom(String who) {
    return 'Who it is for: $who';
  }

  @override
  String get courseHidden => 'Hide from the catalogue';

  @override
  String get courseHiddenHint => 'Only enrolled learners and staff see it.';

  @override
  String get courseLanguage => 'Main language of teaching';

  @override
  String get courseLanguageHint =>
      'The language explanations are given in. Arabic or Qur\'anic text inside lessons does not make Arabic the teaching language.';

  @override
  String get coursePrerequisites => 'Must finish first';

  @override
  String get coursePrerequisitesNone => 'No prerequisites';

  @override
  String get courseTargetLearner => 'Who it is for';

  @override
  String get courseTargetLearnerHint =>
      'e.g. Complete beginners who cannot yet read Arabic';

  @override
  String get courseTrack => 'Learning track';

  @override
  String get courseTrackHint =>
      'Reading, recitation, tajwīd, Qur\'anic Arabic… are different goals.';

  @override
  String get languageNotSet => 'Not set';

  @override
  String lessonCopied(String course) {
    return 'Copied to $course as a draft';
  }

  @override
  String get lessonCopy => 'Copy to another course…';

  @override
  String lessonCopyTo(String lesson) {
    return 'Copy \"$lesson\" to…';
  }

  @override
  String get lessonEditDetails => 'Edit details';

  @override
  String get lessonLanguage => 'Taught in';

  @override
  String lessonLanguageFromCourse(String languages) {
    return 'Same as the course: $languages';
  }

  @override
  String get lessonLanguageSameAsCourse => 'Same as the course';

  @override
  String get lessonLocation => 'Where this lesson is';

  @override
  String get lessonMove => 'Move…';

  @override
  String lessonMoveTo(String lesson) {
    return 'Move \"$lesson\" to…';
  }

  @override
  String get lessonMoveTop => 'Top of the course (no unit)';

  @override
  String lessonMoved(String place) {
    return 'Moved to $place';
  }

  @override
  String get lessonNoOutcomes =>
      'No learning outcomes yet. Add what the learner will be able to do.';

  @override
  String get lessonOutcomes => 'Learning outcomes';

  @override
  String get lessonOutcomesHint =>
      'One per line, e.g. \"Reads letters with fatḥah correctly\"';

  @override
  String get lessonOverview => 'Overview';

  @override
  String get lessonQuranReference => 'Qur\'an reference';

  @override
  String get lessonQuranReferenceOptional => 'Qur\'an reference (optional)';

  @override
  String get lessonYouWill => 'In this lesson you will';

  @override
  String get marzExplain =>
      'These tests run on the payments server, the only place that holds the MarzPay secret. No money moves: collections are tested with a request MarzPay must refuse. A real payment can only be proved by paying for a course and entering the PIN.';

  @override
  String marzLastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get marzNoAnswer =>
      'The payments server did not answer. Is it running?';

  @override
  String marzResultsFrom(String time) {
    return 'Results from $time';
  }

  @override
  String get marzRunTests => 'Test integration';

  @override
  String get marzRunning => 'Testing…';

  @override
  String get marzServerOffline =>
      'Payments server is not running: learners\' mobile-money payments wait until it is';

  @override
  String get marzServerOnline => 'Payments server is running';

  @override
  String get marzTitle => 'MarzPay (mobile money)';

  @override
  String get provisionalBody =>
      'Seeded as a starting point. A teacher or scholar should check it before learners use it.';

  @override
  String get provisionalTitle => 'Needs review';

  @override
  String get quranAyahFrom => 'From āyah';

  @override
  String get quranAyahTo => 'To āyah';

  @override
  String quranRef(String ref) {
    return 'Qur\'an $ref';
  }

  @override
  String get quranSurah => 'Sūrah no.';

  @override
  String get resourceAddLink => 'Add link';

  @override
  String get resourceCheckLink => 'Check link';

  @override
  String get resourceFile => 'File';

  @override
  String get resourceHide => 'Hide from learners';

  @override
  String get resourceLanguage => 'Language';

  @override
  String get resourceLocked => 'You do not have access to this file.';

  @override
  String get resourceLooksRight => 'Looks right: save';

  @override
  String get resourceNotVerified => 'not checked';

  @override
  String get resourceOpen => 'Open';

  @override
  String resourcePreviewUnavailable(String reason) {
    return 'No automatic preview ($reason). Check the address yourself before saving.';
  }

  @override
  String get resourceRemove => 'Remove';

  @override
  String resourceRemoveBody(String title) {
    return 'Remove \"$title\" from here? The file itself is kept.';
  }

  @override
  String get resourceSaveAnyway => 'I trust it: save';

  @override
  String get resourceShow => 'Show to learners';

  @override
  String get resourceSize => 'Size';

  @override
  String get resourceType => 'Type';

  @override
  String get resourceUpload => 'Upload file';

  @override
  String get resourceUploadNow => 'Upload';

  @override
  String resourceUploading(String name) {
    return 'Uploading $name';
  }

  @override
  String get resourceVerified => 'checked';

  @override
  String get resourcesNone => 'No files or links yet.';

  @override
  String get resourcesTitle => 'Resources';

  @override
  String get settingsPayments => 'Payments';

  @override
  String get subAttachFile => 'Attach file';

  @override
  String subAttempt(int n) {
    return 'attempt $n';
  }

  @override
  String get subFeedback => 'Feedback for the learner';

  @override
  String subFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
      zero: 'no files',
    );
    return '$_temp0';
  }

  @override
  String get subFromGallery => 'From gallery';

  @override
  String get subHandIn => 'Hand in';

  @override
  String get subHandedIn => 'Handed in. Your teacher has it.';

  @override
  String get subMarkReviewed => 'Mark reviewed';

  @override
  String get subMarkUnderReview => 'I\'m looking at it (under review)';

  @override
  String get subNoneToReview => 'Nothing here';

  @override
  String get subPrivacyNote =>
      'Only you and your teachers can see what you hand in.';

  @override
  String get subReceived => 'Received';

  @override
  String get subRequestResubmission => 'Ask for a new try';

  @override
  String get subResubmit => 'Please try again';

  @override
  String get subReturned => 'Returned';

  @override
  String get subReviewed => 'Reviewed';

  @override
  String get subSavedForLater =>
      'Saved on this phone. It will upload when you are online; tap Try again.';

  @override
  String get subScoreOptional => 'Score (optional)';

  @override
  String get subSubmitAgain => 'Hand in again';

  @override
  String get subSubmitWork => 'Submit work';

  @override
  String get subSubmitted => 'Handed in';

  @override
  String get subTakePhoto => 'Take photo';

  @override
  String get subTeacherHint => 'Work learners handed in to your lessons';

  @override
  String get subTitle => 'Submitted work';

  @override
  String get subUnderReview => 'Under review';

  @override
  String get subUploadFailed => 'Upload failed';

  @override
  String get subWaitingToUpload => 'Waiting to upload (not handed in yet)';

  @override
  String get subWorkTab => 'Work';

  @override
  String get subYourAnswer => 'Your answer';

  @override
  String subYourWork(String status, int attempt) {
    return 'Your work: $status (attempt $attempt)';
  }

  @override
  String taughtIn(String languages) {
    return 'Taught in $languages';
  }

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get uploadUploading => 'Uploading…';

  @override
  String get aboutTitle => 'About Sidra';

  @override
  String get aboutBody =>
      'Sidra is Almuntahha\'s learning app for the Qur\'an and the Islamic sciences. Teachers give each day\'s portion once, learners read, listen and record, and every learner still gets their teacher\'s personal correction.';

  @override
  String get aboutBy => 'Made for Almuntahha by Xhenvolt.';

  @override
  String get aboutLicences => 'Open-source licences';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String get aboutWhatsNew => 'What\'s new';

  @override
  String get analyticsTitle => 'Teaching insights';

  @override
  String analyticsDays(int days) {
    return '$days days';
  }

  @override
  String get anWaiting => 'Waiting';

  @override
  String get anWaitingQ => 'Work not yet reviewed';

  @override
  String get anTurnaround => 'Review time';

  @override
  String get anTurnaroundQ => 'Average time until first review';

  @override
  String get anFirstTry => 'Right first time';

  @override
  String get anFirstTryQ => 'First attempts marked correct';

  @override
  String get anSubmissions => 'Submissions';

  @override
  String get anSubmissionsQ => 'Recordings and work handed in';

  @override
  String get anIncomplete => 'Not finished';

  @override
  String get anIncompleteQ => 'Portions still open after 3 days';

  @override
  String get anTopCorrections => 'Most used corrections';

  @override
  String get anTopCategories => 'Most common mistakes';

  @override
  String get anRepeat => 'Learners trying many times';

  @override
  String get anByTeacher => 'Reviews by teacher';

  @override
  String get anNone => 'Nothing yet';

  @override
  String get attNew => 'New work';

  @override
  String get attResubmissions => 'Tried again';

  @override
  String get attCorrection => 'Waiting to try again';

  @override
  String get attNotSubmitted => 'Not sent yet';

  @override
  String get attBehind => 'Falling behind';

  @override
  String attOpenPortions(int count) {
    return '$count portions open';
  }

  @override
  String get attAllClear => 'Nothing needs you right now.';

  @override
  String get audioPlay => 'Play';

  @override
  String get audioPause => 'Pause';

  @override
  String get audioRecord => 'Record';

  @override
  String get audioRecording => 'Recording';

  @override
  String get audioPaused => 'Paused';

  @override
  String get audioPauseRecording => 'Pause';

  @override
  String get audioResume => 'Continue';

  @override
  String get audioStop => 'Stop';

  @override
  String get audioDiscard => 'Discard';

  @override
  String get audioRecordAgain => 'Record again';

  @override
  String audioYourRecording(String duration) {
    return 'Your recording ($duration)';
  }

  @override
  String get audioNeedsMicrophone =>
      'Sidra needs the microphone to record. Allow it in your phone\'s settings.';

  @override
  String get audioRecordFailed => 'Recording did not work. Please try again.';

  @override
  String get audioCannotPlay => 'This recording cannot be played.';

  @override
  String get audioLibraryTitle => 'Audio library';

  @override
  String get audioSearch => 'Search recordings';

  @override
  String get audioOnlyMine => 'Only mine';

  @override
  String get audioNone => 'No recordings yet';

  @override
  String get correctionLibrary => 'Correction library';

  @override
  String get correctionLibraryHint =>
      'Corrections saved while reviewing appear here, ready to reuse.';

  @override
  String get correctionAdd => 'New correction';

  @override
  String get correctionSearch => 'Search: ص, shaddah, madd…';

  @override
  String get correctionNone => 'No corrections found';

  @override
  String get correctionTitle => 'Title';

  @override
  String get correctionTitleHint => 'e.g. Difference between ص and س';

  @override
  String get correctionCategory => 'Mistake category';

  @override
  String get correctionExplanation => 'Short explanation (optional)';

  @override
  String correctionUsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'used $count times',
      one: 'used once',
      zero: 'not used yet',
    );
    return '$_temp0';
  }

  @override
  String get correctionArchive => 'Archive';

  @override
  String get correctionForYou => 'Correction for you';

  @override
  String get groupNew => 'New group';

  @override
  String get groupName => 'Group name';

  @override
  String groupLearners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count learners',
      one: '1 learner',
      zero: 'No learners',
    );
    return '$_temp0';
  }

  @override
  String get groupNoLearners => 'No learners are enrolled in this course yet.';

  @override
  String get groupMembers => 'Learners';

  @override
  String groupWaiting(int count) {
    return '$count waiting';
  }

  @override
  String get groupsNone => 'No groups yet. Create one for a class you teach.';

  @override
  String get myGroups => 'My groups';

  @override
  String get needsAttention => 'Needs my attention';

  @override
  String get navTeaching => 'Teaching';

  @override
  String get libraryTitle => 'Content library';

  @override
  String get librarySearch => 'Search files and links';

  @override
  String get libraryRenameTag => 'Rename or tag';

  @override
  String get libraryReplace => 'Replace with a new version';

  @override
  String get libraryReplaced =>
      'New version saved. Work already assigned keeps the old one.';

  @override
  String libraryUsedIn(int lessons, int portions) {
    return 'in $lessons lessons, $portions portions';
  }

  @override
  String get listenTeacher => 'Listen to your teacher';

  @override
  String get listenModel => 'Listen to the model reading';

  @override
  String get notSentYet =>
      'Saved on this phone. Your teacher has not received it yet.';

  @override
  String get noteAdd => 'Private note';

  @override
  String get notePrivate => 'Note (only teachers see it)';

  @override
  String get notePrivateHint => 'e.g. Still confusing ض and ظ';

  @override
  String notesAbout(String name) {
    return 'Notes about $name';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsNone => 'No notifications';

  @override
  String get notificationsMarkRead => 'Mark all read';

  @override
  String get partNew => 'New';

  @override
  String get partToDo => 'To do';

  @override
  String get partWaiting => 'Sent · waiting';

  @override
  String get partUnderReview => 'Teacher is listening';

  @override
  String get partTryAgain => 'Try again';

  @override
  String get partDone => 'Done';

  @override
  String get portionDefaultTitle => 'Page ';

  @override
  String get portionCreateToday => 'Create today\'s portion';

  @override
  String portionCreateNext(String title) {
    return 'Next after $title';
  }

  @override
  String get portionsTitle => 'Portions';

  @override
  String get portionEdit => 'Edit portion';

  @override
  String get portionTitle => 'Title';

  @override
  String get portionTitleHint => 'e.g. Page 12';

  @override
  String get portionTask => 'What learners should do';

  @override
  String get portionTaskHint =>
      'e.g. Read this page three times. Watch the shaddah.';

  @override
  String get portionExplainedIn => 'Instructions given in';

  @override
  String get portionLearnersSend => 'Learners send';

  @override
  String get portionPage => 'Page';

  @override
  String get portionAddPage => 'Add page (photo, image or PDF)';

  @override
  String get portionInstruction => 'Teacher instruction';

  @override
  String get portionRecordInstruction => 'Record instruction';

  @override
  String get portionModel => 'Model recitation';

  @override
  String get portionRecordModel => 'Record model';

  @override
  String get portionFromLibrary => 'From my audio';

  @override
  String get portionUseRecording => 'Use this recording';

  @override
  String get portionAssignGroup => 'Assign to the group';

  @override
  String get portionAssignChosen => 'Assign to chosen learners';

  @override
  String portionAssignCount(int count) {
    return 'Assign to $count';
  }

  @override
  String portionAssigned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count learners received it',
      one: '1 learner received it',
      zero: 'Everyone already had it',
    );
    return '$_temp0';
  }

  @override
  String get portionSaveDraft => 'Save as draft';

  @override
  String get portionNotAssigned => 'Not assigned to anyone yet';

  @override
  String get portionBoardHint => 'Tap a learner to listen and review.';

  @override
  String get recordHint => 'Read the page aloud and record yourself.';

  @override
  String get recordAgainBelow => 'Listen, then record again below.';

  @override
  String get resExcellent => 'Excellent';

  @override
  String get resCorrect => 'Correct';

  @override
  String get resMinor => 'Correct, small note';

  @override
  String get resCorrection => 'Correction required';

  @override
  String get resExplain => 'Needs explanation';

  @override
  String get reviewCorrectionTitle => 'Correction';

  @override
  String get reviewUseExisting => 'Existing correction';

  @override
  String get reviewRecordNew => 'Record new';

  @override
  String get reviewSaveToLibrary => 'Save to correction library';

  @override
  String get reviewSaveToLibraryHint =>
      'Reuse it for the next learner with this mistake.';

  @override
  String get reviewFeedbackOptional => 'Written feedback (optional)';

  @override
  String get reviewSent => 'Sent to the learner';

  @override
  String get sendToTeacher => 'Send to teacher';

  @override
  String get sentToTeacher => 'Sent. Your teacher has it.';

  @override
  String get sentWaiting => 'Sent: waiting for your teacher';

  @override
  String get sentWaitingBody => 'You will be told when your teacher replies.';

  @override
  String teacherSays(String text) {
    return 'Your teacher: $text';
  }

  @override
  String get theirRecording => 'Their recording';

  @override
  String get todayLearning => 'Today\'s learning';

  @override
  String get useThis => 'Use';

  @override
  String yourAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your $count attempts',
      one: 'Your attempt',
    );
    return '$_temp0';
  }

  @override
  String get yourTask => 'Your task';

  @override
  String get deleteLearner => 'Delete permanently';

  @override
  String get deleteLearnerHint =>
      'Erase this learner and everything about them';

  @override
  String deleteLearnerTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteLearnerBody =>
      'This erases their account, enrolments, progress, recordings, photos, teacher notes and notifications. It cannot be undone. If they have made payments, the payments are kept for the accounts under \"Removed learner\", with no name or contact details.';

  @override
  String deleteLearnerTypeName(String name) {
    return 'Type \"$name\" to confirm';
  }

  @override
  String get deleteReason => 'Reason (optional, kept in the activity log)';

  @override
  String get deleteLearnerConfirm => 'Delete permanently';

  @override
  String get deleteLearnerDone => 'Learner deleted.';

  @override
  String get deleteLearnerKept =>
      'Learner deleted. Their payments are kept for the accounts as \"Removed learner\".';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesHint =>
      'Mistake categories organise the correction library. Rename, reorder or add your own; deleting a category keeps its corrections.';

  @override
  String get categoryAdd => 'New category';

  @override
  String get categoryAddSub => 'Add sub-category';

  @override
  String get categoryRename => 'Rename';

  @override
  String get categoryName => 'Name';

  @override
  String get categoryDelete => 'Delete';

  @override
  String categoryDeleteBody(String name) {
    return 'Delete \"$name\" and its sub-categories? Corrections in it are kept, without a category.';
  }
}
