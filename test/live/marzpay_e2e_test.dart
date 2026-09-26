// Real money, real phone: a learner pays for a course through MarzPay.
//
//   SIDRA_LIVE_PAY=1 SIDRA_ADMIN_PASSWORD=… SIDRA_PAY_PHONE=0741341483 \
//     flutter test test/live/marzpay_e2e_test.dart
//
// Needs the payments server running (server/bin/payments_server.dart).
// Creates a 500 UGX course, pays for it as the superadmin through the app's
// own repositories, waits for the PIN, then archives the course.
@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/network/pg_client.dart';
import 'package:sidra_lms/core/network/postgres_api.dart';
import 'package:sidra_lms/features/auth/data/auth_backend.dart';
import 'package:sidra_lms/features/payments/data/payments_repository.dart';

import '../../tool/gen_config.dart' show parseDotEnv;

void main() {
  final run = Platform.environment['SIDRA_LIVE_PAY'] == '1';
  test(
    'learner pays 500 UGX with mobile money',
    () async {
      final env = parseDotEnv(File('.env').readAsStringSync());
      final client = PgClient(env['APP_DATABASE_URL']!);
      final auth = PgAuthBackend(client);
      final session = await auth.login(
        'hamibra',
        Platform.environment['SIDRA_ADMIN_PASSWORD'] ?? '',
      );
      final api = PgWireApi(
        client,
        ({bool forceRefresh = false}) async =>
            session['access_token'] as String,
      );
      final repo = PaymentsRepository(api);

      final course = (await api.insert('courses', {
        'slug': 'marzpay-test-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'MarzPay test (500 UGX)',
        'subject': 'Test',
        'access': 'paid',
        'price_amount': 500,
        'price_currency': 'UGX',
      })).single;
      final id = course['id'] as String;
      try {
        await api.insert('lessons', {
          'course_id': id,
          'title': 'Paid lesson',
          'position': 0,
          'status': 'published',
        });
        await api.rpc(
          'set_course_status',
          params: {'p_course_id': id, 'p_status': 'published'},
        );

        final before = await repo.balance(id);
        expect(before.outstanding, 500);

        final phone = Platform.environment['SIDRA_PAY_PHONE'] ?? '0741341483';
        final started = await repo.payWithMobileMoney(id, phone);
        // ignore: avoid_print
        print(
          'payment ${started.id}: ${started.status} — CHECK THE PHONE, enter PIN',
        );

        Payment latest = started;
        final deadline = DateTime.now().add(const Duration(minutes: 4));
        var last = '';
        while (DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(seconds: 4));
          latest = (await repo.myPayments(id)).first;
          if (latest.status.name != last) {
            last = latest.status.name;
            // ignore: avoid_print
            print(
              '${DateTime.now().toIso8601String()} ${latest.status.name} '
              '${latest.statusReason ?? ''}',
            );
          }
          if (!latest.awaitingPayer) break;
        }
        // ignore: avoid_print
        print('final: ${latest.status.name} ${latest.statusReason ?? ''}');
        expect(
          latest.status,
          isNot(PaymentStatus.initiated),
          reason: 'the payments server never picked it up',
        );
        if (latest.status == PaymentStatus.verified) {
          final after = await repo.balance(id);
          expect(after.outstanding, 0);
        }
      } finally {
        await api.rpc(
          'set_course_status',
          params: {'p_course_id': id, 'p_status': 'archived'},
        );
        await auth.logout(
          session['refresh_token'] as String,
          session['access_token'] as String,
        );
        await client.close();
      }
    },
    skip: run ? false : 'set SIDRA_LIVE_PAY=1',
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
