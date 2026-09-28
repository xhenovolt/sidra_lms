-- Founder-independent settings (0033). Uses access_test fixtures.

-- Every setting the app offers exists (saving a switch used to fail with
-- "unknown setting").
select pg_temp.check((select count(*) from org_settings where key in (
  'notify_lesson_work', 'notify_reviewed', 'notify_correction', 'notify_portion_assigned',
  'notify_submission', 'notify_resubmission', 'allow_self_signup', 'min_password_length',
  'lockout_attempts', 'lockout_minutes', 'attention_stale_days', 'falling_behind_portions',
  'default_progression', 'default_pass_mark', 'latest_app_build', 'latest_app_version',
  'app_download_url', 'min_supported_build')) = 18, 'all settings exist');

select pg_temp.login_as('admin_1');
set local role authenticated;
select public.set_org_setting('notify_lesson_work', 'false');
select pg_temp.expect_error($q$select public.set_org_setting('notify_lesson_work', 'maybe')$q$, 'on or off');
select pg_temp.expect_error($q$select public.set_org_setting('min_password_length', '3')$q$, 'between 6 and 64');
select pg_temp.expect_error($q$select public.set_org_setting('lockout_attempts', '0')$q$, 'between 3 and 20');
select pg_temp.expect_error($q$select public.set_org_setting('default_progression', 'anything')$q$, 'unknown lesson rule');
select pg_temp.expect_error($q$select public.set_org_setting('app_download_url', 'http://x')$q$, 'https://');
select public.set_org_setting('app_download_url', 'https://example.org/sidra.apk');
select public.set_org_setting('latest_app_build', '99');
select public.set_org_setting('allow_self_signup', 'false');
select public.set_org_setting('min_password_length', '10');
select public.set_org_setting('lockout_attempts', '3');
reset role;

-- Before sign-in the app sees public settings only.
set local role sidra_app;
select pg_temp.check(public.public_settings()->>'allow_self_signup' = 'false'
                     and public.public_settings()->>'latest_app_build' = '99'
                     and public.public_settings() ? 'org_name'
                     and not (public.public_settings() ? 'lockout_attempts')
                     and not (public.public_settings() ? 'notify_lesson_work'),
  'public settings: sign-up, updates, name; nothing private');
reset role;

-- Sign-up closed.
select pg_temp.expect_error($q$select auth_api.register('+256700999888', 'long-enough-pass', 'New Person')$q$,
  'signup_closed');
update org_settings set value = 'true' where key = 'allow_self_signup';
-- Password length follows the setting (10).
select pg_temp.expect_error($q$select auth_api.register('+256700999888', 'short9pas', 'New Person')$q$,
  'weak_password');
select pg_temp.check((auth_api.register('+256700999888', 'long-enough-pass', 'New Person')->>'id') is not null,
  'sign-up open again');
-- Lock-out after 3 failures (setting), not 5.
select auth_api.login('+256700999888', 'wrong-1');
select auth_api.login('+256700999888', 'wrong-2');
select auth_api.login('+256700999888', 'wrong-3');
select pg_temp.check(auth_api.login('+256700999888', 'long-enough-pass')->>'error' = 'locked',
  'locked after the configured number of failures');

-- Export follows permissions.
select pg_temp.login_as('admin_1');
set local role authenticated;
select pg_temp.check(exists (select 1 from public.admin_export('learners')), 'admins export learners');
reset role;
select pg_temp.login_as('learner_a');
set local role authenticated;
select pg_temp.expect_error($q$select * from public.admin_export('learners')$q$, 'not allowed to export');
select pg_temp.expect_error($q$select * from public.admin_export('payments')$q$, 'not allowed to export');
reset role;

select 'ALL SETTINGS TESTS PASSED' as result;
