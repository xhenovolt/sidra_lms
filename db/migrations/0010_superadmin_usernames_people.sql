-- 0010 superadmins, usernames, and people-management API.
--
-- Superadmin = an admin with users.is_superadmin. Only superadmins can
-- create, promote, edit, disable or demote administrators. At least one
-- active superadmin must always remain.

alter table users add column is_superadmin boolean not null default false;
alter table users add column username text
  check (username is null or username ~ '^[a-z0-9_.]{3,30}$');
create unique index users_username_unique on users (username) where username is not null;
alter table users add constraint users_superadmin_is_admin
  check (not is_superadmin or role = 'admin');

create or replace function app_private.is_superadmin()
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce((select is_superadmin and role = 'admin' from users
                   where id = app_private.current_user_id()), false)
$$;
grant execute on function app_private.is_superadmin() to authenticated;

-- Role / superadmin / subject changes only through the API functions.
create or replace function app_private.protect_user_role()
returns trigger
language plpgsql
as $$
begin
  if (new.role is distinct from old.role or new.is_superadmin is distinct from old.is_superadmin)
     and current_setting('sidra.role_change', true) is distinct from 'allowed' then
    raise exception 'role can only be changed by an administrator';
  end if;
  if new.auth_subject is distinct from old.auth_subject then
    raise exception 'auth_subject is immutable';
  end if;
  return new;
end;
$$;

-- ------------------------------------------------------- identifiers --

-- email (contains @) | phone (starts with + / 00 / digit) | username.
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
  elsif v ~ '^[+0-9]' then
    kind := 'phone';
    value := regexp_replace(v, '[\s().-]', '', 'g');
    if value like '00%' then value := '+' || substr(value, 3); end if;
    if value !~ '^\+[1-9][0-9]{7,14}$' then
      raise exception 'invalid_identifier' using errcode = 'SA400';
    end if;
  else
    kind := 'username';
    value := lower(v);
    if value !~ '^[a-z0-9_.]{3,30}$' then
      raise exception 'invalid_identifier' using errcode = 'SA400';
    end if;
  end if;
end;
$$;

create or replace function app_private.find_user_by_identifier(p text)
returns uuid
language plpgsql stable security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare v record;
begin
  select * into v from auth_api.normalize_identifier(p);
  return (select id from users where
            (v.kind = 'email' and lower(email) = v.value)
         or (v.kind = 'phone' and phone = v.value)
         or (v.kind = 'username' and username = v.value));
end;
$$;

-- Same as 0009, but also accepts usernames.
create or replace function auth_api.login(p_identifier text, p_password text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  v_uid uuid;
  v_user users%rowtype;
  v_cred app_private.credentials%rowtype;
begin
  begin
    v_uid := app_private.find_user_by_identifier(p_identifier);
  exception when others then
    return jsonb_build_object('error', 'invalid_credentials');
  end;
  select * into v_user from users where id = v_uid;
  select * into v_cred from app_private.credentials where user_id = v_uid;

  if v_cred.user_id is null then
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
    where user_id = v_uid;
    return jsonb_build_object('error', 'invalid_credentials');
  end if;
  if not v_user.is_active then
    return jsonb_build_object('error', 'disabled');
  end if;
  update app_private.credentials set failed_attempts = 0, locked_until = null
  where user_id = v_uid;
  return auth_api._profile(v_uid);
end;
$$;

create or replace function auth_api._profile(p_user uuid)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select jsonb_build_object(
    'id', u.id, 'role', u.role, 'is_superadmin', u.is_superadmin,
    'display_name', u.display_name, 'username', u.username,
    'email', u.email, 'phone', u.phone,
    'must_change_password', coalesce(c.must_change, false))
  from users u left join app_private.credentials c on c.user_id = u.id
  where u.id = p_user
$$;

-- ------------------------------------------------ account creation --

-- Normalises and checks one optional identifier; raises a readable error.
create or replace function app_private.checked_identifier(p text, p_kind text)
returns text
language plpgsql stable security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare v record;
begin
  if nullif(trim(coalesce(p, '')), '') is null then return null; end if;
  begin
    select * into v from auth_api.normalize_identifier(p);
  exception when others then
    raise exception 'invalid %', p_kind using errcode = 'PT400';
  end;
  if v.kind <> p_kind then
    raise exception 'invalid %', p_kind using errcode = 'PT400';
  end if;
  return v.value;
end;
$$;

-- Shared by the admin API and tool/db.dart (owner). No permission checks
-- here. Callers enforce them.
create or replace function app_private.create_account(
  p_display_name text, p_phone text, p_email text, p_username text,
  p_role app_role, p_superadmin boolean, p_password text, p_must_change boolean)
returns uuid
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  v_id uuid := gen_random_uuid();
  v_phone text := app_private.checked_identifier(p_phone, 'phone');
  v_email text := app_private.checked_identifier(p_email, 'email');
  v_username text := app_private.checked_identifier(p_username, 'username');
begin
  if coalesce(trim(p_display_name), '') = '' then
    raise exception 'name is required' using errcode = 'PT400';
  end if;
  if v_phone is null and v_email is null and v_username is null then
    raise exception 'a phone number, email or username is required' using errcode = 'PT400';
  end if;
  if coalesce(length(p_password), 0) < 8 then
    raise exception 'password must be at least 8 characters' using errcode = 'PT400';
  end if;
  if exists (select 1 from users where phone = v_phone) then
    raise exception 'this phone number is already used' using errcode = 'PT409';
  end if;
  if exists (select 1 from users where lower(email) = v_email) then
    raise exception 'this email is already used' using errcode = 'PT409';
  end if;
  if exists (select 1 from users where username = v_username) then
    raise exception 'this username is already taken' using errcode = 'PT409';
  end if;

  perform set_config('sidra.role_change', 'allowed', true);
  insert into users (id, auth_subject, display_name, phone, email, username, role, is_superadmin)
  values (v_id, v_id::text, trim(p_display_name), v_phone, v_email, v_username,
          p_role, coalesce(p_superadmin, false) and p_role = 'admin');
  insert into learner_profiles (user_id) values (v_id);
  insert into app_private.credentials (user_id, password_hash, must_change)
  values (v_id, crypt(p_password, gen_salt('bf', 10)), p_must_change);
  return v_id;
end;
$$;

-- Admins create learners and teachers; only superadmins create admins.
-- The new person must change the temporary password at first sign-in.
create or replace function public.admin_create_user(
  p_display_name text,
  p_role app_role,
  p_temporary_password text,
  p_phone text default null,
  p_email text default null,
  p_username text default null,
  p_superadmin boolean default false)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare v_id uuid;
begin
  if not app_private.is_admin() then
    raise exception 'administrators only' using errcode = 'PT403';
  end if;
  if (p_role = 'admin' or p_superadmin) and not app_private.is_superadmin() then
    raise exception 'only a superadmin can create administrators' using errcode = 'PT403';
  end if;
  v_id := app_private.create_account(p_display_name, p_phone, p_email, p_username,
                                     p_role, p_superadmin, p_temporary_password, true);
  return auth_api._profile(v_id);
end;
$$;

-- --------------------------------------------------- account changes --

-- Can the caller manage this account? Admins manage learners/teachers;
-- administrators are managed by superadmins only.
create or replace function app_private.can_manage_user(p_user uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.is_admin() and exists (
    select 1 from users u where u.id = p_user
      and (u.role <> 'admin' or app_private.is_superadmin()))
$$;

create or replace function public.admin_update_user(
  p_user_id uuid,
  p_display_name text,
  p_phone text default null,
  p_email text default null,
  p_username text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  v_phone text := app_private.checked_identifier(p_phone, 'phone');
  v_email text := app_private.checked_identifier(p_email, 'email');
  v_username text := app_private.checked_identifier(p_username, 'username');
begin
  if not (app_private.can_manage_user(p_user_id)
          or p_user_id = app_private.current_user_id() and app_private.is_admin()) then
    raise exception 'not allowed to edit this person' using errcode = 'PT403';
  end if;
  if coalesce(trim(p_display_name), '') = '' then
    raise exception 'name is required' using errcode = 'PT400';
  end if;
  if v_phone is null and v_email is null and v_username is null then
    raise exception 'a phone number, email or username is required' using errcode = 'PT400';
  end if;
  if exists (select 1 from users where phone = v_phone and id <> p_user_id) then
    raise exception 'this phone number is already used' using errcode = 'PT409';
  end if;
  if exists (select 1 from users where lower(email) = v_email and id <> p_user_id) then
    raise exception 'this email is already used' using errcode = 'PT409';
  end if;
  if exists (select 1 from users where username = v_username and id <> p_user_id) then
    raise exception 'this username is already taken' using errcode = 'PT409';
  end if;
  update users set display_name = trim(p_display_name), phone = v_phone,
                   email = v_email, username = v_username
  where id = p_user_id;
  return auth_api._profile(p_user_id);
end;
$$;

-- Role changes: learner <-> teacher by admins; anything involving the
-- admin role (or superadmin flag) by superadmins. Nobody changes their own.
create or replace function public.set_user_role(p_user_id uuid, p_role app_role)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_user users%rowtype;
begin
  if not app_private.is_admin() then
    raise exception 'administrators only' using errcode = 'PT403';
  end if;
  if p_user_id = app_private.current_user_id() then
    raise exception 'you cannot change your own role' using errcode = 'PT409';
  end if;
  select * into v_user from users where id = p_user_id;
  if not found then raise exception 'user not found' using errcode = 'PT404'; end if;
  if (v_user.role = 'admin' or p_role = 'admin') and not app_private.is_superadmin() then
    raise exception 'only a superadmin can change administrators' using errcode = 'PT403';
  end if;
  perform set_config('sidra.role_change', 'allowed', true);
  update users set role = p_role,
    is_superadmin = case when p_role = 'admin' then is_superadmin else false end
  where id = p_user_id returning * into v_user;
  return jsonb_build_object('id', v_user.id, 'role', v_user.role,
                            'is_superadmin', v_user.is_superadmin);
end;
$$;

create or replace function public.set_superadmin(p_user_id uuid, p_superadmin boolean)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.is_superadmin() then
    raise exception 'superadmins only' using errcode = 'PT403';
  end if;
  if p_user_id = app_private.current_user_id() and not p_superadmin then
    raise exception 'you cannot remove your own superadmin access' using errcode = 'PT409';
  end if;
  if p_superadmin and not exists (select 1 from users where id = p_user_id and role = 'admin') then
    raise exception 'make this person an administrator first' using errcode = 'PT409';
  end if;
  perform set_config('sidra.role_change', 'allowed', true);
  update users set is_superadmin = p_superadmin where id = p_user_id;
end;
$$;

-- Disable/enable an account. Disabling signs the person out everywhere.
create or replace function public.set_user_active(p_user_id uuid, p_active boolean)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.can_manage_user(p_user_id) then
    raise exception 'not allowed to change this account' using errcode = 'PT403';
  end if;
  if p_user_id = app_private.current_user_id() then
    raise exception 'you cannot disable your own account' using errcode = 'PT409';
  end if;
  update users set is_active = p_active where id = p_user_id;
  if not p_active then
    update app_private.refresh_tokens set revoked_at = coalesce(revoked_at, now())
    where user_id = p_user_id;
  end if;
end;
$$;

-- Last active superadmin can never be removed, demoted or disabled.
create or replace function app_private.keep_a_superadmin()
returns trigger
language plpgsql
as $$
begin
  if old.is_superadmin and old.is_active
     and not (new.is_superadmin and new.is_active and new.role = 'admin')
     and not exists (select 1 from users where id <> old.id
                     and is_superadmin and is_active and role = 'admin') then
    raise exception 'Sidra must keep at least one active superadmin' using errcode = 'PT409';
  end if;
  return new;
end;
$$;
create trigger users_keep_superadmin before update on users
  for each row execute function app_private.keep_a_superadmin();

-- Admin password resets: admins reset learners/teachers; superadmins also
-- reset admins. (Teachers still reset their own learners, as in 0009.)
create or replace function public.reset_password(p_user_id uuid, p_temporary text)
returns void
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare v_target app_role;
begin
  select role into v_target from users where id = p_user_id;
  if v_target is null then
    if app_private.is_admin() then
      raise exception 'user not found' using errcode = 'PT404';
    end if;
    raise exception 'not allowed to reset this password' using errcode = 'PT403';
  end if;
  if not (
    app_private.can_manage_user(p_user_id)
    or (v_target = 'learner' and exists (
          select 1 from course_enrolments e
          where e.user_id = p_user_id and app_private.is_course_staff(e.course_id)))
  ) then
    raise exception 'not allowed to reset this password' using errcode = 'PT403';
  end if;
  if coalesce(length(p_temporary), 0) < 8 then
    raise exception 'temporary password must be at least 8 characters' using errcode = 'PT400';
  end if;
  insert into app_private.credentials (user_id, password_hash, must_change)
  values (p_user_id, crypt(p_temporary, gen_salt('bf', 10)), true)
  on conflict (user_id) do update set
    password_hash = excluded.password_hash, must_change = true,
    failed_attempts = 0, locked_until = null, password_changed_at = now();
  update app_private.refresh_tokens set revoked_at = coalesce(revoked_at, now())
  where user_id = p_user_id;
end;
$$;

-- ------------------------------------------------------ overview --

create or replace function public.admin_overview()
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case when not app_private.is_admin() then null else jsonb_build_object(
    'learners', (select count(*) from users where role = 'learner' and is_active),
    'teachers', (select count(*) from users where role = 'teacher' and is_active),
    'admins', (select count(*) from users where role = 'admin' and is_active),
    'disabled', (select count(*) from users where not is_active),
    'courses_published', (select count(*) from courses where status = 'published'),
    'courses_draft', (select count(*) from courses where status = 'draft'),
    'active_enrolments', (select count(*) from course_enrolments where status = 'active'),
    'active_learners_7d', (select count(distinct user_id) from learner_progress
                           where last_accessed_at > now() - interval '7 days'),
    'lessons_completed_7d', (select count(*) from learner_progress
                             where completed_at > now() - interval '7 days')
  ) end
$$;

revoke all on function
  public.admin_create_user(text, app_role, text, text, text, text, boolean),
  public.admin_update_user(uuid, text, text, text, text),
  public.set_superadmin(uuid, boolean),
  public.set_user_active(uuid, boolean),
  public.admin_overview()
from public, anonymous;
grant execute on function
  public.admin_create_user(text, app_role, text, text, text, text, boolean),
  public.admin_update_user(uuid, text, text, text, text),
  public.set_superadmin(uuid, boolean),
  public.set_user_active(uuid, boolean),
  public.admin_overview()
to authenticated;
