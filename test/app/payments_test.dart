import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sidra_lms/features/payments/data/payments_repository.dart';
import 'package:sidra_lms/features/payments/presentation/course_payment_card.dart';

import '../helpers/fake_postgres_api.dart';
import 'teacher_console_test.dart' show permsFor, signInAs, staffServer;

/// A learner looking at a 50,000 UGX course; payments move through
/// [statuses] each time the app asks.
FakePostgresApi payServer(List<String> statuses) {
  final api = staffServer('learner');
  api.selectHandlers['courses'] = (_) => [
    {
      'id': 'c9',
      'slug': 'paid',
      'title': 'Quran Intermediate',
      'subject': 'Quran',
      'status': 'published',
      'access': 'paid',
      'price_amount': 50000,
      'price_currency': 'UGX',
    },
  ];
  api.selectHandlers['lessons'] = (_) => [
    {
      'id': 'l1',
      'course_id': 'c9',
      'title': 'Lesson 1',
      'position': 0,
      'status': 'published',
    },
  ];
  api.rpcHandlers['course_lesson_order'] = (_) => [
    {'lesson_id': 'l1', 'seq': 1, 'is_unlocked': false},
  ];
  api.rpcHandlers['my_course_balance'] = (_) => {
    'fee': 50000,
    'paid': 0,
    'refunded': 0,
    'waived': 0,
    'outstanding': 50000,
    'currency': 'UGX',
  };
  var started = false;
  var polls = 0;
  api.rpcHandlers['start_course_payment'] = (p) {
    started = true;
    return {
      'id': 'pay1',
      'amount': 50000,
      'currency': 'UGX',
      'status': 'initiated',
      'phone': '+256741341483',
    };
  };
  api.rpcHandlers['my_payments'] = (_) {
    if (!started) return <Object>[];
    final s = statuses[(polls++).clamp(0, statuses.length - 1)];
    return [
      {
        'id': 'pay1',
        'amount': 50000,
        'currency': 'UGX',
        'status': s,
        'phone': '+256741341483',
      },
    ];
  };
  return api;
}

Future<void> openPaidCourse(WidgetTester tester, FakePostgresApi api) async {
  await signInAs(tester, 'learner', api: api);
  GoRouter.of(tester.element(find.byType(NavigationBar))).go('/courses/c9');
  await tester.pumpAndSettle();
}

Future<void> pay(WidgetTester tester) async {
  await tester.tap(find.text('Pay with mobile money'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), '0741 341483');
  await tester.tap(find.widgetWithText(FilledButton, 'Pay'));
  // Let the dialog close and the request return, but not the polling run.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  test('Uganda mobile numbers are normalised', () {
    expect(ugMobile('0741 341483'), '+256741341483');
    expect(ugMobile('+256 772 123456'), '+256772123456');
    expect(ugMobile('256701234567'), '+256701234567');
    expect(ugMobile('0412 123456'), isNull);
    expect(ugMobile('12345'), isNull);
    expect(formatMoney(1250000, 'UGX'), 'UGX 1,250,000');
  });

  testWidgets('a learner pays with mobile money and the course opens', (
    tester,
  ) async {
    final api = payServer(['processing', 'processing', 'verified']);
    await openPaidCourse(tester, api);
    expect(find.text('UGX 50,000'), findsOneWidget);

    await pay(tester);
    final call = api.rpcCalls.lastWhere((c) => c.$1 == 'start_course_payment');
    expect(call.$2['p_course_id'], 'c9');
    expect(call.$2['p_phone'], '+256741341483');
    expect(
      call.$2.containsKey('p_amount'),
      isFalse,
      reason: 'the server decides the amount',
    );
    expect(find.text('Check your phone'), findsOneWidget);

    // The app keeps asking the server until MarzPay confirms.
    await tester.pumpAndSettle();
    expect(
      api.rpcCalls.where((c) => c.$1 == 'my_payments').length,
      greaterThanOrEqualTo(3),
    );
    expect(find.text('Payment received'), findsOneWidget);
  });

  testWidgets('a declined prompt can be tried again', (tester) async {
    final api = payServer(['failed']);
    await openPaidCourse(tester, api);
    await pay(tester);
    await tester.pumpAndSettle();
    expect(find.text('Payment not completed'), findsOneWidget);
    expect(find.text('Pay with mobile money'), findsOneWidget);
  });

  testWidgets('a wrong number is caught before anything is sent', (
    tester,
  ) async {
    final api = payServer(['processing']);
    await openPaidCourse(tester, api);
    await tester.tap(find.text('Pay with mobile money'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Pay'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter an MTN or Airtel Uganda number, e.g. 0772 123456'),
      findsOneWidget,
    );
    expect(api.rpcCalls.where((c) => c.$1 == 'start_course_payment'), isEmpty);
  });

  testWidgets('finance sees the retained formula with real numbers', (
    tester,
  ) async {
    final api = staffServer('finance_officer');
    api.rpcHandlers['my_permissions'] = (_) => [
      {
        'my_permissions': [
          ...permsFor('finance_officer'),
          'finance.verify_payment',
        ],
      },
    ];
    api.rpcHandlers['finance_summary'] = (_) => {
      'currency': 'UGX',
      'expected': 300000,
      'collected': 200000,
      'outstanding': 70000,
      'waived': 30000,
      'refunded': 10000,
      'provider_fees': 6000,
      'expenses': 50000,
      'retained': 134000,
      'pending_count': 1,
      'pending_amount': 20000,
      'by_course': <Object>[],
      'by_method': {'marzpay': 150000, 'bank': 50000},
    };
    api.rpcHandlers['finance_payments'] = (_) => [
      {
        'id': 'p1',
        'user_id': 'l1',
        'learner': 'Bilal',
        'course': 'Quran Intermediate',
        'amount': 20000,
        'currency': 'UGX',
        'method': 'bank',
        'status': 'pending',
        'external_reference': 'SLIP-77',
        'refunded': 0,
        'total': 1,
      },
    ];
    api.rpcHandlers['verify_payment'] = (_) => {'id': 'p1'};
    await signInAs(tester, 'finance_officer', api: api);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Finance'),
      ),
    );
    await tester.pumpAndSettle();
    // Finance home → Payments and fees.
    await tester.scrollUntilVisible(
      find.text('Payments and fees'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Payments and fees'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'UGX 200,000 − UGX 10,000 − UGX 6,000 − UGX 50,000 = UGX 134,000',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('1 payment waiting'), findsOneWidget);

    await tester.tap(find.textContaining('1 payment waiting'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Bilal'));
    await tester.pumpAndSettle();
    expect(find.text('SLIP-77'), findsOneWidget);
    await tester.tap(find.text('Verify: money received'));
    await tester.pumpAndSettle();
    expect(
      api.rpcCalls
          .lastWhere((c) => c.$1 == 'verify_payment')
          .$2['p_payment_id'],
      'p1',
    );
  });
}
