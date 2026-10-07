// Google Play graphics, rendered from the app itself (run on demand):
//   STORE_GRAPHICS=1 flutter test test/store --update-goldens
// Writes dist/play-store/: icon-512.png, feature-graphic-1024x500.png and
// phone screenshots (1080x2340) of real screens with sample courses.
@Tags(['store'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:sidra_lms/app/router/routes.dart';
import 'package:sidra_lms/core/theme/app_tokens.dart';
import 'package:sidra_lms/features/auth/domain/auth_session.dart';
import 'package:sidra_lms/features/profile/presentation/appearance_screen.dart';

import '../app/finance_ledger_test.dart' show booksServer;
import '../app/teacher_console_test.dart' show signInAs;
import '../helpers/fake_auth_service.dart';
import '../helpers/fake_postgres_api.dart';
import '../helpers/test_app.dart';

const _out = '../../dist/play-store';
final _run = Platform.environment['STORE_GRAPHICS'] == '1';

Future<void> _font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
    );
  }
  await loader.load();
}

Future<void> _loadFonts() async {
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? 'C:/FlutterSDK/flutter';
  final m = '$sdk/bin/cache/artifacts/material_fonts';
  await _font('Roboto', [
    for (final w in ['regular', 'medium', 'bold', 'light']) '$m/roboto-$w.ttf',
  ]);
  await _font('MaterialIcons', ['$m/materialicons-regular.otf']);
  await _font('Lora', ['assets/fonts/Lora-Variable.ttf']);
  await _font('Amiri', [
    'assets/fonts/Amiri-Regular.ttf',
    'assets/fonts/Amiri-Bold.ttf',
  ]);
}

/// Sample courses, as Almuntahha's catalogue describes them.
FakePostgresApi demoServer() {
  final api = emptyServer();
  final courses = [
    (
      'c1',
      'Yassarna for Beginners',
      'Quran',
      'Read Arabic letters and short words with correct sounds.',
    ),
    (
      'c2',
      'Yassarna Intermediate',
      'Quran',
      'Join letters, read with harakat and practise daily portions.',
    ),
    (
      'c3',
      'Introduction to Qur\'an Recitation',
      'Tajweed',
      'Recite with tajweed, corrected word by word by your teacher.',
    ),
    (
      'c4',
      'Introduction to Arabic Language',
      'Arabic',
      'First steps in reading and understanding Arabic.',
    ),
  ];
  api.selectHandlers['courses'] = (f) => [
    for (final (id, title, subject, d) in courses)
      if (f['id'] == null ||
          f['id'] == 'eq.$id' ||
          (f['id'] ?? '').contains(id))
        {
          'id': id,
          'slug': id,
          'title': title,
          'subject': subject,
          'description': d,
          'status': 'published',
          'visibility': 'catalogue',
          'access': 'free',
          'progression': 'teacher_gated',
          'language': 'en',
        },
  ];
  api.rpcHandlers['top_courses'] = (_) => [
    for (final (id, title, subject, _) in courses)
      {
        'id': id,
        'title': title,
        'subject': subject,
        'learners': 40 - id.codeUnitAt(1),
      },
  ];
  api.rpcHandlers['my_courses'] = (_) => [
    for (final (id, pct, done, total) in [
      ('c1', 62, 10, 16),
      ('c3', 25, 3, 12),
    ])
      {
        'course_id': id,
        'enrolment_id': 'e$id',
        'enrolment_status': 'active',
        'total_lessons': total,
        'completed_lessons': done,
        'unlocked_lessons': done + 1,
        'progress_percent': pct,
        'next_lesson_id': '${id}l${done + 1}',
        'last_accessed_at': DateTime.now().toIso8601String(),
      },
  ];
  api.selectHandlers['course_units'] = (_) => [
    {
      'id': 'u1',
      'course_id': 'c1',
      'title': 'The Arabic letters',
      'position': 0,
      'status': 'published',
    },
    {
      'id': 'u2',
      'course_id': 'c1',
      'title': 'Short vowels (harakat)',
      'position': 1,
      'status': 'published',
    },
  ];
  api.selectHandlers['curriculum_nodes'] = (_) => [
    {
      'id': 'n1',
      'course_id': 'c1',
      'unit_id': 'u1',
      'node_type': 'section',
      'title': 'Yassarna — page 3',
      'position': 0,
      'page_start': 3,
      'status': 'published',
    },
    {
      'id': 'n2',
      'course_id': 'c1',
      'unit_id': 'u2',
      'node_type': 'section',
      'title': 'Yassarna — page 9',
      'position': 0,
      'page_start': 9,
      'status': 'published',
    },
  ];
  final lessons = [
    ('l1', 'n1', 'Alif, Ba, Ta'),
    ('l2', 'n1', 'Tha, Jim, Ha'),
    ('l3', 'n1', 'Kha, Dal, Dhal'),
    ('l4', 'n2', 'Fatha'),
    ('l5', 'n2', 'Kasra'),
    ('l6', 'n2', 'Damma'),
  ];
  api.selectHandlers['lessons'] = (_) => [
    for (final (i, (id, node, title)) in lessons.indexed)
      {
        'id': id,
        'course_id': 'c1',
        'node_id': node,
        'title': title,
        'position': i,
        'status': 'published',
      },
  ];
  api.rpcHandlers['course_lesson_order'] = (_) => [
    for (final (i, (id, _, _)) in lessons.indexed)
      {
        'lesson_id': id,
        'seq': i + 1,
        'is_unlocked': i < 4,
        'is_completed': i < 3,
      },
  ];
  return api;
}

Future<void> _shoot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  // Pictures (the logo…) load asynchronously: wait for them.
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('$_out/$name.png'),
  );
  _flatten('dist/play-store/$name.png');
}

/// Play wants the feature graphic without transparency: rewrite as RGB.
void _flatten(String path) {
  final f = File(path);
  final image = img.decodePng(f.readAsBytesSync())!;
  final rgb = img.Image(
    width: image.width,
    height: image.height,
    numChannels: 3,
  );
  img.compositeImage(rgb, image);
  f.writeAsBytesSync(img.encodePng(rgb));
}

void main() {
  setUpAll(() async {
    if (_run) await _loadFonts();
  });

  test('app icon 512x512', () {
    final src = img.decodePng(
      File('assets/branding/icon.png').readAsBytesSync(),
    )!;
    final icon = img.copyResize(
      src,
      width: 512,
      height: 512,
      interpolation: img.Interpolation.cubic,
    );
    Directory('dist/play-store').createSync(recursive: true);
    File('dist/play-store/icon-512.png').writeAsBytesSync(img.encodePng(icon));
  }, skip: _run ? false : 'set STORE_GRAPHICS=1');

  testWidgets('feature graphic 1024x500', (tester) async {
    tester.view.physicalSize = const Size(1024, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final mark = File('assets/branding/icon.png').readAsBytesSync();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SidraColors.teal900,
                  SidraColors.teal700,
                  SidraColors.teal500,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 72),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(48),
                  child: Image.memory(mark, width: 240, height: 240),
                ),
                const SizedBox(width: 56),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Sidra',
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 92,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          SizedBox(width: 24),
                          Text(
                            'سدرة',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 64,
                              color: SidraColors.gold200,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Learn the Qur\'an with your teacher,\nwherever you are.',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 34,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'from Almuntahha',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 24,
                          color: SidraColors.gold200,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () =>
          precacheImage(MemoryImage(mark), tester.element(find.byType(Image))),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('$_out/feature-graphic-1024x500.png'),
    );
    _flatten('dist/play-store/feature-graphic-1024x500.png');
  }, skip: !_run);

  group('phone screenshots 1080x2340', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(
        1080,
        2340,
      );
      binding.platformDispatcher.views.first.devicePixelRatio = 2.625;
    });
    tearDown(
      () => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
          .reset(),
    );

    Future<void> learner(WidgetTester tester, {FakePostgresApi? api}) async {
      await tester.pumpWidget(
        await buildTestApp(
          FakeAuthService(
            const AuthSession.signedIn(
              AppUser(id: 'u1', displayName: 'Aisha Nakato', role: 'learner'),
            ),
          ),
          api: api ?? demoServer(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('1 my courses', (tester) async {
      await learner(tester);
      await _shoot(tester, 'screenshot-1-my-courses');
    }, skip: !_run);

    testWidgets('2 course page', (tester) async {
      await learner(tester);
      await tester.tap(find.text('Yassarna for Beginners').last);
      await _shoot(tester, 'screenshot-2-course');
    }, skip: !_run);

    testWidgets('3 explore courses', (tester) async {
      await learner(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Explore'),
        ),
      );
      await _shoot(tester, 'screenshot-3-explore');
    }, skip: !_run);

    testWidgets('4 appearance', (tester) async {
      // As someone who has the premium themes.
      final api = demoServer()
        ..rpcHandlers['my_entitlements'] = ((_) => [
          {
            'my_entitlements': ['themes_premium'],
          },
        ]);
      await learner(tester, api: api);
      Navigator.of(
        tester.element(find.byType(NavigationBar)),
      ).push(MaterialPageRoute<void>(builder: (_) => const AppearanceScreen()));
      await _shoot(tester, 'screenshot-4-appearance');
    }, skip: !_run);

    testWidgets('5 finance for administrators', (tester) async {
      // Once starting amounts are in and the accountant confirmed the rules.
      final api = booksServer();
      final overview = api.rpcHandlers['ledger_overview']!;
      api.rpcHandlers['ledger_overview'] = (p) => {
        ...(overview(p)! as Map<String, Object?>),
        'opening_entered': true,
        'rules_confirmed': {'by': 'Accountant', 'on': '2026-10-01'},
      };
      await signInAs(tester, 'finance_officer', api: api);
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go(Routes.adminFinance);
      await _shoot(tester, 'screenshot-5-finance');
    }, skip: !_run);
  });
}
