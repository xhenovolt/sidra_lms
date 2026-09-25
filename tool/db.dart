// Sidra database tool: talks to Neon PostgreSQL directly with the owner
// connection string from .env (developer machines only, never the app).
//
//   dart run tool/db.dart status
//   dart run tool/db.dart test               # pending migrations + db/tests/*.sql, rolled back
//   dart run tool/db.dart migrate            # apply pending migrations + sync settings
//   dart run tool/db.dart promote <clerk_user_id> <admin|teacher|learner>
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import 'gen_config.dart' show parseDotEnv;

const _migrationsDir = 'db/migrations';
const _testsDir = 'db/tests';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _usage();
    exit(64);
  }
  final env = parseDotEnv(File('.env').readAsStringSync());
  final url = env['DATABASE_URL'];
  if (url == null || url.isEmpty) {
    stderr.writeln('DATABASE_URL missing from .env');
    exit(1);
  }

  final conn = await _connect(url);
  try {
    switch (args.first) {
      case 'status':
        await _status(conn);
      case 'migrate':
        await _migrate(conn, env);
      case 'test':
        await _test(conn);
      case 'promote':
        if (args.length != 3) {
          _usage();
          exit(64);
        }
        await _promote(conn, args[1], args[2]);
      default:
        _usage();
        exit(64);
    }
  } on _Abort catch (e) {
    stderr.writeln(e.message);
    exitCode = 1;
  } on ServerException catch (e) {
    stderr.writeln('PostgreSQL error [${e.code}]: ${e.message}');
    if (e.detail != null) stderr.writeln('  detail: ${e.detail}');
    exitCode = 1;
  } finally {
    await conn.close();
  }
}

void _usage() => stderr.writeln(
  'Usage: dart run tool/db.dart status | test | migrate | '
  'promote <clerk_user_id> <admin|teacher|learner>',
);

class _Abort implements Exception {
  _Abort(this.message);
  final String message;
}

Future<Connection> _connect(String url) {
  final uri = Uri.parse(url);
  final userInfo = uri.userInfo.split(':');
  return Connection.open(
    Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: uri.pathSegments.first,
      username: Uri.decodeComponent(userInfo.first),
      password: Uri.decodeComponent(userInfo.skip(1).join(':')),
    ),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );
}

class _Migration {
  _Migration(this.name, this.sql)
    : checksum = sha256.convert(utf8.encode(sql)).toString();
  final String name;
  final String sql;
  final String checksum;
}

List<_Migration> _loadMigrations() {
  final files =
      Directory(_migrationsDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sql'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final f in files)
      _Migration(f.uri.pathSegments.last, f.readAsStringSync()),
  ];
}

Future<void> _ensureLedger(Session s) => s.execute('''
  create table if not exists public.schema_migrations (
    filename text primary key,
    checksum text not null,
    applied_at timestamptz not null default now()
  )''');

/// Pending migrations, after verifying applied ones are unchanged.
Future<List<_Migration>> _pending(Session s) async {
  await _ensureLedger(s);
  final applied = {
    for (final r in await s.execute(
      'select filename, checksum from public.schema_migrations',
    ))
      r[0] as String: r[1] as String,
  };
  final all = _loadMigrations();
  for (final m in all) {
    final sum = applied[m.name];
    if (sum != null && sum != m.checksum) {
      throw _Abort(
        '${m.name} was modified after being applied. '
        'Never edit applied migrations; add a new one.',
      );
    }
  }
  return [
    for (final m in all)
      if (!applied.containsKey(m.name)) m,
  ];
}

Future<void> _apply(Session s, _Migration m) async {
  await s.execute(m.sql, queryMode: QueryMode.simple);
  await s.execute(
    Sql.named(
      'insert into public.schema_migrations (filename, checksum) '
      'values (@f, @c)',
    ),
    parameters: {'f': m.name, 'c': m.checksum},
  );
}

Future<void> _status(Connection conn) async {
  final pending = {for (final m in await _pending(conn)) m.name};
  for (final m in _loadMigrations()) {
    final state = pending.contains(m.name) ? 'PENDING' : 'applied';
    stdout.writeln('  ${state.padRight(8)} ${m.name}');
  }
  stdout.writeln(
    pending.isEmpty ? 'Database is up to date.' : '${pending.length} pending.',
  );
}

Future<void> _migrate(Connection conn, Map<String, String> env) async {
  await conn.runTx((tx) async {
    final pending = await _pending(tx);
    for (final m in pending) {
      stdout.writeln('applying ${m.name}');
      await _apply(tx, m);
    }
    await _syncSettings(tx, env);
    stdout.writeln(
      pending.isEmpty
          ? 'No pending migrations. Settings synced.'
          : 'Applied ${pending.length} migration(s). Settings synced.',
    );
  });
}

/// Copies server-side secrets from .env into app_private.settings.
Future<void> _syncSettings(Session s, Map<String, String> env) async {
  const keys = {
    'CLOUDINARY_CLOUD_NAME': 'cloudinary_cloud_name',
    'CLOUDINARY_API_KEY': 'cloudinary_api_key',
    'CLOUDINARY_API_SECRET': 'cloudinary_api_secret',
  };
  for (final e in keys.entries) {
    final v = env[e.key];
    if (v == null || v.isEmpty) {
      stdout.writeln('  settings: ${e.key} not in .env (skipped)');
      continue;
    }
    await s.execute(
      Sql.named(
        'insert into app_private.settings (key, value) values (@k, @v) '
        'on conflict (key) do update set value = excluded.value, updated_at = now()',
      ),
      parameters: {'k': e.value, 'v': v},
    );
    stdout.writeln('  settings: ${e.value} set');
  }
}

/// Runs pending migrations and every db/tests/*.sql file in ONE
/// transaction, then rolls back. Nothing is left in the database.
Future<void> _test(Connection conn) async {
  final tests =
      Directory(_testsDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sql'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  await conn.execute('begin');
  try {
    final pending = await _pending(conn);
    for (final m in pending) {
      stdout.writeln('(tx) applying ${m.name}');
      await _apply(conn, m);
    }
    for (final t in tests) {
      stdout.write('(tx) running ${t.uri.pathSegments.last} … ');
      final statements = splitSql(t.readAsStringSync());
      for (final stmt in statements) {
        await conn.execute(stmt, queryMode: QueryMode.simple);
      }
      stdout.writeln('passed (${statements.length} statements)');
    }
    stdout.writeln('All database tests passed.');
  } catch (e) {
    stdout.writeln('FAILED');
    stderr.writeln(e);
    exitCode = 1;
  } finally {
    if (conn.isOpen) {
      await conn.execute('rollback');
      stdout.writeln('(rolled back — database unchanged)');
    } else {
      stdout.writeln('(connection closed — server discarded the transaction)');
    }
  }
}

Future<void> _promote(Connection conn, String clerkId, String role) async {
  if (!{'admin', 'teacher', 'learner'}.contains(role)) {
    throw _Abort('role must be admin, teacher or learner');
  }
  await conn.runTx((tx) async {
    await tx.execute("select set_config('sidra.role_change', 'allowed', true)");
    final r = await tx.execute(
      Sql.named(
        'update users set role = @r::app_role where clerk_user_id = @c '
        'returning display_name, email',
      ),
      parameters: {'r': role, 'c': clerkId},
    );
    if (r.isEmpty) {
      throw _Abort(
        'No user with clerk_user_id "$clerkId". '
        'Sign in to the app once first so your profile is created.',
      );
    }
    stdout.writeln('${r.first[0] ?? r.first[1] ?? clerkId} is now $role.');
  });
}

/// Splits a SQL script into statements on top-level `;`, respecting
/// 'strings', "identifiers", $tag$ dollar quotes $tag$, -- and /* */ comments.
List<String> splitSql(String sql) {
  final out = <String>[];
  final buf = StringBuffer();
  var i = 0;
  String? dollarTag;
  while (i < sql.length) {
    final c = sql[i];
    if (dollarTag != null) {
      if (sql.startsWith(dollarTag, i)) {
        buf.write(dollarTag);
        i += dollarTag.length;
        dollarTag = null;
      } else {
        buf.write(c);
        i++;
      }
      continue;
    }
    if (c == '-' && sql.startsWith('--', i)) {
      final end = sql.indexOf('\n', i);
      i = end == -1 ? sql.length : end;
      continue;
    }
    if (c == '/' && sql.startsWith('/*', i)) {
      final end = sql.indexOf('*/', i + 2);
      i = end == -1 ? sql.length : end + 2;
      continue;
    }
    if (c == "'" || c == '"') {
      var j = i + 1;
      while (j < sql.length) {
        if (sql[j] == c) {
          if (j + 1 < sql.length && sql[j + 1] == c) {
            j += 2;
            continue;
          }
          break;
        }
        j++;
      }
      buf.write(sql.substring(i, j + 1 > sql.length ? sql.length : j + 1));
      i = j + 1;
      continue;
    }
    if (c == r'$') {
      final m = RegExp(r'\$[A-Za-z_]*\$').matchAsPrefix(sql, i);
      if (m != null) {
        dollarTag = m.group(0);
        buf.write(dollarTag);
        i = m.end;
        continue;
      }
    }
    if (c == ';') {
      final stmt = buf.toString().trim();
      if (stmt.isNotEmpty) out.add(stmt);
      buf.clear();
      i++;
      continue;
    }
    buf.write(c);
    i++;
  }
  final tail = buf.toString().trim();
  if (tail.isNotEmpty) out.add(tail);
  return out;
}
