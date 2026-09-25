import 'package:flutter/foundation.dart';
import 'package:sidra_lms/features/auth/domain/auth_service.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';

/// Test-only [AuthService]. Never referenced from `lib/`.
class FakeAuthService extends ChangeNotifier implements AuthService {
  FakeAuthService([this._session = const AuthSession.signedOut()]);

  AuthSession _session;
  String? token = 'test.jwt.token';
  int signOutCalls = 0;

  @override
  AuthSession get session => _session;

  set session(AuthSession value) {
    _session = value;
    notifyListeners();
  }

  @override
  Future<String?> dataApiToken() async => _session.isSignedIn ? token : null;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    session = const AuthSession.signedOut();
  }
}

const testUser = AppUser(
  id: 'user_test123',
  displayName: 'Aisha Rahman',
  email: 'aisha@example.com',
);
