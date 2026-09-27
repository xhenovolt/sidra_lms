-- Admin reports: course completion, learner activity, teacher activity.
-- Every figure answers an operational question (see the app's labels).

create or replace function public.admin_reports(p_days int default 30)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  with period as (
    select now() - make_interval(days => least(greatest(coalesce(p_days, 30), 1), 365)) as since
  ),
  activity as (   -- last learning activity per learner and course
    select user_id, course_id, max(greatest(last_accessed_at, updated_at, completed_at)) as at
    from learner_progress group by user_id, course_id
    union all
    select user_id, course_id, max(submitted_at) from submissions group by user_id, course_id
  ),
  last_act as (
    select user_id, course_id, max(at) as at from activity group by user_id, course_id
  ),
  enrolled as (
    select e.*, u.display_name,
           (select count(*) from lessons l where l.course_id = e.course_id and l.status = 'published') as total,
           (select count(*) from learner_progress p where p.user_id = e.user_id
              and p.course_id = e.course_id and p.status = 'completed') as done,
           la.at as last_activity
    from course_enrolments e
    join users u on u.id = e.user_id and u.removed_at is null
    left join last_act la on la.user_id = e.user_id and la.course_id = e.course_id
    where e.status in ('active', 'completed')
  ),
  reviews as (   -- every teacher verdict, both review systems
    select r.reviewer_id as teacher_id, r.created_at, s.submitted_at
    from submission_reviews r join submissions s on s.id = r.submission_id
    union all
    select teacher_id, created_at, null from lesson_reviews
  )
  select case when not (app_private.has_permission('reports.view')
                        or app_private.has_permission('courses.view')) then null
  else jsonb_build_object(
    'days', p_days,
    'totals', jsonb_build_object(
      'learners', (select count(*) from users where role = 'learner' and is_active and removed_at is null),
      'active', (select count(distinct user_id) from last_act, period where at >= period.since),
      'new', (select count(*) from users, period where role = 'learner' and removed_at is null
              and created_at >= period.since),
      'completions', (select count(*) from enrolled, period
                      where (status = 'completed' and completed_at >= period.since))),
    'courses', (select coalesce(jsonb_agg(x order by x->>'title'), '[]') from (
      select jsonb_build_object(
        'id', c.id, 'title', c.title, 'status', c.status,
        'enrolled', count(e.id),
        'completed', count(e.id) filter (where e.status = 'completed' or (e.total > 0 and e.done >= e.total)),
        'avg_progress', round(avg(case when e.total > 0 then 100.0 * least(e.done, e.total) / e.total end)),
        'active', count(e.id) filter (where e.last_activity >= (select since from period)),
        'stalled', count(e.id) filter (where e.status = 'active'
                                        and (e.last_activity is null or e.last_activity < (select since from period))
                                        and not (e.total > 0 and e.done >= e.total))) x
      from courses c left join enrolled e on e.course_id = c.id
      where c.status <> 'archived'
      group by c.id, c.title, c.status) t),
    'inactive_learners', (select coalesce(jsonb_agg(x), '[]') from (
      select jsonb_build_object('user_id', e.user_id, 'name', e.display_name,
               'course', (select title from courses where id = e.course_id),
               'last_activity', e.last_activity, 'progress',
               case when e.total > 0 then round(100.0 * least(e.done, e.total) / e.total) end) x
      from enrolled e, period
      where e.status = 'active' and not (e.total > 0 and e.done >= e.total)
        and (e.last_activity is null or e.last_activity < period.since)
      order by e.last_activity nulls first
      limit 50) t),
    'teachers', (select coalesce(jsonb_agg(x order by (x->>'reviews')::int desc, x->>'name'), '[]') from (
      select jsonb_build_object(
        'user_id', u.id, 'name', u.display_name,
        'reviews', (select count(*) from reviews r, period
                    where r.teacher_id = u.id and r.created_at >= period.since),
        'avg_review_hours', (select round(avg(extract(epoch from r.created_at - r.submitted_at) / 3600)::numeric, 1)
                             from reviews r, period
                             where r.teacher_id = u.id and r.submitted_at is not null
                               and r.created_at >= period.since),
        'waiting', (select count(*) from portion_learners pl
                    join teaching_portions p on p.id = pl.portion_id
                    where pl.status in ('submitted', 'under_review')
                      and u.id in (select * from app_private.portion_teachers(p.id))),
        'courses', (select count(*) from course_staff s where s.user_id = u.id),
        'last_sign_in', (select max(created_at) from app_private.refresh_tokens where user_id = u.id)) x
      from users u
      where u.is_active and u.removed_at is null
        and (u.role = 'teacher' or exists (select 1 from course_staff s where s.user_id = u.id))) t))
  end
$$;
revoke all on function public.admin_reports(int) from public;
grant execute on function public.admin_reports(int) to authenticated, sidra_app;
