import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('signed-in learner lands on Home with greeting and nav', (
    tester,
  ) async {
    final auth = FakeAuthService(const AuthSession.signedIn(testUser));
    await tester.pumpWidget(await buildTestApp(auth));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aisha'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Begin your journey'), findsOneWidget);
  });

  testWidgets('tabs switch sections', (tester) async {
    final auth = FakeAuthService(const AuthSession.signedIn(testUser));
    await tester.pumpWidget(await buildTestApp(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();
    expect(find.text('No downloads'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('aisha@example.com'), findsOneWidget);
  });

  testWidgets('initializing shows splash, then home when session restores', (
    tester,
  ) async {
    final auth = FakeAuthService(const AuthSession.initializing());
    await tester.pumpWidget(await buildTestApp(auth));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    auth.session = const AuthSession.signedIn(testUser);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Arabic locale lays out right-to-left', (tester) async {
    final auth = FakeAuthService(const AuthSession.signedIn(testUser));
    await tester.pumpWidget(
      await buildTestApp(auth, locale: const Locale('ar')),
    );
    await tester.pumpAndSettle();

    final ctx = tester.element(find.byType(NavigationBar));
    expect(Directionality.of(ctx), TextDirection.rtl);
    expect(find.text('الرئيسية'), findsOneWidget);
  });
}
