import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';

final paymentIntegrationProvider = FutureProvider.autoDispose<Map?>(
  (ref) async =>
      await ref.watch(postgresApiProvider).rpc('payment_integration_status')
          as Map?,
);

/// Settings card: is the payments server running, and a way to test MarzPay.
class PaymentIntegrationCard extends ConsumerWidget {
  const PaymentIntegrationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(paymentIntegrationProvider).value;
    final online = status?['server_online'] == true;
    return Card(
      child: ListTile(
        leading: Icon(
          online ? Icons.check_circle : Icons.cloud_off,
          color: online
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        title: Text(l10n.marzTitle),
        subtitle: Text(online ? l10n.marzServerOnline : l10n.marzServerOffline),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MarzPayTestScreen()),
        ),
      ),
    );
  }
}

/// Admin → Settings → Payments (MarzPay) → Test integration.
/// The tests run on the payments server (the only place with the MarzPay
/// secret) and report PASS / WARNING / FAIL. No money moves.
class MarzPayTestScreen extends ConsumerStatefulWidget {
  const MarzPayTestScreen({super.key});

  @override
  ConsumerState<MarzPayTestScreen> createState() => _MarzPayTestScreenState();
}

class _MarzPayTestScreenState extends ConsumerState<MarzPayTestScreen> {
  String? _runId;
  Timer? _poll;
  bool _timedOut = false;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    final l10n = AppLocalizations.of(context);
    try {
      final id = await ref
          .read(postgresApiProvider)
          .rpc('request_payment_diagnostics');
      setState(() {
        _runId = '$id';
        _timedOut = false;
      });
      final started = DateTime.now();
      _poll?.cancel();
      _poll = Timer.periodic(const Duration(seconds: 2), (_) {
        ref.invalidate(paymentIntegrationProvider);
        final latest =
            ref.read(paymentIntegrationProvider).value?['latest_run'] as Map?;
        if (latest?['id'] == _runId && latest?['status'] == 'done') {
          _poll?.cancel();
          setState(() => _runId = null);
        } else if (DateTime.now().difference(started).inSeconds > 60) {
          _poll?.cancel();
          setState(() {
            _runId = null;
            _timedOut = true;
          });
        }
      });
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ForbiddenFailure ? l10n.adminNotAllowed : l10n.genericError,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = ref.watch(paymentIntegrationProvider);
    final s = status.value;
    final latest = s?['latest_run'] as Map?;
    final results = (latest?['results'] as List?) ?? const [];
    final running = _runId != null;
    final when = DateFormat.yMMMd(l10n.localeName).add_jms();
    final lastSeen = DateTime.tryParse('${s?['server_last_seen'] ?? ''}');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.marzTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(paymentIntegrationProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  s?['server_online'] == true ? Icons.dns : Icons.cloud_off,
                ),
                title: Text(
                  s?['server_online'] == true
                      ? l10n.marzServerOnline
                      : l10n.marzServerOffline,
                ),
                subtitle: Text(
                  [
                    if (lastSeen != null)
                      l10n.marzLastSeen(when.format(lastSeen.toLocal())),
                    if (s?['server_version'] != null)
                      'v${s!['server_version']}',
                    if (s?['server_public_url'] != null)
                      '${s!['server_public_url']}',
                  ].join(' · '),
                ),
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(l10n.marzExplain, style: theme.textTheme.bodySmall),
            const SizedBox(height: Space.md),
            FilledButton.icon(
              onPressed: running ? null : _run,
              icon: running
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(running ? l10n.marzRunning : l10n.marzRunTests),
            ),
            if (_timedOut)
              Padding(
                padding: const EdgeInsets.only(top: Space.sm),
                child: Text(
                  l10n.marzNoAnswer,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (latest != null && latest['status'] == 'done') ...[
              const SizedBox(height: Space.md),
              Text(
                l10n.marzResultsFrom(
                  when.format(
                    DateTime.parse('${latest['finished_at']}').toLocal(),
                  ),
                ),
                style: theme.textTheme.titleSmall,
              ),
              for (final r in results.cast<Map>())
                Card(
                  child: ListTile(
                    leading: _ResultBadge(result: '${r['result']}'),
                    title: Text('${r['label']}'),
                    subtitle: Text('${r['message']}'),
                  ),
                ),
            ],
            if (status.hasError)
              ErrorView(
                error: status.error!,
                onRetry: () => ref.invalidate(paymentIntegrationProvider),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.result});
  final String result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color, icon) = switch (result) {
      'pass' => ('PASS', scheme.primary, Icons.check_circle),
      'warning' => ('WARNING', Colors.orange.shade800, Icons.warning_amber),
      _ => ('FAIL', scheme.error, Icons.cancel),
    };
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
