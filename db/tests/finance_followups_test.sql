-- 0053: paying months ahead, receipts, the MarzPay check and the
-- accounting-rules record.

select set_config('ff.l', app_private.create_account('Prepay Learner', '+256772770001', null, null,
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('ff.o', app_private.create_account('Other Learner FF', '+256772770002', null, null,
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('ff.f', app_private.create_account('FF Finance', null, null, 'ff_finance',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('ff.f')::uuid, 'finance_officer');

-- A monthly course (20,000 a month) and a one-time one.
insert into courses (id, slug, title, subject, access, price_amount, price_currency, progression, status,
                     language, billing_period)
values
  ('00000000-0000-0000-0000-000000111001', 'ff-monthly', 'FF Monthly', 'Quran', 'paid', 20000, 'UGX',
   'open', 'published', 'en', 'monthly'),
  ('00000000-0000-0000-0000-000000111002', 'ff-once', 'FF Once', 'Quran', 'paid', 50000, 'UGX',
   'open', 'published', 'en', 'once');
-- Enrolled ten days ago: the first month is due.
insert into course_enrolments (course_id, user_id, status, source, fee_amount, fee_currency, billing_start)
values ('00000000-0000-0000-0000-000000111001', current_setting('ff.l')::uuid, 'pending', 'payment',
        20000, 'UGX', current_date - 10);

-- ------------------------------------------------------- paying ahead --
select pg_temp.login_as_id(current_setting('ff.l')::uuid);
set local role authenticated;

select set_config('ff.q', public.prepay_quote('00000000-0000-0000-0000-000000111001', 5)::text, true);
select pg_temp.check((current_setting('ff.q')::jsonb->>'amount')::numeric = 100000, '5 months cost 100,000');
select pg_temp.check((current_setting('ff.q')::jsonb->>'covers_from')::date = current_date - 10,
  'covering from the first unpaid month');
select pg_temp.check((current_setting('ff.q')::jsonb->>'covers_until')::date
  = (current_date - 10 + interval '5 months')::date - 1, 'to the end of the fifth month');
select pg_temp.expect_error($q$select public.prepay_quote('00000000-0000-0000-0000-000000111001', 0)$q$, 'at least');
select pg_temp.expect_error($q$select public.prepay_quote('00000000-0000-0000-0000-000000111001', 13)$q$, 'at most');
select pg_temp.expect_error($q$select public.prepay_quote('00000000-0000-0000-0000-000000111002', 2)$q$, 'one-time');

select set_config('ff.p', (public.start_course_payment('00000000-0000-0000-0000-000000111001',
  '0772770001', 5))->>'id', true);
select pg_temp.check((select amount = 100000 from payments where id = current_setting('ff.p')::uuid),
  'the MarzPay request is for 100,000');
select pg_temp.expect_error(format($q$select public.payment_receipt(%L)$q$, current_setting('ff.p')),
  'once the payment is confirmed');
reset role;

-- MarzPay confirms it (as the payments Worker does), with its real fee.
update payments set status = 'verified', verified_at = now(), verified_via = 'payments_server',
  provider_fee = 3000, external_reference = 'MP-ABC-1'
where id = current_setting('ff.p')::uuid;
select pg_temp.check((select receipt_number is not null and covers_from = current_date - 10
                             and covers_until = (current_date - 10 + interval '5 months')::date - 1
                      from payments where id = current_setting('ff.p')::uuid),
  'receipt number and the five months it pays for');
select pg_temp.check((select has_access and access_until
                             = (current_date - 10 + interval '5 months')::date
                               + app_private.int_setting('billing_grace_days', 7) - 1
                      from course_enrolments where user_id = current_setting('ff.l')::uuid
                        and course_id = '00000000-0000-0000-0000-000000111001'),
  'access runs to the end of the paid months (plus grace)');

select pg_temp.login_as_id(current_setting('ff.l')::uuid);
set local role authenticated;
select set_config('ff.r', public.payment_receipt(current_setting('ff.p')::uuid)::text, true);
select pg_temp.check((current_setting('ff.r')::jsonb->>'amount')::numeric = 100000
  and current_setting('ff.r')::jsonb->>'provider_reference' = 'MP-ABC-1'
  and current_setting('ff.r')::jsonb->>'course' = 'FF Monthly'
  and current_setting('ff.r')::jsonb->>'org_name' is not null, 'the learner sees their receipt');
select pg_temp.check(jsonb_array_length(public.my_payment_history()) = 1, 'payment history');
-- Paying ahead again continues after the paid months.
select pg_temp.check((public.prepay_quote('00000000-0000-0000-0000-000000111001', 1)->>'covers_from')::date
  = (current_date - 10 + interval '5 months')::date, 'the next payment starts after the paid months');
reset role;

select pg_temp.login_as_id(current_setting('ff.o')::uuid);
set local role authenticated;
select pg_temp.expect_error(format($q$select public.payment_receipt(%L)$q$, current_setting('ff.p')), 'not found');
reset role;

-- ------------------------------------------------------ MarzPay check --
select pg_temp.check(exists (select 1 from payments_api.statement_to_check(50)
                             where id = current_setting('ff.p')::uuid), 'the payment is due a check');
select pg_temp.check(payments_api.record_statement_check(current_setting('ff.p')::uuid,
  '[{"type": "credit", "amount": "100000", "status": "successful"},
    {"type": "debit", "amount": "3000", "status": "successful"}]') = 'match', 'MarzPay agrees');
select pg_temp.check(not exists (select 1 from payments_api.statement_to_check(50)
                                 where id = current_setting('ff.p')::uuid), 'not checked again at once');
select pg_temp.check(payments_api.record_statement_check(current_setting('ff.p')::uuid,
  '[{"type": "credit", "amount": "100000", "status": "successful"},
    {"type": "debit", "amount": "2000", "status": "successful"}]') = 'mismatch', 'a different fee is a mismatch');
select pg_temp.check(payments_api.record_statement_check(current_setting('ff.p')::uuid, '[]') = 'mismatch',
  'counted by Sidra but no money at MarzPay is a mismatch');

select pg_temp.login_as_id(current_setting('ff.f')::uuid);
set local role authenticated;
select pg_temp.check((public.marzpay_check_report()->>'mismatched')::int >= 1
  and public.marzpay_check_report()->'problems' @> jsonb_build_array(jsonb_build_object(
        'payment_id', current_setting('ff.p'))), 'finance sees the mismatch');

-- ------------------------------------------------- accounting rules --
select pg_temp.expect_error($q$select public.ledger_confirm_rules('')$q$, 'name');
select public.ledger_confirm_rules('A. Accountant', 'Cash basis is fine');
select pg_temp.check(public.ledger_overview()->'rules_confirmed'->>'by' = 'A. Accountant', 'rules confirmed, by whom');
reset role;
