-- 0042 In teacher-controlled courses the teacher marks lessons, not the
-- learner: a learner hands in work, the teacher reviews it. Only courses an
-- administrator deliberately set to "open" or "in order" keep the learner's
-- own "I finished" button.
create or replace function app_private.lesson_needs_work(p_lesson_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce(l.work_required, c.progression in ('after_submission', 'after_approval', 'teacher_gated'))
  from lessons l join courses c on c.id = l.course_id
  where l.id = p_lesson_id
$$;

select app_private.lock_down_functions();
