// Queues MarzPay test-centre tests from a developer machine (as the
// database owner) and prints the results, step by step. Money tests are
// NOT available here: they need an administrator's typed confirmation in
// the app.
//
//   dart run tool/payment_test.dart connection capabilities balance reconciliation
//   dart run tool/payment_test.dart status_lookup <sidra id | marzpay id | reference>
//
// The payments server must be running (it executes the tests).
import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import 'gen_config.dart' show parseDotEnv;

const _safe = {'connection', 'capabilities', 'balance', 'status_lookup', 'callbacks', 'reconciliation'};

Future<void> main(List<String> args) async {
  final env = parseDotEnv(File('.env').readAsStringSync());
  final uri = Uri.parse(env['DATABASE_URL']!);
  final user = uri.userInfo.split(':');
  final bridge = Platform.environment['SIDRA_DB_BRIDGE']?.split(':');
  final db = await Connection.open(
    Endpoint(
      host: bridge?.first ?? uri.host,
      port: bridge != null ? int.parse(bridge.last) : (uri.hasPort ? uri.port : 5432),
      database: uri.pathSegments.first,
      username: Uri.decodeComponent(user.first),
      password: Uri.decodeComponent(user.skip(1).join(':')),
    ),
    settings: ConnectionSettings(sslMode: bridge != null ? SslMode.disable : SslMode.require),
  );
  try {
    final ids = <String>[];
    for (var i = 0; i < args.length; i++) {
      final kind = args[i];
      if (!_safe.contains(kind)) {
        stderr.writeln('skipping "$kind": only $_safe here');
        continue;
      }
      final params = kind == 'status_lookup' && i + 1 < args.length ? {'query': args[++i]} : {};
      final r = await db.execute(
        Sql.named("insert into payment_tests (kind, params) values (@k, @p::jsonb) returning id"),
        parameters: {'k': kind, 'p': jsonEncode(params)},
      );
      ids.add('${r.first.first}');
    }
    await db.execute("select pg_notify('sidra_payments', 'tests')");
    stdout.writeln('queued ${ids.length} test(s); waiting for the payments server…');
    final deadline = DateTime.now().add(const Duration(minutes: 6));
    while (DateTime.now().isBefore(deadline)) {
      final r = await db.execute(
        Sql.named("select count(*) from payment_tests where id = any(@ids::uuid[]) and status <> 'done'"),
        parameters: {'ids': ids},
      );
      if (r.first.first == 0) break;
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    final rows = await db.execute(
      Sql.named(
        'select kind, status, result, message, steps::text, evidence::text, environment '
        'from payment_tests where id = any(@ids::uuid[]) order by created_at',
      ),
      parameters: {'ids': ids},
    );
    for (final r in rows) {
      stdout.writeln('\n== ${r[0]}: ${r[2] ?? r[1]}  ${r[6] ?? ''}\n   ${r[3] ?? ''}');
      for (final s in (jsonDecode('${r[4]}') as List)) {
        stdout.writeln('   ${s['step']}. [${s['state']}] ${s['label']}: ${s['detail'] ?? ''}');
      }
      stdout.writeln('   evidence: ${r[5]}');
    }
  } finally {
    await db.close();
  }
}
