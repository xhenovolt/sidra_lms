import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/user_avatar.dart';

/// A profile photo, full screen: pinch to zoom, drag to move.
class PhotoViewScreen extends ConsumerWidget {
  const PhotoViewScreen({
    super.key,
    required this.avatarUrl,
    required this.name,
  });

  /// `media:<id>` (a photo) — built-in avatars and initials are shown large.
  final String? avatarUrl;
  final String? name;

  static Future<void> open(
    BuildContext context,
    String? avatarUrl,
    String? name,
  ) => Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) =>
          PhotoViewScreen(avatarUrl: avatarUrl, name: name),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = avatarUrl;
    final url = v != null && v.startsWith('media:')
        ? ref.watch(avatarUrlProvider(v.substring(6))).value
        : null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(name ?? ''),
      ),
      body: Center(
        child: url != null
            ? InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const CircularProgressIndicator(),
                ),
              )
            : UserAvatar(avatarUrl: v, name: name, radius: 120),
      ),
    );
  }
}

/// Crop (move and zoom inside the circle) and rotate a new photo before it
/// is uploaded. Returns the path of the edited JPEG, or null if cancelled.
class PhotoEditScreen extends StatefulWidget {
  const PhotoEditScreen({super.key, required this.path});
  final String path;

  static Future<String?> edit(BuildContext context, String path) =>
      Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => PhotoEditScreen(path: path)),
      );

  @override
  State<PhotoEditScreen> createState() => _PhotoEditScreenState();
}

class _PhotoEditScreenState extends State<PhotoEditScreen> {
  final _transform = TransformationController();
  img.Image? _image;
  Uint8List? _preview;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.path).readAsBytes();
      final decoded = await compute(_decode, bytes);
      if (decoded == null) throw const FormatException('not an image');
      _setImage(decoded);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  static img.Image? _decode(Uint8List bytes) {
    final d = img.decodeImage(bytes);
    if (d == null) return null;
    // Respect the camera's orientation, then keep it light to work with.
    final upright = img.bakeOrientation(d);
    return upright.width > 1600 || upright.height > 1600
        ? img.copyResize(
            upright,
            width: upright.width >= upright.height ? 1600 : null,
            height: upright.height > upright.width ? 1600 : null,
          )
        : upright;
  }

  void _setImage(img.Image i) {
    setState(() {
      _image = i;
      _preview = Uint8List.fromList(img.encodeJpg(i, quality: 90));
      _transform.value = Matrix4.identity();
      _busy = false;
    });
  }

  void _rotate() {
    final i = _image;
    if (i == null) return;
    setState(() => _busy = true);
    _setImage(img.copyRotate(i, angle: 90));
  }

  Future<void> _done(double frame) async {
    final i = _image;
    if (i == null) return;
    setState(() => _busy = true);
    // The image fills the square frame (cover); the viewer's zoom/pan says
    // which part of it is inside the frame.
    final m = _transform.value;
    final k = m.getMaxScaleOnAxis();
    final tx = m.getTranslation().x;
    final ty = m.getTranslation().y;
    final c = frame / (i.width < i.height ? i.width : i.height);
    final ox = (frame - i.width * c) / 2;
    final oy = (frame - i.height * c) / 2;
    final x0 = (-tx / k - ox) / c;
    final y0 = (-ty / k - oy) / c;
    final side = frame / k / c;
    final crop = img.copyCrop(
      i,
      x: x0.round().clamp(0, i.width - 1),
      y: y0.round().clamp(0, i.height - 1),
      width: side.round().clamp(1, i.width),
      height: side.round().clamp(1, i.height),
    );
    final out = crop.width > 800 ? img.copyResize(crop, width: 800) : crop;
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(img.encodeJpg(out, quality: 85));
    if (mounted) Navigator.of(context).pop(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.photoEditTitle),
      ),
      body: _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.white)),
            )
          : LayoutBuilder(
              builder: (context, box) {
                final frame =
                    (box.maxWidth < box.maxHeight - 140
                        ? box.maxWidth
                        : box.maxHeight - 140) -
                    Space.lg * 2;
                return Column(
                  children: [
                    const SizedBox(height: Space.lg),
                    Center(
                      child: SizedBox.square(
                        dimension: frame,
                        child: Stack(
                          children: [
                            if (_preview != null)
                              ClipRect(
                                child: InteractiveViewer(
                                  transformationController: _transform,
                                  minScale: 1,
                                  maxScale: 6,
                                  child: SizedBox.square(
                                    dimension: frame,
                                    child: Image.memory(
                                      _preview!,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                ),
                              ),
                            // The round frame: what people will see.
                            IgnorePointer(
                              child: CustomPaint(
                                size: Size.square(frame),
                                painter: _CircleMask(),
                              ),
                            ),
                            if (_busy)
                              const Center(child: CircularProgressIndicator()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      l10n.photoEditHint,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(Space.md),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                l10n.adminCancel,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: l10n.photoRotate,
                              color: Colors.white,
                              icon: const Icon(
                                Icons.rotate_90_degrees_cw_outlined,
                              ),
                              onPressed: _busy ? null : _rotate,
                            ),
                            IconButton(
                              tooltip: l10n.photoReset,
                              color: Colors.white,
                              icon: const Icon(Icons.fit_screen_outlined),
                              onPressed: _busy
                                  ? null
                                  : () => _transform.value = Matrix4.identity(),
                            ),
                            const SizedBox(width: Space.sm),
                            FilledButton(
                              onPressed: _busy ? null : () => _done(frame),
                              child: Text(l10n.photoUse),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _CircleMask extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final outside = Path()
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      outside,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      Offset(r, r),
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white70,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
