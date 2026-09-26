// MarzPay integration tests, requested exactly as the admin screen does.
//
//   SIDRA_LIVE=1 SIDRA_ADMIN_PASSWORD=… flutter test test/live/payment_diagnostics_test.dart
//
// Needs the payments server running. Moves no money.
@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/network/pg_client.dart';
import 'package:sidra_lms/core/network/postgres_api.dart';
import 'package:sidra_lms/features/auth/data/auth_backend.dart';

import '../../tool/gen_config.dart' show parseDotEnv;

void main() {
  final run = Platform.environment['SIDRA_LIVE'] == '1';
  test(
    'MarzPay diagnostics report PASS / WARNING / FAIL',
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
      try {
        final id = await api.rpc('request_payment_diagnostics');
        Map? run;
        for (var i = 0; i < 30; i++) {
          await Future<void>.delayed(const Duration(seconds: 2));
          final status = await api.rpc('payment_integration_status') as Map;
          final latest = status['latest_run'] as Map?;
          if (latest?['id'] == id && latest?['status'] == 'done') {
            run = latest;
            // ignore: avoid_print
            print('server online: ${status['server_online']}');
            break;
          }
        }
        expect(run, isNotNull, reason: 'payments server did not answer');
        for (final r in run!['results'] as List) {
          // ignore: avoid_print
          print(
            '${(r['result'] as String).toUpperCase().padRight(8)} '
            '${r['label']}: ${r['message']}',
          );
        }
        final text = run.toString();
        expect(
          text.contains(env['MARZPAY_API_SECRET']!),
          isFalse,
          reason: 'secrets must never appear in results',
        );
      } finally {
        await auth.logout(
          session['refresh_token'] as String,
          session['access_token'] as String,
        );
        await client.close();
      }
    },
    skip: run ? false : 'set SIDRA_LIVE=1',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
