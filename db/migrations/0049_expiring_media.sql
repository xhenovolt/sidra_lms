-- 0049 Course files are handed out as links that EXPIRE (Phase 6, Stage 1).
--
-- media_url() checked access, then signed a Cloudinary "authenticated" URL —
-- but such signatures never expire: a link obtained once kept working after
-- access was withdrawn (refund, reversal, suspension, unpaid period).
-- Now every file is given as a Cloudinary download link that expires after
-- two hours (signed with the API secret; verified live 2026-10-02: a fresh
-- link → 200, an expired one → 401 "Stale request"). Only images asked for
-- with a transformation (thumbnails, avatars) that are NOT paid-course
-- content keep the old transformation URL.

-- Is this file part of a paid course's teaching content?
create or replace function app_private.is_paid_content(p_asset_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (select 1 from lesson_content_blocks b join lessons l on l.id = b.lesson_id
                 join courses c on c.id = l.course_id
                 where b.media_asset_id = p_asset_id and c.access = 'paid')
      or exists (select 1 from resources r join resource_links k on k.resource_id = r.id
                 left join lessons l on l.id = k.lesson_id
                 join courses c on c.id = coalesce(k.course_id, l.course_id)
                 where r.media_asset_id = p_asset_id and c.access = 'paid')
      or exists (select 1 from resources r join portion_resources pr on pr.resource_id = r.id
                 join teaching_portions tp on tp.id = pr.portion_id
                 join courses c on c.id = tp.course_id
                 where r.media_asset_id = p_asset_id and c.access = 'paid')
$$;

-- A Cloudinary download link valid for p_seconds (signed request).
create or replace function app_private.expiring_media_url(p_asset media_assets, p_seconds int default 7200)
returns text
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_cloud text := app_private.setting('cloudinary_cloud_name');
  v_key text := app_private.setting('cloudinary_api_key');
  v_secret text := app_private.setting('cloudinary_api_secret');
  v_ts bigint := extract(epoch from now())::bigint;
  v_exp bigint := v_ts + greatest(p_seconds, 60);
  v_params text;
begin
  if v_cloud is null or v_key is null or v_secret is null then return null; end if;
  -- Signed: the parameters sorted by name, then the secret (Cloudinary API).
  v_params := 'expires_at=' || v_exp
           || coalesce('&format=' || nullif(p_asset.format, ''), '')
           || '&public_id=' || p_asset.public_id
           || '&timestamp=' || v_ts
           || '&type=' || p_asset.delivery;
  return format('https://api.cloudinary.com/v1_1/%s/%s/download?%s&signature=%s&api_key=%s',
    v_cloud, p_asset.resource_type,
    replace(replace(v_params, '/', '%2F'), ' ', '%20'),
    encode(digest(v_params || v_secret, 'sha1'), 'hex'), v_key);
end;
$$;

do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.media_url(uuid, text)'::regprocedure);
  if position('  v_source := v_m.public_id || coalesce(''.'' || v_m.format, '''');' in v_src) = 0 then
    raise exception 'media_url changed; update 0049';
  end if;
  execute replace(v_src, '  v_source := v_m.public_id || coalesce(''.'' || v_m.format, '''');',
    '  -- (0049) Files are links that expire, except thumbnails of free things.
  if v_m.delivery = ''authenticated''
     and (p_transformation is null or app_private.is_paid_content(p_asset_id)) then
    v_source := app_private.expiring_media_url(v_m);
    if v_source is not null then return v_source; end if;
  end if;
  v_source := v_m.public_id || coalesce(''.'' || v_m.format, '''');');
end $$;

select app_private.lock_down_functions();
