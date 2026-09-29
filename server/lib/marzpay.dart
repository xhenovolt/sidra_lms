// MarzPay API client (collections). Pure dart:io so the payments server and
// the developer CLI (tool/marzpay.dart) share one implementation.
//
// Docs: https://wallet.wearemarz.com/documentation/api
//   POST /collect-money            start a mobile-money collection
//   GET  /collect-money/{uuid}     its authoritative status
// Auth: Basic base64("API_KEY:API_SECRET"). The secret lives only on the
// server (env vars), never in the app.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class MarzPayException implements Exception {
  MarzPayException(this.message, {this.statusCode, this.errorCode});
  final String message;
  final int? statusCode;
  final String? errorCode;

  /// Worth retrying later (network trouble, MarzPay 5xx, rate limit).
  bool get transient =>
      statusCode == null || statusCode! >= 500 || statusCode == 429;

  @override
  String toString() =>
      'MarzPayException($statusCode ${errorCode ?? ''}): $message';
}

/// A collection as MarzPay reports it.
class MarzCollection {
  MarzCollection({
    required this.uuid,
    required this.reference,
    required this.status,
    this.providerReference,
    this.provider,
    this.amount,
    this.phone,
    this.raw = const {},
  });

  /// Reads both the create response (`data.transaction` / `data.collection`)
  /// and the status response / webhook (`transaction` / `collection`).
  factory MarzCollection.fromJson(Map<String, dynamic> body) {
    final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? body;
    final tx = (data['transaction'] as Map?)?.cast<String, dynamic>() ?? data;
    final col = (data['collection'] as Map?)?.cast<String, dynamic>() ?? {};
    final amount =
        (tx['amount'] as Map?)?['raw'] ?? (col['amount'] as Map?)?['raw'];
    return MarzCollection(
      uuid: '${tx['uuid'] ?? ''}',
      reference: '${tx['reference'] ?? ''}',
      status: '${tx['status'] ?? 'unknown'}'.toLowerCase(),
      providerReference:
          (tx['provider_reference'] ?? col['provider_transaction_id'])
              ?.toString(),
      provider: (col['provider'] ?? tx['provider'])?.toString(),
      amount: amount is num ? amount : num.tryParse('${amount ?? ''}'),
      phone: (col['phone_number'] ?? tx['phone_number'])?.toString(),
      raw: body,
    );
  }

  final String uuid;
  final String reference;

  /// processing | pending | successful | completed | failed | cancelled |
  /// sandbox (test services).
  final String status;
  final String? providerReference;
  final String? provider;
  final num? amount;
  final String? phone;
  final Map<String, dynamic> raw;

  bool get succeeded => status == 'successful' || status == 'completed';
  bool get failed => status == 'failed' || status == 'cancelled';
  bool get finished => succeeded || failed;
}

/// One line of MarzPay's transaction list.
class MarzTransaction {
  MarzTransaction({
    required this.uuid,
    required this.reference,
    required this.type,
    required this.status,
    this.amount,
  });

  factory MarzTransaction.fromJson(Map<String, dynamic> j) {
    final raw = (j['amount'] as Map?)?['raw'];
    return MarzTransaction(
      uuid: '${j['uuid']}',
      reference: '${j['reference']}',
      type: '${j['type']}'.toLowerCase(),
      status: '${j['status']}'.toLowerCase(),
      amount: raw is num ? raw : num.tryParse('${raw ?? ''}'),
    );
  }

  final String uuid;
  final String reference;

  /// credit (money in) | debit (e.g. MarzPay's charge).
  final String type;
  final String status;
  final num? amount;
}

class MarzPayClient {
  MarzPayClient({
    required this.baseUrl,
    required String basicAuth,
    this.country = 'UG',
    HttpClient? http,
  }) : _auth = basicAuth,
       _http =
           http ??
           (HttpClient()..connectionTimeout = const Duration(seconds: 15));

  /// From env: MARZPAY_BASE_URL, MARZPAY_AUTH_BASIC (or MARZPAY_API_KEY +
  /// MARZPAY_API_SECRET), MARZPAY_COUNTRY.
  factory MarzPayClient.fromEnv(Map<String, String> env) {
    final basic =
        env['MARZPAY_AUTH_BASIC'] ??
        base64Encode(
          utf8.encode('${env['MARZPAY_API_KEY']}:${env['MARZPAY_API_SECRET']}'),
        );
    return MarzPayClient(
      baseUrl: env['MARZPAY_BASE_URL'] ?? 'https://wallet.wearemarz.com/api/v1',
      basicAuth: basic,
      country: env['MARZPAY_COUNTRY'] ?? 'UG',
    );
  }

  final String baseUrl;
  final String country;
  final String _auth;
  final HttpClient _http;

  static const minAmount = 500;
  static const maxAmount = 10000000;

  /// Uganda numbers in the +256XXXXXXXXX form MarzPay requires.
  static String? normalizeUgPhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
    final m = RegExp(r'^(?:\+?256|0)?(7\d{8})$').firstMatch(digits);
    return m == null ? null : '+256${m.group(1)}';
  }

  /// Starts a collection: the payer gets a prompt on their phone.
  /// [reference] must be a fresh UUIDv4 (it is our idempotency key).
  Future<MarzCollection> collect({
    required int amount,
    required String phone,
    required String reference,
    String? description,
    String? callbackUrl,
    List<Map<String, Object?>> metadata = const [],
  }) async {
    final body = await _send('POST', '/collect-money', {
      'amount': amount,
      'phone_number': phone,
      'country': country,
      'reference': reference,
      'description': ?description,
      'callback_url': ?callbackUrl,
      if (metadata.isNotEmpty) 'metadata': metadata,
    });
    return MarzCollection.fromJson(body);
  }

  /// The authoritative state of a collection (use this, never a webhook
  /// body alone, before crediting anything).
  Future<MarzCollection> status(String uuid) async =>
      MarzCollection.fromJson(await _send('GET', '/collect-money/$uuid'));

  Future<Map<String, dynamic>> services() =>
      _send('GET', '/collect-money/services');

  /// Every MarzPay entry for one of our references. A collection has a
  /// `credit` (the payer's money) and usually a `debit` (MarzPay's fee).
  Future<List<MarzTransaction>> transactionsFor(String reference) async {
    final body = await _send(
      'GET',
      '/transactions?reference=${Uri.encodeQueryComponent(reference)}',
    );
    final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    return [
      for (final t in (data['transactions'] as List? ?? const []))
        MarzTransaction.fromJson((t as Map).cast<String, dynamic>()),
    ].where((t) => t.reference == reference).toList();
  }

  /// Disbursement (money OUT of the MarzPay wallet). Needs the server's IP
  /// on MarzPay's whitelist and money in the wallet. MarzPay's documentation
  /// doesn't give this request's body; it mirrors collect-money.
  Future<MarzCollection> sendMoney({
    required int amount,
    required String phone,
    required String reference,
    String? description,
    String? callbackUrl,
  }) async => MarzCollection.fromJson(
    await _send('POST', '/send-money', {
      'amount': amount,
      'phone_number': phone,
      'country': country,
      'reference': reference,
      'description': ?description,
      'callback_url': ?callbackUrl,
    }),
  );

  Future<MarzCollection> sendStatus(String uuid) async =>
      MarzCollection.fromJson(await _send('GET', '/send-money/$uuid'));

  /// Any transaction (collection, disbursement, fee…) by MarzPay's id.
  Future<MarzTransaction?> transaction(String uuid) async {
    final body = await _send('GET', '/transactions/$uuid');
    // Answered without the usual "data" wrapper, with "event_type"
    // (collection.failed…) instead of "type".
    final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? body;
    final tx = (data['transaction'] as Map?)?.cast<String, dynamic>() ?? data;
    if (tx['uuid'] == null) return null;
    final event = '${body['event_type'] ?? data['event_type'] ?? ''}';
    return MarzTransaction.fromJson({
      ...tx,
      'type':
          tx['type'] ??
          (event.startsWith('collection')
              ? 'credit'
              : event.isNotEmpty
              ? 'debit'
              : 'unknown'),
    });
  }

  /// The wallet balance as the transaction list reports it (works without
  /// the IP whitelist, unlike /balance).
  Future<num?> balanceFromTransactions() async {
    final body = await _send('GET', '/transactions?per_page=1');
    final raw =
        (((body['data'] as Map?)?['account'] as Map?)?['current_balance']
            as Map?)?['raw'];
    return raw is num ? raw : num.tryParse('${raw ?? ''}');
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, Object?>? json,
  ]) async {
    final HttpClientResponse res;
    final String text;
    try {
      final req = await _http
          .openUrl(method, Uri.parse('$baseUrl$path'))
          .timeout(const Duration(seconds: 20));
      req.headers
        ..set(HttpHeaders.authorizationHeader, 'Basic $_auth')
        ..set(HttpHeaders.acceptHeader, 'application/json');
      if (json != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(json));
      }
      res = await req.close().timeout(const Duration(seconds: 30));
      text = await res.transform(utf8.decoder).join();
    } on Exception catch (e) {
      throw MarzPayException('network: $e');
    }
    Map<String, dynamic> body;
    try {
      body = (jsonDecode(text) as Map).cast<String, dynamic>();
    } catch (_) {
      throw MarzPayException(
        'unexpected response: ${text.length > 200 ? text.substring(0, 200) : text}',
        statusCode: res.statusCode,
      );
    }
    if (res.statusCode >= 400 || body['status'] == 'error') {
      throw MarzPayException(
        '${body['message'] ?? 'request failed'}',
        statusCode: res.statusCode,
        errorCode: body['error_code']?.toString(),
      );
    }
    return body;
  }

  /// For diagnostics: one raw request, never throws. [basicAuth] overrides
  /// the configured credentials (to prove bad ones are refused).
  Future<MarzProbe> probe(
    String method,
    String path, {
    Map<String, Object?>? json,
    String? basicAuth,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final watch = Stopwatch()..start();
    try {
      final req = await _http
          .openUrl(method, Uri.parse('$baseUrl$path'))
          .timeout(timeout);
      req.headers
        ..set(HttpHeaders.authorizationHeader, 'Basic ${basicAuth ?? _auth}')
        ..set(HttpHeaders.acceptHeader, 'application/json');
      if (json != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(json));
      }
      final res = await req.close().timeout(timeout);
      final text = await res.transform(utf8.decoder).join().timeout(timeout);
      Map<String, dynamic>? body;
      try {
        body = (jsonDecode(text) as Map).cast<String, dynamic>();
      } catch (_) {}
      return MarzProbe(res.statusCode, body, null, watch.elapsed);
    } on TimeoutException {
      return MarzProbe(null, null, 'timed out', watch.elapsed);
    } catch (e) {
      return MarzProbe(null, null, '$e', watch.elapsed);
    }
  }

  /// A short, safe form of the API key for display ("marz_t8…RL").
  String get maskedKey {
    try {
      final key = utf8.decode(base64Decode(_auth)).split(':').first;
      return key.length <= 8
          ? '••••'
          : '${key.substring(0, 7)}…${key.substring(key.length - 2)}';
    } catch (_) {
      return '••••';
    }
  }

  void close() => _http.close(force: true);
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
