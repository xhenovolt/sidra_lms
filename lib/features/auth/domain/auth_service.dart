import 'package:flutter/foundation.dart';

import 'auth_session.dart';

/// Authentication contract used by the rest of the app.
///
/// Implemented by `SidraAuthService` (Sidra's own phone/email + password
/// service). Screens and repositories depend only on this interface.
abstract interface class AuthService implements Listenable {
  AuthSession get session;

  /// Access token (JWT) for the Neon Data API, refreshed as needed.
  /// Returns null when signed out.
  Future<String?> dataApiToken();

  /// [identifier] is a phone number (international format) or an email.
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

  Future<void> signOut();

  void dispose();
}
