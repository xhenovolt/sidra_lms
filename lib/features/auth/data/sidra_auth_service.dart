import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../domain/auth_service.dart';
import '../domain/auth_session.dart';

/// Key/value storage for credentials (Keychain / Android Keystore).
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Sidra's own authentication, talking to the auth service (Worker).
///
/// * The refresh token (60 days, rotating) lives in secure storage; the
///   access token (15 min JWT) only in memory.
/// * A saved session restores immediately, even offline. The learner is
///   signed out only when the server REJECTS the refresh token, never
///   because the network is down.
/// * Refreshes are single-flight: concurrent callers share one request,
///   because replaying a rotated token would revoke the whole session.
class SidraAuthService extends ChangeNotifier implements AuthService {
  SidraAuthService({
    required this._http,
    required this._store,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Dio _http;
  final SecureStore _store;
  final DateTime Function() _clock;
  static const _log = AppLogger('auth');

  static const _kRefresh = 'sidra.auth.refresh';
  static const _kUser = 'sidra.auth.user';

  /// Builds the HTTP client for the auth service base URL.
  static Dio httpFor(String baseUrl) => Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  AuthSession _session = const AuthSession.initializing();
  String? _access;
  DateTime? _accessExpiry;
  Future<String?>? _refreshing;

  @override
  AuthSession get session => _session;

  void _set(AuthSession s) {
    if (s == _session) return;
    _session = s;
    notifyListeners();
  }

  /// Restores a saved session. Call once at startup.
  Future<void> restore() async {
    try {
      final userJson = await _store.read(_kUser);
      final refresh = await _store.read(_kRefresh);
      if (userJson == null || refresh == null) {
        _set(const AuthSession.signedOut());
        return;
      }
      _set(
        AuthSession.signedIn(
          AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      _log.warning('could not read saved session', {'error': '$e'});
      _set(const AuthSession.signedOut());
      return;
    }
    // Validate in the background; offline keeps the saved session.
    unawaited(
      dataApiToken().then<void>(
        (_) {},
        onError: (Object e) {
          _log.debug('background refresh deferred', {'reason': '$e'});
        },
      ),
    );
  }

  @override
  Future<String?> dataApiToken() {
    if (!_session.isSignedIn) return Future.value(null);
    final exp = _accessExpiry;
    if (_access != null &&
        exp != null &&
        exp.isAfter(_clock().add(const Duration(seconds: 60)))) {
      return Future.value(_access);
    }
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _refresh() async {
    final token = await _store.read(_kRefresh);
    if (token == null) {
      await _clearLocal();
      return null;
    }
    try {
      final res = await _http.post<Map<String, dynamic>>(
        '/v1/refresh',
        data: {'refresh_token': token},
      );
      await _apply(res.data!);
      return _access;
    } on DioException catch (e) {
      final failure = _map(e);
      if (failure is AuthFailure) {
        // Server says this session is over (revoked, expired, disabled).
        await _clearLocal();
        throw const UnauthenticatedFailure('Session ended');
      }
      throw failure; // offline / timeout / server: keep the session
    }
  }

  Future<void> _apply(Map<String, dynamic> body) async {
    final user = AppUser.fromJson(body['user'] as Map<String, dynamic>);
    _access = body['access_token'] as String;
    _accessExpiry = _clock().add(
      Duration(seconds: (body['expires_in'] as num).toInt()),
    );
    await _store.write(_kRefresh, body['refresh_token'] as String);
    await _store.write(_kUser, jsonEncode(user.toJson()));
    _set(AuthSession.signedIn(user));
  }

  Future<void> _clearLocal() async {
    _access = null;
    _accessExpiry = null;
    await _store.delete(_kRefresh);
    await _store.delete(_kUser);
    _set(const AuthSession.signedOut());
  }

  Future<void> _post(
    String path,
    Map<String, dynamic> data, {
    String? bearer,
  }) async {
    try {
      final res = await _http.post<Map<String, dynamic>>(
        path,
        data: data,
        options: bearer == null
            ? null
            : Options(headers: {'Authorization': 'Bearer $bearer'}),
      );
      await _apply(res.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> signIn({required String identifier, required String password}) =>
      _post('/v1/login', {'identifier': identifier, 'password': password});

  @override
  Future<void> signUp({
    required String displayName,
    required String identifier,
    required String password,
  }) => _post('/v1/register', {
    'display_name': displayName,
    'identifier': identifier,
    'password': password,
  });

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await dataApiToken();
    if (token == null) throw const UnauthenticatedFailure();
    await _post('/v1/password', {
      'old_password': oldPassword,
      'new_password': newPassword,
    }, bearer: token);
  }

  @override
  Future<void> signOut() async {
    final token = await _store.read(_kRefresh);
    await _clearLocal();
    if (token != null) {
      // Best effort: revoke on the server; signing out never waits on it.
      unawaited(
        _http
            .post<void>('/v1/logout', data: {'refresh_token': token})
            .then<void>((_) {}, onError: (_) {}),
      );
    }
  }

  AppFailure _map(DioException e) {
    final data = e.response?.data;
    final status = e.response?.statusCode ?? 0;
    if (data is Map &&
        data['error'] is String &&
        status >= 400 &&
        status < 500) {
      return AuthFailure(data['error'] as String);
    }
    return mapDioError(e);
  }
}
