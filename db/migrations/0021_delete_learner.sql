-- Permanently delete a learner.
--
-- Everything about the learner is erased: sign-in, profile, enrolments,
-- progress, unlocks, quiz attempts, recordings and photos they handed in,
-- teacher notes about them, notifications, group memberships, and personal
-- data inside the activity log. Their uploaded files are removed from the
-- database immediately (so no link can be signed any more) and queued for
-- deletion from Cloudinary.
--
-- One exception, by the finance rule "money records are never deleted":
-- if the learner has payments or waivers, the account row itself is kept as
-- "Removed learner" (no name, phone, email, username, password or data) so
-- the books still add up. Otherwise the row is deleted too.

alter table users add column removed_at timestamptz;

insert into permissions (key, area, description)
values ('learners.delete', 'people', 'Delete learners permanently')
on conflict (key) do nothing;
insert into role_permissions (role_key, permission_key)
select r, 'learners.delete' from unnest(array['super_admin', 'admin']) r
where exists (select 1 from app_roles where key = r)
on conflict do nothing;

-- Files waiting to be deleted from Cloudinary (the payments server, which
-- runs with the service credentials, empties this queue).
create table app_private.media_purge (
  id bigserial primary key,
  public_id text not null,
  resource_type text not null,
  delivery text not null,
  queued_at timestamptz not null default now(),
  purged_at timestamptz,
  attempts int not null default 0,
  last_error text
);

create or replace function public.delete_learner(
  p_user_id uuid, p_confirm text, p_reason text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v users%rowtype;
  v_me uuid := app_private.current_user_id();
  v_keep boolean;
  v_asset record;
  v_files int := 0;
begin
  if not app_private.has_permission('learners.delete') then
    raise exception 'not allowed to delete learners' using errcode = 'PT403';
  end if;
  select * into v from users where id = p_user_id and removed_at is null for update;
  if not found then raise exception 'learner not found' using errcode = 'PT404'; end if;
  if v.id = v_me then raise exception 'you cannot delete yourself' using errcode = 'PT422'; end if;
  if v.role <> 'learner' or v.is_superadmin
     or exists (select 1 from user_roles where user_id = v.id) then
    raise exception 'only learners can be deleted; disable staff accounts instead'
      using errcode = 'PT422';
  end if;
  if lower(trim(coalesce(p_confirm, ''))) not in (
       lower(trim(coalesce(v.display_name, ''))), lower(trim(coalesce(v.username, '')))) then
    raise exception 'type the learner''s name exactly to confirm' using errcode = 'PT422';
  end if;

  v_keep := exists (select 1 from payments where user_id = v.id)
         or exists (select 1 from waivers where user_id = v.id);

  -- Learning data (children first; most would cascade, but the kept-row
  -- path needs them removed explicitly).
  delete from submissions where user_id = v.id;           -- files, reviews cascade
  delete from quiz_attempts where user_id = v.id;         -- answers cascade
  delete from portion_learners where user_id = v.id;
  delete from teaching_group_members where user_id = v.id;
  delete from lesson_reviews where user_id = v.id;
  delete from lesson_unlocks where user_id = v.id;
  delete from learner_progress where user_id = v.id;
  delete from course_enrolments where user_id = v.id;
  delete from teacher_notes where learner_id = v.id;
  delete from notifications where user_id = v.id;
  delete from sync_operations where user_id = v.id;
  delete from learner_profiles where user_id = v.id;
  delete from app_private.refresh_tokens where user_id = v.id;
  delete from app_private.access_tokens where user_id = v.id;
  delete from app_private.credentials where user_id = v.id;

  -- Their own uploads, except proof-of-payment files (finance records).
  for v_asset in
    select m.* from media_assets m
    where m.uploaded_by = v.id
      and not exists (select 1 from payments p where p.proof_asset_id = m.id)
  loop
    begin
      delete from media_assets where id = v_asset.id;
      insert into app_private.media_purge (public_id, resource_type, delivery)
      values (v_asset.public_id, v_asset.resource_type, v_asset.delivery::text);
      v_files := v_files + 1;
    exception when foreign_key_violation then
      null;  -- still used by course material: keep it
    end;
  end loop;

  if v_keep then
    update users set display_name = 'Removed learner', phone = null, email = null,
      username = null, avatar_url = null, languages = '{}', is_active = false,
      removed_at = now()
    where id = v.id;
  else
    delete from users where id = v.id;
  end if;

  -- Personal data recorded in the activity log.
  update audit_log set changes = jsonb_build_object('erased', true)
  where entity_id = v.id::text and entity in ('users', 'learner_profiles');
  insert into audit_log (actor_id, action, entity, entity_id, changes, note)
  values (v_me, 'learner.deleted', 'users', v.id::text,
          jsonb_build_object('kept_for_finance', v_keep, 'files_removed', v_files),
          nullif(trim(p_reason), ''));

  return jsonb_build_object('mode', case when v_keep then 'anonymised' else 'deleted' end,
                            'files_removed', v_files);
end;
$$;
revoke all on function public.delete_learner(uuid, text, text) from public;
grant execute on function public.delete_learner(uuid, text, text) to authenticated, sidra_app;

-- Cloudinary deletions, signed in the database (the secret never leaves it).
create or replace function payments_api.claim_media_purge(p_limit int default 20)
returns setof jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_cloud text := app_private.setting('cloudinary_cloud_name');
  v_key text := app_private.setting('cloudinary_api_key');
  v_secret text := app_private.setting('cloudinary_api_secret');
  v_ts text := extract(epoch from now())::bigint::text;
  r record;
begin
  if v_secret is null then return; end if;
  for r in select * from app_private.media_purge
           where purged_at is null and attempts < 5
           order by id limit p_limit for update skip locked loop
    update app_private.media_purge set attempts = attempts + 1 where id = r.id;
    return next jsonb_build_object(
      'id', r.id,
      'url', format('https://api.cloudinary.com/v1_1/%s/%s/destroy', v_cloud, r.resource_type),
      'fields', jsonb_build_object(
        'public_id', r.public_id, 'type', r.delivery, 'timestamp', v_ts, 'api_key', v_key,
        'signature', encode(digest(format('public_id=%s&timestamp=%s&type=%s', r.public_id,
                                          v_ts, r.delivery) || v_secret, 'sha1'), 'hex')));
  end loop;
end;
$$;

create or replace function payments_api.finish_media_purge(p_id bigint, p_error text default null)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update app_private.media_purge
  set purged_at = case when p_error is null then now() end, last_error = p_error
  where id = p_id
$$;
revoke all on function payments_api.claim_media_purge(int), payments_api.finish_media_purge(bigint, text)
  from public;
grant execute on function payments_api.claim_media_purge(int), payments_api.finish_media_purge(bigint, text)
  to sidra_payments;

-- Removed learners no longer appear in people lists or counts.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.admin_people(app_role, text, boolean, int, int)'::regprocedure);
  if position('  where (p_persona is null or u.role = p_persona)' in v_src) = 0 then
    raise exception 'admin_people changed; update 0021';
  end if;
  execute replace(v_src, '  where (p_persona is null or u.role = p_persona)',
                  '  where u.removed_at is null and (p_persona is null or u.role = p_persona)');

  v_src := pg_get_functiondef('public.admin_list_users(text)'::regprocedure);
  execute replace(v_src, '  where (app_private.has_permission(''learners.view'')',
                  '  where u.removed_at is null and (app_private.has_permission(''learners.view'')');
end $$;

do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.admin_overview()'::regprocedure);
  if position('(select count(*) from users where not is_active)' in v_src) = 0 then
    raise exception 'admin_overview changed; update 0021';
  end if;
  execute replace(v_src, '(select count(*) from users where not is_active)',
                  '(select count(*) from users where not is_active and removed_at is null)');
end $$;
