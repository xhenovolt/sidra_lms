import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_postgres_api.dart';
import '../helpers/test_app.dart';

FakePostgresApi quranServer() {
  final api = emptyServer();
  api.selectHandlers['courses'] = (_) => [
    {
      'id': 'c1',
      'slug': 'quran-beginners',
      'title': 'Quran for Beginners',
      'subject': 'Quran',
      'status': 'published',
      'access': 'free',
      'progression': 'teacher_gated',
      'learning_objectives': ['Recognise the Arabic letters'],
    },
  ];
  api.selectHandlers['course_units'] = (_) => [
    {
      'id': 'u1',
      'course_id': 'c1',
      'title': 'Arabic Letter Recognition',
      'position': 0,
      'status': 'published',
    },
  ];
  api.selectHandlers['curriculum_nodes'] = (_) => [
    {
      'id': 'n1',
      'course_id': 'c1',
      'unit_id': 'u1',
      'node_type': 'section',
      'title': 'Yassarna — Section 1',
      'position': 0,
      'page_start': 3,
      'status': 'published',
    },
  ];
  api.selectHandlers['lessons'] = (_) => [
    {
      'id': 'l1',
      'course_id': 'c1',
      'node_id': 'n1',
      'title': 'Alif and Ba',
      'position': 0,
      'status': 'published',
    },
    {
      'id': 'l2',
      'course_id': 'c1',
      'node_id': 'n1',
      'title': 'Ta and Tha',
      'position': 1,
      'status': 'published',
    },
  ];
  api.rpcHandlers['course_lesson_order'] = (_) => [
    {'lesson_id': 'l1', 'seq': 1, 'is_unlocked': true},
    {'lesson_id': 'l2', 'seq': 2, 'is_unlocked': false},
  ];
  api.rpcHandlers['my_courses'] = (_) => [
    {
      'course_id': 'c1',
      'enrolment_id': 'e1',
      'enrolment_status': 'active',
      'total_lessons': 2,
      'completed_lessons': 0,
      'unlocked_lessons': 1,
      'progress_percent': 0,
      'next_lesson_id': 'l1',
    },
  ];
  api.selectHandlers['lesson_content_blocks'] = (f) => f['lesson_id'] == 'eq.l1'
      ? [
          {
            'id': 'b1',
            'position': 0,
            'block_type': 'heading',
            'body': {'text': 'The first letters'},
          },
          {
            'id': 'b2',
            'position': 1,
            'block_type': 'quran_text',
            'body': {'arabic': 'ا ب'},
          },
        ]
      : const [];
  api.rpcHandlers['record_progress'] = (p) => {
    'lesson_id': p['p_lesson_id'],
    'course_id': 'c1',
    'status': p['p_status'],
    'client_updated_at': p['p_client_updated_at'],
  };
  return api;
}

void main() {
  testWidgets('learner opens course, reads unlocked lesson, sees lock', (
    tester,
  ) async {
    final api = quranServer();
    await tester.pumpWidget(
      await buildTestApp(
        FakeAuthService(const AuthSession.signedIn(testUser)),
        api: api,
      ),
    );
    await tester.pumpAndSettle();

    // Explore → course detail.
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quran for Beginners'));
    await tester.pumpAndSettle();

    expect(find.text('Recognise the Arabic letters'), findsOneWidget);
    expect(find.text('Arabic Letter Recognition'), findsOneWidget);
    await tester.ensureVisible(find.text('Ta and Tha'));
    await tester.pumpAndSettle();
    expect(find.text('Alif and Ba'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    // Locked lesson explains why.
    await tester.tap(find.text('Ta and Tha'));
    await tester.pump();
    expect(
      find.textContaining('Your teacher opens this lesson'),
      findsOneWidget,
    );

    // Unlocked lesson renders its blocks, including RTL Quranic text.
    await tester.ensureVisible(find.text('Alif and Ba'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alif and Ba'));
    await tester.pumpAndSettle();
    expect(find.text('The first letters'), findsOneWidget);
    expect(find.text('ا ب'), findsOneWidget);

    // Opening recorded "in progress" through the outbox.
    expect(api.rpcCalls.where((c) => c.$1 == 'record_progress'), isNotEmpty);

    // Next is locked (teacher-gated); completing shows waiting message.
    await tester.tap(find.text('I have finished this lesson'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);
    expect(
      api.rpcCalls.any(
        (c) => c.$1 == 'record_progress' && c.$2['p_status'] == 'completed',
      ),
      isTrue,
    );
  });
}
