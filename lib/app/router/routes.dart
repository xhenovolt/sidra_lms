/// Route paths. Use these constants; never hardcode paths in widgets.
abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';

  /// An imported learner's first sign-in with an invitation code.
  static const activate = '/activate';
  static const changePassword = '/change-password';

  // Learner navigation.
  static const home = '/home';
  static const myLearning = '/learning';
  static const explore = '/explore';
  static const downloads = '/downloads';
  static const profile = '/profile';

  // Teacher navigation.
  static const teacherTeaching = '/teacher/teaching';
  static const teacherLearners = '/teacher/learners';
  static const teacherCourses = '/teacher/courses';
  static const teacherMore = '/teacher/more';

  // Admin console (drawer).
  static const adminDashboard = '/admin/dashboard';
  static const adminCourses = '/admin/courses';
  static const adminBooks = '/admin/books';
  static const adminLearners = '/admin/review';
  static const adminPeopleLearners = '/admin/people/learners';
  static const adminPeopleTeachers = '/admin/people/teachers';
  static const adminPeopleAdmins = '/admin/people/admins';
  static const adminPeople = adminPeopleLearners;
  static const adminRoles = '/admin/roles';
  static const adminAudit = '/admin/activity';
  static const adminFinance = '/admin/finance';
  static const adminFinancePayments = '/admin/finance/payments';
  static const adminAccounts = '/admin/finance/accounts';
  static const adminJournal = '/admin/finance/journal';
  static const adminBills = '/admin/finance/bills';
  static const adminAssets = '/admin/finance/assets';
  static const adminFinanceReports = '/admin/finance/reports';
  static const adminCounts = '/admin/finance/counts';

  /// Real MarzPay test collections / disbursements (payments.test).
  static const testTransactions = '/test-transactions';
  static const adminSettings = '/admin/settings';
  static const adminSubmissions = '/admin/submissions';
  static const teachSubmissions = '/teach/submissions';
  static const adminTeaching = '/admin/teaching';
  static const adminLibrary = '/admin/library';
  static const adminCorrections = '/admin/corrections';
  static const adminReports = '/admin/reports';
  static const about = '/about';
  static const notifications = '/notifications';
  static const adminMore = '/admin/account';

  /// The published catalogue as learners see it (for staff previews).
  static const catalogue = '/catalogue';

  static const course = '/courses/:courseId';
  static const lesson = '/courses/:courseId/lessons/:lessonId';

  static const quizPath = '/quiz/:assessmentId';
  static String quiz(String assessmentId) => '/quiz/$assessmentId';

  static String courseDetail(String courseId) => '/courses/$courseId';
  static String lessonDetail(String courseId, String lessonId) =>
      '/courses/$courseId/lessons/$lessonId';

  /// Routes reachable without a session.
  static const public = {splash, onboarding, signIn, signUp, activate};

  /// Learner-only tabs (staff are not learners).
  static const learnerTabs = {home, myLearning, explore, downloads, profile};

  /// Where each role starts.
  static String homeFor(String? role) => switch (role) {
    'admin' => adminDashboard,
    'teacher' => teacherTeaching,
    _ => home,
  };
}
