import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/phone_notifications.dart';

import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/data_providers.dart';
import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../admin/presentation/sessions_screens.dart' show DevicesScreen;
import '../../auth/presentation/auth_providers.dart';
import '../data/profile_repository.dart';
import 'avatar_editor.dart';
import '../../payments/presentation/receipts.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider).user;
    final profile = ref.watch(profileProvider).value;
    final sync = ref.watch(syncStatusProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          IconButton(
            tooltip: l10n.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () => signOutEverywhere(ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          Row(
            children: [
              const MyAvatar(),
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
                    if (user?.identifier != null)
                      Text(
                        user!.identifier!,
                        textDirection: TextDirection.ltr,
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
            leading: const Icon(Icons.report_problem_outlined),
            title: Text(l10n.issuesMine),
            subtitle: Text(l10n.issuesMineHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/learn/issues'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.key_outlined),
            title: Text(l10n.authChangePassword),
            onTap: () => context.push(Routes.changePassword),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.devices_outlined),
            title: Text(l10n.devicesMine),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DevicesScreen()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(l10n.rcMyPayments),
            subtitle: Text(l10n.rcMyPaymentsHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MyPaymentsScreen()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutTitle),
            onTap: () => context.push(Routes.about),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            onTap: () => signOutEverywhere(ref),
          ),
        ],
      ),
    );
  }
}
