import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../lessons/domain/external_link.dart';
import 'media_widgets.dart';

/// How a file is shown inside Sidra.
enum ViewerKind { image, audio, video, pdf, text, office, link }

ViewerKind viewerKindFor({String? kind, String? mimeType, String? fileName}) {
  final ext = (fileName ?? '').contains('.')
      ? fileName!.split('.').last.toLowerCase()
      : '';
  final mime = (mimeType ?? '').toLowerCase();
  if (kind == 'link') return ViewerKind.link;
  const images = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'};
  const audio = {'mp3', 'wav', 'm4a', 'aac', 'ogg', 'opus'};
  const video = {'mp4', 'mov', 'webm', '3gp', 'mkv'};
  if (kind == 'image' || mime.startsWith('image/') || images.contains(ext)) {
    return ViewerKind.image;
  }
  if (kind == 'audio' || mime.startsWith('audio/') || audio.contains(ext)) {
    return ViewerKind.audio;
  }
  if (kind == 'video' || mime.startsWith('video/') || video.contains(ext)) {
    return ViewerKind.video;
  }
  if (ext == 'pdf' || mime == 'application/pdf') return ViewerKind.pdf;
  if (ext == 'txt' || mime.startsWith('text/')) return ViewerKind.text;
  return ViewerKind.office;
}

/// Opens a file the way messaging apps do, never as a browser page:
/// * audio plays at once in a small player that slides up from the bottom
///   (swipe down to close; the page stays visible);
/// * pictures, video, PDF and text open full screen with a back arrow;
/// * office documents are downloaded and handed to the phone's document app;
/// * a link straight to such a file is treated the same way; only real web
///   pages open in the in-app browser (YouTube / Telegram in their own apps).
Future<void> openInApp(
  BuildContext context, {
  String? assetId,
  String? url,
  String? kind,
  String? mimeType,
  String? fileName,
  String? localPath,
  required String title,
}) async {
  var type = viewerKindFor(kind: kind, mimeType: mimeType, fileName: fileName);
  // A link straight to a media file (….mp3, ….pdf…) opens like the file.
  String? fileUrl;
  if (assetId == null && localPath == null && url != null) {
    final uri = Uri.tryParse(url);
    final direct = uri == null
        ? ViewerKind.link
        : viewerKindFor(fileName: uri.path.split('/').last);
    if (uri != null &&
        uri.path.contains('.') &&
        direct != ViewerKind.office &&
        linkProviderOf(uri) == LinkProvider.web) {
      type = direct;
      fileUrl = url;
    }
  }
  if (type == ViewerKind.audio) {
    await showAudioSheet(
      context,
      assetId: assetId,
      url: fileUrl,
      localPath: localPath,
      title: title,
    );
    return;
  }
  if (fileUrl == null &&
      (type == ViewerKind.link || (assetId == null && localPath == null))) {
    final uri = parseExternalLink(url ?? '');
    if (uri == null) return;
    final app = linkProviderOf(uri) != LinkProvider.web;
    await launchUrl(
      uri,
      mode: app ? LaunchMode.externalApplication : LaunchMode.inAppBrowserView,
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MediaViewerScreen(
        assetId: assetId,
        url: fileUrl,
        localPath: localPath,
        type: type,
        title: title,
        fileName: fileName,
        mimeType: mimeType,
      ),
    ),
  );
}

/// Plays audio in a bottom sheet over the current page: it starts at once,
/// and closes with a swipe down or a tap outside — no new page to leave.
Future<void> showAudioSheet(
  BuildContext context, {
  String? assetId,
  String? url,
  String? localPath,
  required String title,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  builder: (sheet) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
    child: SidraAudioPlayer(
      assetId: assetId,
      url: url ?? (localPath == null ? null : Uri.file(localPath).toString()),
      title: title,
      autoPlay: true,
    ),
  ),
);

final _signedUrlProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, assetId) async =>
      (await ref
              .watch(postgresApiProvider)
              .rpc('media_url', params: {'p_asset_id': assetId}))
          as String,
);

class MediaViewerScreen extends ConsumerWidget {
  const MediaViewerScreen({
    super.key,
    this.assetId,
    this.url,
    this.localPath,
    required this.type,
    required this.title,
    this.fileName,
    this.mimeType,
  });

  final String? assetId;

  /// A direct link to the file (when it is not stored by Sidra).
  final String? url;

  /// A copy saved on the phone (offline downloads) is used first.
  final String? localPath;
  final ViewerKind type;
  final String title;
  final String? fileName;
  final String? mimeType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = localPath;
    final Widget body;
    if (local != null && type != ViewerKind.audio && type != ViewerKind.video) {
      body = switch (type) {
        ViewerKind.image => InteractiveViewer(
          maxScale: 6,
          child: Center(child: Image.file(File(local))),
        ),
        ViewerKind.pdf => PdfViewer.file(local),
        ViewerKind.text => SingleChildScrollView(
          padding: const EdgeInsets.all(Space.md),
          child: SelectableText(File(local).readAsStringSync()),
        ),
        _ => _OfficeFile(
          url: null,
          localPath: local,
          fileName: fileName ?? title,
          mimeType: mimeType,
        ),
      };
      return _frame(context, body);
    }
    final AsyncValue<String> url = assetId == null
        ? AsyncData(this.url!)
        : ref.watch(_signedUrlProvider(assetId!));
    body = switch (type) {
      // These players fetch their own signed URL.
      ViewerKind.audio => Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: SidraAudioPlayer(
            assetId: assetId,
            url: this.url,
            title: title,
          ),
        ),
      ),
      ViewerKind.video => Center(
        child: SidraVideoPlayer(
          assetId: assetId,
          url: this.url,
          autoPlay: true,
        ),
      ),
      _ => switch (url) {
        AsyncData(:final value) => switch (type) {
          ViewerKind.image => InteractiveViewer(
            maxScale: 6,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: value,
                placeholder: (_, _) => const CircularProgressIndicator(),
              ),
            ),
          ),
          ViewerKind.pdf => PdfViewer.uri(Uri.parse(value)),
          ViewerKind.text => _TextFile(url: value),
          _ => _OfficeFile(
            url: value,
            fileName: fileName ?? title,
            mimeType: mimeType,
          ),
        },
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(_signedUrlProvider(assetId!)),
        ),
        _ => const LoadingView(),
      },
    };
    return _frame(context, body);
  }

  Widget _frame(BuildContext context, Widget body) {
    final dark = type == ViewerKind.image || type == ViewerKind.video;
    return Scaffold(
      backgroundColor: dark ? Colors.black : null,
      appBar: AppBar(
        backgroundColor: dark ? Colors.black : null,
        foregroundColor: dark ? Colors.white : null,
        title: Text(title, overflow: TextOverflow.ellipsis),
      ),
      body: body,
    );
  }
}

class _TextFile extends StatelessWidget {
  const _TextFile({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => FutureBuilder<Response<String>>(
    future: Dio().get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    ),
    builder: (context, snap) {
      if (snap.hasError) return ErrorView(error: snap.error!);
      if (!snap.hasData) return const LoadingView();
      return SingleChildScrollView(
        padding: const EdgeInsets.all(Space.md),
        child: SelectableText(snap.data!.data ?? ''),
      );
    },
  );
}

/// Word / PowerPoint / Excel: download inside Sidra, then open with the
/// phone's document app (as messaging apps do).
class _OfficeFile extends StatefulWidget {
  const _OfficeFile({
    required this.url,
    required this.fileName,
    this.mimeType,
    this.localPath,
  });
  final String? url;
  final String? localPath;
  final String fileName;
  final String? mimeType;

  @override
  State<_OfficeFile> createState() => _OfficeFileState();
}

class _OfficeFileState extends State<_OfficeFile> {
  double? _progress;
  String? _path;
  String? _error;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    setState(() {
      _error = null;
      _progress = 0;
    });
    try {
      final saved = widget.localPath;
      if (saved != null) {
        setState(() => _path = saved);
        await _open();
        return;
      }
      final dir = await getTemporaryDirectory();
      final safe = widget.fileName.replaceAll(RegExp(r'[^\w.\- ]'), '_');
      final path = '${dir.path}${Platform.pathSeparator}$safe';
      if (!File(path).existsSync()) {
        await Dio().download(
          widget.url!,
          path,
          onReceiveProgress: (r, t) {
            if (mounted && t > 0) setState(() => _progress = r / t);
          },
        );
      }
      if (!mounted) return;
      setState(() => _path = path);
      await _open();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _open() async {
    final r = await OpenFilex.open(_path!, type: widget.mimeType);
    if (!mounted) return;
    if (r.type == ResultType.noAppToOpen) {
      setState(() => _error = AppLocalizations.of(context).viewerNoApp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: Space.sm),
            Text(
              widget.fileName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: Space.md),
            if (_error != null) ...[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: Space.sm),
              FilledButton(onPressed: _download, child: Text(l10n.retry)),
            ] else if (_path == null) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: Space.xs),
              Text(l10n.viewerDownloading),
            ] else
              FilledButton.icon(
                onPressed: _open,
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.viewerOpenAgain),
              ),
          ],
        ),
      ),
    );
  }
}
