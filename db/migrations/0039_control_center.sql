-- 0039 Control centre: settings you can trace, system health, diagnostics,
-- a MarzPay test centre with proof, payment tracing, security overview.
-- See docs/PHASE5_AUDIT.md.

insert into permissions (key, area, description) values
  ('payments.test', 'finance', 'Run MarzPay tests, including real small-money tests'),
  ('system.diagnose', 'settings', 'See system health and run diagnostics')
on conflict (key) do nothing;
insert into role_permissions (role_key, permission_key)
select r, p from (values ('super_admin', 'payments.test'), ('super_admin', 'system.diagnose'),
                         ('admin', 'system.diagnose')) v(r, p)
where exists (select 1 from app_roles where key = r)
on conflict do nothing;

insert into org_settings (key, value, is_public) values
  -- MarzPay test centre safety
  ('marzpay_tests_enabled', 'true', false),
  ('marzpay_test_max_amount', '1000', false),
  ('marzpay_disbursement_tests_enabled', 'false', false),
  -- uploads (the app checks before sending; Cloudinary's own plan limit also applies)
  ('upload_max_mb', '100', true)
on conflict (key) do nothing;

do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.set_org_setting(text, text)'::regprocedure);
  if position('  update org_settings set value = v' in v_src) = 0 then
    raise exception 'set_org_setting changed; update 0039';
  end if;
  execute replace(v_src, '  update org_settings set value = v',
$r$  if p_key in ('marzpay_tests_enabled', 'marzpay_disbursement_tests_enabled')
     and coalesce(v, '') not in ('true', 'false') then
    raise exception '% must be on or off', p_key using errcode = 'PT422';
  end if;
  if p_key = 'marzpay_test_max_amount' and (v !~ '^\d+$' or v::int not between 500 and 100000) then
    raise exception 'the test limit must be between 500 and 100,000 UGX' using errcode = 'PT422';
  end if;
  if p_key = 'upload_max_mb' and (v !~ '^\d+$' or v::int not between 1 and 500) then
    raise exception 'the upload limit must be between 1 and 500 MB' using errcode = 'PT422';
  end if;
  update org_settings set value = v$r$);
end $$;

-- ---------------------------------------------- settings: who and why --
-- Fix: the audit trigger took the entity id from `id`/`user_id`, which
-- org_settings doesn't have, so updated settings weren't named. It now
-- falls back to `key`, and records the reason given for a change.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('app_private.audit()'::regprocedure);
  if position('v_new->>''user_id'', v_old->>''user_id'');' in v_src) = 0
     or position('tg_table_name, v_id, v_changes);' in v_src) = 0 then
    raise exception 'audit() changed; update 0039';
  end if;
  v_src := replace(v_src, 'v_new->>''user_id'', v_old->>''user_id'');',
    'v_new->>''user_id'', v_old->>''user_id'', v_new->>''key'', v_old->>''key'');');
  v_src := replace(v_src, 'insert into audit_log (actor_id, action, entity, entity_id, changes)',
    'insert into audit_log (actor_id, action, entity, entity_id, changes, note)');
  execute replace(v_src, 'tg_table_name, v_id, v_changes);',
    'tg_table_name, v_id, v_changes, nullif(current_setting(''sidra.change_reason'', true), ''''));');
end $$;

-- Change a setting and say why.
create or replace function public.set_org_setting_reason(p_key text, p_value text, p_reason text)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  perform set_config('sidra.change_reason', left(coalesce(trim(p_reason), ''), 300), true);
  perform public.set_org_setting(p_key, p_value);
  perform set_config('sidra.change_reason', '', true);
end;
$$;

-- Who changed which setting, from what to what, when and why.
create or replace function public.settings_history(p_key text default null, p_limit int default 100)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not (app_private.has_permission('settings.manage') or app_private.has_permission('audit.view')) then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  return query
    select jsonb_build_object(
      'at', a.at, 'key', a.entity_id, 'action', a.action,
      'from', a.changes->'value'->'from', 'to', coalesce(a.changes->'value'->'to', a.changes->'value'),
      'reason', a.note,
      'actor_name', (select display_name from users where id = a.actor_id))
    from audit_log a
    where a.entity = 'org_settings' and a.entity_id is not null
      and (p_key is null or a.entity_id = p_key)
    order by a.at desc
    limit least(greatest(p_limit, 1), 500);
end;
$$;

-- Last change per setting (for "changed by … on …" next to each value).
create or replace function public.settings_last_changes()
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.has_permission('settings.manage') then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  return query
    select distinct on (a.entity_id) jsonb_build_object(
      'key', a.entity_id, 'at', a.at, 'reason', a.note,
      'actor_name', (select display_name from users where id = a.actor_id))
    from audit_log a
    where a.entity = 'org_settings' and a.entity_id is not null
    order by a.entity_id, a.at desc;
end;
$$;

-- ------------------------------------------------ MarzPay test centre --
create table payment_tests (
  id uuid primary key default gen_random_uuid(),
  requested_by uuid references users (id) on delete set null,
  kind text not null check (kind in ('connection', 'capabilities', 'balance', 'collection',
    'disbursement', 'status_lookup', 'callbacks', 'reconciliation')),
  -- what the admin entered, with the phone masked (+2567••••483)
  params jsonb not null default '{}',
  real_money boolean not null default false,
  reference text,
  status text not null default 'queued' check (status in ('queued', 'running', 'done')),
  -- [{step, label, state: done|failed|waiting|skipped, detail, at}]
  steps jsonb not null default '[]',
  result text check (result in ('verified_success', 'provider_accepted', 'failed', 'cancelled',
    'pending', 'unknown', 'blocked', 'unsupported')),
  provider_uuid text,
  provider_status text,
  error_code text,
  message text,
  evidence jsonb not null default '{}',
  environment text,
  created_at timestamptz not null default now(),
  started_at timestamptz,
  finished_at timestamptz
);
create index payment_tests_recent on payment_tests (created_at desc);
alter table payment_tests enable row level security;
create policy payment_tests_read on payment_tests for select to public
  using (app_private.has_permission('payments.test') or app_private.has_permission('finance.view'));
grant select on payment_tests to authenticated, sidra_app;
create trigger payment_tests_audit after insert on payment_tests
  for each row execute function app_private.audit();

-- The full phone number of a money test lives here, readable by nobody but
-- the database owner and the payments server's claim function.
create table app_private.payment_test_targets (
  test_id uuid primary key references payment_tests (id) on delete cascade,
  phone text
);

create or replace function app_private.mask_phone(p text)
returns text language sql immutable
as $$ select case when p is null then null
                  when length(p) <= 7 then '••••'
                  else left(p, 5) || '••••' || right(p, 3) end $$;

-- An admin asks for a test. Money tests need: the switch on, the amount
-- within the limit, and p_confirm typed exactly as "<amount> UGX <phone>".
-- Nothing runs on page load; nothing is retried automatically.
create or replace function public.request_payment_test(
  p_kind text, p_params jsonb default '{}', p_confirm text default null)
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
  insert into payment_tests (requested_by, kind, params, real_money, reference)
  values (app_private.current_user_id(), p_kind, v_params, v_real,
          case when v_real then gen_random_uuid()::text end)
  returning id into v_id;
  if v_real then
    insert into app_private.payment_test_targets (test_id, phone) values (v_id, v_phone);
  end if;
  perform pg_notify('sidra_payments', 'tests');
  return v_id;
end;
$$;

create or replace function public.payment_tests(p_limit int default 50)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not (app_private.has_permission('payments.test') or app_private.has_permission('finance.view')) then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  return query
    select to_jsonb(t) || jsonb_build_object('requested_by_name',
             (select display_name from users where id = t.requested_by))
    from payment_tests t order by t.created_at desc limit least(greatest(p_limit, 1), 200);
end;
$$;

-- Server side: claim one queued test (with the phone for money tests).
-- A test left "running" for 15 minutes (server crash) becomes UNKNOWN,
-- never re-sent.
create or replace function payments_api.claim_test()
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v payment_tests%rowtype;
begin
  update payment_tests set status = 'done', result = 'unknown', finished_at = now(),
    message = 'The payments server stopped during this test. Check the transaction at MarzPay before trying again.'
  where status = 'running' and started_at < now() - interval '15 minutes';
  if coalesce((select value from org_settings where key = 'marzpay_tests_enabled'), 'true') <> 'true' then
    return null;
  end if;
  update payment_tests set status = 'running', started_at = now()
  where id = (select id from payment_tests where status = 'queued' order by created_at
              limit 1 for update skip locked)
  returning * into v;
  if not found then return null; end if;
  return to_jsonb(v) || jsonb_build_object('target_phone',
           (select phone from app_private.payment_test_targets where test_id = v.id));
end;
$$;

create or replace function payments_api.test_step(p_id uuid, p_step jsonb)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update payment_tests set steps = steps || jsonb_build_array(p_step || jsonb_build_object('at', now()))
  where id = p_id and status = 'running'
$$;

create or replace function payments_api.finish_test(
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
    evidence = coalesce(p_evidence, '{}'), environment = p_environment
  where id = p_id;
  delete from app_private.payment_test_targets where test_id = p_id;
$$;

-- For the server's lookup and reconciliation tests: Sidra's view of payments.
create or replace function payments_api.sidra_payment(p_query text)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select to_jsonb(p) - 'provider_payload' - 'phone'
  from payments p
  where p.id::text = p_query or p.provider_uuid = p_query or p.reference::text = p_query
     or p.external_reference = p_query
  order by p.created_at desc limit 1
$$;

create or replace function payments_api.sidra_marzpay_payments(p_days int default 30)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'reference', reference, 'provider_uuid', provider_uuid,
                                               'status', status, 'amount', amount)), '[]')
  from payments
  where method = 'marzpay' and created_at > now() - make_interval(days => p_days)
$$;

-- ---------------------------------------------------------- webhooks --
create table payment_webhooks (
  id bigserial primary key,
  received_at timestamptz not null default now(),
  provider_uuid text,
  event text,
  body_valid boolean not null,
  duplicate boolean not null default false,
  outcome text,
  payment_id uuid references payments (id) on delete set null,
  error text
);
create index payment_webhooks_recent on payment_webhooks (received_at desc);
alter table payment_webhooks enable row level security;
create policy payment_webhooks_read on payment_webhooks for select to public
  using (app_private.has_permission('payments.test') or app_private.has_permission('finance.view'));
grant select on payment_webhooks to authenticated, sidra_app;

create or replace function payments_api.log_webhook(
  p_provider_uuid text, p_event text, p_body_valid boolean, p_outcome text, p_error text default null)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  insert into payment_webhooks (provider_uuid, event, body_valid, duplicate, outcome, payment_id, error)
  values (p_provider_uuid, left(p_event, 60), p_body_valid,
          exists (select 1 from payment_webhooks w where w.provider_uuid = p_provider_uuid
                  and w.outcome = p_outcome and p_provider_uuid is not null),
          left(p_outcome, 60),
          (select id from payments where provider_uuid = p_provider_uuid),
          left(p_error, 500))
$$;

-- ------------------------------------------------------ payment trace --
-- "I paid but Sidra says unpaid": everything Sidra knows about payments
-- matching a learner name/phone, a Sidra id, a MarzPay id or a reference.
create or replace function public.payment_trace(p_query text)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare v_q text := trim(coalesce(p_query, ''));
begin
  if not app_private.has_permission('finance.view') then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  if length(v_q) < 3 then return; end if;
  return query
    select jsonb_build_object(
      'payment', to_jsonb(p) - 'provider_payload',
      'learner', (select jsonb_build_object('id', u.id, 'name', u.display_name, 'phone', u.phone)
                  from users u where u.id = p.user_id),
      'course', (select title from courses where id = p.course_id),
      'balance', (select to_jsonb(b) from app_private.course_balance(p.user_id, p.course_id) b
                  where p.course_id is not null),
      'enrolment', (select e.status from course_enrolments e
                    where e.user_id = p.user_id and e.course_id = p.course_id),
      'history', (select coalesce(jsonb_agg(jsonb_build_object('at', a.at, 'action', a.action,
                           'changes', a.changes - 'provider_payload',
                           'actor', (select display_name from users where id = a.actor_id))
                         order by a.at), '[]')
                  from audit_log a where a.entity = 'payments' and a.entity_id = p.id::text),
      'webhooks', (select coalesce(jsonb_agg(to_jsonb(w) order by w.received_at), '[]')
                   from payment_webhooks w where w.provider_uuid = p.provider_uuid),
      'provider_status', p.provider_payload->'data'->'transaction'->>'status')
    from payments p
    left join users u on u.id = p.user_id
    where p.id::text = v_q or p.provider_uuid = v_q or p.reference::text = v_q
       or p.external_reference = v_q
       or u.display_name ilike '%' || v_q || '%'
       or u.phone = app_private.normalize_ug_phone(v_q) or p.phone = app_private.normalize_ug_phone(v_q)
    order by p.created_at desc
    limit 30;
end;
$$;

-- -------------------------------------------------------- diagnostics --
create table diagnostic_runs (
  id bigserial primary key,
  at timestamptz not null default now(),
  run_by uuid references users (id) on delete set null,
  component text not null,
  result text not null check (result in ('ok', 'warning', 'failed', 'blocked')),
  tested text,
  expected text,
  happened text,
  next_action text,
  latency_ms int,
  device text
);
create index diagnostic_runs_recent on diagnostic_runs (component, at desc);
alter table diagnostic_runs enable row level security;
create policy diagnostic_runs_read on diagnostic_runs for select to public
  using (app_private.has_permission('system.diagnose'));
grant select on diagnostic_runs to authenticated, sidra_app;

create or replace function public.record_diagnostic(
  p_component text, p_result text, p_tested text, p_expected text, p_happened text,
  p_next_action text default null, p_latency_ms int default null, p_device text default null)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.has_permission('system.diagnose') then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  insert into diagnostic_runs (run_by, component, result, tested, expected, happened, next_action, latency_ms, device)
  values (app_private.current_user_id(), left(p_component, 40), p_result, left(p_tested, 300),
          left(p_expected, 300), left(p_happened, 1000), left(p_next_action, 500), p_latency_ms, left(p_device, 100));
end;
$$;

create or replace function public.diagnostic_history(p_component text default null, p_limit int default 50)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.has_permission('system.diagnose') then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  return query
    select to_jsonb(d) || jsonb_build_object('run_by_name', (select display_name from users where id = d.run_by))
    from diagnostic_runs d
    where p_component is null or d.component = p_component
    order by d.at desc limit least(greatest(p_limit, 1), 300);
end;
$$;

-- A notification to yourself, to test the phone notification pipeline.
create or replace function public.send_test_notification()
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.has_permission('system.diagnose') then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  insert into notifications (user_id, kind, title, body, data)
  values (app_private.current_user_id(), 'diagnostic', 'Sidra test notification',
          'If you see this on the notification bar, phone notifications work.', '{}');
end;
$$;

-- ------------------------------------------------------ system health --
-- One call answers "is Sidra healthy right now?", part by part.
create or replace function public.system_health()
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_server app_private.payment_server_status%rowtype;
  v_tests jsonb;
begin
  if not app_private.has_permission('system.diagnose') then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  select * into v_server from app_private.payment_server_status limit 1;
  select coalesce(jsonb_object_agg(kind, j), '{}') into v_tests from (
    select distinct on (kind) kind, jsonb_build_object('result', result, 'at', coalesce(finished_at, created_at),
                                                       'status', status, 'message', message) j
    from payment_tests order by kind, created_at desc) s;
  return jsonb_build_object(
    'checked_at', now(),
    'database', jsonb_build_object(
      'ok', true,
      'latest_migration', (select filename from schema_migrations order by filename desc limit 1),
      'migrations', (select count(*) from schema_migrations)),
    'payments_server', jsonb_build_object(
      'last_seen', v_server.last_seen, 'version', v_server.version,
      'public_url', v_server.public_url is not null and v_server.public_url <> '',
      'online', coalesce(v_server.last_seen > now() - interval '90 seconds', false)),
    'marzpay', jsonb_build_object(
      'enabled', coalesce((select value from org_settings where key = 'marzpay_enabled'), 'true') = 'true',
      'tests_enabled', coalesce((select value from org_settings where key = 'marzpay_tests_enabled'), 'true') = 'true',
      'latest_tests', v_tests,
      'verified_payments', (select count(*) from payments where method = 'marzpay' and status = 'verified'),
      'stuck', (select count(*) from payments where method = 'marzpay' and status in ('initiated', 'processing')
                and created_at < now() - interval '1 hour')),
    'storage', jsonb_build_object(
      'configured', (select count(*) = 3 from app_private.settings
                     where key in ('cloudinary_cloud_name', 'cloudinary_api_key', 'cloudinary_api_secret')
                       and coalesce(value, '') <> ''),
      'last_upload', (select max(created_at) from media_assets),
      'uploads_24h', (select count(*) from media_assets where created_at > now() - interval '1 day'),
      'purge_waiting', (select count(*) from app_private.media_purge where purged_at is null)),
    'notifications', jsonb_build_object(
      'sent_24h', (select count(*) from notifications where created_at > now() - interval '1 day'),
      'phones_registered', (select count(*) from app_private.notification_tokens),
      'phones_checked_1h', (select count(*) from app_private.notification_tokens
                            where last_used_at > now() - interval '1 hour'),
      'devices_blocking', (select count(*) from app_private.devices
                           where notifications_allowed = false and revoked_at is null)),
    'security', jsonb_build_object(
      'failed_sign_ins_24h', (select count(*) from app_private.auth_events
                              where kind = 'sign_in_failed' and at > now() - interval '1 day'),
      'throttled_24h', (select count(*) from app_private.auth_events
                        where kind = 'sign_in_throttled' and at > now() - interval '1 day'),
      'locked_now', (select count(*) from app_private.credentials where locked_until > now()),
      'devices_revoked_7d', (select count(*) from app_private.devices where revoked_at > now() - interval '7 days'),
      'accounts_on_many_devices', (select count(*) from (
          select user_id from app_private.devices d where d.revoked_at is null and exists (
            select 1 from app_private.refresh_tokens r where r.device_id = d.id
              and r.revoked_at is null and r.expires_at > now())
          group by user_id having count(*) > 3) x)),
    'learning', jsonb_build_object(
      'active_learners_7d', (select count(*) from app_private.dashboard_rows('active_learners_7d')),
      'open_problem_reports', (select count(*) from work_issues where status <> 'resolved'),
      'late_work', (select count(*) from learner_policy_events where resolved_at is null
                    and kind in ('overdue', 'escalated')),
      'suspended', (select count(*) from course_enrolments where status = 'suspended'),
      'waiting_review_48h', (select count(*) from submissions where status in ('submitted', 'received')
                             and submitted_at < now() - interval '48 hours'),
      'policies_last_run', (select value from org_settings where key = 'policy_last_run')),
    'payments', jsonb_build_object(
      'manual_waiting', (select count(*) from payments where status = 'pending'),
      'stuck_mobile_money', (select count(*) from payments where method = 'marzpay'
                             and status in ('initiated', 'processing') and created_at < now() - interval '1 hour')),
    'app', jsonb_build_object(
      'latest_build', (select value from org_settings where key = 'latest_app_build'),
      'latest_version', (select value from org_settings where key = 'latest_app_version'),
      'min_supported_build', (select value from org_settings where key = 'min_supported_build'),
      'builds_in_use', (select coalesce(jsonb_object_agg(coalesce(app_build::text, '?'), n), '{}') from (
          select app_build, count(*) n from app_private.devices
          where revoked_at is null and last_contact_at > now() - interval '30 days'
          group by app_build) b)),
    'recent_failed_diagnostics', (select count(*) from diagnostic_runs
                                  where result = 'failed' and at > now() - interval '1 day'));
end;
$$;

-- Sign-in problems at a glance (sessions.view).
create or replace function public.security_events(p_limit int default 100)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.has_permission('sessions.view') then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  return query
    select jsonb_build_object('at', e.at, 'kind', e.kind, 'user_id', e.user_id,
      'name', (select display_name from users where id = e.user_id),
      'known_account', e.user_id is not null, 'detail', e.detail,
      'actor_name', (select display_name from users where id = e.actor_id))
    from app_private.auth_events e
    where e.kind in ('sign_in_failed', 'sign_in_locked', 'sign_in_throttled', 'sign_in_disabled',
                     'refresh_rejected', 'device_revoked', 'sessions_ended')
    order by e.at desc limit least(greatest(p_limit, 1), 500);
end;
$$;

revoke all on function public.set_org_setting_reason(text, text, text), public.settings_history(text, int),
  public.settings_last_changes(), public.request_payment_test(text, jsonb, text), public.payment_tests(int),
  public.payment_trace(text), public.record_diagnostic(text, text, text, text, text, text, int, text),
  public.diagnostic_history(text, int), public.send_test_notification(), public.system_health(),
  public.security_events(int) from public, anonymous;
grant execute on function public.set_org_setting_reason(text, text, text), public.settings_history(text, int),
  public.settings_last_changes(), public.request_payment_test(text, jsonb, text), public.payment_tests(int),
  public.payment_trace(text), public.record_diagnostic(text, text, text, text, text, text, int, text),
  public.diagnostic_history(text, int), public.send_test_notification(), public.system_health(),
  public.security_events(int) to authenticated, sidra_app;

grant execute on function payments_api.claim_test(), payments_api.test_step(uuid, jsonb),
  payments_api.finish_test(uuid, text, text, text, text, text, jsonb, text),
  payments_api.sidra_payment(text), payments_api.sidra_marzpay_payments(int),
  payments_api.log_webhook(text, text, boolean, text, text) to sidra_payments;

select app_private.lock_down_functions();
