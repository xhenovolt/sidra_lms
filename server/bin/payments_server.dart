// Sidra payments server.
//
//   cd server && dart run bin/payments_server.dart
//
// Environment (or ../.env on a developer machine):
//   PAYMENTS_DATABASE_URL  sidra_payments login (tool/db.dart payments-role)
//   MARZPAY_API_KEY / MARZPAY_API_SECRET (or MARZPAY_AUTH_BASIC)
//   MARZPAY_BASE_URL       default https://wallet.wearemarz.com/api/v1
//   PUBLIC_URL             optional, e.g. https://pay.almuntahha.org — MarzPay
//                          then calls PUBLIC_URL/marzpay/webhook
//   PORT                   default 8080
//
// What it does
//   1. Sends queued collections (payments_api.claim) to MarzPay. Woken
//      instantly by NOTIFY sidra_payments, and every 5 s as a fallback.
//   2. Every 20 s asks MarzPay about payments still waiting on the payer.
//   3. POST /marzpay/webhook: never trusts the body — re-fetches the
//      transaction from MarzPay, then records it (payments_api.settle).
//   GET /health reports liveness.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import 'package:sidra_payments_server/marzpay.dart';

Future<void> main() async {
  final env = _environment();
  final dbUrl = env['PAYMENTS_DATABASE_URL'];
  if (dbUrl == null) {
    stderr.writeln('PAYMENTS_DATABASE_URL is not set');
    exit(64);
  }
  final server = PaymentsServer(
    db: await _connect(dbUrl),
    marz: MarzPayClient.fromEnv(env),
    publicUrl: env['PUBLIC_URL'],
  );
  await server.start(int.tryParse(env['PORT'] ?? '') ?? 8080);
}

class PaymentsServer {
  PaymentsServer({required this.db, required this.marz, this.publicUrl});

  Connection db;
  final MarzPayClient marz;
  final String? publicUrl;
  DateTime? lastQueueRun;
  DateTime? lastReconcileRun;
  bool _queueBusy = false;
  bool _reconcileBusy = false;

  Future<void> start(int port) async {
    await _listen();
    Timer.periodic(const Duration(seconds: 5), (_) => runQueue());
    Timer.periodic(const Duration(seconds: 20), (_) => reconcile());
    unawaited(runQueue());
    unawaited(reconcile());

    final http = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _log(
      'listening on :$port'
      '${publicUrl == null ? ' (no PUBLIC_URL: polling only)' : ''}',
    );
    await for (final req in http) {
      unawaited(_handle(req));
    }
  }

  Future<void> _listen() async {
    try {
      await db.execute('listen sidra_payments');
      db.channels['sidra_payments'].listen((_) => runQueue());
    } catch (e) {
      _log('LISTEN unavailable ($e); relying on polling');
    }
  }

  // ------------------------------------------------------------- queue --

  Future<void> runQueue() async {
    if (_queueBusy) return;
    _queueBusy = true;
    try {
      final rows = await _db(
        (c) => c.execute(
          'select id, reference, amount, currency, phone, description '
          'from payments_api.claim(10)',
        ),
      );
      for (final r in rows) {
        await _send(
          id: '${r[0]}',
          reference: '${r[1]}',
          amount: num.parse('${r[2]}'),
          phone: '${r[4]}',
          description: '${r[5]}',
        );
      }
      lastQueueRun = DateTime.now();
    } catch (e) {
      _log('queue: $e');
    } finally {
      _queueBusy = false;
    }
  }

  Future<void> _send({
    required String id,
    required String reference,
    required num amount,
    required String phone,
    required String description,
  }) async {
    try {
      final c = await marz.collect(
        amount: amount.round(),
        phone: phone,
        reference: reference,
        description: description,
        callbackUrl: publicUrl == null ? null : '$publicUrl/marzpay/webhook',
        metadata: [
          {'payment_id': id},
        ],
      );
      await _submitted(id, c.uuid, c.provider, c.status);
      _log('sent $id → ${c.uuid} (${c.provider}, ${c.status})');
    } on MarzPayException catch (e) {
      if (e.errorCode == 'DUPLICATE_REFERENCE') {
        // Sent before (e.g. we crashed after sending): find it, don't resend.
        final credit = (await marz.transactionsFor(
          reference,
        )).where((t) => t.type == 'credit').firstOrNull;
        if (credit != null) {
          await _submitted(id, credit.uuid, null, credit.status);
          _log('recovered $id → ${credit.uuid}');
          return;
        }
      }
      final permanent = !e.transient;
      await _db(
        (c) => c.execute(
          Sql.named(
            'select payments_api.submit_failed(@id::uuid, @err, @perm)',
          ),
          parameters: {'id': id, 'err': e.message, 'perm': permanent},
        ),
      );
      _log('send $id failed (${permanent ? 'permanent' : 'will retry'}): $e');
    }
  }

  Future<void> _submitted(
    String id,
    String uuid,
    String? provider,
    String status,
  ) => _db(
    (c) => c.execute(
      Sql.named(
        'select payments_api.submitted(@id::uuid, @uuid, @provider, @status)',
      ),
      parameters: {
        'id': id,
        'uuid': uuid,
        'provider': provider,
        'status': status,
      },
    ),
  );

  // --------------------------------------------------------- reconcile --

  Future<void> reconcile() async {
    if (_reconcileBusy) return;
    _reconcileBusy = true;
    try {
      final rows = await _db(
        (c) => c.execute(
          'select provider_uuid, reference from payments_api.to_reconcile(20)',
        ),
      );
      for (final r in rows) {
        await settleFromMarzPay('${r[0]}', reference: '${r[1]}');
      }
      lastReconcileRun = DateTime.now();
    } catch (e) {
      _log('reconcile: $e');
    } finally {
      _reconcileBusy = false;
    }
  }

  /// Asks MarzPay for the truth about [uuid] and records it.
  Future<String> settleFromMarzPay(String uuid, {String? reference}) async {
    final c = await marz.status(uuid);
    num? fee;
    if (c.succeeded) {
      try {
        final ref = reference ?? c.reference;
        fee = (await marz.transactionsFor(ref))
            .where((t) => t.type == 'debit')
            .fold<num>(0, (sum, t) => sum + (t.amount ?? 0));
      } catch (_) {
        fee = null; // fee is informative; never block crediting on it
      }
    }
    final r = await _db(
      (conn) => conn.execute(
        Sql.named(
          'select payments_api.settle(@uuid, @status, @amount::numeric, @ref, '
          '@payload::jsonb, @fee::numeric)',
        ),
        parameters: {
          'uuid': uuid,
          'status': c.status,
          'amount': c.amount?.toString(),
          'ref': c.providerReference,
          'payload': jsonEncode(c.raw),
          'fee': fee?.toString(),
        },
      ),
    );
    final outcome = '${r.first.first}';
    if (outcome != 'processing') _log('settled $uuid: ${c.status} → $outcome');
    return outcome;
  }

  // -------------------------------------------------------------- http --

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      if (req.method == 'GET' && req.uri.path == '/health') {
        res.headers.contentType = ContentType.json;
        res.write(
          jsonEncode({
            'ok': true,
            'last_queue_run': lastQueueRun?.toIso8601String(),
            'last_reconcile_run': lastReconcileRun?.toIso8601String(),
          }),
        );
      } else if (req.method == 'POST' && req.uri.path == '/marzpay/webhook') {
        final body = await utf8.decoder.bind(req).join();
        final uuid = _webhookUuid(body);
        // Acknowledge first; the payload itself is never trusted.
        res.statusCode = HttpStatus.ok;
        res.write('{"received":true}');
        if (uuid != null) {
          unawaited(
            settleFromMarzPay(uuid).catchError((Object e) {
              _log('webhook $uuid: $e');
              return 'error';
            }),
          );
        }
      } else {
        res.statusCode = HttpStatus.notFound;
      }
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      _log('http: $e');
    } finally {
      await res.close();
    }
  }

  static String? _webhookUuid(String body) {
    if (body.length > 64 * 1024) return null;
    try {
      final j = (jsonDecode(body) as Map).cast<String, dynamic>();
      final tx =
          (j['transaction'] as Map?) ?? (j['data'] as Map?)?['transaction'];
      final uuid = tx?['uuid']?.toString();
      return uuid != null && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(uuid)
          ? uuid
          : null;
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------ helpers --

  /// Runs [f], reconnecting once if the connection dropped.
  Future<T> _db<T>(Future<T> Function(Connection c) f) async {
    try {
      if (!db.isOpen) throw StateError('closed');
      return await f(db);
    } catch (e) {
      if (db.isOpen && e is! StateError) rethrow;
      db = await _connect(_environment()['PAYMENTS_DATABASE_URL']!);
      await _listen();
      return f(db);
    }
  }
}

Future<Connection> _connect(String url) {
  final uri = Uri.parse(url);
  final user = uri.userInfo.split(':');
  return Connection.open(
    Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: uri.pathSegments.first,
      username: Uri.decodeComponent(user[0]),
      password: Uri.decodeComponent(user.sublist(1).join(':')),
    ),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );
}

/// Real environment wins; ../.env or .env fills gaps on a developer machine.
Map<String, String> _environment() {
  final env = <String, String>{};
  for (final path in ['../.env', '.env']) {
    final f = File(path);
    if (!f.existsSync()) continue;
    for (final line in f.readAsLinesSync()) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('#') || !t.contains('=')) continue;
      final i = t.indexOf('=');
      var v = t.substring(i + 1).trim();
      if (v.length >= 2 &&
          (v.startsWith('"') && v.endsWith('"') ||
              v.startsWith("'") && v.endsWith("'"))) {
        v = v.substring(1, v.length - 1);
      }
      env.putIfAbsent(t.substring(0, i).trim(), () => v);
    }
  }
  return {...env, ...Platform.environment};
}

void _log(String m) => stdout.writeln('${DateTime.now().toIso8601String()} $m');
