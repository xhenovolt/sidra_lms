-- Access-control and business-rule tests.
-- Run by `dart run tool/db.dart test`: migrations + this file execute in ONE
-- transaction that is always rolled back, against the real database engine.
-- Any failed expectation raises and aborts the run.
--
-- Impersonation mirrors the Data API: SET ROLE authenticated plus the
-- request.jwt.claims setting that pg_session_jwt reads.

-- ------------------------------------------------------------ helpers --
create function pg_temp.expect_error(p_sql text, p_like text) returns void
language plpgsql as $$
begin
  execute p_sql;
  raise exception 'EXPECTED ERROR "%" but statement succeeded: %', p_like, p_sql;
exception when others then
  if sqlerrm like 'EXPECTED ERROR%' then raise; end if;
  if sqlerrm not ilike '%' || p_like || '%' and sqlstate not ilike p_like then
    raise exception 'expected error like "%", got [%] %', p_like, sqlstate, sqlerrm;
  end if;
end $$;

create function pg_temp.check(p_ok boolean, p_msg text) returns void
language plpgsql as $$
begin
  if p_ok is not true then raise exception 'CHECK FAILED: %', p_msg; end if;
end $$;

grant execute on function pg_temp.expect_error(text, text), pg_temp.check(boolean, text) to authenticated;

insert into app_private.settings (key, value) values
  ('cloudinary_cloud_name', 'testcloud'),
  ('cloudinary_api_key', '123'),
  ('cloudinary_api_secret', 'testsecret')
on conflict (key) do update set value = excluded.value;

-- ------------------------------------------------------------ fixtures --
-- (as owner; RLS does not apply to the table owner)
insert into users (id, clerk_user_id, display_name, role) values
  ('00000000-0000-0000-0000-00000000000a', 'admin_1', 'Admin', 'admin'),
  ('00000000-0000-0000-0000-00000000000b', 'teacher_1', 'Ustadh Musa', 'teacher'),
  ('00000000-0000-0000-0000-00000000000c', 'teacher_2', 'Other Teacher', 'teacher'),
  ('00000000-0000-0000-0000-0000000000a1', 'learner_a', 'Aisha', 'learner'),
  ('00000000-0000-0000-0000-0000000000b1', 'learner_b', 'Bilal', 'learner');

insert into media_assets (id, kind, resource_type, delivery, public_id, format, version) values
  ('00000000-0000-0000-0000-0000000000f1', 'image', 'image', 'upload', 'sidra/thumbs/quran', 'jpg', 1),
  ('00000000-0000-0000-0000-0000000000f2', 'image', 'image', 'authenticated', 'sidra/l1/letters', 'png', 7),
  ('00000000-0000-0000-0000-0000000000f3', 'audio', 'video', 'authenticated', 'sidra/l2/recitation', 'mp3', 9);

insert into courses (id, slug, title, subject, access, progression, status, thumbnail_asset_id, price_amount, price_currency) values
  ('00000000-0000-0000-0000-000000000c01', 'quran-intermediate', 'Quran Intermediate', 'Quran',
   'free', 'teacher_gated', 'published', '00000000-0000-0000-0000-0000000000f1', null, null),
  ('00000000-0000-0000-0000-000000000c02', 'aqeedah-advanced', 'Aqeedah Advanced', 'Theology',
   'paid', 'teacher_gated', 'published', null, 20, 'USD'),
  ('00000000-0000-0000-0000-000000000c03', 'draft-course', 'Draft', 'Fiqh',
   'free', 'open', 'draft', null, null, null),
  ('00000000-0000-0000-0000-000000000c04', 'arabic-letters', 'Arabic Letters', 'Arabic',
   'free', 'sequential', 'published', null, null, null);

insert into course_staff (course_id, user_id, role) values
  ('00000000-0000-0000-0000-000000000c01', '00000000-0000-0000-0000-00000000000b', 'teacher');

insert into course_units (id, course_id, title, position, status) values
  ('00000000-0000-0000-0000-000000000d01', '00000000-0000-0000-0000-000000000c01', 'Unit 1', 0, 'published');

-- Book with an admin-defined Surah → Verse structure.
insert into books (id, title, status) values
  ('00000000-0000-0000-0000-000000000b01', 'The Quran', 'published');
insert into book_structures (id, book_id, name, is_default) values
  ('00000000-0000-0000-0000-000000000501', '00000000-0000-0000-0000-000000000b01', 'Surah and verse', true);
insert into book_structure_levels (id, structure_id, depth, node_type, label_singular, label_plural, uses_surah, uses_verses) values
  ('00000000-0000-0000-0000-000000000601', '00000000-0000-0000-0000-000000000501', 1, 'surah', 'Surah', 'Surahs', true, false),
  ('00000000-0000-0000-0000-000000000602', '00000000-0000-0000-0000-000000000501', 2, 'verse', 'Verse', 'Verses', false, true);

insert into curriculum_nodes (id, course_id, unit_id, parent_id, structure_level_id, title, position, surah_number, status) values
  ('00000000-0000-0000-0000-000000000e01', '00000000-0000-0000-0000-000000000c01',
   '00000000-0000-0000-0000-000000000d01', null, '00000000-0000-0000-0000-000000000601',
   'Al-Fatihah', 0, 1, 'published');
insert into curriculum_nodes (id, course_id, parent_id, structure_level_id, title, position, verse_start, verse_end, status) values
  ('00000000-0000-0000-0000-000000000e02', '00000000-0000-0000-0000-000000000c01',
   '00000000-0000-0000-0000-000000000e01', '00000000-0000-0000-0000-000000000602',
   'Verses 1–3', 0, 1, 3, 'published');

-- Lessons: L1, L2 published under the verse node; L3 draft (never counted).
insert into lessons (id, course_id, node_id, title, position, status) values
  ('00000000-0000-0000-0000-000000001001', '00000000-0000-0000-0000-000000000c01', '00000000-0000-0000-0000-000000000e02', 'Lesson 1', 0, 'published'),
  ('00000000-0000-0000-0000-000000001002', '00000000-0000-0000-0000-000000000c01', '00000000-0000-0000-0000-000000000e02', 'Lesson 2', 1, 'published'),
  ('00000000-0000-0000-0000-000000001003', '00000000-0000-0000-0000-000000000c01', '00000000-0000-0000-0000-000000000e02', 'Lesson 3 (draft)', 2, 'draft');

insert into lesson_content_blocks (lesson_id, position, block_type, body, media_asset_id) values
  ('00000000-0000-0000-0000-000000001001', 0, 'heading', '{"text":"Bismillah","level":1}', null),
  ('00000000-0000-0000-0000-000000001001', 1, 'image', '{}', '00000000-0000-0000-0000-0000000000f2'),
  ('00000000-0000-0000-0000-000000001002', 0, 'quran_text', '{"arabic":"الحمد لله رب العالمين","surah":1,"verse_start":2}', null),
  ('00000000-0000-0000-0000-000000001002', 1, 'audio', '{}', '00000000-0000-0000-0000-0000000000f3');

-- Graded quiz on lesson 1 + practice quiz on lesson 1.
insert into assessments (id, course_id, lesson_id, title, kind, grading, pass_mark_percent, status) values
  ('00000000-0000-0000-0000-000000002001', '00000000-0000-0000-0000-000000000c01', '00000000-0000-0000-0000-000000001001', 'Graded', 'graded', 'auto', 50, 'published'),
  ('00000000-0000-0000-0000-000000002002', '00000000-0000-0000-0000-000000000c01', '00000000-0000-0000-0000-000000001001', 'Practice', 'practice', 'auto', 50, 'published');
insert into assessment_questions (id, assessment_id, position, question_type, prompt, points) values
  ('00000000-0000-0000-0000-000000003001', '00000000-0000-0000-0000-000000002001', 0, 'single_choice', 'How many verses in Al-Fatihah?', 1),
  ('00000000-0000-0000-0000-000000003002', '00000000-0000-0000-0000-000000002002', 0, 'true_false', 'Al-Fatihah is the first surah', 1);
insert into assessment_options (id, question_id, position, label, is_correct) values
  ('00000000-0000-0000-0000-000000004001', '00000000-0000-0000-0000-000000003001', 0, '5', false),
  ('00000000-0000-0000-0000-000000004002', '00000000-0000-0000-0000-000000003001', 1, '7', true),
  ('00000000-0000-0000-0000-000000004003', '00000000-0000-0000-0000-000000003002', 0, 'True', true),
  ('00000000-0000-0000-0000-000000004004', '00000000-0000-0000-0000-000000003002', 1, 'False', false);

-- Sequential course with two lessons.
insert into lessons (id, course_id, title, position, status) values
  ('00000000-0000-0000-0000-000000005001', '00000000-0000-0000-0000-000000000c04', 'Alif', 0, 'published'),
  ('00000000-0000-0000-0000-000000005002', '00000000-0000-0000-0000-000000000c04', 'Ba', 1, 'published');

-- -------------------------------------------- structural integrity (owner) --
select pg_temp.expect_error($q$
  insert into curriculum_nodes (course_id, parent_id, structure_level_id, title, position)
  values ('00000000-0000-0000-0000-000000000c01', '00000000-0000-0000-0000-000000000e02',
          '00000000-0000-0000-0000-000000000602', 'verse under verse', 5)$q$,
  'must sit directly under');
select pg_temp.expect_error($q$
  insert into lesson_content_blocks (lesson_id, position, block_type, body)
  values ('00000000-0000-0000-0000-000000001001', 9, 'audio', '{}')$q$,
  'lesson_content_blocks_valid');
select pg_temp.expect_error($q$
  insert into curriculum_nodes (course_id, title, position, surah_number)
  values ('00000000-0000-0000-0000-000000000c01', 'bad surah', 9, 115)$q$,
  'check constraint');
select pg_temp.check(
  (select array_agg(lesson_id order by seq) from app_private.lesson_sequence('00000000-0000-0000-0000-000000000c01'))
  = array['00000000-0000-0000-0000-000000001001', '00000000-0000-0000-0000-000000001002']::uuid[],
  'sequence has only live lessons, in tree order');

-- ============================================================ learner A ==
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"learner_a"}', true);

select pg_temp.check((public.ensure_profile('Aisha R', 'a@example.com'))->>'role' = 'learner',
  'new profile is a learner');
select pg_temp.check(not exists (select 1 from courses where slug = 'draft-course'),
  'draft courses hidden from learners');
select pg_temp.check((select count(*) from lessons where course_id = '00000000-0000-0000-0000-000000000c01') = 2,
  'outline shows only published lessons');
select pg_temp.check(not exists (select 1 from lesson_content_blocks),
  'no lesson content before enrolment');

select pg_temp.expect_error($q$select public.enrol_in_course('00000000-0000-0000-0000-000000000c02')$q$,
  'requires access to be granted');
select public.enrol_in_course('00000000-0000-0000-0000-000000000c01');
select public.enrol_in_course('00000000-0000-0000-0000-000000000c01');  -- idempotent

select pg_temp.check((select count(*) from lesson_content_blocks
                      where lesson_id = '00000000-0000-0000-0000-000000001001') = 2,
  'first lesson unlocked on enrolment');
select pg_temp.check(not exists (select 1 from lesson_content_blocks
                                 where lesson_id = '00000000-0000-0000-0000-000000001002'),
  'second lesson content hidden until teacher unlocks');

select pg_temp.check(public.media_url('00000000-0000-0000-0000-0000000000f2')
  like 'https://res.cloudinary.com/testcloud/image/authenticated/s--%--/v7/sidra/l1/letters.png',
  'signed URL for unlocked lesson image');
select pg_temp.check(public.media_url('00000000-0000-0000-0000-0000000000f1')
  = 'https://res.cloudinary.com/testcloud/image/upload/v1/sidra/thumbs/quran.jpg',
  'public thumbnail URL is unsigned');
select pg_temp.expect_error($q$select public.media_url('00000000-0000-0000-0000-0000000000f3')$q$,
  'media is locked');

-- Progress: idempotent, completion is sticky, does NOT unlock in teacher-gated.
select public.record_progress('00000000-0000-0000-0000-00000000aa01',
  '00000000-0000-0000-0000-000000001001', 'completed', '{"block":1}');
select public.record_progress('00000000-0000-0000-0000-00000000aa01',
  '00000000-0000-0000-0000-000000001001', 'completed', '{"block":1}');
select public.record_progress('00000000-0000-0000-0000-00000000aa02',
  '00000000-0000-0000-0000-000000001001', 'in_progress', '{"block":0}',
  now() - interval '1 hour');
select pg_temp.check((select status from learner_progress
                      where lesson_id = '00000000-0000-0000-0000-000000001001') = 'completed',
  'completed never regresses; stale position ignored');
select pg_temp.check((select last_position->>'block' from learner_progress
                      where lesson_id = '00000000-0000-0000-0000-000000001001') = '1',
  'older client update does not overwrite newer position');
select pg_temp.check(not exists (select 1 from lesson_unlocks
                                 where lesson_id = '00000000-0000-0000-0000-000000001002'),
  'completing a teacher-gated lesson does not unlock the next');
select pg_temp.expect_error($q$select public.record_progress(gen_random_uuid(),
  '00000000-0000-0000-0000-000000001002', 'completed')$q$, 'lesson is locked');

-- Direct tampering is refused.
select pg_temp.expect_error($q$insert into lesson_unlocks (user_id, lesson_id, course_id, reason)
  values ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-000000001002',
          '00000000-0000-0000-0000-000000000c01', 'teacher_approved')$q$, 'permission denied');
select pg_temp.expect_error($q$select public.unlock_lesson('00000000-0000-0000-0000-0000000000a1',
  '00000000-0000-0000-0000-000000001002')$q$, 'only the course teacher');
select pg_temp.expect_error($q$update users set role = 'admin'
  where clerk_user_id = 'learner_a'$q$, 'permission denied');
select pg_temp.expect_error($q$insert into course_enrolments (course_id, user_id, source)
  values ('00000000-0000-0000-0000-000000000c02', '00000000-0000-0000-0000-0000000000a1', 'payment')$q$,
  'permission denied');
update courses set title = 'hacked' where id = '00000000-0000-0000-0000-000000000c01';
select pg_temp.check((select title from courses where id = '00000000-0000-0000-0000-000000000c01')
  = 'Quran Intermediate', 'learners cannot edit curriculum (RLS matches no rows)');
select pg_temp.expect_error($q$select public.set_user_role('00000000-0000-0000-0000-0000000000a1', 'admin')$q$,
  'administrators only');
select pg_temp.check((select array_agg(clerk_user_id order by clerk_user_id) from users)
  = array['learner_a', 'teacher_1'],
  'learner sees self and course teachers only, not other learners or admins');

-- Quiz: graded answers never exposed; server scores.
select pg_temp.check(not exists (select 1 from assessment_options), 'base options table hidden');
select pg_temp.check((select bool_and(is_correct is null) from learner_assessment_options
                      where question_id = '00000000-0000-0000-0000-000000003001'),
  'graded quiz correctness hidden');
select pg_temp.check((select count(*) filter (where is_correct) from learner_assessment_options
                      where question_id = '00000000-0000-0000-0000-000000003002') = 1,
  'practice quiz correctness available for offline scoring');
select pg_temp.check((public.submit_attempt(jsonb_build_object(
    'id', '00000000-0000-0000-0000-00000000ab01',
    'assessment_id', '00000000-0000-0000-0000-000000002001',
    'client_score', 1,
    'answers', jsonb_build_array(jsonb_build_object(
      'question_id', '00000000-0000-0000-0000-000000003001',
      'selected_option_ids', jsonb_build_array('00000000-0000-0000-0000-000000004001'))))
  ))->>'passed' = 'false',
  'server scores the attempt, ignoring the client score');
select pg_temp.check(((public.submit_attempt(jsonb_build_object(
    'id', '00000000-0000-0000-0000-00000000ab01',
    'assessment_id', '00000000-0000-0000-0000-000000002001')))->>'score')::numeric = 0,
  'resubmitting the same attempt is idempotent');
select pg_temp.check((select count(*) from quiz_attempts) = 1, 'one attempt stored');

-- Dashboard: 1 of 2 live lessons done (draft lesson not counted).
select pg_temp.check((select progress_percent from public.my_courses()
                      where course_id = '00000000-0000-0000-0000-000000000c01') = 50,
  'progress counts live lessons only');

-- Sequential course unlocks automatically.
select public.enrol_in_course('00000000-0000-0000-0000-000000000c04');
select public.record_progress(gen_random_uuid(), '00000000-0000-0000-0000-000000005001', 'completed');
select pg_temp.check(exists (select 1 from lesson_unlocks
                             where lesson_id = '00000000-0000-0000-0000-000000005002'),
  'sequential course auto-unlocks the next lesson');

reset role;

-- ============================================================ learner B ==
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"learner_b"}', true);
select pg_temp.check(not exists (select 1 from learner_progress), 'cannot see other learners progress');
select pg_temp.check(not exists (select 1 from quiz_attempts), 'cannot see other learners attempts');
select pg_temp.check(not exists (select 1 from course_enrolments), 'cannot see other learners enrolments');
select pg_temp.check(public.attempt_result('00000000-0000-0000-0000-00000000ab01') is null,
  'cannot read another learners attempt result');
reset role;

-- ====================================================== unrelated teacher ==
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"teacher_2"}', true);
select pg_temp.expect_error($q$select public.unlock_lesson('00000000-0000-0000-0000-0000000000a1',
  '00000000-0000-0000-0000-000000001002')$q$, 'only the course teacher');
select pg_temp.check(not exists (select 1 from public.teacher_learners()),
  'teacher sees no learners outside their courses');
reset role;

-- ========================================================= course teacher ==
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"teacher_1"}', true);
select pg_temp.check((select awaiting_review from public.teacher_learners()
                      where user_id = '00000000-0000-0000-0000-0000000000a1'),
  'learner shows as awaiting review');
select pg_temp.check((public.review_lesson('00000000-0000-0000-0000-0000000000a1',
    '00000000-0000-0000-0000-000000001001', 'passed', 90, 'Excellent tajweed'))
  ->>'unlocked_lesson_id' = '00000000-0000-0000-0000-000000001002',
  'passing review unlocks the next lesson');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"learner_a"}', true);
select pg_temp.check((select count(*) from lesson_content_blocks
                      where lesson_id = '00000000-0000-0000-0000-000000001002') = 2,
  'learner can now read lesson 2 content');
select pg_temp.check(public.media_url('00000000-0000-0000-0000-0000000000f3')
  like '%/video/authenticated/s--%--/v9/sidra/l2/recitation.mp3',
  'lesson 2 audio now signed');
select pg_temp.check((select count(*) from lesson_reviews) = 1, 'learner sees own review');
reset role;

-- ================================================================= admin ==
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"admin_1"}', true);
select public.grant_enrolment('00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-000000000c02');
select public.set_user_role('00000000-0000-0000-0000-00000000000c', 'learner');
select pg_temp.expect_error($q$select public.set_user_role('00000000-0000-0000-0000-00000000000a', 'learner')$q$,
  'cannot remove your own administrator role');
select pg_temp.check(exists (select 1 from courses where slug = 'draft-course'), 'admin sees drafts');
select pg_temp.check((public.sign_media_upload('lessons'))->>'folder' = 'sidra/lessons',
  'staff upload signature');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"learner_b"}', true);
select pg_temp.check((public.sign_media_upload('lessons'))->>'folder'
  = 'sidra/submissions/00000000-0000-0000-0000-0000000000b1',
  'learner uploads confined to own submissions folder');
select pg_temp.check(exists (select 1 from course_enrolments
                             where course_id = '00000000-0000-0000-0000-000000000c02'),
  'admin-granted paid enrolment visible to learner');
reset role;

-- ============================================================ anonymous ==
set local role anonymous;
select pg_temp.expect_error('select count(*) from courses', 'permission denied');
select pg_temp.expect_error($q$select public.enrol_in_course('00000000-0000-0000-0000-000000000c01')$q$,
  'permission denied');
reset role;

select 'ALL ACCESS TESTS PASSED' as result;
