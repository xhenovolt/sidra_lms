import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../../admin/data/admin_repository.dart';
import '../../admin/presentation/admin_common.dart';
import '../../admin/presentation/learners_tab.dart' show staffCoursesProvider;
import '../../audio/presentation/audio_widgets.dart';
import '../../content/data/content_repository.dart';
import '../../content/presentation/resource_widgets.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../data/teaching_repository.dart';
import 'learner_portion_screen.dart' show participationLabel, resultLabel;
import '../../../shared/widgets/user_avatar.dart';
import '../../media/presentation/capture_sheet.dart';

/// Upload a local file once and register it as a shared resource.
Future<String> uploadAsResource(
  WidgetRef ref, {
  required String path,
  required String fileName,
  required String kind,
  required String title,
  String? language,
}) async {
  final profile = await ref.read(profileProvider.future);
  final assetId = await ref
      .read(adminRepositoryProvider)
      .uploadMedia(
        filePath: path,
        fileName: fileName,
        kind: kind,
        uploaderId: profile.id,
        folder: 'teaching',
        title: title,
      );
  final row = (await ref.read(adminRepositoryProvider).api.insert('resources', {
    'kind': kind,
    'title': title,
    'provider': 'cloudinary',
    'media_asset_id': assetId,
    'file_name': fileName,
    'mime_type': mimeTypeFor(fileName),
    'bytes': File(path).lengthSync(),
    'language': language,
    'uploaded_by': profile.id,
  })).first;
  return row['id'] as String;
}

// ================================================================ home ==

/// Teacher home: who needs me, then my groups.
class TeachingHomeScreen extends ConsumerWidget {
  const TeachingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final groups = ref.watch(myGroupsProvider);
    final attention = ref.watch(attentionProvider);

    Future<void> refresh() async {
      ref.invalidate(attentionProvider);
      ref.invalidate(myGroupsProvider);
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-group',
        onPressed: () async {
          if (await showGroupForm(context, ref)) {
            ref.invalidate(myGroupsProvider);
          }
        },
        icon: const Icon(Icons.group_add_outlined),
        label: Text(l10n.groupNew),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 96),
          children: [
            Text(l10n.needsAttention, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xs),
            switch (attention) {
              AsyncData(:final value) => _AttentionCard(attention: value),
              AsyncError(:final error) => ErrorView(
                error: error,
                onRetry: refresh,
              ),
              _ => const Padding(
                padding: EdgeInsets.all(Space.md),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.school_outlined, size: 18),
                  label: Text(l10n.correctionLibrary),
                  onPressed: () => context.push('/teach/corrections'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.library_music_outlined, size: 18),
                  label: Text(l10n.audioLibraryTitle),
                  onPressed: () => context.push('/teach/audio'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.insights_outlined, size: 18),
                  label: Text(l10n.analyticsTitle),
                  onPressed: () => context.push('/teach/analytics'),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            Text(l10n.myGroups, style: theme.textTheme.titleLarge),
            switch (groups) {
              AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Text(l10n.groupsNone, style: theme.textTheme.bodyMedium),
              ),
              AsyncData(:final value) => Column(
                children: [
                  for (final g in value)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${g.learners}')),
                        title: Text(g.name),
                        subtitle: Text(
                          [
                            g.courseTitle,
                            if (g.latestPortion != null)
                              '${g.latestPortion!['title']}',
                            if (g.waiting > 0) l10n.groupWaiting(g.waiting),
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/teach/groups/${g.id}'),
                      ),
                    ),
                ],
              ),
              AsyncError(:final error) => ErrorView(
                error: error,
                onRetry: refresh,
              ),
              _ => const LoadingView(),
            },
          ],
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.attention});
  final Json attention;

  List<Json> _list(String k) => [
    for (final e in (attention[k] as List? ?? const []))
      Map<String, dynamic>.from(e as Map),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = [
      (Icons.mark_email_unread_outlined, l10n.attNew, _list('new_submissions')),
      (Icons.replay, l10n.attResubmissions, _list('resubmissions')),
      (Icons.report_outlined, l10n.attCorrection, _list('correction_required')),
      (Icons.schedule, l10n.attNotSubmitted, _list('not_submitted')),
    ];
    final behind = _list('falling_behind');
    final total = sections.fold(0, (n, s) => n + s.$3.length) + behind.length;
    if (total == 0) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.task_alt),
          title: Text(l10n.attAllClear),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final (icon, label, items) in sections)
            if (items.isNotEmpty)
              ExpansionTile(
                leading: Icon(icon),
                title: Text('$label (${items.length})'),
                initiallyExpanded: label == l10n.attNew,
                children: [
                  for (final i in items)
                    ListTile(
                      dense: true,
                      title: Text('${i['learner']}'),
                      subtitle: Text([i['title'], ?i['group']].join(' · ')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push('/teach/portions/${i['portion_id']}'),
                    ),
                ],
              ),
          if (behind.isNotEmpty)
            ExpansionTile(
              leading: const Icon(Icons.trending_down),
              title: Text('${l10n.attBehind} (${behind.length})'),
              children: [
                for (final b in behind)
                  ListTile(
                    dense: true,
                    title: Text('${b['learner']}'),
                    subtitle: Text(
                      l10n.attOpenPortions(b['open_portions'] as int),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ============================================================== groups ==

/// Create a group of enrolled learners in a course.
Future<bool> showGroupForm(BuildContext context, WidgetRef ref) async {
  final ok = await Navigator.of(context)
      .push<bool>(MaterialPageRoute(builder: (_) => const _GroupFormScreen()));
  return ok ?? false;
}

class _GroupFormScreen extends ConsumerStatefulWidget {
  const _GroupFormScreen();

  @override
  ConsumerState<_GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends ConsumerState<_GroupFormScreen> {
  Course? _course;
  final _name = TextEditingController(text: 'Group A');
  List<CoursePerson> _learners = const [];
  final _chosen = <String>{};
  bool _saving = false;

  Future<void> _pickCourse(Course c) async {
    setState(() {
      _course = c;
      _learners = const [];
      _chosen.clear();
    });
    final people = await ref.read(adminRepositoryProvider).coursePeople(c.id);
    if (!mounted) return;
    setState(() {
      _learners = people
          .where((p) => !p.isStaff && p.status == 'active')
          .toList();
      _chosen.addAll(_learners.map((p) => p.userId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final courses =
        ref.watch(staffCoursesProvider).value?.values.toList() ??
        const <Course>[];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupNew)),
      body: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _course?.id,
            decoration: InputDecoration(labelText: l10n.financeCourse),
            items: [
              for (final c in courses)
                DropdownMenuItem(value: c.id, child: Text(c.title)),
            ],
            onChanged: (id) =>
                _pickCourse(courses.firstWhere((c) => c.id == id)),
          ),
          AdminField(controller: _name, label: l10n.groupName, required: true),
          if (_course != null) ...[
            const SizedBox(height: Space.sm),
            Text(l10n.groupLearners(_chosen.length)),
            if (_learners.isEmpty)
              Text(
                l10n.groupNoLearners,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            for (final p in _learners)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _chosen.contains(p.userId),
                title: Text(p.name),
                onChanged: (v) => setState(
                  () => v! ? _chosen.add(p.userId) : _chosen.remove(p.userId),
                ),
              ),
          ],
          const SizedBox(height: Space.md),
          FilledButton(
            onPressed: _course == null || _saving || _name.text.trim().isEmpty
                ? null
                : () async {
                    setState(() => _saving = true);
                    final ok = await runAdminAction(
                      context,
                      () => ref
                          .read(teachingRepositoryProvider)
                          .saveGroup(
                            courseId: _course!.id,
                            name: _name.text.trim(),
                            learnerIds: _chosen.toList(),
                          ),
                      success: l10n.adminSaved,
                    );
                    if (!context.mounted) return;
                    setState(() => _saving = false);
                    if (ok) Navigator.pop(context, true);
                  },
            child: Text(l10n.adminSave),
          ),
        ],
      ),
    );
  }
}

final _groupProvider = FutureProvider.autoDispose
    .family<
      ({TeachingGroup group, List<Json> members, List<Json> portions}),
      String
    >((ref, id) async {
      final repo = ref.watch(teachingRepositoryProvider);
      final groups = await repo.myGroups();
      final group = groups.firstWhere((g) => g.id == id);
      return (
        group: group,
        members: await repo.groupMembers(id),
        portions: await repo.groupPortions(id),
      );
    });

/// A group: its learners and its portions; create today's (or the next).
class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = ref.watch(_groupProvider(groupId));
    final date = DateFormat.MMMEd(l10n.localeName);
    return Scaffold(
      appBar: AppBar(title: Text(data.value?.group.name ?? '')),
      body: switch (data) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(_groupProvider(groupId).future),
          child: ListView(
            padding: const EdgeInsets.all(Space.md),
            children: [
              Text(value.group.courseTitle, style: theme.textTheme.titleMedium),
              Text(l10n.groupLearners(value.members.length)),
              const SizedBox(height: Space.md),
              FilledButton.icon(
                onPressed: () => context.push(
                  '/teach/portions/new?group=$groupId&course=${value.group.courseId}',
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.portionCreateToday),
              ),
              if (value.portions.isNotEmpty) ...[
                const SizedBox(height: Space.xs),
                OutlinedButton.icon(
                  onPressed: () async {
                    Json? next;
                    if (await runAdminAction(
                          context,
                          () async => next = await ref
                              .read(teachingRepositoryProvider)
                              .nextPortion(
                                value.portions.first['id'] as String,
                              ),
                        ) &&
                        next != null &&
                        context.mounted) {
                      await context.push('/teach/portions/${next!['id']}/edit');
                      ref.invalidate(_groupProvider(groupId));
                    }
                  },
                  icon: const Icon(Icons.skip_next),
                  label: Text(
                    l10n.portionCreateNext('${value.portions.first['title']}'),
                  ),
                ),
              ],
              const SizedBox(height: Space.md),
              Text(l10n.portionsTitle, style: theme.textTheme.titleMedium),
              for (final p in value.portions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    p['status'] == 'draft'
                        ? Icons.edit_note
                        : Icons.assignment_turned_in_outlined,
                  ),
                  title: Text('${p['title']}'),
                  subtitle: Text(
                    [
                      if (p['status'] == 'draft') l10n.adminDraft,
                      if (p['assigned_at'] != null)
                        date.format(
                          DateTime.parse('${p['assigned_at']}').toLocal(),
                        ),
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    p['status'] == 'draft'
                        ? '/teach/portions/${p['id']}/edit'
                        : '/teach/portions/${p['id']}',
                  ),
                ),
              const Divider(height: Space.xl),
              Text(l10n.groupMembers, style: theme.textTheme.titleMedium),
              for (final m in value.members)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text('${m['display_name'] ?? '—'}'),
                  trailing: IconButton(
                    tooltip: l10n.noteAdd,
                    icon: const Icon(Icons.sticky_note_2_outlined),
                    onPressed: () => showNotesSheet(
                      context,
                      ref,
                      learnerId: m['id'] as String,
                      learnerName: '${m['display_name'] ?? ''}',
                      courseId: value.group.courseId,
                    ),
                  ),
                ),
            ],
          ),
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(_groupProvider(groupId)),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

// ======================================================== portion editor ==

/// Create or finish a portion: details, page, instruction, model; assign.
class PortionEditorScreen extends ConsumerStatefulWidget {
  const PortionEditorScreen({
    super.key,
    this.portionId,
    this.groupId,
    this.courseId,
  });
  final String? portionId;
  final String? groupId;
  final String? courseId;

  @override
  ConsumerState<PortionEditorScreen> createState() =>
      _PortionEditorScreenState();
}

class _PortionEditorScreenState extends ConsumerState<PortionEditorScreen> {
  String? _id;
  String? _groupId;
  String? _courseId;
  final _title = TextEditingController();
  final _instructions = TextEditingController();
  String? _language;
  final _types = <String>{'audio'};
  List<PortionResource> _resources = const [];
  bool _busy = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _id = widget.portionId;
    _groupId = widget.groupId;
    _courseId = widget.courseId;
    if (_id != null) {
      _load();
    } else {
      _loaded = true;
    }
  }

  Future<void> _load() async {
    final board = await ref.read(teachingRepositoryProvider).board(_id!);
    final p = board.portion;
    if (!mounted) return;
    setState(() {
      _groupId = p['group_id'] as String?;
      _courseId = p['course_id'] as String?;
      _title.text = '${p['title']}';
      _instructions.text = (p['instructions'] as String?) ?? '';
      _language = p['instruction_language'] as String?;
      _types
        ..clear()
        ..addAll([for (final t in (p['submission_types'] as List)) '$t']);
      _resources = board.resources;
      _loaded = true;
    });
  }

  /// Saves the details (creating the draft the first time).
  Future<bool> _save() async {
    final repo = ref.read(teachingRepositoryProvider);
    var ok = true;
    await runAdminAction(context, () async {
      final saved = await repo.savePortion(
        courseId: _courseId!,
        groupId: _groupId,
        title: _title.text.trim(),
        instructions: nullIfBlank(_instructions.text),
        instructionLanguage: _language,
        submissionTypes: _types.toList(),
        portionId: _id,
      );
      _id = saved['id'] as String;
    }).then((v) => ok = v);
    return ok;
  }

  Future<void> _attach(
    String role,
    Future<String?> Function() makeResource,
  ) async {
    if (_id == null && !await _save()) return;
    if (!mounted) return;
    setState(() => _busy = true);
    await runAdminAction(context, () async {
      final rid = await makeResource();
      if (rid == null) return;
      await ref.read(teachingRepositoryProvider).setResource(_id!, rid, role);
    });
    if (!mounted) return;
    await _load();
    setState(() => _busy = false);
  }

  Future<void> _addPage() async {
    final f = await captureContent(
      context,
      allow: const {
        CaptureSource.photo,
        CaptureSource.scan,
        CaptureSource.gallery,
        CaptureSource.file,
      },
      fileExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (f == null) return;
    await _attach(
      'page',
      () => uploadAsResource(
        ref,
        path: f.path,
        fileName: f.name,
        kind: f.kind,
        title: _title.text.trim(),
      ),
    );
  }

  Future<void> _addRecording(String role) async {
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<RecordedAudio>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RecordSheet(
        title: role == 'model' ? l10n.portionModel : l10n.portionInstruction,
      ),
    );
    if (result == null) return;
    await _attach(
      role,
      () => uploadAsResource(
        ref,
        path: result.path,
        fileName: result.fileName,
        kind: 'audio',
        title:
            '${_title.text.trim()} · ${role == 'model' ? l10n.portionModel : l10n.portionInstruction}',
        language: role == 'model' ? 'ar' : _language,
      ),
    );
  }

  Future<void> _pickFromLibrary(String role) async {
    final picked = await showModalBottomSheet<Json>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AudioPicker(),
    );
    if (picked == null || picked['type'] != 'resource') return;
    await _attach(role, () async => picked['id'] as String);
  }

  Future<void> _assign({bool choose = false}) async {
    final l10n = AppLocalizations.of(context);
    if (!await _save()) return;
    List<String>? userIds;
    if (choose || _groupId == null) {
      if (!mounted) return;
      userIds = await showLearnerChooser(context, ref, courseId: _courseId!);
      if (userIds == null || userIds.isEmpty) return;
    }
    if (!mounted) return;
    int count = 0;
    final ok = await runAdminAction(
      context,
      () async => count = await ref
          .read(teachingRepositoryProvider)
          .assign(_id!, userIds: userIds),
    );
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.portionAssigned(count))));
    context.pushReplacement('/teach/portions/$_id');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (!_loaded) return const Scaffold(body: LoadingView());
    if (_id == null && _title.text.isEmpty) {
      _title.text = l10n.portionDefaultTitle;
    }
    Iterable<PortionResource> withRole(String r) =>
        _resources.where((x) => x.role == r);

    Widget resourceTile(PortionResource r) => r.kind == 'audio'
        ? Row(
            children: [
              Expanded(
                child: VoicePlayer(
                  mediaAssetId: r.mediaAssetId,
                  title: r.title,
                ),
              ),
              IconButton(
                tooltip: l10n.resourceRemove,
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await ref
                      .read(teachingRepositoryProvider)
                      .setResource(_id!, r.id, r.role, remove: true);
                  await _load();
                },
              ),
            ],
          )
        : ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(resourceIcon(r.kind)),
            title: Text(r.title),
            trailing: IconButton(
              tooltip: l10n.resourceRemove,
              icon: const Icon(Icons.close),
              onPressed: () async {
                await ref
                    .read(teachingRepositoryProvider)
                    .setResource(_id!, r.id, r.role, remove: true);
                await _load();
              },
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(_id == null ? l10n.portionCreateToday : l10n.portionEdit),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            if (_busy) const LinearProgressIndicator(),
            AdminField(
              controller: _title,
              label: l10n.portionTitle,
              hint: l10n.portionTitleHint,
              required: true,
            ),
            AdminField(
              controller: _instructions,
              label: l10n.portionTask,
              hint: l10n.portionTaskHint,
              maxLines: 3,
            ),
            LanguageDropdown(
              value: _language,
              label: l10n.portionExplainedIn,
              noneLabel: l10n.lessonLanguageSameAsCourse,
              onChanged: (v) => setState(() => _language = v),
            ),
            const SizedBox(height: Space.sm),
            Text(l10n.portionLearnersSend, style: theme.textTheme.labelLarge),
            Wrap(
              spacing: Space.xs,
              children: [
                for (final (t, label) in [
                  ('audio', l10n.assignmentAudio),
                  ('image', l10n.assignmentPhotos),
                  ('document', l10n.assignmentDocuments),
                  ('text', l10n.assignmentText),
                ])
                  FilterChip(
                    label: Text(label),
                    selected: _types.contains(t),
                    onSelected: (v) => setState(
                      () => v
                          ? _types.add(t)
                          : (_types.length > 1 ? _types.remove(t) : null),
                    ),
                  ),
              ],
            ),
            const Divider(height: Space.xl),
            _SectionHead(
              icon: Icons.menu_book_outlined,
              text: l10n.portionPage,
            ),
            for (final r in withRole('page')) resourceTile(r),
            OutlinedButton.icon(
              onPressed: _addPage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(l10n.portionAddPage),
            ),
            const Divider(height: Space.xl),
            _SectionHead(
              icon: Icons.record_voice_over_outlined,
              text: l10n.portionInstruction,
            ),
            for (final r in withRole('instruction')) resourceTile(r),
            Wrap(
              spacing: Space.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _addRecording('instruction'),
                  icon: const Icon(Icons.mic),
                  label: Text(l10n.portionRecordInstruction),
                ),
                TextButton(
                  onPressed: () => _pickFromLibrary('instruction'),
                  child: Text(l10n.portionFromLibrary),
                ),
              ],
            ),
            const Divider(height: Space.xl),
            _SectionHead(icon: Icons.graphic_eq, text: l10n.portionModel),
            for (final r in withRole('model')) resourceTile(r),
            Wrap(
              spacing: Space.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _addRecording('model'),
                  icon: const Icon(Icons.mic),
                  label: Text(l10n.portionRecordModel),
                ),
                TextButton(
                  onPressed: () => _pickFromLibrary('model'),
                  child: Text(l10n.portionFromLibrary),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            if (_groupId != null)
              FilledButton.icon(
                onPressed: _busy ? null : () => _assign(),
                icon: const Icon(Icons.groups),
                label: Text(l10n.portionAssignGroup),
              ),
            const SizedBox(height: Space.xs),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _assign(choose: true),
              icon: const Icon(Icons.person_search_outlined),
              label: Text(l10n.portionAssignChosen),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      if (await _save() && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.adminSaved)),
                        );
                      }
                    },
              child: Text(l10n.portionSaveDraft),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.xs),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: Space.xs),
        Text(text, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _RecordSheet extends StatefulWidget {
  const _RecordSheet({required this.title});
  final String title;

  @override
  State<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends State<_RecordSheet> {
  RecordedAudio? _audio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          VoiceRecorder(onChanged: (a) => setState(() => _audio = a)),
          const SizedBox(height: Space.sm),
          FilledButton(
            onPressed: _audio == null
                ? null
                : () => Navigator.pop(context, _audio),
            child: Text(l10n.portionUseRecording),
          ),
        ],
      ),
    );
  }
}

class _AudioPicker extends ConsumerStatefulWidget {
  const _AudioPicker();

  @override
  ConsumerState<_AudioPicker> createState() => _AudioPickerState();
}

class _AudioPickerState extends ConsumerState<_AudioPicker> {
  String _q = '';
  bool _mine = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.audioSearch,
              ),
              onSubmitted: (v) => setState(() => _q = v),
            ),
          ),
          SwitchListTile(
            value: _mine,
            onChanged: (v) => setState(() => _mine = v),
            title: Text(l10n.audioOnlyMine),
          ),
          Expanded(
            child: FutureBuilder<List<Json>>(
              future: ref
                  .read(teachingRepositoryProvider)
                  .audioLibrary(query: _q, mine: _mine),
              builder: (context, snap) {
                final rows = (snap.data ?? const <Json>[])
                    .where((r) => r['type'] == 'resource')
                    .toList();
                if (!snap.hasData) return const LoadingView();
                if (rows.isEmpty) {
                  return EmptyView(
                    icon: Icons.library_music_outlined,
                    title: l10n.audioNone,
                  );
                }
                return ListView(
                  children: [
                    for (final r in rows)
                      ListTile(
                        title: Text('${r['title']}'),
                        subtitle: VoicePlayer(
                          mediaAssetId: r['media_asset_id'] as String,
                          compact: true,
                        ),
                        trailing: FilledButton(
                          onPressed: () => Navigator.pop(context, r),
                          child: Text(l10n.useThis),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Choose learners of a course (for individual assignment).
Future<List<String>?> showLearnerChooser(
  BuildContext context,
  WidgetRef ref, {
  required String courseId,
}) async {
  final l10n = AppLocalizations.of(context);
  final people =
      (await ref.read(adminRepositoryProvider).coursePeople(courseId))
          .where((p) => !p.isStaff && p.status == 'active')
          .toList();
  if (!context.mounted) return null;
  final chosen = <String>{};
  return showDialog<List<String>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.portionAssignChosen),
        content: SizedBox(
          width: 420,
          height: 420,
          child: ListView(
            children: [
              for (final p in people)
                CheckboxListTile(
                  value: chosen.contains(p.userId),
                  title: Text(p.name),
                  onChanged: (v) => setState(
                    () => v! ? chosen.add(p.userId) : chosen.remove(p.userId),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, chosen.toList()),
            child: Text(l10n.portionAssignCount(chosen.length)),
          ),
        ],
      ),
    ),
  );
}

// ============================================================ the board ==

/// Every learner on one portion: status, their latest recording inline,
/// tap to review. Designed for 30 learners in a row.
class PortionBoardScreen extends ConsumerWidget {
  const PortionBoardScreen({super.key, required this.portionId});
  final String portionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final board = ref.watch(portionBoardProvider(portionId));
    return Scaffold(
      appBar: AppBar(
        title: Text(board.value?.title ?? ''),
        actions: [
          IconButton(
            tooltip: l10n.portionEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/teach/portions/$portionId/edit'),
          ),
        ],
      ),
      body: switch (board) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(portionBoardProvider(portionId).future),
          child: ListView(
            padding: const EdgeInsets.only(bottom: Space.xxl),
            children: [
              Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.xs,
                  children: [
                    for (final (label, n) in [
                      (
                        l10n.partWaiting,
                        value.rows.where((r) => r.waiting).length,
                      ),
                      (
                        l10n.partTryAgain,
                        value.rows
                            .where(
                              (r) =>
                                  r.status == Participation.correctionRequired,
                            )
                            .length,
                      ),
                      (
                        l10n.partDone,
                        value.rows
                            .where((r) => r.status == Participation.completed)
                            .length,
                      ),
                      (
                        l10n.partToDo,
                        value.rows
                            .where(
                              (r) =>
                                  r.status == Participation.assigned ||
                                  r.status == Participation.opened,
                            )
                            .length,
                      ),
                    ])
                      Chip(label: Text('$label: $n')),
                  ],
                ),
              ),
              for (final r in value.rows)
                _BoardTile(row: r, portionId: portionId, board: value),
              if (value.rows.isEmpty)
                EmptyView(
                  icon: Icons.groups_outlined,
                  title: l10n.portionNotAssigned,
                ),
              Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Text(
                  l10n.portionBoardHint,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(portionBoardProvider(portionId)),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _BoardTile extends ConsumerWidget {
  const _BoardTile({
    required this.row,
    required this.portionId,
    required this.board,
  });
  final BoardRow row;
  final String portionId;
  final PortionBoard board;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final audio = row.latestFiles
        .where((f) => f['kind'] == 'audio')
        .firstOrNull;
    final color = switch (row.status) {
      Participation.submitted ||
      Participation.underReview => theme.colorScheme.primary,
      Participation.correctionRequired => theme.colorScheme.tertiary,
      Participation.completed => Colors.green.shade700,
      _ => theme.colorScheme.outline,
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 4),
      child: InkWell(
        onTap: row.latestSubmissionId == null
            ? null
            : () async {
                await showReviewSheet(context, ref, row: row, board: board);
                ref.invalidate(portionBoardProvider(portionId));
                ref.invalidate(attentionProvider);
              },
        child: Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(
                    avatarUrl: row.avatarUrl,
                    name: row.name,
                    radius: 16,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(row.name, style: theme.textTheme.titleSmall),
                  ),
                  Text(
                    [
                      row.lastResult != null &&
                              row.status != Participation.submitted
                          ? resultLabel(l10n, row.lastResult!)
                          : participationLabel(l10n, row.status),
                      if (row.attempts > 1) l10n.subAttempt(row.attempts),
                    ].join(' · '),
                    style: theme.textTheme.labelMedium?.copyWith(color: color),
                  ),
                ],
              ),
              if (audio != null)
                VoicePlayer(
                  mediaAssetId: audio['media_asset_id'] as String,
                  compact: true,
                )
              else if (row.latestFiles.isNotEmpty)
                Text(
                  l10n.subFilesCount(row.latestFiles.length),
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Review one learner's latest attempt in a single sheet.
Future<void> showReviewSheet(
  BuildContext context,
  WidgetRef ref, {
  required BoardRow row,
  required PortionBoard board,
}) async {
  final id = row.latestSubmissionId;
  if (id != null && row.status == Participation.submitted) {
    try {
      await ref.read(teachingRepositoryProvider).markUnderReview(id);
    } catch (_) {}
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReviewSheet(row: row, board: board),
  );
}

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.row, required this.board});
  final BoardRow row;
  final PortionBoard board;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  final _feedback = TextEditingController();
  final _note = TextEditingController();
  Correction? _correction;
  RecordedAudio? _recording;
  bool _showRecorder = false;
  bool _saveToLibrary = false;
  final _libTitle = TextEditingController();
  String? _categoryId;
  bool _sending = false;

  Future<void> _send(ReviewResult result) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);
    final repo = ref.read(teachingRepositoryProvider);
    final ok = await runAdminAction(context, () async {
      String? assetId;
      if (_recording != null) {
        final profile = await ref.read(profileProvider.future);
        assetId = await ref
            .read(adminRepositoryProvider)
            .uploadMedia(
              filePath: _recording!.path,
              fileName: _recording!.fileName,
              kind: 'audio',
              uploaderId: profile.id,
              folder: 'corrections',
            );
      }
      await repo.review(
        submissionId: widget.row.latestSubmissionId!,
        result: result,
        feedback: nullIfBlank(_feedback.text),
        correctionId: _correction?.id,
        correctionAssetId: assetId,
        saveAs: _saveToLibrary && assetId != null
            ? {
                'title': _libTitle.text.trim().isEmpty
                    ? (_feedback.text.trim().isEmpty
                          ? widget.board.title
                          : _feedback.text.trim())
                    : _libTitle.text.trim(),
                'category_id': _categoryId,
                'explanation': nullIfBlank(_feedback.text),
              }
            : null,
      );
      if (_note.text.trim().isNotEmpty) {
        await repo.addNote(
          widget.row.userId,
          _note.text.trim(),
          courseId: widget.board.portion['course_id'] as String?,
        );
      }
    }, success: l10n.reviewSent);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final latest = widget.row.latest ?? const {};
    final files = widget.row.latestFiles;
    final categories =
        ref.watch(correctionCategoriesProvider).value ?? const [];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.md,
        0,
        Space.md,
        MediaQuery.viewInsetsOf(context).bottom + Space.lg,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            '${widget.row.name} · ${l10n.subAttempt(widget.row.attempts)}',
            style: theme.textTheme.titleLarge,
          ),
          for (final f in files)
            if (f['kind'] == 'audio')
              VoicePlayer(
                mediaAssetId: f['media_asset_id'] as String,
                title: l10n.theirRecording,
              )
            else if (f['kind'] == 'image')
              _SignedImage(assetId: f['media_asset_id'] as String)
            else
              ListTile(
                leading: Icon(resourceIcon('${f['kind']}')),
                title: Text('${f['file_name'] ?? 'file'}'),
              ),
          if (latest['text'] != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Text('${latest['text']}'),
              ),
            ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              FilledButton.icon(
                onPressed: _sending ? null : () => _send(ReviewResult.correct),
                icon: const Icon(Icons.check),
                label: Text(l10n.resCorrect),
              ),
              FilledButton.tonalIcon(
                onPressed: _sending
                    ? null
                    : () => _send(ReviewResult.excellent),
                icon: const Icon(Icons.star_outline),
                label: Text(l10n.resExcellent),
              ),
              OutlinedButton(
                onPressed: _sending
                    ? null
                    : () => _send(ReviewResult.minorCorrection),
                child: Text(l10n.resMinor),
              ),
            ],
          ),
          const Divider(height: Space.lg),
          Text(l10n.reviewCorrectionTitle, style: theme.textTheme.titleSmall),
          if (_correction != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.school_outlined),
                title: Text(_correction!.title),
                subtitle: _correction!.mediaAssetId == null
                    ? null
                    : VoicePlayer(
                        mediaAssetId: _correction!.mediaAssetId,
                        compact: true,
                      ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _correction = null),
                ),
              ),
            ),
          Wrap(
            spacing: Space.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final c = await showCorrectionPicker(context, ref);
                  if (c != null) setState(() => _correction = c);
                },
                icon: const Icon(Icons.search),
                label: Text(l10n.reviewUseExisting),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showRecorder = true),
                icon: const Icon(Icons.mic),
                label: Text(l10n.reviewRecordNew),
              ),
            ],
          ),
          if (_showRecorder) ...[
            VoiceRecorder(onChanged: (a) => setState(() => _recording = a)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _saveToLibrary,
              onChanged: (v) => setState(() => _saveToLibrary = v),
              title: Text(l10n.reviewSaveToLibrary),
              subtitle: Text(l10n.reviewSaveToLibraryHint),
            ),
            if (_saveToLibrary) ...[
              TextField(
                controller: _libTitle,
                decoration: InputDecoration(
                  labelText: l10n.correctionTitle,
                  hintText: l10n.correctionTitleHint,
                ),
              ),
              DropdownButtonFormField<String?>(
                initialValue: _categoryId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.correctionCategory),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.languageNotSet),
                  ),
                  for (final c in categories)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        c.parentId == null
                            ? c.name
                            : '${categories.firstWhere((p) => p.id == c.parentId, orElse: () => c).name} › ${c.name}',
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ],
          ],
          TextField(
            controller: _feedback,
            maxLines: 2,
            decoration: InputDecoration(labelText: l10n.reviewFeedbackOptional),
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                ),
                onPressed: _sending
                    ? null
                    : () => _send(ReviewResult.correctionRequired),
                icon: const Icon(Icons.replay),
                label: Text(l10n.resCorrection),
              ),
              TextButton(
                onPressed: _sending
                    ? null
                    : () => _send(ReviewResult.needsExplanation),
                child: Text(l10n.resExplain),
              ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.noteAdd),
            children: [
              TextField(
                controller: _note,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.notePrivate,
                  hintText: l10n.notePrivateHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignedImage extends ConsumerWidget {
  const _SignedImage({required this.assetId});
  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder<String>(
    future: ref.read(contentRepositoryProvider).mediaUrl(assetId),
    builder: (context, snap) => snap.hasData
        ? InteractiveViewer(child: CachedNetworkImage(imageUrl: snap.data!))
        : const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
  );
}

/// Search the correction library and pick one.
Future<Correction?> showCorrectionPicker(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<Correction>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CorrectionPicker(),
    );

class _CorrectionPicker extends ConsumerStatefulWidget {
  const _CorrectionPicker();

  @override
  ConsumerState<_CorrectionPicker> createState() => _CorrectionPickerState();
}

class _CorrectionPickerState extends ConsumerState<_CorrectionPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.correctionSearch,
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Correction>>(
              future: ref
                  .read(teachingRepositoryProvider)
                  .searchCorrections(query: _q),
              builder: (context, snap) {
                if (!snap.hasData) return const LoadingView();
                if (snap.data!.isEmpty) {
                  return EmptyView(
                    icon: Icons.school_outlined,
                    title: l10n.correctionNone,
                  );
                }
                return ListView(
                  children: [
                    for (final c in snap.data!)
                      ListTile(
                        title: Text(c.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              [
                                ?c.parentCategory,
                                ?c.category,
                                l10n.correctionUsed(c.useCount),
                              ].join(' · '),
                            ),
                            if (c.mediaAssetId != null)
                              VoicePlayer(
                                mediaAssetId: c.mediaAssetId,
                                compact: true,
                              ),
                          ],
                        ),
                        trailing: FilledButton(
                          onPressed: () => Navigator.pop(context, c),
                          child: Text(l10n.useThis),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Private notes about a learner (never shown to learners).
Future<void> showNotesSheet(
  BuildContext context,
  WidgetRef ref, {
  required String learnerId,
  required String learnerName,
  String? courseId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _NotesSheet(
    learnerId: learnerId,
    learnerName: learnerName,
    courseId: courseId,
  ),
);

class _NotesSheet extends ConsumerStatefulWidget {
  const _NotesSheet({
    required this.learnerId,
    required this.learnerName,
    this.courseId,
  });
  final String learnerId;
  final String learnerName;
  final String? courseId;

  @override
  ConsumerState<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends ConsumerState<_NotesSheet> {
  final _body = TextEditingController();
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = DateFormat.yMMMd(l10n.localeName);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.md,
        0,
        Space.md,
        MediaQuery.viewInsetsOf(context).bottom + Space.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.notesAbout(widget.learnerName),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            l10n.notePrivateHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextField(
            controller: _body,
            maxLines: 2,
            decoration: InputDecoration(labelText: l10n.notePrivate),
          ),
          FilledButton(
            onPressed: () async {
              if (_body.text.trim().isEmpty) return;
              if (await runAdminAction(
                context,
                () => ref
                    .read(teachingRepositoryProvider)
                    .addNote(
                      widget.learnerId,
                      _body.text.trim(),
                      courseId: widget.courseId,
                    ),
              )) {
                _body.clear();
                setState(() => _reload++);
              }
            },
            child: Text(l10n.adminSave),
          ),
          SizedBox(
            height: 240,
            child: FutureBuilder<List<Json>>(
              key: ValueKey(_reload),
              future: ref
                  .read(teachingRepositoryProvider)
                  .notes(widget.learnerId),
              builder: (context, snap) => ListView(
                children: [
                  for (final n in snap.data ?? const <Json>[])
                    ListTile(
                      dense: true,
                      title: Text('${n['body']}'),
                      subtitle: Text(
                        [
                          ?n['author'] as String?,
                          if (n['created_at'] != null)
                            date.format(
                              DateTime.parse('${n['created_at']}').toLocal(),
                            ),
                        ].join(' · '),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
