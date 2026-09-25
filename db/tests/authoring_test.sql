-- Authoring permissions used by the in-app teacher/admin console.
-- Runs after access_test.sql in the SAME rolled-back transaction, so it
-- reuses those fixtures (courses c01/c02, teacher_1, learner_a, …).

-- ============================================ teacher (not an editor) ==
select pg_temp.login_as('teacher_1');
set local role authenticated;
select pg_temp.expect_error($q$
  insert into lessons (course_id, title, position)
  values ('00000000-0000-0000-0000-000000000c01', 'teacher lesson', 9)$q$,
  'row-level security');
select pg_temp.check((select count(*) from course_units
                      where course_id = '00000000-0000-0000-0000-000000000c01') = 1,
  'teacher can read their course outline');
reset role;

-- Promote teacher_1 to curriculum editor of c01 (as the admin console does).
update course_staff set role = 'editor'
where course_id = '00000000-0000-0000-0000-000000000c01'
  and user_id = '00000000-0000-0000-0000-00000000000b';

-- ============================================ course editor ==
select pg_temp.login_as('teacher_1');
set local role authenticated;
insert into lessons (id, course_id, node_id, title, position, status)
values ('00000000-0000-0000-0000-000000001009', '00000000-0000-0000-0000-000000000c01',
        '00000000-0000-0000-0000-000000000e02', 'Editor lesson', 5, 'draft');
insert into lesson_content_blocks (lesson_id, position, block_type, body)
values ('00000000-0000-0000-0000-000000001009', 0, 'rich_text', '{"text":"Hello"}');
select pg_temp.check((select content_version from lessons
                      where id = '00000000-0000-0000-0000-000000001009') > 1,
  'adding content bumps the lesson content_version');
select pg_temp.expect_error($q$
  insert into lessons (course_id, title, position)
  values ('00000000-0000-0000-0000-000000000c02', 'not my course', 0)$q$,
  'row-level security');
select pg_temp.expect_error($q$
  insert into courses (slug, title, subject) values ('editor-course', 'X', 'Y')$q$,
  'row-level security');
select pg_temp.expect_error($q$
  insert into books (title) values ('Editor book')$q$,
  'row-level security');
-- Editors may publish their course through the API function.
select pg_temp.check((public.set_course_status(
    '00000000-0000-0000-0000-000000000c01', 'published'))->>'status' = 'published',
  'editor can publish own course');
select pg_temp.expect_error($q$select public.set_course_status(
  '00000000-0000-0000-0000-000000000c02', 'draft')$q$, 'not allowed to change this course');
-- Direct status edits are not a granted column.
select pg_temp.expect_error($q$update courses set status = 'draft'
  where id = '00000000-0000-0000-0000-000000000c01'$q$, 'permission denied');
reset role;

-- ============================================ learner ==
select pg_temp.login_as('learner_a');
set local role authenticated;
select pg_temp.check(not exists (select 1 from lessons
                                 where id = '00000000-0000-0000-0000-000000001009'),
  'draft lesson invisible to learners');
select pg_temp.expect_error($q$
  insert into lesson_content_blocks (lesson_id, position, block_type, body)
  values ('00000000-0000-0000-0000-000000001001', 7, 'rich_text', '{"text":"x"}')$q$,
  'row-level security');
select pg_temp.expect_error($q$
  insert into media_assets (kind, resource_type, public_id, uploaded_by)
  values ('image', 'image', 'sidra/content/sneaky',
          '00000000-0000-0000-0000-0000000000a1')$q$,
  'row-level security');
insert into media_assets (kind, resource_type, public_id, uploaded_by)
values ('audio', 'video',
        'sidra/submissions/00000000-0000-0000-0000-0000000000a1/recitation1',
        '00000000-0000-0000-0000-0000000000a1');
select pg_temp.check(exists (select 1 from media_assets
                             where public_id like 'sidra/submissions/%recitation1'),
  'learner can register own recitation upload and read it back');
select pg_temp.expect_error($q$
  insert into course_staff (course_id, user_id, role)
  values ('00000000-0000-0000-0000-000000000c01',
          '00000000-0000-0000-0000-0000000000a1', 'editor')$q$,
  'row-level security');
select pg_temp.expect_error($q$
  update users set display_name = 'Aisha Updated', role = 'admin'
  where auth_subject = 'learner_a'$q$, 'permission denied');
update users set display_name = 'Aisha Updated' where id = '00000000-0000-0000-0000-0000000000a1';
select pg_temp.check((select display_name from users where id = '00000000-0000-0000-0000-0000000000a1')
  = 'Aisha Updated', 'learner can edit own display name');
reset role;

-- ============================================ admin ==
select pg_temp.login_as('admin_1');
set local role authenticated;
insert into courses (id, slug, title, subject)
values ('00000000-0000-0000-0000-000000000c09', 'admin-course', 'Admin course', 'Fiqh');
insert into books (id, title) values ('00000000-0000-0000-0000-000000000b09', 'Admin book');
insert into book_structures (id, book_id, name, is_default)
values ('00000000-0000-0000-0000-000000000509', '00000000-0000-0000-0000-000000000b09',
        'Page by page', true);
insert into book_structure_levels (structure_id, depth, node_type, label_singular, label_plural)
values ('00000000-0000-0000-0000-000000000509', 1, 'page', 'Page', 'Pages');
insert into course_staff (course_id, user_id, role)
values ('00000000-0000-0000-0000-000000000c09', '00000000-0000-0000-0000-00000000000b', 'teacher');
select pg_temp.check(exists (select 1 from courses where slug = 'admin-course'),
  'admin can create courses and read them back (draft)');
reset role;

select 'ALL AUTHORING TESTS PASSED' as result;
