-- 0050: one call per screen returns what the separate reads returned, under
-- the same Row Level Security (the functions run with the caller's rights).

select set_config('sb.l', app_private.create_account('Bundle Learner', '+256772750001', null, null,
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('sb.a', app_private.create_account('Bundle Admin', null, null, 'sb_admin',
  'admin', false, 'staff-pass-1', false)::text, true);

insert into courses (id, slug, title, subject, access, price_amount, price_currency, progression, status, language) values
  ('00000000-0000-0000-0000-000000091001', 'sb-paid', 'SB Paid', 'Quran', 'paid', 50000, 'UGX', 'open', 'published', 'en'),
  ('00000000-0000-0000-0000-000000091002', 'sb-draft', 'SB Draft', 'Quran', 'free', null, null, 'open', 'draft', 'en');
insert into course_units (id, course_id, title, position, status) values
  ('00000000-0000-0000-0000-000000092001', '00000000-0000-0000-0000-000000091001', 'Unit B', 1, 'published'),
  ('00000000-0000-0000-0000-000000092002', '00000000-0000-0000-0000-000000091001', 'Unit A', 0, 'published');
insert into lessons (id, course_id, title, position, status, is_preview) values
  ('00000000-0000-0000-0000-000000093001', '00000000-0000-0000-0000-000000091001', 'Intro', 0, 'published', true),
  ('00000000-0000-0000-0000-000000093002', '00000000-0000-0000-0000-000000091001', 'Lesson 1', 1, 'published', false),
  ('00000000-0000-0000-0000-000000093003', '00000000-0000-0000-0000-000000091001', 'Hidden draft', 2, 'draft', false);
insert into books (id, title, status) values
  ('00000000-0000-0000-0000-000000094001', 'SB Book', 'published');
insert into book_structures (id, book_id, name, is_default) values
  ('00000000-0000-0000-0000-000000095001', '00000000-0000-0000-0000-000000094001', 'Other', false),
  ('00000000-0000-0000-0000-000000095002', '00000000-0000-0000-0000-000000094001', 'Default', true);
insert into book_structure_levels (id, structure_id, depth, node_type, label_singular, label_plural) values
  ('00000000-0000-0000-0000-000000096002', '00000000-0000-0000-0000-000000095002', 2, 'verse', 'Verse', 'Verses'),
  ('00000000-0000-0000-0000-000000096001', '00000000-0000-0000-0000-000000095002', 1, 'surah', 'Surah', 'Surahs'),
  ('00000000-0000-0000-0000-000000096009', '00000000-0000-0000-0000-000000095001', 1, 'chapter', 'Chapter', 'Chapters');
insert into course_books (course_id, book_id, position) values
  ('00000000-0000-0000-0000-000000091001', '00000000-0000-0000-0000-000000094001', 0);
insert into curriculum_nodes (id, course_id, structure_level_id, title, position, status) values
  ('00000000-0000-0000-0000-000000097001', '00000000-0000-0000-0000-000000091001',
   '00000000-0000-0000-0000-000000096001', 'Al-Fatihah', 0, 'published');

-- ---------------------------------------------------- as a learner -----
select pg_temp.login_as_id(current_setting('sb.l')::uuid);
set local role authenticated;

select set_config('sb.o', public.course_outline('00000000-0000-0000-0000-000000091001')::text, true);
select pg_temp.check(current_setting('sb.o')::jsonb->'course'->>'title' = 'SB Paid', 'outline: the course');
select pg_temp.check(
  jsonb_array_length(current_setting('sb.o')::jsonb->'lessons')
    = (select count(*) from lessons where course_id = '00000000-0000-0000-0000-000000091001'),
  'outline: exactly the lessons this learner may see (RLS as before)');
select pg_temp.check(
  not (current_setting('sb.o')::jsonb->'lessons') @> '[{"title": "Hidden draft"}]',
  'outline: a draft lesson stays hidden from learners');
select pg_temp.check(
  (select array_agg(e->>'title') from jsonb_array_elements(current_setting('sb.o')::jsonb->'units') e)
    = array['Unit A', 'Unit B'],
  'outline: units in position order');
select pg_temp.check(
  (select array_agg(e->>'lesson_id') from jsonb_array_elements(current_setting('sb.o')::jsonb->'order') e)
    is not distinct from
  (select array_agg(o.lesson_id::text) from public.course_lesson_order('00000000-0000-0000-0000-000000091001') o),
  'outline: lesson order as course_lesson_order returns it');
select pg_temp.check(
  not (current_setting('sb.o')::jsonb->'order'->0) ? 'ordinality',
  'outline: no helper column in the order entries');
select pg_temp.check(
  (current_setting('sb.o')::jsonb->'books'->0->>'title') = 'SB Book'
  and jsonb_array_length(current_setting('sb.o')::jsonb->'course_books') = 1,
  'outline: the course''s books');
select pg_temp.check(
  (select array_agg(e->>'label_singular') from jsonb_array_elements(current_setting('sb.o')::jsonb->'levels') e)
    = array['Surah'],
  'outline: labels of the levels its nodes use');
select pg_temp.check(public.course_outline('00000000-0000-0000-0000-000000091002') is null,
  'outline: a draft course is not shown to a learner');
select pg_temp.check(public.course_outline('00000000-0000-0000-0000-0000000999ff') is null,
  'outline: unknown course gives null');

reset role;

-- ----------------------------------------------------- as an admin -----
select pg_temp.login_as_id(current_setting('sb.a')::uuid);
set local role authenticated;

select pg_temp.check(public.course_outline('00000000-0000-0000-0000-000000091002') is not null,
  'admin sees the draft course');
select set_config('sb.b', public.course_builder_data('00000000-0000-0000-0000-000000091001')::text, true);
select pg_temp.check(
  jsonb_array_length(current_setting('sb.b')::jsonb->'lessons') = 3,
  'builder: every lesson, drafts included, for an admin');
select pg_temp.check(
  (select array_agg(e->>'label_singular')
   from jsonb_array_elements(current_setting('sb.b')::jsonb->'levels_by_book'->'00000000-0000-0000-0000-000000094001') e)
    = array['Surah', 'Verse'],
  'builder: the book''s DEFAULT structure, levels by depth');
select pg_temp.check(
  (current_setting('sb.b')::jsonb->'books') @> '[{"title": "SB Book"}]',
  'builder: all books for linking');
select pg_temp.check(public.course_builder_data('00000000-0000-0000-0000-0000000999ff') is null,
  'builder: unknown course gives null');

reset role;
