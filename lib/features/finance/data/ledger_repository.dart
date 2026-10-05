import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/network/postgres_api.dart';
import '../../../shared/models/json.dart';

/// An account in the chart, with its balance (natural side: assets and
/// expenses debit − credit; liabilities, equity and income credit − debit).
class LedgerAccount {
  const LedgerAccount({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.isMoney,
    required this.isActive,
    required this.balance,
    this.isSystem = false,
    this.description,
  });

  factory LedgerAccount.fromJson(Json j) => LedgerAccount(
    id: (j['account_id'] ?? j['id']) as String,
    code: j.str('code'),
    name: j.str('name'),
    type: j.str('type'),
    isMoney: j['is_money'] == true,
    isActive: j['is_active'] != false,
    isSystem: j['is_system'] == true,
    description: j.strOrNull('description'),
    balance: j.numOrNull('balance') ?? 0,
  );

  final String id;
  final String code;
  final String name;

  /// asset, liability, equity, income or expense.
  final String type;
  final bool isMoney;
  final bool isActive;
  final bool isSystem;
  final String? description;
  final double balance;

  String get label => '$code · $name';
}

/// Everything about Almuntahha's books: balances, statements, the journal,
/// bills, assets, budgets, counts and reports. Every call is checked in
/// PostgreSQL (finance.view to read; finance.post_journal or
/// finance.manage_accounts to write).
class LedgerRepository {
  LedgerRepository(this.api);
  final PostgresApi api;

  static String? _d(DateTime? d) => d?.toIso8601String().substring(0, 10);

  Future<Json> overview() async =>
      Map<String, dynamic>.from(await api.rpc('ledger_overview') as Map);

  Future<List<LedgerAccount>> accounts({DateTime? asOf}) async {
    final rows = await api.rpcRows(
      'ledger_balances',
      params: {'p_as_of': ?_d(asOf)},
    );
    // Descriptions and the built-in flag live on the accounts table.
    final meta = {
      for (final r in await api.select('ledger_accounts')) r['id'] as String: r,
    };
    return [
      for (final r in rows)
        LedgerAccount.fromJson({...?meta[r['account_id']], ...r}),
    ];
  }

  Future<Json> statement(
    String accountId, {
    DateTime? from,
    DateTime? to,
  }) async => Map<String, dynamic>.from(
    await api.rpc(
      'ledger_statement',
      params: {'p_account_id': accountId, 'p_from': ?_d(from), 'p_to': ?_d(to)},
    ) as Map,
  );

  Future<List<Json>> journal({
    DateTime? from,
    DateTime? to,
    String? sourceType,
    int limit = 100,
  }) async => _list(
    await api.rpc(
      'ledger_journal',
      params: {
        'p_from': ?_d(from),
        'p_to': ?_d(to),
        'p_source_type': ?sourceType,
        'p_limit': limit,
      },
    ),
  );

  Future<Json> report(String function, {DateTime? from, DateTime? to}) async =>
      Map<String, dynamic>.from(
        await api.rpc(
          function,
          params: {
            if (function == 'ledger_balance_sheet')
              'p_as_of': ?_d(to)
            else ...{
              'p_from': _d(from),
              'p_to': _d(to),
            },
          },
        ) as Map,
      );

  Future<List<Json>> budgetReport(DateTime from, DateTime to) async => _list(
    await api.rpc(
      'ledger_budget_report',
      params: {'p_from': _d(from), 'p_to': _d(to)},
    ),
  );

  Future<List<Json>> bills({bool includePaid = false}) async => _list(
    await api.rpc('ledger_bills', params: {'p_include_paid': includePaid}),
  );

  Future<List<Json>> assets() async => _list(await api.rpc('ledger_assets'));

  Future<List<Json>> reconciliations() async =>
      _list(await api.rpc('ledger_reconciliations'));

  /// Refunds: owed to learners first, then paid out.
  Future<List<Json>> refunds({bool owedOnly = false}) async => _list(
    await api.rpc('finance_refunds', params: {'p_owed_only': owedOnly}),
  );

  Future<void> payOutRefund({
    required String refundId,
    required String fromAccount,
    required String method,
    required String reference,
    required DateTime paidOn,
  }) => api.rpc(
    'pay_out_refund',
    params: {
      'p_refund_id': refundId,
      'p_from_account': fromAccount,
      'p_method': method,
      'p_reference': reference,
      'p_paid_on': _d(paidOn),
    },
  );

  /// How Sidra's MarzPay payments compare with MarzPay's own records.
  Future<Json> marzpayCheck() async =>
      Map<String, dynamic>.from(await api.rpc('marzpay_check_report') as Map);

  /// Records who confirmed the books' rules (the organisation's accountant).
  Future<void> confirmRules(String confirmedBy, String? note) => api.rpc(
    'ledger_confirm_rules',
    params: {'p_confirmed_by': confirmedBy, 'p_note': ?note},
  );

  static List<Json> _list(Object? v) => [
    for (final r in (v as List?) ?? const [])
      Map<String, dynamic>.from(r as Map),
  ];

  // ------------------------------------------------------------ writes --

  Future<void> setOpeningBalance(
    String accountId,
    double amount,
    DateTime asOf,
  ) => api.rpc(
    'ledger_set_opening_balance',
    params: {
      'p_account_id': accountId,
      'p_amount': amount,
      'p_as_of': _d(asOf),
    },
  );

  Future<void> transfer({
    required String from,
    required String to,
    required double amount,
    required DateTime date,
    String? memo,
    double? fee,
  }) => api.rpc(
    'ledger_transfer',
    params: {
      'p_from': from,
      'p_to': to,
      'p_amount': amount,
      'p_date': _d(date),
      'p_memo': ?memo,
      'p_fee': ?fee,
    },
  );

  Future<void> moneyIn({
    required String to,
    required String source,
    required double amount,
    required DateTime date,
    String? memo,
  }) => api.rpc(
    'ledger_money_in',
    params: {
      'p_to': to,
      'p_source_account': source,
      'p_amount': amount,
      'p_date': _d(date),
      'p_memo': ?memo,
    },
  );

  Future<void> moneyOut({
    required String from,
    required String target,
    required double amount,
    required DateTime date,
    String? memo,
  }) => api.rpc(
    'ledger_money_out',
    params: {
      'p_from': from,
      'p_target_account': target,
      'p_amount': amount,
      'p_date': _d(date),
      'p_memo': ?memo,
    },
  );

  Future<void> recordExpense({
    required String accountId,
    required String accountName,
    required String paidFrom,
    required double amount,
    required DateTime spentOn,
    String? payee,
    String? description,
  }) => api.rpc(
    'record_expense',
    params: {
      'p_category': accountName,
      'p_amount': amount,
      'p_spent_on': _d(spentOn),
      'p_description': ?description,
      'p_payee': ?payee,
      'p_account_id': accountId,
      'p_paid_from_account_id': paidFrom,
    },
  );

  /// lines: (accountId, debit, credit, memo)
  Future<void> postJournal(
    DateTime date,
    String memo,
    List<(String, double, double, String?)> lines,
  ) => api.rpc(
    'ledger_post_journal',
    params: {
      'p_date': _d(date),
      'p_memo': memo,
      'p_lines': [
        for (final (a, d, c, m) in lines)
          {'account_id': a, 'debit': d, 'credit': c, 'memo': ?m},
      ],
    },
  );

  Future<void> reverse(String entryId, String reason) => api.rpc(
    'ledger_reverse',
    params: {'p_entry_id': entryId, 'p_reason': reason},
  );

  Future<void> recordBill({
    required String supplier,
    required String accountId,
    required double amount,
    required DateTime billDate,
    DateTime? dueDate,
    String? description,
  }) => api.rpc(
    'ledger_record_bill',
    params: {
      'p_supplier': supplier,
      'p_account_id': accountId,
      'p_amount': amount,
      'p_bill_date': _d(billDate),
      'p_due_date': ?_d(dueDate),
      'p_description': ?description,
    },
  );

  Future<void> payBill(
    String billId,
    String from,
    double amount,
    DateTime paidOn,
  ) => api.rpc(
    'ledger_pay_bill',
    params: {
      'p_bill_id': billId,
      'p_from': from,
      'p_amount': amount,
      'p_paid_on': _d(paidOn),
    },
  );

  Future<void> voidBill(String billId, String reason) => api.rpc(
    'ledger_void_bill',
    params: {'p_bill_id': billId, 'p_reason': reason},
  );

  Future<void> recordAsset({
    required String name,
    required double cost,
    required DateTime purchasedOn,
    required String paidFrom,
    int? usefulLifeMonths,
    String? note,
  }) => api.rpc(
    'ledger_record_asset',
    params: {
      'p_name': name,
      'p_cost': cost,
      'p_purchased_on': _d(purchasedOn),
      'p_paid_from': paidFrom,
      'p_useful_life_months': ?usefulLifeMonths,
      'p_note': ?note,
    },
  );

  Future<int> postDepreciation(DateTime month) async {
    final n = await api.rpc(
      'ledger_post_depreciation',
      params: {'p_month': _d(month)},
    );
    return int.tryParse('$n') ?? 0;
  }

  Future<Json> reconcile({
    required String accountId,
    required DateTime asOf,
    required double counted,
    String? note,
    bool postDifference = false,
  }) async => Map<String, dynamic>.from(
    await api.rpc(
      'ledger_reconcile',
      params: {
        'p_account_id': accountId,
        'p_as_of': _d(asOf),
        'p_counted': counted,
        'p_note': ?note,
        'p_post_difference': postDifference,
      },
    ) as Map,
  );

  Future<void> setBudget(String accountId, DateTime month, double amount) =>
      api.rpc(
        'ledger_set_budget',
        params: {
          'p_account_id': accountId,
          'p_month': _d(DateTime(month.year, month.month)),
          'p_amount': amount,
        },
      );

  Future<void> closeBooks(DateTime? through) =>
      api.rpc('ledger_close_books', params: {'p_through': _d(through)});

  Future<void> saveAccount({
    String? id,
    required String code,
    required String name,
    required String type,
    bool isMoney = false,
    String? description,
    bool isActive = true,
  }) => api.rpc(
    'ledger_save_account',
    params: {
      'p_id': id,
      'p_code': code,
      'p_name': name,
      'p_type': type,
      'p_is_money': isMoney,
      'p_description': description,
      'p_is_active': isActive,
    },
  );
}

final ledgerRepositoryProvider = Provider<LedgerRepository>(
  (ref) => LedgerRepository(ref.watch(postgresApiProvider)),
);

final ledgerOverviewProvider = FutureProvider.autoDispose<Json>(
  (ref) => ref.watch(ledgerRepositoryProvider).overview(),
);

final ledgerAccountsProvider = FutureProvider.autoDispose<List<LedgerAccount>>(
  (ref) => ref.watch(ledgerRepositoryProvider).accounts(),
);

final ledgerBillsProvider = FutureProvider.autoDispose<List<Json>>(
  (ref) => ref.watch(ledgerRepositoryProvider).bills(includePaid: true),
);

final ledgerAssetsProvider = FutureProvider.autoDispose<List<Json>>(
  (ref) => ref.watch(ledgerRepositoryProvider).assets(),
);

final ledgerReconciliationsProvider = FutureProvider.autoDispose<List<Json>>(
  (ref) => ref.watch(ledgerRepositoryProvider).reconciliations(),
);

final ledgerRefundsProvider = FutureProvider.autoDispose<List<Json>>(
  (ref) => ref.watch(ledgerRepositoryProvider).refunds(),
);

final marzpayCheckProvider = FutureProvider.autoDispose<Json>(
  (ref) => ref.watch(ledgerRepositoryProvider).marzpayCheck(),
);

/// Every screen showing the books, refreshed after a change.
void refreshLedger(WidgetRef ref) {
  ref.invalidate(ledgerRefundsProvider);
  ref.invalidate(marzpayCheckProvider);
  ref.invalidate(ledgerOverviewProvider);
  ref.invalidate(ledgerAccountsProvider);
  ref.invalidate(ledgerBillsProvider);
  ref.invalidate(ledgerAssetsProvider);
  ref.invalidate(ledgerReconciliationsProvider);
}
