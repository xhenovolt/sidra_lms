import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';

import '../../../../core/data/data_providers.dart';
import '../../../../core/device/device_profile.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/json.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../about/presentation/about_screen.dart' show packageInfoProvider;
import '../../../auth/presentation/auth_providers.dart';
import '../../../content/data/submission_queue.dart';
import '../admin_common.dart';
import '../export_screen.dart';
import '../languages_tracks_screen.dart';
import '../marzpay_test_screen.dart' show MarzPayTestScreen;
import '../sessions_screens.dart';
import '../settings_screen.dart'
    show HolidaysScreen, PolicyPause, orgSettingsAdminProvider;
import 'marzpay_center.dart';
import 'settings_registry.dart';

/// The database migration this app version was built for. The Database
/// section compares it with what the database actually has.
const expectedMigration = '0040_settings_validation.sql';

final systemHealthProvider = FutureProvider.autoDispose<Json>(
  (ref) async => Json.from(
    (await ref.watch(postgresApiProvider).rpc('system_health')) as Map,
  ),
);

final _lastChangesProvider = FutureProvider.autoDispose<Map<String, Json>>((
  ref,
) async {
  final rows = await ref
      .watch(postgresApiProvider)
      .rpcRows('settings_last_changes');
  return {for (final r in rows) '${r['key']}': Json.from(r)};
});

String _when(AppLocalizations l, Object? v) {
  final d = v == null ? null : DateTime.tryParse('$v');
  return d == null
      ? '—'
      : DateFormat.yMMMd(l.localeName).add_jm().format(d.toLocal());
}

// ============================================================ status chip ==

enum Health { ok, warning, failed, untested, disabled }

class HealthChip extends StatelessWidget {
  const HealthChip(this.health, {super.key, this.label});
  final Health health;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (color, text) = switch (health) {
      Health.ok => (Colors.green.shade700, l.ccOk),
      Health.warning => (Colors.orange.shade800, l.ccWarning),
      Health.failed => (scheme.error, l.ccFailed),
      Health.untested => (scheme.outline, l.ccUntested),
      Health.disabled => (scheme.outline, l.ccDisabled),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label ?? text,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ========================================================= control centre ==

/// Admin → Settings: health at a glance, search, and every section.
class ControlCenterScreen extends ConsumerStatefulWidget {
  const ControlCenterScreen({super.key});

  @override
  ConsumerState<ControlCenterScreen> createState() =>
      _ControlCenterScreenState();
}

class _ControlCenterScreenState extends ConsumerState<ControlCenterScreen> {
  String _query = '';

  void _openSection(SettingsSection s, [String? focus]) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SettingsSectionScreen(section: s, focusKey: focus),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final health = ref.watch(systemHealthProvider);
    final q = _query.trim();
    return RefreshIndicator(
      onRefresh: () => ref.refresh(systemHealthProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          Text(l.settingsTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.ccSearchHint,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: Space.md),
          if (q.isNotEmpty) ...[
            for (final d in settingsRegistry.where((d) => d.matches(l, q)))
              ListTile(
                leading: Icon(d.section.icon),
                title: Text(d.label(l)),
                subtitle: Text(d.section.title(l)),
                onTap: () => _openSection(d.section, d.key),
              ),
            for (final t in settingsTools.where(
              (t) => '${t.label(l)} ${t.keywords} ${t.section.title(l)}'
                  .toLowerCase()
                  .contains(q.toLowerCase()),
            ))
              ListTile(
                leading: Icon(t.icon),
                title: Text(t.label(l)),
                subtitle: Text(t.section.title(l)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openSettingsTool(context, ref, t.id),
              ),
            for (final s in SettingsSection.values.where(
              (s) => s.title(l).toLowerCase().contains(q.toLowerCase()),
            ))
              ListTile(
                leading: Icon(s.icon),
                title: Text(s.title(l)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openSection(s),
              ),
          ] else ...[
            Text(l.ccHealthTitle, style: theme.textTheme.titleMedium),
            Text(l.ccHealthHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: Space.xs),
            switch (health) {
              AsyncData(:final value) => _HealthGrid(
                health: value,
                onOpen: _openSection,
              ),
              AsyncError(:final error) => Text(
                error is ForbiddenFailure ? l.ccHealthNoPermission : '$error',
                style: theme.textTheme.bodySmall,
              ),
              _ => const LinearProgressIndicator(),
            },
            const SizedBox(height: Space.lg),
            Text(l.ccSections, style: theme.textTheme.titleMedium),
            for (final s in SettingsSection.values)
              Card(
                child: ListTile(
                  leading: Icon(s.icon),
                  title: Text(s.title(l)),
                  subtitle: Text(
                    s.hint(l),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openSection(s),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// MarzPay's honest state: never "ON" without evidence.
(Health, String) marzpayState(AppLocalizations l, Json h) {
  final m = h.obj('marzpay');
  final tests = m.obj('latest_tests');
  String? res(String k) => (tests[k] as Map?)?['result'] as String?;
  if (m['enabled'] != true) return (Health.disabled, l.ccMarzDisabled);
  if (res('connection') == 'failed') return (Health.failed, l.ccMarzConnFailed);
  if (h.obj('payments_server')['online'] != true) {
    return (Health.failed, l.ccMarzServerDown);
  }
  if (res('collection') == 'verified_success' ||
      (m['verified_payments'] as num? ?? 0) > 0) {
    return (
      (m['stuck'] as num? ?? 0) > 0 ? Health.warning : Health.ok,
      l.ccMarzVerified,
    );
  }
  if (res('connection') == 'verified_success') {
    return (Health.warning, l.ccMarzAuthOnly);
  }
  return (Health.untested, l.ccMarzUntested);
}

class _HealthGrid extends ConsumerWidget {
  const _HealthGrid({required this.health, required this.onOpen});
  final Json health;
  final void Function(SettingsSection) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final h = health;
    final db = h.obj('database');
    final server = h.obj('payments_server');
    final storage = h.obj('storage');
    final notes = h.obj('notifications');
    final sec = h.obj('security');
    final learn = h.obj('learning');
    final pay = h.obj('payments');
    final app = h.obj('app');
    final info = ref.watch(packageInfoProvider).value;
    final latest = int.tryParse('${app['latest_build'] ?? ''}');
    final mine = int.tryParse(info?.buildNumber ?? '');
    final dbMigration = '${db['latest_migration'] ?? ''}';
    final marz = marzpayState(l, h);
    final cards = <(SettingsSection, IconData, String, Health, String)>[
      (
        SettingsSection.database,
        Icons.storage_outlined,
        l.ccDatabase,
        dbMigration.compareTo(expectedMigration) < 0
            ? Health.warning
            : Health.ok,
        l.ccDbLine(
          dbMigration.split('_').first,
          expectedMigration.split('_').first,
        ),
      ),
      (
        SettingsSection.payments,
        Icons.dns_outlined,
        l.ccPaymentsServer,
        server['online'] == true ? Health.ok : Health.failed,
        server['online'] == true
            ? l.ccServerOnline(server['version'] ?? '?')
            : server['last_seen'] == null
            ? l.ccServerNever
            : l.ccServerLastSeen(_when(l, server['last_seen'])),
      ),
      (
        SettingsSection.marzpay,
        Icons.phone_android_outlined,
        l.marzTitle,
        marz.$1,
        marz.$2,
      ),
      (
        SettingsSection.storage,
        Icons.cloud_outlined,
        l.ccStorage,
        storage['configured'] == true ? Health.ok : Health.failed,
        storage['configured'] == true
            ? l.ccStorageLine(
                storage['uploads_24h'] ?? 0,
                _when(l, storage['last_upload']),
              )
            : l.ccStorageMissing,
      ),
      (
        SettingsSection.notifications,
        Icons.notifications_outlined,
        l.settingsNotifications,
        (notes['devices_blocking'] as num? ?? 0) > 0
            ? Health.warning
            : Health.ok,
        l.ccNotifLine(
          notes['sent_24h'] ?? 0,
          notes['phones_registered'] ?? 0,
          notes['devices_blocking'] ?? 0,
        ),
      ),
      (
        SettingsSection.security,
        Icons.shield_outlined,
        l.ccSecurity,
        (sec['locked_now'] as num? ?? 0) > 0 ||
                (sec['failed_sign_ins_24h'] as num? ?? 0) > 20 ||
                (sec['accounts_on_many_devices'] as num? ?? 0) > 0
            ? Health.warning
            : Health.ok,
        l.ccSecurityLine(
          sec['failed_sign_ins_24h'] ?? 0,
          sec['locked_now'] ?? 0,
          sec['accounts_on_many_devices'] ?? 0,
        ),
      ),
      (
        SettingsSection.learners,
        Icons.school_outlined,
        l.ccLearning,
        (learn['open_problem_reports'] as num? ?? 0) +
                    (learn['late_work'] as num? ?? 0) +
                    (learn['waiting_review_48h'] as num? ?? 0) >
                0
            ? Health.warning
            : Health.ok,
        l.ccLearningLine(
          learn['active_learners_7d'] ?? 0,
          learn['open_problem_reports'] ?? 0,
          learn['late_work'] ?? 0,
          learn['waiting_review_48h'] ?? 0,
        ),
      ),
      (
        SettingsSection.payments,
        Icons.payments_outlined,
        l.settingsPayments,
        (pay['stuck_mobile_money'] as num? ?? 0) > 0 ||
                (pay['manual_waiting'] as num? ?? 0) > 0
            ? Health.warning
            : Health.ok,
        l.ccPaymentsLine(
          pay['manual_waiting'] ?? 0,
          pay['stuck_mobile_money'] ?? 0,
        ),
      ),
      (
        SettingsSection.application,
        Icons.system_update_outlined,
        l.ccApplication,
        latest != null && mine != null && mine < latest
            ? Health.warning
            : Health.ok,
        l.ccAppLine(
          info?.version ?? '?',
          info?.buildNumber ?? '?',
          app['latest_build'] ?? '—',
        ),
      ),
      (
        SettingsSection.advanced,
        Icons.health_and_safety_outlined,
        l.ccDiagnostics,
        (h['recent_failed_diagnostics'] as num? ?? 0) > 0
            ? Health.failed
            : Health.ok,
        l.ccDiagLine(h['recent_failed_diagnostics'] ?? 0),
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth >= 700
            ? (box.maxWidth - Space.sm) / 2
            : box.maxWidth;
        return Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final (section, icon, title, state, line) in cards)
              SizedBox(
                width: width,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(icon),
                    title: Row(
                      children: [
                        Expanded(child: Text(title)),
                        HealthChip(state),
                      ],
                    ),
                    subtitle: Text(line),
                    onTap: () => onOpen(section),
                  ),
                ),
              ),
            Text(
              l.ccCheckedAt(_when(l, h['checked_at'])),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        );
      },
    );
  }
}

/// Opens a tool by id (used by sections and search).
void openSettingsTool(BuildContext context, WidgetRef ref, String id) {
  void push(Widget w) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
  switch (id) {
    case 'presence':
      push(const PresenceScreen());
    case 'security_events':
      push(const SecurityEventsScreen());
    case 'my_devices':
      push(const DevicesScreen());
    case 'holidays':
      push(const HolidaysScreen());
    case 'late_work':
      context.push('/teach/late');
    case 'issues':
      context.push('/teach/issues');
    case 'languages':
      push(const LanguagesTracksScreen());
    case 'test_notification':
      push(const DiagnosticsScreen(only: 'notifications'));
    case 'payment_trace':
      push(const PaymentTraceScreen());
    case 'marzpay_center':
      push(const MarzPayCenterScreen());
    case 'marzpay_selfcheck':
      push(const MarzPayTestScreen());
    case 'diagnostics':
      push(const DiagnosticsScreen());
    case 'settings_history':
      push(const SettingsHistoryScreen());
    case 'export':
      push(const ExportScreen());
  }
}

// ================================================================ section ==

/// One section: its status, its settings (each showing who last changed
/// it), a reason for the change, and its tools.
class SettingsSectionScreen extends ConsumerStatefulWidget {
  const SettingsSectionScreen({
    super.key,
    required this.section,
    this.focusKey,
  });
  final SettingsSection section;
  final String? focusKey;

  @override
  ConsumerState<SettingsSectionScreen> createState() =>
      _SettingsSectionScreenState();
}

class _SettingsSectionScreenState extends ConsumerState<SettingsSectionScreen> {
  final _edits = <String, String?>{};
  final _errors = <String, String>{};
  final _reason = TextEditingController();
  final _controllers = <String, TextEditingController>{};
  bool _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(Map<String, String?> values) async {
    final l = AppLocalizations.of(context);
    final api = ref.read(postgresApiProvider);
    setState(() {
      _saving = true;
      _errors.clear();
    });
    final saved = <String>[];
    for (final e in _edits.entries) {
      try {
        await api.rpc(
          'set_org_setting_reason',
          params: {
            'p_key': e.key,
            'p_value': (e.value ?? '').trim().isEmpty ? null : e.value!.trim(),
            'p_reason': _reason.text.trim(),
          },
        );
        saved.add(e.key);
      } on AppFailure catch (f) {
        _errors[e.key] = f.message;
      }
    }
    if (!mounted) return;
    setState(() {
      for (final k in saved) {
        _edits.remove(k);
      }
      _saving = false;
      if (_edits.isEmpty) _reason.clear();
    });
    ref.invalidate(orgSettingsAdminProvider);
    ref.invalidate(_lastChangesProvider);
    ref.invalidate(systemHealthProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _errors.isEmpty
              ? l.ccSaved(saved.length)
              : l.ccSavedSome(saved.length, _errors.length),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = widget.section;
    final values = ref.watch(orgSettingsAdminProvider);
    final changes = ref.watch(_lastChangesProvider).value ?? const {};
    final defs = settingsRegistry.where((d) => d.section == s).toList();
    final tools = settingsTools.where((t) => t.section == s).toList();
    return Scaffold(
      appBar: AppBar(title: Text(s.title(l))),
      bottomNavigationBar: _edits.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _reason,
                        decoration: InputDecoration(
                          labelText: l.ccReason,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    FilledButton(
                      onPressed: _saving || values.value == null
                          ? null
                          : () => _save(values.value!),
                      child: Text(l.ccSaveChanges(_edits.length)),
                    ),
                  ],
                ),
              ),
            ),
      body: switch (values) {
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(orgSettingsAdminProvider),
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            Text(s.hint(l), style: theme.textTheme.bodyMedium),
            const SizedBox(height: Space.sm),
            _SectionStatus(section: s),
            for (final d in defs) _field(l, theme, d, value, changes[d.key]),
            if (s == SettingsSection.learners)
              PolicyPause(
                pausedUntil: DateTime.tryParse(
                  value['policy_paused_until'] ?? '',
                ),
                lastRun: DateTime.tryParse(value['policy_last_run'] ?? ''),
              ),
            if (tools.isNotEmpty) ...[
              const SizedBox(height: Space.md),
              for (final t in tools)
                Card(
                  child: ListTile(
                    leading: Icon(t.icon),
                    title: Text(t.label(l)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openSettingsTool(context, ref, t.id),
                  ),
                ),
            ],
            const SizedBox(height: 80),
          ],
        ),
        _ => const LoadingView(),
      },
    );
  }

  Widget _field(
    AppLocalizations l,
    ThemeData theme,
    SettingDef d,
    Map<String, String?> values,
    Json? change,
  ) {
    final current = _edits.containsKey(d.key) ? _edits[d.key] : values[d.key];
    final error = _errors[d.key];
    final focused = widget.focusKey == d.key;
    void set(String? v) => setState(() {
      if (v == values[d.key] || (v ?? '') == (values[d.key] ?? '')) {
        _edits.remove(d.key);
      } else {
        _edits[d.key] = v;
      }
      _errors.remove(d.key);
    });
    final Widget input = switch (d.type) {
      SettingType.toggle => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: switch (current) {
          'true' => true,
          'false' => false,
          _ => d.defaultOn,
        },
        onChanged: (v) => set('$v'),
        title: Text(d.label(l)),
        subtitle: d.help == null ? null : Text(d.help!(l)),
      ),
      SettingType.choice => DropdownButtonFormField<String>(
        initialValue: d.options.containsKey(current) ? current : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: d.label(l),
          helperText: d.help?.call(l),
        ),
        items: [
          for (final e in d.options.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value(l))),
        ],
        onChanged: set,
      ),
      _ => TextField(
        controller: _controllers.putIfAbsent(
          d.key,
          () => TextEditingController(text: current ?? ''),
        ),
        autofocus: focused,
        maxLines: d.type == SettingType.multiline ? 3 : 1,
        keyboardType: d.type == SettingType.number
            ? TextInputType.number
            : null,
        decoration: InputDecoration(
          labelText: d.label(l),
          helperText: [
            ?d.help?.call(l),
            if (d.min != null && d.max != null) l.ccRange(d.min!, d.max!),
          ].join(' '),
          helperMaxLines: 4,
          errorText: error,
          errorMaxLines: 3,
        ),
        onChanged: (v) {
          if (d.type == SettingType.number && v.trim().isNotEmpty) {
            final n = int.tryParse(v.trim());
            if (n == null ||
                (d.min != null && n < d.min!) ||
                (d.max != null && n > d.max!)) {
              setState(
                () => _errors[d.key] = l.ccRange(d.min ?? 0, d.max ?? 999999),
              );
              return;
            }
          }
          set(v);
        },
      ),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      decoration: focused
          ? BoxDecoration(
              border: Border.all(color: theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(Radii.md),
            )
          : null,
      padding: focused ? const EdgeInsets.all(Space.xs) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          input,
          if (d.type != SettingType.text &&
              d.type != SettingType.multiline &&
              d.type != SettingType.number &&
              error != null)
            Text(error, style: TextStyle(color: theme.colorScheme.error)),
          if (change != null)
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsHistoryScreen(settingKey: d.key),
                ),
              ),
              child: Text(
                [
                  l.ccLastChanged(
                    '${change['actor_name'] ?? l.ccSystem}',
                    _when(l, change['at']),
                  ),
                  if ((change['reason'] as String?)?.isNotEmpty ?? false)
                    '“${change['reason']}”',
                ].join(' · '),
                style: theme.textTheme.labelSmall?.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Live status shown at the top of a section.
class _SectionStatus extends ConsumerWidget {
  const _SectionStatus({required this.section});
  final SettingsSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final h = ref.watch(systemHealthProvider).value;
    Widget card(List<(String, String)> rows) => Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          children: [
            for (final (k, v) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(k, style: theme.textTheme.bodySmall),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(v, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    if (h == null) return const SizedBox.shrink();
    switch (section) {
      case SettingsSection.database:
        final db = h.obj('database');
        return card([
          (l.ccDbConnected, l.ccYes),
          (l.ccDbLatest, '${db['latest_migration']}'),
          (l.ccDbAppExpects, expectedMigration),
          (l.ccDbCount, '${db['migrations']}'),
          (l.ccDbBackups, l.ccDbBackupsHint),
        ]);
      case SettingsSection.storage:
        final s = h.obj('storage');
        return card([
          (l.ccStorageProvider, 'Cloudinary'),
          (l.ccConfigured, s['configured'] == true ? l.ccYes : l.ccNo),
          (l.ccLastUpload, _when(l, s['last_upload'])),
          (l.ccUploads24h, '${s['uploads_24h']}'),
          (l.ccPurgeWaiting, '${s['purge_waiting']}'),
        ]);
      case SettingsSection.marzpay || SettingsSection.payments:
        final m = h.obj('marzpay');
        final server = h.obj('payments_server');
        final state = marzpayState(l, h);
        return card([
          (l.marzTitle, state.$2),
          (
            l.ccPaymentsServer,
            server['online'] == true
                ? l.ccServerOnline(server['version'] ?? '?')
                : l.ccServerLastSeen(_when(l, server['last_seen'])),
          ),
          (
            l.ccPublicAddress,
            server['public_url'] == true ? l.ccYes : l.ccNoPollingOnly,
          ),
          (l.ccVerifiedPayments, '${m['verified_payments']}'),
          (l.ccStuckPayments, '${m['stuck']}'),
        ]);
      case SettingsSection.application:
        final app = h.obj('app');
        final info = ref.watch(packageInfoProvider).value;
        final builds = app.obj('builds_in_use');
        return card([
          (
            l.ccThisPhone,
            '${info?.version ?? '?'} (${info?.buildNumber ?? '?'})',
          ),
          (l.settingsLatestBuild, '${app['latest_build'] ?? '—'}'),
          (l.settingsMinBuild, '${app['min_supported_build'] ?? '—'}'),
          (
            l.ccBuildsInUse,
            builds.isEmpty
                ? '—'
                : builds.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
          ),
        ]);
      case SettingsSection.sync:
        return const _SyncStatus();
      case SettingsSection.security:
        final s = h.obj('security');
        return card([
          (l.ccFailedSignIns, '${s['failed_sign_ins_24h']}'),
          (l.ccThrottled, '${s['throttled_24h']}'),
          (l.ccLockedNow, '${s['locked_now']}'),
          (l.ccRevoked7d, '${s['devices_revoked_7d']}'),
          (l.ccManyDevices, '${s['accounts_on_many_devices']}'),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _SyncStatus extends ConsumerWidget {
  const _SyncStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sync = ref.watch(syncStatusProvider).value;
    final queued = ref.watch(submissionQueueProvider).value ?? const [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.ccSyncThisPhone,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              l.ccSyncLine(
                sync?.pending ?? 0,
                sync?.rejected ?? 0,
                queued.length,
              ),
            ),
            if (sync?.lastError != null) Text(sync!.lastError!.message),
            for (final q in queued)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${q.state} · ${q.files.length} file(s)'),
                subtitle: q.error == null ? null : Text(q.error!),
                trailing: TextButton(
                  onPressed: () =>
                      ref.read(submissionQueueProvider.notifier).retry(q.id),
                  child: Text(l.retry),
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () async {
                  await ref.read(submissionQueueProvider.notifier).flush();
                  final engine = await ref.read(syncEngineProvider.future);
                  await engine.run();
                },
                icon: const Icon(Icons.sync),
                label: Text(l.ccSyncNow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================ history ==

class SettingsHistoryScreen extends ConsumerStatefulWidget {
  const SettingsHistoryScreen({super.key, this.settingKey});
  final String? settingKey;

  @override
  ConsumerState<SettingsHistoryScreen> createState() =>
      _SettingsHistoryScreenState();
}

class _SettingsHistoryScreenState extends ConsumerState<SettingsHistoryScreen> {
  late String? _key = widget.settingKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = {for (final d in settingsRegistry) d.key: d.label(l)};
    return Scaffold(
      appBar: AppBar(title: Text(l.ccSettingsHistory)),
      body: FutureBuilder(
        future: ref
            .read(postgresApiProvider)
            .rpcRows(
              'settings_history',
              params: {'p_key': _key, 'p_limit': 200},
            ),
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorView(
              error: snap.error!,
              onRetry: () => setState(() {}),
            );
          }
          if (!snap.hasData) return const LoadingView();
          final rows = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(Space.md),
            children: [
              Text(
                l.ccHistoryHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_key != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: InputChip(
                    label: Text(labels[_key] ?? _key!),
                    onDeleted: () => setState(() => _key = null),
                  ),
                ),
              if (rows.isEmpty)
                EmptyView(icon: Icons.history, title: l.dashListEmpty),
              for (final r in rows)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tune),
                  title: Text(labels['${r['key']}'] ?? '${r['key']}'),
                  subtitle: Text(
                    [
                      '${_plain(r['from'])} → ${_plain(r['to'])}',
                      '${r['actor_name'] ?? l.ccSystem} · ${_when(l, r['at'])}',
                      if ((r['reason'] as String?)?.isNotEmpty ?? false)
                        '“${r['reason']}”',
                    ].join('\n'),
                  ),
                  onTap: () => setState(() => _key = '${r['key']}'),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _plain(Object? v) =>
      v == null ? '—' : (v is String ? v : jsonEncode(v));
}

// =============================================================== security ==

class SecurityEventsScreen extends ConsumerWidget {
  const SecurityEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.ccSecurityEvents)),
      body: FutureBuilder(
        future: ref
            .read(postgresApiProvider)
            .rpcRows('security_events', params: {'p_limit': 200}),
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorView(error: snap.error!, onRetry: () {});
          }
          if (!snap.hasData) return const LoadingView();
          final rows = snap.data!;
          if (rows.isEmpty) {
            return EmptyView(
              icon: Icons.verified_user_outlined,
              title: l.ccNoSecurityEvents,
            );
          }
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = rows[i];
              final known = r['known_account'] == true;
              return ListTile(
                leading: Icon(
                  '${r['kind']}'.contains('failed') ||
                          '${r['kind']}'.contains('throttled')
                      ? Icons.warning_amber
                      : Icons.logout,
                ),
                title: Text(authEventLabel(l, '${r['kind']}')),
                subtitle: Text(
                  [
                    known ? '${r['name'] ?? ''}' : l.ccUnknownAccount,
                    _when(l, r['at']),
                    ?r['actor_name'] as String?,
                  ].join(' · '),
                ),
                onTap: known
                    ? () => context.push('/teach/people/${r['user_id']}')
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

// ========================================================== payment trace ==

/// "I paid but Sidra says unpaid": follow one payment end to end.
class PaymentTraceScreen extends ConsumerStatefulWidget {
  const PaymentTraceScreen({super.key});

  @override
  ConsumerState<PaymentTraceScreen> createState() => _PaymentTraceScreenState();
}

class _PaymentTraceScreenState extends ConsumerState<PaymentTraceScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.ccPaymentTrace)),
      body: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          Text(l.ccTraceHint, style: theme.textTheme.bodySmall),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.ccTraceSearch,
            ),
            onSubmitted: (v) => setState(() => _q = v.trim()),
          ),
          const SizedBox(height: Space.sm),
          if (_q.length >= 3)
            FutureBuilder(
              key: ValueKey(_q),
              future: ref
                  .read(postgresApiProvider)
                  .rpcRows('payment_trace', params: {'p_query': _q}),
              builder: (context, snap) {
                if (snap.hasError) {
                  return ErrorView(
                    error: snap.error!,
                    onRetry: () => setState(() {}),
                  );
                }
                if (!snap.hasData) return const LinearProgressIndicator();
                if (snap.data!.isEmpty) {
                  return EmptyView(
                    icon: Icons.search_off,
                    title: l.ccTraceNone,
                  );
                }
                return Column(
                  children: [
                    for (final r in snap.data!) _TraceCard(r: Json.from(r)),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TraceCard extends ConsumerWidget {
  const _TraceCard({required this.r});
  final Json r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = r.obj('payment');
    final learner = r.obj('learner');
    final bal = r.obj('balance');
    final history = (r['history'] as List? ?? const []);
    final hooks = (r['webhooks'] as List? ?? const []);
    Widget line(String k, Object? v) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 130, child: Text(k, style: theme.textTheme.bodySmall)),
        Expanded(child: SelectableText('${v ?? '—'}')),
      ],
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${learner['name'] ?? '?'} · ${p['amount']} ${p['currency']}',
              style: theme.textTheme.titleMedium,
            ),
            Text('${r['course'] ?? ''}', style: theme.textTheme.bodySmall),
            const Divider(),
            Text(l.ccTraceStep1, style: theme.textTheme.labelLarge),
            line(l.ccTraceMethod, p['method']),
            line(l.ccTraceCreated, _when(l, p['created_at'])),
            line(l.ccTraceSidraId, p['id']),
            line(l.ccTraceReference, p['reference']),
            Text(l.ccTraceStep2, style: theme.textTheme.labelLarge),
            line(l.ccTraceProviderId, p['provider_uuid']),
            line(l.ccTraceProviderStatus, r['provider_status']),
            line(
              l.ccTraceAttempts,
              '${p['attempts']} · ${p['last_error'] ?? ''}',
            ),
            Text(l.ccTraceStep3, style: theme.textTheme.labelLarge),
            line(
              l.ccTraceCallbacks,
              hooks.isEmpty
                  ? l.ccTraceNoCallbacks
                  : hooks
                        .map(
                          (w) =>
                              '${(w as Map)['outcome']} ${_when(l, w['received_at'])}',
                        )
                        .join('\n'),
            ),
            Text(l.ccTraceStep4, style: theme.textTheme.labelLarge),
            line(
              l.ccTraceSidraStatus,
              '${p['status']}${p['status_reason'] == null ? '' : ' · ${p['status_reason']}'}',
            ),
            line(l.ccTraceVerifiedAt, _when(l, p['verified_at'])),
            line(
              l.ccTraceBalance,
              bal.isEmpty
                  ? '—'
                  : '${bal['outstanding']} ${bal['currency']} ${l.ccTraceOutstanding}',
            ),
            line(l.ccTraceEnrolment, r['enrolment']),
            if (history.isNotEmpty) ...[
              Text(l.ccTraceHistory, style: theme.textTheme.labelLarge),
              for (final h in history)
                Text(
                  '• ${_when(l, (h as Map)['at'])} ${h['action']} ${h['actor'] ?? ''}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
            if (p['method'] == 'marzpay' && p['provider_uuid'] != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  icon: const Icon(Icons.travel_explore),
                  label: Text(l.ccTraceAskMarzPay),
                  onPressed: () => startPaymentTest(
                    context,
                    ref,
                    'status_lookup',
                    {'query': p['provider_uuid']},
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================ diagnostics ==

class _DiagResult {
  _DiagResult(this.component, this.label);
  final String component;
  final String label;
  String result = 'running';
  String tested = '';
  String expected = '';
  String happened = '';
  String? next;
  int? ms;
}

/// Runs the checks a founder needs when something breaks, explains each,
/// and records the outcome.
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key, this.only});
  final String? only;

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  final _results = <_DiagResult>[];
  bool _running = false;

  Future<void> _run() async {
    final l = AppLocalizations.of(context);
    final api = ref.read(postgresApiProvider);
    setState(() {
      _running = true;
      _results.clear();
    });
    Future<void> check(
      String component,
      String label,
      String tested,
      String expected,
      Future<(String, String, String?)> Function() body,
    ) async {
      if (widget.only != null && widget.only != component) return;
      final r = _DiagResult(component, label)
        ..tested = tested
        ..expected = expected;
      setState(() => _results.add(r));
      final sw = Stopwatch()..start();
      try {
        final (result, happened, next) = await body().timeout(
          const Duration(seconds: 60),
        );
        r
          ..result = result
          ..happened = happened
          ..next = next;
      } catch (e) {
        r
          ..result = 'failed'
          ..happened = e is AppFailure ? e.message : '$e'
          ..next = l.diagNextCheckNetwork;
      }
      r.ms = sw.elapsedMilliseconds;
      if (mounted) setState(() {});
      try {
        await api.rpc(
          'record_diagnostic',
          params: {
            'p_component': component,
            'p_result': r.result,
            'p_tested': tested,
            'p_expected': expected,
            'p_happened': r.happened,
            'p_next_action': r.next,
            'p_latency_ms': r.ms,
            'p_device': '${(await DeviceProfile.collect())['model'] ?? ''}',
          },
        );
      } catch (_) {}
    }

    await check(
      'database',
      l.ccDatabase,
      l.diagDbTested,
      l.diagDbExpected,
      () async {
        final sw = Stopwatch()..start();
        await api.rpc('public_settings');
        return ('ok', l.diagDbHappened(sw.elapsedMilliseconds), null);
      },
    );
    await check(
      'session',
      l.diagSession,
      l.diagSessionTested,
      l.diagSessionExpected,
      () async {
        final t = await ref
            .read(authServiceProvider)
            .sessionToken(forceRefresh: true);
        return t == null
            ? ('failed', l.diagSessionNone, l.diagNextSignIn)
            : ('ok', l.diagSessionOk, null);
      },
    );
    await check(
      'device',
      l.diagDevice,
      l.diagDeviceTested,
      l.diagDeviceExpected,
      () async {
        final facts = await DeviceProfile.collect();
        await api.rpc(
          'report_device',
          params: {'p_device': facts, 'p_active': true},
        );
        final mine = (await api.rpcRows('user_devices'))
            .where((d) => d['this_device'] == true);
        final perms = [
          if (facts['notifications_allowed'] == 'false')
            l.deviceNotificationsOff,
          if (facts['microphone_allowed'] == 'false') l.deviceMicOff,
        ];
        return (
          mine.isEmpty
              ? 'warning'
              : perms.isEmpty
              ? 'ok'
              : 'warning',
          [
            mine.isEmpty
                ? l.diagDeviceNotLinked
                : l.diagDeviceLinked(
                    '${facts['model'] ?? '?'}',
                    '${facts['app_version'] ?? '?'}',
                  ),
            ...perms,
          ].join(' · '),
          perms.isEmpty ? null : l.diagNextPermissions,
        );
      },
    );
    await check(
      'storage',
      l.ccStorage,
      l.diagStorageTested,
      l.diagStorageExpected,
      () async {
        final me = ref.read(authSessionProvider).user!;
        final dir = await getTemporaryDirectory();
        final text = 'Sidra diagnostic ${DateTime.now().toIso8601String()}';
        final file = File(
          '${dir.path}${Platform.pathSeparator}sidra_diagnostic.txt',
        )..writeAsStringSync(text);
        final id = await ref
            .read(adminRepositoryProvider)
            .uploadMedia(
              filePath: file.path,
              fileName: 'sidra_diagnostic.txt',
              kind: 'document',
              uploaderId: me.id,
              folder: 'diagnostics',
            );
        final url =
            (await api.rpc('media_url', params: {'p_asset_id': id})) as String;
        final got = await Dio().get<String>(
          url,
          options: Options(responseType: ResponseType.plain),
        );
        return got.data == text
            ? ('ok', l.diagStorageOk, null)
            : ('failed', l.diagStorageMismatch, l.diagNextStorage);
      },
    );
    await check(
      'notifications',
      l.settingsNotifications,
      l.diagNotifTested,
      l.diagNotifExpected,
      () async {
        await api.rpc('send_test_notification');
        return ('ok', l.diagNotifSent, l.diagNotifNext);
      },
    );
    await check(
      'sync',
      l.ccSync,
      l.diagSyncTested,
      l.diagSyncExpected,
      () async {
        final s = ref.read(syncStatusProvider).value;
        final q = ref.read(submissionQueueProvider).value ?? const [];
        final stuck = q.where((e) => e.state == 'failed').length;
        return (
          stuck > 0 || (s?.rejected ?? 0) > 0 ? 'warning' : 'ok',
          l.ccSyncLine(s?.pending ?? 0, s?.rejected ?? 0, q.length),
          stuck > 0 ? l.diagNextSync : null,
        );
      },
    );
    await check(
      'payments_server',
      l.ccPaymentsServer,
      l.diagServerTested,
      l.diagServerExpected,
      () async {
        ref.invalidate(systemHealthProvider);
        final h = await ref.read(systemHealthProvider.future);
        final s = h.obj('payments_server');
        return s['online'] == true
            ? ('ok', l.ccServerOnline(s['version'] ?? '?'), null)
            : (
                'failed',
                s['last_seen'] == null
                    ? l.ccServerNever
                    : l.ccServerLastSeen(_when(l, s['last_seen'])),
                l.diagNextServer,
              );
      },
    );
    await check(
      'marzpay',
      l.marzTitle,
      l.diagMarzTested,
      l.diagMarzExpected,
      () async {
        final h = await ref.read(systemHealthProvider.future);
        final state = marzpayState(l, h);
        return (
          switch (state.$1) {
            Health.ok => 'ok',
            Health.failed => 'failed',
            _ => 'warning',
          },
          state.$2,
          state.$1 == Health.ok ? null : l.diagNextMarz,
        );
      },
    );
    await check(
      'app_version',
      l.ccApplication,
      l.diagAppTested,
      l.diagAppExpected,
      () async {
        final info = await ref.read(packageInfoProvider.future);
        final h = await ref.read(systemHealthProvider.future);
        final latest = int.tryParse('${h.obj('app')['latest_build'] ?? ''}');
        final mine = int.tryParse(info.buildNumber) ?? 0;
        return latest != null && mine < latest
            ? (
                'warning',
                l.diagAppOld(info.buildNumber, latest),
                l.diagNextUpdate,
              )
            : ('ok', l.diagAppCurrent(info.version, info.buildNumber), null);
      },
    );
    if (mounted) setState(() => _running = false);
    ref.invalidate(systemHealthProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.ccDiagnostics)),
      body: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          Text(l.ccDiagnosticsHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: Space.sm),
          FilledButton.icon(
            onPressed: _running ? null : _run,
            icon: const Icon(Icons.play_arrow),
            label: Text(widget.only == null ? l.ccRunAll : l.ccRunCheck),
          ),
          const SizedBox(height: Space.sm),
          for (final r in _results)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.label,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (r.result == 'running')
                          const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          HealthChip(switch (r.result) {
                            'ok' => Health.ok,
                            'failed' => Health.failed,
                            _ => Health.warning,
                          }),
                      ],
                    ),
                    Text(
                      '${l.ccTested}: ${r.tested}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${l.ccExpected}: ${r.expected}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (r.result != 'running')
                      Text(
                        '${l.ccHappened}: ${r.happened}${r.ms == null ? '' : ' (${r.ms} ms)'}',
                      ),
                    if (r.next != null)
                      Text(
                        '${l.ccNextAction}: ${r.next}',
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Space.md),
          Text(l.ccDiagHistory, style: theme.textTheme.titleMedium),
          FutureBuilder(
            key: ValueKey(_running),
            future: ref
                .read(postgresApiProvider)
                .rpcRows(
                  'diagnostic_history',
                  params: {'p_component': widget.only, 'p_limit': 30},
                ),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              return Column(
                children: [
                  for (final h in snap.data!)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: HealthChip(switch ('${h['result']}') {
                        'ok' => Health.ok,
                        'failed' => Health.failed,
                        _ => Health.warning,
                      }),
                      title: Text(
                        '${h['component']} · ${h['happened'] ?? ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_when(l, h['at'])} · ${h['run_by_name'] ?? ''} · ${h['device'] ?? ''}',
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
