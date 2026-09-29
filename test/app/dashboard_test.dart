import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'teacher_console_test.dart' show signInAs, staffServer;

void main() {
  testWidgets('dashboard: organisation numbers open the people behind them', (
    tester,
  ) async {
    final api = staffServer('admin');
    api.rpcHandlers['admin_overview'] = (_) => {
      'learners': 3,
      'learners_in_courses': 2,
      'course_places': 4,
      'active_learners_7d': 2,
      'lessons_completed_7d': 5,
      'teachers': 1,
      'admins': 1,
      'courses_published': 2,
      'courses_draft': 0,
      'courses_in_review': 0,
    };
    api.rpcHandlers['dashboard_list'] = (p) =>
        p['p_kind'] == 'active_learners_7d'
        ? [
            {'title': 'Aisha', 'user_id': 'a', 'at': '2026-09-29T08:00:00Z'},
            {'title': 'Bilal', 'user_id': 'b', 'at': '2026-09-28T08:00:00Z'},
          ]
        : [];
    api.rpcHandlers['learners_at_a_glance'] = (_) => [
      {
        'user_id': 'a',
        'display_name': 'Aisha',
        'courses': [
          {'title': 'Yassarna', 'done': 3, 'total': 10},
        ],
        'last_used': DateTime.now().toUtc().toIso8601String(),
        'late_work': 1,
        'open_reports': 0,
        'suspended': false,
      },
    ];
    await signInAs(tester, 'admin', api: api);

    expect(find.textContaining('at a glance'), findsWidgets);
    expect(find.text('Learners in courses'), findsOneWidget);
    expect(find.textContaining('Course places'), findsOneWidget);

    // The learner list: courses with progress, last use, late work.
    await tester.scrollUntilVisible(
      find.text('Yassarna 3/10'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1 late'), findsOneWidget);

    // Tapping a number opens exactly the people it counts.
    await tester.ensureVisible(find.text('Active learners (7 days)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Active learners (7 days)'));
    await tester.pumpAndSettle();
    expect(find.text('2 in this list'), findsOneWidget);
    expect(find.text('Aisha'), findsOneWidget);
    expect(find.text('Bilal'), findsOneWidget);
  });
}
