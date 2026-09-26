// Builds Sidra's brand images from the source logo.
//
//   dart run tool/gen_icons.dart
//   dart run flutter_launcher_icons
//
// Source: assets/images/sidra.jpg (green mark on an off-white background).
// Outputs (assets/branding/):
//   icon.png        1024² launcher icon: the mark centred on the background
//   foreground.png  1024² Android adaptive-icon foreground: the mark alone on
//                   transparency, sized to the 66% safe zone
//   mark.png        512² the mark alone on transparency, for use in the app
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const _source = 'assets/images/sidra.jpg';
const _out = 'assets/branding';

void main() {
  final src = img.decodeImage(File(_source).readAsBytesSync());
  if (src == null) {
    stderr.writeln('Cannot read $_source');
    exit(1);
  }

  final background = _backgroundColour(src);
  final box = _markBounds(src, background);
  stdout.writeln(
    'background ${_hex(background)}; mark at '
    '${box.x},${box.y} ${box.w}×${box.h}',
  );
  final mark = _cutOut(src, box, background);

  Directory(_out).createSync(recursive: true);
  // Launcher icon: mark fills ~62% of the square (reads well at 48 dp).
  _save('icon.png', _place(mark, 1024, 0.62, background));
  // Adaptive foreground: launchers crop to a circle/squircle within the
  // centre 66%, so keep the mark inside ~50%.
  _save('foreground.png', _place(mark, 1024, 0.50, null));
  _save('mark.png', _place(mark, 512, 0.92, null));
  // Android launch screen: the mark at 96 dp for each density.
  for (final (dir, px) in const [
    ('mdpi', 96),
    ('hdpi', 144),
    ('xhdpi', 192),
    ('xxhdpi', 288),
    ('xxxhdpi', 384),
  ]) {
    final path = 'android/app/src/main/res/drawable-$dir/splash_mark.png';
    File(path).parent.createSync(recursive: true);
    File(path).writeAsBytesSync(img.encodePng(_place(mark, px, 1, null)));
  }
  stdout.writeln('background colour for adaptive icons: ${_hex(background)}');
}

/// Median colour of the image border.
img.Color _backgroundColour(img.Image im) {
  final rs = <num>[], gs = <num>[], bs = <num>[];
  void add(int x, int y) {
    final p = im.getPixel(x, y);
    rs.add(p.r);
    gs.add(p.g);
    bs.add(p.b);
  }

  for (var x = 0; x < im.width; x += 4) {
    add(x, 0);
    add(x, im.height - 1);
  }
  for (var y = 0; y < im.height; y += 4) {
    add(0, y);
    add(im.width - 1, y);
  }
  num median(List<num> v) => (v..sort())[v.length ~/ 2];
  return img.ColorRgb8(
    median(rs).toInt(),
    median(gs).toInt(),
    median(bs).toInt(),
  );
}

/// How far a pixel is from the background (0 = background, 1 = far).
double _ink(img.Pixel p, img.Color bg) {
  final d = sqrt(pow(p.r - bg.r, 2) + pow(p.g - bg.g, 2) + pow(p.b - bg.b, 2));
  return (d / 160).clamp(0.0, 1.0);
}

({int x, int y, int w, int h}) _markBounds(img.Image im, img.Color bg) {
  var minX = im.width, minY = im.height, maxX = 0, maxY = 0;
  for (final p in im) {
    if (_ink(p, bg) > 0.5) {
      minX = min(minX, p.x);
      maxX = max(maxX, p.x);
      minY = min(minY, p.y);
      maxY = max(maxY, p.y);
    }
  }
  return (x: minX, y: minY, w: maxX - minX + 1, h: maxY - minY + 1);
}

/// The mark in its own colour with anti-aliased alpha from the background
/// distance, so edges stay smooth on any colour.
img.Image _cutOut(
  img.Image im,
  ({int x, int y, int w, int h}) box,
  img.Color bg,
) {
  const pad = 4;
  final crop = img.copyCrop(
    im,
    x: box.x - pad,
    y: box.y - pad,
    width: box.w + 2 * pad,
    height: box.h + 2 * pad,
  );
  // The mark's solid colour: average of strongly inked pixels.
  var r = 0.0, g = 0.0, b = 0.0, n = 0;
  for (final p in crop) {
    if (_ink(p, bg) > 0.9) {
      r += p.r;
      g += p.g;
      b += p.b;
      n++;
    }
  }
  final ink = img.ColorRgb8(r ~/ n, g ~/ n, b ~/ n);
  final out = img.Image(width: crop.width, height: crop.height, numChannels: 4);
  for (final p in crop) {
    // Ramp from 0.2 to 0.6: JPEG noise near the background drops out.
    final t = ((_ink(p, bg) - 0.2) / 0.4).clamp(0.0, 1.0);
    final a = (t * t * (3 - 2 * t) * 255).round();
    out.setPixelRgba(p.x, p.y, ink.r, ink.g, ink.b, a);
  }
  return out;
}

/// [mark] scaled so its longer side is [fill] of a [size]² canvas, centred,
/// on [background] (or transparent).
img.Image _place(img.Image mark, int size, double fill, img.Color? background) {
  final scale = size * fill / max(mark.width, mark.height);
  final scaled = img.copyResize(
    mark,
    width: (mark.width * scale).round(),
    height: (mark.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  if (background != null) {
    img.fill(
      canvas,
      color: img.ColorRgba8(
        background.r.toInt(),
        background.g.toInt(),
        background.b.toInt(),
        255,
      ),
    );
  }
  return img.compositeImage(
    canvas,
    scaled,
    dstX: (size - scaled.width) ~/ 2,
    dstY: (size - scaled.height) ~/ 2,
  );
}

void _save(String name, img.Image im) {
  File('$_out/$name').writeAsBytesSync(img.encodePng(im));
  stdout.writeln('wrote $_out/$name (${im.width}×${im.height})');
}

String _hex(img.Color c) =>
    '#${[c.r, c.g, c.b].map((v) => v.toInt().toRadixString(16).padLeft(2, '0')).join()}'
        .toUpperCase();
