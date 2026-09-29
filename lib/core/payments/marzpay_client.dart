import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// MarzPay, called straight from the app.
/// Docs: https://wallet.wearemarz.com/documentation/api
class MarzPayException implements Exception {
  MarzPayException(this.message, {this.statusCode, this.errorCode});
  final String message;
  final int? statusCode;
  final String? errorCode;

  bool get transient => statusCode == null || statusCode! >= 500 || statusCode == 429;

  @override
  String toString() => message;
}

/// A collection or disbursement as MarzPay reports it.
class MarzTx {
  MarzTx({
    required this.uuid,
    required this.reference,
    required this.status,
    this.type,
    this.amount,
    this.provider,
    this.providerReference,
    this.raw = const {},
  });

  factory MarzTx.fromJson(Map<String, dynamic> body, {String? type}) {
    final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? body;
    final tx = (data['transaction'] as Map?)?.cast<String, dynamic>() ?? data;
    final col = (data['collection'] as Map?)?.cast<String, dynamic>() ?? const {};
    final raw = (tx['amount'] as Map?)?['raw'] ?? (col['amount'] as Map?)?['raw'];
    final event = '${body['event_type'] ?? data['event_type'] ?? ''}';
    return MarzTx(
      uuid: '${tx['uuid'] ?? ''}',
      reference: '${tx['reference'] ?? ''}',
      status: '${tx['status'] ?? 'unknown'}'.toLowerCase(),
      type: (tx['type'] ?? type ?? (event.startsWith('collection') ? 'credit' : event.isEmpty ? null : 'debit'))
          ?.toString()
          .toLowerCase(),
      amount: raw is num ? raw : num.tryParse('${raw ?? ''}'),
      provider: (col['provider'] ?? tx['provider'])?.toString(),
      providerReference: (tx['provider_reference'] ?? col['provider_transaction_id'])?.toString(),
      raw: body,
    );
  }

  final String uuid;
  final String reference;

  /// processing | pending | successful | completed | failed | cancelled | sandbox
  final String status;
  final String? type;
  final num? amount;
  final String? provider;
  final String? providerReference;
  final Map<String, dynamic> raw;

  bool get succeeded => status == 'successful' || status == 'completed';
  bool get failed => status == 'failed' || status == 'cancelled' || status == 'rejected' || status == 'expired';
  bool get finished => succeeded || failed;
}

class MarzProbe {
  MarzProbe(this.status, this.body, this.error, this.elapsed);
  final int? status;
  final Map<String, dynamic>? body;
  final String? error;
  final Duration elapsed;
  String? get errorCode => body?['error_code']?.toString();
  String? get message => body?['message']?.toString();
}

class MarzPayClient {
  MarzPayClient({required String baseUrl, required String basicAuth, this.country = 'UG'})
    : _auth = basicAuth,
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
          validateStatus: (_) => true,
        ),
      );

  final String _auth;
  final Dio _dio;
  final String country;

  String get baseUrl => _dio.options.baseUrl;

  /// A short, safe form of the API key ("marz_t8…RL").
  String get maskedKey {
    try {
      final key = utf8.decode(base64Decode(_auth)).split(':').first;
      return key.length <= 8 ? '••••' : '${key.substring(0, 7)}…${key.substring(key.length - 2)}';
    } catch (_) {
      return '••••';
    }
  }

  Future<MarzProbe> probe(String method, String path, {Map<String, Object?>? json, String? basicAuth}) async {
    final sw = Stopwatch()..start();
    try {
      final r = await _dio.request<Object?>(
        path,
        data: json,
        options: Options(method: method, headers: {'Authorization': 'Basic ${basicAuth ?? _auth}'}),
      );
      final body = r.data is Map ? (r.data as Map).cast<String, dynamic>() : null;
      return MarzProbe(r.statusCode, body, null, sw.elapsed);
    } on DioException catch (e) {
      return MarzProbe(null, null, e.message ?? e.type.name, sw.elapsed);
    }
  }

  Future<Map<String, dynamic>> _send(String method, String path, [Map<String, Object?>? json]) async {
    final p = await probe(method, path, json: json);
    if (p.status == null) throw MarzPayException('Could not reach MarzPay (${p.error}).');
    final body = p.body;
    if (body == null) throw MarzPayException('Unexpected answer from MarzPay (HTTP ${p.status}).', statusCode: p.status);
    if (p.status! >= 400 || body['status'] == 'error' || body['success'] == false) {
      throw MarzPayException('${body['message'] ?? 'MarzPay refused the request'}',
          statusCode: p.status, errorCode: body['error_code']?.toString());
    }
    return body;
  }

  /// Starts a collection: the payer's phone shows a PIN prompt.
  Future<MarzTx> collect({required int amount, required String phone, required String reference, String? description}) async =>
      MarzTx.fromJson(await _send('POST', '/collect-money', {
        'amount': amount,
        'phone_number': phone,
        'country': country,
        'reference': reference,
        'description': ?description,
      }));

  Future<MarzTx> status(String uuid) async => MarzTx.fromJson(await _send('GET', '/collect-money/$uuid'));

  /// Sends money out of the wallet (needs an IP whitelisted at MarzPay).
  Future<MarzTx> sendMoney({required int amount, required String phone, required String reference, String? description}) async =>
      MarzTx.fromJson(await _send('POST', '/send-money', {
        'amount': amount,
        'phone_number': phone,
        'country': country,
        'reference': reference,
        'description': ?description,
      }));

  Future<MarzTx> sendStatus(String uuid) async => MarzTx.fromJson(await _send('GET', '/send-money/$uuid'));

  /// Any transaction by MarzPay's id.
  Future<MarzTx?> transaction(String uuid) async {
    final t = MarzTx.fromJson(await _send('GET', '/transactions/$uuid'));
    return t.uuid.isEmpty ? null : t;
  }

  /// MarzPay's ledger entries for one of our references: a collection has a
  /// credit (the payer's money) and usually a debit (MarzPay's fee).
  Future<List<MarzTx>> transactionsFor(String reference) async {
    final body = await _send('GET', '/transactions?reference=${Uri.encodeQueryComponent(reference)}');
    final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    return [
      for (final t in (data['transactions'] as List? ?? const []))
        MarzTx.fromJson((t as Map).cast<String, dynamic>()),
    ].where((t) => t.reference == reference).toList();
  }

  /// Wallet balance as the transaction list reports it (no whitelist needed).
  Future<num?> ledgerBalance() async {
    final body = await _send('GET', '/transactions?per_page=1');
    final raw = (((body['data'] as Map?)?['account'] as Map?)?['current_balance'] as Map?)?['raw'];
    return raw is num ? raw : num.tryParse('${raw ?? ''}');
  }
}

/// Null when this build has no MarzPay credentials.
final marzPayClientProvider = Provider<MarzPayClient?>((ref) {
  final c = ref.watch(appConfigProvider);
  if (!c.isMarzPayConfigured) return null;
  return MarzPayClient(baseUrl: c.marzpayBaseUrl, basicAuth: c.marzpayAuth, country: c.marzpayCountry);
});
