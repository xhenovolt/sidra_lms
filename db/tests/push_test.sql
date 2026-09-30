-- 0046: instant notifications through Firebase.

select set_config('pu.a', app_private.create_account('Push Learner', null, null, 'pu_learner',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('pu.b', app_private.create_account('No Phone Learner', null, null, 'pu_nophone',
  'learner', false, 'learner-pass-1', false)::text, true);

-- The learner's phone registers its push address (not a phone number).
select pg_temp.login_as_id(current_setting('pu.a')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.register_push_device('short')$q$, 'invalid push address');
select public.register_push_device('fcm-token-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'android');
select public.register_push_device('fcm-token-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'android');
select pg_temp.expect_error($q$select * from push_api.claim(10)$q$, 'permission denied');
reset role;
select pg_temp.check((select count(*) from app_private.push_devices
                      where user_id = current_setting('pu.a')::uuid) = 1, 'one phone, registered once');

-- Two notifications: one for the learner with a phone, one without.
select app_private.notify(current_setting('pu.a')::uuid, 'work_reply', 'Page 12',
  'Your teacher responded to your work.', '{"portion_id": "00000000-0000-0000-0000-000000000001"}');
select app_private.notify(current_setting('pu.b')::uuid, 'work_reply', 'Page 12',
  'Your teacher responded to your work.', '{}');

-- The Worker's login claims them: only the one with a phone comes back.
set local role sidra_push;
select set_config('pu.claim', (select jsonb_agg(j)::text from push_api.claim(100) j
                               where j->>'body' = 'Your teacher responded to your work.'
                                 and j->'tokens' ? 'fcm-token-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'), true);
select pg_temp.check(jsonb_array_length(current_setting('pu.claim')::jsonb) = 1,
  'the learner with a phone gets one push, with its address');
select pg_temp.check(current_setting('pu.claim')::jsonb->0->'data'->>'portion_id'
                     = '00000000-0000-0000-0000-000000000001', 'with what to open on tap');
select pg_temp.check((select count(*) from push_api.claim(100) j
                      where j->>'body' = 'Your teacher responded to your work.') = 0,
  'claimed once: never pushed twice');
-- The Worker can do nothing else.
select pg_temp.expect_error($q$select count(*) from users$q$, 'permission denied');
select pg_temp.expect_error($q$select count(*) from notifications$q$, 'permission denied');
-- Google says the address is dead: it goes.
select pg_temp.check(push_api.drop_tokens(array['fcm-token-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa']) = 1,
  'dead push addresses are removed');
reset role;
select pg_temp.check((select count(*) from notifications where user_id in
                        (current_setting('pu.a')::uuid, current_setting('pu.b')::uuid)
                      and pushed_at is null) = 0, 'both are marked, the phone-less one too');

-- Sign-out removes the phone.
select pg_temp.login_as_id(current_setting('pu.a')::uuid);
set local role authenticated;
select public.register_push_device('fcm-token-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb');
select public.unregister_push_device('fcm-token-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb');
reset role;
select pg_temp.check(not exists (select 1 from app_private.push_devices
                                 where fcm_token = 'fcm-token-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'),
  'signed out: no more pushes to that phone');

-- A phone handed to someone else moves to their account.
select pg_temp.login_as_id(current_setting('pu.a')::uuid);
set local role authenticated;
select public.register_push_device('fcm-token-cccccccccccccccccccccccccccccccccccc');
reset role;
select pg_temp.login_as_id(current_setting('pu.b')::uuid);
set local role authenticated;
select public.register_push_device('fcm-token-cccccccccccccccccccccccccccccccccccc');
reset role;
select pg_temp.check((select user_id from app_private.push_devices
                      where fcm_token = 'fcm-token-cccccccccccccccccccccccccccccccccccc')
                     = current_setting('pu.b')::uuid, 'a phone belongs to whoever signed in last');
