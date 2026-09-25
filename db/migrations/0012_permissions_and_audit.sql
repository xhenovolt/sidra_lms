-- 0012 roles & permissions (data, not code) and the administrative audit log.
--
-- users.role stays the PERSONA that picks the app experience:
--   learner → learner app, teacher → teaching app, admin → admin console.
-- What a console user may DO comes from their roles' permissions:
--   has_permission('courses.publish') etc. Superadmins have every permission.

-- ---------------------------------------------------------------- model --

create table permissions (
  key text primary key check (key ~ '^[a-z_]+\.[a-z_]+$'),
  area text not null,
  description text not null
);

create table app_roles (
  key text primary key check (key ~ '^[a-z][a-z0-9_]{1,40}$'),
  name text not null,
  description text,
  persona app_role not null default 'admin',   -- which app this role uses
  is_system boolean not null default false,     -- seeded; cannot be deleted
  created_at timestamptz not null default now()
);

create table role_permissions (
  role_key text not null references app_roles (key) on delete cascade,
  permission_key text not null references permissions (key) on delete cascade,
  primary key (role_key, permission_key)
);

create table user_roles (
  user_id uuid not null references users (id) on delete cascade,
  role_key text not null references app_roles (key) on delete restrict,
  granted_by uuid references users (id) on delete set null,
  granted_at timestamptz not null default now(),
  primary key (user_id, role_key)
);
create index user_roles_role on user_roles (role_key);

insert into permissions (key, area, description) values
  ('dashboard.view', 'dashboard', 'See the admin dashboard'),
  ('courses.view', 'academic', 'See all courses, including drafts'),
  ('courses.create', 'academic', 'Create courses'),
  ('courses.edit', 'academic', 'Edit course details'),
  ('courses.publish', 'academic', 'Publish and unpublish courses'),
  ('courses.archive', 'academic', 'Archive and restore courses'),
  ('curriculum.edit', 'academic', 'Edit units, sections, lessons and content'),
  ('books.manage', 'academic', 'Create and edit books and their structures'),
  ('assessments.manage', 'academic', 'Create and edit quizzes'),
  ('content.upload', 'content', 'Upload media and manage resources'),
  ('learners.view', 'people', 'See learners and their records'),
  ('learners.create', 'people', 'Create learner accounts'),
  ('learners.edit', 'people', 'Edit, disable and reset learners'),
  ('teachers.view', 'people', 'See teachers'),
  ('teachers.create', 'people', 'Create teacher accounts'),
  ('teachers.assign', 'people', 'Assign teachers to courses, units and sections'),
  ('admins.manage', 'people', 'Create and manage administrators'),
  ('roles.manage', 'people', 'Edit roles and their permissions'),
  ('enrolments.view', 'enrolment', 'See enrolments'),
  ('enrolments.manage', 'enrolment', 'Enrol learners and change course access'),
  ('finance.view', 'finance', 'See payments, balances and reports'),
  ('finance.set_fees', 'finance', 'Set course fees'),
  ('finance.record_payment', 'finance', 'Record bank and mobile-money payments'),
  ('finance.verify_payment', 'finance', 'Verify, reject or reverse payments'),
  ('finance.manage_waiver', 'finance', 'Grant and revoke waivers'),
  ('finance.record_expense', 'finance', 'Record expenses'),
  ('reports.view', 'reports', 'See reports'),
  ('audit.view', 'audit', 'See the activity log'),
  ('settings.manage', 'settings', 'Change organisation settings'),
  ('teaching.review', 'teaching', 'Review and unlock learners in assigned courses');

insert into app_roles (key, name, description, persona, is_system) values
  ('super_admin', 'Super Admin', 'Everything, including administrators and roles', 'admin', true),
  ('admin', 'Admin', 'Runs Sidra day to day (all but administrators and roles)', 'admin', true),
  ('academic_manager', 'Academic Manager', 'Courses, curriculum, teachers and enrolments', 'admin', true),
  ('finance_officer', 'Finance Officer', 'Payments, waivers, expenses and finance reports', 'admin', true),
  ('content_manager', 'Content Manager', 'Lessons, books, media and resources', 'admin', true),
  ('teacher', 'Teacher', 'Teaches assigned courses, units or sections', 'teacher', true),
  ('learner', 'Learner', 'Studies courses they have access to', 'learner', true);

insert into role_permissions (role_key, permission_key)
select 'super_admin', key from permissions
union all
select 'admin', key from permissions where key not in ('admins.manage', 'roles.manage')
union all
select 'academic_manager', unnest(array[
  'dashboard.view', 'courses.view', 'courses.create', 'courses.edit', 'courses.publish',
  'courses.archive', 'curriculum.edit', 'books.manage', 'assessments.manage',
  'content.upload', 'learners.view', 'learners.create', 'teachers.view',
  'teachers.assign', 'enrolments.view', 'enrolments.manage', 'reports.view',
  'teaching.review'])
union all
select 'finance_officer', unnest(array[
  'dashboard.view', 'finance.view', 'finance.set_fees', 'finance.record_payment',
  'finance.verify_payment', 'finance.manage_waiver', 'finance.record_expense',
  'learners.view', 'enrolments.view', 'reports.view'])
union all
select 'content_manager', unnest(array[
  'dashboard.view', 'courses.view', 'curriculum.edit', 'books.manage',
  'assessments.manage', 'content.upload'])
union all
select 'teacher', 'teaching.review';

-- Existing staff keep what they had.
insert into user_roles (user_id, role_key)
select id, case when is_superadmin then 'super_admin' else 'admin' end
from users where role = 'admin'
union all
select id, 'teacher' from users where role = 'teacher';

-- ------------------------------------------------------------ checks --

create or replace function app_private.has_permission(p_key text)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce((
    select u.is_superadmin or exists (
      select 1 from user_roles ur
      join role_permissions rp on rp.role_key = ur.role_key
      where ur.user_id = u.id and rp.permission_key = p_key)
    from users u
    where u.id = app_private.current_user_id() and u.role in ('admin', 'teacher')
  ), false)
$$;

-- "Full administrator" (Admin or Super Admin role). Kept for the checks
-- that are genuinely admin-wide; everything else uses has_permission().
create or replace function app_private.is_admin()
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce((
    select u.is_superadmin or exists (
      select 1 from user_roles ur where ur.user_id = u.id and ur.role_key = 'admin')
    from users u
    where u.id = app_private.current_user_id() and u.role = 'admin'
  ), false)
$$;

-- Any console (staff) user.
create or replace function app_private.is_console_user()
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$ select coalesce(app_private.current_app_role() in ('admin', 'teacher'), false) $$;

-- Course staff = assigned teachers/editors, or console users whose roles
-- cover all courses (viewing drafts / editing curriculum).
create or replace function app_private.is_course_staff(
  p_course_id uuid, p_editor_only boolean default false)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select
    (case when p_editor_only then app_private.has_permission('curriculum.edit')
          else app_private.has_permission('courses.view')
               or app_private.has_permission('curriculum.edit') end)
    or exists (
      select 1 from course_staff s join users u on u.id = s.user_id
      where s.course_id = p_course_id
        and s.user_id = app_private.current_user_id()
        and u.role in ('teacher', 'admin')
        and (not p_editor_only or s.role = 'editor'))
$$;

grant execute on function app_private.has_permission(text), app_private.is_console_user()
  to authenticated, sidra_app;

-- Keep users.role (persona) in step with assigned roles.
create or replace function app_private.sync_persona()
returns trigger
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_user uuid := coalesce(new.user_id, old.user_id);
  v_persona app_role;
begin
  select case
    when bool_or(r.persona = 'admin') then 'admin'::app_role
    when bool_or(r.persona = 'teacher') then 'teacher'::app_role
    else 'learner'::app_role end
  into v_persona
  from user_roles ur join app_roles r on r.key = ur.role_key
  where ur.user_id = v_user;
  perform set_config('sidra.role_change', 'allowed', true);
  update users set
    role = coalesce(v_persona, 'learner'),
    is_superadmin = exists (select 1 from user_roles
                            where user_id = v_user and role_key = 'super_admin')
  where id = v_user and (role, is_superadmin) is distinct from (
    coalesce(v_persona, 'learner'),
    exists (select 1 from user_roles where user_id = v_user and role_key = 'super_admin'));
  return null;
end;
$$;
create trigger user_roles_sync_persona
  after insert or delete on user_roles
  for each row execute function app_private.sync_persona();

-- ---------------------------------------------- role management API --

create or replace function public.my_permissions()
returns text[]
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case
    when (select is_superadmin from users where id = app_private.current_user_id())
      then array(select key from permissions order by key)
    else array(
      select distinct rp.permission_key from user_roles ur
      join role_permissions rp on rp.role_key = ur.role_key
      join users u on u.id = ur.user_id
      where ur.user_id = app_private.current_user_id() and u.role in ('admin', 'teacher')
      order by 1)
  end
$$;

create or replace function public.admin_roles()
returns table (key text, name text, description text, persona app_role,
               is_system boolean, permissions text[], members int)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select r.key, r.name, r.description, r.persona, r.is_system,
         array(select permission_key from role_permissions p
               where p.role_key = r.key order by 1),
         (select count(*)::int from user_roles ur where ur.role_key = r.key)
  from app_roles r
  where app_private.is_console_user()
  order by r.is_system desc, r.name
$$;

create or replace function public.admin_permissions()
returns table (key text, area text, description text)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select key, area, description from permissions
  where app_private.is_console_user() order by area, key
$$;

create or replace function public.save_role(
  p_key text, p_name text, p_description text,
  p_permissions text[], p_persona app_role default 'admin')
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.has_permission('roles.manage') then
    raise exception 'only superadmins can change roles' using errcode = 'PT403';
  end if;
  if p_key = 'super_admin' then
    raise exception 'the Super Admin role always has every permission' using errcode = 'PT409';
  end if;
  insert into app_roles (key, name, description, persona)
  values (p_key, trim(p_name), nullif(trim(p_description), ''), p_persona)
  on conflict (key) do update set name = excluded.name, description = excluded.description;
  delete from role_permissions where role_key = p_key;
  insert into role_permissions (role_key, permission_key)
  select p_key, unnest(coalesce(p_permissions, '{}'));
end;
$$;

create or replace function public.delete_role(p_key text)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.has_permission('roles.manage') then
    raise exception 'only superadmins can change roles' using errcode = 'PT403';
  end if;
  if exists (select 1 from app_roles where key = p_key and is_system) then
    raise exception 'built-in roles cannot be deleted' using errcode = 'PT409';
  end if;
  if exists (select 1 from user_roles where role_key = p_key) then
    raise exception 'remove this role from everyone first' using errcode = 'PT409';
  end if;
  delete from app_roles where key = p_key;
end;
$$;

-- Gives someone exactly one role (their job in Sidra). Admin-level roles
-- (persona admin) need admins.manage; teacher/learner need people rights.
create or replace function public.set_user_primary_role(p_user_id uuid, p_role_key text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_new app_roles%rowtype;
  v_target users%rowtype;
begin
  select * into v_new from app_roles where key = p_role_key;
  if not found then raise exception 'unknown role' using errcode = 'PT404'; end if;
  select * into v_target from users where id = p_user_id;
  if not found then raise exception 'user not found' using errcode = 'PT404'; end if;
  if p_user_id = app_private.current_user_id() then
    raise exception 'you cannot change your own role' using errcode = 'PT409';
  end if;
  if (v_new.persona = 'admin' or v_target.role = 'admin')
     and not app_private.has_permission('admins.manage') then
    raise exception 'only a superadmin can change administrators' using errcode = 'PT403';
  end if;
  if not (app_private.has_permission('learners.edit')
          or app_private.has_permission('teachers.create')
          or app_private.has_permission('admins.manage')) then
    raise exception 'not allowed to change roles' using errcode = 'PT403';
  end if;
  delete from user_roles where user_id = p_user_id;
  if p_role_key <> 'learner' then
    insert into user_roles (user_id, role_key, granted_by)
    values (p_user_id, p_role_key, app_private.current_user_id());
  else
    -- persona back to learner (the delete trigger already synced it)
    null;
  end if;
  return auth_api._profile(p_user_id)
      || jsonb_build_object('role_key', p_role_key);
end;
$$;

-- Old API kept working: map learner/teacher/admin to roles.
create or replace function public.set_user_role(p_user_id uuid, p_role app_role)
returns jsonb
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  select public.set_user_primary_role(p_user_id, p_role::text)
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
  if p_superadmin then
    delete from user_roles where user_id = p_user_id;
    insert into user_roles (user_id, role_key, granted_by)
    values (p_user_id, 'super_admin', app_private.current_user_id());
  else
    delete from user_roles where user_id = p_user_id and role_key = 'super_admin';
    insert into user_roles (user_id, role_key, granted_by)
    values (p_user_id, 'admin', app_private.current_user_id())
    on conflict do nothing;
  end if;
end;
$$;

-- Account creation assigns the matching role row.
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

  insert into users (id, auth_subject, display_name, phone, email, username)
  values (v_id, v_id::text, trim(p_display_name), v_phone, v_email, v_username);
  insert into learner_profiles (user_id) values (v_id);
  insert into app_private.credentials (user_id, password_hash, must_change)
  values (v_id, crypt(p_password, gen_salt('bf', 10)), p_must_change);
  if p_role <> 'learner' then
    insert into user_roles (user_id, role_key)
    values (v_id, case when p_superadmin and p_role = 'admin' then 'super_admin'
                       else p_role::text end);
  end if;
  return v_id;
end;
$$;

-- Admin user creation with an explicit role key (e.g. finance_officer).
create or replace function public.admin_create_user_with_role(
  p_display_name text, p_role_key text, p_temporary_password text,
  p_phone text default null, p_email text default null, p_username text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  v_role app_roles%rowtype;
  v_id uuid;
begin
  select * into v_role from app_roles where key = p_role_key;
  if not found then raise exception 'unknown role' using errcode = 'PT404'; end if;
  if not (
    (v_role.persona = 'admin' and app_private.has_permission('admins.manage'))
    or (v_role.persona = 'teacher' and app_private.has_permission('teachers.create'))
    or (v_role.persona = 'learner' and app_private.has_permission('learners.create'))
  ) then
    raise exception 'not allowed to create this kind of account' using errcode = 'PT403';
  end if;
  v_id := app_private.create_account(p_display_name, p_phone, p_email, p_username,
                                     'learner', false, p_temporary_password, true);
  if p_role_key <> 'learner' then
    insert into user_roles (user_id, role_key, granted_by)
    values (v_id, p_role_key, app_private.current_user_id());
  end if;
  return auth_api._profile(v_id) || jsonb_build_object('role_key', p_role_key);
end;
$$;

create or replace function public.admin_create_user(
  p_display_name text, p_role app_role, p_temporary_password text,
  p_phone text default null, p_email text default null,
  p_username text default null, p_superadmin boolean default false)
returns jsonb
language sql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
  select public.admin_create_user_with_role(
    p_display_name,
    case when p_superadmin and p_role = 'admin' then 'super_admin' else p_role::text end,
    p_temporary_password, p_phone, p_email, p_username)
$$;

-- Who may manage an account: learners need learners.edit, teachers need
-- teachers.create, administrators need admins.manage.
create or replace function app_private.can_manage_user(p_user uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (
    select 1 from users u where u.id = p_user and case u.role
      when 'admin' then app_private.has_permission('admins.manage')
      when 'teacher' then app_private.has_permission('teachers.create')
      else app_private.has_permission('learners.edit') end)
$$;

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
  where (app_private.has_permission('learners.view')
         or app_private.has_permission('teachers.view'))
    and (u.role <> 'learner' or app_private.has_permission('learners.view'))
    and (p_search is null or p_search = ''
         or u.display_name ilike '%' || p_search || '%'
         or u.phone ilike '%' || p_search || '%'
         or u.email ilike '%' || p_search || '%'
         or u.username ilike '%' || p_search || '%')
  order by u.role desc, u.display_name nulls last
  limit 500
$$;

-- -------------------------------------- permission-based policies --

drop policy courses_insert on courses;
create policy courses_insert on courses for insert to public
  with check (app_private.has_permission('courses.create'));
drop policy courses_delete on courses;
create policy courses_delete on courses for delete to public
  using (app_private.is_superadmin());   -- archive instead (see 0013)

drop policy books_write on books;
create policy books_write on books for all to public
  using (app_private.has_permission('books.manage'))
  with check (app_private.has_permission('books.manage'));
drop policy book_structures_write on book_structures;
create policy book_structures_write on book_structures for all to public
  using (app_private.has_permission('books.manage'))
  with check (app_private.has_permission('books.manage'));
drop policy book_levels_write on book_structure_levels;
create policy book_levels_write on book_structure_levels for all to public
  using (app_private.has_permission('books.manage'))
  with check (app_private.has_permission('books.manage'));
drop policy books_read on books;
create policy books_read on books for select to public
  using (status = 'published' or app_private.is_console_user());

drop policy course_staff_admin on course_staff;
create policy course_staff_admin on course_staff for all to public
  using (app_private.has_permission('teachers.assign'))
  with check (app_private.has_permission('teachers.assign'));

drop policy media_admin on media_assets;
create policy media_admin on media_assets for update to public
  using (app_private.has_permission('content.upload'))
  with check (app_private.has_permission('content.upload'));
drop policy media_admin_delete on media_assets;
create policy media_admin_delete on media_assets for delete to public
  using (app_private.has_permission('content.upload'));

drop policy users_read on users;
create policy users_read on users for select to public using (
  id = app_private.current_user_id()
  or app_private.has_permission('learners.view')
  or app_private.has_permission('teachers.view')
  or exists (select 1 from course_enrolments e
             where e.user_id = users.id and app_private.is_course_staff(e.course_id))
  or exists (select 1 from course_staff s where s.user_id = users.id)
);

create or replace function public.grant_enrolment(
  p_user_id uuid, p_course_id uuid, p_teacher_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_enrolment course_enrolments%rowtype;
begin
  if not app_private.has_permission('enrolments.manage') then
    raise exception 'not allowed to enrol learners' using errcode = 'PT403';
  end if;
  insert into course_enrolments (course_id, user_id, status, source, teacher_id, granted_by)
  values (p_course_id, p_user_id, 'active', 'admin_grant', p_teacher_id, app_private.current_user_id())
  on conflict (course_id, user_id) do update set
    status = 'active',
    teacher_id = coalesce(excluded.teacher_id, course_enrolments.teacher_id),
    granted_by = excluded.granted_by
  returning * into v_enrolment;
  return to_jsonb(v_enrolment);
end;
$$;

create or replace function public.set_course_status(p_course_id uuid, p_status publish_status)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_course courses%rowtype;
begin
  if not (
    (p_status = 'archived' and app_private.has_permission('courses.archive'))
    or (p_status <> 'archived' and (
          app_private.has_permission('courses.publish')
          -- an editor ASSIGNED to this course (not merely curriculum.edit)
          or exists (select 1 from course_staff s
                     where s.course_id = p_course_id and s.role = 'editor'
                       and s.user_id = app_private.current_user_id())))
  ) then
    raise exception 'not allowed to change this course''s status' using errcode = 'PT403';
  end if;
  update courses set
    status = p_status,
    content_version = content_version + 1,
    published_at = case when p_status = 'published' then coalesce(published_at, now()) else published_at end
  where id = p_course_id returning * into v_course;
  return to_jsonb(v_course);
end;
$$;

create or replace function public.admin_overview()
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case when not app_private.has_permission('dashboard.view') then null else jsonb_build_object(
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

-- --------------------------------------------------------- audit log --

create table audit_log (
  id bigint generated always as identity primary key,
  at timestamptz not null default now(),
  actor_id uuid references users (id) on delete set null,
  action text not null,              -- e.g. courses.update, user_roles.insert
  entity text not null,              -- table name
  entity_id text,
  changes jsonb not null default '{}',
  note text
);
create index audit_log_at on audit_log (at desc);
create index audit_log_entity on audit_log (entity, entity_id);
create index audit_log_actor on audit_log (actor_id, at desc);
alter table audit_log enable row level security;
create policy audit_read on audit_log for select to public
  using (app_private.has_permission('audit.view'));
grant select on audit_log to authenticated, sidra_app;

-- Generic trigger: records who changed what. For updates only the changed
-- columns are stored. Sensitive columns are never recorded.
create or replace function app_private.audit()
returns trigger
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_old jsonb := case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end;
  v_new jsonb := case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end;
  v_changes jsonb := '{}';
  v_key text;
  v_id text;
begin
  if tg_op = 'UPDATE' then
    for v_key in select jsonb_object_keys(v_new) loop
      if v_key not in ('updated_at', 'content_version')
         and v_new->v_key is distinct from v_old->v_key then
        v_changes := v_changes || jsonb_build_object(
          v_key, jsonb_build_object('from', v_old->v_key, 'to', v_new->v_key));
      end if;
    end loop;
    if v_changes = '{}' then return null; end if;
  else
    v_changes := coalesce(v_new, v_old);
  end if;
  v_changes := v_changes - array['password_hash', 'token_hash', 'auth_subject'];
  v_id := coalesce(v_new->>'id', v_old->>'id',
                   v_new->>'user_id', v_old->>'user_id');
  insert into audit_log (actor_id, action, entity, entity_id, changes)
  values (app_private.current_user_id(), tg_table_name || '.' || lower(tg_op),
          tg_table_name, v_id, v_changes);
  return null;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array[
    'courses', 'course_units', 'books', 'course_enrolments', 'course_staff',
    'user_roles', 'role_permissions', 'app_roles', 'lesson_unlocks', 'lesson_reviews'
  ] loop
    execute format(
      'create trigger %I after insert or update or delete on %I
         for each row execute function app_private.audit()', t || '_audit', t);
  end loop;
end $$;
create trigger users_audit after update of role, is_active, is_superadmin,
  display_name, phone, email, username on users
  for each row execute function app_private.audit();

create or replace function public.admin_audit_log(
  p_entity text default null, p_actor uuid default null,
  p_before bigint default null, p_limit int default 50)
returns table (id bigint, at timestamptz, actor_id uuid, actor_name text,
               action text, entity text, entity_id text, changes jsonb, note text)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select a.id, a.at, a.actor_id, u.display_name, a.action, a.entity,
         a.entity_id, a.changes, a.note
  from audit_log a left join users u on u.id = a.actor_id
  where app_private.has_permission('audit.view')
    and (p_entity is null or a.entity = p_entity)
    and (p_actor is null or a.actor_id = p_actor)
    and (p_before is null or a.id < p_before)
  order by a.id desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
$$;

-- ------------------------------------------------------------- grants --

alter table permissions enable row level security;
alter table app_roles enable row level security;
alter table role_permissions enable row level security;
alter table user_roles enable row level security;
create policy permissions_read on permissions for select to public
  using (app_private.is_console_user());
create policy app_roles_read on app_roles for select to public
  using (app_private.is_console_user());
create policy role_permissions_read on role_permissions for select to public
  using (app_private.is_console_user());
create policy user_roles_read on user_roles for select to public
  using (user_id = app_private.current_user_id() or app_private.is_console_user());
grant select on permissions, app_roles, role_permissions, user_roles
  to authenticated, sidra_app;

revoke all on function
  public.my_permissions(), public.admin_roles(), public.admin_permissions(),
  public.save_role(text, text, text, text[], app_role), public.delete_role(text),
  public.set_user_primary_role(uuid, text),
  public.admin_create_user_with_role(text, text, text, text, text, text),
  public.admin_audit_log(text, uuid, bigint, int)
from public, anonymous;
grant execute on function
  public.my_permissions(), public.admin_roles(), public.admin_permissions(),
  public.save_role(text, text, text, text[], app_role), public.delete_role(text),
  public.set_user_primary_role(uuid, text),
  public.admin_create_user_with_role(text, text, text, text, text, text),
  public.admin_audit_log(text, uuid, bigint, int)
to authenticated, sidra_app;
