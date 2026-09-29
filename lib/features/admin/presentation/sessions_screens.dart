import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import 'admin_common.dart';

/// "5 min ago", "3 h ago", "yesterday", or a date.
String sinceLabel(AppLocalizations l10n, DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return l10n.timeJustNow;
  if (d.inHours < 1) return l10n.timeMinutesAgo(d.inMinutes);
  if (d.inDays < 1) return l10n.timeHoursAgo(d.inHours);
  if (d.inDays < 7) return l10n.timeDaysAgo(d.inDays);
  return DateFormat.yMMMd(l10n.localeName).format(t.toLocal());
}

final _presenceProvider = FutureProvider.autoDispose.family<List<Json>, String>(
  (ref, search) async =>
      (await ref
              .watch(postgresApiProvider)
              .rpcRows(
                'people_presence',
                params: {'p_search': search.isEmpty ? null : search},
              ))
          .map(Json.from)
          .toList(),
);

final devicesProvider = FutureProvider.autoDispose.family<List<Json>, String?>(
  (ref, userId) async =>
      (await ref
              .watch(postgresApiProvider)
              .rpcRows('user_devices', params: {'p_user_id': userId}))
          .map(Json.from)
          .toList(),
);

final _historyProvider = FutureProvider.autoDispose.family<List<Json>, String?>(
  (ref, userId) async =>
      (await ref
              .watch(postgresApiProvider)
              .rpcRows(
                'auth_history',
                params: {'p_user_id': userId, 'p_limit': 50},
              ))
          .map(Json.from)
          .toList(),
);

/// A small coloured status label.
class _State extends StatelessWidget {
  const _State(this.label, {required this.on, this.icon});
  final String label;
  final bool on;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(
        icon ?? (on ? Icons.circle : Icons.circle_outlined),
        size: 14,
        color: on ? scheme.primary : scheme.outline,
      ),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: on
          ? scheme.primaryContainer.withValues(alpha: 0.6)
          : scheme.surfaceContainerHighest,
    );
  }
}

/// Signed in / online / active, as three separate facts.
List<Widget> presenceChips(AppLocalizations l10n, Json p) {
  final signedIn =
      (p['signed_in_devices'] as num?)?.toInt() ??
      ((p['signed_in'] == true) ? 1 : 0);
  final contact = p.dateOrNull('last_contact_at');
  final active = p.dateOrNull('last_active_at');
  return [
    _State(
      signedIn > 0 ? l10n.presenceSignedIn(signedIn) : l10n.presenceSignedOut,
      on: signedIn > 0,
      icon: signedIn > 0 ? Icons.lock_open : Icons.lock_outline,
    ),
    _State(
      p['online'] == true
          ? l10n.presenceOnline
          : contact == null
          ? l10n.presenceNeverSeen
          : l10n.presenceLastSeen(sinceLabel(l10n, contact)),
      on: p['online'] == true,
      icon: Icons.wifi,
    ),
    if (active != null)
      _State(
        p['active'] == true
            ? l10n.presenceActiveNow
            : l10n.presenceLastActive(sinceLabel(l10n, active)),
        on: p['active'] == true,
        icon: Icons.touch_app_outlined,
      ),
  ];
}

/// Admin: who is signed in, online and using Sidra (sessions.view).
class PresenceScreen extends ConsumerStatefulWidget {
  const PresenceScreen({super.key});

  @override
  ConsumerState<PresenceScreen> createState() => _PresenceScreenState();
}

class _PresenceScreenState extends ConsumerState<PresenceScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final people = ref.watch(_presenceProvider(_search));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.presenceTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_presenceProvider(_search).future),
        child: ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            Text(
              l10n.presenceHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Space.sm),
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.presenceSearch,
              ),
              onSubmitted: (v) => setState(() => _search = v.trim()),
            ),
            const SizedBox(height: Space.sm),
            ...switch (people) {
              AsyncData(:final value) when value.isEmpty => [
                EmptyView(icon: Icons.devices_other, title: l10n.devicesEmpty),
              ],
              AsyncData(:final value) => [
                for (final p in value)
                  Card(
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DevicesScreen(
                            userId: p['user_id'] as String,
                            name: p['display_name'] as String?,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Space.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${p['display_name']}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                if (p['is_active'] == false)
                                  Text(
                                    l10n.adminDisabled,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium,
                                  ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            Wrap(
                              spacing: Space.xs,
                              runSpacing: Space.xs,
                              children: presenceChips(l10n, p),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
              AsyncError(:final error) => [
                ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(_presenceProvider(_search)),
                ),
              ],
              _ => [const LoadingView()],
            },
          ],
        ),
      ),
    );
  }
}

/// A person's phones and sign-in history. Staff with sessions.view see
/// anyone's; everyone sees their own ([userId] null). Signing out one phone
/// or all of them needs sessions.manage, or being that person.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key, this.userId, this.name});
  final String? userId;
  final String? name;

  Future<void> _revoke(BuildContext context, WidgetRef ref, Json d) async {
    final l10n = AppLocalizations.of(context);
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deviceRevokeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deviceRevokeBody),
            TextField(
              controller: reason,
              decoration: InputDecoration(labelText: l10n.deviceRevokeReason),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deviceRevoke),
          ),
        ],
      ),
    );
    final why = reason.text.trim();
    reason.dispose();
    if (ok != true || !context.mounted) return;
    await runAdminAction(
      context,
      () => ref
          .read(postgresApiProvider)
          .rpc(
            'revoke_device',
            params: {
              'p_device_id': d['id'],
              'p_reason': why.isEmpty ? null : why,
            },
          ),
      success: l10n.adminSaved,
    );
    ref.invalidate(devicesProvider(userId));
    ref.invalidate(_historyProvider(userId));
  }

  Future<void> _endAll(BuildContext context, WidgetRef ref, String uid) async {
    final l10n = AppLocalizations.of(context);
    if (!await confirm(
      context,
      title: l10n.devicesEndAll,
      message: l10n.devicesEndAllBody,
    )) {
      return;
    }
    if (!context.mounted) return;
    var count = 0;
    final ok = await runAdminAction(context, () async {
      count =
          ((await ref
                      .read(postgresApiProvider)
                      .rpc('end_all_sessions', params: {'p_user_id': uid}))
                  as num?)
              ?.toInt() ??
          0;
    });
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.devicesEndAllDone(count))));
    }
    ref.invalidate(devicesProvider(userId));
    ref.invalidate(_historyProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final devices = ref.watch(devicesProvider(userId));
    final history = ref.watch(_historyProvider(userId));
    final uid = userId ?? devices.value?.firstOrNull?['user_id'] as String?;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          name ?? (userId == null ? l10n.devicesMine : l10n.devicesTitle),
        ),
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () => _endAll(context, ref, uid),
              child: Text(l10n.devicesEndAll),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_historyProvider(userId));
          ref.invalidate(devicesProvider(userId));
          await ref.read(devicesProvider(userId).future);
        },
        child: ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            Text(l10n.devicesHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: Space.sm),
            ...switch (devices) {
              AsyncData(:final value) when value.isEmpty => [
                EmptyView(icon: Icons.devices_other, title: l10n.devicesEmpty),
              ],
              AsyncData(:final value) => [
                for (final d in value)
                  _DeviceCard(
                    device: d,
                    onRevoke: () => _revoke(context, ref, d),
                  ),
              ],
              AsyncError(:final error) => [
                ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(devicesProvider(userId)),
                ),
              ],
              _ => [const LoadingView()],
            },
            const SizedBox(height: Space.lg),
            Text(l10n.authHistoryTitle, style: theme.textTheme.titleMedium),
            ...switch (history) {
              AsyncData(:final value) => [
                for (final e in value)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_eventIcon('${e['kind']}'), size: 20),
                    title: Text(authEventLabel(l10n, '${e['kind']}')),
                    subtitle: Text(
                      [
                        DateFormat.yMMMd(l10n.localeName)
                            .add_jm()
                            .format(e.dateOrNull('at')!.toLocal()),
                        if ((e['device'] as String?)?.isNotEmpty ?? false)
                          e['device'] as String,
                        ?e['actor_name'] as String?,
                        if ((e['detail'] as Map?)?['reason']
                            case final String r)
                          '“$r”',
                      ].join(' · '),
                    ),
                  ),
              ],
              AsyncError() => [const SizedBox.shrink()],
              _ => [const LoadingView()],
            },
            const SizedBox(height: Space.xxl),
          ],
        ),
      ),
    );
  }
}

IconData _eventIcon(String kind) => switch (kind) {
  'sign_in' || 'signed_up' => Icons.login,
  'sign_out' || 'sessions_ended' || 'device_revoked' => Icons.logout,
  'sign_in_failed' ||
  'sign_in_locked' ||
  'sign_in_disabled' => Icons.warning_amber,
  'password_changed' => Icons.key_outlined,
  _ => Icons.history,
};

String authEventLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'sign_in' => l10n.authEventSignIn,
  'signed_up' => l10n.authEventSignedUp,
  'sign_in_failed' => l10n.authEventFailed,
  'sign_in_locked' => l10n.authEventLocked,
  'sign_in_disabled' => l10n.authEventDisabled,
  'sign_out' => l10n.authEventSignOut,
  'refresh_rejected' => l10n.authEventRefreshRejected,
  'device_revoked' => l10n.authEventDeviceRevoked,
  'sessions_ended' => l10n.authEventSessionsEnded,
  'password_changed' => l10n.authEventPasswordChanged,
  _ => kind,
};

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.onRevoke});
  final Json device;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = device;
    final revoked = d.dateOrNull('revoked_at');
    final name = [
      d['manufacturer'],
      d['model'],
    ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
    final facts = [
      if (d['app_version'] != null)
        l10n.deviceApp('${d['app_version']}', '${d['app_build'] ?? '?'}'),
      if (d['os_version'] != null)
        l10n.deviceAndroid('${d['os_version']}', '${d['sdk_int'] ?? '?'}'),
      if (d['network'] != null) l10n.deviceNetwork('${d['network']}'),
      if (d['notifications_allowed'] == false) l10n.deviceNotificationsOff,
      if (d['microphone_allowed'] == false) l10n.deviceMicOff,
      if (d.dateOrNull('last_sync_at') case final s?)
        l10n.deviceLastSync(sinceLabel(l10n, s)),
      if (d.dateOrNull('first_seen_at') case final f?)
        l10n.deviceFirstSeen(sinceLabel(l10n, f)),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_android),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    name.isEmpty ? l10n.deviceUnknown : name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (d['this_device'] == true)
                  Text(l10n.deviceThis, style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: presenceChips(l10n, d),
            ),
            const SizedBox(height: Space.xs),
            Text(facts.join(' · '), style: theme.textTheme.bodySmall),
            if (revoked != null)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Text(
                  l10n.deviceRevokedBy(
                    '${d['revoked_by_name'] ?? '—'}',
                    sinceLabel(l10n, revoked),
                    '${d['revoke_reason'] ?? ''}',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              )
            else if (d['this_device'] != true)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: onRevoke,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.deviceRevoke),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
