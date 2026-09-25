-- 0011 the app connects to PostgreSQL directly (no Data API, no Worker).
--
-- The app logs in to Postgres as `sidra_app`. That login ships inside the
-- APK, so it is treated as PUBLIC: on its own it can only
--   * call the sign-in functions (auth_api.app_*), and
--   * read what an anonymous visitor may read (published catalogue).
-- Everything else needs a learner session token: each app transaction
-- starts with app_private.authenticate(token), which binds the learner's
-- identity to THIS backend + THIS transaction in a table the app cannot
-- write. RLS and every SECURITY DEFINER function then see that learner.

-- ----------------------------------------------------- access tokens --

create table app_private.access_tokens (
  token_hash text primary key,
  user_id uuid not null references users (id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  revoked_at timestamptz
);
create index access_tokens_user on app_private.access_tokens (user_id);

-- Identity of the current transaction on each backend (one row per
-- backend, overwritten per transaction; unlogged = cheap).
create unlogged table app_private.connection_identity (
  backend_pid int primary key,
  xact xid8 not null,
  user_id uuid not null
);

create or replace function auth_api._issue_access(p_user uuid)
returns text
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_token text := encode(gen_random_bytes(32), 'hex');
begin
  delete from app_private.access_tokens
  where user_id = p_user and (expires_at < now() or revoked_at is not null);
  insert into app_private.access_tokens (token_hash, user_id, expires_at)
  values (encode(digest(v_token, 'sha256'), 'hex'), p_user, now() + interval '1 hour');
  return v_token;
end;
$$;

-- Binds a session token to the current transaction. Call first in every
-- app transaction. Raises PT401 when the token is unknown/expired.
create or replace function app_private.authenticate(p_token text)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_user uuid;
begin
  select t.user_id into v_user
  from app_private.access_tokens t join users u on u.id = t.user_id
  where t.token_hash = encode(digest(coalesce(p_token, ''), 'sha256'), 'hex')
    and t.revoked_at is null and t.expires_at > now() and u.is_active;
  if v_user is null then
    raise exception 'session expired' using errcode = 'PT401';
  end if;
  insert into app_private.connection_identity (backend_pid, xact, user_id)
  values (pg_backend_pid(), pg_current_xact_id(), v_user)
  on conflict (backend_pid) do update
    set xact = excluded.xact, user_id = excluded.user_id;
end;
$$;

-- Identity comes ONLY from the transaction-bound session written by
-- authenticate(). (pg_session_jwt's auth.user_id() is NOT consulted: it
-- trusts the request.jwt.claims setting, which a direct connection can set
-- to anything. Consulting it would let the app login impersonate anyone.)
create or replace function app_private.jwt_sub()
returns text
language sql stable security definer
set search_path = public, app_private, pg_catalog, pg_temp
as $$
  select user_id::text from app_private.connection_identity
  where backend_pid = pg_backend_pid()
    and xact = pg_current_xact_id_if_assigned()
$$;

-- ----------------------------------------------- app sign-in functions --

create or replace function auth_api._session(p_user uuid, p_refresh text)
returns jsonb
language sql volatile security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
  select jsonb_build_object(
    'access_token', auth_api._issue_access(p_user),
    'expires_in', 3600,
    'refresh_token', p_refresh,
    'user', auth_api._profile(p_user))
$$;

create or replace function auth_api.app_register(
  p_identifier text, p_password text, p_display_name text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare v_user jsonb;
begin
  v_user := auth_api.register(p_identifier, p_password, p_display_name);
  return auth_api._session((v_user->>'id')::uuid,
                           auth_api.issue_refresh((v_user->>'id')::uuid));
exception when sqlstate 'SA400' or sqlstate 'SA409' then
  return jsonb_build_object('error', sqlerrm);
end;
$$;

create or replace function auth_api.app_login(p_identifier text, p_password text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare v jsonb := auth_api.login(p_identifier, p_password);
begin
  if v ? 'error' then return v; end if;
  return auth_api._session((v->>'id')::uuid, auth_api.issue_refresh((v->>'id')::uuid));
end;
$$;

create or replace function auth_api.app_refresh(p_refresh_token text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare v jsonb := auth_api.rotate_refresh(p_refresh_token);
begin
  if v ? 'error' then return v; end if;
  return auth_api._session((v->>'id')::uuid, v->>'refresh_token');
end;
$$;

create or replace function auth_api.app_logout(p_refresh_token text, p_access_token text default null)
returns void
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
begin
  perform auth_api.revoke_refresh(p_refresh_token);
  update app_private.access_tokens set revoked_at = now()
  where token_hash = encode(digest(coalesce(p_access_token, ''), 'sha256'), 'hex');
end;
$$;

create or replace function auth_api.app_change_password(
  p_access_token text, p_old text, p_new text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare v_user uuid;
begin
  select user_id into v_user from app_private.access_tokens
  where token_hash = encode(digest(coalesce(p_access_token, ''), 'sha256'), 'hex')
    and revoked_at is null and expires_at > now();
  if v_user is null then
    return jsonb_build_object('error', 'invalid_token');
  end if;
  begin
    perform auth_api.change_password(v_user, p_old, p_new);
  exception when sqlstate 'SA400' or sqlstate 'SA401' then
    return jsonb_build_object('error', sqlerrm);
  end;
  update app_private.access_tokens set revoked_at = now()
  where user_id = v_user and revoked_at is null;
  return auth_api._session(v_user, auth_api.issue_refresh(v_user));
end;
$$;

-- Any password change (staff reset or self-service) ends every existing
-- session immediately; app_change_password then issues a fresh one.
-- (Disabling is covered by authenticate(), which requires an active user;
-- password changes revoke in app_change_password.)
create or replace function app_private.revoke_access_after_reset()
returns trigger
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if new.password_hash is distinct from old.password_hash then
    update app_private.access_tokens set revoked_at = now()
    where user_id = new.user_id and revoked_at is null;
  end if;
  return new;
end;
$$;
create trigger credentials_reset_revokes_access
  after update on app_private.credentials
  for each row execute function app_private.revoke_access_after_reset();

-- --------------------------------------- contact details are private --

-- Learners may see teachers' names, not their phone/email/username.
revoke select on users from authenticated;
grant select (id, display_name, avatar_url, role, is_active, created_at)
  on users to authenticated;
-- (sidra_app is granted the same below.)

-- Admin people list with contact details.
create or replace function public.admin_list_users(p_search text default null)
returns table (
  id uuid, display_name text, phone text, email text, username text,
  role app_role, is_superadmin boolean, is_active boolean, created_at timestamptz)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select u.id, u.display_name, u.phone, u.email, u.username, u.role,
         u.is_superadmin, u.is_active, u.created_at
  from users u
  where app_private.is_admin()
    and (p_search is null or p_search = ''
         or u.display_name ilike '%' || p_search || '%'
         or u.phone ilike '%' || p_search || '%'
         or u.email ilike '%' || p_search || '%'
         or u.username ilike '%' || p_search || '%')
  order by u.role desc, u.display_name nulls last
  limit 500
$$;

-- Staff view of a course's people (learners + staff) with names.
create or replace function public.course_people(p_course_id uuid)
returns table (
  user_id uuid, display_name text, contact text, kind text, status text,
  enrolment_id uuid, since timestamptz)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select e.user_id, u.display_name, coalesce(u.phone, u.email, u.username),
         'learner', e.status::text, e.id, e.enrolled_at
  from course_enrolments e join users u on u.id = e.user_id
  where e.course_id = p_course_id and app_private.is_course_staff(p_course_id)
  union all
  select s.user_id, u.display_name, coalesce(u.phone, u.email, u.username),
         'staff', s.role::text, null, s.created_at
  from course_staff s join users u on u.id = s.user_id
  where s.course_id = p_course_id and app_private.is_course_staff(p_course_id)
  order by 4 desc, 2 nulls last
$$;

-- -------------------------------------------------------- app role --

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'sidra_app') then
    create role sidra_app nologin;
  end if;
end $$;
-- Neon manages the `authenticated` role, so we cannot add members to it.
-- Instead sidra_app receives exactly the privileges authenticated has, and
-- the RLS policies (previously TO authenticated) apply to every role that
-- holds table privileges. `anonymous` still has none.
do $$
declare r record;
begin
  for r in select schemaname, tablename, policyname from pg_policies
           where roles = '{authenticated}' loop
    execute format('alter policy %I on %I.%I to public',
                   r.policyname, r.schemaname, r.tablename);
  end loop;

  for r in select distinct table_schema, table_name, privilege_type
           from information_schema.role_table_grants
           where grantee = 'authenticated' and table_schema in ('public', 'app_private') loop
    execute format('grant %s on %I.%I to sidra_app',
                   r.privilege_type, r.table_schema, r.table_name);
  end loop;

  for r in select table_schema, table_name, privilege_type,
                  string_agg(format('%I', column_name), ', ') cols
           from information_schema.column_privileges c
           where grantee = 'authenticated' and table_schema = 'public'
             and not exists (select 1 from information_schema.role_table_grants t
                             where t.grantee = 'authenticated' and t.table_schema = c.table_schema
                               and t.table_name = c.table_name and t.privilege_type = c.privilege_type)
           group by 1, 2, 3 loop
    execute format('grant %s (%s) on %I.%I to sidra_app',
                   r.privilege_type, r.cols, r.table_schema, r.table_name);
  end loop;

  for r in select p.oid::regprocedure as fn
           from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname in ('public', 'app_private')
             and has_function_privilege('authenticated', p.oid, 'execute')
             and not has_function_privilege('public', p.oid, 'execute') loop
    execute format('grant execute on function %s to sidra_app', r.fn);
  end loop;
end $$;
grant usage on schema public, app_private to sidra_app;
alter role sidra_app set statement_timeout = '20s';
alter role sidra_app set idle_in_transaction_session_timeout = '30s';
alter role sidra_app connection limit 300;

-- New functions default to EXECUTE for PUBLIC. Lock auth_api down first,
-- so internal helpers such as _issue_access(user) can never be called by
-- the app login, then grant only the app-facing entry points.
revoke all on all functions in schema auth_api from public;
alter default privileges in schema auth_api revoke execute on functions from public;
grant usage on schema auth_api to sidra_app;
grant execute on function
  auth_api.app_register(text, text, text),
  auth_api.app_login(text, text),
  auth_api.app_refresh(text),
  auth_api.app_logout(text, text),
  auth_api.app_change_password(text, text, text)
to sidra_app;
grant execute on function app_private.authenticate(text) to sidra_app;

revoke all on function public.admin_list_users(text), public.course_people(uuid)
  from public, anonymous;
grant execute on function public.admin_list_users(text), public.course_people(uuid)
  to authenticated, sidra_app;

-- ------------------------------------------------ identity by user id --
-- Sessions now identify users by users.id (not auth_subject).

create or replace function app_private.current_user_id()
returns uuid
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select id from users where id::text = app_private.jwt_sub() and is_active
$$;

create or replace function app_private.current_app_role()
returns app_role
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select role from users where id::text = app_private.jwt_sub() and is_active
$$;

create or replace function public.ensure_profile(
  p_display_name text default null,
  p_email text default null,
  p_avatar_url text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare v_user users%rowtype;
begin
  select * into v_user from users where id::text = app_private.jwt_sub();
  if not found then
    raise exception 'not signed in' using errcode = 'PT401';
  end if;
  if not v_user.is_active then
    raise exception 'account disabled' using errcode = 'PT403';
  end if;
  update users set
    display_name = coalesce(nullif(trim(p_display_name), ''), display_name),
    avatar_url = coalesce(p_avatar_url, avatar_url)
  where id = v_user.id;
  insert into learner_profiles (user_id) values (v_user.id) on conflict do nothing;
  return auth_api._profile(v_user.id);
end;
$$;
