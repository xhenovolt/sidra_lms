import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/data_providers.dart';
import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider).user;
    final profile = ref.watch(profileProvider).value;
    final sync = ref.watch(syncStatusProvider).value;
    final initial = (user?.displayName ?? user?.email ?? '?').characters.first
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundImage: user?.imageUrl == null
                    ? null
                    : NetworkImage(user!.imageUrl!),
                child: Text(initial, style: theme.textTheme.titleLarge),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user?.displayName != null)
                      Text(
                        user!.displayName!,
                        style: theme.textTheme.titleLarge,
                      ),
                    if (user?.email != null)
                      Text(
                        user!.email!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (profile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.xxs),
                        child: Text(
                          switch (profile.role) {
                            UserRole.admin => l10n.roleAdmin,
                            UserRole.teacher => l10n.roleTeacher,
                            UserRole.learner => l10n.roleLearner,
                          },
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          if (profile?.isStaff ?? false) ...[
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.school_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(l10n.teacherConsole),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.teach),
              ),
            ),
            const SizedBox(height: Space.md),
          ],
          if (sync != null && !sync.isClean)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text(
                sync.rejected > 0
                    ? l10n.syncRejected(sync.rejected)
                    : l10n.syncPending(sync.pending),
              ),
            ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            onTap: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
