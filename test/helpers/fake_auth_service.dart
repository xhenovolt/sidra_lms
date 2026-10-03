import 'package:flutter/foundation.dart';
import 'package:sidra_lms/core/errors/app_failure.dart';
import 'package:sidra_lms/features/auth/domain/auth_service.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';

/// Test-only [AuthService]. Never referenced from `lib/`.
class FakeAuthService extends ChangeNotifier implements AuthService {
  FakeAuthService([this._session = const AuthSession.signedOut()]);

  AuthSession _session;
  String? token = 'test.jwt.token';
  int signOutCalls = 0;

  /// Accounts that exist: identifier → password.
  final accounts = <String, String>{'+256700000001': 'correct-password'};
  final calls = <String>[];

  /// When set, the next auth call fails with this.
  Object? failWith;

  @override
  AuthSession get session => _session;

  set session(AuthSession value) {
    _session = value;
    notifyListeners();
  }

  @override
  Future<String?> sessionToken({bool forceRefresh = false}) async =>
      _session.isSignedIn ? token : null;

  void _maybeFail() {
    final f = failWith;
    if (f != null) {
      failWith = null;
      throw f;
    }
  }

  @override
  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    calls.add('signIn:$identifier');
    _maybeFail();
    final key = identifier.replaceAll(RegExp(r'[\s-]'), '');
    if (accounts[key] != password) {
      throw const AuthFailure('invalid_credentials');
    }
    session = AuthSession.signedIn(AppUser(id: 'u-$key', phone: key));
  }

  /// Invitation codes the fake accepts, by identifier.
  final invitations = <String, String>{};

  @override
  Future<void> activate({
    required String identifier,
    required String code,
    required String password,
  }) async {
    calls.add('activate:$identifier');
    _maybeFail();
    final key = identifier.replaceAll(RegExp(r'[\s-]'), '');
    // Like the database: case and dashes / spaces do not matter.
    if (invitations[key] !=
        code.toUpperCase().replaceAll(RegExp(r'[\s-]'), '')) {
      throw const AuthFailure('invalid_code');
    }
    accounts[key] = password;
    session = AuthSession.signedIn(AppUser(id: 'u-$key', phone: key));
  }

  @override
  Future<void> signUp({
    required String displayName,
    required String identifier,
    required String password,
  }) async {
    calls.add('signUp:$identifier');
    _maybeFail();
    final key = identifier.replaceAll(RegExp(r'[\s-]'), '');
    if (accounts.containsKey(key)) throw const AuthFailure('identifier_taken');
    accounts[key] = password;
    session = AuthSession.signedIn(
      AppUser(id: 'u-$key', displayName: displayName, phone: key),
    );
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    calls.add('changePassword');
    _maybeFail();
    final u = _session.user!;
    session = AuthSession.signedIn(
      AppUser(
        id: u.id,
        displayName: u.displayName,
        phone: u.phone,
        email: u.email,
      ),
    );
  }

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
