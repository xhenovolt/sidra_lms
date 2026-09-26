-- People directory, person profile and unit-scoped teachers (0015).
-- Uses the access_test fixtures (admin_1, teacher_2, learner_b).

-- Course with two units; lesson 2 sits in a section nested under unit 2.
select set_config('t.teacher3', app_private.create_account('Scoped Teacher', null, null,
  'scoped_teacher', 'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('t.teacher3')::uuid, 'teacher');

insert into courses (id, slug, title, subject, progression, status) values
  ('00000000-0000-0000-0000-00000000d001', 'scoped', 'Scoped course', 'Quran',
   'teacher_gated', 'published');
insert into course_units (id, course_id, title, position, status) values
  ('00000000-0000-0000-0000-00000000d0a1', '00000000-0000-0000-0000-00000000d001', 'Unit one', 0, 'published'),
  ('00000000-0000-0000-0000-00000000d0a2', '00000000-0000-0000-0000-00000000d001', 'Unit two', 1, 'published');
insert into curriculum_nodes (id, course_id, unit_id, parent_id, title, position, status) values
  ('00000000-0000-0000-0000-00000000d0b1', '00000000-0000-0000-0000-00000000d001',
   '00000000-0000-0000-0000-00000000d0a2', null, 'Surah', 0, 'published'),
  ('00000000-0000-0000-0000-00000000d0b2', '00000000-0000-0000-0000-00000000d001',
   null, '00000000-0000-0000-0000-00000000d0b1', 'Verses', 0, 'published');
insert into lessons (id, course_id, unit_id, node_id, title, position, status) values
  ('00000000-0000-0000-0000-00000000d0c1', '00000000-0000-0000-0000-00000000d001',
   '00000000-0000-0000-0000-00000000d0a1', null, 'Letters', 0, 'published'),
  ('00000000-0000-0000-0000-00000000d0c2', '00000000-0000-0000-0000-00000000d001',
   null, '00000000-0000-0000-0000-00000000d0b2', 'Verse 1', 0, 'published');
insert into course_enrolments (course_id, user_id, status, source) values
  ('00000000-0000-0000-0000-00000000d001', '00000000-0000-0000-0000-0000000000b1', 'active', 'admin_grant');
insert into course_staff (course_id, user_id, role) values
  ('00000000-0000-0000-0000-00000000d001', current_setting('t.teacher3')::uuid, 'teacher');

select pg_temp.check(app_private.lesson_unit('00000000-0000-0000-0000-00000000d0c2')
                     = '00000000-0000-0000-0000-00000000d0a2',
  'a lesson in a nested section belongs to its ancestor''s unit');

select set_config('t.content2', app_private.create_account('Content Two', null, null,
  'content_two', 'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key)
values (current_setting('t.content2')::uuid, 'content_manager');

-- ------------------------------------------ admin limits the teacher --
select pg_temp.login_as('admin_1');
set local role authenticated;
select public.set_staff_units('00000000-0000-0000-0000-00000000d001',
  current_setting('t.teacher3')::uuid, array['00000000-0000-0000-0000-00000000d0a1']::uuid[]);
select pg_temp.expect_error($q$select public.set_staff_units('00000000-0000-0000-0000-00000000d001',
  current_setting('t.teacher3')::uuid, array['00000000-0000-0000-0000-00000000d0a1',
  (select id from course_units where course_id <> '00000000-0000-0000-0000-00000000d001' limit 1)]::uuid[])$q$,
  'another course');
select pg_temp.check((select units->0->>'title' from public.course_people('00000000-0000-0000-0000-00000000d001')
                      where kind = 'staff') = 'Unit one',
  'course people show the teacher''s units');
reset role;

-- ------------------------------------------------- scoped teacher --
select pg_temp.login_as_id(current_setting('t.teacher3')::uuid);
set local role authenticated;
select pg_temp.check(exists (select 1 from public.teacher_learners('00000000-0000-0000-0000-00000000d001')
                             where user_id = '00000000-0000-0000-0000-0000000000b1'),
  'scoped teacher sees a learner working in their unit');
select pg_temp.expect_error($q$select public.set_staff_units('00000000-0000-0000-0000-00000000d001',
  current_setting('t.teacher3')::uuid, '{}')$q$, 'not allowed to assign');
select pg_temp.expect_error($q$select public.review_lesson('00000000-0000-0000-0000-0000000000b1',
  '00000000-0000-0000-0000-00000000d0c2', 'passed')$q$, 'only the course teacher');
select public.review_lesson('00000000-0000-0000-0000-0000000000b1',
  '00000000-0000-0000-0000-00000000d0c1', 'passed');
select pg_temp.check(not exists (select 1 from public.teacher_learners('00000000-0000-0000-0000-00000000d001')
                                 where user_id = '00000000-0000-0000-0000-0000000000b1'),
  'once the learner moves to unit two, it is no longer this teacher''s learner');
select pg_temp.expect_error($q$select public.admin_person_profile('00000000-0000-0000-0000-0000000000b1')$q$,
  'person not found');
reset role;

-- ------------------------------------ content manager cannot teach --
select pg_temp.login_as_id(current_setting('t.content2')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.review_lesson('00000000-0000-0000-0000-0000000000b1',
  '00000000-0000-0000-0000-00000000d0c2', 'passed')$q$, 'only the course teacher');
select pg_temp.expect_error($q$select public.unlock_lesson('00000000-0000-0000-0000-0000000000b1',
  '00000000-0000-0000-0000-00000000d0c2')$q$, 'only the course teacher');
select pg_temp.expect_error($q$select public.set_enrolment_status(
  (select id from course_enrolments where course_id = '00000000-0000-0000-0000-00000000d001' limit 1),
  'suspended')$q$, 'not allowed to change this enrolment');
select pg_temp.check(not exists (select 1 from public.teacher_learners()),
  'content managers have no learners to review');
reset role;

-- ------------------------------------------------------- directory --
select pg_temp.login_as('admin_1');
set local role authenticated;
select pg_temp.check((select count(*) from public.admin_people('learner', p_limit => 1)) = 1
                     and (select total from public.admin_people('learner', p_limit => 1)) >= 2,
  'pages carry the total count');
select pg_temp.check(exists (select 1 from public.admin_people('learner', 'bila')
                             where display_name = 'Bilal'),
  'search is case-insensitive');
select pg_temp.check(not exists (select 1 from public.admin_people(null, '%')),
  'search wildcards are literal');
select pg_temp.check(not exists (select 1 from public.admin_people('admin')),
  'admins without admins.manage do not list administrators');
select pg_temp.check((select role_key from public.admin_people('teacher', 'Scoped Teacher')) = 'teacher',
  'rows carry the role');

select set_config('t.profile', public.admin_person_profile('00000000-0000-0000-0000-0000000000b1')::text, true);
select pg_temp.check(exists (select 1 from jsonb_array_elements(current_setting('t.profile')::jsonb->'enrolments') e
                             where e->>'course_title' = 'Scoped course'
                               and (e->>'completed_lessons')::int = 1
                               and (e->>'total_lessons')::int = 2),
  'profile shows enrolments with progress');
select pg_temp.check(jsonb_array_length(current_setting('t.profile')::jsonb->'reviews') >= 1,
  'profile shows teacher reviews');
select pg_temp.check(jsonb_typeof(current_setting('t.profile')::jsonb->'activity') = 'array',
  'audit viewers see activity');
select pg_temp.check((public.admin_person_profile(current_setting('t.teacher3')::uuid)
                      ->'teaching'->0->'units'->>0) = 'Unit one',
  'teacher profile shows assignments and units');
reset role;

select 'ALL PEOPLE SCOPE TESTS PASSED' as result;
