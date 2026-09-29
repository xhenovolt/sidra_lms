-- MarzPay from the app (0041): payer reports, staff confirm or reverse.
-- (Also 0042: teacher-controlled courses need work, not a self-mark.)
select pg_temp.check(app_private.lesson_needs_work(l.id), 'teacher-controlled lessons need work')
from lessons l join courses c on c.id = l.course_id
where c.progression = 'teacher_gated' and l.work_required is null
limit 1;
update org_settings set value = 'true' where key = 'marzpay_enabled';

select set_config('md.a', app_private.create_account('Payer A', null, null, 'md_payer_a',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('md.b', app_private.create_account('Payer B', null, null, 'md_payer_b',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('md.su', app_private.create_account('Founder MD', null, null, 'md_founder',
  'admin', true, 'founder-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('md.su')::uuid, 'super_admin')
on conflict do nothing;
insert into courses (id, slug, title, subject, access, price_amount, price_currency, progression, status, language)
values ('00000000-0000-0000-0000-0000000d0001', 'md-paid', 'MD Paid Course', 'Quran', 'paid', 1000, 'UGX',
        'open', 'published', 'en');

-- ------------------------------------------ payer reports success --
select pg_temp.login_as_id(current_setting('md.a')::uuid);
set local role authenticated;
select set_config('md.p', (public.start_course_payment('00000000-0000-0000-0000-0000000d0001', '0772123456'))->>'id', true);
select set_config('md.ref', (select j->>'reference' from public.my_payments('00000000-0000-0000-0000-0000000d0001') j limit 1), true);
select pg_temp.check(current_setting('md.ref') <> '', 'the payer''s app gets the reference to send');
select public.marzpay_submitted(current_setting('md.p')::uuid, 'md-uuid-1', 'airtel', 'processing');
select pg_temp.expect_error($q$select public.marzpay_result(current_setting('md.p')::uuid, 'successful', 1000,
  'another-reference')$q$, 'belongs to another payment');
select pg_temp.check((public.marzpay_result(current_setting('md.p')::uuid, 'successful', 1000,
  current_setting('md.ref')))->>'status' = 'verified', 'reported success verifies the payment');
reset role;
select pg_temp.check((select verified_via = 'payer_app' and ledger_confirmed_at is null from payments
                      where id = current_setting('md.p')::uuid), 'marked as reported by the payer, not yet confirmed');
select pg_temp.check((select status from course_enrolments where user_id = current_setting('md.a')::uuid
                      and course_id = '00000000-0000-0000-0000-0000000d0001') = 'active', 'the course opens at once');

-- Other learners can't touch it or see the staff queue.
select pg_temp.login_as_id(current_setting('md.b')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.marzpay_submitted(current_setting('md.p')::uuid, 'x')$q$, 'not found');
select pg_temp.expect_error($q$select public.marzpay_result(current_setting('md.p')::uuid, 'successful', 1000,
  current_setting('md.ref'))$q$, 'not found');
select pg_temp.expect_error($q$select public.marzpay_to_confirm()$q$, 'not allowed');
select pg_temp.expect_error($q$select public.marzpay_confirm(current_setting('md.p')::uuid, 'successful', 1000,
  current_setting('md.ref'))$q$, 'not allowed');
reset role;

-- ------------------------------ staff phone: MarzPay disagrees → reverse --
select pg_temp.login_as('admin_1');
set local role authenticated;
select pg_temp.check(exists (select 1 from public.marzpay_to_confirm() j where j->>'id' = current_setting('md.p')),
  'reported payments wait for a staff check');
select pg_temp.check(public.marzpay_confirm(current_setting('md.p')::uuid, 'failed', 1000,
  current_setting('md.ref')) = 'reversed', 'a payment MarzPay does not confirm is reversed');
reset role;
select pg_temp.check((select status from course_enrolments where user_id = current_setting('md.a')::uuid
                      and course_id = '00000000-0000-0000-0000-0000000d0001') = 'suspended',
  'and the course closes again');

-- ------------------------ staff phone: confirms a waiting payment --
select pg_temp.login_as_id(current_setting('md.b')::uuid);
set local role authenticated;
select set_config('md.q', (public.start_course_payment('00000000-0000-0000-0000-0000000d0001', '0701234567'))->>'id', true);
select set_config('md.qref', (select j->>'reference' from public.my_payments('00000000-0000-0000-0000-0000000d0001') j limit 1), true);
select public.marzpay_submitted(current_setting('md.q')::uuid, 'md-uuid-2');
reset role;
update payments set updated_at = now() - interval '5 minutes' where id = current_setting('md.q')::uuid;
select pg_temp.login_as('admin_1');
set local role authenticated;
select pg_temp.check(public.marzpay_confirm(current_setting('md.q')::uuid, 'successful', 999,
  current_setting('md.qref')) = 'pending', 'a different amount goes to a person (pending)');
reset role;
select pg_temp.check((select verified_via is null from payments where id = current_setting('md.q')::uuid),
  'not verified');

-- ------------------------------------------------ tests on the phone --
select pg_temp.login_as_id(current_setting('md.su')::uuid);
set local role authenticated;
select set_config('md.t', public.request_payment_test('connection', '{}', null, true)::text, true);
select public.payment_test_step(current_setting('md.t')::uuid, '{"step": 1, "label": "network", "state": "done"}');
select public.payment_test_finish(current_setting('md.t')::uuid, 'verified_success', null, null, null, 'ok');
reset role;
select pg_temp.check((select status = 'done' and environment = 'app' and jsonb_array_length(steps) = 1
                      from payment_tests where id = current_setting('md.t')::uuid),
  'a test run on the phone records its steps and result');
select pg_temp.check(payments_api.claim_test() is null
                     or (payments_api.claim_test())->>'id' <> current_setting('md.t'),
  'the server never picks up a phone test');
