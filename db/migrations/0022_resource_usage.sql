-- Content library: where each resource is used (so staff can move it,
-- hide it in one place, or remove it from one place).

create or replace function public.resource_usages(p_resource_id uuid)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select * from (
    select jsonb_build_object(
      'link_id', k.id, 'kind', 'link', 'status', k.status,
      'target', case when k.course_id is not null then 'course'
                     when k.unit_id is not null then 'unit'
                     when k.node_id is not null then 'section'
                     when k.lesson_id is not null then 'lesson'
                     when k.assignment_id is not null then 'assignment'
                     else 'book' end,
      'title', coalesce((select title from courses where id = k.course_id),
                        (select title from course_units where id = k.unit_id),
                        (select title from curriculum_nodes where id = k.node_id),
                        (select title from lessons where id = k.lesson_id),
                        (select title from assignments where id = k.assignment_id),
                        (select title from books where id = k.book_id)),
      'course_id', app_private.link_course(k),
      'course_title', (select title from courses where id = app_private.link_course(k))) j
    from resource_links k
    where k.resource_id = p_resource_id
    union all
    select jsonb_build_object(
      'portion_resource_id', pr.id, 'kind', 'portion', 'status', p.status,
      'target', 'portion', 'role', pr.role, 'title', p.title,
      'course_id', p.course_id,
      'course_title', (select title from courses where id = p.course_id),
      'group', (select name from teaching_groups where id = p.group_id))
    from portion_resources pr join teaching_portions p on p.id = pr.portion_id
    where pr.resource_id = p_resource_id
  ) x
  where app_private.has_permission('content.upload') or app_private.has_permission('courses.view')
$$;
revoke all on function public.resource_usages(uuid) from public;
grant execute on function public.resource_usages(uuid) to authenticated, sidra_app;
