import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/auth_service.dart';
import '../domain/auth_session.dart';

/// Used when the build has no APP_DATABASE_URL. It is permanently signed out and
/// refuses every sign-in, so the app shows onboarding and an explanatory
/// sign-in screen instead of dead-ending. There is no fake login.
class UnconfiguredAuthService extends ChangeNotifier implements AuthService {
  static const _failure = ConfigurationFailure('Sign-in is not configured');

  @override
  AuthSession get session => const AuthSession.signedOut();

  @override
  Future<String?> sessionToken({bool forceRefresh = false}) async => null;

  @override
  Future<void> signIn({required String identifier, required String password}) =>
      Future.error(_failure);

  @override
  Future<void> signUp({
    required String displayName,
    required String identifier,
    required String password,
  }) => Future.error(_failure);

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) => Future.error(_failure);

  @override
  Future<void> signOut() async {}
}
