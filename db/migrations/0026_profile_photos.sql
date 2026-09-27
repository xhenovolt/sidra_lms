-- Profile photos: a photo taken in the app, one uploaded from the phone, or
-- a built-in avatar.
--   users.avatar_url = 'media:<media asset id>'  (their own uploaded image)
--                    | 'avatar:<key>'            (a built-in avatar)
--                    | null                      (initials)

alter table users add constraint users_avatar_format check (
  avatar_url is null
  or avatar_url ~ '^avatar:[a-z0-9_]{1,32}$'
  or avatar_url ~ '^media:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

create or replace function public.set_my_avatar(p_value text)
returns text
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_asset uuid;
  v_old text;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  if p_value is not null and p_value like 'media:%' then
    v_asset := substr(p_value, 7)::uuid;
    if not exists (select 1 from media_assets where id = v_asset and uploaded_by = v_me
                   and kind = 'image') then
      raise exception 'the photo must be one you uploaded' using errcode = 'PT403';
    end if;
  elsif p_value is not null and p_value !~ '^avatar:[a-z0-9_]{1,32}$' then
    raise exception 'unknown avatar' using errcode = 'PT422';
  end if;
  select avatar_url into v_old from users where id = v_me;
  update users set avatar_url = p_value, updated_at = now() where id = v_me;
  -- The previous photo is no longer needed.
  if v_old like 'media:%' and v_old is distinct from p_value then
    begin
      with gone as (
        delete from media_assets where id = substr(v_old, 7)::uuid and uploaded_by = v_me
        returning public_id, resource_type, delivery)
      insert into app_private.media_purge (public_id, resource_type, delivery)
      select public_id, resource_type, delivery::text from gone;
    exception when foreign_key_violation then
      null;
    end;
  end if;
  return p_value;
end;
$$;
revoke all on function public.set_my_avatar(text) from public;
grant execute on function public.set_my_avatar(text) to authenticated, sidra_app;

do $$
declare v_src text;
begin
  -- A profile photo is visible to anyone signed in (like a class list).
  v_src := pg_get_functiondef('app_private.can_read_media(uuid)'::regprocedure);
  if position('    else
      app_private.has_permission(''courses.view'')' in v_src) = 0 then
    raise exception 'can_read_media changed; update 0026';
  end if;
  execute replace(v_src, '    else
      app_private.has_permission(''courses.view'')', '    else
      (app_private.current_user_id() is not null
       and exists (select 1 from users u where u.avatar_url = ''media:'' || p_asset_id::text))
      or app_private.has_permission(''courses.view'')');

  -- Profiles and the review board show photos.
  v_src := pg_get_functiondef('public.admin_person_profile(uuid)'::regprocedure);
  execute replace(v_src, '''languages'', v.languages,',
                  '''languages'', v.languages, ''avatar_url'', v.avatar_url,');
  v_src := pg_get_functiondef('public.portion_board(uuid)'::regprocedure);
  if position('''name'', u.display_name,' in v_src) = 0 then
    raise exception 'portion_board changed; update 0026';
  end if;
  execute replace(v_src, '''name'', u.display_name,',
                  '''name'', u.display_name, ''avatar_url'', u.avatar_url,');
end $$;
