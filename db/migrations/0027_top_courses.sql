-- Top courses for the catalogue carousel: ranked by how many learners are
-- actually enrolled (active or completed). Only published courses listed in
-- the catalogue; returns counts only, never who is enrolled.

create or replace function public.top_courses(p_limit int default 8)
returns table (course_id uuid, enrolled bigint)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select c.id, count(e.id) as enrolled
  from courses c
  join course_enrolments e on e.course_id = c.id and e.status in ('active', 'completed')
  join users u on u.id = e.user_id and u.removed_at is null
  where c.status = 'published' and c.visibility = 'catalogue'
  group by c.id
  order by count(e.id) desc, max(e.enrolled_at) desc
  limit least(greatest(coalesce(p_limit, 8), 1), 20)
$$;
revoke all on function public.top_courses(int) from public;
grant execute on function public.top_courses(int) to anonymous, authenticated, sidra_app;

-- Privacy: a learner sees the teachers of THEIR courses, not every teacher
-- in the institution (previously anyone on any course's staff was visible
-- to every signed-in user).
drop policy users_read on users;
create policy users_read on users for select to public using (
  id = app_private.current_user_id()
  or app_private.has_permission('learners.view')
  or app_private.has_permission('teachers.view')
  or exists (select 1 from course_enrolments e
             where e.user_id = users.id and app_private.is_course_staff(e.course_id))
  or exists (select 1 from course_staff s
             where s.user_id = users.id
               and (app_private.is_enrolled(s.course_id) or app_private.is_course_staff(s.course_id)))
);
