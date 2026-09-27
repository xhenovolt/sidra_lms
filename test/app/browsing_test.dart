import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';
import 'package:sidra_lms/features/courses/presentation/course_browsing.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_postgres_api.dart';
import '../helpers/test_app.dart';
import 'teacher_console_test.dart' show navLabels, signInAs, staffServer;

FakePostgresApi catalogueServer([FakePostgresApi? base]) {
  final api = base ?? emptyServer();
  api.selectHandlers['courses'] = (_) => [
    for (final (id, title) in [
      ('c1', 'Yassarna for Beginners'),
      ('c2', 'Introduction to Arabic'),
      ('c3', 'Tajwid Basics'),
    ])
      {
        'id': id,
        'slug': id,
        'title': title,
        'subject': 'Quran',
        'status': 'published',
        'access': 'free',
      },
  ];
  api.rpcHandlers['top_courses'] = (_) => [
    {'course_id': 'c2', 'enrolled': 40},
    {'course_id': 'c1', 'enrolled': 25},
  ];
  return api;
}

void main() {
  testWidgets('learners get top courses and a two-column grid', (tester) async {
    await tester.pumpWidget(
      await buildTestApp(
        FakeAuthService(const AuthSession.signedIn(testUser)),
        api: catalogueServer(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('Top courses'), findsOneWidget);
    expect(find.text('40 learners'), findsOneWidget); // most enrolled first
    expect(find.text('All courses'), findsOneWidget);
    final tiles = find.byType(CourseTile);
    expect(tiles, findsNWidgets(3));
    // Two columns on a phone-width screen: the first two tiles share a row.
    expect(
      tester.getTopLeft(tiles.at(0)).dy,
      tester.getTopLeft(tiles.at(1)).dy,
    );
    // Switch to the list.
    await tester.tap(find.byTooltip('Show as list'));
    await tester.pumpAndSettle();
    expect(find.byType(CourseTile), findsNothing);
  });

  testWidgets('admins switch courses between list and grid', (tester) async {
    final api = staffServer('admin');
    await signInAs(tester, 'admin', api: api);
    GoRouter.of(tester.element(find.byType(NavigationBar)))
        .go('/admin/courses');
    await tester.pumpAndSettle();
    expect(find.byType(CourseTile), findsNothing); // admins start with the list
    await tester.tap(find.byTooltip('Show as grid'));
    await tester.pumpAndSettle();
    expect(find.byType(CourseTile), findsWidgets);
  });

  testWidgets('an admin previews the learner app and exits', (tester) async {
    final api = catalogueServer(staffServer('admin'));
    await signInAs(tester, 'admin', api: api);
    GoRouter.of(tester.element(find.byType(NavigationBar)))
        .go('/admin/account');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview as learner'));
    await tester.pumpAndSettle();
    expect(find.text('You are previewing as a learner'), findsOneWidget);
    expect(navLabels(tester), containsAll(['Home', 'Explore']));
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();
    expect(find.text('You are previewing as a learner'), findsNothing);
    expect(navLabels(tester), contains('More'));
  });
}
