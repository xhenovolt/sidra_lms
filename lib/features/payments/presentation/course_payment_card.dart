import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/payments/direct_payments.dart';
import '../../../core/payments/marzpay_client.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../curriculum/domain/curriculum_models.dart';
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

  Future<void> _pay() async {
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
      final p = await _repo.payWithMobileMoney(widget.course.id, phone);
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
              if (b.paid > 0 || b.waived > 0)
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
