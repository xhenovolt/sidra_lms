import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_service.dart';
import '../domain/auth_session.dart';

/// The active [AuthService]. Overridden in `bootstrap.dart` (and in tests).
final authServiceProvider = Provider<AuthService>(
  (ref) => throw UnimplementedError('authServiceProvider must be overridden'),
);

/// Current [AuthSession], kept in sync with the [AuthService].
final authSessionProvider = NotifierProvider<AuthSessionNotifier, AuthSession>(
  AuthSessionNotifier.new,
);

class AuthSessionNotifier extends Notifier<AuthSession> {
  @override
  AuthSession build() {
    final service = ref.watch(authServiceProvider);
    void listener() => state = service.session;
    service.addListener(listener);
    ref.onDispose(() => service.removeListener(listener));
    return service.session;
  }
}
