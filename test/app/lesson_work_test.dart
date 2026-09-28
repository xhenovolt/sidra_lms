import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';
import 'package:sidra_lms/features/teaching/data/lesson_work.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/test_app.dart';
import 'learner_flow_test.dart' show quranServer;
import 'teacher_console_test.dart' show signInAs, staffServer;

void main() {
  test('score follows the word marks: correct 1, weak ½, wrong 0', () {
    expect(scoreFromMarks(const []), 100);
    expect(
      scoreFromMarks(const [
        MarkedWord(0, 'a', WordMark.ok),
        MarkedWord(1, 'b', WordMark.weak),
        MarkedWord(2, 'c', WordMark.wrong),
        MarkedWord(3, 'd', WordMark.ok),
      ]),
      63, // (1 + 0.5 + 0 + 1) / 4
    );
  });

  testWidgets('a work lesson says Submit work, not I have finished', (
    tester,
  ) async {
    final api = quranServer();
    final courses = api.selectHandlers['courses']!;
    api.selectHandlers['courses'] = (f) => [
      for (final c in courses(f))
        {...c, 'progression': 'after_approval', 'pass_mark_percent': 70},
    ];
    api.rpcHandlers['my_lesson_work'] = (_) => <Object>[];
    await tester.pumpWidget(
      await buildTestApp(
        FakeAuthService(const AuthSession.signedIn(testUser)),
        api: api,
      ),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(NavigationBar)))
        .go('/courses/c1/lessons/l1');
    await tester.pumpAndSettle();
    expect(find.text('Submit work'), findsWidgets);
    expect(find.text('I have finished this lesson'), findsNothing);
    expect(find.text('Your work'), findsOneWidget);
  });

  testWidgets('the teacher marks word by word and approves', (tester) async {
    final api = staffServer('teacher');
    api.rpcHandlers['lesson_marking_text'] = (_) => [
      'بِسْمِ',
      'ٱللَّهِ',
      'ٱلرَّحْمَٰنِ',
      'ٱلرَّحِيمِ',
    ];
    api.rpcHandlers['review_lesson_work'] = (p) => {'id': 'r1', 'passed': true};
    await signInAs(tester, 'teacher', api: api);
    GoRouter.of(tester.element(find.byType(NavigationBar))).push(
      '/teach/work/s1',
      extra: const LessonWork({
        'id': 's1',
        'lesson_id': 'l1',
        'course_id': 'c1',
        'status': 'submitted',
        'attempt': 1,
        'learner': 'Maryam',
        'lesson_title': 'Al-Fatihah 1-4',
        'pass_mark': 70,
        'files': <Object>[],
        'reviews': <Object>[],
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Overall score: 100%'), findsOneWidget);
    // One word wrong, one weak: (1 + 0 + 0.5 + 1) / 4 = 63%.
    await tester.tap(find.text('ٱللَّهِ'));
    await tester.tap(find.text('ٱللَّهِ'));
    await tester.tap(find.text('ٱلرَّحْمَٰنِ'));
    await tester.pump();
    expect(find.text('Overall score: 63%'), findsOneWidget);
    expect(find.textContaining('Below the pass mark'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Approve'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    final call = api.rpcCalls.lastWhere((c) => c.$1 == 'review_lesson_work');
    expect(call.$2['p_score_percent'], 63);
    final marks = (call.$2['p_word_marks'] as List)
        .cast<Map<String, Object?>>();
    expect(marks[1]['m'], 'wrong');
    expect(marks[2]['m'], 'weak');
  });

  testWidgets('the teacher inbox lists every kind of waiting work', (
    tester,
  ) async {
    final api = staffServer('teacher');
    api.rpcHandlers['teacher_inbox'] = (_) => [
      {
        'type': 'portion',
        'id': 's1',
        'portion_id': 'p1',
        'learner': 'Ahmad',
        'title': 'Page 12',
        'context': 'Group A',
        'attempt': 1,
        'has_audio': true,
      },
      {
        'type': 'lesson_work',
        'id': 's2',
        'learner': 'Maryam',
        'title': 'Al-Fatihah 1-4',
        'context': 'Yassarna',
        'attempt': 2,
        'has_audio': true,
      },
      {
        'type': 'assignment',
        'id': 's3',
        'learner': 'Yusuf',
        'title': 'Write ا ب ت',
        'context': 'Yassarna',
        'attempt': 1,
      },
    ];
    await signInAs(tester, 'teacher', api: api);
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('3 pieces of work waiting'), findsOneWidget);
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Review next automatically'), findsOneWidget);
    expect(find.text('Ahmad'), findsOneWidget);
    expect(find.textContaining('attempt 2'), findsOneWidget);
    expect(find.text('Yusuf'), findsOneWidget);
  });
}
