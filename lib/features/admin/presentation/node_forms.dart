import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../curriculum/domain/curriculum_models.dart';
import 'admin_common.dart';
import 'course_builder_screen.dart';

/// New items are visible immediately in a draft course (nothing is public
/// yet), but start as drafts in a live course so learners never see
/// half-built content.
String _defaultStatus(BuilderData data) =>
    data.course.status == PublishStatus.published ? 'draft' : 'published';

Future<bool> _dialog(
  BuildContext context, {
  required String title,
  required Widget Function(StateSetter setState) body,
  required Future<void> Function() onSave,
  required GlobalKey<FormState> form,
}) async {
  final l10n = AppLocalizations.of(context);
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 480,
          child: Form(
            key: form,
            child: SingleChildScrollView(child: body(setState)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final ok = await runAdminAction(context, onSave);
              if (ok && dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(l10n.adminSave),
          ),
        ],
      ),
    ),
  );
  return saved ?? false;
}

Future<bool> showUnitDialog(
  BuildContext context,
  WidgetRef ref, {
  required String courseId,
  CourseUnit? unit,
  int nextPosition = 0,
}) {
  final l10n = AppLocalizations.of(context);
  final title = TextEditingController(text: unit?.title);
  final description = TextEditingController(text: unit?.description);
  final objectives = TextEditingController(
    text: unit?.learningObjectives.join('\n'),
  );
  return _dialog(
    context,
    form: GlobalKey<FormState>(),
    title: unit == null ? l10n.adminAddUnit : l10n.adminEdit,
    body: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AdminField(controller: title, label: l10n.adminTitle, required: true),
        AdminField(
          controller: description,
          label: l10n.adminDescription,
          maxLines: 3,
        ),
        AdminField(
          controller: objectives,
          label: l10n.learningObjectives,
          hint: l10n.adminOnePerLine,
          maxLines: 3,
        ),
      ],
    ),
    onSave: () => ref.read(adminRepositoryProvider).save('course_units', {
      'title': title.text.trim(),
      'description': nullIfBlank(description.text),
      'learning_objectives': [
        for (final l in objectives.text.split('\n'))
          if (l.trim().isNotEmpty) l.trim(),
      ],
      if (unit == null) ...{
        'course_id': courseId,
        'position': nextPosition,
        'status': 'published',
      },
    }, id: unit?.id),
  );
}

Future<bool> showLinkBookDialog(
  BuildContext context,
  WidgetRef ref,
  BuilderData data,
) {
  final l10n = AppLocalizations.of(context);
  final linked = {for (final b in data.linkedBooks) b.book.id};
  final available = data.allBooks.where((b) => !linked.contains(b.id)).toList();
  String? bookId = available.isEmpty ? null : available.first.id;
  String? unitId;
  return _dialog(
    context,
    form: GlobalKey<FormState>(),
    title: l10n.adminLinkBook,
    body: (setState) => available.isEmpty
        ? Text(l10n.adminNoBooksToLink)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: bookId,
                decoration: InputDecoration(labelText: l10n.adminBook),
                items: [
                  for (final b in available)
                    DropdownMenuItem(value: b.id, child: Text(b.title)),
                ],
                onChanged: (v) => setState(() => bookId = v),
              ),
              const SizedBox(height: Space.md),
              DropdownButtonFormField<String?>(
                initialValue: unitId,
                decoration: InputDecoration(labelText: l10n.adminUnitOptional),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.adminWholeCourse),
                  ),
                  for (final u in data.units)
                    DropdownMenuItem(value: u.id, child: Text(u.title)),
                ],
                onChanged: (v) => setState(() => unitId = v),
              ),
            ],
          ),
    onSave: () async {
      if (bookId == null) return;
      await ref.read(adminRepositoryProvider).api.insert('course_books', {
        'course_id': data.course.id,
        'book_id': bookId,
        'unit_id': unitId,
        'position': data.linkedBooks.length,
      });
    },
  );
}

/// Add/edit a curriculum node. When the node comes from a book, the level
/// (e.g. "Surah", "Verse range") and the reference fields that level uses
/// are chosen automatically from the book's structure.
Future<bool> showNodeDialog(
  BuildContext context,
  WidgetRef ref, {
  required BuilderData data,
  CurriculumNode? parent,
  CurriculumNode? existing,
}) {
  final l10n = AppLocalizations.of(context);
  final levelsById = data.levelsById;
  final effectiveParent = existing == null
      ? parent
      : data.nodes.where((n) => n.id == existing.parentId).firstOrNull;
  final parentLevel = effectiveParent?.structureLevelId == null
      ? null
      : levelsById[effectiveParent!.structureLevelId];

  String? unitId = existing?.unitId ?? parent?.unitId;
  String? bookId =
      existing?.bookId ??
      effectiveParent?.bookId ??
      (data.linkedBooks.length == 1 ? data.linkedBooks.first.book.id : null);

  BookStructureLevel? levelFor(String? book) {
    if (book == null) return null;
    final levels = data.levelsByBook[book] ?? const [];
    final depth = parentLevel == null ? 1 : parentLevel.depth + 1;
    return levels.where((l) => l.depth == depth).firstOrNull;
  }

  final title = TextEditingController(text: existing?.title);
  final type = TextEditingController(text: existing?.nodeType ?? 'section');
  final description = TextEditingController(text: existing?.description);
  final label = TextEditingController(text: existing?.referenceLabel);
  final pageStart = TextEditingController(
    text: existing?.pageStart?.toString(),
  );
  final pageEnd = TextEditingController(text: existing?.pageEnd?.toString());
  final chapter = TextEditingController(
    text: existing?.chapterNumber?.toString(),
  );
  final surah = TextEditingController(text: existing?.surahNumber?.toString());
  final verseStart = TextEditingController(
    text: existing?.verseStart?.toString(),
  );
  final verseEnd = TextEditingController(text: existing?.verseEnd?.toString());

  return _dialog(
    context,
    form: GlobalKey<FormState>(),
    title: existing != null
        ? l10n.adminEdit
        : (levelFor(bookId)?.labelSingular ?? l10n.adminAddSection),
    body: (setState) {
      final level = levelFor(bookId);
      final showAllRefs = level == null;
      Widget num(TextEditingController c, String label) => Expanded(
        child: AdminField(
          controller: c,
          label: label,
          keyboardType: TextInputType.number,
        ),
      );
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (effectiveParent == null && data.units.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              initialValue: unitId,
              decoration: InputDecoration(labelText: l10n.adminUnitOptional),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.adminNoUnit)),
                for (final u in data.units)
                  DropdownMenuItem(value: u.id, child: Text(u.title)),
              ],
              onChanged: (v) => setState(() => unitId = v),
            ),
            const SizedBox(height: Space.md),
          ],
          if (effectiveParent?.bookId == null &&
              data.linkedBooks.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              initialValue: bookId,
              decoration: InputDecoration(labelText: l10n.adminFromBook),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.adminNoBook)),
                for (final b in data.linkedBooks)
                  DropdownMenuItem(value: b.book.id, child: Text(b.book.title)),
              ],
              onChanged: (v) => setState(() => bookId = v),
            ),
            const SizedBox(height: Space.md),
          ],
          if (level != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Text(
                '${l10n.adminLevel}: ${level.labelSingular}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            )
          else
            AdminField(
              controller: type,
              label: l10n.adminSectionType,
              hint: l10n.adminSectionTypeHint,
            ),
          AdminField(controller: title, label: l10n.adminTitle, required: true),
          if (showAllRefs || level.usesSurah || level.usesVerses)
            Row(
              children: [
                if (showAllRefs || level.usesSurah) num(surah, l10n.adminSurah),
                if (showAllRefs || level.usesSurah)
                  const SizedBox(width: Space.xs),
                if (showAllRefs || level.usesVerses) ...[
                  num(verseStart, l10n.adminVerseFrom),
                  const SizedBox(width: Space.xs),
                  num(verseEnd, l10n.adminVerseTo),
                ],
              ],
            ),
          if (showAllRefs || level.usesPage)
            Row(
              children: [
                num(pageStart, l10n.adminPageFrom),
                const SizedBox(width: Space.xs),
                num(pageEnd, l10n.adminPageTo),
              ],
            ),
          if (showAllRefs || level.usesChapter)
            Row(children: [num(chapter, l10n.adminChapter)]),
          AdminField(
            controller: label,
            label: l10n.adminReferenceLabel,
            hint: l10n.adminReferenceLabelHint,
          ),
          AdminField(
            controller: description,
            label: l10n.adminDescription,
            maxLines: 3,
          ),
        ],
      );
    },
    onSave: () {
      final level = levelFor(bookId);
      return ref.read(adminRepositoryProvider).save('curriculum_nodes', {
        'title': title.text.trim(),
        'description': nullIfBlank(description.text),
        'reference_label': nullIfBlank(label.text),
        'node_type':
            level?.nodeType ??
            (slugify(type.text).replaceAll('-', '_').isEmpty
                ? 'section'
                : slugify(type.text).replaceAll('-', '_')),
        'book_id': bookId,
        'structure_level_id': level?.id,
        'page_start': intOrNull(pageStart.text),
        'page_end': intOrNull(pageEnd.text),
        'chapter_number': intOrNull(chapter.text),
        'surah_number': intOrNull(surah.text),
        'verse_start': intOrNull(verseStart.text),
        'verse_end': intOrNull(verseEnd.text),
        if (existing == null) ...{
          'course_id': data.course.id,
          'parent_id': parent?.id,
          'unit_id': parent == null ? unitId : null,
          'position': nextPosition(
            data,
            parentNodeId: parent?.id,
            unitId: parent == null ? unitId : null,
          ),
          'status': _defaultStatus(data),
        } else if (effectiveParent == null) ...{
          'unit_id': unitId,
        },
      }, id: existing?.id);
    },
  );
}

Future<bool> showLessonDialog(
  BuildContext context,
  WidgetRef ref, {
  required BuilderData data,
  CurriculumNode? node,
  Lesson? existing,
}) {
  final l10n = AppLocalizations.of(context);
  final title = TextEditingController(text: existing?.title);
  final summary = TextEditingController(text: existing?.summary);
  final minutes = TextEditingController(
    text: existing?.estimatedMinutes?.toString(),
  );
  var preview = existing?.isPreview ?? false;
  String? unitId = existing?.unitId ?? node?.unitId;
  final nodeId = existing?.nodeId ?? node?.id;

  return _dialog(
    context,
    form: GlobalKey<FormState>(),
    title: existing == null ? l10n.adminAddLesson : l10n.adminEdit,
    body: (setState) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (nodeId == null && data.units.isNotEmpty) ...[
          DropdownButtonFormField<String?>(
            initialValue: unitId,
            decoration: InputDecoration(labelText: l10n.adminUnitOptional),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.adminNoUnit)),
              for (final u in data.units)
                DropdownMenuItem(value: u.id, child: Text(u.title)),
            ],
            onChanged: (v) => setState(() => unitId = v),
          ),
          const SizedBox(height: Space.md),
        ],
        AdminField(controller: title, label: l10n.adminTitle, required: true),
        AdminField(controller: summary, label: l10n.adminSummary, maxLines: 3),
        AdminField(
          controller: minutes,
          label: l10n.adminMinutes,
          keyboardType: TextInputType.number,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: preview,
          onChanged: (v) => setState(() => preview = v),
          title: Text(l10n.adminPreviewLesson),
          subtitle: Text(l10n.adminPreviewLessonHint),
        ),
      ],
    ),
    onSave: () => ref.read(adminRepositoryProvider).save('lessons', {
      'title': title.text.trim(),
      'summary': nullIfBlank(summary.text),
      'estimated_minutes': intOrNull(minutes.text),
      'is_preview': preview,
      if (existing == null) ...{
        'course_id': data.course.id,
        'node_id': nodeId,
        'unit_id': nodeId == null ? unitId : null,
        'position': nextPosition(
          data,
          parentNodeId: nodeId,
          unitId: nodeId == null ? unitId : null,
        ),
        'status': _defaultStatus(data),
      },
    }, id: existing?.id),
  );
}
