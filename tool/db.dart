// Sidra database tool: talks to Neon PostgreSQL directly with the owner
// connection string from .env (developer machines only, never the app).
//
//   dart run tool/db.dart status
//   dart run tool/db.dart test               # pending migrations + db/tests/*.sql, rolled back
//   dart run tool/db.dart migrate            # apply pending migrations + sync settings
//   dart run tool/db.dart promote <phone|email> <admin|teacher|learner>
//   SIDRA_NEW_PASSWORD=… dart run tool/db.dart create-user --name "Full Name" \n//       [--phone +256…] [--email …] [--username …] --role superadmin|admin|teacher|learner
//   dart run tool/db.dart push-role          # login for the push Worker → .env PUSH_DATABASE_URL
//   dart run tool/db.dart app-role           # (re)create the app's own login → .env APP_DATABASE_URL
import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
        await _test(conn, args.skip(1).toList());
      case 'promote':
        if (args.length != 3) {
          _usage();
          exit(64);
        }
        await _promote(conn, args[1], args[2]);
      case 'create-user':
        await _createUser(conn, _flags(args.skip(1).toList()));
      case 'app-role':
        await _appRole(conn, url);
      case 'payments-role':
        await _paymentsRole(conn, url);
      case 'push-role':
        await _pushRole(conn, url);
      case 'query':
        // Read-only inspection: dart run tool/db.dart query "select …"
        await conn.execute('begin read only');
        try {
          final r = await conn.execute(args.skip(1).join(' '));
          stdout.writeln(r.schema.columns.map((c) => c.columnName).join(' | '));
          for (final row in r) {
            stdout.writeln(row.map((v) => '$v').join(' | '));
          }
        } finally {
          await conn.execute('rollback');
        }
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
  'promote <phone|email> <admin|teacher|learner> | app-role | payments-role | push-role | create-user',
);

class _Abort implements Exception {
  _Abort(this.message);
  final String message;
}

Future<Connection> _connect(String url) {
  final uri = Uri.parse(url);
  final userInfo = uri.userInfo.split(':');
  // Networks that block port 5432: run `node tool/pg_ws_bridge.mjs` and set
  // SIDRA_DB_BRIDGE=127.0.0.1:55432. The bridge carries the connection over
  // Neon's WebSocket endpoint (HTTPS, port 443), which provides the TLS.
  final bridge = Platform.environment['SIDRA_DB_BRIDGE'];
  if (bridge != null && bridge.isNotEmpty) {
    final parts = bridge.split(':');
    return Connection.open(
      Endpoint(
        host: parts.first,
        port: int.parse(parts.last),
        database: uri.pathSegments.first,
        username: Uri.decodeComponent(userInfo.first),
        password: Uri.decodeComponent(userInfo.skip(1).join(':')),
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
  }
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
/// Runs pending migrations and the database tests in one transaction that
/// is always rolled back. `only` limits the run to test files whose name
/// contains one of the words. Each file goes to the server as one batch (a
/// single round trip), so slow or far-away links finish quickly; a failure
/// is then re-run statement by statement to point at the failing one.
Future<void> _test(Connection conn, [List<String> only = const []]) async {
  final tests =
      Directory(_testsDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sql'))
          .where(
            (f) =>
                only.isEmpty ||
                only.any((w) => f.uri.pathSegments.last.contains(w)),
          )
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
      await conn.execute('savepoint test_file');
      try {
        await conn.execute(
          _asOneBlock(statements),
          queryMode: QueryMode.simple,
        );
        await conn.execute('release savepoint test_file');
        stdout.writeln('passed (${statements.length} statements)');
        continue;
      } on ServerException catch (e) {
        stderr.writeln('\n  ${e.message}');
        // Re-run one statement at a time to show the failing one.
        await conn.execute('rollback to savepoint test_file');
      }
      for (final (i, stmt) in statements.indexed) {
        try {
          await conn.execute(stmt, queryMode: QueryMode.simple);
        } catch (_) {
          final preview = stmt.replaceAll(RegExp(r'\s+'), ' ');
          final shown = preview.length > 300
              ? '${preview.substring(0, 300)}…'
              : preview;
          stderr.writeln('\n  statement #${i + 1}: $shown');
          rethrow;
        }
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

/// All statements of a test file as one `DO` block (one round trip). Each
/// statement runs through EXECUTE in order; a failure names its number.
String _asOneBlock(List<String> statements) {
  final b = StringBuffer('do \$sidra_block\$\ndeclare n int := 0;\nbegin\n');
  for (final (i, s) in statements.indexed) {
    final body = s.trim().replaceFirst(RegExp(r';\s*$'), '');
    b.writeln('  n := ${i + 1};');
    b.writeln('  execute \$sidra_s${i + 1}\$$body\$sidra_s${i + 1}\$;');
  }
  b.write(
    'exception when others then\n'
    "  raise exception 'statement %: %', n, sqlerrm;\n"
    'end \$sidra_block\$',
  );
  return b.toString();
}

/// Changes a user's role, found by phone (E.164) or email.
Future<void> _promote(Connection conn, String identifier, String role) async {
  if (!{'admin', 'teacher', 'learner'}.contains(role)) {
    throw _Abort('role must be admin, teacher or learner');
  }
  await conn.runTx((tx) async {
    await tx.execute("select set_config('sidra.role_change', 'allowed', true)");
    final r = await tx.execute(
      Sql.named(
        'update users set role = @r::app_role '
        'where lower(email) = lower(@i) or phone = @i '
        '   or phone = (select value from auth_api.normalize_identifier(@i)) '
        'returning display_name, coalesce(email, phone)',
      ),
      parameters: {'r': role, 'i': identifier.trim()},
    );
    if (r.isEmpty) {
      throw _Abort(
        'No account with phone/email "$identifier". '
        'Create it in the app (Create account) first.',
      );
    }
    stdout.writeln('${r.first[0] ?? r.first[1]} is now $role.');
  });
}

Map<String, String> _flags(List<String> a) {
  final out = <String, String>{};
  for (var i = 0; i + 1 < a.length; i += 2) {
    if (!a[i].startsWith('--')) throw _Abort('Unexpected argument ${a[i]}');
    out[a[i].substring(2)] = a[i + 1];
  }
  return out;
}

/// Creates an account directly (owner connection). The password comes from
/// the SIDRA_NEW_PASSWORD environment variable, never from the command line.
Future<void> _createUser(Connection conn, Map<String, String> f) async {
  final password = Platform.environment['SIDRA_NEW_PASSWORD'];
  final role = f['role'] ?? 'learner';
  if (password == null || password.length < 8) {
    throw _Abort('Set SIDRA_NEW_PASSWORD (8+ characters).');
  }
  if (f['name'] == null) throw _Abort('--name is required');
  if (!{'superadmin', 'admin', 'teacher', 'learner'}.contains(role)) {
    throw _Abort('--role must be superadmin, admin, teacher or learner');
  }
  final r = await conn.execute(
    Sql.named(
      'select app_private.create_account('
      '@name, @phone, @email, @username, @role::app_role, @super, @pw, false)',
    ),
    parameters: {
      'name': f['name'],
      'phone': f['phone'],
      'email': f['email'],
      'username': f['username'],
      'role': role == 'superadmin' ? 'admin' : role,
      'super': role == 'superadmin',
      'pw': password,
    },
  );
  // Separate statement: a STABLE function in the same statement would not
  // see the row just inserted.
  final id = r.first.first;
  final p =
      (await conn.execute(
            Sql.named('select auth_api._profile(@id::uuid)'),
            parameters: {'id': '$id'},
          )).first.first!
          as Map;
  stdout.writeln(
    'Created ${p['display_name']} ('
    '${p['is_superadmin'] == true ? 'superadmin' : p['role']}): '
    'phone ${p['phone']}, email ${p['email']}, username ${p['username']}',
  );
}

/// Gives the app its own low-privilege login (sidra_app) and writes the
/// connection string to .env as APP_DATABASE_URL, from where
/// tool/gen_config.dart puts it in the build. This login is PUBLIC by design
/// (it ships in the APK); see migration 0011 for why that is safe.
Future<void> _appRole(Connection conn, String ownerUrl) async {
  final rnd = Random.secure();
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  final password = List.generate(
    40,
    (_) => chars[rnd.nextInt(chars.length)],
  ).join();
  await conn.execute("alter role sidra_app with login password '$password'");
  final owner = Uri.parse(ownerUrl);
  final url = owner.replace(
    userInfo: 'sidra_app:${Uri.encodeComponent(password)}',
    queryParameters: {'sslmode': 'require'},
  );
  final envFile = File('.env');
  final lines = envFile.readAsLinesSync()
    ..removeWhere((l) => l.startsWith('APP_DATABASE_URL='));
  final at = lines.indexWhere((l) => l.startsWith('CLOUDINARY_CLOUD_NAME='));
  final entry = [
    '# App login (sidra_app): public by design, can only act as a signed-in user',
    'APP_DATABASE_URL=$url',
  ];
  if (at < 0) {
    lines.addAll(entry);
  } else {
    lines.insertAll(at, entry);
  }
  envFile.writeAsStringSync('${lines.join('\n')}\n');
  stdout.writeln('sidra_app can log in; APP_DATABASE_URL written to .env.');
}

/// Gives the payments server (sidra_payments) a login and writes
/// PAYMENTS_DATABASE_URL to .env. It uses the DIRECT host (not the pooler)
/// so LISTEN/NOTIFY works. The role can only call payments_api functions.
Future<void> _paymentsRole(Connection conn, String ownerUrl) async {
  final rnd = Random.secure();
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  final password = List.generate(
    40,
    (_) => chars[rnd.nextInt(chars.length)],
  ).join();
  await conn.execute(
    "alter role sidra_payments with login password '$password'",
  );
  final owner = Uri.parse(ownerUrl);
  final url = owner.replace(
    host: owner.host.replaceFirst('-pooler.', '.'),
    userInfo: 'sidra_payments:${Uri.encodeComponent(password)}',
    queryParameters: {'sslmode': 'require'},
  );
  final envFile = File('.env');
  final lines = envFile.readAsLinesSync()
    ..removeWhere(
      (l) =>
          l.startsWith('PAYMENTS_DATABASE_URL=') ||
          l.startsWith('# Payments server login'),
    )
    ..addAll([
      '# Payments server login (sidra_payments): server-side only, never in the app',
      'PAYMENTS_DATABASE_URL=$url',
    ]);
  envFile.writeAsStringSync('${lines.join('\n')}\n');
  stdout.writeln(
    'sidra_payments can log in; PAYMENTS_DATABASE_URL written to .env.',
  );
}

/// Gives the push Worker (sidra_push) a login and writes PUSH_DATABASE_URL
/// to .env, to paste into the Cloudflare Worker's DATABASE_URL secret. The
/// role can only call push_api.claim and push_api.drop_tokens.
Future<void> _pushRole(Connection conn, String ownerUrl) async {
  final rnd = Random.secure();
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  final password = List.generate(
    40,
    (_) => chars[rnd.nextInt(chars.length)],
  ).join();
  await conn.execute("alter role sidra_push with login password '$password'");
  final owner = Uri.parse(ownerUrl);
  final url = owner.replace(
    host: owner.host.replaceFirst('-pooler.', '.'),
    userInfo: 'sidra_push:${Uri.encodeComponent(password)}',
    queryParameters: {'sslmode': 'require'},
  );
  final envFile = File('.env');
  final lines = envFile.readAsLinesSync()
    ..removeWhere(
      (l) =>
          l.startsWith('PUSH_DATABASE_URL=') ||
          l.startsWith('# Push Worker login'),
    )
    ..addAll([
      '# Push Worker login (sidra_push): Cloudflare secret DATABASE_URL, never in the app',
      'PUSH_DATABASE_URL=$url',
    ]);
  envFile.writeAsStringSync('${lines.join('\n')}\n');
  stdout.writeln('sidra_push can log in; PUSH_DATABASE_URL written to .env.');
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
