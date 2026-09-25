import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/auth_service.dart';
import '../domain/auth_session.dart';

/// [AuthService] backed by the Clerk Flutter SDK.
///
/// Clerk persists its client locally, so a previously signed-in learner is
/// restored even when the device starts offline.
class ClerkAuthService extends ChangeNotifier implements AuthService {
  ClerkAuthService(this.clerk, {required this.jwtTemplate}) {
    _session = _map();
    clerk.addListener(_onClerkChanged);
  }

  final ClerkAuthState clerk;
  final String jwtTemplate;
  static const _log = AppLogger('auth');

  late AuthSession _session;

  @override
  AuthSession get session => _session;

  void _onClerkChanged() {
    final next = _map();
    if (next != _session) {
      _session = next;
      notifyListeners();
    }
  }

  AuthSession _map() {
    final user = clerk.user;
    if (user == null) return const AuthSession.signedOut();
    final name = user.name.trim();
    return AuthSession.signedIn(
      AppUser(
        id: user.id,
        displayName: name.isEmpty ? null : name,
        email: user.email,
        imageUrl: user.imageUrl,
      ),
    );
  }

  @override
  Future<String?> dataApiToken() async {
    if (!clerk.isSignedIn) return null;
    try {
      final token = await clerk.sessionToken(templateName: jwtTemplate);
      return token.jwt;
    } catch (e, st) {
      _log.error('failed to obtain data API token', error: e, stackTrace: st);
      throw UnauthenticatedFailure('Token unavailable: ${e.runtimeType}');
    }
  }

  @override
  Future<void> signOut() => clerk.signOut();

  @override
  void dispose() {
    clerk.removeListener(_onClerkChanged);
    super.dispose();
  }

  /// Creates and initialises the Clerk state. Throws if Clerk cannot start
  /// and has no persisted client to fall back on.
  static Future<ClerkAuthState> createClerkState(String publishableKey) =>
      ClerkAuthState.create(
        config: ClerkAuthConfig(publishableKey: publishableKey),
      );
}
