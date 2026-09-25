// Builds a release APK named Sidra-<version>-<channel>.apk into dist/.
//
//   dart run tool/build_apk.dart            -> dist/Sidra-1.1.0-dev.apk
//   dart run tool/build_apk.dart beta
//   dart run tool/build_apk.dart prod
//
// Channel selects config/<channel>.json, regenerated from .env first.
// Version comes from pubspec.yaml (X.Y.Z; the +build number is embedded in
// the APK as versionCode).
import 'dart:io';

const channels = {'dev', 'beta', 'prod'};

Future<void> main(List<String> args) async {
  final channel = args.isEmpty ? 'dev' : args.first;
  if (!channels.contains(channel)) {
    stderr.writeln('Unknown channel "$channel". Use one of: $channels');
    exit(64);
  }

  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*(\d+\.\d+\.\d+)(?:\+(\d+))?',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) {
    stderr.writeln('Could not read version from pubspec.yaml');
    exit(1);
  }
  final version = match.group(1)!;
  final build = match.group(2) ?? '1';

  await _run('dart', ['run', 'tool/gen_config.dart', channel]);
  await _run('flutter', [
    'build',
    'apk',
    '--release',
    '--dart-define-from-file=config/$channel.json',
    '--build-name=$version',
    '--build-number=$build',
  ]);

  final apk = File('build/app/outputs/flutter-apk/app-release.apk');
  if (!apk.existsSync()) {
    stderr.writeln('Build finished but ${apk.path} was not found.');
    exit(1);
  }
  Directory('dist').createSync();
  final target = 'dist/Sidra-$version-$channel.apk';
  apk.copySync(target);
  final mb = (File(target).lengthSync() / (1024 * 1024)).toStringAsFixed(1);
  stdout.writeln('\nAPK ready: $target ($mb MB, versionCode $build)');
}

Future<void> _run(String exe, List<String> args) async {
  stdout.writeln('> $exe ${args.join(' ')}');
  final p = await Process.start(
    exe,
    args,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await p.exitCode;
  if (code != 0) {
    stderr.writeln('$exe exited with $code');
    exit(code);
  }
}
