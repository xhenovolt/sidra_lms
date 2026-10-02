// Where does a slow screen spend its time? (Phase 6, Stage 2.)
//
//   dart run tool/perf_probe.dart
//
// A. Network, exactly as the app talks to the database: the sidra_app login
//    on Neon's pooled endpoint, one transaction per call, session binding
//    first. Timed from this machine.
// B. Server: each screen's query run as a real learner / teacher / admin,
//    timed inside the database (no network). Everything runs in transactions
//    that are rolled back; nothing is changed.
import 'dart:io';

import 'package:postgres/postgres.dart';

import 'gen_config.dart' show parseDotEnv;

Future<void> main() async {
  final env = parseDotEnv(File('.env').readAsStringSync());
  await _network(env['APP_DATABASE_URL']!);
  await _server(env['DATABASE_URL']!);
}

Endpoint _endpoint(String url) {
  final uri = Uri.parse(url);
  final user = uri.userInfo.split(':');
  return Endpoint(
    host: uri.host,
    port: uri.hasPort ? uri.port : 5432,
    database: uri.pathSegments.first,
    username: Uri.decodeComponent(user.first),
    password: Uri.decodeComponent(user.skip(1).join(':')),
  );
}

const _settings = ConnectionSettings(sslMode: SslMode.require);

void _row(String what, Object ms) =>
    stdout.writeln('  ${what.padRight(44)} $ms');

Future<void> _network(String appUrl) async {
  stdout.writeln('A. Network (sidra_app, pooled endpoint, like the app)');
  final w = Stopwatch()..start();
  final conn = await Connection.open(_endpoint(appUrl), settings: _settings);
  _row('open connection (TCP + TLS + login)', '${w.elapsedMilliseconds} ms');
  final single = <int>[];
  for (var i = 0; i < 5; i++) {
    w.reset();
    await conn.execute('select 1');
    single.add(w.elapsedMilliseconds);
  }
  _row('one statement (round trip)', '${single.join(' / ')} ms');
  final tx = <int>[];
  for (var i = 0; i < 5; i++) {
    w.reset();
    await conn.runTx((s) async {
      // Stands in for app_private.authenticate(token) + the call itself.
      await s.execute('select 1');
      await s.execute('select count(*) from courses');
    });
    tx.add(w.elapsedMilliseconds);
  }
  _row('one app call (begin, bind, query, commit)', '${tx.join(' / ')} ms');
  final one = <int>[];
  for (var i = 0; i < 5; i++) {
    w.reset();
    // How the app sends a call now: binding + query in one message, which
    // PostgreSQL runs as one transaction.
    final r = await conn.execute(
      r"do $s$ begin perform set_config('sidra.probe', 'x', true); end $s$; "
      r"select (select count(*) from courses where title <> E'it''s \\ ok')::text",
      queryMode: QueryMode.simple,
    );
    if (r.length != 1) throw StateError('expected one row, got ${r.length}');
    one.add(w.elapsedMilliseconds);
  }
  _row('one app call, single message (new)', '${one.join(' / ')} ms');
  w.reset();
  await Future.wait([
    for (var i = 0; i < 8; i++) conn.runTx((s) => s.execute('select 1')),
  ]);
  _row('8 calls on the one connection (queued)', '${w.elapsedMilliseconds} ms');
  await conn.close();
}

/// Times each statement inside the database as the given user.
Future<void> _server(String ownerUrl) async {
  stdout.writeln('\nB. Server time per screen query (no network)');
  final conn = await Connection.open(_endpoint(ownerUrl), settings: _settings);
  try {
    final sizes = await conn.execute(
      "select relname, n_live_tup from pg_stat_user_tables "
      "where schemaname = 'public' order by n_live_tup desc limit 8",
    );
    stdout.writeln(
      '  largest tables: '
      '${sizes.map((r) => '${r[0]} ${r[1]}').join(', ')}',
    );

    final learner = (await conn.execute(
      "select e.user_id, (array_agg(e.course_id order by e.course_id))[1] "
      "from course_enrolments e where e.has_access "
      "group by e.user_id order by count(*) desc limit 1",
    ));
    final teacher = await conn.execute(
      "select user_id from teaching_group_teachers group by user_id "
      "order by count(*) desc limit 1",
    );
    final admin = await conn.execute(
      "select id from users where role = 'admin' and is_active limit 1",
    );

    if (learner.isNotEmpty) {
      final u = learner.first[0]! as String;
      final c = learner.first[1]! as String;
      await _as(conn, 'learner', u, [
        'select count(*) from public.my_courses()',
        'select count(*) from public.top_courses()',
        'select count(*) from public.learner_today()',
        "select count(*) from public.course_lesson_order('$c')",
        "select public.my_course_access('$c')",
        'select count(*) from public.my_notifications()',
        "select count(*) from courses",
        "select count(*) from lessons where course_id = '$c'",
        "select count(*) from curriculum_nodes",
        'select count(*) from lesson_content_blocks',
      ]);
    }
    if (teacher.isNotEmpty) {
      await _as(conn, 'teacher', teacher.first[0]! as String, [
        'select count(*) from public.my_teaching_groups()',
        'select public.teacher_attention()',
        'select public.teaching_analytics()',
        'select count(*) from public.my_notifications()',
      ]);
    }
    if (admin.isNotEmpty) {
      await _as(conn, 'admin', admin.first[0]! as String, [
        'select count(*) from users',
        'select count(*) from course_enrolments',
        'select count(*) from payments',
        'select public.finance_summary()',
        'select count(*) from courses',
        'select count(*) from lessons',
      ]);
    }
  } finally {
    await conn.close();
  }
}

Future<void> _as(
  Connection conn,
  String who,
  String userId,
  List<String> statements,
) async {
  stdout.writeln('  as the busiest $who:');
  for (final sql in statements) {
    try {
      await conn.execute('begin');
      late final int ms;
      try {
        await conn.execute(
          r'insert into app_private.connection_identity (backend_pid, xact, user_id) '
          r'values (pg_backend_pid(), pg_current_xact_id(), $1::uuid) '
          r'on conflict (backend_pid) do update '
          r'set xact = excluded.xact, user_id = excluded.user_id',
          parameters: [userId],
        );
        await conn.execute('set local role authenticated');
        // Timed inside one statement: no network in the number.
        final escaped = sql.replaceAll("'", "''");
        await conn.execute(
          r"do $probe$ declare t0 timestamptz := clock_timestamp(); begin "
          "execute '$escaped'; "
          r"perform set_config('probe.ms', "
          r"round(extract(epoch from clock_timestamp() - t0) * 1000)::text, true); "
          r"end $probe$",
          queryMode: QueryMode.simple,
        );
        final r = await conn.execute("select current_setting('probe.ms')");
        ms = int.parse('${r.first[0]}');
      } finally {
        await conn.execute('rollback');
      }
      _row(sql.length > 44 ? '${sql.substring(0, 41)}...' : sql, '$ms ms');
    } catch (e) {
      _row(
        sql.length > 44 ? '${sql.substring(0, 41)}...' : sql,
        'error: ${'$e'.split('\n').first}',
      );
    }
  }
}
