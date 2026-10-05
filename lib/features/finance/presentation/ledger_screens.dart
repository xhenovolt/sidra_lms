import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../../core/export/documents.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../../admin/presentation/admin_common.dart';
import '../../admin/presentation/admin_shell.dart' show myPermissionsProvider;
import '../../admin/presentation/finance_screen.dart' show askText;
import '../../payments/data/payments_repository.dart' show formatMoney;
import '../data/ledger_repository.dart';
import 'ledger_forms.dart';

String _m(num v) => formatMoney(v, 'UGX');

Set<String> _perms(WidgetRef ref) =>
    ref.watch(myPermissionsProvider).value ?? const {};

Widget _async<T>(
  WidgetRef ref,
  AsyncValue<T> value,
  void Function() retry,
  Widget Function(T data) data,
) => switch (value) {
  AsyncData(:final value) => data(value),
  AsyncError(:final error) => ListView(
    children: [ErrorView(error: error, onRetry: retry)],
  ),
  _ => const LoadingView(),
};

// ------------------------------------------------------------ accounts --

/// The chart of accounts with every balance, by kind. Tap an account for
/// its statement; its menu sets the opening balance, counts it or edits it.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final perms = _perms(ref);
    final canPost = perms.contains('finance.post_journal');
    final canManage = perms.contains('finance.manage_accounts');
    final accounts = ref.watch(ledgerAccountsProvider);
    return Scaffold(
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'add-account',
              onPressed: () => editAccount(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.lgAddAccount),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ledgerAccountsProvider.future),
        child: _async(
          ref,
          accounts,
          () => ref.invalidate(ledgerAccountsProvider),
          (all) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: Text(
                    l10n.lgAccountsIntro,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                for (final type in const [
                  'asset',
                  'liability',
                  'equity',
                  'income',
                  'expense',
                ]) ...[
                  ListTile(
                    title: Text(
                      accountTypeLabel(l10n, type),
                      style: theme.textTheme.titleMedium,
                    ),
                    trailing: Text(
                      _m(
                        all
                            .where((a) => a.type == type)
                            .fold<double>(0, (s, a) => s + a.balance),
                      ),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  for (final a in all.where((a) => a.type == type))
                    ListTile(
                      dense: true,
                      enabled: a.isActive,
                      leading: Icon(
                        a.isMoney
                            ? Icons.account_balance_wallet_outlined
                            : Icons.label_outline,
                      ),
                      title: Text(a.name),
                      subtitle: Text(a.code),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_m(a.balance)),
                          if (canPost || canManage)
                            PopupMenuButton<String>(
                              onSelected: (v) => switch (v) {
                                'opening' => setOpeningBalance(context, ref, a),
                                'count' => runLedgerAction(
                                  context,
                                  ref,
                                  LedgerAction.count,
                                  account: a,
                                ),
                                'budget' => setBudget(context, ref, account: a),
                                _ => editAccount(context, ref, account: a),
                              },
                              itemBuilder: (_) => [
                                if (canPost &&
                                    a.type != 'income' &&
                                    a.type != 'expense' &&
                                    a.code != '3000')
                                  PopupMenuItem(
                                    value: 'opening',
                                    child: Text(l10n.lgSetOpening),
                                  ),
                                if (canManage && a.isMoney)
                                  PopupMenuItem(
                                    value: 'count',
                                    child: Text(l10n.lgCountMoney),
                                  ),
                                if (canManage &&
                                    (a.type == 'income' || a.type == 'expense'))
                                  PopupMenuItem(
                                    value: 'budget',
                                    child: Text(l10n.lgSetBudget),
                                  ),
                                if (canManage)
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(l10n.lgEditAccount),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              StatementScreen(accountId: a.id, title: a.name),
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One account's movements with the running balance.
class StatementScreen extends ConsumerStatefulWidget {
  const StatementScreen({
    super.key,
    required this.accountId,
    required this.title,
  });
  final String accountId;
  final String title;

  @override
  ConsumerState<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends ConsumerState<StatementScreen> {
  late Future<Json> _data = _load();

  Future<Json> _load() =>
      ref.read(ledgerRepositoryProvider).statement(widget.accountId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd(l10n.localeName);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<Json>(
        future: _data,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorView(
              error: snap.error!,
              onRetry: () => setState(() => _data = _load()),
            );
          }
          if (!snap.hasData) return const LoadingView();
          final lines = [
            for (final l in (snap.data!['lines'] as List? ?? const []))
              Map<String, dynamic>.from(l as Map),
          ].reversed.toList();
          final account = Map<String, dynamic>.from(
            snap.data!['account'] as Map,
          );
          return RefreshIndicator(
            onRefresh: () async => setState(() => _data = _load()),
            child: lines.isEmpty
                ? ListView(
                    children: [
                      if (account.strOrNull('description') != null)
                        Padding(
                          padding: const EdgeInsets.all(Space.md),
                          child: Text(account.str('description')),
                        ),
                      EmptyView(
                        icon: Icons.receipt_long_outlined,
                        title: l10n.lgNoMovements,
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: lines.length + 1,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return ListTile(
                          title: Text(
                            l10n.lgBalanceNow,
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: account.strOrNull('description') == null
                              ? null
                              : Text(account.str('description')),
                          trailing: Text(
                            _m(lines.first.numOrNull('running') ?? 0),
                            style: theme.textTheme.titleMedium,
                          ),
                        );
                      }
                      final l = lines[i - 1];
                      final dr = l.numOrNull('debit') ?? 0;
                      final cr = l.numOrNull('credit') ?? 0;
                      return ListTile(
                        title: Text(l.str('memo')),
                        subtitle: Text(
                          [
                            date.format(DateTime.parse(l.str('entry_date'))),
                            '#${l['number']}',
                            ?l.strOrNull('person'),
                          ].join(' · '),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              dr > 0 ? l10n.lgDr(_m(dr)) : l10n.lgCr(_m(cr)),
                            ),
                            Text(
                              _m(l.numOrNull('running') ?? 0),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------- journal --

final _journalFilterProvider = StateProvider.autoDispose<String?>((_) => null);
final _journalProvider = FutureProvider.autoDispose<List<Json>>((ref) {
  ref.watch(ledgerOverviewProvider); // refreshed with the books
  return ref
      .watch(ledgerRepositoryProvider)
      .journal(sourceType: ref.watch(_journalFilterProvider));
});

String sourceLabel(AppLocalizations l10n, String s) => switch (s) {
  'payment' => l10n.lgSrcPayment,
  'refund' => l10n.lgSrcRefund,
  'expense' => l10n.lgSrcExpense,
  'test' => l10n.lgSrcTest,
  'opening' => l10n.lgSrcOpening,
  'transfer' => l10n.lgTransfer,
  'money_in' => l10n.lgMoneyIn,
  'money_out' => l10n.lgMoneyOut,
  'bill' => l10n.lgSrcBill,
  'bill_payment' => l10n.lgSrcBillPayment,
  'asset' => l10n.lgSrcAsset,
  'depreciation' => l10n.lgSrcDepreciation,
  'reconciliation' => l10n.lgCountMoney,
  'manual' => l10n.lgSrcManual,
  _ => l10n.lgSrcReversal,
};

/// The journal (up to 500 entries, current filter) as a spreadsheet or PDF:
/// one row per line, so debits and credits can be totalled.
Future<void> _exportJournal(
  BuildContext context,
  WidgetRef ref,
  String? filter, {
  required bool pdf,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final entries = await ref
      .read(ledgerRepositoryProvider)
      .journal(sourceType: filter, limit: 500);
  final table = DocTable(
    title: l10n.lgJournal,
    subtitle: filter == null ? null : sourceLabel(l10n, filter),
    columns: [
      l10n.lgDate,
      '#',
      l10n.lgDescription,
      l10n.lgAccountCode,
      l10n.lgAccountName,
      l10n.lgDebit,
      l10n.lgCredit,
    ],
    numeric: {5, 6},
    rows: [
      for (final e in entries.reversed)
        for (final l in (e['lines'] as List? ?? const []))
          [
            e['entry_date'],
            e['number'],
            e['memo'],
            (l as Map)['code'],
            l['account'],
            num.tryParse('${l['debit']}') == 0
                ? null
                : num.tryParse('${l['debit']}'),
            num.tryParse('${l['credit']}') == 0
                ? null
                : num.tryParse('${l['credit']}'),
          ],
    ],
  );
  final name =
      'sidra-journal-${DateTime.now().toIso8601String().substring(0, 10)}';
  final ok = await saveDocument(
    pdf ? '$name.pdf' : '$name.xlsx',
    pdf
        ? await tablesToPdf([table], header: l10n.exHeader)
        : tablesToXlsx([table]),
  );
  if (ok) messenger.showSnackBar(SnackBar(content: Text(l10n.rcSaved)));
}

/// Every entry in the books, newest first, with its debit and credit lines.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  static const _reversible = {
    'manual',
    'transfer',
    'money_in',
    'money_out',
    'opening',
    'reconciliation',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canPost = _perms(ref).contains('finance.post_journal');
    final filter = ref.watch(_journalFilterProvider);
    final entries = ref.watch(_journalProvider);
    final date = DateFormat.yMMMd(l10n.localeName);
    return Scaffold(
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              heroTag: 'journal-entry',
              onPressed: () => postJournalEntry(context, ref),
              icon: const Icon(Icons.edit_note),
              label: Text(l10n.lgJournalEntry),
            )
          : null,
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.xs,
            ),
            child: Row(
              children: [
                for (final s in [
                  null,
                  'payment',
                  'test',
                  'expense',
                  'transfer',
                  'money_in',
                  'money_out',
                  'bill',
                  'manual',
                  'opening',
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
                    child: ChoiceChip(
                      label: Text(
                        s == null ? l10n.lgAll : sourceLabel(l10n, s),
                      ),
                      selected: filter == s,
                      onSelected: (_) =>
                          ref.read(_journalFilterProvider.notifier).state = s,
                    ),
                  ),
                IconButton(
                  tooltip: l10n.exDownloadExcel,
                  icon: const Icon(Icons.table_view_outlined),
                  onPressed: () =>
                      _exportJournal(context, ref, filter, pdf: false),
                ),
                IconButton(
                  tooltip: l10n.exDownloadPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () =>
                      _exportJournal(context, ref, filter, pdf: true),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(_journalProvider.future),
              child: _async(
                ref,
                entries,
                () => ref.invalidate(_journalProvider),
                (list) {
                  if (list.isEmpty) {
                    return ListView(
                      children: [
                        EmptyView(
                          icon: Icons.menu_book_outlined,
                          title: l10n.lgNoEntries,
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final e = list[i];
                      final lines = [
                        for (final l in (e['lines'] as List? ?? const []))
                          Map<String, dynamic>.from(l as Map),
                      ];
                      final total = lines.fold<double>(
                        0,
                        (s, l) => s + (l.numOrNull('debit') ?? 0),
                      );
                      final reversed = e['reversed'] == true;
                      return ExpansionTile(
                        title: Text(
                          e.str('memo'),
                          style: reversed
                              ? const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                )
                              : null,
                        ),
                        subtitle: Text(
                          [
                            date.format(DateTime.parse(e.str('entry_date'))),
                            '#${e['number']}',
                            sourceLabel(l10n, e.str('source_type')),
                            if (reversed) l10n.lgReversed,
                            ?e.strOrNull('created_by'),
                          ].join(' · '),
                        ),
                        trailing: Text(_m(total)),
                        children: [
                          for (final l in lines)
                            ListTile(
                              dense: true,
                              title: Text('${l['code']} · ${l['account']}'),
                              subtitle: l.strOrNull('memo') == null
                                  ? null
                                  : Text(l.str('memo')),
                              trailing: Text(
                                (l.numOrNull('debit') ?? 0) > 0
                                    ? l10n.lgDr(_m(l.numOrNull('debit')!))
                                    : l10n.lgCr(_m(l.numOrNull('credit') ?? 0)),
                              ),
                            ),
                          if (canPost &&
                              !reversed &&
                              e['reverses'] == null &&
                              _reversible.contains(e.str('source_type')))
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton.icon(
                                icon: const Icon(Icons.undo),
                                label: Text(l10n.lgReverse),
                                onPressed: () async {
                                  final reason = await askText(
                                    context,
                                    title: l10n.lgReverse,
                                    label: l10n.reason,
                                  );
                                  if (reason == null || !context.mounted) {
                                    return;
                                  }
                                  if (await runAdminAction(
                                    context,
                                    () => ref
                                        .read(ledgerRepositoryProvider)
                                        .reverse(e.str('id'), reason),
                                    success: l10n.adminSaved,
                                  )) {
                                    refreshLedger(ref);
                                  }
                                },
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.sm),
                            child: Text(
                              l10n.lgEntryBalanced,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- bills --

/// Bills received: what is still owed, paid in full or in parts.
class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canPost = _perms(ref).contains('finance.post_journal');
    final bills = ref.watch(ledgerBillsProvider);
    final date = DateFormat.yMMMd(l10n.localeName);
    return Scaffold(
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              heroTag: 'record-bill',
              onPressed: () => runLedgerAction(context, ref, LedgerAction.bill),
              icon: const Icon(Icons.add),
              label: Text(l10n.lgRecordBill),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ledgerBillsProvider.future),
        child: _async(ref, bills, () => ref.invalidate(ledgerBillsProvider), (
          list,
        ) {
          if (list.isEmpty) {
            return ListView(
              children: [
                EmptyView(
                  icon: Icons.request_page_outlined,
                  title: l10n.lgNoBills,
                  message: l10n.lgBillsHint,
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final b = list[i];
              final owed = b.numOrNull('owed') ?? 0;
              final due = b.strOrNull('due_date');
              final late =
                  due != null &&
                  owed > 0 &&
                  DateTime.parse(due).isBefore(DateTime.now());
              return ListTile(
                title: Text(
                  '${b.str('supplier')} · ${_m(b.numOrNull('amount') ?? 0)}',
                ),
                subtitle: Text(
                  [
                    b.str('account'),
                    ?b.strOrNull('description'),
                    if (due != null)
                      l10n.lgDue(date.format(DateTime.parse(due))),
                  ].join(' · '),
                ),
                trailing: owed > 0
                    ? Text(
                        l10n.lgOwed(_m(owed)),
                        style: TextStyle(
                          color: late
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      )
                    : Text(l10n.lgPaid),
                onTap: !canPost || owed <= 0
                    ? null
                    : () => showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        builder: (sheet) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.payments_outlined),
                                title: Text(l10n.lgPayBill(b.str('supplier'))),
                                onTap: () {
                                  Navigator.pop(sheet);
                                  payBill(context, ref, b);
                                },
                              ),
                              if (owed == (b.numOrNull('amount') ?? 0))
                                ListTile(
                                  leading: const Icon(Icons.block),
                                  title: Text(l10n.lgVoidBill),
                                  onTap: () async {
                                    Navigator.pop(sheet);
                                    final reason = await askText(
                                      context,
                                      title: l10n.lgVoidBill,
                                      label: l10n.reason,
                                    );
                                    if (reason == null || !context.mounted) {
                                      return;
                                    }
                                    if (await runAdminAction(
                                      context,
                                      () => ref
                                          .read(ledgerRepositoryProvider)
                                          .voidBill(b.str('id'), reason),
                                      success: l10n.adminSaved,
                                    )) {
                                      refreshLedger(ref);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
              );
            },
          );
        }),
      ),
    );
  }
}

// -------------------------------------------------------------- assets --

/// Things bought to use for years, and their value after monthly wear.
class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canManage = _perms(ref).contains('finance.manage_accounts');
    final assets = ref.watch(ledgerAssetsProvider);
    final date = DateFormat.yMMMd(l10n.localeName);
    return Scaffold(
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'record-asset',
              onPressed: () =>
                  runLedgerAction(context, ref, LedgerAction.asset),
              icon: const Icon(Icons.add),
              label: Text(l10n.lgRecordAsset),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ledgerAssetsProvider.future),
        child: _async(ref, assets, () => ref.invalidate(ledgerAssetsProvider), (
          list,
        ) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (canManage)
                Card(
                  margin: const EdgeInsets.all(Space.md),
                  child: ListTile(
                    leading: const Icon(Icons.trending_down),
                    title: Text(l10n.lgRunDepreciation),
                    subtitle: Text(l10n.lgRunDepreciationHint),
                    onTap: () async {
                      final now = DateTime.now();
                      final month = DateTime(now.year, now.month - 1);
                      var posted = 0;
                      if (await runAdminAction(context, () async {
                        posted = await ref
                            .read(ledgerRepositoryProvider)
                            .postDepreciation(month);
                      })) {
                        refreshLedger(ref);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.lgDepreciationPosted(
                                  posted,
                                  DateFormat.yMMMM(l10n.localeName)
                                      .format(month),
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              if (list.isEmpty)
                EmptyView(
                  icon: Icons.chair_outlined,
                  title: l10n.lgNoAssets,
                  message: l10n.lgAssetsHint,
                ),
              for (final a in list)
                ListTile(
                  title: Text(a.str('name')),
                  subtitle: Text(
                    [
                      l10n.lgBoughtFor(
                        _m(a.numOrNull('cost') ?? 0),
                        date.format(DateTime.parse(a.str('purchased_on'))),
                      ),
                      if (a.intOrNull('useful_life_months') != null)
                        l10n.lgOverMonths(a.intOrNull('useful_life_months')!),
                    ].join(' · '),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_m(a.numOrNull('value') ?? 0)),
                      Text(l10n.lgValueNow, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// -------------------------------------------------------------- counts --

/// Counting money against the books: cash counts, bank statements and the
/// MarzPay share, with any difference explained.
class CountsScreen extends ConsumerWidget {
  const CountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canManage = _perms(ref).contains('finance.manage_accounts');
    final counts = ref.watch(ledgerReconciliationsProvider);
    final date = DateFormat.yMMMd(l10n.localeName);
    return Scaffold(
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'count-money',
              onPressed: () =>
                  runLedgerAction(context, ref, LedgerAction.count),
              icon: const Icon(Icons.calculate_outlined),
              label: Text(l10n.lgCountMoney),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ledgerReconciliationsProvider.future),
        child: _async(
          ref,
          counts,
          () => ref.invalidate(ledgerReconciliationsProvider),
          (list) {
            if (list.isEmpty) {
              return ListView(
                children: [
                  const MarzPayCheckCard(),
                  EmptyView(
                    icon: Icons.calculate_outlined,
                    title: l10n.lgNoCounts,
                    message: l10n.lgCountIntro,
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: list.length + 1,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (i == 0) return const MarzPayCheckCard();
                final r = list[i - 1];
                final diff = r.numOrNull('difference') ?? 0;
                return ListTile(
                  leading: Icon(
                    diff == 0
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: diff == 0
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    '${r.str('account')} · ${date.format(DateTime.parse(r.str('as_of')))}',
                  ),
                  subtitle: Text(
                    [
                      l10n.lgCountLine(
                        _m(r.numOrNull('counted') ?? 0),
                        _m(r.numOrNull('books') ?? 0),
                      ),
                      ?r.strOrNull('note'),
                      if (r['posted'] == true) l10n.lgDifferencePosted,
                      ?r.strOrNull('by'),
                    ].join(' · '),
                  ),
                  trailing: Text(_m(diff)),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- reports --

enum _Period { thisMonth, lastMonth, thisYear, allTime }

(DateTime, DateTime) _range(_Period p) {
  final now = DateTime.now();
  return switch (p) {
    _Period.thisMonth => (DateTime(now.year, now.month), now),
    _Period.lastMonth => (
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month, 0),
    ),
    _Period.thisYear => (DateTime(now.year), now),
    _Period.allTime => (DateTime(2020), now),
  };
}

/// Income and expenses, what is owned and owed, money in and out, the
/// trial balance and the budget, for a chosen period.
class FinanceReportsScreen extends ConsumerStatefulWidget {
  const FinanceReportsScreen({super.key});

  @override
  ConsumerState<FinanceReportsScreen> createState() =>
      _FinanceReportsScreenState();
}

class _FinanceReportsScreenState extends ConsumerState<FinanceReportsScreen> {
  _Period _period = _Period.thisMonth;
  int _tab = 0;
  late Future<Object> _data = _load();

  Future<Object> _load() {
    final repo = ref.read(ledgerRepositoryProvider);
    final (from, to) = _range(_period);
    return switch (_tab) {
      0 => repo.report('ledger_income_statement', from: from, to: to),
      1 => repo.report('ledger_balance_sheet', to: to),
      2 => repo.report('ledger_cash_flow', from: from, to: to),
      3 => repo.accounts(asOf: to),
      _ => repo.budgetReport(from, to),
    };
  }

  void _reload() => setState(() => _data = _load());

  /// The report on screen as a PDF or an Excel workbook.
  Future<void> _download(BuildContext context, {required bool pdf}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final d = await _data;
    final (from, to) = _range(_period);
    final date = DateFormat.yMMMd(l10n.localeName);
    final period = _tab == 1
        ? l10n.exAsOf(date.format(to))
        : '${date.format(from)} – ${date.format(to)}';
    List<List<Object?>> items(
      Object? list,
      String label, {
      String key = 'amount',
    }) => [
      for (final i in (list as List? ?? const []))
        [(i as Map)[label], num.tryParse('${i[key]}')],
    ];
    final columns = [l10n.exItem, l10n.rcAmount];
    final tables = switch (_tab) {
      0 => [
        DocTable(
          title: l10n.lgIncomeStatement,
          subtitle: period,
          columns: columns,
          numeric: {1},
          rows: [
            [l10n.lgTypeIncome, (d as Json).numOrNull('total_income')],
            ...items(d['income'], 'name'),
            [l10n.lgTypeExpense, d.numOrNull('total_expenses')],
            ...items(d['expenses'], 'name'),
            [l10n.lgSurplus, d.numOrNull('surplus')],
          ],
        ),
      ],
      1 => [
        DocTable(
          title: l10n.lgBalanceSheet,
          subtitle: period,
          columns: columns,
          numeric: {1},
          rows: [
            [l10n.lgTypeAsset, (d as Json).numOrNull('total_assets')],
            ...items(d['assets'], 'name'),
            [l10n.lgTypeLiability, d.numOrNull('total_liabilities')],
            ...items(d['liabilities'], 'name'),
            [l10n.lgTypeEquity, d.numOrNull('total_equity')],
            ...items(d['equity'], 'name'),
            [l10n.lgSurplusSoFar, d.numOrNull('surplus')],
          ],
        ),
      ],
      2 => [
        DocTable(
          title: l10n.lgCashFlow,
          subtitle: period,
          columns: columns,
          numeric: {1},
          rows: [
            [l10n.lgOpeningMoney, (d as Json).numOrNull('opening')],
            [l10n.lgMoneyCameIn, d.numOrNull('total_in')],
            ...items(d['in'], 'what'),
            [l10n.lgMoneyWentOut, d.numOrNull('total_out')],
            ...items(d['out'], 'what'),
            [l10n.lgClosingMoney, d.numOrNull('closing')],
          ],
        ),
      ],
      3 => [
        DocTable(
          title: l10n.lgTrialBalance,
          subtitle: period,
          columns: [
            l10n.lgAccountCode,
            l10n.lgAccountName,
            l10n.lgDebit,
            l10n.lgCredit,
          ],
          numeric: {2, 3},
          rows: [
            for (final a in (d as List<LedgerAccount>).where(
              (a) => a.balance != 0,
            ))
              if ((a.type == 'asset' || a.type == 'expense') ==
                  (a.balance >= 0))
                [a.code, a.name, a.balance.abs(), null]
              else
                [a.code, a.name, null, a.balance.abs()],
          ],
        ),
      ],
      _ => [
        DocTable(
          title: l10n.lgBudget,
          subtitle: period,
          columns: [l10n.lgAccountName, l10n.lgBudget, l10n.exActual],
          numeric: {1, 2},
          rows: [
            for (final r in d as List<Json>)
              [r['name'], r.numOrNull('budget'), r.numOrNull('actual')],
          ],
        ),
      ],
    };
    final name =
        'sidra-${tables.first.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}'
        '-${to.toIso8601String().substring(0, 10)}';
    final ok = await saveDocument(
      pdf ? '$name.pdf' : '$name.xlsx',
      pdf
          ? await tablesToPdf(tables, header: l10n.exHeader)
          : tablesToXlsx(tables),
    );
    if (ok) messenger.showSnackBar(SnackBar(content: Text(l10n.rcSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canManage = _perms(ref).contains('finance.manage_accounts');
    final tabs = [
      l10n.lgIncomeStatement,
      l10n.lgBalanceSheet,
      l10n.lgCashFlow,
      l10n.lgTrialBalance,
      l10n.lgBudget,
    ];
    final periods = {
      _Period.thisMonth: l10n.periodThisMonth,
      _Period.lastMonth: l10n.periodLastMonth,
      _Period.thisYear: l10n.periodThisYear,
      _Period.allTime: l10n.periodAllTime,
    };

    Widget row(
      String label,
      num amount, {
      bool strong = false,
      bool indent = true,
    }) => ListTile(
      dense: !strong,
      contentPadding: EdgeInsetsDirectional.only(
        start: indent ? Space.lg : Space.md,
        end: Space.md,
      ),
      title: Text(label, style: strong ? theme.textTheme.titleSmall : null),
      trailing: Text(
        _m(amount),
        style: strong ? theme.textTheme.titleSmall : null,
      ),
    );
    List<Widget> section(String title, Object? items, num total) => [
      row(title, total, strong: true, indent: false),
      for (final i in (items as List? ?? const []))
        row((i as Map)['name'] as String, num.parse('${i['amount']}')),
    ];

    return Scaffold(
      floatingActionButton: _tab == 4 && canManage
          ? FloatingActionButton.extended(
              heroTag: 'set-budget',
              onPressed: () async {
                if (await setBudget(context, ref)) _reload();
              },
              icon: const Icon(Icons.flag_outlined),
              label: Text(l10n.lgSetBudget),
            )
          : null,
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, 0),
            child: Row(
              children: [
                for (final (i, t) in tabs.indexed)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: _tab == i,
                      onSelected: (_) => setState(() {
                        _tab = i;
                        _data = _load();
                      }),
                    ),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            child: Row(
              children: [
                for (final e in periods.entries)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
                    child: FilterChip(
                      label: Text(e.value),
                      selected: _period == e.key,
                      onSelected: (_) => setState(() {
                        _period = e.key;
                        _data = _load();
                      }),
                    ),
                  ),
                IconButton(
                  tooltip: l10n.exDownloadPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () => _download(context, pdf: true),
                ),
                IconButton(
                  tooltip: l10n.exDownloadExcel,
                  icon: const Icon(Icons.table_view_outlined),
                  onPressed: () => _download(context, pdf: false),
                ),
                if (canManage)
                  TextButton.icon(
                    icon: const Icon(Icons.lock_clock_outlined),
                    label: Text(l10n.lgCloseBooks),
                    onPressed: () => _closeBooks(context),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Object>(
              future: _data,
              builder: (context, snap) {
                if (snap.hasError) {
                  return ErrorView(error: snap.error!, onRetry: _reload);
                }
                if (!snap.hasData) return const LoadingView();
                final d = snap.data!;
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: switch (_tab) {
                      0 => [
                        ...section(
                          l10n.lgTypeIncome,
                          (d as Json)['income'],
                          d.numOrNull('total_income') ?? 0,
                        ),
                        ...section(
                          l10n.lgTypeExpense,
                          d['expenses'],
                          d.numOrNull('total_expenses') ?? 0,
                        ),
                        const Divider(),
                        row(
                          (d.numOrNull('surplus') ?? 0) >= 0
                              ? l10n.lgSurplus
                              : l10n.lgDeficit,
                          d.numOrNull('surplus') ?? 0,
                          strong: true,
                          indent: false,
                        ),
                      ],
                      1 => [
                        ...section(
                          l10n.lgTypeAsset,
                          (d as Json)['assets'],
                          d.numOrNull('total_assets') ?? 0,
                        ),
                        ...section(
                          l10n.lgTypeLiability,
                          d['liabilities'],
                          d.numOrNull('total_liabilities') ?? 0,
                        ),
                        ...section(
                          l10n.lgTypeEquity,
                          d['equity'],
                          d.numOrNull('total_equity') ?? 0,
                        ),
                        row(l10n.lgSurplusSoFar, d.numOrNull('surplus') ?? 0),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(Space.md),
                          child: Text(
                            l10n.lgBalanceSheetCheck,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                      2 => [
                        row(
                          l10n.lgOpeningMoney,
                          (d as Json).numOrNull('opening') ?? 0,
                          strong: true,
                          indent: false,
                        ),
                        row(
                          l10n.lgMoneyCameIn,
                          d.numOrNull('total_in') ?? 0,
                          strong: true,
                          indent: false,
                        ),
                        for (final i in (d['in'] as List? ?? const []))
                          row(
                            (i as Map)['what'] as String,
                            num.parse('${i['amount']}'),
                          ),
                        row(
                          l10n.lgMoneyWentOut,
                          d.numOrNull('total_out') ?? 0,
                          strong: true,
                          indent: false,
                        ),
                        for (final i in (d['out'] as List? ?? const []))
                          row(
                            (i as Map)['what'] as String,
                            num.parse('${i['amount']}'),
                          ),
                        const Divider(),
                        row(
                          l10n.lgClosingMoney,
                          d.numOrNull('closing') ?? 0,
                          strong: true,
                          indent: false,
                        ),
                      ],
                      3 => _trialBalance(l10n, theme, d as List<LedgerAccount>),
                      _ => _budget(l10n, d as List<Json>),
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _trialBalance(
    AppLocalizations l10n,
    ThemeData theme,
    List<LedgerAccount> all,
  ) {
    double dr = 0, cr = 0;
    final rows = <Widget>[];
    for (final a in all.where((a) => a.balance != 0)) {
      final debitSide = a.type == 'asset' || a.type == 'expense';
      final isDr = debitSide == (a.balance >= 0);
      final v = a.balance.abs();
      if (isDr) {
        dr += v;
      } else {
        cr += v;
      }
      rows.add(
        ListTile(
          dense: true,
          title: Text(a.label),
          trailing: Text(isDr ? l10n.lgDr(_m(v)) : l10n.lgCr(_m(v))),
        ),
      );
    }
    return [
      if (rows.isEmpty)
        EmptyView(icon: Icons.balance, title: l10n.lgNoMovements),
      ...rows,
      const Divider(),
      ListTile(
        title: Text(
          l10n.lgTotals(_m(dr), _m(cr)),
          style: theme.textTheme.titleSmall,
        ),
        trailing: Icon(
          (dr - cr).abs() < 0.005 ? Icons.check_circle : Icons.error,
          color: (dr - cr).abs() < 0.005
              ? Colors.green
              : theme.colorScheme.error,
        ),
      ),
    ];
  }

  List<Widget> _budget(AppLocalizations l10n, List<Json> rows) => [
    if (rows.isEmpty)
      EmptyView(
        icon: Icons.flag_outlined,
        title: l10n.lgNoBudget,
        message: l10n.lgBudgetIntro,
      ),
    for (final r in rows)
      ListTile(
        title: Text(r.str('name')),
        subtitle: LinearProgressIndicator(
          value: (r.numOrNull('budget') ?? 0) == 0
              ? null
              : ((r.numOrNull('actual') ?? 0) / r.numOrNull('budget')!)
                    .clamp(0, 1)
                    .toDouble(),
        ),
        trailing: Text(
          l10n.lgBudgetLine(
            _m(r.numOrNull('actual') ?? 0),
            _m(r.numOrNull('budget') ?? 0),
          ),
        ),
      ),
  ];

  Future<void> _closeBooks(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final lastMonthEnd = DateTime(now.year, now.month, 0);
    final d = await showDatePicker(
      context: context,
      helpText: l10n.lgCloseBooksHelp,
      initialDate: lastMonthEnd,
      firstDate: DateTime(2020),
      lastDate: now.subtract(const Duration(days: 1)),
    );
    if (d == null || !context.mounted) return;
    final ok = await confirm(
      context,
      title: l10n.lgCloseBooks,
      message: l10n.lgCloseBooksConfirm(
        DateFormat.yMMMd(l10n.localeName).format(d),
      ),
    );
    if (!ok || !context.mounted) return;
    if (await runAdminAction(
      context,
      () => ref.read(ledgerRepositoryProvider).closeBooks(d),
      success: l10n.adminSaved,
    )) {
      refreshLedger(ref);
    }
  }
}

// ------------------------------------------------------------- refunds --

/// Refunds agreed for learners: owed until paid out from a money account
/// (with the transaction ID), then shown as paid.
class RefundsView extends ConsumerWidget {
  const RefundsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canPay = _perms(ref).contains('finance.verify_payment');
    final rows = ref.watch(ledgerRefundsProvider);
    final date = DateFormat.yMMMd(l10n.localeName);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(ledgerRefundsProvider.future),
      child: _async(ref, rows, () => ref.invalidate(ledgerRefundsProvider), (
        list,
      ) {
        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Text(l10n.rfIntro, style: theme.textTheme.bodySmall),
            ),
            if (list.isEmpty) EmptyView(icon: Icons.undo, title: l10n.rfNone),
            for (final r in list)
              ListTile(
                leading: Icon(
                  r['status'] == 'owed'
                      ? Icons.schedule
                      : Icons.check_circle_outline,
                  color: r['status'] == 'owed'
                      ? theme.colorScheme.error
                      : Colors.green,
                ),
                title: Text(
                  '${r.strOrNull('learner') ?? ''} · ${_m(r.numOrNull('amount') ?? 0)}',
                ),
                subtitle: Text(
                  [
                    ?r.strOrNull('course'),
                    ?r.strOrNull('reason'),
                    if (r['status'] == 'owed')
                      l10n.rfOwedSince(
                        date.format(DateTime.parse(r.str('agreed_on'))),
                      )
                    else
                      l10n.rfPaidOut(
                        date.format(DateTime.parse(r.str('paid_out_on'))),
                        r.strOrNull('paid_from') ?? '',
                        r.strOrNull('payout_reference') ?? '',
                      ),
                  ].join(' · '),
                ),
                trailing: canPay && r['status'] == 'owed'
                    ? FilledButton(
                        onPressed: () => _payOut(context, ref, r),
                        child: Text(l10n.rfPayOut),
                      )
                    : null,
              ),
          ],
        );
      }),
    );
  }

  Future<void> _payOut(BuildContext context, WidgetRef ref, Json r) async {
    final l10n = AppLocalizations.of(context);
    final saved = await showLedgerSheet(
      context,
      LedgerForm(
        title: l10n.rfPayOutTitle(r.strOrNull('learner') ?? ''),
        intro: l10n.rfPayOutIntro(
          _m(r.numOrNull('amount') ?? 0),
          r.strOrNull('phone') ?? '',
        ),
        fields: [
          AccountField('from', l10n.lgPaidFrom, isMoneyAccount),
          TextLedgerField('method', l10n.rfMethod, hint: l10n.rfMethodHint),
          TextLedgerField('reference', l10n.rfReference, required: true),
          DateField('date', l10n.lgDate),
        ],
        onSave: (v) => ref
            .read(ledgerRepositoryProvider)
            .payOutRefund(
              refundId: r.str('id'),
              fromAccount: (v['from']! as LedgerAccount).id,
              method: (v['method'] as String?) ?? '',
              reference: v['reference']! as String,
              paidOn: (v['date'] as DateTime?) ?? DateTime.now(),
            ),
      ),
    );
    if (saved) refreshLedger(ref);
  }
}

// -------------------------------------------------------- MarzPay check --

/// How Sidra's MarzPay payments compare with MarzPay's own records (the
/// payments Worker checks a few every minute).
class MarzPayCheckCard extends ConsumerWidget {
  const MarzPayCheckCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final check = ref.watch(marzpayCheckProvider);
    final when = DateFormat.yMMMd(l10n.localeName).add_jm();
    return Card(
      margin: const EdgeInsets.all(Space.md),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: switch (check) {
          AsyncData(value: final c) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.mkTitle, style: theme.textTheme.titleMedium),
              Text(l10n.mkIntro, style: theme.textTheme.bodySmall),
              const SizedBox(height: Space.xs),
              Text(
                l10n.mkCounts(
                  c.intOrNull('matched') ?? 0,
                  c.intOrNull('mismatched') ?? 0,
                  c.intOrNull('waiting') ?? 0,
                  c.intOrNull('not_checked') ?? 0,
                ),
              ),
              if (c.strOrNull('last_checked') != null)
                Text(
                  l10n.mkLast(
                    when.format(
                      DateTime.parse(c.str('last_checked')).toLocal(),
                    ),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              for (final p in (c['problems'] as List? ?? const []))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    (p as Map)['result'] == 'mismatch'
                        ? Icons.error_outline
                        : Icons.schedule,
                    color: p['result'] == 'mismatch'
                        ? theme.colorScheme.error
                        : null,
                  ),
                  title: Text(
                    '${p['learner'] ?? ''} · ${_m(num.parse('${p['amount']}'))} · ${p['course'] ?? ''}',
                  ),
                  subtitle: Text('${p['detail'] ?? ''}'),
                ),
            ],
          ),
          AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(marzpayCheckProvider),
          ),
          _ => const LinearProgressIndicator(),
        },
      ),
    );
  }
}

// ---------------------------------------------------- accounting rules --

/// The rules the books follow, for the organisation's accountant to read and
/// confirm (who confirmed, and when, is recorded).
class AccountingRulesScreen extends ConsumerWidget {
  const AccountingRulesScreen({super.key});

  static List<(String, String)> rules(AppLocalizations l10n) => [
    (l10n.arCashTitle, l10n.arCash),
    (l10n.arOpeningTitle, l10n.arOpening),
    (l10n.arMarzPayTitle, l10n.arMarzPay),
    (l10n.arFeesTitle, l10n.arFees),
    (l10n.arTestTitle, l10n.arTest),
    (l10n.arRefundsTitle, l10n.arRefunds),
    (l10n.arClosingTitle, l10n.arClosing),
    (l10n.arAccountsTitle, l10n.arAccounts),
    (l10n.arCurrencyTitle, l10n.arCurrency),
    (l10n.arPermanentTitle, l10n.arPermanent),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canConfirm = _perms(ref).contains('finance.manage_accounts');
    final overview = ref.watch(ledgerOverviewProvider).value;
    final confirmed = overview?['rules_confirmed'] as Map?;
    final date = DateFormat.yMMMd(l10n.localeName);
    final list = rules(l10n);
    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        Text(l10n.arIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: Space.sm),
        Card(
          color: confirmed == null
              ? theme.colorScheme.tertiaryContainer
              : theme.colorScheme.primaryContainer,
          child: ListTile(
            leading: Icon(
              confirmed == null
                  ? Icons.pending_outlined
                  : Icons.verified_outlined,
            ),
            title: Text(
              confirmed == null
                  ? l10n.arNotConfirmed
                  : l10n.arConfirmed(
                      '${confirmed['by']}',
                      date.format(DateTime.parse('${confirmed['on']}')),
                    ),
            ),
            subtitle: confirmed?['note'] == null
                ? null
                : Text('${confirmed!['note']}'),
          ),
        ),
        for (final (i, (title, body)) in list.indexed)
          ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(title),
            subtitle: Text(body),
          ),
        const SizedBox(height: Space.md),
        OutlinedButton.icon(
          onPressed: () async {
            final bytes = await tablesToPdf([
              DocTable(
                title: l10n.arTitle,
                subtitle: l10n.arIntro,
                columns: ['#', l10n.arRule, l10n.arWhat],
                rows: [
                  for (final (i, (t, b)) in list.indexed) [i + 1, t, b],
                ],
              ),
            ], header: l10n.arPdfHeader);
            final ok = await saveDocument('sidra-accounting-rules.pdf', bytes);
            if (ok && context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l10n.rcSaved)));
            }
          },
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(l10n.arSendPdf),
        ),
        if (canConfirm) ...[
          const SizedBox(height: Space.xs),
          FilledButton.icon(
            onPressed: () async {
              final saved = await showLedgerSheet(
                context,
                LedgerForm(
                  title: l10n.arConfirmTitle,
                  intro: l10n.arConfirmIntro,
                  fields: [
                    TextLedgerField('by', l10n.arConfirmedBy, required: true),
                    TextLedgerField('note', l10n.arNote),
                  ],
                  onSave: (v) => ref
                      .read(ledgerRepositoryProvider)
                      .confirmRules(v['by']! as String, v['note'] as String?),
                ),
              );
              if (saved) refreshLedger(ref);
            },
            icon: const Icon(Icons.how_to_reg_outlined),
            label: Text(l10n.arConfirmTitle),
          ),
        ],
      ],
    );
  }
}
