import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/test_app.dart';
import 'teacher_console_test.dart' show signInAs, staffServer;

Map<String, Object?> _portion({
  String status = 'opened',
  List<Object> attempts = const [],
}) => {
  'id': 'p1',
  'title': 'Page 12',
  'instructions': 'Read this page three times. Watch the shaddah.',
  'instruction_language': 'en',
  'course_title': 'Yassarna: Beginners',
  'group_name': 'Group A',
  'submission_types': ['audio'],
  'resources': <Object>[],
  'participation': {'status': status},
  'attempts': attempts,
};

void main() {
  testWidgets('learner: today\'s portion → task → record and send', (
    tester,
  ) async {
    final api = emptyServer();
    api.rpcHandlers['learner_today'] = (_) => [_portion()];
    api.rpcHandlers['open_portion'] = (_) => _portion();
    api.selectHandlers['languages'] = (_) => [
      {'code': 'en', 'name': 'English'},
    ];
    await tester.pumpWidget(
      await buildTestApp(
        FakeAuthService(const AuthSession.signedIn(testUser)),
        api: api,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Today\'s learning'), findsOneWidget);
    expect(find.text('Page 12'), findsOneWidget);
    await tester.tap(find.text('Page 12'));
    await tester.pumpAndSettle();
    expect(find.text('Your task'), findsOneWidget);
    expect(
      find.text('Read this page three times. Watch the shaddah.'),
      findsOneWidget,
    );
    expect(find.text('Taught in English'), findsOneWidget);
    expect(find.text('Record'), findsOneWidget);
    // Nothing to send until something is recorded.
    final send = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Send to teacher'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('learner sees the teacher\'s correction and can try again', (
    tester,
  ) async {
    final api = emptyServer();
    final p = _portion(
      status: 'correction_required',
      attempts: [
        {
          'id': 's1',
          'attempt': 1,
          'files': <Object>[],
          'reviews': [
            {
              'result': 'correction_required',
              'feedback': 'Repeat the second line.',
              'reviewer': 'Ustadh Musa',
              'correction': {
                'id': 'c1',
                'title': 'Shaddah pronunciation',
                'explanation': 'Hold the letter.',
              },
            },
          ],
        },
      ],
    );
    api.rpcHandlers['learner_today'] = (_) => [p];
    api.rpcHandlers['open_portion'] = (_) => p;
    await tester.pumpWidget(
      await buildTestApp(
        FakeAuthService(const AuthSession.signedIn(testUser)),
        api: api,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Try again · Yassarna: Beginners'), findsOneWidget);
    await tester.tap(find.text('Page 12'));
    await tester.pumpAndSettle();
    expect(find.text('Correction required'), findsOneWidget);
    expect(find.text('Your teacher: Repeat the second line.'), findsOneWidget);
    expect(find.textContaining('Shaddah pronunciation'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Record'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Record'), findsOneWidget);
  });

  testWidgets('teacher: needs my attention and the review board', (
    tester,
  ) async {
    final api = staffServer('teacher');
    api.rpcHandlers['teacher_attention'] = (_) => {
      'new_submissions': [
        {
          'portion_id': 'p1',
          'title': 'Page 12',
          'learner': 'Ahmad',
          'group': 'Group A',
          'status': 'submitted',
          'attempts': 1,
        },
      ],
      'resubmissions': <Object>[],
      'correction_required': <Object>[],
      'not_submitted': <Object>[],
      'falling_behind': <Object>[],
    };
    api.rpcHandlers['my_teaching_groups'] = (_) => [
      {
        'id': 'g1',
        'name': 'Group A',
        'course_id': 'c1',
        'course_title': 'Yassarna: Beginners',
        'learners': 20,
        'waiting': 1,
      },
    ];
    api.rpcHandlers['portion_board'] = (_) => {
      'portion': {
        'id': 'p1',
        'title': 'Page 12',
        'course_id': 'c1',
        'resources': <Object>[],
      },
      'learners': [
        {
          'user_id': 'a',
          'name': 'Ahmad',
          'status': 'submitted',
          'attempts': 1,
          'latest': {'id': 's1', 'files': <Object>[]},
        },
        {
          'user_id': 'b',
          'name': 'Aisha',
          'status': 'completed',
          'last_result': 'correct',
          'attempts': 1,
        },
        {'user_id': 'c', 'name': 'Maryam', 'status': 'assigned', 'attempts': 0},
      ],
    };
    await signInAs(tester, 'teacher', api: api);
    expect(find.text('Needs my attention'), findsOneWidget);
    expect(find.text('New work (1)'), findsOneWidget);
    expect(find.text('Group A'), findsOneWidget);
    await tester.tap(find.text('Ahmad'));
    await tester.pumpAndSettle();
    expect(find.text('Sent · waiting: 1'), findsOneWidget);
    expect(find.text('Done: 1'), findsOneWidget);
    expect(find.text('Maryam'), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget); // Aisha's result
  });

  testWidgets('About shows the changelog', (tester) async {
    await tester.pumpWidget(
      await buildTestApp(FakeAuthService(const AuthSession.signedIn(testUser))),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(NavigationBar))).push('/about');
    await tester.pumpAndSettle();
    expect(find.text('About Sidra'), findsOneWidget);
    expect(find.text('What\'s new'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('The beginning'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('The beginning'), findsOneWidget);
  });
}
