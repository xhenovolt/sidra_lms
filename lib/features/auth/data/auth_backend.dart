import 'dart:convert';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/sql_runner.dart';

/// Where sign-in requests go. Each call returns a session map
/// `{access_token, expires_in, refresh_token, user}` or throws
/// [AuthFailure] (wrong password, locked…) / Offline/Timeout failures.
abstract interface class AuthBackend {
  Future<Map<String, dynamic>> login(String identifier, String password);
  Future<Map<String, dynamic>> register(
    String identifier,
    String password,
    String displayName,
  );
  Future<Map<String, dynamic>> refresh(String refreshToken);
  Future<Map<String, dynamic>> changePassword(
    String accessToken,
    String oldPassword,
    String newPassword,
  );
  Future<void> logout(String refreshToken, String? accessToken);

  /// An imported learner accepts their invitation: phone / email, the code
  /// from the school and their own new password.
  Future<Map<String, dynamic>> activate(
    String identifier,
    String code,
    String password,
  );
}

/// Sign-in handled entirely by PostgreSQL (`auth_api.app_*`), as the app's
/// own low-privilege login — over HTTPS in the app ([NeonHttpRunner]; some
/// networks block PostgreSQL's port). Passwords are checked with bcrypt
/// inside the database; the app never sees a hash.
class PgAuthBackend implements AuthBackend {
  PgAuthBackend(this._runner, {this.device});

  final SqlRunner _runner;

  /// This phone's facts (install id, model, app version…), sent with each
  /// sign-in and refresh so sessions belong to a device the administrators
  /// can see and sign out. Null in tools and tests: sessions without a
  /// device, as before.
  final Future<Map<String, Object?>> Function()? device;

  Future<String?> _device() async {
    final d = device;
    if (d == null) return null;
    try {
      return jsonEncode(await d());
    } catch (_) {
      return null; // never block sign-in on device facts
    }
  }

  Future<Map<String, dynamic>> _call(String fn, List<String?> args) async {
    final placeholders = [for (var i = 1; i <= args.length; i++) '\$$i'];
    final rows = await _runner.run(
      null,
      'select auth_api.$fn(${placeholders.join(', ')})::text',
      args,
    );
    final text = rows.isEmpty ? null : rows.first;
    final map = text == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(text) as Map);
    final error = map['error'];
    if (error is String) throw AuthFailure(error);
    return map;
  }

  @override
  Future<Map<String, dynamic>> login(
    String identifier,
    String password,
  ) async => _call('app_login', [identifier, password, await _device()]);

  @override
  Future<Map<String, dynamic>> register(
    String identifier,
    String password,
    String displayName,
  ) async => _call('app_register', [
    identifier,
    password,
    displayName,
    await _device(),
  ]);

  @override
  Future<Map<String, dynamic>> activate(
    String identifier,
    String code,
    String password,
  ) async =>
      _call('app_activate', [identifier, code, password, await _device()]);

  @override
  Future<Map<String, dynamic>> refresh(String refreshToken) async =>
      _call('app_refresh', [refreshToken, await _device()]);

  @override
  Future<Map<String, dynamic>> changePassword(
    String accessToken,
    String oldPassword,
    String newPassword,
  ) async => _call('app_change_password', [
    accessToken,
    oldPassword,
    newPassword,
    await _device(),
  ]);

  @override
  Future<void> logout(String refreshToken, String? accessToken) => _runner
      .run(null, r'select auth_api.app_logout($1, $2)::text', [
        refreshToken,
        accessToken,
      ])
      .then((_) {});
}
