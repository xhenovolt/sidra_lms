import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/data_providers.dart';

/// Built-in avatars: calm symbols (no faces), each with its own colour.
const builtInAvatars = <String, (IconData, Color)>{
  'crescent': (Icons.nightlight_round, Color(0xFF1B5E55)),
  'star': (Icons.star_rounded, Color(0xFFA87A2A)),
  'book': (Icons.menu_book_rounded, Color(0xFF2E7D71)),
  'lantern': (Icons.emoji_objects_rounded, Color(0xFFB0662B)),
  'palm': (Icons.park_rounded, Color(0xFF3F7D3A)),
  'mountain': (Icons.landscape_rounded, Color(0xFF5B6B8C)),
  'flower': (Icons.local_florist_rounded, Color(0xFFA0527A)),
  'water': (Icons.water_drop_rounded, Color(0xFF2F74A8)),
  'sun': (Icons.wb_sunny_rounded, Color(0xFFC2891B)),
  'leaf': (Icons.eco_rounded, Color(0xFF4E8A3E)),
  'pen': (Icons.edit_rounded, Color(0xFF6D4C8D)),
  'hexagon': (Icons.hexagon_rounded, Color(0xFF0E3B36)),
};

/// Signed URL of a profile photo (the database decides who may see it).
/// Kept for the session so lists don't ask again for every row.
final avatarUrlProvider = FutureProvider.family<String?, String>((
  ref,
  assetId,
) async {
  ref.keepAlive();
  try {
    return await ref
            .watch(postgresApiProvider)
            .rpc('media_url', params: {'p_asset_id': assetId})
        as String?;
  } catch (_) {
    return null;
  }
});

/// A person's picture: their photo, their chosen avatar, or initials.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 20,
  });

  /// `media:<id>`, `avatar:<key>` or null.
  final String? avatarUrl;
  final String? name;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final v = avatarUrl;
    final initials = Text(
      (name == null || name!.trim().isEmpty)
          ? '?'
          : name!.trim().characters.first.toUpperCase(),
      style: TextStyle(
        fontSize: radius * 0.8,
        color: scheme.onPrimaryContainer,
      ),
    );
    if (v != null && v.startsWith('avatar:')) {
      final a = builtInAvatars[v.substring(7)];
      if (a != null) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: a.$2,
          child: Icon(a.$1, color: Colors.white, size: radius * 1.1),
        );
      }
    }
    if (v != null && v.startsWith('media:')) {
      final url = ref.watch(avatarUrlProvider(v.substring(6))).value;
      return CircleAvatar(
        radius: radius,
        backgroundColor: scheme.primaryContainer,
        foregroundImage: url == null ? null : CachedNetworkImageProvider(url),
        child: initials,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: initials,
    );
  }
}
