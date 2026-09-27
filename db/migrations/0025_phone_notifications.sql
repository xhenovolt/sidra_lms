-- Phone notifications without Firebase: each signed-in phone gets a
-- notification-only token. With it, the app's background check (Android
-- WorkManager, about every 15 minutes) can read the titles of new in-app
-- notifications — and nothing else. The token is stored hashed, is revoked
-- on sign-out, and dies with the account.

create table app_private.notification_tokens (
  token_hash text primary key,
  user_id uuid not null references users (id) on delete cascade,
  created_at timestamptz not null default now(),
  last_used_at timestamptz
);
create index notification_tokens_user on app_private.notification_tokens (user_id);

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
  insert into app_private.notification_tokens (token_hash, user_id)
  values (encode(digest(v_token, 'sha256'), 'hex'), v_me);
  return v_token;
end;
$$;

create or replace function public.revoke_notification_token(p_token text)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  delete from app_private.notification_tokens
  where token_hash = encode(digest(coalesce(p_token, ''), 'sha256'), 'hex')
$$;

-- New unread notifications for the token's owner, after p_after.
create or replace function public.poll_notifications(p_token text, p_after timestamptz default null)
returns setof jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_user uuid;
begin
  update app_private.notification_tokens t set last_used_at = now()
  from users u
  where t.token_hash = encode(digest(coalesce(p_token, ''), 'sha256'), 'hex')
    and u.id = t.user_id and u.is_active and u.removed_at is null
  returning t.user_id into v_user;
  if v_user is null then return; end if;
  return query
    select jsonb_build_object('id', n.id, 'kind', n.kind, 'title', n.title, 'body', n.body,
                              'portion_id', n.data->>'portion_id', 'created_at', n.created_at)
    from notifications n
    where n.user_id = v_user and n.read_at is null
      and n.created_at > coalesce(p_after, now() - interval '1 day')
    order by n.created_at
    limit 20;
end;
$$;

revoke all on function public.issue_notification_token(), public.revoke_notification_token(text),
  public.poll_notifications(text, timestamptz) from public;
grant execute on function public.issue_notification_token() to authenticated, sidra_app;
grant execute on function public.revoke_notification_token(text),
  public.poll_notifications(text, timestamptz) to anonymous, authenticated, sidra_app;

-- Deleting a learner also revokes their phones.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.delete_learner(uuid, text, text)'::regprocedure);
  if position('  delete from app_private.credentials where user_id = v.id;' in v_src) = 0 then
    raise exception 'delete_learner changed; update 0025';
  end if;
  execute replace(v_src, '  delete from app_private.credentials where user_id = v.id;',
    '  delete from app_private.credentials where user_id = v.id;
  delete from app_private.notification_tokens where user_id = v.id;');
end $$;
