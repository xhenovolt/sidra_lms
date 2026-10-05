import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/network/postgres_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';

enum PaymentStatus {
  initiated,
  processing,
  pending,
  verified,
  failed,
  rejected,
  reversed,
}

/// One payment as the payer (or finance) sees it.
class Payment {
  const Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    this.courseId,
    this.statusReason,
    this.phone,
    this.externalReference,
    this.reference,
    this.providerUuid,
    this.createdAt,
  });

  factory Payment.fromJson(Json j) => Payment(
    id: j.str('id'),
    courseId: j.strOrNull('course_id'),
    amount: j.numOrNull('amount') ?? 0,
    currency: j.strOrNull('currency') ?? 'UGX',
    method: j.strOrNull('method') ?? 'marzpay',
    status: enumByName(
      PaymentStatus.values,
      j.strOrNull('status'),
      PaymentStatus.pending,
    ),
    statusReason: j.strOrNull('status_reason'),
    phone: j.strOrNull('phone'),
    externalReference: j.strOrNull('external_reference'),
    reference: j.strOrNull('reference'),
    providerUuid: j.strOrNull('provider_uuid'),
    createdAt: j.dateOrNull('created_at'),
  );

  final String id;
  final String? courseId;
  final double amount;
  final String currency;
  final String method;
  final PaymentStatus status;
  final String? statusReason;
  final String? phone;
  final String? externalReference;

  /// Our reference at MarzPay, and MarzPay's own id once sent.
  final String? reference;
  final String? providerUuid;
  final DateTime? createdAt;

  /// Waiting on the payer's phone (MarzPay prompt).
  bool get awaitingPayer =>
      status == PaymentStatus.initiated || status == PaymentStatus.processing;
}

/// What a learner owes for a course.
class CourseBalance {
  const CourseBalance({
    required this.fee,
    required this.paid,
    required this.waived,
    required this.outstanding,
    required this.currency,
    this.billingPeriod = 'once',
    this.intervalDays,
    this.periodsTotal,
    this.pricePerPeriod,
    this.periodsDue = 1,
    this.periodsCovered,
    this.nextDueOn,
    this.pausedForFees = false,
  });

  factory CourseBalance.fromJson(Json j) => CourseBalance(
    fee: j.numOrNull('fee') ?? 0,
    paid: (j.numOrNull('paid') ?? 0) - (j.numOrNull('refunded') ?? 0),
    waived: j.numOrNull('waived') ?? 0,
    outstanding: j.numOrNull('outstanding') ?? 0,
    currency: j.strOrNull('currency') ?? 'UGX',
    billingPeriod: j.strOrNull('billing_period') ?? 'once',
    intervalDays: j.numOrNull('billing_interval_days')?.toInt(),
    periodsTotal: j.numOrNull('billing_periods')?.toInt(),
    pricePerPeriod: j.numOrNull('price_per_period'),
    periodsDue: j.numOrNull('periods_due')?.toInt() ?? 1,
    periodsCovered: j.numOrNull('periods_covered')?.toInt(),
    nextDueOn: j.dateOrNull('next_due_on'),
    pausedForFees: j['paused_for_fees'] == true,
  );

  /// What is due so far (the price per period × the periods begun).
  final double fee;
  final double paid;
  final double waived;
  final double outstanding;
  final String currency;

  /// once | weekly | monthly | termly | custom (every [intervalDays]).
  final String billingPeriod;
  final int? intervalDays;
  final int? periodsTotal;
  final double? pricePerPeriod;
  final int periodsDue;
  final int? periodsCovered;
  final DateTime? nextDueOn;

  /// The course is paused because a period went unpaid.
  final bool pausedForFees;

  bool get recurring => billingPeriod != 'once';
}

/// "UGX 30,000 / month", or just "UGX 50,000" for a one-time fee.
String priceWithPeriod(
  AppLocalizations l10n,
  num amount,
  String currency,
  String period, [
  int? days,
]) {
  final money = formatMoney(amount, currency);
  return switch (period) {
    'weekly' => l10n.billPerWeek(money),
    'monthly' => l10n.billPerMonth(money),
    'termly' => l10n.billPerTerm(money),
    'custom' => l10n.billPerDays(money, days ?? 30),
    _ => money,
  };
}

class PaymentsRepository {
  PaymentsRepository(this.api);
  final PostgresApi api;

  Future<CourseBalance> balance(String courseId) async {
    final res = await api.rpc(
      'my_course_balance',
      params: {'p_course_id': courseId},
    );
    return CourseBalance.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Creates the MarzPay payment for what is owed (the app then sends the
  /// prompt to [phone]; see DirectPayments). Returns the payment to watch.
  /// With [periods] (repeating fees): pays that many periods ahead.
  Future<Payment> payWithMobileMoney(
    String courseId,
    String phone, {
    int? periods,
  }) async {
    final res = await api.rpc(
      'start_course_payment',
      params: {
        'p_course_id': courseId,
        'p_phone': phone,
        'p_periods': ?periods,
      },
    );
    return Payment.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// What paying for [periods] periods costs and covers (from the database:
  /// amount, covers_from, covers_until, min_periods, max_periods).
  Future<Json> prepayQuote(String courseId, int periods) async =>
      Map<String, dynamic>.from(
        await api.rpc(
          'prepay_quote',
          params: {'p_course_id': courseId, 'p_periods': periods},
        ) as Map,
      );

  /// Every payment the learner made, newest first (with course names).
  Future<List<Json>> myPaymentHistory() async => [
    for (final r in (await api.rpc('my_payment_history') as List? ?? const []))
      Map<String, dynamic>.from(r as Map),
  ];

  /// A confirmed payment's receipt (the learner's own, or any for finance).
  Future<Json> receipt(String paymentId) async => Map<String, dynamic>.from(
    await api.rpc('payment_receipt', params: {'p_payment_id': paymentId})
        as Map,
  );

  /// "I paid by bank / mobile money": finance confirms it later.
  Future<Payment> reportPayment({
    required String courseId,
    required String method,
    required double amount,
    required String reference,
    String? note,
  }) async {
    final res = await api.rpc(
      'submit_manual_payment',
      params: {
        'p_course_id': courseId,
        'p_method': method,
        'p_amount': amount,
        'p_external_reference': reference,
        'p_note': ?note,
      },
    );
    return Payment.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<List<Payment>> myPayments(String courseId) async {
    final rows = await api.rpcRows(
      'my_payments',
      params: {'p_course_id': courseId},
    );
    return [
      for (final r in rows)
        Payment.fromJson(
          Map<String, dynamic>.from((r['my_payments'] ?? r) as Map),
        ),
    ];
  }

  /// Public organisation settings (name, bank / mobile-money instructions).
  Future<Map<String, String?>> orgSettings() async {
    final res = await api.rpc('org_settings');
    return {
      for (final e in (res as Map? ?? const {}).entries)
        '${e.key}': e.value as String?,
    };
  }
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>(
  (ref) => PaymentsRepository(ref.watch(postgresApiProvider)),
);

final courseBalanceProvider = FutureProvider.autoDispose
    .family<CourseBalance, String>(
      (ref, courseId) =>
          ref.watch(paymentsRepositoryProvider).balance(courseId),
    );

final orgSettingsProvider = FutureProvider.autoDispose<Map<String, String?>>(
  (ref) => ref.watch(paymentsRepositoryProvider).orgSettings(),
);

String formatMoney(num amount, String currency) {
  final whole = amount.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$currency $whole';
}
