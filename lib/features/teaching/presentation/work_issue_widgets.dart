import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../../admin/presentation/admin_common.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../media/presentation/capture_sheet.dart';
import '../../media/presentation/media_viewer.dart';

/// What a problem report is about: a teaching portion, a lesson (its own
/// work) or an assignment.
typedef WorkTarget = ({String kind, String id});

const issueCategories = [
  'dont_understand',
  'need_clarification',
  'need_more_time',
  'unavailable',
  'technical',
  'cannot_access',
  'cannot_record',
  'cannot_upload',
  'other',
];

String issueCategoryLabel(AppLocalizations l10n, String c) => switch (c) {
  'dont_understand' => l10n.issueDontUnderstand,
  'need_clarification' => l10n.issueClarification,
  'need_more_time' => l10n.issueMoreTime,
  'unavailable' => l10n.issueUnavailable,
  'technical' => l10n.issueTechnical,
  'cannot_access' => l10n.issueCannotAccess,
  'cannot_record' => l10n.issueCannotRecord,
  'cannot_upload' => l10n.issueCannotUpload,
  _ => l10n.issueOther,
};

final myWorkIssuesProvider = FutureProvider.autoDispose
    .family<List<Json>, WorkTarget>(
      (ref, t) async =>
          (await ref
                  .watch(postgresApiProvider)
                  .rpcRows(
                    'my_work_issues',
                    params: {'p_kind': t.kind, 'p_target_id': t.id},
                  ))
              .map(Json.from)
              .toList(),
    );

final teacherIssuesProvider = FutureProvider.autoDispose
    .family<List<Json>, String>(
      (ref, status) async =>
          (await ref
                  .watch(postgresApiProvider)
                  .rpcRows('work_issues_for_me', params: {'p_status': status}))
              .map(Json.from)
              .toList(),
    );

final policyEventsProvider = FutureProvider.autoDispose<List<Json>>(
  (ref) async =>
      (await ref
              .watch(postgresApiProvider)
              .rpcRows('learner_policy_events', params: {'p_open_only': true}))
          .map(Json.from)
          .toList(),
);

/// Runs the late-work policies (the database skips it if it ran in the last
/// 15 minutes), so reminders go out even while the server is not running.
final policyTickProvider = FutureProvider.autoDispose<void>((ref) async {
  try {
    await ref.watch(postgresApiProvider).rpc('run_learner_policies');
  } catch (_) {
    // offline, or not allowed for this role: nothing to do
  }
});

String _when(AppLocalizations l10n, DateTime? d) => d == null
    ? ''
    : DateFormat.yMMMd(l10n.localeName).add_jm().format(d.toLocal());

/// Learner: "I have a problem with this work", and the teacher's answer.
class WorkIssueSection extends ConsumerWidget {
  const WorkIssueSection({super.key, required this.target});
  final WorkTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final issues = ref.watch(myWorkIssuesProvider(target)).value ?? const [];
    final latest = issues.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (latest != null)
          Card(
            color: latest['status'] == 'open'
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latest['status'] == 'open'
                        ? l10n.issueSentTitle
                        : l10n.issueAnsweredTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    [
                      issueCategoryLabel(l10n, '${latest['category']}'),
                      ?latest['message'] as String?,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (latest['response'] != null) ...[
                    const SizedBox(height: Space.xs),
                    Text(
                      '${latest['responder_name'] ?? ''}: ${latest['response']}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  if (latest.dateOrNull('extension_until') case final ext?)
                    Text(
                      l10n.issueNewDue(_when(l10n, ext)),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () async {
              final sent = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => _ReportSheet(target: target),
              );
              if (sent == true) ref.invalidate(myWorkIssuesProvider(target));
            },
            icon: const Icon(Icons.report_problem_outlined),
            label: Text(l10n.issueReport),
          ),
        ),
      ],
    );
  }
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.target});
  final WorkTarget target;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  String? _category;
  final _message = TextEditingController();
  CapturedFile? _file;
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final ok = await runAdminAction(context, () async {
      String? asset;
      if (_file case final f? when f.text == null) {
        final me = ref.read(authSessionProvider).user!;
        asset = await ref
            .read(adminRepositoryProvider)
            .uploadMedia(
              filePath: f.path,
              fileName: f.name,
              kind: f.kind,
              uploaderId: me.id,
              folder: 'issues',
            );
      }
      final text = [
        _message.text.trim(),
        ?_file?.text,
      ].where((s) => s.isNotEmpty).join('\n');
      await ref
          .read(postgresApiProvider)
          .rpc(
            'report_work_issue',
            params: {
              'p_kind': widget.target.kind,
              'p_target_id': widget.target.id,
              'p_category': _category,
              'p_message': text.isEmpty ? null : text,
              'p_attachment_asset_id': asset,
            },
          );
    }, success: l10n.issueSent);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: Space.md,
        right: Space.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Space.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.issueReport, style: theme.textTheme.titleLarge),
            Text(l10n.issueReportHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final c in issueCategories)
                  ChoiceChip(
                    label: Text(issueCategoryLabel(l10n, c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _message,
              maxLines: 4,
              maxLength: 1500,
              decoration: InputDecoration(labelText: l10n.issueMessage),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _file == null
                        ? l10n.issueAttachHint
                        : '${_file!.name} · ${formatFileSize(_file!.bytes)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final f = await captureContent(context);
                          if (f != null) setState(() => _file = f);
                        },
                  icon: const Icon(Icons.attach_file),
                  label: Text(l10n.issueAttach),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            FilledButton(
              onPressed: _category == null || _busy ? null : _send,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.issueSend),
            ),
          ],
        ),
      ),
    );
  }
}

/// Teacher/admin: problem reports on the work they handle.
class TeacherIssuesScreen extends ConsumerWidget {
  const TeacherIssuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.issuesTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.issuesOpen),
              Tab(text: l10n.issuesResolved),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _IssueList(status: 'open'),
            _IssueList(status: 'resolved'),
          ],
        ),
      ),
    );
  }
}

class _IssueList extends ConsumerWidget {
  const _IssueList({required this.status});
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final issues = ref.watch(teacherIssuesProvider(status));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(teacherIssuesProvider(status).future),
      child: switch (issues) {
        AsyncData(:final value) when value.isEmpty => ListView(
          children: [
            EmptyView(icon: Icons.check_circle_outline, title: l10n.issuesNone),
          ],
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            for (final i in value)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i['learner_name']} · ${i['work_title'] ?? ''}',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        [
                          ?i['course_title'] as String?,
                          _when(l10n, i.dateOrNull('created_at')),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: Space.xs),
                      Chip(
                        label: Text(
                          issueCategoryLabel(l10n, '${i['category']}'),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (i['message'] != null) Text('${i['message']}'),
                      if (i['attachment_asset_id'] case final String asset)
                        TextButton.icon(
                          onPressed: () => openInApp(
                            context,
                            assetId: asset,
                            title: l10n.issueOpenAttachment,
                          ),
                          icon: const Icon(Icons.attachment),
                          label: Text(l10n.issueOpenAttachment),
                        ),
                      if (i['response'] != null)
                        Text(
                          '${i['responder_name'] ?? ''}: ${i['response']}',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (i.dateOrNull('extension_until') case final ext?)
                        Text(
                          l10n.issueNewDue(_when(l10n, ext)),
                          style: theme.textTheme.labelMedium,
                        ),
                      if (status != 'resolved')
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: FilledButton.tonal(
                            onPressed: () async {
                              final done = await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (_) => _RespondSheet(issue: i),
                              );
                              if (done == true) {
                                ref.invalidate(teacherIssuesProvider('open'));
                                ref.invalidate(
                                  teacherIssuesProvider('resolved'),
                                );
                              }
                            },
                            child: Text(l10n.issueRespond),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        AsyncError(:final error) => ListView(
          children: [
            ErrorView(
              error: error,
              onRetry: () => ref.invalidate(teacherIssuesProvider(status)),
            ),
          ],
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _RespondSheet extends ConsumerStatefulWidget {
  const _RespondSheet({required this.issue});
  final Json issue;

  @override
  ConsumerState<_RespondSheet> createState() => _RespondSheetState();
}

class _RespondSheetState extends ConsumerState<_RespondSheet> {
  final _response = TextEditingController();
  DateTime? _extension;
  bool _resolve = true;
  bool _busy = false;

  @override
  void dispose() {
    _response.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      initialDate: now.add(const Duration(days: 2)),
    );
    if (day == null) return;
    // End of that day, so the learner has the whole day.
    setState(() => _extension = DateTime(day.year, day.month, day.day, 23, 59));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: Space.md,
        right: Space.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Space.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.issueRespond, style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _response,
            maxLines: 4,
            decoration: InputDecoration(labelText: l10n.issueYourAnswer),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(
              _extension == null
                  ? l10n.issueGiveMoreTime
                  : l10n.issueNewDue(_when(l10n, _extension)),
            ),
            trailing: _extension == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _extension = null),
                  ),
            onTap: _pickDate,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _resolve,
            onChanged: (v) => setState(() => _resolve = v),
            title: Text(l10n.issueMarkResolved),
          ),
          FilledButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    final ok = await runAdminAction(
                      context,
                      () => ref
                          .read(postgresApiProvider)
                          .rpc(
                            'respond_work_issue',
                            params: {
                              'p_issue_id': widget.issue['id'],
                              'p_response': _response.text.trim(),
                              'p_extension_until': _extension
                                  ?.toUtc()
                                  .toIso8601String(),
                              'p_resolve': _resolve,
                            },
                          ),
                      success: l10n.adminSaved,
                    );
                    if (!context.mounted) return;
                    setState(() => _busy = false);
                    if (ok) Navigator.of(context).pop(true);
                  },
            child: Text(l10n.issueSendAnswer),
          ),
        ],
      ),
    );
  }
}

String policyEventLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'not_opened' => l10n.policyNotOpened,
  'not_submitted' => l10n.policyNotSubmitted,
  'overdue' => l10n.policyOverdue,
  'escalated' => l10n.policyEscalated,
  'suspended' => l10n.policySuspended,
  'inactive' => l10n.policyInactive,
  'reinstated' => l10n.policyReinstated,
  _ => kind,
};

/// Late work, inactive learners and automatic suspensions (open events).
class LateWorkScreen extends ConsumerWidget {
  const LateWorkScreen({super.key, this.canRunNow = false});
  final bool canRunNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final events = ref.watch(policyEventsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lateWorkTitle),
        actions: [
          if (canRunNow)
            TextButton(
              onPressed: () async {
                await runAdminAction(
                  context,
                  () => ref
                      .read(postgresApiProvider)
                      .rpc('run_learner_policies', params: {'p_force': true}),
                  success: l10n.adminSaved,
                );
                ref.invalidate(policyEventsProvider);
              },
              child: Text(l10n.lateWorkRunNow),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(policyEventsProvider.future),
        child: switch (events) {
          AsyncData(:final value) when value.isEmpty => ListView(
            children: [
              EmptyView(
                icon: Icons.check_circle_outline,
                title: l10n.lateWorkNone,
              ),
            ],
          ),
          AsyncData(:final value) => ListView(
            padding: const EdgeInsets.all(Space.md),
            children: [
              Text(l10n.lateWorkHint, style: theme.textTheme.bodySmall),
              for (final e in value)
                Card(
                  child: ListTile(
                    leading: Icon(switch ('${e['kind']}') {
                      'suspended' => Icons.pause_circle_outline,
                      'inactive' => Icons.bedtime_outlined,
                      'escalated' => Icons.priority_high,
                      _ => Icons.schedule,
                    }),
                    title: Text('${e['learner_name']}'),
                    subtitle: Text(
                      [
                        policyEventLabel(l10n, '${e['kind']}'),
                        ?e['work_title'] as String?,
                        ?e['course_title'] as String?,
                        if (e['hours_late'] case final num h)
                          l10n.lateWorkHours(h.round()),
                        ?e['reason'] as String?,
                      ].join(' · '),
                    ),
                    trailing: e['kind'] == 'suspended'
                        ? TextButton(
                            onPressed: () async {
                              await runAdminAction(
                                context,
                                () => ref
                                    .read(postgresApiProvider)
                                    .rpc(
                                      'reinstate_learner',
                                      params: {
                                        'p_user_id': e['user_id'],
                                        'p_course_id': e['course_id'],
                                      },
                                    ),
                                success: l10n.adminSaved,
                              );
                              ref.invalidate(policyEventsProvider);
                            },
                            child: Text(l10n.lateWorkReinstate),
                          )
                        : null,
                  ),
                ),
            ],
          ),
          AsyncError(:final error) => ListView(
            children: [
              ErrorView(
                error: error,
                onRetry: () => ref.invalidate(policyEventsProvider),
              ),
            ],
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}
