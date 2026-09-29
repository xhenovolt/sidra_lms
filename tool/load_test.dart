// Load test: N learners using Sidra at the same time, the way the app does.
//
//   dart run tool/load_test.dart            # 50 learners, 10 rounds each
//   dart run tool/load_test.dart 80 20      # 80 learners, 20 rounds
//
// 1. As the owner: creates N temporary learners (username loadtest_<n>),
//    enrolled in one published course.
// 2. Each learner, on its OWN connection as the app login (sidra_app):
//    signs in (bcrypt, device record), then runs rounds of what the home
//    screen does, each round one transaction that starts with
//    app_private.authenticate(token): catalogue, my courses, notifications,
//    problem reports, heartbeat.
// 3. Prints sign-in and round times (median, 95th percentile, worst) and
//    errors, then deletes the temporary learners (always, even on failure).
//
// SIDRA_DB_BRIDGE=127.0.0.1:55433 routes through tool/pg_ws_bridge.mjs.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import 'gen_config.dart' show parseDotEnv;

Future<Connection> _open(String url) {
  final uri = Uri.parse(url);
  final user = uri.userInfo.split(':');
  final bridge = Platform.environment['SIDRA_DB_BRIDGE'];
  final parts = bridge?.split(':');
  return Connection.open(
    Endpoint(
      host: parts?.first ?? uri.host,
      port: parts != null
          ? int.parse(parts.last)
          : (uri.hasPort ? uri.port : 5432),
      database: uri.pathSegments.first,
      username: Uri.decodeComponent(user.first),
      password: Uri.decodeComponent(user.skip(1).join(':')),
    ),
    settings: ConnectionSettings(
      sslMode: bridge != null ? SslMode.disable : SslMode.require,
      connectTimeout: const Duration(seconds: 30),
    ),
  );
}

String _stats(List<int> ms) {
  if (ms.isEmpty) return 'none';
  final s = [...ms]..sort();
  int at(double q) => s[((s.length - 1) * q).round()];
  return 'median ${at(0.5)} ms · 95% ${at(0.95)} ms · worst ${s.last} ms · n=${s.length}';
}

Future<void> main(List<String> args) async {
  final learners = args.isNotEmpty ? int.parse(args[0]) : 50;
  final rounds = args.length > 1 ? int.parse(args[1]) : 10;
  final env = parseDotEnv(File('.env').readAsStringSync());
  final ownerUrl = env['DATABASE_URL']!;
  final appUrl = env['APP_DATABASE_URL']!;
  const password = 'load-test-pass-9';

  final owner = await _open(ownerUrl);
  stdout.writeln('Creating $learners temporary learners…');
  final course =
      (await owner.execute(
            "select id from courses where status = 'published' order by created_at limit 1",
          )).first.first
          as String?;
  await owner.execute("delete from users where username like 'loadtest\\_%'");
  for (var i = 0; i < learners; i++) {
    final id = (await owner.execute(
      Sql.named(
        "select app_private.create_account(@n, null, null, @u, 'learner', false, @p, false)",
      ),
      parameters: {'n': 'Load Test $i', 'u': 'loadtest_$i', 'p': password},
    )).first.first;
    if (course != null) {
      await owner.execute(
        Sql.named(
          "insert into course_enrolments (course_id, user_id, status, source) "
          "values (@c, @u, 'active', 'admin_grant') on conflict do nothing",
        ),
        parameters: {'c': course, 'u': id},
      );
    }
  }

  final signIns = <int>[];
  final roundsMs = <int>[];
  final errors = <String>[];
  final perQuery = <String, List<int>>{};
  final started = DateTime.now();
  try {
    stdout.writeln(
      'Running $learners learners × $rounds rounds at the same time…',
    );
    await Future.wait([
      for (var i = 0; i < learners; i++)
        () async {
          Connection? c;
          try {
            c = await _open(appUrl);
            final sw = Stopwatch()..start();
            final session =
                (await c.execute(
                      Sql.named('select auth_api.app_login(@u, @p, @d)'),
                      parameters: {
                        'u': 'loadtest_$i',
                        'p': password,
                        'd': jsonEncode({
                          'install_id': 'loadtest-install-$i',
                          'model': 'Load test',
                        }),
                      },
                    )).first.first!
                    as Map;
            signIns.add(sw.elapsedMilliseconds);
            final token = session['access_token'] as String?;
            if (token == null) throw StateError('sign-in: ${session['error']}');
            for (var r = 0; r < rounds; r++) {
              final t = Stopwatch()..start();
              await c.runTx((tx) async {
                Future<void> q(
                  String name,
                  Object sql, [
                  Map<String, Object?>? p,
                ]) async {
                  final qs = Stopwatch()..start();
                  await tx.execute(sql, parameters: p);
                  (perQuery[name] ??= []).add(qs.elapsedMilliseconds);
                }

                await q(
                  'authenticate',
                  Sql.named('select app_private.authenticate(@t)'),
                  {'t': token},
                );
                await q(
                  'catalogue',
                  "select id, title from courses where status = 'published' limit 50",
                );
                await q(
                  'enrolments',
                  'select * from course_enrolments limit 50',
                );
                await q(
                  'notifications',
                  'select * from notifications order by created_at desc limit 30',
                );
                await q(
                  'problem reports',
                  'select * from public.my_work_issues()',
                );
                await q(
                  'heartbeat',
                  Sql.named('select public.report_device(@d, true, false)'),
                  {
                    'd': jsonEncode({
                      'install_id': 'loadtest-install-$i',
                      'network': 'wifi',
                    }),
                  },
                );
              });
              roundsMs.add(t.elapsedMilliseconds);
            }
          } catch (e) {
            errors.add('learner $i: $e');
          } finally {
            await c?.close();
          }
        }(),
    ]);
  } finally {
    final elapsed = DateTime.now().difference(started);
    stdout
      ..writeln('')
      ..writeln(
        'Learners: $learners, rounds each: $rounds, total ${elapsed.inSeconds} s',
      )
      ..writeln('Sign-in: ${_stats(signIns)}')
      ..writeln(
        'Home-screen round (6 queries, 1 transaction): ${_stats(roundsMs)}',
      )
      ..writeln('Errors: ${errors.length}');
    for (final e in perQuery.entries) {
      stdout.writeln('  ${e.key}: ${_stats(e.value)}');
    }
    for (final e in errors.take(10)) {
      stdout.writeln('  $e');
    }
    stdout.writeln('Removing the temporary learners…');
    await owner.execute("delete from users where username like 'loadtest\\_%'");
    await owner.close();
  }
}
