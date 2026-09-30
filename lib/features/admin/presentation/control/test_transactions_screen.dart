import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/data/data_providers.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/payments/marzpay_client.dart';
import '../../../../core/payments/phone_test_runner.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/json.dart';
import '../../../../shared/widgets/state_views.dart';
import '../admin_shell.dart' show myPermissionsProvider;

/// Uganda mobile-money networks by prefix (the 3 digits after 0 / +256).
enum MoMoNetwork { mtn, airtel }

/// MTN MoMo: 076 077 078 079 (and 039). Airtel Money: 070 074 075 (and
/// 020). Returns the number as +2567XXXXXXXX and its network, or null.
(String, MoMoNetwork)? parseMoMoNumber(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
  final m = RegExp(r'^(?:\+?256|0)?([37]\d{8}|20\d{7})$').firstMatch(digits);
  if (m == null) return null;
  final local = m.group(1)!;
  final prefix = local.substring(0, 2);
  final network = switch (prefix) {
    '76' || '77' || '78' || '79' || '39' => MoMoNetwork.mtn,
    '70' || '74' || '75' || '20' => MoMoNetwork.airtel,
    _ => null,
  };
  return network == null ? null : ('+256$local', network);
}

final _moneyTestsProvider = FutureProvider.autoDispose<List<Json>>(
  (ref) async => [
    for (final r in await ref
        .watch(postgresApiProvider)
        .rpcRows('payment_tests', params: {'p_limit': 200}))
      if (r['kind'] == 'collection' || r['kind'] == 'disbursement') Json.from(r),
  ],
);

/// Admin / developer only (permission payments.test, also checked by the
/// database): send a REAL collection or disbursement through MarzPay and
/// see exactly what came back, with a history of every test.
class TestTransactionsScreen extends ConsumerStatefulWidget {
  const TestTransactionsScreen({super.key});

  @override
  ConsumerState<TestTransactionsScreen> createState() =>
      _TestTransactionsScreenState();
}

class _TestTransactionsScreenState
    extends ConsumerState<TestTransactionsScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _amount = TextEditingController(text: '500');
  final _note = TextEditingController();
  final _scroll = ScrollController();
  bool _collect = true;
  bool _sending = false;
  String? _error;

  /// The test shown in the response panel (the one just sent, or one
  /// tapped in the history).
  String? _shownId;
  Json? _shown;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    _phone.dispose();
    _amount.dispose();
    _note.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _show(String id) {
    _poll?.cancel();
    setState(() {
      _shownId = id;
      _shown = null;
    });
    Future<void> load() async {
      try {
        final rows = await ref
            .read(postgresApiProvider)
            .select('payment_tests', filters: {'id': 'eq.$id'});
        if (!mounted || _shownId != id) return;
        setState(() => _shown = rows.isEmpty ? null : Json.from(rows.first));
        if (_shown?['status'] == 'done') {
          _poll?.cancel();
          ref.invalidate(_moneyTestsProvider);
        }
      } catch (_) {
        // next tick tries again
      }
    }

    unawaited(load());
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => load());
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    final (phone, network) = parseMoMoNumber(_phone.text)!;
    final amount = int.parse(_amount.text.trim());
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber, size: 40),
        title: Text(l.ttConfirmTitle),
        content: Text(
          _collect
              ? l.ttConfirmCollect(amount, phone, _networkName(l, network))
              : l.ttConfirmDisburse(amount, phone, _networkName(l, network)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_collect ? l.ttCollectNow : l.ttDisburseNow),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final kind = _collect ? 'collection' : 'disbursement';
    final params = <String, Object?>{
      'phone': phone,
      'amount': amount,
      'description': _note.text.trim(),
    };
    // The database asks for this exact phrase (typed in the older form):
    // this screen's own confirmation stands in for it.
    final confirm = '$amount UGX $phone';
    try {
      final marz = ref.read(marzPayClientProvider);
      final api = ref.read(postgresApiProvider);
      final id = marz != null
          ? await PhoneTestRunner(api: api, marz: marz)
                .start(kind, params, confirm)
          : '${await api.rpc('request_payment_test', params: {
              'p_kind': kind,
              'p_params': params,
              'p_confirm': confirm,
            })}';
      if (!mounted) return;
      ref.invalidate(_moneyTestsProvider);
      _show(id);
      // Bring the response into view.
      unawaited(
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      );
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static String _networkName(AppLocalizations l, MoMoNetwork n) =>
      n == MoMoNetwork.mtn ? l.ttMtn : l.ttAirtel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final perms = ref.watch(myPermissionsProvider).value ?? const {};
    if (!perms.contains('payments.test')) {
      return Scaffold(
        appBar: AppBar(title: Text(l.ttTitle)),
        body: EmptyView(icon: Icons.lock_outline, title: l.adminNotAllowed),
      );
    }
    final hasKeys = ref.watch(marzPayClientProvider) != null;
    final parsed = parseMoMoNumber(_phone.text);
    final history = ref.watch(_moneyTestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.ttTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_moneyTestsProvider.future),
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(Space.md),
          children: [
            if (_shownId != null) ...[
              _ResponsePanel(test: _shown, onClose: () {
                _poll?.cancel();
                setState(() {
                  _shownId = null;
                  _shown = null;
                });
              }),
              const SizedBox(height: Space.md),
            ],
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Text(l.ttRealMoney),
              ),
            ),
            if (!hasKeys)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Text(l.ttNoKeys),
                ),
              ),
            const SizedBox(height: Space.sm),
            Form(
              key: _form,
              // Once shown, errors clear as soon as the entry is right.
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.call_received),
                        label: Text(l.ttCollect),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.call_made),
                        label: Text(l.ttDisburse),
                      ),
                    ],
                    selected: {_collect},
                    onSelectionChanged: (s) =>
                        setState(() => _collect = s.first),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.xs),
                    child: Text(
                      _collect ? l.ttCollectHint : l.ttDisburseHint,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: _collect ? l.ttPayerPhone : l.ttRecipientPhone,
                      hintText: '0772 123456',
                      helperText: parsed == null
                          ? l.ttPhoneHelp
                          : '${_networkName(l, parsed.$2)} · ${parsed.$1}',
                      suffixIcon: parsed == null
                          ? null
                          : Icon(Icons.check_circle, color: Colors.green.shade700),
                    ),
                    validator: (v) =>
                        parseMoMoNumber(v ?? '') == null ? l.ttPhoneInvalid : null,
                  ),
                  TextFormField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l.ttAmount,
                      helperText: l.ttAmountHelp,
                      suffixText: 'UGX',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      return n == null || n < 500 ? l.ttAmountInvalid : null;
                    },
                  ),
                  TextFormField(
                    controller: _note,
                    decoration: InputDecoration(labelText: l.mcDescription),
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
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _collect ? null : theme.colorScheme.error,
                    ),
                    onPressed: _sending ? null : _submit,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_collect ? Icons.call_received : Icons.call_made),
                    label: Text(_collect ? l.ttCollectNow : l.ttDisburseNow),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
            Text(l.ttHistory, style: theme.textTheme.titleMedium),
            Text(l.ttHistoryHint, style: theme.textTheme.bodySmall),
            switch (history) {
              AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Text(l.mcNoTests),
              ),
              AsyncData(:final value) => Column(
                children: [
                  for (final t in value)
                    _HistoryRow(
                      test: t,
                      selected: t['id'] == _shownId,
                      onTap: () {
                        _show('${t['id']}');
                        unawaited(
                          _scroll.animateTo(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          ),
                        );
                      },
                    ),
                ],
              ),
              AsyncError(:final error) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(_moneyTestsProvider),
              ),
              _ => const LinearProgressIndicator(),
            },
          ],
        ),
      ),
    );
  }
}

String _statusOf(AppLocalizations l, Json t) {
  if (t['status'] != 'done') return l.mcRunning;
  return switch ('${t['result']}') {
    'verified_success' => l.ttResultSuccess,
    'provider_accepted' => l.ttResultAccepted,
    'failed' => l.ttResultFailed,
    'cancelled' => l.ttResultCancelled,
    'pending' => l.ttResultPending,
    'blocked' => l.ttResultBlocked,
    final r => r,
  };
}

Color _statusColor(ThemeData theme, Json t) => switch ('${t['result']}') {
  _ when t['status'] != 'done' => theme.colorScheme.outline,
  'verified_success' => Colors.green.shade700,
  'provider_accepted' || 'pending' => theme.colorScheme.tertiary,
  _ => theme.colorScheme.error,
};

String _when(AppLocalizations l, Object? at) {
  final d = DateTime.tryParse('${at ?? ''}');
  return d == null
      ? ''
      : DateFormat.yMMMd(l.localeName).add_Hms().format(d.toLocal());
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.test,
    required this.selected,
    required this.onTap,
  });
  final Json test;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final t = test;
    final collect = t['kind'] == 'collection';
    final p = (t['params'] as Map?) ?? const {};
    return Card(
      color: selected ? theme.colorScheme.secondaryContainer : null,
      child: ListTile(
        onTap: onTap,
        leading: Icon(collect ? Icons.call_received : Icons.call_made),
        title: Text(
          '${collect ? l.ttCollect : l.ttDisburse} · ${p['amount'] ?? '?'} UGX',
        ),
        subtitle: Text(
          [
            _when(l, t['created_at']),
            // (stored masked: the full number is never kept)
            '${p['phone'] ?? ''}',
            ?t['error_code'] as String?,
          ].where((s) => s.isNotEmpty).join(' · '),
        ),
        trailing: Text(
          _statusOf(l, t),
          style: theme.textTheme.labelMedium?.copyWith(
            color: _statusColor(theme, t),
          ),
        ),
      ),
    );
  }
}

/// What happened: status, MarzPay's own status and error code, every step,
/// and MarzPay's raw answers.
class _ResponsePanel extends StatelessWidget {
  const _ResponsePanel({required this.test, required this.onClose});
  final Json? test;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final t = test;
    final mono = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    final ev = (t?['evidence'] as Map?)?.cast<String, dynamic>() ?? const {};
    Widget raw(String title, Object? json) => json == null
        ? const SizedBox.shrink()
        : ExpansionTile(
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: true,
            title: Text(title, style: theme.textTheme.titleSmall),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(json),
                  style: mono,
                ),
              ),
            ],
          );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: t == null
            ? const LinearProgressIndicator()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.ttResponse,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        _statusOf(l, t),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: _statusColor(theme, t),
                        ),
                      ),
                      IconButton(
                        tooltip: l.ttClose,
                        icon: const Icon(Icons.close),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  if (t['status'] != 'done') const LinearProgressIndicator(),
                  if (t['message'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.xs),
                      child: Text('${t['message']}'),
                    ),
                  Wrap(
                    spacing: Space.md,
                    runSpacing: Space.xxs,
                    children: [
                      for (final (label, v) in [
                        (l.ttProviderStatus, t['provider_status']),
                        (l.ttErrorCode, t['error_code'] ?? ev['error_code']),
                        (l.ttHttpStatus, ev['http_status']),
                        (l.ccTraceProviderId, t['provider_uuid']),
                        (l.ttReference, t['reference']),
                        (l.mcEnvironment, t['environment']),
                      ])
                        if (v != null)
                          SelectableText(
                            '$label: $v',
                            style: theme.textTheme.bodySmall,
                          ),
                    ],
                  ),
                  const SizedBox(height: Space.xs),
                  for (final s in (t['steps'] as List? ?? const []))
                    Text(
                      '${(s as Map)['step']}. ${s['label']}: '
                      '${s['state']}${s['detail'] == null ? '' : ' — ${s['detail']}'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  raw(l.ttRawResponse, ev['provider_response']),
                  raw(l.ttRawFinal, ev['final_response']),
                ],
              ),
      ),
    );
  }
}
