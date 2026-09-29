-- 0040 Every setting the control centre shows is checked by the database:
-- the ones added in 0035/0037 had no limits yet.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.set_org_setting(text, text)'::regprocedure);
  if position('  update org_settings set value = v' in v_src) = 0 then
    raise exception 'set_org_setting changed; update 0040';
  end if;
  execute replace(v_src, '  update org_settings set value = v',
$r$  if p_key in ('messaging_enabled', 'messaging_learners') and coalesce(v, '') not in ('true', 'false') then
    raise exception '% must be on or off', p_key using errcode = 'PT422';
  end if;
  if p_key = 'signin_failures_per_minute' and (v !~ '^\d+$' or v::int not between 5 and 1000) then
    raise exception 'the sign-in brake must be between 5 and 1000 failures a minute' using errcode = 'PT422';
  end if;
  if p_key = 'presence_online_minutes' and (v !~ '^\d+$' or v::int not between 1 and 60) then
    raise exception 'online means seen within 1 to 60 minutes' using errcode = 'PT422';
  end if;
  if p_key = 'auth_events_keep_days' and (v !~ '^\d+$' or v::int not between 7 and 3650) then
    raise exception 'sign-in history is kept 7 to 3650 days' using errcode = 'PT422';
  end if;
  if p_key in ('org_name') and coalesce(trim(v), '') = '' then
    raise exception 'the organisation needs a name' using errcode = 'PT422';
  end if;
  update org_settings set value = v$r$);
end $$;

select app_private.lock_down_functions();
