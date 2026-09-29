import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/finance_repository.dart';
import 'admin_common.dart';
import 'control/control_center.dart';

final orgSettingsAdminProvider =
    FutureProvider.autoDispose<Map<String, String?>>(
      (ref) => ref.watch(financeRepositoryProvider).settings(),
    );

/// Admin → Settings: the control centre (health, search, sections, tests).
/// Needs settings.manage for changes; system.diagnose for health.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ControlCenterScreen();
}

/// Pauses every automatic reminder and suspension (e.g. during an outage
/// or exams), and shows when the rules last ran.
class PolicyPause extends ConsumerWidget {
  const PolicyPause({
    super.key,
    required this.pausedUntil,
    required this.lastRun,
  });
  final DateTime? pausedUntil;
  final DateTime? lastRun;

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    DateTime? until,
  ) async {
    final l10n = AppLocalizations.of(context);
    await runAdminAction(
      context,
      () => ref
          .read(financeRepositoryProvider)
          .setSetting('policy_paused_until', until?.toUtc().toIso8601String()),
      success: l10n.adminSaved,
    );
    ref.invalidate(orgSettingsAdminProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fmt = DateFormat.yMMMd(l10n.localeName).add_jm();
    final paused = pausedUntil != null && pausedUntil!.isAfter(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            paused
                ? l10n.policyPausedUntil(fmt.format(pausedUntil!.toLocal()))
                : l10n.policyRunning,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (lastRun != null)
            Text(
              l10n.policyLastRun(fmt.format(lastRun!.toLocal())),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          Wrap(
            spacing: Space.xs,
            children: [
              if (paused)
                OutlinedButton(
                  onPressed: () => _set(context, ref, null),
                  child: Text(l10n.policyResume),
                )
              else ...[
                OutlinedButton(
                  onPressed: () => _set(
                    context,
                    ref,
                    DateTime.now().add(const Duration(days: 1)),
                  ),
                  child: Text(l10n.policyPauseDays(1)),
                ),
                OutlinedButton(
                  onPressed: () => _set(
                    context,
                    ref,
                    DateTime.now().add(const Duration(days: 7)),
                  ),
                  child: Text(l10n.policyPauseDays(7)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

final _holidaysProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) => ref
          .watch(postgresApiProvider)
          .select('calendar_holidays', order: 'day.asc'),
    );

/// Days that don't count towards any deadline.
class HolidaysScreen extends ConsumerWidget {
  const HolidaysScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (day == null || !context.mounted) return;
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.holidaysAdd),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.holidaysName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.adminSave),
          ),
        ],
      ),
    );
    final text = name.text.trim();
    name.dispose();
    if (ok != true || text.isEmpty || !context.mounted) return;
    await runAdminAction(
      context,
      () => ref.read(postgresApiProvider).insert('calendar_holidays', {
        'day': DateFormat('yyyy-MM-dd').format(day),
        'name': text,
      }),
      success: l10n.adminSaved,
    );
    ref.invalidate(_holidaysProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final days = ref.watch(_holidaysProvider);
    final fmt = DateFormat.yMMMEd(l10n.localeName);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.holidaysTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.holidaysAdd),
      ),
      body: switch (days) {
        AsyncData(:final value) when value.isEmpty => EmptyView(
          icon: Icons.event_available_outlined,
          title: l10n.holidaysNone,
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            for (final d in value)
              Card(
                child: ListTile(
                  title: Text('${d['name']}'),
                  subtitle: Text(fmt.format(DateTime.parse('${d['day']}'))),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.adminDelete,
                    onPressed: () async {
                      await runAdminAction(
                        context,
                        () => ref
                            .read(postgresApiProvider)
                            .delete(
                              'calendar_holidays',
                              filters: {'day': 'eq.${d['day']}'},
                            ),
                        success: l10n.adminSaved,
                      );
                      ref.invalidate(_holidaysProvider);
                    },
                  ),
                ),
              ),
          ],
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(_holidaysProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}
