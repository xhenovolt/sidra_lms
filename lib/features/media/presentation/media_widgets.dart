import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/media_repository.dart';

final mediaRepositoryProvider = FutureProvider<MediaRepository>((ref) async {
  final local = await ref.watch(localDatabaseProvider.future);
  final userId = ref.watch(authSessionProvider.select((s) => s.user?.id));
  final base = await getApplicationSupportDirectory();
  final name = sha1.convert(utf8.encode(userId ?? 'none')).toString();
  return MediaRepository(
    local,
    ref.watch(postgresApiProvider),
    mediaDir: Directory(p.join(base.path, 'media', name.substring(0, 16))),
  );
});

typedef MediaKey = ({String assetId, String? transformation});

final mediaSourceProvider = FutureProvider.family<MediaSource, MediaKey>((
  ref,
  key,
) async {
  final repo = await ref.watch(mediaRepositoryProvider.future);
  return repo.resolve(key.assetId, transformation: key.transformation);
});

/// Placeholder shown while media loads or when it is unavailable.
class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.icon, this.height = 180, this.label});
  final IconData icon;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          if (label != null) ...[
            const SizedBox(height: Space.xs),
            Text(
              label!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Image from a media asset (local file when downloaded).
class SidraImage extends ConsumerWidget {
  const SidraImage({
    super.key,
    required this.assetId,
    this.transformation,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = Radii.md,
  });

  final String assetId;
  final String? transformation;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(
      mediaSourceProvider((assetId: assetId, transformation: transformation)),
    );
    final placeholder = _MediaPlaceholder(
      icon: Icons.image_outlined,
      height: height ?? 180,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: switch (source) {
        AsyncData(value: LocalMedia(:final file)) => Image.file(
          file,
          height: height,
          width: double.infinity,
          fit: fit,
        ),
        AsyncData(value: RemoteMedia(:final url)) => CachedNetworkImage(
          imageUrl: url,
          height: height,
          width: double.infinity,
          fit: fit,
          placeholder: (_, _) => placeholder,
          errorWidget: (_, _, _) => _MediaPlaceholder(
            icon: Icons.broken_image_outlined,
            height: height ?? 180,
          ),
        ),
        AsyncError() => _MediaPlaceholder(
          icon: Icons.image_not_supported_outlined,
          height: height ?? 180,
        ),
        _ => placeholder,
      },
    );
  }
}

/// Compact audio player (recitations, explanations, voice notes).
class SidraAudioPlayer extends ConsumerStatefulWidget {
  const SidraAudioPlayer({
    super.key,
    this.assetId,
    this.url,
    this.title,
    this.autoPlay = false,
  }) : assert(assetId != null || url != null);

  /// A file stored by Sidra (signed and access-checked), or…
  final String? assetId;

  /// …a direct link to an audio file.
  final String? url;
  final String? title;

  /// Start playing as soon as it is loaded (opened from a list).
  final bool autoPlay;

  @override
  ConsumerState<SidraAudioPlayer> createState() => _SidraAudioPlayerState();
}

class _SidraAudioPlayerState extends ConsumerState<SidraAudioPlayer> {
  final _player = AudioPlayer();
  String? _loadedFor;
  Object? _error;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load(MediaSource source) async {
    final key = switch (source) {
      LocalMedia(:final file) => file.path,
      RemoteMedia(:final url) => url,
    };
    if (_loadedFor == key) return;
    _loadedFor = key;
    try {
      switch (source) {
        case LocalMedia(:final file):
          await _player.setFilePath(file.path);
        case RemoteMedia(:final url):
          await _player.setUrl(url);
      }
      if (widget.autoPlay) unawaited(_player.play());
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final source = _sourceFor(ref, widget.assetId, widget.url);
    final scheme = Theme.of(context).colorScheme;
    if (source case AsyncData(:final value)) unawaited(_load(value));
    if (source is AsyncError || _error != null) {
      return const _MediaPlaceholder(
        icon: Icons.volume_off_outlined,
        height: 72,
        label: 'Audio unavailable',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (context, snap) {
          final state = snap.data;
          final loading =
              source is AsyncLoading ||
              state?.processingState == ProcessingState.loading ||
              state?.processingState == ProcessingState.buffering;
          final playing = state?.playing ?? false;
          return Row(
            children: [
              IconButton.filled(
                tooltip: playing ? 'Pause' : 'Play',
                onPressed: loading
                    ? null
                    : () {
                        if (playing) {
                          _player.pause();
                        } else {
                          if (state?.processingState ==
                              ProcessingState.completed) {
                            _player.seek(Duration.zero);
                          }
                          _player.play();
                        }
                      },
                icon: loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(playing ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: Space.xs),
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, pos) {
                    final total = _player.duration ?? Duration.zero;
                    final at = pos.data ?? Duration.zero;
                    final max = total.inMilliseconds.toDouble();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.title != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: Space.sm,
                            ),
                            child: Text(
                              widget.title!,
                              style: Theme.of(context).textTheme.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Slider(
                          value: max == 0
                              ? 0
                              : at.inMilliseconds.clamp(0, max).toDouble(),
                          max: max == 0 ? 1 : max,
                          onChanged: max == 0
                              ? null
                              : (v) => _player.seek(
                                  Duration(milliseconds: v.round()),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, pos) => Text(
                  '${_fmt(pos.data ?? Duration.zero)} / '
                  '${_fmt(_player.duration ?? Duration.zero)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Inline video player with tap-to-play.
class SidraVideoPlayer extends ConsumerStatefulWidget {
  const SidraVideoPlayer({
    super.key,
    this.assetId,
    this.url,
    this.autoPlay = false,
  }) : assert(assetId != null || url != null);
  final String? assetId;
  final String? url;
  final bool autoPlay;

  @override
  ConsumerState<SidraVideoPlayer> createState() => _SidraVideoPlayerState();
}

class _SidraVideoPlayerState extends ConsumerState<SidraVideoPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _init(MediaSource source) async {
    if (_controller != null) return;
    final c = switch (source) {
      LocalMedia(:final file) => VideoPlayerController.file(file),
      RemoteMedia(:final url) => VideoPlayerController.networkUrl(
        Uri.parse(url),
      ),
    };
    _controller = c;
    try {
      await c.initialize();
      if (widget.autoPlay) unawaited(c.play());
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = _sourceFor(ref, widget.assetId, widget.url);
    if (source case AsyncData(:final value)) unawaited(_init(value));
    if (source is AsyncError || _failed) {
      return const _MediaPlaceholder(
        icon: Icons.videocam_off_outlined,
        label: 'Video unavailable',
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const _MediaPlaceholder(icon: Icons.movie_outlined);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.md),
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(c),
            ValueListenableBuilder(
              valueListenable: c,
              builder: (context, v, _) => v.isPlaying
                  ? GestureDetector(
                      onTap: c.pause,
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    )
                  : IconButton.filled(
                      iconSize: 36,
                      onPressed: c.play,
                      icon: const Icon(Icons.play_arrow),
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(c, allowScrubbing: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where a player reads from: Sidra's stored file (preferring the offline
/// copy), or a direct link.
AsyncValue<MediaSource> _sourceFor(
  WidgetRef ref,
  String? assetId,
  String? url,
) => assetId != null
    ? ref.watch(mediaSourceProvider((assetId: assetId, transformation: null)))
    : AsyncData(RemoteMedia(url!));
