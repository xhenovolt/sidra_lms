// A screen's calls with one connection vs the pool (Phase 6, Stage 2).
//   SIDRA_LIVE=1 flutter test test/live/pool_timing_test.dart
@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/network/pg_client.dart';

import '../../tool/gen_config.dart' show parseDotEnv;

void main() {
  final run = Platform.environment['SIDRA_LIVE'] == '1';
  test(
    '8 calls: one connection vs pool',
    () async {
      final env = parseDotEnv(File('.env').readAsStringSync());
      for (final size in [1, 3]) {
        final client = PgClient(env['APP_DATABASE_URL']!, maxConnections: size);
        // Shaped like an app call: a transaction with two statements
        // (session binding + query), anonymously.
        Future<void> call() => client.transaction((tx) async {
          await tx.execute('select 1');
          await tx.execute('select count(*) from courses');
        });
        try {
          await call(); // connected
          final w = Stopwatch()..start();
          await Future.wait([for (var i = 0; i < 8; i++) call()]);
          final cold = w.elapsedMilliseconds;
          w.reset();
          await Future.wait([for (var i = 0; i < 8; i++) call()]);
          // ignore: avoid_print
          print(
            '$size connection(s): 8 calls $cold ms (incl. opening), '
            'then ${w.elapsedMilliseconds} ms',
          );
        } finally {
          await client.close();
        }
      }
    },
    skip: run ? false : 'set SIDRA_LIVE=1',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
