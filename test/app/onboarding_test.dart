import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('first launch: onboarding pages then sign-in, flag persisted', (
    tester,
  ) async {
    await tester.pumpWidget(
      await buildTestApp(FakeAuthService(), onboarded: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learn with structure'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Guided by your teacher'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Study anywhere'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Sidra'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_completed_v1'), isTrue);
  });

  testWidgets('skip jumps straight to sign-in', (tester) async {
    await tester.pumpWidget(
      await buildTestApp(FakeAuthService(), onboarded: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Sidra'), findsOneWidget);
  });

  testWidgets('returning signed-out learner goes straight to sign-in', (
    tester,
  ) async {
    await tester.pumpWidget(await buildTestApp(FakeAuthService()));
    await tester.pumpAndSettle();
    expect(find.text('Learn with structure'), findsNothing);
    expect(find.text('Welcome to Sidra'), findsOneWidget);
  });

  testWidgets('build without Clerk key explains instead of dead-ending', (
    tester,
  ) async {
    // Tests run without --dart-define, so the Clerk key is absent.
    await tester.pumpWidget(await buildTestApp(FakeAuthService()));
    await tester.pumpAndSettle();
    expect(find.text('Sign-in is not available yet'), findsOneWidget);
    expect(find.textContaining('CLERK_PUBLISHABLE_KEY'), findsOneWidget);
  });

  testWidgets('onboarding renders right-to-left in Arabic', (tester) async {
    await tester.pumpWidget(
      await buildTestApp(
        FakeAuthService(),
        onboarded: false,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('تعلّم بمنهجية'), findsOneWidget);
    final ctx = tester.element(find.byType(PageView));
    expect(Directionality.of(ctx), TextDirection.rtl);
  });
}
