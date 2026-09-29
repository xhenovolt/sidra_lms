import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data_providers.dart';
import '../network/postgres_api.dart';
import 'marzpay_client.dart';

/// MarzPay straight from the app (0041): the payer's phone sends the
/// collection and reports MarzPay's answer; staff phones re-check every
/// reported payment against MarzPay and reverse any it does not confirm.
class DirectPayments {
  DirectPayments(this.api, this.marz);
  final PostgresApi api;
  final MarzPayClient marz;

  /// Sends the PIN prompt for a payment made by start_course_payment and
  /// records MarzPay's id. Returns that id.
  Future<String> send({
    required String paymentId,
    required String reference,
    required num amount,
    required String phone,
    String? description,
  }) async {
    MarzTx tx;
    try {
      tx = await marz.collect(
        amount: amount.round(),
        phone: phone,
        reference: reference,
        description: description,
      );
    } on MarzPayException catch (e) {
      // Sent before (the app closed after sending): find it, don't resend.
      final earlier = e.errorCode == 'DUPLICATE_REFERENCE'
          ? await _credit(reference)
          : null;
      if (earlier == null) {
        if (!e.transient) {
          await api.rpc(
            'marzpay_send_failed',
            params: {'p_payment_id': paymentId, 'p_error': e.message},
          );
        }
        rethrow;
      }
      tx = earlier;
    }
    await api.rpc(
      'marzpay_submitted',
      params: {
        'p_payment_id': paymentId,
        'p_provider_uuid': tx.uuid,
        'p_provider': tx.provider,
        'p_status': tx.status,
      },
    );
    return tx.uuid;
  }

  /// Asks MarzPay about [providerUuid]; once it has a final answer, reports
  /// it and returns the payment as the database now has it (else null).
  Future<Map<String, dynamic>?> check({
    required String paymentId,
    required String providerUuid,
    required String reference,
  }) async {
    final tx = await marz.status(providerUuid);
    if (!tx.finished) return null;
    final res = await api.rpc(
      'marzpay_result',
      params: {
        'p_payment_id': paymentId,
        'p_status': tx.status,
        'p_amount': tx.amount,
        'p_reference': await _referenceOf(tx, reference),
        'p_provider_ref': tx.providerReference,
        'p_fee': tx.succeeded ? await _fee(reference) : null,
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }

  /// Staff phones: re-check payments payers' apps reported (or left
  /// waiting). Returns how many were looked at.
  Future<int> confirmPending({int limit = 20}) async {
    final rows = await api.rpcRows(
      'marzpay_to_confirm',
      params: {'p_limit': limit},
    );
    var n = 0;
    for (final r in rows) {
      final j = Map<String, dynamic>.from((r['marzpay_to_confirm'] ?? r) as Map);
      final uuid = '${j['provider_uuid']}';
      final reference = '${j['reference']}';
      try {
        final tx = await marz.status(uuid);
        if (!tx.finished) continue;
        await api.rpc(
          'marzpay_confirm',
          params: {
            'p_payment_id': j['id'],
            'p_status': tx.status,
            'p_amount': tx.amount,
            'p_reference': await _referenceOf(tx, reference),
            'p_provider_ref': tx.providerReference,
            'p_fee': tx.succeeded ? await _fee(reference) : null,
          },
        );
        n++;
      } on MarzPayException catch (e) {
        if (e.statusCode == 404) {
          // MarzPay has never heard of it: the payer's app made it up.
          await api.rpc(
            'marzpay_confirm',
            params: {
              'p_payment_id': j['id'],
              'p_status': 'not_found',
              'p_amount': null,
              'p_reference': '',
            },
          );
          n++;
        }
      }
    }
    return n;
  }

  /// The reference MarzPay itself holds for [tx]; if its status answer has
  /// none, the ledger entry with [expected] must exist to count.
  Future<String> _referenceOf(MarzTx tx, String expected) async {
    if (tx.reference.isNotEmpty) return tx.reference;
    return await _credit(expected) != null ? expected : '';
  }

  Future<MarzTx?> _credit(String reference) async {
    try {
      return (await marz.transactionsFor(
        reference,
      )).where((t) => t.type == 'credit').firstOrNull;
    } on MarzPayException {
      return null;
    }
  }

  /// MarzPay's fee (its debit entries for the reference); informative only.
  Future<num?> _fee(String reference) async {
    try {
      return (await marz.transactionsFor(reference))
          .where((t) => t.type == 'debit')
          .fold<num>(0, (sum, t) => sum + (t.amount ?? 0));
    } on MarzPayException {
      return null;
    }
  }
}

/// Null when this build has no MarzPay credentials.
final directPaymentsProvider = Provider<DirectPayments?>((ref) {
  final marz = ref.watch(marzPayClientProvider);
  if (marz == null) return null;
  return DirectPayments(ref.watch(postgresApiProvider), marz);
});

/// While a finance person has the app open: re-check reported payments
/// against MarzPay now and every two minutes. Watched by the admin shell
/// only for people with finance.verify_payment.
final marzPayConfirmLoopProvider = Provider<void>((ref) {
  final direct = ref.watch(directPaymentsProvider);
  if (direct == null) return;
  var busy = false;
  Future<void> tick() async {
    if (busy) return;
    busy = true;
    try {
      await direct.confirmPending();
    } catch (_) {
      // offline or MarzPay down; the next tick tries again
    } finally {
      busy = false;
    }
  }

  unawaited(tick());
  final timer = Timer.periodic(const Duration(minutes: 2), (_) => tick());
  ref.onDispose(timer.cancel);
});
