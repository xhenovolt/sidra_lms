import 'package:flutter/foundation.dart';

import 'auth_session.dart';

/// Provider-agnostic authentication contract.
///
/// The Clerk SDK is beta, so it is isolated behind this interface; nothing
/// outside `features/auth/data` imports Clerk directly.
abstract interface class AuthService implements Listenable {
  AuthSession get session;

  /// JWT for the Neon Data API (Clerk JWT template), refreshed as needed.
  /// Returns null when signed out.
  Future<String?> dataApiToken();

  Future<void> signOut();

  void dispose();
}
