-- Devices, sessions, revocation, presence and sign-in protection (0035).
-- Acts as the app login (sidra_app), like a real phone would.

grant sidra_app to current_user;
delete from app_private.connection_identity where backend_pid = pg_backend_pid();
create temp table t_ss (name text primary key, v jsonb);
grant all on t_ss to sidra_app, authenticated;

-- ------------------------------------------- two phones, one learner --
set local role sidra_app;
insert into t_ss values ('a', auth_api.app_register('+256 766 111 222', 'device-pass-1', 'Device Learner',
  '{"install_id": "install-aaaa-1111", "manufacturer": "Tecno", "model": "Spark 10", "os": "android",
    "os_version": "13", "sdk_int": "33", "app_version": "2.28.0", "app_build": "47",
    "notifications_allowed": "true", "locale": "en_UG", "time_zone": "Africa/Kampala"}'));
insert into t_ss values ('b', auth_api.app_login('+256766111222', 'device-pass-1',
  '{"install_id": "install-bbbb-2222", "manufacturer": "Samsung", "model": "Galaxy A14"}'));
insert into t_ss select 'uid', to_jsonb(v->'user'->>'id') from t_ss where name = 'a';
select pg_temp.check((select v->>'device_id' is not null from t_ss where name = 'a'),
  'sign-up records the phone');
select pg_temp.check((select v->>'device_id' from t_ss where name = 'a')
                     <> (select v->>'device_id' from t_ss where name = 'b'),
  'two phones are two devices');

-- Both sessions work; the transaction knows its device; the heartbeat lands.
select app_private.authenticate((select v->>'access_token' from t_ss where name = 'a'));
select public.report_device('{"install_id": "install-aaaa-1111", "network": "wifi",
                              "microphone_allowed": "false", "storage_free_mb": "812"}', true, true);
select app_private.authenticate((select v->>'access_token' from t_ss where name = 'b'));
reset role;

select pg_temp.check((select network = 'wifi' and microphone_allowed = false and storage_free_mb = 812
                             and last_active_at is not null and last_sync_at is not null
                             and model = 'Spark 10' and sdk_int = 33
                      from app_private.devices where install_id = 'install-aaaa-1111'),
  'heartbeat stores state, activity and sync separately');
select pg_temp.check((select last_active_at is null and last_contact_at is not null
                      from app_private.devices where install_id = 'install-bbbb-2222'),
  'contact without use is online, not active');

-- --------------------------------------------- learners cannot reach it --
select pg_temp.login_as('learner_a');
set local role authenticated;
select pg_temp.expect_error(
  $q$select public.user_devices((select (v #>> '{}')::uuid from t_ss where name = 'uid'))$q$, 'not allowed');
select pg_temp.expect_error(
  $q$select public.revoke_device((select (v->>'device_id')::uuid from t_ss where name = 'b'))$q$,
  'device not found');
select pg_temp.expect_error($q$select public.people_presence()$q$, 'not allowed');
select pg_temp.expect_error(
  $q$select public.end_all_sessions((select (v #>> '{}')::uuid from t_ss where name = 'uid'))$q$,
  'not allowed');
select pg_temp.expect_error($q$select * from app_private.devices$q$, 'permission denied');
reset role;

-- ------------------------------------------ admin revokes phone A only --
select pg_temp.login_as('admin_1');
set local role authenticated;
select pg_temp.check((select count(*) from public.user_devices(
                        (select (v #>> '{}')::uuid from t_ss where name = 'uid'))) = 2,
  'admin sees both phones');
select pg_temp.check(exists (select 1 from public.people_presence('Device Learner') j
                             where (j->>'online')::boolean and (j->>'signed_in_devices')::int = 2),
  'presence: online with two signed-in phones');
select public.revoke_device((select (v->>'device_id')::uuid from t_ss where name = 'a'), 'lost phone');
select pg_temp.check((select not (j->>'signed_in')::boolean and j->>'revoke_reason' = 'lost phone'
                      from public.user_devices((select (v #>> '{}')::uuid from t_ss where name = 'uid')) j
                      where j->>'id' = (select v->>'device_id' from t_ss where name = 'a')),
  'revoked phone shows as signed out, with the reason');
reset role;
delete from app_private.connection_identity where backend_pid = pg_backend_pid();

set local role sidra_app;
select pg_temp.expect_error(
  $q$select app_private.authenticate((select v->>'access_token' from t_ss where name = 'a'))$q$,
  'session expired');
select pg_temp.check((auth_api.app_refresh((select v->>'refresh_token' from t_ss where name = 'a')))->>'error'
                     = 'invalid_token', 'revoked phone cannot refresh');
select app_private.authenticate((select v->>'access_token' from t_ss where name = 'b'));
insert into t_ss values ('b2', auth_api.app_refresh((select v->>'refresh_token' from t_ss where name = 'b'),
                                                    '{"install_id": "install-bbbb-2222", "network": "mobile"}'));
select pg_temp.check((select v ? 'access_token' and v->>'device_id' = (select v->>'device_id' from t_ss where name = 'b')
                      from t_ss where name = 'b2'), 'the other phone keeps working, same device');
reset role;
select pg_temp.check(exists (select 1 from audit_log where action = 'device.revoked'),
  'revocation is in the audit log');

-- ------------------------------------------------- admin ends all --
select pg_temp.login_as('admin_1');
set local role authenticated;
select pg_temp.check(public.end_all_sessions((select (v #>> '{}')::uuid from t_ss where name = 'uid'), 'test') >= 1,
  'end all sessions');
reset role;
delete from app_private.connection_identity where backend_pid = pg_backend_pid();
set local role sidra_app;
select pg_temp.expect_error(
  $q$select app_private.authenticate((select v->>'access_token' from t_ss where name = 'b2'))$q$,
  'session expired');
select pg_temp.check((auth_api.app_refresh((select v->>'refresh_token' from t_ss where name = 'b2')))->>'error'
                     = 'invalid_token', 'no phone can refresh after end-all');
-- The owner, with the password, can sign in again on the recovered phone.
select pg_temp.check((auth_api.app_login('+256766111222', 'device-pass-1',
                       '{"install_id": "install-aaaa-1111"}')) ? 'access_token',
  'signing in again with the password works');
reset role;
select pg_temp.check((select revoked_at is null from app_private.devices where install_id = 'install-aaaa-1111'),
  'signing in again clears the revocation');

-- ------------------------------------------------ sign-in protection --
update org_settings set value = '5' where key = 'lockout_attempts';
update org_settings set value = '15' where key = 'lockout_minutes';
set local role sidra_app;
-- Unknown numbers lock exactly like real accounts (no enumeration).
select count(auth_api.app_login('+256799999991', 'wrong-pass')) from generate_series(1, 5);
select pg_temp.check((auth_api.app_login('+256799999991', 'wrong-pass'))->>'error' = 'locked',
  'unknown number gets locked like a real account');
-- Real account: 5 failures lock it, even the right password is refused.
select count(auth_api.app_login('+256766111222', 'wrong-pass')) from generate_series(1, 5);
select pg_temp.check((auth_api.app_login('+256766111222', 'device-pass-1'))->>'error' = 'locked',
  'locked after 5 failures');
reset role;
select pg_temp.check((select locked_until between now() + interval '14 minutes' and now() + interval '16 minutes'
                      from app_private.credentials c join users u on u.id = c.user_id
                      where u.phone = '+256766111222'), 'first lock lasts 15 minutes');
-- The lock runs out; five more failures lock it for twice as long.
update app_private.credentials set locked_until = now() - interval '1 second'
where user_id = (select id from users where phone = '+256766111222');
set local role sidra_app;
select count(auth_api.app_login('+256766111222', 'wrong-pass')) from generate_series(1, 5);
reset role;
select pg_temp.check((select locked_until between now() + interval '29 minutes' and now() + interval '31 minutes'
                      from app_private.credentials c join users u on u.id = c.user_id
                      where u.phone = '+256766111222'), 'second lock lasts 30 minutes');
-- A staff password reset clears the lock for the real owner.
update app_private.credentials set locked_until = null, failed_attempts = 0, lock_count = 0
where user_id = (select id from users where phone = '+256766111222');

-- Whole-system brake: too many failures in a minute → "try later".
update org_settings set value = '3' where key = 'signin_failures_per_minute';
set local role sidra_app;
select pg_temp.check((auth_api.app_login('+256766111222', 'device-pass-1'))->>'error' = 'try_later',
  'system-wide brake stops sign-in storms');
reset role;
update org_settings set value = '60' where key = 'signin_failures_per_minute';

-- Sign-up closed gives a clear answer (S6).
update org_settings set value = 'false' where key = 'allow_self_signup';
set local role sidra_app;
select pg_temp.check((auth_api.app_register('+256766333444', 'closed-pass-1', 'Late Comer'))->>'error'
                     = 'signup_closed', 'sign-up closed is an answer, not a crash');
reset role;
update org_settings set value = 'true' where key = 'allow_self_signup';

-- History exists, without passwords or raw phone numbers.
select pg_temp.check((select count(*) >= 10 from app_private.auth_events e join users u on u.id = e.user_id
                      where u.phone = '+256766111222' and e.kind = 'sign_in_failed'), 'failures recorded');
select pg_temp.check(not exists (select 1 from app_private.auth_events
                                 where detail::text like '%device-pass%' or detail::text like '%+2567%'),
  'history holds no passwords or phone numbers');
