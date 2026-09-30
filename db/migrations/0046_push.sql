-- 0046 Instant notifications (Firebase Cloud Messaging).
--
-- Every notification is already a row in `notifications` (written by
-- app_private.notify). This adds delivery by push:
--   * each signed-in phone registers the push address Google gives the app
--     (an FCM token — a random code, not a phone number);
--   * a small cloud function (Cloudflare Worker, the `sidra_push` login)
--     claims notifications not yet pushed, sends them through Firebase and
--     drops push addresses Google says are dead.
-- The Worker is woken by the app right after an action ("ping", which
-- carries no content) and every minute as a safety net. It only ever sends
-- notifications that exist here, each once. The in-app list stays the
-- record: a push that fails is still in the list, and the old background
-- check remains as a fallback.

create table app_private.push_devices (
  fcm_token text primary key check (length(fcm_token) between 20 and 4096),
  user_id uuid not null references users (id) on delete cascade,
  platform text not null default 'android' check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);
create index push_devices_user on app_private.push_devices (user_id);

alter table notifications add column pushed_at timestamptz;
-- Everything already there has been seen the old way: never push it now.
update notifications set pushed_at = now() where pushed_at is null;
create index notifications_to_push on notifications (created_at) where pushed_at is null;

-- The signed-in phone's push address. A phone passed to another person
-- (sign out, sign in) moves to the new account.
create or replace function public.register_push_device(p_fcm_token text, p_platform text default 'android')
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_me uuid := app_private.current_user_id();
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  if length(coalesce(p_fcm_token, '')) not between 20 and 4096 then
    raise exception 'invalid push address' using errcode = 'PT422';
  end if;
  insert into app_private.push_devices (fcm_token, user_id, platform)
  values (p_fcm_token, v_me, coalesce(p_platform, 'android'))
  on conflict (fcm_token) do update set user_id = v_me, platform = excluded.platform,
    last_seen_at = now();
end;
$$;

-- Sign-out: this phone gets no more pushes for the account.
create or replace function public.unregister_push_device(p_fcm_token text)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  delete from app_private.push_devices where fcm_token = p_fcm_token
$$;

revoke all on function public.register_push_device(text, text), public.unregister_push_device(text)
  from public, anonymous;
grant execute on function public.register_push_device(text, text), public.unregister_push_device(text)
  to authenticated, sidra_app;

-- ------------------------------------------------ the Worker's login --

create schema if not exists push_api;
revoke all on schema push_api from public;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'sidra_push') then
    create role sidra_push nologin;
  end if;
end $$;
alter role sidra_push set statement_timeout = '15s';
do $$ begin
  execute format('grant sidra_push to %I', current_user);
end $$;

-- Up to p_limit notifications not yet pushed (from the last day), marked
-- as pushed in the same step so two Workers never send one twice, each
-- with the recipient's push addresses. Users without a registered phone
-- are marked too (nothing to send).
create or replace function push_api.claim(p_limit int default 100)
returns setof jsonb
language sql volatile security definer
set search_path = public, app_private, pg_temp
as $$
  with picked as (
    select n.id from notifications n
    where n.pushed_at is null and n.created_at > now() - interval '1 day'
    order by n.created_at
    limit least(greatest(coalesce(p_limit, 100), 1), 500)
    for update skip locked
  ), marked as (
    update notifications n set pushed_at = now()
    from picked where n.id = picked.id
    returning n.*
  )
  select jsonb_build_object(
           'id', m.id, 'kind', m.kind, 'title', m.title, 'body', m.body, 'data', m.data,
           'tokens', (select jsonb_agg(d.fcm_token) from app_private.push_devices d
                      where d.user_id = m.user_id))
  from marked m
  join users u on u.id = m.user_id and u.is_active and u.removed_at is null
  where exists (select 1 from app_private.push_devices d where d.user_id = m.user_id)
$$;

-- Google said these push addresses are dead (app removed, token replaced).
create or replace function push_api.drop_tokens(p_tokens text[])
returns int
language sql volatile security definer
set search_path = public, app_private, pg_temp
as $$
  with d as (delete from app_private.push_devices where fcm_token = any (coalesce(p_tokens, '{}'))
             returning 1)
  select count(*)::int from d
$$;

grant usage on schema push_api to sidra_push;
revoke all on all functions in schema push_api from public;
grant execute on function push_api.claim(int), push_api.drop_tokens(text[]) to sidra_push;

select app_private.lock_down_functions();
