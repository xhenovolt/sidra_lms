// Generates config/<env>.json (public build values) from the local .env.
//
//   dart run tool/gen_config.dart          -> config/dev.json
//   dart run tool/gen_config.dart prod     -> config/prod.json
//
// Only an explicit allow-list of PUBLIC keys is copied. Secrets in .env
// (DATABASE_URL, CLOUDINARY_API_SECRET, ...) are never
// written, because everything in config/*.json is compiled into the app.
import 'dart:convert';
import 'dart:io';

const publicKeys = [
  'NEON_DATA_API_URL',
  'AUTH_URL',
  'CLOUDINARY_CLOUD_NAME',
];

void main(List<String> args) {
  final env = args.isEmpty ? 'dev' : args.first;
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    stderr.writeln('No .env found. Copy .env.example to .env first.');
    exit(1);
  }

  final values = parseDotEnv(envFile.readAsStringSync());
  final out = <String, String>{'SIDRA_ENV': env};
  for (final key in publicKeys) {
    final v = values[key];
    if (v != null && v.isNotEmpty) out[key] = v;
  }
  final auth = out['AUTH_URL'];
  if (auth != null && !auth.startsWith('https://')) {
    stderr.writeln('AUTH_URL must be an https:// URL. Aborting.');
    exit(1);
  }

  Directory('config').createSync();
  final file = File('config/$env.json');
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(out)}\n',
  );

  stdout.writeln('Wrote ${file.path}:');
  for (final key in publicKeys) {
    stdout.writeln('  $key: ${out.containsKey(key) ? 'set' : 'MISSING'}');
  }
}

/// Minimal .env parser: KEY=value, optional quotes, # comments.
/// Later duplicates override earlier ones.
Map<String, String> parseDotEnv(String source) {
  final result = <String, String>{};
  for (final raw in const LineSplitter().convert(source)) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final key = line.substring(0, eq).trim();
    var value = line.substring(eq + 1).trim();
    if (value.length >= 2 &&
        (value.startsWith("'") && value.endsWith("'") ||
            value.startsWith('"') && value.endsWith('"'))) {
      value = value.substring(1, value.length - 1);
    }
    result[key] = value;
  }
  return result;
}
