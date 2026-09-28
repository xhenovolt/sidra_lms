import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/finance_repository.dart';
import 'admin_common.dart';
import 'courses_tab.dart' show courseNotificationKinds, notificationKindLabel;
import 'marzpay_test_screen.dart';

final orgSettingsAdminProvider =
    FutureProvider.autoDispose<Map<String, String?>>(
      (ref) => ref.watch(financeRepositoryProvider).settings(),
    );

/// Organisation details learners see (name, support contacts, how to pay)
/// and switches such as MarzPay payments. Needs settings.manage.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(orgSettingsAdminProvider);
    return switch (settings) {
      AsyncData(:final value) => _SettingsForm(values: value),
      AsyncError(:final error) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(orgSettingsAdminProvider),
      ),
      _ => const LoadingView(),
    };
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.values});
  final Map<String, String?> values;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  static const _textKeys = [
    'org_name',
    'currency',
    'support_phone',
    'support_email',
    'bank_instructions',
    'mobile_money_instructions',
  ];
  late final _controllers = {
    for (final k in _textKeys)
      k: TextEditingController(text: widget.values[k] ?? ''),
  };
  late bool _marzpay = widget.values['marzpay_enabled'] != 'false';

  /// Notification kinds switched on for every course (`notify_<kind>`).
  static const _notifyKinds = [...courseNotificationKinds, 'resubmission'];
  late final Map<String, bool> _notify = {
    for (final k in _notifyKinds) k: widget.values['notify_$k'] != 'false',
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(financeRepositoryProvider);
    setState(() => _saving = true);
    final ok = await runAdminAction(context, () async {
      for (final k in _textKeys) {
        final v = _controllers[k]!.text.trim();
        if (v != (widget.values[k] ?? '')) {
          await repo.setSetting(k, v.isEmpty ? null : v);
        }
      }
      final m = _marzpay ? 'true' : 'false';
      if (m != (widget.values['marzpay_enabled'] ?? 'true')) {
        await repo.setSetting('marzpay_enabled', m);
      }
      for (final e in _notify.entries) {
        final v = e.value ? 'true' : 'false';
        if (v != (widget.values['notify_${e.key}'] ?? 'true')) {
          await repo.setSetting('notify_${e.key}', v);
        }
      }
    }, success: l10n.adminSaved);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) ref.invalidate(orgSettingsAdminProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget field(String key, String label, {String? hint, int lines = 1}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: TextField(
            controller: _controllers[key],
            maxLines: lines,
            decoration: InputDecoration(labelText: label, hintText: hint),
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        Text(l10n.settingsTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: Space.md),
        field('org_name', l10n.settingsOrgName),
        field('currency', l10n.settingsCurrency, hint: 'UGX'),
        field('support_phone', l10n.settingsSupportPhone),
        field('support_email', l10n.settingsSupportEmail),
        field(
          'bank_instructions',
          l10n.settingsBank,
          hint: l10n.settingsBankHint,
          lines: 3,
        ),
        field('mobile_money_instructions', l10n.settingsMobileMoney, lines: 3),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _marzpay,
          onChanged: (v) => setState(() => _marzpay = v),
          title: Text(l10n.settingsMarzPay),
          subtitle: Text(l10n.settingsMarzPayHint),
        ),
        const SizedBox(height: Space.md),
        Text(l10n.settingsNotifications, style: theme.textTheme.titleMedium),
        Text(l10n.settingsNotificationsHint, style: theme.textTheme.bodySmall),
        for (final k in _notifyKinds)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _notify[k]!,
            onChanged: (v) => setState(() => _notify[k] = v),
            title: Text(notificationKindLabel(l10n, k)),
          ),
        const SizedBox(height: Space.md),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.adminSave),
        ),
        const SizedBox(height: Space.lg),
        Text(l10n.settingsPayments, style: theme.textTheme.titleMedium),
        const PaymentIntegrationCard(),
      ],
    );
  }
}
