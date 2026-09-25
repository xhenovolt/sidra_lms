import 'package:flutter/foundation.dart';

import '../domain/auth_service.dart';
import '../domain/auth_session.dart';

/// Used when the build has no Clerk publishable key. It is permanently
/// signed out and cannot sign anyone in — it exists so the app can still
/// show onboarding and an explanatory sign-in screen instead of dead-ending.
class UnconfiguredAuthService extends ChangeNotifier implements AuthService {
  @override
  AuthSession get session => const AuthSession.signedOut();

  @override
  Future<String?> dataApiToken() async => null;

  @override
  Future<void> signOut() async {}
}
