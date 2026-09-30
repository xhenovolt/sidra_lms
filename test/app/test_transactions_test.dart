import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sidra_lms/features/admin/presentation/control/test_transactions_screen.dart';

import '../helpers/fake_postgres_api.dart';
import 'teacher_console_test.dart' show permsFor, signInAs, staffServer;

/// A super admin with the payments.test permission (as in the database).
FakePostgresApi testerServer() {
  final api = staffServer('superadmin');
  api.rpcHandlers['my_permissions'] = (_) => [
    {'my_permissions': [...permsFor('superadmin'), 'payments.test']},
  ];
  return api;
}

void main() {
  test('MTN and Airtel numbers are recognised; others refused', () {
    expect(parseMoMoNumber('0772 123456'), ('+256772123456', MoMoNetwork.mtn));
    expect(parseMoMoNumber('+256 701 234567'), ('+256701234567', MoMoNetwork.airtel));
    expect(parseMoMoNumber('256751234567')?.$2, MoMoNetwork.airtel);
    expect(parseMoMoNumber('0761234567')?.$2, MoMoNetwork.mtn);
    expect(parseMoMoNumber('0711234567'), isNull, reason: 'not MTN / Airtel');
    expect(parseMoMoNumber('07721234'), isNull, reason: 'too short');
    expect(parseMoMoNumber('hello'), isNull);
  });

  testWidgets('send a test collection and see the raw response and history', (
    tester,
  ) async {
    final api = testerServer();
    final done = {
      'id': 't1',
      'kind': 'collection',
      'status': 'done',
      'result': 'failed',
      'created_at': '2026-09-30T10:00:00Z',
      'params': {'phone': '+25677•••456', 'amount': 500},
      'provider_status': null,
      'error_code': 'INVALID_PHONE',
      'message': 'MarzPay refused: The phone number is invalid',
      'steps': [
        {'step': 1, 'label': 'Sidra created the test', 'state': 'done'},
        {'step': 2, 'label': 'MarzPay accepted the request', 'state': 'failed'},
      ],
      'evidence': {
        'http_status': 422,
        'provider_response': {'status': 'error', 'error_code': 'INVALID_PHONE'},
      },
    };
    var sent = false;
    api.rpcHandlers['request_payment_test'] = (p) {
      sent = true;
      return 't1';
    };
    api.rpcHandlers['payment_tests'] = (_) => sent ? [done] : <Object>[];
    api.selectHandlers['payment_tests'] = (_) => [done];
    await signInAs(tester, 'superadmin', api: api);

    // A button in the menu, not hidden.
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/test-transactions');
    await tester.pumpAndSettle();
    expect(find.text('Test transactions'), findsWidgets);
    expect(find.text('Collect (money in)'), findsOneWidget);
    expect(find.text('Disburse (money out)'), findsOneWidget);

    // A wrong number is refused before anything is sent.
    await tester.enterText(find.byType(TextFormField).first, '0711 234567');
    await tester.tap(find.text('Collect now'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter an MTN MoMo or Airtel Money number'), findsOneWidget);
    expect(sent, isFalse);

    await tester.enterText(find.byType(TextFormField).first, '0772 123456');
    await tester.pump();
    expect(find.text('MTN MoMo · +256772123456'), findsOneWidget);
    await tester.tap(find.text('Collect now'));
    await tester.pumpAndSettle();
    expect(find.text('Real money will move'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Collect now').last);
    await tester.pumpAndSettle();

    final call = api.rpcCalls.lastWhere((c) => c.$1 == 'request_payment_test');
    expect(call.$2['p_kind'], 'collection');
    expect((call.$2['p_params'] as Map)['phone'], '+256772123456');
    expect((call.$2['p_params'] as Map)['amount'], 500);
    expect(call.$2['p_confirm'], '500 UGX +256772123456');

    // The response: status, error code, HTTP status, steps, raw JSON.
    expect(find.text('Response'), findsOneWidget);
    expect(find.text('Error code: INVALID_PHONE'), findsOneWidget);
    expect(find.text('HTTP: 422'), findsOneWidget);
    expect(find.textContaining('MarzPay accepted the request: failed'), findsOneWidget);
    expect(find.textContaining('"error_code": "INVALID_PHONE"'), findsOneWidget);
    // And the history below.
    await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Collect (money in) · 500 UGX'), findsOneWidget);
  });

  testWidgets('the menu has a Test transactions button', (tester) async {
    await signInAs(tester, 'superadmin', api: testerServer());
    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Test transactions'),
      200,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ).first,
    );
    expect(find.text('Test transactions'), findsOneWidget);
  });
}
