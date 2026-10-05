import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/data/data_providers.dart';
import 'package:sidra_lms/core/export/documents.dart';
import 'package:sidra_lms/features/admin/presentation/admin_shell.dart'
    show myPermissionsProvider;
import 'package:sidra_lms/features/curriculum/domain/curriculum_models.dart';
import 'package:sidra_lms/features/finance/presentation/ledger_screens.dart';
import 'package:sidra_lms/features/payments/data/payments_repository.dart';
import 'package:sidra_lms/features/payments/presentation/course_payment_card.dart';
import 'package:sidra_lms/features/payments/presentation/receipts.dart';
import 'package:sidra_lms/l10n/app_localizations.dart';

import '../helpers/fake_postgres_api.dart';

Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  required FakePostgresApi api,
  Set<String> perms = const {},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        postgresApiProvider.overrideWithValue(api),
        myPermissionsProvider.overrideWith((_) => Stream.value(perms)),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a learner chooses how many months to pay ahead', (tester) async {
    final api = FakePostgresApi()
      ..rpcHandlers['prepay_quote'] = (p) {
        final n = p['p_periods'] as int;
        return {
          'amount': 20000 * n,
          'currency': 'UGX',
          'min_periods': 1,
          'max_periods': 12,
          'covers_from': '2026-10-01',
          'covers_until': DateTime(2026, 10 + n, 0).toIso8601String().substring(0, 10),
        };
      };
    int? chosen;
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: () async {
                    chosen = await showModalBottomSheet<int>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const PrepaySheet(
                        course: Course(id: 'c1', slug: 'c', title: 'Monthly', subject: 'Quran'),
                        balance: CourseBalance(
                          fee: 20000,
                          paid: 20000,
                          waived: 0,
                          outstanding: 0,
                          currency: 'UGX',
                          billingPeriod: 'monthly',
                          pricePerPeriod: 20000,
                          periodsCovered: 1,
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ],
            ),
          ),
        ),
      ),
      api: api,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('1 month'), findsOneWidget);
    expect(find.text('UGX 20,000'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('5 months'), findsOneWidget);
    expect(find.text('UGX 100,000'), findsOneWidget, reason: 'the 100K for 5 months case');
    expect(find.textContaining('Covers'), findsOneWidget);
    await tester.tap(find.text('Pay with mobile money'));
    await tester.pumpAndSettle();
    expect(chosen, 5);
    expect(
      api.rpcCalls.where((c) => c.$1 == 'prepay_quote').last.$2['p_periods'],
      5,
    );
  });

  testWidgets('learners see their payments and open a receipt', (tester) async {
    final api = FakePostgresApi()
      ..rpcHandlers['my_payment_history'] = ((_) => [
        {
          'id': 'p1',
          'course': 'Yassarna',
          'amount': 100000,
          'currency': 'UGX',
          'status': 'verified',
          'method': 'marzpay',
          'created_at': '2026-10-05T08:00:00Z',
          'receipt_number': 12,
          'covers_from': '2026-10-01',
          'covers_until': '2027-02-28',
          'refunded': 0,
        },
      ])
      ..rpcHandlers['payment_receipt'] = (_) => {
        'receipt_number': 12,
        'org_name': 'Almuntahha',
        'learner': 'Aisha',
        'course': 'Yassarna',
        'amount': 100000,
        'currency': 'UGX',
        'method': 'marzpay',
        'status': 'verified',
        'paid_on': '2026-10-05',
        'reference': 'abc-ref',
        'provider_reference': 'MP-123',
        'covers_from': '2026-10-01',
        'covers_until': '2027-02-28',
        'refunded': 0,
      };
    await pumpScreen(tester, const MyPaymentsScreen(), api: api);
    expect(find.textContaining('Yassarna · UGX 100,000'), findsOneWidget);
    expect(find.textContaining('SR-000012'), findsOneWidget);
    await tester.tap(find.textContaining('Yassarna · UGX 100,000'));
    await tester.pumpAndSettle();
    expect(find.text('Receipt SR-000012'), findsOneWidget);
    expect(find.text('MP-123'), findsOneWidget);
    expect(find.text('Save as PDF'), findsOneWidget);
  });

  testWidgets('owed refunds are listed with a pay-out button', (tester) async {
    final api = FakePostgresApi()
      ..rpcHandlers['finance_refunds'] = (_) => [
        {
          'id': 'r1',
          'learner': 'Bilal',
          'course': 'Yassarna',
          'amount': 5000,
          'reason': 'left',
          'agreed_on': '2026-10-04',
          'status': 'owed',
        },
        {
          'id': 'r2',
          'learner': 'Maryam',
          'amount': 3000,
          'agreed_on': '2026-09-01',
          'status': 'paid',
          'paid_out_on': '2026-09-02',
          'paid_from': 'Cash on hand',
          'payout_reference': 'Slip 4',
        },
      ];
    await pumpScreen(
      tester,
      const Scaffold(body: RefundsView()),
      api: api,
      perms: {'finance.view', 'finance.verify_payment'},
    );
    expect(find.text('Bilal · UGX 5,000'), findsOneWidget);
    expect(find.text('Pay out'), findsOneWidget, reason: 'only the owed one');
    expect(find.textContaining('Slip 4'), findsOneWidget);
  });

  test('Excel export is a real workbook with numbers kept as numbers', () {
    final bytes = tablesToXlsx([
      const DocTable(
        title: 'Income and expenses',
        columns: ['Item', 'Amount'],
        rows: [
          ['Course fees', 100000],
          ['Rent & utilities', 80000],
        ],
        numeric: {1},
      ),
    ]);
    final zip = ZipDecoder().decodeBytes(bytes);
    final names = zip.files.map((f) => f.name).toSet();
    expect(names, containsAll(['[Content_Types].xml', 'xl/workbook.xml', 'xl/worksheets/sheet1.xml']));
    final sheet = utf8.decode(zip.findFile('xl/worksheets/sheet1.xml')!.content as List<int>);
    expect(sheet, contains('<v>100000</v>'));
    expect(sheet, contains('Rent &amp; utilities'));
  });

  testWidgets('PDF export produces a PDF (Arabic-capable font)', (tester) async {
    final bytes = await tester.runAsync(
      () => tablesToPdf([
        const DocTable(title: 'Journal', columns: ['Memo', 'Amount'], rows: [
          ['رسوم الدورة', 100000],
        ]),
      ], header: 'Almuntahha'),
    );
    expect(utf8.decode(bytes!.sublist(0, 5), allowMalformed: true), '%PDF-');
  });
}
