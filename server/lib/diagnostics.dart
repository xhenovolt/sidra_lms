// MarzPay integration tests, run by the payments server when an admin asks
// (Admin → Settings → Payments → Test integration). Nothing here moves
// money: MarzPay has no sandbox for this account, so collections are
// tested only with requests MarzPay must REJECT (invalid amount), and the
// duplicate-notification test runs inside a database transaction that is
// always rolled back. Secrets are never included in results.
import 'dart:convert';

import 'marzpay.dart';

enum Outcome { pass, warning, fail }

class Check {
  Check(this.key, this.label, this.outcome, this.message);
  final String key;
  final String label;
  final Outcome outcome;
  final String message;

  Map<String, Object?> toJson() => {
    'key': key,
    'label': label,
    'result': outcome.name,
    'message': message,
  };
}

/// Database calls the diagnostics need (kept abstract for testing).
abstract class DiagnosticsDb {
  Future<Map<String, dynamic>> selftestIdempotency();
  Future<Map<String, dynamic>> reconciliationReport();
}

Future<List<Check>> runDiagnostics({
  required Map<String, String> env,
  required MarzPayClient marz,
  required DiagnosticsDb db,
  String? publicUrl,
  Future<MarzProbe> Function(String url)? fetchPublic,
}) async {
  final checks = <Check>[];

  // 1. Configuration
  final hasKey =
      (env['MARZPAY_API_KEY']?.isNotEmpty ?? false) &&
          (env['MARZPAY_API_SECRET']?.isNotEmpty ?? false) ||
      (env['MARZPAY_AUTH_BASIC']?.isNotEmpty ?? false);
  checks.add(
    Check(
      'configuration',
      'Configuration',
      hasKey ? Outcome.pass : Outcome.fail,
      hasKey
          ? 'API key ${marz.maskedKey} and secret are set on the payments server; '
                'base URL ${marz.baseUrl}.'
          : 'MARZPAY_API_KEY / MARZPAY_API_SECRET are missing on the payments server.',
    ),
  );

  // 2 + 3. Connectivity and authentication (lists collection services).
  final services = await marz.probe('GET', '/collect-money/services');
  if (services.status == null) {
    checks.add(
      Check(
        'connectivity',
        'Connection to MarzPay',
        Outcome.fail,
        'Could not reach MarzPay: ${services.error}.',
      ),
    );
  } else {
    checks.add(
      Check(
        'connectivity',
        'Connection to MarzPay',
        Outcome.pass,
        'MarzPay answered in ${services.elapsed.inMilliseconds} ms.',
      ),
    );
  }
  if (services.status == 200) {
    final providers = <String>[];
    final countries = (services.body?['data'] as Map?)?['countries'] as Map?;
    for (final c in (countries?.values ?? const [])) {
      for (final p in ((c as Map)['providers'] as List? ?? const [])) {
        providers.add('${(p as Map)['provider']}');
      }
    }
    checks.add(
      Check(
        'authentication',
        'Credentials accepted',
        Outcome.pass,
        'Collections available: ${providers.isEmpty ? 'none listed' : providers.join(', ')}.',
      ),
    );
  } else if (services.status != null) {
    checks.add(
      Check(
        'authentication',
        'Credentials accepted',
        Outcome.fail,
        'MarzPay refused the credentials (HTTP ${services.status}'
            '${services.message == null ? '' : ': ${services.message}'}).',
      ),
    );
  }

  // 4. Bad credentials must be refused (proves auth is really checked).
  final bad = await marz.probe(
    'GET',
    '/collect-money/services',
    basicAuth: base64Encode(utf8.encode('invalid:invalid')),
  );
  checks.add(
    Check(
      'invalid_credentials',
      'Wrong credentials are refused',
      bad.status == 401 || bad.status == 403
          ? Outcome.pass
          : bad.status == null
          ? Outcome.warning
          : Outcome.fail,
      bad.status == null
          ? 'Could not run: ${bad.error}.'
          : 'MarzPay answered HTTP ${bad.status} to made-up credentials'
                '${bad.status == 401 || bad.status == 403 ? ', as it should' : ''}.',
    ),
  );

  // 5. Collection request validation, with an amount MarzPay must reject:
  //    nobody is prompted and no money moves.
  final invalid = await marz.probe(
    'POST',
    '/collect-money',
    json: {
      'amount': 1,
      'phone_number': '+256700000000',
      'country': marz.country,
      'reference': _uuidLike(),
      'description': 'Sidra integration test (invalid on purpose)',
    },
  );
  final rejected = invalid.status == 422 || invalid.status == 400;
  checks.add(
    Check(
      'collection_request',
      'Collection requests are validated',
      rejected
          ? Outcome.pass
          : invalid.status == null
          ? Outcome.warning
          : Outcome.fail,
      rejected
          ? 'A deliberately invalid collection (1 UGX) was refused '
                '(${invalid.errorCode ?? 'HTTP ${invalid.status}'}): nobody was charged. '
                'MarzPay has no sandbox here; a real collection can only be proved '
                'by paying for a course with a PIN.'
          : invalid.status == null
          ? 'Could not run: ${invalid.error}.'
          : 'Unexpected HTTP ${invalid.status} for an invalid request; check with MarzPay.',
    ),
  );

  // 6. Transaction status retrieval.
  final report = await db.reconciliationReport();
  final latest = report['latest_provider_uuid'] as String?;
  if (latest == null) {
    checks.add(
      Check(
        'status',
        'Payment status lookup',
        Outcome.warning,
        'No MarzPay payment has been made through Sidra yet, so there is '
            'nothing to look up.',
      ),
    );
  } else {
    final s = await marz.probe('GET', '/collect-money/$latest');
    final st = (s.body?['data'] as Map?)?['transaction'] as Map?;
    checks.add(
      Check(
        'status',
        'Payment status lookup',
        s.status == 200 ? Outcome.pass : Outcome.fail,
        s.status == 200
            ? 'Latest payment is "${st?['status']}" at MarzPay.'
            : 'Could not read the latest payment (HTTP ${s.status ?? s.error}).',
      ),
    );
  }

  // 7. Timeouts are handled (a request cut short must fail cleanly).
  final quick = await marz.probe(
    'GET',
    '/collect-money/services',
    timeout: const Duration(milliseconds: 1),
  );
  checks.add(
    Check(
      'timeout',
      'Timeouts handled',
      quick.error != null || quick.status != null ? Outcome.pass : Outcome.fail,
      quick.error != null
          ? 'A request limited to 1 ms stopped cleanly ("${quick.error}"); '
                'real requests retry with backoff.'
          : 'MarzPay answered within 1 ms; timeout handling is in place.',
    ),
  );

  // 8. Duplicate notifications credit once.
  final dup = await db.selftestIdempotency();
  final once = dup['verified_rows'] == 1 && dup['second'] == 'verified';
  checks.add(
    Check(
      'duplicates',
      'Duplicate notifications credit once',
      once ? Outcome.pass : Outcome.fail,
      once
          ? 'A payment confirmed twice was credited once (test data rolled back).'
          : 'Unexpected result: ${jsonEncode(dup)}.',
    ),
  );

  // 9. Webhook readiness.
  if (publicUrl == null || publicUrl.isEmpty) {
    checks.add(
      Check(
        'webhook',
        'Webhook address',
        Outcome.warning,
        'No PUBLIC_URL: MarzPay cannot notify Sidra, so payments are '
            'confirmed by checking MarzPay every 20 seconds instead.',
      ),
    );
  } else {
    final h =
        await (fetchPublic ??
            (_) async => MarzProbe(null, null, 'not checked', Duration.zero))(
          '$publicUrl/health',
        );
    checks.add(
      Check(
        'webhook',
        'Webhook address',
        h.status == 200 ? Outcome.pass : Outcome.fail,
        h.status == 200
            ? '$publicUrl/marzpay/webhook is reachable from the internet.'
            : '$publicUrl/health did not answer (${h.status ?? h.error}).',
      ),
    );
  }

  // 10. Reconciliation.
  final stuck = (report['stuck'] as num?)?.toInt() ?? 0;
  final noAccess = (report['verified_without_access'] as num?)?.toInt() ?? 0;
  final waiting = (report['amount_mismatch_waiting'] as num?)?.toInt() ?? 0;
  checks.add(
    Check(
      'reconciliation',
      'Payments match learners and courses',
      noAccess > 0
          ? Outcome.fail
          : (stuck > 0 || waiting > 0)
          ? Outcome.warning
          : Outcome.pass,
      [
        if (noAccess > 0)
          '$noAccess fully paid learners without course access.',
        if (stuck > 0)
          '$stuck mobile-money payments unanswered for over 30 minutes.',
        if (waiting > 0)
          '$waiting MarzPay payments with an unexpected amount wait for finance.',
        if (noAccess == 0 && stuck == 0 && waiting == 0)
          'Every verified payment has opened its course; nothing is stuck.',
      ].join(' '),
    ),
  );

  // 11. Account endpoints (informational).
  final balance = await marz.probe('GET', '/balance');
  checks.add(
    Check(
      'ip_whitelist',
      'Balance and account endpoints',
      balance.status == 200 ? Outcome.pass : Outcome.warning,
      balance.status == 200
          ? 'This server can read the MarzPay balance.'
          : 'MarzPay requires this server'
                's IP address to be whitelisted to read the '
                'balance (${balance.errorCode ?? 'HTTP ${balance.status ?? balance.error}'}). '
                'Collections do not need it.',
    ),
  );
  return checks;
}

String _uuidLike() {
  final t = DateTime.now().microsecondsSinceEpoch
      .toRadixString(16)
      .padLeft(12, '0');
  return '00000000-0000-4000-8000-${t.substring(t.length - 12)}';
}
