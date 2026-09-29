-- 0038 Dashboard: numbers you can open, and learners one by one.
--
-- Every dashboard number now comes from the same query as the list behind
-- it (public.dashboard_list), so "Active learners: 12" always opens exactly
-- those 12 people. "Enrolments" is split into people and places:
--   learners_in_courses  learners with at least one active course (people)
--   course_places        active course places (one learner in 3 courses = 3)
-- public.learners_at_a_glance: one row per learner — courses, progress,
-- last use of Sidra, late work and open problem reports.

-- The rows behind each number. p_kind is one of the dashboard numbers.
create or replace function app_private.dashboard_rows(p_kind text)
returns table (title text, subtitle text, user_id uuid, course_id uuid, at timestamptz)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  -- people by role
  select u.display_name, coalesce(u.phone, u.email, u.username), u.id, null::uuid, u.created_at
  from users u
  where p_kind in ('learners', 'teachers', 'admins') and u.is_active and u.removed_at is null
    and u.role::text = case p_kind when 'learners' then 'learner' when 'teachers' then 'teacher' else 'admin' end
  union all
  -- courses by status
  select c.title, c.subject, null, c.id, c.updated_at
  from courses c
  where p_kind in ('courses_published', 'courses_draft', 'courses_in_review')
    and c.status::text = case p_kind when 'courses_published' then 'published'
                                     when 'courses_draft' then 'draft' else 'in_review' end
  union all
  -- learners with at least one active course (people, counted once)
  select u.display_name, string_agg(c.title, ', ' order by c.title), u.id, null, max(e.enrolled_at)
  from course_enrolments e
  join users u on u.id = e.user_id and u.role = 'learner' and u.is_active and u.removed_at is null
  join courses c on c.id = e.course_id
  where p_kind = 'learners_in_courses' and e.status = 'active'
  group by u.id, u.display_name
  union all
  -- course places (a learner in 3 courses = 3 rows)
  select u.display_name, c.title, u.id, c.id, e.enrolled_at
  from course_enrolments e
  join users u on u.id = e.user_id and u.role = 'learner' and u.is_active and u.removed_at is null
  join courses c on c.id = e.course_id
  where p_kind = 'course_places' and e.status = 'active'
  union all
  -- learners who used Sidra in the last 7 days (opened a lesson or the app)
  select u.display_name, null, u.id, null, a.last_at
  from users u
  join lateral (
    select greatest(
      (select max(p.last_accessed_at) from learner_progress p where p.user_id = u.id),
      (select max(d.last_active_at) from app_private.devices d where d.user_id = u.id)) as last_at
  ) a on a.last_at > now() - interval '7 days'
  where p_kind = 'active_learners_7d' and u.role = 'learner' and u.is_active and u.removed_at is null
  union all
  -- lessons completed in the last 7 days: who, which lesson, when
  select u.display_name, l.title || ' · ' || c.title, u.id, c.id, p.completed_at
  from learner_progress p
  join users u on u.id = p.user_id and u.removed_at is null
  join lessons l on l.id = p.lesson_id
  join courses c on c.id = p.course_id
  where p_kind = 'lessons_completed_7d' and p.completed_at > now() - interval '7 days'
$$;

create or replace function public.admin_overview()
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case when not app_private.has_permission('dashboard.view') then null else
    (select jsonb_object_agg(k, (select count(*) from app_private.dashboard_rows(k)))
     from unnest(array['learners', 'teachers', 'admins', 'courses_published', 'courses_draft',
                       'courses_in_review', 'learners_in_courses', 'course_places',
                       'active_learners_7d', 'lessons_completed_7d']) k)
    || jsonb_build_object(
      -- older app versions read these
      'active_enrolments', (select count(*) from app_private.dashboard_rows('course_places')),
      'disabled', (select count(*) from users where not is_active and removed_at is null))
  end
$$;

-- The list behind one dashboard number, newest first.
create or replace function public.dashboard_list(p_kind text)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.has_permission('dashboard.view') then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  return query
    select jsonb_build_object('title', r.title, 'subtitle', r.subtitle, 'user_id', r.user_id,
                              'course_id', r.course_id, 'at', r.at)
    from app_private.dashboard_rows(p_kind) r
    order by r.at desc nulls last, r.title
    limit 500;
end;
$$;

-- One row per learner: what an administrator needs to know about each.
create or replace function public.learners_at_a_glance(p_search text default null, p_limit int default 100)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.has_permission('learners.view') then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  return query
    select jsonb_build_object(
      'user_id', u.id, 'display_name', u.display_name, 'avatar_url', u.avatar_url,
      'courses', (select coalesce(jsonb_agg(jsonb_build_object(
                    'title', c.title,
                    'done', (select count(*) from learner_progress p where p.user_id = u.id
                             and p.course_id = c.id and p.status = 'completed'),
                    'total', (select count(*) from lessons l where l.course_id = c.id
                              and l.status = 'published'))
                   order by c.title), '[]')
                  from course_enrolments e join courses c on c.id = e.course_id
                  where e.user_id = u.id and e.status = 'active'),
      'last_used', greatest(
         (select max(p.last_accessed_at) from learner_progress p where p.user_id = u.id),
         (select max(d.last_active_at) from app_private.devices d where d.user_id = u.id)),
      'late_work', (select count(*) from learner_policy_events ev where ev.user_id = u.id
                    and ev.resolved_at is null and ev.kind in ('not_opened', 'not_submitted', 'overdue', 'escalated')),
      'suspended', exists (select 1 from course_enrolments e where e.user_id = u.id and e.status = 'suspended'),
      'open_reports', (select count(*) from work_issues i where i.user_id = u.id and i.status <> 'resolved'))
    from users u
    where u.role = 'learner' and u.is_active and u.removed_at is null
      and (p_search is null or u.display_name ilike '%' || p_search || '%')
    order by u.display_name
    limit least(greatest(p_limit, 1), 500);
end;
$$;

revoke all on function public.dashboard_list(text), public.learners_at_a_glance(text, int) from public, anonymous;
grant execute on function public.dashboard_list(text), public.learners_at_a_glance(text, int)
  to authenticated, sidra_app;

select app_private.lock_down_functions();
