import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../curriculum/domain/curriculum_tree.dart';

/// Renders a course outline of ANY shape: units, surahs, pages, chapters…
/// The tree comes from data; nothing here knows about specific books.
class OutlineView extends StatelessWidget {
  const OutlineView({
    super.key,
    required this.items,
    required this.onOpenLesson,
    required this.onLockedLesson,
  });

  final List<OutlineItem> items;
  final void Function(LessonItem) onOpenLesson;
  final void Function(LessonItem) onLockedLesson;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final item in items) _item(context, item, 0)],
    );
  }

  Widget _item(BuildContext context, OutlineItem item, int depth) {
    final theme = Theme.of(context);
    return switch (item) {
      UnitItem(:final unit, :final children) => Padding(
        padding: const EdgeInsets.only(top: Space.md),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.md,
                    Space.sm,
                    Space.md,
                    Space.xs,
                  ),
                  child: Text(unit.title, style: theme.textTheme.titleMedium),
                ),
                if (unit.description != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.md),
                    child: Text(
                      unit.description!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                for (final c in children) _item(context, c, 1),
              ],
            ),
          ),
        ),
      ),
      NodeItem(:final node, :final children, :final levelLabel) => Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _containsOpenLesson(children),
          tilePadding: EdgeInsetsDirectional.only(
            start: Space.md + depth * Space.sm,
            end: Space.md,
          ),
          childrenPadding: EdgeInsets.zero,
          title: Text(node.title, style: theme.textTheme.titleSmall),
          subtitle: _nodeSubtitle(levelLabel, node.locator) == null
              ? null
              : Text(
                  _nodeSubtitle(levelLabel, node.locator)!,
                  style: theme.textTheme.bodySmall,
                ),
          children: [for (final c in children) _item(context, c, depth + 1)],
        ),
      ),
      LessonItem() => _LessonTile(
        item: item,
        depth: depth,
        onTap: () => item.access == LessonAccess.locked
            ? onLockedLesson(item)
            : onOpenLesson(item),
      ),
    };
  }

  static String? _nodeSubtitle(String? level, String? locator) {
    final parts = [?level, ?locator];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static bool _containsOpenLesson(List<OutlineItem> children) => children.any(
    (c) => switch (c) {
      LessonItem(:final access) => access == LessonAccess.unlocked,
      NodeItem(:final children) => _containsOpenLesson(children),
      UnitItem(:final children) => _containsOpenLesson(children),
    },
  );
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.item,
    required this.depth,
    required this.onTap,
  });

  final LessonItem item;
  final int depth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, semantic) = switch (item.access) {
      LessonAccess.completed => (
        Icons.check_circle,
        scheme.primary,
        l10n.completedLabel,
      ),
      LessonAccess.unlocked => (
        Icons.play_circle_outline,
        scheme.primary,
        l10n.continueAction,
      ),
      LessonAccess.locked => (
        Icons.lock_outline,
        scheme.outline,
        l10n.lockedLessonTitle,
      ),
    };
    final locked = item.access == LessonAccess.locked;
    return ListTile(
      contentPadding: EdgeInsetsDirectional.only(
        start: Space.md + depth * Space.sm,
        end: Space.md,
      ),
      leading: Icon(icon, color: color, semanticLabel: semantic),
      title: Text(
        item.lesson.title,
        style: TextStyle(color: locked ? scheme.onSurfaceVariant : null),
      ),
      subtitle: item.lesson.estimatedMinutes == null
          ? null
          : Text('${item.lesson.estimatedMinutes} min'),
      onTap: onTap,
    );
  }
}
