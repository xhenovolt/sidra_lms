import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/data/repository_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/notifications/transfer_notifications.dart';
import '../../admin/data/admin_repository.dart';
import '../../admin/presentation/admin_common.dart';
import '../../teaching/data/work_thread.dart';

/// A file chosen for a submission, and where its upload stands.
class QueuedFile {
  QueuedFile({
    required this.path,
    required this.name,
    required this.kind,
    this.bytes,
    this.mediaAssetId,
  });

  factory QueuedFile.fromJson(Map<String, dynamic> j) => QueuedFile(
    path: j['path'] as String,
    name: j['name'] as String,
    kind: j['kind'] as String,
    bytes: j['bytes'] as int?,
    mediaAssetId: j['media_asset_id'] as String?,
  );

  final String path;
  final String name;
  final String kind;
  final int? bytes;

  /// Set once uploaded, so a retry never uploads the same file twice.
  String? mediaAssetId;

  bool get uploaded => mediaAssetId != null;

  Map<String, Object?> toJson() => {
    'path': path,
    'name': name,
    'kind': kind,
    'bytes': bytes,
    'media_asset_id': mediaAssetId,
  };
}

/// Work waiting to reach the server: a new attempt, or a reply on an
/// attempt ([replyTo]). States shown on screen:
///   pending     queued (offline: waiting for a connection)
///   uploading   files going up, with real byte progress (uploadProgressProvider)
///   submitting  files are up; recording it in Sidra
///   failed      stopped with a reason; Retry keeps finished files
/// It is only "sent" once the server has accepted it, and is sent once: the
/// ids are made here, so a retry after a timeout never duplicates it.
class QueuedSubmission {
  QueuedSubmission({
    required this.id,
    this.assignmentId,
    this.portionId,
    this.lessonId,
    required this.files,
    this.text,
    this.target,
    this.replyTo,
    this.correctionId,
    this.saveAs,
    List<String>? messageIds,
    this.state = 'pending',
    this.error,
  }) : messageIds = messageIds ?? const [];

  factory QueuedSubmission.fromJson(Map<String, dynamic> j) => QueuedSubmission(
    id: j['id'] as String,
    assignmentId: j['assignment_id'] as String?,
    portionId: j['portion_id'] as String?,
    lessonId: j['lesson_id'] as String?,
    text: j['text'] as String?,
    target: (j['target'] as Map?)?.cast<String, dynamic>(),
    replyTo: j['reply_to'] as String?,
    correctionId: j['correction_id'] as String?,
    saveAs: (j['save_as'] as Map?)?.cast<String, dynamic>(),
    messageIds: [for (final m in (j['message_ids'] as List? ?? const [])) '$m'],
    files: [
      for (final f in (j['files'] as List? ?? const []))
        QueuedFile.fromJson(Map<String, dynamic>.from(f as Map)),
    ],
    // An app killed mid-upload restarts the entry from "queued".
    state: switch (j['state'] as String?) {
      'failed' => 'failed',
      _ => 'pending',
    },
    error: j['error'] as String?,
  );

  final String id;
  final String? assignmentId;

  /// Teaching portion (recitation) instead of an assignment.
  final String? portionId;

  /// A lesson's own work (course rules).
  final String? lessonId;
  final String? text;
  final List<QueuedFile> files;

  /// What the attempt / reply is about (a line, an ayah…); see 0044.
  final Map<String, dynamic>? target;

  /// Set for a reply on this attempt (submission id) instead of a new attempt.
  final String? replyTo;

  /// Teacher reply: a library correction to send.
  final String? correctionId;

  /// Teacher reply: keep the (first) voice note in the correction library.
  final Map<String, dynamic>? saveAs;

  /// Reply parts' ids (one per file, then the text, then the correction).
  final List<String> messageIds;
  String state;
  String? error;

  bool get isReply => replyTo != null;

  /// portion | lesson | assignment, and its id.
  (String, String) get work => portionId != null
      ? ('portion', portionId!)
      : lessonId != null
      ? ('lesson', lessonId!)
      : ('assignment', assignmentId!);

  Map<String, Object?> toJson() => {
    'id': id,
    'assignment_id': assignmentId,
    'portion_id': portionId,
    'lesson_id': lessonId,
    'text': text,
    'target': target,
    'reply_to': replyTo,
    'correction_id': correctionId,
    'save_as': saveAs,
    'message_ids': messageIds,
    'files': [for (final f in files) f.toJson()],
    'state': state,
    'error': error,
  };
}

/// Live byte progress of one file of a queued entry.
class FileProgress {
  const FileProgress(this.sent, this.total);
  final int sent;
  final int total;
  double get fraction => total <= 0 ? 0 : (sent / total).clamp(0, 1);
}

/// Upload progress by "entryId#fileIndex", straight from the upload's own
/// byte counts. In memory only (a restarted upload starts over).
class UploadProgress extends Notifier<Map<String, FileProgress>> {
  @override
  Map<String, FileProgress> build() => const {};

  void set(String key, int sent, int total) {
    final old = state[key];
    // Repaint at most once per whole percent.
    if (old != null &&
        total > 0 &&
        (old.sent * 100 ~/ total) == (sent * 100 ~/ total) &&
        sent != total) {
      return;
    }
    state = {...state, key: FileProgress(sent, total)};
  }

  void clear(String entryId) => state = {
    for (final e in state.entries)
      if (!e.key.startsWith('$entryId#')) e.key: e.value,
  };
}

final uploadProgressProvider =
    NotifierProvider<UploadProgress, Map<String, FileProgress>>(
      UploadProgress.new,
    );

/// Learner submissions queued on the device (per-user local database).
class SubmissionQueue extends AsyncNotifier<List<QueuedSubmission>> {
  static const _key = 'pending_submissions';

  @override
  Future<List<QueuedSubmission>> build() async {
    final local = await ref.watch(localDatabaseProvider.future);
    final raw = await local.getKv(_key);
    if (raw == null) return const [];
    return [
      for (final e in jsonDecode(raw) as List)
        QueuedSubmission.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
  }

  Future<void> _save(List<QueuedSubmission> list) async {
    final local = await ref.read(localDatabaseProvider.future);
    await local.setKv(_key, jsonEncode([for (final s in list) s.toJson()]));
    state = AsyncData(List.of(list));
  }

  /// Queues work and tries to send it now. Returns true when the server
  /// accepted it; false when it stays queued (offline or failed).
  Future<bool> submit({
    String? assignmentId,
    String? portionId,
    String? lessonId,
    String? text,
    Map<String, dynamic>? target,
    required List<QueuedFile> files,
  }) async {
    assert(
      [assignmentId, portionId, lessonId].where((e) => e != null).length == 1,
    );
    final list = [...(await future)];
    final entry = QueuedSubmission(
      id: const Uuid().v4(),
      assignmentId: assignmentId,
      portionId: portionId,
      lessonId: lessonId,
      text: text,
      target: target,
      files: files,
    );
    list.add(entry);
    await _save(list);
    return _send(entry);
  }

  /// A reply on attempt [submissionId] (learner or teacher): files (voice
  /// notes, photos…), text and/or a library correction, sent in that order.
  Future<bool> reply({
    required String submissionId,
    required String workKind,
    required String workId,
    String? text,
    String? correctionId,
    Map<String, dynamic>? target,
    Map<String, dynamic>? saveAs,
    required List<QueuedFile> files,
  }) async {
    final list = [...(await future)];
    final hasText = text != null && text.trim().isNotEmpty;
    final entry = QueuedSubmission(
      id: const Uuid().v4(),
      portionId: workKind == 'portion' ? workId : null,
      lessonId: workKind == 'lesson' ? workId : null,
      assignmentId: workKind == 'assignment' ? workId : null,
      text: hasText ? text.trim() : null,
      target: target,
      replyTo: submissionId,
      correctionId: correctionId,
      saveAs: saveAs,
      messageIds: [
        for (var i = 0;
            i < files.length + (hasText ? 1 : 0) + (correctionId != null ? 1 : 0);
            i++)
          const Uuid().v4(),
      ],
      files: files,
    );
    list.add(entry);
    await _save(list);
    return _send(entry);
  }

  Future<bool> retry(String id) async {
    final entry = (await future).where((e) => e.id == id).firstOrNull;
    return entry == null ? false : _send(entry);
  }

  Future<void> discard(String id) async =>
      _save([...(await future)]..removeWhere((e) => e.id == id));

  /// Sends everything still queued (e.g. when the app is back online).
  Future<void> flush() async {
    for (final e in [...(await future)]) {
      await _send(e);
    }
  }

  /// Submissions being sent right now (a second flush skips them, so a file
  /// is never uploaded twice at the same time).
  final _sending = <String>{};

  Future<bool> _send(QueuedSubmission entry) async {
    if (!_sending.add(entry.id)) return false;
    try {
      return await _sendOnce(entry);
    } finally {
      _sending.remove(entry.id);
    }
  }

  Future<bool> _sendOnce(QueuedSubmission entry) async {
    final list = [...(await future)];
    final current = list.where((e) => e.id == entry.id).firstOrNull;
    if (current == null) return false; // already sent or discarded
    entry = current;
    entry.state = 'uploading';
    entry.error = null;
    await _save(list);
    final l10n = TransferNotifications.l10n;
    try {
      final profile = await ref.read(profileProvider.future);
      final admin = ref.read(adminRepositoryProvider);
      final pending = entry.files.where((f) => !f.uploaded).toList();
      // A file deleted from the phone can never be sent: say so plainly
      // instead of retrying forever.
      for (final f in pending) {
        if (!File(f.path).existsSync()) {
          throw StorageFailure(l10n.uploadFileMissing(f.name));
        }
      }
      final total = pending.fold<int>(
        0,
        (s, f) => s + (f.bytes ?? File(f.path).lengthSync()),
      );
      final progress = ref.read(uploadProgressProvider.notifier);
      // Finished files show as done straight away.
      for (final (i, f) in entry.files.indexed) {
        if (f.uploaded) progress.set('${entry.id}#$i', 1, 1);
      }
      var before = 0;
      for (final (i, f) in entry.files.indexed) {
        if (f.uploaded) continue;
        final size = f.bytes ?? File(f.path).lengthSync();
        f.mediaAssetId = await admin.uploadMedia(
          filePath: f.path,
          fileName: f.name,
          kind: f.kind,
          uploaderId: profile.id,
          folder: entry.isReply ? 'replies' : 'submissions',
          onProgress: (sent, fileTotal) {
            progress.set('${entry.id}#$i', sent, fileTotal > 0 ? fileTotal : size);
            TransferNotifications.progress(
              entry.id,
              l10n.uploadingWork,
              before + sent,
              total,
            );
          },
        );
        progress.set('${entry.id}#$i', size, size);
        before += size;
        await _save(list); // remember each finished upload
      }
      // Files are up; now record it in Sidra.
      entry.state = 'submitting';
      await _save(list);
      final api = ref.read(postgresApiProvider);
      final (workKind, workId) = entry.work;
      if (entry.isReply) {
        var m = 0;
        for (final f in entry.files) {
          await api.rpc(
            'work_reply',
            params: {
              'p_id': entry.messageIds[m++],
              'p_submission_id': entry.replyTo,
              'p_kind': f.kind == 'audio' ? 'voice' : 'file',
              'p_body': null,
              'p_media_asset_id': f.mediaAssetId,
              'p_target': entry.target,
              'p_save_as': f.kind == 'audio' && m == 1 ? entry.saveAs : null,
            },
          );
        }
        if (entry.text != null) {
          await api.rpc(
            'work_reply',
            params: {
              'p_id': entry.messageIds[m++],
              'p_submission_id': entry.replyTo,
              'p_kind': 'text',
              'p_body': entry.text,
              'p_target': entry.target,
            },
          );
        }
        if (entry.correctionId != null) {
          await api.rpc(
            'work_reply',
            params: {
              'p_id': entry.messageIds[m++],
              'p_submission_id': entry.replyTo,
              'p_kind': 'correction',
              'p_correction_id': entry.correctionId,
              'p_target': entry.target,
            },
          );
        }
      } else {
        await api.rpc(
          'send_work',
          params: {
            'p_submission_id': entry.id,
            'p_kind': workKind,
            'p_target_id': workId,
            'p_text': entry.text,
            'p_files': [
              for (final f in entry.files)
                {
                  'media_asset_id': f.mediaAssetId,
                  'file_name': f.name,
                  'mime_type': mimeTypeFor(f.name),
                  'bytes': f.bytes,
                },
            ],
            'p_target': entry.target,
          },
        );
      }
      progress.clear(entry.id);
      list.removeWhere((e) => e.id == entry.id);
      await _save(list);
      ref.invalidate(workThreadProvider((workKind, workId, null)));
      if (entry.files.isNotEmpty) {
        await TransferNotifications.finished(
          entry.id,
          l10n.uploadDoneTitle,
          l10n.uploadDoneBody,
        );
      }
      return true;
    } on AppFailure catch (e) {
      final offline = e is OfflineFailure || e is TimeoutFailure;
      entry.state = offline ? 'pending' : 'failed';
      entry.error = e.message;
      await _save(list);
      if (entry.files.isNotEmpty) {
        await TransferNotifications.finished(
          entry.id,
          offline ? l10n.uploadWaitingTitle : l10n.uploadFailedTitle,
          offline ? l10n.uploadWaitingBody : e.message,
        );
      }
      return false;
    } catch (e) {
      // Anything unexpected (unreadable file, full storage…): never leave the
      // work stuck at "uploading"; it stays saved and can be retried.
      entry.state = 'failed';
      entry.error = '$e';
      await _save(list);
      await TransferNotifications.finished(
        entry.id,
        l10n.uploadFailedTitle,
        l10n.uploadFailedBody,
      );
      return false;
    }
  }
}

final submissionQueueProvider =
    AsyncNotifierProvider<SubmissionQueue, List<QueuedSubmission>>(
      SubmissionQueue.new,
    );

/// Sends queued submissions when the app starts and whenever the phone
/// comes back online. Watched by the learner shell.
final submissionFlushProvider = Provider<void>((ref) {
  Future<void> flush() async {
    try {
      await ref.read(submissionQueueProvider.notifier).flush();
    } catch (_) {
      // stays queued; the learner sees "Waiting to upload"
    }
  }

  unawaited(flush());
  final sub = Connectivity().onConnectivityChanged.listen((results) {
    if (results.any((r) => r != ConnectivityResult.none)) unawaited(flush());
  });
  ref.onDispose(sub.cancel);
});
