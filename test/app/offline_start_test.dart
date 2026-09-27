import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/data/cache_first.dart';
import 'package:sidra_lms/core/data/data_providers.dart';
import 'package:sidra_lms/core/errors/app_failure.dart';

import '../helpers/fake_postgres_api.dart';
import 'teacher_console_test.dart' show navLabels, signInAs, staffServer;

void main() {
  testWidgets('admin with no internet still gets the bottom bar', (
    tester,
  ) async {
    final api = staffServer('admin')..failAll = const OfflineFailure();
    await signInAs(tester, 'admin', api: api);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(navLabels(tester), contains('More'));
    expect(navLabels(tester).length, greaterThanOrEqualTo(3));
  });

  test('cache first: saved copy at once, then the server', () async {
    final db = await openTestDatabase();
    final container = ProviderContainer(
      overrides: [localDatabaseProvider.overrideWith((_) async => db)],
    );
    addTearDown(container.dispose);
    var online = true;
    var serverValue = 'fresh-1';
    final provider = StreamProvider.autoDispose<String>(
      (ref) => cacheFirst<String>(
        ref,
        key: 'demo',
        fetch: () async {
          if (!online) throw const OfflineFailure();
          return serverValue;
        },
        encode: (v) => v,
        decode: (j) => j! as String,
      ),
    );

    // First open: nothing saved, shows the server's answer and saves it.
    final seen = <String>[];
    final sub = container.listen(
      provider,
      (_, next) => next.whenData(seen.add),
      fireImmediately: true,
    );
    await container.read(provider.future);
    await Future<void>.delayed(Duration.zero);
    expect(seen, ['fresh-1']);
    sub.close();

    // Reopen offline: the saved copy shows, no error.
    online = false;
    container.invalidate(provider);
    final offline = <AsyncValue<String>>[];
    final sub2 = container.listen(
      provider,
      (_, next) => offline.add(next),
      fireImmediately: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(offline.last.value, 'fresh-1');
    expect(offline.any((v) => v.hasError), isFalse);
    sub2.close();

    // Back online: saved copy first, then the new one.
    online = true;
    serverValue = 'fresh-2';
    container.invalidate(provider);
    final again = <String>[];
    final sub3 = container.listen(
      provider,
      (_, next) => next.whenData(again.add),
      fireImmediately: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(again.first, 'fresh-1'); // the saved copy, at once
    expect(again.last, 'fresh-2'); // then the server's
    sub3.close();
  });
}
