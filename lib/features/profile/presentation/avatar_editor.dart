import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../admin/presentation/admin_common.dart';
import 'photo_editor.dart';

/// Your own picture, with a camera badge: tap to change it.
class MyAvatar extends ConsumerWidget {
  const MyAvatar({super.key, this.radius = 32});
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider).value;
    return Semantics(
      button: true,
      label: l10n.avatarChange,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showAvatarEditor(context, ref),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatar(
              avatarUrl: profile?.avatarUrl,
              name: profile?.displayName,
              radius: radius,
            ),
            PositionedDirectional(
              end: -2,
              bottom: -2,
              child: CircleAvatar(
                radius: radius * 0.34,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(
                  Icons.photo_camera,
                  size: radius * 0.38,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Take a photo, upload one, or choose an avatar.
Future<void> showAvatarEditor(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AvatarEditor(),
    );

class _AvatarEditor extends ConsumerStatefulWidget {
  const _AvatarEditor();

  @override
  ConsumerState<_AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends ConsumerState<_AvatarEditor> {
  bool _saving = false;

  Future<void> _set(String? value) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    final ok = await runAdminAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .api
          .rpc('set_my_avatar', params: {'p_value': value}),
      success: l10n.avatarSaved,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ref.invalidate(profileProvider);
      Navigator.pop(context);
    }
  }

  Future<void> _photo(ImageSource source) async {
    final x = await ImagePicker().pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 95,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (x == null || !mounted) return;
    // Crop (zoom, move into the circle) and rotate before uploading.
    final edited = await PhotoEditScreen.edit(context, x.path);
    if (edited == null || !mounted) return;
    final name = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    setState(() => _saving = true);
    String? assetId;
    final ok = await runAdminAction(context, () async {
      final profile = await ref.read(profileProvider.future);
      assetId = await ref
          .read(adminRepositoryProvider)
          .uploadMedia(
            filePath: edited,
            fileName: name,
            kind: 'image',
            uploaderId: profile.id,
            folder: 'avatars',
            title: 'Profile photo',
          );
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok && assetId != null) await _set('media:$assetId');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = ref.watch(profileProvider).value;
    return AbsorbPointer(
      absorbing: _saving,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.avatarTitle, style: theme.textTheme.titleLarge),
              if (_saving) const LinearProgressIndicator(),
              const SizedBox(height: Space.sm),
              if (current?.avatarUrl != null)
                ListTile(
                  leading: const Icon(Icons.zoom_out_map),
                  title: Text(l10n.photoView),
                  onTap: () => PhotoViewScreen.open(
                    context,
                    current!.avatarUrl,
                    current.displayName,
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.avatarTakePhoto),
                onTap: () => _photo(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.avatarUpload),
                onTap: () => _photo(ImageSource.gallery),
              ),
              const SizedBox(height: Space.sm),
              Text(l10n.avatarChoose, style: theme.textTheme.titleSmall),
              const SizedBox(height: Space.xs),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final key in builtInAvatars.keys)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _set('avatar:$key'),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 2,
                            color: current?.avatarUrl == 'avatar:$key'
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: UserAvatar(
                          avatarUrl: 'avatar:$key',
                          name: null,
                          radius: 26,
                        ),
                      ),
                    ),
                ],
              ),
              if (current?.avatarUrl != null) ...[
                const SizedBox(height: Space.sm),
                TextButton.icon(
                  onPressed: () => _set(null),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.avatarRemove),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
