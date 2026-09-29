-- Control centre (0039): settings history, payment test safety, health.

-- The app login cannot even enter payments_api (where money is settled).
select pg_temp.check(not has_schema_privilege('sidra_app', 'payments_api', 'usage')
                     and not has_schema_privilege('authenticated', 'payments_api', 'usage'),
  'the app login has no access to payments_api at all');

-- A founder (super admin) fixture.
select set_config('cc.su', app_private.create_account('Founder CC', null, null, 'cc_founder',
  'admin', true, 'founder-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('cc.su')::uuid, 'super_admin')
on conflict do nothing;
update org_settings set value = 'true' where key = 'marzpay_tests_enabled';
update org_settings set value = '1000' where key = 'marzpay_test_max_amount';
update org_settings set value = 'false' where key = 'marzpay_disbursement_tests_enabled';

-- ------------------------------------------------ settings: who and why --
select pg_temp.login_as('admin_1');
set local role authenticated;
select public.set_org_setting_reason('upload_max_mb', '50', 'Phones on slow data');
select pg_temp.check((select j->>'to' = '"50"' or j->>'to' = '50' from public.settings_history('upload_max_mb') j limit 1),
  'history names the setting and its new value');
select pg_temp.check((select j->>'reason' = 'Phones on slow data' and j->>'actor_name' = 'Admin'
                      from public.settings_history('upload_max_mb') j limit 1),
  'history records who and why');
select pg_temp.check(exists (select 1 from public.settings_last_changes() j where j->>'key' = 'upload_max_mb'),
  'last change per setting');
select pg_temp.expect_error($q$select public.set_org_setting('upload_max_mb', '9000')$q$, 'between 1 and 500');
select pg_temp.expect_error($q$select public.set_org_setting('marzpay_test_max_amount', '5')$q$, 'between 500');
-- An admin without payments.test cannot start payment tests.
select pg_temp.expect_error($q$select public.request_payment_test('connection')$q$, 'not allowed');
select pg_temp.check(public.system_health() ? 'database', 'admins can see system health');
reset role;

select pg_temp.login_as('learner_a');
set local role authenticated;
select pg_temp.expect_error($q$select public.system_health()$q$, 'not allowed');
select pg_temp.expect_error($q$select public.settings_history()$q$, 'not allowed');
select pg_temp.expect_error($q$select public.payment_trace('Aisha')$q$, 'not allowed');
select pg_temp.check(not exists (select 1 from payment_tests), 'learners see no payment tests');
reset role;

-- -------------------------------------------------- payment test safety --
select pg_temp.login_as_id(current_setting('cc.su')::uuid);
set local role authenticated;
select pg_temp.check(public.request_payment_test('connection') is not null, 'a connection test is queued');
-- Money tests: wrong confirmation, too much, disbursement switched off.
select pg_temp.expect_error($q$select public.request_payment_test('collection',
  '{"phone": "0772123456", "amount": 500}', 'yes')$q$, 'type the confirmation exactly');
select pg_temp.expect_error($q$select public.request_payment_test('collection',
  '{"phone": "0772123456", "amount": 5000}', '5000 UGX +256772123456')$q$, 'between 500 and 1000');
select pg_temp.expect_error($q$select public.request_payment_test('disbursement',
  '{"phone": "0772123456", "amount": 500}', '500 UGX +256772123456')$q$, 'sending-money tests are off');
select set_config('cc.t', public.request_payment_test('collection',
  '{"phone": "0772 123 456", "amount": 500}', '500 UGX +256772123456')::text, true);
select pg_temp.check((select params->>'phone' = '+2567••••456' and real_money and reference is not null
                      from payment_tests where id = current_setting('cc.t')::uuid),
  'the stored test shows only a masked phone');
reset role;
select pg_temp.check((select phone = '+256772123456' from app_private.payment_test_targets
                      where test_id = current_setting('cc.t')::uuid), 'the full number is kept privately');

-- The server claims tests in order, gets the phone once, and finishes them.
select pg_temp.check((payments_api.claim_test())->>'kind' = 'connection', 'oldest test first');
select pg_temp.check((payments_api.claim_test())->>'target_phone' = '+256772123456',
  'the server gets the number for the money test');
select payments_api.test_step(current_setting('cc.t')::uuid, '{"step": 1, "label": "created", "state": "done"}');
select payments_api.finish_test(current_setting('cc.t')::uuid, 'cancelled', 'uuid-x', 'cancelled',
  null, 'The payer cancelled the prompt.');
select pg_temp.check((select result = 'cancelled' and jsonb_array_length(steps) = 1
                      and not exists (select 1 from app_private.payment_test_targets
                                      where test_id = current_setting('cc.t')::uuid)
                      from payment_tests where id = current_setting('cc.t')::uuid),
  'finished: result, steps, and the number is deleted');

-- Emergency stop: no new tests, and the server claims nothing.
update org_settings set value = 'false' where key = 'marzpay_tests_enabled';
select pg_temp.check(payments_api.claim_test() is null, 'switched off: the server claims nothing');
select pg_temp.login_as_id(current_setting('cc.su')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.request_payment_test('balance')$q$, 'switched off');
reset role;
update org_settings set value = 'true' where key = 'marzpay_tests_enabled';

-- A test abandoned mid-way becomes UNKNOWN, never re-sent.
insert into payment_tests (kind, status, started_at) values ('collection', 'running', now() - interval '20 minutes');
select payments_api.claim_test();
select pg_temp.check(not exists (select 1 from payment_tests where status = 'running'
                                 and started_at < now() - interval '15 minutes'),
  'stale running tests end as unknown');
select pg_temp.check(exists (select 1 from payment_tests where result = 'unknown'), 'marked unknown');

-- Webhooks: duplicates are flagged.
select payments_api.log_webhook('wh-1', 'collection.completed', true, 'verified');
select payments_api.log_webhook('wh-1', 'collection.completed', true, 'verified');
select pg_temp.check((select count(*) filter (where duplicate) = 1 from payment_webhooks where provider_uuid = 'wh-1'),
  'a repeated webhook is flagged as duplicate');
