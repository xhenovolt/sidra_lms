// Developer CLI for MarzPay (reads .env; never shipped).
//
//   dart run tool/marzpay.dart services
//   dart run tool/marzpay.dart collect 0741341483 500 [--wait]
//   dart run tool/marzpay.dart status <uuid>
import 'dart:convert';
import 'dart:io';
import 'dart:math';

// The payments server's client, shared (plain dart:io, no Flutter).
// ignore: avoid_relative_lib_imports
import '../server/lib/marzpay.dart';
import 'gen_config.dart' show parseDotEnv;

Future<void> main(List<String> args) async {
  final env = parseDotEnv(File('.env').readAsStringSync());
  final client = MarzPayClient.fromEnv(env);
  try {
    switch (args) {
      case ['services']:
        stdout.writeln(
          const JsonEncoder.withIndent('  ').convert(await client.services()),
        );
      case ['collect', final phone, final amount, ...final rest]:
        final msisdn = MarzPayClient.normalizeUgPhone(phone);
        if (msisdn == null) throw ArgumentError('not a Uganda mobile: $phone');
        final ref = uuidV4();
        final c = await client.collect(
          amount: int.parse(amount),
          phone: msisdn,
          reference: ref,
          description: 'Sidra test collection',
        );
        stdout.writeln(
          'started: uuid=${c.uuid} reference=$ref status=${c.status} '
          'provider=${c.provider}',
        );
        if (rest.contains('--wait')) await _wait(client, c.uuid);
      case ['status', final uuid]:
        final c = await client.status(uuid);
        stdout.writeln(
          'status=${c.status} provider=${c.provider} '
          'provider_ref=${c.providerReference} amount=${c.amount}',
        );
      default:
        stderr.writeln('usage: services | collect <phone> <amount> [--wait] '
            '| status <uuid>');
        exitCode = 64;
    }
  } on MarzPayException catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  } finally {
    client.close();
  }
}

Future<void> _wait(MarzPayClient client, String uuid) async {
  final deadline = DateTime.now().add(const Duration(minutes: 3));
  var last = '';
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(seconds: 5));
    final c = await client.status(uuid);
    if (c.status != last) {
      stdout.writeln('${DateTime.now().toIso8601String()} status=${c.status}');
      last = c.status;
    }
    if (c.finished) return;
  }
  stdout.writeln('still ${last.isEmpty ? 'unknown' : last} after 3 minutes');
}

String uuidV4() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}
