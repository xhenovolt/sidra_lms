import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../../admin/presentation/admin_shell.dart' show myPermissionsProvider;
import '../../payments/data/payments_repository.dart' show formatMoney;
import '../data/ledger_repository.dart';
import 'ledger_forms.dart';
import 'ledger_screens.dart';

/// Finance home: what Almuntahha has right now, this month's money in and
/// out, what is owed both ways, what needs attention, and every finance
/// page. All figures come from the double-entry books.
class FinanceHomeScreen extends ConsumerWidget {
  const FinanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final overview = ref.watch(ledgerOverviewProvider);
    final perms = ref.watch(myPermissionsProvider).value ?? const {};
    final canPost = perms.contains('finance.post_journal');
    final canManage = perms.contains('finance.manage_accounts');
    final canExpense = perms.contains('finance.record_expense');

    Widget action(IconData icon, String label, LedgerAction a) => SizedBox(
      width: 150,
      child: OutlinedButton.icon(
        onPressed: () => runLedgerAction(context, ref, a),
        icon: Icon(icon),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );

    return RefreshIndicator(
      onRefresh: () => ref.refresh(ledgerOverviewProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          switch (overview) {
            AsyncData(value: final o) => _Summary(o),
            AsyncError(:final error) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(ledgerOverviewProvider),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(Space.xl),
              child: LoadingView(),
            ),
          },
          if (canPost || canManage || canExpense) ...[
            const SizedBox(height: Space.md),
            Text(l10n.lgDoSomething, style: theme.textTheme.titleMedium),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                if (canExpense)
                  action(
                    Icons.receipt_long_outlined,
                    l10n.financeRecordExpense,
                    LedgerAction.expense,
                  ),
                if (canPost) ...[
                  action(
                    Icons.south_west,
                    l10n.lgMoneyIn,
                    LedgerAction.moneyIn,
                  ),
                  action(
                    Icons.north_east,
                    l10n.lgMoneyOut,
                    LedgerAction.moneyOut,
                  ),
                  action(
                    Icons.swap_horiz,
                    l10n.lgTransfer,
                    LedgerAction.transfer,
                  ),
                  action(
                    Icons.request_page_outlined,
                    l10n.lgRecordBill,
                    LedgerAction.bill,
                  ),
                ],
                if (canManage)
                  action(
                    Icons.calculate_outlined,
                    l10n.lgCountMoney,
                    LedgerAction.count,
                  ),
              ],
            ),
          ],
          const SizedBox(height: Space.md),
          Text(l10n.lgPages, style: theme.textTheme.titleMedium),
          for (final (icon, title, subtitle, route) in [
            (
              Icons.payments_outlined,
              l10n.lgPaymentsPage,
              l10n.lgPaymentsPageHint,
              Routes.adminFinancePayments,
            ),
            (
              Icons.account_tree_outlined,
              l10n.lgAccounts,
              l10n.lgAccountsHint,
              Routes.adminAccounts,
            ),
            (
              Icons.menu_book_outlined,
              l10n.lgJournal,
              l10n.lgJournalHint,
              Routes.adminJournal,
            ),
            (
              Icons.request_page_outlined,
              l10n.lgBills,
              l10n.lgBillsHint,
              Routes.adminBills,
            ),
            (
              Icons.chair_outlined,
              l10n.lgAssets,
              l10n.lgAssetsHint,
              Routes.adminAssets,
            ),
            (
              Icons.insights_outlined,
              l10n.lgReports,
              l10n.lgReportsHint,
              Routes.adminFinanceReports,
            ),
            (
              Icons.calculate_outlined,
              l10n.lgCounts,
              l10n.lgCountsHint,
              Routes.adminCounts,
            ),
            (
              Icons.rule_outlined,
              l10n.arTitle,
              l10n.arHint,
              Routes.adminAccountingRules,
            ),
          ])
            Card(
              margin: const EdgeInsets.only(top: Space.xs),
              child: ListTile(
                leading: Icon(icon, color: theme.colorScheme.primary),
                title: Text(title),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(route),
              ),
            ),
        ],
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary(this.o);
  final Json o;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currency = o.strOrNull('currency') ?? 'UGX';
    String money(String key) => formatMoney(o.numOrNull(key) ?? 0, currency);
    final accounts = [
      for (final m in (o['money'] as List? ?? const []))
        Map<String, dynamic>.from(m as Map),
    ];
    final closed = o.strOrNull('closed_through');
    final notInBooks = o.intOrNull('not_in_books') ?? 0;
    final needsReview = o.numOrNull('needs_review') ?? 0;
    final testMoney = o.numOrNull('test_money') ?? 0;

    Widget alert(IconData icon, String text, {VoidCallback? onTap}) => Card(
      color: theme.colorScheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(icon),
        title: Text(text),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.lgWhatWeHave, style: theme.textTheme.titleSmall),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    money('money_total'),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: Space.xs),
                for (final a in accounts)
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => StatementScreen(
                          accountId: a.str('account_id'),
                          title: a.str('name'),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(a.str('name'))),
                          Text(
                            formatMoney(a.numOrNull('balance') ?? 0, currency),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: Space.xs),
                Text(l10n.lgMarzPayShareNote, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        if (o['opening_entered'] != true)
          alert(
            Icons.flag_outlined,
            l10n.lgEnterOpening,
            onTap: () => context.push(Routes.adminAccounts),
          ),
        if ((o.numOrNull('refunds_owed') ?? 0) > 0)
          alert(
            Icons.undo,
            l10n.rfOwedAlert(money('refunds_owed')),
            onTap: () => context.push(Routes.adminFinancePayments),
          ),
        if (o['rules_confirmed'] == null)
          alert(
            Icons.rule_outlined,
            l10n.arNotConfirmed,
            onTap: () => context.push(Routes.adminAccountingRules),
          ),
        if (notInBooks > 0)
          alert(Icons.report_outlined, l10n.lgNotInBooks(notInBooks)),
        if (needsReview != 0)
          alert(
            Icons.help_outline,
            l10n.lgNeedsReview(formatMoney(needsReview, currency)),
            onTap: () => context.push(Routes.adminJournal),
          ),
        if (testMoney != 0)
          alert(
            Icons.science_outlined,
            l10n.lgTestMoneyHeld(formatMoney(testMoney, currency)),
          ),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            _Tile(l10n.lgMonthIn, money('month_income'), Icons.south_west),
            _Tile(l10n.lgMonthOut, money('month_expenses'), Icons.north_east),
            _Tile(
              l10n.lgOwedToUs,
              money('owed_to_us'),
              Icons.pending_actions_outlined,
              onTap: () => context.push(Routes.adminFinancePayments),
            ),
            _Tile(
              l10n.lgBillsToPay,
              money('bills_due'),
              Icons.request_page_outlined,
              onTap: () => context.push(Routes.adminBills),
            ),
          ],
        ),
        if (closed != null) ...[
          const SizedBox(height: Space.xs),
          Text(
            l10n.lgClosedThrough(
              DateFormat.yMMMd(l10n.localeName).format(DateTime.parse(closed)),
            ),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, this.icon, {this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 168,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(height: Space.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
