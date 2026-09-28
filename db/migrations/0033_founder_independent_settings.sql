-- Founder independence: settings that were fixed in code become settings
-- administrators change in the app (see docs/ARCHITECTURE_AUDIT.md).
--
-- Also fixes: set_org_setting only updates keys that already exist, so the
-- notification switches (notify_<kind>) could not be saved. Every setting
-- the app offers now exists with its default.

create or replace function app_private.int_setting(p_key text, p_default int)
returns int
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce((select nullif(value, '')::int from org_settings where key = p_key), p_default)
$$;

insert into org_settings (key, value, is_public) values
  -- the organisation's name in Arabic texts
  ('org_name_ar', 'المنتهى', true),
  -- notifications (0030)
  ('notify_lesson_work', 'true', false),
  ('notify_reviewed', 'true', false),
  ('notify_correction', 'true', false),
  ('notify_portion_assigned', 'true', false),
  ('notify_submission', 'true', false),
  ('notify_resubmission', 'true', false),
  -- sign-up and security (public: the sign-in screen needs them)
  ('allow_self_signup', 'true', true),
  ('min_password_length', '8', true),
  ('lockout_attempts', '5', false),
  ('lockout_minutes', '15', false),
  -- teaching
  ('attention_stale_days', '2', false),
  ('falling_behind_portions', '3', false),
  ('default_progression', 'teacher_gated', false),
  ('default_pass_mark', '70', false),
  -- app updates (public: every phone checks them)
  ('latest_app_build', null, true),
  ('latest_app_version', null, true),
  ('app_download_url', null, true),
  ('min_supported_build', null, true)
on conflict (key) do nothing;
update org_settings set is_public = true where key in ('org_name', 'support_phone', 'support_email');

-- Values are checked, so a typo cannot lock everybody out.
create or replace function public.set_org_setting(p_key text, p_value text)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v text := nullif(trim(p_value), '');
begin
  if not app_private.has_permission('settings.manage') then
    raise exception 'not allowed to change settings' using errcode = 'PT403';
  end if;
  if p_key = 'currency' and coalesce(v, '') !~ '^[A-Z]{3}$' then
    raise exception 'currency must be a 3-letter code like UGX' using errcode = 'PT422';
  end if;
  if (p_key like 'notify\_%' or p_key in ('allow_self_signup', 'marzpay_enabled'))
     and coalesce(v, '') not in ('true', 'false') then
    raise exception '% must be on or off', p_key using errcode = 'PT422';
  end if;
  if p_key = 'min_password_length' and (v !~ '^\d+$' or v::int not between 6 and 64) then
    raise exception 'minimum password length must be between 6 and 64' using errcode = 'PT422';
  end if;
  if p_key = 'lockout_attempts' and (v !~ '^\d+$' or v::int not between 3 and 20) then
    raise exception 'failed sign-ins before lock-out must be between 3 and 20' using errcode = 'PT422';
  end if;
  if p_key = 'lockout_minutes' and (v !~ '^\d+$' or v::int not between 1 and 1440) then
    raise exception 'lock-out must last between 1 and 1440 minutes' using errcode = 'PT422';
  end if;
  if p_key in ('attention_stale_days', 'falling_behind_portions')
     and (v !~ '^\d+$' or v::int not between 1 and 60) then
    raise exception '% must be between 1 and 60', p_key using errcode = 'PT422';
  end if;
  if p_key = 'default_pass_mark' and (v !~ '^\d+$' or v::int not between 0 and 100) then
    raise exception 'pass mark must be between 0 and 100' using errcode = 'PT422';
  end if;
  if p_key = 'default_progression' and v not in (
       'open', 'sequential', 'after_submission', 'after_approval', 'teacher_gated') then
    raise exception 'unknown lesson rule' using errcode = 'PT422';
  end if;
  if p_key in ('latest_app_build', 'min_supported_build') and v is not null and v !~ '^\d+$' then
    raise exception 'build numbers are whole numbers' using errcode = 'PT422';
  end if;
  if p_key = 'app_download_url' and v is not null and v !~* '^https://[^\s]+$' then
    raise exception 'the download link must start with https://' using errcode = 'PT422';
  end if;
  update org_settings set value = v, updated_by = app_private.current_user_id(), updated_at = now()
  where key = p_key;
  if not found then
    raise exception 'unknown setting %', p_key using errcode = 'PT404';
  end if;
end;
$$;

-- What the app may know before anyone signs in (name, contacts, sign-up,
-- updates). Never secrets.
create or replace function public.public_settings()
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce(jsonb_object_agg(key, value), '{}') from org_settings where is_public
$$;
revoke all on function public.public_settings() from public;
grant execute on function public.public_settings() to anonymous, authenticated, sidra_app;

-- Sign-up can be closed; password length follows the setting.
create or replace function auth_api._check_password(p text)
returns void
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if p is null or length(p) < least(greatest(app_private.int_setting('min_password_length', 8), 6), 64)
     or length(p) > 128 then
    raise exception 'weak_password' using errcode = 'SA400';
  end if;
end;
$$;

do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('auth_api.register(text, text, text)'::regprocedure);
  if position('  select * into v_id from auth_api.normalize_identifier(p_identifier);' in v_src) = 0 then
    raise exception 'register changed; update 0033';
  end if;
  execute replace(v_src, '  select * into v_id from auth_api.normalize_identifier(p_identifier);',
    '  if coalesce((select value from org_settings where key = ''allow_self_signup''), ''true'') = ''false'' then
    raise exception ''signup_closed'' using errcode = ''SA403'';
  end if;
  select * into v_id from auth_api.normalize_identifier(p_identifier);');

  -- Lock-out follows the settings.
  v_src := pg_get_functiondef('auth_api.login(text, text)'::regprocedure);
  if position('failed_attempts + 1 >= 5' in v_src) = 0
     or position('interval ''15 minutes''' in v_src) = 0 then
    raise exception 'login changed; update 0033';
  end if;
  v_src := replace(v_src, 'failed_attempts + 1 >= 5',
    'failed_attempts + 1 >= app_private.int_setting(''lockout_attempts'', 5)');
  execute replace(v_src, 'interval ''15 minutes''',
    'make_interval(mins => app_private.int_setting(''lockout_minutes'', 15))');

  -- Teacher alerts follow the settings.
  v_src := pg_get_functiondef('public.teacher_attention(int)'::regprocedure);
  if position('make_interval(days => p_stale_days)' in v_src) = 0
     or position('having count(*) >= 3' in v_src) = 0 then
    raise exception 'teacher_attention changed; update 0033';
  end if;
  v_src := replace(v_src, 'make_interval(days => p_stale_days)',
    'make_interval(days => coalesce(p_stale_days, app_private.int_setting(''attention_stale_days'', 2)))');
  v_src := replace(v_src, 'p_stale_days int default 2', 'p_stale_days int default null');
  execute replace(v_src, 'having count(*) >= 3',
    'having count(*) >= app_private.int_setting(''falling_behind_portions'', 3)');
end $$;

-- ------------------------------------------------------------- export --
-- The institution's data, as rows for CSV files.
create or replace function public.admin_export(p_kind text)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if p_kind = 'learners' and app_private.has_permission('learners.view') then
    return query
      select jsonb_build_object('name', u.display_name, 'phone', u.phone, 'email', u.email,
        'username', u.username, 'active', u.is_active, 'joined', u.created_at::date,
        'courses', (select count(*) from course_enrolments e where e.user_id = u.id))
      from users u where u.role = 'learner' and u.removed_at is null
      order by u.display_name;
  elsif p_kind = 'enrolments' and app_private.has_permission('learners.view') then
    return query
      select jsonb_build_object('learner', u.display_name, 'course', c.title, 'status', e.status,
        'source', e.source, 'enrolled', e.enrolled_at::date, 'completed', e.completed_at::date,
        'lessons_done', (select count(*) from learner_progress p where p.user_id = e.user_id
                          and p.course_id = e.course_id and p.status = 'completed'),
        'lessons_total', (select count(*) from lessons l where l.course_id = c.id
                           and l.status = 'published'))
      from course_enrolments e join users u on u.id = e.user_id join courses c on c.id = e.course_id
      where u.removed_at is null
      order by c.title, u.display_name;
  elsif p_kind = 'payments' and app_private.has_permission('finance.view') then
    return query
      select jsonb_build_object('date', p.created_at::date, 'learner', u.display_name,
        'course', c.title, 'amount', p.amount, 'currency', p.currency, 'method', p.method,
        'status', p.status, 'reference', coalesce(p.external_reference, p.provider_uuid))
      from payments p join users u on u.id = p.user_id left join courses c on c.id = p.course_id
      order by p.created_at desc;
  elsif p_kind = 'progress' and app_private.has_permission('learners.view') then
    return query
      select jsonb_build_object('learner', u.display_name, 'course', c.title, 'lesson', l.title,
        'status', p.status, 'completed', p.completed_at::date,
        'last_opened', p.last_accessed_at::date)
      from learner_progress p join users u on u.id = p.user_id
      join lessons l on l.id = p.lesson_id join courses c on c.id = p.course_id
      where u.removed_at is null
      order by c.title, u.display_name, l.position;
  else
    raise exception 'not allowed to export %', p_kind using errcode = 'PT403';
  end if;
end;
$$;
revoke all on function public.admin_export(text) from public;
grant execute on function public.admin_export(text) to authenticated, sidra_app;
grant execute on function app_private.int_setting(text, int) to authenticated, sidra_app, anonymous;
