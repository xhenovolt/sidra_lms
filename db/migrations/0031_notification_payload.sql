-- Phone notifications carry their full data (submission, lesson, course),
-- so tapping one opens the right work or lesson.
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
                              'portion_id', n.data->>'portion_id', 'data', n.data,
                              'created_at', n.created_at)
    from notifications n
    where n.user_id = v_user and n.read_at is null
      and n.created_at > coalesce(p_after, now() - interval '1 day')
    order by n.created_at
    limit 20;
end;
$$;
