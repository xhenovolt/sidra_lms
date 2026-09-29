// The MarzPay test centre, server side. An administrator queues a test in
// the app (public.request_payment_test); this runner claims it, talks to
// MarzPay, writes each step as it happens, and ends with one honest result:
//
//   verified_success   the operation was proven (e.g. MarzPay's own ledger
//                      shows the money arrived)
//   provider_accepted  MarzPay took the request; the outcome isn't proven
//   failed / cancelled / pending / unknown
//   blocked            something outside Sidra prevents it (IP whitelist…)
//   unsupported        MarzPay or this account doesn't offer it
//
// Money tests run once. Nothing is retried automatically.
import 'dart:async';
import 'dart:convert';

import 'marzpay.dart';

abstract class TestDb {
  Future<void> step(String id, Map<String, Object?> step);
  Future<void> finish(
    String id, {
    required String result,
    String? providerUuid,
    String? providerStatus,
    String? errorCode,
    String? message,
    Map<String, Object?> evidence = const {},
    String? environment,
  });
  Future<Map<String, dynamic>?> sidraPayment(String query);
  Future<List<Map<String, dynamic>>> sidraMarzPayPayments(int days);
}

class PaymentTestRunner {
  PaymentTestRunner({
    required this.marz,
    required this.db,
    this.publicUrl,
    this.fetch,
    this.pollEvery = const Duration(seconds: 5),
    this.pollFor = const Duration(minutes: 4),
  });

  final MarzPayClient marz;
  final TestDb db;
  final String? publicUrl;
  final Future<MarzProbe> Function(String url)? fetch;
  final Duration pollEvery;
  final Duration pollFor;

  late String _id;
  var _n = 0;

  Future<void> _step(String label, String state, [String? detail]) => db.step(
    _id,
    {'step': ++_n, 'label': label, 'state': state, 'detail': ?detail},
  );

  /// Runs one claimed test (the row from payments_api.claim_test).
  Future<void> run(Map<String, dynamic> test) async {
    _id = test['id'] as String;
    _n = 0;
    final params = (test['params'] as Map?)?.cast<String, dynamic>() ?? {};
    try {
      switch (test['kind']) {
        case 'connection':
          await _connection();
        case 'capabilities':
          await _capabilities();
        case 'balance':
          await _balance();
        case 'collection':
          await _collection(
            test['target_phone'] as String?,
            params,
            test['reference'] as String,
          );
        case 'disbursement':
          await _disbursement(
            test['target_phone'] as String?,
            params,
            test['reference'] as String,
          );
        case 'status_lookup':
          await _lookup('${params['query'] ?? ''}'.trim());
        case 'callbacks':
          await _callbacks();
        case 'reconciliation':
          await _reconciliation();
        default:
          await db.finish(_id, result: 'unsupported', message: 'Unknown test.');
      }
    } catch (e) {
      await db.finish(
        _id,
        result: 'unknown',
        message:
            'The test stopped unexpectedly: $e. Check MarzPay before trying again.',
      );
    }
  }

  // --------------------------------------------------------- connection --

  Future<void> _connection() async {
    await _step(
      'Credentials on the payments server',
      'done',
      'API key ${marz.maskedKey}; ${marz.baseUrl}',
    );
    final p = await marz.probe('GET', '/collect-money/services');
    if (p.status == null) {
      final e = '${p.error}';
      final kind = e.contains('Failed host lookup')
          ? 'The name wallet.wearemarz.com could not be found (DNS). Check the server\'s internet.'
          : e.contains('Handshake') || e.contains('CERTIFICATE')
          ? 'A secure (TLS) connection could not be made.'
          : e.contains('timed out')
          ? 'MarzPay did not answer in time.'
          : 'MarzPay could not be reached: $e';
      await _step('Network, DNS and TLS', 'failed', kind);
      return db.finish(_id, result: 'failed', message: kind);
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
      return db.finish(
        _id,
        result: 'failed',
        errorCode: p.errorCode,
        message: msg,
      );
    }
    final data = (p.body?['data'] as Map?) ?? {};
    final account = '${(data['account'] as Map?)?['uuid'] ?? '?'}';
    final providers = _providers(p.body);
    final sandbox = providers.any((e) => '${e['mode']}'.contains('sandbox'));
    await _step(
      'Authentication',
      'done',
      'Credentials accepted. Account ${_mask(account)}.',
    );
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
    await db.finish(
      _id,
      result: 'verified_success',
      message:
          'Reachable, secure, and MarzPay accepted Sidra\'s credentials '
          '(${p.elapsed.inMilliseconds} ms).',
      evidence: {
        'account': _mask(account),
        'latency_ms': p.elapsed.inMilliseconds,
        'collection_providers': [for (final e in providers) e['provider']],
      },
      environment: sandbox ? 'sandbox' : 'live',
    );
  }

  // ------------------------------------------------------- capabilities --

  Future<void> _capabilities() async {
    final col = await marz.probe('GET', '/collect-money/services');
    final send = await marz.probe('GET', '/send-money/services');
    final bal = await marz.probe('GET', '/balance');
    final hooks = await marz.probe('GET', '/webhooks');
    final collection = [
      for (final e in _providers(col.body)) '${e['provider']}',
    ];
    final disbursement = [
      for (final e in _providers(send.body)) '${e['provider']}',
    ];
    await _step(
      'Collection services',
      col.status == 200 ? 'done' : 'failed',
      col.status == 200
          ? collection.join(', ')
          : 'HTTP ${col.status ?? col.error}',
    );
    await _step(
      'Disbursement services',
      send.status == 200 ? 'done' : 'failed',
      send.status == 200
          ? disbursement.join(', ')
          : 'HTTP ${send.status ?? send.error}',
    );
    await _step(
      'Balance and account endpoints',
      bal.status == 200 ? 'done' : 'failed',
      bal.status == 200
          ? 'Readable.'
          : bal.errorCode == 'IP_WHITELIST_REQUIRED'
          ? 'Blocked: MarzPay needs this server\'s IP address on its whitelist '
                '(MarzPay dashboard → IP Whitelist).'
          : 'HTTP ${bal.status ?? bal.error}',
    );
    final hookList =
        ((hooks.body?['data'] as Map?)?['webhooks'] as List?) ?? const [];
    await _step(
      'Webhooks registered at MarzPay',
      hooks.status == 200 ? 'done' : 'failed',
      '${hookList.length} (Sidra also sends its address with each payment when PUBLIC_URL is set).',
    );
    await db.finish(
      _id,
      result: col.status == 200 ? 'verified_success' : 'failed',
      message: 'Capabilities read from MarzPay.',
      evidence: {
        'collection': collection,
        'disbursement': disbursement,
        'bank_transfer': disbursement.any(
          (p) => p.toLowerCase().contains('bank'),
        ),
        'wallet_transfer': disbursement.any(
          (p) => p.toLowerCase().contains('wallet'),
        ),
        'balance_endpoint': bal.status == 200
            ? 'ok'
            : bal.errorCode == 'IP_WHITELIST_REQUIRED'
            ? 'ip_whitelist_required'
            : 'error',
        'send_money_endpoint_needs_whitelist': true,
        'webhooks_registered': hookList.length,
      },
    );
  }

  // ------------------------------------------------------------ balance --

  Future<void> _balance() async {
    final p = await marz.probe('GET', '/balance');
    num? fromLedger;
    try {
      fromLedger = await marz.balanceFromTransactions();
      await _step(
        'Balance from the transaction list',
        'done',
        '$fromLedger UGX',
      );
    } catch (e) {
      await _step('Balance from the transaction list', 'failed', '$e');
    }
    if (p.status == 200) {
      final acc = ((p.body?['data'] as Map?)?['account'] as Map?) ?? {};
      final bal = (acc['balance'] as Map?)?['raw'];
      final avail = (acc['available_balance'] as Map?)?['raw'];
      await _step('Balance endpoint', 'done', 'balance $bal, available $avail');
      return db.finish(
        _id,
        result: 'verified_success',
        message: 'Balance: $bal UGX (available $avail).',
        evidence: {
          'balance': bal,
          'available': avail,
          'ledger_balance': fromLedger,
        },
      );
    }
    final blocked = p.errorCode == 'IP_WHITELIST_REQUIRED';
    await _step(
      'Balance endpoint',
      'failed',
      blocked
          ? 'MarzPay requires this server\'s IP on its whitelist.'
          : 'HTTP ${p.status ?? p.error}',
    );
    await db.finish(
      _id,
      result: blocked ? (fromLedger != null ? 'blocked' : 'blocked') : 'failed',
      errorCode: p.errorCode,
      message: blocked
          ? 'The balance endpoint is blocked until this server\'s IP address is whitelisted at MarzPay'
                '${fromLedger == null ? '' : '. The transaction list reports $fromLedger UGX'}.'
          : 'Could not read the balance (HTTP ${p.status ?? p.error}).',
      evidence: {'ledger_balance': fromLedger},
    );
  }

  // --------------------------------------------------------- collection --

  Future<void> _collection(
    String? phone,
    Map<String, dynamic> params,
    String reference,
  ) async {
    if (phone == null) {
      return db.finish(
        _id,
        result: 'failed',
        message: 'No phone number (it is deleted after a test).',
      );
    }
    final amount = (params['amount'] as num).toInt();
    await _step(
      'Sidra created the test',
      'done',
      '$amount UGX from ${params['phone']}, reference $reference',
    );
    num? before;
    try {
      before = await marz.balanceFromTransactions();
      await _step('Wallet balance before', 'done', '$before UGX');
    } catch (_) {
      await _step('Wallet balance before', 'skipped', 'Not readable.');
    }
    final MarzCollection c;
    try {
      c = await marz.collect(
        amount: amount,
        phone: phone,
        reference: reference,
        description: 'SIDRA-TEST ${params['description'] ?? 'collection test'}',
        callbackUrl: publicUrl == null ? null : '$publicUrl/marzpay/webhook',
      );
    } on MarzPayException catch (e) {
      await _step('MarzPay accepted the request', 'failed', e.message);
      return db.finish(
        _id,
        result: e.errorCode == 'IP_WHITELIST_REQUIRED' ? 'blocked' : 'failed',
        errorCode: e.errorCode,
        message: 'MarzPay refused the collection: ${e.message}',
      );
    }
    await _step(
      'MarzPay accepted the request',
      'done',
      'MarzPay id ${c.uuid}, status ${c.status}',
    );
    if (c.status == 'sandbox') {
      return db.finish(
        _id,
        result: 'provider_accepted',
        providerUuid: c.uuid,
        providerStatus: c.status,
        environment: 'sandbox',
        message:
            'Sandbox service: MarzPay skipped the real provider. No money moved.',
      );
    }
    await _step(
      'Payment prompt sent',
      'waiting',
      'The phone ${params['phone']} should now ask for the PIN.',
    );
    final end = await _poll(() => marz.status(c.uuid));
    await _step(
      'Payer\'s answer',
      end.succeeded
          ? 'done'
          : end.finished
          ? 'failed'
          : 'waiting',
      end.succeeded
          ? 'Approved.'
          : end.status == 'cancelled'
          ? 'Cancelled.'
          : end.failed
          ? 'Failed.'
          : 'No answer after ${pollFor.inMinutes} minutes (still ${end.status}).',
    );
    await _step(
      'MarzPay\'s final status',
      end.finished ? 'done' : 'waiting',
      end.status,
    );
    // Proof: MarzPay's own ledger for our reference, and the balance change.
    final ledger =
        await _safe(() => marz.transactionsFor(reference)) ??
        const <MarzTransaction>[];
    final credit = ledger.where((t) => t.type == 'credit').firstOrNull;
    final fee = ledger
        .where((t) => t.type == 'debit')
        .fold<num>(0, (s, t) => s + (t.amount ?? 0));
    final after = await _safe(marz.balanceFromTransactions);
    await _step(
      'Money in MarzPay\'s ledger',
      _ok(credit?.status) ? 'done' : 'failed',
      credit == null
          ? 'No credit entry for this reference.'
          : 'Credit ${credit.amount} UGX (${credit.status}), fee $fee UGX. '
                'Wallet ${before ?? '?'} → ${after ?? '?'} UGX.',
    );
    final proven =
        end.succeeded &&
        credit != null &&
        credit.amount == amount &&
        _ok(credit.status);
    await db.finish(
      _id,
      result: proven
          ? 'verified_success'
          : end.succeeded
          ? 'provider_accepted'
          : end.status == 'cancelled'
          ? 'cancelled'
          : end.failed
          ? 'failed'
          : 'pending',
      providerUuid: c.uuid,
      providerStatus: end.status,
      message: proven
          ? 'Proven: $amount UGX arrived in the MarzPay wallet (ledger credit ${credit.uuid}).'
          : end.succeeded
          ? 'MarzPay says successful, but its ledger shows no matching credit yet. Check again with a lookup.'
          : end.finished
          ? 'The payment did not go through (${end.status}). No money moved.'
          : 'Still waiting for the payer. Look it up later with MarzPay id ${c.uuid}.',
      evidence: {
        'amount': amount,
        'provider_reference': end.providerReference,
        'provider': end.provider,
        'ledger_credit': credit == null
            ? null
            : {
                'uuid': credit.uuid,
                'amount': credit.amount,
                'status': credit.status,
              },
        'fee': fee,
        'balance_before': before,
        'balance_after': after,
      },
      environment: 'live',
    );
  }

  // ------------------------------------------------------- disbursement --

  Future<void> _disbursement(
    String? phone,
    Map<String, dynamic> params,
    String reference,
  ) async {
    if (phone == null) {
      return db.finish(_id, result: 'failed', message: 'No phone number.');
    }
    final amount = (params['amount'] as num).toInt();
    await _step(
      'Sidra created the test',
      'done',
      '$amount UGX to ${params['phone']}, reference $reference',
    );
    final before = await _safe(marz.balanceFromTransactions);
    await _step(
      'Wallet balance before',
      before == null ? 'skipped' : 'done',
      '${before ?? '?'} UGX',
    );
    if (before != null && before < amount) {
      await _step(
        'Enough money in the wallet',
        'failed',
        'The wallet has $before UGX.',
      );
      return db.finish(
        _id,
        result: 'blocked',
        message:
            'The MarzPay wallet has $before UGX, less than $amount UGX. Collect money first.',
        evidence: {'balance_before': before},
      );
    }
    final MarzCollection s;
    try {
      s = await marz.sendMoney(
        amount: amount,
        phone: phone,
        reference: reference,
        description:
            'SIDRA-TEST ${params['description'] ?? 'disbursement test'}',
        callbackUrl: publicUrl == null ? null : '$publicUrl/marzpay/webhook',
      );
    } on MarzPayException catch (e) {
      final blocked = e.errorCode == 'IP_WHITELIST_REQUIRED';
      await _step('MarzPay accepted the request', 'failed', e.message);
      return db.finish(
        _id,
        result: blocked ? 'blocked' : 'failed',
        errorCode: e.errorCode,
        message: blocked
            ? 'Blocked: sending money needs this server\'s IP address on MarzPay\'s whitelist.'
            : 'MarzPay refused: ${e.message}',
      );
    }
    await _step(
      'MarzPay accepted the request',
      'done',
      'MarzPay id ${s.uuid}, status ${s.status}',
    );
    final end = await _poll(() => marz.sendStatus(s.uuid));
    await _step(
      'MarzPay\'s final status',
      end.finished ? 'done' : 'waiting',
      end.status,
    );
    final ledger =
        await _safe(() => marz.transactionsFor(reference)) ??
        const <MarzTransaction>[];
    final debit = ledger.where((t) => t.type == 'debit').firstOrNull;
    final after = await _safe(marz.balanceFromTransactions);
    await _step(
      'Money out of MarzPay\'s ledger',
      debit != null ? 'done' : 'failed',
      debit == null
          ? 'No debit entry for this reference.'
          : 'Debit ${debit.amount} UGX (${debit.status}). '
                'Wallet ${before ?? '?'} → ${after ?? '?'} UGX. Ask the recipient to confirm receipt.',
    );
    final proven = end.succeeded && debit != null && _ok(debit.status);
    await db.finish(
      _id,
      result: proven
          ? 'verified_success'
          : end.succeeded
          ? 'provider_accepted'
          : end.status == 'cancelled'
          ? 'cancelled'
          : end.failed
          ? 'failed'
          : 'pending',
      providerUuid: s.uuid,
      providerStatus: end.status,
      message: proven
          ? 'Proven: $amount UGX left the wallet (ledger debit ${debit.uuid}). Confirm with the recipient.'
          : 'Outcome: ${end.status}.',
      evidence: {
        'balance_before': before,
        'balance_after': after,
        'ledger_debit': debit?.uuid,
      },
      environment: 'live',
    );
  }

  // ------------------------------------------------------------- lookup --

  Future<void> _lookup(String query) async {
    if (query.isEmpty) {
      return db.finish(
        _id,
        result: 'failed',
        message: 'Enter a Sidra payment id, MarzPay id or reference.',
      );
    }
    final sidra = await db.sidraPayment(query);
    await _step(
      'Sidra\'s record',
      sidra == null ? 'failed' : 'done',
      sidra == null
          ? 'No Sidra payment matches.'
          : 'Sidra says ${sidra['status']} for ${sidra['amount']} ${sidra['currency']}.',
    );
    final uuid = (sidra?['provider_uuid'] as String?) ?? query;
    final ref = (sidra?['reference'] as String?) ?? query;
    MarzCollection? found;
    for (final get in [() => marz.status(uuid), () => marz.sendStatus(uuid)]) {
      found = await _safe(get);
      if (found != null && found.uuid.isNotEmpty) break;
    }
    if (found != null && found.uuid.isEmpty) found = null;
    // Any MarzPay transaction by its own id (fees, other products' entries…).
    final tx = found == null ? await _safe(() => marz.transaction(uuid)) : null;
    if (tx != null) {
      found = MarzCollection(
        uuid: tx.uuid,
        reference: tx.reference,
        status: tx.status,
        amount: tx.amount,
        provider: '${tx.type} entry',
      );
    }
    await _step(
      'MarzPay\'s record',
      found == null ? 'failed' : 'done',
      found == null
          ? 'MarzPay has no transaction with that id.'
          : 'MarzPay says ${found.status}, ${found.amount} UGX, ${found.provider ?? ''}.',
    );
    final ledger =
        await _safe(() => marz.transactionsFor(tx?.reference ?? ref)) ??
        const <MarzTransaction>[];
    await _step(
      'MarzPay ledger for the reference',
      ledger.isEmpty ? 'failed' : 'done',
      ledger.isEmpty
          ? 'No entries.'
          : ledger.map((t) => '${t.type} ${t.amount} ${t.status}').join('; '),
    );
    final agree =
        sidra == null ||
        found == null ||
        (found.succeeded == (sidra['status'] == 'verified'));
    await db.finish(
      _id,
      result: found != null || ledger.isNotEmpty
          ? 'verified_success'
          : 'failed',
      providerUuid: found?.uuid,
      providerStatus: found?.status,
      message: found == null && ledger.isEmpty
          ? 'Not found at MarzPay.'
          : sidra == null
          ? 'Found at MarzPay only: not a Sidra payment (this MarzPay account is '
                'shared with other products, e.g. DRAIS).'
          : agree
          ? 'Sidra and MarzPay agree.'
          : 'MISMATCH: MarzPay says ${found.status}, Sidra says ${sidra['status']}. The server re-checks '
                'unanswered payments; a finance officer can resolve the rest.',
      evidence: {
        'sidra': sidra,
        'marzpay_status': found?.status,
        'ledger': [
          for (final t in ledger)
            {'type': t.type, 'amount': t.amount, 'status': t.status},
        ],
      },
    );
  }

  // ---------------------------------------------------------- callbacks --

  Future<void> _callbacks() async {
    if (publicUrl == null || publicUrl!.isEmpty) {
      await _step(
        'Public address (PUBLIC_URL)',
        'failed',
        'Not set on the payments server.',
      );
      return db.finish(
        _id,
        result: 'blocked',
        message:
            'MarzPay can\'t call Sidra: the payments server has no public address (PUBLIC_URL). '
            'Payments are still confirmed by checking MarzPay every 20 seconds.',
      );
    }
    await _step(
      'Public address (PUBLIC_URL)',
      'done',
      '$publicUrl/marzpay/webhook',
    );
    final h =
        await (fetch ??
            (_) async => MarzProbe(null, null, 'not checked', Duration.zero))(
          '$publicUrl/health',
        );
    await _step(
      'Reachable from the internet',
      h.status == 200 ? 'done' : 'failed',
      'HTTP ${h.status ?? h.error}',
    );
    await db.finish(
      _id,
      result: h.status == 200 ? 'verified_success' : 'failed',
      message: h.status == 200
          ? 'MarzPay can reach Sidra. Received callbacks are listed under Callbacks.'
          : 'The public address did not answer; MarzPay callbacks would fail.',
    );
  }

  // ----------------------------------------------------- reconciliation --

  Future<void> _reconciliation() async {
    final ours = await db.sidraMarzPayPayments(30);
    await _step(
      'Sidra\'s MarzPay payments (30 days)',
      'done',
      '${ours.length}',
    );
    final problems = <String>[];
    var checked = 0;
    for (final p in ours.take(50)) {
      final ref = '${p['reference']}';
      final ledger =
          await _safe(() => marz.transactionsFor(ref)) ??
          const <MarzTransaction>[];
      final credit = ledger.where((t) => t.type == 'credit').firstOrNull;
      final paid = _ok(credit?.status);
      final sidraPaid = p['status'] == 'verified';
      checked++;
      if (paid != sidraPaid) {
        problems.add(
          '${p['id']}: MarzPay ${credit?.status ?? 'no entry'}, Sidra ${p['status']}',
        );
      } else if (paid && credit!.amount != (p['amount'] as num)) {
        problems.add(
          '${p['id']}: amount ${credit.amount} at MarzPay, ${p['amount']} in Sidra',
        );
      }
    }
    await _step(
      'Compared with MarzPay\'s ledger',
      problems.isEmpty ? 'done' : 'failed',
      problems.isEmpty ? '$checked checked, all agree.' : problems.join('\n'),
    );
    await db.finish(
      _id,
      result: problems.isEmpty ? 'verified_success' : 'failed',
      message: problems.isEmpty
          ? (checked == 0
                ? 'Nothing to reconcile yet.'
                : 'All $checked payments agree with MarzPay.')
          : '${problems.length} of $checked payments disagree with MarzPay.',
      evidence: {'checked': checked, 'problems': problems},
    );
  }

  // ------------------------------------------------------------- helpers --

  Future<MarzCollection> _poll(Future<MarzCollection> Function() get) async {
    final deadline = DateTime.now().add(pollFor);
    var last = MarzCollection(uuid: '', reference: '', status: 'unknown');
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

  static bool _ok(String? s) => s == 'successful' || s == 'completed';

  static Future<T?> _safe<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> _providers(Map<String, dynamic>? body) => [
    for (final c
        in (((body?['data'] as Map?)?['countries'] as Map?)?.values ??
            const []))
      for (final p in ((c as Map)['providers'] as List? ?? const []))
        (p as Map).cast<String, dynamic>(),
  ];

  static String _mask(String s) => s.length <= 8
      ? '••••'
      : '${s.substring(0, 4)}…${s.substring(s.length - 4)}';
}
