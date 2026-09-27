import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../profile/data/profile_repository.dart';
import 'people_tab.dart';

/// A staff tab page with its own title bar.
class StaffPage extends StatelessWidget {
  const StaffPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: child,
  );
}

/// "More" for teachers and admins: account, extra tools, sign out.
/// (Staff are not learners, so they get this instead of the learner Profile.)
class StaffMoreScreen extends ConsumerWidget {
  const StaffMoreScreen({super.key, this.embedded = false});

  /// Inside the admin console the shell already shows a title bar.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider).user;
    final sync = ref.watch(syncStatusProvider).value;
    final role = UserRole.values.asNameMap()[user?.role] ?? UserRole.learner;

    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(l10n.navMore)),
      body: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  (user?.displayName ?? '?').characters.first.toUpperCase(),
                ),
              ),
              title: Text(user?.displayName ?? ''),
              subtitle: Text(
                [
                  roleLabel(
                    l10n,
                    role,
                    superadmin: user?.isSuperadmin ?? false,
                  ),
                  ?user?.identifier,
                ].join(' · '),
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          if (role == UserRole.teacher)
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: Text(l10n.subTitle),
              subtitle: Text(l10n.subTeacherHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.teachSubmissions),
            ),
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: Text(l10n.moreBrowseCatalogue),
            subtitle: Text(l10n.moreBrowseCatalogueHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.catalogue),
          ),
          if (sync != null && !sync.isClean)
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text(
                sync.rejected > 0
                    ? l10n.syncRejected(sync.rejected)
                    : l10n.syncPending(sync.pending),
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: Text(l10n.authChangePassword),
            onTap: () => context.push(Routes.changePassword),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.notificationsTitle),
            onTap: () => context.push(Routes.notifications),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutTitle),
            onTap: () => context.push(Routes.about),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            onTap: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
