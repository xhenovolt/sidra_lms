-- Phase 2E–2G: enrolment terms, payments (MarzPay + manual), waivers,
-- refunds, expenses, finance summary, organisation settings.
--
-- Money rules
--   * Amounts are never trusted from the app: a learner's MarzPay payment is
--     always for the course's outstanding balance, computed here.
--   * A payment is credited only when verified: MarzPay payments by the
--     payments server after re-fetching the transaction from MarzPay
--     (never a webhook body or a "success" screen); manual payments by a
--     finance officer.
--   * Nothing financial is deleted. Payments are rejected or reversed,
--     expenses voided, waivers revoked — all with a reason, all audited.
--   * Retained = Verified collections − Refunds − Expenses.
--     Waivers reduce what is owed; they are never counted as collections.

-- ------------------------------------------------------ enrolment terms --

alter table course_enrolments
  add column starts_at timestamptz,
  add column ends_at timestamptz,
  add column fee_amount numeric(14, 2) check (fee_amount is null or fee_amount >= 0),
  add column fee_currency text check (fee_currency is null or fee_currency ~ '^[A-Z]{3}$'),
  add constraint course_enrolments_window check (ends_at is null or starts_at is null or ends_at > starts_at);

-- Access honours the enrolment window.
create or replace function app_private.is_enrolled(p_course_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (
    select 1 from course_enrolments
    where course_id = p_course_id
      and user_id = app_private.current_user_id()
      and status in ('active', 'completed')
      and (starts_at is null or starts_at <= now())
      and (ends_at is null or ends_at > now())
  )
$$;

-- ------------------------------------------------ organisation settings --

create table org_settings (
  key text primary key check (key ~ '^[a-z][a-z0-9_]*$'),
  value text,
  -- Shown to every signed-in user (e.g. bank details for paying fees).
  is_public boolean not null default false,
  updated_by uuid references users (id) on delete set null,
  updated_at timestamptz not null default now()
);
alter table org_settings enable row level security;
insert into org_settings (key, value, is_public) values
  ('org_name', 'Almuntahha', true),
  ('currency', 'UGX', true),
  ('support_phone', null, true),
  ('support_email', null, true),
  ('bank_instructions', null, true),
  ('mobile_money_instructions', null, true),
  ('marzpay_enabled', 'true', true);

create trigger org_settings_audit after insert or update or delete on org_settings
  for each row execute function app_private.audit();

create or replace function public.org_settings()
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce(jsonb_object_agg(key, value), '{}')
  from org_settings
  where app_private.current_user_id() is not null
    and (is_public or app_private.has_permission('settings.manage'))
$$;

create or replace function public.set_org_setting(p_key text, p_value text)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.has_permission('settings.manage') then
    raise exception 'not allowed to change settings' using errcode = 'PT403';
  end if;
  if p_key = 'currency' and coalesce(p_value, '') !~ '^[A-Z]{3}$' then
    raise exception 'currency must be a 3-letter code like UGX' using errcode = 'PT422';
  end if;
  update org_settings set value = nullif(trim(p_value), ''),
    updated_by = app_private.current_user_id(), updated_at = now()
  where key = p_key;
  if not found then
    raise exception 'unknown setting %', p_key using errcode = 'PT404';
  end if;
end;
$$;

-- ----------------------------------------------------------- payments --

create type payment_method as enum ('marzpay', 'mobile_money', 'bank', 'cash', 'other');
-- initiated  → MarzPay request queued for the payments server
-- processing → prompt sent to the payer's phone; waiting for MarzPay
-- pending    → manual payment waiting for a finance officer
-- verified   → money confirmed; counts as collected
-- failed / rejected → never counted; reversed → was verified, then undone
create type payment_status as enum (
  'initiated', 'processing', 'pending', 'verified', 'failed', 'rejected', 'reversed');

create table payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users (id) on delete restrict,
  course_id uuid references courses (id) on delete restrict,
  amount numeric(14, 2) not null check (amount > 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  method payment_method not null,
  status payment_status not null,
  -- Our idempotency key; sent to MarzPay as `reference` (UUIDv4).
  reference uuid not null unique default gen_random_uuid(),
  provider text,
  provider_uuid text unique,
  -- Bank slip / mobile-money transaction id / provider transaction id.
  external_reference text,
  phone text,
  paid_on date,
  note text,
  proof_asset_id uuid references media_assets (id) on delete set null,
  status_reason text,
  recorded_by uuid references users (id) on delete set null,
  verified_by uuid references users (id) on delete set null,
  verified_at timestamptz,
  attempts int not null default 0,
  next_attempt_at timestamptz,
  last_error text,
  provider_payload jsonb,
  -- What the provider kept (MarzPay charges ~3% as a separate debit).
  provider_fee numeric(14, 2) check (provider_fee is null or provider_fee >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index payments_user_course on payments (user_id, course_id);
create index payments_status on payments (status, created_at desc);
create index payments_verified_at on payments (verified_at) where status = 'verified';
create unique index payments_one_inflight on payments (user_id, course_id)
  where status in ('initiated', 'processing') and method = 'marzpay';

create table refunds (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references payments (id) on delete restrict,
  amount numeric(14, 2) not null check (amount > 0),
  reason text not null check (length(trim(reason)) > 0),
  recorded_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now()
);

create table waivers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users (id) on delete restrict,
  course_id uuid not null references courses (id) on delete restrict,
  -- null = the whole fee.
  amount numeric(14, 2) check (amount is null or amount > 0),
  reason text not null check (length(trim(reason)) > 0),
  granted_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now(),
  revoked_at timestamptz,
  revoked_by uuid references users (id) on delete set null,
  revoke_reason text
);
create index waivers_user_course on waivers (user_id, course_id) where revoked_at is null;

create table expenses (
  id uuid primary key default gen_random_uuid(),
  category text not null check (length(trim(category)) > 0),
  description text,
  payee text,
  amount numeric(14, 2) not null check (amount > 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  spent_on date not null,
  recorded_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now(),
  voided_at timestamptz,
  voided_by uuid references users (id) on delete set null,
  void_reason text
);
create index expenses_spent_on on expenses (spent_on) where voided_at is null;

-- Financial rows are never deleted (not even by cascades).
create or replace function app_private.forbid_delete()
returns trigger
language plpgsql
as $$
begin
  raise exception '% records are never deleted; reverse, void or revoke them instead',
    tg_table_name using errcode = 'PT409';
end;
$$;

do $$
declare t text;
begin
  foreach t in array array['payments', 'refunds', 'waivers', 'expenses'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create trigger %I before delete on %I
                      for each row execute function app_private.forbid_delete()',
                   t || '_no_delete', t);
    execute format('create trigger %I after insert or update on %I
                      for each row execute function app_private.audit()',
                   t || '_audit', t);
    execute format('grant select on %I to authenticated, sidra_app', t);
  end loop;
end $$;

create policy payments_read on payments for select to public
  using (user_id = app_private.current_user_id()
         or app_private.has_permission('finance.view'));
create policy refunds_read on refunds for select to public
  using (app_private.has_permission('finance.view')
         or exists (select 1 from payments p where p.id = payment_id
                    and p.user_id = app_private.current_user_id()));
create policy waivers_read on waivers for select to public
  using (user_id = app_private.current_user_id()
         or app_private.has_permission('finance.view'));
create policy expenses_read on expenses for select to public
  using (app_private.has_permission('finance.view'));

-- --------------------------------------------------------- balances --

-- What a learner owes for a course: fee (snapshot on the enrolment, else
-- the course price) − verified payments + refunds − active waivers.
create or replace function app_private.course_balance(p_user_id uuid, p_course_id uuid)
returns table (fee numeric, currency text, paid numeric, refunded numeric,
               waived numeric, outstanding numeric)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  with base as (
    select coalesce(e.fee_amount, case when c.access = 'paid' then c.price_amount end, 0) as fee,
           coalesce(e.fee_currency, c.price_currency,
                    (select value from org_settings where key = 'currency'), 'UGX') as currency
    from courses c
    left join course_enrolments e on e.course_id = c.id and e.user_id = p_user_id
    where c.id = p_course_id
  ),
  paid as (
    select coalesce(sum(amount), 0) as v from payments
    where user_id = p_user_id and course_id = p_course_id and status = 'verified'
  ),
  refunded as (
    select coalesce(sum(r.amount), 0) as v from refunds r join payments p on p.id = r.payment_id
    where p.user_id = p_user_id and p.course_id = p_course_id and p.status = 'verified'
  ),
  waived as (
    select coalesce(sum(coalesce(w.amount, b.fee)), 0) as v
    from waivers w, base b
    where w.user_id = p_user_id and w.course_id = p_course_id and w.revoked_at is null
  )
  select b.fee, b.currency, paid.v, refunded.v, least(waived.v, b.fee),
         greatest(b.fee - (paid.v - refunded.v) - waived.v, 0)
  from base b, paid, refunded, waived
$$;

-- Opens a paid course once it is fully covered by payments and waivers.
create or replace function app_private.apply_payment_access(p_user_id uuid, p_course_id uuid)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_bal record; v_course courses%rowtype;
begin
  select * into v_course from courses where id = p_course_id;
  if not found or v_course.access <> 'paid' then return; end if;
  select * into v_bal from app_private.course_balance(p_user_id, p_course_id);
  if v_bal.fee > 0 and v_bal.outstanding = 0 then
    insert into course_enrolments (course_id, user_id, status, source, fee_amount, fee_currency)
    values (p_course_id, p_user_id, 'active', 'payment', v_bal.fee, v_bal.currency)
    on conflict (course_id, user_id) do update set
      status = case when course_enrolments.status in ('pending', 'withdrawn')
                    then 'active'::enrolment_status else course_enrolments.status end,
      fee_amount = coalesce(course_enrolments.fee_amount, excluded.fee_amount),
      fee_currency = coalesce(course_enrolments.fee_currency, excluded.fee_currency);
  end if;
end;
$$;

-- -------------------------------------------------- learner: pay fees --

create or replace function app_private.normalize_ug_phone(p text)
returns text
language sql immutable
as $$
  select '+256' || m[1]
  from regexp_match(regexp_replace(coalesce(p, ''), '[^0-9+]', '', 'g'),
                    '^(?:\+?256|0)?(7[0-9]{8})$') m
$$;

create or replace function app_private.payment_json(p payments)
returns jsonb
language sql stable
as $$
  select jsonb_build_object(
    'id', p.id, 'course_id', p.course_id, 'amount', p.amount, 'currency', p.currency,
    'method', p.method, 'status', p.status, 'status_reason', p.status_reason,
    'phone', p.phone, 'external_reference', p.external_reference,
    'created_at', p.created_at, 'verified_at', p.verified_at)
$$;

-- Learner taps "Pay": queue a MarzPay collection for what they owe.
create or replace function public.start_course_payment(p_course_id uuid, p_phone text)
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

  -- One prompt at a time: an unfinished payment is returned, not repeated.
  select * into v_payment from payments
  where user_id = v_me and course_id = p_course_id and method = 'marzpay'
    and status in ('initiated', 'processing');
  if found then return app_private.payment_json(v_payment); end if;

  select * into v_bal from app_private.course_balance(v_me, p_course_id);
  if v_bal.outstanding <= 0 then
    perform app_private.apply_payment_access(v_me, p_course_id);
    raise exception 'this course is already paid for' using errcode = 'PT409';
  end if;
  if v_bal.currency <> 'UGX' then
    raise exception 'mobile money only takes UGX' using errcode = 'PT422';
  end if;
  if v_bal.outstanding < 500 or v_bal.outstanding > 10000000 then
    raise exception 'mobile money takes 500 to 10,000,000 UGX; pay the balance another way'
      using errcode = 'PT422';
  end if;

  -- The learner shows up as "waiting for payment" with the fee fixed now.
  insert into course_enrolments (course_id, user_id, status, source, fee_amount, fee_currency)
  values (p_course_id, v_me, 'pending', 'payment', v_bal.fee, v_bal.currency)
  on conflict (course_id, user_id) do update set
    fee_amount = coalesce(course_enrolments.fee_amount, excluded.fee_amount),
    fee_currency = coalesce(course_enrolments.fee_currency, excluded.fee_currency);

  insert into payments (user_id, course_id, amount, currency, method, status, phone,
                        recorded_by, next_attempt_at)
  values (v_me, p_course_id, ceil(v_bal.outstanding), v_bal.currency, 'marzpay', 'initiated',
          v_phone, v_me, now())
  returning * into v_payment;
  perform pg_notify('sidra_payments', v_payment.id::text);
  return app_private.payment_json(v_payment);
end;
$$;

-- Learner paid by bank / mobile money outside the app: finance verifies.
create or replace function public.submit_manual_payment(
  p_course_id uuid, p_method payment_method, p_amount numeric,
  p_external_reference text, p_paid_on date default null, p_note text default null,
  p_proof_asset_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_bal record;
  v_payment payments%rowtype;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  if p_method = 'marzpay' then
    raise exception 'use Pay with mobile money for MarzPay' using errcode = 'PT422';
  end if;
  if coalesce(trim(p_external_reference), '') = '' then
    raise exception 'enter the transaction or slip number' using errcode = 'PT422';
  end if;
  if not exists (select 1 from courses where id = p_course_id and status = 'published') then
    raise exception 'course not found' using errcode = 'PT404';
  end if;
  select * into v_bal from app_private.course_balance(v_me, p_course_id);
  insert into payments (user_id, course_id, amount, currency, method, status,
                        external_reference, paid_on, note, proof_asset_id, recorded_by)
  values (v_me, p_course_id, p_amount, v_bal.currency, p_method, 'pending',
          trim(p_external_reference), coalesce(p_paid_on, current_date), p_note,
          p_proof_asset_id, v_me)
  returning * into v_payment;
  return app_private.payment_json(v_payment);
end;
$$;

create or replace function public.my_payments(p_course_id uuid default null)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.payment_json(p) from payments p
  where p.user_id = app_private.current_user_id()
    and (p_course_id is null or p.course_id = p_course_id)
  order by p.created_at desc
  limit 50
$$;

create or replace function public.my_course_balance(p_course_id uuid)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select to_jsonb(b) from app_private.course_balance(app_private.current_user_id(), p_course_id) b
  where app_private.current_user_id() is not null
$$;

-- ------------------------------------------ payments server (MarzPay) --
-- Runs as the `sidra_payments` login: it can call only these functions.

create schema if not exists payments_api;
revoke all on schema payments_api from public;
alter default privileges in schema payments_api revoke execute on functions from public;

-- Next MarzPay requests to send. Each claim pushes next_attempt_at out, so a
-- crashed server retries later with the SAME reference (MarzPay rejects a
-- duplicate, so the payer is never prompted twice for one payment).
create or replace function payments_api.claim(p_limit int default 10)
returns table (id uuid, reference uuid, amount numeric, currency text, phone text,
               description text, attempts int)
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  with picked as (
    select p.id from payments p
    where p.method = 'marzpay' and p.status = 'initiated'
      and coalesce(p.next_attempt_at, now()) <= now()
    order by p.created_at
    limit greatest(p_limit, 1)
    for update skip locked
  )
  update payments p set
    attempts = p.attempts + 1,
    next_attempt_at = now() + (interval '30 seconds' * power(2, least(p.attempts, 6))),
    updated_at = now()
  from picked
  where p.id = picked.id
  returning p.id, p.reference, p.amount, p.currency, p.phone,
    left(coalesce((select title from courses c where c.id = p.course_id), 'Sidra') || ' fees', 250),
    p.attempts
$$;

create or replace function payments_api.submitted(
  p_id uuid, p_provider_uuid text, p_provider text, p_status text)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update payments set status = 'processing', provider_uuid = p_provider_uuid,
    provider = p_provider, last_error = null, next_attempt_at = null, updated_at = now()
  where id = p_id and status = 'initiated'
$$;

-- A request MarzPay refused. Permanent problems (bad number, validation)
-- fail the payment; others are retried with backoff, up to 6 attempts.
create or replace function payments_api.submit_failed(
  p_id uuid, p_error text, p_permanent boolean)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update payments set
    last_error = left(p_error, 500),
    status = case when p_permanent or attempts >= 6 then 'failed'::payment_status else status end,
    status_reason = case when p_permanent or attempts >= 6
                         then left(p_error, 500) else status_reason end,
    updated_at = now()
  where id = p_id and status = 'initiated'
$$;

-- Payments waiting on MarzPay (for polling when no webhook arrives).
create or replace function payments_api.to_reconcile(p_limit int default 20)
returns table (id uuid, provider_uuid text, reference uuid)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select p.id, p.provider_uuid, p.reference from payments p
  where p.method = 'marzpay' and p.status = 'processing'
    and p.provider_uuid is not null
    and p.updated_at < now() - interval '10 seconds'
    and p.created_at > now() - interval '2 days'
  order by p.updated_at
  limit greatest(p_limit, 1)
$$;

-- Records MarzPay's answer. Call only with data fetched FROM MarzPay's
-- status endpoint. Idempotent; money is credited once.
create or replace function payments_api.settle(
  p_provider_uuid text, p_status text, p_amount numeric,
  p_provider_ref text, p_payload jsonb default null, p_fee numeric default null)
returns text
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v payments%rowtype; v_s text := lower(coalesce(p_status, ''));
begin
  select * into v from payments where provider_uuid = p_provider_uuid for update;
  if not found then return 'unknown'; end if;
  if v.status in ('verified', 'reversed', 'rejected') then return v.status::text; end if;

  if v_s in ('successful', 'completed', 'success') then
    if p_amount is null or p_amount <> v.amount then
      -- Money arrived but not what we asked for: a person decides.
      update payments set status = 'pending', external_reference = p_provider_ref,
        status_reason = format('MarzPay reported %s %s; expected %s', p_amount, v.currency, v.amount),
        provider_payload = p_payload, updated_at = now()
      where id = v.id;
      return 'pending';
    end if;
    update payments set status = 'verified', verified_at = now(),
      provider_fee = p_fee,
      external_reference = coalesce(p_provider_ref, external_reference),
      status_reason = null, provider_payload = p_payload, updated_at = now()
    where id = v.id;
    perform app_private.apply_payment_access(v.user_id, v.course_id);
    return 'verified';
  elsif v_s in ('failed', 'cancelled', 'canceled', 'rejected', 'expired') then
    update payments set status = 'failed', status_reason = 'MarzPay: ' || v_s,
      provider_payload = p_payload, updated_at = now()
    where id = v.id;
    return 'failed';
  elsif v.created_at < now() - interval '1 day' then
    update payments set status = 'failed', status_reason = 'no answer from MarzPay after a day',
      provider_payload = p_payload, updated_at = now()
    where id = v.id;
    return 'failed';
  end if;
  -- still processing / pending on the payer's phone
  update payments set updated_at = now(), provider_payload = coalesce(p_payload, provider_payload)
  where id = v.id;
  return 'processing';
end;
$$;

-- ------------------------------------------------- finance officers --

create or replace function app_private.require(p_permission text)
returns void
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.has_permission(p_permission) then
    raise exception 'not allowed (%)', p_permission using errcode = 'PT403';
  end if;
end;
$$;

create or replace function public.record_payment(
  p_user_id uuid, p_course_id uuid, p_amount numeric, p_method payment_method,
  p_external_reference text, p_paid_on date default null, p_note text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_payment payments%rowtype; v_currency text;
begin
  perform app_private.require('finance.record_payment');
  if p_method = 'marzpay' then
    raise exception 'MarzPay payments are recorded automatically' using errcode = 'PT422';
  end if;
  select currency into v_currency from app_private.course_balance(p_user_id, p_course_id);
  insert into payments (user_id, course_id, amount, currency, method, status,
                        external_reference, paid_on, note, recorded_by)
  values (p_user_id, p_course_id, p_amount, coalesce(v_currency, 'UGX'), p_method, 'pending',
          nullif(trim(p_external_reference), ''), coalesce(p_paid_on, current_date), p_note,
          app_private.current_user_id())
  returning * into v_payment;
  return app_private.payment_json(v_payment);
end;
$$;

create or replace function public.verify_payment(p_payment_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v payments%rowtype;
begin
  perform app_private.require('finance.verify_payment');
  update payments set status = 'verified', verified_by = app_private.current_user_id(),
    verified_at = now(), status_reason = null, updated_at = now()
  where id = p_payment_id and status = 'pending'
  returning * into v;
  if not found then
    raise exception 'only payments waiting for verification can be verified' using errcode = 'PT409';
  end if;
  perform app_private.apply_payment_access(v.user_id, v.course_id);
  return app_private.payment_json(v);
end;
$$;

create or replace function public.reject_payment(p_payment_id uuid, p_reason text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v payments%rowtype;
begin
  perform app_private.require('finance.verify_payment');
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'give a reason' using errcode = 'PT422';
  end if;
  update payments set status = 'rejected', status_reason = trim(p_reason),
    verified_by = app_private.current_user_id(), updated_at = now()
  where id = p_payment_id and status = 'pending'
  returning * into v;
  if not found then
    raise exception 'only payments waiting for verification can be rejected' using errcode = 'PT409';
  end if;
  return app_private.payment_json(v);
end;
$$;

-- Undo a verified payment (e.g. a bounced cheque). The learner's paid
-- access is suspended if they now owe money.
create or replace function public.reverse_payment(p_payment_id uuid, p_reason text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v payments%rowtype;
begin
  perform app_private.require('finance.verify_payment');
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'give a reason' using errcode = 'PT422';
  end if;
  update payments set status = 'reversed', status_reason = trim(p_reason), updated_at = now()
  where id = p_payment_id and status = 'verified'
  returning * into v;
  if not found then
    raise exception 'only verified payments can be reversed' using errcode = 'PT409';
  end if;
  update course_enrolments e set status = 'suspended'
  where e.user_id = v.user_id and e.course_id = v.course_id
    and e.source = 'payment' and e.status = 'active'
    and (select outstanding from app_private.course_balance(v.user_id, v.course_id)) > 0;
  return app_private.payment_json(v);
end;
$$;

create or replace function public.record_refund(
  p_payment_id uuid, p_amount numeric, p_reason text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v payments%rowtype; v_refunded numeric; v_refund refunds%rowtype;
begin
  perform app_private.require('finance.verify_payment');
  select * into v from payments where id = p_payment_id for update;
  if not found or v.status <> 'verified' then
    raise exception 'only verified payments can be refunded' using errcode = 'PT409';
  end if;
  select coalesce(sum(amount), 0) into v_refunded from refunds where payment_id = v.id;
  if p_amount <= 0 or v_refunded + p_amount > v.amount then
    raise exception 'refunds cannot exceed the payment (% already refunded of %)',
      v_refunded, v.amount using errcode = 'PT422';
  end if;
  insert into refunds (payment_id, amount, reason, recorded_by)
  values (v.id, p_amount, trim(p_reason), app_private.current_user_id())
  returning * into v_refund;
  return to_jsonb(v_refund);
end;
$$;

create or replace function public.grant_waiver(
  p_user_id uuid, p_course_id uuid, p_amount numeric, p_reason text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v waivers%rowtype;
begin
  perform app_private.require('finance.manage_waiver');
  insert into waivers (user_id, course_id, amount, reason, granted_by)
  values (p_user_id, p_course_id, p_amount, trim(p_reason), app_private.current_user_id())
  returning * into v;
  perform app_private.apply_payment_access(p_user_id, p_course_id);
  return to_jsonb(v);
end;
$$;

create or replace function public.revoke_waiver(p_waiver_id uuid, p_reason text)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform app_private.require('finance.manage_waiver');
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'give a reason' using errcode = 'PT422';
  end if;
  update waivers set revoked_at = now(), revoked_by = app_private.current_user_id(),
    revoke_reason = trim(p_reason)
  where id = p_waiver_id and revoked_at is null;
  if not found then raise exception 'waiver not found' using errcode = 'PT404'; end if;
end;
$$;

create or replace function public.record_expense(
  p_category text, p_amount numeric, p_spent_on date,
  p_description text default null, p_payee text default null, p_currency text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v expenses%rowtype;
begin
  perform app_private.require('finance.record_expense');
  insert into expenses (category, description, payee, amount, currency, spent_on, recorded_by)
  values (trim(p_category), p_description, p_payee, p_amount,
          coalesce(p_currency, (select value from org_settings where key = 'currency'), 'UGX'),
          coalesce(p_spent_on, current_date), app_private.current_user_id())
  returning * into v;
  return to_jsonb(v);
end;
$$;

create or replace function public.void_expense(p_expense_id uuid, p_reason text)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform app_private.require('finance.record_expense');
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'give a reason' using errcode = 'PT422';
  end if;
  update expenses set voided_at = now(), voided_by = app_private.current_user_id(),
    void_reason = trim(p_reason)
  where id = p_expense_id and voided_at is null;
  if not found then raise exception 'expense not found' using errcode = 'PT404'; end if;
end;
$$;

-- ------------------------------------------------------ finance reads --

create or replace function public.finance_summary(
  p_from date default null, p_to date default null, p_course_id uuid default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_from timestamptz := coalesce(p_from, '2000-01-01')::timestamptz;
  v_to timestamptz := (coalesce(p_to, current_date) + 1)::timestamptz;
  v jsonb;
begin
  perform app_private.require('finance.view');
  with enr as (
    select e.user_id, e.course_id, b.*
    from course_enrolments e
    cross join lateral app_private.course_balance(e.user_id, e.course_id) b
    where e.fee_amount is not null and e.fee_amount > 0
      and e.enrolled_at >= v_from and e.enrolled_at < v_to
      and (p_course_id is null or e.course_id = p_course_id)
      and e.status <> 'withdrawn'
  ),
  collected as (
    select coalesce(sum(amount), 0) v from payments
    where status = 'verified' and verified_at >= v_from and verified_at < v_to
      and (p_course_id is null or course_id = p_course_id)
  ),
  refunded as (
    select coalesce(sum(r.amount), 0) v from refunds r join payments p on p.id = r.payment_id
    where r.created_at >= v_from and r.created_at < v_to
      and (p_course_id is null or p.course_id = p_course_id)
  ),
  waived as (
    select coalesce(sum(coalesce(w.amount, b.fee)), 0) v
    from waivers w
    cross join lateral app_private.course_balance(w.user_id, w.course_id) b
    where w.revoked_at is null and w.created_at >= v_from and w.created_at < v_to
      and (p_course_id is null or w.course_id = p_course_id)
  ),
  fees as (
    select coalesce(sum(provider_fee), 0) v from payments
    where status = 'verified' and verified_at >= v_from and verified_at < v_to
      and (p_course_id is null or course_id = p_course_id)
  ),
  spent as (
    select coalesce(sum(amount), 0) v from expenses
    where voided_at is null and spent_on >= v_from::date and spent_on < v_to::date
      and p_course_id is null
  ),
  pending as (
    select count(*) n, coalesce(sum(amount), 0) v from payments
    where status = 'pending' and (p_course_id is null or course_id = p_course_id)
  )
  select jsonb_build_object(
    'currency', coalesce((select value from org_settings where key = 'currency'), 'UGX'),
    'expected', (select coalesce(sum(fee), 0) from enr),
    'outstanding', (select coalesce(sum(outstanding), 0) from enr),
    'collected', collected.v,
    'refunded', refunded.v,
    'waived', waived.v,
    'expenses', spent.v,
    'provider_fees', fees.v,
    -- Retained = verified collections − refunds − provider fees − expenses
    'retained', collected.v - refunded.v - fees.v - spent.v,
    'pending_count', pending.n,
    'pending_amount', pending.v,
    'by_course', (
      select coalesce(jsonb_agg(x order by x->>'title'), '[]') from (
        select jsonb_build_object(
          'course_id', c.id, 'title', c.title,
          'learners', count(enr.*),
          'expected', coalesce(sum(enr.fee), 0),
          'collected', (select coalesce(sum(amount), 0) from payments p
                        where p.course_id = c.id and p.status = 'verified'
                          and p.verified_at >= v_from and p.verified_at < v_to),
          'outstanding', coalesce(sum(enr.outstanding), 0)) x
        from courses c join enr on enr.course_id = c.id
        group by c.id, c.title) t),
    'by_method', (
      select coalesce(jsonb_object_agg(method, total), '{}') from (
        select method, sum(amount) total from payments
        where status = 'verified' and verified_at >= v_from and verified_at < v_to
          and (p_course_id is null or course_id = p_course_id)
        group by method) t))
  into v
  from collected, refunded, waived, fees, spent, pending;
  return v;
end;
$$;

create or replace function public.finance_payments(
  p_status payment_status default null, p_method payment_method default null,
  p_search text default null, p_course_id uuid default null,
  p_limit int default 50, p_offset int default 0)
returns table (
  id uuid, user_id uuid, learner text, course_id uuid, course text,
  amount numeric, currency text, method payment_method, status payment_status,
  external_reference text, phone text, paid_on date, note text, status_reason text,
  recorded_by text, verified_by text, created_at timestamptz, verified_at timestamptz,
  refunded numeric, total bigint)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select p.id, p.user_id, u.display_name, p.course_id, c.title,
         p.amount, p.currency, p.method, p.status,
         p.external_reference, p.phone, p.paid_on, p.note, p.status_reason,
         rb.display_name, vb.display_name, p.created_at, p.verified_at,
         (select coalesce(sum(r.amount), 0) from refunds r where r.payment_id = p.id),
         count(*) over ()
  from payments p
  join users u on u.id = p.user_id
  left join courses c on c.id = p.course_id
  left join users rb on rb.id = p.recorded_by
  left join users vb on vb.id = p.verified_by
  where app_private.has_permission('finance.view')
    and (p_status is null or p.status = p_status)
    and (p_method is null or p.method = p_method)
    and (p_course_id is null or p.course_id = p_course_id)
    and (nullif(trim(p_search), '') is null
         or u.display_name ilike '%' || trim(p_search) || '%'
         or u.phone ilike '%' || trim(p_search) || '%'
         or p.phone ilike '%' || trim(p_search) || '%'
         or p.external_reference ilike '%' || trim(p_search) || '%')
  order by (p.status = 'pending') desc, p.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0)
$$;

-- Who owes what, per enrolment in fee-paying courses.
create or replace function public.finance_balances(
  p_course_id uuid default null, p_only_owing boolean default true)
returns table (user_id uuid, learner text, phone text, course_id uuid, course text,
               fee numeric, paid numeric, refunded numeric, waived numeric,
               outstanding numeric, currency text, enrolment_status enrolment_status)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select e.user_id, u.display_name, u.phone, c.id, c.title,
         b.fee, b.paid, b.refunded, b.waived, b.outstanding, b.currency, e.status
  from course_enrolments e
  join users u on u.id = e.user_id
  join courses c on c.id = e.course_id
  cross join lateral app_private.course_balance(e.user_id, e.course_id) b
  where app_private.has_permission('finance.view')
    and b.fee > 0
    and e.status <> 'withdrawn'
    and (p_course_id is null or e.course_id = p_course_id)
    and (not p_only_owing or b.outstanding > 0)
  order by b.outstanding desc, u.display_name
  limit 500
$$;

create or replace function public.finance_waivers(p_include_revoked boolean default false)
returns table (id uuid, user_id uuid, learner text, course_id uuid, course text,
               amount numeric, reason text, granted_by text, created_at timestamptz,
               revoked_at timestamptz, revoke_reason text)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select w.id, w.user_id, u.display_name, w.course_id, c.title, w.amount, w.reason,
         g.display_name, w.created_at, w.revoked_at, w.revoke_reason
  from waivers w
  join users u on u.id = w.user_id
  join courses c on c.id = w.course_id
  left join users g on g.id = w.granted_by
  where app_private.has_permission('finance.view')
    and (p_include_revoked or w.revoked_at is null)
  order by w.created_at desc
  limit 500
$$;

create or replace function public.finance_expenses(
  p_from date default null, p_to date default null, p_include_voided boolean default false)
returns table (id uuid, category text, description text, payee text, amount numeric,
               currency text, spent_on date, recorded_by text, voided_at timestamptz,
               void_reason text)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select x.id, x.category, x.description, x.payee, x.amount, x.currency, x.spent_on,
         u.display_name, x.voided_at, x.void_reason
  from expenses x left join users u on u.id = x.recorded_by
  where app_private.has_permission('finance.view')
    and (p_include_voided or x.voided_at is null)
    and (p_from is null or x.spent_on >= p_from)
    and (p_to is null or x.spent_on <= p_to)
  order by x.spent_on desc, x.created_at desc
  limit 500
$$;

-- ------------------------------------------------------- enrolments --

-- Staff enrolment now records the fee owed (paid courses) and dates.
create or replace function public.grant_enrolment(
  p_user_id uuid, p_course_id uuid, p_teacher_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_id uuid;
begin
  v_id := (public.bulk_enrol(p_course_id, array[p_user_id]) ->> 'last_id')::uuid;
  if p_teacher_id is not null then
    update course_enrolments set teacher_id = p_teacher_id where id = v_id;
  end if;
  return (select to_jsonb(e) from course_enrolments e where e.id = v_id);
end;
$$;

create or replace function public.bulk_enrol(
  p_course_id uuid, p_user_ids uuid[],
  p_starts_at timestamptz default null, p_ends_at timestamptz default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_course courses%rowtype;
  v_user uuid;
  v_id uuid;
  v_count int := 0;
begin
  if not app_private.has_permission('enrolments.manage') then
    raise exception 'not allowed to enrol learners' using errcode = 'PT403';
  end if;
  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course not found' using errcode = 'PT404'; end if;
  if p_ends_at is not null and p_starts_at is not null and p_ends_at <= p_starts_at then
    raise exception 'the end date must be after the start date' using errcode = 'PT422';
  end if;
  foreach v_user in array coalesce(p_user_ids, '{}') loop
    insert into course_enrolments (course_id, user_id, status, source, granted_by,
                                   starts_at, ends_at, fee_amount, fee_currency)
    values (p_course_id, v_user, 'active', 'admin_grant', app_private.current_user_id(),
            p_starts_at, p_ends_at,
            case when v_course.access = 'paid' then v_course.price_amount end,
            case when v_course.access = 'paid' then v_course.price_currency end)
    on conflict (course_id, user_id) do update set
      status = 'active',
      granted_by = excluded.granted_by,
      starts_at = coalesce(excluded.starts_at, course_enrolments.starts_at),
      ends_at = coalesce(excluded.ends_at, course_enrolments.ends_at),
      fee_amount = coalesce(course_enrolments.fee_amount, excluded.fee_amount),
      fee_currency = coalesce(course_enrolments.fee_currency, excluded.fee_currency)
    returning id into v_id;
    v_count := v_count + 1;
  end loop;
  return jsonb_build_object('enrolled', v_count, 'last_id', v_id);
end;
$$;

create or replace function public.set_enrolment_terms(
  p_enrolment_id uuid, p_starts_at timestamptz, p_ends_at timestamptz,
  p_fee_amount numeric default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v course_enrolments%rowtype;
begin
  perform app_private.require('enrolments.manage');
  if p_fee_amount is not null and not app_private.has_permission('finance.set_fees') then
    raise exception 'not allowed to change fees' using errcode = 'PT403';
  end if;
  update course_enrolments set starts_at = p_starts_at, ends_at = p_ends_at,
    fee_amount = coalesce(p_fee_amount, fee_amount), updated_at = now()
  where id = p_enrolment_id returning * into v;
  if not found then raise exception 'enrolment not found' using errcode = 'PT404'; end if;
  return to_jsonb(v);
end;
$$;

-- --------------------------------------------------------- grants --

do $$
declare r record;
begin
  for r in select p.oid::regprocedure as fn
           from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.proname in (
             'org_settings', 'set_org_setting', 'start_course_payment',
             'submit_manual_payment', 'my_payments', 'my_course_balance',
             'record_payment', 'verify_payment', 'reject_payment', 'reverse_payment',
             'record_refund', 'grant_waiver', 'revoke_waiver', 'record_expense',
             'void_expense', 'finance_summary', 'finance_payments', 'finance_balances',
             'finance_waivers', 'finance_expenses', 'grant_enrolment', 'bulk_enrol',
             'set_enrolment_terms') loop
    execute format('revoke all on function %s from public', r.fn);
    execute format('grant execute on function %s to authenticated, sidra_app', r.fn);
  end loop;
end $$;
revoke all on function app_private.course_balance(uuid, uuid),
  app_private.apply_payment_access(uuid, uuid) from public;

-- The payments server's own login (password set by `tool/db.dart payments-role`).
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'sidra_payments') then
    create role sidra_payments nologin;
  end if;
end $$;
alter role sidra_payments set statement_timeout = '20s';
-- The owner may act as it (tests, maintenance); it gains nothing else.
do $$ begin
  execute format('grant sidra_payments to %I', current_user);
end $$;
grant usage on schema payments_api to sidra_payments;
revoke all on all functions in schema payments_api from public;
grant execute on all functions in schema payments_api to sidra_payments;
