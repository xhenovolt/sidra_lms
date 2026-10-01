import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../../admin/presentation/admin_common.dart';
import '../../admin/presentation/contact_import_screen.dart';
import '../../admin/presentation/learners_tab.dart' show staffCoursesProvider;
import '../data/import_parsers.dart';
import '../data/onboarding_repository.dart';
import 'onboarding_wizard.dart';
import 'position_editor.dart';

/// Admin / teacher → Learners → Import & onboard: every way to bring
/// learners in, what was imported before, and where everyone is.
class OnboardingCenterScreen extends ConsumerWidget {
  const OnboardingCenterScreen({super.key});

  Future<void> _open(BuildContext context, ParsedImport parsed, {
    String? group,
    ({String path, String name})? history,
  }) async {
    if (parsed.rows.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.obNothingFound)));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingWizard(parsed: parsed, suggestedGroup: group, historyFile: history),
      ),
    );
  }

  /// The chat exported from WhatsApp: a .txt, or a .zip holding _chat.txt.
  Future<void> _whatsApp(BuildContext context) async {
    final f = await pickLocalFile(FileType.any);
    if (f == null || !context.mounted) return;
    final bytes = await File(f.path).readAsBytes();
    String text;
    var keep = f;
    if (f.name.toLowerCase().endsWith('.zip')) {
      final zip = ZipDecoder().decodeBytes(bytes);
      final chat = zip.files.where((x) => x.name.toLowerCase().endsWith('.txt')).firstOrNull;
      if (chat == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).obNotAnExport)),
          );
        }
        return;
      }
      text = utf8.decode(chat.content as List<int>, allowMalformed: true);
      final out = File('${Directory.systemTemp.path}${Platform.pathSeparator}${chat.name.split('/').last}');
      await out.writeAsString(text);
      keep = (path: out.path, name: f.name.replaceAll(RegExp(r'\.zip$', caseSensitive: false), '.txt'));
    } else {
      text = utf8.decode(bytes, allowMalformed: true);
    }
    if (!context.mounted) return;
    if (!fileLooksLikeWhatsApp(f.name, text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).obNotAnExport)),
      );
      return;
    }
    await _open(context, parseWhatsAppExport(text), group: groupNameFromExport(f.name), history: keep);
  }

  Future<void> _file(BuildContext context) async {
    final f = await pickLocalFile(FileType.any);
    if (f == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final name = f.name.toLowerCase();
    try {
      final bytes = await File(f.path).readAsBytes();
      if (!context.mounted) return;
      final ParsedImport parsed;
      if (name.endsWith('.xlsx')) {
        parsed = rowsFromTable(parseXlsx(Uint8List.fromList(bytes)), source: 'excel');
      } else if (name.endsWith('.csv') || name.endsWith('.txt') || name.endsWith('.tsv')) {
        parsed = rowsFromTable(parseCsv(utf8.decode(bytes, allowMalformed: true)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.obFileTypes)));
        return;
      }
      if (context.mounted) await _open(context, parsed);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.obFileUnreadable)));
      }
    }
  }

  Future<void> _paste(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final c = TextEditingController(text: (await Clipboard.getData('text/plain'))?.text ?? '');
    if (!context.mounted) return;
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.obPasteTitle),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: c,
            maxLines: 10,
            minLines: 6,
            decoration: InputDecoration(hintText: l10n.obPasteHint),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.adminCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: Text(l10n.obNext)),
        ],
      ),
    );
    c.dispose();
    if (text == null || !context.mounted) return;
    await _open(context, parsePastedList(text));
  }

  Future<void> _one(BuildContext context) => _open(
    context,
    ParsedImport([ImportRow()], source: 'manual'),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget source(IconData icon, String title, String body, VoidCallback onTap) => Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(body),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.obCenterTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          Text(l10n.obCenterIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Space.md),
          source(Icons.chat_outlined, l10n.obFromWhatsApp, l10n.obFromWhatsAppHint, () => _whatsApp(context)),
          if (canImportContacts)
            source(Icons.contacts_outlined, l10n.obFromContacts, l10n.obFromContactsHint, () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ContactImportScreen()),
              );
            }),
          source(Icons.table_chart_outlined, l10n.obFromFile, l10n.obFromFileHint, () => _file(context)),
          source(Icons.content_paste, l10n.obFromPaste, l10n.obFromPasteHint, () => _paste(context)),
          source(Icons.person_add_alt, l10n.obFromOne, l10n.obFromOneHint, () => _one(context)),
          Card(
            color: theme.colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Text(l10n.obWhatsAppTruth, style: theme.textTheme.bodySmall),
            ),
          ),
          const Divider(height: Space.lg),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: Text(l10n.obBoardTitle),
            subtitle: Text(l10n.obBoardHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MigrationBoardScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(l10n.obHistoryTitle),
            subtitle: Text(l10n.obHistoryHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ImportHistoryScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================ history ==

final _historyProvider = FutureProvider.autoDispose<List<Json>>(
  (ref) => ref.watch(onboardingRepositoryProvider).history(),
);

class ImportHistoryScreen extends ConsumerWidget {
  const ImportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final history = ref.watch(_historyProvider);
    final when = DateFormat.yMMMd(l10n.localeName).add_jm();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.obHistoryTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_historyProvider.future),
        child: switch (history) {
          AsyncData(:final value) when value.isEmpty => ListView(
            children: [EmptyView(icon: Icons.history, title: l10n.obHistoryEmpty)],
          ),
          AsyncData(:final value) => ListView(
            children: [
              for (final b in value)
                ListTile(
                  leading: Icon(
                    b['rolled_back_at'] != null ? Icons.undo : Icons.group_add_outlined,
                  ),
                  title: Text(
                    '${b['label'] ?? sourceLabel(l10n, b['source'] as String?)}'
                    '${b['rolled_back_at'] != null ? ' · ${l10n.obUndone}' : ''}',
                  ),
                  subtitle: Text(
                    [
                      when.format(DateTime.parse('${b['created_at']}').toLocal()),
                      ?b['created_by_name'] as String?,
                      ?b['course_title'] as String?,
                      l10n.obBatchCounts(
                        (b['processed'] as num?)?.toInt() ?? 0,
                        (b['created'] as num?)?.toInt() ?? 0,
                        (b['matched'] as num?)?.toInt() ?? 0,
                        (b['rejected'] as num?)?.toInt() ?? 0,
                      ),
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => _BatchScreen(batch: b)),
                    );
                    ref.invalidate(_historyProvider);
                  },
                ),
            ],
          ),
          AsyncError(:final error) => ListView(
            children: [ErrorView(error: error, onRetry: () => ref.invalidate(_historyProvider))],
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}

final _itemsProvider = FutureProvider.autoDispose.family<List<Json>, String>(
  (ref, id) => ref.watch(onboardingRepositoryProvider).batchItems(id),
);

class _BatchScreen extends ConsumerWidget {
  const _BatchScreen({required this.batch});
  final Json batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final id = '${batch['id']}';
    final items = ref.watch(_itemsProvider(id));
    final undone = batch['rolled_back_at'] != null;
    return Scaffold(
      appBar: AppBar(
        title: Text('${batch['label'] ?? sourceLabel(l10n, batch['source'] as String?)}'),
        actions: [
          if (!undone)
            TextButton.icon(
              onPressed: () async {
                if (!await confirm(
                  context,
                  title: l10n.obUndoTitle,
                  message: l10n.obUndoBody,
                  destructive: true,
                )) {
                  return;
                }
                if (!context.mounted) return;
                Json? report;
                final ok = await runAdminAction(context, () async {
                  report = await ref.read(onboardingRepositoryProvider).rollback(id);
                });
                if (ok && context.mounted) {
                  await showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.obUndone),
                      content: Text(
                        l10n.obUndoReport(
                          (report?['removed'] as num?)?.toInt() ?? 0,
                          (report?['kept_with_activity'] as num?)?.toInt() ?? 0,
                          (report?['unlinked_existing'] as num?)?.toInt() ?? 0,
                        ),
                      ),
                      actions: [
                        FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.done)),
                      ],
                    ),
                  );
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.undo),
              label: Text(l10n.obUndo),
            ),
        ],
      ),
      body: switch (items) {
        AsyncData(:final value) => ListView(
          children: [
            if (undone && batch['rollback_report'] != null)
              Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Text(
                  l10n.obUndoReport(
                    ((batch['rollback_report'] as Map)['removed'] as num?)?.toInt() ?? 0,
                    ((batch['rollback_report'] as Map)['kept_with_activity'] as num?)?.toInt() ?? 0,
                    ((batch['rollback_report'] as Map)['unlinked_existing'] as num?)?.toInt() ?? 0,
                  ),
                ),
              ),
            for (final it in value)
              ListTile(
                leading: Icon(switch (it['outcome']) {
                  'created' => Icons.person_add_alt,
                  'matched' => Icons.link,
                  'skipped' => Icons.remove_circle_outline,
                  _ => Icons.error_outline,
                }, color: it['outcome'] == 'rejected' ? theme.colorScheme.error : null),
                title: Text('${it['name'] ?? '?'}'),
                subtitle: Text(
                  [
                    ?it['phone'] as String?,
                    _outcome(l10n, '${it['outcome']}'),
                    ?it['reason'] as String?,
                    if (it['account_state'] != null) _state(l10n, '${it['account_state']}'),
                  ].join(' · '),
                ),
                trailing: it['user_id'] != null && it['account_state'] != 'active' && !undone
                    ? IconButton(
                        tooltip: l10n.obNewCode,
                        icon: const Icon(Icons.vpn_key_outlined),
                        onPressed: () => showInvitation(context, ref, '${it['user_id']}'),
                      )
                    : null,
              ),
          ],
        ),
        AsyncError(:final error) => ErrorView(error: error),
        _ => const LoadingView(),
      },
    );
  }

  static String _outcome(AppLocalizations l10n, String o) => switch (o) {
    'created' => l10n.obOutcomeCreated,
    'matched' => l10n.obOutcomeMatched,
    'skipped' => l10n.obOutcomeSkipped,
    _ => l10n.obOutcomeRejected,
  };
}

String _state(AppLocalizations l10n, String s) => switch (s) {
  'active' => l10n.obStateActive,
  'invited' => l10n.obStateInvited,
  _ => l10n.obStateImported,
};

/// A new invitation code for a learner who has not signed in yet, with
/// copy and "send on WhatsApp".
Future<void> showInvitation(BuildContext context, WidgetRef ref, String userId) async {
  final l10n = AppLocalizations.of(context);
  Json? inv;
  final ok = await runAdminAction(context, () async {
    inv = await ref.read(onboardingRepositoryProvider).issueInvitation(userId);
  });
  if (!ok || !context.mounted || inv == null) return;
  final msg = l10n.obInviteMessage('${inv!['name'] ?? ''}', '${inv!['code']}', '${inv!['phone'] ?? ''}');
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.obInvitationFor('${inv!['name'] ?? ''}')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            '${inv!['code']}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontFamily: 'monospace'),
          ),
          const SizedBox(height: Space.sm),
          Text(l10n.obInvitationHintOne),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Clipboard.setData(ClipboardData(text: msg)),
          icon: const Icon(Icons.copy),
          label: Text(l10n.obCopy),
        ),
        if (inv!['phone'] != null)
          FilledButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://wa.me/${'${inv!['phone']}'.replaceAll('+', '')}?text=${Uri.encodeComponent(msg)}'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.send_outlined),
            label: Text(l10n.obSendWhatsApp),
          ),
      ],
    ),
  );
}

// ================================================================== board ==

/// Where every learner of a course is, what still needs doing, and quick
/// fixes (position for one or many, a new invitation code).
class MigrationBoardScreen extends ConsumerStatefulWidget {
  const MigrationBoardScreen({super.key, this.courseId});
  final String? courseId;

  @override
  ConsumerState<MigrationBoardScreen> createState() => _MigrationBoardScreenState();
}

class _MigrationBoardScreenState extends ConsumerState<MigrationBoardScreen> {
  late String? _courseId = widget.courseId;
  List<Json>? _rows;
  Object? _error;
  bool _onlyNeeds = false;
  final _picked = <String>{};

  @override
  void initState() {
    super.initState();
    if (_courseId != null) _load();
  }

  Future<void> _load() async {
    final id = _courseId;
    if (id == null) return;
    setState(() {
      _rows = null;
      _error = null;
      _picked.clear();
    });
    try {
      final rows = await ref.read(onboardingRepositoryProvider).board(id);
      if (mounted && _courseId == id) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _setPosition(List<String> userIds, {Position? current, String? status}) async {
    final l10n = AppLocalizations.of(context);
    Position pos = current ?? const {'kind': 'unknown'};
    var st = status ?? 'in_progress';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, MediaQuery.viewInsetsOf(context).bottom + Space.lg),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(l10n.obSetPositionFor(userIds.length), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Space.sm),
            PositionEditor(value: pos, onChanged: (p) => pos = p),
            StatusDropdown(value: st, onChanged: (s) => st = s),
            const SizedBox(height: Space.md),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.adminSave)),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final saved = await runAdminAction(context, () => ref.read(onboardingRepositoryProvider).setPositions(
      _courseId!,
      [for (final u in userIds) {'user_id': u, 'position': pos, 'status': st}],
    ), success: l10n.adminSaved);
    if (saved) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final courses = ref.watch(staffCoursesProvider).value?.values.toList() ?? const [];
    final rows = [
      for (final r in _rows ?? const <Json>[])
        if (!_onlyNeeds || r['ready'] != true || r['account_state'] != 'active') r,
    ];
    final needs = (_rows ?? const []).where((r) => r['ready'] != true).length;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.obBoardTitle)),
      floatingActionButton: _picked.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _setPosition(_picked.toList()),
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: Text(l10n.obSetPositionFor(_picked.length)),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
            child: DropdownButtonFormField<String>(
              initialValue: _courseId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.obCourse),
              items: [
                for (final c in courses) DropdownMenuItem(value: c.id, child: Text(c.title)),
              ],
              onChanged: (v) {
                setState(() => _courseId = v);
                _load();
              },
            ),
          ),
          if (_rows != null)
            SwitchListTile(
              value: _onlyNeeds,
              onChanged: (v) => setState(() => _onlyNeeds = v),
              title: Text(l10n.obOnlyNeeds),
              subtitle: Text(l10n.obNeedsCount(needs)),
            ),
          Expanded(
            child: switch ((_courseId, _rows, _error)) {
              (null, _, _) => EmptyView(icon: Icons.map_outlined, title: l10n.obChooseCourse),
              (_, _, final Object e) => ErrorView(error: e, onRetry: _load),
              (_, null, _) => const LoadingView(),
              _ when rows.isEmpty => EmptyView(icon: Icons.check_circle_outline, title: l10n.obBoardEmpty),
              _ => RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    final id = '${r['user_id']}';
                    final ready = r['ready'] == true;
                    final active = r['account_state'] == 'active';
                    return CheckboxListTile(
                      value: _picked.contains(id),
                      onChanged: (v) => setState(() => v == true ? _picked.add(id) : _picked.remove(id)),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text('${r['name'] ?? ''}'),
                      subtitle: Text(
                        [
                          sourceLabel(l10n, r['source'] as String?),
                          positionLabel(l10n, (r['position'] as Map?)?.cast<String, dynamic>()),
                          learnerStatusLabel(l10n, r['status'] as String?),
                          _state(l10n, '${r['account_state']}'),
                        ].join(' · '),
                      ),
                      secondary: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!active)
                            IconButton(
                              tooltip: l10n.obNewCode,
                              icon: const Icon(Icons.vpn_key_outlined),
                              onPressed: () => showInvitation(context, ref, id),
                            ),
                          IconButton(
                            tooltip: l10n.obSetPosition,
                            icon: Icon(
                              ready ? Icons.edit_location_alt_outlined : Icons.wrong_location_outlined,
                              color: ready ? null : theme.colorScheme.error,
                            ),
                            onPressed: () => _setPosition(
                              [id],
                              current: (r['position'] as Map?)?.cast<String, dynamic>(),
                              status: r['status'] as String?,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// Failure text for snack bars.
String obFailureText(AppLocalizations l10n, Object e) =>
    e is AppFailure && e.message.isNotEmpty ? e.message : l10n.genericError;
