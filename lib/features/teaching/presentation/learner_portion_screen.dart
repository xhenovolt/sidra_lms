import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../audio/presentation/audio_widgets.dart';
import '../../content/data/content_repository.dart';
import '../../content/data/submission_queue.dart';
import '../../content/presentation/resource_widgets.dart';
import '../data/teaching_repository.dart';
import '../../media/presentation/capture_sheet.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(portion.value?.title ?? l10n.todayLearning)),
      body: switch (portion) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(learnerPortionProvider(portionId).future),
          child: _PortionBody(portion: value),
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
  const _PortionBody({required this.portion});
  final LearnerPortion portion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = portion;
    final langs = ref.watch(languagesProvider).value;
    final queued = (ref.watch(submissionQueueProvider).value ?? const [])
        .where((q) => q.portionId == p.id)
        .toList();
    final review = p.latestReview;
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

        // ------------------------------------------------ where things are
        if (p.status == Participation.submitted ||
            p.status == Participation.underReview)
          _StatusCard(
            icon: Icons.hourglass_top,
            title: l10n.sentWaiting,
            body: l10n.sentWaitingBody,
          ),
        if (review != null &&
            p.status != Participation.submitted &&
            p.status != Participation.underReview)
          _FeedbackCard(review: review),
        for (final q in queued)
          _StatusCard(
            icon: q.state == 'failed'
                ? Icons.error_outline
                : Icons.cloud_upload_outlined,
            title: switch (q.state) {
              'uploading' => l10n.uploadUploading,
              'failed' => l10n.subUploadFailed,
              _ => l10n.subWaitingToUpload,
            },
            body: l10n.notSentYet,
            action: q.state == 'uploading'
                ? null
                : TextButton(
                    onPressed: () async {
                      if (await ref
                          .read(submissionQueueProvider.notifier)
                          .retry(q.id)) {
                        ref.invalidate(learnerPortionProvider(p.id));
                      }
                    },
                    child: Text(l10n.retry),
                  ),
          ),

        // ------------------------------------------------------- hand in
        if (p.canSubmit && queued.isEmpty) _SubmitPanel(portion: p),

        // --------------------------------------------------------- history
        if (p.attempts.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.yourAttempts(p.attempts.length)),
            children: [
              for (final a in p.attempts)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          l10n.subAttempt(a.number),
                          if (a.latestReview != null)
                            resultLabel(l10n, a.latestReview!.result),
                        ].join(' · '),
                        style: theme.textTheme.labelLarge,
                      ),
                      for (final f in a.files)
                        if (f['kind'] == 'audio')
                          VoicePlayer(
                            mediaAssetId: f['media_asset_id'] as String,
                            compact: true,
                          ),
                    ],
                  ),
                ),
            ],
          ),
        ],
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(body),
      trailing: action,
    ),
  );
}

/// The teacher's verdict, what to do next, and the correction to listen to.
class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final passed = review.result.passed;
    final correction = review.correction;
    return Card(
      color: passed
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  review.result == ReviewResult.excellent
                      ? Icons.star
                      : passed
                      ? Icons.check_circle
                      : Icons.replay,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    resultLabel(l10n, review.result),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (review.feedback != null) ...[
              const SizedBox(height: Space.xs),
              Text(l10n.teacherSays(review.feedback!)),
            ],
            if (correction != null) ...[
              const SizedBox(height: Space.xs),
              if (correction['media_asset_id'] != null)
                VoicePlayer(
                  mediaAssetId: correction['media_asset_id'] as String,
                  title: correction['title'] as String?,
                  subtitle: correction['explanation'] as String?,
                  icon: Icons.school_outlined,
                )
              else
                Text(
                  '${correction['title']}: ${correction['explanation'] ?? ''}',
                ),
            ],
            if (review.correctionAssetId != null)
              VoicePlayer(
                mediaAssetId: review.correctionAssetId,
                title: l10n.correctionForYou,
                icon: Icons.school_outlined,
              ),
            if (!passed) ...[
              const SizedBox(height: Space.xs),
              Text(l10n.recordAgainBelow, style: theme.textTheme.labelLarge),
            ],
          ],
        ),
      ),
    );
  }
}

/// Record (and / or photograph, attach) and send to the teacher.
class _SubmitPanel extends ConsumerStatefulWidget {
  const _SubmitPanel({required this.portion});
  final LearnerPortion portion;

  @override
  ConsumerState<_SubmitPanel> createState() => _SubmitPanelState();
}

class _SubmitPanelState extends ConsumerState<_SubmitPanel> {
  RecordedAudio? _audio;
  final _files = <QueuedFile>[];
  bool _sending = false;
  int _recorderKey = 0;

  LearnerPortion get p => widget.portion;

  /// Photo, multi-page scan (PDF), gallery or file, with its size shown.
  Future<void> _capture() async {
    final f = await captureContent(
      context,
      allow: const {
        CaptureSource.photo,
        CaptureSource.scan,
        CaptureSource.gallery,
        CaptureSource.file,
      },
    );
    if (f == null) return;
    setState(
      () => _files.add(
        QueuedFile(path: f.path, name: f.name, kind: f.kind, bytes: f.bytes),
      ),
    );
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    final files = [
      if (_audio != null)
        QueuedFile(
          path: _audio!.path,
          name: _audio!.fileName,
          kind: 'audio',
          bytes: File(_audio!.path).lengthSync(),
        ),
      ..._files,
    ];
    final ok = await ref
        .read(submissionQueueProvider.notifier)
        .submit(portionId: p.id, files: files);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(ok ? l10n.sentToTeacher : l10n.subSavedForLater)),
    );
    setState(() {
      _sending = false;
      _audio = null;
      _files.clear();
      _recorderKey++;
    });
    ref.invalidate(learnerPortionProvider(p.id));
    ref.invalidate(learnerTodayProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final types = p.submissionTypes;
    final hasSomething = _audio != null || _files.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (types.contains('audio'))
          VoiceRecorder(
            key: ValueKey(_recorderKey),
            hint: l10n.recordHint,
            onChanged: (a) => setState(() => _audio = a),
          ),
        if (types.contains('image') || types.contains('document'))
          OutlinedButton.icon(
            onPressed: _capture,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(l10n.capAddWork),
          ),
        for (final (i, f) in _files.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: f.kind == 'image'
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: Image.file(
                      File(f.path),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(resourceIcon(f.kind)),
            title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(formatFileSize(f.bytes ?? 0)),
            trailing: IconButton(
              tooltip: l10n.audioDiscard,
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _files.removeAt(i)),
            ),
          ),
        const SizedBox(height: Space.sm),
        FilledButton.icon(
          onPressed: hasSomething && !_sending ? _send : null,
          icon: _sending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(l10n.sendToTeacher),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Space.xs),
          child: Text(l10n.subPrivacyNote, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}
