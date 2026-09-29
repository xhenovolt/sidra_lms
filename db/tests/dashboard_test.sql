-- Dashboard (0038): every number equals the list it opens; people vs places.
select pg_temp.login_as('admin_1');
set local role authenticated;

select pg_temp.check(
  (select bool_and((public.admin_overview()->>k)::int
                   = (select count(*) from public.dashboard_list(k)))
   from unnest(array['learners', 'teachers', 'admins', 'courses_published', 'courses_draft',
                     'courses_in_review', 'learners_in_courses', 'course_places',
                     'active_learners_7d', 'lessons_completed_7d']) k),
  'each number is exactly the length of its list');
select pg_temp.check((public.admin_overview()->>'learners_in_courses')::int
                     <= (public.admin_overview()->>'course_places')::int,
  'people in courses never exceed course places');
select pg_temp.check((public.admin_overview()->>'active_enrolments')
                     = (public.admin_overview()->>'course_places'),
  'older apps still get their number');
select pg_temp.check(not exists (select 1 from public.dashboard_list('lessons_completed_7d') j
                                 where j->>'title' is null or j->>'subtitle' is null),
  'completed lessons say who and which lesson');
select pg_temp.check((select count(*) from public.learners_at_a_glance())
                     = (public.admin_overview()->>'learners')::int
                     or (public.admin_overview()->>'learners')::int > 100,
  'one row per learner');
reset role;

select pg_temp.login_as('learner_a');
set local role authenticated;
select pg_temp.check(public.admin_overview() is null, 'learners get no dashboard');
select pg_temp.expect_error($q$select public.dashboard_list('learners')$q$, 'not allowed');
select pg_temp.expect_error($q$select public.learners_at_a_glance()$q$, 'not allowed');
reset role;
