import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sidra_lms/features/teaching/data/work_thread.dart';

import 'payments_test.dart' show openPaidCourse, payServer;
import 'teacher_console_test.dart' show signInAs, staffServer;

/// Ahmed's work on "Ayat al-Kursi": attempt 1 (superseded, for 2:255),
/// attempt 2 (photos + recording) under review, the teacher's voice note and
/// text, and Ahmed's reply.
Map<String, Object?> _thread(String role) => {
  'kind': 'portion',
  'target_id': 'p1',
  'role': role,
  'learner': {'id': 'u9', 'name': 'Ahmed'},
  'participation': {'status': 'under_review'},
  'events': [
    {
      'type': 'attempt',
      'at': '2026-09-30T08:00:00Z',
      'submission_id': 's1',
      'attempt': 1,
      'status': 'superseded',
      'target': {'kind': 'ayah', 'surah': 2, 'ayah_start': 255, 'ayah_end': 255},
      'files': [
        {'media_asset_id': 'm1', 'kind': 'audio', 'file_name': 'r1.m4a'},
      ],
    },
    {
      'type': 'attempt',
      'at': '2026-09-30T08:05:00Z',
      'submission_id': 's2',
      'attempt': 2,
      'status': 'under_review',
      'text': 'Here is my writing too.',
      'target': {'kind': 'page_line', 'page': 14, 'line': 3},
      'files': [
        {'media_asset_id': 'm2', 'kind': 'document', 'file_name': 'p1.pdf'},
      ],
    },
    {
      'type': 'message',
      'at': '2026-09-30T09:00:00Z',
      'submission_id': 's2',
      'author_role': 'teacher',
      'author': 'Ustadh Tt',
      'kind': 'text',
      'body': 'Repeat the line slowly.',
    },
    {
      'type': 'message',
      'at': '2026-09-30T09:10:00Z',
      'submission_id': 's2',
      'author_role': 'learner',
      'author': 'Ahmed',
      'kind': 'text',
      'body': 'Is this better?',
    },
  ],
};

void main() {
  test('targets describe themselves', () {
    // Plain data: no localisations needed for the kind checks.
    expect(WorkTarget.ayah(2, 255).kind, 'ayah');
    expect(WorkTarget.pageLine(14, 3).j['line'], 3);
    expect(
      WorkTarget.block('b1', 4, 12, 'بِسْمِ ٱللَّهِ').j,
      containsPair('end', 12),
    );
    expect(WorkTarget.whole().isWhole, isTrue);
  });

  testWidgets('a learner sees every attempt and reply, and can reply', (
    tester,
  ) async {
    final api = staffServer('learner');
    api.rpcHandlers['work_thread'] = (_) => _thread('learner');
    api.rpcHandlers['work_reply'] = (p) => {'id': p['p_id']};
    await signInAs(tester, 'learner', api: api);
    GoRouter.of(tester.element(find.byType(NavigationBar))).push('/work/portion/p1');
    await tester.pumpAndSettle();

    expect(find.text('You · Attempt 1'), findsOneWidget);
    expect(find.text('You · Attempt 2'), findsOneWidget);

    expect(find.text('Replaced by a newer attempt'), findsOneWidget);
    expect(find.text('For: Surah 2, ayah 255'), findsOneWidget);
    expect(find.text('For: Page 14, line 3'), findsOneWidget);
    expect(find.text('Repeat the line slowly.'), findsOneWidget);
    expect(find.text('Is this better?'), findsOneWidget);
    // Still open: a new attempt or a reply.
    expect(find.text('New attempt'), findsOneWidget);
    expect(find.text('Reply'), findsOneWidget);

    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Thank you, teacher');
    await tester.pump();
    await tester.tap(find.byTooltip('Send reply'));
    await tester.pumpAndSettle();
    final call = api.rpcCalls.lastWhere((c) => c.$1 == 'work_reply');
    expect(call.$2['p_submission_id'], 's2', reason: 'replies go on the latest attempt');
    expect(call.$2['p_kind'], 'text');
    expect(call.$2['p_body'], 'Thank you, teacher');
    expect(call.$2['p_id'], isA<String>(), reason: 'the phone makes the id: no duplicates');
  });

  testWidgets('a teacher sees the whole thread and marks the latest attempt', (
    tester,
  ) async {
    final api = staffServer('teacher');
    api.rpcHandlers['work_thread'] = (_) => _thread('teacher');
    api.rpcHandlers['review_attempt'] = (p) => {'id': 'r1', 'result': p['p_result']};
    await signInAs(tester, 'teacher', api: api);
    GoRouter.of(tester.element(find.byType(NavigationBar)))
        .push('/work/portion/p1?learner=u9');
    await tester.pumpAndSettle();

    expect(find.text("Ahmed's work"), findsOneWidget);
    expect(find.text('Ahmed · Attempt 2'), findsOneWidget);
    expect(find.text('Mark attempt 2:'), findsOneWidget);
    for (final action in ['Correct', 'Excellent', 'Correct, small note', 'Try again']) {
      expect(find.text(action), findsWidgets, reason: action);
    }
    // Library corrections and voice are one tap away.
    expect(find.byTooltip('Record'), findsOneWidget);
    expect(find.byTooltip('Existing correction'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Well read.');
    await tester.tap(find.widgetWithText(FilledButton, 'Correct'));
    await tester.pumpAndSettle();
    final call = api.rpcCalls.lastWhere((c) => c.$1 == 'review_attempt');
    expect(call.$2['p_submission_id'], 's2');
    expect(call.$2['p_result'], 'correct');
    expect(call.$2['p_feedback'], 'Well read.');
  });

  testWidgets('a monthly course shows its price per month and what is paid', (
    tester,
  ) async {
    final api = payServer(['initiated']);
    api.rpcHandlers['my_course_balance'] = (_) => {
      'fee': 60000,
      'paid': 30000,
      'refunded': 0,
      'waived': 0,
      'outstanding': 30000,
      'currency': 'UGX',
      'billing_period': 'monthly',
      'price_per_period': 30000,
      'billing_periods': 3,
      'periods_due': 2,
      'periods_covered': 1,
      'next_due_on': '2026-10-15',
    };
    await openPaidCourse(tester, api);
    expect(find.text('UGX 30,000 / month · 3 payments in all'), findsOneWidget);
    expect(find.textContaining('Paid 1 of 2 so far'), findsOneWidget);
    expect(find.textContaining('next due'), findsOneWidget);
  });

  testWidgets('sign out is in the top bar on every admin page', (tester) async {
    await signInAs(tester, 'admin');
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Change password'), findsOneWidget);
  });
}

