-- Course rules and lesson work (0029, 0030).

select set_config('t.lt', app_private.create_account('Ustadha Lw', null, null, 'lw_teacher',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('t.lt')::uuid, 'teacher');
select set_config('t.ll', app_private.create_account('Maryam Lw', null, null, 'lw_learner',
  'learner', false, 'learner-pass-1', false)::text, true);

-- An "after approval" course, pass mark 70, with two lessons.
insert into courses (id, slug, title, subject, access, progression, status, language, pass_mark_percent)
values ('00000000-0000-0000-0000-0000000cc001', 'lw-approval', 'LW Approval', 'Quran', 'restricted',
        'after_approval', 'published', 'en', 70),
       ('00000000-0000-0000-0000-0000000cc002', 'lw-submission', 'LW Submission', 'Quran', 'restricted',
        'after_submission', 'published', 'en', 70);
insert into lessons (id, course_id, title, position, status) values
  ('00000000-0000-0000-0000-0000000cca01', '00000000-0000-0000-0000-0000000cc001', 'Al-Fatihah 1-4', 0, 'published'),
  ('00000000-0000-0000-0000-0000000cca02', '00000000-0000-0000-0000-0000000cc001', 'Al-Fatihah 5-7', 1, 'published'),
  ('00000000-0000-0000-0000-0000000ccb01', '00000000-0000-0000-0000-0000000cc002', 'S1', 0, 'published'),
  ('00000000-0000-0000-0000-0000000ccb02', '00000000-0000-0000-0000-0000000cc002', 'S2', 1, 'published');
insert into lesson_content_blocks (lesson_id, position, block_type, body, language) values
  ('00000000-0000-0000-0000-0000000cca01', 0, 'quran_text',
   '{"arabic": "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ١"}', 'ar');
insert into course_staff (course_id, user_id, role) values
  ('00000000-0000-0000-0000-0000000cc001', current_setting('t.lt')::uuid, 'teacher'),
  ('00000000-0000-0000-0000-0000000cc002', current_setting('t.lt')::uuid, 'teacher');
insert into course_enrolments (course_id, user_id, status, source) values
  ('00000000-0000-0000-0000-0000000cc001', current_setting('t.ll')::uuid, 'active', 'admin_grant'),
  ('00000000-0000-0000-0000-0000000cc002', current_setting('t.ll')::uuid, 'active', 'admin_grant');
insert into media_assets (id, kind, resource_type, delivery, public_id, format, uploaded_by) values
  ('00000000-0000-0000-0000-0000000ccf01', 'audio', 'video', 'authenticated',
   'sidra/submissions/' || current_setting('t.ll') || '/w1', 'm4a', current_setting('t.ll')::uuid),
  ('00000000-0000-0000-0000-0000000ccf02', 'audio', 'video', 'authenticated',
   'sidra/submissions/' || current_setting('t.ll') || '/w2', 'm4a', current_setting('t.ll')::uuid);

select pg_temp.login_as_id(current_setting('t.ll')::uuid);
set local role authenticated;
select pg_temp.check(app_private.can_read_lesson('00000000-0000-0000-0000-0000000cca01'), 'first lesson open');
select pg_temp.check(not app_private.can_read_lesson('00000000-0000-0000-0000-0000000cca02'), 'second locked');
-- "I have finished" cannot complete a lesson that needs work.
select public.record_progress(gen_random_uuid(), '00000000-0000-0000-0000-0000000cca01', 'completed');
select pg_temp.check((select status::text from learner_progress
                      where lesson_id = '00000000-0000-0000-0000-0000000cca01'
                        and user_id = app_private.current_user_id()) = 'in_progress',
  'self-marking a work lesson finished is refused');
select pg_temp.check(not app_private.can_read_lesson('00000000-0000-0000-0000-0000000cca02'), 'still locked');
select public.submit_lesson_work('00000000-0000-0000-0000-0000000cc501', '00000000-0000-0000-0000-0000000cca01',
  null, '[{"media_asset_id": "00000000-0000-0000-0000-0000000ccf01", "file_name": "w1.m4a"}]');
select pg_temp.expect_error($q$select public.submit_lesson_work('00000000-0000-0000-0000-0000000cc502',
  '00000000-0000-0000-0000-0000000cca01', 'again', '[]')$q$, 'wait for your teacher');
reset role;

select pg_temp.login_as_id(current_setting('t.lt')::uuid);
set local role authenticated;
select pg_temp.check(exists (select 1 from notifications where kind = 'lesson_work'
                             and title = 'New work from Maryam Lw'), 'teacher notified: New work from Maryam Lw');
select pg_temp.check((select count(*) from public.teacher_lesson_work()) = 1, 'in the teacher''s queue');
select pg_temp.check(jsonb_array_length(public.lesson_marking_text('00000000-0000-0000-0000-0000000cca01')) = 4,
  'lesson text split into words for marking (verse number skipped)');
-- 60% is below the pass mark: correction, still locked.
select pg_temp.check((public.review_lesson_work('00000000-0000-0000-0000-0000000cc501', 'correct', 60,
  '[{"i":0,"w":"بِسْمِ","m":"ok"},{"i":1,"w":"ٱللَّهِ","m":"wrong"}]', 'Watch the madd')->>'passed')::boolean = false,
  'below the pass mark is not a pass');
reset role;

select pg_temp.login_as_id(current_setting('t.ll')::uuid);
set local role authenticated;
select pg_temp.check(not app_private.can_read_lesson('00000000-0000-0000-0000-0000000cca02'), 'still locked after 60%');
select pg_temp.check((select x->'reviews'->0->'word_marks'->1->>'m' from public.my_lesson_work(
  '00000000-0000-0000-0000-0000000cca01') x limit 1) = 'wrong', 'learner sees the word marks');
select pg_temp.check((public.submit_lesson_work('00000000-0000-0000-0000-0000000cc503',
  '00000000-0000-0000-0000-0000000cca01', null,
  '[{"media_asset_id": "00000000-0000-0000-0000-0000000ccf02"}]')->>'attempt')::int = 2, 'attempt 2');
reset role;

select pg_temp.login_as_id(current_setting('t.lt')::uuid);
set local role authenticated;
select pg_temp.check((public.review_lesson_work('00000000-0000-0000-0000-0000000cc503', 'correct', 90)->>'passed')::boolean,
  '90% passes');
reset role;

select pg_temp.login_as_id(current_setting('t.ll')::uuid);
set local role authenticated;
select pg_temp.check(app_private.can_read_lesson('00000000-0000-0000-0000-0000000cca02'), 'pass unlocked the next lesson');
select pg_temp.check(exists (select 1 from notifications where kind = 'reviewed'
                             and title = 'Al-Fatihah 1-4'
                             and data->>'lesson_id' = '00000000-0000-0000-0000-0000000cca01'),
  'learner notified, naming the lesson');
select pg_temp.check((select status::text from learner_progress
                      where lesson_id = '00000000-0000-0000-0000-0000000cca01'
                        and user_id = app_private.current_user_id()) = 'completed', 'lesson completed');
-- After-submission course: handing in unlocks the next lesson at once.
select pg_temp.check((public.submit_lesson_work('00000000-0000-0000-0000-0000000cc504',
  '00000000-0000-0000-0000-0000000ccb01', 'My answer', '[]')->>'unlocked_lesson_id')
  = '00000000-0000-0000-0000-0000000ccb02', 'handing in unlocks the next lesson');
reset role;

-- Admins can switch a kind of notification off: for everyone, or a course.
insert into org_settings (key, value) values ('notify_lesson_work', 'false')
on conflict (key) do update set value = 'false';
select pg_temp.check(not app_private.notification_allowed('lesson_work', null), 'switched off for everyone');
update org_settings set value = 'true' where key = 'notify_lesson_work';
update courses set metadata = metadata || '{"notify": {"lesson_work": false}}'
where id = '00000000-0000-0000-0000-0000000cc002';
select pg_temp.check(not app_private.notification_allowed('lesson_work', '00000000-0000-0000-0000-0000000cc002')
                     and app_private.notification_allowed('lesson_work', '00000000-0000-0000-0000-0000000cc001'),
  'switched off for one course only');

-- Other teachers see none of it.
select pg_temp.login_as_id(current_setting('t.ll')::uuid);
set local role authenticated;
select pg_temp.check(not exists (select 1 from public.teacher_lesson_work()), 'learners have no queue');
select pg_temp.check(public.lesson_marking_text('00000000-0000-0000-0000-0000000cca01') is null,
  'learners cannot fetch the marking text');
reset role;

select 'ALL LESSON WORK TESTS PASSED' as result;
