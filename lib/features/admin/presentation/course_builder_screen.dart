import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../curriculum/domain/curriculum_tree.dart';
import '../../../core/network/postgres_api.dart';
import '../../../core/data/repository_providers.dart';
import 'admin_common.dart';
import 'admin_shell.dart';
import 'course_lifecycle_card.dart';
import '../../content/data/content_repository.dart';
import '../../content/presentation/resource_widgets.dart';
import 'course_people_section.dart';
import 'lesson_overview_tab.dart';
import 'courses_tab.dart';
import 'node_forms.dart';

/// Everything the builder needs for one course (drafts included for staff).
class BuilderData {
  const BuilderData({
    required this.course,
    required this.units,
    required this.nodes,
    required this.lessons,
    required this.linkedBooks,
    required this.allBooks,
    required this.levelsByBook,
  });

  final Course course;
  final List<CourseUnit> units;
  final List<CurriculumNode> nodes;
  final List<Lesson> lessons;
  final List<({Book book, String? unitId})> linkedBooks;
  final List<Book> allBooks;
  final Map<String, List<BookStructureLevel>> levelsByBook;

  Map<String, BookStructureLevel> get levelsById => {
    for (final ls in levelsByBook.values)
      for (final l in ls) l.id: l,
  };
}

final builderDataProvider = FutureProvider.autoDispose
    .family<BuilderData, String>((ref, courseId) async {
      final repo = ref.watch(adminRepositoryProvider);
      final byCourse = {'course_id': Pg.eq(courseId)};
      final courseRow = await repo.api.selectOne(
        'courses',
        filters: {'id': Pg.eq(courseId)},
      );
      if (courseRow == null) throw StateError('Course not found');
      final results = await Future.wait([
        repo.rows('course_units', filters: byCourse),
        repo.rows('curriculum_nodes', filters: byCourse),
        repo.rows('lessons', filters: byCourse),
        repo.rows('course_books', filters: byCourse),
      ]);
      final allBooks = await repo.books();
      final bookById = {for (final b in allBooks) b.id: b};
      final linked = [
        for (final cb in results[3])
          if (bookById[cb['book_id']] != null)
            (book: bookById[cb['book_id']]!, unitId: cb['unit_id'] as String?),
      ];
      final levels = <String, List<BookStructureLevel>>{};
      for (final l in linked) {
        levels[l.book.id] = await repo.levelsForBook(l.book.id);
      }
      return BuilderData(
        course: Course.fromJson(courseRow),
        units: results[0].map(CourseUnit.fromJson).toList(),
        nodes: results[1].map(CurriculumNode.fromJson).toList(),
        lessons: results[2].map(Lesson.fromJson).toList(),
        linkedBooks: linked,
        allBooks: allBooks,
        levelsByBook: levels,
      );
    });

class CourseBuilderScreen extends ConsumerWidget {
  const CourseBuilderScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(builderDataProvider(courseId));
    return Scaffold(
      appBar: AppBar(title: Text(data.value?.course.title ?? '…')),
      body: switch (data) {
        AsyncData(:final value) => _Builder(data: value),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(builderDataProvider(courseId)),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _Builder extends ConsumerWidget {
  const _Builder({required this.data});
  final BuilderData data;

  void _reload(WidgetRef ref) {
    ref.invalidate(builderDataProvider(data.course.id));
    ref.invalidate(adminCoursesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final course = data.course;
    final tree = CurriculumTree.build(
      units: data.units,
      nodes: data.nodes,
      lessons: data.lessons,
      order: const [],
      levelLabels: {
        for (final l in data.levelsById.values) l.id: l.labelSingular,
      },
    );

    return RefreshIndicator(
      onRefresh: () => ref.refresh(builderDataProvider(course.id).future),
      child: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          CourseLifecycleCard(course: course, onChanged: () => _reload(ref)),
          _CourseFacts(course: course),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.adminEditCourse),
                  onTap: () => context.push(
                    '/teach/courses/${course.id}/edit',
                    extra: course,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: Text(l10n.adminPreviewAsLearner),
                  onTap: () => context.push('/courses/${course.id}'),
                ),
              ],
            ),
          ),
          _SectionTitle(
            l10n.adminUnits,
            action: TextButton.icon(
              onPressed: () async {
                if (await showUnitDialog(
                  context,
                  ref,
                  courseId: course.id,
                  nextPosition: data.units.length,
                )) {
                  _reload(ref);
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.adminAddUnit),
            ),
          ),
          if (data.units.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Text(
                l10n.adminUnitsHint,
                style: theme.textTheme.bodySmall,
              ),
            ),
          for (final (i, u) in (List.of(
            data.units,
          )..sort((a, b) => a.position.compareTo(b.position))).indexed)
            _UnitTile(
              unit: u,
              index: i,
              units: data.units,
              onChanged: () => _reload(ref),
            ),
          _SectionTitle(
            l10n.booksTitle,
            action: TextButton.icon(
              onPressed: () async {
                if (await showLinkBookDialog(context, ref, data)) _reload(ref);
              },
              icon: const Icon(Icons.link),
              label: Text(l10n.adminLinkBook),
            ),
          ),
          for (final b in data.linkedBooks)
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(b.book.title),
              subtitle: Text(
                [
                  for (final l in data.levelsByBook[b.book.id] ?? const [])
                    l.labelSingular,
                ].join(' → '),
              ),
            ),
          const SizedBox(height: Space.md),
          ResourceManager(target: ResourceTarget.course, id: course.id),
          _SectionTitle(
            l10n.courseOutline,
            action: PopupMenuButton<String>(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: l10n.adminAdd,
              onSelected: (v) async {
                final ok = v == 'node'
                    ? await showNodeDialog(context, ref, data: data)
                    : await showLessonDialog(context, ref, data: data);
                if (ok) _reload(ref);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'node', child: Text(l10n.adminAddSection)),
                PopupMenuItem(
                  value: 'lesson',
                  child: Text(l10n.adminAddLesson),
                ),
              ],
            ),
          ),
          if (tree.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Text(
                l10n.adminOutlineHint,
                style: theme.textTheme.bodySmall,
              ),
            ),
          for (final item in tree.items)
            _AdminOutlineItem(
              item: item,
              data: data,
              depth: 0,
              siblings: tree.items,
              onChanged: () => _reload(ref),
            ),
          CoursePeopleSection(
            courseId: course.id,
            isAdmin: ref.watch(profileProvider).value?.isAdmin ?? false,
            units: data.units,
          ),
          // Only never-published drafts can be deleted; others are archived.
          if (course.publishedAt == null &&
              (ref
                      .watch(myPermissionsProvider)
                      .value
                      ?.contains('courses.archive') ??
                  false)) ...[
            const SizedBox(height: Space.xl),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () => deleteCourseFlow(
                context,
                ref,
                courseId: course.id,
                title: course.title,
              ),
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.adminDeleteCourse),
            ),
          ],
          const SizedBox(height: Space.xxl),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?action,
      ],
    ),
  );
}

class _UnitTile extends ConsumerWidget {
  const _UnitTile({
    required this.unit,
    required this.index,
    required this.units,
    required this.onChanged,
  });

  final CourseUnit unit;
  final int index;
  final List<CourseUnit> units;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(adminRepositoryProvider);
    final sorted = List.of(units)
      ..sort((a, b) => a.position.compareTo(b.position));
    Future<void> swapWith(int other) async {
      final o = sorted[other];
      if (await runAdminAction(
        context,
        () => repo.swapPositions(
          'course_units',
          (id: unit.id, position: unit.position),
          (id: o.id, position: o.position),
        ),
      )) {
        onChanged();
      }
    }

    return Card(
      child: ListTile(
        title: Text(unit.title),
        subtitle: Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusChip(published: unit.status == PublishStatus.published),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            switch (v) {
              case 'up':
                await swapWith(index - 1);
              case 'down':
                await swapWith(index + 1);
              case 'edit':
                if (await showUnitDialog(
                  context,
                  ref,
                  courseId: unit.courseId,
                  unit: unit,
                )) {
                  onChanged();
                }
              case 'publish':
                if (await runAdminAction(
                  context,
                  () => repo.save('course_units', {
                    'status': unit.status == PublishStatus.published
                        ? 'draft'
                        : 'published',
                  }, id: unit.id),
                )) {
                  onChanged();
                }
              case 'delete':
                if (await confirm(
                      context,
                      title: l10n.adminDeleteTitle,
                      message: l10n.adminDeleteUnitBody,
                      destructive: true,
                    ) &&
                    context.mounted &&
                    await runAdminAction(
                      context,
                      () => repo.deleteRow('course_units', unit.id),
                    )) {
                  onChanged();
                }
            }
          },
          itemBuilder: (_) => [
            if (index > 0)
              PopupMenuItem(value: 'up', child: Text(l10n.adminMoveUp)),
            if (index < sorted.length - 1)
              PopupMenuItem(value: 'down', child: Text(l10n.adminMoveDown)),
            PopupMenuItem(value: 'edit', child: Text(l10n.adminEdit)),
            PopupMenuItem(
              value: 'publish',
              child: Text(
                unit.status == PublishStatus.published
                    ? l10n.adminUnpublish
                    : l10n.adminPublish,
              ),
            ),
            PopupMenuItem(value: 'delete', child: Text(l10n.adminDelete)),
          ],
        ),
      ),
    );
  }
}

/// One outline row with its admin actions (recursive).
class _AdminOutlineItem extends ConsumerWidget {
  const _AdminOutlineItem({
    required this.item,
    required this.data,
    required this.depth,
    required this.siblings,
    required this.onChanged,
  });

  final OutlineItem item;
  final BuilderData data;
  final int depth;
  final List<OutlineItem> siblings;
  final VoidCallback onChanged;

  static ({String table, String id, int position})? _ref(OutlineItem i) =>
      switch (i) {
        NodeItem(:final node) => (
          table: 'curriculum_nodes',
          id: node.id,
          position: node.position,
        ),
        LessonItem(:final lesson) => (
          table: 'lessons',
          id: lesson.id,
          position: lesson.position,
        ),
        UnitItem() => null,
      };

  Future<void> _move(BuildContext context, WidgetRef ref, int delta) async {
    final movable = siblings.where((s) => _ref(s) != null).toList();
    final i = movable.indexOf(item);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= movable.length) return;
    final a = _ref(item)!, b = _ref(movable[j])!;
    final repo = ref.read(adminRepositoryProvider);
    // Nodes/lessons have no unique position constraint: swap directly.
    // Equal positions (legacy data) get distinct values.
    final bPos = a.position == b.position ? b.position + delta : b.position;
    if (await runAdminAction(context, () async {
      await repo.save(a.table, {'position': bPos}, id: a.id);
      await repo.save(b.table, {'position': a.position}, id: b.id);
    })) {
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = ref.read(adminRepositoryProvider);
    final pad = EdgeInsetsDirectional.only(start: depth * Space.md);

    List<PopupMenuEntry<String>> commonItems(bool published) => [
      PopupMenuItem(value: 'up', child: Text(l10n.adminMoveUp)),
      PopupMenuItem(value: 'down', child: Text(l10n.adminMoveDown)),
      PopupMenuItem(value: 'edit', child: Text(l10n.adminEdit)),
      PopupMenuItem(
        value: 'publish',
        child: Text(published ? l10n.adminUnpublish : l10n.adminPublish),
      ),
      PopupMenuItem(value: 'delete', child: Text(l10n.adminDelete)),
    ];

    Future<void> togglePublish(String table, String id, bool published) async {
      if (await runAdminAction(
        context,
        () => repo.save(table, {
          'status': published ? 'draft' : 'published',
        }, id: id),
      )) {
        onChanged();
      }
    }

    Future<void> delete(String table, String id, String message) async {
      if (await confirm(
            context,
            title: l10n.adminDeleteTitle,
            message: message,
            destructive: true,
          ) &&
          context.mounted &&
          await runAdminAction(context, () => repo.deleteRow(table, id))) {
        onChanged();
      }
    }

    switch (item) {
      case UnitItem(:final unit, :final children):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: Space.md, bottom: Space.xxs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      unit.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => showResourcesSheet(
                      context,
                      target: ResourceTarget.unit,
                      id: unit.id,
                      title: unit.title,
                    ),
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: Text(l10n.resourcesTitle),
                  ),
                ],
              ),
            ),
            for (final c in children)
              _AdminOutlineItem(
                item: c,
                data: data,
                depth: depth,
                siblings: children,
                onChanged: onChanged,
              ),
          ],
        );
      case NodeItem(:final node, :final children, :final levelLabel):
        final published = node.status == PublishStatus.published;
        return Padding(
          padding: pad,
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(node.title),
                  subtitle: Wrap(
                    spacing: Space.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        [
                          levelLabel ?? node.nodeType,
                          ?node.locator,
                        ].join(' · '),
                      ),
                      StatusChip(published: published),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      switch (v) {
                        case 'child':
                          if (await showNodeDialog(
                            context,
                            ref,
                            data: data,
                            parent: node,
                          )) {
                            onChanged();
                          }
                        case 'lesson':
                          if (await showLessonDialog(
                            context,
                            ref,
                            data: data,
                            node: node,
                          )) {
                            onChanged();
                          }
                        case 'resources':
                          await showResourcesSheet(
                            context,
                            target: ResourceTarget.node,
                            id: node.id,
                            title: node.title,
                          );
                        case 'up':
                          await _move(context, ref, -1);
                        case 'down':
                          await _move(context, ref, 1);
                        case 'edit':
                          if (await showNodeDialog(
                            context,
                            ref,
                            data: data,
                            existing: node,
                          )) {
                            onChanged();
                          }
                        case 'publish':
                          await togglePublish(
                            'curriculum_nodes',
                            node.id,
                            published,
                          );
                        case 'delete':
                          await delete(
                            'curriculum_nodes',
                            node.id,
                            l10n.adminDeleteNodeBody,
                          );
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'child',
                        child: Text(l10n.adminAddSubsection),
                      ),
                      PopupMenuItem(
                        value: 'lesson',
                        child: Text(l10n.adminAddLesson),
                      ),
                      PopupMenuItem(
                        value: 'resources',
                        child: Text(l10n.resourcesTitle),
                      ),
                      const PopupMenuDivider(),
                      ...commonItems(published),
                    ],
                  ),
                ),
                for (final c in children)
                  _AdminOutlineItem(
                    item: c,
                    data: data,
                    depth: 1,
                    siblings: children,
                    onChanged: onChanged,
                  ),
              ],
            ),
          ),
        );
      case LessonItem(:final lesson):
        final published = lesson.status == PublishStatus.published;
        return Padding(
          padding: pad,
          child: ListTile(
            leading: const Icon(Icons.article_outlined),
            title: Text(lesson.title),
            subtitle: Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusChip(published: published),
            ),
            onTap: () => context.push('/teach/lessons/${lesson.id}'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'up':
                    await _move(context, ref, -1);
                  case 'down':
                    await _move(context, ref, 1);
                  case 'edit':
                    if (await showLessonDialog(
                      context,
                      ref,
                      data: data,
                      existing: lesson,
                    )) {
                      onChanged();
                    }
                  case 'publish':
                    await togglePublish('lessons', lesson.id, published);
                  case 'delete':
                    await delete(
                      'lessons',
                      lesson.id,
                      l10n.adminDeleteLessonBody,
                    );
                  case 'move':
                    if (await showMoveLessonDialog(
                      context,
                      ref,
                      LessonPlace(
                        lesson: lesson,
                        course: data.course,
                        units: data.units,
                        nodes: data.nodes,
                      ),
                    )) {
                      onChanged();
                    }
                  case 'copy':
                    await showCopyLessonDialog(context, ref, lesson);
                }
              },
              itemBuilder: (_) => [
                ...commonItems(published),
                const PopupMenuDivider(),
                PopupMenuItem(value: 'move', child: Text(l10n.lessonMove)),
                PopupMenuItem(value: 'copy', child: Text(l10n.lessonCopy)),
              ],
            ),
          ),
        );
    }
  }
}

/// Helper so dialogs can compute next positions under a parent.
int nextPosition(BuilderData data, {String? parentNodeId, String? unitId}) {
  final positions = <int>[
    for (final n in data.nodes)
      if (n.parentId == parentNodeId &&
          (parentNodeId != null || n.unitId == unitId))
        n.position,
    for (final l in data.lessons)
      if (l.nodeId == parentNodeId &&
          (parentNodeId != null || l.unitId == unitId))
        l.position,
  ];
  return positions.isEmpty ? 0 : positions.reduce((a, b) => a > b ? a : b) + 1;
}

Json unitValues(String courseId, String title, String? description) => {
  'course_id': courseId,
  'title': title,
  'description': description,
};

/// Track, languages, audience and review state at a glance.
class _CourseFacts extends ConsumerWidget {
  const _CourseFacts({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langs = ref.watch(languagesProvider).value;
    final tracks = ref.watch(tracksProvider).value ?? const <LearningTrack>[];
    final track = tracks.where((t) => t.key == course.trackKey).firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.needsReview)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        (course.metadata['review_note'] as String?) ??
                            l10n.provisionalBody,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                if (course.needsReview)
                  Chip(
                    label: Text(l10n.provisionalTitle),
                    visualDensity: VisualDensity.compact,
                  ),
                if (track != null)
                  Chip(
                    label: Text(track.name),
                    visualDensity: VisualDensity.compact,
                  ),
                Chip(
                  avatar: const Icon(Icons.translate, size: 16),
                  label: Text(
                    l10n.taughtIn(
                      course.languages
                          .map((c) => languageName(langs, c))
                          .join(', '),
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                if (course.hidden)
                  Chip(
                    label: Text(l10n.courseHidden),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (course.targetLearner != null) ...[
              const SizedBox(height: Space.xs),
              Text(
                l10n.courseForWhom(course.targetLearner!),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
