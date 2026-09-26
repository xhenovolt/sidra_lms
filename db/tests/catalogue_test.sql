-- Phase 3 acceptance: the seeded Qur'an catalogue (0019).

select set_config('t.before', app_private.seed_quran_catalogue()::text, true);
select pg_temp.check((current_setting('t.before')::jsonb->>'courses')::int = 5, 'five courses seeded');
select pg_temp.check(app_private.seed_quran_catalogue() = current_setting('t.before')::jsonb,
  'seeding again creates nothing (idempotent)');
select pg_temp.check((select count(*) from courses where slug like 'quran-yassarna-%') = 3
                     and (select count(distinct id) from courses where slug like 'quran-yassarna-%') = 3,
  'Beginner, Intermediate and Advanced are separate courses');

-- Every lesson has a real outcome and is flagged for review; statuses safe.
select pg_temp.check(not exists (select 1 from lessons where metadata->>'seed' = 'quran-catalogue-v1'
                                 and (cardinality(objectives) = 0 or objectives[1] ilike 'understand lesson%')),
  'every seeded lesson has a meaningful outcome');
select pg_temp.check(not exists (select 1 from lessons where metadata->>'seed' = 'quran-catalogue-v1'
                                 and coalesce((metadata->>'provisional')::boolean, false) = false),
  'every seeded lesson is marked provisional');
select pg_temp.check(not exists (select 1 from courses where metadata->>'seed' = 'quran-catalogue-v1'
                                 and (status <> 'in_review' or access <> 'restricted' or self_enrol)),
  'seeded courses wait for review and are by invitation');
select pg_temp.check(not exists (select 1 from courses where metadata->>'seed' = 'quran-catalogue-v1'
                                 and (language <> 'en' or track_key is null)),
  'every course has a delivery language and a learning track');
select pg_temp.check((select count(distinct track_key) from courses
                      where metadata->>'seed' = 'quran-catalogue-v1') = 4,
  'reading, recitation, tajwīd and Qur''anic Arabic are distinct tracks');
select pg_temp.check(not exists (
  select 1 from lesson_content_blocks b join lessons l on l.id = b.lesson_id
  where l.metadata->>'seed' = 'quran-catalogue-v1' and b.block_type = 'quran_text'
    and b.language <> 'ar'), 'Arabic blocks are Arabic inside English-taught lessons');
select pg_temp.check((select array_agg(surah_number order by surah_number) from curriculum_nodes n
                      join courses c on c.id = n.course_id
                      where c.slug = 'quran-recitation-introduction') = array[1, 112, 113, 114],
  'recitation course is organised Sūrah → āyāt');
select pg_temp.check((select count(*) from course_prerequisites p join courses c on c.id = p.course_id
                      where c.metadata->>'seed' = 'quran-catalogue-v1') = 4, 'prerequisites seeded');
select pg_temp.check(exists (select 1 from assessments a join lessons l on l.id = a.lesson_id
                             where l.metadata->>'seed' = 'quran-catalogue-v1' and a.grading = 'teacher'),
  'teacher-assessed recitation exists');

-- ------------------------------------------------ learners A and B --
select set_config('t.cla', app_private.create_account('Catalogue A', null, null, 'cat_a',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('t.clb', app_private.create_account('Catalogue B', null, null, 'cat_b',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('t.beg', (select id::text from courses where slug = 'quran-yassarna-beginner'), true);

select pg_temp.login_as_id(current_setting('t.clb')::uuid);
set local role authenticated;
select pg_temp.check(not exists (select 1 from courses where metadata->>'seed' = 'quran-catalogue-v1'),
  'unreviewed courses are invisible to learners');
reset role;

-- The admin reviews, publishes, and enrols learner A only.
select pg_temp.login_as('admin_1');
set local role authenticated;
select public.set_course_status(current_setting('t.beg')::uuid, 'published');
select public.bulk_enrol(current_setting('t.beg')::uuid, array[current_setting('t.cla')::uuid]);

-- TEST 2: add a lesson to Stage 3 and it lands in sequence there.
insert into lessons (id, course_id, unit_id, title, position, status, objectives)
values ('00000000-0000-0000-0000-0000000fa001', current_setting('t.beg')::uuid,
        app_private.seed_id('unit:quran-yassarna-beginner:2'),
        'Reading letters with short vowels', 4, 'published',
        array['The learner reads letters carrying any short vowel accurately.']);
select pg_temp.check(
  (select s.seq from public.course_lesson_order(current_setting('t.beg')::uuid) s
   where s.lesson_id = '00000000-0000-0000-0000-0000000fa001')
  = 1 + (select s.seq from public.course_lesson_order(current_setting('t.beg')::uuid) s
         where s.lesson_id = app_private.seed_id('lesson:quran-yassarna-beginner:2:3')),
  'the new lesson comes right after the last lesson of Stage 3');
reset role;

select pg_temp.login_as_id(current_setting('t.cla')::uuid);
set local role authenticated;
select pg_temp.check(exists (select 1 from courses where id = current_setting('t.beg')::uuid),
  'learner A sees Yassarna: Beginners');
select pg_temp.check(app_private.can_read_lesson(app_private.seed_id('lesson:quran-yassarna-beginner:0:0')),
  'learner A opens the first lesson');
select pg_temp.check((select count(*) from lesson_content_blocks
                      where lesson_id = app_private.seed_id('lesson:quran-yassarna-beginner:0:0')) = 2,
  'learner A sees its content, not the teacher''s note');
select pg_temp.check(not app_private.can_read_lesson(app_private.seed_id('lesson:quran-yassarna-beginner:0:1')),
  'the next lesson waits for the teacher');
select pg_temp.expect_error($q$select public.enrol_in_course(
  (select id from courses where slug = 'quran-yassarna-intermediate'))$q$, 'course not found');
reset role;

select pg_temp.login_as_id(current_setting('t.clb')::uuid);
set local role authenticated;
select pg_temp.check(exists (select 1 from courses where id = current_setting('t.beg')::uuid),
  'learner B can see the published course in the catalogue');
select pg_temp.check(not app_private.can_read_lesson(app_private.seed_id('lesson:quran-yassarna-beginner:0:0')),
  'learner B cannot open its lessons');
select pg_temp.check(not exists (select 1 from lesson_content_blocks
                                 where lesson_id = app_private.seed_id('lesson:quran-yassarna-beginner:0:0')),
  'learner B cannot read its content');
select pg_temp.expect_error($q$select public.enrol_in_course(current_setting('t.beg')::uuid)$q$,
  'requires access');
select pg_temp.expect_error($q$insert into course_enrolments (course_id, user_id, status, source)
  values (current_setting('t.beg')::uuid, app_private.current_user_id(), 'active', 'admin_grant')$q$,
  'permission denied');
select pg_temp.expect_error($q$insert into lesson_unlocks (user_id, lesson_id, course_id, reason)
  values (app_private.current_user_id(), app_private.seed_id('lesson:quran-yassarna-beginner:0:1'),
          current_setting('t.beg')::uuid, 'first_lesson')$q$, 'permission denied');
reset role;

select 'ALL CATALOGUE TESTS PASSED' as result;
