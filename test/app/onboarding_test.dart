import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';
import 'package:sidra_lms/features/onboarding/data/import_parsers.dart';
import 'package:sidra_lms/features/onboarding/presentation/onboarding_wizard.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/test_app.dart';
import 'teacher_console_test.dart' show signInAs, staffServer;

void main() {
  testWidgets('an imported learner joins with the invitation code', (tester) async {
    final auth = FakeAuthService(const AuthSession.signedOut())
      ..invitations['+256772000002'] = 'ABCD2345'; // the app sends +256…
    await tester.pumpWidget(await buildTestApp(auth, authConfigured: true));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('I have an invitation code'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I have an invitation code'));
    await tester.pumpAndSettle();
    expect(find.text('Join with your invitation'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '0772000002');
    await tester.enterText(fields.at(1), 'WRONG-123');
    await tester.enterText(fields.at(2), 'my-own-pass-1');
    await tester.enterText(fields.at(3), 'my-own-pass-1');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Join Sidra'));
    await tester.tap(find.widgetWithText(FilledButton, 'Join Sidra'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(find.textContaining('That code is not right'), findsOneWidget);
    expect(auth.session.isSignedIn, isFalse);

    await tester.enterText(fields.at(1), 'abcd-2345');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Join Sidra'));
    await tester.tap(find.widgetWithText(FilledButton, 'Join Sidra'));
    await tester.pumpAndSettle();
    expect(auth.calls.where((c) => c.startsWith('activate:')).length, 2);
    expect(auth.session.isSignedIn, isTrue, reason: 'signed in with their own password');
  });

  testWidgets('a WhatsApp group: check, decide duplicates, import, invitations', (tester) async {
    final api = staffServer('admin');
    api.rpcHandlers['onboarding_preview'] = (p) => [
      {'row': 1, 'name': 'Ahmed Musa', 'phone': '+256772123401', 'status': 'new', 'reasons': [], 'matches': []},
      {
        'row': 2, 'name': 'Fatuma Ali', 'phone': '+256701234567', 'status': 'existing', 'reasons': [],
        'matches': [{'user_id': 'u-fatuma', 'name': 'Fatuma Ali', 'phone': '+2567••••567', 'why': 'same_phone'}],
      },
      {
        'row': 3, 'name': 'Yusuf H', 'phone': '+256752999888', 'status': 'possible_duplicate', 'reasons': [],
        'matches': [{'user_id': 'u-yusuf', 'name': 'Yusuf H', 'phone': '+2567••••111', 'why': 'same_name'}],
      },
    ];
    api.rpcHandlers['onboard_learners'] = (p) => {
      'batch_id': 'b1', 'created': 2, 'matched': 1, 'skipped': 0, 'rejected': 0,
      'rows': [
        {'row': 1, 'name': 'Ahmed Musa', 'phone': '+256772123401', 'outcome': 'created', 'user_id': 'u1', 'invitation_code': 'ABCD-2345'},
        {'row': 2, 'name': 'Fatuma Ali', 'phone': '+256701234567', 'outcome': 'matched', 'user_id': 'u-fatuma'},
        {'row': 3, 'name': 'Yusuf H', 'phone': '+256752999888', 'outcome': 'created', 'user_id': 'u3', 'invitation_code': 'EFGH-6789'},
      ],
    };
    await signInAs(tester, 'admin', api: api);
    final parsed = parseWhatsAppExport(
      '30/09/2026, 08:01 - Ustadh Musa: Read page 18 today\n'
      '30/09/2026, 08:05 - +256 772 123 401: done\n'
      '30/09/2026, 08:06 - +256 701 234 567: done\n'
      '30/09/2026, 08:07 - +256 752 999 888: page 21\n',
    );
    final nav = Navigator.of(tester.element(find.byType(Scaffold).first));
    nav.push(MaterialPageRoute<void>(
      builder: (_) => OnboardingWizard(parsed: parsed, suggestedGroup: 'Yassarna A'),
    ));
    await tester.pumpAndSettle();

    // The teacher wrote too, saved by name only: no number, flagged; untick.
    expect(find.textContaining('have no phone number or email'), findsOneWidget);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Ustadh Musa'));
    await tester.pump();
    await tester.tap(find.text('Check 3 against Sidra'));
    await tester.pumpAndSettle();

    final preview = api.rpcCalls.lastWhere((c) => c.$1 == 'onboarding_preview');
    expect((preview.$2['p_rows'] as List).length, 3, reason: 'only the chosen people are sent');
    expect(find.text('Already in Sidra'), findsWidgets);
    // A possible duplicate must be decided before going on.
    final next = find.widgetWithText(FilledButton, 'Next');
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.scrollUntilVisible(find.text('A different person: create'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('A different person: create'));
    await tester.pump();
    expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
    await tester.tap(next);
    await tester.pumpAndSettle();

    // Placement: no course this time (learners are added and invited).
    expect(find.text('No course yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ready: 2 new learners, 1 existing linked'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Import 3'));
    await tester.pumpAndSettle();

    final call = api.rpcCalls.lastWhere((c) => c.$1 == 'onboard_learners');
    final rows = (call.$2['p_rows'] as List).cast<Map>();
    expect([for (final r in rows) r['action']], ['create', 'use_existing', 'create_separate']);
    expect(rows[1]['existing_user_id'], 'u-fatuma', reason: 'linked, not duplicated');
    final opts = call.$2['p_options'] as Map;
    expect(opts['source'], 'whatsapp');
    expect(opts['previous_group'], 'Yassarna A');
    expect(opts['invite'], true);

    expect(find.text('Learners imported'), findsOneWidget);
    expect(find.textContaining('ABCD-2345'), findsOneWidget);
    expect(find.textContaining('EFGH-6789'), findsOneWidget);
    expect(find.byTooltip('Send on WhatsApp'), findsNWidgets(2));
  });
}
