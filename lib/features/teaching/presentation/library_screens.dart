import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/network/postgres_api.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../../admin/data/admin_repository.dart';
import '../../admin/presentation/admin_common.dart';
import '../../audio/presentation/audio_widgets.dart';
import '../../content/data/content_repository.dart';
import '../../content/presentation/resource_widgets.dart';
import '../data/teaching_repository.dart';

// ====================================================== correction library ==

class CorrectionLibraryScreen extends ConsumerStatefulWidget {
  const CorrectionLibraryScreen({super.key});

  @override
  ConsumerState<CorrectionLibraryScreen> createState() =>
      _CorrectionLibraryScreenState();
}

class _CorrectionLibraryScreenState
    extends ConsumerState<CorrectionLibraryScreen> {
  String _q = '';
  String? _category;
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cats = ref.watch(correctionCategoriesProvider).value ?? const [];
    final top = cats.where((c) => c.parentId == null).toList();
    final subs = _category == null
        ? const <CorrectionCategory>[]
        : cats.where((c) => c.parentId == _category).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.correctionLibrary)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (await _addCorrection(context, cats)) setState(() => _reload++);
        },
        icon: const Icon(Icons.mic),
        label: Text(l10n.correctionAdd),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.correctionSearch,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.xs,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.adminEveryone),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                for (final c in top)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: Space.xs),
                    child: ChoiceChip(
                      label: Text(c.name),
                      selected:
                          _category == c.id ||
                          subs.any((s) => s.id == _category),
                      onSelected: (_) => setState(() => _category = c.id),
                    ),
                  ),
              ],
            ),
          ),
          if (subs.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              child: Row(
                children: [
                  for (final s in subs)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: Space.xs),
                      child: FilterChip(
                        label: Text(s.name),
                        selected: _category == s.id,
                        onSelected: (_) => setState(() => _category = s.id),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Correction>>(
              key: ValueKey('$_q|$_category|$_reload'),
              future: ref
                  .read(teachingRepositoryProvider)
                  .searchCorrections(query: _q, categoryId: _category),
              builder: (context, snap) {
                if (snap.hasError) return ErrorView(error: snap.error!);
                if (!snap.hasData) return const LoadingView();
                if (snap.data!.isEmpty) {
                  return EmptyView(
                    icon: Icons.school_outlined,
                    title: l10n.correctionNone,
                    message: l10n.correctionLibraryHint,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    for (final c in snap.data!)
                      Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: Space.md,
                          vertical: 4,
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
                                      c.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'archive' &&
                                          await runAdminAction(
                                            context,
                                            () => ref
                                                .read(
                                                  teachingRepositoryProvider,
                                                )
                                                .archiveCorrection(c.id),
                                          )) {
                                        setState(() => _reload++);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: 'archive',
                                        child: Text(l10n.correctionArchive),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                [
                                  ?c.parentCategory,
                                  ?c.category,
                                  l10n.correctionUsed(c.useCount),
                                  ?c.createdBy,
                                ].join(' · '),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (c.explanation != null) Text(c.explanation!),
                              if (c.mediaAssetId != null)
                                VoicePlayer(
                                  mediaAssetId: c.mediaAssetId,
                                  compact: true,
                                ),
                            ],
                          ),
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

  Future<bool> _addCorrection(
    BuildContext context,
    List<CorrectionCategory> cats,
  ) async {
    final l10n = AppLocalizations.of(context);
    final title = TextEditingController();
    final explanation = TextEditingController();
    String? category;
    RecordedAudio? audio;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
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
                l10n.correctionAdd,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextField(
                controller: title,
                decoration: InputDecoration(
                  labelText: l10n.correctionTitle,
                  hintText: l10n.correctionTitleHint,
                ),
              ),
              DropdownButtonFormField<String?>(
                initialValue: category,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.correctionCategory),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.languageNotSet),
                  ),
                  for (final c in cats)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        c.parentId == null
                            ? c.name
                            : '${cats.firstWhere((p) => p.id == c.parentId, orElse: () => c).name} › ${c.name}',
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => category = v),
              ),
              TextField(
                controller: explanation,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.correctionExplanation,
                ),
              ),
              const SizedBox(height: Space.sm),
              VoiceRecorder(onChanged: (a) => setState(() => audio = a)),
              FilledButton(
                onPressed: title.text.trim().isEmpty && audio == null
                    ? null
                    : () => Navigator.pop(sheetContext, true),
                child: Text(l10n.adminSave),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !context.mounted) return false;
    return runAdminAction(context, () async {
      String? assetId;
      if (audio != null) {
        final profile = await ref.read(profileProvider.future);
        assetId = await ref
            .read(adminRepositoryProvider)
            .uploadMedia(
              filePath: audio!.path,
              fileName: audio!.fileName,
              kind: 'audio',
              uploaderId: profile.id,
              folder: 'corrections',
            );
      }
      await ref
          .read(teachingRepositoryProvider)
          .saveCorrection(
            title: title.text.trim().isEmpty
                ? l10n.correctionAdd
                : title.text.trim(),
            mediaAssetId: assetId,
            explanation: nullIfBlank(explanation.text),
            categoryId: category,
          );
    }, success: l10n.adminSaved);
  }
}

// ============================================================ my audio ==

class AudioLibraryScreen extends ConsumerStatefulWidget {
  const AudioLibraryScreen({super.key});

  @override
  ConsumerState<AudioLibraryScreen> createState() => _AudioLibraryScreenState();
}

class _AudioLibraryScreenState extends ConsumerState<AudioLibraryScreen> {
  String _q = '';
  bool _mine = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = DateFormat.yMMMd(l10n.localeName);
    String roleName(String? r) => switch (r) {
      'instruction' => l10n.portionInstruction,
      'model' => l10n.portionModel,
      'correction' => l10n.reviewCorrectionTitle,
      _ => '',
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.audioLibraryTitle)),
      body: Column(
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
              key: ValueKey('$_q|$_mine'),
              future: ref
                  .read(teachingRepositoryProvider)
                  .audioLibrary(query: _q, mine: _mine),
              builder: (context, snap) {
                if (snap.hasError) return ErrorView(error: snap.error!);
                if (!snap.hasData) return const LoadingView();
                if (snap.data!.isEmpty) {
                  return EmptyView(
                    icon: Icons.library_music_outlined,
                    title: l10n.audioNone,
                  );
                }
                return ListView(
                  children: [
                    for (final a in snap.data!)
                      ListTile(
                        title: Text('${a['title']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              [
                                roleName(a['role'] as String?),
                                l10n.correctionUsed(
                                  (a['uses'] as num?)?.toInt() ?? 0,
                                ),
                                if (a['created_at'] != null)
                                  date.format(
                                    DateTime.parse('${a['created_at']}')
                                        .toLocal(),
                                  ),
                              ].where((s) => s.isNotEmpty).join(' · '),
                            ),
                            if (a['media_asset_id'] != null)
                              VoicePlayer(
                                mediaAssetId: a['media_asset_id'] as String,
                                compact: true,
                              ),
                          ],
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

// ============================================================ analytics ==

class TeachingAnalyticsScreen extends ConsumerStatefulWidget {
  const TeachingAnalyticsScreen({super.key});

  @override
  ConsumerState<TeachingAnalyticsScreen> createState() =>
      _TeachingAnalyticsScreenState();
}

class _TeachingAnalyticsScreenState
    extends ConsumerState<TeachingAnalyticsScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.analyticsTitle)),
      body: FutureBuilder<Json>(
        key: ValueKey(_days),
        future: ref.read(teachingRepositoryProvider).analytics(days: _days),
        builder: (context, snap) {
          if (snap.hasError) return ErrorView(error: snap.error!);
          if (!snap.hasData) return const LoadingView();
          final a = snap.data!;
          List<Json> list(String k) => [
            for (final e in (a[k] as List? ?? const []))
              Map<String, dynamic>.from(e as Map),
          ];
          Widget stat(String label, Object? value, String question) => SizedBox(
            width: 168,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${value ?? '—'}',
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(label, style: theme.textTheme.labelLarge),
                    Text(question, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          );
          return ListView(
            padding: const EdgeInsets.all(Space.md),
            children: [
              SegmentedButton<int>(
                segments: [
                  for (final d in [7, 30, 90])
                    ButtonSegment(value: d, label: Text(l10n.analyticsDays(d))),
                ],
                selected: {_days},
                onSelectionChanged: (s) => setState(() => _days = s.first),
              ),
              const SizedBox(height: Space.md),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  stat(l10n.anWaiting, a['waiting'], l10n.anWaitingQ),
                  stat(
                    l10n.anTurnaround,
                    a['avg_review_hours'] == null
                        ? null
                        : '${a['avg_review_hours']} h',
                    l10n.anTurnaroundQ,
                  ),
                  stat(
                    l10n.anFirstTry,
                    a['first_try_correct_percent'] == null
                        ? null
                        : '${a['first_try_correct_percent']}%',
                    l10n.anFirstTryQ,
                  ),
                  stat(
                    l10n.anSubmissions,
                    a['submissions'],
                    l10n.anSubmissionsQ,
                  ),
                  stat(l10n.anIncomplete, a['incomplete'], l10n.anIncompleteQ),
                ],
              ),
              for (final (title, key, labelKey, valueKey) in [
                (l10n.anTopCorrections, 'top_corrections', 'title', 'uses'),
                (l10n.anTopCategories, 'top_categories', 'category', 'uses'),
                (l10n.anRepeat, 'repeat_resubmitters', 'learner', 'portions'),
                (l10n.anByTeacher, 'by_teacher', 'teacher', 'reviews'),
              ]) ...[
                const SizedBox(height: Space.md),
                Text(title, style: theme.textTheme.titleMedium),
                if (list(key).isEmpty)
                  Text(l10n.anNone, style: theme.textTheme.bodySmall)
                else
                  for (final r in list(key))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${r[labelKey]}'),
                      trailing: Text('${r[valueKey]}'),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ======================================================= content library ==

/// Institutional library: every uploaded file and link, with where it is
/// used. Rename, tag, replace with a better version, archive.
class ContentLibraryScreen extends ConsumerStatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  ConsumerState<ContentLibraryScreen> createState() =>
      _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends ConsumerState<ContentLibraryScreen> {
  String? _kind;
  String _q = '';
  int _reload = 0;

  Future<void> _edit(Json r) async {
    final l10n = AppLocalizations.of(context);
    final title = TextEditingController(text: '${r['title']}');
    final tags = TextEditingController(
      text: [for (final t in (r['tags'] as List? ?? const [])) '$t'].join(', '),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminEdit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: InputDecoration(labelText: l10n.adminTitle),
            ),
            TextField(
              controller: tags,
              decoration: InputDecoration(labelText: l10n.courseTags),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.adminSave),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (await runAdminAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .api
          .update(
            'resources',
            {
              'title': title.text.trim(),
              'tags': [
                for (final t in tags.text.split(','))
                  if (t.trim().isNotEmpty) t.trim(),
              ],
            },
            filters: {'id': Pg.eq('${r['id']}')},
          ),
      success: l10n.adminSaved,
    )) {
      setState(() => _reload++);
    }
  }

  Future<void> _replace(Json r) async {
    final l10n = AppLocalizations.of(context);
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: allowedResourceExtensions,
    );
    final path = f?.path;
    if (f == null || path == null || !mounted) return;
    if (await runAdminAction(context, () async {
      final profile = await ref.read(profileProvider.future);
      final assetId = await ref
          .read(adminRepositoryProvider)
          .uploadMedia(
            filePath: path,
            fileName: f.name,
            kind: fileKindFor(f.name),
            uploaderId: profile.id,
            folder: 'resources',
          );
      await ref
          .read(adminRepositoryProvider)
          .api
          .rpc(
            'replace_resource',
            params: {
              'p_resource_id': '${r['id']}',
              'p_media_asset_id': assetId,
              'p_file_name': f.name,
              'p_mime_type': mimeTypeFor(f.name),
              'p_bytes': File(path).lengthSync(),
            },
          );
    }, success: l10n.libraryReplaced)) {
      setState(() => _reload++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.librarySearch,
              isDense: true,
            ),
            onSubmitted: (v) => setState(() => _q = v),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.xs,
          ),
          child: Row(
            children: [
              for (final (k, label) in [
                (null, l10n.adminEveryone),
                ('image', l10n.assignmentPhotos),
                ('document', l10n.assignmentDocuments),
                ('audio', l10n.assignmentAudio),
                ('video', l10n.assignmentVideo),
                ('link', l10n.resourceAddLink),
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Space.xs),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _kind == k,
                    onSelected: (_) => setState(() => _kind = k),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Json>>(
            key: ValueKey('$_kind|$_q|$_reload'),
            future: ref
                .read(teachingRepositoryProvider)
                .contentLibrary(kind: _kind, query: _q),
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(error: snap.error!);
              if (!snap.hasData) return const LoadingView();
              if (snap.data!.isEmpty) {
                return EmptyView(
                  icon: Icons.folder_open,
                  title: l10n.resourcesNone,
                );
              }
              return ListView.separated(
                itemCount: snap.data!.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = snap.data![i];
                  final resource = Resource(r);
                  return ListTile(
                    leading: Icon(resourceIcon(resource.kind)),
                    title: Text(resource.title),
                    subtitle: Text(
                      [
                        if ((r['version'] as num? ?? 1) > 1) 'v${r['version']}',
                        l10n.libraryUsedIn(
                          (r['used_in_lessons'] as num?)?.toInt() ?? 0,
                          (r['used_in_portions'] as num?)?.toInt() ?? 0,
                        ),
                        ?r['uploader'] as String?,
                        ?resource.fileName,
                        if (resource.bytes != null) formatBytes(resource.bytes),
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => showResourcePreview(context, ref, resource),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        switch (v) {
                          case 'edit':
                            await _edit(r);
                          case 'replace':
                            await _replace(r);
                          case 'archive':
                            if (await runAdminAction(
                              context,
                              () => ref
                                  .read(adminRepositoryProvider)
                                  .api
                                  .update(
                                    'resources',
                                    {
                                      'archived_at': DateTime.now()
                                          .toUtc()
                                          .toIso8601String(),
                                    },
                                    filters: {'id': Pg.eq('${r['id']}')},
                                  ),
                            )) {
                              setState(() => _reload++);
                            }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(l10n.libraryRenameTag),
                        ),
                        if (!resource.isLink)
                          PopupMenuItem(
                            value: 'replace',
                            child: Text(l10n.libraryReplace),
                          ),
                        PopupMenuItem(
                          value: 'archive',
                          child: Text(l10n.correctionArchive),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ======================================================== notifications ==

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(notificationsProvider);
    final when = DateFormat.MMMd(l10n.localeName).add_jm();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(teachingRepositoryProvider).markRead();
              ref.invalidate(notificationsProvider);
            },
            child: Text(l10n.notificationsMarkRead),
          ),
        ],
      ),
      body: switch (list) {
        AsyncData(:final value) when value.isEmpty => EmptyView(
          icon: Icons.notifications_none,
          title: l10n.notificationsNone,
        ),
        AsyncData(:final value) => ListView.separated(
          itemCount: value.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final n = value[i];
            return ListTile(
              leading: Icon(switch (n.kind) {
                'portion_assigned' => Icons.menu_book_outlined,
                'correction' => Icons.replay,
                'reviewed' => Icons.check_circle_outline,
                'submission' || 'resubmission' => Icons.mic_none,
                _ => Icons.notifications_none,
              }, color: n.read ? null : Theme.of(context).colorScheme.primary),
              title: Text(
                n.title,
                style: n.read
                    ? null
                    : const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  ?n.body,
                  if (n.at != null) when.format(n.at!.toLocal()),
                ].join('\n'),
              ),
              onTap: () async {
                await ref
                    .read(teachingRepositoryProvider)
                    .markRead(ids: [n.id]);
                ref.invalidate(notificationsProvider);
                if (n.portionId == null || !context.mounted) return;
                final isTeacher =
                    n.kind == 'submission' || n.kind == 'resubmission';
                await context.push(
                  isTeacher
                      ? '/teach/portions/${n.portionId}'
                      : '/learn/portions/${n.portionId}',
                );
              },
            );
          },
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

/// A bell with the number of unread notifications.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unread = (ref.watch(notificationsProvider).value ?? const [])
        .where((n) => !n.read)
        .length;
    return IconButton(
      tooltip: l10n.notificationsTitle,
      onPressed: () async {
        await context.push('/notifications');
        ref.invalidate(notificationsProvider);
      },
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
