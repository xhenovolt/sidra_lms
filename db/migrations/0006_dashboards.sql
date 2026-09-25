-- 0006 read models for the learner dashboard and the teacher console.
--
-- Progress rule (documented): course progress = completed LIVE lessons /
-- LIVE lessons, where live means published all the way up the tree
-- (app_private.lesson_sequence). Draft/archived lessons never count.

create or replace function public.my_courses()
returns table (
  course_id uuid,
  enrolment_id uuid,
  enrolment_status enrolment_status,
  total_lessons int,
  completed_lessons int,
  unlocked_lessons int,
  progress_percent int,
  next_lesson_id uuid,
  last_lesson_id uuid,
  last_accessed_at timestamptz)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  with me as (select app_private.current_user_id() as id),
  enr as (
    select e.* from course_enrolments e, me
    where e.user_id = me.id and e.status in ('active', 'completed', 'pending')
  ),
  seq as (
    select e.course_id, s.lesson_id, s.seq
    from enr e cross join lateral app_private.lesson_sequence(e.course_id) s
  ),
  stats as (
    select seq.course_id,
      count(*)::int as total,
      count(*) filter (where p.status = 'completed')::int as completed,
      count(*) filter (where u.id is not null or l.is_preview or c.progression = 'open')::int as unlocked,
      -- first unlocked-but-not-completed lesson in order
      (array_agg(seq.lesson_id order by seq.seq) filter (
         where (u.id is not null or l.is_preview or c.progression = 'open')
           and p.status is distinct from 'completed'))[1] as next_lesson
    from seq
    join lessons l on l.id = seq.lesson_id
    join courses c on c.id = seq.course_id
    cross join me
    left join learner_progress p on p.lesson_id = seq.lesson_id and p.user_id = me.id
    left join lesson_unlocks u on u.lesson_id = seq.lesson_id and u.user_id = me.id
    group by seq.course_id
  ),
  last_access as (
    select distinct on (p.course_id) p.course_id, p.lesson_id, p.last_accessed_at
    from learner_progress p, me
    where p.user_id = me.id
    order by p.course_id, p.last_accessed_at desc
  )
  select e.course_id, e.id, e.status,
    coalesce(s.total, 0), coalesce(s.completed, 0), coalesce(s.unlocked, 0),
    case when coalesce(s.total, 0) = 0 then 0
         else (s.completed * 100 / s.total) end,
    s.next_lesson, la.lesson_id, la.last_accessed_at
  from enr e
  left join stats s on s.course_id = e.course_id
  left join last_access la on la.course_id = e.course_id
  order by la.last_accessed_at desc nulls last, e.enrolled_at desc
$$;

-- Teacher console: each active learner in the caller's courses with their
-- position in the sequence. `awaiting_review` = the learner completed or
-- opened their furthest unlocked lesson and the next one is still locked.
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
  order by (p.status is not null and nxt.lesson_id is not null) desc,
           usr.display_name nulls last
$$;

grant execute on function
  public.my_courses(),
  public.teacher_learners(uuid)
to authenticated;
