import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_postgres_api.dart';
import '../helpers/test_app.dart';

FakePostgresApi staffServer(String role) {
  final api = emptyServer();
  api.rpcHandlers['ensure_profile'] = (_) => {'id': 'u1', 'role': role};
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

  testWidgets('admin sees books and people management', (tester) async {
    await openConsole(tester, staffServer('admin'));
    expect(find.text('Books'), findsOneWidget);
    expect(find.text('People'), findsOneWidget);
  });
}
