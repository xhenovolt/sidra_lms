import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/postgres_api.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../content/data/content_repository.dart';
import '../../content/presentation/resource_widgets.dart';
import '../../curriculum/domain/curriculum_models.dart';
import 'admin_common.dart';
import 'courses_tab.dart';

/// Where a lesson sits: its course, unit and section path.
class LessonPlace {
  const LessonPlace({
    required this.lesson,
    required this.course,
    required this.units,
    required this.nodes,
  });
  final Lesson lesson;
  final Course course;
  final List<CourseUnit> units;
  final List<CurriculumNode> nodes;

  CourseUnit? get unit {
    String? unitId = lesson.unitId;
    for (final n in path) {
      unitId ??= n.unitId;
    }
    return units.where((u) => u.id == unitId).firstOrNull;
  }

  /// Sections from the top down to the lesson's own.
  List<CurriculumNode> get path {
    final byId = {for (final n in nodes) n.id: n};
    final out = <CurriculumNode>[];
    var id = lesson.nodeId;
    while (id != null && byId[id] != null && out.length < 50) {
      out.insert(0, byId[id]!);
      id = byId[id]!.parentId;
    }
    return out;
  }

  String breadcrumb() =>
      [course.title, ?unit?.title, for (final n in path) n.title].join(' › ');
}

final lessonPlaceProvider = FutureProvider.autoDispose
    .family<LessonPlace, String>((ref, lessonId) async {
      final repo = ref.watch(adminRepositoryProvider);
      final lesson = await repo.api.selectOne(
        'lessons',
        filters: {'id': Pg.eq(lessonId)},
      );
      if (lesson == null) throw StateError('Lesson not found');
      final courseId = lesson['course_id'] as String;
      final course = await repo.api.selectOne(
        'courses',
        filters: {'id': Pg.eq(courseId)},
      );
      final byCourse = {'course_id': Pg.eq(courseId)};
      final units = await repo.rows('course_units', filters: byCourse);
      final nodes = await repo.rows('curriculum_nodes', filters: byCourse);
      return LessonPlace(
        lesson: Lesson.fromJson(lesson),
        course: Course.fromJson(course!),
        units: units.map(CourseUnit.fromJson).toList(),
        nodes: nodes.map(CurriculumNode.fromJson).toList(),
      );
    });

/// Lesson editor, first tab: what the lesson teaches and where it sits.
class LessonOverviewTab extends ConsumerWidget {
  const LessonOverviewTab({super.key, required this.lessonId, this.onChanged});
  final String lessonId;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final place = ref.watch(lessonPlaceProvider(lessonId));
    final langs = ref.watch(languagesProvider).value;

    void reload() {
      ref.invalidate(lessonPlaceProvider(lessonId));
      onChanged?.call();
    }

    return switch (place) {
      AsyncData(value: final p) => ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: Text(l10n.lessonLocation),
              subtitle: Text(p.breadcrumb()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/teach/courses/${p.course.id}'),
            ),
          ),
          if (p.lesson.needsReview)
            Card(
              color: theme.colorScheme.tertiaryContainer,
              child: ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(l10n.provisionalTitle),
                subtitle: Text(
                  (p.lesson.metadata['review_note'] as String?) ??
                      l10n.provisionalBody,
                ),
              ),
            ),
          const SizedBox(height: Space.sm),
          Text(l10n.lessonOutcomes, style: theme.textTheme.titleMedium),
          if (p.lesson.objectives.isEmpty)
            Text(l10n.lessonNoOutcomes, style: theme.textTheme.bodySmall)
          else
            for (final o in p.lesson.objectives)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined, size: 20),
                title: Text(o),
              ),
          const SizedBox(height: Space.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.translate),
            title: Text(l10n.lessonLanguage),
            subtitle: Text(
              p.lesson.deliveryLanguage == null
                  ? l10n.lessonLanguageFromCourse(
                      p.course.languages
                          .map((c) => languageName(langs, c))
                          .join(', '),
                    )
                  : languageName(langs, p.lesson.deliveryLanguage!),
            ),
          ),
          if (p.lesson.quranReference != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l10n.lessonQuranReference),
              subtitle: Text(p.lesson.quranReference!),
            ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  if (await showLessonDetailsForm(context, ref, p.lesson)) {
                    reload();
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.lessonEditDetails),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  if (await showMoveLessonDialog(context, ref, p)) reload();
                },
                icon: const Icon(Icons.drive_file_move_outlined),
                label: Text(l10n.lessonMove),
              ),
              OutlinedButton.icon(
                onPressed: () => showCopyLessonDialog(context, ref, p.lesson),
                icon: const Icon(Icons.copy_all_outlined),
                label: Text(l10n.lessonCopy),
              ),
            ],
          ),
        ],
      ),
      AsyncError(:final error) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(lessonPlaceProvider(lessonId)),
      ),
      _ => const LoadingView(),
    };
  }
}

/// Title, summary, outcomes, language and Qur'an reference.
Future<bool> showLessonDetailsForm(
  BuildContext context,
  WidgetRef ref,
  Lesson lesson,
) async {
  final l10n = AppLocalizations.of(context);
  final form = GlobalKey<FormState>();
  final title = TextEditingController(text: lesson.title);
  final summary = TextEditingController(text: lesson.summary);
  final outcomes = TextEditingController(text: lesson.objectives.join('\n'));
  final minutes = TextEditingController(
    text: lesson.estimatedMinutes?.toString(),
  );
  final surah = TextEditingController(text: lesson.quranSurah?.toString());
  final from = TextEditingController(text: lesson.quranAyahStart?.toString());
  final to = TextEditingController(text: lesson.quranAyahEnd?.toString());
  String? language = lesson.deliveryLanguage;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.lessonEditDetails),
        content: SizedBox(
          width: 480,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminField(
                    controller: title,
                    label: l10n.adminTitle,
                    required: true,
                  ),
                  AdminField(
                    controller: summary,
                    label: l10n.adminSummary,
                    maxLines: 3,
                  ),
                  AdminField(
                    controller: outcomes,
                    label: l10n.lessonOutcomes,
                    hint: l10n.lessonOutcomesHint,
                    maxLines: 5,
                  ),
                  LanguageDropdown(
                    value: language,
                    label: l10n.lessonLanguage,
                    noneLabel: l10n.lessonLanguageSameAsCourse,
                    onChanged: (v) => setState(() => language = v),
                  ),
                  AdminField(
                    controller: minutes,
                    label: l10n.adminMinutes,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    l10n.lessonQuranReferenceOptional,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AdminField(
                          controller: surah,
                          label: l10n.quranSurah,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: AdminField(
                          controller: from,
                          label: l10n.quranAyahFrom,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: AdminField(
                          controller: to,
                          label: l10n.quranAyahTo,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(l10n.adminSave),
          ),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return false;
  final s = intOrNull(surah.text);
  return runAdminAction(
    context,
    () => ref.read(adminRepositoryProvider).save('lessons', {
      'title': title.text.trim(),
      'summary': nullIfBlank(summary.text),
      'objectives': [
        for (final l in outcomes.text.split('\n'))
          if (l.trim().isNotEmpty) l.trim(),
      ],
      'delivery_language': language,
      'estimated_minutes': intOrNull(minutes.text),
      'quran_surah': s,
      'quran_ayah_start': s == null ? null : intOrNull(from.text),
      'quran_ayah_end': s == null ? null : intOrNull(to.text),
    }, id: lesson.id),
    success: l10n.adminSaved,
  );
}

/// Move a lesson to another unit or section of the same course.
Future<bool> showMoveLessonDialog(
  BuildContext context,
  WidgetRef ref,
  LessonPlace place,
) async {
  final l10n = AppLocalizations.of(context);
  final options = <(String?, String?, String)>[
    (null, null, l10n.lessonMoveTop),
    for (final u in place.units)
      (u.id, null, '${l10n.adminUnitLabel}: ${u.title}'),
    for (final n in place.nodes) (null, n.id, n.title),
  ];
  final choice = await showDialog<(String?, String?, String)>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.lessonMoveTo(place.lesson.title)),
      children: [
        for (final o in options)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, o),
            child: Text(o.$3),
          ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return false;
  return runAdminAction(
    context,
    () => ref
        .read(contentRepositoryProvider)
        .moveLesson(place.lesson.id, unitId: choice.$1, nodeId: choice.$2),
    success: l10n.lessonMoved(choice.$3),
  );
}

/// Copy a lesson (content and resources) into another course, as a draft.
Future<void> showCopyLessonDialog(
  BuildContext context,
  WidgetRef ref,
  Lesson lesson,
) async {
  final l10n = AppLocalizations.of(context);
  final courses = (await ref.read(adminCoursesProvider.future))
      .where((c) => c.id != lesson.courseId)
      .toList();
  if (!context.mounted) return;
  final target = await showDialog<Course>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.lessonCopyTo(lesson.title)),
      children: [
        for (final c in courses)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, c),
            child: Text(c.title),
          ),
      ],
    ),
  );
  if (target == null || !context.mounted) return;
  String? newId;
  final ok = await runAdminAction(
    context,
    () async => newId = await ref
        .read(contentRepositoryProvider)
        .copyLesson(lesson.id, target.id),
    success: l10n.lessonCopied(target.title),
  );
  if (ok && newId != null && context.mounted) {
    await context.push('/teach/lessons/$newId');
  }
}
