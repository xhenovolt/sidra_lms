import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/test_app.dart';

Finder field(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets('sign in with phone lands on Home', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(await buildTestApp(auth, authConfigured: true));
    await tester.pumpAndSettle();

    await tester.enterText(field('identifier'), '+256 700 000001');
    await tester.enterText(field('password'), 'correct-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['signIn:+256 700 000001']);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('validates before calling the server', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(await buildTestApp(auth, authConfigured: true));
    await tester.pumpAndSettle();

    // (0772… is fine since learners type local numbers; this is not a number)
    await tester.enterText(field('identifier'), '12 345');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter a mobile number like'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget); // empty password
    expect(auth.calls, isEmpty);

    // Switching to email validates as email.
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    await tester.enterText(field('identifier'), 'not-an-email');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('wrong password shows a friendly error', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(await buildTestApp(auth, authConfigured: true));
    await tester.pumpAndSettle();

    await tester.enterText(field('identifier'), '+256700000001');
    await tester.enterText(field('password'), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(
      find.text("Those sign-in details and password don't match."),
      findsOneWidget,
    );
    expect(auth.session.isSignedIn, isFalse);
  });

  testWidgets('create an account, then land on Home', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(await buildTestApp(auth, authConfigured: true));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('New to Sidra? Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New to Sidra? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(field('name'), 'Maryam Nabirye');
    await tester.enterText(field('identifier'), '+256711222333');
    await tester.enterText(field('password'), 'my-password');
    await tester.enterText(field('confirm'), 'different');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);

    await tester.enterText(field('confirm'), 'my-password');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(auth.calls, ['signUp:+256711222333']);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.textContaining('Maryam'), findsOneWidget); // greeting
  });

  testWidgets('temporary password forces a change before anything else', (
    tester,
  ) async {
    final auth = FakeAuthService(
      const AuthSession.signedIn(
        AppUser(id: 'u1', displayName: 'Yusuf', mustChangePassword: true),
      ),
    );
    await tester.pumpWidget(await buildTestApp(auth, authConfigured: true));
    await tester.pumpAndSettle();

    expect(find.text('Choose a new password'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.enterText(field('old'), 'sidra-12345');
    await tester.enterText(field('new'), 'my-new-password');
    await tester.enterText(field('confirm'), 'my-new-password');
    await tester.ensureVisible(find.text('Save password'));
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['changePassword']);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
