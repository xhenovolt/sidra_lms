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
    return 'Delete “$title” permanently, with all its lessons, enrolments and learner progress? This cannot be undone. To only hide it, switch Published off instead.';
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
}
