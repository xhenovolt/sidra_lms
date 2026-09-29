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
import '../../teaching/data/lesson_work.dart';
import '../../teaching/data/teaching_repository.dart';
import 'content_repository.dart';

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

/// Work waiting to reach the server. States shown to the learner:
/// pending (queued), uploading, failed (with retry). It is only "handed in"
/// once the server has accepted it.
class QueuedSubmission {
  QueuedSubmission({
    required this.id,
    this.assignmentId,
    this.portionId,
    this.lessonId,
    required this.files,
    this.text,
    this.state = 'pending',
    this.error,
  });

  factory QueuedSubmission.fromJson(Map<String, dynamic> j) => QueuedSubmission(
    id: j['id'] as String,
    assignmentId: j['assignment_id'] as String?,
    portionId: j['portion_id'] as String?,
    lessonId: j['lesson_id'] as String?,
    text: j['text'] as String?,
    files: [
      for (final f in (j['files'] as List? ?? const []))
        QueuedFile.fromJson(Map<String, dynamic>.from(f as Map)),
    ],
    state: j['state'] as String? ?? 'pending',
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
  String state;
  String? error;

  Map<String, Object?> toJson() => {
    'id': id,
    'assignment_id': assignmentId,
    'portion_id': portionId,
    'lesson_id': lessonId,
    'text': text,
    'files': [for (final f in files) f.toJson()],
    'state': state,
    'error': error,
  };
}

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
      var before = 0;
      for (final f in pending) {
        f.mediaAssetId = await admin.uploadMedia(
          filePath: f.path,
          fileName: f.name,
          kind: f.kind,
          uploaderId: profile.id,
          folder: 'submissions',
          onProgress: (sent, _) => TransferNotifications.progress(
            entry.id,
            l10n.uploadingWork,
            before + sent,
            total,
          ),
        );
        before += f.bytes ?? File(f.path).lengthSync();
        await _save(list); // remember each finished upload
      }
      final files = [
        for (final f in entry.files)
          {
            'media_asset_id': f.mediaAssetId,
            'file_name': f.name,
            'mime_type': mimeTypeFor(f.name),
            'bytes': f.bytes,
          },
      ];
      if (entry.lessonId != null) {
        await ref
            .read(lessonWorkRepositoryProvider)
            .submit(
              submissionId: entry.id,
              lessonId: entry.lessonId!,
              text: entry.text,
              files: files,
            );
      } else if (entry.portionId != null) {
        await ref
            .read(teachingRepositoryProvider)
            .submit(
              submissionId: entry.id,
              portionId: entry.portionId!,
              text: entry.text,
              files: files,
            );
      } else {
        await ref
            .read(contentRepositoryProvider)
            .submitWork(
              submissionId: entry.id,
              assignmentId: entry.assignmentId!,
              text: entry.text,
              files: [
                for (final f in entry.files)
                  {
                    'media_asset_id': f.mediaAssetId,
                    'file_name': f.name,
                    'mime_type': mimeTypeFor(f.name),
                    'bytes': f.bytes,
                  },
              ],
            );
      }
      list.removeWhere((e) => e.id == entry.id);
      await _save(list);
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
