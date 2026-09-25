-- Roles & permissions (0012): each built-in role can do its job and no more.
-- Runs after the other suites in the same rolled-back transaction.

create function pg_temp.staff(p_name text, p_role text) returns uuid
language plpgsql as $$
declare v uuid;
begin
  v := app_private.create_account(p_name, null, null, lower(replace(p_name, ' ', '_')),
                                  'learner', false, 'staff-pass-1', false);
  insert into user_roles (user_id, role_key) values (v, p_role);
  return v;
end $$;

select set_config('t.academic', pg_temp.staff('Academic Manager Test', 'academic_manager')::text, true);
select set_config('t.finance', pg_temp.staff('Finance Officer Test', 'finance_officer')::text, true);
select set_config('t.content', pg_temp.staff('Content Manager Test', 'content_manager')::text, true);

select pg_temp.check((select role from users where id = current_setting('t.finance')::uuid) = 'admin',
  'admin-persona roles open the admin console');

-- ------------------------------------------------ academic manager --
select pg_temp.login_as_id(current_setting('t.academic')::uuid);
set local role authenticated;
select pg_temp.check('courses.create' = any (public.my_permissions()), 'academic manager permissions');
select pg_temp.check(not ('finance.view' = any (public.my_permissions())), 'no finance for academics');
insert into courses (id, slug, title, subject)
values ('00000000-0000-0000-0000-00000000c0a1', 'academic-course', 'Academic course', 'Quran');
select public.set_course_status('00000000-0000-0000-0000-00000000c0a1', 'published');
select public.grant_enrolment('00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-00000000c0a1');
insert into course_staff (course_id, user_id, role)
values ('00000000-0000-0000-0000-00000000c0a1', '00000000-0000-0000-0000-00000000000b', 'teacher');
select pg_temp.check(exists (select 1 from public.admin_list_users('Bilal')),
  'academic manager can list learners');
select pg_temp.expect_error($q$select public.save_role('x_role', 'X', null, '{}')$q$,
  'only superadmins can change roles');
select pg_temp.expect_error($q$select public.admin_create_user_with_role('New Admin', 'admin', 'temp-pass-1',
    p_username => 'newadmin1')$q$, 'not allowed to create this kind of account');
select pg_temp.check(not exists (select 1 from audit_log), 'no audit view without audit.view');
reset role;

-- ------------------------------------------------- finance officer --
select pg_temp.login_as_id(current_setting('t.finance')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$insert into courses (slug, title, subject)
  values ('finance-course', 'Nope', 'X')$q$, 'row-level security');
select pg_temp.expect_error($q$select public.grant_enrolment('00000000-0000-0000-0000-0000000000b1',
  '00000000-0000-0000-0000-000000000c01')$q$, 'not allowed to enrol');
select pg_temp.expect_error($q$select public.set_course_status('00000000-0000-0000-0000-00000000c0a1', 'archived')$q$,
  'not allowed to change');
select pg_temp.check((public.admin_overview()) is not null, 'finance officer sees the dashboard');
select pg_temp.check(exists (select 1 from public.admin_list_users('Bilal')),
  'finance officer can look up learners');
reset role;

-- ------------------------------------------------- content manager --
select pg_temp.login_as_id(current_setting('t.content')::uuid);
set local role authenticated;
insert into lessons (course_id, title, position, status)
values ('00000000-0000-0000-0000-00000000c0a1', 'Content lesson', 0, 'draft');
insert into books (title) values ('Content book');
select pg_temp.expect_error($q$select public.set_course_status('00000000-0000-0000-0000-00000000c0a1', 'draft')$q$,
  'not allowed to change');
select pg_temp.expect_error($q$select public.grant_enrolment('00000000-0000-0000-0000-0000000000b1',
  '00000000-0000-0000-0000-000000000c01')$q$, 'not allowed to enrol');
select pg_temp.check(not exists (select 1 from public.admin_list_users()),
  'content manager cannot see people');
reset role;

-- ---------------------------------------------------- superadmin --
select pg_temp.login_as('admin_1');
select set_config('sidra.role_change', 'allowed', true);
update users set is_superadmin = true where auth_subject = 'admin_1';
set local role authenticated;
select public.save_role('registrar', 'Registrar', 'Enrols learners',
  array['dashboard.view', 'learners.view', 'enrolments.view', 'enrolments.manage']);
select pg_temp.check((select permissions from public.admin_roles() where key = 'registrar')
  = array['dashboard.view', 'enrolments.manage', 'enrolments.view', 'learners.view'],
  'custom role saved with its permissions');
select public.set_user_primary_role(current_setting('t.content')::uuid, 'registrar');
select pg_temp.expect_error($q$select public.delete_role('registrar')$q$, 'remove this role from everyone first');
select pg_temp.expect_error($q$select public.delete_role('admin')$q$, 'built-in roles cannot be deleted');
select pg_temp.expect_error($q$select public.save_role('super_admin', 'x', null, '{}')$q$,
  'always has every permission');
-- Audit log saw the course, enrolment, staff and role changes with actors.
select pg_temp.check(exists (select 1 from public.admin_audit_log('courses')
                             where entity_id = '00000000-0000-0000-0000-00000000c0a1'
                               and action = 'courses.insert'
                               and actor_id = current_setting('t.academic')::uuid),
  'course creation audited with its actor');
select pg_temp.check(exists (select 1 from public.admin_audit_log('course_enrolments')),
  'enrolment audited');
select pg_temp.check(exists (select 1 from public.admin_audit_log('user_roles')
                             where entity_id = current_setting('t.content')),
  'role change audited');
select pg_temp.check(not exists (select 1 from audit_log
                                 where changes ? 'password_hash' or changes ? 'token_hash'),
  'no secrets in the audit log');
reset role;

-- The persona follows the role: registrar is an admin-console role.
select pg_temp.check((select role from users where id = current_setting('t.content')::uuid) = 'admin',
  'custom admin role keeps the admin console');

select 'ALL ROLES TESTS PASSED' as result;
