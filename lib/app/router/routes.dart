/// Route paths. Use these constants; never hardcode paths in widgets.
abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const changePassword = '/change-password';

  // Learner navigation.
  static const home = '/home';
  static const myLearning = '/learning';
  static const explore = '/explore';
  static const downloads = '/downloads';
  static const profile = '/profile';

  // Teacher navigation.
  static const teacherLearners = '/teacher/learners';
  static const teacherCourses = '/teacher/courses';
  static const teacherMore = '/teacher/more';

  // Admin navigation.
  static const adminDashboard = '/admin/dashboard';
  static const adminLearners = '/admin/learners';
  static const adminCourses = '/admin/courses';
  static const adminPeople = '/admin/people';
  static const adminMore = '/admin/more';
  static const adminBooks = '/admin/books';

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
  static const public = {splash, onboarding, signIn, signUp};

  /// Learner-only tabs (staff are not learners).
  static const learnerTabs = {home, myLearning, explore, downloads, profile};

  /// Where each role starts.
  static String homeFor(String? role) => switch (role) {
    'admin' => adminDashboard,
    'teacher' => teacherLearners,
    _ => home,
  };
}
