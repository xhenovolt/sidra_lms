// Builds the small icon Android shows in the status bar and notification
// panel. Android draws only the icon's shape (its alpha), so a full-colour
// launcher icon turns into a plain circle. This writes the Sidra mark as a
// white silhouette on transparency.
//
//   dart run tool/gen_notification_icon.dart
//
// Source: assets/branding/mark.png. Output: android/app/src/main/res/
// drawable-<density>/ic_stat_sidra.png
import 'dart:io';

import 'package:image/image.dart' as img;

const _source = 'assets/branding/mark.png';
const _sizes = {'mdpi': 24, 'hdpi': 36, 'xhdpi': 48, 'xxhdpi': 72, 'xxxhdpi': 96};

void main() {
  final src = img.decodeImage(File(_source).readAsBytesSync());
  if (src == null) {
    stderr.writeln('Cannot read $_source');
    exit(1);
  }
  final white = img.Image(width: src.width, height: src.height, numChannels: 4);
  for (final p in src) {
    white.setPixelRgba(p.x, p.y, 255, 255, 255, p.a);
  }
  for (final MapEntry(key: density, value: size) in _sizes.entries) {
    // Android keeps a little padding round status-bar icons.
    final inner = (size * 0.84).round();
    final mark = img.copyResize(white, width: inner, height: inner,
        interpolation: img.Interpolation.average);
    final out = img.Image(width: size, height: size, numChannels: 4);
    img.compositeImage(out, mark,
        dstX: (size - inner) ~/ 2, dstY: (size - inner) ~/ 2);
    final dir = Directory('android/app/src/main/res/drawable-$density')
      ..createSync(recursive: true);
    File('${dir.path}/ic_stat_sidra.png').writeAsBytesSync(img.encodePng(out));
    stdout.writeln('${dir.path}/ic_stat_sidra.png ($size px)');
  }
}
