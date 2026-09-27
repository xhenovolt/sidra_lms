-- Enrolments, payments, waivers, refunds, expenses, finance (0016).
-- Uses access_test fixtures: admin_1 (Admin role), learner_a, learner_b.

-- Totals are compared against a baseline: the live database may already
-- hold real payments and waivers.
select pg_temp.login_as('admin_1');
set local role authenticated;
select set_config('t.base', public.finance_summary(p_course_id => null)::text, true);
reset role;

insert into courses (id, slug, title, subject, access, price_amount, price_currency, status)
values ('00000000-0000-0000-0000-00000000f001', 'paid-quran', 'Paid Quran', 'Quran',
        'paid', 50000, 'UGX', 'published');
insert into lessons (id, course_id, title, position, status, is_preview)
values ('00000000-0000-0000-0000-00000000f0a1', '00000000-0000-0000-0000-00000000f001',
        'Lesson 1', 0, 'published', true);

-- ---------------------------------------------- learner pays by MarzPay --
select pg_temp.login_as('learner_b');
set local role authenticated;
select pg_temp.check((public.my_course_balance('00000000-0000-0000-0000-00000000f001')
                      ->>'outstanding')::numeric = 50000, 'owes the course price');
select pg_temp.expect_error($q$select public.start_course_payment(
  '00000000-0000-0000-0000-00000000f001', '12345')$q$, 'MTN or Airtel');
select set_config('t.pay1', (public.start_course_payment(
  '00000000-0000-0000-0000-00000000f001', '0741 341483')->>'id'), true);
select pg_temp.check((select phone from payments where id = current_setting('t.pay1')::uuid)
                     = '+256741341483', 'phone normalised for MarzPay');
select pg_temp.check((public.start_course_payment(
  '00000000-0000-0000-0000-00000000f001', '0741341483')->>'id') = current_setting('t.pay1'),
  'a second tap returns the same payment (one prompt at a time)');
select pg_temp.check(not app_private.can_read_lesson('00000000-0000-0000-0000-00000000f0a1'),
  'no access before the money is confirmed');
select pg_temp.expect_error($q$select public.verify_payment(current_setting('t.pay1')::uuid)$q$,
  'not allowed');
select pg_temp.expect_error($q$update payments set status = 'verified'$q$, 'permission denied');
reset role;

-- --------------------------------------------------- payments server --
set local role sidra_payments;
select pg_temp.expect_error($q$select * from payments$q$, 'permission denied');
select pg_temp.check((select count(*) from payments_api.claim(10)
                      where id = current_setting('t.pay1')::uuid) = 1, 'server claims it');
select pg_temp.check(not exists (select 1 from payments_api.claim(10)
                                 where id = current_setting('t.pay1')::uuid),
  'a claimed payment is not handed out twice at once');
select payments_api.submitted(current_setting('t.pay1')::uuid, 'marz-uuid-1', 'Airtel', 'pending');
select pg_temp.check(payments_api.settle('marz-uuid-1', 'pending', 50000, null) = 'processing',
  'still waiting for the PIN');
select pg_temp.check(payments_api.settle('marz-uuid-1', 'successful', 50000, 'AIRTEL-1', null, 1500)
                     = 'verified', 'MarzPay success verifies the payment');
select pg_temp.check(payments_api.settle('marz-uuid-1', 'failed', 50000, null) = 'verified',
  'settling again changes nothing');
reset role;

select pg_temp.login_as('learner_b');
set local role authenticated;
select pg_temp.check(app_private.can_read_lesson('00000000-0000-0000-0000-00000000f0a1'),
  'paid in full: the course opens');
select pg_temp.check((public.my_course_balance('00000000-0000-0000-0000-00000000f001')
                      ->>'outstanding')::numeric = 0, 'nothing owed');
select pg_temp.expect_error($q$select public.start_course_payment(
  '00000000-0000-0000-0000-00000000f001', '0741341483')$q$, 'already paid');
reset role;

-- A second learner's prompt fails, then an amount mismatch goes to a person.
select pg_temp.login_as('learner_a');
set local role authenticated;
select set_config('t.pay2', (public.start_course_payment(
  '00000000-0000-0000-0000-00000000f001', '0772123456')->>'id'), true);
reset role;
set local role sidra_payments;
select payments_api.submitted(current_setting('t.pay2')::uuid, 'marz-uuid-2', 'MTN', 'pending');
select pg_temp.check(payments_api.settle('marz-uuid-2', 'failed', 50000, null) = 'failed',
  'PIN never entered → failed');
reset role;
select pg_temp.login_as('learner_a');
set local role authenticated;
select set_config('t.pay3', (public.start_course_payment(
  '00000000-0000-0000-0000-00000000f001', '0772123456')->>'id'), true);
reset role;
set local role sidra_payments;
select payments_api.submitted(current_setting('t.pay3')::uuid, 'marz-uuid-3', 'MTN', 'pending');
select pg_temp.check(payments_api.settle('marz-uuid-3', 'successful', 500, 'MTN-3') = 'pending',
  'a different amount is held for a finance officer');
reset role;

-- ------------------------------------------------ manual + waivers --
select pg_temp.login_as('learner_a');
set local role authenticated;
select set_config('t.bank', (public.submit_manual_payment('00000000-0000-0000-0000-00000000f001',
  'bank', 20000, 'SLIP-1', null, 'Stanbic deposit')->>'id'), true);
select pg_temp.check(not exists (select 1 from payments
                                 where user_id <> app_private.current_user_id()),
  'learners see only their own payments');
reset role;

select pg_temp.login_as('admin_1');
set local role authenticated;
select pg_temp.check((public.verify_payment(current_setting('t.bank')::uuid)->>'status') = 'verified',
  'finance verifies the bank slip');
select pg_temp.expect_error($q$select public.reject_payment(current_setting('t.bank')::uuid, 'x')$q$,
  'only payments waiting');
select public.reject_payment(current_setting('t.pay3')::uuid, 'Wrong amount; refunded by MarzPay');
select public.grant_waiver('00000000-0000-0000-0000-0000000000a1',
  '00000000-0000-0000-0000-00000000f001', 30000, 'Orphan bursary');
select pg_temp.check((select outstanding from public.finance_balances(
  '00000000-0000-0000-0000-00000000f001', false)
  where user_id = '00000000-0000-0000-0000-0000000000a1') = 0,
  '20,000 paid + 30,000 waived covers the fee');
select pg_temp.check((select status from course_enrolments
                      where user_id = '00000000-0000-0000-0000-0000000000a1'
                        and course_id = '00000000-0000-0000-0000-00000000f001') = 'active',
  'covered by payment and waiver: access opens');
select public.reverse_payment(current_setting('t.bank')::uuid, 'Cheque bounced');
select pg_temp.check((select status from course_enrolments
                      where user_id = '00000000-0000-0000-0000-0000000000a1'
                        and course_id = '00000000-0000-0000-0000-00000000f001') = 'suspended',
  'a reversed payment suspends access while money is owed');

-- Refunds, expenses, the summary.
select pg_temp.expect_error($q$select public.record_refund(current_setting('t.pay1')::uuid, 60000, 'too much')$q$,
  'cannot exceed');
select public.record_refund(current_setting('t.pay1')::uuid, 1000, 'Overcharged');
select set_config('t.exp', (public.record_expense('Rent', 100000, current_date, 'Classroom')->>'id'), true);
select public.void_expense(current_setting('t.exp')::uuid, 'Entered twice');
select public.record_expense('Transport', 2000, current_date);
select set_config('t.sum', public.finance_summary(p_course_id => null)::text, true);
select pg_temp.check((current_setting('t.sum')::jsonb->>'collected')::numeric = (current_setting('t.base')::jsonb->>'collected')::numeric + 50000,
  'collected = verified payments only (reversed and pending excluded)');
select pg_temp.check((current_setting('t.sum')::jsonb->>'provider_fees')::numeric = (current_setting('t.base')::jsonb->>'provider_fees')::numeric + 1500,
  'MarzPay fees counted');
select pg_temp.check((current_setting('t.sum')::jsonb->>'retained')::numeric = (current_setting('t.base')::jsonb->>'retained')::numeric + 50000 - 1000 - 1500 - 2000,
  'retained = collected − refunds − provider fees − expenses (voided excluded)');
select pg_temp.check((current_setting('t.sum')::jsonb->>'waived')::numeric = (current_setting('t.base')::jsonb->>'waived')::numeric + 30000,
  'waivers reported');
select pg_temp.check((current_setting('t.sum')::jsonb->>'pending_count')::int = (current_setting('t.base')::jsonb->>'pending_count')::int,
  'nothing waiting for verification');
select pg_temp.check(exists (select 1 from public.finance_balances()
                             where user_id = '00000000-0000-0000-0000-0000000000a1'
                               and outstanding = 20000),
  'who owes what');
select pg_temp.check((select count(*) from public.finance_payments(p_search => 'SLIP-1')) = 1,
  'payments searchable by slip number');

-- Enrolment terms: an expired window closes access.
select public.bulk_enrol('00000000-0000-0000-0000-000000000c04',
  array['00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000b1']::uuid[],
  now() - interval '30 days', now() - interval '1 day');
select pg_temp.expect_error($q$select public.bulk_enrol('00000000-0000-0000-0000-000000000c04',
  array['00000000-0000-0000-0000-0000000000a1']::uuid[], now(), now() - interval '1 day')$q$,
  'end date must be after');
select public.set_org_setting('bank_instructions', 'Stanbic, Almuntahha, 9030000000000');
reset role;

select pg_temp.login_as('learner_a');
set local role authenticated;
select pg_temp.check(not app_private.is_enrolled('00000000-0000-0000-0000-000000000c04'),
  'access ends with the enrolment window');
select pg_temp.check((public.org_settings()->>'bank_instructions') like 'Stanbic%',
  'learners see how to pay by bank');
select pg_temp.expect_error($q$select public.set_org_setting('org_name', 'X')$q$, 'not allowed');
select pg_temp.expect_error($q$select public.finance_summary()$q$, 'not allowed');
reset role;

-- Nothing financial is ever deleted.
select pg_temp.expect_error($q$delete from payments where id = current_setting('t.pay1')::uuid$q$,
  'never deleted');
select pg_temp.expect_error($q$delete from expenses$q$, 'never deleted');

select 'ALL FINANCE TESTS PASSED' as result;
