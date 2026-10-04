import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sidra_lms/app/router/routes.dart';

import '../helpers/fake_postgres_api.dart';
import 'teacher_console_test.dart' show signInAs, staffServer;

/// A finance officer's books: two money accounts, one fee received, one
/// expense, a bill.
FakePostgresApi booksServer() {
  final api = staffServer('finance_officer');
  api.rpcHandlers['my_permissions'] = (_) => [
    {
      'my_permissions': [
        'dashboard.view',
        'finance.view',
        'finance.record_expense',
        'finance.post_journal',
        'finance.manage_accounts',
      ],
    },
  ];
  Map<String, Object?> acct(String id, String code, String name, String type,
          double balance, {bool money = false}) =>
      {
        'account_id': id,
        'code': code,
        'name': name,
        'type': type,
        'is_money': money,
        'is_active': true,
        'debit': 0,
        'credit': 0,
        'balance': balance,
      };
  final accounts = [
    acct('a1', '1000', 'Cash on hand', 'asset', 35000, money: true),
    acct('a2', '1020', 'MarzPay wallet', 'asset', 58200, money: true),
    acct('a3', '2000', 'Bills to pay', 'liability', 80000),
    acct('a4', '3000', 'Opening balances', 'equity', 0),
    acct('a5', '4000', 'Course fees', 'income', 100000),
    acct('a6', '5000', 'Payment provider fees', 'expense', 1800),
    acct('a7', '5400', 'Rent and utilities', 'expense', 80000),
  ];
  api.rpcHandlers['ledger_balances'] = (_) => accounts;
  api.rpcHandlers['ledger_overview'] = (_) => {
    'currency': 'UGX',
    'money': [
      {'account_id': 'a1', 'code': '1000', 'name': 'Cash on hand', 'balance': 35000},
      {'account_id': 'a2', 'code': '1020', 'name': 'MarzPay wallet', 'balance': 58200},
    ],
    'money_total': 93200,
    'month_income': 100000,
    'month_expenses': 81800,
    'owed_to_us': 20000,
    'bills_due': 80000,
    'opening_entered': false,
    'not_in_books': 0,
    'needs_review': 0,
    'test_money': 0,
  };
  api.rpcHandlers['ledger_journal'] = (_) => [
    {
      'id': 'e1',
      'number': 7,
      'entry_date': '2026-10-02',
      'memo': 'Course fee from Aisha (marzpay)',
      'source_type': 'payment',
      'reversed': false,
      'lines': [
        {'code': '1020', 'account': 'MarzPay wallet', 'debit': 60000, 'credit': 0},
        {'code': '4000', 'account': 'Course fees', 'debit': 0, 'credit': 60000},
      ],
    },
  ];
  api.rpcHandlers['ledger_income_statement'] = (_) => {
    'income': [
      {'name': 'Course fees', 'amount': 100000},
    ],
    'expenses': [
      {'name': 'Payment provider fees', 'amount': 1800},
      {'name': 'Rent and utilities', 'amount': 80000},
    ],
    'total_income': 100000,
    'total_expenses': 81800,
    'surplus': 18200,
  };
  api.rpcHandlers['ledger_bills'] = (_) => [
    {
      'id': 'b1',
      'supplier': 'Landlord',
      'account': 'Rent and utilities',
      'amount': 80000,
      'paid': 0,
      'owed': 80000,
      'bill_date': '2026-10-01',
      'due_date': '2026-10-10',
    },
  ];
  return api;
}

void main() {
  Future<void> open(WidgetTester tester, String route) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
    await tester.pumpAndSettle();
  }

  testWidgets('finance home shows what Almuntahha has, from the books', (tester) async {
    await signInAs(tester, 'finance_officer', api: booksServer());
    await open(tester, Routes.adminFinance);
    expect(find.text('What Almuntahha has'), findsOneWidget);
    expect(find.text('UGX 93,200'), findsOneWidget);
    expect(find.text('MarzPay wallet'), findsOneWidget);
    expect(find.textContaining('Enter the starting amounts'), findsOneWidget);
    expect(find.text('Bills to pay'), findsOneWidget);
    // Quick actions for someone allowed to post.
    await tester.scrollUntilVisible(find.text('Money in'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Money in'), findsOneWidget);
    expect(find.text('Move money'), findsOneWidget);
  });

  testWidgets('accounts, journal, bills and reports pages', (tester) async {
    await signInAs(tester, 'finance_officer', api: booksServer());

    await open(tester, Routes.adminAccounts);
    expect(find.text('What we own'), findsOneWidget);
    expect(find.text('UGX 93,200'), findsOneWidget); // assets total
    await tester.scrollUntilVisible(find.text('Course fees'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Course fees'), findsOneWidget);

    await open(tester, Routes.adminJournal);
    await tester.tap(find.text('Course fee from Aisha (marzpay)'));
    await tester.pumpAndSettle();
    expect(find.text('Dr UGX 60,000'), findsOneWidget);
    expect(find.text('Cr UGX 60,000'), findsOneWidget);
    // Automatic entries are undone where they came from, not here.
    expect(find.text('Reverse this entry'), findsNothing);

    await open(tester, Routes.adminBills);
    expect(find.text('Landlord · UGX 80,000'), findsOneWidget);
    expect(find.text('owed UGX 80,000'), findsOneWidget);

    await open(tester, Routes.adminFinanceReports);
    expect(find.text('Surplus'), findsOneWidget);
    expect(find.text('UGX 18,200'), findsOneWidget);
  });

  testWidgets('the finance pages are in the menu', (tester) async {
    await signInAs(tester, 'finance_officer', api: booksServer());
    await open(tester, Routes.adminFinance);
    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold).first);
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    for (final page in ['Finance home', 'Payments and fees', 'Accounts', 'Journal',
                        'Bills', 'Assets', 'Financial reports', 'Counting money']) {
      expect(find.text(page), findsWidgets, reason: page);
    }
  });
}
