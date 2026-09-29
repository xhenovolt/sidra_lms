import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../admin/presentation/admin_common.dart';
import '../../audio/presentation/audio_widgets.dart';
import '../../content/data/content_repository.dart';
import '../../content/data/submission_queue.dart';
import '../../content/presentation/resource_widgets.dart';
import '../../media/presentation/capture_sheet.dart';
import '../data/lesson_work.dart';
import '../data/teaching_repository.dart';
import 'learner_portion_screen.dart' show resultLabel;
import 'teacher_screens.dart' show showCorrectionPicker;
import 'work_issue_widgets.dart';

Color _markColor(WordMark m, ColorScheme scheme) => switch (m) {
  WordMark.ok => Colors.green.shade700,
  WordMark.weak => Colors.orange.shade800,
  WordMark.wrong => scheme.error,
};

/// The lesson's words as the teacher marked them.
class MarkedWords extends StatelessWidget {
  const MarkedWords({super.key, required this.marks});
  final List<MarkedWord> marks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final m in marks)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _markColor(m.mark, scheme).withValues(alpha: 0.12),
                border: Border.all(color: _markColor(m.mark, scheme)),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Text(
                m.word,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  color: _markColor(m.mark, scheme),
                  decoration: m.mark == WordMark.wrong
                      ? TextDecoration.underline
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================== learner ==

/// "Your work" in a lesson that needs handed-in work: what to do, the
/// teacher's verdict and marks, and the button to hand in (again).
class LessonWorkPanel extends ConsumerWidget {
  const LessonWorkPanel({super.key, required this.lessonId});
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final work = ref.watch(myLessonWorkProvider(lessonId)).value ?? const [];
    final queued = (ref.watch(submissionQueueProvider).value ?? const [])
        .where((q) => q.lessonId == lessonId)
        .toList();
    final latest = work.firstOrNull;
    final review = latest?.latestReview;
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: Space.sm),
                Text(l10n.workTitle, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: Space.xs),
            if (latest == null && queued.isEmpty) Text(l10n.workHint),
            for (final q in queued)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  q.state == 'failed'
                      ? Icons.error_outline
                      : Icons.cloud_upload_outlined,
                ),
                title: Text(switch (q.state) {
                  'uploading' => l10n.uploadUploading,
                  'failed' => l10n.subUploadFailed,
                  _ => l10n.subWaitingToUpload,
                }),
                subtitle: Text(l10n.notSentYet),
                trailing: q.state == 'uploading'
                    ? null
                    : TextButton(
                        onPressed: () async {
                          await ref
                              .read(submissionQueueProvider.notifier)
                              .retry(q.id);
                          ref.invalidate(myLessonWorkProvider(lessonId));
                        },
                        child: Text(l10n.retry),
                      ),
              ),
            if (latest != null) ...[
              Text(
                latest.waiting
                    ? l10n.workWaiting
                    : latest.approved
                    ? l10n.workApproved
                    : l10n.workTryAgain,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: latest.approved
                      ? Colors.green.shade700
                      : latest.tryAgain
                      ? theme.colorScheme.error
                      : null,
                ),
              ),
              Text(
                l10n.subAttempt(latest.attempt),
                style: theme.textTheme.bodySmall,
              ),
              if (review != null) ...[
                const SizedBox(height: Space.xs),
                Text(
                  resultLabel(l10n, review.result),
                  style: theme.textTheme.labelLarge,
                ),
                if (review.score != null)
                  Text(
                    l10n.workScore(
                      review.score!.toStringAsFixed(0),
                      latest.passMark,
                    ),
                  ),
                if (review.marks.isNotEmpty) ...[
                  const SizedBox(height: Space.xs),
                  MarkedWords(marks: review.marks),
                  Text(l10n.workLegend, style: theme.textTheme.bodySmall),
                ],
                if (review.feedback != null) ...[
                  const SizedBox(height: Space.xs),
                  Text(l10n.teacherSays(review.feedback!)),
                ],
                if (review.correction?['media_asset_id'] != null)
                  VoicePlayer(
                    mediaAssetId:
                        review.correction!['media_asset_id'] as String,
                    title: review.correction!['title'] as String?,
                    icon: Icons.school_outlined,
                  ),
                if (review.correctionAssetId != null)
                  VoicePlayer(
                    mediaAssetId: review.correctionAssetId,
                    title: l10n.correctionForYou,
                    icon: Icons.school_outlined,
                  ),
              ],
            ],
            if (queued.isEmpty && (latest == null || latest.tryAgain)) ...[
              const SizedBox(height: Space.sm),
              FilledButton.icon(
                onPressed: () => showSubmitLessonWork(context, ref, lessonId),
                icon: const Icon(Icons.upload),
                label: Text(
                  latest == null ? l10n.workSubmit : l10n.workSubmitAgain,
                ),
              ),
            ],
            if (latest == null || !latest.approved)
              WorkIssueSection(target: (kind: 'lesson', id: lessonId)),
          ],
        ),
      ),
    );
  }
}

Future<void> showSubmitLessonWork(
  BuildContext context,
  WidgetRef ref,
  String lessonId,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SubmitSheet(lessonId: lessonId),
  );
  ref.invalidate(myLessonWorkProvider(lessonId));
}

class _SubmitSheet extends ConsumerStatefulWidget {
  const _SubmitSheet({required this.lessonId});
  final String lessonId;

  @override
  ConsumerState<_SubmitSheet> createState() => _SubmitSheetState();
}

class _SubmitSheetState extends ConsumerState<_SubmitSheet> {
  RecordedAudio? _audio;
  final _files = <CapturedFile>[];
  final _text = TextEditingController();
  bool _sending = false;

  Future<void> _add() async {
    final f = await captureContent(
      context,
      allow: const {
        CaptureSource.photo,
        CaptureSource.scan,
        CaptureSource.gallery,
        CaptureSource.video,
        CaptureSource.file,
      },
    );
    if (f != null) setState(() => _files.add(f));
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    final ok = await ref
        .read(submissionQueueProvider.notifier)
        .submit(
          lessonId: widget.lessonId,
          text: _text.text.trim().isEmpty ? null : _text.text.trim(),
          files: [
            if (_audio != null)
              QueuedFile(
                path: _audio!.path,
                name: _audio!.fileName,
                kind: 'audio',
              ),
            for (final f in _files)
              QueuedFile(
                path: f.path,
                name: f.name,
                kind: f.kind,
                bytes: f.bytes,
              ),
          ],
        );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(ok ? l10n.sentToTeacher : l10n.subSavedForLater)),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasSomething =
        _audio != null || _files.isNotEmpty || _text.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.md,
        0,
        Space.md,
        MediaQuery.viewInsetsOf(context).bottom + Space.lg,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(l10n.workSubmit, style: theme.textTheme.titleLarge),
          Text(l10n.workHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: Space.sm),
          VoiceRecorder(
            hint: l10n.recordHint,
            onChanged: (a) => setState(() => _audio = a),
          ),
          OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(l10n.capAddWork),
          ),
          for (final (i, f) in _files.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(resourceIcon(f.kind)),
              title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(formatFileSize(f.bytes)),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _files.removeAt(i)),
              ),
            ),
          TextField(
            controller: _text,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.workAnswer),
          ),
          const SizedBox(height: Space.md),
          FilledButton.icon(
            onPressed: hasSomething && !_sending ? _send : null,
            icon: const Icon(Icons.send),
            label: Text(l10n.sendToTeacher),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Text(l10n.subPrivacyNote, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

// =============================================================== teacher ==

/// Lesson work waiting for review, oldest first.
class LessonWorkQueueScreen extends ConsumerWidget {
  const LessonWorkQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final queue = ref.watch(lessonWorkQueueProvider);
    final date = DateFormat.MMMd(l10n.localeName).add_jm();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.workQueueTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(lessonWorkQueueProvider.future),
        child: switch (queue) {
          AsyncData(:final value) when value.isEmpty => ListView(
            children: [
              EmptyView(icon: Icons.task_alt, title: l10n.workQueueEmpty),
            ],
          ),
          AsyncData(:final value) => ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final w = value[i];
              final audio = w.files
                  .where((f) => f['kind'] == 'audio')
                  .firstOrNull;
              return ListTile(
                leading: UserAvatar(avatarUrl: w.avatarUrl, name: w.learner),
                title: Text(w.learner ?? '—'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        ?w.lessonTitle,
                        l10n.subAttempt(w.attempt),
                        if (w.submittedAt != null)
                          date.format(w.submittedAt!.toLocal()),
                      ].join(' · '),
                    ),
                    if (audio != null)
                      VoicePlayer(
                        mediaAssetId: audio['media_asset_id'] as String,
                        compact: true,
                      ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await context.push('/teach/work/${w.id}', extra: w);
                  ref.invalidate(lessonWorkQueueProvider);
                },
              );
            },
          ),
          AsyncError(:final error) => ListView(
            children: [
              ErrorView(
                error: error,
                onRetry: () => ref.invalidate(lessonWorkQueueProvider),
              ),
            ],
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}

final _workByIdProvider = FutureProvider.autoDispose
    .family<LessonWork?, String>(
      (ref, id) async =>
          (await ref.watch(lessonWorkRepositoryProvider).queue(status: 'all'))
              .where((w) => w.id == id)
              .firstOrNull,
    );

/// Review one piece of lesson work: listen / look, mark word by word,
/// score, feedback, correction, then approve or ask for a correction.
class LessonWorkReviewScreen extends ConsumerWidget {
  const LessonWorkReviewScreen({
    super.key,
    required this.submissionId,
    this.work,
  });
  final String submissionId;
  final LessonWork? work;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (work != null) return _Review(work: work!);
    final w = ref.watch(_workByIdProvider(submissionId));
    return switch (w) {
      AsyncData(value: final LessonWork found) => _Review(work: found),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: EmptyView(icon: Icons.search_off, title: l10n.workQueueEmpty),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: error),
      ),
      _ => const Scaffold(body: LoadingView()),
    };
  }
}

class _Review extends ConsumerStatefulWidget {
  const _Review({required this.work});
  final LessonWork work;

  @override
  ConsumerState<_Review> createState() => _ReviewState();
}

class _ReviewState extends ConsumerState<_Review> {
  List<MarkedWord>? _marks;
  int? _score; // overridden score; null = from marks
  final _feedback = TextEditingController();
  Correction? _correction;
  RecordedAudio? _recording;
  bool _showRecorder = false;
  bool _saveToLibrary = false;
  final _libTitle = TextEditingController();
  bool _sending = false;

  LessonWork get w => widget.work;

  @override
  void initState() {
    super.initState();
    ref
        .read(lessonWorkRepositoryProvider)
        .markingText(w.lessonId)
        .then((words) {
          if (!mounted) return;
          setState(
            () => _marks = [
              for (final (i, word) in words.indexed)
                MarkedWord(i, word, WordMark.ok),
            ],
          );
        })
        .catchError((_) {
          if (mounted) setState(() => _marks = const []);
        });
  }

  int get _effectiveScore =>
      _score ??
      (_marks == null || _marks!.isEmpty ? 100 : scoreFromMarks(_marks!));

  void _cycle(int i) {
    final m = _marks![i];
    final next = WordMark.values[(m.mark.index + 1) % WordMark.values.length];
    setState(() {
      _marks![i] = MarkedWord(m.index, m.word, next);
      _score = null; // follow the marks again
    });
  }

  Future<void> _send(ReviewResult result) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);
    Map<String, dynamic>? res;
    final ok = await runAdminAction(context, () async {
      String? assetId;
      if (_recording != null) {
        final profile = await ref.read(profileProvider.future);
        assetId = await ref
            .read(adminRepositoryProvider)
            .uploadMedia(
              filePath: _recording!.path,
              fileName: _recording!.fileName,
              kind: 'audio',
              uploaderId: profile.id,
              folder: 'corrections',
            );
      }
      res = await ref
          .read(lessonWorkRepositoryProvider)
          .review(
            submissionId: w.id,
            result: result,
            scorePercent: _effectiveScore,
            marks: _marks,
            feedback: nullIfBlank(_feedback.text),
            correctionId: _correction?.id,
            correctionAssetId: assetId,
            saveAs: _saveToLibrary && assetId != null
                ? {
                    'title': _libTitle.text.trim().isEmpty
                        ? (w.lessonTitle ?? 'Correction')
                        : _libTitle.text.trim(),
                    'explanation': nullIfBlank(_feedback.text),
                  }
                : null,
          );
    }, success: l10n.reviewSent);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok && res != null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final passes = _effectiveScore >= w.passMark;
    return Scaffold(
      appBar: AppBar(title: Text(w.learner ?? l10n.workQueueTitle)),
      body: AbsorbPointer(
        absorbing: _sending,
        child: ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            Text(
              [
                ?w.courseTitle,
                ?w.lessonTitle,
                l10n.subAttempt(w.attempt),
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: Space.sm),
            for (final f in w.files)
              if (f['kind'] == 'audio')
                VoicePlayer(
                  mediaAssetId: f['media_asset_id'] as String,
                  title: l10n.theirRecording,
                )
              else
                Card(
                  child: ListTile(
                    leading: Icon(resourceIcon('${f['kind']}')),
                    title: Text('${f['file_name'] ?? 'file'}'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => openResource(
                      context,
                      ref,
                      Resource({
                        'id': f['media_asset_id'],
                        'provider': 'cloudinary',
                        'media_asset_id': f['media_asset_id'],
                        'kind': f['kind'],
                        'title': f['file_name'],
                        'file_name': f['file_name'],
                        'mime_type': f['mime_type'],
                      }),
                    ),
                  ),
                ),
            if (w.text != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: SelectableText(w.text!),
                ),
              ),
            const Divider(height: Space.xl),
            Text(l10n.workMarkWords, style: theme.textTheme.titleMedium),
            if (_marks == null)
              const LinearProgressIndicator()
            else if (_marks!.isEmpty)
              Text(l10n.workNoText, style: theme.textTheme.bodySmall)
            else ...[
              Text(l10n.workMarkWordsHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: Space.xs),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (i, m) in _marks!.indexed)
                      InkWell(
                        onTap: () => _cycle(i),
                        borderRadius: BorderRadius.circular(Radii.sm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _markColor(
                              m.mark,
                              theme.colorScheme,
                            ).withValues(alpha: 0.12),
                            border: Border.all(
                              color: _markColor(m.mark, theme.colorScheme),
                            ),
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          child: Text(
                            m.word,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 24,
                              color: _markColor(m.mark, theme.colorScheme),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(l10n.workLegend, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: Space.md),
            Text(
              l10n.workScoreLabel(_effectiveScore),
              style: theme.textTheme.titleSmall,
            ),
            Slider(
              value: _effectiveScore.toDouble(),
              max: 100,
              divisions: 20,
              label: '$_effectiveScore%',
              onChanged: (v) => setState(() => _score = v.round()),
            ),
            Text(
              passes
                  ? l10n.workWillPass(w.passMark)
                  : l10n.workWillFail(w.passMark),
              style: TextStyle(
                color: passes ? Colors.green.shade700 : theme.colorScheme.error,
              ),
            ),
            const Divider(height: Space.xl),
            Text(l10n.reviewCorrectionTitle, style: theme.textTheme.titleSmall),
            if (_correction != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: Text(_correction!.title),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _correction = null),
                  ),
                ),
              ),
            Wrap(
              spacing: Space.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final c = await showCorrectionPicker(context, ref);
                    if (c != null) setState(() => _correction = c);
                  },
                  icon: const Icon(Icons.search),
                  label: Text(l10n.reviewUseExisting),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showRecorder = true),
                  icon: const Icon(Icons.mic),
                  label: Text(l10n.reviewRecordNew),
                ),
              ],
            ),
            if (_showRecorder) ...[
              VoiceRecorder(onChanged: (a) => setState(() => _recording = a)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _saveToLibrary,
                onChanged: (v) => setState(() => _saveToLibrary = v),
                title: Text(l10n.reviewSaveToLibrary),
              ),
              if (_saveToLibrary)
                TextField(
                  controller: _libTitle,
                  decoration: InputDecoration(labelText: l10n.correctionTitle),
                ),
            ],
            TextField(
              controller: _feedback,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.reviewFeedbackOptional,
              ),
            ),
            const SizedBox(height: Space.md),
            FilledButton.icon(
              onPressed: _sending ? null : () => _send(ReviewResult.correct),
              icon: const Icon(Icons.check),
              label: Text(l10n.workApprove),
            ),
            const SizedBox(height: Space.xs),
            OutlinedButton.icon(
              onPressed: _sending ? null : () => _send(ReviewResult.excellent),
              icon: const Icon(Icons.star_outline),
              label: Text(l10n.resExcellent),
            ),
            const SizedBox(height: Space.xs),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: _sending
                  ? null
                  : () => _send(ReviewResult.correctionRequired),
              icon: const Icon(Icons.replay),
              label: Text(l10n.workNeedsCorrection),
            ),
          ],
        ),
      ),
    );
  }
}
