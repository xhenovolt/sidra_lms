import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';
import 'package:sidra_lms/features/profile/data/profile_repository.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_postgres_api.dart';
import '../helpers/test_app.dart';

FakePostgresApi staffServer(String role) {
  final api = emptyServer();
  api.rpcHandlers['ensure_profile'] = (_) => {
    'id': 'u1',
    'role': role == 'superadmin' ? 'admin' : role,
    'is_superadmin': role == 'superadmin',
  };
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
  api.rpcHandlers['admin_create_user'] = (p) => {'id': 'new'};
  api.rpcHandlers['review_lesson'] = (p) => {
    'review': {'id': 'r1'},
    'unlocked_lesson_id': p['p_unlock_next'] == true ? 'l2' : null,
  };
  return api;
}

Future<void> openConsole(WidgetTester tester, FakePostgresApi api) async {
  await tester.pumpWidget(
    await buildTestApp(
      FakeAuthService(const AuthSession.signedIn(testUser)),
      api: api,
    ),
  );
  await tester.pumpAndSettle();
  final context = tester.element(find.byType(NavigationBar));
  GoRouter.of(context).push('/teach');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('learners cannot use the console', (tester) async {
    await openConsole(tester, staffServer('learner'));
    expect(find.text("You don't have permission for this."), findsOneWidget);
  });

  testWidgets('teacher reviews a learner and opens the next lesson', (
    tester,
  ) async {
    final api = staffServer('teacher');
    await openConsole(tester, api);

    expect(find.text('Waiting for your review'), findsOneWidget);
    expect(find.text('Bilal'), findsOneWidget);
    expect(find.text('Books'), findsNothing, reason: 'admin-only tab');

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

  testWidgets('admin sees overview, books and people', (tester) async {
    await openConsole(tester, staffServer('admin'));
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('12'), findsOneWidget); // learners stat
    expect(find.text('Books'), findsOneWidget);
    expect(find.text('People'), findsOneWidget);
  });

  testWidgets('superadmin adds a teacher and gets a temporary password', (
    tester,
  ) async {
    final api = staffServer('superadmin');
    await openConsole(tester, api);
    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    expect(find.text('Hamuza Ibrahim'), findsOneWidget);
    expect(find.textContaining('Superadmin'), findsOneWidget);

    await tester.tap(find.text('Add person').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name *'),
      'Ustadh Ali',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'ustadh_ali',
    );
    // Admin role is offered to superadmins.
    await tester.tap(find.byType(DropdownButtonFormField<UserRole>));
    await tester.pumpAndSettle();
    expect(find.text('Administrator').last, findsOneWidget);
    await tester.tap(find.text('Teacher').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final call = api.rpcCalls.lastWhere((c) => c.$1 == 'admin_create_user');
    expect(call.$2['p_display_name'], 'Ustadh Ali');
    expect(call.$2['p_role'], 'teacher');
    expect(call.$2['p_username'], 'ustadh_ali');
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
}
