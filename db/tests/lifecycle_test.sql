-- Course lifecycle (0014): review, publish checks, archive instead of delete,
-- external links, self-enrolment switch. Uses the access_test fixtures.

select pg_temp.login_as('admin_1');
set local role authenticated;

insert into courses (id, slug, title, subject, self_enrol)
values ('00000000-0000-0000-0000-00000000c1f1', 'lifecycle', 'Lifecycle', 'Quran', false);

select pg_temp.check((public.course_publish_check('00000000-0000-0000-0000-00000000c1f1')
                      ->'errors'->0->>'code') = 'no_published_lessons',
  'an empty course cannot be published');
select pg_temp.expect_error($q$select public.set_course_status(
  '00000000-0000-0000-0000-00000000c1f1', 'in_review')$q$, 'not ready');

insert into lessons (id, course_id, title, position, status)
values ('00000000-0000-0000-0000-00000000c1a1', '00000000-0000-0000-0000-00000000c1f1',
        'Lesson one', 0, 'published'),
       ('00000000-0000-0000-0000-00000000c1a2', '00000000-0000-0000-0000-00000000c1f1',
        'Lesson two', 1, 'draft');
select pg_temp.check(
  (select array_agg(w->>'code' order by w->>'code')
     from jsonb_array_elements(public.course_publish_check(
            '00000000-0000-0000-0000-00000000c1f1')->'warnings') w)
  = array['draft_lessons', 'empty_lessons', 'no_description', 'no_teacher', 'no_thumbnail'],
  'warnings list what is missing');

-- External links: YouTube / Telegram / web, http(s) only.
insert into lesson_content_blocks (lesson_id, position, block_type, body)
values ('00000000-0000-0000-0000-00000000c1a1', 0, 'external_link',
        '{"url": "https://youtu.be/dQw4w9WgXcQ", "provider": "youtube", "title": "Makharij"}');
insert into lesson_content_blocks (lesson_id, position, block_type, body)
values ('00000000-0000-0000-0000-00000000c1a1', 1, 'external_link',
        '{"url": "https://t.me/almuntahha/12", "provider": "telegram"}');
select pg_temp.expect_error($q$insert into lesson_content_blocks (lesson_id, position, block_type, body)
  values ('00000000-0000-0000-0000-00000000c1a1', 2, 'external_link',
          '{"url": "javascript:alert(1)"}')$q$, 'lesson_content_blocks_valid');
select pg_temp.expect_error($q$insert into lesson_content_blocks (lesson_id, position, block_type, body)
  values ('00000000-0000-0000-0000-00000000c1a1', 2, 'external_link',
          '{"url": "https://example.com", "provider": "tiktok"}')$q$, 'lesson_content_blocks_valid');

-- draft → in_review → back to draft with a note → published.
select pg_temp.check((public.set_course_status('00000000-0000-0000-0000-00000000c1f1',
                        'in_review', 'Ready for a look'))->>'review_note' = 'Ready for a look',
  'submitted for review with a note');
select pg_temp.check((public.admin_overview()->>'courses_in_review')::int >= 1,
  'dashboard counts courses in review');
select pg_temp.check((public.set_course_status('00000000-0000-0000-0000-00000000c1f1',
                        'draft', 'Add the audio'))->>'review_note' = 'Add the audio',
  'returned to draft with feedback');
select pg_temp.check((public.set_course_status('00000000-0000-0000-0000-00000000c1f1',
                        'published'))->>'published_at' is not null,
  'published');
select pg_temp.check((select review_note from courses
                      where id = '00000000-0000-0000-0000-00000000c1f1') is null,
  'publishing clears the review note');

-- Published courses are archived, never deleted.
select pg_temp.expect_error($q$delete from courses
  where id = '00000000-0000-0000-0000-00000000c1f1'$q$, 'archive it instead');
select pg_temp.check((public.set_course_status('00000000-0000-0000-0000-00000000c1f1',
                        'archived'))->>'archived_at' is not null,
  'archived');
select pg_temp.expect_error($q$select public.set_course_status(
  '00000000-0000-0000-0000-00000000c1f1', 'published')$q$, 'restore this archived course');
select pg_temp.check((public.set_course_status('00000000-0000-0000-0000-00000000c1f1',
                        'draft'))->>'archived_at' is null,
  'restored to draft');
select public.set_course_status('00000000-0000-0000-0000-00000000c1f1', 'published');

-- A never-published draft without learners can be deleted.
insert into courses (id, slug, title, subject)
values ('00000000-0000-0000-0000-00000000c1f2', 'scratch', 'Scratch', 'Fiqh');
delete from courses where id = '00000000-0000-0000-0000-00000000c1f2';
select pg_temp.check(not exists (select 1 from courses
                                 where id = '00000000-0000-0000-0000-00000000c1f2'),
  'unused draft deleted');
reset role;

-- Learners: no self-enrolment when it is switched off; review is invisible.
select pg_temp.login_as('learner_a');
set local role authenticated;
select pg_temp.expect_error($q$select public.enrol_in_course(
  '00000000-0000-0000-0000-00000000c1f1')$q$, 'requires access');
reset role;

select pg_temp.login_as('admin_1');
set local role authenticated;
select public.set_course_status('00000000-0000-0000-0000-00000000c1f1', 'draft');
select public.set_course_status('00000000-0000-0000-0000-00000000c1f1', 'in_review');
reset role;
select pg_temp.login_as('learner_a');
set local role authenticated;
select pg_temp.check(not exists (select 1 from courses
                                 where id = '00000000-0000-0000-0000-00000000c1f1'),
  'courses in review are hidden from learners');
reset role;

select 'ALL LIFECYCLE TESTS PASSED' as result;
