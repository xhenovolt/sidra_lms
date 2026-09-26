-- Phase 2D-2: people directory, person profile, unit-scoped teachers.
--
-- * admin_people(): server-paged, filtered people list with a total count.
-- * admin_person_profile(): one person's record — enrolments with progress,
--   teaching assignments, teacher reviews, quiz results, recent activity.
-- * course_staff_units: a teacher may be limited to some units of a course
--   (no rows = the whole course).
-- * Teaching actions (review, unlock, grade, change enrolment status) now
--   require teaching.review and, for teachers, an assignment covering the
--   lesson. Before this, anyone who could merely SEE all courses (e.g. a
--   Content Manager) could review, unlock and grade learners.

-- ------------------------------------------------------ teacher scope --

create table course_staff_units (
  course_id uuid not null,
  user_id uuid not null,
  unit_id uuid not null references course_units (id) on delete cascade,
  primary key (course_id, user_id, unit_id),
  foreign key (course_id, user_id) references course_staff (course_id, user_id)
    on delete cascade
);
alter table course_staff_units enable row level security;
create policy course_staff_units_read on course_staff_units for select to public
  using (app_private.is_course_staff(course_id));
grant select on course_staff_units to authenticated, sidra_app;

create trigger course_staff_units_audit after insert or update or delete
  on course_staff_units for each row execute function app_private.audit();

-- The unit a lesson belongs to: its own, or the nearest one up its sections.
create or replace function app_private.lesson_unit(p_lesson_id uuid)
returns uuid
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  with recursive up as (
    select n.id, n.parent_id, n.unit_id, 0 as depth
      from lessons l join curriculum_nodes n on n.id = l.node_id
     where l.id = p_lesson_id
    union all
    select n.id, n.parent_id, n.unit_id, up.depth + 1
      from curriculum_nodes n join up on n.id = up.parent_id
     where up.unit_id is null and up.depth < 50
  )
  select coalesce(
    (select unit_id from lessons where id = p_lesson_id),
    (select unit_id from up where unit_id is not null order by depth limit 1))
$$;

-- May the caller teach (review, unlock, grade) in this course — and, when a
-- lesson is given, that lesson? Console reviewers (teaching.review plus
-- courses.view, e.g. Admin, Academic Manager) cover every course; teachers
-- need an assignment, limited to their units when they have any.
create or replace function app_private.teaches(
  p_course_id uuid, p_lesson_id uuid default null)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.has_permission('teaching.review') and (
    app_private.has_permission('courses.view')
    or exists (
      select 1 from course_staff s join users u on u.id = s.user_id
       where s.course_id = p_course_id
         and s.user_id = app_private.current_user_id()
         and u.role in ('teacher', 'admin')
         and (not exists (select 1 from course_staff_units cu
                           where cu.course_id = s.course_id and cu.user_id = s.user_id)
              or (p_lesson_id is not null and exists (
                    select 1 from course_staff_units cu
                     where cu.course_id = s.course_id and cu.user_id = s.user_id
                       and cu.unit_id = app_private.lesson_unit(p_lesson_id))))))
$$;

grant execute on function app_private.teaches(uuid, uuid), app_private.lesson_unit(uuid)
  to authenticated, sidra_app;

create or replace function public.set_staff_units(
  p_course_id uuid, p_user_id uuid, p_unit_ids uuid[] default '{}')
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.has_permission('teachers.assign') then
    raise exception 'not allowed to assign teachers' using errcode = 'PT403';
  end if;
  if not exists (select 1 from course_staff
                  where course_id = p_course_id and user_id = p_user_id) then
    raise exception 'this person is not on the course staff' using errcode = 'PT404';
  end if;
  if exists (select 1 from unnest(coalesce(p_unit_ids, '{}')) x
              where not exists (select 1 from course_units
                                 where id = x and course_id = p_course_id)) then
    raise exception 'that unit belongs to another course' using errcode = 'PT422';
  end if;
  delete from course_staff_units
   where course_id = p_course_id and user_id = p_user_id
     and unit_id <> all (coalesce(p_unit_ids, '{}'));
  insert into course_staff_units (course_id, user_id, unit_id)
  select distinct p_course_id, p_user_id, x from unnest(coalesce(p_unit_ids, '{}')) x
  on conflict do nothing;
end;
$$;

-- --------------------------------------------- teaching actions (fix) --

create or replace function public.unlock_lesson(
  p_user_id uuid, p_lesson_id uuid, p_note text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_course uuid;
  v_unlock lesson_unlocks%rowtype;
begin
  select course_id into v_course from lessons where id = p_lesson_id;
  if v_course is null then raise exception 'lesson not found' using errcode = 'PT404'; end if;
  if not app_private.teaches(v_course, p_lesson_id) then
    raise exception 'only the course teacher can unlock lessons' using errcode = 'PT403';
  end if;
  if not exists (
    select 1 from course_enrolments
    where course_id = v_course and user_id = p_user_id and status = 'active'
  ) then
    raise exception 'learner is not actively enrolled' using errcode = 'PT409';
  end if;

  insert into lesson_unlocks (user_id, lesson_id, course_id, reason, unlocked_by, note)
  values (p_user_id, p_lesson_id, v_course,
          case when app_private.is_admin() then 'admin_override' else 'teacher_approved' end::unlock_reason,
          app_private.current_user_id(), p_note)
  on conflict (user_id, lesson_id) do update set note = coalesce(excluded.note, lesson_unlocks.note)
  returning * into v_unlock;
  return to_jsonb(v_unlock);
end;
$$;

create or replace function public.revoke_lesson_unlock(p_user_id uuid, p_lesson_id uuid)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.teaches((select course_id from lessons where id = p_lesson_id), p_lesson_id) then
    raise exception 'staff only' using errcode = 'PT403';
  end if;
  delete from lesson_unlocks where user_id = p_user_id and lesson_id = p_lesson_id;
end;
$$;

create or replace function public.review_lesson(
  p_user_id uuid,
  p_lesson_id uuid,
  p_outcome review_outcome,
  p_score numeric default null,
  p_feedback text default null,
  p_unlock_next boolean default true,
  p_feedback_audio_asset_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_course uuid;
  v_review lesson_reviews%rowtype;
  v_next uuid;
begin
  select course_id into v_course from lessons where id = p_lesson_id;
  if v_course is null then raise exception 'lesson not found' using errcode = 'PT404'; end if;
  if not app_private.teaches(v_course, p_lesson_id) then
    raise exception 'only the course teacher can review learners' using errcode = 'PT403';
  end if;

  insert into lesson_reviews (user_id, lesson_id, course_id, teacher_id, outcome,
                              score, feedback, feedback_audio_asset_id)
  values (p_user_id, p_lesson_id, v_course, app_private.current_user_id(), p_outcome,
          p_score, p_feedback, p_feedback_audio_asset_id)
  returning * into v_review;

  if p_outcome = 'passed' then
    insert into learner_progress (user_id, lesson_id, course_id, status, completed_at)
    values (p_user_id, p_lesson_id, v_course, 'completed', now())
    on conflict (user_id, lesson_id) do update
      set status = 'completed',
          completed_at = coalesce(learner_progress.completed_at, now());

    if p_unlock_next then
      v_next := app_private.next_lesson(p_lesson_id);
      if v_next is not null then
        insert into lesson_unlocks (user_id, lesson_id, course_id, reason, unlocked_by)
        values (p_user_id, v_next, v_course, 'teacher_approved', app_private.current_user_id())
        on conflict (user_id, lesson_id) do nothing;
      end if;
    end if;
  end if;

  return jsonb_build_object('review', to_jsonb(v_review), 'unlocked_lesson_id', v_next);
end;
$$;

create or replace function public.set_enrolment_status(
  p_enrolment_id uuid, p_status enrolment_status)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_enrolment course_enrolments%rowtype;
begin
  select * into v_enrolment from course_enrolments where id = p_enrolment_id;
  if not found then raise exception 'enrolment not found' using errcode = 'PT404'; end if;
  if not (app_private.has_permission('enrolments.manage')
          or app_private.teaches(v_enrolment.course_id)) then
    raise exception 'not allowed to change this enrolment' using errcode = 'PT403';
  end if;
  update course_enrolments set status = p_status,
    completed_at = case when p_status = 'completed' then now() else completed_at end
  where id = p_enrolment_id returning * into v_enrolment;
  return to_jsonb(v_enrolment);
end;
$$;

-- grade_attempt: same body as 0004, teaching check instead of visibility.
do $$
declare v_src text;
begin
  select pg_get_functiondef('public.grade_attempt(uuid, jsonb, text)'::regprocedure)
    into v_src;
  if position('app_private.is_course_staff(v_assessment.course_id)' in v_src) = 0 then
    raise exception 'grade_attempt changed unexpectedly; update 0015';
  end if;
  execute replace(v_src,
    'app_private.is_course_staff(v_assessment.course_id)',
    'app_private.teaches(v_assessment.course_id, v_assessment.lesson_id)');
end $$;

-- Teacher console list: only learners whose current lesson the caller teaches.
create or replace function public.teacher_learners(p_course_id uuid default null)
returns table (
  course_id uuid,
  user_id uuid,
  display_name text,
  email text,
  enrolment_status enrolment_status,
  current_lesson_id uuid,
  current_lesson_title text,
  current_lesson_status progress_status,
  next_lesson_id uuid,
  completed_lessons int,
  total_lessons int,
  awaiting_review boolean,
  last_activity_at timestamptz)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  with courses_in_scope as (
    select c.id from courses c
    where (p_course_id is null or c.id = p_course_id)
      and app_private.is_course_staff(c.id)
  ),
  enr as (
    select e.* from course_enrolments e
    join courses_in_scope s on s.id = e.course_id
    where e.status in ('active', 'pending')
  ),
  seq as (
    select s.id as course_id, q.lesson_id, q.seq
    from courses_in_scope s cross join lateral app_private.lesson_sequence(s.id) q
  ),
  furthest as (
    select distinct on (e.id) e.id as enrolment_id, seq.lesson_id, seq.seq
    from enr e
    join seq on seq.course_id = e.course_id
    join lesson_unlocks u on u.lesson_id = seq.lesson_id and u.user_id = e.user_id
    order by e.id, seq.seq desc
  )
  select e.course_id, e.user_id, usr.display_name, usr.email, e.status,
    f.lesson_id, l.title, p.status,
    nxt.lesson_id,
    (select count(*)::int from learner_progress lp join seq on seq.lesson_id = lp.lesson_id
       where lp.user_id = e.user_id and seq.course_id = e.course_id and lp.status = 'completed'),
    (select count(*)::int from seq where seq.course_id = e.course_id),
    (p.status is not null and nxt.lesson_id is not null),
    (select max(lp.last_accessed_at) from learner_progress lp
       where lp.user_id = e.user_id and lp.course_id = e.course_id)
  from enr e
  join users usr on usr.id = e.user_id
  left join furthest f on f.enrolment_id = e.id
  left join lessons l on l.id = f.lesson_id
  left join learner_progress p on p.user_id = e.user_id and p.lesson_id = f.lesson_id
  left join seq nxt on nxt.course_id = e.course_id and nxt.seq = f.seq + 1
  where app_private.teaches(e.course_id, coalesce(
          f.lesson_id,
          (select s1.lesson_id from seq s1 where s1.course_id = e.course_id
            order by s1.seq limit 1)))
  order by (p.status is not null and nxt.lesson_id is not null) desc,
           usr.display_name nulls last
$$;

-- Course people now carry each teacher's unit scope.
drop function public.course_people(uuid);
create function public.course_people(p_course_id uuid)
returns table (
  user_id uuid, display_name text, contact text, kind text, status text,
  enrolment_id uuid, since timestamptz, units jsonb)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select e.user_id, u.display_name, coalesce(u.phone, u.email, u.username),
         'learner', e.status::text, e.id, e.enrolled_at, null::jsonb
  from course_enrolments e join users u on u.id = e.user_id
  where e.course_id = p_course_id and app_private.is_course_staff(p_course_id)
  union all
  select s.user_id, u.display_name, coalesce(u.phone, u.email, u.username),
         'staff', s.role::text, null, s.created_at,
         (select coalesce(jsonb_agg(jsonb_build_object('id', cu.unit_id, 'title', un.title)
                                    order by un.position), '[]')
            from course_staff_units cu join course_units un on un.id = cu.unit_id
           where cu.course_id = s.course_id and cu.user_id = s.user_id)
  from course_staff s join users u on u.id = s.user_id
  where s.course_id = p_course_id and app_private.is_course_staff(p_course_id)
  order by 4 desc, 2 nulls last
$$;

-- -------------------------------------------------------- directory --

create or replace function app_private.can_view_person(p_role app_role)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case p_role
    when 'learner' then app_private.has_permission('learners.view')
    when 'teacher' then app_private.has_permission('teachers.view')
    else app_private.has_permission('admins.manage')
  end
$$;

create or replace function public.admin_people(
  p_persona app_role default null,
  p_search text default null,
  p_active boolean default null,
  p_limit int default 50,
  p_offset int default 0)
returns table (
  id uuid, display_name text, phone text, email text, username text,
  role app_role, is_superadmin boolean, is_active boolean, created_at timestamptz,
  role_key text, role_name text, total bigint)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  with q as (
    select nullif(trim(p_search), '') as term
  ), pattern as (
    select '%' || replace(replace(replace(term, '\', '\\'), '%', '\%'), '_', '\_') || '%' as p
    from q
  )
  select u.id, u.display_name, u.phone, u.email, u.username, u.role,
         u.is_superadmin, u.is_active, u.created_at, r.key, r.name,
         count(*) over ()
  from users u
  cross join pattern
  left join lateral (
    select ar.key, ar.name from user_roles ur join app_roles ar on ar.key = ur.role_key
     where ur.user_id = u.id order by ar.is_system desc, ar.key limit 1) r on true
  where (p_persona is null or u.role = p_persona)
    and app_private.can_view_person(u.role)
    and (p_active is null or u.is_active = p_active)
    and (pattern.p is null
         or u.display_name ilike pattern.p
         or u.phone ilike pattern.p
         or u.email ilike pattern.p
         or u.username ilike pattern.p)
  order by u.display_name nulls last, u.id
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0)
$$;

create or replace function public.admin_person_profile(p_user_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare v users%rowtype;
begin
  select * into v from users where id = p_user_id;
  if not found or not (app_private.can_view_person(v.role)
                       or v.id = app_private.current_user_id()) then
    raise exception 'person not found' using errcode = 'PT404';
  end if;

  return jsonb_build_object(
    'user', jsonb_build_object(
      'id', v.id, 'display_name', v.display_name, 'phone', v.phone,
      'email', v.email, 'username', v.username, 'role', v.role,
      'is_superadmin', v.is_superadmin, 'is_active', v.is_active,
      'created_at', v.created_at,
      'last_sign_in', (select max(created_at) from app_private.refresh_tokens
                        where user_id = v.id),
      'roles', (select coalesce(jsonb_agg(jsonb_build_object('key', ar.key, 'name', ar.name)
                                          order by ar.key), '[]')
                  from user_roles ur join app_roles ar on ar.key = ur.role_key
                 where ur.user_id = v.id)),
    'enrolments', (
      select coalesce(jsonb_agg(x order by x->>'enrolled_at' desc), '[]') from (
        select jsonb_build_object(
          'id', e.id, 'course_id', c.id, 'course_title', c.title,
          'status', e.status, 'source', e.source,
          'enrolled_at', e.enrolled_at, 'completed_at', e.completed_at,
          'completed_lessons', (select count(*) from learner_progress lp
                                 where lp.user_id = v.id and lp.course_id = c.id
                                   and lp.status = 'completed'),
          'total_lessons', (select count(*) from lessons l
                             where l.course_id = c.id and l.status = 'published'),
          'last_activity', (select max(last_accessed_at) from learner_progress lp
                             where lp.user_id = v.id and lp.course_id = c.id)) as x
        from course_enrolments e join courses c on c.id = e.course_id
        where e.user_id = v.id) t),
    'teaching', (
      select coalesce(jsonb_agg(x order by x->>'course_title'), '[]') from (
        select jsonb_build_object(
          'course_id', c.id, 'course_title', c.title, 'role', s.role,
          'units', (select coalesce(jsonb_agg(un.title order by un.position), '[]')
                      from course_staff_units cu join course_units un on un.id = cu.unit_id
                     where cu.course_id = s.course_id and cu.user_id = s.user_id),
          'learners', (select count(*) from course_enrolments e
                        where e.course_id = c.id and e.status = 'active')) as x
        from course_staff s join courses c on c.id = s.course_id
        where s.user_id = v.id) t),
    'reviews', (
      select coalesce(jsonb_agg(x order by x->>'created_at' desc), '[]') from (
        select jsonb_build_object(
          'lesson_title', l.title, 'course_title', c.title, 'outcome', r.outcome,
          'score', r.score, 'feedback', r.feedback, 'teacher', t.display_name,
          'created_at', r.created_at) as x
        from lesson_reviews r
        join lessons l on l.id = r.lesson_id
        join courses c on c.id = r.course_id
        left join users t on t.id = r.teacher_id
        where r.user_id = v.id
        order by r.created_at desc limit 10) t),
    'quiz_attempts', (
      select coalesce(jsonb_agg(x order by x->>'submitted_at' desc nulls last), '[]') from (
        select jsonb_build_object(
          'assessment_title', a.title, 'status', q.status, 'score', q.score,
          'max_score', q.max_score, 'passed', q.passed,
          'submitted_at', q.submitted_at) as x
        from quiz_attempts q join assessments a on a.id = q.assessment_id
        where q.user_id = v.id
        order by q.submitted_at desc nulls last limit 10) t),
    'activity', case when app_private.has_permission('audit.view') then (
      select coalesce(jsonb_agg(x order by (x->>'id')::bigint desc), '[]') from (
        select jsonb_build_object(
          'id', a.id, 'at', a.at, 'action', a.action, 'entity', a.entity,
          'actor', u.display_name, 'by_them', a.actor_id = v.id) as x
        from audit_log a left join users u on u.id = a.actor_id
        where a.actor_id = v.id or a.entity_id = v.id::text
        order by a.id desc limit 15) t) end);
end;
$$;

revoke all on function
  public.set_staff_units(uuid, uuid, uuid[]),
  public.course_people(uuid),
  public.admin_people(app_role, text, boolean, int, int),
  public.admin_person_profile(uuid)
from public;
grant execute on function
  public.set_staff_units(uuid, uuid, uuid[]),
  public.course_people(uuid),
  public.admin_people(app_role, text, boolean, int, int),
  public.admin_person_profile(uuid)
to authenticated, sidra_app;
