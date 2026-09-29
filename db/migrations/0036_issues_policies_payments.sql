-- 0036 Tier 2: problem reports, learner policies, payment rechecks.
--
-- 1. Work issues: a learner says "I have a problem with this work" about a
--    teaching portion, a lesson or an assignment (category + text + optional
--    file). The work's teachers are notified, answer, may grant more time,
--    and resolve it. Nothing disappears into a generic notification.
-- 2. Learner policies, all settings (Settings → Learner policies), each
--    change audited like every setting:
--      warn        a reminder after the due time (+ grace)
--      overdue     the teacher is told
--      escalate    administrators are told
--      suspend     OFF by default; suspends the COURSE enrolment only
--      inactive    learner hasn't used Sidra for N days (not about any work)
--    "Not opened", "opened but not submitted" and "not using the app" are
--    separate events. Clocks skip weekends (if set) and holidays, and wait
--    while a problem report is open; a teacher's extension moves the due
--    time. Before suspending: a warning must have been sent at least a day
--    earlier, the work must have reached the learner, and there must be no
--    open report, extension, pause, or earlier suspension. Every automatic
--    action is recorded with the policy values that caused it.
-- 3. MarzPay: a payment with no answer is re-checked for 7 days (was 1),
--    older ones less often, and the ones the old rule failed are re-checked.

-- ------------------------------------------------------------ settings --
insert into org_settings (key, value, is_public) values
  ('policy_enabled', 'true', false),
  ('policy_warn_after_hours', '24', false),
  ('policy_overdue_after_hours', '48', false),
  ('policy_escalate_after_days', '4', false),
  ('policy_auto_suspend', 'false', false),
  ('policy_suspend_after_days', '14', false),
  ('policy_inactive_after_days', '7', false),
  ('policy_grace_hours', '0', false),
  ('policy_count_weekends', 'true', false),
  ('policy_reminder_every_hours', '48', false),
  ('policy_paused_until', null, false),
  ('policy_last_run', null, false),
  ('org_time_zone', 'Africa/Kampala', false),
  ('payment_unanswered_days', '7', false)
on conflict (key) do nothing;

-- Values are checked (same rule as 0033: a typo must not break anything).
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.set_org_setting(text, text)'::regprocedure);
  if position('  update org_settings set value = v' in v_src) = 0 then
    raise exception 'set_org_setting changed; update 0036';
  end if;
  execute replace(v_src, '  update org_settings set value = v',
$r$  if p_key in ('policy_enabled', 'policy_auto_suspend', 'policy_count_weekends')
     and coalesce(v, '') not in ('true', 'false') then
    raise exception '% must be on or off', p_key using errcode = 'PT422';
  end if;
  if p_key in ('policy_warn_after_hours', 'policy_overdue_after_hours', 'policy_reminder_every_hours')
     and (v !~ '^\d+$' or v::int not between 1 and 2000) then
    raise exception '% must be between 1 and 2000 hours', p_key using errcode = 'PT422';
  end if;
  if p_key = 'policy_grace_hours' and (v !~ '^\d+$' or v::int not between 0 and 720) then
    raise exception 'grace must be between 0 and 720 hours' using errcode = 'PT422';
  end if;
  if p_key in ('policy_escalate_after_days', 'policy_suspend_after_days', 'policy_inactive_after_days',
               'payment_unanswered_days')
     and (v !~ '^\d+$' or v::int not between 1 and 365) then
    raise exception '% must be between 1 and 365 days', p_key using errcode = 'PT422';
  end if;
  if p_key = 'policy_paused_until' and v is not null then
    begin perform v::timestamptz;
    exception when others then
      raise exception 'pause must be a date and time' using errcode = 'PT422';
    end;
  end if;
  if p_key = 'org_time_zone' and not exists (select 1 from pg_timezone_names where name = v) then
    raise exception 'unknown time zone %', v using errcode = 'PT422';
  end if;
  update org_settings set value = v$r$);
end $$;

-- Days that don't count towards any deadline (Eid, national holidays…).
create table calendar_holidays (
  day date primary key,
  name text not null check (length(trim(name)) > 0),
  created_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now()
);
alter table calendar_holidays enable row level security;
create policy holidays_read on calendar_holidays for select to public using (true);
create policy holidays_write on calendar_holidays for all to public
  using (app_private.has_permission('settings.manage'))
  with check (app_private.has_permission('settings.manage'));
grant select, insert, update, delete on calendar_holidays to authenticated, sidra_app;
create trigger calendar_holidays_audit after insert or update or delete on calendar_holidays
  for each row execute function app_private.audit();

-- ------------------------------------------------------- work issues --
create table work_issues (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users (id) on delete cascade,
  course_id uuid not null references courses (id) on delete cascade,
  lesson_id uuid references lessons (id) on delete cascade,
  portion_id uuid references teaching_portions (id) on delete cascade,
  assignment_id uuid references assignments (id) on delete cascade,
  category text not null check (category in (
    'dont_understand', 'unavailable', 'technical', 'cannot_access', 'need_clarification',
    'cannot_record', 'cannot_upload', 'need_more_time', 'other')),
  message text check (length(message) <= 2000),
  attachment_asset_id uuid references media_assets (id) on delete set null,
  work_state text,
  status text not null default 'open' check (status in ('open', 'answered', 'resolved')),
  response text check (length(response) <= 2000),
  responded_by uuid references users (id) on delete set null,
  responded_at timestamptz,
  extension_until timestamptz,
  resolved_by uuid references users (id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (num_nonnulls(portion_id, assignment_id) <= 1),
  check (portion_id is not null or assignment_id is not null or lesson_id is not null)
);
create index work_issues_user on work_issues (user_id, created_at desc);
create index work_issues_open on work_issues (course_id, status) where status <> 'resolved';
alter table work_issues enable row level security;

-- The teachers responsible for a piece of work.
create or replace function app_private.work_teachers(p_course uuid, p_lesson uuid, p_portion uuid)
returns setof uuid
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select gt.user_id from teaching_portions p
  join teaching_group_teachers gt on gt.group_id = p.group_id
  where p.id = p_portion
  union
  select t from app_private.lesson_teachers(p_lesson) t where p_lesson is not null
  union
  select s.user_id from course_staff s join users u on u.id = s.user_id and u.is_active
  where s.course_id = p_course and p_lesson is null and p_portion is null
    and u.role in ('teacher', 'admin')
$$;

create or replace function app_private.can_handle_issue(i work_issues)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.has_permission('learners.edit')
      or (i.portion_id is not null and app_private.teaches_portion(i.portion_id))
      or app_private.teaches(i.course_id, i.lesson_id)
$$;

create policy work_issues_read on work_issues for select to public
  using (user_id = app_private.current_user_id() or app_private.can_handle_issue(work_issues));
grant select on work_issues to authenticated, sidra_app;
create trigger work_issues_audit after insert or update on work_issues
  for each row execute function app_private.audit();

create or replace function app_private.issue_json(i work_issues)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select to_jsonb(i) || jsonb_build_object(
    'learner_name', (select display_name from users where id = i.user_id),
    'course_title', (select title from courses where id = i.course_id),
    'work_title', coalesce(
       (select title from teaching_portions where id = i.portion_id),
       (select title from assignments where id = i.assignment_id),
       (select title from lessons where id = i.lesson_id)),
    'responder_name', (select display_name from users where id = i.responded_by))
$$;

-- Learner: report a problem. p_kind = portion | lesson | assignment.
create or replace function public.report_work_issue(
  p_kind text, p_target_id uuid, p_category text, p_message text default null,
  p_attachment_asset_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_course uuid; v_lesson uuid; v_portion uuid; v_assignment uuid; v_state text;
  v work_issues%rowtype;
  t uuid;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  if p_kind = 'portion' then
    select p.course_id, p.lesson_id, p.id, pl.status::text into v_course, v_lesson, v_portion, v_state
    from teaching_portions p join portion_learners pl on pl.portion_id = p.id and pl.user_id = v_me
    where p.id = p_target_id;
  elsif p_kind = 'lesson' then
    select l.course_id, l.id into v_course, v_lesson from lessons l where l.id = p_target_id;
    if v_course is not null and not app_private.is_enrolled(v_course) then v_course := null; end if;
    select s.status::text into v_state from submissions s
    where s.lesson_id = p_target_id and s.user_id = v_me and s.assignment_id is null and s.portion_id is null
    order by s.submitted_at desc limit 1;
  elsif p_kind = 'assignment' then
    select a.course_id, a.lesson_id, a.id into v_course, v_lesson, v_assignment
    from assignments a where a.id = p_target_id
      and app_private.can_read_assignment(a.id) and app_private.is_enrolled(a.course_id);
    select s.status::text into v_state from submissions s
    where s.assignment_id = p_target_id and s.user_id = v_me order by s.submitted_at desc limit 1;
  end if;
  if v_course is null then raise exception 'work not found' using errcode = 'PT404'; end if;
  if p_category is null or p_category not in ('dont_understand', 'unavailable', 'technical',
       'cannot_access', 'need_clarification', 'cannot_record', 'cannot_upload', 'need_more_time', 'other') then
    raise exception 'choose what the problem is' using errcode = 'PT422';
  end if;
  if p_category = 'other' and coalesce(trim(p_message), '') = '' then
    raise exception 'describe the problem' using errcode = 'PT422';
  end if;
  if p_attachment_asset_id is not null
     and not exists (select 1 from media_assets where id = p_attachment_asset_id and uploaded_by = v_me) then
    raise exception 'attachment not found' using errcode = 'PT404';
  end if;
  -- One open report per piece of work: a second tap adds to it.
  select * into v from work_issues
  where user_id = v_me and status <> 'resolved'
    and portion_id is not distinct from v_portion and assignment_id is not distinct from v_assignment
    and (v_portion is not null or v_assignment is not null or lesson_id = v_lesson);
  if found then
    update work_issues set category = p_category,
      message = left(concat_ws(E'\n', nullif(message, ''), nullif(trim(p_message), '')), 2000),
      attachment_asset_id = coalesce(p_attachment_asset_id, attachment_asset_id),
      status = 'open', updated_at = now()
    where id = v.id returning * into v;
  else
    insert into work_issues (user_id, course_id, lesson_id, portion_id, assignment_id, category,
                             message, attachment_asset_id, work_state)
    values (v_me, v_course, v_lesson, v_portion, v_assignment, p_category,
            nullif(trim(p_message), ''), p_attachment_asset_id, v_state)
    returning * into v;
  end if;
  for t in select * from app_private.work_teachers(v_course, v_lesson, v_portion) loop
    perform app_private.notify(t, 'work_issue',
      (select display_name from users where id = v_me) || ' reported a problem',
      coalesce(nullif(trim(p_message), ''), p_category),
      jsonb_build_object('issue_id', v.id, 'course_id', v_course, 'portion_id', v_portion,
                         'lesson_id', v_lesson));
  end loop;
  return app_private.issue_json(v);
end;
$$;

-- Teacher: answer, optionally give more time, optionally resolve.
create or replace function public.respond_work_issue(
  p_issue_id uuid, p_response text, p_extension_until timestamptz default null,
  p_resolve boolean default true)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v work_issues%rowtype;
begin
  select * into v from work_issues where id = p_issue_id for update;
  if not found or not app_private.can_handle_issue(v) then
    raise exception 'problem report not found' using errcode = 'PT404';
  end if;
  if coalesce(trim(p_response), '') = '' and p_extension_until is null and not p_resolve then
    raise exception 'write an answer' using errcode = 'PT422';
  end if;
  if p_extension_until is not null and p_extension_until < now() then
    raise exception 'the new due time must be in the future' using errcode = 'PT422';
  end if;
  update work_issues set
    response = coalesce(nullif(trim(p_response), ''), response),
    responded_by = app_private.current_user_id(), responded_at = now(),
    extension_until = coalesce(p_extension_until, extension_until),
    status = case when p_resolve then 'resolved' else 'answered' end,
    resolved_by = case when p_resolve then app_private.current_user_id() end,
    resolved_at = case when p_resolve then now() end,
    updated_at = now()
  where id = v.id returning * into v;
  perform app_private.notify(v.user_id, 'issue_answered', 'Your teacher answered your problem report',
    coalesce(v.response, 'More time was given'),
    jsonb_build_object('issue_id', v.id, 'course_id', v.course_id, 'portion_id', v.portion_id,
                       'lesson_id', v.lesson_id));
  return app_private.issue_json(v);
end;
$$;

-- Learner: my reports (optionally for one piece of work).
create or replace function public.my_work_issues(p_kind text default null, p_target_id uuid default null)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.issue_json(i) from work_issues i
  where i.user_id = app_private.current_user_id()
    and (p_target_id is null
         or (p_kind = 'portion' and i.portion_id = p_target_id)
         or (p_kind = 'assignment' and i.assignment_id = p_target_id)
         or (p_kind = 'lesson' and i.lesson_id = p_target_id and i.portion_id is null
             and i.assignment_id is null))
  order by i.created_at desc
  limit 50
$$;

-- Staff: reports on the work they handle (p_status: open | answered | resolved | all).
create or replace function public.work_issues_for_me(p_status text default 'open')
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.issue_json(i) from work_issues i
  where app_private.can_handle_issue(i)
    and (p_status = 'all' or i.status = p_status
         or (p_status = 'open' and i.status in ('open', 'answered')))
  order by (i.status = 'open') desc, i.created_at desc
  limit 200
$$;

-- ---------------------------------------------------- learner policies --
create table learner_policy_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users (id) on delete cascade,
  course_id uuid references courses (id) on delete cascade,
  portion_id uuid references teaching_portions (id) on delete cascade,
  assignment_id uuid references assignments (id) on delete cascade,
  kind text not null check (kind in (
    'not_opened', 'not_submitted', 'overdue', 'escalated', 'suspended', 'inactive', 'reinstated')),
  due_at timestamptz,
  hours_late numeric,
  policy jsonb not null default '{}',
  reason text,
  created_at timestamptz not null default now(),
  last_notified_at timestamptz,
  resolved_at timestamptz,
  resolved_by uuid references users (id) on delete set null
);
-- One open event of each kind per piece of work (and per learner for inactivity).
create unique index learner_policy_events_once on learner_policy_events (
  user_id, kind, coalesce(portion_id, assignment_id, course_id, '00000000-0000-0000-0000-000000000000'))
  where resolved_at is null;
create index learner_policy_events_recent on learner_policy_events (created_at desc);
alter table learner_policy_events enable row level security;
create policy policy_events_read on learner_policy_events for select to public
  using (user_id = app_private.current_user_id()
         or app_private.has_permission('learners.view')
         or (portion_id is not null and app_private.teaches_portion(portion_id))
         or (course_id is not null and app_private.teaches(course_id, null)));
grant select on learner_policy_events to authenticated, sidra_app;
create trigger learner_policy_events_audit after insert or update on learner_policy_events
  for each row execute function app_private.audit();

-- Hours between two moments that count: weekends (if so set) and holidays
-- don't, measured in the organisation's time zone.
create or replace function app_private.counted_hours(p_from timestamptz, p_to timestamptz)
returns numeric
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_tz text := coalesce((select value from org_settings where key = 'org_time_zone'), 'UTC');
  v_weekends boolean := coalesce((select value from org_settings where key = 'policy_count_weekends'), 'true') = 'true';
  v_from timestamp := p_from at time zone v_tz;
  v_to timestamp := p_to at time zone v_tz;
begin
  if p_from is null or p_to is null or p_to <= p_from then return 0; end if;
  return coalesce((
    select sum(extract(epoch from (least(d + interval '1 day', v_to) - greatest(d, v_from))))
    from generate_series(date_trunc('day', v_from), v_to, interval '1 day') d
    where (v_weekends or extract(isodow from d) < 6)
      and not exists (select 1 from calendar_holidays h where h.day = d::date)
  ), 0) / 3600;
end;
$$;

-- One pass over all outstanding work. Idempotent: events are recorded once;
-- reminders repeat only after policy_reminder_every_hours.
create or replace function app_private.evaluate_learner_policies()
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_warn int := app_private.int_setting('policy_warn_after_hours', 24);
  v_over int := app_private.int_setting('policy_overdue_after_hours', 48);
  v_esc int := app_private.int_setting('policy_escalate_after_days', 4) * 24;
  v_susp_on boolean := coalesce((select value from org_settings where key = 'policy_auto_suspend'), 'false') = 'true';
  v_susp int := app_private.int_setting('policy_suspend_after_days', 14) * 24;
  v_grace int := app_private.int_setting('policy_grace_hours', 0);
  v_every int := app_private.int_setting('policy_reminder_every_hours', 48);
  v_inactive int := app_private.int_setting('policy_inactive_after_days', 7);
  v_policy jsonb;
  r record;
  v_late numeric;
  v_kind text;
  v_event learner_policy_events%rowtype;
  n_warned int := 0; n_overdue int := 0; n_escalated int := 0; n_suspended int := 0;
  n_skipped int := 0; n_inactive int := 0;
  t uuid;
begin
  if coalesce((select value from org_settings where key = 'policy_enabled'), 'true') <> 'true' then
    return jsonb_build_object('skipped', 'policies are switched off');
  end if;
  if (select value::timestamptz from org_settings where key = 'policy_paused_until') > now() then
    return jsonb_build_object('skipped', 'paused by an administrator');
  end if;
  update org_settings set value = now()::text where key = 'policy_last_run';
  v_policy := jsonb_build_object('warn_hours', v_warn, 'overdue_hours', v_over,
    'escalate_hours', v_esc, 'auto_suspend', v_susp_on, 'suspend_hours', v_susp,
    'grace_hours', v_grace,
    'count_weekends', (select value from org_settings where key = 'policy_count_weekends'));

  -- Outstanding portion work and assignment work, with the effective due time.
  for r in
    select pl.user_id, p.course_id, p.lesson_id, p.id as portion_id, null::uuid as assignment_id,
           p.title, pl.opened_at, pl.assigned_at,
           greatest(p.due_at, (select max(extension_until) from work_issues i
                               where i.user_id = pl.user_id and i.portion_id = p.id)) as due_at
    from portion_learners pl join teaching_portions p on p.id = pl.portion_id
    where p.due_at is not null and p.requires_submission and p.status = 'assigned'
      and pl.status in ('assigned', 'opened', 'correction_required')
    union all
    select e.user_id, a.course_id, a.lesson_id, null, a.id, a.title, null, e.enrolled_at,
           greatest(a.due_at, (select max(extension_until) from work_issues i
                               where i.user_id = e.user_id and i.assignment_id = a.id))
    from assignments a
    join course_enrolments e on e.course_id = a.course_id and e.status = 'active'
    join users u on u.id = e.user_id and u.role = 'learner' and u.is_active
    where a.due_at is not null and a.status = 'published'
      and not exists (select 1 from submissions s where s.assignment_id = a.id and s.user_id = e.user_id)
  loop
    -- Safeguards: an open problem report stops the clock; work that never
    -- reached the learner (assigned after the due time) is not late.
    if exists (select 1 from work_issues i where i.user_id = r.user_id and i.status <> 'resolved'
               and (i.portion_id = r.portion_id or i.assignment_id = r.assignment_id)) then
      n_skipped := n_skipped + 1; continue;
    end if;
    if r.assigned_at is not null and r.assigned_at > r.due_at then
      n_skipped := n_skipped + 1; continue;
    end if;
    v_late := app_private.counted_hours(r.due_at + make_interval(hours => v_grace), now());
    if v_late < v_warn then continue; end if;

    -- 1. Reminder to the learner ("not opened" vs "opened, not submitted").
    v_kind := case when r.portion_id is not null and r.opened_at is null then 'not_opened' else 'not_submitted' end;
    insert into learner_policy_events (user_id, course_id, portion_id, assignment_id, kind, due_at, hours_late, policy)
    values (r.user_id, r.course_id, r.portion_id, r.assignment_id, v_kind, r.due_at, round(v_late, 1), v_policy)
    on conflict do nothing;
    select * into v_event from learner_policy_events
    where user_id = r.user_id and kind = v_kind and resolved_at is null
      and coalesce(portion_id, assignment_id) = coalesce(r.portion_id, r.assignment_id);
    if v_event.last_notified_at is null or v_event.last_notified_at < now() - make_interval(hours => v_every) then
      perform app_private.notify(r.user_id, 'work_overdue_warning',
        case v_kind when 'not_opened' then 'You haven''t opened “' || r.title || '” yet'
                    else '“' || r.title || '” is waiting for your work' end,
        'It was due ' || to_char(r.due_at at time zone coalesce((select value from org_settings where key = 'org_time_zone'), 'UTC'), 'DD Mon HH24:MI')
          || '. If something is stopping you, tap “I have a problem”.',
        jsonb_build_object('course_id', r.course_id, 'portion_id', r.portion_id,
                           'assignment_id', r.assignment_id, 'lesson_id', r.lesson_id));
      update learner_policy_events set last_notified_at = now(), hours_late = round(v_late, 1)
      where id = v_event.id;
      n_warned := n_warned + 1;
    end if;

    -- 2. Overdue: the teachers are told once.
    if v_late >= v_over then
      insert into learner_policy_events (user_id, course_id, portion_id, assignment_id, kind, due_at, hours_late, policy)
      values (r.user_id, r.course_id, r.portion_id, r.assignment_id, 'overdue', r.due_at, round(v_late, 1), v_policy)
      on conflict do nothing
      returning * into v_event;
      if found then
        for t in select * from app_private.work_teachers(r.course_id, r.lesson_id, r.portion_id) loop
          perform app_private.notify(t, 'work_overdue',
            (select display_name from users where id = r.user_id) || ' is late with “' || r.title || '”',
            round(v_late)::text || ' hours past the due time',
            jsonb_build_object('course_id', r.course_id, 'portion_id', r.portion_id, 'learner_id', r.user_id));
        end loop;
        n_overdue := n_overdue + 1;
      end if;
    end if;

    -- 3. Escalation: administrators (learners.edit) are told once.
    if v_late >= v_esc then
      insert into learner_policy_events (user_id, course_id, portion_id, assignment_id, kind, due_at, hours_late, policy)
      values (r.user_id, r.course_id, r.portion_id, r.assignment_id, 'escalated', r.due_at, round(v_late, 1), v_policy)
      on conflict do nothing
      returning * into v_event;
      if found then
        for t in select distinct ur.user_id from user_roles ur
                 join role_permissions rp on rp.role_key = ur.role_key and rp.permission_key = 'learners.edit'
                 join users u on u.id = ur.user_id and u.is_active loop
          perform app_private.notify(t, 'work_escalated',
            (select display_name from users where id = r.user_id) || ': “' || r.title || '” still not done',
            round(v_late / 24)::text || ' days past the due time; the teacher was told earlier',
            jsonb_build_object('course_id', r.course_id, 'portion_id', r.portion_id, 'learner_id', r.user_id));
        end loop;
        n_escalated := n_escalated + 1;
      end if;
    end if;

    -- 4. Automatic suspension (off unless an administrator switched it on).
    if v_susp_on and v_late >= v_susp
       -- warned at least a day before, so the learner had a real chance
       and exists (select 1 from learner_policy_events w
                   where w.user_id = r.user_id and w.kind in ('not_opened', 'not_submitted')
                     and coalesce(w.portion_id, w.assignment_id) = coalesce(r.portion_id, r.assignment_id)
                     and w.created_at < now() - interval '1 day')
       -- no suspension already, and the enrolment is active
       and exists (select 1 from course_enrolments e where e.user_id = r.user_id
                   and e.course_id = r.course_id and e.status = 'active')
       -- the learner has used Sidra since the work was given (reachable),
       -- otherwise it's inactivity, handled separately
       and exists (select 1 from app_private.devices d where d.user_id = r.user_id
                   and d.last_contact_at > coalesce(r.assigned_at, r.due_at)) then
      update course_enrolments set status = 'suspended'
      where user_id = r.user_id and course_id = r.course_id and status = 'active';
      insert into learner_policy_events (user_id, course_id, portion_id, assignment_id, kind, due_at,
                                         hours_late, policy, reason)
      values (r.user_id, r.course_id, r.portion_id, r.assignment_id, 'suspended', r.due_at,
              round(v_late, 1), v_policy,
              format('“%s” was %s days late after reminders', r.title, round(v_late / 24)))
      on conflict do nothing;
      perform app_private.notify(r.user_id, 'learner_suspended',
        'Your place in ' || (select title from courses where id = r.course_id) || ' is paused',
        '“' || r.title || '” is ' || round(v_late / 24)::text
          || ' days late. Your work and progress are kept. Contact your teacher to continue.',
        jsonb_build_object('course_id', r.course_id, 'portion_id', r.portion_id));
      for t in select * from app_private.work_teachers(r.course_id, r.lesson_id, r.portion_id) loop
        perform app_private.notify(t, 'learner_suspended',
          (select display_name from users where id = r.user_id) || ' was suspended automatically',
          '“' || r.title || '” ' || round(v_late / 24)::text || ' days late. Reinstate from the learner''s page.',
          jsonb_build_object('course_id', r.course_id, 'learner_id', r.user_id));
      end loop;
      n_suspended := n_suspended + 1;
    end if;
  end loop;

  -- Account inactivity: an enrolled learner who hasn't used Sidra for N days.
  for r in
    select u.id as user_id, max(d.last_active_at) as last_active
    from users u
    join course_enrolments e on e.user_id = u.id and e.status = 'active'
    left join app_private.devices d on d.user_id = u.id
    where u.role = 'learner' and u.is_active and u.removed_at is null
    group by u.id
    having coalesce(max(d.last_active_at), max(e.enrolled_at)) < now() - make_interval(days => v_inactive)
  loop
    insert into learner_policy_events (user_id, kind, policy, reason)
    values (r.user_id, 'inactive', v_policy,
            case when r.last_active is null then 'not seen using Sidra yet'
                 else 'last used Sidra ' || to_char(r.last_active, 'DD Mon') end)
    on conflict do nothing
    returning * into v_event;
    if found then
      perform app_private.notify(r.user_id, 'learner_inactive', 'We miss you at Sidra',
        'Your lessons are waiting. Open Sidra to continue where you left off.', '{}');
      n_inactive := n_inactive + 1;
    end if;
  end loop;
  -- Using the app again closes the inactivity event.
  update learner_policy_events ev set resolved_at = now()
  where ev.kind = 'inactive' and ev.resolved_at is null
    and exists (select 1 from app_private.devices d where d.user_id = ev.user_id
                and d.last_active_at > ev.created_at);
  -- Work handed in (or no longer outstanding) closes its events.
  update learner_policy_events ev set resolved_at = now()
  where ev.resolved_at is null and ev.kind in ('not_opened', 'not_submitted', 'overdue', 'escalated')
    and ((ev.portion_id is not null and not exists (
            select 1 from portion_learners pl where pl.portion_id = ev.portion_id
              and pl.user_id = ev.user_id and pl.status in ('assigned', 'opened', 'correction_required')))
      or (ev.assignment_id is not null and exists (
            select 1 from submissions s where s.assignment_id = ev.assignment_id and s.user_id = ev.user_id)));
  -- Opening a portion turns "not opened" into "not submitted" next pass.
  update learner_policy_events ev set resolved_at = now()
  where ev.kind = 'not_opened' and ev.resolved_at is null
    and exists (select 1 from portion_learners pl where pl.portion_id = ev.portion_id
                and pl.user_id = ev.user_id and pl.opened_at is not null);

  return jsonb_build_object('reminded', n_warned, 'overdue', n_overdue, 'escalated', n_escalated,
                            'suspended', n_suspended, 'inactive', n_inactive, 'paused_by_reports', n_skipped);
end;
$$;

-- Runs the policies. Called by staff screens (at most every 15 minutes, so
-- it works even without the server) and by the server; admins can force it.
create or replace function public.run_learner_policies(p_force boolean default false)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_last timestamptz := (select value::timestamptz from org_settings where key = 'policy_last_run');
begin
  if app_private.current_user_id() is null then
    raise exception 'not signed in' using errcode = 'PT401';
  end if;
  if not (app_private.has_permission('teaching.review') or app_private.has_permission('learners.edit')) then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  if p_force and not app_private.has_permission('settings.manage') then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  if not p_force and v_last is not null and v_last > now() - interval '15 minutes' then
    return jsonb_build_object('skipped', 'ran recently', 'last_run', v_last);
  end if;
  return app_private.evaluate_learner_policies();
end;
$$;

-- Policy events for staff (learners.view, or the work's teachers).
create or replace function public.learner_policy_events(p_open_only boolean default true, p_user_id uuid default null)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select to_jsonb(e) || jsonb_build_object(
    'learner_name', (select display_name from users where id = e.user_id),
    'course_title', (select title from courses where id = e.course_id),
    'work_title', coalesce((select title from teaching_portions where id = e.portion_id),
                           (select title from assignments where id = e.assignment_id)))
  from learner_policy_events e
  where (not p_open_only or e.resolved_at is null)
    and (p_user_id is null or e.user_id = p_user_id)
    and (app_private.has_permission('learners.view')
         or (e.portion_id is not null and app_private.teaches_portion(e.portion_id))
         or (e.course_id is not null and app_private.teaches(e.course_id, null)))
  order by e.created_at desc
  limit 300
$$;

-- Reinstate a suspended learner (teacher of the course or learners.edit).
create or replace function public.reinstate_learner(p_user_id uuid, p_course_id uuid, p_note text default null)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not (app_private.has_permission('learners.edit') or app_private.teaches(p_course_id, null)) then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  update course_enrolments set status = 'active'
  where user_id = p_user_id and course_id = p_course_id and status = 'suspended';
  if not found then raise exception 'this learner is not suspended in this course' using errcode = 'PT409'; end if;
  update learner_policy_events set resolved_at = now(), resolved_by = app_private.current_user_id()
  where user_id = p_user_id and course_id = p_course_id and resolved_at is null;
  insert into learner_policy_events (user_id, course_id, kind, reason, resolved_at, resolved_by)
  values (p_user_id, p_course_id, 'reinstated', nullif(trim(p_note), ''), now(), app_private.current_user_id());
  perform app_private.notify(p_user_id, 'learner_reinstated',
    'You can continue ' || (select title from courses where id = p_course_id),
    coalesce(nullif(trim(p_note), ''), 'Your place in the course is open again.'),
    jsonb_build_object('course_id', p_course_id));
end;
$$;

revoke all on function public.report_work_issue(text, uuid, text, text, uuid),
  public.respond_work_issue(uuid, text, timestamptz, boolean),
  public.my_work_issues(text, uuid), public.work_issues_for_me(text),
  public.run_learner_policies(boolean), public.learner_policy_events(boolean, uuid),
  public.reinstate_learner(uuid, uuid, text) from public, anonymous;
grant execute on function public.report_work_issue(text, uuid, text, text, uuid),
  public.respond_work_issue(uuid, text, timestamptz, boolean),
  public.my_work_issues(text, uuid), public.work_issues_for_me(text),
  public.run_learner_policies(boolean), public.learner_policy_events(boolean, uuid),
  public.reinstate_learner(uuid, uuid, text) to authenticated, sidra_app;

-- ------------------------------------------------ MarzPay: keep checking --
create or replace function payments_api.to_reconcile(p_limit int default 20)
returns table (id uuid, provider_uuid text, reference uuid)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select p.id, p.provider_uuid, p.reference from payments p
  where p.method = 'marzpay' and p.provider_uuid is not null
    and p.created_at > now() - make_interval(days => app_private.int_setting('payment_unanswered_days', 7) + 1)
    and (p.status = 'processing'
         -- failed only because nobody answered for a day (the old rule)
         or (p.status = 'failed' and p.status_reason = 'no answer from MarzPay after a day'))
    -- fresh payments every few seconds, older ones every 10 minutes
    and p.updated_at < now() - case when p.created_at > now() - interval '1 hour'
                                    then interval '10 seconds' else interval '10 minutes' end
  order by p.updated_at
  limit greatest(p_limit, 1)
$$;

do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('payments_api.settle(text, text, numeric, text, jsonb, numeric)'::regprocedure);
  if position('elsif v.created_at < now() - interval ''1 day'' then' in v_src) = 0
     or position('''no answer from MarzPay after a day''' in v_src) = 0 then
    raise exception 'settle changed; update 0036';
  end if;
  v_src := replace(v_src, 'elsif v.created_at < now() - interval ''1 day'' then',
    'elsif v.created_at < now() - make_interval(days => app_private.int_setting(''payment_unanswered_days'', 7)) then');
  execute replace(v_src, '''no answer from MarzPay after a day''',
    'format(''no answer from MarzPay after %s days'', app_private.int_setting(''payment_unanswered_days'', 7))');
end $$;

select app_private.lock_down_functions();
