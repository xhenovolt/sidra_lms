-- Tier 2 (0036): problem reports, learner policies with safeguards,
-- suspension and reinstatement, calendars, MarzPay rechecks.

select set_config('t2.t', app_private.create_account('Teacher T2', null, null, 't2_teacher',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('t2.t')::uuid, 'teacher');
select set_config('t2.a', app_private.create_account('Learner Reporter', null, null, 't2_a',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('t2.b', app_private.create_account('Learner Late', null, null, 't2_b',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('t2.x', app_private.create_account('Outsider T2', null, null, 't2_x',
  'learner', false, 'learner-pass-1', false)::text, true);

insert into courses (id, slug, title, subject, access, progression, status, language)
values ('00000000-0000-0000-0000-0000000b2001', 't2-course', 'T2 Course', 'Quran',
        'restricted', 'open', 'published', 'en');
insert into course_staff (course_id, user_id, role)
values ('00000000-0000-0000-0000-0000000b2001', current_setting('t2.t')::uuid, 'teacher');
insert into course_enrolments (course_id, user_id, status, source)
select '00000000-0000-0000-0000-0000000b2001', u, 'active', 'admin_grant'
from unnest(array[current_setting('t2.a')::uuid, current_setting('t2.b')::uuid]) u;

select pg_temp.login_as_id(current_setting('t2.t')::uuid);
set local role authenticated;
select set_config('t2.g', public.save_teaching_group('00000000-0000-0000-0000-0000000b2001', 'T2 Group',
  array[current_setting('t2.a')::uuid, current_setting('t2.b')::uuid])->>'id', true);
select set_config('t2.p', public.save_portion('00000000-0000-0000-0000-0000000b2001', 'Page 20',
  current_setting('t2.g')::uuid, null, 'Read page 20.', 'en')->>'id', true);
select public.assign_portion(current_setting('t2.p')::uuid);
reset role;

-- The work was given 6 days ago and was due 5 days ago. B opened it; A didn't.
update teaching_portions set due_at = now() - interval '5 days', assigned_at = now() - interval '6 days',
  requires_submission = true
where id = current_setting('t2.p')::uuid;
update portion_learners set assigned_at = now() - interval '6 days' where portion_id = current_setting('t2.p')::uuid;
update portion_learners set status = 'opened', opened_at = now() - interval '5 days'
where portion_id = current_setting('t2.p')::uuid and user_id = current_setting('t2.b')::uuid;
update org_settings set value = 'true' where key = 'policy_count_weekends';
update org_settings set value = null where key in ('policy_paused_until', 'policy_last_run');
update org_settings set value = 'false' where key = 'policy_auto_suspend';

-- ----------------------------------------------------- problem reports --
select pg_temp.login_as_id(current_setting('t2.x')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.report_work_issue('portion', current_setting('t2.p')::uuid,
  'need_more_time', 'please')$q$, 'work not found');
reset role;

select pg_temp.login_as_id(current_setting('t2.a')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.report_work_issue('portion', current_setting('t2.p')::uuid,
  'other', '')$q$, 'describe the problem');
select set_config('t2.i', public.report_work_issue('portion', current_setting('t2.p')::uuid,
  'need_more_time', 'I was sick this week')->>'id', true);
select pg_temp.check((public.report_work_issue('portion', current_setting('t2.p')::uuid,
  'cannot_record', 'and my microphone fails'))->>'id' = current_setting('t2.i'),
  'a second report on the same work joins the open one');
select pg_temp.check((select count(*) from public.my_work_issues('portion', current_setting('t2.p')::uuid)) = 1,
  'learner sees their report');
reset role;

select pg_temp.check((select work_state = 'assigned' and category = 'cannot_record'
                             and message like 'I was sick%microphone fails'
                      from work_issues where id = current_setting('t2.i')::uuid),
  'report records the work state, category and both messages');
select pg_temp.check(exists (select 1 from notifications where user_id = current_setting('t2.t')::uuid
                             and kind = 'work_issue'), 'the teacher is notified');

-- Another learner can't see it.
select pg_temp.login_as_id(current_setting('t2.b')::uuid);
set local role authenticated;
select pg_temp.check(not exists (select 1 from work_issues where id = current_setting('t2.i')::uuid),
  'learners cannot read other learners'' reports');
select pg_temp.expect_error($q$select public.respond_work_issue(current_setting('t2.i')::uuid, 'ok')$q$,
  'not found');
reset role;

-- ------------------------------------------------------- policies run --
select app_private.evaluate_learner_policies();
select pg_temp.check(not exists (select 1 from learner_policy_events where user_id = current_setting('t2.a')::uuid),
  'an open problem report stops the clock');
select pg_temp.check((select array_agg(kind order by kind) from learner_policy_events
                      where user_id = current_setting('t2.b')::uuid and resolved_at is null)
                     = array['escalated', 'not_submitted', 'overdue'],
  'opened-but-not-submitted, overdue and escalated recorded separately');
select pg_temp.check((select policy->>'overdue_hours' = '48' from learner_policy_events
                      where user_id = current_setting('t2.b')::uuid and kind = 'overdue'),
  'each event records the policy that caused it');
select pg_temp.check(exists (select 1 from notifications where user_id = current_setting('t2.b')::uuid
                             and kind = 'work_overdue_warning'), 'late learner is reminded');
select pg_temp.check(exists (select 1 from notifications where user_id = current_setting('t2.t')::uuid
                             and kind = 'work_overdue'), 'teacher told about overdue work');
select pg_temp.check((select status from course_enrolments where user_id = current_setting('t2.b')::uuid
                      and course_id = '00000000-0000-0000-0000-0000000b2001') = 'active',
  'no suspension while automatic suspension is off');
-- Running again adds nothing.
select app_private.evaluate_learner_policies();
select pg_temp.check((select count(*) from learner_policy_events where user_id = current_setting('t2.b')::uuid) = 3,
  'policies are idempotent');

-- ------------------------------------------- teacher answers + extends --
select pg_temp.login_as_id(current_setting('t2.t')::uuid);
set local role authenticated;
select pg_temp.check((select count(*) from public.work_issues_for_me('open')) >= 1, 'teacher sees open reports');
select public.respond_work_issue(current_setting('t2.i')::uuid, 'Take two more days, get well',
  now() + interval '2 days', true);
reset role;
select pg_temp.check((select status = 'resolved' and extension_until > now() from work_issues
                      where id = current_setting('t2.i')::uuid), 'resolved with an extension');
select pg_temp.check(exists (select 1 from notifications where user_id = current_setting('t2.a')::uuid
                             and kind = 'issue_answered'), 'learner told about the answer');
select app_private.evaluate_learner_policies();
select pg_temp.check(not exists (select 1 from learner_policy_events where user_id = current_setting('t2.a')::uuid),
  'the extension moves the due time: not late');

-- ------------------------------------------------ automatic suspension --
update org_settings set value = 'true' where key = 'policy_auto_suspend';
update org_settings set value = '3' where key = 'policy_suspend_after_days';
select app_private.evaluate_learner_policies();
select pg_temp.check((select status from course_enrolments where user_id = current_setting('t2.b')::uuid
                      and course_id = '00000000-0000-0000-0000-0000000b2001') = 'active',
  'not suspended: the warning is less than a day old');
update learner_policy_events set created_at = now() - interval '2 days'
where user_id = current_setting('t2.b')::uuid and kind = 'not_submitted';
select app_private.evaluate_learner_policies();
select pg_temp.check((select status from course_enrolments where user_id = current_setting('t2.b')::uuid
                      and course_id = '00000000-0000-0000-0000-0000000b2001') = 'active',
  'not suspended: the learner has not used Sidra since the work was given');
insert into app_private.devices (user_id, install_id, last_contact_at)
values (current_setting('t2.b')::uuid, 'install-t2-late-1', now());
select app_private.evaluate_learner_policies();
select pg_temp.check((select status from course_enrolments where user_id = current_setting('t2.b')::uuid
                      and course_id = '00000000-0000-0000-0000-0000000b2001') = 'suspended',
  'suspended after warning, reachability and threshold');
select pg_temp.check((select reason like '%days late after reminders' and policy->>'auto_suspend' = 'true'
                      from learner_policy_events where user_id = current_setting('t2.b')::uuid and kind = 'suspended'),
  'suspension explains why and which policy');
select pg_temp.check(exists (select 1 from notifications where user_id = current_setting('t2.b')::uuid
                             and kind = 'learner_suspended'), 'learner told why');
select pg_temp.check(exists (select 1 from portion_learners where user_id = current_setting('t2.b')::uuid
                             and portion_id = current_setting('t2.p')::uuid), 'work and progress kept');

-- Pausing the policies (e.g. an outage) stops all automatic actions.
update org_settings set value = (now() + interval '1 day')::text where key = 'policy_paused_until';
select pg_temp.check(app_private.evaluate_learner_policies() ? 'skipped', 'a pause stops the policies');
update org_settings set value = null where key = 'policy_paused_until';

-- The teacher reinstates.
select pg_temp.login_as_id(current_setting('t2.t')::uuid);
set local role authenticated;
select public.reinstate_learner(current_setting('t2.b')::uuid, '00000000-0000-0000-0000-0000000b2001',
  'Talked to the family');
select pg_temp.check((select count(*) from public.learner_policy_events(false,
                        current_setting('t2.b')::uuid)) >= 4, 'teacher sees the history');
reset role;
select pg_temp.check((select status from course_enrolments where user_id = current_setting('t2.b')::uuid
                      and course_id = '00000000-0000-0000-0000-0000000b2001') = 'active', 'reinstated');
select pg_temp.check(not exists (select 1 from learner_policy_events where user_id = current_setting('t2.b')::uuid
                                 and resolved_at is null), 'reinstating closes the open events');
update org_settings set value = 'false' where key = 'policy_auto_suspend';
update org_settings set value = '14' where key = 'policy_suspend_after_days';

-- A learner can't run or change policies.
select pg_temp.login_as_id(current_setting('t2.a')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.run_learner_policies(true)$q$, 'not allowed');
select pg_temp.expect_error($q$select public.reinstate_learner(current_setting('t2.b')::uuid,
  '00000000-0000-0000-0000-0000000b2001')$q$, 'not allowed');
reset role;

-- ------------------------------------------------ calendars and hours --
update org_settings set value = 'false' where key = 'policy_count_weekends';
update org_settings set value = 'Africa/Kampala' where key = 'org_time_zone';
select pg_temp.check(app_private.counted_hours('2026-10-03 00:00+03', '2026-10-05 00:00+03') = 0,
  'a Saturday and Sunday do not count when weekends are off');
insert into calendar_holidays (day, name) values ('2026-10-09', 'Independence Day');
select pg_temp.check(app_private.counted_hours('2026-10-08 00:00+03', '2026-10-10 00:00+03') = 24,
  'a holiday does not count');
update org_settings set value = 'true' where key = 'policy_count_weekends';
select pg_temp.expect_error($q$select public.set_org_setting('policy_warn_after_hours', 'soon')$q$, 'not allowed');

-- -------------------------------------------------- MarzPay rechecks --
insert into payments (id, user_id, course_id, amount, currency, method, status, provider_uuid,
                      status_reason, created_at, updated_at)
values
  ('00000000-0000-0000-0000-0000000b2f01', current_setting('t2.a')::uuid, '00000000-0000-0000-0000-0000000b2001',
   1000, 'UGX', 'marzpay', 'failed', 't2-old-rule', 'no answer from MarzPay after a day',
   now() - interval '2 days', now() - interval '1 hour'),
  ('00000000-0000-0000-0000-0000000b2f02', current_setting('t2.b')::uuid, '00000000-0000-0000-0000-0000000b2001',
   1000, 'UGX', 'marzpay', 'processing', 't2-slow', null,
   now() - interval '3 days', now() - interval '1 hour');
select pg_temp.check((select count(*) from payments_api.to_reconcile(100)
                      where provider_uuid in ('t2-old-rule', 't2-slow')) = 2,
  'unanswered and old-rule-failed payments are rechecked');
select pg_temp.check(payments_api.settle('t2-slow', 'pending', 1000, null) = 'processing',
  'three days without an answer is still "processing", not failed');
select pg_temp.check(payments_api.settle('t2-old-rule', 'successful', 1000, 'AIRTEL-123') = 'verified',
  'money that arrived late is recorded (evidence re-fetched from MarzPay)');
select pg_temp.check(payments_api.settle('t2-old-rule', 'failed', 1000, null) = 'verified',
  'a verified payment never goes back');
