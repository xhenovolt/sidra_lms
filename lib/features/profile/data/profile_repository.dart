import '../../../core/database/local_database.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/postgres_api.dart';
import '../../../shared/models/json.dart';
import '../../auth/domain/auth_session.dart';

enum UserRole { learner, teacher, admin }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.role,
    this.displayName,
    this.email,
    this.isSuperadmin = false,
  });

  factory UserProfile.fromJson(Json j) => UserProfile(
    id: j.str('id'),
    role: enumByName(UserRole.values, j.strOrNull('role'), UserRole.learner),
    displayName: j.strOrNull('display_name'),
    email: j.strOrNull('email'),
    isSuperadmin: j.boolean('is_superadmin'),
  );

  final String id;
  final UserRole role;
  final String? displayName;
  final String? email;

  /// Can manage administrators (creating, promoting, disabling admins).
  final bool isSuperadmin;

  bool get isStaff => role == UserRole.teacher || role == UserRole.admin;
  bool get isAdmin => role == UserRole.admin;

  Json toJson() => {
    'id': id,
    'role': role.name,
    'display_name': displayName,
    'email': email,
    'is_superadmin': isSuperadmin,
  };
}

/// Creates/refreshes the caller's database profile and learns their role.
///
/// The role shown in the UI is cached for offline use, but it only controls
/// what the UI OFFERS. Every staff action is re-checked by Postgres.
class ProfileRepository {
  ProfileRepository(this._local, this._api);

  final LocalDatabase _local;
  final PostgresApi _api;
  static const _key = 'profile';

  Future<UserProfile> ensure(AppUser user) async {
    try {
      final json = await _api.rpc(
        'ensure_profile',
        params: {
          'p_display_name': user.displayName,
          'p_email': user.email,
          'p_avatar_url': user.imageUrl,
        },
      );
      final profile = UserProfile.fromJson(Json.from(json as Map));
      await _local.setKv(_key, LocalDatabase.encode(profile.toJson()));
      return profile;
    } on AppFailure {
      final cached = await _local.getKv(_key);
      if (cached == null) rethrow;
      return UserProfile.fromJson(LocalDatabase.decodeMap(cached));
    }
  }
}
