import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/data_providers.dart';
import '../../l10n/app_localizations.dart';

/// One bottom-navigation destination.
typedef NavItem = ({IconData icon, IconData selectedIcon, String label});

/// Bottom-navigation shell. Each role gets its own set of [items] (learner,
/// teacher, admin); switches to a navigation rail on wide screens.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell, required this.items});

  final StatefulNavigationShell shell;
  final List<NavItem> Function(AppLocalizations l10n) items;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps background sync running while signed in.
    ref.watch(syncSchedulerProvider);
    final nav = items(AppLocalizations.of(context));

    final wide = MediaQuery.sizeOf(context).width >= 840;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final n in nav)
                  NavigationRailDestination(
                    icon: Icon(n.icon),
                    selectedIcon: Icon(n.selectedIcon),
                    label: Text(n.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _select,
        destinations: [
          for (final n in nav)
            NavigationDestination(
              icon: Icon(n.icon),
              selectedIcon: Icon(n.selectedIcon),
              label: n.label,
            ),
        ],
      ),
    );
  }
}

List<NavItem> learnerNav(AppLocalizations l10n) => [
  (icon: Icons.home_outlined, selectedIcon: Icons.home, label: l10n.navHome),
  (
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
    label: l10n.navMyLearning,
  ),
  (
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
    label: l10n.navExplore,
  ),
  (
    icon: Icons.download_for_offline_outlined,
    selectedIcon: Icons.download_for_offline,
    label: l10n.navDownloads,
  ),
  (
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: l10n.navProfile,
  ),
];

List<NavItem> teacherNav(AppLocalizations l10n) => [
  (
    icon: Icons.rate_review_outlined,
    selectedIcon: Icons.rate_review,
    label: l10n.adminTabLearners,
  ),
  (
    icon: Icons.library_books_outlined,
    selectedIcon: Icons.library_books,
    label: l10n.adminTabCourses,
  ),
  (icon: Icons.more_horiz, selectedIcon: Icons.more_horiz, label: l10n.navMore),
];

List<NavItem> adminNav(AppLocalizations l10n) => [
  (
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: l10n.navDashboard,
  ),
  (
    icon: Icons.rate_review_outlined,
    selectedIcon: Icons.rate_review,
    label: l10n.adminTabLearners,
  ),
  (
    icon: Icons.library_books_outlined,
    selectedIcon: Icons.library_books,
    label: l10n.adminTabCourses,
  ),
  (
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups,
    label: l10n.adminTabPeople,
  ),
  (icon: Icons.more_horiz, selectedIcon: Icons.more_horiz, label: l10n.navMore),
];
