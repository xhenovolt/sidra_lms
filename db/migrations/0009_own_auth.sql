-- 0009 Sidra's own authentication (replaces Clerk).
--
--   app ──identifier+password──▶ auth service (Cloudflare Worker)
--        ◀── access JWT (RS256, 15 min) + refresh token (60 days, rotating)
--   app ──JWT──▶ Neon Data API ──▶ Postgres (auth.user_id() = users.id)
--
-- Passwords are verified HERE (bcrypt via pgcrypto). The Worker is the only
-- caller of auth_api.*, through a dedicated login role that can do nothing
-- else. auth_api is not exposed by the Data API.

-- ------------------------------------------------------------ identity --

alter table users rename column clerk_user_id to auth_subject;
alter table users add column phone text
  check (phone is null or phone ~ '^\+[1-9][0-9]{7,14}$');
create unique index users_email_lower on users (lower(email)) where email is not null;
create unique index users_phone_unique on users (phone) where phone is not null;

-- JWT `sub` of the current request (users.id as text for Sidra tokens).
create or replace function app_private.jwt_sub()
returns text
language plpgsql stable security definer
set search_path = pg_catalog, pg_temp
as $$
begin
  return auth.user_id();
exception
  when invalid_parameter_value or undefined_object or null_value_not_allowed then
    return null;
end;
$$;
revoke all on function app_private.jwt_sub() from public;
grant execute on function app_private.jwt_sub() to authenticated;

create or replace function app_private.current_user_id()
returns uuid
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select id from users where auth_subject = app_private.jwt_sub() and is_active
$$;

create or replace function app_private.current_app_role()
returns app_role
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select role from users where auth_subject = app_private.jwt_sub() and is_active
$$;

create or replace function app_private.protect_user_role()
returns trigger
language plpgsql
as $$
begin
  if new.role is distinct from old.role
     and current_setting('sidra.role_change', true) is distinct from 'allowed' then
    raise exception 'role can only be changed by an administrator';
  end if;
  if new.auth_subject is distinct from old.auth_subject then
    raise exception 'auth_subject is immutable';
  end if;
  return new;
end;
$$;

-- Profile refresh for signed-in users. Accounts are created by
-- auth_api.register(), never implicitly from a token.
create or replace function public.ensure_profile(
  p_display_name text default null,
  p_email text default null,
  p_avatar_url text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_user users%rowtype;
begin
  select * into v_user from users where auth_subject = app_private.jwt_sub();
  if not found then
    raise exception 'not signed in' using errcode = 'PT401';
  end if;
  if not v_user.is_active then
    raise exception 'account disabled' using errcode = 'PT403';
  end if;
  update users set
    display_name = coalesce(nullif(trim(p_display_name), ''), display_name),
    avatar_url = coalesce(p_avatar_url, avatar_url)
  where id = v_user.id
  returning * into v_user;
  insert into learner_profiles (user_id) values (v_user.id) on conflict do nothing;
  return jsonb_build_object(
    'id', v_user.id, 'role', v_user.role,
    'display_name', v_user.display_name, 'email', v_user.email,
    'phone', v_user.phone, 'avatar_url', v_user.avatar_url);
end;
$$;

drop function app_private.clerk_id();

-- --------------------------------------------------------- credentials --

create table app_private.credentials (
  user_id uuid primary key references users (id) on delete cascade,
  password_hash text not null,
  must_change boolean not null default false,
  failed_attempts int not null default 0,
  locked_until timestamptz,
  password_changed_at timestamptz not null default now()
);

-- Rotating refresh tokens. Only SHA-256 hashes are stored. Presenting an
-- already-rotated token revokes its whole family (likely theft).
create table app_private.refresh_tokens (
  token_hash text primary key,
  user_id uuid not null references users (id) on delete cascade,
  family uuid not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  revoked_at timestamptz
);
create index refresh_tokens_user on app_private.refresh_tokens (user_id);
create index refresh_tokens_family on app_private.refresh_tokens (family);

create schema if not exists auth_api;
revoke all on schema auth_api from public;

-- Normalises a login identifier: emails lower-cased; phones to E.164.
create or replace function auth_api.normalize_identifier(p text, out kind text, out value text)
language plpgsql immutable
as $$
declare v text := trim(coalesce(p, ''));
begin
  if position('@' in v) > 0 then
    kind := 'email';
    value := lower(v);
    if value !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
      raise exception 'invalid_identifier' using errcode = 'SA400';
    end if;
  else
    kind := 'phone';
    value := regexp_replace(v, '[\s().-]', '', 'g');
    if value like '00%' then value := '+' || substr(value, 3); end if;
    if value !~ '^\+[1-9][0-9]{7,14}$' then
      raise exception 'invalid_identifier' using errcode = 'SA400';
    end if;
  end if;
end;
$$;

create or replace function auth_api._check_password(p text)
returns void
language plpgsql immutable
as $$
begin
  if p is null or length(p) < 8 then
    raise exception 'weak_password' using errcode = 'SA400';
  end if;
  if length(p) > 128 then
    raise exception 'weak_password' using errcode = 'SA400';
  end if;
end;
$$;

create or replace function auth_api._profile(p_user uuid)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select jsonb_build_object(
    'id', u.id, 'role', u.role, 'display_name', u.display_name,
    'email', u.email, 'phone', u.phone,
    'must_change_password', coalesce(c.must_change, false))
  from users u left join app_private.credentials c on c.user_id = u.id
  where u.id = p_user
$$;

create or replace function auth_api.register(
  p_identifier text, p_password text, p_display_name text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  v_id record;
  v_user uuid := gen_random_uuid();
begin
  select * into v_id from auth_api.normalize_identifier(p_identifier);
  perform auth_api._check_password(p_password);
  if coalesce(trim(p_display_name), '') = '' then
    raise exception 'name_required' using errcode = 'SA400';
  end if;
  if exists (select 1 from users where
             (v_id.kind = 'email' and lower(email) = v_id.value)
             or (v_id.kind = 'phone' and phone = v_id.value)) then
    raise exception 'identifier_taken' using errcode = 'SA409';
  end if;

  insert into users (id, auth_subject, display_name, email, phone)
  values (v_user, v_user::text, trim(p_display_name),
          case when v_id.kind = 'email' then v_id.value end,
          case when v_id.kind = 'phone' then v_id.value end);
  insert into learner_profiles (user_id) values (v_user);
  insert into app_private.credentials (user_id, password_hash)
  values (v_user, crypt(p_password, gen_salt('bf', 10)));
  return auth_api._profile(v_user);
end;
$$;

-- Verifies a password. Unknown identifiers and wrong passwords give the
-- same error (no account enumeration). 5 failures lock for 15 minutes.
--
-- Failures are RETURNED as {"error": "..."} rather than raised: raising
-- would roll back the failed-attempt counter written just before.
create or replace function auth_api.login(p_identifier text, p_password text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  v_id record;
  v_user users%rowtype;
  v_cred app_private.credentials%rowtype;
begin
  begin
    select * into v_id from auth_api.normalize_identifier(p_identifier);
  exception when others then
    return jsonb_build_object('error', 'invalid_credentials');
  end;
  select * into v_user from users
  where (v_id.kind = 'email' and lower(email) = v_id.value)
     or (v_id.kind = 'phone' and phone = v_id.value);
  select * into v_cred from app_private.credentials where user_id = v_user.id;

  if v_cred.user_id is null then
    -- Equalise timing with a real bcrypt comparison.
    perform crypt(coalesce(p_password, ''),
                  '$2a$10$abcdefghijklmnopqrstuuMpJcY5ZBFaHQ9R5aZ1r/7lJmD8hGf1y');
    return jsonb_build_object('error', 'invalid_credentials');
  end if;
  if v_cred.locked_until is not null and v_cred.locked_until > now() then
    return jsonb_build_object('error', 'locked');
  end if;
  if crypt(coalesce(p_password, ''), v_cred.password_hash) <> v_cred.password_hash then
    update app_private.credentials set
      failed_attempts = failed_attempts + 1,
      locked_until = case when failed_attempts + 1 >= 5
                          then now() + interval '15 minutes' end
    where user_id = v_user.id;
    return jsonb_build_object('error', 'invalid_credentials');
  end if;
  if not v_user.is_active then
    return jsonb_build_object('error', 'disabled');
  end if;
  update app_private.credentials set failed_attempts = 0, locked_until = null
  where user_id = v_user.id;
  return auth_api._profile(v_user.id);
end;
$$;

create or replace function auth_api.issue_refresh(p_user uuid, p_family uuid default null)
returns text
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_token text := encode(gen_random_bytes(32), 'hex');
begin
  insert into app_private.refresh_tokens (token_hash, user_id, family, expires_at)
  values (encode(digest(v_token, 'sha256'), 'hex'), p_user,
          coalesce(p_family, gen_random_uuid()), now() + interval '60 days');
  return v_token;
end;
$$;

-- Exchanges a refresh token for a new one (rotation) + current profile.
-- Errors are returned (not raised) so the reuse-detection revoke persists.
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
    return jsonb_build_object('error', 'invalid_token');
  end if;
  select is_active into v_active from users where id = v_row.user_id;
  if not coalesce(v_active, false) then
    return jsonb_build_object('error', 'disabled');
  end if;
  update app_private.refresh_tokens set revoked_at = now()
  where token_hash = v_row.token_hash;
  return auth_api._profile(v_row.user_id)
    || jsonb_build_object('refresh_token',
         auth_api.issue_refresh(v_row.user_id, v_row.family));
end;
$$;

create or replace function auth_api.revoke_refresh(p_token text)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update app_private.refresh_tokens set revoked_at = coalesce(revoked_at, now())
  where family = (select family from app_private.refresh_tokens
                  where token_hash = encode(digest(coalesce(p_token, ''), 'sha256'), 'hex'))
$$;

-- Learner changes their own password (old one required, even a temporary
-- one set by staff). Ends every other session.
create or replace function auth_api.change_password(
  p_user uuid, p_old text, p_new text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare v_hash text;
begin
  select password_hash into v_hash from app_private.credentials where user_id = p_user;
  if v_hash is null or crypt(coalesce(p_old, ''), v_hash) <> v_hash then
    raise exception 'invalid_credentials' using errcode = 'SA401';
  end if;
  perform auth_api._check_password(p_new);
  if p_new = p_old then
    raise exception 'same_password' using errcode = 'SA400';
  end if;
  update app_private.credentials set
    password_hash = crypt(p_new, gen_salt('bf', 10)),
    must_change = false, failed_attempts = 0, locked_until = null,
    password_changed_at = now()
  where user_id = p_user;
  update app_private.refresh_tokens set revoked_at = coalesce(revoked_at, now())
  where user_id = p_user;
  return auth_api._profile(p_user);
end;
$$;

-- ---------------------------------------------- staff password reset --

-- Teachers can reset learners enrolled in their courses; admins anyone.
-- The learner must choose a new password at next sign-in.
create or replace function public.reset_password(p_user_id uuid, p_temporary text)
returns void
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare v_target app_role;
begin
  select role into v_target from users where id = p_user_id;
  -- Non-admins get the same answer whether or not the account exists.
  if v_target is null then
    if app_private.is_admin() then
      raise exception 'user not found' using errcode = 'PT404';
    end if;
    raise exception 'not allowed to reset this password' using errcode = 'PT403';
  end if;
  if not (
    app_private.is_admin()
    or (v_target = 'learner' and exists (
          select 1 from course_enrolments e
          where e.user_id = p_user_id and app_private.is_course_staff(e.course_id)))
  ) then
    raise exception 'not allowed to reset this password' using errcode = 'PT403';
  end if;
  begin
    perform auth_api._check_password(p_temporary);
  exception when others then
    raise exception 'temporary password must be at least 8 characters'
      using errcode = 'PT400';
  end;
  insert into app_private.credentials (user_id, password_hash, must_change)
  values (p_user_id, crypt(p_temporary, gen_salt('bf', 10)), true)
  on conflict (user_id) do update set
    password_hash = excluded.password_hash, must_change = true,
    failed_attempts = 0, locked_until = null, password_changed_at = now();
  update app_private.refresh_tokens set revoked_at = coalesce(revoked_at, now())
  where user_id = p_user_id;
end;
$$;

-- ------------------------------------------------------------- grants --

revoke all on all functions in schema auth_api from public;
revoke all on function public.reset_password(uuid, text) from public, anonymous;
grant execute on function public.reset_password(uuid, text) to authenticated;
revoke all on function public.ensure_profile(text, text, text) from public, anonymous;
grant execute on function public.ensure_profile(text, text, text) to authenticated;

-- The auth service's login role is created by `dart run tool/db.dart
-- auth-role` (so its password never lives in a migration). This role
-- gets EXECUTE on auth_api's public entry points only.
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'sidra_auth_service') then
    create role sidra_auth_service nologin;
  end if;
end $$;
grant usage on schema auth_api to sidra_auth_service;
grant execute on function
  auth_api.register(text, text, text),
  auth_api.login(text, text),
  auth_api.issue_refresh(uuid, uuid),
  auth_api.rotate_refresh(text),
  auth_api.revoke_refresh(text),
  auth_api.change_password(uuid, text, text)
to sidra_auth_service;
