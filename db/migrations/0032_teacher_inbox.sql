-- One inbox for teachers: every piece of work waiting for them, whatever
-- its kind, oldest first — daily-portion recordings, lesson work (course
-- rules) and assignment hand-ins.

create or replace function public.teacher_inbox(p_limit int default 200)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select j from (
    -- lesson work
    select jsonb_build_object(
      'type', 'lesson_work', 'id', s.id, 'submitted_at', s.submitted_at, 'attempt', s.attempt,
      'learner', u.display_name, 'avatar_url', u.avatar_url, 'user_id', s.user_id,
      'title', l.title, 'context', c.title,
      'has_audio', exists (select 1 from submission_files f join media_assets m on m.id = f.media_asset_id
                           where f.submission_id = s.id and m.kind = 'audio')) j,
      s.submitted_at at
    from submissions s
    join users u on u.id = s.user_id
    join lessons l on l.id = s.lesson_id
    join courses c on c.id = s.course_id
    where s.assignment_id is null and s.portion_id is null
      and s.status in ('submitted', 'received', 'under_review')
      and app_private.teaches(s.course_id, s.lesson_id)
    union all
    -- daily portions
    select jsonb_build_object(
      'type', 'portion', 'id', s.id, 'portion_id', s.portion_id, 'submitted_at', s.submitted_at,
      'attempt', s.attempt, 'learner', u.display_name, 'avatar_url', u.avatar_url,
      'user_id', s.user_id, 'title', p.title,
      'context', coalesce((select name from teaching_groups g where g.id = p.group_id), c.title),
      'has_audio', true),
      s.submitted_at
    from submissions s
    join users u on u.id = s.user_id
    join teaching_portions p on p.id = s.portion_id
    join courses c on c.id = s.course_id
    where s.portion_id is not null
      and s.status in ('submitted', 'received', 'under_review')
      and app_private.teaches_portion(s.portion_id)
    union all
    -- assignments
    select jsonb_build_object(
      'type', 'assignment', 'id', s.id, 'submitted_at', s.submitted_at, 'attempt', s.attempt,
      'learner', u.display_name, 'avatar_url', u.avatar_url, 'user_id', s.user_id,
      'title', a.title, 'context', c.title, 'has_audio', false),
      s.submitted_at
    from submissions s
    join users u on u.id = s.user_id
    join assignments a on a.id = s.assignment_id
    join courses c on c.id = s.course_id
    where s.assignment_id is not null
      and s.status in ('submitted', 'received', 'under_review')
      and app_private.teaches(s.course_id, s.lesson_id)
  ) x
  order by at
  limit least(greatest(coalesce(p_limit, 200), 1), 500)
$$;
revoke all on function public.teacher_inbox(int) from public;
grant execute on function public.teacher_inbox(int) to authenticated, sidra_app;
