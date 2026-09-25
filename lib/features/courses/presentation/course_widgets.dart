import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../media/presentation/media_widgets.dart';

extension CourseLabels on Course {
  String accessLabel(AppLocalizations l10n) => switch (access) {
    CourseAccess.free => l10n.accessFree,
    CourseAccess.paid => l10n.accessPaid,
    CourseAccess.restricted => l10n.accessRestricted,
  };

  String difficultyLabel(AppLocalizations l10n) => switch (difficulty) {
    Difficulty.beginner => l10n.difficultyBeginner,
    Difficulty.intermediate => l10n.difficultyIntermediate,
    Difficulty.advanced => l10n.difficultyAdvanced,
  };
}

/// Cover image or a calm typographic fallback when none is set.
class CourseCover extends StatelessWidget {
  const CourseCover({super.key, required this.course, this.height = 132});
  final Course course;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (course.thumbnailAssetId != null) {
      return SidraImage(
        assetId: course.thumbnailAssetId!,
        transformation: 'c_fill,w_800,h_450,q_auto',
        height: height,
        borderRadius: 0,
      );
    }
    return Container(
      height: height,
      width: double.infinity,
      alignment: AlignmentDirectional.bottomStart,
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, SidraColors.teal900],
        ),
      ),
      child: Text(
        course.subject.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: scheme.onPrimary.withValues(alpha: 0.85),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key, this.icon, this.emphasis = false});
  final String label;
  final IconData? icon;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = emphasis ? scheme.onTertiaryContainer : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 3),
      decoration: BoxDecoration(
        color: emphasis ? scheme.tertiaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.percent, this.label});
  final int percent;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: LinearProgressIndicator(value: percent / 100, minHeight: 6),
        ),
        if (label != null) ...[
          const SizedBox(height: Space.xxs),
          Text(label!, style: Theme.of(context).textTheme.labelSmall),
        ],
      ],
    );
  }
}

/// Catalogue / list card for a course.
class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.progressPercent,
  });

  final Course course;
  final VoidCallback onTap;
  final int? progressPercent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CourseCover(course: course, height: 120),
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (course.subtitle != null) ...[
                    const SizedBox(height: Space.xxs),
                    Text(
                      course.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: Space.sm),
                  Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [
                      InfoChip(course.difficultyLabel(l10n)),
                      InfoChip(
                        course.accessLabel(l10n),
                        emphasis: !course.isFree,
                      ),
                      if (course.estimatedHours != null)
                        InfoChip(
                          l10n.hoursShort(
                            course.estimatedHours!.toStringAsFixed(
                              course.estimatedHours! % 1 == 0 ? 0 : 1,
                            ),
                          ),
                          icon: Icons.schedule,
                        ),
                    ],
                  ),
                  if (progressPercent != null) ...[
                    const SizedBox(height: Space.md),
                    ProgressLine(
                      percent: progressPercent!,
                      label: l10n.percentComplete(progressPercent!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin banner: pending/rejected sync work. Hidden when all is synced.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider).value;
    if (status == null || status.isClean) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rejected = status.rejected > 0;
    return Material(
      color: rejected ? scheme.errorContainer : scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.xs,
        ),
        child: Row(
          children: [
            Icon(
              rejected ? Icons.sync_problem : Icons.cloud_upload_outlined,
              size: 18,
              color: rejected
                  ? scheme.onErrorContainer
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Text(
                rejected
                    ? l10n.syncRejected(status.rejected)
                    : l10n.syncPending(status.pending),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
