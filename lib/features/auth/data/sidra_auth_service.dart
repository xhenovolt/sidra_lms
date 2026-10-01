import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/auth_service.dart';
import '../domain/auth_session.dart';
import 'auth_backend.dart';

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

/// Sidra's own authentication (phone / email / username + password).
///
/// * The refresh token (60 days, rotating) lives in secure storage; the
///   session token (1 hour) only in memory.
/// * A saved session restores immediately, even offline. The learner is
///   signed out only when the server REJECTS the refresh token, never
///   because the network is down.
/// * Refreshes are single-flight: concurrent callers share one request,
///   because replaying a rotated token would end the whole session.
class SidraAuthService extends ChangeNotifier implements AuthService {
  SidraAuthService({
    required this._backend,
    required this._store,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AuthBackend _backend;
  final SecureStore _store;
  final DateTime Function() _clock;
  static const _log = AppLogger('auth');

  static const _kRefresh = 'sidra.auth.refresh';
  static const _kUser = 'sidra.auth.user';

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
      sessionToken().then<void>(
        (_) {},
        onError: (Object e) {
          _log.debug('background refresh deferred', {'reason': '$e'});
        },
      ),
    );
  }

  @override
  Future<String?> sessionToken({bool forceRefresh = false}) {
    if (!_session.isSignedIn) return Future.value(null);
    final exp = _accessExpiry;
    if (!forceRefresh &&
        _access != null &&
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
      await _apply(await _backend.refresh(token));
      return _access;
    } on AuthFailure {
      // The server says this session is over (revoked, expired, disabled).
      await _clearLocal();
      throw const UnauthenticatedFailure('Session ended');
    }
    // Offline / timeout / server errors propagate; the session is kept.
  }

  Future<void> _apply(Map<String, dynamic> body) async {
    final user = AppUser.fromJson(
      Map<String, dynamic>.from(body['user'] as Map),
    );
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

  @override
  Future<void> signIn({
    required String identifier,
    required String password,
  }) async => _apply(await _backend.login(identifier.trim(), password));

  @override
  Future<void> signUp({
    required String displayName,
    required String identifier,
    required String password,
  }) async => _apply(
    await _backend.register(identifier.trim(), password, displayName.trim()),
  );

  @override
  Future<void> activate({
    required String identifier,
    required String code,
    required String password,
  }) async => _apply(
    await _backend.activate(identifier.trim(), code.trim(), password),
  );

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await sessionToken();
    if (token == null) throw const UnauthenticatedFailure();
    await _apply(
      await _backend.changePassword(token, oldPassword, newPassword),
    );
  }

  @override
  Future<void> signOut() async {
    final refresh = await _store.read(_kRefresh);
    final access = _access;
    await _clearLocal();
    if (refresh != null) {
      // Best effort: revoke on the server; signing out never waits on it.
      unawaited(
        _backend.logout(refresh, access).then<void>((_) {}, onError: (_) {}),
      );
    }
  }
}
