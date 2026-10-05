-- Finance follow-ups:
--   1. Receipts: every confirmed payment gets a receipt number, and the
--      periods it pays for; learners see their payments and receipts.
--   2. Paying ahead: a learner on a repeating fee chooses how many periods
--      to pay (e.g. 5 months at once); access runs to the end of them.
--   3. Refunds are owed first, then paid out from a chosen account.
--   4. MarzPay check: the payments Worker compares each Sidra MarzPay
--      payment with MarzPay's own records (status, amount, fee).
--   5. Accounting rules: who confirmed the books' defaults, and when.

-- ----------------------------------------------------------- receipts --

create sequence if not exists receipt_numbers;

alter table payments
  add column receipt_number bigint unique,
  -- the periods this payment paid for, fixed when it was confirmed
  add column covers_from date,
  add column covers_until date;

-- Number a payment the moment it is confirmed (numbers never repeat).
create or replace function app_private.payment_receipt_number()
returns trigger
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if new.status = 'verified' and new.receipt_number is null then
    new.receipt_number := nextval('receipt_numbers');
  end if;
  return new;
end;
$$;
create trigger payments_receipt_number before insert or update of status on payments
  for each row execute function app_private.payment_receipt_number();

-- Which periods a just-confirmed payment pays for (repeating fees only):
-- from the first period it starts paying to the last one it completes.
create or replace function app_private.payment_coverage(p_payment uuid)
returns table (covers_from date, covers_until date)
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare
  p payments%rowtype;
  c courses%rowtype;
  v_info jsonb;
  v_price numeric;
  v_bal record;
  v_after numeric;
  v_first int;
  v_last int;
  v_start date;
  v_step interval;
begin
  select * into p from payments where id = p_payment;
  select * into c from courses where id = p.course_id;
  if c.billing_period = 'once' then return; end if;
  v_info := app_private.billing_info(p.user_id, p.course_id);
  v_price := (v_info->>'price_per_period')::numeric;
  if coalesce(v_price, 0) <= 0 then return; end if;
  select * into v_bal from app_private.course_balance(p.user_id, p.course_id);
  v_after := v_bal.paid - v_bal.refunded + v_bal.waived;
  v_first := floor((v_after - p.amount) / v_price)::int;    -- periods paid before it
  v_last := floor(v_after / v_price)::int;                  -- periods paid after it
  if v_last <= v_first then return; end if;                 -- only part of a period
  v_start := (v_info->>'billing_start')::date;
  v_step := app_private.billing_step(c);
  covers_from := (v_start + v_first * v_step)::date;
  covers_until := (v_start + v_last * v_step)::date - 1;
  return next;
end;
$$;

create or replace function app_private.payment_set_coverage()
returns trigger
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v record;
begin
  if new.status = 'verified' and new.covers_from is null
     and (tg_op = 'INSERT' or old.status is distinct from 'verified') then
    select * into v from app_private.payment_coverage(new.id);
    if v.covers_from is not null then
      update payments set covers_from = v.covers_from, covers_until = v.covers_until
      where id = new.id;
    end if;
  end if;
  return null;
end;
$$;
create trigger payments_coverage after insert or update of status on payments
  for each row execute function app_private.payment_set_coverage();

-- Numbers for payments confirmed before this (in date order).
do $$
declare r record;
begin
  for r in select id from payments where status in ('verified', 'reversed') and receipt_number is null
           order by coalesce(verified_at, created_at) loop
    update payments set receipt_number = nextval('receipt_numbers') where id = r.id;
  end loop;
end $$;

create or replace function app_private.payment_json(p payments)
returns jsonb
language sql stable
as $$
  select jsonb_build_object(
    'id', p.id, 'course_id', p.course_id, 'amount', p.amount, 'currency', p.currency,
    'method', p.method, 'status', p.status, 'status_reason', p.status_reason,
    'phone', p.phone, 'external_reference', p.external_reference,
    'reference', p.reference, 'provider_uuid', p.provider_uuid,
    'created_at', p.created_at, 'verified_at', p.verified_at,
    'receipt_number', p.receipt_number, 'covers_from', p.covers_from, 'covers_until', p.covers_until)
$$;

-- A receipt, for the learner who paid or for finance staff.
create or replace function public.payment_receipt(p_payment_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare p payments%rowtype; v jsonb;
begin
  select * into p from payments where id = p_payment_id;
  if not found or (p.user_id is distinct from app_private.current_user_id()
                   and not app_private.has_permission('finance.view')) then
    raise exception 'receipt not found' using errcode = 'PT404';
  end if;
  if p.receipt_number is null then
    raise exception 'a receipt is issued once the payment is confirmed' using errcode = 'PT409';
  end if;
  select jsonb_build_object(
    'receipt_number', p.receipt_number,
    'org_name', (select value from org_settings where key = 'org_name'),
    'org_name_ar', (select value from org_settings where key = 'org_name_ar'),
    'org_phone', (select value from org_settings where key = 'support_phone'),
    'org_email', (select nullif(value, 'null') from org_settings where key = 'support_email'),
    'learner', u.display_name, 'learner_phone', u.phone,
    'course', c.title, 'billing_period', c.billing_period,
    'amount', p.amount, 'currency', p.currency, 'method', p.method, 'provider', p.provider,
    'status', p.status, 'paid_on', coalesce(p.paid_on, p.verified_at::date),
    'confirmed_at', p.verified_at,
    -- Sidra's own reference, and the MTN/Airtel/bank transaction ID.
    'reference', p.reference,
    'provider_reference', p.external_reference,
    'covers_from', p.covers_from, 'covers_until', p.covers_until,
    'refunded', (select coalesce(sum(amount), 0) from refunds where payment_id = p.id),
    'received_by', vb.display_name)
  into v
  from users u, courses c
  left join users vb on vb.id = p.verified_by
  where u.id = p.user_id and c.id = p.course_id;
  return v;
end;
$$;

-- A learner's payments in every course, newest first.
create or replace function public.my_payment_history()
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce(jsonb_agg(app_private.payment_json(p) || jsonb_build_object(
           'course', c.title,
           'refunded', (select coalesce(sum(amount), 0) from refunds where payment_id = p.id))
         order by p.created_at desc), '[]')
  from payments p join courses c on c.id = p.course_id
  where p.user_id = app_private.current_user_id()
    and p.status not in ('initiated')
$$;

-- ------------------------------------------------------- paying ahead --

-- What paying for p_periods periods would cost and cover, for a learner
-- on a repeating fee. Periods already due must be included.
create or replace function app_private.prepay_quote(p_user uuid, p_course uuid, p_periods int)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare
  c courses%rowtype;
  v_info jsonb;
  v_price numeric;
  v_bal record;
  v_credit numeric;
  v_covered int;
  v_due int;
  v_min int;
  v_max int;
  v_target int;
  v_start date;
  v_step interval;
begin
  select * into c from courses where id = p_course;
  if not found or c.access <> 'paid' then
    raise exception 'course not found' using errcode = 'PT404';
  end if;
  if c.billing_period = 'once' then
    raise exception 'this course has a one-time fee' using errcode = 'PT409';
  end if;
  v_info := app_private.billing_info(p_user, p_course);
  v_price := (v_info->>'price_per_period')::numeric;
  if coalesce(v_price, 0) <= 0 then
    raise exception 'this course has no fee' using errcode = 'PT409';
  end if;
  select * into v_bal from app_private.course_balance(p_user, p_course);
  v_credit := v_bal.paid - v_bal.refunded + v_bal.waived;
  v_covered := floor(v_credit / v_price)::int;
  v_due := (v_info->>'periods_due')::int;
  v_min := greatest(1, v_due - v_covered);
  v_max := least(coalesce(c.billing_periods - v_covered, 1000000),
                 v_covered - v_due + greatest(app_private.int_setting('prepay_max_periods', 12), 1));
  if v_max < 1 then
    raise exception 'every period of this course is already paid for' using errcode = 'PT409';
  end if;
  if p_periods is null or p_periods < v_min then
    raise exception 'pay for at least % (what is already due)', v_min using errcode = 'PT422';
  end if;
  if p_periods > v_max then
    raise exception 'you can pay for at most % at once', v_max using errcode = 'PT422';
  end if;
  v_target := v_covered + p_periods;
  v_start := (v_info->>'billing_start')::date;
  v_step := app_private.billing_step(c);
  return jsonb_build_object(
    'periods', p_periods, 'min_periods', v_min, 'max_periods', v_max,
    'billing_period', c.billing_period, 'price_per_period', v_price,
    'currency', v_bal.currency,
    'amount', ceil(v_target * v_price - v_credit),
    'covers_from', (v_start + v_covered * v_step)::date,
    'covers_until', (v_start + v_target * v_step)::date - 1);
end;
$$;

create or replace function public.prepay_quote(p_course_id uuid, p_periods int)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if app_private.current_user_id() is null then
    raise exception 'not signed in' using errcode = 'PT401';
  end if;
  return app_private.prepay_quote(app_private.current_user_id(), p_course_id, p_periods);
end;
$$;

insert into org_settings (key, value, is_public) values ('prepay_max_periods', '12', false)
on conflict (key) do nothing;

-- Starting a mobile-money payment: as before, or (p_periods) for that many
-- periods of a repeating fee, paid ahead.
drop function public.start_course_payment(uuid, text);
create function public.start_course_payment(p_course_id uuid, p_phone text, p_periods int default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_course courses%rowtype;
  v_bal record;
  v_phone text := app_private.normalize_ug_phone(p_phone);
  v_payment payments%rowtype;
  v_amount numeric;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  select * into v_course from courses where id = p_course_id and status = 'published';
  if not found then raise exception 'course not found' using errcode = 'PT404'; end if;
  if v_course.access <> 'paid' then
    raise exception 'this course is not paid for online' using errcode = 'PT409';
  end if;
  if coalesce((select value from org_settings where key = 'marzpay_enabled'), 'true') <> 'true' then
    raise exception 'mobile-money payments are switched off; pay by bank or at the office'
      using errcode = 'PT409';
  end if;
  if v_phone is null then
    raise exception 'enter an MTN or Airtel Uganda number, e.g. 0772 123456' using errcode = 'PT422';
  end if;

  perform app_private.require_prerequisites(p_course_id);
  -- One prompt at a time: an unfinished payment is returned, not repeated.
  select * into v_payment from payments
  where user_id = v_me and course_id = p_course_id and method = 'marzpay'
    and status in ('initiated', 'processing');
  if found then return app_private.payment_json(v_payment); end if;

  select * into v_bal from app_private.course_balance(v_me, p_course_id);
  if p_periods is not null then
    v_amount := (app_private.prepay_quote(v_me, p_course_id, p_periods)->>'amount')::numeric;
  else
    if v_bal.outstanding <= 0 then
      perform app_private.apply_payment_access(v_me, p_course_id);
      raise exception 'this course is already paid for' using errcode = 'PT409';
    end if;
    v_amount := ceil(v_bal.outstanding);
  end if;
  if v_bal.currency <> 'UGX' then
    raise exception 'mobile money only takes UGX' using errcode = 'PT422';
  end if;
  if v_amount < 500 or v_amount > 10000000 then
    raise exception 'mobile money takes 500 to 10,000,000 UGX; pay the balance another way'
      using errcode = 'PT422';
  end if;

  -- The learner shows up as "waiting for payment" with the fee fixed now.
  insert into course_enrolments (course_id, user_id, status, source, fee_amount, fee_currency)
  values (p_course_id, v_me, 'pending', 'payment',
          coalesce(v_course.price_amount, v_bal.fee), v_bal.currency)
  on conflict (course_id, user_id) do update set
    fee_amount = coalesce(course_enrolments.fee_amount, excluded.fee_amount),
    fee_currency = coalesce(course_enrolments.fee_currency, excluded.fee_currency);

  insert into payments (user_id, course_id, amount, currency, method, status, phone,
                        recorded_by, next_attempt_at, note)
  values (v_me, p_course_id, v_amount, v_bal.currency, 'marzpay', 'initiated',
          v_phone, v_me, now(),
          case when p_periods is not null then format('Paid ahead: %s period(s)', p_periods) end)
  returning * into v_payment;
  perform pg_notify('sidra_payments', v_payment.id::text);
  return app_private.payment_json(v_payment);
end;
$$;

-- ------------------------------------------------------ refund payouts --

insert into ledger_accounts (code, name, type, is_system, description) values
  ('2050', 'Refunds owed to learners', 'liability', true,
   'Refunds agreed but not yet paid back.')
on conflict (code) do nothing;

alter table refunds
  add column payout_status text not null default 'owed' check (payout_status in ('owed', 'paid')),
  add column paid_from_account_id uuid references ledger_accounts (id),
  add column payout_method text,
  add column payout_reference text,
  add column paid_out_on date,
  add column paid_out_by uuid references users (id) on delete set null;

-- Refunds booked before this were booked as already paid from the money
-- account the payment came into.
update refunds set payout_status = 'paid', payout_method = 'before_payouts'
where exists (select 1 from journal_entries e where e.source_type = 'refund'
              and e.source_id = refunds.id and e.source_event = 'refund');

-- A refund is owed to the learner when agreed (income goes down, a debt to
-- the learner goes up); paying it out clears the debt from a money account.
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
  if r.payout_method = 'before_payouts' then return; end if; -- already in the books
  perform app_private.post_entry(
    r.created_at::date, 'Refund agreed: ' || coalesce(r.reason, ''), 'refund', r.id, 'owed',
    jsonb_build_array(
      app_private.line(app_private.account_id('4090'), r.amount, 0, p.user_id, p.course_id),
      app_private.line(app_private.account_id('2050'), 0, r.amount, p.user_id, p.course_id)));
  if r.payout_status = 'paid' and r.paid_from_account_id is not null then
    perform app_private.post_entry(
      r.paid_out_on, 'Refund paid out' || coalesce(' (' || r.payout_reference || ')', ''),
      'refund', r.id, 'paid',
      jsonb_build_array(
        app_private.line(app_private.account_id('2050'), r.amount, 0, p.user_id, p.course_id),
        app_private.line(r.paid_from_account_id, 0, r.amount, p.user_id, p.course_id)));
  end if;
end;
$$;

drop trigger refunds_ledger on refunds;
create trigger refunds_ledger after insert or update of payout_status on refunds
  for each row execute function app_private.ledger_on_refund();

create or replace function public.pay_out_refund(
  p_refund_id uuid, p_from_account uuid, p_method text, p_reference text, p_paid_on date default null)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare r refunds%rowtype;
begin
  perform app_private.require('finance.verify_payment');
  select * into r from refunds where id = p_refund_id for update;
  if not found then raise exception 'refund not found' using errcode = 'PT404'; end if;
  if r.payout_status = 'paid' then
    raise exception 'this refund is already paid out' using errcode = 'PT409';
  end if;
  perform app_private.require_account(p_from_account, array['asset'], true, 'account it was paid from');
  if coalesce(trim(p_reference), '') = '' then
    raise exception 'enter the transaction ID or receipt of the payout' using errcode = 'PT422';
  end if;
  update refunds set payout_status = 'paid', paid_from_account_id = p_from_account,
    payout_method = nullif(trim(p_method), ''), payout_reference = trim(p_reference),
    paid_out_on = coalesce(p_paid_on, current_date), paid_out_by = app_private.current_user_id()
  where id = r.id;
end;
$$;

create or replace function public.finance_refunds(p_owed_only boolean default false)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform app_private.require('finance.view');
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', r.id, 'payment_id', p.id, 'learner', u.display_name, 'phone', p.phone,
             'course', c.title, 'amount', r.amount, 'reason', r.reason,
             'agreed_on', r.created_at::date, 'status', r.payout_status,
             'paid_out_on', r.paid_out_on, 'payout_reference', r.payout_reference,
             'paid_from', a.name, 'method', p.method)
           order by r.payout_status desc, r.created_at desc)
    from refunds r join payments p on p.id = r.payment_id
    left join users u on u.id = p.user_id
    left join courses c on c.id = p.course_id
    left join ledger_accounts a on a.id = r.paid_from_account_id
    where not p_owed_only or r.payout_status = 'owed'), '[]');
end;
$$;

-- --------------------------------------------------------- MarzPay check --

create table marzpay_checks (
  payment_id uuid primary key references payments (id) on delete cascade,
  checked_at timestamptz not null default now(),
  -- match | mismatch | waiting
  result text not null check (result in ('match', 'mismatch', 'waiting')),
  detail text,
  marz_credit numeric(14, 2),
  marz_fee numeric(14, 2),
  entries jsonb not null default '[]'
);
alter table marzpay_checks enable row level security;
create policy marzpay_checks_read on marzpay_checks for select to public
  using (app_private.has_permission('finance.view'));
grant select on marzpay_checks to authenticated, sidra_app;

-- Sidra MarzPay payments to compare with MarzPay (newest first; problems
-- again after 30 minutes, the rest every 6 hours, for 90 days).
create or replace function payments_api.statement_to_check(p_limit int default 10)
returns table (id uuid, reference text)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select p.id, p.reference::text
  from payments p left join marzpay_checks k on k.payment_id = p.id
  where p.method = 'marzpay' and p.reference is not null
    and p.status <> 'initiated'
    and p.created_at > now() - interval '90 days'
    and (k.payment_id is null
         or (k.result <> 'match' and k.checked_at < now() - interval '30 minutes')
         or k.checked_at < now() - interval '6 hours')
  order by k.checked_at nulls first, p.created_at desc
  limit least(greatest(coalesce(p_limit, 10), 1), 50)
$$;

-- MarzPay's entries for one payment's reference ({type, amount, status}),
-- judged against what Sidra counts. Read-only for money: it only records.
create or replace function payments_api.record_statement_check(p_payment_id uuid, p_entries jsonb)
returns text
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  p payments%rowtype;
  v_credit numeric;
  v_fee numeric;
  v_result text;
  v_detail text;
begin
  select * into p from payments where id = p_payment_id;
  if not found then return 'unknown'; end if;
  select coalesce(sum((e->>'amount')::numeric) filter (
           where lower(e->>'type') = 'credit' and lower(e->>'status') in ('successful', 'completed')), 0),
         coalesce(sum((e->>'amount')::numeric) filter (
           where lower(e->>'type') = 'debit' and lower(e->>'status') in ('successful', 'completed')), 0)
  into v_credit, v_fee
  from jsonb_array_elements(coalesce(p_entries, '[]')) e;
  if p.status in ('verified', 'reversed') and v_credit = 0 then
    v_result := 'mismatch';
    v_detail := 'Sidra counts this payment but MarzPay shows no successful money in.';
  elsif p.status in ('verified', 'reversed') and v_credit <> p.amount then
    v_result := 'mismatch';
    v_detail := format('Amounts differ: Sidra %s, MarzPay %s.', p.amount, v_credit);
  elsif p.status in ('verified', 'reversed') and coalesce(p.provider_fee, 0) <> v_fee then
    v_result := 'mismatch';
    v_detail := format('Fees differ: Sidra %s, MarzPay %s.', coalesce(p.provider_fee, 0), v_fee);
  elsif p.status in ('failed', 'rejected') and v_credit > 0 then
    v_result := 'mismatch';
    v_detail := format('MarzPay received %s that Sidra does not count.', v_credit);
  elsif p.status in ('processing', 'pending') then
    v_result := 'waiting';
    v_detail := case when v_credit > 0 then 'MarzPay has the money; Sidra will confirm it shortly.'
                     else 'Not finished at MarzPay yet.' end;
  else
    v_result := 'match';
  end if;
  insert into marzpay_checks (payment_id, checked_at, result, detail, marz_credit, marz_fee, entries)
  values (p.id, now(), v_result, v_detail, v_credit, v_fee, coalesce(p_entries, '[]'))
  on conflict (payment_id) do update set checked_at = now(), result = excluded.result,
    detail = excluded.detail, marz_credit = excluded.marz_credit, marz_fee = excluded.marz_fee,
    entries = excluded.entries;
  return v_result;
end;
$$;

grant execute on function payments_api.statement_to_check(int),
  payments_api.record_statement_check(uuid, jsonb) to sidra_payments;

create or replace function public.marzpay_check_report()
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform app_private.require('finance.view');
  return jsonb_build_object(
    'checked', (select count(*) from marzpay_checks),
    'matched', (select count(*) from marzpay_checks where result = 'match'),
    'waiting', (select count(*) from marzpay_checks where result = 'waiting'),
    'mismatched', (select count(*) from marzpay_checks where result = 'mismatch'),
    'not_checked', (select count(*) from payments p
                    where p.method = 'marzpay' and p.status <> 'initiated'
                      and p.created_at > now() - interval '90 days'
                      and not exists (select 1 from marzpay_checks k where k.payment_id = p.id)),
    'last_checked', (select max(checked_at) from marzpay_checks),
    'problems', coalesce((
      select jsonb_agg(jsonb_build_object('payment_id', p.id, 'learner', u.display_name,
               'course', c.title, 'amount', p.amount, 'status', p.status, 'result', k.result,
               'detail', k.detail, 'checked_at', k.checked_at, 'date', p.created_at::date)
             order by k.checked_at desc)
      from marzpay_checks k join payments p on p.id = k.payment_id
      left join users u on u.id = p.user_id left join courses c on c.id = p.course_id
      where k.result <> 'match'), '[]'));
end;
$$;

-- --------------------------------------------------- accounting rules --

-- The person who keeps Almuntahha's accounts confirms the books' rules.
create or replace function public.ledger_confirm_rules(p_confirmed_by text, p_note text default null)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform app_private.require('finance.manage_accounts');
  if coalesce(trim(p_confirmed_by), '') = '' then
    raise exception 'enter the name of the person who confirmed the rules' using errcode = 'PT422';
  end if;
  insert into org_settings (key, value, is_public, updated_by, updated_at)
  values ('accounting_rules_confirmed',
          jsonb_build_object('by', trim(p_confirmed_by), 'note', nullif(trim(p_note), ''),
                             'on', current_date, 'recorded_by',
                             (select display_name from users where id = app_private.current_user_id()))::text,
          false, app_private.current_user_id(), now())
  on conflict (key) do update set value = excluded.value, updated_by = excluded.updated_by, updated_at = now();
end;
$$;

-- The overview also says whether the rules were confirmed and what refunds
-- are still owed.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.ledger_overview()'::regprocedure);
  if position('''opening_entered''' in v_src) = 0 then
    raise exception 'ledger_overview changed; update 0053';
  end if;
  v_src := replace(v_src, '''opening_entered'',',
    '''rules_confirmed'', (select value::jsonb from org_settings where key = ''accounting_rules_confirmed''),
    ''refunds_owed'', (select coalesce(sum(amount), 0) from refunds where payout_status = ''owed''),
    ''opening_entered'',');
  execute v_src;
end $$;

select app_private.lock_down_functions();
