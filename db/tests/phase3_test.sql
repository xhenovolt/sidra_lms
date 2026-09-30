-- Phase 3 infrastructure (0018). Own fixtures; access_test helpers.

select set_config('t.teach', app_private.create_account('P3 Teacher', null, null, 'p3_teacher',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('t.teach')::uuid, 'teacher');
select set_config('t.other_teach', app_private.create_account('P3 Other Teacher', null, null,
  'p3_other', 'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('t.other_teach')::uuid, 'teacher');
select set_config('t.la', app_private.create_account('Learner A', null, null, 'p3_la',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('t.lb', app_private.create_account('Learner B', null, null, 'p3_lb',
  'learner', false, 'learner-pass-1', false)::text, true);

insert into courses (id, slug, title, subject, access, progression, status, language,
                     delivery_languages, track_key)
values ('00000000-0000-0000-0000-0000000e0001', 'p3-beginner', 'P3 Beginner', 'Quran',
        'restricted', 'open', 'published', 'en', '{ar}', 'quran_reading'),
       ('00000000-0000-0000-0000-0000000e0002', 'p3-intermediate', 'P3 Intermediate', 'Quran',
        'free', 'open', 'published', 'en', '{}', 'quran_reading');
insert into lessons (id, course_id, title, position, status, delivery_language, objectives)
values ('00000000-0000-0000-0000-0000000e0a01', '00000000-0000-0000-0000-0000000e0001',
        'Short vowels', 0, 'published', 'en',
        array['The learner reads letters carrying fatḥah, kasrah and ḍammah.']);
insert into course_staff (course_id, user_id, role) values
  ('00000000-0000-0000-0000-0000000e0001', current_setting('t.teach')::uuid, 'teacher');
insert into course_enrolments (course_id, user_id, status, source) values
  ('00000000-0000-0000-0000-0000000e0001', current_setting('t.la')::uuid, 'active', 'admin_grant');
insert into course_prerequisites values
  ('00000000-0000-0000-0000-0000000e0002', '00000000-0000-0000-0000-0000000e0001');

select pg_temp.expect_error($q$insert into courses (slug, title, subject, delivery_languages)
  values ('bad-lang', 'X', 'Y', '{xx}')$q$, 'courses_languages_known');
select pg_temp.expect_error($q$update lessons set delivery_language = 'zz'
  where id = '00000000-0000-0000-0000-0000000e0a01'$q$, 'foreign key');

-- Content: Arabic Qur'an text in an English-delivered lesson; a staff note.
insert into lesson_content_blocks (lesson_id, position, block_type, body, language, audience) values
  ('00000000-0000-0000-0000-0000000e0a01', 0, 'quran_text', '{"arabic": "بِسْمِ ٱللَّهِ"}', 'ar', 'all'),
  ('00000000-0000-0000-0000-0000000e0a01', 1, 'rich_text', '{"text": "Read slowly."}', 'en', 'all'),
  ('00000000-0000-0000-0000-0000000e0a01', 2, 'callout', '{"text": "Watch for ḍammah."}', 'en', 'staff');

-- ------------------------------------------------------------ resources --
insert into media_assets (id, kind, resource_type, delivery, public_id, format, uploaded_by,
                          file_name, mime_type)
values ('00000000-0000-0000-0000-0000000e0f01', 'document', 'raw', 'authenticated',
        'sidra/content/student-practice', 'pdf', current_setting('t.teach')::uuid,
        'student-practice.pdf', 'application/pdf');

select pg_temp.login_as_id(current_setting('t.teach')::uuid);
set local role authenticated;
insert into resources (id, kind, title, provider, media_asset_id, file_name, mime_type,
                       extension, language, uploaded_by)
values ('00000000-0000-0000-0000-0000000e0d01', 'document', 'Student practice sheet',
        'cloudinary', '00000000-0000-0000-0000-0000000e0f01', 'student-practice.pdf',
        'application/pdf', 'pdf', 'en', current_setting('t.teach')::uuid);
insert into resources (id, kind, title, provider, url, preview, uploaded_by)
values ('00000000-0000-0000-0000-0000000e0d02', 'link', 'Makharij video', 'external',
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ', '{"status": "ok", "title": "Video"}',
        current_setting('t.teach')::uuid);
select pg_temp.expect_error($q$insert into resources (kind, title, provider, url, uploaded_by)
  values ('link', 'Bad', 'external', 'javascript:alert(1)', app_private.current_user_id())$q$,
  'resources_url_check');
insert into resource_links (resource_id, lesson_id) values
  ('00000000-0000-0000-0000-0000000e0d01', '00000000-0000-0000-0000-0000000e0a01'),
  ('00000000-0000-0000-0000-0000000e0d02', '00000000-0000-0000-0000-0000000e0a01');
select pg_temp.expect_error($q$insert into resource_links (resource_id, course_id)
  values ('00000000-0000-0000-0000-0000000e0d01', '00000000-0000-0000-0000-0000000e0002')$q$,
  'row-level security');

-- Assignment on the lesson.
insert into assignments (id, course_id, lesson_id, title, instructions, submission_types, status, max_score)
values ('00000000-0000-0000-0000-0000000e0e01', '00000000-0000-0000-0000-0000000e0001',
        '00000000-0000-0000-0000-0000000e0a01', 'Write ا ب ت ث',
        'Write each letter five times on paper and photograph it.', '{image}', 'published', 10);
select pg_temp.check(exists (select 1 from lesson_content_blocks where audience = 'staff'),
  'teachers see teacher notes');
reset role;

-- ------------------------------------------------------------ learner A --
select pg_temp.login_as_id(current_setting('t.la')::uuid);
set local role authenticated;
select pg_temp.check((select count(*) from lesson_content_blocks
                      where lesson_id = '00000000-0000-0000-0000-0000000e0a01') = 2,
  'learners do not see teacher notes');
select pg_temp.check((select language from lesson_content_blocks where block_type = 'quran_text'
                      and lesson_id = '00000000-0000-0000-0000-0000000e0a01') = 'ar'
                     and (select delivery_language from lessons
                          where id = '00000000-0000-0000-0000-0000000e0a01') = 'en',
  'Arabic content inside an English-delivered lesson');
select pg_temp.check((select count(*) from resources) = 2, 'enrolled learner sees lesson resources');
select pg_temp.check(public.media_url('00000000-0000-0000-0000-0000000e0f01') like 'https://res.cloudinary.com/%',
  'enrolled learner can open the PDF');
select pg_temp.expect_error($q$select public.enrol_in_course('00000000-0000-0000-0000-0000000e0002')$q$,
  'finish P3 Beginner first');
reset role;

-- Learner A photographs their work (upload registered as theirs).
insert into media_assets (id, kind, resource_type, delivery, public_id, format, uploaded_by, file_name)
values ('00000000-0000-0000-0000-0000000e0f02', 'image', 'image', 'authenticated',
        'sidra/submissions/' || current_setting('t.la') || '/letters', 'jpg',
        current_setting('t.la')::uuid, 'letters.jpg');
select pg_temp.login_as_id(current_setting('t.la')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.submit_work('00000000-0000-0000-0000-0000000e05b1',
  '00000000-0000-0000-0000-0000000e0e01', null,
  '[{"media_asset_id": "00000000-0000-0000-0000-0000000e0f01"}]')$q$, 'your own uploads');
select public.submit_work('00000000-0000-0000-0000-0000000e05b1',
  '00000000-0000-0000-0000-0000000e0e01', 'Done',
  '[{"media_asset_id": "00000000-0000-0000-0000-0000000e0f02", "file_name": "letters.jpg", "mime_type": "image/jpeg"}]');
select pg_temp.check((public.submit_work('00000000-0000-0000-0000-0000000e05b1',
  '00000000-0000-0000-0000-0000000e0e01', 'Done again', '[]')->>'text_answer') = 'Done',
  'resending a queued submission changes nothing');
-- (Since 0043 a newer attempt may follow a waiting one: work_threads_test.sql.)
reset role;

-- ------------------------------------------------------------ learner B --
select pg_temp.login_as_id(current_setting('t.lb')::uuid);
set local role authenticated;
select pg_temp.check(not exists (select 1 from resources), 'not enrolled: no resources');
select pg_temp.expect_error($q$select public.media_url('00000000-0000-0000-0000-0000000e0f01')$q$,
  'media is locked');
select pg_temp.expect_error($q$select public.media_url('00000000-0000-0000-0000-0000000e0f02')$q$,
  'media is locked');
select pg_temp.check(not exists (select 1 from submissions), 'cannot see another learner''s work');
select pg_temp.expect_error($q$select public.submit_work('00000000-0000-0000-0000-0000000e05b3',
  '00000000-0000-0000-0000-0000000e0e01', 'sneaky', '[]')$q$, 'assignment not found');
select pg_temp.expect_error($q$select public.enrol_in_course('00000000-0000-0000-0000-0000000e0001')$q$,
  'requires access');
reset role;

-- ------------------------------------------------------ other teacher --
select pg_temp.login_as_id(current_setting('t.other_teach')::uuid);
set local role authenticated;
select pg_temp.check(not exists (select 1 from submissions), 'other teachers see no submissions');
select pg_temp.expect_error($q$select public.media_url('00000000-0000-0000-0000-0000000e0f02')$q$,
  'media is locked');
select pg_temp.check(not exists (select 1 from public.teacher_submissions()), 'empty queue');
reset role;

-- ------------------------------------------------------------- teacher --
select pg_temp.login_as_id(current_setting('t.teach')::uuid);
set local role authenticated;
select pg_temp.check((select count(*) from public.teacher_submissions()) = 1, 'teacher sees the work');
select pg_temp.check((select x->'files'->0->>'file_name' from public.teacher_submissions() x) = 'letters.jpg',
  'with its photo');
select pg_temp.check(public.media_url('00000000-0000-0000-0000-0000000e0f02') like 'https://res.cloudinary.com/%',
  'teacher can open the photo');
select pg_temp.expect_error($q$select public.review_submission('00000000-0000-0000-0000-0000000e05b1',
  'reviewed', 'x', 11)$q$, 'cannot exceed');
select public.review_submission('00000000-0000-0000-0000-0000000e05b1', 'resubmission_requested',
  'Your ت needs two dots above.', 6);
reset role;

select pg_temp.login_as_id(current_setting('t.la')::uuid);
set local role authenticated;
select pg_temp.check((select x->>'feedback' from public.my_submissions() x limit 1)
                     = 'Your ت needs two dots above.', 'learner reads the feedback');
select pg_temp.check((public.submit_work('00000000-0000-0000-0000-0000000e05b4',
  '00000000-0000-0000-0000-0000000e0e01', 'Fixed', '[]')->>'attempt')::int = 2,
  'resubmission is attempt 2');
reset role;

-- ------------------------------------------------ hidden / move / copy --
update courses set visibility = 'hidden' where id = '00000000-0000-0000-0000-0000000e0001';
select pg_temp.login_as_id(current_setting('t.lb')::uuid);
set local role authenticated;
select pg_temp.check(not exists (select 1 from courses where id = '00000000-0000-0000-0000-0000000e0001'),
  'hidden course not in the catalogue');
reset role;
select pg_temp.login_as_id(current_setting('t.la')::uuid);
set local role authenticated;
select pg_temp.check(exists (select 1 from courses where id = '00000000-0000-0000-0000-0000000e0001'),
  'its learners still see it');
reset role;

select pg_temp.login_as('admin_1');
set local role authenticated;
insert into course_units (id, course_id, title, position, status) values
  ('00000000-0000-0000-0000-0000000e0b01', '00000000-0000-0000-0000-0000000e0001', 'Stage 2', 1, 'published');
select pg_temp.check((public.move_lesson('00000000-0000-0000-0000-0000000e0a01',
  '00000000-0000-0000-0000-0000000e0b01')->>'unit_id') = '00000000-0000-0000-0000-0000000e0b01',
  'lesson moved into a unit');
select pg_temp.expect_error($q$select public.move_lesson('00000000-0000-0000-0000-0000000e0a01',
  (select id from course_units where course_id <> '00000000-0000-0000-0000-0000000e0001' limit 1))$q$,
  'another course');
select set_config('t.copy', public.copy_lesson('00000000-0000-0000-0000-0000000e0a01',
  '00000000-0000-0000-0000-0000000e0002')->>'id', true);
select pg_temp.check((select status::text from lessons where id = current_setting('t.copy')::uuid) = 'draft'
                     and (select count(*) from lesson_content_blocks
                          where lesson_id = current_setting('t.copy')::uuid) = 3
                     and (select count(*) from resource_links
                          where lesson_id = current_setting('t.copy')::uuid) = 2,
  'copy brings content and resources, as a draft');
select pg_temp.check(public.request_payment_diagnostics() is not null, 'admins can run MarzPay tests');
reset role;

select pg_temp.login_as_id(current_setting('t.la')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.request_payment_diagnostics()$q$, 'not allowed');
select pg_temp.check(public.payment_integration_status() is null, 'learners see no payment status');
reset role;

-- ------------------------------------------------ payments self-test --
set local role sidra_payments;
select pg_temp.check((payments_api.selftest_idempotency()->>'verified_rows')::int = 1
                     and payments_api.selftest_idempotency()->>'second' = 'verified',
  'a duplicate notification credits once');
select payments_api.heartbeat('test', null);
reset role;
select pg_temp.check(not exists (select 1 from payments where provider_uuid like 'selftest-%'),
  'self-test leaves nothing behind');

select 'ALL PHASE 3 TESTS PASSED' as result;
