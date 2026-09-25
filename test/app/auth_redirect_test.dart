import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/app/router/app_router.dart';
import 'package:sidra_lms/app/router/routes.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';

void main() {
  group('authRedirect', () {
    test('initializing sends everything to splash', () {
      for (final onboarded in [true, false]) {
        expect(
          authRedirect(
            AuthStatus.initializing,
            Routes.home,
            onboarded: onboarded,
          ),
          Routes.splash,
        );
        expect(
          authRedirect(
            AuthStatus.initializing,
            Routes.splash,
            onboarded: onboarded,
          ),
          isNull,
        );
      }
    });

    test('first launch shows onboarding before sign-in', () {
      for (final path in [Routes.home, Routes.signIn, Routes.splash]) {
        expect(
          authRedirect(AuthStatus.signedOut, path, onboarded: false),
          Routes.onboarding,
          reason: path,
        );
      }
      expect(
        authRedirect(AuthStatus.signedOut, Routes.onboarding, onboarded: false),
        isNull,
      );
    });

    test('signed out and onboarded cannot reach protected routes', () {
      for (final path in [
        Routes.home,
        Routes.profile,
        Routes.courseDetail('c1'),
        Routes.lessonDetail('c1', 'l1'),
        Routes.splash,
        Routes.onboarding,
      ]) {
        expect(
          authRedirect(AuthStatus.signedOut, path, onboarded: true),
          Routes.signIn,
          reason: path,
        );
      }
      expect(
        authRedirect(AuthStatus.signedOut, Routes.signIn, onboarded: true),
        isNull,
      );
    });

    test('signed in skips public routes, including onboarding', () {
      for (final onboarded in [true, false]) {
        for (final path in [Routes.signIn, Routes.splash, Routes.onboarding]) {
          expect(
            authRedirect(AuthStatus.signedIn, path, onboarded: onboarded),
            Routes.home,
            reason: path,
          );
        }
        expect(
          authRedirect(
            AuthStatus.signedIn,
            Routes.explore,
            onboarded: onboarded,
          ),
          isNull,
        );
        expect(
          authRedirect(
            AuthStatus.signedIn,
            Routes.courseDetail('c1'),
            onboarded: onboarded,
          ),
          isNull,
        );
      }
    });

    test('sign-up is reachable when signed out', () {
      expect(
        authRedirect(AuthStatus.signedOut, Routes.signUp, onboarded: true),
        isNull,
      );
      expect(
        authRedirect(AuthStatus.signedIn, Routes.signUp, onboarded: true),
        Routes.home,
      );
    });

    test('a staff-reset password must be changed first', () {
      for (final path in [Routes.home, Routes.explore, Routes.signIn]) {
        expect(
          authRedirect(
            AuthStatus.signedIn,
            path,
            onboarded: true,
            mustChangePassword: true,
          ),
          Routes.changePassword,
          reason: path,
        );
      }
      expect(
        authRedirect(
          AuthStatus.signedIn,
          Routes.changePassword,
          onboarded: true,
          mustChangePassword: true,
        ),
        isNull,
      );
      // Voluntary change from Profile is allowed.
      expect(
        authRedirect(
          AuthStatus.signedIn,
          Routes.changePassword,
          onboarded: true,
        ),
        isNull,
      );
    });
  });
}
