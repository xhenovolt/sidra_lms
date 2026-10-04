import 'dart:async';
import 'dart:convert';

import '../network/postgres_api.dart';
import 'direct_payments.dart';
import 'marzpay_client.dart';

/// The MarzPay test centre, run on the administrator's own phone with the
/// keys this build carries (server/lib/payment_tests.dart does the same on
/// the payments server). Each test writes its steps as they happen
/// (payment_test_step) and ends with one honest result
/// (payment_test_finish):
///
///   verified_success   proven (e.g. MarzPay's ledger shows the money)
///   provider_accepted  MarzPay took the request; the outcome isn't proven
///   failed / cancelled / pending / unknown
///   blocked            something outside Sidra prevents it (IP whitelist…)
///   unsupported        not offered
///
/// Money tests run once. Nothing is retried automatically.
class PhoneTestRunner {
  PhoneTestRunner({
    required this.api,
    required this.marz,
    this.pollEvery = const Duration(seconds: 5),
    this.pollFor = const Duration(minutes: 4),
  });

  final PostgresApi api;
  final MarzPayClient marz;
  final Duration pollEvery;
  final Duration pollFor;

  late String _id;
  var _n = 0;

  Future<void> _step(String label, String state, [String? detail]) => api.rpc(
    'payment_test_step',
    params: {
      'p_id': _id,
      'p_step': {'step': ++_n, 'label': label, 'state': state, 'detail': ?detail},
    },
  );

  Future<void> _finish({
    required String result,
    String? providerUuid,
    String? providerStatus,
    String? errorCode,
    String? message,
    Map<String, Object?> evidence = const {},
    String? environment,
  }) => api.rpc(
    'payment_test_finish',
    params: {
      'p_id': _id,
      'p_result': result,
      'p_provider_uuid': providerUuid,
      'p_provider_status': providerStatus,
      'p_error_code': errorCode,
      'p_message': message,
      'p_evidence': evidence,
      'p_environment': environment,
    },
  );

  /// Creates the test (request_payment_test with p_run_here) and runs it.
  /// [phone] is the full number for money tests; the database keeps only a
  /// masked copy. Returns the test id at once; the run continues in the
  /// background and reports through the database.
  Future<String> start(
    String kind,
    Map<String, Object?> params,
    String? confirm,
  ) async {
    final id = '${await api.rpc('request_payment_test', params: {
      'p_kind': kind,
      'p_params': params,
      'p_confirm': confirm,
      'p_run_here': true,
    })}';
    final rows = await api.rpcRows('payment_tests', params: {'p_limit': 20});
    final test = rows
        .map((r) => Map<String, dynamic>.from((r['payment_tests'] ?? r) as Map))
        .where((t) => t['id'] == id)
        .firstOrNull;
    unawaited(
      run(id, kind, params, reference: test?['reference'] as String?),
    );
    return id;
  }

  Future<void> run(
    String id,
    String kind,
    Map<String, Object?> params, {
    String? reference,
  }) async {
    _id = id;
    _n = 0;
    try {
      switch (kind) {
        case 'connection':
          await _connection();
        case 'capabilities':
          await _capabilities();
        case 'balance':
          await _balance();
        case 'collection':
        case 'disbursement':
          await _money(kind == 'collection', params, reference);
        case 'status_lookup':
          await _lookup('${params['query'] ?? ''}'.trim());
        case 'callbacks':
          await _finish(
            result: 'unsupported',
            message:
                'This phone has no public address for MarzPay to call. Payments '
                'are confirmed by asking MarzPay directly, from the payer\'s phone '
                'and again from staff phones.',
          );
        case 'reconciliation':
          await _reconciliation();
        default:
          await _finish(result: 'unsupported', message: 'Unknown test.');
      }
    } catch (e) {
      try {
        await _finish(
          result: 'unknown',
          message:
              'The test stopped unexpectedly: $e. Check MarzPay before trying again.',
        );
      } catch (_) {}
    }
  }

  // --------------------------------------------------------- connection --

  Future<void> _connection() async {
    await _step(
      'Credentials in this app',
      'done',
      'API key ${marz.maskedKey}; ${marz.baseUrl}',
    );
    final p = await marz.probe('GET', '/collect-money/services');
    if (p.status == null) {
      final e = '${p.error}';
      final kind = e.contains('host lookup')
          ? 'The name wallet.wearemarz.com could not be found (DNS). Check this phone\'s internet.'
          : e.contains('Handshake') || e.contains('CERTIFICATE')
          ? 'A secure (TLS) connection could not be made.'
          : e.contains('timeout') || e.contains('timed out')
          ? 'MarzPay did not answer in time.'
          : 'MarzPay could not be reached: $e';
      await _step('Network, DNS and TLS', 'failed', kind);
      return _finish(result: 'failed', message: kind);
    }
    await _step(
      'Network, DNS and TLS',
      'done',
      'MarzPay answered over HTTPS in ${p.elapsed.inMilliseconds} ms (HTTP ${p.status}).',
    );
    if (p.status != 200) {
      final msg = p.status == 401 || p.status == 403
          ? 'MarzPay refused the credentials (${p.errorCode ?? 'HTTP ${p.status}'}): ${p.message ?? ''}'
          : 'Unexpected answer HTTP ${p.status}: ${p.message ?? ''}';
      await _step('Authentication', 'failed', msg);
      return _finish(result: 'failed', errorCode: p.errorCode, message: msg);
    }
    final data = (p.body?['data'] as Map?) ?? {};
    final account = '${(data['account'] as Map?)?['uuid'] ?? '?'}';
    final providers = _providers(p.body);
    final sandbox = providers.any((e) => '${e['mode']}'.contains('sandbox'));
    await _step('Authentication', 'done', 'Credentials accepted. Account ${_mask(account)}.');
    final bad = await marz.probe(
      'GET',
      '/collect-money/services',
      basicAuth: base64Encode(utf8.encode('invalid:invalid')),
    );
    await _step(
      'Wrong credentials are refused',
      bad.status == 401 || bad.status == 403 ? 'done' : 'failed',
      'Made-up credentials got HTTP ${bad.status ?? bad.error}.',
    );
    await _finish(
      result: 'verified_success',
      message:
          'Reachable from this phone, secure, and MarzPay accepted Sidra\'s '
          'credentials (${p.elapsed.inMilliseconds} ms).',
      evidence: {
        'account': _mask(account),
        'latency_ms': p.elapsed.inMilliseconds,
        'collection_providers': [for (final e in providers) e['provider']],
      },
      environment: sandbox ? 'sandbox' : 'app',
    );
  }

  // ------------------------------------------------------- capabilities --

  Future<void> _capabilities() async {
    final col = await marz.probe('GET', '/collect-money/services');
    final send = await marz.probe('GET', '/send-money/services');
    final bal = await marz.probe('GET', '/balance');
    final collection = [for (final e in _providers(col.body)) '${e['provider']}'];
    final disbursement = [for (final e in _providers(send.body)) '${e['provider']}'];
    await _step(
      'Collection services',
      col.status == 200 ? 'done' : 'failed',
      col.status == 200 ? collection.join(', ') : 'HTTP ${col.status ?? col.error}',
    );
    await _step(
      'Disbursement services',
      send.status == 200 ? 'done' : 'failed',
      send.status == 200 ? disbursement.join(', ') : 'HTTP ${send.status ?? send.error}',
    );
    await _step(
      'Balance and account endpoints',
      bal.status == 200 ? 'done' : 'failed',
      bal.status == 200
          ? 'Readable.'
          : bal.errorCode == 'IP_WHITELIST_REQUIRED'
          ? 'Blocked: MarzPay allows these only from whitelisted IP addresses '
                '(a phone\'s address changes, so these stay blocked on phones).'
          : 'HTTP ${bal.status ?? bal.error}',
    );
    await _finish(
      result: col.status == 200 ? 'verified_success' : 'failed',
      message: 'Capabilities read from MarzPay.',
      evidence: {
        'collection': collection,
        'disbursement': disbursement,
        'balance_endpoint': bal.status == 200
            ? 'ok'
            : bal.errorCode == 'IP_WHITELIST_REQUIRED'
            ? 'ip_whitelist_required'
            : 'error',
      },
    );
  }

  // ------------------------------------------------------------ balance --

  Future<void> _balance() async {
    final fromLedger = await _safe(marz.ledgerBalance);
    await _step(
      'Balance from the transaction list',
      fromLedger == null ? 'failed' : 'done',
      '${fromLedger ?? '?'} UGX',
    );
    final p = await marz.probe('GET', '/balance');
    if (p.status == 200) {
      final acc = ((p.body?['data'] as Map?)?['account'] as Map?) ?? {};
      final bal = (acc['balance'] as Map?)?['raw'];
      final avail = (acc['available_balance'] as Map?)?['raw'];
      await _step('Balance endpoint', 'done', 'balance $bal, available $avail');
      return _finish(
        result: 'verified_success',
        message: 'Balance: $bal UGX (available $avail).',
        evidence: {'balance': bal, 'available': avail, 'ledger_balance': fromLedger},
      );
    }
    final blocked = p.errorCode == 'IP_WHITELIST_REQUIRED';
    await _step(
      'Balance endpoint',
      blocked ? 'skipped' : 'failed',
      blocked ? 'Needs a whitelisted IP address.' : 'HTTP ${p.status ?? p.error}',
    );
    await _finish(
      result: fromLedger != null ? 'verified_success' : (blocked ? 'blocked' : 'failed'),
      errorCode: p.errorCode,
      message: fromLedger != null
          ? 'The wallet holds $fromLedger UGX (from MarzPay\'s transaction list).'
          : 'Could not read the balance (HTTP ${p.status ?? p.error}).',
      evidence: {'ledger_balance': fromLedger},
    );
  }

  // --------------------------------------------- collection / disbursement --

  Future<void> _money(
    bool collect,
    Map<String, Object?> params,
    String? reference,
  ) async {
    final m = RegExp(r'^(?:\+?256|0)?(7\d{8})$')
        .firstMatch('${params['phone'] ?? ''}'.replaceAll(RegExp(r'[^0-9+]'), ''));
    final phone = m == null ? null : '+256${m.group(1)}';
    final amount = int.tryParse('${params['amount']}');
    if (phone == null || amount == null || reference == null) {
      return _finish(result: 'failed', message: 'Missing number, amount or reference.');
    }
    final shown = '${phone.substring(0, 6)}…${phone.substring(phone.length - 3)}';
    await _step(
      'Sidra created the test',
      'done',
      collect
          ? '$amount UGX from $shown, reference $reference'
          : '$amount UGX to $shown, reference $reference',
    );
    final before = await _safe(marz.ledgerBalance);
    await _step('Wallet balance before', before == null ? 'skipped' : 'done', '${before ?? '?'} UGX');
    if (!collect && before != null && before < amount) {
      await _step('Enough money in the wallet', 'failed', 'The wallet has $before UGX.');
      return _finish(
        result: 'blocked',
        message: 'The MarzPay wallet has $before UGX, less than $amount UGX. Collect money first.',
        evidence: {'balance_before': before},
      );
    }
    final MarzTx tx;
    try {
      final description = 'SIDRA-TEST ${params['description'] ?? (collect ? 'collection' : 'disbursement')} test';
      tx = collect
          ? await marz.collect(amount: amount, phone: phone, reference: reference, description: description)
          : await marz.sendMoney(amount: amount, phone: phone, reference: reference, description: description);
    } on MarzPayException catch (e) {
      final blocked = e.errorCode == 'IP_WHITELIST_REQUIRED';
      await _step('MarzPay accepted the request', 'failed', e.message);
      return _finish(
        result: blocked ? 'blocked' : 'failed',
        errorCode: e.errorCode,
        message: blocked
            ? 'Blocked: MarzPay only sends money from a whitelisted IP address, which a phone does not have.'
            : 'MarzPay refused: ${e.message}',
        evidence: {
          'amount': amount,
          'direction': collect ? 'collect' : 'disburse',
          'http_status': e.statusCode,
          'error_code': e.errorCode,
          // exactly what MarzPay answered
          'provider_response': e.body,
        },
      );
    }
    await _step('MarzPay accepted the request', 'done', 'MarzPay id ${tx.uuid}, status ${tx.status}');
    if (tx.status == 'sandbox') {
      return _finish(
        result: 'provider_accepted',
        providerUuid: tx.uuid,
        providerStatus: tx.status,
        environment: 'sandbox',
        message: 'Sandbox service: MarzPay skipped the real provider. No money moved.',
        evidence: {'provider_response': tx.raw},
      );
    }
    if (collect) {
      await _step('Payment prompt sent', 'waiting', 'The phone $shown should now ask for the PIN.');
    }
    final end = await _poll(() => collect ? marz.status(tx.uuid) : marz.sendStatus(tx.uuid));
    await _step(
      'MarzPay\'s final status',
      end.succeeded ? 'done' : end.finished ? 'failed' : 'waiting',
      end.finished ? end.status : 'No answer after ${pollFor.inMinutes} minutes (still ${end.status}).',
    );
    final ledger = await _safe(() => marz.transactionsFor(reference)) ?? const <MarzTx>[];
    final entry = ledger.where((t) => t.type == (collect ? 'credit' : 'debit')).firstOrNull;
    final after = await _safe(marz.ledgerBalance);
    await _step(
      collect ? 'Money in MarzPay\'s ledger' : 'Money out of MarzPay\'s ledger',
      entry != null && entry.succeeded ? 'done' : 'failed',
      entry == null
          ? 'No ledger entry for this reference.'
          : '${entry.type} ${entry.amount} UGX (${entry.status}). Wallet ${before ?? '?'} → ${after ?? '?'} UGX.',
    );
    final proven = end.succeeded && entry != null && entry.succeeded && (!collect || entry.amount == amount);
    // MarzPay's own charge: the other debits for this reference (the books
    // record exactly this, never an assumed rate).
    final fee = ledger
        .where((t) => t != entry && t.type == 'debit' && t.succeeded)
        .fold<num>(0, (s, t) => s + (t.amount ?? 0));
    await _finish(
      result: proven
          ? 'verified_success'
          : end.succeeded
          ? 'provider_accepted'
          : end.status == 'cancelled'
          ? 'cancelled'
          : end.failed
          ? 'failed'
          : 'pending',
      providerUuid: tx.uuid,
      providerStatus: end.status,
      message: proven
          ? (collect
                ? 'Proven: $amount UGX arrived in the MarzPay wallet.'
                : 'Proven: $amount UGX left the wallet. Confirm with the recipient.')
          : end.succeeded
          ? 'MarzPay says successful, but its ledger shows no matching entry yet. Check again with a lookup.'
          : end.finished
          ? 'It did not go through (${end.status}). No money moved.'
          : 'Still waiting. Look it up later with MarzPay id ${tx.uuid}.',
      evidence: {
        'amount': amount,
        'direction': collect ? 'collect' : 'disburse',
        'provider': end.provider,
        'provider_reference': end.providerReference,
        'ledger_entry': entry?.uuid,
        if (proven) 'fee': fee,
        'balance_before': before,
        'balance_after': after,
        // exactly what MarzPay answered: to the request, and at the end
        'provider_response': tx.raw,
        'final_response': end.raw,
      },
    );
  }

  // ------------------------------------------------------------- lookup --

  Future<void> _lookup(String query) async {
    if (query.isEmpty) {
      return _finish(result: 'failed', message: 'Enter a Sidra payment id, MarzPay id or reference.');
    }
    final trace = query.length < 3
        ? const <Map<String, dynamic>>[]
        : await _safe(() => api.rpcRows('payment_trace', params: {'p_query': query})) ??
              const <Map<String, dynamic>>[];
    final sidra = trace.isEmpty
        ? null
        : Map<String, dynamic>.from(
            ((trace.first['payment_trace'] ?? trace.first) as Map)['payment'] as Map,
          );
    await _step(
      'Sidra\'s record',
      sidra == null ? 'failed' : 'done',
      sidra == null
          ? 'No Sidra payment matches.'
          : 'Sidra says ${sidra['status']} for ${sidra['amount']} ${sidra['currency']}.',
    );
    final uuid = (sidra?['provider_uuid'] as String?) ?? query;
    final ref = (sidra?['reference'] as String?) ?? query;
    MarzTx? found;
    for (final get in [() => marz.status(uuid), () => marz.sendStatus(uuid), () async => (await marz.transaction(uuid))!]) {
      found = await _safe(get);
      if (found != null && found.uuid.isNotEmpty) break;
      found = null;
    }
    await _step(
      'MarzPay\'s record',
      found == null ? 'failed' : 'done',
      found == null
          ? 'MarzPay has no transaction with that id.'
          : 'MarzPay says ${found.status}, ${found.amount} UGX, ${found.provider ?? found.type ?? ''}.',
    );
    final ledger = await _safe(() => marz.transactionsFor(found?.reference.isNotEmpty ?? false ? found!.reference : ref)) ??
        const <MarzTx>[];
    await _step(
      'MarzPay ledger for the reference',
      ledger.isEmpty ? 'failed' : 'done',
      ledger.isEmpty ? 'No entries.' : ledger.map((t) => '${t.type} ${t.amount} ${t.status}').join('; '),
    );
    final agree = sidra == null || found == null || (found.succeeded == (sidra['status'] == 'verified'));
    await _finish(
      result: found != null || ledger.isNotEmpty ? 'verified_success' : 'failed',
      providerUuid: found?.uuid,
      providerStatus: found?.status,
      message: found == null && ledger.isEmpty
          ? 'Not found at MarzPay.'
          : sidra == null
          ? 'Found at MarzPay only: not a Sidra payment (this MarzPay account is shared with other products, e.g. DRAIS).'
          : agree
          ? 'Sidra and MarzPay agree.'
          : 'MISMATCH: MarzPay says ${found.status}, Sidra says ${sidra['status']}. Staff phones re-check '
                'reported payments; a finance officer can resolve the rest.',
      evidence: {
        'sidra_status': sidra?['status'],
        'marzpay_status': found?.status,
        'ledger': [for (final t in ledger) {'type': t.type, 'amount': t.amount, 'status': t.status}],
      },
    );
  }

  // ----------------------------------------------------- reconciliation --

  Future<void> _reconciliation() async {
    await _step(
      'Payments to check',
      'done',
      'Payments a payer\'s phone reported, and payments still waiting.',
    );
    final n = await DirectPayments(api, marz).confirmPending(limit: 100);
    await _step('Checked against MarzPay', 'done', '$n finished at MarzPay and recorded.');
    await _finish(
      result: 'verified_success',
      message: n == 0
          ? 'Nothing waiting to be checked.'
          : '$n payments checked against MarzPay. Any MarzPay did not confirm were reversed.',
      evidence: {'checked': n},
    );
  }

  // ------------------------------------------------------------- helpers --

  Future<MarzTx> _poll(Future<MarzTx> Function() get) async {
    final deadline = DateTime.now().add(pollFor);
    var last = MarzTx(uuid: '', reference: '', status: 'unknown');
    var lastStatus = '';
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(pollEvery);
      final c = await _safe(get);
      if (c == null) continue;
      last = c;
      if (c.status != lastStatus) {
        lastStatus = c.status;
        await _step('Status at MarzPay', 'waiting', c.status);
      }
      if (c.finished) break;
    }
    return last;
  }

  static Future<T?> _safe<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> _providers(Map<String, dynamic>? body) => [
    for (final c in (((body?['data'] as Map?)?['countries'] as Map?)?.values ?? const []))
      for (final p in ((c as Map)['providers'] as List? ?? const [])) (p as Map).cast<String, dynamic>(),
  ];

  static String _mask(String s) => s.length <= 8 ? '••••' : '${s.substring(0, 4)}…${s.substring(s.length - 4)}';
}
