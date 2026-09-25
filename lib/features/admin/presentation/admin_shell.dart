import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/sidra_mark.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/presentation/auth_providers.dart';
import 'admin_common.dart';

/// What the signed-in console user may do (from their roles). Cached on the
/// device so the drawer renders offline; PostgreSQL re-checks every action.
final myPermissionsProvider = FutureProvider<Set<String>>((ref) async {
  final userId = ref.watch(authSessionProvider.select((s) => s.user?.id));
  if (userId == null) return const {};
  final local = await ref.watch(localDatabaseProvider.future);
  try {
    final perms = await ref.watch(adminRepositoryProvider).myPermissions();
    await local.setKv('permissions', jsonEncode(perms.toList()));
    return perms;
  } catch (_) {
    final cached = await local.getKv('permissions');
    if (cached == null) rethrow;
    return {for (final p in jsonDecode(cached) as List) p as String};
  }
});

/// One drawer destination, shown when the user has any of [anyOf].
class AdminDestination {
  const AdminDestination(this.path, this.icon, this.label, this.anyOf);
  final String path;
  final IconData icon;
  final String Function(AppLocalizations) label;
  final Set<String> anyOf;
}

class AdminSection {
  const AdminSection(this.title, this.items);
  final String Function(AppLocalizations)? title;
  final List<AdminDestination> items;
}

final adminSections = <AdminSection>[
  AdminSection(null, [
    AdminDestination(
      Routes.adminDashboard,
      Icons.dashboard_outlined,
      (l) => l.navDashboard,
      {'dashboard.view'},
    ),
  ]),
  AdminSection((l) => l.drawerAcademic, [
    AdminDestination(
      Routes.adminCourses,
      Icons.library_books_outlined,
      (l) => l.adminTabCourses,
      {'courses.view', 'curriculum.edit'},
    ),
    AdminDestination(
      Routes.adminBooks,
      Icons.menu_book_outlined,
      (l) => l.booksTitle,
      {'books.manage'},
    ),
  ]),
  AdminSection((l) => l.drawerTeaching, [
    AdminDestination(
      Routes.adminLearners,
      Icons.rate_review_outlined,
      (l) => l.drawerReview,
      {'teaching.review', 'courses.view'},
    ),
  ]),
  AdminSection((l) => l.drawerPeople, [
    AdminDestination(
      Routes.adminPeopleLearners,
      Icons.school_outlined,
      (l) => l.adminStatLearners,
      {'learners.view'},
    ),
    AdminDestination(
      Routes.adminPeopleTeachers,
      Icons.co_present_outlined,
      (l) => l.adminStatTeachers,
      {'teachers.view'},
    ),
    AdminDestination(
      Routes.adminPeopleAdmins,
      Icons.admin_panel_settings_outlined,
      (l) => l.adminStatAdmins,
      {'admins.manage'},
    ),
    AdminDestination(
      Routes.adminRoles,
      Icons.key_outlined,
      (l) => l.drawerRoles,
      {'roles.manage'},
    ),
  ]),
  AdminSection((l) => l.drawerOversight, [
    AdminDestination(
      Routes.adminAudit,
      Icons.history,
      (l) => l.drawerActivity,
      {'audit.view'},
    ),
  ]),
  AdminSection(null, [
    AdminDestination(
      Routes.adminMore,
      Icons.account_circle_outlined,
      (l) => l.drawerAccount,
      {},
    ),
  ]),
];

bool allowed(AdminDestination d, Set<String> perms) =>
    d.anyOf.isEmpty || d.anyOf.any(perms.contains);

/// Admin console frame: title bar + drawer (modal on phones, permanent on
/// wide screens). Pages are the router's child.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncSchedulerProvider);
    final l10n = AppLocalizations.of(context);
    final perms = ref.watch(myPermissionsProvider);
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    final current = adminSections
        .expand((s) => s.items)
        .where((d) => location.startsWith(d.path))
        .firstOrNull;

    final drawer = switch (perms) {
      AsyncData(:final value) => _AdminDrawer(
        permissions: value,
        location: location,
        closeOnTap: !wide,
      ),
      AsyncError() => const Drawer(child: SizedBox.shrink()),
      _ => const Drawer(child: LoadingView()),
    };

    final page = switch (perms) {
      AsyncData(:final value)
          when current != null && !allowed(current, value) =>
        EmptyView(icon: Icons.lock_outline, title: l10n.adminNotAllowed),
      AsyncError(:final error) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(myPermissionsProvider),
      ),
      _ => child,
    };

    final title = Text(current?.label(l10n) ?? l10n.appName);
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(width: 280, child: drawer),
            const VerticalDivider(width: 1),
            Expanded(
              child: Scaffold(
                appBar: AppBar(title: title, automaticallyImplyLeading: false),
                body: page,
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: title),
      drawer: drawer,
      body: page,
    );
  }
}

class _AdminDrawer extends ConsumerWidget {
  const _AdminDrawer({
    required this.permissions,
    required this.location,
    required this.closeOnTap,
  });

  final Set<String> permissions;
  final String location;
  final bool closeOnTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider).user;
    return Drawer(
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: Space.sm),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.sm,
                Space.md,
                Space.md,
              ),
              child: Row(
                children: [
                  const SidraMark(size: 36),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.appName, style: theme.textTheme.titleLarge),
                        Text(
                          user?.displayName ?? '',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (final section in adminSections)
              if (section.items.any((d) => allowed(d, permissions))) ...[
                if (section.title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.md,
                      Space.md,
                      Space.md,
                      Space.xs,
                    ),
                    child: Text(
                      section.title!(l10n).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                for (final d in section.items)
                  if (allowed(d, permissions))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                      child: ListTile(
                        dense: true,
                        selected: location.startsWith(d.path),
                        selectedTileColor: theme.colorScheme.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        leading: Icon(d.icon),
                        title: Text(d.label(l10n)),
                        onTap: () {
                          if (closeOnTap) Navigator.of(context).pop();
                          context.go(d.path);
                        },
                      ),
                    ),
              ],
          ],
        ),
      ),
    );
  }
}
