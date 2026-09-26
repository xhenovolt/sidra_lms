import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../admin/data/admin_repository.dart' show fileKindFor;
import '../../admin/presentation/admin_common.dart';
import '../data/content_repository.dart';
import '../data/submission_queue.dart';
import 'resource_widgets.dart';

final lessonAssignmentsProvider = FutureProvider.autoDispose
    .family<List<Assignment>, String>(
      (ref, lessonId) =>
          ref.watch(contentRepositoryProvider).assignmentsForLesson(lessonId),
    );

final mySubmissionsProvider = FutureProvider.autoDispose
    .family<List<Submission>, String>(
      (ref, assignmentId) =>
          ref.watch(contentRepositoryProvider).mySubmissions(assignmentId),
    );

typedef SubmissionFilter = ({String? lessonId, String? status});

final teacherSubmissionsProvider = FutureProvider.autoDispose
    .family<List<Submission>, SubmissionFilter>(
      (ref, f) => ref
          .watch(contentRepositoryProvider)
          .teacherSubmissions(lessonId: f.lessonId, status: f.status),
    );

String submissionStatusLabel(AppLocalizations l10n, String s) => switch (s) {
  'submitted' => l10n.subSubmitted,
  'received' => l10n.subReceived,
  'under_review' => l10n.subUnderReview,
  'reviewed' => l10n.subReviewed,
  'returned' => l10n.subReturned,
  'resubmission_requested' => l10n.subResubmit,
  _ => s,
};

// =============================================================== learner ==

/// The assignments in a lesson, with the learner's work and feedback.
class LessonAssignmentsView extends ConsumerWidget {
  const LessonAssignmentsView({super.key, required this.lessonId});
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list =
        ref.watch(lessonAssignmentsProvider(lessonId)).value ?? const [];
    final published = list.where((a) => a.published).toList();
    if (published.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final a in published) _AssignmentCard(assignment: a)],
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  const _AssignmentCard({required this.assignment});
  final Assignment assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final a = assignment;
    final subs = ref.watch(mySubmissionsProvider(a.id)).value ?? const [];
    final latest = subs.firstOrNull;
    final queued = (ref.watch(submissionQueueProvider).value ?? const [])
        .where((q) => q.assignmentId == a.id)
        .toList();
    final canSubmit = queued.isEmpty && (latest == null || latest.canResubmit);
    final date = DateFormat.yMMMd(l10n.localeName);

    return Card(
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
                Expanded(
                  child: Text(a.title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            if (a.instructions != null) ...[
              const SizedBox(height: Space.xs),
              Text(a.instructions!),
            ],
            if (a.dueAt != null)
              Text(
                l10n.assignmentDue(date.format(a.dueAt!.toLocal())),
                style: theme.textTheme.bodySmall,
              ),
            ResourceListView(target: ResourceTarget.assignment, id: a.id),
            for (final q in queued)
              Padding(
                padding: const EdgeInsets.only(top: Space.sm),
                child: _QueuedTile(entry: q),
              ),
            if (latest != null) ...[
              const Divider(height: Space.lg),
              Text(
                l10n.subYourWork(
                  submissionStatusLabel(l10n, latest.status),
                  latest.attempt,
                ),
                style: theme.textTheme.labelLarge,
              ),
              if (latest.feedback != null)
                Container(
                  margin: const EdgeInsets.only(top: Space.xs),
                  padding: const EdgeInsets.all(Space.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Text(
                    [
                      if (latest.reviewer != null) '${latest.reviewer}:',
                      latest.feedback!,
                      if (latest.score != null)
                        '(${_fmt(latest.score!)}${a.maxScore == null ? '' : ' / ${_fmt(a.maxScore!)}'})',
                    ].join(' '),
                  ),
                ),
            ],
            if (canSubmit) ...[
              const SizedBox(height: Space.sm),
              FilledButton.icon(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => SubmitWorkSheet(assignment: a),
                  );
                  ref.invalidate(mySubmissionsProvider(a.id));
                },
                icon: const Icon(Icons.upload),
                label: Text(
                  latest == null ? l10n.subSubmitWork : l10n.subSubmitAgain,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

class _QueuedTile extends ConsumerWidget {
  const _QueuedTile({required this.entry});
  final QueuedSubmission entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final uploading = entry.state == 'uploading';
    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          uploading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  entry.state == 'failed'
                      ? Icons.error_outline
                      : Icons.cloud_upload_outlined,
                ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(switch (entry.state) {
              'uploading' => l10n.uploadUploading,
              'failed' => l10n.subUploadFailed,
              _ => l10n.subWaitingToUpload,
            }),
          ),
          if (!uploading)
            TextButton(
              onPressed: () =>
                  ref.read(submissionQueueProvider.notifier).retry(entry.id),
              child: Text(l10n.retry),
            ),
        ],
      ),
    );
  }
}

/// Hand in work: photos (camera or gallery), files, and / or a written answer.
class SubmitWorkSheet extends ConsumerStatefulWidget {
  const SubmitWorkSheet({super.key, required this.assignment});
  final Assignment assignment;

  @override
  ConsumerState<SubmitWorkSheet> createState() => _SubmitWorkSheetState();
}

class _SubmitWorkSheetState extends ConsumerState<SubmitWorkSheet> {
  final _files = <QueuedFile>[];
  final _text = TextEditingController();
  bool _sending = false;

  Assignment get a => widget.assignment;

  Future<void> _photo(ImageSource source) async {
    final x = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 2200,
    );
    if (x == null) return;
    final size = await File(x.path).length();
    setState(
      () => _files.add(
        QueuedFile(path: x.path, name: x.name, kind: 'image', bytes: size),
      ),
    );
  }

  Future<void> _file() async {
    final exts = [
      if (a.submissionTypes.contains('document')) ...[
        'pdf', 'doc', 'docx', 'txt', //
      ],
      if (a.submissionTypes.contains('image')) ...[
        'jpg',
        'jpeg',
        'png',
        'webp',
      ],
      if (a.submissionTypes.contains('audio')) ...['mp3', 'm4a', 'wav', 'aac'],
      if (a.submissionTypes.contains('video')) ...['mp4', 'mov'],
    ];
    if (exts.isEmpty) return;
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: exts,
    );
    final path = f?.path;
    if (f == null || path == null) return;
    setState(
      () => _files.add(
        QueuedFile(
          path: path,
          name: f.name,
          kind: fileKindFor(f.name),
          bytes: File(path).lengthSync(),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    final ok = await ref
        .read(submissionQueueProvider.notifier)
        .submit(
          assignmentId: a.id,
          text: _text.text.trim().isEmpty ? null : _text.text.trim(),
          files: List.of(_files),
        );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(ok ? l10n.subHandedIn : l10n.subSavedForLater)),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final allowsImages = a.submissionTypes.contains('image');
    final allowsFiles = a.submissionTypes.any(
      (t) => t == 'document' || t == 'audio' || t == 'video',
    );
    final allowsText = a.submissionTypes.contains('text');
    final full = _files.length >= a.maxFiles;
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
          Text(a.title, style: theme.textTheme.titleLarge),
          if (a.instructions != null) Text(a.instructions!),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              if (allowsImages) ...[
                OutlinedButton.icon(
                  onPressed: full ? null : () => _photo(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.subTakePhoto),
                ),
                OutlinedButton.icon(
                  onPressed: full ? null : () => _photo(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.subFromGallery),
                ),
              ],
              if (allowsFiles || allowsImages)
                OutlinedButton.icon(
                  onPressed: full ? null : _file,
                  icon: const Icon(Icons.attach_file),
                  label: Text(l10n.subAttachFile),
                ),
            ],
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
              subtitle: Text(formatBytes(f.bytes)),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _files.removeAt(i)),
              ),
            ),
          if (allowsText)
            TextField(
              controller: _text,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.subYourAnswer),
            ),
          const SizedBox(height: Space.md),
          FilledButton(
            onPressed: _sending || (_files.isEmpty && _text.text.trim().isEmpty)
                ? null
                : _send,
            child: Text(_sending ? l10n.uploadUploading : l10n.subHandIn),
          ),
          const SizedBox(height: Space.xs),
          Text(l10n.subPrivacyNote, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// =============================================================== teacher ==

/// Work handed in to the lessons this teacher teaches.
class SubmissionsList extends ConsumerStatefulWidget {
  const SubmissionsList({super.key, this.lessonId});
  final String? lessonId;

  @override
  ConsumerState<SubmissionsList> createState() => _SubmissionsListState();
}

class _SubmissionsListState extends ConsumerState<SubmissionsList> {
  String? _status = 'submitted';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final key = (lessonId: widget.lessonId, status: _status);
    final subs = ref.watch(teacherSubmissionsProvider(key));
    final date = DateFormat.yMMMd(l10n.localeName).add_jm();
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.xs,
          ),
          child: Row(
            children: [
              for (final s in <String?>[
                'submitted',
                'under_review',
                'resubmission_requested',
                'reviewed',
                null,
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Space.xs),
                  child: ChoiceChip(
                    label: Text(
                      s == null
                          ? l10n.adminEveryone
                          : submissionStatusLabel(l10n, s),
                    ),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.refresh(teacherSubmissionsProvider(key).future),
            child: switch (subs) {
              AsyncData(:final value) when value.isEmpty => ListView(
                children: [
                  EmptyView(
                    icon: Icons.inbox_outlined,
                    title: l10n.subNoneToReview,
                  ),
                ],
              ),
              AsyncData(:final value) => ListView.separated(
                itemCount: value.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = value[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (s.learner ?? '?').characters.first.toUpperCase(),
                      ),
                    ),
                    title: Text(
                      '${s.learner ?? '—'} · ${s.assignmentTitle ?? ''}',
                    ),
                    subtitle: Text(
                      [
                        submissionStatusLabel(l10n, s.status),
                        ?s.lessonTitle,
                        l10n.subFilesCount(s.files.length),
                        if (s.submittedAt != null)
                          date.format(s.submittedAt!.toLocal()),
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SubmissionReviewScreen(submission: s),
                        ),
                      );
                      ref.invalidate(teacherSubmissionsProvider(key));
                    },
                  );
                },
              ),
              AsyncError(:final error) => ListView(
                children: [
                  ErrorView(
                    error: error,
                    onRetry: () =>
                        ref.invalidate(teacherSubmissionsProvider(key)),
                  ),
                ],
              ),
              _ => const LoadingView(),
            },
          ),
        ),
      ],
    );
  }
}

class SubmissionsScreen extends StatelessWidget {
  const SubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).subTitle)),
    body: const SubmissionsList(),
  );
}

/// Open a learner's work, look at it, give feedback, decide.
class SubmissionReviewScreen extends ConsumerStatefulWidget {
  const SubmissionReviewScreen({super.key, required this.submission});
  final Submission submission;

  @override
  ConsumerState<SubmissionReviewScreen> createState() =>
      _SubmissionReviewScreenState();
}

class _SubmissionReviewScreenState
    extends ConsumerState<SubmissionReviewScreen> {
  late Submission _s = widget.submission;
  late final _feedback = TextEditingController(text: _s.feedback);
  late final _score = TextEditingController(
    text: _s.score == null ? '' : _fmt(_s.score!),
  );
  final _urls = <String, String>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUrls();
    // Opening new work tells the learner it has been received.
    if (_s.status == 'submitted') _set('received', quiet: true);
  }

  Future<void> _loadUrls() async {
    final repo = ref.read(contentRepositoryProvider);
    for (final f in _s.files) {
      try {
        final url = await repo.mediaUrl(f.mediaAssetId);
        if (mounted) setState(() => _urls[f.mediaAssetId] = url);
      } on AppFailure {
        // shown as unavailable
      }
    }
  }

  Future<void> _set(String status, {bool quiet = false}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    final repo = ref.read(contentRepositoryProvider);
    Submission? updated;
    final ok = await runAdminAction(
      context,
      () async => updated = await repo.review(
        _s.id,
        status,
        feedback: _feedback.text.trim().isEmpty ? null : _feedback.text.trim(),
        score: double.tryParse(_score.text.trim()),
      ),
      success: quiet ? null : l10n.adminSaved,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok && updated != null) _s = updated!;
    });
    if (ok && !quiet && status != 'under_review') Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd(l10n.localeName).add_jm();
    return Scaffold(
      appBar: AppBar(title: Text(_s.learner ?? l10n.subTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          Text(_s.assignmentTitle ?? '', style: theme.textTheme.titleMedium),
          Text(
            [
              ?_s.courseTitle,
              ?_s.lessonTitle,
              l10n.subAttempt(_s.attempt),
              if (_s.submittedAt != null)
                date.format(_s.submittedAt!.toLocal()),
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          Text(
            submissionStatusLabel(l10n, _s.status),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          if (_s.text != null) ...[
            const SizedBox(height: Space.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: SelectableText(_s.text!),
              ),
            ),
          ],
          for (final f in _s.files) ...[
            const SizedBox(height: Space.sm),
            if (f.kind == 'image' && _urls[f.mediaAssetId] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: InteractiveViewer(
                  maxScale: 5,
                  child: CachedNetworkImage(imageUrl: _urls[f.mediaAssetId]!),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: Icon(resourceIcon(f.kind)),
                  title: Text(f.fileName),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _urls[f.mediaAssetId] == null
                      ? null
                      : () => openResource(
                          context,
                          ref,
                          Resource({
                            'id': f.mediaAssetId,
                            'provider': 'external',
                            'url': _urls[f.mediaAssetId],
                          }),
                        ),
                ),
              ),
          ],
          const SizedBox(height: Space.md),
          TextField(
            controller: _feedback,
            maxLines: 4,
            decoration: InputDecoration(labelText: l10n.subFeedback),
          ),
          TextField(
            controller: _score,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.subScoreOptional),
          ),
          const SizedBox(height: Space.md),
          FilledButton.icon(
            onPressed: _saving ? null : () => _set('reviewed'),
            icon: const Icon(Icons.check),
            label: Text(l10n.subMarkReviewed),
          ),
          const SizedBox(height: Space.xs),
          OutlinedButton.icon(
            onPressed: _saving ? null : () => _set('resubmission_requested'),
            icon: const Icon(Icons.replay),
            label: Text(l10n.subRequestResubmission),
          ),
          const SizedBox(height: Space.xs),
          TextButton(
            onPressed: _saving ? null : () => _set('under_review'),
            child: Text(l10n.subMarkUnderReview),
          ),
        ],
      ),
    );
  }
}

// ================================================================= admin ==

/// Create or edit an assignment on a lesson.
Future<bool> showAssignmentForm(
  BuildContext context,
  WidgetRef ref, {
  required String courseId,
  required String lessonId,
  Assignment? existing,
  int position = 0,
}) async {
  final l10n = AppLocalizations.of(context);
  final title = TextEditingController(text: existing?.title);
  final instructions = TextEditingController(text: existing?.instructions);
  final maxScore = TextEditingController(
    text: existing?.maxScore == null ? '' : _fmt(existing!.maxScore!),
  );
  final types = {
    ...(existing?.submissionTypes ?? const ['image', 'document']),
  };
  var published = existing?.published ?? true;
  final form = GlobalKey<FormState>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existing == null ? l10n.assignmentAdd : l10n.adminEdit),
        content: SizedBox(
          width: 460,
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
                    controller: instructions,
                    label: l10n.assignmentInstructions,
                    maxLines: 4,
                  ),
                  Text(l10n.assignmentAccepts),
                  Wrap(
                    spacing: Space.xs,
                    children: [
                      for (final (t, label) in [
                        ('image', l10n.assignmentPhotos),
                        ('document', l10n.assignmentDocuments),
                        ('audio', l10n.assignmentAudio),
                        ('video', l10n.assignmentVideo),
                        ('text', l10n.assignmentText),
                      ])
                        FilterChip(
                          label: Text(label),
                          selected: types.contains(t),
                          onSelected: (v) => setState(
                            () => v ? types.add(t) : types.remove(t),
                          ),
                        ),
                    ],
                  ),
                  AdminField(
                    controller: maxScore,
                    label: l10n.assignmentMaxScore,
                    keyboardType: TextInputType.number,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: published,
                    onChanged: (v) => setState(() => published = v),
                    title: Text(l10n.adminVisibleToLearners),
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
              if (form.currentState!.validate() && types.isNotEmpty) {
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
  return runAdminAction(
    context,
    () => ref.read(contentRepositoryProvider).saveAssignment({
      'title': title.text.trim(),
      'instructions': nullIfBlank(instructions.text),
      'submission_types': types.toList(),
      'max_score': double.tryParse(maxScore.text.trim()),
      'status': published ? 'published' : 'draft',
      if (existing == null) ...{
        'course_id': courseId,
        'lesson_id': lessonId,
        'position': position,
      },
    }, id: existing?.id),
    success: l10n.adminSaved,
  );
}

/// Lesson editor tab: the lesson's assignments.
class AssignmentManager extends ConsumerWidget {
  const AssignmentManager({
    super.key,
    required this.courseId,
    required this.lessonId,
  });
  final String courseId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(lessonAssignmentsProvider(lessonId));
    void reload() => ref.invalidate(lessonAssignmentsProvider(lessonId));
    final items = list.value ?? const <Assignment>[];
    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        Text(l10n.assignmentHint),
        const SizedBox(height: Space.sm),
        OutlinedButton.icon(
          onPressed: () async {
            if (await showAssignmentForm(
              context,
              ref,
              courseId: courseId,
              lessonId: lessonId,
              position: items.length,
            )) {
              reload();
            }
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.assignmentAdd),
        ),
        for (final a in items)
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: Text(a.title),
                  subtitle: Text(
                    [
                      if (!a.published) l10n.adminHidden,
                      a.submissionTypes.join(', '),
                      if (a.maxScore != null) '/ ${_fmt(a.maxScore!)}',
                    ].join(' · '),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        if (await showAssignmentForm(
                          context,
                          ref,
                          courseId: courseId,
                          lessonId: lessonId,
                          existing: a,
                        )) {
                          reload();
                        }
                      } else if (v == 'delete' &&
                          await confirm(
                            context,
                            title: l10n.adminDeleteTitle,
                            message: l10n.assignmentDeleteBody,
                            destructive: true,
                          ) &&
                          context.mounted &&
                          await runAdminAction(
                            context,
                            () => ref
                                .read(contentRepositoryProvider)
                                .deleteAssignment(a.id),
                          )) {
                        reload();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text(l10n.adminEdit)),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.adminDelete),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.md,
                    0,
                    Space.md,
                    Space.sm,
                  ),
                  child: ResourceManager(
                    target: ResourceTarget.assignment,
                    id: a.id,
                    header: false,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
