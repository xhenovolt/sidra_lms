-- The app's own Postgres login (sidra_app) ships in the APK, so assume an
-- attacker has it. These tests act AS sidra_app and check it can do no more
-- than a signed-in learner, and nothing at all without a session token.

grant sidra_app to current_user;
-- Suites share one transaction; start this one with no bound identity
-- (in the app every request is its own transaction).
delete from app_private.connection_identity where backend_pid = pg_backend_pid();

create temp table t_s (name text primary key, v jsonb);
grant all on t_s to sidra_app, authenticated;

set local role sidra_app;

-- ----------------------------------------------- sign-in functions --
insert into t_s values ('reg', auth_api.app_register('+256 766 000 777', 'app-pass-123', 'Direct Learner'));
select pg_temp.check((select v->'user'->>'phone' = '+256766000777' from t_s where name = 'reg'),
  'register returns a session with the user');
select pg_temp.check((select length(v->>'access_token') = 64 and length(v->>'refresh_token') = 64
                      from t_s where name = 'reg'), 'opaque access + refresh tokens');
select pg_temp.check((auth_api.app_register('+256766000777', 'app-pass-123', 'Dup'))->>'error'
  = 'identifier_taken', 'duplicate registration returns an error, not an exception');
select pg_temp.check((auth_api.app_login('+256766000777', 'wrong-pass'))->>'error'
  = 'invalid_credentials', 'wrong password');
insert into t_s values ('login', auth_api.app_login('+256766000777', 'app-pass-123'));

-- ----------------------------------------- no session = anonymous --
select pg_temp.check(app_private.jwt_sub() is null, 'no identity before authenticate()');
select pg_temp.expect_error('select public.ensure_profile()', 'not signed in');
select pg_temp.expect_error('select public.enrol_in_course(''00000000-0000-0000-0000-000000000c01'')',
  'not signed in');
select pg_temp.check(exists (select 1 from courses where slug = 'quran-intermediate'),
  'published catalogue is readable without signing in');
select pg_temp.check(not exists (select 1 from lesson_content_blocks),
  'no lesson content without a session');

-- Impersonation attempts.
select set_config('request.jwt.claims', '{"sub":"admin_1"}', true);
select pg_temp.check(app_private.jwt_sub() is null, 'forged JWT claims are ignored');
select pg_temp.check(not app_private.is_admin(), 'forged claims do not grant admin');
select pg_temp.expect_error('insert into app_private.connection_identity values (pg_backend_pid(), pg_current_xact_id(), ''00000000-0000-0000-0000-00000000000a'')',
  'permission denied');
select pg_temp.expect_error('select auth_api.issue_refresh(''00000000-0000-0000-0000-00000000000a'')',
  'permission denied');
select pg_temp.expect_error('select auth_api._issue_access(''00000000-0000-0000-0000-00000000000a'')',
  'permission denied');
select pg_temp.expect_error('select auth_api.change_password(''00000000-0000-0000-0000-00000000000a'', ''x'', ''yyyyyyyy'')',
  'permission denied');
select pg_temp.expect_error('select count(*) from app_private.access_tokens', 'permission denied');
select pg_temp.expect_error('select count(*) from app_private.credentials', 'permission denied');
select pg_temp.expect_error('select phone from users', 'permission denied');
select pg_temp.expect_error('select app_private.authenticate(''not-a-real-token'')', 'session expired');
select pg_temp.expect_error('select app_private.setting(''cloudinary_api_secret'')', 'permission denied');

-- --------------------------------------------- with a session token --
select app_private.authenticate((select v->>'access_token' from t_s where name = 'login'));
select pg_temp.check(app_private.current_user_id() = (select (v->'user'->>'id')::uuid from t_s where name = 'reg'),
  'authenticate() binds the learner to this transaction');
select pg_temp.check((public.ensure_profile())->>'display_name' = 'Direct Learner', 'profile works');
select public.enrol_in_course('00000000-0000-0000-0000-000000000c01');
select pg_temp.check((select count(*) from lesson_content_blocks
                      where lesson_id = '00000000-0000-0000-0000-000000001001') = 2,
  'learner reads their unlocked lesson');
select pg_temp.check(not exists (select 1 from lesson_content_blocks
                                 where lesson_id = '00000000-0000-0000-0000-000000001002'),
  'locked lesson stays locked');
select pg_temp.check(not exists (select 1 from learner_progress
                                 where user_id = '00000000-0000-0000-0000-0000000000a1'),
  'other learners progress stays private');
select pg_temp.expect_error($q$select public.set_user_role('00000000-0000-0000-0000-00000000000a', 'learner')$q$,
  'administrators only');
select pg_temp.check(not exists (select 1 from public.admin_list_users()),
  'learners cannot list people');

-- ------------------------------------ refresh, change password, logout --
insert into t_s values ('refresh', auth_api.app_refresh((select v->>'refresh_token' from t_s where name = 'login')));
select pg_temp.check((select v ? 'access_token' from t_s where name = 'refresh'), 'refresh gives a new session');
select pg_temp.check((auth_api.app_refresh((select v->>'refresh_token' from t_s where name = 'login')))->>'error'
  = 'invalid_token', 'old refresh token cannot be reused');
insert into t_s values ('changed', auth_api.app_change_password(
  (select v->>'access_token' from t_s where name = 'refresh'), 'app-pass-123', 'app-pass-456'));
select pg_temp.check((select v ? 'access_token' from t_s where name = 'changed'), 'password changed');
select pg_temp.expect_error(format('select app_private.authenticate(%L)',
  (select v->>'access_token' from t_s where name = 'refresh')), 'session expired');
select auth_api.app_logout((select v->>'refresh_token' from t_s where name = 'changed'),
                           (select v->>'access_token' from t_s where name = 'changed'));
select pg_temp.expect_error(format('select app_private.authenticate(%L)',
  (select v->>'access_token' from t_s where name = 'changed')), 'session expired');
reset role;

-- A staff reset ends existing sessions immediately.
insert into t_s values ('before_reset', auth_api.app_login('+256766000777', 'app-pass-456'));
select pg_temp.login_as('admin_1');
set local role authenticated;
select public.reset_password((select (v->'user'->>'id')::uuid from t_s where name = 'reg'), 'temp-pass-77');
reset role;
set local role sidra_app;
select pg_temp.expect_error(format('select app_private.authenticate(%L)',
  (select v->>'access_token' from t_s where name = 'before_reset')), 'session expired');
reset role;

select 'ALL DIRECT APP TESTS PASSED' as result;
