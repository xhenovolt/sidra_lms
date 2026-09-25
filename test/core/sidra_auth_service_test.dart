import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/errors/app_failure.dart';
import 'package:sidra_lms/features/auth/data/auth_backend.dart';
import 'package:sidra_lms/features/auth/data/sidra_auth_service.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';

class MemoryStore implements SecureStore {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

/// Behaves like auth_api.app_* in PostgreSQL.
class FakeBackend implements AuthBackend {
  bool offline = false;
  Completer<void>? gate;
  final calls = <String>[];
  String? validRefresh;
  int _n = 0;
  bool mustChange = false;

  Map<String, dynamic> _session() {
    final r = 'r${++_n}';
    validRefresh = r;
    return {
      'access_token': 'at-$r',
      'expires_in': 3600,
      'refresh_token': r,
      'user': {
        'id': 'u1',
        'role': 'learner',
        'display_name': 'Yusuf',
        'phone': '+256700000001',
        'must_change_password': mustChange,
      },
    };
  }

  Future<void> _net(String name) async {
    calls.add(name);
    if (gate != null) await gate!.future;
    if (offline) throw const OfflineFailure();
  }

  @override
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    await _net('login');
    if (password != 'right-password') {
      throw const AuthFailure('invalid_credentials');
    }
    return _session();
  }

  @override
  Future<Map<String, dynamic>> register(String i, String p, String n) async {
    await _net('register');
    return _session();
  }

  @override
  Future<Map<String, dynamic>> refresh(String token) async {
    await _net('refresh');
    if (token != validRefresh) throw const AuthFailure('invalid_token');
    return _session();
  }

  @override
  Future<Map<String, dynamic>> changePassword(
    String a,
    String o,
    String n,
  ) async {
    await _net('changePassword:$a');
    return _session();
  }

  @override
  Future<void> logout(String refreshToken, String? accessToken) async {
    await _net('logout');
  }
}

void main() {
  late FakeBackend backend;
  late MemoryStore store;
  late DateTime now;
  late SidraAuthService auth;

  SidraAuthService build() =>
      SidraAuthService(backend: backend, store: store, clock: () => now);

  setUp(() {
    backend = FakeBackend();
    store = MemoryStore();
    now = DateTime.utc(2026, 9, 25, 12);
    auth = build();
  });

  Future<void> signIn() =>
      auth.signIn(identifier: '+256700000001', password: 'right-password');

  test('no saved session → signed out', () async {
    await auth.restore();
    expect(auth.session.status, AuthStatus.signedOut);
  });

  test('sign in stores the refresh token and yields a session token', () async {
    await auth.restore();
    await signIn();
    expect(auth.session.user?.displayName, 'Yusuf');
    expect(store.data['sidra.auth.refresh'], 'r1');
    expect(await auth.sessionToken(), 'at-r1');
    expect(backend.calls, ['login'], reason: 'cached token reused');
  });

  test('wrong password surfaces AuthFailure(invalid_credentials)', () async {
    await auth.restore();
    await expectLater(
      auth.signIn(identifier: '+256700000001', password: 'nope'),
      throwsA(
        isA<AuthFailure>().having((f) => f.code, 'code', 'invalid_credentials'),
      ),
    );
    expect(auth.session.isSignedIn, isFalse);
  });

  test('saved session restores offline and stays signed in', () async {
    await auth.restore();
    await signIn();
    backend.offline = true;
    final restarted = build();
    await restarted.restore();
    expect(restarted.session.isSignedIn, isTrue);
    await expectLater(restarted.sessionToken(), throwsA(isA<OfflineFailure>()));
    expect(restarted.session.isSignedIn, isTrue, reason: 'network ≠ logout');
  });

  test(
    'expired session token refreshes and rotates the stored token',
    () async {
      await auth.restore();
      await signIn();
      now = now.add(const Duration(hours: 1));
      expect(await auth.sessionToken(), 'at-r2');
      expect(store.data['sidra.auth.refresh'], 'r2');
    },
  );

  test('forceRefresh gets a new token even before expiry', () async {
    await auth.restore();
    await signIn();
    expect(await auth.sessionToken(forceRefresh: true), 'at-r2');
  });

  test('concurrent callers share ONE refresh (no token reuse)', () async {
    await auth.restore();
    await signIn();
    now = now.add(const Duration(hours: 1));
    backend.gate = Completer<void>();
    final tokens = [
      auth.sessionToken(),
      auth.sessionToken(),
      auth.sessionToken(),
    ];
    backend.gate!.complete();
    expect(await Future.wait(tokens), everyElement('at-r2'));
    expect(backend.calls.where((c) => c == 'refresh'), hasLength(1));
  });

  test(
    'server rejecting the refresh token signs out and clears storage',
    () async {
      await auth.restore();
      await signIn();
      backend.validRefresh = 'revoked';
      now = now.add(const Duration(hours: 1));
      await expectLater(
        auth.sessionToken(),
        throwsA(isA<UnauthenticatedFailure>()),
      );
      expect(auth.session.status, AuthStatus.signedOut);
      expect(store.data, isEmpty);
    },
  );

  test('change password sends the current session token', () async {
    await auth.restore();
    await signIn();
    await auth.changePassword(
      oldPassword: 'right-password',
      newPassword: 'new-password',
    );
    expect(backend.calls.last, 'changePassword:at-r1');
    expect(store.data['sidra.auth.refresh'], 'r2');
  });

  test('temporary-password accounts are flagged for a forced change', () async {
    backend.mustChange = true;
    await auth.restore();
    await signIn();
    expect(auth.session.user!.mustChangePassword, isTrue);
  });

  test('sign out clears locally even when offline', () async {
    await auth.restore();
    await signIn();
    backend.offline = true;
    await auth.signOut();
    expect(auth.session.status, AuthStatus.signedOut);
    expect(store.data, isEmpty);
    expect(await auth.sessionToken(), isNull);
  });
}
