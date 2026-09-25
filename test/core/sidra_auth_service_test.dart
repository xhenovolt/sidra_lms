import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/errors/app_failure.dart';
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

typedef Handler = (int, Map<String, dynamic>?) Function(RequestOptions);

/// Fake auth service server. Throws a connection error when [offline].
class FakeServer implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <Map<String, dynamic>>[];
  bool offline = false;
  Completer<void>? gate;
  final Map<String, Handler> routes = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    bodies.add(Map<String, dynamic>.from((options.data as Map?) ?? const {}));
    if (gate != null) await gate!.future;
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    final (status, body) = routes[options.path]!(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> sessionBody(String refresh, {bool mustChange = false}) => {
  'access_token': 'jwt-$refresh',
  'token_type': 'Bearer',
  'expires_in': 900,
  'refresh_token': refresh,
  'user': {
    'id': 'u1',
    'role': 'learner',
    'display_name': 'Yusuf',
    'phone': '+256700000001',
    'must_change_password': mustChange,
  },
};

void main() {
  late FakeServer server;
  late MemoryStore store;
  late DateTime now;
  late SidraAuthService auth;

  SidraAuthService build() => SidraAuthService(
    http: Dio(BaseOptions(baseUrl: 'https://auth.test'))
      ..httpClientAdapter = server,
    store: store,
    clock: () => now,
  );

  setUp(() {
    server = FakeServer();
    store = MemoryStore();
    now = DateTime.utc(2026, 9, 25, 12);
    auth = build();
    var n = 0;
    server.routes['/v1/login'] = (o) {
      final b = o.data as Map;
      return b['password'] == 'right-password'
          ? (200, sessionBody('r${++n}'))
          : (401, {'error': 'invalid_credentials'});
    };
    server.routes['/v1/refresh'] = (o) =>
        (o.data as Map)['refresh_token'] == store.data['sidra.auth.refresh']
        ? (200, sessionBody('r${++n}'))
        : (401, {'error': 'invalid_token'});
    server.routes['/v1/logout'] = (_) => (204, null);
    server.routes['/v1/password'] = (o) =>
        o.headers['Authorization'] == 'Bearer jwt-r1'
        ? (200, sessionBody('r${++n}'))
        : (401, {'error': 'invalid_token'});
  });

  test('no saved session → signed out', () async {
    await auth.restore();
    expect(auth.session.status, AuthStatus.signedOut);
  });

  test('sign in stores the refresh token and yields an access token', () async {
    await auth.restore();
    await auth.signIn(identifier: '+256700000001', password: 'right-password');
    expect(auth.session.user?.displayName, 'Yusuf');
    expect(store.data['sidra.auth.refresh'], 'r1');
    expect(await auth.dataApiToken(), 'jwt-r1');
    expect(server.requests.length, 1, reason: 'cached token reused');
  });

  test('wrong password surfaces AuthFailure(invalid_credentials)', () async {
    await auth.restore();
    await expectLater(
      auth.signIn(identifier: '+256700000001', password: 'nope-nope'),
      throwsA(
        isA<AuthFailure>().having((f) => f.code, 'code', 'invalid_credentials'),
      ),
    );
    expect(auth.session.isSignedIn, isFalse);
  });

  test('saved session restores offline and stays signed in', () async {
    await auth.restore();
    await auth.signIn(identifier: '+256700000001', password: 'right-password');

    server.offline = true;
    final restarted = build();
    await restarted.restore();
    expect(restarted.session.isSignedIn, isTrue);
    await expectLater(restarted.dataApiToken(), throwsA(isA<OfflineFailure>()));
    expect(restarted.session.isSignedIn, isTrue, reason: 'network ≠ logout');
  });

  test('expired access token refreshes and rotates the stored token', () async {
    await auth.restore();
    await auth.signIn(identifier: '+256700000001', password: 'right-password');
    now = now.add(const Duration(minutes: 15));
    expect(await auth.dataApiToken(), 'jwt-r2');
    expect(store.data['sidra.auth.refresh'], 'r2');
  });

  test('concurrent callers share ONE refresh (no token reuse)', () async {
    await auth.restore();
    await auth.signIn(identifier: '+256700000001', password: 'right-password');
    now = now.add(const Duration(minutes: 15));
    server.gate = Completer<void>();
    final tokens = [
      auth.dataApiToken(),
      auth.dataApiToken(),
      auth.dataApiToken(),
    ];
    server.gate!.complete();
    expect(await Future.wait(tokens), everyElement('jwt-r2'));
    expect(server.requests.where((r) => r.path == '/v1/refresh').length, 1);
  });

  test(
    'server rejecting the refresh token signs out and clears storage',
    () async {
      await auth.restore();
      await auth.signIn(
        identifier: '+256700000001',
        password: 'right-password',
      );
      store.data['sidra.auth.refresh'] = 'revoked-elsewhere';
      server.routes['/v1/refresh'] = (_) => (401, {'error': 'invalid_token'});
      now = now.add(const Duration(minutes: 15));
      await expectLater(
        auth.dataApiToken(),
        throwsA(isA<UnauthenticatedFailure>()),
      );
      expect(auth.session.status, AuthStatus.signedOut);
      expect(store.data, isEmpty);
    },
  );

  test(
    'change password sends the bearer token and replaces the session',
    () async {
      await auth.restore();
      await auth.signIn(
        identifier: '+256700000001',
        password: 'right-password',
      );
      await auth.changePassword(
        oldPassword: 'right-password',
        newPassword: 'new-password',
      );
      expect(store.data['sidra.auth.refresh'], 'r2');
    },
  );

  test('temporary-password accounts are flagged for a forced change', () async {
    server.routes['/v1/login'] = (_) =>
        (200, sessionBody('r1', mustChange: true));
    await auth.restore();
    await auth.signIn(identifier: '+256700000001', password: 'temp');
    expect(auth.session.user!.mustChangePassword, isTrue);
  });

  test('sign out clears locally even when offline', () async {
    await auth.restore();
    await auth.signIn(identifier: '+256700000001', password: 'right-password');
    server.offline = true;
    await auth.signOut();
    expect(auth.session.status, AuthStatus.signedOut);
    expect(store.data, isEmpty);
    expect(await auth.dataApiToken(), isNull);
  });
}
