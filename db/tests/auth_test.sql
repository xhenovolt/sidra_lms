-- Sidra authentication (auth_api) tests. Runs after access/authoring tests
-- in the same rolled-back transaction (reuses their users and courses).

create function pg_temp.expect_result_error(p_sql text, p_code text) returns void
language plpgsql as $$
declare r jsonb;
begin
  execute p_sql into r;
  if r->>'error' is distinct from p_code then
    raise exception 'expected result error %, got %', p_code, r;
  end if;
end $$;

-- ------------------------------------------------------ registration --
select pg_temp.check((auth_api.register('+256 700 123-456', 'correct horse', 'Yusuf'))
  ->>'phone' = '+256700123456', 'phone normalised to E.164');
select pg_temp.check((auth_api.register('Zaynab@Example.COM', 'battery staple', 'Zaynab'))
  ->>'email' = 'zaynab@example.com', 'email lower-cased');
select set_config('test.yusuf', (select id::text from users where phone = '+256700123456'), true);
select pg_temp.check((select auth_subject = id::text from users where phone = '+256700123456'),
  'JWT subject is the user id');
select pg_temp.check((select role from users where phone = '+256700123456') = 'learner',
  'new accounts are learners');
select pg_temp.expect_error($q$select auth_api.register('00256700123456', 'another one', 'Dup')$q$,
  'identifier_taken');
select pg_temp.expect_error($q$select auth_api.register('ZAYNAB@example.com', 'another one', 'Dup')$q$,
  'identifier_taken');
select pg_temp.expect_error($q$select auth_api.register('+256700999999', 'short', 'X')$q$,
  'weak_password');
select pg_temp.expect_error($q$select auth_api.register('0700 123 456', 'long enough', 'X')$q$,
  'invalid_identifier');
select pg_temp.expect_error($q$select auth_api.register('+256700888888', 'long enough', '  ')$q$,
  'name_required');
select pg_temp.check((select password_hash like '$2a$10$%' from app_private.credentials c
                      join users u on u.id = c.user_id where u.phone = '+256700123456'),
  'password stored as bcrypt, never plain');

-- ------------------------------------------------------------- login --
select pg_temp.check((auth_api.login('+256700123456', 'correct horse'))->>'display_name' = 'Yusuf',
  'login with phone');
select pg_temp.check((auth_api.login('  zaynab@EXAMPLE.com ', 'battery staple'))->>'display_name' = 'Zaynab',
  'login with email, case-insensitive');
select pg_temp.expect_result_error($q$select auth_api.login('+256700123456', 'wrong')$q$, 'invalid_credentials');
select pg_temp.expect_result_error($q$select auth_api.login('+256700000000', 'whatever1')$q$, 'invalid_credentials');
select pg_temp.expect_result_error($q$select auth_api.login('not an identifier', 'whatever1')$q$, 'invalid_credentials');

-- Lockout after 5 consecutive failures (1 already above).
select pg_temp.expect_result_error($q$select auth_api.login('+256700123456', 'wrong')$q$, 'invalid_credentials');
select pg_temp.expect_result_error($q$select auth_api.login('+256700123456', 'wrong')$q$, 'invalid_credentials');
select pg_temp.expect_result_error($q$select auth_api.login('+256700123456', 'wrong')$q$, 'invalid_credentials');
select pg_temp.expect_result_error($q$select auth_api.login('+256700123456', 'wrong')$q$, 'invalid_credentials');
select pg_temp.expect_result_error($q$select auth_api.login('+256700123456', 'correct horse')$q$, 'locked');
update app_private.credentials set locked_until = now() - interval '1 second'
where user_id = current_setting('test.yusuf')::uuid;
select pg_temp.check((auth_api.login('+256700123456', 'correct horse')) is not null,
  'login works again after the lock expires');

-- ------------------------------------------------------ refresh tokens --
create temp table t_tok (name text primary key, token text);
insert into t_tok values ('r1', auth_api.issue_refresh(
  current_setting('test.yusuf')::uuid));
select pg_temp.check((select length(token) = 64 from t_tok where name = 'r1'), 'opaque 256-bit token');
select pg_temp.check(not exists (select 1 from app_private.refresh_tokens rt, t_tok t
                                 where t.name = 'r1' and rt.token_hash = t.token),
  'only token hashes are stored');
insert into t_tok select 'r2', (auth_api.rotate_refresh(token))->>'refresh_token' from t_tok where name = 'r1';
select pg_temp.check((select token from t_tok where name = 'r2') <> (select token from t_tok where name = 'r1'),
  'rotation issues a new token');
-- Replaying r1 (already rotated) is treated as theft: family revoked, r2 dies too.
select pg_temp.expect_result_error(
  format('select auth_api.rotate_refresh(%L)', (select token from t_tok where name = 'r1')),
  'invalid_token');
select pg_temp.expect_result_error(
  format('select auth_api.rotate_refresh(%L)', (select token from t_tok where name = 'r2')),
  'invalid_token');
select pg_temp.expect_result_error($q$select auth_api.rotate_refresh('deadbeef')$q$, 'invalid_token');

-- Logout revokes.
insert into t_tok values ('r3', auth_api.issue_refresh(
  current_setting('test.yusuf')::uuid));
select auth_api.revoke_refresh(token) from t_tok where name = 'r3';
select pg_temp.expect_result_error(
  format('select auth_api.rotate_refresh(%L)', (select token from t_tok where name = 'r3')),
  'invalid_token');

-- ---------------------------------------------------- change password --
insert into t_tok values ('r4', auth_api.issue_refresh(
  current_setting('test.yusuf')::uuid));
select pg_temp.expect_error(format(
  'select auth_api.change_password(%L, %L, %L)',
  current_setting('test.yusuf')::uuid, 'not the old one', 'new password 1'),
  'invalid_credentials');
select auth_api.change_password(
  current_setting('test.yusuf')::uuid, 'correct horse', 'new password 1');
select pg_temp.expect_result_error($q$select auth_api.login('+256700123456', 'correct horse')$q$, 'invalid_credentials');
select pg_temp.check((auth_api.login('+256700123456', 'new password 1')) is not null, 'new password works');
select pg_temp.expect_result_error(
  format('select auth_api.rotate_refresh(%L)', (select token from t_tok where name = 'r4')),
  'invalid_token');

-- ------------------------------------------------ staff password reset --
-- Yusuf enrols in teacher_1's course so teacher_1 may reset him.
insert into course_enrolments (course_id, user_id, source)
select '00000000-0000-0000-0000-000000000c01', id, 'self_free'
from users where phone = '+256700123456';

select pg_temp.login_as('teacher_1');
set local role authenticated;
select public.reset_password(current_setting('test.yusuf')::uuid, 'temp-pass-1');
select pg_temp.expect_error(format('select public.reset_password(%L, %L)',
  '00000000-0000-0000-0000-00000000000a', 'temp-pass-1'), 'not allowed');
select pg_temp.expect_error(format('select public.reset_password(%L, %L)',
  current_setting('test.yusuf')::uuid, 'short'), 'at least 8');
reset role;

select pg_temp.check((auth_api.login('+256700123456', 'temp-pass-1'))->>'must_change_password' = 'true',
  'temporary password forces a change');
select auth_api.change_password(
  current_setting('test.yusuf')::uuid, 'temp-pass-1', 'my own password');
select pg_temp.check((auth_api.login('+256700123456', 'my own password'))->>'must_change_password' = 'false',
  'flag cleared after change');

select set_config('test.yusuf', (select id::text from users where phone = '+256700123456'), true);
select pg_temp.login_as('learner_a');
set local role authenticated;
select pg_temp.expect_error(format('select public.reset_password(%L, %L)',
  current_setting('test.yusuf'), 'hijack-pass'), 'not allowed');
select pg_temp.expect_error(format('select public.reset_password(%L, %L)',
  gen_random_uuid(), 'hijack-pass'), 'not allowed');
-- Data API callers can't reach auth_api or the credential tables.
select pg_temp.expect_error($q$select auth_api.login('+256700123456', 'my own password')$q$,
  'permission denied');
select pg_temp.expect_error('select count(*) from app_private.credentials', 'permission denied');
reset role;

-- Signed-in via a Sidra token (sub = users.id) resolves the profile.
select pg_temp.login_as_id(current_setting('test.yusuf')::uuid);
set local role authenticated;
select pg_temp.check((public.ensure_profile())->>'display_name' = 'Yusuf',
  'Sidra JWT subject maps to the user');
reset role;

-- ------------------------------------------ auth service role confinement --
grant sidra_auth_service to current_user;
set local role sidra_auth_service;
select pg_temp.check((auth_api.login('zaynab@example.com', 'battery staple')) is not null,
  'auth service can log users in');
select pg_temp.expect_error('select count(*) from users', 'permission denied');
select pg_temp.expect_error('select count(*) from app_private.credentials', 'permission denied');
select pg_temp.expect_error(format('select public.reset_password(%L, %L)',
  gen_random_uuid(), 'temporary-1'), 'permission denied');
reset role;

select 'ALL AUTH TESTS PASSED' as result;
