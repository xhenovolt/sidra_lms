import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/network/postgres_api.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../lessons/domain/content_blocks.dart';
import '../../lessons/presentation/block_renderer.dart';
import 'admin_common.dart';

class _EditorData {
  const _EditorData(this.lesson, this.rows);
  final Lesson lesson;
  final List<Json> rows; // raw block rows (for editing)

  List<ContentBlock> get blocks => rows.map(ContentBlock.fromJson).toList();
}

final _editorProvider = FutureProvider.autoDispose.family<_EditorData, String>((
  ref,
  lessonId,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  final lesson = await repo.api.selectOne(
    'lessons',
    filters: {'id': Pg.eq(lessonId)},
  );
  if (lesson == null) throw StateError('Lesson not found');
  final rows = await repo.rows(
    'lesson_content_blocks',
    filters: {'lesson_id': Pg.eq(lessonId)},
  );
  return _EditorData(Lesson.fromJson(lesson), rows);
});

/// Block types offered to teachers, in the order they are most used.
enum _NewBlock {
  text('rich_text', Icons.notes),
  heading('heading', Icons.title),
  quran('quran_text', Icons.menu_book),
  translation('translation', Icons.translate),
  transliteration('transliteration', Icons.abc),
  image('image', Icons.image_outlined),
  audio('audio', Icons.graphic_eq),
  video('video', Icons.movie_outlined),
  attachment('attachment', Icons.attach_file),
  reference('reference', Icons.bookmark_border),
  callout('callout', Icons.lightbulb_outline),
  quiz('assessment', Icons.quiz_outlined),
  divider('divider', Icons.horizontal_rule);

  const _NewBlock(this.dbType, this.icon);
  final String dbType;
  final IconData icon;

  bool get isMedia =>
      this == image || this == audio || this == video || this == attachment;
}

class LessonEditorScreen extends ConsumerWidget {
  const LessonEditorScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(_editorProvider(lessonId));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(data.value?.lesson.title ?? l10n.lessonTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.adminContent),
              Tab(text: l10n.adminPreview),
            ],
          ),
        ),
        floatingActionButton: data.hasValue
            ? FloatingActionButton.extended(
                onPressed: () => _addBlock(context, ref, data.value!),
                icon: const Icon(Icons.add),
                label: Text(l10n.adminAddContent),
              )
            : null,
        body: switch (data) {
          AsyncData(:final value) => TabBarView(
            children: [
              _BlockList(data: value),
              ListView.separated(
                padding: const EdgeInsets.all(Space.lg),
                itemCount: value.blocks.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.md),
                itemBuilder: (_, i) => BlockView(block: value.blocks[i]),
              ),
            ],
          ),
          AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(_editorProvider(lessonId)),
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }

  Future<void> _addBlock(
    BuildContext context,
    WidgetRef ref,
    _EditorData data,
  ) async {
    final l10n = AppLocalizations.of(context);
    final type = await showModalBottomSheet<_NewBlock>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          padding: const EdgeInsets.all(Space.md),
          children: [
            for (final t in _NewBlock.values)
              InkWell(
                borderRadius: BorderRadius.circular(Radii.md),
                onTap: () => Navigator.pop(context, t),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.icon, size: 28),
                    const SizedBox(height: Space.xs),
                    Text(
                      _typeLabel(l10n, t.dbType),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    if (type == null || !context.mounted) return;
    final position = data.rows.isEmpty
        ? 0
        : data.rows
                  .map((r) => r['position'] as int)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    final saved = await showBlockEditor(
      context,
      ref,
      lesson: data.lesson,
      dbType: type.dbType,
      position: position,
    );
    if (saved) ref.invalidate(_editorProvider(lessonId));
  }
}

String _typeLabel(AppLocalizations l10n, String t) => switch (t) {
  'rich_text' => l10n.adminBlockText,
  'heading' => l10n.adminBlockHeading,
  'quran_text' => l10n.adminBlockQuran,
  'translation' => l10n.adminBlockTranslation,
  'transliteration' => l10n.adminBlockTransliteration,
  'image' => l10n.adminBlockImage,
  'audio' => l10n.adminBlockAudio,
  'video' => l10n.adminBlockVideo,
  'attachment' => l10n.adminBlockAttachment,
  'reference' => l10n.adminBlockReference,
  'callout' => l10n.adminBlockCallout,
  'assessment' => l10n.adminBlockQuiz,
  'divider' => l10n.adminBlockDivider,
  _ => t,
};

class _BlockList extends ConsumerWidget {
  const _BlockList({required this.data});
  final _EditorData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(adminRepositoryProvider);
    final rows = List.of(data.rows)
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    void reload() => ref.invalidate(_editorProvider(data.lesson.id));

    if (rows.isEmpty) {
      return EmptyView(
        icon: Icons.post_add,
        title: l10n.adminEmptyLessonTitle,
        message: l10n.adminEmptyLessonBody,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 96),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        final type = row['block_type'] as String;
        final block = ContentBlock.fromJson(row);
        Future<void> swap(int j) async {
          final other = rows[j];
          if (await runAdminAction(
            context,
            () => repo.swapPositions(
              'lesson_content_blocks',
              (id: row['id'] as String, position: row['position'] as int),
              (id: other['id'] as String, position: other['position'] as int),
            ),
          )) {
            reload();
          }
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                dense: true,
                title: Text(_typeLabel(l10n, type)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.adminMoveUp,
                      onPressed: i == 0 ? null : () => swap(i - 1),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: l10n.adminMoveDown,
                      onPressed: i == rows.length - 1
                          ? null
                          : () => swap(i + 1),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          if (await showBlockEditor(
                            context,
                            ref,
                            lesson: data.lesson,
                            dbType: type,
                            position: row['position'] as int,
                            existing: row,
                          )) {
                            reload();
                          }
                        } else if (v == 'quiz' &&
                            row['assessment_id'] != null) {
                          if (context.mounted) {
                            await context.push(
                              '/teach/assessments/${row['assessment_id']}',
                            );
                          }
                        } else if (v == 'delete') {
                          if (await confirm(
                                context,
                                title: l10n.adminDeleteTitle,
                                message: l10n.adminDeleteBlockBody,
                                destructive: true,
                              ) &&
                              context.mounted &&
                              await runAdminAction(
                                context,
                                () => repo.deleteRow(
                                  'lesson_content_blocks',
                                  row['id'] as String,
                                ),
                              )) {
                            reload();
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        if (type != 'divider')
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(l10n.adminEdit),
                          ),
                        if (type == 'assessment')
                          PopupMenuItem(
                            value: 'quiz',
                            child: Text(l10n.adminEditQuestions),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.adminDelete),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  0,
                  Space.md,
                  Space.md,
                ),
                child: IgnorePointer(child: BlockView(block: block)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Create or edit one block. Media blocks upload a file first; quiz blocks
/// create an assessment and open its editor.
Future<bool> showBlockEditor(
  BuildContext context,
  WidgetRef ref, {
  required Lesson lesson,
  required String dbType,
  required int position,
  Json? existing,
}) async {
  final l10n = AppLocalizations.of(context);
  final repo = ref.read(adminRepositoryProvider);
  final body = Json.from((existing?['body'] as Map?) ?? const {});

  Future<bool> save(Json values) => runAdminAction(
    context,
    () => repo.save('lesson_content_blocks', {
      ...values,
      if (existing == null) ...{
        'lesson_id': lesson.id,
        'position': position,
        'block_type': dbType,
      },
    }, id: existing?['id'] as String?),
  );

  switch (dbType) {
    case 'divider':
      return save({'body': <String, dynamic>{}});

    case 'assessment':
      if (existing != null) return false;
      final id = await _createQuiz(context, ref, lesson);
      if (id == null || !context.mounted) return false;
      final ok = await save({'assessment_id': id, 'body': <String, dynamic>{}});
      if (ok && context.mounted) {
        await context.push('/teach/assessments/$id');
      }
      return ok;

    case 'image' || 'audio' || 'video' || 'attachment':
      String? mediaId = existing?['media_asset_id'] as String?;
      final caption = TextEditingController(
        text: (body['caption'] ?? body['title']) as String?,
      );
      final transcript = TextEditingController(
        text: body['transcript'] as String?,
      );
      var uploading = false;
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(_typeLabel(l10n, dbType)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: uploading
                          ? null
                          : () async {
                              final file = await pickLocalFile(switch (dbType) {
                                'image' => FileType.image,
                                'video' => FileType.video,
                                'audio' => FileType.audio,
                                _ => FileType.any,
                              });
                              if (file == null || !context.mounted) return;
                              final profile = await ref.read(
                                profileProvider.future,
                              );
                              setState(() => uploading = true);
                              if (!context.mounted) return;
                              await runAdminAction(context, () async {
                                mediaId = await repo.uploadMedia(
                                  filePath: file.path,
                                  fileName: file.name,
                                  kind: dbType == 'attachment'
                                      ? 'document'
                                      : dbType,
                                  uploaderId: profile.id,
                                  folder: 'lessons',
                                );
                              });
                              if (context.mounted) {
                                setState(() => uploading = false);
                              }
                            },
                      icon: uploading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              mediaId == null
                                  ? Icons.upload
                                  : Icons.check_circle,
                            ),
                      label: Text(
                        mediaId == null
                            ? l10n.adminChooseFile
                            : l10n.adminFileUploaded,
                      ),
                    ),
                    const SizedBox(height: Space.md),
                    AdminField(
                      controller: caption,
                      label: dbType == 'image'
                          ? l10n.adminCaption
                          : l10n.adminTitle,
                    ),
                    if (dbType == 'audio')
                      AdminField(
                        controller: transcript,
                        label: l10n.adminTranscript,
                        maxLines: 4,
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.adminCancel),
              ),
              FilledButton(
                onPressed: mediaId == null || uploading
                    ? null
                    : () => Navigator.pop(dialogContext, true),
                child: Text(l10n.adminSave),
              ),
            ],
          ),
        ),
      );
      if (result != true || !context.mounted) return false;
      return save({
        'media_asset_id': mediaId,
        'body': {
          if (dbType == 'image') 'caption': nullIfBlank(caption.text),
          if (dbType != 'image') 'title': nullIfBlank(caption.text),
          if (dbType == 'audio') 'transcript': nullIfBlank(transcript.text),
        }..removeWhere((_, v) => v == null),
      });

    default:
      final values = await _textBlockDialog(context, dbType, body);
      if (values == null || !context.mounted) return false;
      return save({'body': values});
  }
}

Future<String?> _createQuiz(
  BuildContext context,
  WidgetRef ref,
  Lesson lesson,
) async {
  final l10n = AppLocalizations.of(context);
  final title = TextEditingController(
    text: '${lesson.title} — ${l10n.quizTitle}',
  );
  var graded = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.adminBlockQuiz),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminField(controller: title, label: l10n.adminTitle),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: graded,
              onChanged: (v) => setState(() => graded = v),
              title: Text(l10n.adminGradedQuiz),
              subtitle: Text(
                graded ? l10n.adminGradedQuizHint : l10n.adminPracticeQuizHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.adminCreate),
          ),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return null;
  String? id;
  await runAdminAction(context, () async {
    final row = await ref.read(adminRepositoryProvider).save('assessments', {
      'course_id': lesson.courseId,
      'lesson_id': lesson.id,
      'title': title.text.trim(),
      'kind': graded ? 'graded' : 'practice',
      'grading': 'auto',
      'status': 'published',
    });
    id = row['id'] as String;
  });
  return id;
}

Future<Json?> _textBlockDialog(BuildContext context, String dbType, Json body) {
  final l10n = AppLocalizations.of(context);
  final form = GlobalKey<FormState>();
  final main = TextEditingController(
    text: (body['text'] ?? body['arabic'] ?? body['citation']) as String?,
  );
  final a = TextEditingController(
    text:
        (body['translator'] ?? body['source'] ?? body['surah']?.toString())
            as String?,
  );
  final b = TextEditingController(
    text: (body['url'] ?? body['verse_start']?.toString()) as String?,
  );
  final c = TextEditingController(text: body['verse_end']?.toString());
  var level = (body['level'] as num?)?.toInt() ?? 2;
  var tone = (body['tone'] as String?) ?? 'info';
  var language = (body['language'] as String?) ?? 'en';

  return showDialog<Json>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(_typeLabel(l10n, dbType)),
        content: SizedBox(
          width: 520,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminField(
                    controller: main,
                    required: true,
                    label: switch (dbType) {
                      'quran_text' => l10n.adminArabicText,
                      'reference' => l10n.adminCitation,
                      _ => l10n.adminText,
                    },
                    hint: dbType == 'rich_text' ? l10n.adminTextHint : null,
                    maxLines: dbType == 'heading' ? 1 : 8,
                    textDirection: dbType == 'quran_text'
                        ? TextDirection.rtl
                        : null,
                  ),
                  if (dbType == 'heading')
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('H1')),
                        ButtonSegment(value: 2, label: Text('H2')),
                        ButtonSegment(value: 3, label: Text('H3')),
                      ],
                      selected: {level},
                      onSelectionChanged: (s) =>
                          setState(() => level = s.first),
                    ),
                  if (dbType == 'quran_text')
                    Row(
                      children: [
                        Expanded(
                          child: AdminField(
                            controller: a,
                            label: l10n.adminSurah,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: Space.xs),
                        Expanded(
                          child: AdminField(
                            controller: b,
                            label: l10n.adminVerseFrom,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: Space.xs),
                        Expanded(
                          child: AdminField(
                            controller: c,
                            label: l10n.adminVerseTo,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  if (dbType == 'translation') ...[
                    DropdownButtonFormField<String>(
                      initialValue: language,
                      decoration: InputDecoration(
                        labelText: l10n.adminLanguage,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                        DropdownMenuItem(value: 'sw', child: Text('Kiswahili')),
                        DropdownMenuItem(value: 'lg', child: Text('Luganda')),
                      ],
                      onChanged: (v) => setState(() => language = v!),
                    ),
                    const SizedBox(height: Space.md),
                    AdminField(controller: a, label: l10n.adminTranslator),
                  ],
                  if (dbType == 'reference') ...[
                    AdminField(controller: a, label: l10n.adminSource),
                    AdminField(
                      controller: b,
                      label: l10n.adminLink,
                      keyboardType: TextInputType.url,
                    ),
                  ],
                  if (dbType == 'callout')
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'info',
                          label: Text(l10n.adminToneInfo),
                        ),
                        ButtonSegment(
                          value: 'note',
                          label: Text(l10n.adminToneNote),
                        ),
                        ButtonSegment(
                          value: 'warning',
                          label: Text(l10n.adminToneWarning),
                        ),
                      ],
                      selected: {tone},
                      onSelectionChanged: (s) => setState(() => tone = s.first),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              final text = main.text.trim();
              Navigator.pop(
                dialogContext,
                <String, dynamic>{
                  ...switch (dbType) {
                    'heading' => {'text': text, 'level': level},
                    'rich_text' => {'text': text, 'format': 'markdown'},
                    'quran_text' => {
                      'arabic': text,
                      'surah': intOrNull(a.text),
                      'verse_start': intOrNull(b.text),
                      'verse_end': intOrNull(c.text),
                    },
                    'translation' => {
                      'text': text,
                      'language': language,
                      'translator': nullIfBlank(a.text),
                    },
                    'reference' => {
                      'citation': text,
                      'source': nullIfBlank(a.text),
                      'url': nullIfBlank(b.text),
                    },
                    'callout' => {'text': text, 'tone': tone},
                    _ => {'text': text},
                  },
                }..removeWhere((_, v) => v == null),
              );
            },
            child: Text(l10n.adminSave),
          ),
        ],
      ),
    ),
  );
}
