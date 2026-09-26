import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_postgres_api.dart';
import 'teacher_console_test.dart' show signInAs, staffServer;

FakePostgresApi peopleServer({int learners = 3}) {
  final api = staffServer('admin');
  api.rpcHandlers['admin_list_users'] = (_) => [
    for (var i = 1; i <= learners; i++)
      {
        'id': 'l$i',
        'display_name': 'Learner $i',
        'phone': '+2567000000$i',
        'role': 'learner',
        'is_active': true,
      },
  ];
  api.rpcHandlers['admin_person_profile'] = (p) => {
    'user': {
      'id': p['p_user_id'],
      'display_name': 'Learner 1',
      'phone': '+25670000001',
      'role': 'learner',
      'is_active': true,
      'created_at': '2026-09-01T08:00:00Z',
      'last_sign_in': null,
      'roles': <Object>[],
    },
    'enrolments': [
      {
        'id': 'e1',
        'course_id': 'c1',
        'course_title': 'Quran for Beginners',
        'status': 'active',
        'source': 'admin_grant',
        'completed_lessons': 3,
        'total_lessons': 12,
        'enrolled_at': '2026-09-02T08:00:00Z',
      },
    ],
    'teaching': <Object>[],
    'reviews': [
      {
        'lesson_title': 'Alif to Ya',
        'course_title': 'Quran for Beginners',
        'outcome': 'passed',
        'teacher': 'Ustadh Musa',
        'feedback': 'Clear makharij',
        'created_at': '2026-09-10T08:00:00Z',
      },
    ],
    'quiz_attempts': <Object>[],
    'activity': <Object>[],
  };
  return api;
}

Future<void> goTo(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('people lists page from the server', (tester) async {
    final api = peopleServer(learners: 35);
    await signInAs(tester, 'admin', api: api);
    await goTo(tester, '/admin/people/learners');

    expect(find.text('Showing 30 of 35'), findsOneWidget);
    final first = api.rpcCalls.lastWhere((c) => c.$1 == 'admin_people');
    expect(first.$2['p_persona'], 'learner');
    expect(first.$2['p_offset'], 0);

    await tester.scrollUntilVisible(
      find.text('Load more'),
      500,
      scrollable: find
          .descendant(
            of: find.byType(RefreshIndicator),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 35 of 35'), findsOneWidget);
    expect(
      api.rpcCalls.lastWhere((c) => c.$1 == 'admin_people').$2['p_offset'],
      30,
    );
  });

  testWidgets('search and status filters go to the server', (tester) async {
    final api = peopleServer();
    await signInAs(tester, 'admin', api: api);
    await goTo(tester, '/admin/people/learners');

    await tester.enterText(find.byType(TextField).first, 'learner 2');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Learner 2'), findsOneWidget);
    expect(find.text('Learner 1'), findsNothing);
    expect(
      api.rpcCalls.lastWhere((c) => c.$1 == 'admin_people').$2['p_search'],
      'learner 2',
    );

    await tester.tap(find.widgetWithText(FilterChip, 'Disabled'));
    await tester.pumpAndSettle();
    expect(
      api.rpcCalls.lastWhere((c) => c.$1 == 'admin_people').$2['p_active'],
      isFalse,
    );
    expect(find.text('No one found'), findsOneWidget);
  });

  testWidgets('tapping a person opens their record', (tester) async {
    final api = peopleServer();
    await signInAs(tester, 'admin', api: api);
    await goTo(tester, '/admin/people/learners');

    await tester.tap(find.text('Learner 1'));
    await tester.pumpAndSettle();
    expect(find.text('Quran for Beginners'), findsOneWidget);
    expect(find.textContaining('3 of 12 lessons done'), findsOneWidget);
    expect(find.text('Has not signed in yet'), findsOneWidget);
    expect(find.textContaining('Clear makharij'), findsOneWidget);
    expect(find.text('Actions'), findsOneWidget);
  });
}
