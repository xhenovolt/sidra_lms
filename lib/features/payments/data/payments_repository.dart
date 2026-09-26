import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/network/postgres_api.dart';
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
  });

  factory CourseBalance.fromJson(Json j) => CourseBalance(
    fee: j.numOrNull('fee') ?? 0,
    paid: (j.numOrNull('paid') ?? 0) - (j.numOrNull('refunded') ?? 0),
    waived: j.numOrNull('waived') ?? 0,
    outstanding: j.numOrNull('outstanding') ?? 0,
    currency: j.strOrNull('currency') ?? 'UGX',
  );

  final double fee;
  final double paid;
  final double waived;
  final double outstanding;
  final String currency;
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

  /// Queues a MarzPay collection for what is owed; the payments server
  /// sends the prompt to [phone]. Returns the payment to watch.
  Future<Payment> payWithMobileMoney(String courseId, String phone) async {
    final res = await api.rpc(
      'start_course_payment',
      params: {'p_course_id': courseId, 'p_phone': phone},
    );
    return Payment.fromJson(Map<String, dynamic>.from(res as Map));
  }

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
