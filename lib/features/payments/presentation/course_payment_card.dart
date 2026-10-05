import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/errors/app_failure.dart';
import '../../../core/payments/direct_payments.dart';
import '../../../core/payments/marzpay_client.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../../shared/models/json.dart';
import '../data/payments_repository.dart';

/// Shown on a paid course the learner has not unlocked: what it costs,
/// Pay with mobile money (MarzPay prompt on their phone), or report a
/// payment made another way. With MarzPay credentials in the build the app
/// sends the prompt and reads MarzPay's answer itself; staff phones then
/// re-check it against MarzPay.
class CoursePaymentCard extends ConsumerStatefulWidget {
  const CoursePaymentCard({
    super.key,
    required this.course,
    required this.onPaid,
  });

  final Course course;

  /// Called once the course is paid for (refresh enrolment and outline).
  final VoidCallback onPaid;

  @override
  ConsumerState<CoursePaymentCard> createState() => _CoursePaymentCardState();
}

class _CoursePaymentCardState extends ConsumerState<CoursePaymentCard> {
  Payment? _payment;
  String? _error;
  Timer? _poll;
  DateTime? _startedAt;
  bool _checking = false;

  static const _pollEvery = Duration(seconds: 3);
  static const _giveUpAfter = Duration(minutes: 4);

  @override
  void initState() {
    super.initState();
    // Resume a payment started earlier (e.g. the app was closed).
    unawaited(_refresh(resume: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  PaymentsRepository get _repo => ref.read(paymentsRepositoryProvider);

  Future<void> _refresh({bool resume = false}) async {
    try {
      final list = await _repo.myPayments(widget.course.id);
      if (!mounted) return;
      var latest = list.firstOrNull;
      if (latest != null && latest.awaitingPayer) {
        latest = await _askMarzPay(latest) ?? latest;
        if (!mounted) return;
      }
      if (latest == null) return;
      if (resume &&
          !latest.awaitingPayer &&
          latest.status != PaymentStatus.pending) {
        return;
      }
      setState(() => _payment = latest);
      if (latest.status == PaymentStatus.verified) {
        _poll?.cancel();
        widget.onPaid();
      } else if (latest.awaitingPayer) {
        _startPolling();
      } else {
        _poll?.cancel();
      }
    } on AppFailure {
      // transient; the next tick tries again
    }
  }

  /// Direct mode: sends a payment not yet sent, or asks MarzPay whether a
  /// sent one is finished and records the answer.
  Future<Payment?> _askMarzPay(Payment p) async {
    final direct = ref.read(directPaymentsProvider);
    if (direct == null || _checking || p.reference == null) return null;
    _checking = true;
    try {
      if (p.providerUuid == null) {
        if (p.status != PaymentStatus.initiated || p.phone == null) return null;
        await direct.send(
          paymentId: p.id,
          reference: p.reference!,
          amount: p.amount,
          phone: p.phone!,
          description: widget.course.title,
        );
        return null;
      }
      final res = await direct.check(
        paymentId: p.id,
        providerUuid: p.providerUuid!,
        reference: p.reference!,
      );
      return res == null ? null : Payment.fromJson(res);
    } on MarzPayException catch (e) {
      if (!e.transient && mounted) setState(() => _error = e.message);
      return null;
    } finally {
      _checking = false;
    }
  }

  void _startPolling() {
    _startedAt ??= DateTime.now();
    _poll ??= Timer.periodic(_pollEvery, (_) {
      if (DateTime.now().difference(_startedAt!) > _giveUpAfter) {
        _poll?.cancel();
        _poll = null;
        if (mounted) setState(() {});
        return;
      }
      unawaited(_refresh());
    });
  }

  /// [periods]: pay that many periods of a repeating fee ahead.
  Future<void> _pay({int? periods}) async {
    final l10n = AppLocalizations.of(context);
    final phone = await _askPhone(
      context,
      ref.read(authSessionProvider).user?.phone,
    );
    if (phone == null || !mounted) return;
    setState(() {
      _error = null;
      _payment = null;
    });
    try {
      final p = await _repo.payWithMobileMoney(
        widget.course.id,
        phone,
        periods: periods,
      );
      if (!mounted) return;
      _poll?.cancel();
      _poll = null;
      _startedAt = DateTime.now();
      setState(() => _payment = p);
      await _refresh();
      if (mounted && (_payment?.awaitingPayer ?? false)) _startPolling();
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e is OfflineFailure
            ? l10n.offlineError
            : (e.message.isEmpty ? l10n.genericError : e.message),
      );
    }
  }

  Future<void> _reportOtherPayment(CourseBalance balance) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _ReportPaymentSheet(course: widget.course, balance: balance),
    );
    if (ok == true) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final balance = ref.watch(courseBalanceProvider(widget.course.id));
    final payment = _payment;
    final timedOut = payment != null && payment.awaitingPayer && _poll == null;

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: switch (balance) {
          AsyncData(value: final b) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.payCourseFee, style: theme.textTheme.labelLarge),
              Text(
                formatMoney(
                  b.outstanding > 0 ? b.outstanding : b.fee,
                  b.currency,
                ),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (b.recurring && b.pricePerPeriod != null)
                Text(
                  priceWithPeriod(
                        l10n,
                        b.pricePerPeriod!,
                        b.currency,
                        b.billingPeriod,
                        b.intervalDays,
                      ) +
                      (b.periodsTotal == null
                          ? ''
                          : ' · ${l10n.billPeriodsTotal(b.periodsTotal!)}'),
                  style: theme.textTheme.bodyMedium,
                ),
              if (b.pausedForFees)
                Text(
                  l10n.billPaused,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              if (b.recurring && b.periodsCovered != null)
                Text(
                  [
                    l10n.billCovered(b.periodsCovered!, b.periodsDue),
                    if (b.nextDueOn != null)
                      l10n.billNextDue(
                        DateFormat.yMMMd(l10n.localeName).format(b.nextDueOn!),
                      ),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                )
              else if (b.paid > 0 || b.waived > 0)
                Text(
                  l10n.payAlreadyCovered(
                    formatMoney(b.paid + b.waived, b.currency),
                    formatMoney(b.fee, b.currency),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: Space.md),
              if (payment != null && payment.awaitingPayer && !timedOut)
                _Status(
                  icon: Icons.phone_iphone,
                  busy: true,
                  title: l10n.payCheckPhoneTitle,
                  body: l10n.payCheckPhoneBody(
                    formatMoney(payment.amount, payment.currency),
                    payment.phone ?? '',
                  ),
                )
              else if (payment?.status == PaymentStatus.verified)
                _Status(
                  icon: Icons.check_circle,
                  title: l10n.payReceivedTitle,
                  body: l10n.payReceivedBody,
                )
              else if (payment?.status == PaymentStatus.pending)
                _Status(
                  icon: Icons.hourglass_top,
                  title: l10n.payPendingTitle,
                  body: l10n.payPendingBody,
                )
              else ...[
                if (timedOut)
                  _Status(
                    icon: Icons.schedule,
                    title: l10n.payNoAnswerTitle,
                    body: l10n.payNoAnswerBody,
                  ),
                if (payment?.status == PaymentStatus.failed ||
                    payment?.status == PaymentStatus.rejected)
                  _Status(
                    icon: Icons.error_outline,
                    error: true,
                    title: l10n.payFailedTitle,
                    body: l10n.payFailedBody,
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: b.outstanding > 0 ? _pay : null,
                  icon: const Icon(Icons.phone_android),
                  label: Text(l10n.payWithMobileMoney),
                ),
                if (b.recurring) ...[
                  const SizedBox(height: Space.xs),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final n = await showModalBottomSheet<int>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) =>
                            PrepaySheet(course: widget.course, balance: b),
                      );
                      if (n != null) await _pay(periods: n);
                    },
                    icon: const Icon(Icons.event_repeat),
                    label: Text(
                      l10n.ppPayAhead(periodWord(l10n, b.billingPeriod, 2)),
                    ),
                  ),
                ],
                const SizedBox(height: Space.xs),
                TextButton(
                  onPressed: () => _reportOtherPayment(b),
                  child: Text(l10n.payOtherWay),
                ),
              ],
            ],
          ),
          AsyncError() => Text(l10n.genericError),
          _ => const LinearProgressIndicator(),
        },
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    required this.icon,
    required this.title,
    required this.body,
    this.busy = false,
    this.error = false,
  });
  final IconData icon;
  final String title;
  final String body;
  final bool busy;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = error ? theme.colorScheme.error : theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          busy
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Icon(icon, color: color),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks for the MTN / Airtel number to prompt.
Future<String?> _askPhone(BuildContext context, String? initial) {
  final l10n = AppLocalizations.of(context);
  final form = GlobalKey<FormState>();
  final phone = TextEditingController(
    text: initial?.replaceFirst(RegExp(r'^\+256'), '0'),
  );
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.payWithMobileMoney),
      content: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.payPhoneHint),
            const SizedBox(height: Space.sm),
            TextFormField(
              controller: phone,
              autofocus: true,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: l10n.payPhoneLabel,
                hintText: '07XX XXX XXX',
              ),
              validator: (v) =>
                  ugMobile(v ?? '') == null ? l10n.payPhoneInvalid : null,
            ),
          ],
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
              Navigator.pop(dialogContext, ugMobile(phone.text));
            }
          },
          child: Text(l10n.payNow),
        ),
      ],
    ),
  );
}

/// Uganda mobile number as +2567XXXXXXXX, or null.
String? ugMobile(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
  final m = RegExp(r'^(?:\+?256|0)?(7\d{8})$').firstMatch(digits);
  return m == null ? null : '+256${m.group(1)}';
}

/// "I paid by bank / mobile money outside the app".
class _ReportPaymentSheet extends ConsumerStatefulWidget {
  const _ReportPaymentSheet({required this.course, required this.balance});
  final Course course;
  final CourseBalance balance;

  @override
  ConsumerState<_ReportPaymentSheet> createState() =>
      _ReportPaymentSheetState();
}

class _ReportPaymentSheetState extends ConsumerState<_ReportPaymentSheet> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.balance.outstanding.round().toString(),
  );
  final _reference = TextEditingController();
  final _note = TextEditingController();
  String _method = 'bank';
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(paymentsRepositoryProvider)
          .reportPayment(
            courseId: widget.course.id,
            method: _method,
            amount: double.parse(_amount.text.trim()),
            reference: _reference.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message.isEmpty ? l10n.genericError : e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(orgSettingsProvider).value ?? const {};
    final instructions = _method == 'bank'
        ? settings['bank_instructions']
        : settings['mobile_money_instructions'];
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
            Text(l10n.payOtherWay, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.sm),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'bank', label: Text(l10n.payMethodBank)),
                ButtonSegment(
                  value: 'mobile_money',
                  label: Text(l10n.payMethodMobileMoney),
                ),
              ],
              selected: {_method},
              onSelectionChanged: (s) => setState(() => _method = s.first),
            ),
            const SizedBox(height: Space.sm),
            if (instructions != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: SelectableText(instructions),
                ),
              ),
            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.payAmountLabel(widget.balance.currency),
              ),
              validator: (v) => (double.tryParse(v?.trim() ?? '') ?? 0) <= 0
                  ? l10n.payAmountInvalid
                  : null,
            ),
            TextFormField(
              controller: _reference,
              decoration: InputDecoration(labelText: l10n.payReferenceLabel),
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? l10n.payReferenceRequired
                  : null,
            ),
            TextFormField(
              controller: _note,
              decoration: InputDecoration(labelText: l10n.payNoteLabel),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: Space.sm),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: Space.md),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(l10n.paySubmitReport),
            ),
            const SizedBox(height: Space.xs),
            Text(l10n.paySubmitReportHint, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// "week", "month", "term" or "period", for [n] of them.
String periodWord(AppLocalizations l10n, String period, int n) =>
    switch (period) {
      'weekly' => l10n.ppWeeks(n),
      'monthly' => l10n.ppMonths(n),
      'termly' => l10n.ppTerms(n),
      _ => l10n.ppPeriods(n),
    };

/// Choose how many periods to pay at once; the database says what that
/// costs and until when it covers. Pops with the number chosen.
class PrepaySheet extends ConsumerStatefulWidget {
  const PrepaySheet({super.key, required this.course, required this.balance});
  final Course course;
  final CourseBalance balance;

  @override
  ConsumerState<PrepaySheet> createState() => _PrepaySheetState();
}

class _PrepaySheetState extends ConsumerState<PrepaySheet> {
  int _n = 1;
  Json? _quote;
  Object? _error;
  int _asked = 0;

  @override
  void initState() {
    super.initState();
    // Start from what is already due (at least one period).
    final behind =
        widget.balance.periodsDue - (widget.balance.periodsCovered ?? 0);
    _n = behind > 1 ? behind : 1;
    _ask();
  }

  Future<void> _ask() async {
    final ticket = ++_asked;
    setState(() {
      _quote = null;
      _error = null;
    });
    try {
      final q = await ref
          .read(paymentsRepositoryProvider)
          .prepayQuote(widget.course.id, _n);
      if (mounted && ticket == _asked) setState(() => _quote = q);
    } catch (e) {
      if (mounted && ticket == _asked) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final b = widget.balance;
    final q = _quote;
    final max = q?.intOrNull('max_periods');
    final min = q?.intOrNull('min_periods') ?? 1;
    final date = DateFormat.yMMMd(l10n.localeName);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.ppTitle, style: theme.textTheme.titleLarge),
          Text(l10n.ppIntro, style: theme.textTheme.bodySmall),
          const SizedBox(height: Space.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _n > min
                    ? () {
                        _n--;
                        _ask();
                      }
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                child: Text(
                  periodWord(l10n, b.billingPeriod, _n),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              IconButton.filledTonal(
                onPressed: max == null || _n < max
                    ? () {
                        _n++;
                        _ask();
                      }
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          if (_error != null)
            Text(
              _error is AppFailure && (_error! as AppFailure).message.isNotEmpty
                  ? (_error! as AppFailure).message
                  : l10n.genericError,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            )
          else if (q == null)
            const LinearProgressIndicator()
          else ...[
            Text(
              formatMoney(
                q.numOrNull('amount') ?? 0,
                q.strOrNull('currency') ?? b.currency,
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              l10n.ppCovers(
                date.format(DateTime.parse(q.str('covers_from'))),
                date.format(DateTime.parse(q.str('covers_until'))),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: Space.md),
          FilledButton.icon(
            onPressed: q == null ? null : () => Navigator.pop(context, _n),
            icon: const Icon(Icons.phone_android),
            label: Text(l10n.payWithMobileMoney),
          ),
        ],
      ),
    );
  }
}
