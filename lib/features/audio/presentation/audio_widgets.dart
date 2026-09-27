import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../content/data/content_repository.dart';

String formatDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
}

/// Plays a voice note: an uploaded file (by media id, via a signed URL the
/// database issues only to people allowed to hear it) or a local recording.
class VoicePlayer extends ConsumerStatefulWidget {
  const VoicePlayer({
    super.key,
    this.mediaAssetId,
    this.filePath,
    this.title,
    this.subtitle,
    this.icon = Icons.record_voice_over_outlined,
    this.compact = false,
  }) : assert(mediaAssetId != null || filePath != null);

  final String? mediaAssetId;
  final String? filePath;
  final String? title;
  final String? subtitle;
  final IconData icon;

  /// A single row (for review lists).
  final bool compact;

  @override
  ConsumerState<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends ConsumerState<VoicePlayer> {
  final _player = AudioPlayer();
  bool _loaded = false;
  bool _loading = false;
  String? _error;
  double _speed = 1;

  @override
  void didUpdateWidget(VoicePlayer old) {
    super.didUpdateWidget(old);
    if (old.mediaAssetId != widget.mediaAssetId ||
        old.filePath != widget.filePath) {
      _loaded = false;
      unawaited(_player.stop());
    }
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_player.playing) {
      await _player.pause();
      return;
    }
    if (!_loaded) {
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        if (widget.filePath != null) {
          await _player.setFilePath(widget.filePath!);
        } else {
          final url = await ref
              .read(contentRepositoryProvider)
              .mediaUrl(widget.mediaAssetId!);
          await _player.setUrl(url);
        }
        _loaded = true;
      } on AppFailure catch (e) {
        if (mounted) setState(() => _error = e.message);
      } catch (_) {
        if (mounted) {
          setState(() => _error = AppLocalizations.of(context).audioCannotPlay);
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      if (!_loaded) return;
    }
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    unawaited(_player.play());
  }

  void _cycleSpeed() {
    const speeds = [1.0, 0.75, 1.25];
    final next = speeds[(speeds.indexOf(_speed) + 1) % speeds.length];
    setState(() => _speed = next);
    unawaited(_player.setSpeed(next));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snap) {
        final playing = snap.data?.playing ?? false;
        final done = snap.data?.processingState == ProcessingState.completed;
        final button = SizedBox.square(
          dimension: 44,
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : IconButton.filledTonal(
                  tooltip: playing ? l10n.audioPause : l10n.audioPlay,
                  onPressed: _toggle,
                  icon: Icon(playing && !done ? Icons.pause : Icons.play_arrow),
                ),
        );
        final progress = StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, pos) {
            final total = _player.duration ?? Duration.zero;
            final at = pos.data ?? Duration.zero;
            final max = total.inMilliseconds.toDouble();
            return Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: max <= 0
                          ? 0
                          : at.inMilliseconds.clamp(0, max.toInt()).toDouble(),
                      max: max <= 0 ? 1 : max,
                      onChanged: max <= 0
                          ? null
                          : (v) =>
                                _player.seek(Duration(milliseconds: v.round())),
                    ),
                  ),
                ),
                const SizedBox(width: Space.xs),
                Text(
                  _loaded
                      ? '${formatDuration(at)} / ${formatDuration(total)}'
                      : '--:--',
                  style: theme.textTheme.labelSmall,
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(40, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  onPressed: _cycleSpeed,
                  child: Text('${_speed}x'),
                ),
              ],
            );
          },
        );
        if (widget.compact) {
          return Row(
            children: [
              button,
              const SizedBox(width: Space.xs),
              Expanded(child: progress),
            ],
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.sm,
              Space.xs,
              Space.xs,
              Space.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null)
                  Row(
                    children: [
                      Icon(
                        widget.icon,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text(
                          widget.title!,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                if (widget.subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      widget.subtitle!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                Row(
                  children: [
                    button,
                    const SizedBox(width: Space.xs),
                    Expanded(child: progress),
                  ],
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A finished recording on this device.
class RecordedAudio {
  const RecordedAudio(this.path, this.duration);
  final String path;
  final Duration duration;
  String get fileName => path.split(Platform.pathSeparator).last;
}

/// Record a voice note: record, pause/resume, stop, listen, redo.
/// Saved in the app's own storage so it survives being offline; nothing is
/// sent until the caller submits it.
class VoiceRecorder extends StatefulWidget {
  const VoiceRecorder({
    super.key,
    required this.onChanged,
    this.hint,
    this.maxDuration = const Duration(minutes: 15),
  });

  final ValueChanged<RecordedAudio?> onChanged;
  final String? hint;
  final Duration maxDuration;

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

enum _RecState { idle, recording, paused, done }

class _VoiceRecorderState extends State<VoiceRecorder>
    with WidgetsBindingObserver {
  final _rec = AudioRecorder();
  _RecState _state = _RecState.idle;
  RecordedAudio? _result;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  StreamSubscription<Amplitude>? _ampSub;
  final _levels = <double>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _ampSub?.cancel();
    unawaited(_rec.dispose());
    super.dispose();
  }

  /// A call or leaving the app pauses the recording instead of losing it.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _state == _RecState.recording) {
      unawaited(_pause());
    }
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    try {
      if (!await _rec.hasPermission()) {
        setState(() => _error = l10n.audioNeedsMicrophone);
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(
        '${dir.path}${Platform.pathSeparator}recordings',
      );
      await folder.create(recursive: true);
      final path =
          '${folder.path}${Platform.pathSeparator}${const Uuid().v4()}.m4a';
      await _rec.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 22050,
          numChannels: 1,
        ),
        path: path,
      );
      _levels.clear();
      _elapsed = Duration.zero;
      _ampSub = _rec
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((a) {
            final v = ((a.current + 60) / 60).clamp(0.05, 1.0);
            setState(() {
              _levels.add(v);
              if (_levels.length > 48) _levels.removeAt(0);
            });
          });
      _startTicker();
      setState(() => _state = _RecState.recording);
    } catch (e) {
      setState(() => _error = l10n.audioRecordFailed);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= widget.maxDuration) unawaited(_stop());
    });
  }

  Future<void> _pause() async {
    await _rec.pause();
    _ticker?.cancel();
    if (mounted) setState(() => _state = _RecState.paused);
  }

  Future<void> _resume() async {
    await _rec.resume();
    _startTicker();
    setState(() => _state = _RecState.recording);
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    await _ampSub?.cancel();
    final path = await _rec.stop();
    if (!mounted) return;
    if (path == null || !File(path).existsSync()) {
      setState(() {
        _state = _RecState.idle;
        _error = AppLocalizations.of(context).audioRecordFailed;
      });
      return;
    }
    _result = RecordedAudio(path, _elapsed);
    setState(() => _state = _RecState.done);
    widget.onChanged(_result);
  }

  Future<void> _discard() async {
    final path = _result?.path;
    if (_state == _RecState.recording || _state == _RecState.paused) {
      await _rec.cancel();
    }
    _ticker?.cancel();
    await _ampSub?.cancel();
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    _result = null;
    setState(() {
      _state = _RecState.idle;
      _elapsed = Duration.zero;
      _levels.clear();
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.hint != null && _state == _RecState.idle)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text(widget.hint!, style: theme.textTheme.bodyMedium),
              ),
            if (_state == _RecState.recording ||
                _state == _RecState.paused) ...[
              SizedBox(
                height: 40,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (final l in _levels)
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 3,
                            height: 40 * l,
                            decoration: BoxDecoration(
                              color: _state == _RecState.recording
                                  ? scheme.error
                                  : scheme.outline,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                '${_state == _RecState.paused ? l10n.audioPaused : l10n.audioRecording} · ${formatDuration(_elapsed)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: Space.sm),
            ],
            if (_state == _RecState.done && _result != null) ...[
              VoicePlayer(
                filePath: _result!.path,
                title: l10n.audioYourRecording(
                  formatDuration(_result!.duration),
                ),
                icon: Icons.mic,
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: switch (_state) {
                _RecState.idle => [
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.mic),
                    label: Text(l10n.audioRecord),
                  ),
                ],
                _RecState.recording => [
                  OutlinedButton.icon(
                    onPressed: _pause,
                    icon: const Icon(Icons.pause),
                    label: Text(l10n.audioPauseRecording),
                  ),
                  FilledButton.icon(
                    onPressed: _stop,
                    icon: const Icon(Icons.stop),
                    label: Text(l10n.audioStop),
                  ),
                ],
                _RecState.paused => [
                  OutlinedButton.icon(
                    onPressed: _resume,
                    icon: const Icon(Icons.mic),
                    label: Text(l10n.audioResume),
                  ),
                  FilledButton.icon(
                    onPressed: _stop,
                    icon: const Icon(Icons.stop),
                    label: Text(l10n.audioStop),
                  ),
                  TextButton(
                    onPressed: _discard,
                    child: Text(l10n.audioDiscard),
                  ),
                ],
                _RecState.done => [
                  TextButton.icon(
                    onPressed: _discard,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.audioRecordAgain),
                  ),
                ],
              },
            ),
          ],
        ),
      ),
    );
  }
}
