import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/features/media/presentation/capture_sheet.dart';
import 'package:sidra_lms/l10n/app_localizations.dart';

Widget _host(void Function(BuildContext) onTap) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => onTap(context),
          child: const Text('Add'),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('the add sheet offers every way to add content', (tester) async {
    await tester.pumpWidget(_host((c) => captureContent(c)));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    for (final label in [
      'Take photo',
      'Record video',
      'Scan pages (PDF)',
      'Record audio',
      'From gallery',
      'Choose file',
      'Paste text',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('pasting text returns the clipboard text', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? {'text': '  Read page 12 slowly.  '}
          : null,
    );
    CapturedFile? got;
    await tester.pumpWidget(
      _host((c) async {
        got = await captureContent(c, allow: const {CaptureSource.paste});
      }),
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(got?.kind, 'text');
    expect(got?.text, 'Read page 12 slowly.');
  });
}
