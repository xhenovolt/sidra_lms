-- 0051/0052: double-entry books. Every posting balances, money accounts
-- show what the organisation has, nothing can be edited, and only finance
-- staff can read or write.

create function pg_temp.lg_staff(p_name text, p_role text) returns uuid
language plpgsql as $$
declare v uuid;
begin
  v := app_private.create_account(p_name, null, null, lower(replace(p_name, ' ', '_')),
                                  'learner', false, 'staff-pass-1', false);
  insert into user_roles (user_id, role_key) values (v, p_role);
  return v;
end $$;

-- Earlier test files post too (their payments are verified): this test
-- measures only its own entries, numbered after this point.
select set_config('lg.n', coalesce((select max(number) from journal_entries), 0)::text, true);

create function pg_temp.acct(p_code text) returns uuid
language sql as $$ select id from ledger_accounts where code = p_code $$;
grant execute on function pg_temp.acct(text) to authenticated;

-- What this test moved on an account, on the account's natural side.
create function pg_temp.bal(p_code text) returns numeric
language sql as $$
  select coalesce(sum(case when a.type in ('asset', 'expense') then l.debit - l.credit
                           else l.credit - l.debit end), 0)
  from ledger_accounts a
  left join (journal_lines l join journal_entries e on e.id = l.entry_id
             and e.number > current_setting('lg.n')::bigint) on l.account_id = a.id
  where a.code = p_code
$$;
grant execute on function pg_temp.bal(text) to authenticated;

select set_config('lg.fin', pg_temp.lg_staff('Ledger Finance', 'finance_officer')::text, true);
select set_config('lg.teacher', pg_temp.lg_staff('Ledger Teacher', 'teacher')::text, true);
select set_config('lg.learner', app_private.create_account('Ledger Learner', '+256772760001', null, null,
  'learner', false, 'learner-pass-1', false)::text, true);
insert into courses (id, slug, title, subject, access, price_amount, price_currency, progression, status, language)
values ('00000000-0000-0000-0000-000000101001', 'lg-paid', 'LG Paid', 'Quran', 'paid', 100000, 'UGX',
        'open', 'published', 'en');

-- The chart is there and starts empty.
select pg_temp.check((select count(*) from ledger_accounts where is_money) = 4, 'four money accounts');

-- ----------------------------------------------- nobody else can look --
select pg_temp.login_as_id(current_setting('lg.teacher')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.ledger_overview()$q$, 'not allowed');
select pg_temp.check((select count(*) from ledger_accounts) = 0, 'a teacher sees no accounts');
select pg_temp.expect_error($q$select public.ledger_post_journal(current_date, 'x', '[]')$q$, 'not allowed');
reset role;

select pg_temp.login_as_id(current_setting('lg.fin')::uuid);
set local role authenticated;
select pg_temp.check((public.ledger_overview()->>'opening_entered')::boolean = false, 'no opening balances yet');
select set_config('lg.nib', public.ledger_overview()->>'not_in_books', true);

-- ------------------------------------------------- automatic postings --
-- A cash payment, recorded then verified: cash up, course fees up.
select set_config('lg.cash', (public.record_payment(current_setting('lg.learner')::uuid,
  '00000000-0000-0000-0000-000000101001', 40000, 'cash', 'RCPT-1', current_date - 3, null))->>'id', true);
select pg_temp.check(pg_temp.bal('1000') = 0, 'nothing posted before verification');
select public.verify_payment(current_setting('lg.cash')::uuid);
select pg_temp.check(pg_temp.bal('1000') = 40000, 'verified cash payment: cash on hand 40,000');
select pg_temp.check(pg_temp.bal('4000') = 40000, 'course fees 40,000');
reset role;

-- A MarzPay payment confirmed with MarzPay's real fee (as the Worker does).
insert into payments (id, user_id, course_id, amount, currency, method, status, provider, verified_at,
                      verified_via, provider_fee, paid_on)
values ('00000000-0000-0000-0000-000000102001', current_setting('lg.learner')::uuid,
        '00000000-0000-0000-0000-000000101001', 60000, 'UGX', 'marzpay', 'verified', 'marzpay', now(),
        'payments_server', 1800, current_date - 2);
select pg_temp.check(pg_temp.bal('1020') = 58200, 'MarzPay wallet: 60,000 less the 1,800 fee');
select pg_temp.check(pg_temp.bal('5000') = 1800, 'provider fees: the actual fee');
-- The trigger firing again posts nothing twice.
update payments set provider_fee = 1800, updated_at = now() where id = '00000000-0000-0000-0000-000000102001';
select pg_temp.check(pg_temp.bal('1020') = 58200, 'no double posting');

-- A real-money MarzPay test that MarzPay's ledger proved: the money is in
-- the wallet, held as Test money (not income); MarzPay's fee is a cost.
insert into payment_tests (kind, params, real_money, result, status, evidence, finished_at)
values ('collection', '{"amount": 1000, "currency": "UGX"}', true, 'verified_success', 'done',
        '{"amount": 1000, "fee": 30}', now());
select pg_temp.check(pg_temp.bal('2090') = 1000 and pg_temp.bal('1020') = 58200 + 970
  and pg_temp.bal('5000') = 1830 and pg_temp.bal('4000') = 100000,
  'test money: in the wallet, held as Test money, fee booked, income unchanged');
-- A test that did not finish moves nothing.
insert into payment_tests (kind, params, real_money, result, status)
values ('collection', '{"amount": 500}', true, 'pending', 'done');
select pg_temp.check(pg_temp.bal('2090') = 1000, 'an unfinished test books nothing');

-- A payment in another currency stays out of the books (and is listed).
insert into payments (user_id, course_id, amount, currency, method, status, verified_at)
values (current_setting('lg.learner')::uuid, '00000000-0000-0000-0000-000000101001', 20, 'USD', 'bank',
        'verified', now());

select pg_temp.login_as_id(current_setting('lg.fin')::uuid);
set local role authenticated;
select pg_temp.check((public.ledger_overview()->>'not_in_books')::int = current_setting('lg.nib')::int + 1,
  'the USD payment is listed as not in the books');

-- Refund part of the cash payment: owed to the learner first (income down),
-- then paid out from cash.
select set_config('lg.refund', (public.record_refund(current_setting('lg.cash')::uuid, 5000, 'left the course'))->>'id', true);
select pg_temp.check(pg_temp.bal('1000') = 40000 and pg_temp.bal('4090') = -5000 and pg_temp.bal('2050') = 5000,
  'refund agreed: owed to the learner, cash not yet paid');
select pg_temp.check((public.ledger_overview()->>'refunds_owed')::numeric >= 5000, 'owed refunds on the finance home');
select pg_temp.expect_error($q$select public.pay_out_refund(current_setting('lg.refund')::uuid,
  pg_temp.acct('1000'), 'cash', '')$q$, 'transaction ID');
select public.pay_out_refund(current_setting('lg.refund')::uuid, pg_temp.acct('1000'), 'cash', 'Cash slip 12');
select pg_temp.check(pg_temp.bal('1000') = 35000 and pg_temp.bal('2050') = 0, 'refund paid out from cash');
select pg_temp.expect_error($q$select public.pay_out_refund(current_setting('lg.refund')::uuid,
  pg_temp.acct('1000'), 'cash', 'again')$q$, 'already paid');

-- Reverse the MarzPay payment: the receipt is undone, the fee stays (MarzPay keeps it).
select public.reverse_payment('00000000-0000-0000-0000-000000102001', 'chargeback');
select pg_temp.check(pg_temp.bal('1020') = -1800 + 970 and pg_temp.bal('4000') = 40000,
  'reversed: wallet loses the 60,000, income back to 40,000, fee remains');

-- Expenses: with an account and where the money came from.
select set_config('lg.exp', (public.record_expense('Internet', 15000, current_date - 1, 'Bundles', 'MTN', null,
  pg_temp.acct('5200'), pg_temp.acct('1000')))->>'id', true);
select pg_temp.check(pg_temp.bal('5200') = 15000 and pg_temp.bal('1000') = 20000, 'expense paid from cash');
select public.void_expense(current_setting('lg.exp')::uuid, 'entered twice');
select pg_temp.check(pg_temp.bal('5200') = 0 and pg_temp.bal('1000') = 35000, 'voided expense reversed');
-- Nobody said where it was paid from: "Needs review", never guessed.
select public.record_expense('Transport', 3000, current_date, null, null);
select pg_temp.check(pg_temp.bal('5900') = 3000 and pg_temp.bal('1999') = -3000, 'unknown source goes to Needs review');
select pg_temp.expect_error($q$select public.record_expense('x', 10, current_date, null, null, null,
  pg_temp.acct('1000'))$q$, 'expense account');

-- ------------------------------------------------------ staff actions --
-- Opening balances come from staff, and can be corrected.
select public.ledger_set_opening_balance(pg_temp.acct('1010'), 500000, current_date - 30);
select public.ledger_set_opening_balance(pg_temp.acct('1010'), 400000, current_date - 30);
select pg_temp.check(pg_temp.bal('1010') = 400000 and pg_temp.bal('3000') = 400000, 'corrected opening balance');
select pg_temp.check((public.ledger_overview()->>'opening_entered')::boolean, 'opening balances entered');

-- Moving money between own accounts, with a charge.
select public.ledger_transfer(pg_temp.acct('1010'), pg_temp.acct('1000'), 100000,
  current_date, 'Withdrawal', 1000);
select pg_temp.check(pg_temp.bal('1010') = 299000 and pg_temp.bal('1000') = 135000
  and pg_temp.bal('5000') = 2830, 'transfer with its charge');
select pg_temp.expect_error($q$select public.ledger_transfer(pg_temp.acct('1010'),
  pg_temp.acct('1010'), 1, current_date)$q$, 'different');

-- A loan received and part repaid; a donation.
select public.ledger_money_in(pg_temp.acct('1010'), pg_temp.acct('2100'), 200000, current_date, 'Loan');
select public.ledger_money_out(pg_temp.acct('1010'), pg_temp.acct('2100'), 50000, current_date, 'Repayment');
select public.ledger_money_in(pg_temp.acct('1030'), pg_temp.acct('4100'), 25000, current_date, 'Donation');
select pg_temp.check(pg_temp.bal('2100') = 150000 and pg_temp.bal('4100') = 25000, 'loan and donation');

-- Manual entries must balance; staff entries can be reversed, automatic ones not.
select pg_temp.expect_error($q$select public.ledger_post_journal(current_date, 'bad', jsonb_build_array(
  jsonb_build_object('account_id', pg_temp.acct('1000'), 'debit', 10),
  jsonb_build_object('account_id', pg_temp.acct('5900'), 'credit', 9)))$q$, 'must be equal');
select set_config('lg.manual', public.ledger_post_journal(current_date, 'Reclassify', jsonb_build_array(
  jsonb_build_object('account_id', pg_temp.acct('1999'), 'debit', 3000),
  jsonb_build_object('account_id', pg_temp.acct('1000'), 'credit', 3000)))::text, true);
select pg_temp.check(pg_temp.bal('1999') = 0, 'Needs review cleared by a journal entry');
select public.ledger_reverse(current_setting('lg.manual')::uuid, 'wrong account');
select pg_temp.check(pg_temp.bal('1999') = -3000, 'manual entry reversed');
select pg_temp.expect_error($q$select public.ledger_reverse(current_setting('lg.manual')::uuid, 'again')$q$, 'already');
select pg_temp.expect_error(format($q$select public.ledger_reverse(%L, 'no')$q$,
  (select id from journal_entries where source_type = 'payment' limit 1)), 'where it came from');

-- Bills: owed, paid in part, never overpaid, not voided once paid.
select set_config('lg.bill', public.ledger_record_bill('Landlord', pg_temp.acct('5400'), 80000,
  current_date, current_date + 10, 'October rent')::text, true);
select pg_temp.check(pg_temp.bal('2000') = 80000 and pg_temp.bal('5400') = 80000, 'bill owed');
select public.ledger_pay_bill(current_setting('lg.bill')::uuid, pg_temp.acct('1010'), 30000, current_date);
select pg_temp.check(pg_temp.bal('2000') = 50000, 'part paid');
select pg_temp.expect_error($q$select public.ledger_pay_bill(current_setting('lg.bill')::uuid,
  pg_temp.acct('1010'), 60000, current_date)$q$, 'still owed');
select pg_temp.expect_error($q$select public.ledger_void_bill(current_setting('lg.bill')::uuid, 'x')$q$, 'part of this bill');
select pg_temp.check((public.ledger_bills()->0->>'owed')::numeric = 50000, 'bill list shows what is owed');

-- An asset and its monthly wear (once per month however often it runs).
select public.ledger_record_asset('Laptop', 1200000, date_trunc('month', current_date)::date - 40,
  pg_temp.acct('1010'), 24);
select public.ledger_post_depreciation(current_date - 31);
select public.ledger_post_depreciation(current_date - 31);
select pg_temp.check(pg_temp.bal('5800') = 50000 and pg_temp.bal('1590') = -50000, 'one month of depreciation, once');
select pg_temp.check((public.ledger_assets()->0->>'value')::numeric = 1150000, 'asset written-down value');

-- Counting cash: a shortfall explained and posted.
select public.ledger_reconcile(pg_temp.acct('1000'), current_date, pg_temp.bal('1000') - 2000,
  'Change given wrongly', true);
select pg_temp.check(pg_temp.bal('5950') = 2000, 'shortfall posted to Cash differences');
select pg_temp.check((public.ledger_reconciliations()->0->>'difference')::numeric = -2000, 'reconciliation kept');

-- Budgets against actual.
select public.ledger_set_budget(pg_temp.acct('5400'), current_date, 70000);
select pg_temp.check((select (r->>'budget')::numeric = 70000 and (r->>'actual')::numeric = 80000
  from jsonb_array_elements(public.ledger_budget_report(date_trunc('month', current_date)::date, current_date)) r
  where r->>'code' = '5400'), 'rent: budget 70,000, actual 80,000');

-- --------------------------------------------------------- reports add up --
select pg_temp.check((select sum(debit) = sum(credit) from public.ledger_balances()), 'trial balance balances');
select pg_temp.check((select (b->>'total_assets')::numeric = (b->>'total_liabilities')::numeric
                             + (b->>'total_equity')::numeric from public.ledger_balance_sheet() b),
  'balance sheet: assets = liabilities + equity');
select pg_temp.check((select (s->>'surplus')::numeric = (s->>'total_income')::numeric - (s->>'total_expenses')::numeric
                      from public.ledger_income_statement(current_date - 60, current_date) s), 'surplus = income - expenses');
select pg_temp.check((select (c->>'closing')::numeric = (c->>'opening')::numeric + (c->>'total_in')::numeric
                             - (c->>'total_out')::numeric from public.ledger_cash_flow(current_date - 7, current_date) c),
  'cash flow: closing = opening + in - out');
select pg_temp.check((public.ledger_overview()->>'money_total')::numeric
  = (select sum(balance) from public.ledger_balances() where is_money), 'what we have = the money accounts');
select pg_temp.check((select (s->'lines'->-1->>'running')::numeric
                             = (select balance from public.ledger_balances() where code = '1010')
                      from public.ledger_statement(pg_temp.acct('1010')) s), 'statement running balance');
select pg_temp.check(jsonb_array_length(public.ledger_journal(null, null, 'transfer')) = 1, 'journal filter');

-- ------------------------------------------------------ closed months --
select public.ledger_close_books(current_date - 1);
select pg_temp.expect_error($q$select public.ledger_money_in(pg_temp.acct('1000'),
  pg_temp.acct('4100'), 100, current_date - 5, 'late')$q$, 'closed');
reset role;
-- A payment verified now for an old date lands on the first open day.
insert into payments (id, user_id, course_id, amount, currency, method, status, verified_at, paid_on)
values ('00000000-0000-0000-0000-000000102002', current_setting('lg.learner')::uuid,
        '00000000-0000-0000-0000-000000101001', 1000, 'UGX', 'cash', 'verified', now(), current_date - 20);
select pg_temp.check((select entry_date = current_date from journal_entries
                      where source_id = '00000000-0000-0000-0000-000000102002' and source_event = 'receipt'),
  'late automatic posting lands after the closed date');
select pg_temp.login_as_id(current_setting('lg.fin')::uuid);
set local role authenticated;
select public.ledger_close_books(null); -- reopened (later test files post old dates)
reset role;

-- --------------------------------------------------- the books are permanent --
select pg_temp.expect_error($q$update journal_lines set debit = debit + 1 where debit > 0$q$, 'cannot be changed');
select pg_temp.expect_error($q$delete from journal_entries$q$, 'cannot be changed');
-- An unbalanced entry inserted around the functions is refused at commit.
insert into journal_entries (id, entry_date, memo, source_type)
values ('00000000-0000-0000-0000-000000103001', current_date, 'raw', 'manual');
insert into journal_lines (entry_id, account_id, debit)
values ('00000000-0000-0000-0000-000000103001', pg_temp.acct('1000'), 5);
select pg_temp.expect_error($q$set constraints journal_lines_balanced immediate$q$, 'does not balance');
