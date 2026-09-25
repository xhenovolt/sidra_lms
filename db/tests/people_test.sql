-- People management: superadmins, usernames, admin API (migration 0010).
-- Runs after the other suites in the same rolled-back transaction.

-- Make admin_1 the superadmin; add a plain admin (admin_2).
select set_config('sidra.role_change', 'allowed', true);
update users set is_superadmin = true where auth_subject = 'admin_1';
select app_private.create_account('Plain Admin', null, 'plain.admin@example.org', 'plainadmin',
  'admin', false, 'admin-pass-1', false);
update users set auth_subject = auth_subject where false; -- no-op
select set_config('test.admin2', (select id::text from users where username = 'plainadmin'), true);
select set_config('sidra.role_change', '', true);

-- ------------------------------------------------ usernames & login --
select pg_temp.check((auth_api.login('PlainAdmin', 'admin-pass-1'))->>'username' = 'plainadmin',
  'sign in with a username (case-insensitive)');
select pg_temp.check((auth_api.login('plain.admin@example.org', 'admin-pass-1'))->>'role' = 'admin',
  'same account by email');
select pg_temp.expect_result_error($q$select auth_api.login('no_such_user', 'admin-pass-1')$q$,
  'invalid_credentials');
select pg_temp.expect_result_error($q$select auth_api.login('x!', 'admin-pass-1')$q$,
  'invalid_credentials');

-- ------------------------------------------------ plain admin (admin_2) --
select pg_temp.login_as_id(current_setting('test.admin2')::uuid);
set local role authenticated;

select pg_temp.check((public.admin_create_user('New Learner', 'learner', 'temp-pass-1',
    p_phone => '+256 755 000 111'))->>'must_change_password' = 'true',
  'admin creates a learner with a temporary password');
select pg_temp.check((public.admin_create_user('New Teacher', 'teacher', 'temp-pass-1',
    p_username => 'Ustadh_Ali'))->>'username' = 'ustadh_ali',
  'admin creates a teacher by username');
select pg_temp.expect_error($q$select public.admin_create_user('Sneaky', 'admin', 'temp-pass-1',
    p_email => 'sneaky@example.org')$q$, 'not allowed to create this kind of account');
select pg_temp.expect_error($q$select public.admin_create_user('Dup', 'learner', 'temp-pass-1',
    p_phone => '+256755000111')$q$, 'already used');
select pg_temp.expect_error($q$select public.admin_create_user('No id', 'learner', 'temp-pass-1')$q$,
  'phone number, email or username is required');
select pg_temp.expect_error($q$select public.admin_create_user('Bad', 'learner', 'temp-pass-1',
    p_phone => 'hello')$q$, 'invalid phone');
select pg_temp.expect_error($q$select public.admin_create_user('Short', 'learner', 'short',
    p_username => 'shorty')$q$, 'at least 8');

select public.set_user_role((select id from public.admin_list_users('ustadh_ali')), 'learner');
select public.set_user_role((select id from public.admin_list_users('ustadh_ali')), 'teacher');
select pg_temp.expect_error($q$select public.set_user_role(
    (select id from public.admin_list_users('ustadh_ali')), 'admin')$q$, 'only a superadmin');
select pg_temp.expect_error($q$select public.set_user_role(
    '00000000-0000-0000-0000-00000000000a', 'learner')$q$, 'only a superadmin');
select pg_temp.expect_error($q$select public.set_user_active(
    '00000000-0000-0000-0000-00000000000a', false)$q$, 'not allowed');
select pg_temp.expect_error($q$select public.reset_password(
    '00000000-0000-0000-0000-00000000000a', 'temp-pass-9')$q$, 'not allowed');
select pg_temp.expect_error($q$select public.set_superadmin(
    (select id from public.admin_list_users('ustadh_ali')), true)$q$, 'superadmins only');
select pg_temp.check((public.admin_update_user(
    (select id from public.admin_list_users('ustadh_ali')), 'Ustadh Ali Musa',
    p_username => 'ustadh_ali', p_phone => '+256 755 000 222'))->>'phone' = '+256755000222',
  'admin edits a teacher');
select pg_temp.expect_error($q$select public.admin_update_user(
    '00000000-0000-0000-0000-00000000000a', 'Renamed', p_username => 'renamed')$q$, 'not allowed');
select pg_temp.check((public.admin_overview())->>'admins' is not null, 'admin sees the overview');
reset role;

-- ------------------------------------------------ superadmin (admin_1) --
select pg_temp.login_as('admin_1');
set local role authenticated;
select pg_temp.check((public.admin_create_user('Second Admin', 'admin', 'temp-pass-1',
    p_email => 'second.admin@example.org', p_superadmin => true))->>'is_superadmin' = 'true',
  'superadmin creates another superadmin');
select public.set_superadmin((select id from public.admin_list_users('second.admin')), false);
select public.set_user_role(current_setting('test.admin2')::uuid, 'teacher');
select pg_temp.check((select role from users where id = current_setting('test.admin2')::uuid) = 'teacher',
  'superadmin demotes an admin');
select public.set_user_role(current_setting('test.admin2')::uuid, 'admin');
select public.set_user_active(current_setting('test.admin2')::uuid, false);
reset role;
select pg_temp.expect_result_error($q$select auth_api.login('plainadmin', 'admin-pass-1')$q$, 'disabled');
select pg_temp.login_as('admin_1');
set local role authenticated;
select public.set_user_active(current_setting('test.admin2')::uuid, true);
select pg_temp.expect_error($q$select public.set_user_active('00000000-0000-0000-0000-00000000000a', false)$q$,
  'cannot disable your own');
select pg_temp.expect_error($q$select public.set_superadmin('00000000-0000-0000-0000-00000000000a', false)$q$,
  'cannot remove your own superadmin');
select pg_temp.expect_error($q$select public.set_user_role('00000000-0000-0000-0000-00000000000a', 'learner')$q$,
  'cannot change your own role');
reset role;

-- The last active superadmin can't be removed, even directly by the owner.
-- (Real superadmins exist in the database; step them down inside this
-- rolled-back transaction so admin_1 is the last one.)
select set_config('sidra.role_change', 'allowed', true);
update users set is_superadmin = false where is_superadmin and auth_subject <> 'admin_1';
select pg_temp.expect_error($q$update users set is_superadmin = false
  where auth_subject = 'admin_1'$q$, 'at least one active superadmin');
select set_config('sidra.role_change', '', true);

-- ------------------------------------------------ learners ---------------
select pg_temp.login_as('learner_a');
set local role authenticated;
select pg_temp.expect_error($q$select public.admin_create_user('X', 'learner', 'temp-pass-1',
    p_username => 'xlearner')$q$, 'not allowed to create this kind of account');
select pg_temp.check(public.admin_overview() is null, 'learners get no overview');
select pg_temp.expect_error($q$update users set username = 'hacker' where auth_subject = 'learner_a'$q$,
  'permission denied');
reset role;

select 'ALL PEOPLE TESTS PASSED' as result;
