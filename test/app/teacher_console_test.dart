import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sidra_lms/core/errors/app_failure.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_postgres_api.dart';
import '../helpers/test_app.dart';

const _adminPerms = [
  'dashboard.view',
  'courses.view',
  'courses.create',
  'courses.publish',
  'courses.archive',
  'curriculum.edit',
  'books.manage',
  'learners.view',
  'learners.create',
  'learners.edit',
  'teachers.view',
  'teachers.create',
  'teachers.assign',
  'enrolments.manage',
  'audit.view',
  'teaching.review',
];

/// What each test persona may do (mirrors the seeded roles in 0012).
List<String> permsFor(String role) => switch (role) {
  'superadmin' => [..._adminPerms, 'admins.manage', 'roles.manage'],
  'admin' => _adminPerms,
  'finance_officer' => ['dashboard.view', 'finance.view', 'learners.view'],
  'teacher' => ['teaching.review'],
  _ => const [],
};

/// The app persona behind a test role.
String personaOf(String role) => switch (role) {
  'superadmin' || 'finance_officer' => 'admin',
  _ => role,
};

FakePostgresApi staffServer(String role) {
  final api = emptyServer();
  api.rpcHandlers['ensure_profile'] = (_) => {
    'id': 'u1',
    'role': personaOf(role),
    'is_superadmin': role == 'superadmin',
  };
  api.rpcHandlers['my_permissions'] = (_) => [
    {'my_permissions': permsFor(role)},
  ];
  api.rpcHandlers['admin_roles'] = (_) => [
    for (final (key, name, persona) in [
      ('super_admin', 'Super Admin', 'admin'),
      ('admin', 'Admin', 'admin'),
      ('finance_officer', 'Finance Officer', 'admin'),
      ('teacher', 'Teacher', 'teacher'),
      ('learner', 'Learner', 'learner'),
    ])
      {
        'key': key,
        'name': name,
        'persona': persona,
        'is_system': true,
        'permissions': const <String>[],
        'members': 0,
      },
  ];
  api.selectHandlers['courses'] = (_) => [
    {
      'id': 'c1',
      'slug': 'quran',
      'title': 'Quran Intermediate',
      'subject': 'Quran',
      'status': 'published',
    },
  ];
  api.rpcHandlers['teacher_learners'] = (_) => [
    {
      'course_id': 'c1',
      'user_id': 'learner-1',
      'display_name': 'Bilal',
      'current_lesson_id': 'l1',
      'current_lesson_title': 'Al-Fatihah 1–3',
      'next_lesson_id': 'l2',
      'completed_lessons': 1,
      'total_lessons': 4,
      'awaiting_review': true,
    },
  ];
  api.rpcHandlers['admin_overview'] = (_) => {
    'learners': 12,
    'teachers': 2,
    'admins': 1,
    'courses_published': 3,
  };
  api.rpcHandlers['admin_list_users'] = (_) => [
    {
      'id': 'u1',
      'display_name': 'Hamuza Ibrahim',
      'phone': '+256741341483',
      'username': 'hamibra',
      'role': 'admin',
      'is_superadmin': true,
      'is_active': true,
    },
    {
      'id': 'u2',
      'display_name': 'Bilal',
      'phone': '+256700000009',
      'role': 'learner',
      'is_active': true,
    },
  ];
  // Server-side filtering and paging, like admin_people() in Postgres.
  api.rpcHandlers['admin_people'] = (p) {
    final all = [
      for (final r in api.rpcHandlers['admin_list_users']!(const {}) as List)
        Map<String, dynamic>.from(r as Map),
    ];
    final search = (p['p_search'] as String?)?.toLowerCase();
    final matches = [
      for (final r in all)
        if ((p['p_persona'] == null || r['role'] == p['p_persona']) &&
            (p['p_active'] == null || r['is_active'] == p['p_active']) &&
            (search == null ||
                (r['display_name'] as String).toLowerCase().contains(search)))
          r,
    ];
    final offset = p['p_offset'] as int? ?? 0;
    final limit = p['p_limit'] as int? ?? 50;
    return [
      for (final r in matches.skip(offset).take(limit))
        {...r, 'total': matches.length},
    ];
  };
  api.rpcHandlers['admin_create_user_with_role'] = (_) => {'id': 'new'};
  api.rpcHandlers['review_lesson'] = (p) => {
    'review': {'id': 'r1'},
    'unlocked_lesson_id': p['p_unlock_next'] == true ? 'l2' : null,
  };
  return api;
}

/// Signs in as [role] (learner | teacher | admin | superadmin |
/// finance_officer) and lands on that role's own home.
Future<void> signInAs(
  WidgetTester tester,
  String role, {
  FakePostgresApi? api,
  String userId = 'u1',
}) async {
  await tester.pumpWidget(
    await buildTestApp(
      FakeAuthService(
        AuthSession.signedIn(
          AppUser(
            id: userId,
            displayName: 'Hamuza Ibrahim',
            role: personaOf(role),
            isSuperadmin: role == 'superadmin',
          ),
        ),
      ),
      api: api ?? staffServer(role),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> navLabels(WidgetTester tester) => [
  for (final d in tester.widgetList<NavigationDestination>(
    find.byType(NavigationDestination),
  ))
    d.label,
];

Future<void> openDrawer(WidgetTester tester) async {
  // The last bottom tab, More, opens the drawer.
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('More'),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrolls the drawer until [text] is built and visible.
Future<void> scrollDrawerTo(WidgetTester tester, String text) =>
    tester.scrollUntilVisible(
      inDrawer(text),
      120,
      scrollable: find
          .descendant(
            of: find.byType(Drawer),
            matching: find.byType(Scrollable),
          )
          .first,
    );

Finder inDrawer(String text) =>
    find.descendant(of: find.byType(Drawer), matching: find.text(text));

void main() {
  testWidgets('learners and teachers get their own bottom navigation', (
    tester,
  ) async {
    await signInAs(tester, 'learner');
    expect(navLabels(tester), [
      'Home',
      'My Learning',
      'Explore',
      'Downloads',
      'Profile',
    ]);

    await signInAs(tester, 'teacher');
    expect(navLabels(tester), ['Teaching', 'Learners', 'Courses', 'More']);
  });

  testWidgets(
    'admin lands on the dashboard with a permission-filtered drawer',
    (tester) async {
      await signInAs(tester, 'admin');
      // Facebook-style: tabs at the bottom, the last one opens the drawer.
      expect(navLabels(tester), [
        'Dashboard',
        'Courses',
        'Learners',
        'Review',
        'More',
      ]);
      expect(find.text('Sidra'), findsOneWidget); // app name on top
      expect(find.text('12'), findsOneWidget); // learners stat

      await openDrawer(tester);
      for (final item in [
        'Dashboard',
        'Courses',
        'Books',
        'Review learners',
        'Learners',
        'Teachers',
        'Submitted work',
        'Activity log',
        'My account',
      ]) {
        await scrollDrawerTo(tester, item);
        expect(inDrawer(item), findsOneWidget, reason: item);
      }
      // Only superadmins manage administrators and roles.
      expect(inDrawer('Administrators'), findsNothing);
      expect(inDrawer('Roles & permissions'), findsNothing);
    },
  );

  testWidgets('superadmin also sees administrators and roles', (tester) async {
    await signInAs(tester, 'superadmin');
    await openDrawer(tester);
    await scrollDrawerTo(tester, 'Administrators');
    expect(inDrawer('Administrators'), findsOneWidget);
    await scrollDrawerTo(tester, 'Roles & permissions');
    expect(inDrawer('Roles & permissions'), findsOneWidget);
  });

  testWidgets('a finance officer sees only what the role allows', (
    tester,
  ) async {
    await signInAs(tester, 'finance_officer');
    expect(navLabels(tester), ['Dashboard', 'Learners', 'Finance', 'More']);
    await openDrawer(tester);
    expect(inDrawer('Dashboard'), findsOneWidget);
    expect(inDrawer('Learners'), findsOneWidget);
    expect(inDrawer('Courses'), findsNothing);
    expect(inDrawer('Books'), findsNothing);
    expect(inDrawer('Activity log'), findsNothing);
  });

  testWidgets('a page outside your permissions is refused', (tester) async {
    await signInAs(tester, 'finance_officer');
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/admin/books');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('a learner cannot open staff pages', (tester) async {
    await signInAs(tester, 'learner');
    final context = tester.element(find.byType(NavigationBar));
    GoRouter.of(context).go('/admin/people/learners');
    await tester.pumpAndSettle();
    expect(navLabels(tester), contains('Home'));
    expect(find.text('Add person'), findsNothing);
  });

  testWidgets('My account holds the catalogue, password and sign out', (
    tester,
  ) async {
    await signInAs(tester, 'admin');
    await openDrawer(tester);
    await scrollDrawerTo(tester, 'My account');
    await tester.pumpAndSettle();
    await tester.tap(inDrawer('My account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Administrator'), findsOneWidget);
    expect(find.text('Browse the catalogue'), findsOneWidget);
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('teacher reviews a learner and opens the next lesson', (
    tester,
  ) async {
    final api = staffServer('teacher');
    await signInAs(tester, 'teacher', api: api);

    await tester.tap(find.text('Learners').last);
    await tester.pumpAndSettle();
    expect(find.text('Waiting for your review'), findsOneWidget);
    expect(find.text('Bilal'), findsOneWidget);

    await tester.tap(find.text('Bilal'));
    await tester.pumpAndSettle();
    expect(find.text('Open the next lesson for this learner'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Beautiful tajweed');
    await tester.tap(find.text('Save review'));
    await tester.pumpAndSettle();

    final call = api.rpcCalls.lastWhere((c) => c.$1 == 'review_lesson');
    expect(call.$2['p_user_id'], 'learner-1');
    expect(call.$2['p_lesson_id'], 'l1');
    expect(call.$2['p_outcome'], 'passed');
    expect(call.$2['p_unlock_next'], isTrue);
    expect(call.$2['p_feedback'], 'Beautiful tajweed');
  });

  testWidgets('superadmin adds a finance officer with a temporary password', (
    tester,
  ) async {
    final api = staffServer('superadmin');
    await signInAs(tester, 'superadmin', api: api);
    await openDrawer(tester);
    await scrollDrawerTo(tester, 'Administrators');
    await tester.tap(inDrawer('Administrators'));
    await tester.pumpAndSettle();
    expect(find.text('Hamuza Ibrahim'), findsOneWidget);

    await tester.tap(find.text('Add person').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name *'),
      'Amina Finance',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'amina_fin',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    // Only administrator-level roles are offered on this list.
    expect(find.text('Teacher'), findsNothing);
    await tester.tap(find.text('Finance Officer').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final call = api.rpcCalls.lastWhere(
      (c) => c.$1 == 'admin_create_user_with_role',
    );
    expect(call.$2['p_display_name'], 'Amina Finance');
    expect(call.$2['p_role_key'], 'finance_officer');
    expect(call.$2['p_username'], 'amina_fin');
    expect(
      (call.$2['p_temporary_password'] as String).length,
      greaterThanOrEqualTo(8),
    );
    expect(find.text('Account created'), findsOneWidget);
    expect(
      find.text(call.$2['p_temporary_password'] as String),
      findsOneWidget,
    );
  });

  testWidgets(
    'the bars slide away while scrolling down and return on the way up',
    (tester) async {
      final api = staffServer('admin');
      api.rpcHandlers['admin_list_users'] = (_) => [
        for (var i = 0; i < 40; i++)
          {'id': 'p$i', 'display_name': 'Person $i', 'role': 'learner'},
      ];
      await signInAs(tester, 'admin', api: api);
      GoRouter.of(tester.element(find.byType(NavigationBar)))
          .go('/admin/people/learners');
      await tester.pumpAndSettle();
      double barHeight() => tester.getSize(find.byType(NavigationBar)).height;
      Finder list() => find
          .descendant(
            of: find.byType(RefreshIndicator),
            matching: find.byType(Scrollable),
          )
          .first;

      final shown = tester.getTopLeft(find.byType(NavigationBar)).dy;
      await tester.drag(list(), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byType(NavigationBar)).dy,
        greaterThan(shown),
        reason: 'bottom bar moved off screen',
      );
      expect(find.text('Sidra').hitTestable(), findsNothing);

      await tester.drag(list(), const Offset(0, 100));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(NavigationBar)).dy, shown);
      expect(barHeight(), greaterThan(0));
      expect(find.text('Sidra').hitTestable(), findsOneWidget);
    },
  );

  testWidgets(
    'if the menu cannot load, the drawer says so and keeps My account',
    (tester) async {
      final api = staffServer('admin');
      api.rpcHandlers['my_permissions'] = (_) =>
          throw const UnexpectedFailure('Database error');
      // A user never seen on this device: no cached menu to fall back on.
      await signInAs(tester, 'admin', api: api, userId: 'fresh-admin');
      // No tabs to show: the top bar offers the menu instead.
      expect(find.byType(NavigationBar), findsNothing);
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not load your menu'), findsOneWidget);
      expect(inDrawer('My account'), findsOneWidget);

      api.rpcHandlers['my_permissions'] = (_) => [
        {'my_permissions': permsFor('admin')},
      ];
      await tester.tap(inDrawer('Try again'));
      await tester.pumpAndSettle();
      expect(navLabels(tester), contains('More'));
    },
  );
}
