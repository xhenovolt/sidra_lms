import 'curriculum_models.dart';

/// Lock state of a lesson for the current learner.
enum LessonAccess { unlocked, locked, completed }

/// An entry in the rendered outline: a unit, a node or a lesson.
sealed class OutlineItem {
  const OutlineItem();
}

class UnitItem extends OutlineItem {
  const UnitItem(this.unit, this.children);
  final CourseUnit unit;
  final List<OutlineItem> children;
}

class NodeItem extends OutlineItem {
  const NodeItem(this.node, this.children, {this.levelLabel});
  final CurriculumNode node;
  final List<OutlineItem> children;

  /// Admin-defined label of the node's book level ("Surah", "Page"…).
  final String? levelLabel;
}

class LessonItem extends OutlineItem {
  const LessonItem(this.lesson, {required this.seq, required this.access});
  final Lesson lesson;

  /// 1-based position in the course sequence (null if not live).
  final int? seq;
  final LessonAccess access;
}

/// Builds the course outline from flat rows. Pure and deterministic: the
/// same rows always yield the same tree, whatever the book's structure.
///
/// Siblings (nodes and lessons under the same parent) are ordered by
/// position, matching the server's `lesson_sequence()`.
class CurriculumTree {
  CurriculumTree._(this.items, this.orderedLessons);

  factory CurriculumTree.build({
    required List<CourseUnit> units,
    required List<CurriculumNode> nodes,
    required List<Lesson> lessons,
    required List<LessonOrderEntry> order,
    Set<String> completedLessonIds = const {},
    Map<String, String> levelLabels = const {},
  }) {
    final seqById = {for (final o in order) o.lessonId: o};

    LessonAccess accessOf(Lesson l) {
      if (completedLessonIds.contains(l.id)) return LessonAccess.completed;
      final o = seqById[l.id];
      return (o?.isUnlocked ?? false)
          ? LessonAccess.unlocked
          : LessonAccess.locked;
    }

    final nodesByParent = <String?, List<CurriculumNode>>{};
    for (final n in nodes) {
      nodesByParent.putIfAbsent(n.parentId, () => []).add(n);
    }
    final lessonsByNode = <String, List<Lesson>>{};
    final lessonsByUnit = <String?, List<Lesson>>{};
    for (final l in lessons) {
      if (l.nodeId != null) {
        lessonsByNode.putIfAbsent(l.nodeId!, () => []).add(l);
      } else {
        lessonsByUnit.putIfAbsent(l.unitId, () => []).add(l);
      }
    }

    List<OutlineItem> siblings(
      List<CurriculumNode> childNodes,
      List<Lesson> childLessons,
      Set<String> visiting,
    ) {
      final entries =
          <(int, int, OutlineItem)>[
            for (final n in childNodes)
              if (!visiting.contains(n.id))
                (
                  n.position,
                  0,
                  NodeItem(
                    n,
                    siblings(
                      nodesByParent[n.id] ?? const [],
                      lessonsByNode[n.id] ?? const [],
                      {...visiting, n.id},
                    ),
                    levelLabel: levelLabels[n.structureLevelId],
                  ),
                ),
            for (final l in childLessons)
              (
                l.position,
                1,
                LessonItem(l, seq: seqById[l.id]?.seq, access: accessOf(l)),
              ),
          ]..sort((a, b) {
            final byPos = a.$1.compareTo(b.$1);
            return byPos != 0 ? byPos : a.$2.compareTo(b.$2);
          });
      return [for (final e in entries) e.$3];
    }

    final roots = nodesByParent[null] ?? const [];
    final sortedUnits = [...units]
      ..sort((a, b) => a.position.compareTo(b.position));

    final items = <OutlineItem>[
      // Content not assigned to any unit comes first (mirrors server: -1).
      ...siblings(
        roots.where((n) => n.unitId == null).toList(),
        lessonsByUnit[null] ?? const [],
        {},
      ),
      for (final u in sortedUnits)
        UnitItem(
          u,
          siblings(
            roots.where((n) => n.unitId == u.id).toList(),
            lessonsByUnit[u.id] ?? const [],
            {},
          ),
        ),
    ];

    final lessonById = {for (final l in lessons) l.id: l};
    final ordered = [
      for (final o in [...order]..sort((a, b) => a.seq.compareTo(b.seq)))
        if (lessonById[o.lessonId] != null) lessonById[o.lessonId]!,
    ];
    return CurriculumTree._(items, ordered);
  }

  final List<OutlineItem> items;

  /// Live lessons in course order (server sequence).
  final List<Lesson> orderedLessons;

  Lesson? previousOf(String lessonId) {
    final i = orderedLessons.indexWhere((l) => l.id == lessonId);
    return i > 0 ? orderedLessons[i - 1] : null;
  }

  Lesson? nextOf(String lessonId) {
    final i = orderedLessons.indexWhere((l) => l.id == lessonId);
    return i >= 0 && i < orderedLessons.length - 1
        ? orderedLessons[i + 1]
        : null;
  }
}
