import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../about/presentation/about_screen.dart' show packageInfoProvider;
import '../data/finance_repository.dart';
import 'admin_common.dart';
import 'courses_tab.dart' show courseNotificationKinds, notificationKindLabel;
import 'export_screen.dart';
import 'languages_tracks_screen.dart';
import 'marzpay_test_screen.dart';

final orgSettingsAdminProvider =
    FutureProvider.autoDispose<Map<String, String?>>(
      (ref) => ref.watch(financeRepositoryProvider).settings(),
    );

/// Everything an organisation runs on without a developer: its name and
/// contacts, how to pay, who may sign up, password and lock-out rules,
/// teaching defaults, notifications, app updates, languages and tracks,
/// and data export. Needs settings.manage.
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
    'org_name_ar',
    'currency',
    'support_phone',
    'support_email',
    'bank_instructions',
    'mobile_money_instructions',
    'min_password_length',
    'lockout_attempts',
    'lockout_minutes',
    'attention_stale_days',
    'falling_behind_portions',
    'latest_app_version',
    'latest_app_build',
    'app_download_url',
    'min_supported_build',
  ];

  /// On/off settings and what they are when never set.
  static const _switchDefaults = {
    'marzpay_enabled': true,
    'allow_self_signup': true,
  };

  late final _controllers = {
    for (final k in _textKeys)
      k: TextEditingController(text: widget.values[k] ?? ''),
  };
  late final Map<String, bool> _switches = {
    for (final e in _switchDefaults.entries)
      e.key: switch (widget.values[e.key]) {
        'true' => true,
        'false' => false,
        _ => e.value,
      },
  };
  late String _defaultRule =
      widget.values['default_progression'] ?? 'teacher_gated';
  late int _defaultPassMark =
      int.tryParse(widget.values['default_pass_mark'] ?? '') ?? 70;

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
    // Each value is checked by the server; the first bad one stops the
    // save with its reason, and everything before it is kept.
    final ok = await runAdminAction(context, () async {
      Future<void> put(String key, String? value) async {
        if (value != widget.values[key]) await repo.setSetting(key, value);
      }

      for (final k in _textKeys) {
        final v = _controllers[k]!.text.trim();
        if (v != (widget.values[k] ?? '')) {
          await repo.setSetting(k, v.isEmpty ? null : v);
        }
      }
      for (final e in _switches.entries) {
        final v = e.value ? 'true' : 'false';
        final was = widget.values[e.key] ?? '${_switchDefaults[e.key]}';
        if (v != was) await repo.setSetting(e.key, v);
      }
      await put('default_progression', _defaultRule);
      await put('default_pass_mark', '$_defaultPassMark');
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
    final info = ref.watch(packageInfoProvider).value;
    Widget field(
      String key,
      String label, {
      String? hint,
      String? helper,
      int lines = 1,
      bool number = false,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: TextField(
        controller: _controllers[key],
        maxLines: lines,
        keyboardType: number ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          helperMaxLines: 3,
        ),
      ),
    );
    Widget toggle(String key, String title, {String? subtitle}) =>
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _switches[key]!,
          onChanged: (v) => setState(() => _switches[key] = v),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
        );
    Widget section(String title, [String? hint]) => Padding(
      padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (hint != null) Text(hint, style: theme.textTheme.bodySmall),
        ],
      ),
    );
    final rules = [
      ('after_approval', l10n.ruleApproval),
      ('after_submission', l10n.ruleSubmission),
      ('teacher_gated', l10n.adminProgressionTeacher),
      ('sequential', l10n.adminProgressionSequential),
      ('open', l10n.adminProgressionOpen),
    ];

    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        Text(l10n.settingsTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: Space.md),
        field('org_name', l10n.settingsOrgName),
        field('org_name_ar', l10n.settingsOrgNameAr),
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
        toggle(
          'marzpay_enabled',
          l10n.settingsMarzPay,
          subtitle: l10n.settingsMarzPayHint,
        ),

        section(l10n.settingsSignupSecurity),
        toggle(
          'allow_self_signup',
          l10n.settingsAllowSignup,
          subtitle: l10n.settingsAllowSignupHint,
        ),
        field('min_password_length', l10n.settingsMinPassword, number: true),
        field('lockout_attempts', l10n.settingsLockoutAttempts, number: true),
        field('lockout_minutes', l10n.settingsLockoutMinutes, number: true),

        section(
          l10n.settingsTeachingDefaults,
          l10n.settingsTeachingDefaultsHint,
        ),
        field('attention_stale_days', l10n.settingsStaleDays, number: true),
        field(
          'falling_behind_portions',
          l10n.settingsFallingBehind,
          number: true,
        ),
        DropdownButtonFormField<String>(
          initialValue: rules.any((r) => r.$1 == _defaultRule)
              ? _defaultRule
              : 'teacher_gated',
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.settingsDefaultRule),
          items: [
            for (final (value, label) in rules)
              DropdownMenuItem(value: value, child: Text(label)),
          ],
          onChanged: (v) => setState(() => _defaultRule = v ?? _defaultRule),
        ),
        const SizedBox(height: Space.sm),
        Text(
          l10n.settingsDefaultPassMark(_defaultPassMark),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _defaultPassMark.toDouble(),
          max: 100,
          divisions: 20,
          label: '$_defaultPassMark%',
          onChanged: (v) => setState(() => _defaultPassMark = v.round()),
        ),

        section(l10n.settingsNotifications, l10n.settingsNotificationsHint),
        for (final k in _notifyKinds)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _notify[k]!,
            onChanged: (v) => setState(() => _notify[k] = v),
            title: Text(notificationKindLabel(l10n, k)),
          ),

        section(l10n.settingsAppUpdates, l10n.settingsAppUpdatesHint),
        if (info != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Text(
              l10n.settingsThisBuild(info.version, info.buildNumber),
              style: theme.textTheme.bodySmall,
            ),
          ),
        field('latest_app_version', l10n.settingsLatestVersion),
        field('latest_app_build', l10n.settingsLatestBuild, number: true),
        field('app_download_url', l10n.settingsDownloadUrl),
        field(
          'min_supported_build',
          l10n.settingsMinBuild,
          helper: l10n.settingsMinBuildHint,
          number: true,
        ),
        const SizedBox(height: Space.md),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.adminSave),
        ),
        const SizedBox(height: Space.lg),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.translate),
                title: Text(l10n.settingsLanguagesTracks),
                subtitle: Text(l10n.settingsLanguagesTracksHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LanguagesTracksScreen(),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: Text(l10n.settingsExport),
                subtitle: Text(l10n.settingsExportHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ExportScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        Text(l10n.settingsPayments, style: theme.textTheme.titleMedium),
        const PaymentIntegrationCard(),
      ],
    );
  }
}
