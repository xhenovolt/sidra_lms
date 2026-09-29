-- The app login (sidra_app) ships in the APK: assume an attacker has it.
-- It must not reach internal helpers that act for someone else (0034).

grant sidra_app to current_user;
delete from app_private.connection_identity where backend_pid = pg_backend_pid();
set local role sidra_app;

select pg_temp.expect_error(
  $q$select app_private.create_account('Intruder', null, null, 'intruder', 'learner', true, 'password-123', false)$q$,
  'permission denied');
select pg_temp.expect_error(
  $q$select app_private.complete_and_unlock('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000b', 'work_approved')$q$,
  'permission denied');
select pg_temp.expect_error(
  $q$select app_private.find_user_by_identifier('+256700000001')$q$, 'permission denied');
select pg_temp.expect_error(
  $q$select app_private.checked_identifier('+256700000001', 'phone')$q$, 'permission denied');

-- The rule helpers the database itself needs still work for the app.
select pg_temp.check(app_private.current_user_id() is null, 'identity helper callable, no identity');
select pg_temp.check(not app_private.has_permission('settings.manage'), 'permission helper callable');
select pg_temp.check(exists (select 1 from courses), 'catalogue rules still evaluate');

reset role;

-- A setting's value never appears in an error.
insert into org_settings (key, value, is_public) values ('test_private_text', 'do-not-leak', false)
  on conflict (key) do update set value = excluded.value;
select pg_temp.check(app_private.int_setting('test_private_text', 7) = 7,
  'non-numeric setting gives the default instead of an error');

-- Regression guard: every SECURITY DEFINER function in app_private that the
-- app login can run is on this list. A new one must be reviewed and added.
select pg_temp.check(x = '{}', 'unreviewed internal functions callable by the app login: ' || x::text)
from (select
  coalesce((select array_agg(p.proname::text order by p.proname)
            from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'app_private' and p.prosecdef
              and has_function_privilege('sidra_app', p.oid, 'execute')
              and p.proname not in (
                'authenticate', 'jwt_sub', 'current_user_id', 'current_app_role',
                'has_permission', 'is_admin', 'is_superadmin', 'is_console_user',
                'can_author', 'can_manage_user', 'can_read_assessment', 'can_read_assignment',
                'can_read_lesson', 'can_read_media', 'can_read_resource', 'can_see_course',
                'can_view_person', 'check_languages', 'in_portion', 'is_course_staff',
                'is_enrolled', 'lesson_is_live', 'teaches', 'teaches_group',
                'teaches_portion', 'lesson_unit', 'lesson_teachers', 'lesson_needs_work',
                'int_setting', 'notification_allowed', 'valid_block', 'completed_course',
                'link_course', 'can_handle_issue', 'is_member')),
           '{}') as x) s;

-- auth_api: the app login may run exactly the five sign-in entry points.
select pg_temp.check(x = array['app_change_password', 'app_login', 'app_logout', 'app_refresh', 'app_register'],
                     'auth_api functions callable by the app login: ' || x::text)
from (select array_agg(p.proname::text order by p.proname) x
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'auth_api' and has_function_privilege('sidra_app', p.oid, 'execute')) s;
