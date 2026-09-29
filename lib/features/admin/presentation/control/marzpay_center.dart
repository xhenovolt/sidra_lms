import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/data/data_providers.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/json.dart';
import '../../../../shared/widgets/state_views.dart';
import 'control_center.dart'
    show HealthChip, Health, SettingsSectionScreen, systemHealthProvider;
import 'settings_registry.dart';

final _testsProvider = FutureProvider.autoDispose<List<Json>>(
  (ref) async =>
      (await ref
              .watch(postgresApiProvider)
              .rpcRows('payment_tests', params: {'p_limit': 100}))
          .map(Json.from)
          .toList(),
);

String _when(AppLocalizations l, Object? v) {
  final d = v == null ? null : DateTime.tryParse('$v');
  return d == null
      ? '—'
      : DateFormat.yMMMd(l.localeName).add_jms().format(d.toLocal());
}

String? normalizeUgPhone(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
  final m = RegExp(r'^(?:\+?256|0)?(7\d{8})$').firstMatch(digits);
  return m == null ? null : '+256${m.group(1)}';
}

String testKindLabel(AppLocalizations l, String k) => switch (k) {
  'connection' => l.mcConnection,
  'capabilities' => l.mcCapabilities,
  'balance' => l.mcBalance,
  'collection' => l.mcCollection,
  'disbursement' => l.mcDisbursement,
  'status_lookup' => l.mcLookup,
  'callbacks' => l.mcCallbacks,
  'reconciliation' => l.mcReconciliation,
  _ => k,
};

(Health, String) testResult(AppLocalizations l, String? r) => switch (r) {
  'verified_success' => (Health.ok, l.mcVerified),
  'provider_accepted' => (Health.warning, l.mcAccepted),
  'failed' => (Health.failed, l.mcFailedR),
  'cancelled' => (Health.warning, l.mcCancelled),
  'pending' => (Health.warning, l.mcPending),
  'unknown' => (Health.warning, l.mcUnknown),
  'blocked' => (Health.disabled, l.mcBlocked),
  'unsupported' => (Health.disabled, l.mcUnsupported),
  _ => (Health.untested, l.mcRunning),
};

/// Queues a test (after the right confirmations) and opens its live view.
Future<void> startPaymentTest(
  BuildContext context,
  WidgetRef ref,
  String kind, [
  Map<String, Object?> params = const {},
  String? confirm,
]) async {
  final l = AppLocalizations.of(context);
  try {
    final id = await ref
        .read(postgresApiProvider)
        .rpc(
          'request_payment_test',
          params: {'p_kind': kind, 'p_params': params, 'p_confirm': confirm},
        );
    ref.invalidate(_testsProvider);
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PaymentTestRunScreen(testId: '$id'),
        ),
      );
    }
    ref.invalidate(_testsProvider);
    ref.invalidate(systemHealthProvider);
  } on AppFailure catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${l.genericError} $e')));
    }
  }
}

// ============================================================ test centre ==

class MarzPayCenterScreen extends ConsumerWidget {
  const MarzPayCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tests = ref.watch(_testsProvider);
    final list = tests.value ?? const <Json>[];
    Json? latest(String kind) => list
        .where((t) => t['kind'] == kind && t['status'] == 'done')
        .firstOrNull;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.ccMarzCenter),
          actions: [
            IconButton(
              tooltip: l.ccSafetySettings,
              icon: const Icon(Icons.tune),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsSectionScreen(
                    section: SettingsSection.marzpay,
                  ),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l.mcTestTab),
              Tab(text: l.mcHistoryTab),
              Tab(text: l.mcCallbacks),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.refresh(_testsProvider.future),
              child: ListView(
                padding: const EdgeInsets.all(Space.md),
                children: [
                  Text(l.mcIntro, style: theme.textTheme.bodySmall),
                  const SizedBox(height: Space.sm),
                  _CapabilityMatrix(latest: latest),
                  const SizedBox(height: Space.md),
                  Text(l.mcWhatTesting, style: theme.textTheme.titleMedium),
                  const SizedBox(height: Space.xs),
                  for (final (kind, icon, money) in const [
                    ('connection', Icons.wifi_tethering, false),
                    ('capabilities', Icons.checklist, false),
                    ('balance', Icons.account_balance_wallet_outlined, false),
                    ('collection', Icons.call_received, true),
                    ('disbursement', Icons.call_made, true),
                    ('status_lookup', Icons.manage_search, false),
                    ('callbacks', Icons.webhook, false),
                    ('reconciliation', Icons.balance, false),
                  ])
                    Card(
                      child: ListTile(
                        leading: Icon(icon),
                        title: Row(
                          children: [
                            Expanded(child: Text(testKindLabel(l, kind))),
                            if (money)
                              HealthChip(Health.failed, label: l.mcRealMoney),
                          ],
                        ),
                        subtitle: Text(
                          [
                            _kindHint(l, kind),
                            if (latest(kind) case final t?)
                              '${l.mcLast}: ${testResult(l, t['result'] as String?).$2} · ${_when(l, t['finished_at'])}',
                          ].join('\n'),
                        ),
                        onTap: () => _start(context, ref, kind),
                      ),
                    ),
                ],
              ),
            ),
            _History(tests: tests),
            const _Callbacks(),
          ],
        ),
      ),
    );
  }

  static String _kindHint(AppLocalizations l, String kind) => switch (kind) {
    'connection' => l.mcConnectionHint,
    'capabilities' => l.mcCapabilitiesHint,
    'balance' => l.mcBalanceHint,
    'collection' => l.mcCollectionHint,
    'disbursement' => l.mcDisbursementHint,
    'status_lookup' => l.mcLookupHint,
    'callbacks' => l.mcCallbacksHint,
    _ => l.mcReconciliationHint,
  };

  Future<void> _start(BuildContext context, WidgetRef ref, String kind) async {
    switch (kind) {
      case 'collection' || 'disbursement':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => _MoneyTestForm(kind: kind)),
        );
      case 'status_lookup':
        final l = AppLocalizations.of(context);
        final c = TextEditingController();
        final q = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.mcLookup),
            content: TextField(
              controller: c,
              autofocus: true,
              decoration: InputDecoration(labelText: l.mcLookupField),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.adminCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, c.text.trim()),
                child: Text(l.mcRunTest),
              ),
            ],
          ),
        );
        c.dispose();
        if (q != null && q.isNotEmpty && context.mounted) {
          await startPaymentTest(context, ref, kind, {'query': q});
        }
      default:
        await startPaymentTest(context, ref, kind);
    }
  }
}

/// What MarzPay offers, what Sidra implements, and what has been proven.
class _CapabilityMatrix extends ConsumerWidget {
  const _CapabilityMatrix({required this.latest});
  final Json? Function(String kind) latest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ev =
        latest('capabilities')?.obj('evidence') ?? const <String, dynamic>{};
    final col = (ev['collection'] as List? ?? const [])
        .map((e) => '$e'.toLowerCase())
        .toList();
    final send = (ev['disbursement'] as List? ?? const [])
        .map((e) => '$e'.toLowerCase())
        .toList();
    final known = ev.isNotEmpty;
    // provider: true/false/null (not read yet); sidra: implemented?; test kind.
    final rows = <(String, bool?, bool, String?)>[
      (l.mcConnection, true, true, 'connection'),
      (l.mcAuthentication, true, true, 'connection'),
      (
        l.mcCollectionMm,
        known
            ? col.any((p) => p.contains('mtn') || p.contains('airtel'))
            : null,
        true,
        'collection',
      ),
      (
        l.mcCard,
        known ? col.any((p) => p.contains('card')) : null,
        false,
        null,
      ),
      (
        l.mcDisbursementMm,
        known
            ? send.any((p) => p.contains('mtn') || p.contains('airtel'))
            : null,
        true,
        'disbursement',
      ),
      (l.mcBank, known ? ev['bank_transfer'] == true : null, false, null),
      (l.mcWallet, known ? ev['wallet_transfer'] == true : null, false, null),
      (l.mcBalance, true, true, 'balance'),
      (l.mcLookup, true, true, 'status_lookup'),
      (l.mcCallbacks, true, true, 'callbacks'),
      (l.mcReconciliation, true, true, 'reconciliation'),
      (l.mcRefund, false, false, null),
    ];
    String verdict(bool? provider, bool sidra, String? kind) {
      if (provider == false) return l.mcUnsupportedByProvider;
      if (provider == null) return l.mcRunCapabilities;
      if (!sidra) return l.mcSidraMissing;
      final t = kind == null ? null : latest(kind);
      return switch (t?['result'] as String?) {
        null => l.mcImplementedUntested,
        'blocked' => l.mcImplementedBlocked,
        final r => testResult(l, r).$2,
      };
    }

    Health health(bool? provider, bool sidra, String? kind) {
      if (provider == false || !sidra) return Health.disabled;
      final r = kind == null ? null : latest(kind)?['result'] as String?;
      return r == null ? Health.untested : testResult(l, r).$1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.mcMatrix, style: theme.textTheme.titleMedium),
            Text(l.mcMatrixHint, style: theme.textTheme.bodySmall),
            for (final (label, provider, sidra, kind) in rows)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(label),
                subtitle: Text(
                  '${l.mcProvider}: ${provider == null
                      ? '?'
                      : provider
                      ? l.ccYes
                      : l.ccNo} · '
                  '${l.mcSidra}: ${sidra ? l.ccYes : l.ccNo}',
                ),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: HealthChip(
                    health(provider, sidra, kind),
                    label: verdict(provider, sidra, kind),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Collection / disbursement: real money, so a form, a summary and a typed
/// confirmation. Nothing is sent until both are done.
class _MoneyTestForm extends ConsumerStatefulWidget {
  const _MoneyTestForm({required this.kind});
  final String kind;

  @override
  ConsumerState<_MoneyTestForm> createState() => _MoneyTestFormState();
}

class _MoneyTestFormState extends ConsumerState<_MoneyTestForm> {
  final _phone = TextEditingController();
  final _amount = TextEditingController(text: '500');
  final _note = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final l = AppLocalizations.of(context);
    final phone = normalizeUgPhone(_phone.text);
    final amount = int.tryParse(_amount.text.trim());
    if (phone == null || amount == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.mcFormInvalid)));
      return;
    }
    final collect = widget.kind == 'collection';
    // 1: the facts, clearly.
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber, size: 40),
        title: Text(l.mcRealTitle),
        content: Text(
          collect
              ? l.mcRealCollect(amount, phone)
              : l.mcRealSend(amount, phone),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.mcContinue),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return;
    // 2: type it.
    final expected = '$amount UGX $phone';
    final typed = TextEditingController();
    final second = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.mcTypeToConfirm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              expected,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            TextField(controller: typed, autofocus: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, typed.text.trim()),
            child: Text(l.mcRunTest),
          ),
        ],
      ),
    );
    typed.dispose();
    if (second == null || !mounted) return;
    await startPaymentTest(context, ref, widget.kind, {
      'phone': phone,
      'amount': amount,
      'description': _note.text.trim(),
    }, second);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final collect = widget.kind == 'collection';
    return Scaffold(
      appBar: AppBar(title: Text(testKindLabel(l, widget.kind))),
      body: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Text(collect ? l.mcCollectWarning : l.mcSendWarning),
            ),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: collect ? l.mcPayerPhone : l.mcRecipientPhone,
              hintText: '0772 123456',
            ),
          ),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l.mcAmount,
              helperText: l.mcAmountHint,
            ),
          ),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.mcDescription),
          ),
          const SizedBox(height: Space.md),
          FilledButton.icon(
            onPressed: _go,
            icon: Icon(collect ? Icons.call_received : Icons.call_made),
            label: Text(collect ? l.mcStartCollection : l.mcStartDisbursement),
          ),
        ],
      ),
    );
  }
}

// =============================================================== live run ==

/// One test, live: every step as the payments server reports it.
class PaymentTestRunScreen extends ConsumerStatefulWidget {
  const PaymentTestRunScreen({super.key, required this.testId});
  final String testId;

  @override
  ConsumerState<PaymentTestRunScreen> createState() =>
      _PaymentTestRunScreenState();
}

class _PaymentTestRunScreenState extends ConsumerState<PaymentTestRunScreen> {
  Json? _test;
  Timer? _poll;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await ref
          .read(postgresApiProvider)
          .select('payment_tests', filters: {'id': 'eq.${widget.testId}'});
      if (!mounted) return;
      setState(() => _test = rows.isEmpty ? null : Json.from(rows.first));
      if (_test?['status'] == 'done') _poll?.cancel();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final t = _test;
    if (t == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _error != null
            ? ErrorView(error: _error!, onRetry: _load)
            : const LoadingView(),
      );
    }
    final (health, label) = testResult(l, t['result'] as String?);
    final steps = (t['steps'] as List? ?? const [])
        .map((s) => Json.from(s as Map))
        .toList();
    final queuedFor = DateTime.now().difference(
      DateTime.tryParse('${t['created_at']}') ?? DateTime.now(),
    );
    return Scaffold(
      appBar: AppBar(title: Text(testKindLabel(l, '${t['kind']}'))),
      body: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _when(l, t['created_at']),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (t['real_money'] == true)
                HealthChip(Health.failed, label: l.mcRealMoney),
              const SizedBox(width: Space.xs),
              if (t['status'] == 'done')
                HealthChip(health, label: label)
              else
                HealthChip(Health.untested, label: l.mcRunning),
            ],
          ),
          if (t['status'] == 'queued' && queuedFor.inSeconds > 30)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Text(l.mcQueuedLong),
              ),
            ),
          if ((t['params'] as Map?)?.isNotEmpty ?? false)
            Text(
              (t['params'] as Map).entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join(' · '),
            ),
          const SizedBox(height: Space.sm),
          for (final s in steps)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                switch ('${s['state']}') {
                  'done' => Icons.check_circle,
                  'failed' => Icons.cancel,
                  'skipped' => Icons.remove_circle_outline,
                  _ => Icons.hourglass_top,
                },
                color: switch ('${s['state']}') {
                  'done' => Colors.green.shade700,
                  'failed' => theme.colorScheme.error,
                  _ => theme.colorScheme.outline,
                },
              ),
              title: Text('${s['step']}. ${s['label']}'),
              subtitle: Text('${s['detail'] ?? ''}\n${_when(l, s['at'])}'),
            ),
          if (t['status'] != 'done') const LinearProgressIndicator(),
          if (t['message'] != null) ...[
            const SizedBox(height: Space.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Text(
                  '${t['message']}',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ],
          if ((t['evidence'] as Map?)?.isNotEmpty ?? false) ...[
            Text(l.mcEvidence, style: theme.textTheme.titleSmall),
            SelectableText(
              const JsonEncoder.withIndent('  ').convert(t['evidence']),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
          if (t['provider_uuid'] != null)
            SelectableText('${l.ccTraceProviderId}: ${t['provider_uuid']}'),
          if (t['environment'] != null)
            Text('${l.mcEnvironment}: ${t['environment']}'),
        ],
      ),
    );
  }
}

class _History extends ConsumerWidget {
  const _History({required this.tests});
  final AsyncValue<List<Json>> tests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return switch (tests) {
      AsyncData(:final value) when value.isEmpty => EmptyView(
        icon: Icons.science_outlined,
        title: l.mcNoTests,
      ),
      AsyncData(:final value) => RefreshIndicator(
        onRefresh: () => ref.refresh(_testsProvider.future),
        child: ListView.separated(
          itemCount: value.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final t = value[i];
            final (h, label) = testResult(l, t['result'] as String?);
            return ListTile(
              title: Text(testKindLabel(l, '${t['kind']}')),
              subtitle: Text(
                [
                  _when(l, t['created_at']),
                  ?t['requested_by_name'] as String?,
                  if ((t['params'] as Map?)?['amount'] != null)
                    '${(t['params'] as Map)['amount']} UGX ${(t['params'] as Map)['phone']}',
                  ?t['message'] as String?,
                ].join(' · '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: HealthChip(
                t['status'] == 'done' ? h : Health.untested,
                label: t['status'] == 'done' ? label : l.mcRunning,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PaymentTestRunScreen(testId: '${t['id']}'),
                ),
              ),
            );
          },
        ),
      ),
      AsyncError(:final error) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(_testsProvider),
      ),
      _ => const LoadingView(),
    };
  }
}

class _Callbacks extends ConsumerWidget {
  const _Callbacks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return FutureBuilder(
      future: ref
          .read(postgresApiProvider)
          .select('payment_webhooks', order: 'received_at.desc', limit: 100),
      builder: (context, snap) {
        if (snap.hasError) return ErrorView(error: snap.error!, onRetry: () {});
        if (!snap.hasData) return const LoadingView();
        final rows = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            Text(
              l.mcCallbacksList,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (rows.isEmpty)
              EmptyView(icon: Icons.webhook, title: l.mcNoCallbacks),
            for (final w in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  w['body_valid'] == true
                      ? Icons.mark_email_read_outlined
                      : Icons.report_outlined,
                ),
                title: Text(
                  '${w['event'] ?? '?'} → ${w['outcome'] ?? '?'}${w['duplicate'] == true ? ' · ${l.mcDuplicate}' : ''}',
                ),
                subtitle: Text(
                  [
                    _when(l, w['received_at']),
                    ?w['provider_uuid'] as String?,
                    ?w['error'] as String?,
                  ].join(' · '),
                ),
              ),
          ],
        );
      },
    );
  }
}
