-- 0041 MarzPay straight from the app (the owner's decision, 2026-09-29).
--
-- The app holds the MarzPay credentials and talks to MarzPay itself:
--   1. start_course_payment (unchanged) creates the payment and its reference;
--   2. the payer's app sends the collection and records MarzPay's id
--      (marzpay_submitted), then reports MarzPay's final answer
--      (marzpay_result). A success opens the course at once;
--   3. because a payer's app could lie, every such payment is re-checked
--      against MarzPay by a staff phone (marzpay_to_confirm /
--      marzpay_confirm): same reference, same amount, successful. Anything
--      else is reversed and the course closed again.
-- The payments server, if ever hosted, still works alongside.
-- Test-centre tests can also run on the admin's phone (p_run_here).

alter table payments
  add column verified_via text check (verified_via in ('payments_server', 'payer_app', 'staff_app', 'finance')),
  add column ledger_confirmed_at timestamptz;

-- Payers' apps need the reference and MarzPay id of their own payments.
create or replace function app_private.payment_json(p payments)
returns jsonb
language sql stable
as $$
  select jsonb_build_object(
    'id', p.id, 'course_id', p.course_id, 'amount', p.amount, 'currency', p.currency,
    'method', p.method, 'status', p.status, 'status_reason', p.status_reason,
    'phone', p.phone, 'external_reference', p.external_reference,
    'reference', p.reference, 'provider_uuid', p.provider_uuid,
    'created_at', p.created_at, 'verified_at', p.verified_at)
$$;

-- The payer's app sent the collection: record MarzPay's id.
create or replace function public.marzpay_submitted(
  p_payment_id uuid, p_provider_uuid text, p_provider text default null, p_status text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v payments%rowtype;
begin
  update payments set status = 'processing', provider_uuid = p_provider_uuid,
    provider = coalesce(p_provider, 'marzpay'), last_error = null, next_attempt_at = null,
    attempts = attempts + 1, updated_at = now()
  where id = p_payment_id and user_id = app_private.current_user_id()
    and method = 'marzpay' and status in ('initiated', 'processing')
    and (provider_uuid is null or provider_uuid = p_provider_uuid)
  returning * into v;
  if not found then raise exception 'payment not found' using errcode = 'PT404'; end if;
  return app_private.payment_json(v);
end;
$$;

-- MarzPay refused the request (bad number, limits…).
create or replace function public.marzpay_send_failed(p_payment_id uuid, p_error text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v payments%rowtype;
begin
  update payments set status = 'failed', status_reason = left(p_error, 500), last_error = left(p_error, 500),
    updated_at = now()
  where id = p_payment_id and user_id = app_private.current_user_id()
    and method = 'marzpay' and status = 'initiated'
  returning * into v;
  if not found then raise exception 'payment not found' using errcode = 'PT404'; end if;
  return app_private.payment_json(v);
end;
$$;

-- MarzPay's final answer, as the payer's app read it. The reference must be
-- the payment's own; the amount is checked by settle(). The course opens
-- now; a staff phone confirms it against MarzPay later.
create or replace function public.marzpay_result(
  p_payment_id uuid, p_status text, p_amount numeric, p_reference text,
  p_provider_ref text default null, p_fee numeric default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v payments%rowtype;
  v_outcome text;
begin
  select * into v from payments
  where id = p_payment_id and user_id = app_private.current_user_id() and method = 'marzpay';
  if not found or v.provider_uuid is null then
    raise exception 'payment not found' using errcode = 'PT404';
  end if;
  if p_reference is distinct from v.reference::text then
    raise exception 'this MarzPay transaction belongs to another payment' using errcode = 'PT409';
  end if;
  v_outcome := payments_api.settle(v.provider_uuid, p_status, p_amount, p_provider_ref,
                                   jsonb_build_object('reported_by', 'payer_app', 'status', p_status), p_fee);
  if v_outcome = 'verified' then
    update payments set verified_via = 'payer_app' where id = v.id and verified_via is null;
  end if;
  select * into v from payments where id = v.id;
  return app_private.payment_json(v);
end;
$$;

-- For staff phones: payments to check against MarzPay — reported by a
-- payer's app and not yet confirmed, or still waiting (the payer's app may
-- have closed).
create or replace function public.marzpay_to_confirm(p_limit int default 20)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.has_permission('finance.verify_payment') then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  return query
    select jsonb_build_object('id', p.id, 'provider_uuid', p.provider_uuid, 'reference', p.reference,
                              'amount', p.amount, 'status', p.status)
    from payments p
    where p.method = 'marzpay' and p.provider_uuid is not null
      and p.created_at > now() - make_interval(days => app_private.int_setting('payment_unanswered_days', 7) + 1)
      and ((p.status = 'verified' and p.ledger_confirmed_at is null and p.verified_via = 'payer_app')
           or (p.status = 'processing' and p.updated_at < now() - interval '1 minute'))
    order by p.updated_at
    limit least(greatest(p_limit, 1), 100);
end;
$$;

-- A staff phone reports what MarzPay itself says about a payment.
create or replace function public.marzpay_confirm(
  p_payment_id uuid, p_status text, p_amount numeric, p_reference text,
  p_provider_ref text default null, p_fee numeric default null)
returns text
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v payments%rowtype;
  v_outcome text;
  v_ok boolean;
begin
  perform app_private.require('finance.verify_payment');
  select * into v from payments where id = p_payment_id and method = 'marzpay' for update;
  if not found then raise exception 'payment not found' using errcode = 'PT404'; end if;
  v_ok := p_reference = v.reference::text
          and lower(coalesce(p_status, '')) in ('successful', 'completed', 'success')
          and p_amount = v.amount;
  if v.status = 'verified' then
    if v_ok then
      update payments set ledger_confirmed_at = now() where id = v.id;
      return 'confirmed';
    end if;
    -- The payer's app said "paid" but MarzPay disagrees.
    perform public.reverse_payment(v.id,
      format('MarzPay does not confirm this payment (status %s, amount %s, reference %s)',
             coalesce(p_status, '?'), coalesce(p_amount::text, '?'),
             case when p_reference = v.reference::text then 'matches' else 'differs' end));
    update payments set verified_via = null where id = v.id;
    return 'reversed';
  end if;
  if v.status = 'processing' then
    if p_reference is distinct from v.reference::text then
      update payments set status = 'failed', status_reason = 'the MarzPay id belongs to another payment',
        updated_at = now() where id = v.id;
      return 'failed';
    end if;
    v_outcome := payments_api.settle(v.provider_uuid, p_status, p_amount, p_provider_ref,
                                     jsonb_build_object('reported_by', 'staff_app', 'status', p_status), p_fee);
    if v_outcome = 'verified' then
      update payments set verified_via = 'staff_app', ledger_confirmed_at = now() where id = v.id;
    end if;
    return v_outcome;
  end if;
  return v.status::text;
end;
$$;

-- The payments server marks what it verifies.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('payments_api.settle(text, text, numeric, text, jsonb, numeric)'::regprocedure);
  if position('    update payments set status = ''verified'', verified_at = now(),' in v_src) = 0 then
    raise exception 'settle changed; update 0041';
  end if;
  execute replace(v_src, '    update payments set status = ''verified'', verified_at = now(),',
    '    update payments set status = ''verified'', verified_at = now(),
      verified_via = case when coalesce(p_payload->>''reported_by'', '''') = '''' then ''payments_server'' end,
      ledger_confirmed_at = case when coalesce(p_payload->>''reported_by'', '''') = '''' then now() end,');
end $$;

-- ------------------------------------------------ tests on the phone --
drop function public.request_payment_test(text, jsonb, text);
create function public.request_payment_test(
  p_kind text, p_params jsonb default '{}', p_confirm text default null, p_run_here boolean default false)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_id uuid;
  v_phone text;
  v_amount int;
  v_real boolean := p_kind in ('collection', 'disbursement');
  v_params jsonb := coalesce(p_params, '{}');
  v_max int := app_private.int_setting('marzpay_test_max_amount', 1000);
begin
  if not app_private.has_permission('payments.test') then
    raise exception 'not allowed to test payments' using errcode = 'PT403';
  end if;
  if coalesce((select value from org_settings where key = 'marzpay_tests_enabled'), 'true') <> 'true' then
    raise exception 'MarzPay tests are switched off (Settings → MarzPay)' using errcode = 'PT409';
  end if;
  if p_kind not in ('connection', 'capabilities', 'balance', 'collection', 'disbursement',
                    'status_lookup', 'callbacks', 'reconciliation') then
    raise exception 'unknown test' using errcode = 'PT422';
  end if;
  if v_real then
    if p_kind = 'disbursement'
       and coalesce((select value from org_settings where key = 'marzpay_disbursement_tests_enabled'), 'false') <> 'true' then
      raise exception 'sending-money tests are off; switch them on in Settings → MarzPay first'
        using errcode = 'PT409';
    end if;
    v_phone := app_private.normalize_ug_phone(v_params->>'phone');
    if v_phone is null then
      raise exception 'enter an MTN or Airtel Uganda number' using errcode = 'PT422';
    end if;
    v_amount := case when v_params->>'amount' ~ '^\d{1,9}$' then (v_params->>'amount')::int end;
    if v_amount is null or v_amount < 500 or v_amount > v_max then
      raise exception 'test amounts must be between 500 and % UGX (Settings → MarzPay)', v_max
        using errcode = 'PT422';
    end if;
    if coalesce(trim(p_confirm), '') <> format('%s UGX %s', v_amount, v_phone) then
      raise exception 'type the confirmation exactly: % UGX %', v_amount, v_phone
        using errcode = 'PT422';
    end if;
    v_params := v_params - 'phone' || jsonb_build_object('phone', app_private.mask_phone(v_phone),
                                                         'amount', v_amount, 'currency', 'UGX');
  end if;
  insert into payment_tests (requested_by, kind, params, real_money, reference, status, started_at, environment)
  values (app_private.current_user_id(), p_kind, v_params, v_real,
          case when v_real then gen_random_uuid()::text end,
          case when p_run_here then 'running' else 'queued' end,
          case when p_run_here then now() end,
          case when p_run_here then 'app' end)
  returning id into v_id;
  if v_real and not p_run_here then
    insert into app_private.payment_test_targets (test_id, phone) values (v_id, v_phone);
  end if;
  if not p_run_here then perform pg_notify('sidra_payments', 'tests'); end if;
  return v_id;
end;
$$;

-- Steps and results of a test running on the requester's phone.
create or replace function public.payment_test_step(p_id uuid, p_step jsonb)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update payment_tests set steps = steps || jsonb_build_array(p_step || jsonb_build_object('at', now()))
  where id = p_id and status = 'running' and requested_by = app_private.current_user_id()
    and app_private.has_permission('payments.test')
$$;

create or replace function public.payment_test_finish(
  p_id uuid, p_result text, p_provider_uuid text default null, p_provider_status text default null,
  p_error_code text default null, p_message text default null, p_evidence jsonb default '{}',
  p_environment text default null)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update payment_tests set status = 'done', result = p_result, finished_at = now(),
    provider_uuid = coalesce(p_provider_uuid, provider_uuid), provider_status = p_provider_status,
    error_code = p_error_code, message = left(p_message, 2000),
    evidence = coalesce(p_evidence, '{}'), environment = coalesce(p_environment, environment)
  where id = p_id and status = 'running' and requested_by = app_private.current_user_id()
    and app_private.has_permission('payments.test')
$$;

revoke all on function public.marzpay_submitted(uuid, text, text, text), public.marzpay_send_failed(uuid, text),
  public.marzpay_result(uuid, text, numeric, text, text, numeric), public.marzpay_to_confirm(int),
  public.marzpay_confirm(uuid, text, numeric, text, text, numeric),
  public.request_payment_test(text, jsonb, text, boolean), public.payment_test_step(uuid, jsonb),
  public.payment_test_finish(uuid, text, text, text, text, text, jsonb, text) from public, anonymous;
grant execute on function public.marzpay_submitted(uuid, text, text, text), public.marzpay_send_failed(uuid, text),
  public.marzpay_result(uuid, text, numeric, text, text, numeric), public.marzpay_to_confirm(int),
  public.marzpay_confirm(uuid, text, numeric, text, text, numeric),
  public.request_payment_test(text, jsonb, text, boolean), public.payment_test_step(uuid, jsonb),
  public.payment_test_finish(uuid, text, text, text, text, text, jsonb, text) to authenticated, sidra_app;

select app_private.lock_down_functions();
