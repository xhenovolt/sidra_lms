import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/cache_first.dart';
import '../../../core/data/data_providers.dart';
import '../../../core/notifications/phone_notifications.dart'
    show signOutEverywhere;
import '../../../core/data/repository_providers.dart' show profileProvider;
import '../../../core/payments/direct_payments.dart'
    show marzPayConfirmLoopProvider;
import '../../../shared/widgets/user_avatar.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/sidra_mark.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/presentation/auth_providers.dart';
import 'admin_common.dart';

/// What the signed-in console user may do (from their roles). Cached on the
/// device so the drawer renders offline; PostgreSQL re-checks every action.
///
/// The saved copy is shown at once and refreshed in the background, so the
/// bottom bar and menu never wait for the internet.
final myPermissionsProvider = StreamProvider<Set<String>>((ref) {
  final userId = ref.watch(authSessionProvider.select((s) => s.user?.id));
  if (userId == null) return Stream.value(const {});
  return cacheFirst<Set<String>>(
    ref,
    key: 'permissions:$userId',
    fetch: () => ref.read(adminRepositoryProvider).myPermissions(),
    encode: (v) => v.toList(),
    decode: (j) => {for (final p in j! as List) p as String},
  );
});

/// Before permissions have ever been loaded on this phone (first sign-in
/// while offline), show what the role normally has. Display only: the
/// database checks every action.
Set<String> fallbackPermissions(bool superadmin) =>
    {
      for (final d in [...adminTabs, ...adminSections.expand((s) => s.items)])
        ...d.anyOf,
    }..removeAll(
      superadmin ? const <String>{} : const {'admins.manage', 'roles.manage'},
    );

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
    AdminDestination(
      Routes.adminReports,
      Icons.insights_outlined,
      (l) => l.reportsTitle,
      {'reports.view'},
    ),
    AdminDestination(
      Routes.adminTeaching,
      Icons.co_present_outlined,
      (l) => l.navTeaching,
      {'teaching.review'},
    ),
    AdminDestination(
      Routes.adminCorrections,
      Icons.school_outlined,
      (l) => l.correctionLibrary,
      {'teaching.review', 'content.upload'},
    ),
    AdminDestination(
      Routes.adminLibrary,
      Icons.perm_media_outlined,
      (l) => l.libraryTitle,
      {'content.upload', 'courses.view'},
    ),
    AdminDestination(
      Routes.adminSubmissions,
      Icons.inbox_outlined,
      (l) => l.subTitle,
      {'teaching.review'},
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
  AdminSection((l) => l.drawerFinance, [
    AdminDestination(
      Routes.adminFinance,
      Icons.account_balance_wallet_outlined,
      (l) => l.lgFinanceHome,
      {'finance.view'},
    ),
    AdminDestination(
      Routes.adminFinancePayments,
      Icons.payments_outlined,
      (l) => l.lgPaymentsPage,
      {'finance.view'},
    ),
    AdminDestination(
      Routes.adminAccounts,
      Icons.account_tree_outlined,
      (l) => l.lgAccounts,
      {'finance.view'},
    ),
    AdminDestination(
      Routes.adminJournal,
      Icons.menu_book_outlined,
      (l) => l.lgJournal,
      {'finance.view'},
    ),
    AdminDestination(
      Routes.adminBills,
      Icons.request_page_outlined,
      (l) => l.lgBills,
      {'finance.view'},
    ),
    AdminDestination(
      Routes.adminAssets,
      Icons.chair_outlined,
      (l) => l.lgAssets,
      {'finance.view'},
    ),
    AdminDestination(
      Routes.adminFinanceReports,
      Icons.insights_outlined,
      (l) => l.lgReports,
      {'finance.view'},
    ),
    AdminDestination(
      Routes.adminCounts,
      Icons.calculate_outlined,
      (l) => l.lgCounts,
      {'finance.view'},
    ),
    AdminDestination(
      Routes.testTransactions,
      Icons.swap_vert,
      (l) => l.ttTitle,
      {'payments.test'},
    ),
  ]),
  AdminSection((l) => l.drawerOversight, [
    AdminDestination(
      Routes.adminAudit,
      Icons.history,
      (l) => l.drawerActivity,
      {'audit.view'},
    ),
    AdminDestination(
      Routes.adminSettings,
      Icons.settings_outlined,
      (l) => l.drawerSettings,
      {'settings.manage'},
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

/// Bottom-bar tabs for the console on phones, in priority order; the first
/// four the user may open are shown, then **More** (which opens the drawer).
final adminTabs = <AdminDestination>[
  AdminDestination(
    Routes.adminDashboard,
    Icons.dashboard_outlined,
    (l) => l.navDashboard,
    {'dashboard.view'},
  ),
  AdminDestination(
    Routes.adminCourses,
    Icons.library_books_outlined,
    (l) => l.adminTabCourses,
    {'courses.view', 'curriculum.edit'},
  ),
  AdminDestination(
    Routes.adminPeopleLearners,
    Icons.school_outlined,
    (l) => l.adminStatLearners,
    {'learners.view'},
  ),
  AdminDestination(
    Routes.adminFinance,
    Icons.account_balance_wallet_outlined,
    (l) => l.drawerFinance,
    {'finance.view'},
  ),
  AdminDestination(
    Routes.adminLearners,
    Icons.rate_review_outlined,
    (l) => l.navReview,
    {'teaching.review', 'courses.view'},
  ),
  AdminDestination(
    Routes.adminPeopleTeachers,
    Icons.co_present_outlined,
    (l) => l.adminStatTeachers,
    {'teachers.view'},
  ),
  AdminDestination(Routes.adminAudit, Icons.history, (l) => l.drawerActivity, {
    'audit.view',
  }),
];

/// Admin console frame.
///
/// Phones: the Sidra name on top, tabs at the bottom (the last one, More,
/// opens the drawer with every page). Both bars slide away while scrolling
/// down and come back on scrolling up, like Facebook.
/// Wide screens: a permanent drawer beside the page.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final _scaffold = GlobalKey<ScaffoldState>();
  bool _barsVisible = true;

  @override
  void didUpdateWidget(AdminShell old) {
    super.didUpdateWidget(old);
    // A new page starts with the bars showing.
    if (old.location != widget.location) _barsVisible = true;
  }

  /// How far the finger has moved one way since the bars last changed.
  double _drag = 0;

  void _showBars(bool show) {
    _drag = 0;
    if (show != _barsVisible) setState(() => _barsVisible = show);
  }

  /// Hides the bars while reading down a long page, shows them on the way
  /// back up. Showing / hiding them resizes the page, so:
  ///  * only the page's own list counts (not lists inside it);
  ///  * it takes a deliberate drag (48 px), not the wobble of a tap;
  ///  * near the END of the page nothing changes — otherwise the page
  ///    shifts under the finger and the last items (Sign out!) can't be
  ///    tapped: the bug this replaces.
  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || n.depth != 0) return false;
    if (n is ScrollUpdateNotification && n.dragDetails != null) {
      final m = n.metrics;
      if (m.pixels <= m.minScrollExtent + 8) {
        _showBars(true); // back at the top
      } else if (m.extentAfter > 160) {
        _drag += n.scrollDelta ?? 0;
        if (_drag > 48) {
          _showBars(false);
        } else if (_drag < -48) {
          _showBars(true);
        }
      }
    } else if (n is ScrollEndNotification) {
      _drag = 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncSchedulerProvider);
    final l10n = AppLocalizations.of(context);
    final perms = ref.watch(myPermissionsProvider);
    if (perms.value?.contains('finance.verify_payment') ?? false) {
      ref.watch(marzPayConfirmLoopProvider);
    }
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final location = widget.location;

    // The most specific page (/admin/finance/bills before /admin/finance).
    final current =
        (adminSections
                .expand((s) => s.items)
                .where((d) => location.startsWith(d.path))
                .toList()
              ..sort((a, b) => b.path.length.compareTo(a.path.length)))
            .firstOrNull;

    // Saved permissions (or the role's usual ones on a phone that has never
    // loaded them): the bar and menu never wait for the internet.
    final superadmin = ref.watch(
      authSessionProvider.select((s) => s.user?.isSuperadmin ?? false),
    );
    final permSet = perms.value ?? fallbackPermissions(superadmin);
    final drawer = _AdminDrawer(
      permissions: permSet,
      location: location,
      closeOnTap: !wide,
    );

    final page = perms.hasValue && current != null && !allowed(current, permSet)
        ? EmptyView(icon: Icons.lock_outline, title: l10n.adminNotAllowed)
        : widget.child;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(width: 280, child: drawer),
            const VerticalDivider(width: 1),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(current?.label(l10n) ?? l10n.appName),
                  automaticallyImplyLeading: false,
                  actions: const [
                    _AccountMenu(),
                    SizedBox(width: Space.sm),
                  ],
                ),
                body: page,
              ),
            ),
          ],
        ),
      );
    }

    final tabs = [
      for (final t in adminTabs)
        if (allowed(t, permSet)) t,
    ].take(4).toList();
    final tabIndex = tabs.indexWhere((t) => location.startsWith(t.path));
    // Pages reached from the drawer highlight More.
    final selected = tabIndex >= 0 ? tabIndex : tabs.length;
    // The page's own name, for pages that are not a tab.
    // (also a page inside a tab, e.g. Finance › Bills).
    final subtitle = tabIndex < 0 || tabs[tabIndex].path != current?.path
        ? current?.label(l10n)
        : null;

    return Scaffold(
      key: _scaffold,
      drawer: drawer,
      appBar: _HidingTopBar(
        visible: _barsVisible,
        title: _BrandTitle(subtitle: subtitle),
        actions: const [
          _AccountMenu(),
          SizedBox(width: Space.xs),
        ],
        leading: tabs.isEmpty
            ? IconButton(
                tooltip: l10n.navMore,
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffold.currentState?.openDrawer(),
              )
            : null,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: page,
      ),
      // NavigationBar needs two items; with no tabs (permissions still
      // loading, or a role with none) the drawer opens from the top bar.
      bottomNavigationBar: tabs.isEmpty
          ? null
          : _Collapse(
              visible: _barsVisible,
              alignment: Alignment.topCenter,
              child: NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (i) {
                  if (i == tabs.length) {
                    _scaffold.currentState?.openDrawer();
                  } else {
                    context.go(tabs[i].path);
                  }
                },
                destinations: [
                  for (final t in tabs)
                    NavigationDestination(
                      icon: Icon(t.icon),
                      label: t.label(l10n),
                    ),
                  NavigationDestination(
                    icon: const Icon(Icons.menu),
                    label: l10n.navMore,
                  ),
                ],
              ),
            ),
    );
  }
}

/// Sidra's name and mark, as the console's title (like Facebook's wordmark).
class _BrandTitle extends StatelessWidget {
  const _BrandTitle({this.subtitle});
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        const SidraMark(size: 30),
        const SizedBox(width: Space.sm),
        Text(
          l10n.appName,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: Space.sm),
          Flexible(
            child: Text(
              '· $subtitle',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The top bar, which slides up out of view when [visible] is false. The
/// status-bar area stays covered so page content never runs under it.
class _HidingTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _HidingTopBar({
    required this.visible,
    required this.title,
    this.leading,
    this.actions,
  });
  final bool visible;
  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top),
          _Collapse(
            visible: visible,
            alignment: Alignment.bottomCenter,
            child: AppBar(
              primary: false,
              automaticallyImplyLeading: false,
              titleSpacing: Space.md,
              title: title,
              leading: leading,
              actions: actions,
            ),
          ),
        ],
      ),
    );
  }
}

/// The account menu in the top bar: sign out is always one tap away, on
/// every page, never at the bottom of a long list.
class _AccountMenu extends ConsumerWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authSessionProvider).user;
    return PopupMenuButton<String>(
      tooltip: l10n.accountMenu,
      // (not MyAvatar: that one opens the photo editor on tap)
      icon: UserAvatar(
        avatarUrl: ref.watch(profileProvider).value?.avatarUrl,
        name: user?.displayName,
        radius: 15,
      ),
      onSelected: (v) async {
        switch (v) {
          case 'password':
            await context.push(Routes.changePassword);
          case 'signout':
            await signOutEverywhere(ref);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            user?.displayName ?? '',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'password',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.key_outlined),
            title: Text(l10n.authChangePassword),
          ),
        ),
        PopupMenuItem(
          value: 'signout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.signOut,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows [child] fully, or shrinks it to nothing, with a short slide.
class _Collapse extends StatelessWidget {
  const _Collapse({
    required this.visible,
    required this.alignment,
    required this.child,
  });
  final bool visible;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: visible ? 1 : 0),
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOut,
    child: child,
    builder: (context, factor, child) => ClipRect(
      child: Align(alignment: alignment, heightFactor: factor, child: child),
    ),
  );
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
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xs),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.logout, color: theme.colorScheme.error),
                title: Text(
                  l10n.signOut,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  if (closeOnTap) Navigator.of(context).pop();
                  signOutEverywhere(ref);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
