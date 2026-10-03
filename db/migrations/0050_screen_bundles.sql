-- Phase 6, Stage 2: one call per screen instead of many.
--
-- The database is ~300 ms a round trip from Uganda and an app call takes
-- several, so a screen that makes 6-8 calls in waves waited 10 s or more.
-- These functions return what those calls returned, in one call.
--
-- SECURITY INVOKER (the default): they read the same tables with the
-- caller's rights, so Row Level Security decides exactly as it did for the
-- separate reads. No privilege changes.

-- The learner course page / home card: what CourseRepository.fetchOutline
-- read in 6-8 calls. Null when the course isn't visible to the caller.
create or replace function public.course_outline(p_course_id uuid)
returns jsonb
language sql stable
set search_path = public, pg_temp
as $$
  select case when c.id is null then null else jsonb_build_object(
    'course', to_jsonb(c),
    'units', coalesce((select jsonb_agg(to_jsonb(u) order by u.position)
                       from course_units u where u.course_id = p_course_id), '[]'),
    'nodes', coalesce((select jsonb_agg(to_jsonb(n) order by n.position)
                       from curriculum_nodes n where n.course_id = p_course_id), '[]'),
    'lessons', coalesce((select jsonb_agg(to_jsonb(l) order by l.position)
                         from lessons l where l.course_id = p_course_id), '[]'),
    'order', coalesce((select jsonb_agg(to_jsonb(o) - 'ordinality' order by o.ordinality)
                       from public.course_lesson_order(p_course_id) with ordinality o), '[]'),
    'course_books', coalesce((select jsonb_agg(to_jsonb(cb) order by cb.position)
                              from course_books cb where cb.course_id = p_course_id), '[]'),
    'books', coalesce((select jsonb_agg(to_jsonb(b))
                       from books b
                       where b.id in (select cb.book_id from course_books cb
                                      where cb.course_id = p_course_id)), '[]'),
    'levels', coalesce((select jsonb_agg(to_jsonb(s))
                        from book_structure_levels s
                        where s.id in (select n.structure_level_id from curriculum_nodes n
                                       where n.course_id = p_course_id)), '[]')
  ) end
  from (select 1) one
  left join courses c on c.id = p_course_id;
$$;

-- The admin course builder: what builderDataProvider read in 1 + 4 + 1 + one
-- call per linked book. `levels_by_book`: each linked book's default
-- structure's levels, by depth (AdminRepository.levelsForBook).
create or replace function public.course_builder_data(p_course_id uuid)
returns jsonb
language sql stable
set search_path = public, pg_temp
as $$
  select case when c.id is null then null else jsonb_build_object(
    'course', to_jsonb(c),
    'units', coalesce((select jsonb_agg(to_jsonb(u) order by u.position)
                       from course_units u where u.course_id = p_course_id), '[]'),
    'nodes', coalesce((select jsonb_agg(to_jsonb(n) order by n.position)
                       from curriculum_nodes n where n.course_id = p_course_id), '[]'),
    'lessons', coalesce((select jsonb_agg(to_jsonb(l) order by l.position)
                         from lessons l where l.course_id = p_course_id), '[]'),
    'course_books', coalesce((select jsonb_agg(to_jsonb(cb) order by cb.position)
                              from course_books cb where cb.course_id = p_course_id), '[]'),
    'books', coalesce((select jsonb_agg(to_jsonb(b) order by b.title) from books b), '[]'),
    'levels_by_book', coalesce((
      select jsonb_object_agg(cb.book_id, coalesce((
               select jsonb_agg(to_jsonb(lv) order by lv.depth)
               from book_structure_levels lv
               where lv.structure_id = (select s.id from book_structures s
                                        where s.book_id = cb.book_id
                                        order by s.is_default desc limit 1)), '[]'))
      from (select distinct book_id from course_books where course_id = p_course_id) cb), '{}')
  ) end
  from (select 1) one
  left join courses c on c.id = p_course_id;
$$;

select app_private.lock_down_functions();
