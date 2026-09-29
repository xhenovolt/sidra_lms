-- 0035 Devices, sessions per device, presence, and sign-in protection.
--
-- Separates what used to be one thing:
--   account   users.is_active / removed_at (unchanged)
--   session   refresh + access tokens, now tied to the device that signed in
--   device    one row per app installation (install id chosen by the app)
--   online    devices.last_contact_at: the phone last reached the server
--   active    devices.last_active_at: the person last used the app
-- Administrators (sessions.view / sessions.manage) can see every device and
-- sign out one device or every session; each such action is recorded.
--
-- Sign-in protection:
--   * a lock that has run out starts a fresh count, and each further lock
--     lasts twice as long (up to a day); a day without locks resets it;
--   * unknown phone numbers are locked out exactly like real ones, so the
--     answers never reveal who has an account;
--   * a whole-system brake: when too many sign-ins fail in one minute
--     (someone trying many accounts), sign-in answers "try later".

insert into permissions (key, area, description) values
  ('sessions.view', 'people', 'See sign-ins, sessions and devices'),
  ('sessions.manage', 'people', 'Sign out devices and end sessions')
on conflict (key) do nothing;
insert into role_permissions (role_key, permission_key)
select r, p from unnest(array['super_admin', 'admin']) r,
                 unnest(array['sessions.view', 'sessions.manage']) p
where exists (select 1 from app_roles where key = r)
on conflict do nothing;

insert into org_settings (key, value, is_public) values
  ('signin_failures_per_minute', '60', false),
  ('presence_online_minutes', '5', false),
  ('auth_events_keep_days', '180', false)
on conflict (key) do nothing;

-- ------------------------------------------------------------- devices --

create table app_private.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users (id) on delete cascade,
  install_id text not null check (length(install_id) between 8 and 64),
  manufacturer text,
  model text,
  os text,
  os_version text,
  sdk_int int,
  app_version text,
  app_build int,
  locale text,
  time_zone text,
  notifications_allowed boolean,
  microphone_allowed boolean,
  network text,
  storage_free_mb bigint,
  first_seen_at timestamptz not null default now(),
  last_sign_in_at timestamptz,
  last_contact_at timestamptz,
  last_active_at timestamptz,
  last_sync_at timestamptz,
  signed_out_at timestamptz,
  revoked_at timestamptz,
  revoked_by uuid references users (id) on delete set null,
  revoke_reason text,
  unique (user_id, install_id)
);
create index devices_user on app_private.devices (user_id);

alter table app_private.access_tokens
  add column device_id uuid references app_private.devices (id) on delete cascade;
alter table app_private.refresh_tokens
  add column device_id uuid references app_private.devices (id) on delete cascade;
alter table app_private.notification_tokens
  add column device_id uuid references app_private.devices (id) on delete cascade;
alter table app_private.connection_identity add column device_id uuid;
alter table app_private.credentials
  add column lock_count int not null default 0,
  add column last_locked_at timestamptz;

-- Sign-in and session history (no passwords; identifiers only as hashes).
create table app_private.auth_events (
  id bigserial primary key,
  at timestamptz not null default now(),
  kind text not null,
  user_id uuid references users (id) on delete cascade,
  device_id uuid references app_private.devices (id) on delete set null,
  actor_id uuid references users (id) on delete set null,
  identifier_hash text,
  detail jsonb
);
create index auth_events_at on app_private.auth_events (at);
create index auth_events_user on app_private.auth_events (user_id, at desc);
create index auth_events_failures on app_private.auth_events (identifier_hash, at)
  where kind = 'sign_in_failed';

-- ------------------------------------------------------------- helpers --

create or replace function app_private.clip(p text, n int)
returns text language sql immutable
as $$ select nullif(left(btrim(p), n), '') $$;

create or replace function app_private.small_int(p text)
returns int language sql immutable
as $$ select case when btrim(p) ~ '^[0-9]{1,9}$' then btrim(p)::int end $$;

create or replace function app_private.flag(p text)
returns boolean language sql immutable
as $$ select case lower(btrim(p)) when 'true' then true when 'false' then false end $$;

create or replace function app_private.identifier_hash(p text)
returns text language sql immutable
set search_path = public, pg_temp
as $$ select encode(digest(lower(btrim(coalesce(p, ''))), 'sha256'), 'hex') $$;

create or replace function app_private.auth_event(
  p_kind text, p_user uuid, p_device uuid default null,
  p_identifier text default null, p_detail jsonb default null)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  insert into app_private.auth_events (kind, user_id, device_id, actor_id, identifier_hash, detail)
  values (p_kind, p_user, p_device, app_private.current_user_id(),
          case when p_identifier is not null then app_private.identifier_hash(p_identifier) end,
          p_detail);
  -- Old history is dropped now and then (kept for auth_events_keep_days).
  if random() < 0.01 then
    delete from app_private.auth_events
    where at < now() - make_interval(days => app_private.int_setting('auth_events_keep_days', 180));
  end if;
end;
$$;

-- Records (or refreshes) the calling app installation. p_device is what the
-- app reports; every value is optional, trimmed and length-limited.
create or replace function app_private.upsert_device(p_user uuid, p_device jsonb, p_sign_in boolean)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_install text := app_private.clip(p_device->>'install_id', 64);
  v_id uuid;
begin
  if p_user is null or v_install is null or length(v_install) < 8 then
    return null;
  end if;
  insert into app_private.devices as d (
    user_id, install_id, manufacturer, model, os, os_version, sdk_int, app_version,
    app_build, locale, time_zone, notifications_allowed, microphone_allowed, network,
    storage_free_mb, last_contact_at, last_sign_in_at)
  values (
    p_user, v_install,
    app_private.clip(p_device->>'manufacturer', 60), app_private.clip(p_device->>'model', 80),
    app_private.clip(p_device->>'os', 20), app_private.clip(p_device->>'os_version', 40),
    app_private.small_int(p_device->>'sdk_int'), app_private.clip(p_device->>'app_version', 20),
    app_private.small_int(p_device->>'app_build'), app_private.clip(p_device->>'locale', 20),
    app_private.clip(p_device->>'time_zone', 60),
    app_private.flag(p_device->>'notifications_allowed'),
    app_private.flag(p_device->>'microphone_allowed'),
    app_private.clip(p_device->>'network', 20),
    app_private.small_int(p_device->>'storage_free_mb'),
    now(), case when p_sign_in then now() end)
  on conflict (user_id, install_id) do update set
    manufacturer = coalesce(excluded.manufacturer, d.manufacturer),
    model = coalesce(excluded.model, d.model),
    os = coalesce(excluded.os, d.os),
    os_version = coalesce(excluded.os_version, d.os_version),
    sdk_int = coalesce(excluded.sdk_int, d.sdk_int),
    app_version = coalesce(excluded.app_version, d.app_version),
    app_build = coalesce(excluded.app_build, d.app_build),
    locale = coalesce(excluded.locale, d.locale),
    time_zone = coalesce(excluded.time_zone, d.time_zone),
    notifications_allowed = coalesce(excluded.notifications_allowed, d.notifications_allowed),
    microphone_allowed = coalesce(excluded.microphone_allowed, d.microphone_allowed),
    network = coalesce(excluded.network, d.network),
    storage_free_mb = coalesce(excluded.storage_free_mb, d.storage_free_mb),
    last_contact_at = now(),
    last_sign_in_at = coalesce(excluded.last_sign_in_at, d.last_sign_in_at),
    -- Signing in again (with the password) brings a signed-out or revoked
    -- installation back; a refresh never does.
    signed_out_at = case when p_sign_in then null else d.signed_out_at end,
    revoked_at = case when p_sign_in then null else d.revoked_at end,
    revoked_by = case when p_sign_in then null else d.revoked_by end,
    revoke_reason = case when p_sign_in then null else d.revoke_reason end
  returning id into v_id;
  return v_id;
end;
$$;

-- The device of the current app transaction (set by authenticate()).
create or replace function app_private.current_device_id()
returns uuid
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select device_id from app_private.connection_identity
  where backend_pid = pg_backend_pid() and xact = pg_current_xact_id_if_assigned()
$$;

-- Ends one device's sessions and phone notifications.
create or replace function app_private.end_device_sessions(p_device uuid)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update app_private.refresh_tokens set revoked_at = coalesce(revoked_at, now())
  where device_id = p_device;
  update app_private.access_tokens set revoked_at = coalesce(revoked_at, now())
  where device_id = p_device;
  delete from app_private.notification_tokens where device_id = p_device;
$$;

-- --------------------------------------------------------------- sign-in --

create or replace function auth_api.login(p_identifier text, p_password text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  v_uid uuid;
  v_user users%rowtype;
  v_cred app_private.credentials%rowtype;
  v_hash text := app_private.identifier_hash(p_identifier);
  v_max int := greatest(app_private.int_setting('lockout_attempts', 5), 1);
  v_mins int := greatest(app_private.int_setting('lockout_minutes', 15), 1);
begin
  -- Whole-system brake against someone trying many accounts.
  if (select count(*) from app_private.auth_events
      where kind = 'sign_in_failed' and at > now() - interval '1 minute')
     >= app_private.int_setting('signin_failures_per_minute', 60) then
    perform app_private.auth_event('sign_in_throttled', null, null, p_identifier);
    return jsonb_build_object('error', 'try_later');
  end if;

  begin
    v_uid := app_private.find_user_by_identifier(p_identifier);
  exception when others then
    v_uid := null;
  end;
  select * into v_user from users where id = v_uid;
  select * into v_cred from app_private.credentials where user_id = v_uid;

  if v_cred.user_id is null then
    -- No such account: behave exactly like a real one, lock-out included.
    if (select count(*) from app_private.auth_events
        where kind = 'sign_in_failed' and identifier_hash = v_hash
          and at > now() - make_interval(mins => v_mins)) >= v_max then
      return jsonb_build_object('error', 'locked');
    end if;
    perform crypt(coalesce(p_password, ''),
                  '$2a$10$abcdefghijklmnopqrstuuMpJcY5ZBFaHQ9R5aZ1r/7lJmD8hGf1y');
    perform app_private.auth_event('sign_in_failed', null, null, p_identifier);
    return jsonb_build_object('error', 'invalid_credentials');
  end if;

  if v_cred.locked_until is not null and v_cred.locked_until > now() then
    perform app_private.auth_event('sign_in_locked', v_uid, null, p_identifier);
    return jsonb_build_object('error', 'locked');
  end if;
  -- A lock that has run out starts a fresh count; a day without any lock
  -- forgets earlier ones.
  if v_cred.locked_until is not null
     or (v_cred.last_locked_at is not null and v_cred.last_locked_at < now() - interval '1 day') then
    update app_private.credentials set
      failed_attempts = 0, locked_until = null,
      lock_count = case when last_locked_at < now() - interval '1 day' then 0 else lock_count end
    where user_id = v_uid
    returning * into v_cred;
  end if;

  if crypt(coalesce(p_password, ''), v_cred.password_hash) <> v_cred.password_hash then
    update app_private.credentials set
      failed_attempts = failed_attempts + 1,
      locked_until = case when failed_attempts + 1 >= v_max
                          then now() + make_interval(mins => least(v_mins * (2 ^ least(lock_count, 7))::int, 1440)) end,
      lock_count = case when failed_attempts + 1 >= v_max then lock_count + 1 else lock_count end,
      last_locked_at = case when failed_attempts + 1 >= v_max then now() else last_locked_at end
    where user_id = v_uid;
    perform app_private.auth_event('sign_in_failed', v_uid, null, p_identifier);
    return jsonb_build_object('error', 'invalid_credentials');
  end if;
  if not v_user.is_active then
    perform app_private.auth_event('sign_in_disabled', v_uid, null, p_identifier);
    return jsonb_build_object('error', 'disabled');
  end if;
  update app_private.credentials set failed_attempts = 0, locked_until = null, lock_count = 0
  where user_id = v_uid;
  return auth_api._profile(v_uid);
end;
$$;

-- Sessions carry their device. Old app versions send no device and get the
-- same sessions as before.
drop function auth_api._session(uuid, text);
drop function auth_api._issue_access(uuid);
drop function auth_api.issue_refresh(uuid, uuid);

create function auth_api._issue_access(p_user uuid, p_device uuid default null)
returns text
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_token text := encode(gen_random_bytes(32), 'hex');
begin
  delete from app_private.access_tokens
  where user_id = p_user and (expires_at < now() or revoked_at is not null);
  insert into app_private.access_tokens (token_hash, user_id, expires_at, device_id)
  values (encode(digest(v_token, 'sha256'), 'hex'), p_user, now() + interval '1 hour', p_device);
  return v_token;
end;
$$;

create function auth_api.issue_refresh(p_user uuid, p_family uuid default null, p_device uuid default null)
returns text
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_token text := encode(gen_random_bytes(32), 'hex');
begin
  insert into app_private.refresh_tokens (token_hash, user_id, family, expires_at, device_id)
  values (encode(digest(v_token, 'sha256'), 'hex'), p_user,
          coalesce(p_family, gen_random_uuid()), now() + interval '60 days', p_device);
  return v_token;
end;
$$;

create function auth_api._session(p_user uuid, p_refresh text, p_device uuid default null)
returns jsonb
language sql volatile security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
  select jsonb_build_object(
    'access_token', auth_api._issue_access(p_user, p_device),
    'expires_in', 3600,
    'refresh_token', p_refresh,
    'device_id', p_device,
    'user', auth_api._profile(p_user))
$$;

-- Rotation keeps the device; a revoked device's tokens are already revoked.
create or replace function auth_api.rotate_refresh(p_token text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  v_row app_private.refresh_tokens%rowtype;
  v_active boolean;
begin
  select * into v_row from app_private.refresh_tokens
  where token_hash = encode(digest(coalesce(p_token, ''), 'sha256'), 'hex')
  for update;
  if not found or v_row.expires_at < now() then
    return jsonb_build_object('error', 'invalid_token');
  end if;
  if v_row.revoked_at is not null then
    update app_private.refresh_tokens set revoked_at = coalesce(revoked_at, now())
    where family = v_row.family;
    perform app_private.auth_event('refresh_rejected', v_row.user_id, v_row.device_id);
    return jsonb_build_object('error', 'invalid_token');
  end if;
  select is_active into v_active from users where id = v_row.user_id;
  if not coalesce(v_active, false) then
    return jsonb_build_object('error', 'disabled');
  end if;
  update app_private.refresh_tokens set revoked_at = now()
  where token_hash = v_row.token_hash;
  return auth_api._profile(v_row.user_id)
    || jsonb_build_object(
         'refresh_token', auth_api.issue_refresh(v_row.user_id, v_row.family, v_row.device_id),
         'device_id', v_row.device_id);
end;
$$;

drop function auth_api.app_login(text, text);
create function auth_api.app_login(p_identifier text, p_password text, p_device jsonb default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  v jsonb := auth_api.login(p_identifier, p_password);
  v_uid uuid;
  v_dev uuid;
begin
  if v ? 'error' then return v; end if;
  v_uid := (v->>'id')::uuid;
  v_dev := app_private.upsert_device(v_uid, p_device, true);
  perform app_private.auth_event('sign_in', v_uid, v_dev, p_identifier);
  return auth_api._session(v_uid, auth_api.issue_refresh(v_uid, null, v_dev), v_dev);
end;
$$;

drop function auth_api.app_register(text, text, text);
create function auth_api.app_register(
  p_identifier text, p_password text, p_display_name text, p_device jsonb default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  v_user jsonb;
  v_uid uuid;
  v_dev uuid;
begin
  v_user := auth_api.register(p_identifier, p_password, p_display_name);
  v_uid := (v_user->>'id')::uuid;
  v_dev := app_private.upsert_device(v_uid, p_device, true);
  perform app_private.auth_event('signed_up', v_uid, v_dev, p_identifier);
  return auth_api._session(v_uid, auth_api.issue_refresh(v_uid, null, v_dev), v_dev);
-- SA403: sign-up closed by an administrator (0033).
exception when sqlstate 'SA400' or sqlstate 'SA409' or sqlstate 'SA403' then
  return jsonb_build_object('error', sqlerrm);
end;
$$;

drop function auth_api.app_refresh(text);
create function auth_api.app_refresh(p_refresh_token text, p_device jsonb default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  v jsonb := auth_api.rotate_refresh(p_refresh_token);
  v_uid uuid;
  v_dev uuid;
begin
  if v ? 'error' then return v; end if;
  v_uid := (v->>'id')::uuid;
  v_dev := (v->>'device_id')::uuid;
  if p_device is not null then
    if v_dev is null then
      -- A session from before devices existed: attach it to this phone.
      v_dev := app_private.upsert_device(v_uid, p_device, false);
      update app_private.refresh_tokens set device_id = v_dev
      where token_hash = encode(digest(v->>'refresh_token', 'sha256'), 'hex');
    elsif exists (select 1 from app_private.devices
                  where id = v_dev and install_id = app_private.clip(p_device->>'install_id', 64)) then
      perform app_private.upsert_device(v_uid, p_device, false);
    end if;
  end if;
  return auth_api._session(v_uid, v->>'refresh_token', v_dev);
end;
$$;

create or replace function auth_api.app_logout(p_refresh_token text, p_access_token text default null)
returns void
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare v_row app_private.refresh_tokens%rowtype;
begin
  select * into v_row from app_private.refresh_tokens
  where token_hash = encode(digest(coalesce(p_refresh_token, ''), 'sha256'), 'hex');
  perform auth_api.revoke_refresh(p_refresh_token);
  update app_private.access_tokens set revoked_at = now()
  where token_hash = encode(digest(coalesce(p_access_token, ''), 'sha256'), 'hex');
  if v_row.device_id is not null then
    perform app_private.end_device_sessions(v_row.device_id);
    update app_private.devices set signed_out_at = now() where id = v_row.device_id;
  end if;
  if v_row.user_id is not null then
    perform app_private.auth_event('sign_out', v_row.user_id, v_row.device_id);
  end if;
end;
$$;

drop function auth_api.app_change_password(text, text, text);
create function auth_api.app_change_password(
  p_access_token text, p_old text, p_new text, p_device jsonb default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  v_user uuid;
  v_dev uuid;
begin
  select user_id, device_id into v_user, v_dev from app_private.access_tokens
  where token_hash = encode(digest(coalesce(p_access_token, ''), 'sha256'), 'hex')
    and revoked_at is null and expires_at > now();
  if v_user is null then
    return jsonb_build_object('error', 'invalid_token');
  end if;
  -- This phone keeps its notifications; every other device loses them.
  perform set_config('sidra.keep_device', coalesce(v_dev::text, ''), true);
  begin
    perform auth_api.change_password(v_user, p_old, p_new);
  exception when sqlstate 'SA400' or sqlstate 'SA401' then
    return jsonb_build_object('error', sqlerrm);
  end;
  update app_private.access_tokens set revoked_at = now()
  where user_id = v_user and revoked_at is null;
  perform app_private.auth_event('password_changed', v_user, v_dev);
  return auth_api._session(v_user, auth_api.issue_refresh(v_user, null, v_dev), v_dev);
end;
$$;

grant execute on function
  auth_api.app_register(text, text, text, jsonb),
  auth_api.app_login(text, text, jsonb),
  auth_api.app_refresh(text, jsonb),
  auth_api.app_logout(text, text),
  auth_api.app_change_password(text, text, text, jsonb)
to sidra_app;

-- Any password change or reset: every session ends (as before) and every
-- other phone stops receiving notifications.
create or replace function app_private.revoke_access_after_reset()
returns trigger
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_keep text := nullif(current_setting('sidra.keep_device', true), '');
begin
  if new.password_hash is distinct from old.password_hash then
    update app_private.access_tokens set revoked_at = now()
    where user_id = new.user_id and revoked_at is null;
    delete from app_private.notification_tokens
    where user_id = new.user_id
      and (v_keep is null or device_id is distinct from v_keep::uuid);
  end if;
  return new;
end;
$$;

-- Each app transaction: identity + device; a revoked device is refused.
-- Last contact is written at most once a minute per device.
create or replace function app_private.authenticate(p_token text)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_user uuid;
  v_device uuid;
begin
  select t.user_id, t.device_id into v_user, v_device
  from app_private.access_tokens t
  join users u on u.id = t.user_id
  left join app_private.devices d on d.id = t.device_id
  where t.token_hash = encode(digest(coalesce(p_token, ''), 'sha256'), 'hex')
    and t.revoked_at is null and t.expires_at > now() and u.is_active
    and d.revoked_at is null;
  if v_user is null then
    raise exception 'session expired' using errcode = 'PT401';
  end if;
  insert into app_private.connection_identity (backend_pid, xact, user_id, device_id)
  values (pg_backend_pid(), pg_current_xact_id(), v_user, v_device)
  on conflict (backend_pid) do update
    set xact = excluded.xact, user_id = excluded.user_id, device_id = excluded.device_id;
  if v_device is not null then
    update app_private.devices set last_contact_at = now()
    where id = v_device
      and (last_contact_at is null or last_contact_at < now() - interval '1 minute');
  end if;
end;
$$;

create or replace function public.issue_notification_token()
returns text
language plpgsql volatile security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_token text := encode(gen_random_bytes(32), 'hex');
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  insert into app_private.notification_tokens (token_hash, user_id, device_id)
  values (encode(digest(v_token, 'sha256'), 'hex'), v_me, app_private.current_device_id());
  return v_token;
end;
$$;

-- ------------------------------------------------------- app heartbeat --

-- The app reports its state: on start, on resume, and every few minutes in
-- use. p_active = the person used the app since the last report; p_synced =
-- queued work finished sending.
create or replace function public.report_device(
  p_device jsonb, p_active boolean default false, p_synced boolean default false)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_dev uuid := app_private.current_device_id();
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  if v_dev is null then
    v_dev := app_private.upsert_device(v_me, p_device, false);
  elsif exists (select 1 from app_private.devices
                where id = v_dev and install_id = app_private.clip(p_device->>'install_id', 64)) then
    perform app_private.upsert_device(v_me, p_device, false);
  end if;
  if v_dev is null then return; end if;
  update app_private.devices set
    last_contact_at = now(),
    last_active_at = case when p_active then now() else last_active_at end,
    last_sync_at = case when p_synced then now() else last_sync_at end
  where id = v_dev and user_id = v_me;
end;
$$;

-- ----------------------------------------------------- admin: presence --

create or replace function app_private.device_json(d app_private.devices)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select jsonb_build_object(
    'id', d.id, 'user_id', d.user_id, 'manufacturer', d.manufacturer, 'model', d.model,
    'os', d.os, 'os_version', d.os_version, 'sdk_int', d.sdk_int,
    'app_version', d.app_version, 'app_build', d.app_build,
    'locale', d.locale, 'time_zone', d.time_zone,
    'notifications_allowed', d.notifications_allowed,
    'microphone_allowed', d.microphone_allowed,
    'network', d.network, 'storage_free_mb', d.storage_free_mb,
    'first_seen_at', d.first_seen_at, 'last_sign_in_at', d.last_sign_in_at,
    'last_contact_at', d.last_contact_at, 'last_active_at', d.last_active_at,
    'last_sync_at', d.last_sync_at, 'signed_out_at', d.signed_out_at,
    'revoked_at', d.revoked_at, 'revoke_reason', d.revoke_reason,
    'revoked_by_name', (select display_name from users where id = d.revoked_by),
    'signed_in', d.revoked_at is null and exists (
       select 1 from app_private.refresh_tokens r
       where r.device_id = d.id and r.revoked_at is null and r.expires_at > now()),
    'online', d.last_contact_at > now() - make_interval(
       mins => app_private.int_setting('presence_online_minutes', 5)),
    'active', d.last_active_at > now() - make_interval(
       mins => app_private.int_setting('presence_online_minutes', 5)),
    'this_device', d.id = app_private.current_device_id())
$$;

-- A person's devices: staff with sessions.view, or the person themselves.
create or replace function public.user_devices(p_user_id uuid default null)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare v_user uuid := coalesce(p_user_id, app_private.current_user_id());
begin
  if app_private.current_user_id() is null then
    raise exception 'not signed in' using errcode = 'PT401';
  end if;
  if v_user <> app_private.current_user_id() and not app_private.has_permission('sessions.view') then
    raise exception 'not allowed to see this person''s devices' using errcode = 'PT403';
  end if;
  return query
    select app_private.device_json(d) from app_private.devices d
    where d.user_id = v_user
    order by coalesce(d.last_contact_at, d.first_seen_at) desc;
end;
$$;

-- Everyone's presence at a glance (sessions.view).
create or replace function public.people_presence(p_search text default null)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare v_mins int := app_private.int_setting('presence_online_minutes', 5);
begin
  perform app_private.require('sessions.view');
  return query
    select jsonb_build_object(
      'user_id', u.id, 'display_name', u.display_name, 'role', u.role,
      'is_active', u.is_active, 'created_at', u.created_at,
      'devices', count(d.id) filter (where d.revoked_at is null),
      'signed_in_devices', count(d.id) filter (where d.revoked_at is null and exists (
         select 1 from app_private.refresh_tokens r
         where r.device_id = d.id and r.revoked_at is null and r.expires_at > now())),
      'last_sign_in_at', max(d.last_sign_in_at),
      'last_contact_at', max(d.last_contact_at),
      'last_active_at', max(d.last_active_at),
      'last_sync_at', max(d.last_sync_at),
      'online', coalesce(max(d.last_contact_at) > now() - make_interval(mins => v_mins), false),
      'active', coalesce(max(d.last_active_at) > now() - make_interval(mins => v_mins), false))
    from users u
    left join app_private.devices d on d.user_id = u.id
    where u.removed_at is null
      and (p_search is null or u.display_name ilike '%' || p_search || '%')
    group by u.id
    order by max(d.last_contact_at) desc nulls last, u.display_name;
end;
$$;

-- Signs out one device (lost or stolen phone). Staff with sessions.manage,
-- or the owner signing out another of their own devices.
create or replace function public.revoke_device(p_device_id uuid, p_reason text default null)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v app_private.devices%rowtype;
begin
  select * into v from app_private.devices where id = p_device_id;
  if not found
     or (v.user_id <> app_private.current_user_id()
         and not app_private.has_permission('sessions.manage')) then
    raise exception 'device not found' using errcode = 'PT404';
  end if;
  perform app_private.end_device_sessions(v.id);
  update app_private.devices set revoked_at = now(),
    revoked_by = app_private.current_user_id(),
    revoke_reason = app_private.clip(p_reason, 300)
  where id = v.id;
  perform app_private.auth_event('device_revoked', v.user_id, v.id, null,
    jsonb_build_object('reason', app_private.clip(p_reason, 300)));
  insert into audit_log (actor_id, action, entity, entity_id, changes)
  values (app_private.current_user_id(), 'device.revoked', 'users', v.user_id::text,
          jsonb_build_object('device', coalesce(v.manufacturer || ' ', '') || coalesce(v.model, ''),
                             'reason', app_private.clip(p_reason, 300)));
end;
$$;

-- Ends every session of a person on every device (sessions.manage, or the
-- person: "sign out everywhere"). Returns how many devices were signed out.
create or replace function public.end_all_sessions(p_user_id uuid, p_reason text default null)
returns int
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_count int;
begin
  if p_user_id is distinct from app_private.current_user_id()
     and not app_private.has_permission('sessions.manage') then
    raise exception 'not allowed to end this person''s sessions' using errcode = 'PT403';
  end if;
  update app_private.refresh_tokens set revoked_at = coalesce(revoked_at, now())
  where user_id = p_user_id;
  update app_private.access_tokens set revoked_at = coalesce(revoked_at, now())
  where user_id = p_user_id;
  delete from app_private.notification_tokens where user_id = p_user_id;
  update app_private.devices set signed_out_at = now()
  where user_id = p_user_id and signed_out_at is null and revoked_at is null;
  get diagnostics v_count = row_count;
  perform app_private.auth_event('sessions_ended', p_user_id, null, null,
    jsonb_build_object('reason', app_private.clip(p_reason, 300)));
  insert into audit_log (actor_id, action, entity, entity_id, changes)
  values (app_private.current_user_id(), 'sessions.ended', 'users', p_user_id::text,
          jsonb_build_object('devices', v_count, 'reason', app_private.clip(p_reason, 300)));
  return v_count;
end;
$$;

-- Sign-in history (sessions.view, or one's own).
create or replace function public.auth_history(p_user_id uuid default null, p_limit int default 100)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare v_user uuid := coalesce(p_user_id, app_private.current_user_id());
begin
  if v_user is distinct from app_private.current_user_id()
     and not app_private.has_permission('sessions.view') then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  return query
    select jsonb_build_object(
      'at', e.at, 'kind', e.kind, 'detail', e.detail,
      'device', (select coalesce(d.manufacturer || ' ', '') || coalesce(d.model, '')
                 from app_private.devices d where d.id = e.device_id),
      'actor_name', (select display_name from users where id = e.actor_id))
    from app_private.auth_events e
    where e.user_id = v_user
    order by e.at desc
    limit least(greatest(p_limit, 1), 500);
end;
$$;

revoke all on function public.report_device(jsonb, boolean, boolean),
  public.user_devices(uuid), public.people_presence(text),
  public.revoke_device(uuid, text), public.end_all_sessions(uuid, text),
  public.auth_history(uuid, int) from public, anonymous;
grant execute on function public.report_device(jsonb, boolean, boolean),
  public.user_devices(uuid), public.people_presence(text),
  public.revoke_device(uuid, text), public.end_all_sessions(uuid, text),
  public.auth_history(uuid, int) to authenticated, sidra_app;

-- ----------------------------------------------- function lock-down --
-- PostgreSQL lets everyone execute a new function, and a per-schema
-- "alter default privileges … revoke" cannot undo that global default (the
-- ones in 0011 and 0034 had no effect). So every migration that adds or
-- recreates functions ends with `select app_private.lock_down_functions();`:
--   auth_api:    only the app_* entry points, for sidra_app;
--   app_private: only the rule helpers row policies, CHECK constraints and
--                column defaults use, plus caller-rights functions.
create or replace function app_private.lock_down_functions()
returns void
language plpgsql
-- catalog only: policies and constraints then print with schema names
set search_path = pg_catalog, pg_temp
as $$
declare
  v_needed text[];
  v_more text[];
  r record;
begin
  revoke execute on all functions in schema auth_api from public;
  revoke execute on all functions in schema app_private from public, anonymous, authenticated, sidra_app;

  for r in select p.oid::regprocedure as fn
           from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'auth_api' and p.proname in (
             'app_register', 'app_login', 'app_refresh', 'app_logout', 'app_change_password') loop
    execute format('grant execute on function %s to sidra_app', r.fn);
  end loop;

  select coalesce(array_agg(distinct m[1]), '{}') into v_needed
  from (
    select regexp_matches(coalesce(qual, '') || ' ' || coalesce(with_check, ''),
                          'app_private\.([a-z_0-9]+)\(', 'g') m
    from pg_policies
    union all
    select regexp_matches(pg_get_constraintdef(oid), 'app_private\.([a-z_0-9]+)\(', 'g')
    from pg_constraint where contype = 'c'
    union all
    select regexp_matches(pg_get_expr(adbin, adrelid), 'app_private\.([a-z_0-9]+)\(', 'g')
    from pg_attrdef
  ) s;
  v_needed := v_needed || array['authenticate', 'jwt_sub', 'current_user_id',
                                'current_app_role', 'has_permission', 'is_admin',
                                'is_superadmin', 'is_console_user'];
  for i in 1..5 loop
    select coalesce(array_agg(distinct m[1]), '{}') into v_more
    from (
      select regexp_matches(p.prosrc, 'app_private\.([a-z_0-9]+)\(', 'g') m
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where not p.prosecdef
        and (n.nspname = 'public' or (n.nspname = 'app_private' and p.proname = any (v_needed)))
    ) s
    where not m[1] = any (v_needed);
    exit when cardinality(v_more) = 0;
    v_needed := v_needed || v_more;
  end loop;
  v_needed := array(select unnest(v_needed)
                    except select unnest(array['create_account', 'complete_and_unlock',
                                               'find_user_by_identifier', 'checked_identifier',
                                               'upsert_device', 'end_device_sessions',
                                               'auth_event', 'lock_down_functions']));
  for r in select p.oid::regprocedure as fn
           from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'app_private' and p.prokind = 'f'
             and (p.proname = any (v_needed) or not p.prosecdef)
             and p.proname <> 'lock_down_functions'
             and p.prorettype <> 'trigger'::regtype loop
    execute format('grant execute on function %s to sidra_app, authenticated, anonymous', r.fn);
  end loop;
end;
$$;

-- Deleting a learner also deletes their devices and sign-in history.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.delete_learner(uuid, text, text)'::regprocedure);
  if position('  delete from app_private.notification_tokens where user_id = v.id;' in v_src) = 0 then
    raise exception 'delete_learner changed; update 0035';
  end if;
  execute replace(v_src, '  delete from app_private.notification_tokens where user_id = v.id;',
    '  delete from app_private.notification_tokens where user_id = v.id;
  delete from app_private.auth_events where user_id = v.id;
  delete from app_private.devices where user_id = v.id;');
end $$;

-- Last: nothing new is callable by the app login unless reviewed.
select app_private.lock_down_functions();
