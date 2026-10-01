import 'package:flutter/foundation.dart';

import 'auth_session.dart';

/// Authentication contract used by the rest of the app.
///
/// Implemented by `SidraAuthService` (phone / email / username + password,
/// verified by PostgreSQL). Screens and repositories depend only on this.
abstract interface class AuthService implements Listenable {
  AuthSession get session;

  /// Session token sent to PostgreSQL with every request (bound to the
  /// transaction by `app_private.authenticate`). Refreshed as needed; pass
  /// [forceRefresh] after the server rejected the current one. Null when
  /// signed out.
  Future<String?> sessionToken({bool forceRefresh = false});

  /// [identifier] is a phone number (international format), an email, or a
  /// username.
  Future<void> signIn({required String identifier, required String password});

  Future<void> signUp({
    required String displayName,
    required String identifier,
    required String password,
  });

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// An imported learner's first sign-in: the school's invitation code and
  /// their own new password (no default passwords anywhere).
  Future<void> activate({
    required String identifier,
    required String code,
    required String password,
  });

  Future<void> signOut();

  void dispose();
}
