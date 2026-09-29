import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';
import 'package:sidra_lms/features/content/data/content_repository.dart';
import 'package:sidra_lms/features/content/presentation/assignment_widgets.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_postgres_api.dart';
import '../helpers/test_app.dart';
import 'learner_flow_test.dart' show quranServer;
import 'teacher_console_test.dart' show permsFor, signInAs, staffServer;

const _languages = [
  {
    'code': 'en',
    'name': 'English',
    'native_name': 'English',
    'direction': 'ltr',
  },
  {
    'code': 'ar',
    'name': 'Arabic',
    'native_name': 'العربية',
    'direction': 'rtl',
  },
];

/// The learner-flow course, now English-delivered with Arabic content,
/// outcomes, a PDF and an assignment on lesson 1.
FakePostgresApi phase3LearnerServer() {
  final api = quranServer();
  final courses = api.selectHandlers['courses']!;
  api.selectHandlers['courses'] = (f) => [
    for (final c in courses(f)) {...c, 'language': 'en'},
  ];
  final lessons = api.selectHandlers['lessons']!;
  api.selectHandlers['lessons'] = (f) => [
    for (final l in lessons(f))
      l['id'] == 'l1'
          ? {
              ...l,
              'objectives': [
                'The learner names Alif and Ba and tells them apart.',
              ],
            }
          : l,
  ];
  api.selectHandlers['languages'] = (_) => _languages;
  api.selectHandlers['lesson_content_blocks'] = (f) => f['lesson_id'] == 'eq.l1'
      ? [
          {
            'id': 'b1',
            'position': 0,
            'block_type': 'quran_text',
            'language': 'ar',
            'body': {'arabic': 'بِسْمِ ٱللَّهِ'},
          },
          {
            'id': 'b2',
            'position': 1,
            'block_type': 'rich_text',
            'language': 'en',
            'body': {'text': 'Read each letter slowly.'},
          },
        ]
      : const [];
  api.selectHandlers['resource_links'] = (f) => f['lesson_id'] == 'eq.l1'
      ? [
          {
            'id': 'k1',
            'resource_id': 'r1',
            'lesson_id': 'l1',
            'position': 0,
            'status': 'published',
          },
        ]
      : const [];
  api.selectHandlers['resources'] = (_) => [
    {
      'id': 'r1',
      'kind': 'document',
      'title': 'Student practice sheet',
      'provider': 'cloudinary',
      'media_asset_id': 'm1',
      'file_name': 'student-practice.pdf',
      'bytes': 120000,
    },
  ];
  api.selectHandlers['assignments'] = (f) => f['lesson_id'] == 'eq.l1'
      ? [
          {
            'id': 'a1',
            'course_id': 'c1',
            'lesson_id': 'l1',
            'title': 'Write ا ب ت ث',
            'instructions': 'Write each letter five times and photograph it.',
            'submission_types': ['image'],
            'max_files': 5,
            'status': 'published',
          },
        ]
      : const [];
  api.rpcHandlers['my_submissions'] = (_) => <Object>[];
  return api;
}

void main() {
  testWidgets('English lesson with Arabic Qur\'an text, outcomes, resources, '
      'assignment', (tester) async {
    final api = phase3LearnerServer();
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

    // Delivery language is English although the lesson contains Arabic.
    expect(find.text('Taught in English'), findsOneWidget);
    expect(find.textContaining('Arabic'), findsNothing);
    expect(find.text('بِسْمِ ٱللَّهِ'), findsOneWidget);
    expect(
      find.text('Names Alif and Ba and tells them apart.'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Submit work'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Student practice sheet'), findsOneWidget);
    expect(find.text('Write ا ب ت ث'), findsOneWidget);
  });

  testWidgets('a teacher asks for a new try with feedback', (tester) async {
    final api = staffServer('teacher');
    api.rpcHandlers['media_url'] = (_) => 'https://res.cloudinary.com/x/y.jpg';
    api.rpcHandlers['review_submission'] = (p) => {
      'id': 's1',
      'assignment_id': 'a1',
      'status': p['p_status'],
      'feedback': p['p_feedback'],
      'files': <Object>[],
    };
    await signInAs(tester, 'teacher', api: api);
    final nav = Navigator.of(tester.element(find.byType(NavigationBar)));
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const SubmissionReviewScreen(
          submission: Submission({
            'id': 's1',
            'assignment_id': 'a1',
            'status': 'received',
            'learner': 'Learner A',
            'assignment_title': 'Write ا ب ت ث',
            'text_answer': 'Done',
            'files': <Object>[],
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Learner A'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Feedback for the learner'),
      'Your ت needs two dots above.',
    );
    await tester.tap(find.text('Ask for a new try'));
    await tester.pumpAndSettle();
    final call = api.rpcCalls.lastWhere((c) => c.$1 == 'review_submission');
    expect(call.$2['p_status'], 'resubmission_requested');
    expect(call.$2['p_feedback'], 'Your ت needs two dots above.');
  });

  testWidgets('the lesson overview shows where a lesson sits', (tester) async {
    final api = staffServer('admin');
    api.selectHandlers['lessons'] = (_) => [
      {
        'id': 'l1',
        'course_id': 'c1',
        'unit_id': 'u1',
        'title': 'Reading letters with short vowels',
        'position': 0,
        'status': 'draft',
        'objectives': ['Reads letters with fatḥah, kasrah and ḍammah.'],
        'metadata': {'provisional': true},
      },
    ];
    api.selectHandlers['course_units'] = (_) => [
      {
        'id': 'u1',
        'course_id': 'c1',
        'title': 'Stage 2: Short vowels',
        'position': 1,
        'status': 'published',
      },
    ];
    api.selectHandlers['languages'] = (_) => _languages;
    await signInAs(tester, 'admin', api: api);
    GoRouter.of(tester.element(find.byType(NavigationBar)))
        .go('/teach/lessons/l1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();
    expect(
      find.text('Quran Intermediate › Stage 2: Short vowels'),
      findsOneWidget,
    );
    expect(find.text('Needs review'), findsOneWidget);
    expect(
      find.text('Reads letters with fatḥah, kasrah and ḍammah.'),
      findsOneWidget,
    );
    expect(find.text('Move…'), findsOneWidget);
    expect(find.text('Copy to another course…'), findsOneWidget);
  });

  testWidgets('MarzPay: honest status, and a capability matrix from evidence', (
    tester,
  ) async {
    final api = staffServer('superadmin');
    api.rpcHandlers['my_permissions'] = (_) => [
      {
        'my_permissions': [
          ...permsFor('superadmin'),
          'settings.manage',
          'payments.test',
          'system.diagnose',
        ],
      },
    ];
    api.rpcHandlers['system_health'] = (_) => {
      'checked_at': '2026-09-29T08:00:00Z',
      'database': {
        'ok': true,
        'latest_migration': '0040_settings_validation.sql',
        'migrations': 40,
      },
      'payments_server': {
        'online': true,
        'version': '1.1.0',
        'public_url': false,
      },
      'marzpay': {
        'enabled': true,
        'verified_payments': 0,
        'stuck': 0,
        'latest_tests': {
          'connection': {'result': 'verified_success'},
        },
      },
      'storage': {'configured': true, 'uploads_24h': 3},
      'notifications': {
        'sent_24h': 5,
        'phones_registered': 2,
        'devices_blocking': 0,
      },
      'security': {
        'failed_sign_ins_24h': 1,
        'locked_now': 0,
        'accounts_on_many_devices': 0,
      },
      'learning': {'active_learners_7d': 4},
      'payments': {'manual_waiting': 0, 'stuck_mobile_money': 0},
      'app': {'latest_build': '50'},
      'recent_failed_diagnostics': 0,
    };
    api.rpcHandlers['payment_tests'] = (_) => [
      {
        'id': 't2',
        'kind': 'capabilities',
        'status': 'done',
        'result': 'verified_success',
        'evidence': {
          'collection': ['MTN', 'Airtel', 'Card Payments'],
          'disbursement': ['MTN', 'Airtel', 'Bank Transfer', 'Wallet Transfer'],
          'bank_transfer': true,
          'wallet_transfer': true,
        },
      },
      {
        'id': 't1',
        'kind': 'connection',
        'status': 'done',
        'result': 'verified_success',
      },
    ];
    await signInAs(tester, 'superadmin', api: api);
    GoRouter.of(tester.element(find.byType(NavigationBar)))
        .go('/admin/settings');
    await tester.pumpAndSettle();

    // Never "ON" without proof: connected, but no collection proven yet.
    expect(
      find.text(
        'Connected and authenticated; a real collection not yet proven',
      ),
      findsOneWidget,
    );

    // Search finds the test centre.
    await tester.enterText(find.byType(TextField).first, 'marzpay');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('MarzPay test centre'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('MarzPay test centre'));
    await tester.pumpAndSettle();
    expect(find.text('Capabilities'), findsOneWidget);
    expect(
      find.text("MarzPay offers it; Sidra doesn't use it yet"),
      findsWidgets,
    ); // bank, wallet, card
    expect(find.text('Not offered by MarzPay'), findsOneWidget); // refunds
    expect(find.text('Verified'), findsWidgets); // connection
    // Money tests are clearly marked; opening the page started nothing.
    expect(api.rpcCalls.any((c) => c.$1 == 'request_payment_test'), isFalse);
  });
}
