import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/repository_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/download_service.dart';
import 'download_button.dart';

/// Downloads tab: courses saved for offline study, with sizes.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(downloadsListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloadsTitle)),
      body: switch (list) {
        AsyncData(:final value) when value.isEmpty => EmptyView(
          icon: Icons.download_for_offline_outlined,
          title: l10n.downloadsEmptyTitle,
          message: l10n.downloadsEmptyBody,
        ),
        AsyncData(:final value) => ListView(
          children: [for (final d in value) _DownloadTile(download: d)],
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(downloadsListProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  const _DownloadTile({required this.download});
  final CourseDownload download;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final course = ref.watch(cachedCourseProvider(download.courseId)).value;
    final live = ref.watch(courseDownloadProvider(download.courseId));
    final d = live.state == DownloadState.none ? download : live;
    return ListTile(
      leading: Icon(
        d.state == DownloadState.done
            ? Icons.offline_pin
            : Icons.download_for_offline_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(course?.title ?? '…'),
      subtitle: Text(switch (d.state) {
        DownloadState.done => l10n.sizeMb(formatMb(d.totalBytes)),
        DownloadState.downloading => l10n.downloadingProgress(d.percent),
        DownloadState.failed =>
          d.error == 'storage' ? l10n.storageFull : l10n.downloadFailed,
        DownloadState.none => '',
      }),
      trailing: IconButton(
        tooltip: l10n.removeDownload,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => ref
            .read(courseDownloadProvider(download.courseId).notifier)
            .remove(),
      ),
      onTap: () => context.push(Routes.courseDetail(download.courseId)),
    );
  }
}
