
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../audio/presentation/audio_widgets.dart';
import '../../content/data/content_repository.dart';
import '../../content/presentation/resource_widgets.dart';
import '../data/teaching_repository.dart';
import '../data/work_thread.dart';
import 'work_issue_widgets.dart';
import 'work_thread_view.dart';

final learnerPortionProvider = FutureProvider.autoDispose
    .family<LearnerPortion, String>(
      (ref, id) => ref.watch(teachingRepositoryProvider).open(id),
    );

String participationLabel(AppLocalizations l10n, Participation p) =>
    switch (p) {
      Participation.assigned => l10n.partNew,
      Participation.opened => l10n.partToDo,
      Participation.submitted => l10n.partWaiting,
      Participation.underReview => l10n.partUnderReview,
      Participation.correctionRequired => l10n.partTryAgain,
      Participation.completed => l10n.partDone,
    };

String resultLabel(AppLocalizations l10n, ReviewResult r) => switch (r) {
  ReviewResult.excellent => l10n.resExcellent,
  ReviewResult.correct => l10n.resCorrect,
  ReviewResult.minorCorrection => l10n.resMinor,
  ReviewResult.correctionRequired => l10n.resCorrection,
  ReviewResult.needsExplanation => l10n.resExplain,
};

/// Home: "Today's learning" — what to do next, most urgent first.
class TodayLearningSection extends ConsumerWidget {
  const TodayLearningSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final today = ref.watch(learnerTodayProvider).value ?? const [];
    if (today.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.todayLearning, style: theme.textTheme.titleLarge),
        const SizedBox(height: Space.xs),
        for (final p in today)
          Card(
            color: p.status == Participation.correctionRequired
                ? theme.colorScheme.tertiaryContainer
                : (p.status == Participation.assigned
                      ? theme.colorScheme.primaryContainer
                      : null),
            child: ListTile(
              leading: Icon(switch (p.status) {
                Participation.completed => Icons.check_circle,
                Participation.submitted ||
                Participation.underReview => Icons.hourglass_top,
                Participation.correctionRequired => Icons.replay,
                _ => Icons.menu_book_outlined,
              }),
              title: Text(p.title),
              subtitle: Text(
                [
                  participationLabel(l10n, p.status),
                  ?p.courseTitle,
                ].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await context.push('/learn/portions/${p.id}');
                ref.invalidate(learnerTodayProvider);
              },
            ),
          ),
      ],
    );
  }
}

/// One portion, for the learner: the page, the teacher's voice, the model,
/// the task — then record and send. Nothing else.
class LearnerPortionScreen extends ConsumerWidget {
  const LearnerPortionScreen({super.key, required this.portionId});
  final String portionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final portion = ref.watch(learnerPortionProvider(portionId));
    final key = ('portion', portionId, null) as WorkKey;
    final thread = ref.watch(workThreadProvider(key)).value;
    void refresh() {
      ref.invalidate(learnerPortionProvider(portionId));
      ref.invalidate(workThreadProvider(key));
      ref.invalidate(learnerTodayProvider);
    }

    return Scaffold(
      appBar: AppBar(title: Text(portion.value?.title ?? l10n.todayLearning)),
      body: switch (portion) {
        AsyncData(:final value) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  refresh();
                  await ref.read(learnerPortionProvider(portionId).future);
                },
                child: _PortionBody(portion: value, thread: thread),
              ),
            ),
            // Send (again) at any time until the teacher accepts it.
            if (thread != null && !thread.completed)
              SafeArea(
                top: false,
                child: WorkComposer(
                  thread: thread,
                  kind: 'portion',
                  targetId: portionId,
                  submissionTypes: value.submissionTypes,
                  onSent: refresh,
                ),
              ),
          ],
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(learnerPortionProvider(portionId)),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _PortionBody extends ConsumerWidget {
  const _PortionBody({required this.portion, this.thread});
  final LearnerPortion portion;
  final WorkThread? thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = portion;
    final langs = ref.watch(languagesProvider).value;
    final explainedIn = p.instructionLanguage ?? p.courseLanguage;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.md,
        Space.xxl,
      ),
      children: [
        Text(
          [?p.courseTitle, ?p.groupName].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        if (explainedIn != null)
          Text(
            l10n.taughtIn(languageName(langs, explainedIn)),
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: Space.sm),
        for (final page in p.withRole('page')) _PageView(resource: page),
        for (final r in p.withRole('instruction'))
          if (r.mediaAssetId != null)
            VoicePlayer(
              mediaAssetId: r.mediaAssetId,
              title: l10n.listenTeacher,
              icon: Icons.record_voice_over_outlined,
            ),
        for (final r in p.withRole('model'))
          if (r.mediaAssetId != null)
            VoicePlayer(
              mediaAssetId: r.mediaAssetId,
              title: l10n.listenModel,
              icon: Icons.graphic_eq,
            ),
        for (final r in [...p.withRole('worksheet'), ...p.withRole('other')])
          Card(
            child: ListTile(
              leading: Icon(resourceIcon(r.kind)),
              title: Text(r.title),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => openResource(context, ref, Resource(r.j)),
            ),
          ),
        if (p.instructions != null) ...[
          const SizedBox(height: Space.sm),
          Text(l10n.yourTask, style: theme.textTheme.titleMedium),
          Text(p.instructions!, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: Space.md),

        // ------------- the whole conversation: attempts, verdicts, replies
        if (p.status == Participation.submitted ||
            p.status == Participation.underReview)
          Card(
            child: ListTile(
              leading: const Icon(Icons.hourglass_top),
              title: Text(l10n.sentWaiting),
              subtitle: Text(l10n.wtSendAgainHint),
            ),
          ),
        if (thread != null)
          WorkTimeline(thread: thread!)
        else
          const Padding(
            padding: EdgeInsets.all(Space.md),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (p.status != Participation.completed)
          WorkIssueSection(target: (kind: 'portion', id: p.id)),
      ],
    );
  }
}

class _PageView extends ConsumerWidget {
  const _PageView({required this.resource});
  final PortionResource resource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (resource.kind != 'image' || resource.mediaAssetId == null) {
      return Card(
        child: ListTile(
          leading: Icon(resourceIcon(resource.kind)),
          title: Text(resource.title),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => openResource(context, ref, Resource(resource.j)),
        ),
      );
    }
    return FutureBuilder<String>(
      future: ref
          .read(contentRepositoryProvider)
          .mediaUrl(resource.mediaAssetId!),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const AspectRatio(
            aspectRatio: 3 / 4,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final url = snap.data!;
        return Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    title: Text(resource.title),
                  ),
                  body: InteractiveViewer(
                    maxScale: 6,
                    child: Center(child: CachedNetworkImage(imageUrl: url)),
                  ),
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.md),
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }
}
