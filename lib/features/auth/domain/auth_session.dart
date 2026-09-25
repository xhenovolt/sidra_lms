/// Authentication status as seen by the rest of the app.
enum AuthStatus {
  /// Restoring a saved session at startup.
  initializing,
  signedOut,
  signedIn,
}

/// Identity of the signed-in person.
///
/// [role] here only decides what the UI offers; PostgreSQL re-checks every
/// action, so a tampered client cannot elevate itself.
class AppUser {
  const AppUser({
    required this.id,
    this.displayName,
    this.email,
    this.phone,
    this.imageUrl,
    this.role = 'learner',
    this.isSuperadmin = false,
    this.mustChangePassword = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] as String,
    displayName: j['display_name'] as String?,
    email: j['email'] as String?,
    phone: j['phone'] as String?,
    imageUrl: j['avatar_url'] as String?,
    role: (j['role'] as String?) ?? 'learner',
    isSuperadmin: (j['is_superadmin'] as bool?) ?? false,
    mustChangePassword: (j['must_change_password'] as bool?) ?? false,
  );

  /// Sidra user id (= JWT `sub`, = `users.id` in Postgres).
  final String id;
  final String? displayName;
  final String? email;
  final String? phone;
  final String? imageUrl;

  /// learner | teacher | admin. Decides the navigation (RBAC); every action
  /// is still authorised by PostgreSQL.
  final String role;

  /// Admin who can also manage other administrators.
  final bool isSuperadmin;

  bool get isLearner => role != 'teacher' && role != 'admin';
  bool get isTeacher => role == 'teacher';
  bool get isAdmin => role == 'admin';

  /// Set after a teacher/admin reset: the learner must pick a new password.
  final bool mustChangePassword;

  /// Phone or email, whichever the account uses.
  String? get identifier => phone ?? email;

  String? get firstName {
    final n = displayName?.trim();
    if (n == null || n.isEmpty) return null;
    return n.split(RegExp(r'\s+')).first;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'email': email,
    'phone': phone,
    'avatar_url': imageUrl,
    'role': role,
    'is_superadmin': isSuperadmin,
    'must_change_password': mustChangePassword,
  };

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.displayName == displayName &&
      other.email == email &&
      other.phone == phone &&
      other.imageUrl == imageUrl &&
      other.role == role &&
      other.isSuperadmin == isSuperadmin &&
      other.mustChangePassword == mustChangePassword;

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    email,
    phone,
    imageUrl,
    role,
    isSuperadmin,
    mustChangePassword,
  );
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
