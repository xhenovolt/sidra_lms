/// Route paths. Use these constants; never hardcode paths in widgets.
abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const changePassword = '/change-password';

  static const home = '/home';
  static const myLearning = '/learning';
  static const explore = '/explore';
  static const downloads = '/downloads';
  static const profile = '/profile';

  static const course = '/courses/:courseId';
  static const lesson = '/courses/:courseId/lessons/:lessonId';

  static const quizPath = '/quiz/:assessmentId';
  static String quiz(String assessmentId) => '/quiz/$assessmentId';

  static const teach = '/teach';

  static String courseDetail(String courseId) => '/courses/$courseId';
  static String lessonDetail(String courseId, String lessonId) =>
      '/courses/$courseId/lessons/$lessonId';

  /// Routes reachable without a session.
  static const public = {splash, onboarding, signIn, signUp};
}
