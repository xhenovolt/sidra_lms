import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/data/repository_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../media/presentation/media_widgets.dart';
import '../data/download_service.dart';

final downloadServiceProvider = FutureProvider<DownloadService>((ref) async {
  return DownloadService(
    local: await ref.watch(localDatabaseProvider.future),
    api: ref.watch(postgresApiProvider),
    courses: await ref.watch(courseRepositoryProvider.future),
    lessons: await ref.watch(lessonRepositoryProvider.future),
    media: await ref.watch(mediaRepositoryProvider.future),
    assessments: await ref.watch(assessmentRepositoryProvider.future),
  );
});

/// Live download state per course (survives leaving the screen).
final courseDownloadProvider =
    NotifierProvider.family<CourseDownloadNotifier, CourseDownload, String>(
      CourseDownloadNotifier.new,
    );

class CourseDownloadNotifier extends Notifier<CourseDownload> {
  CourseDownloadNotifier(this.courseId);
  final String courseId;
  CancelToken? _cancel;

  @override
  CourseDownload build() {
    ref.onDispose(() => _cancel?.cancel());
    unawaited(_loadStored());
    return CourseDownload(courseId: courseId, state: DownloadState.none);
  }

  Future<void> _loadStored() async {
    final local = await ref.read(localDatabaseProvider.future);
    final stored = await DownloadService.statusIn(local, courseId);
    // An interrupted run (app killed) is resumable, not "downloading".
    state = stored.state == DownloadState.downloading
        ? CourseDownload(
            courseId: courseId,
            state: DownloadState.failed,
            totalBytes: stored.totalBytes,
            doneBytes: stored.doneBytes,
            error: 'interrupted',
          )
        : stored;
  }

  Future<void> start() async {
    if (state.state == DownloadState.downloading) return;
    final svc = await ref.read(downloadServiceProvider.future);
    _cancel = CancelToken();
    await for (final d in svc.download(courseId, cancelToken: _cancel)) {
      state = d;
    }
    ref.invalidate(downloadsListProvider);
  }

  void cancel() => _cancel?.cancel();

  Future<void> remove() async {
    final svc = await ref.read(downloadServiceProvider.future);
    await svc.remove(courseId);
    state = CourseDownload(courseId: courseId, state: DownloadState.none);
    ref.invalidate(downloadsListProvider);
  }
}

final downloadsListProvider = FutureProvider<List<CourseDownload>>((ref) async {
  final local = await ref.watch(localDatabaseProvider.future);
  return DownloadService.allIn(local);
});

String formatMb(int bytes) =>
    (bytes / (1024 * 1024)).toStringAsFixed(bytes < 10 * 1024 * 1024 ? 1 : 0);

class DownloadCourseButton extends ConsumerWidget {
  const DownloadCourseButton({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final d = ref.watch(courseDownloadProvider(courseId));
    final notifier = ref.read(courseDownloadProvider(courseId).notifier);
    return switch (d.state) {
      DownloadState.downloading => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: d.totalBytes == 0 ? null : d.percent / 100,
          ),
          TextButton.icon(
            onPressed: notifier.cancel,
            icon: const Icon(Icons.close),
            label: Text(l10n.downloadingProgress(d.percent)),
          ),
        ],
      ),
      DownloadState.done => OutlinedButton.icon(
        onPressed: notifier.start, // refresh newly unlocked lessons
        icon: const Icon(Icons.offline_pin),
        label: Text(
          d.totalBytes > 0
              ? '${l10n.downloadedLabel} · ${l10n.sizeMb(formatMb(d.totalBytes))}'
              : l10n.downloadedLabel,
        ),
      ),
      DownloadState.failed => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            d.error == 'storage' ? l10n.storageFull : l10n.downloadFailed,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          OutlinedButton.icon(
            onPressed: notifier.start,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.tryAgain),
          ),
        ],
      ),
      DownloadState.none => OutlinedButton.icon(
        onPressed: notifier.start,
        icon: const Icon(Icons.download_for_offline_outlined),
        label: Text(l10n.downloadCourse),
      ),
    };
  }
}
