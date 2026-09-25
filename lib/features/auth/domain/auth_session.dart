/// Authentication status as seen by the rest of the app.
enum AuthStatus {
  /// Auth provider still initialising (restoring a persisted session).
  initializing,
  signedOut,
  signedIn,
}

/// Minimal identity of the signed-in person.
///
/// Roles (learner / teacher / admin) are NOT taken from here: they are held
/// in the database and enforced by Row Level Security, so a tampered client
/// cannot elevate itself.
class AppUser {
  const AppUser({
    required this.id,
    this.displayName,
    this.email,
    this.imageUrl,
  });

  /// Clerk user id (`user_…`). Matches the JWT `sub` claim seen by Neon.
  final String id;
  final String? displayName;
  final String? email;
  final String? imageUrl;

  String? get firstName {
    final n = displayName?.trim();
    if (n == null || n.isEmpty) return null;
    return n.split(RegExp(r'\s+')).first;
  }

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.displayName == displayName &&
      other.email == email &&
      other.imageUrl == imageUrl;

  @override
  int get hashCode => Object.hash(id, displayName, email, imageUrl);
}

class AuthSession {
  const AuthSession._(this.status, this.user);

  const AuthSession.initializing() : this._(AuthStatus.initializing, null);
  const AuthSession.signedOut() : this._(AuthStatus.signedOut, null);
  const AuthSession.signedIn(AppUser user) : this._(AuthStatus.signedIn, user);

  final AuthStatus status;
  final AppUser? user;

  bool get isSignedIn => status == AuthStatus.signedIn;

  @override
  bool operator ==(Object other) =>
      other is AuthSession && other.status == status && other.user == user;

  @override
  int get hashCode => Object.hash(status, user);
}
