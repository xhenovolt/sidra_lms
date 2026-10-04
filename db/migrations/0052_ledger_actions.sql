-- Phase 6, Stages 5-6: what finance staff do with the books (0051), and the
-- reports they read.

-- ------------------------------------------------------ staff actions --

create or replace function app_private.require_account(
  p_id uuid, p_types text[], p_money boolean default null, p_what text default 'account')
returns ledger_accounts
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare a ledger_accounts%rowtype;
begin
  select * into a from ledger_accounts where id = p_id and is_active;
  if not found or not (a.type = any (p_types)) or (p_money is not null and a.is_money <> p_money) then
    raise exception 'choose a valid %', p_what using errcode = 'PT422';
  end if;
  return a;
end;
$$;

create or replace function app_private.require_amount(p_amount numeric)
returns void
language plpgsql immutable
as $$
begin
  if p_amount is null or p_amount <= 0 then
    raise exception 'enter an amount above 0' using errcode = 'PT422';
  end if;
end;
$$;

-- What an account held when the organisation started using Sidra's books.
-- Entered by staff from real records (cash count, bank statement, the
-- MarzPay share); changing it reverses the previous one.
create or replace function public.ledger_set_opening_balance(
  p_account_id uuid, p_amount numeric, p_as_of date)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare a ledger_accounts%rowtype; v_old uuid; v_amt numeric := round(coalesce(p_amount, -1), 2);
begin
  perform app_private.require('finance.post_journal');
  a := app_private.require_account(p_account_id, array['asset', 'liability', 'equity']);
  if a.code = '3000' or v_amt < 0 then
    raise exception 'enter the amount the account held (0 or more)' using errcode = 'PT422';
  end if;
  select e.id into v_old from journal_entries e
  where e.source_type = 'opening' and e.source_id = a.id
    and not exists (select 1 from journal_entries r where r.reverses = e.id)
  order by e.number desc limit 1;
  if v_old is not null then
    perform app_private.reverse_entry(v_old, 'Opening balance changed: ' || a.name,
                                      p_date => p_as_of, p_manual => true);
  end if;
  if v_amt = 0 then return null; end if;
  return app_private.post_entry(
    p_as_of, 'Opening balance: ' || a.name, 'opening', a.id, null,
    case when a.type = 'asset' and a.code <> '1590' then jsonb_build_array(
      app_private.line(a.id, v_amt, 0), app_private.line(app_private.account_id('3000'), 0, v_amt))
    else jsonb_build_array(
      app_private.line(app_private.account_id('3000'), v_amt, 0), app_private.line(a.id, 0, v_amt)) end,
    null, true);
end;
$$;

-- Money moved between two of the organisation's own accounts (e.g. MarzPay
-- withdrawn to the bank), with the charge if there was one.
create or replace function public.ledger_transfer(
  p_from uuid, p_to uuid, p_amount numeric, p_date date, p_memo text default null,
  p_fee numeric default null)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare f ledger_accounts%rowtype; t ledger_accounts%rowtype;
begin
  perform app_private.require('finance.post_journal');
  perform app_private.require_amount(p_amount);
  if coalesce(p_fee, 0) < 0 then raise exception 'the charge cannot be negative' using errcode = 'PT422'; end if;
  f := app_private.require_account(p_from, array['asset'], true, 'account to move money from');
  t := app_private.require_account(p_to, array['asset'], true, 'account to move money to');
  if f.id = t.id then raise exception 'choose two different accounts' using errcode = 'PT422'; end if;
  return app_private.post_entry(
    p_date, coalesce(nullif(trim(p_memo), ''), format('Moved from %s to %s', f.name, t.name)),
    'transfer', null, null,
    jsonb_build_array(
      app_private.line(t.id, p_amount, 0),
      app_private.line(app_private.account_id('5000'), coalesce(p_fee, 0), 0, null, null, 'Transfer charge'),
      app_private.line(f.id, 0, p_amount + coalesce(p_fee, 0))),
    null, true);
end;
$$;

-- Money received that is not a course fee: a donation (income), a loan
-- (liability) or money put in by the owners (equity).
create or replace function public.ledger_money_in(
  p_to uuid, p_source_account uuid, p_amount numeric, p_date date, p_memo text default null)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare t ledger_accounts%rowtype; s ledger_accounts%rowtype;
begin
  perform app_private.require('finance.post_journal');
  perform app_private.require_amount(p_amount);
  t := app_private.require_account(p_to, array['asset'], true, 'account the money went into');
  s := app_private.require_account(p_source_account, array['income', 'liability', 'equity'], false,
                                   'kind of money (income, loan or contribution)');
  return app_private.post_entry(
    p_date, coalesce(nullif(trim(p_memo), ''), s.name), 'money_in', null, null,
    jsonb_build_array(app_private.line(t.id, p_amount, 0), app_private.line(s.id, 0, p_amount)),
    null, true);
end;
$$;

-- Money paid out that is not a recorded expense or bill: repaying a loan
-- (liability), buying something kept (asset) or an expense paid at once.
create or replace function public.ledger_money_out(
  p_from uuid, p_target_account uuid, p_amount numeric, p_date date, p_memo text default null)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare f ledger_accounts%rowtype; t ledger_accounts%rowtype;
begin
  perform app_private.require('finance.post_journal');
  perform app_private.require_amount(p_amount);
  f := app_private.require_account(p_from, array['asset'], true, 'account the money came from');
  t := app_private.require_account(p_target_account, array['expense', 'liability', 'asset', 'equity'], false,
                                   'what the money was for');
  return app_private.post_entry(
    p_date, coalesce(nullif(trim(p_memo), ''), t.name), 'money_out', null, null,
    jsonb_build_array(app_private.line(t.id, p_amount, 0), app_private.line(f.id, 0, p_amount)),
    null, true);
end;
$$;

-- A journal entry written by the accountant: any balanced set of lines.
-- p_lines: [{account_id, debit, credit, memo}]
create or replace function public.ledger_post_journal(p_date date, p_memo text, p_lines jsonb)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_line jsonb; v_dr numeric := 0; v_cr numeric := 0; v_d numeric; v_c numeric;
begin
  perform app_private.require('finance.post_journal');
  if coalesce(trim(p_memo), '') = '' then
    raise exception 'describe the entry' using errcode = 'PT422';
  end if;
  if p_lines is null or jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) < 2 then
    raise exception 'an entry needs at least two lines' using errcode = 'PT422';
  end if;
  for v_line in select * from jsonb_array_elements(p_lines) loop
    perform app_private.require_account((v_line->>'account_id')::uuid,
      array['asset', 'liability', 'equity', 'income', 'expense']);
    v_d := coalesce((v_line->>'debit')::numeric, 0);
    v_c := coalesce((v_line->>'credit')::numeric, 0);
    if v_d < 0 or v_c < 0 or (v_d > 0) = (v_c > 0) then
      raise exception 'each line is either a debit or a credit' using errcode = 'PT422';
    end if;
    v_dr := v_dr + v_d;
    v_cr := v_cr + v_c;
  end loop;
  if round(v_dr, 2) <> round(v_cr, 2) then
    raise exception 'debits (%) and credits (%) must be equal', v_dr, v_cr using errcode = 'PT422';
  end if;
  return app_private.post_entry(
    p_date, p_memo, 'manual', null, null,
    (select jsonb_agg(app_private.line((l->>'account_id')::uuid, (l->>'debit')::numeric,
                                       (l->>'credit')::numeric, null, null, l->>'memo'))
     from jsonb_array_elements(p_lines) l),
    null, true);
end;
$$;

-- Undo an entry staff made. Automatic ones are undone where they came from
-- (reverse the payment, void the expense or bill).
create or replace function public.ledger_reverse(p_entry_id uuid, p_reason text, p_date date default null)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare e journal_entries%rowtype;
begin
  perform app_private.require('finance.post_journal');
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'give a reason' using errcode = 'PT422';
  end if;
  select * into e from journal_entries where id = p_entry_id;
  if not found then raise exception 'entry not found' using errcode = 'PT404'; end if;
  if e.source_type not in ('manual', 'transfer', 'money_in', 'money_out', 'opening', 'reconciliation') then
    raise exception 'this entry is undone where it came from (the payment, expense, bill or asset)'
      using errcode = 'PT409';
  end if;
  if e.reverses is not null or exists (select 1 from journal_entries where reverses = e.id) then
    raise exception 'this entry is already a reversal or reversed' using errcode = 'PT409';
  end if;
  return app_private.reverse_entry(e.id, 'Reversed: ' || trim(p_reason),
                                   p_date => coalesce(p_date, current_date), p_manual => true);
end;
$$;

-- Bills: owed when received, cleared when paid (in parts if need be).
create or replace function public.ledger_record_bill(
  p_supplier text, p_account_id uuid, p_amount numeric, p_bill_date date,
  p_due_date date default null, p_description text default null)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare a ledger_accounts%rowtype; v bills%rowtype;
begin
  perform app_private.require('finance.post_journal');
  perform app_private.require_amount(p_amount);
  if coalesce(trim(p_supplier), '') = '' then
    raise exception 'who is the bill from?' using errcode = 'PT422';
  end if;
  a := app_private.require_account(p_account_id, array['expense', 'asset'], false, 'what the bill is for');
  insert into bills (supplier, description, account_id, amount, bill_date, due_date, recorded_by)
  values (trim(p_supplier), p_description, a.id, p_amount, coalesce(p_bill_date, current_date), p_due_date,
          app_private.current_user_id())
  returning * into v;
  perform app_private.post_entry(
    v.bill_date, format('Bill from %s', v.supplier), 'bill', v.id, 'bill',
    jsonb_build_array(app_private.line(a.id, v.amount, 0),
                      app_private.line(app_private.account_id('2000'), 0, v.amount)),
    null, true);
  return v.id;
end;
$$;

create or replace function public.ledger_pay_bill(
  p_bill_id uuid, p_from uuid, p_amount numeric, p_paid_on date)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare b bills%rowtype; f ledger_accounts%rowtype; v_paid numeric; v_id uuid;
begin
  perform app_private.require('finance.post_journal');
  perform app_private.require_amount(p_amount);
  select * into b from bills where id = p_bill_id for update;
  if not found or b.voided_at is not null then
    raise exception 'bill not found' using errcode = 'PT404';
  end if;
  f := app_private.require_account(p_from, array['asset'], true, 'account the money came from');
  select coalesce(sum(amount), 0) into v_paid from bill_payments where bill_id = b.id;
  if v_paid + p_amount > b.amount then
    raise exception 'that is more than the % still owed', b.amount - v_paid using errcode = 'PT422';
  end if;
  insert into bill_payments (bill_id, from_account_id, amount, paid_on, recorded_by)
  values (b.id, f.id, p_amount, coalesce(p_paid_on, current_date), app_private.current_user_id())
  returning id into v_id;
  perform app_private.post_entry(
    coalesce(p_paid_on, current_date), format('Paid bill from %s', b.supplier), 'bill_payment', v_id, 'payment',
    jsonb_build_array(app_private.line(app_private.account_id('2000'), p_amount, 0),
                      app_private.line(f.id, 0, p_amount)),
    null, true);
  return v_id;
end;
$$;

create or replace function public.ledger_void_bill(p_bill_id uuid, p_reason text)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare b bills%rowtype;
begin
  perform app_private.require('finance.post_journal');
  if coalesce(trim(p_reason), '') = '' then raise exception 'give a reason' using errcode = 'PT422'; end if;
  select * into b from bills where id = p_bill_id and voided_at is null for update;
  if not found then raise exception 'bill not found' using errcode = 'PT404'; end if;
  if exists (select 1 from bill_payments where bill_id = b.id) then
    raise exception 'part of this bill is paid; it cannot be voided' using errcode = 'PT409';
  end if;
  update bills set voided_at = now(), void_reason = trim(p_reason) where id = b.id;
  perform app_private.reverse_entry(
    (select id from journal_entries where source_type = 'bill' and source_id = b.id and source_event = 'bill'),
    'Bill voided: ' || trim(p_reason), 'bill', b.id, 'void', current_date, true);
end;
$$;

-- Equipment and furniture: bought (from a money account, on a bill, or
-- already owned) and written off month by month over its useful life.
create or replace function public.ledger_record_asset(
  p_name text, p_cost numeric, p_purchased_on date, p_paid_from uuid,
  p_useful_life_months int default null, p_note text default null)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v fixed_assets%rowtype; f ledger_accounts%rowtype;
begin
  perform app_private.require('finance.manage_accounts');
  perform app_private.require_amount(p_cost);
  if coalesce(trim(p_name), '') = '' then
    raise exception 'name the item' using errcode = 'PT422';
  end if;
  select * into f from ledger_accounts
  where id = p_paid_from and is_active and (is_money or code in ('2000', '3000'));
  if not found then
    raise exception 'choose how it was paid for (a money account, a bill, or already owned)'
      using errcode = 'PT422';
  end if;
  insert into fixed_assets (name, cost, purchased_on, paid_from_account_id, useful_life_months, note, recorded_by)
  values (trim(p_name), p_cost, coalesce(p_purchased_on, current_date), f.id, p_useful_life_months, p_note,
          app_private.current_user_id())
  returning * into v;
  perform app_private.post_entry(
    v.purchased_on, 'Bought: ' || v.name, 'asset', v.id, 'purchase',
    jsonb_build_array(app_private.line(app_private.account_id('1500'), v.cost, 0),
                      app_private.line(f.id, 0, v.cost)),
    null, true);
  return v.id;
end;
$$;

-- Writes off one month of wear for every asset in use that month. Running
-- it again for the same month changes nothing.
create or replace function public.ledger_post_depreciation(p_month date)
returns int
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_month date := date_trunc('month', p_month)::date;
  v_end date := (date_trunc('month', p_month) + interval '1 month - 1 day')::date;
  a fixed_assets%rowtype;
  v_done numeric;
  v_amt numeric;
  n int := 0;
begin
  perform app_private.require('finance.manage_accounts');
  if v_month > date_trunc('month', current_date)::date then
    raise exception 'a month that has not started cannot be written off' using errcode = 'PT422';
  end if;
  for a in select * from fixed_assets
           where useful_life_months is not null and purchased_on <= v_end
             and (disposed_on is null or disposed_on >= v_month) loop
    continue when exists (select 1 from journal_entries where source_type = 'depreciation'
                          and source_id = a.id and source_event = to_char(v_month, 'YYYY-MM'));
    select coalesce(sum(l.credit), 0) into v_done
    from journal_entries e join journal_lines l on l.entry_id = e.id
    where e.source_type = 'depreciation' and e.source_id = a.id
      and l.account_id = app_private.account_id('1590');
    v_amt := least(round(a.cost / a.useful_life_months, 2), a.cost - v_done);
    if v_amt > 0 then
      perform app_private.post_entry(
        v_end, 'Depreciation: ' || a.name, 'depreciation', a.id, to_char(v_month, 'YYYY-MM'),
        jsonb_build_array(app_private.line(app_private.account_id('5800'), v_amt, 0),
                          app_private.line(app_private.account_id('1590'), 0, v_amt)));
      n := n + 1;
    end if;
  end loop;
  return n;
end;
$$;

-- Counting the money: what an account really holds (cash count, bank
-- statement, MarzPay share) against the books. The difference can be
-- posted to "Cash differences" with an explanation.
create or replace function public.ledger_reconcile(
  p_account_id uuid, p_as_of date, p_counted numeric, p_note text default null,
  p_post_difference boolean default false)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare a ledger_accounts%rowtype; v_books numeric; v_diff numeric; v_entry uuid; v reconciliations%rowtype;
begin
  perform app_private.require('finance.manage_accounts');
  a := app_private.require_account(p_account_id, array['asset'], true, 'money account');
  if p_counted is null then raise exception 'enter the amount counted' using errcode = 'PT422'; end if;
  select coalesce(sum(l.debit - l.credit), 0) into v_books
  from journal_lines l join journal_entries e on e.id = l.entry_id
  where l.account_id = a.id and e.entry_date <= coalesce(p_as_of, current_date);
  v_diff := round(p_counted - v_books, 2);
  if p_post_difference and v_diff <> 0 then
    if coalesce(trim(p_note), '') = '' then
      raise exception 'explain the difference before posting it' using errcode = 'PT422';
    end if;
    v_entry := app_private.post_entry(
      coalesce(p_as_of, current_date), format('Counted %s: %s', a.name, trim(p_note)), 'reconciliation',
      null, null,
      case when v_diff > 0 then jsonb_build_array(
        app_private.line(a.id, v_diff, 0), app_private.line(app_private.account_id('5950'), 0, v_diff))
      else jsonb_build_array(
        app_private.line(app_private.account_id('5950'), -v_diff, 0), app_private.line(a.id, 0, -v_diff)) end,
      null, true);
  end if;
  insert into reconciliations (account_id, as_of, counted, books, difference, note, adjustment_entry_id, done_by)
  values (a.id, coalesce(p_as_of, current_date), p_counted, v_books, v_diff, p_note, v_entry,
          app_private.current_user_id())
  returning * into v;
  return to_jsonb(v);
end;
$$;

create or replace function public.ledger_set_budget(p_account_id uuid, p_month date, p_amount numeric)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform app_private.require('finance.manage_accounts');
  perform app_private.require_account(p_account_id, array['income', 'expense']);
  if p_amount is null or p_amount < 0 then
    raise exception 'enter 0 or more' using errcode = 'PT422';
  end if;
  insert into budgets (account_id, month, amount, set_by)
  values (p_account_id, date_trunc('month', p_month)::date, p_amount, app_private.current_user_id())
  on conflict (account_id, month) do update
    set amount = excluded.amount, set_by = excluded.set_by, updated_at = now();
end;
$$;

-- Closing the books up to a day: no manual entry may be dated on or before
-- it. Reopening (an earlier day, or none) is allowed and logged.
create or replace function public.ledger_close_books(p_through date)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform app_private.require('finance.manage_accounts');
  if p_through is not null and p_through >= current_date then
    raise exception 'only past days can be closed' using errcode = 'PT422';
  end if;
  insert into org_settings (key, value, is_public, updated_by, updated_at)
  values ('books_closed_through', p_through::text, false, app_private.current_user_id(), now())
  on conflict (key) do update
    set value = excluded.value, updated_by = excluded.updated_by, updated_at = now();
  insert into audit_log (actor_id, action, entity, entity_id, changes)
  values (app_private.current_user_id(), 'books.close', 'org_settings', 'books_closed_through',
          jsonb_build_object('through', p_through));
end;
$$;

-- Add an account, or rename / describe / retire one. Built-in accounts
-- keep their number and kind; an account holding money can't be retired.
create or replace function public.ledger_save_account(
  p_id uuid, p_code text, p_name text, p_type text,
  p_is_money boolean default false, p_description text default null, p_is_active boolean default true)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare a ledger_accounts%rowtype; v_bal numeric;
begin
  perform app_private.require('finance.manage_accounts');
  if p_id is null then
    if exists (select 1 from ledger_accounts where code = trim(p_code)) then
      raise exception 'account number % is taken', trim(p_code) using errcode = 'PT409';
    end if;
    insert into ledger_accounts (code, name, type, is_money, description)
    values (trim(p_code), trim(p_name), p_type, coalesce(p_is_money, false), p_description)
    returning * into a;
    return a.id;
  end if;
  select * into a from ledger_accounts where id = p_id for update;
  if not found then raise exception 'account not found' using errcode = 'PT404'; end if;
  if a.is_system and (trim(p_code) <> a.code or p_type <> a.type or coalesce(p_is_money, false) <> a.is_money) then
    raise exception 'a built-in account keeps its number and kind' using errcode = 'PT409';
  end if;
  if a.type <> p_type and exists (select 1 from journal_lines where account_id = a.id) then
    raise exception 'an account with entries keeps its kind' using errcode = 'PT409';
  end if;
  if not coalesce(p_is_active, true) and a.is_active then
    select coalesce(sum(debit - credit), 0) into v_bal from journal_lines where account_id = a.id;
    if v_bal <> 0 then
      raise exception 'this account still holds %; move it first', abs(v_bal) using errcode = 'PT409';
    end if;
  end if;
  update ledger_accounts set code = trim(p_code), name = trim(p_name), type = p_type,
    is_money = coalesce(p_is_money, false), description = p_description,
    is_active = coalesce(p_is_active, true)
  where id = a.id;
  return a.id;
end;
$$;

-- ------------------------------------------------------------- reports --

-- Balance of each account (optionally between two days), on its natural
-- side: assets and expenses debit - credit; the others credit - debit.
create or replace function public.ledger_balances(p_as_of date default null, p_from date default null)
returns table (account_id uuid, code text, name text, type text, is_money boolean, is_active boolean,
               debit numeric, credit numeric, balance numeric)
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform app_private.require('finance.view');
  return query
  select a.id, a.code, a.name, a.type, a.is_money, a.is_active,
         coalesce(sum(m.debit), 0), coalesce(sum(m.credit), 0),
         case when a.type in ('asset', 'expense') then coalesce(sum(m.debit - m.credit), 0)
              else coalesce(sum(m.credit - m.debit), 0) end
  from ledger_accounts a
  left join (
    select l.account_id, l.debit, l.credit from journal_lines l
    join journal_entries e on e.id = l.entry_id
    where (p_as_of is null or e.entry_date <= p_as_of) and (p_from is null or e.entry_date >= p_from)
  ) m on m.account_id = a.id
  group by a.id
  order by a.code;
end;
$$;

-- The finance home: what Almuntahha has, this month's in and out, what is
-- owed both ways, and what needs attention.
create or replace function public.ledger_overview()
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_month date := date_trunc('month', current_date)::date;
  v jsonb;
begin
  perform app_private.require('finance.view');
  with b as (select * from public.ledger_balances()),
       m as (select * from public.ledger_balances(null, v_month))
  select jsonb_build_object(
    'currency', app_private.ledger_currency(),
    'closed_through', app_private.books_closed_through(),
    'money', coalesce((select jsonb_agg(jsonb_build_object('account_id', b.account_id, 'code', b.code,
                         'name', b.name, 'balance', b.balance) order by b.code)
                       from b where b.is_money and (b.is_active or b.balance <> 0)), '[]'),
    'money_total', (select coalesce(sum(b.balance), 0) from b where b.is_money),
    'test_money', (select b.balance from b where b.code = '2090'),
    'needs_review', (select b.balance from b where b.code = '1999'),
    'month_income', (select coalesce(sum(m.balance), 0) from m where m.type = 'income'),
    'month_expenses', (select coalesce(sum(m.balance), 0) from m where m.type = 'expense'),
    'owed_to_us', (select coalesce(sum(outstanding), 0) from public.finance_balances(null, true)),
    'bills_due', (select coalesce(sum(bl.amount - coalesce(p.paid, 0)), 0)
                  from bills bl left join (select bill_id, sum(amount) paid from bill_payments group by 1) p
                    on p.bill_id = bl.id
                  where bl.voided_at is null),
    'opening_entered', exists (select 1 from journal_entries where source_type = 'opening'),
    'not_in_books',
      (select count(*) from payments p
       where p.status = 'verified' and not exists (
         select 1 from journal_entries e where e.source_type = 'payment'
           and e.source_id = p.id and e.source_event = 'receipt'))
      + (select count(*) from expenses x
         where x.voided_at is null and not exists (
           select 1 from journal_entries e where e.source_type = 'expense'
             and e.source_id = x.id and e.source_event = 'expense'))
  ) into v;
  return v;
end;
$$;

-- One account's movements with a running balance.
create or replace function public.ledger_statement(
  p_account_id uuid, p_from date default null, p_to date default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare a ledger_accounts%rowtype; v_sign int; v_open numeric := 0;
begin
  perform app_private.require('finance.view');
  select * into a from ledger_accounts where id = p_account_id;
  if not found then raise exception 'account not found' using errcode = 'PT404'; end if;
  v_sign := case when a.type in ('asset', 'expense') then 1 else -1 end;
  if p_from is not null then
    select coalesce(sum(l.debit - l.credit), 0) * v_sign into v_open
    from journal_lines l join journal_entries e on e.id = l.entry_id
    where l.account_id = a.id and e.entry_date < p_from;
  end if;
  return jsonb_build_object(
    'account', to_jsonb(a),
    'opening', v_open,
    'lines', coalesce((
      select jsonb_agg(to_jsonb(x) order by x.entry_date, x.number, x.line_id)
      from (
        select e.id entry_id, e.number, e.entry_date, e.memo, e.source_type, l.id line_id,
               l.debit, l.credit, l.memo line_memo, u.display_name person,
               v_open + sum((l.debit - l.credit) * v_sign) over (order by e.entry_date, e.number, l.id) running
        from journal_lines l join journal_entries e on e.id = l.entry_id
        left join users u on u.id = l.user_id
        where l.account_id = a.id
          and (p_from is null or e.entry_date >= p_from)
          and (p_to is null or e.entry_date <= p_to)
      ) x), '[]'));
end;
$$;

-- The journal, newest first, each entry with its lines.
create or replace function public.ledger_journal(
  p_from date default null, p_to date default null, p_source_type text default null,
  p_limit int default 50, p_offset int default 0)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform app_private.require('finance.view');
  return coalesce((
    select jsonb_agg(to_jsonb(x) order by x.entry_date desc, x.number desc)
    from (
      select e.id, e.number, e.entry_date, e.memo, e.source_type, e.source_event, e.reverses,
             exists (select 1 from journal_entries r where r.reverses = e.id) reversed,
             u.display_name created_by,
             (select jsonb_agg(jsonb_build_object('code', a.code, 'account', a.name,
                       'debit', l.debit, 'credit', l.credit, 'memo', l.memo) order by l.debit desc, a.code)
              from journal_lines l join ledger_accounts a on a.id = l.account_id
              where l.entry_id = e.id) lines
      from journal_entries e left join users u on u.id = e.created_by
      where (p_from is null or e.entry_date >= p_from) and (p_to is null or e.entry_date <= p_to)
        and (p_source_type is null or e.source_type = p_source_type)
      order by e.entry_date desc, e.number desc
      limit least(greatest(coalesce(p_limit, 50), 1), 500) offset greatest(coalesce(p_offset, 0), 0)
    ) x), '[]');
end;
$$;

-- Income and expenses over a period (the surplus or deficit).
create or replace function public.ledger_income_statement(p_from date, p_to date)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare v jsonb;
begin
  perform app_private.require('finance.view');
  with b as (select * from public.ledger_balances(p_to, p_from) where type in ('income', 'expense'))
  select jsonb_build_object(
    'from', p_from, 'to', p_to, 'currency', app_private.ledger_currency(),
    'income', coalesce((select jsonb_agg(jsonb_build_object('account_id', account_id, 'code', code,
                 'name', name, 'amount', balance) order by code) from b where type = 'income' and balance <> 0), '[]'),
    'expenses', coalesce((select jsonb_agg(jsonb_build_object('account_id', account_id, 'code', code,
                 'name', name, 'amount', balance) order by code) from b where type = 'expense' and balance <> 0), '[]'),
    'total_income', (select coalesce(sum(balance), 0) from b where type = 'income'),
    'total_expenses', (select coalesce(sum(balance), 0) from b where type = 'expense'),
    'surplus', (select coalesce(sum(case when type = 'income' then balance else -balance end), 0) from b)
  ) into v;
  return v;
end;
$$;

-- What the organisation owns and owes on a day. Income less expenses not
-- yet moved to "Accumulated surplus" shows as the surplus so far.
create or replace function public.ledger_balance_sheet(p_as_of date default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare v jsonb;
begin
  perform app_private.require('finance.view');
  with b as (select * from public.ledger_balances(coalesce(p_as_of, current_date))),
       s as (select coalesce(sum(case when type = 'income' then balance when type = 'expense' then -balance end), 0) surplus_v from b)
  select jsonb_build_object(
    'as_of', coalesce(p_as_of, current_date), 'currency', app_private.ledger_currency(),
    'assets', coalesce((select jsonb_agg(jsonb_build_object('account_id', account_id, 'code', code,
                'name', name, 'amount', balance) order by code) from b where type = 'asset' and balance <> 0), '[]'),
    'liabilities', coalesce((select jsonb_agg(jsonb_build_object('account_id', account_id, 'code', code,
                'name', name, 'amount', balance) order by code) from b where type = 'liability' and balance <> 0), '[]'),
    'equity', coalesce((select jsonb_agg(jsonb_build_object('account_id', account_id, 'code', code,
                'name', name, 'amount', balance) order by code) from b where type = 'equity' and balance <> 0), '[]'),
    'surplus', (select surplus_v from s),
    'total_assets', (select coalesce(sum(balance), 0) from b where type = 'asset'),
    'total_liabilities', (select coalesce(sum(balance), 0) from b where type = 'liability'),
    'total_equity', (select coalesce(sum(balance), 0) from b where type = 'equity') + (select surplus_v from s)
  ) into v;
  return v;
end;
$$;

-- Money in and out of the money accounts over a period, by what it was.
create or replace function public.ledger_cash_flow(p_from date, p_to date)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare v jsonb;
begin
  perform app_private.require('finance.view');
  with money as (select id from ledger_accounts where is_money),
  moves as (
    select e.id, l.debit - l.credit amount,
           (select string_agg(distinct a2.name, ', ') from journal_lines l2
              join ledger_accounts a2 on a2.id = l2.account_id
            where l2.entry_id = e.id and l2.account_id not in (select id from money)) other
    from journal_lines l join journal_entries e on e.id = l.entry_id
    where l.account_id in (select id from money) and e.entry_date between p_from and p_to
  )
  select jsonb_build_object(
    'from', p_from, 'to', p_to, 'currency', app_private.ledger_currency(),
    'opening', (select coalesce(sum(l.debit - l.credit), 0) from journal_lines l
                join journal_entries e on e.id = l.entry_id
                where l.account_id in (select id from money) and e.entry_date < p_from),
    'in', coalesce((select jsonb_agg(jsonb_build_object('what', coalesce(other, 'Between own accounts'), 'amount', s)
                                     order by s desc)
                    from (select other, sum(amount) s from moves where amount > 0 group by other) x), '[]'),
    'out', coalesce((select jsonb_agg(jsonb_build_object('what', coalesce(other, 'Between own accounts'), 'amount', -s)
                                      order by s)
                     from (select other, sum(amount) s from moves where amount < 0 group by other) x), '[]'),
    'total_in', (select coalesce(sum(amount), 0) from moves where amount > 0),
    'total_out', (select coalesce(-sum(amount), 0) from moves where amount < 0),
    'closing', (select coalesce(sum(l.debit - l.credit), 0) from journal_lines l
                join journal_entries e on e.id = l.entry_id
                where l.account_id in (select id from money) and e.entry_date <= p_to)
  ) into v;
  return v;
end;
$$;

-- Planned against actual, per income and expense account, for a period.
create or replace function public.ledger_budget_report(p_from date, p_to date)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform app_private.require('finance.view');
  return coalesce((
    select jsonb_agg(jsonb_build_object('account_id', a.id, 'code', a.code, 'name', a.name, 'type', a.type,
             'budget', coalesce(bu.amount, 0), 'actual', coalesce(ac.balance, 0)) order by a.code)
    from ledger_accounts a
    left join (select account_id, sum(amount) amount from budgets
               where month between date_trunc('month', p_from)::date and p_to group by 1) bu on bu.account_id = a.id
    left join public.ledger_balances(p_to, p_from) ac on ac.account_id = a.id
    where a.type in ('income', 'expense') and (bu.amount is not null or coalesce(ac.balance, 0) <> 0)), '[]');
end;
$$;

create or replace function public.ledger_bills(p_include_paid boolean default false)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform app_private.require('finance.view');
  return coalesce((
    select jsonb_agg(to_jsonb(x) order by x.due_date nulls last, x.bill_date)
    from (
      select b.id, b.supplier, b.description, b.amount, b.bill_date, b.due_date, a.name account,
             coalesce(p.paid, 0) paid, b.amount - coalesce(p.paid, 0) owed
      from bills b join ledger_accounts a on a.id = b.account_id
      left join (select bill_id, sum(amount) paid from bill_payments group by 1) p on p.bill_id = b.id
      where b.voided_at is null and (p_include_paid or b.amount > coalesce(p.paid, 0))
    ) x), '[]');
end;
$$;

create or replace function public.ledger_assets()
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform app_private.require('finance.view');
  return coalesce((
    select jsonb_agg(to_jsonb(x) order by x.purchased_on desc)
    from (
      select f.id, f.name, f.cost, f.purchased_on, f.useful_life_months, f.disposed_on, f.note,
             coalesce(d.done, 0) depreciated, f.cost - coalesce(d.done, 0) value
      from fixed_assets f
      left join (select e.source_id, sum(l.credit) done from journal_entries e
                 join journal_lines l on l.entry_id = e.id
                 where e.source_type = 'depreciation' and l.account_id = app_private.account_id('1590')
                 group by 1) d on d.source_id = f.id
    ) x), '[]');
end;
$$;

create or replace function public.ledger_reconciliations(p_account_id uuid default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform app_private.require('finance.view');
  return coalesce((
    select jsonb_agg(jsonb_build_object('id', r.id, 'account', a.name, 'as_of', r.as_of, 'counted', r.counted,
             'books', r.books, 'difference', r.difference, 'note', r.note,
             'posted', r.adjustment_entry_id is not null, 'by', u.display_name, 'at', r.created_at)
           order by r.created_at desc)
    from reconciliations r join ledger_accounts a on a.id = r.account_id
    left join users u on u.id = r.done_by
    where p_account_id is null or r.account_id = p_account_id), '[]');
end;
$$;

-- ------------------------------------------------------------ history --

-- Put everything Sidra already recorded into the books, in date order.
do $$
declare r record;
begin
  for r in select id from payments where status in ('verified', 'reversed') and verified_at is not null
           order by coalesce(paid_on, verified_at::date), created_at loop
    perform app_private.ledger_post_payment(r.id);
  end loop;
  for r in select id from refunds order by created_at loop
    perform app_private.ledger_post_refund(r.id);
  end loop;
  for r in select id from expenses order by spent_on, created_at loop
    perform app_private.ledger_post_expense(r.id);
  end loop;
  for r in select id from payment_tests order by created_at loop
    perform app_private.ledger_post_test(r.id);
  end loop;
end $$;

select app_private.lock_down_functions();
