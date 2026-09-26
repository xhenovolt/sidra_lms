import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/network/postgres_api.dart';
import '../../../shared/models/json.dart';

/// Totals for a period (`finance_summary`).
class FinanceSummary {
  const FinanceSummary({
    required this.currency,
    required this.expected,
    required this.collected,
    required this.outstanding,
    required this.waived,
    required this.refunded,
    required this.providerFees,
    required this.expenses,
    required this.retained,
    required this.pendingCount,
    required this.pendingAmount,
    required this.byCourse,
    required this.byMethod,
  });

  factory FinanceSummary.fromJson(Json j) => FinanceSummary(
    currency: j.strOrNull('currency') ?? 'UGX',
    expected: j.numOrNull('expected') ?? 0,
    collected: j.numOrNull('collected') ?? 0,
    outstanding: j.numOrNull('outstanding') ?? 0,
    waived: j.numOrNull('waived') ?? 0,
    refunded: j.numOrNull('refunded') ?? 0,
    providerFees: j.numOrNull('provider_fees') ?? 0,
    expenses: j.numOrNull('expenses') ?? 0,
    retained: j.numOrNull('retained') ?? 0,
    pendingCount: j.integer('pending_count', fallback: 0),
    pendingAmount: j.numOrNull('pending_amount') ?? 0,
    byCourse: [
      for (final c in (j['by_course'] as List? ?? const []))
        Map<String, dynamic>.from(c as Map),
    ],
    byMethod: {
      for (final e in (j['by_method'] as Map? ?? const {}).entries)
        '${e.key}': (e.value as num).toDouble(),
    },
  );

  final String currency;
  final double expected;
  final double collected;
  final double outstanding;
  final double waived;
  final double refunded;
  final double providerFees;
  final double expenses;
  final double retained;
  final int pendingCount;
  final double pendingAmount;
  final List<Json> byCourse;
  final Map<String, double> byMethod;
}

/// A payment row for finance officers (`finance_payments`).
class FinancePayment {
  const FinancePayment(this.j);
  final Json j;

  String get id => j.str('id');
  String get userId => j.str('user_id');
  String get learner => j.strOrNull('learner') ?? '—';
  String? get course => j.strOrNull('course');
  String? get courseId => j.strOrNull('course_id');
  double get amount => j.numOrNull('amount') ?? 0;
  double get refunded => j.numOrNull('refunded') ?? 0;
  String get currency => j.strOrNull('currency') ?? 'UGX';
  String get method => j.strOrNull('method') ?? '';
  String get status => j.strOrNull('status') ?? '';
  String? get reference => j.strOrNull('external_reference');
  String? get phone => j.strOrNull('phone');
  String? get note => j.strOrNull('note');
  String? get reason => j.strOrNull('status_reason');
  String? get recordedBy => j.strOrNull('recorded_by');
  String? get verifiedBy => j.strOrNull('verified_by');
  DateTime? get createdAt => j.dateOrNull('created_at');
  DateTime? get verifiedAt => j.dateOrNull('verified_at');
  int get total => j.integer('total', fallback: 0);
}

class FinanceRepository {
  FinanceRepository(this.api);
  final PostgresApi api;

  Future<FinanceSummary> summary({DateTime? from, DateTime? to}) async {
    final res = await api.rpc(
      'finance_summary',
      params: {'p_from': ?_date(from), 'p_to': ?_date(to)},
    );
    return FinanceSummary.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<List<FinancePayment>> payments({
    String? status,
    String? method,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async => [
    for (final r in await api.rpcRows(
      'finance_payments',
      params: {
        'p_status': ?status,
        'p_method': ?method,
        if (search != null && search.trim().isNotEmpty)
          'p_search': search.trim(),
        'p_limit': limit,
        'p_offset': offset,
      },
    ))
      FinancePayment(r),
  ];

  Future<List<Json>> balances({bool onlyOwing = true}) =>
      api.rpcRows('finance_balances', params: {'p_only_owing': onlyOwing});

  Future<List<Json>> waivers() => api.rpcRows('finance_waivers');

  Future<List<Json>> expenses({DateTime? from, DateTime? to}) => api.rpcRows(
    'finance_expenses',
    params: {'p_from': ?_date(from), 'p_to': ?_date(to)},
  );

  Future<void> recordPayment({
    required String userId,
    required String courseId,
    required double amount,
    required String method,
    required String reference,
    DateTime? paidOn,
    String? note,
  }) => api.rpc(
    'record_payment',
    params: {
      'p_user_id': userId,
      'p_course_id': courseId,
      'p_amount': amount,
      'p_method': method,
      'p_external_reference': reference,
      'p_paid_on': ?_date(paidOn),
      'p_note': ?note,
    },
  );

  Future<void> verify(String paymentId) =>
      api.rpc('verify_payment', params: {'p_payment_id': paymentId});

  Future<void> reject(String paymentId, String reason) => api.rpc(
    'reject_payment',
    params: {'p_payment_id': paymentId, 'p_reason': reason},
  );

  Future<void> reverse(String paymentId, String reason) => api.rpc(
    'reverse_payment',
    params: {'p_payment_id': paymentId, 'p_reason': reason},
  );

  Future<void> refund(String paymentId, double amount, String reason) =>
      api.rpc(
        'record_refund',
        params: {
          'p_payment_id': paymentId,
          'p_amount': amount,
          'p_reason': reason,
        },
      );

  Future<void> grantWaiver({
    required String userId,
    required String courseId,
    double? amount,
    required String reason,
  }) => api.rpc(
    'grant_waiver',
    params: {
      'p_user_id': userId,
      'p_course_id': courseId,
      'p_amount': amount,
      'p_reason': reason,
    },
  );

  Future<void> revokeWaiver(String waiverId, String reason) => api.rpc(
    'revoke_waiver',
    params: {'p_waiver_id': waiverId, 'p_reason': reason},
  );

  Future<void> recordExpense({
    required String category,
    required double amount,
    required DateTime spentOn,
    String? description,
    String? payee,
  }) => api.rpc(
    'record_expense',
    params: {
      'p_category': category,
      'p_amount': amount,
      'p_spent_on': _date(spentOn),
      'p_description': ?description,
      'p_payee': ?payee,
    },
  );

  Future<void> voidExpense(String expenseId, String reason) => api.rpc(
    'void_expense',
    params: {'p_expense_id': expenseId, 'p_reason': reason},
  );

  Future<Map<String, String?>> settings() async {
    final res = await api.rpc('org_settings');
    return {
      for (final e in (res as Map? ?? const {}).entries)
        '${e.key}': e.value as String?,
    };
  }

  Future<void> setSetting(String key, String? value) =>
      api.rpc('set_org_setting', params: {'p_key': key, 'p_value': value});

  Future<void> bulkEnrol(
    String courseId,
    List<String> userIds, {
    DateTime? startsAt,
    DateTime? endsAt,
  }) => api.rpc(
    'bulk_enrol',
    params: {
      'p_course_id': courseId,
      'p_user_ids': userIds,
      'p_starts_at': ?startsAt?.toUtc().toIso8601String(),
      'p_ends_at': ?endsAt?.toUtc().toIso8601String(),
    },
  );

  static String? _date(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';
}

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(postgresApiProvider)),
);
