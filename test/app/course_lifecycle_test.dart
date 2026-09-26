import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_postgres_api.dart';
import 'teacher_console_test.dart' show signInAs, staffServer;

/// An admin console with one course in [status] and the given readiness.
FakePostgresApi lifecycleServer({
  required String status,
  List<Map<String, dynamic>> errors = const [],
  List<Map<String, dynamic>> warnings = const [],
  String? reviewNote,
  String? publishedAt,
}) {
  final api = staffServer('admin');
  api.selectHandlers['courses'] = (_) => [
    {
      'id': 'c1',
      'slug': 'quran-beginners',
      'title': 'Quran for Beginners',
      'subject': 'Quran',
      'status': status,
      'review_note': reviewNote,
      'published_at': publishedAt,
    },
  ];
  api.rpcHandlers['course_publish_check'] = (_) => {
    'errors': errors,
    'warnings': warnings,
    'published_lessons': errors.isEmpty ? 3 : 0,
  };
  api.rpcHandlers['course_people'] = (_) => const [];
  api.rpcHandlers['set_course_status'] = (p) => {'id': 'c1'};
  return api;
}

Future<void> openCourse(WidgetTester tester, FakePostgresApi api) async {
  await signInAs(tester, 'admin', api: api);
  GoRouter.of(tester.element(find.byType(Scaffold).first))
      .go('/teach/courses/c1');
  await tester.pumpAndSettle();
}

Finder builderScrollable() => find
    .descendant(
      of: find.byType(RefreshIndicator),
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  testWidgets('a ready draft can be published; warnings are listed', (
    tester,
  ) async {
    final api = lifecycleServer(
      status: 'draft',
      warnings: [
        {'code': 'no_teacher'},
        {'code': 'draft_lessons', 'count': 2},
      ],
    );
    await openCourse(tester, api);

    expect(find.text('Ready to publish'), findsOneWidget);
    expect(find.textContaining('Assign a teacher'), findsOneWidget);
    expect(find.text('2 lessons are still drafts'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Delete course'),
      300,
      scrollable: builderScrollable(),
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Publish'),
      -300,
      scrollable: builderScrollable(),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Publish'));
    await tester.pumpAndSettle();
    final call = api.rpcCalls.lastWhere((c) => c.$1 == 'set_course_status');
    expect(call.$2['p_course_id'], 'c1');
    expect(call.$2['p_status'], 'published');
  });

  testWidgets('blocking problems disable publishing and review', (
    tester,
  ) async {
    final api = lifecycleServer(
      status: 'draft',
      errors: [
        {'code': 'no_published_lessons'},
      ],
    );
    await openCourse(tester, api);

    expect(find.text('Before publishing:'), findsOneWidget);
    expect(find.text('Publish at least one lesson'), findsOneWidget);
    final publish = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Publish'),
    );
    expect(publish.onPressed, isNull);
    final submit = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Submit for review'),
    );
    expect(submit.onPressed, isNull);
  });

  testWidgets('a reviewer sends a course back with feedback', (tester) async {
    final api = lifecycleServer(
      status: 'in_review',
      reviewNote: 'Please check lesson 3',
    );
    await openCourse(tester, api);

    expect(find.text('In review'), findsWidgets);
    expect(find.textContaining('Please check lesson 3'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Return to draft'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Add the audio');
    await tester.tap(find.widgetWithText(FilledButton, 'Return to draft'));
    await tester.pumpAndSettle();

    final call = api.rpcCalls.lastWhere((c) => c.$1 == 'set_course_status');
    expect(call.$2['p_status'], 'draft');
    expect(call.$2['p_note'], 'Add the audio');
  });

  testWidgets('published courses are archived, not deleted', (tester) async {
    final api = lifecycleServer(
      status: 'published',
      publishedAt: '2026-09-01T08:00:00Z',
    );
    await openCourse(tester, api);

    await tester.fling(builderScrollable(), const Offset(0, -4000), 3000);
    await tester.pumpAndSettle();
    expect(find.text('Delete course'), findsNothing);
    await tester.fling(builderScrollable(), const Offset(0, 4000), 3000);
    await tester.pumpAndSettle();
    expect(find.textContaining('Visible to learners'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Archive'));
    await tester.pumpAndSettle();
    expect(find.text('Archive this course?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
    await tester.pumpAndSettle();

    final call = api.rpcCalls.lastWhere((c) => c.$1 == 'set_course_status');
    expect(call.$2['p_status'], 'archived');
  });
}
