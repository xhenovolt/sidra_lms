import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../admin/presentation/admin_common.dart';
import '../../audio/presentation/audio_widgets.dart';
import '../../content/data/submission_queue.dart';
import '../../content/presentation/resource_widgets.dart';
import '../../lessons/domain/content_blocks.dart';
import '../../media/presentation/capture_sheet.dart';
import '../../media/presentation/media_viewer.dart';
import '../../media/presentation/media_widgets.dart';
import '../data/teaching_repository.dart';
import '../data/work_thread.dart';
import 'learner_portion_screen.dart' show resultLabel;
import 'teacher_screens.dart' show showCorrectionPicker;

/// A passage the learner can point at (from the lesson's content blocks).
class TargetableBlock {
  const TargetableBlock({
    required this.id,
    required this.text,
    this.label,
    this.surah,
    this.verseStart,
    this.verseEnd,
    this.arabic = false,
  });
  final String id;
  final String text;
  final String? label;
  final int? surah;
  final int? verseStart;
  final int? verseEnd;
  final bool arabic;
}

/// The passages of a lesson that work can point at: text, headings,
/// Qur'an text (with its surah / ayat), translation, transliteration, notes.
List<TargetableBlock> targetableBlocks(List<ContentBlock> blocks) => [
  for (final b in blocks) ?_targetable(b),
];

TargetableBlock? _targetable(ContentBlock b) => switch (b) {
  QuranTextBlock(:final arabic) when arabic.trim().isNotEmpty =>
    TargetableBlock(
      id: b.id,
      text: arabic,
      label: b.reference,
      surah: b.surah,
      verseStart: b.verseStart,
      verseEnd: b.verseEnd,
      arabic: true,
    ),
  RichTextBlock(:final text) ||
  HeadingBlock(:final text) ||
  TranslationBlock(:final text) ||
  TransliterationBlock(:final text) ||
  CalloutBlock(:final text) when text.trim().isNotEmpty => TargetableBlock(
    id: b.id,
    text: text,
  ),
  _ => null,
};

String workStatusLabel(AppLocalizations l10n, WorkAttempt a) =>
    switch (a.status) {
      'submitted' || 'received' => l10n.wtWaiting,
      'under_review' => l10n.wtUnderReview,
      'superseded' => l10n.wtSuperseded,
      'resubmission_requested' || 'returned' => l10n.wtTryAgain,
      'reviewed' => l10n.wtAccepted,
      _ => a.status,
    };

// =================================================================== screen

/// One learner's work on one portion / lesson / assignment, as a teaching
/// thread: every attempt, every verdict, every reply, oldest first, with a
/// composer at the bottom. Used by learners (learnerId null) and teachers.
class WorkThreadScreen extends ConsumerStatefulWidget {
  const WorkThreadScreen({
    super.key,
    required this.kind,
    required this.targetId,
    this.learnerId,
    this.title,
    this.submissionTypes = const ['audio', 'image', 'document', 'text'],
    this.blocks = const [],
  });

  final String kind;
  final String targetId;

  /// Whose work (teachers); null = my own.
  final String? learnerId;
  final String? title;
  final List<String> submissionTypes;
  final List<TargetableBlock> blocks;

  @override
  ConsumerState<WorkThreadScreen> createState() => _WorkThreadScreenState();
}

class _WorkThreadScreenState extends ConsumerState<WorkThreadScreen> {
  // Kept across rebuilds so new events never reset the reading position.
  final _scroll = ScrollController();
  bool _markedUnderReview = false;

  WorkKey get _key => (widget.kind, widget.targetId, widget.learnerId);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final thread = ref.watch(workThreadProvider(_key));
    final t = thread.value;
    // A teacher opening waiting work: the learner sees "under review".
    if (t != null && t.asTeacher && !_markedUnderReview) {
      _markedUnderReview = true;
      final latest = t.latest;
      if (latest != null && latest.status == 'submitted') {
        ref
            .read(teachingRepositoryProvider)
            .markUnderReview(latest.submissionId)
            .ignore();
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ??
              (t != null && t.asTeacher
                  ? l10n.wtLearnerTitle(t.learnerName)
                  : l10n.wtMyWork),
        ),
      ),
      body: switch (thread) {
        AsyncValue(:final value?) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(workThreadProvider(_key).future),
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(
                    Space.md,
                    Space.sm,
                    Space.md,
                    Space.lg,
                  ),
                  children: [
                    WorkTimeline(thread: value),
                  ],
                ),
              ),
            ),
            if (!value.completed || value.asTeacher)
              SafeArea(
                top: false,
                child: WorkComposer(
                  thread: value,
                  kind: widget.kind,
                  targetId: widget.targetId,
                  submissionTypes: widget.submissionTypes,
                  blocks: widget.blocks,
                  onSent: () => ref.invalidate(workThreadProvider(_key)),
                ),
              ),
          ],
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(workThreadProvider(_key)),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

// ================================================================= timeline

/// Everything in the thread, oldest first, then what is still on its way.
class WorkTimeline extends ConsumerWidget {
  const WorkTimeline({super.key, required this.thread});
  final WorkThread thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final events = thread.events;
    final ids = {for (final a in thread.attempts) a.submissionId};
    final queued = (ref.watch(submissionQueueProvider).value ?? const [])
        .where(
          (q) => q.isReply
              ? ids.contains(q.replyTo)
              : !thread.asTeacher &&
                    q.work == (thread.kind, thread.targetId),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (events.isEmpty && queued.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.lg),
            child: Text(
              l10n.wtNothingYet,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        for (final e in events)
          switch (e) {
            WorkAttempt() => _AttemptCard(attempt: e, thread: thread),
            WorkVerdict() => _VerdictCard(verdict: e),
            WorkMessage() => _MessageBubble(
              message: e,
              mine: e.fromTeacher == thread.asTeacher,
            ),
          },
        for (final q in queued) QueuedWorkCard(entry: q),
        if (thread.completed && !thread.asTeacher)
          Card(
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.check_circle),
              title: Text(l10n.wtCompleted),
            ),
          ),
      ],
    );
  }
}

String _when(AppLocalizations l10n, DateTime? d) => d == null
    ? ''
    : DateFormat.MMMd(l10n.localeName).add_jm().format(d.toLocal());

class _AttemptCard extends StatelessWidget {
  const _AttemptCard({required this.attempt, required this.thread});
  final WorkAttempt attempt;
  final WorkThread thread;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final a = attempt;
    final images = a.files.where((f) => f['kind'] == 'image').toList();
    return Opacity(
      opacity: a.superseded ? 0.7 : 1,
      child: Card(
        margin: const EdgeInsetsDirectional.only(
          top: Space.sm,
          bottom: Space.xs,
          end: Space.xl,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment_turned_in_outlined,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: Text(
                      [
                        if (thread.asTeacher) thread.learnerName else l10n.wtYou,
                        l10n.wtAttemptN(a.number),
                      ].join(' · '),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    workStatusLabel(l10n, a),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Text(_when(l10n, a.at), style: theme.textTheme.labelSmall),
              if (a.target != null && !a.target!.isWhole)
                Padding(
                  padding: const EdgeInsets.only(top: Space.xxs),
                  child: _TargetChip(target: a.target!),
                ),
              if (a.text != null)
                Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: Text(a.text!),
                ),
              for (final f in a.files)
                if (f['kind'] == 'audio')
                  VoicePlayer(
                    mediaAssetId: f['media_asset_id'] as String,
                    compact: true,
                  )
                else if (f['kind'] != 'image')
                  _FileTile(file: f),
              if (images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [
                      for (final f in images)
                        InkWell(
                          onTap: () => openInApp(
                            context,
                            assetId: f['media_asset_id'] as String,
                            kind: 'image',
                            fileName: f['file_name'] as String?,
                            title: '${f['file_name'] ?? l10n.wtAttemptN(a.number)}',
                          ),
                          child: SizedBox.square(
                            dimension: 96,
                            child: SidraImage(
                              assetId: f['media_asset_id'] as String,
                              transformation: 'c_fill,w_240,h_240',
                              borderRadius: Radii.sm,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.file});
  final Map<String, dynamic> file;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(resourceIcon('${file['kind'] ?? 'document'}')),
    title: Text(
      '${file['file_name'] ?? 'file'}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: const Icon(Icons.open_in_new, size: 18),
    onTap: () => openInApp(
      context,
      assetId: file['media_asset_id'] as String,
      kind: file['kind'] as String?,
      mimeType: file['mime_type'] as String?,
      fileName: file['file_name'] as String?,
      title: '${file['file_name'] ?? ''}',
    ),
  );
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({required this.target});
  final WorkTarget target;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.my_location, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.wtFor(target.describe(l10n)),
              style: theme.textTheme.labelMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.verdict});
  final WorkVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final v = verdict;
    final passed = v.result.passed;
    final correction = v.correction;
    return Card(
      color: passed
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.tertiaryContainer,
      margin: const EdgeInsetsDirectional.only(
        top: Space.xs,
        bottom: Space.xs,
        start: Space.xl,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  v.result == ReviewResult.excellent
                      ? Icons.star
                      : passed
                      ? Icons.check_circle
                      : Icons.replay,
                  size: 20,
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(
                    resultLabel(l10n, v.result),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  [?v.author, _when(l10n, v.at)].join(' · '),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            if (v.feedback != null)
              Padding(
                padding: const EdgeInsets.only(top: Space.xxs),
                child: Text(v.feedback!),
              ),
            if (correction != null) _CorrectionView(correction: correction),
            if (v.correctionAssetId != null)
              VoicePlayer(
                mediaAssetId: v.correctionAssetId,
                title: l10n.correctionForYou,
                icon: Icons.school_outlined,
                compact: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _CorrectionView extends StatelessWidget {
  const _CorrectionView({required this.correction});
  final Map<String, dynamic> correction;

  @override
  Widget build(BuildContext context) =>
      correction['media_asset_id'] != null
      ? VoicePlayer(
          mediaAssetId: correction['media_asset_id'] as String,
          title: correction['title'] as String?,
          subtitle: correction['explanation'] as String?,
          icon: Icons.school_outlined,
        )
      : Padding(
          padding: const EdgeInsets.only(top: Space.xxs),
          child: Text(
            '${correction['title']}: ${correction['explanation'] ?? ''}',
          ),
        );
}

/// A reply: the other side's on the start, mine on the end.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});
  final WorkMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final m = message;
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Card(
          color: m.fromTeacher
              ? theme.colorScheme.surfaceContainerHigh
              : theme.colorScheme.secondaryContainer,
          margin: const EdgeInsets.symmetric(vertical: Space.xxs),
          child: Padding(
            padding: const EdgeInsets.all(Space.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    mine
                        ? l10n.wtYou
                        : (m.author ??
                              (m.fromTeacher ? l10n.wtTeacher : l10n.wtLearner)),
                    _when(l10n, m.at),
                  ].join(' · '),
                  style: theme.textTheme.labelSmall,
                ),
                if (m.target != null && !m.target!.isWhole)
                  _TargetChip(target: m.target!),
                if (m.body != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.xxs),
                    child: Text(m.body!),
                  ),
                if (m.kind == 'voice' && m.mediaAssetId != null)
                  VoicePlayer(mediaAssetId: m.mediaAssetId, compact: true),
                if (m.kind == 'file' && m.mediaAssetId != null)
                  m.mediaKind == 'image'
                      ? InkWell(
                          onTap: () => openInApp(
                            context,
                            assetId: m.mediaAssetId,
                            kind: 'image',
                            title: l10n.wtAttachment,
                          ),
                          child: SizedBox(
                            height: 160,
                            child: SidraImage(
                              assetId: m.mediaAssetId!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : _FileTile(
                          file: {
                            'media_asset_id': m.mediaAssetId,
                            'kind': m.mediaKind,
                            'file_name': l10n.wtAttachment,
                          },
                        ),
                if (m.kind == 'correction' && m.correction != null)
                  _CorrectionView(correction: m.correction!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Work still on its way: each file's real upload progress, then "sending",
/// or why it stopped (with Retry, which keeps finished files).
class QueuedWorkCard extends ConsumerWidget {
  const QueuedWorkCard({super.key, required this.entry});
  final QueuedSubmission entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = ref.watch(uploadProgressProvider);
    final q = entry;
    final files = [
      for (final (i, f) in q.files.indexed)
        (f, progress['${q.id}#$i'], f.uploaded),
    ];
    final totalBytes = q.files.fold<int>(0, (s, f) => s + (f.bytes ?? 0));
    final sentBytes = [
      for (final (f, p, done) in files)
        done ? (f.bytes ?? 0) : (p?.sent ?? 0),
    ].fold<int>(0, (s, b) => s + b);
    final overall = totalBytes <= 0 ? null : sentBytes / totalBytes;
    final title = switch (q.state) {
      'uploading' => overall == null
          ? l10n.wtUploadingPlain
          : l10n.wtUploading((overall * 100).floor()),
      'submitting' => l10n.wtSubmitting,
      'failed' => l10n.wtFailed,
      _ => l10n.wtQueued,
    };
    return Card(
      margin: const EdgeInsetsDirectional.only(
        top: Space.xs,
        bottom: Space.xs,
        start: Space.xl,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  q.state == 'failed'
                      ? Icons.error_outline
                      : q.state == 'pending'
                      ? Icons.cloud_off_outlined
                      : Icons.cloud_upload_outlined,
                  size: 20,
                  color: q.state == 'failed' ? theme.colorScheme.error : null,
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleSmall),
                ),
                if (q.state == 'failed' || q.state == 'pending') ...[
                  TextButton(
                    onPressed: () =>
                        ref.read(submissionQueueProvider.notifier).retry(q.id),
                    child: Text(l10n.retry),
                  ),
                  IconButton(
                    tooltip: l10n.wtDiscard,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (await confirm(
                        context,
                        title: l10n.wtDiscard,
                        message: l10n.wtDiscardBody,
                        destructive: true,
                      )) {
                        await ref
                            .read(submissionQueueProvider.notifier)
                            .discard(q.id);
                      }
                    },
                  ),
                ],
              ],
            ),
            if (q.state == 'uploading' && overall != null)
              LinearProgressIndicator(value: overall),
            if (q.state == 'submitting') const LinearProgressIndicator(),
            if (q.error != null && q.state != 'uploading')
              Text(
                q.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: q.state == 'failed' ? theme.colorScheme.error : null,
                ),
              ),
            if (q.text != null)
              Padding(
                padding: const EdgeInsets.only(top: Space.xxs),
                child: Text(
                  q.text!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            for (final (f, p, done) in files)
              Padding(
                padding: const EdgeInsets.only(top: Space.xxs),
                child: Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : resourceIcon(f.kind),
                      size: 18,
                      color: done ? Colors.green.shade700 : null,
                    ),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Text(
                        f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text(
                        done
                            ? l10n.wtUploadedFile
                            : p == null
                            ? l10n.wtFileQueued
                            : '${(p.fraction * 100).floor()}%',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ================================================================= composer

/// Learner: a new attempt (recording, photos, files, text, what it is for)
/// or a reply on the latest attempt. Teacher: replies — voice, text, file,
/// a saved correction — as many as needed, and the verdict buttons.
class WorkComposer extends ConsumerStatefulWidget {
  const WorkComposer({
    super.key,
    required this.thread,
    required this.kind,
    required this.targetId,
    this.submissionTypes = const ['audio', 'image', 'document', 'text'],
    this.blocks = const [],
    this.onSent,
  });

  final WorkThread thread;
  final String kind;
  final String targetId;
  final List<String> submissionTypes;
  final List<TargetableBlock> blocks;
  final VoidCallback? onSent;

  @override
  ConsumerState<WorkComposer> createState() => _WorkComposerState();
}

class _WorkComposerState extends ConsumerState<WorkComposer> {
  final _text = TextEditingController();
  final _files = <QueuedFile>[];
  final _libTitle = TextEditingController();
  RecordedAudio? _audio;
  bool _recording = false;
  int _recorderKey = 0;
  bool _reply = false;
  bool _saveToLibrary = false;
  bool _sending = false;
  bool _expanded = false;
  Correction? _correction;
  WorkTarget? _target;

  WorkThread get t => widget.thread;
  bool get _teacher => t.asTeacher;

  /// Learners reply only once there is an attempt; teachers only reply.
  bool get _isReply => _teacher || (_reply && t.latest != null);

  bool get _hasContent =>
      _audio != null ||
      _files.isNotEmpty ||
      _text.text.trim().isNotEmpty ||
      _correction != null;

  @override
  void dispose() {
    _text.dispose();
    _libTitle.dispose();
    super.dispose();
  }

  void _clear() => setState(() {
    _audio = null;
    _files.clear();
    _text.clear();
    _correction = null;
    _recording = false;
    _recorderKey++;
    _saveToLibrary = false;
    _libTitle.clear();
    _target = null;
  });

  List<QueuedFile> get _allFiles => [
    if (_audio != null)
      QueuedFile(
        path: _audio!.path,
        name: _audio!.fileName,
        kind: 'audio',
        bytes: File(_audio!.path).lengthSync(),
      ),
    ..._files,
  ];

  Future<void> _addFile() async {
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

  /// Returns true when the server accepted it (false: queued / failed —
  /// the timeline shows it with progress or a Retry).
  Future<bool> _send() async {
    if (!_hasContent || _sending) return false;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    final queue = ref.read(submissionQueueProvider.notifier);
    final files = _allFiles;
    final text = _text.text.trim().isEmpty ? null : _text.text.trim();
    final target = _target?.j;
    final saveAs = _teacher && _saveToLibrary && _audio != null
        ? {
            'title': _libTitle.text.trim().isEmpty
                ? (text ?? l10n.wtCorrectionDefaultTitle)
                : _libTitle.text.trim(),
            'explanation': ?text,
          }
        : null;
    final correctionId = _correction?.id;
    final reply = _isReply;
    _clear();
    setState(() => _expanded = false);
    final ok = reply
        ? await queue.reply(
            submissionId: t.latest!.submissionId,
            workKind: widget.kind,
            workId: widget.targetId,
            text: text,
            correctionId: correctionId,
            target: target,
            saveAs: saveAs,
            files: files,
          )
        : await queue.submit(
            portionId: widget.kind == 'portion' ? widget.targetId : null,
            lessonId: widget.kind == 'lesson' ? widget.targetId : null,
            assignmentId: widget.kind == 'assignment' ? widget.targetId : null,
            text: text,
            target: target,
            files: files,
          );
    if (!mounted) return ok;
    setState(() => _sending = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (reply ? l10n.wtReplySent : l10n.sentToTeacher)
              : l10n.subSavedForLater,
        ),
      ),
    );
    widget.onSent?.call();
    return ok;
  }

  /// Teacher: send what is composed (if anything), then the verdict.
  Future<void> _verdict(ReviewResult result) async {
    final l10n = AppLocalizations.of(context);
    final latest = t.latest;
    if (latest == null) return;
    // Typed text goes with the verdict; recordings / files / a saved
    // correction go first as replies so they arrive before it.
    final feedback = _text.text.trim().isEmpty ? null : _text.text.trim();
    _text.clear();
    if (_audio != null || _files.isNotEmpty || _correction != null) {
      if (!await _send()) return; // offline: the verdict waits for it
    }
    if (!mounted) return;
    final ok = await runAdminAction(
      context,
      () => ref
          .read(teachingRepositoryProvider)
          .review(
            submissionId: latest.submissionId,
            result: result,
            feedback: feedback,
          ),
      success: l10n.reviewSent,
    );
    if (ok) widget.onSent?.call();
  }

  Future<void> _pickTarget() async {
    final picked = await showTargetPicker(
      context,
      current: _target,
      blocks: widget.blocks,
    );
    if (picked != null) setState(() => _target = picked.isWhole ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final types = widget.submissionTypes;
    final canAttempt = !_teacher && !t.completed;
    final latest = t.latest;
    return Material(
      elevation: 6,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, Space.sm),
        child: ConstrainedBox(
          // Never taller than half the screen; scrolls inside if needed.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.55,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------------------------------- mode + target
                if (canAttempt && latest != null)
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.add_task),
                        label: Text(l10n.wtNewAttempt),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.reply),
                        label: Text(l10n.wtReply),
                      ),
                    ],
                    selected: {_reply},
                    onSelectionChanged: (s) => setState(() => _reply = s.first),
                  ),
                if (_teacher && latest != null) ...[
                  Text(
                    l10n.wtMarkLatest(latest.number),
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: Space.xxs),
                  Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [
                      FilledButton.icon(
                        onPressed: _sending
                            ? null
                            : () => _verdict(ReviewResult.correct),
                        icon: const Icon(Icons.check),
                        label: Text(l10n.resCorrect),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _sending
                            ? null
                            : () => _verdict(ReviewResult.excellent),
                        icon: const Icon(Icons.star_outline),
                        label: Text(l10n.resExcellent),
                      ),
                      OutlinedButton.icon(
                        onPressed: _sending
                            ? null
                            : () => _verdict(ReviewResult.minorCorrection),
                        icon: const Icon(Icons.warning_amber_outlined),
                        label: Text(l10n.resMinor),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.tertiary,
                        ),
                        onPressed: _sending
                            ? null
                            : () => _verdict(ReviewResult.correctionRequired),
                        icon: const Icon(Icons.replay),
                        label: Text(l10n.wtTryAgainAction),
                      ),
                    ],
                  ),
                  const Divider(height: Space.md),
                ],
                if (!_teacher && !canAttempt)
                  const SizedBox.shrink()
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isReply
                              ? (_teacher ? l10n.wtTeacherReplyHint : l10n.wtLearnerReplyHint)
                              : l10n.wtNewAttemptHint,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickTarget,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: Text(
                          _target == null
                              ? l10n.wtChooseTargetShort
                              : _target!.describe(l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (_recording || _audio != null)
                    VoiceRecorder(
                      key: ValueKey(_recorderKey),
                      hint: _isReply ? null : l10n.recordHint,
                      onChanged: (a) => setState(() => _audio = a),
                    ),
                  if (_teacher && _audio != null) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _saveToLibrary,
                      onChanged: (v) => setState(() => _saveToLibrary = v),
                      title: Text(l10n.reviewSaveToLibrary),
                      subtitle: Text(l10n.reviewSaveToLibraryHint),
                    ),
                    if (_saveToLibrary)
                      TextField(
                        controller: _libTitle,
                        decoration: InputDecoration(
                          labelText: l10n.correctionTitle,
                          hintText: l10n.correctionTitleHint,
                        ),
                      ),
                  ],
                  if (_correction != null)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.school_outlined),
                      title: Text(_correction!.title),
                      trailing: IconButton(
                        tooltip: l10n.audioDiscard,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _correction = null),
                      ),
                    ),
                  for (final (i, f) in _files.indexed)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: f.kind == 'image'
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(Radii.sm),
                              child: Image.file(
                                File(f.path),
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(resourceIcon(f.kind)),
                      title: Text(
                        f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(formatFileSize(f.bytes ?? 0)),
                      trailing: IconButton(
                        tooltip: l10n.audioDiscard,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _files.removeAt(i)),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_teacher || _isReply || types.contains('audio'))
                        IconButton(
                          tooltip: l10n.wtRecord,
                          icon: Icon(_recording ? Icons.mic : Icons.mic_none),
                          onPressed: () => setState(() => _recording = true),
                        ),
                      if (_teacher ||
                          _isReply ||
                          types.contains('image') ||
                          types.contains('document') ||
                          types.contains('video'))
                        IconButton(
                          tooltip: l10n.capAddWork,
                          icon: const Icon(Icons.attach_file),
                          onPressed: _addFile,
                        ),
                      if (_teacher)
                        IconButton(
                          tooltip: l10n.reviewUseExisting,
                          icon: const Icon(Icons.library_books_outlined),
                          onPressed: () async {
                            final c = await showCorrectionPicker(context, ref);
                            if (c != null) setState(() => _correction = c);
                          },
                        ),
                      Expanded(
                        child: TextField(
                          controller: _text,
                          minLines: 1,
                          maxLines: _expanded ? 6 : 3,
                          textInputAction: TextInputAction.newline,
                          onTap: () => setState(() => _expanded = true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: _teacher
                                ? l10n.wtTeacherTextHint
                                : l10n.wtTextHint,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.xs),
                      IconButton.filled(
                        tooltip: _isReply ? l10n.wtSendReply : l10n.sendToTeacher,
                        onPressed: _hasContent && !_sending ? _send : null,
                        icon: _sending
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================ target picker

/// "What is this for?": the whole work, an ayah or ayat, a page / line, an
/// exercise, or words highlighted in the lesson itself.
Future<WorkTarget?> showTargetPicker(
  BuildContext context, {
  WorkTarget? current,
  List<TargetableBlock> blocks = const [],
}) => showModalBottomSheet<WorkTarget>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _TargetPicker(current: current, blocks: blocks),
);

class _TargetPicker extends StatefulWidget {
  const _TargetPicker({this.current, required this.blocks});
  final WorkTarget? current;
  final List<TargetableBlock> blocks;

  @override
  State<_TargetPicker> createState() => _TargetPickerState();
}

class _TargetPickerState extends State<_TargetPicker> {
  late String _kind = widget.current?.kind ?? 'whole';
  late final _surah = TextEditingController(text: _v('surah'));
  late final _from = TextEditingController(text: _v('ayah_start'));
  late final _to = TextEditingController(text: _v('ayah_end'));
  late final _page = TextEditingController(text: _v('page'));
  late final _line = TextEditingController(text: _v('line'));
  late final _lineTo = TextEditingController(text: _v('line_end'));
  late final _exercise = TextEditingController(text: _v('exercise'));
  String? _error;

  String _v(String k) => '${widget.current?.j[k] ?? ''}';

  @override
  void dispose() {
    for (final c in [_surah, _from, _to, _page, _line, _lineTo, _exercise]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _n(TextEditingController c) => int.tryParse(c.text.trim());

  void _use() {
    final l10n = AppLocalizations.of(context);
    WorkTarget? t;
    switch (_kind) {
      case 'whole':
        t = WorkTarget.whole();
      case 'ayah':
        final s = _n(_surah), a = _n(_from), b = _n(_to);
        if (s == null || s < 1 || s > 114 || a == null || a < 1 || a > 286 ||
            (b != null && (b < a || b > 286))) {
          setState(() => _error = l10n.wtAyahInvalid);
          return;
        }
        t = WorkTarget.ayah(s, a, b);
      case 'page_line':
        final p = _n(_page), l = _n(_line), le = _n(_lineTo);
        if (p == null || p < 1 || (l != null && l < 1) ||
            (le != null && (l == null || le < l))) {
          setState(() => _error = l10n.wtPageInvalid);
          return;
        }
        t = WorkTarget.pageLine(p, l, le);
      case 'exercise':
        if (_exercise.text.trim().isEmpty) {
          setState(() => _error = l10n.wtExerciseInvalid);
          return;
        }
        t = WorkTarget.exercise(_exercise.text.trim());
    }
    Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget num(TextEditingController c, String label) => Expanded(
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.lg,
        0,
        Space.lg,
        MediaQuery.viewInsetsOf(context).bottom + Space.lg,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(l10n.wtChooseTarget, style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          RadioGroup<String>(
            groupValue: _kind,
            onChanged: (v) => setState(() {
              _kind = v ?? 'whole';
              _error = null;
            }),
            child: Column(
              children: [
                RadioListTile(value: 'whole', title: Text(l10n.targetWhole)),
                RadioListTile(value: 'ayah', title: Text(l10n.wtTargetAyah)),
                if (_kind == 'ayah')
                  Row(
                    children: [
                      num(_surah, l10n.wtSurah),
                      const SizedBox(width: Space.sm),
                      num(_from, l10n.wtAyahFrom),
                      const SizedBox(width: Space.sm),
                      num(_to, l10n.wtAyahTo),
                    ],
                  ),
                RadioListTile(value: 'page_line', title: Text(l10n.wtTargetPageLine)),
                if (_kind == 'page_line')
                  Row(
                    children: [
                      num(_page, l10n.wtPage),
                      const SizedBox(width: Space.sm),
                      num(_line, l10n.wtLine),
                      const SizedBox(width: Space.sm),
                      num(_lineTo, l10n.wtLineTo),
                    ],
                  ),
                RadioListTile(value: 'exercise', title: Text(l10n.wtTargetExercise)),
                if (_kind == 'exercise')
                  TextField(
                    controller: _exercise,
                    decoration: InputDecoration(
                      labelText: l10n.wtExerciseName,
                      hintText: l10n.wtExerciseHint,
                      isDense: true,
                    ),
                  ),
                if (widget.blocks.isNotEmpty)
                  RadioListTile(value: 'block', title: Text(l10n.wtTargetText)),
              ],
            ),
          ),
          if (_kind == 'block')
            for (final b in widget.blocks)
              Card(
                child: ListTile(
                  title: Text(
                    b.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: b.arabic ? TextDirection.rtl : null,
                  ),
                  subtitle: b.label == null ? null : Text(b.label!),
                  trailing: const Icon(Icons.highlight),
                  onTap: () async {
                    final t = await Navigator.of(context).push<WorkTarget>(
                      MaterialPageRoute(
                        builder: (_) => _HighlightScreen(block: b),
                      ),
                    );
                    if (t != null && context.mounted) Navigator.pop(context, t);
                  },
                ),
              ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: Space.md),
          if (_kind != 'block')
            FilledButton(onPressed: _use, child: Text(l10n.wtUseTarget)),
        ],
      ),
    );
  }
}

/// Highlight words in one passage; the target keeps the block and the exact
/// character range (not a screenshot), or the ayah numbers for Qur'an text.
class _HighlightScreen extends StatefulWidget {
  const _HighlightScreen({required this.block});
  final TargetableBlock block;

  @override
  State<_HighlightScreen> createState() => _HighlightScreenState();
}

class _HighlightScreenState extends State<_HighlightScreen> {
  TextSelection _sel = const TextSelection.collapsed(offset: -1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final b = widget.block;
    final has = _sel.isValid && !_sel.isCollapsed;
    final quote = has ? _sel.textInside(b.text).trim() : '';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wtTargetText)),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          Text(l10n.wtSelectHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: Space.md),
          SelectableText(
            b.text,
            textDirection: b.arabic ? TextDirection.rtl : null,
            style: (b.arabic
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.bodyLarge)
                ?.copyWith(height: 1.8),
            onSelectionChanged: (s, _) => setState(() => _sel = s),
          ),
          if (has) ...[
            const SizedBox(height: Space.md),
            Text(l10n.wtSelected, style: theme.textTheme.labelLarge),
            Text(
              '“$quote”',
              textDirection: b.arabic ? TextDirection.rtl : null,
            ),
          ],
          if (b.surah != null && b.verseStart != null) ...[
            const SizedBox(height: Space.md),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(
                context,
                WorkTarget.ayah(b.surah!, b.verseStart!, b.verseEnd),
              ),
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(
                l10n.wtUseWholePassage(
                  WorkTarget.ayah(b.surah!, b.verseStart!, b.verseEnd)
                      .describe(l10n),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: FilledButton.icon(
            onPressed: !has
                ? null
                : () {
                    final start = _sel.start < _sel.end ? _sel.start : _sel.end;
                    final end = _sel.start < _sel.end ? _sel.end : _sel.start;
                    Navigator.pop(
                      context,
                      WorkTarget.block(b.id, start, end, quote, b.label),
                    );
                  },
            icon: const Icon(Icons.highlight),
            label: Text(l10n.wtUseSelection),
          ),
        ),
      ),
    );
  }
}

/// Opens a thread as its own page.
Future<void> openWorkThread(
  BuildContext context, {
  required String kind,
  required String targetId,
  String? learnerId,
  String? title,
  List<String> submissionTypes = const ['audio', 'image', 'document', 'text'],
  List<TargetableBlock> blocks = const [],
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => WorkThreadScreen(
      kind: kind,
      targetId: targetId,
      learnerId: learnerId,
      title: title,
      submissionTypes: submissionTypes,
      blocks: blocks,
    ),
  ),
);

/// Thrown text for a failure, for snack bars.
String failureText(AppLocalizations l10n, Object e) =>
    e is AppFailure && e.message.isNotEmpty ? e.message : l10n.genericError;
