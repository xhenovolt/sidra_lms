import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../payments/data/payments_repository.dart' show formatMoney;
import '../../profile/data/profile_repository.dart';
import '../data/admin_repository.dart';
import '../data/finance_repository.dart';
import 'admin_common.dart';
import 'admin_shell.dart';
import 'courses_tab.dart';

/// A reporting period.
enum FinancePeriod { thisMonth, lastMonth, thisYear, allTime }

(DateTime?, DateTime?) periodRange(FinancePeriod p, DateTime now) =>
    switch (p) {
      FinancePeriod.thisMonth => (DateTime(now.year, now.month), now),
      FinancePeriod.lastMonth => (
        DateTime(now.year, now.month - 1),
        DateTime(now.year, now.month, 0),
      ),
      FinancePeriod.thisYear => (DateTime(now.year), now),
      FinancePeriod.allTime => (null, null),
    };

final financePeriodProvider = StateProvider<FinancePeriod>(
  (_) => FinancePeriod.thisMonth,
);

final financeSummaryProvider = FutureProvider.autoDispose<FinanceSummary>((
  ref,
) {
  final (from, to) = periodRange(
    ref.watch(financePeriodProvider),
    DateTime.now(),
  );
  return ref.watch(financeRepositoryProvider).summary(from: from, to: to);
});

final paymentFilterProvider = StateProvider<String?>((_) => 'pending');
final paymentSearchProvider = StateProvider<String>((_) => '');

final financePaymentsProvider =
    FutureProvider.autoDispose<List<FinancePayment>>((ref) {
      final filter = ref.watch(paymentFilterProvider);
      return ref
          .watch(financeRepositoryProvider)
          .payments(
            status: filter,
            search: ref.watch(paymentSearchProvider),
            limit: 100,
          );
    });

final financeBalancesProvider = FutureProvider.autoDispose<List<Json>>(
  (ref) => ref.watch(financeRepositoryProvider).balances(),
);
final financeWaiversProvider = FutureProvider.autoDispose<List<Json>>(
  (ref) => ref.watch(financeRepositoryProvider).waivers(),
);
final financeExpensesProvider = FutureProvider.autoDispose<List<Json>>((ref) {
  final (from, to) = periodRange(
    ref.watch(financePeriodProvider),
    DateTime.now(),
  );
  return ref.watch(financeRepositoryProvider).expenses(from: from, to: to);
});

void _refreshFinance(WidgetRef ref) {
  ref.invalidate(financeSummaryProvider);
  ref.invalidate(financePaymentsProvider);
  ref.invalidate(financeBalancesProvider);
  ref.invalidate(financeWaiversProvider);
  ref.invalidate(financeExpensesProvider);
}

/// Money in and out: totals with the retained formula, payments to verify,
/// who owes, waivers and expenses. Every action is checked in PostgreSQL.
class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.financeOverview),
              Tab(text: l10n.financePayments),
              Tab(text: l10n.financeOwing),
              Tab(text: l10n.financeWaivers),
              Tab(text: l10n.financeExpenses),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _Overview(),
                _Payments(),
                _Owing(),
                _Waivers(),
                _Expenses(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _periodLabel(AppLocalizations l10n, FinancePeriod p) => switch (p) {
  FinancePeriod.thisMonth => l10n.periodThisMonth,
  FinancePeriod.lastMonth => l10n.periodLastMonth,
  FinancePeriod.thisYear => l10n.periodThisYear,
  FinancePeriod.allTime => l10n.periodAllTime,
};

class _PeriodChips extends ConsumerWidget {
  const _PeriodChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final period = ref.watch(financePeriodProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in FinancePeriod.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Space.xs),
              child: ChoiceChip(
                label: Text(_periodLabel(l10n, p)),
                selected: p == period,
                onSelected: (_) =>
                    ref.read(financePeriodProvider.notifier).state = p,
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- overview --

class _Overview extends ConsumerWidget {
  const _Overview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = ref.watch(financeSummaryProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(financeSummaryProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          const _PeriodChips(),
          const SizedBox(height: Space.sm),
          switch (summary) {
            AsyncData(value: final s) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (s.pendingCount > 0)
                  Card(
                    color: theme.colorScheme.tertiaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.hourglass_top),
                      title: Text(l10n.financePendingBanner(s.pendingCount)),
                      subtitle: Text(formatMoney(s.pendingAmount, s.currency)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ref.read(paymentFilterProvider.notifier).state =
                            'pending';
                        DefaultTabController.of(context).animateTo(1);
                      },
                    ),
                  ),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    _Money(
                      l10n.financeCollected,
                      s.collected,
                      s.currency,
                      Icons.savings_outlined,
                      strong: true,
                    ),
                    _Money(
                      l10n.financeOutstanding,
                      s.outstanding,
                      s.currency,
                      Icons.pending_actions_outlined,
                    ),
                    _Money(
                      l10n.financeExpected,
                      s.expected,
                      s.currency,
                      Icons.request_quote_outlined,
                    ),
                    _Money(
                      l10n.financeWaived,
                      s.waived,
                      s.currency,
                      Icons.volunteer_activism_outlined,
                    ),
                    _Money(
                      l10n.financeRefunded,
                      s.refunded,
                      s.currency,
                      Icons.undo,
                    ),
                    _Money(
                      l10n.financeProviderFees,
                      s.providerFees,
                      s.currency,
                      Icons.percent,
                    ),
                    _Money(
                      l10n.financeExpenses,
                      s.expenses,
                      s.currency,
                      Icons.receipt_long_outlined,
                    ),
                    _Money(
                      l10n.financeRetained,
                      s.retained,
                      s.currency,
                      Icons.account_balance_outlined,
                      strong: true,
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Space.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.financeHowRetained,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: Space.xs),
                        Text(l10n.financeFormula),
                        const SizedBox(height: Space.xs),
                        Text(
                          '${formatMoney(s.collected, s.currency)} − '
                          '${formatMoney(s.refunded, s.currency)} − '
                          '${formatMoney(s.providerFees, s.currency)} − '
                          '${formatMoney(s.expenses, s.currency)} = '
                          '${formatMoney(s.retained, s.currency)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: Space.xs),
                        Text(
                          l10n.financeWaiverNote,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                if (s.byMethod.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  Text(l10n.financeByMethod, style: theme.textTheme.titleSmall),
                  for (final e in s.byMethod.entries)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(methodLabel(l10n, e.key)),
                      trailing: Text(formatMoney(e.value, s.currency)),
                    ),
                ],
                if (s.byCourse.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  Text(l10n.financeByCourse, style: theme.textTheme.titleSmall),
                  for (final c in s.byCourse)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.str('title')),
                      subtitle: Text(
                        l10n.financeCourseLine(
                          c.integer('learners', fallback: 0),
                          formatMoney(
                            c.numOrNull('collected') ?? 0,
                            s.currency,
                          ),
                          formatMoney(
                            c.numOrNull('outstanding') ?? 0,
                            s.currency,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
            AsyncError(:final error) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(financeSummaryProvider),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(Space.xl),
              child: LoadingView(),
            ),
          },
        ],
      ),
    );
  }
}

class _Money extends StatelessWidget {
  const _Money(
    this.label,
    this.value,
    this.currency,
    this.icon, {
    this.strong = false,
  });
  final String label;
  final double value;
  final String currency;
  final IconData icon;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 168,
      child: Card(
        color: strong ? theme.colorScheme.primaryContainer : null,
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
                  formatMoney(value, currency),
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
    );
  }
}

String methodLabel(AppLocalizations l10n, String m) => switch (m) {
  'marzpay' => l10n.methodMarzPay,
  'mobile_money' => l10n.payMethodMobileMoney,
  'bank' => l10n.payMethodBank,
  'cash' => l10n.methodCash,
  _ => l10n.methodOther,
};

String paymentStatusLabel(AppLocalizations l10n, String s) => switch (s) {
  'initiated' || 'processing' => l10n.paymentInProgress,
  'pending' => l10n.paymentPending,
  'verified' => l10n.paymentVerified,
  'failed' => l10n.paymentFailed,
  'rejected' => l10n.paymentRejected,
  'reversed' => l10n.paymentReversed,
  _ => s,
};

// ------------------------------------------------------------- payments --

class _Payments extends ConsumerWidget {
  const _Payments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final perms = ref.watch(myPermissionsProvider).value ?? const {};
    final filter = ref.watch(paymentFilterProvider);
    final payments = ref.watch(financePaymentsProvider);
    return Scaffold(
      floatingActionButton: perms.contains('finance.record_payment')
          ? FloatingActionButton.extended(
              heroTag: 'record-payment',
              onPressed: () async {
                if (await showRecordPaymentSheet(context, ref)) {
                  _refreshFinance(ref);
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.financeRecordPayment),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.financeSearchPayments,
                isDense: true,
              ),
              onSubmitted: (v) =>
                  ref.read(paymentSearchProvider.notifier).state = v,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.xs,
            ),
            child: Row(
              children: [
                for (final (value, label) in [
                  ('pending', l10n.paymentPending),
                  ('processing', l10n.paymentInProgress),
                  ('verified', l10n.paymentVerified),
                  ('failed', l10n.paymentFailed),
                  ('rejected', l10n.paymentRejected),
                  ('reversed', l10n.paymentReversed),
                  (null, l10n.adminEveryone),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: filter == value,
                      onSelected: (_) =>
                          ref.read(paymentFilterProvider.notifier).state =
                              value,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(financePaymentsProvider.future),
              child: switch (payments) {
                AsyncData(:final value) when value.isEmpty => ListView(
                  children: [
                    EmptyView(
                      icon: Icons.receipt_long_outlined,
                      title: l10n.financeNoPayments,
                    ),
                  ],
                ),
                AsyncData(:final value) => ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _PaymentTile(p: value[i]),
                ),
                AsyncError(:final error) => ListView(
                  children: [
                    ErrorView(
                      error: error,
                      onRetry: () => ref.invalidate(financePaymentsProvider),
                    ),
                  ],
                ),
                _ => const LoadingView(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends ConsumerWidget {
  const _PaymentTile({required this.p});
  final FinancePayment p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd(l10n.localeName);
    final color = switch (p.status) {
      'verified' => theme.colorScheme.primary,
      'pending' => theme.colorScheme.tertiary,
      'failed' || 'rejected' || 'reversed' => theme.colorScheme.error,
      _ => theme.colorScheme.onSurfaceVariant,
    };
    return ListTile(
      title: Text('${p.learner} · ${formatMoney(p.amount, p.currency)}'),
      subtitle: Text(
        [
          ?p.course,
          methodLabel(l10n, p.method),
          ?p.reference,
          if (p.createdAt != null) date.format(p.createdAt!.toLocal()),
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        paymentStatusLabel(l10n, p.status),
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      ),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _PaymentSheet(p: p),
      ),
    );
  }
}

class _PaymentSheet extends ConsumerWidget {
  const _PaymentSheet({required this.p});
  final FinancePayment p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final perms = ref.watch(myPermissionsProvider).value ?? const {};
    final canVerify = perms.contains('finance.verify_payment');
    final repo = ref.read(financeRepositoryProvider);
    final when = DateFormat.yMMMd(l10n.localeName).add_jm();

    Future<void> act(Future<void> Function() f) async {
      if (await runAdminAction(context, f, success: l10n.adminSaved)) {
        _refreshFinance(ref);
        if (context.mounted) Navigator.pop(context);
      }
    }

    Future<void> withReason(
      String title,
      Future<void> Function(String reason) f,
    ) async {
      final reason = await askText(context, title: title, label: l10n.reason);
      if (reason != null && context.mounted) await act(() => f(reason));
    }

    Widget line(String k, String? v) => v == null || v.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: Space.xxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(k, style: theme.textTheme.bodySmall),
                ),
                Expanded(child: SelectableText(v)),
              ],
            ),
          );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              formatMoney(p.amount, p.currency),
              style: theme.textTheme.headlineSmall,
            ),
            Text(
              paymentStatusLabel(l10n, p.status),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: Space.sm),
            line(l10n.financeLearner, p.learner),
            line(l10n.financeCourse, p.course),
            line(l10n.financeMethod, methodLabel(l10n, p.method)),
            line(l10n.payReferenceLabel, p.reference),
            line(l10n.payPhoneLabel, p.phone),
            line(l10n.payNoteLabel, p.note),
            line(l10n.reason, p.reason),
            line(l10n.financeRecordedBy, p.recordedBy),
            line(l10n.financeVerifiedBy, p.verifiedBy),
            line(
              l10n.financeCreated,
              p.createdAt == null ? null : when.format(p.createdAt!.toLocal()),
            ),
            if (p.refunded > 0)
              line(l10n.financeRefunded, formatMoney(p.refunded, p.currency)),
            const Divider(height: Space.xl),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/teach/people/${p.userId}');
              },
              icon: const Icon(Icons.person_outline),
              label: Text(l10n.financeOpenLearner),
            ),
            if (canVerify && p.status == 'pending') ...[
              FilledButton.icon(
                onPressed: () => act(() => repo.verify(p.id)),
                icon: const Icon(Icons.verified_outlined),
                label: Text(l10n.financeVerify),
              ),
              const SizedBox(height: Space.xs),
              OutlinedButton.icon(
                onPressed: () =>
                    withReason(l10n.financeReject, (r) => repo.reject(p.id, r)),
                icon: const Icon(Icons.block),
                label: Text(l10n.financeReject),
              ),
            ],
            if (canVerify && p.status == 'verified') ...[
              OutlinedButton.icon(
                onPressed: () async {
                  final amount = await askText(
                    context,
                    title: l10n.financeRefund,
                    label: l10n.payAmountLabel(p.currency),
                    number: true,
                  );
                  if (amount == null || !context.mounted) return;
                  await withReason(
                    l10n.financeRefund,
                    (r) => repo.refund(p.id, double.parse(amount), r),
                  );
                },
                icon: const Icon(Icons.undo),
                label: Text(l10n.financeRefund),
              ),
              const SizedBox(height: Space.xs),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: () => withReason(
                  l10n.financeReverse,
                  (r) => repo.reverse(p.id, r),
                ),
                icon: const Icon(Icons.cancel_outlined),
                label: Text(l10n.financeReverse),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- owing --

class _Owing extends ConsumerWidget {
  const _Owing();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final perms = ref.watch(myPermissionsProvider).value ?? const {};
    final rows = ref.watch(financeBalancesProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(financeBalancesProvider.future),
      child: switch (rows) {
        AsyncData(:final value) when value.isEmpty => ListView(
          children: [
            EmptyView(icon: Icons.task_alt, title: l10n.financeNobodyOwes),
          ],
        ),
        AsyncData(:final value) => ListView.separated(
          itemCount: value.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = value[i];
            final currency = r.strOrNull('currency') ?? 'UGX';
            return ListTile(
              title: Text(
                '${r.strOrNull('learner') ?? '—'} · '
                '${formatMoney(r.numOrNull('outstanding') ?? 0, currency)}',
              ),
              subtitle: Text(
                l10n.financeOwingLine(
                  r.strOrNull('course') ?? '',
                  formatMoney(r.numOrNull('fee') ?? 0, currency),
                  formatMoney(
                    (r.numOrNull('paid') ?? 0) - (r.numOrNull('refunded') ?? 0),
                    currency,
                  ),
                  formatMoney(r.numOrNull('waived') ?? 0, currency),
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  final learner = (
                    r.str('user_id'),
                    r.strOrNull('learner') ?? '',
                  );
                  if (v == 'open') {
                    await context.push('/teach/people/${learner.$1}');
                    return;
                  }
                  final ok = v == 'pay'
                      ? await showRecordPaymentSheet(
                          context,
                          ref,
                          learner: learner,
                          courseId: r.str('course_id'),
                          amount: r.numOrNull('outstanding'),
                        )
                      : await showWaiverSheet(
                          context,
                          ref,
                          learner: learner,
                          courseId: r.str('course_id'),
                        );
                  if (ok) _refreshFinance(ref);
                },
                itemBuilder: (_) => [
                  if (perms.contains('finance.record_payment'))
                    PopupMenuItem(
                      value: 'pay',
                      child: Text(l10n.financeRecordPayment),
                    ),
                  if (perms.contains('finance.manage_waiver'))
                    PopupMenuItem(
                      value: 'waive',
                      child: Text(l10n.financeGrantWaiver),
                    ),
                  PopupMenuItem(
                    value: 'open',
                    child: Text(l10n.financeOpenLearner),
                  ),
                ],
              ),
            );
          },
        ),
        AsyncError(:final error) => ListView(
          children: [
            ErrorView(
              error: error,
              onRetry: () => ref.invalidate(financeBalancesProvider),
            ),
          ],
        ),
        _ => const LoadingView(),
      },
    );
  }
}

// -------------------------------------------------------------- waivers --

class _Waivers extends ConsumerWidget {
  const _Waivers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final perms = ref.watch(myPermissionsProvider).value ?? const {};
    final canManage = perms.contains('finance.manage_waiver');
    final rows = ref.watch(financeWaiversProvider);
    return Scaffold(
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'grant-waiver',
              onPressed: () async {
                if (await showWaiverSheet(context, ref)) _refreshFinance(ref);
              },
              icon: const Icon(Icons.volunteer_activism_outlined),
              label: Text(l10n.financeGrantWaiver),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(financeWaiversProvider.future),
        child: switch (rows) {
          AsyncData(:final value) when value.isEmpty => ListView(
            children: [
              EmptyView(
                icon: Icons.volunteer_activism_outlined,
                title: l10n.financeNoWaivers,
              ),
            ],
          ),
          AsyncData(:final value) => ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final w = value[i];
              final amount = w.numOrNull('amount');
              return ListTile(
                title: Text(
                  '${w.strOrNull('learner') ?? '—'} · '
                  '${amount == null ? l10n.financeFullFee : formatMoney(amount, 'UGX')}',
                ),
                subtitle: Text(
                  [
                    w.strOrNull('course') ?? '',
                    w.strOrNull('reason') ?? '',
                    ?w.strOrNull('granted_by'),
                  ].join(' · '),
                ),
                trailing: canManage
                    ? IconButton(
                        tooltip: l10n.financeRevoke,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () async {
                          final reason = await askText(
                            context,
                            title: l10n.financeRevoke,
                            label: l10n.reason,
                          );
                          if (reason == null || !context.mounted) return;
                          if (await runAdminAction(
                            context,
                            () => ref
                                .read(financeRepositoryProvider)
                                .revokeWaiver(w.str('id'), reason),
                            success: l10n.adminSaved,
                          )) {
                            _refreshFinance(ref);
                          }
                        },
                      )
                    : null,
              );
            },
          ),
          AsyncError(:final error) => ListView(
            children: [
              ErrorView(
                error: error,
                onRetry: () => ref.invalidate(financeWaiversProvider),
              ),
            ],
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}

// ------------------------------------------------------------- expenses --

class _Expenses extends ConsumerWidget {
  const _Expenses();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final perms = ref.watch(myPermissionsProvider).value ?? const {};
    final canRecord = perms.contains('finance.record_expense');
    final rows = ref.watch(financeExpensesProvider);
    final date = DateFormat.yMMMd(l10n.localeName);
    return Scaffold(
      floatingActionButton: canRecord
          ? FloatingActionButton.extended(
              heroTag: 'record-expense',
              onPressed: () async {
                if (await showExpenseSheet(context, ref)) _refreshFinance(ref);
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.financeRecordExpense),
            )
          : null,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
            child: _PeriodChips(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(financeExpensesProvider.future),
              child: switch (rows) {
                AsyncData(:final value) when value.isEmpty => ListView(
                  children: [
                    EmptyView(
                      icon: Icons.receipt_long_outlined,
                      title: l10n.financeNoExpenses,
                    ),
                  ],
                ),
                AsyncData(:final value) => ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final x = value[i];
                    final spent = x.dateOrNull('spent_on');
                    return ListTile(
                      title: Text(
                        '${x.str('category')} · '
                        '${formatMoney(x.numOrNull('amount') ?? 0, x.strOrNull('currency') ?? 'UGX')}',
                      ),
                      subtitle: Text(
                        [
                          ?x.strOrNull('description'),
                          ?x.strOrNull('payee'),
                          if (spent != null) date.format(spent),
                          ?x.strOrNull('recorded_by'),
                        ].join(' · '),
                      ),
                      trailing: canRecord
                          ? IconButton(
                              tooltip: l10n.financeVoid,
                              icon: const Icon(Icons.delete_sweep_outlined),
                              onPressed: () async {
                                final reason = await askText(
                                  context,
                                  title: l10n.financeVoid,
                                  label: l10n.reason,
                                );
                                if (reason == null || !context.mounted) return;
                                if (await runAdminAction(
                                  context,
                                  () => ref
                                      .read(financeRepositoryProvider)
                                      .voidExpense(x.str('id'), reason),
                                  success: l10n.adminSaved,
                                )) {
                                  _refreshFinance(ref);
                                }
                              },
                            )
                          : null,
                    );
                  },
                ),
                AsyncError(:final error) => ListView(
                  children: [
                    ErrorView(
                      error: error,
                      onRetry: () => ref.invalidate(financeExpensesProvider),
                    ),
                  ],
                ),
                _ => const LoadingView(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- forms --

/// Asks for one line of text (a reason, an amount). Null when cancelled.
Future<String?> askText(
  BuildContext context, {
  required String title,
  required String label,
  bool number = false,
}) {
  final l10n = AppLocalizations.of(context);
  final form = GlobalKey<FormState>();
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Form(
        key: form,
        child: TextFormField(
          controller: c,
          autofocus: true,
          keyboardType: number ? TextInputType.number : null,
          decoration: InputDecoration(labelText: label),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return l10n.fieldRequired;
            if (number && (double.tryParse(t) ?? 0) <= 0) {
              return l10n.payAmountInvalid;
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.adminCancel),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(dialogContext, c.text.trim());
            }
          },
          child: Text(l10n.adminSave),
        ),
      ],
    ),
  );
}

/// Picks a learner by searching the server.
Future<(String, String)?> pickLearner(BuildContext context, WidgetRef ref) {
  return showDialog<(String, String)>(
    context: context,
    builder: (_) => const _LearnerPicker(),
  );
}

class _LearnerPicker extends ConsumerStatefulWidget {
  const _LearnerPicker();

  @override
  ConsumerState<_LearnerPicker> createState() => _LearnerPickerState();
}

class _LearnerPickerState extends ConsumerState<_LearnerPicker> {
  List<AppUserRow> _rows = const [];
  bool _loading = false;

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final page = await ref
          .read(adminRepositoryProvider)
          .people(persona: UserRole.learner, search: q, limit: 20);
      if (mounted) setState(() => _rows = page.rows);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.financeChooseLearner),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.adminSearchPeople,
              ),
              onSubmitted: _search,
              onChanged: (v) {
                if (v.length >= 2 || v.isEmpty) _search(v);
              },
            ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                children: [
                  for (final p in _rows)
                    ListTile(
                      title: Text(p.name),
                      subtitle: Text(p.contact),
                      onTap: () => Navigator.pop(context, (p.id, p.name)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Course?> _pickPaidCourse(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final courses = (await ref.read(adminCoursesProvider.future))
      .where((c) => c.access == CourseAccess.paid)
      .toList();
  if (!context.mounted) return null;
  return showDialog<Course>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.financeChooseCourse),
      children: [
        if (courses.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Text(l10n.financeNoPaidCourses),
          ),
        for (final c in courses)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, c),
            child: Text(
              '${c.title} · ${formatMoney(c.priceAmount ?? 0, c.priceCurrency ?? 'UGX')}',
            ),
          ),
      ],
    ),
  );
}

/// Record a bank / mobile-money / cash payment (waits for verification).
Future<bool> showRecordPaymentSheet(
  BuildContext context,
  WidgetRef ref, {
  (String, String)? learner,
  String? courseId,
  double? amount,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _MoneyForm(
      kind: _MoneyFormKind.payment,
      learner: learner,
      courseId: courseId,
      amount: amount,
    ),
  );
  return result ?? false;
}

Future<bool> showWaiverSheet(
  BuildContext context,
  WidgetRef ref, {
  (String, String)? learner,
  String? courseId,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _MoneyForm(
      kind: _MoneyFormKind.waiver,
      learner: learner,
      courseId: courseId,
    ),
  );
  return result ?? false;
}

Future<bool> showExpenseSheet(BuildContext context, WidgetRef ref) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _MoneyForm(kind: _MoneyFormKind.expense),
  );
  return result ?? false;
}

enum _MoneyFormKind { payment, waiver, expense }

class _MoneyForm extends ConsumerStatefulWidget {
  const _MoneyForm({
    required this.kind,
    this.learner,
    this.courseId,
    this.amount,
  });
  final _MoneyFormKind kind;
  final (String, String)? learner;
  final String? courseId;
  final double? amount;

  @override
  ConsumerState<_MoneyForm> createState() => _MoneyFormState();
}

class _MoneyFormState extends ConsumerState<_MoneyForm> {
  final _form = GlobalKey<FormState>();
  late (String, String)? _learner = widget.learner;
  late String? _courseId = widget.courseId;
  String? _courseTitle;
  late final _amount = TextEditingController(
    text: widget.amount == null ? '' : widget.amount!.round().toString(),
  );
  final _reference = TextEditingController();
  final _note = TextEditingController();
  final _category = TextEditingController();
  final _payee = TextEditingController();
  String _method = 'mobile_money';
  bool _fullWaiver = true;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final kind = widget.kind;
    final title = switch (kind) {
      _MoneyFormKind.payment => l10n.financeRecordPayment,
      _MoneyFormKind.waiver => l10n.financeGrantWaiver,
      _MoneyFormKind.expense => l10n.financeRecordExpense,
    };
    final needsAmount = kind != _MoneyFormKind.waiver || !_fullWaiver;

    Future<void> save() async {
      if (!_form.currentState!.validate()) return;
      if (kind != _MoneyFormKind.expense &&
          (_learner == null || _courseId == null)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.financeChooseBoth)));
        return;
      }
      setState(() => _saving = true);
      final repo = ref.read(financeRepositoryProvider);
      final amount = double.tryParse(_amount.text.trim());
      final ok = await runAdminAction(
        context,
        () => switch (kind) {
          _MoneyFormKind.payment => repo.recordPayment(
            userId: _learner!.$1,
            courseId: _courseId!,
            amount: amount!,
            method: _method,
            reference: _reference.text.trim(),
            paidOn: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          ),
          _MoneyFormKind.waiver => repo.grantWaiver(
            userId: _learner!.$1,
            courseId: _courseId!,
            amount: _fullWaiver ? null : amount,
            reason: _note.text.trim(),
          ),
          _MoneyFormKind.expense => repo.recordExpense(
            category: _category.text.trim(),
            amount: amount!,
            spentOn: _date,
            description: _note.text.trim().isEmpty ? null : _note.text.trim(),
            payee: _payee.text.trim().isEmpty ? null : _payee.text.trim(),
          ),
        },
        success: l10n.adminSaved,
      );
      if (!context.mounted) return;
      setState(() => _saving = false);
      if (ok) Navigator.pop(context, true);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.lg,
        0,
        Space.lg,
        MediaQuery.viewInsetsOf(context).bottom + Space.lg,
      ),
      child: Form(
        key: _form,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.sm),
            if (kind != _MoneyFormKind.expense) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(_learner?.$2 ?? l10n.financeChooseLearner),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final p = await pickLearner(context, ref);
                  if (p != null) setState(() => _learner = p);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.library_books_outlined),
                title: Text(
                  _courseTitle ??
                      (_courseId == null
                          ? l10n.financeChooseCourse
                          : l10n.financeCourseChosen),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final c = await _pickPaidCourse(context, ref);
                  if (c != null) {
                    setState(() {
                      _courseId = c.id;
                      _courseTitle = c.title;
                    });
                  }
                },
              ),
            ],
            if (kind == _MoneyFormKind.payment)
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: InputDecoration(labelText: l10n.financeMethod),
                items: [
                  for (final m in const [
                    'mobile_money',
                    'bank',
                    'cash',
                    'other',
                  ])
                    DropdownMenuItem(
                      value: m,
                      child: Text(methodLabel(l10n, m)),
                    ),
                ],
                onChanged: (v) => setState(() => _method = v!),
              ),
            if (kind == _MoneyFormKind.waiver)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _fullWaiver,
                onChanged: (v) => setState(() => _fullWaiver = v),
                title: Text(l10n.financeFullFee),
              ),
            if (kind == _MoneyFormKind.expense) ...[
              TextFormField(
                controller: _category,
                decoration: InputDecoration(
                  labelText: l10n.financeCategory,
                  hintText: l10n.financeCategoryHint,
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? l10n.fieldRequired : null,
              ),
              TextFormField(
                controller: _payee,
                decoration: InputDecoration(labelText: l10n.financePayee),
              ),
            ],
            if (needsAmount)
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.payAmountLabel('UGX'),
                ),
                validator: (v) => (double.tryParse(v?.trim() ?? '') ?? 0) <= 0
                    ? l10n.payAmountInvalid
                    : null,
              ),
            if (kind == _MoneyFormKind.payment)
              TextFormField(
                controller: _reference,
                decoration: InputDecoration(labelText: l10n.payReferenceLabel),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? l10n.payReferenceRequired
                    : null,
              ),
            if (kind != _MoneyFormKind.waiver)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(DateFormat.yMMMd(l10n.localeName).format(_date)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
            TextFormField(
              controller: _note,
              decoration: InputDecoration(
                labelText: kind == _MoneyFormKind.waiver
                    ? l10n.reason
                    : l10n.payNoteLabel,
              ),
              validator: (v) =>
                  kind == _MoneyFormKind.waiver && (v?.trim().isEmpty ?? true)
                  ? l10n.fieldRequired
                  : null,
            ),
            const SizedBox(height: Space.md),
            FilledButton(
              onPressed: _saving ? null : save,
              child: Text(l10n.adminSave),
            ),
            if (kind == _MoneyFormKind.payment) ...[
              const SizedBox(height: Space.xs),
              Text(l10n.financeRecordHint, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
