-- Phase 6, Stage 3-4: double-entry books for Almuntahha.
--
-- Every shilling Sidra knows about is a balanced journal entry (debits =
-- credits) on a chart of accounts. Payments, MarzPay's own fees, refunds,
-- reversals, expenses and real-money MarzPay tests post themselves; staff
-- post opening balances, transfers, money in/out, bills, assets and manual
-- entries. Entries are never edited or deleted: a mistake is corrected by a
-- reversing entry.
--
-- Decisions (defaults, changeable later; nothing here invents money):
-- * Cash basis: income is counted when money is received. What learners
--   still owe is shown from course balances, not posted.
-- * Money accounts start at 0. Their real starting amounts are entered as
--   opening balances by staff (Finance > Accounts), never assumed.
-- * MarzPay: the ledger counts Almuntahha's own MarzPay movements (its
--   references). The MarzPay account is shared with DRAIS, so MarzPay's
--   dashboard total is not Almuntahha's money.
-- * MarzPay fees: the amount MarzPay actually charged on each collection
--   (recorded by the payments Worker), never an assumed rate.
-- * Real-money MarzPay tests go to 2090 "Test money", not income.
-- * One currency (the organisation currency, UGX). Anything in another
--   currency is listed under "Not in the books" instead of being converted.
-- * Months are closed by staff when they choose; closed months take no new
--   manual entries, and automatic entries for them land in the next open day.

insert into permissions (key, area, description) values
  ('finance.post_journal', 'finance', 'Post journal entries, opening balances, transfers, bills and money in or out'),
  ('finance.manage_accounts', 'finance', 'Manage accounts, budgets and assets; reconcile and close months')
on conflict (key) do nothing;
insert into role_permissions (role_key, permission_key)
select r, p from (values
  ('super_admin', 'finance.post_journal'), ('super_admin', 'finance.manage_accounts'),
  ('admin', 'finance.post_journal'), ('admin', 'finance.manage_accounts'),
  ('finance_officer', 'finance.post_journal'), ('finance_officer', 'finance.manage_accounts')) v(r, p)
where exists (select 1 from app_roles where key = r)
on conflict do nothing;

-- ------------------------------------------------------------- accounts --

create table ledger_accounts (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[0-9]{3,6}$'),
  name text not null check (length(trim(name)) between 1 and 80),
  type text not null check (type in ('asset', 'liability', 'equity', 'income', 'expense')),
  -- Cash, bank and wallets: "what Almuntahha has".
  is_money boolean not null default false check (not is_money or type = 'asset'),
  is_system boolean not null default false,
  is_active boolean not null default true,
  description text,
  created_at timestamptz not null default now()
);

insert into ledger_accounts (code, name, type, is_money, is_system, description) values
  ('1000', 'Cash on hand', 'asset', true, true, 'Notes and coins held by the organisation.'),
  ('1010', 'Bank account', 'asset', true, true, 'The organisation''s bank account.'),
  ('1020', 'MarzPay wallet', 'asset', true, true,
   'Almuntahha''s share of the MarzPay account (shared with DRAIS): its own collections less fees and payouts.'),
  ('1030', 'Mobile money line', 'asset', true, true,
   'Payments sent directly to the organisation''s mobile money number.'),
  ('1500', 'Equipment and furniture', 'asset', false, true, 'Things bought to use for years.'),
  ('1590', 'Accumulated depreciation', 'asset', false, true, 'Wear of equipment, written off month by month (negative).'),
  ('1999', 'Needs review', 'asset', false, true,
   'Money whose account is not known yet (for example a payment marked "other"). Move it with a journal entry.'),
  ('2000', 'Bills to pay', 'liability', false, true, 'Bills received and not yet paid.'),
  ('2090', 'Test money', 'liability', false, true, 'Real-money MarzPay tests: not income.'),
  ('2100', 'Loans received', 'liability', false, true, 'Money borrowed, to be paid back.'),
  ('3000', 'Opening balances', 'equity', false, true, 'The other side of the starting amounts entered.'),
  ('3100', 'Accumulated surplus', 'equity', false, true, 'Surplus of earlier years.'),
  ('4000', 'Course fees', 'income', false, true, 'Fees received from learners.'),
  ('4090', 'Refunds', 'income', false, true, 'Fees given back (reduces income).'),
  ('4100', 'Donations and other income', 'income', false, true, null),
  ('5000', 'Payment provider fees', 'expense', false, true, 'What MarzPay and others charge per transaction.'),
  ('5100', 'Teacher allowances and salaries', 'expense', false, true, null),
  ('5200', 'Internet and airtime', 'expense', false, true, null),
  ('5300', 'Hosting and software', 'expense', false, true, null),
  ('5400', 'Rent and utilities', 'expense', false, true, null),
  ('5500', 'Learning materials', 'expense', false, true, null),
  ('5600', 'Transport', 'expense', false, true, null),
  ('5800', 'Depreciation', 'expense', false, true, null),
  ('5900', 'Other expenses', 'expense', false, true, null),
  ('5950', 'Cash differences', 'expense', false, true, 'Differences found when counting or reconciling money.');

-- ------------------------------------------------------------- journal --

create table journal_entries (
  id uuid primary key default gen_random_uuid(),
  number bigint generated always as identity unique,
  entry_date date not null,
  memo text not null check (length(trim(memo)) between 1 and 300),
  source_type text not null check (source_type in (
    'payment', 'refund', 'expense', 'test', 'opening', 'transfer', 'money_in', 'money_out',
    'bill', 'bill_payment', 'asset', 'depreciation', 'reconciliation', 'manual', 'reversal')),
  source_id uuid,
  -- What happened to the source: receipt, fee, reversal, refund, …
  source_event text,
  reverses uuid references journal_entries (id),
  created_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now()
);
-- An automatic posting happens once, however often its trigger fires.
create unique index journal_entries_once
  on journal_entries (source_type, source_id, source_event)
  where source_id is not null and source_event is not null;
create unique index journal_entries_reversed_once on journal_entries (reverses) where reverses is not null;
create index journal_entries_date on journal_entries (entry_date desc, number desc);

create table journal_lines (
  id uuid primary key default gen_random_uuid(),
  entry_id uuid not null references journal_entries (id) on delete restrict,
  account_id uuid not null references ledger_accounts (id) on delete restrict,
  debit numeric(14, 2) not null default 0 check (debit >= 0),
  credit numeric(14, 2) not null default 0 check (credit >= 0),
  check ((debit > 0) <> (credit > 0)),
  memo text,
  user_id uuid references users (id) on delete set null,
  course_id uuid references courses (id) on delete set null
);
create index journal_lines_account on journal_lines (account_id);
create index journal_lines_entry on journal_lines (entry_id);

-- Every entry balances (checked at commit, after all its lines are in).
create or replace function app_private.journal_balanced()
returns trigger
language plpgsql
set search_path = public, app_private, pg_temp
as $$
declare v_dr numeric; v_cr numeric; v_n int;
begin
  select coalesce(sum(debit), 0), coalesce(sum(credit), 0), count(*)
  into v_dr, v_cr, v_n from journal_lines where entry_id = new.entry_id;
  if v_n < 2 or v_dr <> v_cr then
    raise exception 'journal entry does not balance (debits %, credits %)', v_dr, v_cr
      using errcode = 'PT422';
  end if;
  return null;
end;
$$;
create constraint trigger journal_lines_balanced
  after insert on journal_lines deferrable initially deferred
  for each row execute function app_private.journal_balanced();

-- The books are permanent. The only change allowed is the database
-- clearing a person or course link when that person/course is deleted.
create or replace function app_private.journal_immutable()
returns trigger
language plpgsql
set search_path = public, app_private, pg_temp
as $$
declare
  v_links text[] := case tg_table_name when 'journal_lines' then array['user_id', 'course_id']
                         else array['created_by'] end;
  v_new jsonb;
  v_old jsonb;
  k text;
begin
  if tg_op = 'UPDATE' then
    v_new := to_jsonb(new);
    v_old := to_jsonb(old);
    if (v_new - v_links) = (v_old - v_links) then
      -- only links changed: allowed when each was cleared or kept
      foreach k in array v_links loop
        if v_new->k <> 'null'::jsonb and v_new->k is distinct from v_old->k then
          raise exception 'the books cannot be changed; post a reversing entry instead'
            using errcode = 'PT409';
        end if;
      end loop;
      return new;
    end if;
  end if;
  raise exception 'the books cannot be changed; post a reversing entry instead'
    using errcode = 'PT409';
end;
$$;
create trigger journal_entries_immutable before update or delete on journal_entries
  for each row execute function app_private.journal_immutable();
create trigger journal_lines_immutable before update or delete on journal_lines
  for each row execute function app_private.journal_immutable();

-- --------------------------------------------------- staff-kept records --

create table bills (
  id uuid primary key default gen_random_uuid(),
  supplier text not null check (length(trim(supplier)) between 1 and 120),
  description text,
  account_id uuid not null references ledger_accounts (id),
  amount numeric(14, 2) not null check (amount > 0),
  bill_date date not null,
  due_date date,
  voided_at timestamptz,
  void_reason text,
  recorded_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now()
);

create table bill_payments (
  id uuid primary key default gen_random_uuid(),
  bill_id uuid not null references bills (id),
  from_account_id uuid not null references ledger_accounts (id),
  amount numeric(14, 2) not null check (amount > 0),
  paid_on date not null,
  recorded_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now()
);

create table fixed_assets (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 120),
  cost numeric(14, 2) not null check (cost > 0),
  purchased_on date not null,
  paid_from_account_id uuid references ledger_accounts (id),
  -- Spread over this many months (straight line); null = not depreciated.
  useful_life_months int check (useful_life_months between 1 and 600),
  disposed_on date,
  note text,
  recorded_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now()
);

create table budgets (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references ledger_accounts (id),
  month date not null check (extract(day from month) = 1),
  amount numeric(14, 2) not null check (amount >= 0),
  set_by uuid references users (id) on delete set null,
  updated_at timestamptz not null default now(),
  unique (account_id, month)
);

create table reconciliations (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references ledger_accounts (id),
  as_of date not null,
  counted numeric(14, 2) not null,
  books numeric(14, 2) not null,
  difference numeric(14, 2) not null,
  note text,
  adjustment_entry_id uuid references journal_entries (id),
  done_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now()
);

alter table expenses
  add column account_id uuid references ledger_accounts (id),
  add column paid_from_account_id uuid references ledger_accounts (id);

-- Only finance staff read the books; nobody writes them except through the
-- functions below.
do $$
declare t text;
begin
  foreach t in array array['ledger_accounts', 'journal_entries', 'journal_lines', 'bills',
                           'bill_payments', 'fixed_assets', 'budgets', 'reconciliations'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy %I on %I for select to public using (app_private.has_permission(''finance.view''))',
                   t || '_read', t);
    execute format('grant select on %I to authenticated, sidra_app', t);
  end loop;
  foreach t in array array['ledger_accounts', 'journal_entries', 'bills', 'bill_payments',
                           'fixed_assets', 'budgets', 'reconciliations'] loop
    execute format('create trigger %I after insert or update on %I
                    for each row execute function app_private.audit()', t || '_audit', t);
  end loop;
end $$;

-- ------------------------------------------------------------- helpers --

create or replace function app_private.ledger_currency()
returns text
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$ select coalesce((select value from org_settings where key = 'currency'), 'UGX') $$;

create or replace function app_private.books_closed_through()
returns date
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case when value ~ '^\d{4}-\d{2}-\d{2}$' then value::date end
  from org_settings where key = 'books_closed_through'
$$;

create or replace function app_private.account_id(p_code text)
returns uuid
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$ select id from ledger_accounts where code = p_code $$;

-- Where money received by each payment method lands.
create or replace function app_private.money_account_for(p_method payment_method)
returns uuid
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.account_id(case p_method
    when 'marzpay' then '1020' when 'mobile_money' then '1030'
    when 'bank' then '1010' when 'cash' then '1000' else '1999' end)
$$;

-- Posts one balanced entry. p_lines: [{account_id, debit, credit, memo,
-- user_id, course_id}]. Automatic postings (p_source_id + p_event) happen
-- once: a repeat returns the existing entry. Manual entries may not be
-- dated in a closed month; automatic ones move to the first open day.
create or replace function app_private.post_entry(
  p_date date, p_memo text, p_source_type text, p_source_id uuid, p_event text,
  p_lines jsonb, p_reverses uuid default null, p_manual boolean default false)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_id uuid;
  v_closed date := app_private.books_closed_through();
  v_date date := coalesce(p_date, current_date);
  v_line jsonb;
begin
  if p_source_id is not null and p_event is not null then
    select id into v_id from journal_entries
    where source_type = p_source_type and source_id = p_source_id and source_event = p_event;
    if found then return v_id; end if;
  end if;
  if v_closed is not null and v_date <= v_closed then
    if p_manual then
      raise exception 'the books are closed up to %; choose a later date', v_closed
        using errcode = 'PT409';
    end if;
    v_date := v_closed + 1;
  end if;
  insert into journal_entries (entry_date, memo, source_type, source_id, source_event, reverses, created_by)
  values (v_date, left(trim(p_memo), 300), p_source_type, p_source_id, p_event, p_reverses,
          app_private.current_user_id())
  returning id into v_id;
  for v_line in select * from jsonb_array_elements(p_lines) loop
    if coalesce((v_line->>'debit')::numeric, 0) = 0 and coalesce((v_line->>'credit')::numeric, 0) = 0 then
      continue; -- a zero line (e.g. no fee) is simply left out
    end if;
    insert into journal_lines (entry_id, account_id, debit, credit, memo, user_id, course_id)
    values (v_id, (v_line->>'account_id')::uuid,
            round(coalesce((v_line->>'debit')::numeric, 0), 2),
            round(coalesce((v_line->>'credit')::numeric, 0), 2),
            nullif(v_line->>'memo', ''),
            (v_line->>'user_id')::uuid, (v_line->>'course_id')::uuid);
  end loop;
  if (select count(*) from journal_lines where entry_id = v_id) < 2 then
    raise exception 'a journal entry needs at least two lines' using errcode = 'PT422';
  end if;
  if (select sum(debit) <> sum(credit) from journal_lines where entry_id = v_id) then
    raise exception 'journal entry does not balance' using errcode = 'PT422';
  end if;
  return v_id;
end;
$$;

create or replace function app_private.line(
  p_account uuid, p_debit numeric, p_credit numeric,
  p_user uuid default null, p_course uuid default null, p_memo text default null)
returns jsonb
language sql immutable
as $$
  select jsonb_build_object('account_id', p_account, 'debit', coalesce(p_debit, 0),
    'credit', coalesce(p_credit, 0), 'user_id', p_user, 'course_id', p_course, 'memo', p_memo)
$$;

-- The opposite of an entry (same accounts, sides swapped).
create or replace function app_private.reverse_entry(
  p_entry uuid, p_memo text, p_source_type text default 'reversal',
  p_source_id uuid default null, p_event text default null,
  p_date date default null, p_manual boolean default false)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_existing uuid;
begin
  select id into v_existing from journal_entries where reverses = p_entry;
  if found then return v_existing; end if;
  return app_private.post_entry(
    coalesce(p_date, current_date), p_memo, p_source_type, p_source_id, p_event,
    (select jsonb_agg(app_private.line(account_id, credit, debit, user_id, course_id, memo))
     from journal_lines where entry_id = p_entry),
    p_entry, p_manual);
end;
$$;

-- ------------------------------------------------- automatic postings --

-- A payment's postings follow its state: received → receipt (+ MarzPay's
-- fee once known); reversed → the receipt is reversed. Safe to call again.
create or replace function app_private.ledger_post_payment(p_payment uuid)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  p payments%rowtype;
  v_money uuid;
  v_receipt uuid;
  v_who text;
begin
  select * into p from payments where id = p_payment;
  if not found or p.currency <> app_private.ledger_currency() then return; end if;
  if p.status not in ('verified', 'reversed') or p.verified_at is null then return; end if;
  v_money := app_private.money_account_for(p.method);
  select coalesce(display_name, 'learner') into v_who from users where id = p.user_id;
  v_receipt := app_private.post_entry(
    coalesce(p.paid_on, p.verified_at::date),
    format('Course fee from %s (%s)', coalesce(v_who, 'learner'), p.method),
    'payment', p.id, 'receipt',
    jsonb_build_array(
      app_private.line(v_money, p.amount, 0, p.user_id, p.course_id),
      app_private.line(app_private.account_id('4000'), 0, p.amount, p.user_id, p.course_id)));
  if coalesce(p.provider_fee, 0) > 0 then
    perform app_private.post_entry(
      coalesce(p.paid_on, p.verified_at::date),
      format('%s fee on a course fee', initcap(coalesce(p.provider, p.method::text))),
      'payment', p.id, 'fee',
      jsonb_build_array(
        app_private.line(app_private.account_id('5000'), p.provider_fee, 0, p.user_id, p.course_id),
        app_private.line(v_money, 0, p.provider_fee, p.user_id, p.course_id)));
  end if;
  if p.status = 'reversed' then
    perform app_private.reverse_entry(
      v_receipt, 'Payment reversed: ' || coalesce(p.status_reason, ''), 'payment', p.id, 'reversal');
  end if;
end;
$$;

create or replace function app_private.ledger_post_refund(p_refund uuid)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare r refunds%rowtype; p payments%rowtype;
begin
  select * into r from refunds where id = p_refund;
  select * into p from payments where id = r.payment_id;
  if not found or p.currency <> app_private.ledger_currency() then return; end if;
  perform app_private.post_entry(
    r.created_at::date, 'Refund: ' || coalesce(r.reason, ''), 'refund', r.id, 'refund',
    jsonb_build_array(
      app_private.line(app_private.account_id('4090'), r.amount, 0, p.user_id, p.course_id),
      app_private.line(app_private.money_account_for(p.method), 0, r.amount, p.user_id, p.course_id)));
end;
$$;

-- An expense: its account (or "Other expenses") against where it was paid
-- from (or "Needs review" when nobody said). Voided → reversed.
create or replace function app_private.ledger_post_expense(p_expense uuid)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare e expenses%rowtype; v_entry uuid;
begin
  select * into e from expenses where id = p_expense;
  if not found or e.currency <> app_private.ledger_currency() then return; end if;
  if e.voided_at is not null
     and not exists (select 1 from journal_entries where source_type = 'expense'
                     and source_id = e.id and source_event = 'expense') then
    return; -- voided before it was ever in the books
  end if;
  v_entry := app_private.post_entry(
    e.spent_on, concat_ws(': ', e.category, coalesce(e.payee, e.description)),
    'expense', e.id, 'expense',
    jsonb_build_array(
      app_private.line(coalesce(e.account_id, app_private.account_id('5900')), e.amount, 0),
      app_private.line(coalesce(e.paid_from_account_id, app_private.account_id('1999')), 0, e.amount)));
  if e.voided_at is not null then
    perform app_private.reverse_entry(
      v_entry, 'Expense voided: ' || coalesce(e.void_reason, ''), 'expense', e.id, 'void');
  end if;
end;
$$;

-- Real-money MarzPay tests that succeeded: the money moved, but it is not
-- income; it sits in "Test money".
create or replace function app_private.ledger_post_test(p_test uuid)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  t payment_tests%rowtype;
  v_amount numeric;
  v_fee numeric;
begin
  select * into t from payment_tests where id = p_test;
  if not found or not t.real_money or t.result is distinct from 'verified_success'
     or t.kind not in ('collection', 'disbursement') then
    return;
  end if;
  v_amount := case when t.params->>'amount' ~ '^\d+(\.\d+)?$' then (t.params->>'amount')::numeric end;
  if v_amount is null then return; end if;
  perform app_private.post_entry(
    coalesce(t.finished_at, t.created_at)::date,
    format('MarzPay test %s', t.kind), 'test', t.id, 'money',
    case when t.kind = 'collection' then jsonb_build_array(
      app_private.line(app_private.account_id('1020'), v_amount, 0),
      app_private.line(app_private.account_id('2090'), 0, v_amount))
    else jsonb_build_array(
      app_private.line(app_private.account_id('2090'), v_amount, 0),
      app_private.line(app_private.account_id('1020'), 0, v_amount)) end);
  v_fee := case when t.evidence->>'fee' ~ '^\d+(\.\d+)?$' then (t.evidence->>'fee')::numeric end;
  if coalesce(v_fee, 0) > 0 then
    perform app_private.post_entry(
      coalesce(t.finished_at, t.created_at)::date, 'MarzPay fee on a test', 'test', t.id, 'fee',
      jsonb_build_array(
        app_private.line(app_private.account_id('5000'), v_fee, 0),
        app_private.line(app_private.account_id('1020'), 0, v_fee)));
  end if;
end;
$$;

create or replace function app_private.ledger_on_payment() returns trigger
language plpgsql security definer set search_path = public, app_private, pg_temp
as $$ begin perform app_private.ledger_post_payment(new.id); return null; end $$;
create or replace function app_private.ledger_on_refund() returns trigger
language plpgsql security definer set search_path = public, app_private, pg_temp
as $$ begin perform app_private.ledger_post_refund(new.id); return null; end $$;
create or replace function app_private.ledger_on_expense() returns trigger
language plpgsql security definer set search_path = public, app_private, pg_temp
as $$ begin perform app_private.ledger_post_expense(new.id); return null; end $$;
create or replace function app_private.ledger_on_test() returns trigger
language plpgsql security definer set search_path = public, app_private, pg_temp
as $$ begin perform app_private.ledger_post_test(new.id); return null; end $$;

create trigger payments_ledger after insert or update of status, provider_fee, verified_at on payments
  for each row execute function app_private.ledger_on_payment();
create trigger refunds_ledger after insert on refunds
  for each row execute function app_private.ledger_on_refund();
create trigger expenses_ledger after insert or update of voided_at on expenses
  for each row execute function app_private.ledger_on_expense();
create trigger payment_tests_ledger after insert or update of result on payment_tests
  for each row execute function app_private.ledger_on_test();

-- Expenses say which account they are and where they were paid from.
drop function if exists public.record_expense(text, numeric, date, text, text, text);
create or replace function public.record_expense(
  p_category text, p_amount numeric, p_spent_on date,
  p_description text default null, p_payee text default null, p_currency text default null,
  p_account_id uuid default null, p_paid_from_account_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v expenses%rowtype; a ledger_accounts%rowtype;
begin
  perform app_private.require('finance.record_expense');
  if p_account_id is not null then
    select * into a from ledger_accounts where id = p_account_id and is_active;
    if not found or a.type not in ('expense', 'asset') or a.is_money then
      raise exception 'choose an expense account' using errcode = 'PT422';
    end if;
  end if;
  if p_paid_from_account_id is not null and not exists (
       select 1 from ledger_accounts where id = p_paid_from_account_id and is_active
         and (is_money or code = '2000')) then
    raise exception 'choose where the money came from' using errcode = 'PT422';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'enter an amount' using errcode = 'PT422';
  end if;
  insert into expenses (category, description, payee, amount, currency, spent_on, recorded_by,
                        account_id, paid_from_account_id)
  values (coalesce(nullif(trim(p_category), ''), a.name, 'Other'), p_description, p_payee, p_amount,
          coalesce(p_currency, app_private.ledger_currency()),
          coalesce(p_spent_on, current_date), app_private.current_user_id(),
          p_account_id, p_paid_from_account_id)
  returning * into v;
  return to_jsonb(v);
end;
$$;

select app_private.lock_down_functions();
