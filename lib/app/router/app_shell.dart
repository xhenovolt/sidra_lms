import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/data_providers.dart';
import '../../l10n/app_localizations.dart';

/// Bottom-navigation shell for the five primary learner sections.
/// Switches to a navigation rail on wide screens (tablets, desktop, web).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps background sync running while signed in.
    ref.watch(syncSchedulerProvider);
    final l10n = AppLocalizations.of(context);
    final items = [
      (Icons.home_outlined, Icons.home, l10n.navHome),
      (Icons.menu_book_outlined, Icons.menu_book, l10n.navMyLearning),
      (Icons.explore_outlined, Icons.explore, l10n.navExplore),
      (
        Icons.download_for_offline_outlined,
        Icons.download_for_offline,
        l10n.navDownloads,
      ),
      (Icons.person_outline, Icons.person, l10n.navProfile),
    ];

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
                for (final (icon, selected, label) in items)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
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
          for (final (icon, selected, label) in items)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}
