-- 0048: paid-course access is decided by payment / waiver, never by an
-- "active" enrolment alone, and enforced on lessons and media.

select set_config('en.a', app_private.create_account('Paying Learner', '+256772710001', null, null,
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('en.b', app_private.create_account('Other Learner', '+256772710002', null, null,
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('en.t', app_private.create_account('Teacher En', null, null, 'en_teacher',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('en.t')::uuid, 'teacher');

insert into courses (id, slug, title, subject, access, price_amount, price_currency, progression, status, language)
values ('00000000-0000-0000-0000-000000061001', 'en-paid', 'EN Paid', 'Quran', 'paid', 100000, 'UGX',
        'open', 'published', 'en');
insert into course_staff (course_id, user_id, role)
values ('00000000-0000-0000-0000-000000061001', current_setting('en.t')::uuid, 'teacher');
insert into lessons (id, course_id, title, position, status, is_preview) values
  ('00000000-0000-0000-0000-000000062001', '00000000-0000-0000-0000-000000061001', 'Introduction', 0, 'published', true),
  ('00000000-0000-0000-0000-000000062002', '00000000-0000-0000-0000-000000061001', 'Lesson 1', 1, 'published', false);
insert into media_assets (id, kind, resource_type, delivery, public_id, format, version) values
  ('00000000-0000-0000-0000-000000063001', 'audio', 'video', 'authenticated', 'sidra/en/l1', 'mp3', 1);
insert into lesson_content_blocks (lesson_id, position, block_type, body, media_asset_id) values
  ('00000000-0000-0000-0000-000000062002', 0, 'audio', '{}', '00000000-0000-0000-0000-000000063001');

-- The defect: staff make the enrolment "active" with nothing paid.
insert into course_enrolments (course_id, user_id, status, source, fee_amount, fee_currency)
values ('00000000-0000-0000-0000-000000061001', current_setting('en.a')::uuid, 'active', 'admin_grant', 100000, 'UGX');

select pg_temp.login_as_id(current_setting('en.a')::uuid);
set local role authenticated;
select pg_temp.check(not app_private.can_read_lesson('00000000-0000-0000-0000-000000062002'),
  'active enrolment, nothing paid: the paid lesson stays closed');
select pg_temp.check((select count(*) from lesson_content_blocks
                      where lesson_id = '00000000-0000-0000-0000-000000062002') = 0, 'its content is hidden');
select pg_temp.expect_error($q$select public.media_url('00000000-0000-0000-0000-000000063001')$q$, 'locked');
select pg_temp.check(not app_private.can_read_lesson('00000000-0000-0000-0000-000000062001'),
  'previews need access too (unchanged rule)');
select pg_temp.check((public.my_course_access('00000000-0000-0000-0000-000000061001'))->>'state' = 'payment_required',
  'the app is told: payment required');
select pg_temp.check((select enrolment_status::text from public.my_courses()
                      where course_id = '00000000-0000-0000-0000-000000061001') = 'pending',
  'my courses shows it as pending (the pay card), not open');
reset role;

-- Nobody unenrolled reads anything.
select pg_temp.login_as_id(current_setting('en.b')::uuid);
set local role authenticated;
select pg_temp.check(not app_private.can_read_lesson('00000000-0000-0000-0000-000000062001')
                     and not app_private.can_read_lesson('00000000-0000-0000-0000-000000062002'),
  'not enrolled: nothing');
reset role;

-- A payment waiting for verification does not open anything.
select pg_temp.login_as_id(current_setting('en.a')::uuid);
set local role authenticated;
select set_config('en.manual', (public.submit_manual_payment('00000000-0000-0000-0000-000000061001', 'bank',
  100000, 'BANK-REF-1'))->>'id', true);
select pg_temp.check((public.my_course_access('00000000-0000-0000-0000-000000061001'))->>'state' = 'payment_pending'
                     and not app_private.can_read_lesson('00000000-0000-0000-0000-000000062002'),
  'a claimed bank payment is pending, not access');
reset role;

-- A teacher cannot verify payments or grant waivers.
select pg_temp.login_as_id(current_setting('en.t')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.verify_payment(current_setting('en.manual')::uuid)$q$, 'not allowed');
select pg_temp.expect_error($q$select public.grant_waiver(current_setting('en.a')::uuid,
  '00000000-0000-0000-0000-000000061001', null, 'kind')$q$, 'not allowed');
reset role;

-- Finance verifies it: the course opens.
select pg_temp.login_as('admin_1');
set local role authenticated;
select public.verify_payment(current_setting('en.manual')::uuid);
reset role;
select pg_temp.login_as_id(current_setting('en.a')::uuid);
set local role authenticated;
select pg_temp.check(app_private.can_read_lesson('00000000-0000-0000-0000-000000062002')
                     and (public.my_course_access('00000000-0000-0000-0000-000000061001'))->>'state' = 'access_granted',
  'verified full payment: access granted');
reset role;

-- A refund takes it back (re-assessed at once).
select pg_temp.login_as('admin_1');
set local role authenticated;
select public.record_refund(current_setting('en.manual')::uuid, 100000, 'left the course');
reset role;
select pg_temp.login_as_id(current_setting('en.a')::uuid);
set local role authenticated;
select pg_temp.check(not app_private.can_read_lesson('00000000-0000-0000-0000-000000062002'),
  'refunded: closed again');
reset role;

-- A waiver opens it — only within its dates, and not once revoked.
select pg_temp.login_as('admin_1');
set local role authenticated;
select set_config('en.w', (public.grant_waiver(current_setting('en.a')::uuid, '00000000-0000-0000-0000-000000061001',
  null, 'scholarship', current_date - 10, current_date - 1))->>'id', true);
reset role;
select pg_temp.check((select access_state from course_enrolments where user_id = current_setting('en.a')::uuid
                      and course_id = '00000000-0000-0000-0000-000000061001') <> 'waived',
  'an expired waiver opens nothing');
select pg_temp.login_as('admin_1');
set local role authenticated;
select set_config('en.w2', (public.grant_waiver(current_setting('en.a')::uuid, '00000000-0000-0000-0000-000000061001',
  null, 'scholarship 2026', current_date, current_date + 30))->>'id', true);
reset role;
select pg_temp.check((select e.access_state = 'waived' and e.has_access and w.granted_by is not null
                      from course_enrolments e join waivers w on w.user_id = e.user_id and w.course_id = e.course_id
                        and w.id = current_setting('en.w2')::uuid
                      where e.user_id = current_setting('en.a')::uuid
                        and e.course_id = '00000000-0000-0000-0000-000000061001'),
  'a current waiver (who, why, when) opens it');
select pg_temp.login_as('admin_1');
set local role authenticated;
select public.revoke_waiver(current_setting('en.w2')::uuid, 'ended');
reset role;
select pg_temp.check((select not has_access from course_enrolments where user_id = current_setting('en.a')::uuid
                      and course_id = '00000000-0000-0000-0000-000000061001'), 'revoked: closed on the next request');

-- The payer's own app report is not proof.
select pg_temp.login_as_id(current_setting('en.b')::uuid);
set local role authenticated;
select set_config('en.p', (public.start_course_payment('00000000-0000-0000-0000-000000061001', '0772710002'))->>'id', true);
select set_config('en.ref', (select j->>'reference' from public.my_payments('00000000-0000-0000-0000-000000061001') j limit 1), true);
select public.marzpay_submitted(current_setting('en.p')::uuid, 'en-uuid-1', 'mtn', 'processing');
select pg_temp.check((public.marzpay_result(current_setting('en.p')::uuid, 'successful', 100000,
                       current_setting('en.ref')))->>'status' = 'processing',
  'reported "successful" by the app: still waiting for a trusted check');
select pg_temp.check(not app_private.can_read_lesson('00000000-0000-0000-0000-000000062002'),
  'and the course stays closed');
reset role;
-- The trusted check (MarzPay itself, via the payments login) opens it;
-- doing it twice changes nothing.
select pg_temp.check(payments_api.settle('en-uuid-1', 'successful', 100000, 'MTN-1', null, 5000) = 'verified',
  'MarzPay confirms: verified');
select pg_temp.check(payments_api.settle('en-uuid-1', 'successful', 100000, 'MTN-1', null, 5000) = 'verified'
                     and (select count(*) from payments where provider_uuid = 'en-uuid-1') = 1,
  'a repeated confirmation creates nothing new');
select pg_temp.login_as_id(current_setting('en.b')::uuid);
set local role authenticated;
select pg_temp.check(app_private.can_read_lesson('00000000-0000-0000-0000-000000062002'), 'now open');
select pg_temp.check((select count(*) from public.my_payments('00000000-0000-0000-0000-000000061001') j
                      where j->>'id' = current_setting('en.manual')) = 0, 'and nobody sees another''s payments');
reset role;

-- Reversed (MarzPay did not confirm after all): closed, for review.
select pg_temp.login_as('admin_1');
set local role authenticated;
select public.reverse_payment(current_setting('en.p')::uuid, 'MarzPay disowned it');
reset role;
select pg_temp.check((select access_state = 'refund_review' and not has_access from course_enrolments
                      where user_id = current_setting('en.b')::uuid
                        and course_id = '00000000-0000-0000-0000-000000061001'), 'reversal: closed, for review');

-- Partial payment opens only when the course says so.
update courses set paid_access_min_percent = 50 where id = '00000000-0000-0000-0000-000000061001';
insert into payments (user_id, course_id, amount, currency, method, status)
values (current_setting('en.b')::uuid, '00000000-0000-0000-0000-000000061001', 60000, 'UGX', 'cash', 'verified');
-- (verify_payment / settle call this after a verified payment)
select app_private.apply_payment_access(current_setting('en.b')::uuid, '00000000-0000-0000-0000-000000061001');
select pg_temp.check((select access_state = 'partially_paid' and has_access and status = 'active' from course_enrolments
                      where user_id = current_setting('en.b')::uuid
                        and course_id = '00000000-0000-0000-0000-000000061001'),
  'a 50% rule: 60% paid opens it, marked partially paid');
update courses set paid_access_min_percent = 100 where id = '00000000-0000-0000-0000-000000061001';
select pg_temp.check((select not has_access from course_enrolments where user_id = current_setting('en.b')::uuid
                      and course_id = '00000000-0000-0000-0000-000000061001'), 'full payment rule again: closed');

-- Repeating fees: access ends when the paid periods (+ grace) run out.
update courses set billing_period = 'monthly', paid_access_min_percent = 100
where id = '00000000-0000-0000-0000-000000061001';
update course_enrolments set billing_start = current_date - 70
where user_id = current_setting('en.b')::uuid and course_id = '00000000-0000-0000-0000-000000061001';
select pg_temp.check((select access_state <> 'access_granted' from course_enrolments
                      where user_id = current_setting('en.b')::uuid
                        and course_id = '00000000-0000-0000-0000-000000061001'),
  'three months begun, one paid: no access');
