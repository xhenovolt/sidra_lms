-- 0045: fees per week / month / term / N days, not only once.

select set_config('rf.l', app_private.create_account('Monthly Learner', null, null, 'rf_learner',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('rf.o', app_private.create_account('Once Learner', null, null, 'rf_once',
  'learner', false, 'learner-pass-1', false)::text, true);

insert into courses (id, slug, title, subject, access, price_amount, price_currency, progression, status,
                     language, billing_period, billing_periods)
values ('00000000-0000-0000-0000-000000081001', 'rf-monthly', 'RF Monthly', 'Quran', 'paid', 30000, 'UGX',
        'open', 'published', 'en', 'monthly', 3),
       ('00000000-0000-0000-0000-000000081002', 'rf-once', 'RF Once', 'Quran', 'paid', 50000, 'UGX',
        'open', 'published', 'en', 'once', null);

select pg_temp.expect_error($q$update courses set billing_period = 'custom'
  where id = '00000000-0000-0000-0000-000000081002'$q$, 'courses_custom_billing');

-- A learner who started 40 days ago (two months begun) and paid one month.
insert into course_enrolments (course_id, user_id, status, source, fee_amount, fee_currency, billing_start)
values ('00000000-0000-0000-0000-000000081001', current_setting('rf.l')::uuid, 'active', 'payment',
        30000, 'UGX', current_date - 40);
insert into payments (user_id, course_id, amount, currency, method, status)
values (current_setting('rf.l')::uuid, '00000000-0000-0000-0000-000000081001', 30000, 'UGX', 'cash', 'verified');

select pg_temp.check((select fee = 60000 and outstanding = 30000
                      from app_private.course_balance(current_setting('rf.l')::uuid,
                                                      '00000000-0000-0000-0000-000000081001')),
  'two months due, one paid: one month outstanding');
select pg_temp.check((select fee = 30000 and outstanding = 0
                      from app_private.course_balance_on(current_setting('rf.l')::uuid,
                                                         '00000000-0000-0000-0000-000000081001', current_date - 20)),
  '20 days ago only the first month was due');

-- The learner sees the period, price and when the unpaid month began.
select pg_temp.login_as_id(current_setting('rf.l')::uuid);
set local role authenticated;
select pg_temp.check((select j->>'billing_period' = 'monthly' and (j->>'price_per_period')::numeric = 30000
                             and (j->>'periods_due')::int = 2 and (j->>'periods_covered')::int = 1
                             and (j->>'next_due_on')::date = (current_date - 40 + interval '1 month')::date
                      from public.my_course_balance('00000000-0000-0000-0000-000000081001') j),
  'the pay card knows: monthly, 30,000 a month, paid one of two, next due date');
reset role;

-- Past the grace days (7): the course pauses and the learner is told.
select pg_temp.check(app_private.enforce_billing() >= 1, 'unpaid past grace: paused');
select pg_temp.check((select status = 'suspended' and billing_suspended_at is not null
                      from course_enrolments where user_id = current_setting('rf.l')::uuid
                        and course_id = '00000000-0000-0000-0000-000000081001'), 'the enrolment is paused for fees');
select pg_temp.check(exists (select 1 from notifications where user_id = current_setting('rf.l')::uuid
                             and kind = 'fee_overdue'), 'and the learner is told why');

-- Paying the month reopens it.
insert into payments (user_id, course_id, amount, currency, method, status)
values (current_setting('rf.l')::uuid, '00000000-0000-0000-0000-000000081001', 30000, 'UGX', 'cash', 'verified');
select app_private.apply_payment_access(current_setting('rf.l')::uuid, '00000000-0000-0000-0000-000000081001');
select pg_temp.check((select status = 'active' and billing_suspended_at is null
                      from course_enrolments where user_id = current_setting('rf.l')::uuid
                        and course_id = '00000000-0000-0000-0000-000000081001'), 'paying reopens the course');

-- Behaviour suspensions are NOT lifted by paying.
update course_enrolments set status = 'suspended', billing_suspended_at = null
where user_id = current_setting('rf.l')::uuid and course_id = '00000000-0000-0000-0000-000000081001';
select app_private.apply_payment_access(current_setting('rf.l')::uuid, '00000000-0000-0000-0000-000000081001');
select pg_temp.check((select status from course_enrolments where user_id = current_setting('rf.l')::uuid
                        and course_id = '00000000-0000-0000-0000-000000081001') = 'suspended',
  'a pause for other reasons stays');

-- Capped at 3 periods: after 200 days only 3 months are ever due.
update course_enrolments set billing_start = current_date - 200, status = 'active'
where user_id = current_setting('rf.l')::uuid and course_id = '00000000-0000-0000-0000-000000081001';
select pg_temp.check((select fee = 90000 and outstanding = 30000
                      from app_private.course_balance(current_setting('rf.l')::uuid,
                                                      '00000000-0000-0000-0000-000000081001')),
  'a 3-month course never charges a 4th month');

-- Termly uses the term length setting; custom its own days.
update courses set billing_period = 'termly', billing_periods = null where id = '00000000-0000-0000-0000-000000081001';
select pg_temp.check((select fee = 30000 * 3 from app_private.course_balance(current_setting('rf.l')::uuid,
                        '00000000-0000-0000-0000-000000081001')), '200 days = 3 terms of 91 days begun');
update courses set billing_period = 'custom', billing_interval_days = 100 where id = '00000000-0000-0000-0000-000000081001';
select pg_temp.check((select fee = 30000 * 3 from app_private.course_balance(current_setting('rf.l')::uuid,
                        '00000000-0000-0000-0000-000000081001')), 'day 200 begins the 3rd period of 100 days');
update course_enrolments set billing_start = current_date - 199
where user_id = current_setting('rf.l')::uuid and course_id = '00000000-0000-0000-0000-000000081001';
select pg_temp.check((select fee = 30000 * 2 from app_private.course_balance(current_setting('rf.l')::uuid,
                        '00000000-0000-0000-0000-000000081001')), 'day 199 is still in the 2nd');

-- One-time courses behave exactly as before.
select pg_temp.check((select fee = 50000 and outstanding = 50000
                      from app_private.course_balance(current_setting('rf.o')::uuid,
                                                      '00000000-0000-0000-0000-000000081002')),
  'a one-time fee is charged once');
insert into payments (user_id, course_id, amount, currency, method, status)
values (current_setting('rf.o')::uuid, '00000000-0000-0000-0000-000000081002', 50000, 'UGX', 'cash', 'verified');
select app_private.apply_payment_access(current_setting('rf.o')::uuid, '00000000-0000-0000-0000-000000081002');
update course_enrolments set billing_start = current_date - 400
where user_id = current_setting('rf.o')::uuid and course_id = '00000000-0000-0000-0000-000000081002';
select pg_temp.check((select outstanding = 0 from app_private.course_balance(current_setting('rf.o')::uuid,
                        '00000000-0000-0000-0000-000000081002')), 'and stays paid a year later');
select pg_temp.check(app_private.enforce_billing() = 0 or not exists (
  select 1 from course_enrolments where user_id = current_setting('rf.o')::uuid and status = 'suspended'),
  'one-time courses are never paused for fees');

-- Switching a course to monthly starts enrolled learners' first period today.
insert into course_enrolments (course_id, user_id, status, source)
values ('00000000-0000-0000-0000-000000081002', current_setting('rf.l')::uuid, 'active', 'admin_grant');
update course_enrolments set billing_start = null where course_id = '00000000-0000-0000-0000-000000081002';
update courses set billing_period = 'monthly' where id = '00000000-0000-0000-0000-000000081002';
select pg_temp.check((select bool_and(billing_start = current_date) from course_enrolments
                      where course_id = '00000000-0000-0000-0000-000000081002'),
  'existing learners start their first month today');
select pg_temp.check((select outstanding = 0 from app_private.course_balance(current_setting('rf.o')::uuid,
                        '00000000-0000-0000-0000-000000081002')), 'what they paid covers it');
