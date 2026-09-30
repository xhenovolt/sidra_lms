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
  String appTagline(String org) {
    return 'Islamic learning by $org';
  }

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
  String exploreEmptyBody(String org) {
    return 'Published courses from $org will be listed here.';
  }

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
  String onboard1Body(String org) {
    return 'Courses prepared by $org teachers — from Quran reading for beginners to Islamic theology — organised into clear units and lessons.';
  }

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
  String signInUnavailableBody(String org) {
    return 'This build of Sidra has not been connected to its sign-in service. Please install the latest version or contact $org.';
  }

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
  String accessRequiredTitle(String org) {
    return 'Enrolment by $org';
  }

  @override
  String accessRequiredBody(String org) {
    return 'This course is opened for learners by the $org team. Please contact your teacher or $org to join.';
  }

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
  String authForgotBody(String org) {
    return 'Ask your teacher or $org to reset it. You will get a temporary password and choose a new one when you sign in.';
  }

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
  String authPasswordRule(int n) {
    return 'At least $n characters';
  }

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
  String authErrorDisabled(String org) {
    return 'This account is disabled. Contact $org.';
  }

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
  String aboutBody(String org) {
    return 'Sidra is $org\'s learning app for the Qur\'an and the Islamic sciences. Teachers give each day\'s portion once, learners read, listen and record, and every learner still gets their teacher\'s personal correction.';
  }

  @override
  String aboutBy(String org) {
    return 'Made for $org by Xhenvolt.';
  }

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

  @override
  String get resourcesForSection => 'Resources for this section';

  @override
  String get resourcesForUnit => 'Resources for this unit';

  @override
  String get libraryUsageAccess => 'Where used & who can see';

  @override
  String get libraryWhoCanSee => 'Who can see it';

  @override
  String get libraryAccessLearners => 'Learners with access';

  @override
  String get libraryAccessLearnersHint =>
      'Only learners allowed into the lesson or course where it is used, and staff.';

  @override
  String get libraryAccessPublic => 'Anyone viewing the course page';

  @override
  String get libraryAccessPublicHint =>
      'Also signed-in people not enrolled yet, e.g. a brochure or sample page.';

  @override
  String get libraryUsedWhere => 'Where it is used';

  @override
  String get libraryAddTo => 'Add to…';

  @override
  String get libraryMoveHint =>
      'To move it, add it to the new place, then remove it from the old one. Daily portions keep the files they were given.';

  @override
  String get libraryNotUsed => 'Not used anywhere yet.';

  @override
  String get libraryAddToCourse => 'Add to which course?';

  @override
  String libraryAddWhere(String course) {
    return 'Where in $course?';
  }

  @override
  String get libraryCoursePage => 'Course page';

  @override
  String get librarySection => 'Section';

  @override
  String get personTeachesIn => 'Teaches in';

  @override
  String get personTeachesInNone => 'Not set. Tap to choose languages.';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get repLearners => 'Learners';

  @override
  String get repLearnersQ => 'Active accounts';

  @override
  String get repActive => 'Studying';

  @override
  String get repActiveQ => 'Learners who did something in this period';

  @override
  String get repNew => 'New';

  @override
  String get repNewQ => 'Learners who joined in this period';

  @override
  String get repCompletions => 'Finished';

  @override
  String get repCompletionsQ => 'Courses completed in this period';

  @override
  String get repCourses => 'Course completion';

  @override
  String get repCoursesQ => 'Are learners getting through each course?';

  @override
  String repCourseLine(
    int enrolled,
    int completed,
    int progress,
    int active,
    int stalled,
  ) {
    return '$enrolled enrolled · $completed finished · $progress% average progress · $active active · $stalled stalled';
  }

  @override
  String get repQuiet => 'Gone quiet';

  @override
  String repQuietQ(int days) {
    return 'Enrolled learners with no activity in $days days: who should we follow up?';
  }

  @override
  String get repNeverStarted => 'never started';

  @override
  String repLastSeen(String date) {
    return 'last active $date';
  }

  @override
  String get repTeachers => 'Teacher activity';

  @override
  String get repTeachersQ =>
      'Who is reviewing, how fast, and what is waiting on them?';

  @override
  String repTeacherReviews(int count) {
    return '$count reviews';
  }

  @override
  String repTeacherTurnaround(String hours) {
    return '$hours h to review';
  }

  @override
  String repTeacherWaiting(int count) {
    return '$count waiting';
  }

  @override
  String get avatarTitle => 'Profile photo';

  @override
  String get avatarChange => 'Change profile photo';

  @override
  String get avatarTakePhoto => 'Take a photo';

  @override
  String get avatarUpload => 'Upload from the phone';

  @override
  String get avatarChoose => 'Or choose an avatar';

  @override
  String get avatarRemove => 'Remove photo';

  @override
  String get avatarSaved => 'Profile photo updated';

  @override
  String get viewerDownloading => 'Downloading…';

  @override
  String get viewerOpenAgain => 'Open again';

  @override
  String get viewerNoApp =>
      'No app on this phone can open this kind of document. Install a document app (e.g. Microsoft Word, WPS Office) and try again.';

  @override
  String get capPhoto => 'Take photo';

  @override
  String get capVideo => 'Record video';

  @override
  String get capScan => 'Scan pages (PDF)';

  @override
  String get capAudio => 'Record audio';

  @override
  String get capGallery => 'From gallery';

  @override
  String get capFile => 'Choose file';

  @override
  String get capPaste => 'Paste text';

  @override
  String capFailed(String reason) {
    return 'Could not open: $reason';
  }

  @override
  String capSize(String size) {
    return 'Size: $size';
  }

  @override
  String capPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get capLarge =>
      'This is a large file. Uploading it uses a lot of mobile data; Wi-Fi is better.';

  @override
  String get capUse => 'Upload this';

  @override
  String get capAddContent => 'Add: take, record, scan or choose';

  @override
  String get capAddWork => 'Add photo, scan or file';

  @override
  String get capClipboardEmpty =>
      'There is no text to paste. Copy some text first.';

  @override
  String get capPasted => 'Text added. Tap it to edit.';

  @override
  String get layoutGrid => 'Show as grid';

  @override
  String get layoutList => 'Show as list';

  @override
  String get topCourses => 'Top courses';

  @override
  String topCoursesLearners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count learners',
      one: '1 learner',
    );
    return '$_temp0';
  }

  @override
  String get allCourses => 'All courses';

  @override
  String get previewAsLearner => 'Preview as learner';

  @override
  String get previewAsLearnerHint => 'See the app exactly as learners see it';

  @override
  String get previewBanner => 'You are previewing as a learner';

  @override
  String get previewExit => 'Exit';

  @override
  String get previewNoProgress =>
      'Preview: progress is recorded for learners only';

  @override
  String get rulesTitle => 'Lesson rules';

  @override
  String get rulesHint =>
      'How a learner moves from one lesson to the next. The database enforces this: learners cannot open locked lessons.';

  @override
  String get ruleApproval => 'After the teacher approves the work';

  @override
  String get ruleApprovalHint =>
      'The learner hands in work; the teacher marks it (word by word if wished). A score at or above the pass mark unlocks the next lesson.';

  @override
  String get ruleSubmission => 'After handing in work';

  @override
  String get ruleSubmissionHint =>
      'Handing in the lesson\'s work unlocks the next lesson; the teacher reviews it afterwards.';

  @override
  String get ruleTeacherHint => 'The teacher unlocks each next lesson by hand.';

  @override
  String get ruleSequentialHint =>
      'Finishing (reading) a lesson unlocks the next.';

  @override
  String get ruleOpenHint => 'All lessons are open in any order.';

  @override
  String rulePassMark(int percent) {
    return 'Pass mark: $percent%';
  }

  @override
  String get ruleMaxAttempts => 'Maximum attempts per lesson (optional)';

  @override
  String get ruleMaxAttemptsHint => 'Leave empty for unlimited tries.';

  @override
  String get courseNotifications => 'Notifications for this course';

  @override
  String get courseNotificationsHint =>
      'Switch off what this course should not send. Switches under Settings apply to every course.';

  @override
  String get notifyLessonWork => 'New work for teachers';

  @override
  String get notifyReviewed => 'Work approved (to learners)';

  @override
  String get notifyCorrection => 'Corrections (to learners)';

  @override
  String get notifyPortionAssigned => 'New daily portion (to learners)';

  @override
  String get notifySubmission => 'Portion recordings (to teachers)';

  @override
  String get notifyResubmission => 'Tried again (to teachers)';

  @override
  String get lessonWorkRequired => 'Needs handed-in work';

  @override
  String lessonWorkFollowsCourse(String answer) {
    return 'Follows the course rule ($answer)';
  }

  @override
  String get lessonWorkFollowCourse => 'Follow the course rule';

  @override
  String get lessonWorkYes => 'Yes, learners hand in work';

  @override
  String get lessonWorkNo => 'No work for this lesson';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get workSubmit => 'Submit work';

  @override
  String get workSubmitAgain => 'Submit again';

  @override
  String get workTitle => 'Your work';

  @override
  String get workHint =>
      'Record your reading, or add a photo, scan or file of your work, then send it to your teacher.';

  @override
  String get workAnswer => 'Written answer (optional)';

  @override
  String get workWaiting => 'Handed in: waiting for your teacher';

  @override
  String get workApproved => 'Approved. The next lesson is open.';

  @override
  String get workApprovedNoUnlock => 'Approved.';

  @override
  String get workTryAgain => 'Your teacher asks you to try again';

  @override
  String workScore(String score, int pass) {
    return 'Score: $score% (pass mark $pass%)';
  }

  @override
  String get workNeededToFinish => 'Hand in your work to finish this lesson';

  @override
  String get workQueueTitle => 'Lesson work';

  @override
  String get workQueueEmpty => 'No lesson work waiting';

  @override
  String get workMarkWords => 'Mark word by word';

  @override
  String get workMarkWordsHint =>
      'Tap a word: correct → weak → wrong. The score follows your marks; you can still adjust it.';

  @override
  String workScoreLabel(int score) {
    return 'Overall score: $score%';
  }

  @override
  String workWillPass(int pass) {
    return 'Passes (pass mark $pass%): the next lesson will open';
  }

  @override
  String workWillFail(int pass) {
    return 'Below the pass mark ($pass%): the learner will be asked to try again';
  }

  @override
  String get workApprove => 'Approve';

  @override
  String get workNeedsCorrection => 'Needs correction';

  @override
  String get workNoText =>
      'This lesson has no Qur\'anic text to mark word by word; give an overall score.';

  @override
  String get workLegend => 'correct · weak · wrong';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsHint =>
      'Switch off a kind of notification for every course. Courses can also switch them off one by one.';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get inboxEmpty => 'Nothing waiting for you';

  @override
  String inboxWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pieces of work waiting',
      one: '1 piece of work waiting',
    );
    return '$_temp0';
  }

  @override
  String get inboxAutoNext => 'Review next automatically';

  @override
  String get inboxAutoNextHint =>
      'After you finish one, the next opens so you can mark a whole class in one go.';

  @override
  String authErrorSignupClosed(String org) {
    return '$org is not taking new sign-ups right now. Ask them to add you.';
  }

  @override
  String get settingsOrgNameAr => 'Organisation name in Arabic';

  @override
  String get settingsSignupSecurity => 'Sign-up and security';

  @override
  String get settingsAllowSignup => 'Anyone can create an account';

  @override
  String get settingsAllowSignupHint =>
      'When off, only staff can add learners.';

  @override
  String get settingsMinPassword => 'Shortest password allowed (6–64)';

  @override
  String get settingsLockoutAttempts =>
      'Wrong passwords before an account is locked (3–20)';

  @override
  String get settingsLockoutMinutes => 'Minutes an account stays locked';

  @override
  String get settingsTeachingDefaults => 'Teaching defaults';

  @override
  String get settingsTeachingDefaultsHint =>
      'Used for new courses and for teachers\' attention lists.';

  @override
  String get settingsStaleDays => 'Days before unreviewed work needs attention';

  @override
  String get settingsFallingBehind =>
      'Portions behind before a learner is flagged';

  @override
  String get settingsDefaultRule => 'Lesson rule for new courses';

  @override
  String settingsDefaultPassMark(int n) {
    return 'Pass mark for new courses: $n%';
  }

  @override
  String get settingsAppUpdates => 'App updates';

  @override
  String get settingsAppUpdatesHint =>
      'When you publish a new version, phones with an older one are asked to update.';

  @override
  String get settingsLatestVersion => 'Newest version (e.g. 2.27.0)';

  @override
  String get settingsLatestBuild => 'Newest build number';

  @override
  String get settingsDownloadUrl => 'Download link (https://…)';

  @override
  String get settingsMinBuild => 'Oldest build still allowed';

  @override
  String get settingsMinBuildHint =>
      'Older phones must update before continuing. Leave empty to allow all.';

  @override
  String settingsThisBuild(String version, String build) {
    return 'This phone has version $version (build $build).';
  }

  @override
  String get settingsLanguagesTracks => 'Languages and learning tracks';

  @override
  String get settingsLanguagesTracksHint =>
      'What courses are taught in and grouped by';

  @override
  String get settingsExport => 'Export data';

  @override
  String get settingsExportHint =>
      'Learners, enrolments, payments and progress as spreadsheets';

  @override
  String get langTitle => 'Languages and tracks';

  @override
  String get langLanguages => 'Languages';

  @override
  String get langTracks => 'Learning tracks';

  @override
  String get langAdd => 'Add language';

  @override
  String get trackAdd => 'Add track';

  @override
  String get langCode => 'Code (e.g. fr)';

  @override
  String get langName => 'Name in English';

  @override
  String get langNative => 'Name in the language itself';

  @override
  String get langRtl => 'Written right to left';

  @override
  String get langActive => 'Available for courses';

  @override
  String get langHidden => 'Hidden';

  @override
  String get langCodeInvalid => 'Use 2–3 lowercase letters, like fr';

  @override
  String get trackKey => 'Short key (e.g. fiqh)';

  @override
  String get trackKeyInvalid =>
      'Lowercase letters, digits and _, starting with a letter';

  @override
  String get trackName => 'Name';

  @override
  String get trackDescription => 'Description';

  @override
  String get exportTitle => 'Export data';

  @override
  String get exportLearners => 'Learners';

  @override
  String get exportLearnersHint =>
      'Every learner with contacts and number of courses';

  @override
  String get exportEnrolments => 'Enrolments';

  @override
  String get exportEnrolmentsHint =>
      'Who is in which course and how far they are';

  @override
  String get exportPayments => 'Payments';

  @override
  String get exportPaymentsHint => 'Every payment and its status';

  @override
  String get exportProgress => 'Lesson progress';

  @override
  String get exportProgressHint => 'Each learner\'s progress lesson by lesson';

  @override
  String exportSaved(int count) {
    return 'Saved $count rows';
  }

  @override
  String get exportEmpty => 'Nothing to export yet';

  @override
  String get exportNote =>
      'Files open in Excel, Google Sheets or any spreadsheet app.';

  @override
  String get updateAvailableTitle => 'A new version is ready';

  @override
  String updateAvailableBody(String version) {
    return 'Sidra $version is available with the latest improvements.';
  }

  @override
  String get updateRequiredTitle => 'Please update Sidra';

  @override
  String get updateRequiredBody =>
      'This version is no longer supported. Download the new one to continue.';

  @override
  String get updateNow => 'Update';

  @override
  String get updateLater => 'Later';

  @override
  String get authErrorTryLater =>
      'Too many sign-in attempts right now. Please wait a minute and try again.';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String timeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String get presenceTitle => 'Who\'s online';

  @override
  String get presenceMenuHint => 'Signed-in phones, last seen and last used';

  @override
  String get presenceHint =>
      'Signed in, online and using the app are different: a phone can be signed in but offline, or online with nobody using it.';

  @override
  String get presenceSearch => 'Search by name';

  @override
  String presenceSignedIn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Signed in on $n phones',
      one: 'Signed in on 1 phone',
    );
    return '$_temp0';
  }

  @override
  String get presenceSignedOut => 'Signed out';

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceActiveNow => 'Using Sidra now';

  @override
  String presenceLastSeen(String when) {
    return 'Last seen $when';
  }

  @override
  String presenceLastActive(String when) {
    return 'Last used $when';
  }

  @override
  String get presenceNeverSeen => 'Not seen yet';

  @override
  String get devicesTitle => 'Devices and sign-ins';

  @override
  String get devicesMine => 'Your devices';

  @override
  String get devicesPersonHint =>
      'Phones, who is online, sign-in history; sign out a lost phone';

  @override
  String get devicesHint =>
      'Every phone that signed in to this account. Signing out a phone ends it at once; the password is needed to use it again.';

  @override
  String get devicesEmpty =>
      'No devices yet. Phones appear after they sign in with Sidra 2.28 or newer.';

  @override
  String get devicesEndAll => 'Sign out everywhere';

  @override
  String get devicesEndAllBody =>
      'Every phone signed in to this account is signed out at once. The password is needed to sign in again.';

  @override
  String devicesEndAllDone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Signed out $n phones',
      one: 'Signed out 1 phone',
      zero: 'No phone was signed in',
    );
    return '$_temp0';
  }

  @override
  String get deviceThis => 'This phone';

  @override
  String get deviceUnknown => 'Unknown phone';

  @override
  String deviceApp(String version, String build) {
    return 'Sidra $version (build $build)';
  }

  @override
  String deviceAndroid(String version, String sdk) {
    return 'Android $version (API $sdk)';
  }

  @override
  String deviceNetwork(String network) {
    return 'Network: $network';
  }

  @override
  String get deviceNotificationsOff => 'Notifications blocked';

  @override
  String get deviceMicOff => 'Microphone not allowed';

  @override
  String deviceLastSync(String when) {
    return 'Last synced $when';
  }

  @override
  String deviceFirstSeen(String when) {
    return 'First seen $when';
  }

  @override
  String get deviceRevoke => 'Sign out this phone';

  @override
  String get deviceRevokeTitle => 'Sign out this phone?';

  @override
  String get deviceRevokeBody =>
      'It stops working at once and needs the password to sign in again. Use this for a lost or stolen phone.';

  @override
  String get deviceRevokeReason => 'Reason (optional)';

  @override
  String deviceRevokedBy(String name, String when, String reason) {
    return 'Signed out by $name $when. $reason';
  }

  @override
  String get authHistoryTitle => 'Sign-in history';

  @override
  String get authEventSignIn => 'Signed in';

  @override
  String get authEventSignedUp => 'Created the account';

  @override
  String get authEventFailed => 'Wrong password';

  @override
  String get authEventLocked => 'Tried while locked';

  @override
  String get authEventDisabled => 'Tried while the account was disabled';

  @override
  String get authEventSignOut => 'Signed out';

  @override
  String get authEventRefreshRejected =>
      'An ended sign-in was used again (refused)';

  @override
  String get authEventDeviceRevoked => 'A phone was signed out';

  @override
  String get authEventSessionsEnded => 'Signed out everywhere';

  @override
  String get authEventPasswordChanged => 'Changed the password';

  @override
  String get issueReport => 'I have a problem with this work';

  @override
  String get issueReportHint =>
      'Tell your teacher what is stopping you. The deadline waits while your report is open.';

  @override
  String get issueDontUnderstand => 'I don\'t understand the work';

  @override
  String get issueClarification => 'I need clarification';

  @override
  String get issueMoreTime => 'I need more time';

  @override
  String get issueUnavailable => 'I am sick or unavailable';

  @override
  String get issueTechnical => 'Technical problem';

  @override
  String get issueCannotAccess => 'I can\'t open the material';

  @override
  String get issueCannotRecord => 'I can\'t record audio';

  @override
  String get issueCannotUpload => 'I can\'t upload';

  @override
  String get issueOther => 'Something else';

  @override
  String get issueMessage => 'Explain (optional)';

  @override
  String get issueAttach => 'Attach';

  @override
  String get issueAttachHint => 'Add a photo, recording or file if it helps';

  @override
  String get issueSend => 'Send to my teacher';

  @override
  String get issueSent => 'Sent. Your teacher will answer here.';

  @override
  String get issueSentTitle => 'Problem reported: waiting for your teacher';

  @override
  String get issueAnsweredTitle => 'Your teacher answered';

  @override
  String issueNewDue(String when) {
    return 'New due time: $when';
  }

  @override
  String get issuesTitle => 'Problem reports';

  @override
  String get issuesOpen => 'Open';

  @override
  String get issuesResolved => 'Resolved';

  @override
  String get issuesNone => 'No problem reports';

  @override
  String issuesWaiting(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n learners reported problems',
      one: '1 learner reported a problem',
    );
    return '$_temp0';
  }

  @override
  String get issueOpenAttachment => 'Open attachment';

  @override
  String get issueRespond => 'Answer';

  @override
  String get issueYourAnswer => 'Your answer';

  @override
  String get issueGiveMoreTime => 'Give more time (optional)';

  @override
  String get issueMarkResolved => 'Mark as resolved';

  @override
  String get issueSendAnswer => 'Send answer';

  @override
  String get lateWorkTitle => 'Late work';

  @override
  String get lateWorkHint =>
      'Created automatically by the learner policies in Settings. Handing in the work closes them.';

  @override
  String get lateWorkNone => 'Nobody is late';

  @override
  String lateWorkCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n late-work alerts',
      one: '1 late-work alert',
    );
    return '$_temp0';
  }

  @override
  String lateWorkHours(int n) {
    return '$n h late';
  }

  @override
  String get lateWorkReinstate => 'Reinstate';

  @override
  String get lateWorkRunNow => 'Check now';

  @override
  String get policyNotOpened => 'Hasn\'t opened the work';

  @override
  String get policyNotSubmitted => 'Opened, not handed in';

  @override
  String get policyOverdue => 'Overdue';

  @override
  String get policyEscalated => 'Escalated to administrators';

  @override
  String get policySuspended => 'Suspended from the course';

  @override
  String get policyInactive => 'Not using Sidra';

  @override
  String get policyReinstated => 'Reinstated';

  @override
  String get policyTitle => 'Learner policies';

  @override
  String get policyHint =>
      'Reminders and late-work rules. Times count from the due time; a problem report pauses them and a teacher\'s extension moves them.';

  @override
  String get policyEnabled => 'Send reminders and late-work alerts';

  @override
  String get policyWarnHours => 'Remind the learner after (hours late)';

  @override
  String get policyWarnHoursHint =>
      'Tells them whether they haven\'t opened the work or haven\'t handed it in.';

  @override
  String get policyOverdueHours => 'Tell the teacher after (hours late)';

  @override
  String get policyEscalateDays => 'Tell administrators after (days late)';

  @override
  String get policyGraceHours => 'Grace period (hours)';

  @override
  String get policyReminderHours => 'Repeat reminders every (hours)';

  @override
  String get policyCountWeekends => 'Weekends count';

  @override
  String get policyCountWeekendsHint =>
      'When off, Saturdays and Sundays don\'t count. Holidays never count.';

  @override
  String get policyInactiveDays => 'Inactive after (days without using Sidra)';

  @override
  String get policyInactiveDaysHint =>
      'Separate from late work: the learner gets a gentle reminder.';

  @override
  String get policyAutoSuspend => 'Suspend automatically';

  @override
  String get policyAutoSuspendHint =>
      'Off by default. Only after a warning at least a day earlier, never with an open problem report or extension, and only if the learner has used Sidra since the work was given. Work and progress are kept.';

  @override
  String get policySuspendDays => 'Suspend after (days late)';

  @override
  String get policyPaymentDays =>
      'Keep checking unanswered mobile-money payments for (days)';

  @override
  String get policyPaymentDaysHint =>
      'After this, a payment MarzPay never answered counts as failed.';

  @override
  String get policyRunning => 'Policies are running.';

  @override
  String policyPausedUntil(String when) {
    return 'Paused until $when';
  }

  @override
  String policyLastRun(String when) {
    return 'Last checked $when';
  }

  @override
  String get policyResume => 'Resume now';

  @override
  String policyPauseDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Pause for $n days',
      one: 'Pause for a day',
    );
    return '$_temp0';
  }

  @override
  String get holidaysTitle => 'Holidays';

  @override
  String get holidaysHint => 'Days that don\'t count towards deadlines';

  @override
  String get holidaysAdd => 'Add a holiday';

  @override
  String get holidaysName => 'Name (e.g. Eid al-Fitr)';

  @override
  String get holidaysNone => 'No holidays added';

  @override
  String get transferChannel => 'Uploads and downloads';

  @override
  String get transferChannelHint => 'Progress of your uploads and downloads';

  @override
  String get uploadingWork => 'Uploading your work';

  @override
  String get uploadDoneTitle => 'Work sent';

  @override
  String get uploadDoneBody => 'Your teacher has received it.';

  @override
  String get uploadWaitingTitle => 'Work saved: waiting for internet';

  @override
  String get uploadWaitingBody => 'It will be sent when you\'re back online.';

  @override
  String get uploadFailedTitle => 'Upload failed';

  @override
  String get uploadFailedBody =>
      'Your work is kept on the phone. Open Sidra to try again.';

  @override
  String uploadFileMissing(String name) {
    return '$name is no longer on this phone. Remove it and add it again.';
  }

  @override
  String get chatsTitle => 'Messages';

  @override
  String get chatsEmpty => 'No conversations yet';

  @override
  String get chatsEmptyHint =>
      'Start a chat with a colleague, or create a group for your team.';

  @override
  String get chatNew => 'New chat';

  @override
  String get chatNewGroup => 'New group';

  @override
  String get chatGroupName => 'Group name';

  @override
  String get chatGroupNameNeeded => 'Give the group a name';

  @override
  String get chatCreateGroup => 'Create group';

  @override
  String get chatAddPeople => 'Add people';

  @override
  String chatMembers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get chatGroupAdmin => 'Group admin';

  @override
  String get chatRemove => 'Remove';

  @override
  String get chatLeave => 'Leave group';

  @override
  String get chatMute => 'Mute notifications';

  @override
  String get chatMessageHint => 'Message';

  @override
  String get chatSend => 'Send';

  @override
  String get chatAttach => 'Attach';

  @override
  String get chatAttachment => 'Attachment';

  @override
  String get chatPhoto => 'Photo';

  @override
  String get chatVideo => 'Video';

  @override
  String get chatAudio => 'Audio';

  @override
  String get chatFile => 'File';

  @override
  String get chatVoiceNote => 'Voice note';

  @override
  String get chatRecording => 'Recording';

  @override
  String get chatMicNeeded =>
      'Allow the microphone for Sidra to send voice notes.';

  @override
  String get chatReply => 'Reply';

  @override
  String get chatCopy => 'Copy';

  @override
  String get chatDeleteForAll => 'Delete for everyone';

  @override
  String get chatDeleted => 'This message was deleted';

  @override
  String get chatNotSent => 'Not sent. Tap to retry';

  @override
  String get chatToday => 'Today';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get photoEditTitle => 'Adjust photo';

  @override
  String get photoEditHint =>
      'Pinch to zoom and drag to place your face in the circle.';

  @override
  String get photoRotate => 'Rotate';

  @override
  String get photoReset => 'Reset';

  @override
  String get photoUse => 'Use photo';

  @override
  String get photoView => 'View photo';

  @override
  String dashSignedInAs(String name, String role) {
    return 'Signed in as $name · $role';
  }

  @override
  String dashOrgTitle(String org) {
    return '$org at a glance';
  }

  @override
  String get dashOrgHint =>
      'Numbers for the whole organisation, not for you. Tap any number to see exactly who or what it counts.';

  @override
  String get dashThisWeek => 'This week';

  @override
  String get dashPeople => 'People';

  @override
  String get dashCourses => 'Courses';

  @override
  String get dashLearnersInCourses => 'Learners in courses';

  @override
  String get dashCoursePlaces => 'Course places (a learner in 3 courses = 3)';

  @override
  String get dashListEmpty => 'Nothing here';

  @override
  String dashListCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n in this list',
      one: '1 in this list',
    );
    return '$_temp0';
  }

  @override
  String get dashLearnersGlance => 'Learners at a glance';

  @override
  String dashSeeAll(int n) {
    return 'See all $n';
  }

  @override
  String get dashGlanceUnavailable => 'You can\'t see learners with your role.';

  @override
  String get dashNoCourses => 'Not in any course';

  @override
  String get dashNeverUsed => 'Hasn\'t used Sidra yet';

  @override
  String dashLastUsed(String when) {
    return 'Last used Sidra $when';
  }

  @override
  String dashLateWork(int n) {
    return '$n late';
  }

  @override
  String dashOpenReports(int n) {
    return '$n problem reported';
  }

  @override
  String get ccGeneral => 'General';

  @override
  String get ccGeneralHint =>
      'Organisation name, time zone, contacts and messaging.';

  @override
  String get ccAccess => 'Users and access';

  @override
  String get ccAccessHint =>
      'Who may sign up, password rules, lock-out and sign-in protection.';

  @override
  String get ccTeaching => 'Teaching';

  @override
  String get ccSecurity => 'Devices and security';

  @override
  String get ccSecurityHint =>
      'Phones signed in, sessions, failed sign-ins and sign-outs.';

  @override
  String get ccPaymentsHint =>
      'Payment methods, instructions for manual payment, and tracing a payment.';

  @override
  String get ccMarzpayHint =>
      'Mobile money through MarzPay: its real status, test centre and safety limits.';

  @override
  String get ccStorage => 'Storage and media';

  @override
  String get ccStorageHint =>
      'Where files are kept (Cloudinary), upload limit and storage checks.';

  @override
  String get ccDatabase => 'Database';

  @override
  String get ccDatabaseHint =>
      'Connection and schema version. Changes to the structure are made by the release process, not here.';

  @override
  String get ccSync => 'Offline and sync';

  @override
  String get ccSyncHint => 'Work saved on this phone and waiting to be sent.';

  @override
  String get ccAudit => 'Audit and history';

  @override
  String get ccAuditHint =>
      'Who changed which setting, when and why; data export.';

  @override
  String get ccApplication => 'Application';

  @override
  String get ccAdvanced => 'Diagnostics';

  @override
  String get ccAdvancedHint =>
      'Run checks when something breaks, with a history of results.';

  @override
  String get ccTimeZone => 'Time zone (e.g. Africa/Kampala)';

  @override
  String get ccTimeZoneHint => 'Used for deadlines, weekends and holidays.';

  @override
  String get ccMessagingOn => 'Messaging for staff';

  @override
  String get ccMessagingLearners => 'Learners can use messaging too';

  @override
  String get ccSigninBrake => 'System-wide brake: failed sign-ins per minute';

  @override
  String get ccSigninBrakeHint =>
      'Above this, sign-in answers \"try later\" for a minute (stops someone guessing many accounts).';

  @override
  String get ccPresenceMinutes => '\"Online\" means seen within (minutes)';

  @override
  String get ccAuthKeepDays => 'Keep sign-in history for (days)';

  @override
  String get ccDefaultPassMark => 'Pass mark for new courses (%)';

  @override
  String get ccMarzTestsOn => 'MarzPay tests allowed (emergency stop)';

  @override
  String get ccMarzTestsOnHint =>
      'Off stops every test at once, including ones waiting to run.';

  @override
  String get ccMarzTestMax => 'Largest test amount (UGX)';

  @override
  String get ccMarzDisbursementOn => 'Allow sending-money tests';

  @override
  String get ccMarzDisbursementOnHint =>
      'Money leaves the MarzPay wallet. Off by default.';

  @override
  String get ccUploadMax => 'Largest upload (MB)';

  @override
  String get ccUploadMaxHint =>
      'Phones refuse bigger files before sending. Cloudinary\'s own plan limit also applies.';

  @override
  String get ccSendTestNotification => 'Send me a test notification';

  @override
  String get ccPaymentTrace => 'Trace a payment';

  @override
  String get ccMarzCenter => 'MarzPay test centre';

  @override
  String get ccDiagnostics => 'Diagnostics';

  @override
  String get ccSettingsHistory => 'Settings history';

  @override
  String get ccSecurityEvents => 'Security events';

  @override
  String get ccOk => 'OK';

  @override
  String get ccWarning => 'Attention';

  @override
  String get ccFailed => 'Failed';

  @override
  String get ccUntested => 'Untested';

  @override
  String get ccDisabled => 'Off';

  @override
  String get ccSearchHint =>
      'Search settings: password, payment, notification…';

  @override
  String get ccHealthTitle => 'Is Sidra healthy right now?';

  @override
  String get ccHealthHint => 'Live status of each part. Tap one for details.';

  @override
  String get ccHealthNoPermission => 'Your role can\'t see system health.';

  @override
  String get ccSections => 'Sections';

  @override
  String get ccMarzDisabled => 'Switched off by an administrator';

  @override
  String get ccMarzConnFailed => 'The last connection test failed';

  @override
  String get ccMarzServerDown =>
      'Payments server offline: payments can\'t be sent';

  @override
  String get ccMarzVerified =>
      'Verified: money has been collected through Sidra';

  @override
  String get ccMarzAuthOnly =>
      'Connected and authenticated; a real collection not yet proven';

  @override
  String get ccMarzUntested => 'Not tested yet';

  @override
  String ccDbLine(String have, String expected) {
    return 'Schema $have (this app expects $expected)';
  }

  @override
  String get ccPaymentsServer => 'Payments server';

  @override
  String ccServerOnline(Object version) {
    return 'Online (version $version)';
  }

  @override
  String get ccServerNever => 'Never seen: it isn\'t running anywhere';

  @override
  String ccServerLastSeen(String when) {
    return 'Offline, last seen $when';
  }

  @override
  String ccStorageLine(Object n, String when) {
    return '$n uploads today; last $when';
  }

  @override
  String get ccStorageMissing =>
      'Cloudinary keys are missing: uploads will fail';

  @override
  String ccNotifLine(Object sent, Object phones, Object blocked) {
    return '$sent sent today · $phones phones registered · $blocked phones block notifications';
  }

  @override
  String ccSecurityLine(Object failed, Object locked, Object many) {
    return '$failed failed sign-ins today · $locked locked · $many accounts on many phones';
  }

  @override
  String get ccLearning => 'Learning';

  @override
  String ccLearningLine(
    Object active,
    Object reports,
    Object late,
    Object review,
  ) {
    return '$active active this week · $reports problem reports · $late late · $review waiting review 2+ days';
  }

  @override
  String ccPaymentsLine(Object manual, Object stuck) {
    return '$manual manual payments to verify · $stuck mobile-money payments stuck';
  }

  @override
  String ccAppLine(String version, String build, Object latest) {
    return 'This phone $version ($build) · newest build $latest';
  }

  @override
  String ccDiagLine(Object n) {
    return '$n failed checks in the last day';
  }

  @override
  String ccCheckedAt(String when) {
    return 'Checked $when';
  }

  @override
  String ccSaved(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n settings saved',
      one: '1 setting saved',
    );
    return '$_temp0';
  }

  @override
  String ccSavedSome(int ok, int failed) {
    return '$ok saved, $failed refused: see the red messages';
  }

  @override
  String get ccReason => 'Reason for the change (recorded)';

  @override
  String ccSaveChanges(int n) {
    return 'Save $n';
  }

  @override
  String ccRange(int min, int max) {
    return 'Between $min and $max.';
  }

  @override
  String ccLastChanged(String name, String when) {
    return 'Last changed by $name, $when';
  }

  @override
  String get ccSystem => 'the system';

  @override
  String get ccYes => 'Yes';

  @override
  String get ccNo => 'No';

  @override
  String get ccDbConnected => 'Connected';

  @override
  String get ccDbLatest => 'Newest applied change';

  @override
  String get ccDbAppExpects => 'This app expects';

  @override
  String get ccDbCount => 'Changes applied';

  @override
  String get ccDbBackups => 'Backups';

  @override
  String get ccDbBackupsHint =>
      'Kept by Neon (see its console; paid plans restore to any moment)';

  @override
  String get ccStorageProvider => 'Provider';

  @override
  String get ccConfigured => 'Configured';

  @override
  String get ccLastUpload => 'Last upload';

  @override
  String get ccUploads24h => 'Uploads today';

  @override
  String get ccPurgeWaiting => 'Files waiting to be deleted';

  @override
  String get ccPublicAddress => 'Public address for callbacks';

  @override
  String get ccNoPollingOnly => 'No (payments are checked every 20 s)';

  @override
  String get ccVerifiedPayments => 'Verified mobile-money payments';

  @override
  String get ccStuckPayments => 'Stuck over an hour';

  @override
  String get ccThisPhone => 'This phone';

  @override
  String get ccBuildsInUse => 'Builds in use (build: phones)';

  @override
  String get ccFailedSignIns => 'Failed sign-ins (24 h)';

  @override
  String get ccThrottled => 'Brake applied (24 h)';

  @override
  String get ccLockedNow => 'Accounts locked now';

  @override
  String get ccRevoked7d => 'Phones signed out by admins (7 days)';

  @override
  String get ccManyDevices => 'Accounts signed in on more than 3 phones';

  @override
  String get ccSyncThisPhone => 'On this phone';

  @override
  String ccSyncLine(int pending, int rejected, int queued) {
    return '$pending progress changes waiting · $rejected refused · $queued submissions queued';
  }

  @override
  String get ccSyncNow => 'Send now';

  @override
  String get ccHistoryHint =>
      'Every change to a setting: old value, new value, who, when and why. Tap one to see only that setting.';

  @override
  String get ccNoSecurityEvents => 'No security events';

  @override
  String get ccUnknownAccount => 'unknown number (no account)';

  @override
  String get ccTraceHint =>
      'Search by learner name or phone, Sidra payment id, MarzPay id or reference. Each result follows the payment from request to MarzPay to Sidra\'s record.';

  @override
  String get ccTraceSearch => 'Name, phone, id or reference';

  @override
  String get ccTraceNone => 'No payment matches';

  @override
  String get ccTraceStep1 => '1 · The request in Sidra';

  @override
  String get ccTraceStep2 => '2 · At MarzPay';

  @override
  String get ccTraceStep3 => '3 · Callbacks received';

  @override
  String get ccTraceStep4 => '4 · Sidra\'s record and access';

  @override
  String get ccTraceMethod => 'Method';

  @override
  String get ccTraceCreated => 'Created';

  @override
  String get ccTraceSidraId => 'Sidra id';

  @override
  String get ccTraceReference => 'Reference';

  @override
  String get ccTraceProviderId => 'MarzPay id';

  @override
  String get ccTraceProviderStatus => 'MarzPay\'s last answer';

  @override
  String get ccTraceAttempts => 'Send attempts';

  @override
  String get ccTraceCallbacks => 'Callbacks';

  @override
  String get ccTraceNoCallbacks => 'None (checked by polling)';

  @override
  String get ccTraceSidraStatus => 'Sidra status';

  @override
  String get ccTraceVerifiedAt => 'Verified';

  @override
  String get ccTraceBalance => 'Still owed';

  @override
  String get ccTraceOutstanding => 'outstanding';

  @override
  String get ccTraceEnrolment => 'Course access';

  @override
  String get ccTraceHistory => 'Changes';

  @override
  String get ccTraceAskMarzPay => 'Ask MarzPay now';

  @override
  String get ccDiagnosticsHint =>
      'Each check says what it tested, what should happen, what happened and what to do next. Results are kept.';

  @override
  String get ccRunAll => 'Run all checks';

  @override
  String get ccRunCheck => 'Run the check';

  @override
  String get ccTested => 'Tested';

  @override
  String get ccExpected => 'Expected';

  @override
  String get ccHappened => 'Happened';

  @override
  String get ccNextAction => 'Next';

  @override
  String get ccDiagHistory => 'Earlier results';

  @override
  String get ccSafetySettings => 'Safety settings';

  @override
  String get diagDbTested => 'A round trip to the database from this phone';

  @override
  String get diagDbExpected => 'An answer within a few seconds';

  @override
  String diagDbHappened(int ms) {
    return 'Answered in $ms ms';
  }

  @override
  String get diagSession => 'Sign-in session';

  @override
  String get diagSessionTested => 'Renewing this phone\'s session';

  @override
  String get diagSessionExpected => 'A fresh session';

  @override
  String get diagSessionOk => 'Session renewed';

  @override
  String get diagSessionNone => 'No session: this phone is signed out';

  @override
  String get diagDevice => 'This phone';

  @override
  String get diagDeviceTested => 'Registration, permissions and app version';

  @override
  String get diagDeviceExpected =>
      'Registered, with notifications and microphone allowed';

  @override
  String diagDeviceLinked(String model, String version) {
    return 'Registered as $model, Sidra $version';
  }

  @override
  String get diagDeviceNotLinked =>
      'Not linked to this session yet (sign out and in once)';

  @override
  String get diagStorageTested =>
      'Uploading a tiny file to Cloudinary, then downloading it';

  @override
  String get diagStorageExpected => 'The same content comes back';

  @override
  String get diagStorageOk => 'Uploaded, signed and downloaded intact';

  @override
  String get diagStorageMismatch =>
      'The downloaded file differs from what was uploaded';

  @override
  String get diagNotifTested => 'Creating a notification for you';

  @override
  String get diagNotifExpected =>
      'It appears in the app and on the notification bar';

  @override
  String get diagNotifSent => 'Created';

  @override
  String get diagNotifNext =>
      'It should appear on the notification bar within a minute while Sidra is open (15 minutes when closed). If not, check this phone\'s notification permission.';

  @override
  String get diagSyncTested => 'Work waiting on this phone';

  @override
  String get diagSyncExpected => 'Nothing stuck';

  @override
  String get diagServerTested => 'The payments server\'s heartbeat';

  @override
  String get diagServerExpected => 'Seen in the last 90 seconds';

  @override
  String get diagMarzTested => 'MarzPay\'s status from the latest tests';

  @override
  String get diagMarzExpected => 'Connected, and a real collection proven';

  @override
  String get diagAppTested => 'This app\'s build against the newest published';

  @override
  String get diagAppExpected => 'The newest build';

  @override
  String diagAppCurrent(String version, String build) {
    return 'Up to date: $version ($build)';
  }

  @override
  String diagAppOld(String build, int latest) {
    return 'Build $build, newest is $latest';
  }

  @override
  String get diagNextCheckNetwork =>
      'Check this phone\'s internet, then run again.';

  @override
  String get diagNextSignIn => 'Sign in again.';

  @override
  String get diagNextPermissions =>
      'Allow them in the phone\'s settings → Apps → Sidra.';

  @override
  String get diagNextStorage =>
      'Check Cloudinary\'s status and plan limits; ask the developer if it continues.';

  @override
  String get diagNextSync =>
      'Open Offline and sync and retry the failed items.';

  @override
  String get diagNextServer =>
      'Start the payments server on its host (see docs/OPERATIONS.md). Until then, mobile-money payments wait.';

  @override
  String get diagNextMarz =>
      'Open the MarzPay test centre and run the connection test.';

  @override
  String get diagNextUpdate => 'Install the newest APK.';

  @override
  String get mcConnection => 'Connection';

  @override
  String get mcConnectionHint =>
      'Network, TLS, credentials, account, environment, latency.';

  @override
  String get mcCapabilities => 'What MarzPay offers this account';

  @override
  String get mcCapabilitiesHint =>
      'Reads the collection and disbursement services, balance access and webhooks.';

  @override
  String get mcBalance => 'Balance';

  @override
  String get mcBalanceHint => 'The MarzPay wallet balance.';

  @override
  String get mcCollection => 'Collection (receive money)';

  @override
  String get mcCollectionHint =>
      'A real prompt on a phone; proven from MarzPay\'s own ledger.';

  @override
  String get mcDisbursement => 'Disbursement (send money)';

  @override
  String get mcDisbursementHint =>
      'Money leaves the wallet to a phone. Off until switched on.';

  @override
  String get mcLookup => 'Transaction lookup';

  @override
  String get mcLookupHint =>
      'Compare Sidra\'s record with MarzPay\'s for one payment.';

  @override
  String get mcLookupField => 'Sidra id, MarzPay id or reference';

  @override
  String get mcCallbacks => 'Callbacks';

  @override
  String get mcCallbacksHint =>
      'Can MarzPay notify Sidra? Lists what was received.';

  @override
  String get mcReconciliation => 'Reconciliation';

  @override
  String get mcReconciliationHint =>
      'Every Sidra mobile-money payment (30 days) against MarzPay\'s ledger.';

  @override
  String get mcAuthentication => 'Authentication';

  @override
  String get mcCollectionMm => 'Mobile money collection (MTN, Airtel)';

  @override
  String get mcCard => 'Card payments';

  @override
  String get mcDisbursementMm => 'Mobile money disbursement';

  @override
  String get mcBank => 'Bank transfer';

  @override
  String get mcWallet => 'Account-to-account (wallet transfer)';

  @override
  String get mcRefund => 'Refund / reversal';

  @override
  String get mcMatrix => 'Capabilities';

  @override
  String get mcMatrixHint =>
      'Provider: offered by MarzPay for this account. Sidra: built in Sidra. The badge shows the latest evidence.';

  @override
  String get mcProvider => 'MarzPay';

  @override
  String get mcSidra => 'Sidra';

  @override
  String get mcUnsupportedByProvider => 'Not offered by MarzPay';

  @override
  String get mcRunCapabilities => 'Run the capabilities test';

  @override
  String get mcSidraMissing => 'MarzPay offers it; Sidra doesn\'t use it yet';

  @override
  String get mcImplementedUntested => 'Built, not tested yet';

  @override
  String get mcImplementedBlocked => 'Built; verification blocked';

  @override
  String get mcVerified => 'Verified';

  @override
  String get mcAccepted => 'Accepted, not proven';

  @override
  String get mcFailedR => 'Failed';

  @override
  String get mcCancelled => 'Cancelled';

  @override
  String get mcPending => 'Pending';

  @override
  String get mcUnknown => 'Unknown';

  @override
  String get mcBlocked => 'Blocked';

  @override
  String get mcUnsupported => 'Unsupported';

  @override
  String get mcRunning => 'Running…';

  @override
  String get mcRealMoney => 'REAL MONEY';

  @override
  String get mcLast => 'Last';

  @override
  String get mcIntro =>
      'Tests run on the payments server (the only place with MarzPay\'s keys). Each ends with proof or an honest reason why not. Opening this page never starts a test.';

  @override
  String get mcWhatTesting => 'What are you testing?';

  @override
  String get mcTestTab => 'Test';

  @override
  String get mcHistoryTab => 'History';

  @override
  String get mcCallbacksList =>
      'Every call MarzPay made to Sidra, and what Sidra did with it.';

  @override
  String get mcNoCallbacks => 'No callbacks received yet';

  @override
  String get mcDuplicate => 'duplicate';

  @override
  String get mcNoTests => 'No tests yet';

  @override
  String get mcRunTest => 'Run test';

  @override
  String get mcFormInvalid =>
      'Enter an MTN or Airtel Uganda number and an amount.';

  @override
  String get mcRealTitle => 'This moves real money';

  @override
  String mcRealCollect(int amount, String phone) {
    return '$amount UGX will be requested from $phone. The phone owner must enter their PIN. The money goes into the MarzPay wallet.';
  }

  @override
  String mcRealSend(int amount, String phone) {
    return '$amount UGX will be sent from the MarzPay wallet to $phone. This can\'t be undone by Sidra.';
  }

  @override
  String get mcContinue => 'Continue';

  @override
  String get mcTypeToConfirm => 'Type exactly this to confirm';

  @override
  String get mcCollectWarning =>
      'A real payment prompt will appear on the phone you enter. Use your own phone and the smallest amount.';

  @override
  String get mcSendWarning =>
      'Real money will leave the MarzPay wallet. The recipient should confirm receipt.';

  @override
  String get mcPayerPhone => 'Payer\'s phone (MTN or Airtel)';

  @override
  String get mcRecipientPhone => 'Recipient\'s phone (MTN or Airtel)';

  @override
  String get mcAmount => 'Amount (UGX)';

  @override
  String get mcAmountHint =>
      'At least 500; at most the limit in Safety settings.';

  @override
  String get mcDescription => 'Note (optional)';

  @override
  String get mcStartCollection => 'Request the payment';

  @override
  String get mcStartDisbursement => 'Send the money';

  @override
  String get mcQueuedLong =>
      'Still waiting: the payments server may be offline. The test starts as soon as it is running.';

  @override
  String get mcEvidence => 'Evidence';

  @override
  String get mcEnvironment => 'Environment';

  @override
  String get ccMarzSelfChecks =>
      'Integration self-checks (duplicates, timeouts, validation)';

  @override
  String get issuesMine => 'My problem reports';

  @override
  String get issuesMineHint =>
      'Problems you reported and your teachers\' answers';

  @override
  String get issuesMineEmpty =>
      'To report a problem, open the lesson or work and tap \"Report a problem\".';

  @override
  String get contactsImportTitle => 'Import from contacts';

  @override
  String get contactsImportHint => 'Pick many learners from this phone at once';

  @override
  String get contactsAddOne => 'Add one person';

  @override
  String get contactsDenied => 'Sidra can\'t read your contacts';

  @override
  String get contactsDeniedBody =>
      'Allow contacts access (Settings → Apps → Sidra → Permissions) and try again.';

  @override
  String get contactsNone => 'No contacts with a phone number';

  @override
  String get contactsSearch => 'Search name or number';

  @override
  String contactsSummary(int count, int created) {
    return '$count contacts · $created added';
  }

  @override
  String get contactsSelectAll => 'Select all';

  @override
  String get contactsSelectNone => 'Select none';

  @override
  String get contactsAlready => 'already in Sidra';

  @override
  String contactsCreated(String password) {
    return 'added · password $password';
  }

  @override
  String contactsImportN(int count) {
    return 'Import $count as learners';
  }

  @override
  String contactsImporting(int done, int count) {
    return 'Adding $done of $count…';
  }

  @override
  String contactsImportConfirm(int count) {
    return 'Add $count learners?';
  }

  @override
  String get contactsImportConfirmBody =>
      'Each gets an account with their phone number and a temporary password, shown here after import. Copy the list and send each person theirs; they choose a new password at first sign-in.';

  @override
  String get contactsCopyPasswords => 'Copy names and passwords';

  @override
  String get contactsCopied => 'Copied. Send each learner their password.';

  @override
  String get targetWhole => 'The whole work';

  @override
  String get targetOther => 'Something else';

  @override
  String targetAyah(int surah, int ayah) {
    return 'Surah $surah, ayah $ayah';
  }

  @override
  String targetAyahRange(int surah, int from, int to) {
    return 'Surah $surah, ayat $from–$to';
  }

  @override
  String targetPage(int page) {
    return 'Page $page';
  }

  @override
  String targetPageLine(int page, int line) {
    return 'Page $page, line $line';
  }

  @override
  String targetPageLines(int page, int line, int lineEnd) {
    return 'Page $page, lines $line–$lineEnd';
  }

  @override
  String get wtWaiting => 'Waiting for teacher';

  @override
  String get wtUnderReview => 'Teacher is reviewing';

  @override
  String get wtSuperseded => 'Replaced by a newer attempt';

  @override
  String get wtTryAgain => 'Try again';

  @override
  String get wtAccepted => 'Accepted';

  @override
  String wtLearnerTitle(String name) {
    return '$name\'s work';
  }

  @override
  String get wtMyWork => 'My work';

  @override
  String get wtNothingYet =>
      'Nothing sent yet. Record, photograph or write your work below.';

  @override
  String get wtCompleted => 'Accepted by your teacher. Well done!';

  @override
  String get wtYou => 'You';

  @override
  String get wtTeacher => 'Teacher';

  @override
  String get wtLearner => 'Learner';

  @override
  String wtFor(String what) {
    return 'For: $what';
  }

  @override
  String get wtAttachment => 'Attachment';

  @override
  String get wtUploadingPlain => 'Uploading…';

  @override
  String wtUploading(int percent) {
    return 'Uploading… $percent%';
  }

  @override
  String get wtSubmitting => 'Uploaded ✓ Sending to your teacher…';

  @override
  String get wtFailed => 'Not sent';

  @override
  String get wtQueued => 'Waiting for a connection';

  @override
  String get wtDiscard => 'Remove';

  @override
  String get wtDiscardBody =>
      'Remove this from the phone? It has not been sent.';

  @override
  String get wtUploadedFile => 'Uploaded';

  @override
  String get wtFileQueued => 'Queued';

  @override
  String get wtCorrectionDefaultTitle => 'Correction';

  @override
  String get wtReplySent => 'Reply sent.';

  @override
  String get wtNewAttempt => 'New attempt';

  @override
  String get wtReply => 'Reply';

  @override
  String wtMarkLatest(int number) {
    return 'Mark attempt $number:';
  }

  @override
  String get wtTryAgainAction => 'Try again';

  @override
  String get wtTeacherReplyHint =>
      'Voice, text, a file or a saved correction. Send as many as you need.';

  @override
  String get wtLearnerReplyHint => 'Answer your teacher about this attempt.';

  @override
  String get wtNewAttemptHint =>
      'Send your work: a recording, photos, files or text.';

  @override
  String get wtChooseTargetShort => 'What is it for?';

  @override
  String get wtRecord => 'Record';

  @override
  String get wtTeacherTextHint => 'Write a correction or note';

  @override
  String get wtTextHint => 'Write something (optional)';

  @override
  String get wtSendReply => 'Send reply';

  @override
  String get wtAyahInvalid => 'Enter a surah (1–114) and ayah numbers.';

  @override
  String get wtPageInvalid => 'Enter a page number (and lines, from – to).';

  @override
  String get wtExerciseInvalid => 'Name the exercise or question.';

  @override
  String get wtChooseTarget => 'What is this for?';

  @override
  String get wtTargetAyah => 'An ayah or ayat';

  @override
  String get wtSurah => 'Surah';

  @override
  String get wtAyahFrom => 'From ayah';

  @override
  String get wtAyahTo => 'To ayah';

  @override
  String get wtTargetPageLine => 'A page or line';

  @override
  String get wtPage => 'Page';

  @override
  String get wtLine => 'Line';

  @override
  String get wtLineTo => 'To line';

  @override
  String get wtTargetExercise => 'An exercise or question';

  @override
  String get wtExerciseName => 'Exercise or question';

  @override
  String get wtExerciseHint => 'e.g. Question 4';

  @override
  String get wtTargetText => 'Highlight part of the lesson';

  @override
  String get wtUseTarget => 'Use';

  @override
  String get wtSelectHint =>
      'Press and hold on the words, drag to highlight them, then tap Use.';

  @override
  String get wtSelected => 'Highlighted';

  @override
  String wtUseWholePassage(String what) {
    return 'Use the whole passage ($what)';
  }

  @override
  String get wtUseSelection => 'Use the highlighted words';

  @override
  String get accountMenu => 'Account';

  @override
  String get wtSendAgainHint =>
      'Sent. Noticed a mistake? Send a new attempt below; it replaces this one.';

  @override
  String get wtSeeHistory => 'See my work and feedback';

  @override
  String wtOpenWork(int count) {
    return 'My work ($count attempts): send, reply, see feedback';
  }

  @override
  String get wtHistory => 'History';

  @override
  String billPerWeek(String price) {
    return '$price / week';
  }

  @override
  String billPerMonth(String price) {
    return '$price / month';
  }

  @override
  String billPerTerm(String price) {
    return '$price / term';
  }

  @override
  String billPerDays(String price, int days) {
    return '$price every $days days';
  }

  @override
  String billPeriodsTotal(int count) {
    return '$count payments in all';
  }

  @override
  String get billPaused =>
      'Paused: a fee is overdue. Pay below to continue learning.';

  @override
  String billCovered(int covered, int due) {
    return 'Paid $covered of $due so far';
  }

  @override
  String billNextDue(String date) {
    return 'next due $date';
  }

  @override
  String get billPeriodLabel => 'How often is it paid?';

  @override
  String get billOnce => 'Once (one payment)';

  @override
  String get billWeekly => 'Every week';

  @override
  String get billMonthly => 'Every month';

  @override
  String get billTermly => 'Every term';

  @override
  String get billCustom => 'Every … days';

  @override
  String get billEveryDaysLabel => 'Every how many days?';

  @override
  String get billDaysInvalid => 'Enter 1 to 730 days.';

  @override
  String get billPeriodsLabel => 'Number of payments (optional)';

  @override
  String get billPeriodsHint => 'e.g. 3 terms; empty = for as long as enrolled';

  @override
  String get billPeriodsInvalid => 'Enter 1 to 520, or leave empty.';

  @override
  String get billHowItWorks =>
      'The price above is charged each period from the day a learner first pays. Learners are reminded when a period starts; one left unpaid past the grace days (Settings) pauses the course for them until they pay. Term length is in Settings.';

  @override
  String get billTermDaysSetting => 'Length of a term (days)';

  @override
  String get billTermDaysSettingHint => 'For courses paid every term.';

  @override
  String get billGraceSetting => 'Days to pay a repeating fee';

  @override
  String get billGraceSettingHint =>
      'After a new week, month or term begins, learners have this many days to pay before the course pauses for them.';

  @override
  String wtAttemptN(int n) {
    return 'Attempt $n';
  }

  @override
  String get ttTitle => 'Test transactions';

  @override
  String get ttConfirmTitle => 'Real money will move';

  @override
  String ttConfirmCollect(int amount, String phone, String network) {
    return 'Ask $phone ($network) to pay $amount UGX into Sidra\'s MarzPay wallet? The phone will show a PIN prompt.';
  }

  @override
  String ttConfirmDisburse(int amount, String phone, String network) {
    return 'Send $amount UGX from Sidra\'s MarzPay wallet to $phone ($network)? This cannot be undone.';
  }

  @override
  String get ttCollectNow => 'Collect now';

  @override
  String get ttDisburseNow => 'Send money now';

  @override
  String get ttMtn => 'MTN MoMo';

  @override
  String get ttAirtel => 'Airtel Money';

  @override
  String get ttRealMoney =>
      'For admins and developers. These are REAL transactions through MarzPay, not a simulation. Keep amounts small (the maximum is set in Settings → MarzPay).';

  @override
  String get ttNoKeys =>
      'This build has no MarzPay keys, so the test waits for the payments server.';

  @override
  String get ttCollect => 'Collect (money in)';

  @override
  String get ttDisburse => 'Disburse (money out)';

  @override
  String get ttCollectHint =>
      'Pulls money from the phone into Sidra\'s MarzPay wallet. The payer approves with their PIN.';

  @override
  String get ttDisburseHint =>
      'Sends money from Sidra\'s MarzPay wallet to the phone. Needs money in the wallet, sending tests switched on (Settings → MarzPay), and MarzPay\'s IP whitelist, which a phone usually does not pass: the response will show it.';

  @override
  String get ttPayerPhone => 'Payer\'s number';

  @override
  String get ttRecipientPhone => 'Recipient\'s number';

  @override
  String get ttPhoneHelp => 'MTN (076–079) or Airtel (070, 074, 075)';

  @override
  String get ttPhoneInvalid =>
      'Enter an MTN MoMo or Airtel Money number, e.g. 0772 123456';

  @override
  String get ttAmount => 'Amount';

  @override
  String get ttAmountHelp => 'At least 500 UGX';

  @override
  String get ttAmountInvalid => 'Enter a whole amount of at least 500 UGX';

  @override
  String get ttHistory => 'Past test transactions';

  @override
  String get ttHistoryHint =>
      'Tap one to see its full response. Numbers are stored masked.';

  @override
  String get ttResultSuccess => 'Succeeded (proven)';

  @override
  String get ttResultAccepted => 'Accepted, not proven';

  @override
  String get ttResultFailed => 'Failed';

  @override
  String get ttResultCancelled => 'Cancelled';

  @override
  String get ttResultPending => 'Pending';

  @override
  String get ttResultBlocked => 'Blocked';

  @override
  String get ttResponse => 'Response';

  @override
  String get ttClose => 'Close';

  @override
  String get ttProviderStatus => 'MarzPay status';

  @override
  String get ttErrorCode => 'Error code';

  @override
  String get ttHttpStatus => 'HTTP';

  @override
  String get ttReference => 'Reference';

  @override
  String get ttRawResponse => 'MarzPay\'s answer to the request (raw)';

  @override
  String get ttRawFinal => 'MarzPay\'s final answer (raw)';

  @override
  String get ttEntryHint =>
      'Collect or send a real amount and see MarzPay\'s exact response';
}
