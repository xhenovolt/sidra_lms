-- Phase 3.5: teaching portions, group assignment, attempts, reviews,
-- reusable corrections, notes, notifications — and the RETURNING fix.

select set_config('t.tt', app_private.create_account('Ustadh Tt', null, null, 'tt_teacher',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('t.tt')::uuid, 'teacher');
select set_config('t.ot', app_private.create_account('Other Tt', null, null, 'tt_other',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('t.ot')::uuid, 'teacher');
select set_config('t.a', app_private.create_account('Ahmad', null, null, 'tt_ahmad',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('t.b', app_private.create_account('Aisha', null, null, 'tt_aisha',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('t.c', app_private.create_account('Yusuf', null, null, 'tt_yusuf',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('t.x', app_private.create_account('Outsider', null, null, 'tt_out',
  'learner', false, 'learner-pass-1', false)::text, true);

insert into courses (id, slug, title, subject, access, progression, status, language)
values ('00000000-0000-0000-0000-0000000aa001', 'tt-yassarna', 'TT Yassarna', 'Quran',
        'restricted', 'open', 'published', 'en');
insert into course_staff (course_id, user_id, role)
values ('00000000-0000-0000-0000-0000000aa001', current_setting('t.tt')::uuid, 'teacher');
insert into course_enrolments (course_id, user_id, status, source)
select '00000000-0000-0000-0000-0000000aa001', u, 'active', 'admin_grant'
from unnest(array[current_setting('t.a')::uuid, current_setting('t.b')::uuid,
                  current_setting('t.c')::uuid]) u;

-- The page image, instruction and model: stored ONCE.
insert into media_assets (id, kind, resource_type, delivery, public_id, format, uploaded_by) values
  ('00000000-0000-0000-0000-0000000aaf01', 'image', 'image', 'authenticated', 'sidra/p/page12', 'jpg', current_setting('t.tt')::uuid),
  ('00000000-0000-0000-0000-0000000aaf02', 'audio', 'video', 'authenticated', 'sidra/p/instr12', 'm4a', current_setting('t.tt')::uuid),
  ('00000000-0000-0000-0000-0000000aaf03', 'audio', 'video', 'authenticated', 'sidra/p/model12', 'm4a', current_setting('t.tt')::uuid);

-- ------------------------------------------ teacher: group + portion --
select pg_temp.login_as_id(current_setting('t.tt')::uuid);
set local role authenticated;

-- RETURNING regression: insert-and-read-back works for resources.
-- (a failure raises "new row violates row-level security policy")
insert into resources (kind, title, provider, media_asset_id, uploaded_by)
values ('image', 'Page 12', 'cloudinary', '00000000-0000-0000-0000-0000000aaf01',
        app_private.current_user_id())
returning id;
insert into resources (id, kind, title, provider, media_asset_id, uploaded_by) values
  ('00000000-0000-0000-0000-0000000aad01', 'image', 'Yassarna page 12', 'cloudinary',
   '00000000-0000-0000-0000-0000000aaf01', app_private.current_user_id()),
  ('00000000-0000-0000-0000-0000000aad02', 'audio', 'Page 12: read slowly', 'cloudinary',
   '00000000-0000-0000-0000-0000000aaf02', app_private.current_user_id()),
  ('00000000-0000-0000-0000-0000000aad03', 'audio', 'Page 12: model reading', 'cloudinary',
   '00000000-0000-0000-0000-0000000aaf03', app_private.current_user_id());
insert into assignments (course_id, title, status)
values ('00000000-0000-0000-0000-0000000aa001', 'Readback', 'draft')
returning id;

select pg_temp.expect_error($q$select public.save_teaching_group('00000000-0000-0000-0000-0000000aa001',
  'Group A', array[current_setting('t.x')::uuid])$q$, 'not enrolled');
select set_config('t.g', public.save_teaching_group('00000000-0000-0000-0000-0000000aa001', 'Group A',
  array[current_setting('t.a')::uuid, current_setting('t.b')::uuid, current_setting('t.c')::uuid])->>'id', true);
select set_config('t.p', public.save_portion('00000000-0000-0000-0000-0000000aa001', 'Page 12',
  current_setting('t.g')::uuid, null, 'Read this page three times. Watch the shaddah.', 'en')->>'id', true);
select public.set_portion_resource(current_setting('t.p')::uuid, '00000000-0000-0000-0000-0000000aad01', 'page');
select public.set_portion_resource(current_setting('t.p')::uuid, '00000000-0000-0000-0000-0000000aad02', 'instruction');
select public.set_portion_resource(current_setting('t.p')::uuid, '00000000-0000-0000-0000-0000000aad03', 'model');
select pg_temp.check(public.assign_portion(current_setting('t.p')::uuid) = 3, 'one action → 3 learners');
select pg_temp.check(public.assign_portion(current_setting('t.p')::uuid) = 0, 'assigning twice adds nobody');
select pg_temp.check((select count(*) from resources where media_asset_id = '00000000-0000-0000-0000-0000000aaf01') = 2
                     and (select count(*) from portion_resources where portion_id = current_setting('t.p')::uuid) = 3,
  'files are shared, not copied per learner');
reset role;

-- ------------------------------------------------------ learners --
insert into media_assets (id, kind, resource_type, delivery, public_id, format, uploaded_by) values
  ('00000000-0000-0000-0000-0000000aaf11', 'audio', 'video', 'authenticated',
   'sidra/submissions/' || current_setting('t.a') || '/r1', 'm4a', current_setting('t.a')::uuid),
  ('00000000-0000-0000-0000-0000000aaf12', 'audio', 'video', 'authenticated',
   'sidra/submissions/' || current_setting('t.b') || '/r1', 'm4a', current_setting('t.b')::uuid),
  ('00000000-0000-0000-0000-0000000aaf13', 'audio', 'video', 'authenticated',
   'sidra/submissions/' || current_setting('t.c') || '/r1', 'm4a', current_setting('t.c')::uuid),
  ('00000000-0000-0000-0000-0000000aaf14', 'audio', 'video', 'authenticated',
   'sidra/submissions/' || current_setting('t.c') || '/r2', 'm4a', current_setting('t.c')::uuid);

select pg_temp.login_as_id(current_setting('t.a')::uuid);
set local role authenticated;
insert into media_assets (kind, resource_type, delivery, public_id, format, uploaded_by)
values ('audio', 'video', 'authenticated',
        'sidra/submissions/' || app_private.current_user_id() || '/readback', 'm4a',
        app_private.current_user_id())
returning id;
select pg_temp.check((select count(*) from public.learner_today()) = 1, 'Ahmad sees today''s portion');
select pg_temp.check((select x->>'title' from public.learner_today() x) = 'Page 12'
                     and jsonb_array_length((select x->'resources' from public.learner_today() x)) = 3,
  'with its page, instruction and model');
select pg_temp.check(public.media_url('00000000-0000-0000-0000-0000000aaf02') like 'https://%',
  'learner plays the teacher''s instruction');
select pg_temp.check(exists (select 1 from notifications where kind = 'portion_assigned'),
  'learner was notified');
select public.open_portion(current_setting('t.p')::uuid);
select public.submit_portion('00000000-0000-0000-0000-0000000aa501', current_setting('t.p')::uuid, null,
  '[{"media_asset_id": "00000000-0000-0000-0000-0000000aaf11", "file_name": "r1.m4a"}]');
select pg_temp.expect_error($q$select public.submit_portion('00000000-0000-0000-0000-0000000aa599',
  current_setting('t.p')::uuid, 'again', '[]')$q$, 'wait for your teacher');
select pg_temp.check((select x->'participation'->>'status' from public.learner_today() x) = 'submitted',
  'waiting for teacher review');
reset role;

select pg_temp.login_as_id(current_setting('t.b')::uuid);
set local role authenticated;
select public.submit_portion('00000000-0000-0000-0000-0000000aa502', current_setting('t.p')::uuid, null,
  '[{"media_asset_id": "00000000-0000-0000-0000-0000000aaf12"}]');
select pg_temp.expect_error($q$select public.media_url('00000000-0000-0000-0000-0000000aaf11')$q$,
  'media is locked');
select pg_temp.check((select count(*) from submissions) = 1, 'Aisha sees only her own work');
reset role;

select pg_temp.login_as_id(current_setting('t.c')::uuid);
set local role authenticated;
select public.submit_portion('00000000-0000-0000-0000-0000000aa503', current_setting('t.p')::uuid, null,
  '[{"media_asset_id": "00000000-0000-0000-0000-0000000aaf13"}]');
reset role;

select pg_temp.login_as_id(current_setting('t.x')::uuid);
set local role authenticated;
select pg_temp.check(not exists (select 1 from public.learner_today()), 'outsider sees nothing');
select pg_temp.expect_error($q$select public.media_url('00000000-0000-0000-0000-0000000aaf01')$q$,
  'media is locked');
select pg_temp.expect_error($q$select public.submit_portion('00000000-0000-0000-0000-0000000aa504',
  current_setting('t.p')::uuid, 'x', '[]')$q$, 'portion not found');
reset role;

-- ------------------------------------------------------ teacher reviews --
select pg_temp.login_as_id(current_setting('t.tt')::uuid);
set local role authenticated;
select pg_temp.check(jsonb_array_length(public.teacher_attention()->'new_submissions') = 3,
  'Needs my attention: three new submissions');
select pg_temp.check(exists (select 1 from notifications where kind = 'submission'),
  'teacher was notified');
select pg_temp.check(jsonb_array_length(public.portion_board(current_setting('t.p')::uuid)->'learners') = 3,
  'review board lists every learner');
select pg_temp.check(public.media_url('00000000-0000-0000-0000-0000000aaf11') like 'https://%',
  'teacher plays Ahmad''s recording');

-- Ahmad: correct.
select public.review_attempt('00000000-0000-0000-0000-0000000aa501', 'correct');
-- Yusuf: unusual mistake → new recording, saved to the library.
insert into media_assets (id, kind, resource_type, delivery, public_id, format, uploaded_by)
values ('00000000-0000-0000-0000-0000000aaf21', 'audio', 'video', 'authenticated', 'sidra/corr/sad-sin',
        'm4a', app_private.current_user_id());
select set_config('t.corr', (public.review_attempt('00000000-0000-0000-0000-0000000aa503',
  'correction_required', 'Listen to the difference.', null, '00000000-0000-0000-0000-0000000aaf21', null,
  jsonb_build_object('title', 'Difference between ص and س',
    'category_id', app_private.seed_id('correction-category:Pronunciation (letters)/س / ص'),
    'tags', jsonb_build_array('ص', 'س')))->>'correction_id'), true);
-- Aisha: same mistake → the saved correction, no new recording.
select pg_temp.check((select x->>'id' from public.search_corrections('ص') x limit 1) = current_setting('t.corr'),
  'the new correction is found in the library');
select public.review_attempt('00000000-0000-0000-0000-0000000aa502', 'correction_required', null,
  current_setting('t.corr')::uuid);
select pg_temp.check((select use_count from corrections where id = current_setting('t.corr')::uuid) = 2,
  'correction reused');
select public.add_teacher_note(current_setting('t.c')::uuid, 'Still confusing ص and س.',
  '00000000-0000-0000-0000-0000000aa001');
select pg_temp.check((public.teaching_analytics(30)->>'reviewed')::int = 3, 'analytics count reviews');
reset role;

select pg_temp.login_as_id(current_setting('t.b')::uuid);
set local role authenticated;
select pg_temp.check((select x->'attempts'->0->'reviews'->0->'correction'->>'title' from public.learner_today() x)
                     = 'Difference between ص and س', 'Aisha sees the correction');
select pg_temp.check(public.media_url('00000000-0000-0000-0000-0000000aaf21') like 'https://%',
  'and can play it');
select pg_temp.check(not exists (select 1 from teacher_notes), 'learners never see teacher notes');
select pg_temp.check(not exists (select 1 from public.learner_notes(current_setting('t.c')::uuid)),
  'nor through the notes function');
reset role;

select pg_temp.login_as_id(current_setting('t.c')::uuid);
set local role authenticated;
select pg_temp.check((select x->'participation'->>'status' from public.learner_today() x) = 'correction_required',
  'Yusuf must try again');
select pg_temp.check((public.submit_portion('00000000-0000-0000-0000-0000000aa505', current_setting('t.p')::uuid,
  null, '[{"media_asset_id": "00000000-0000-0000-0000-0000000aaf14"}]')->>'attempt')::int = 2,
  'attempt 2 kept separately');
select pg_temp.check((select count(*) from submissions) = 2, 'history kept: two attempts');
reset role;

select pg_temp.login_as_id(current_setting('t.tt')::uuid);
set local role authenticated;
select pg_temp.check(jsonb_array_length(public.teacher_attention()->'resubmissions') = 1,
  'resubmission surfaces');
select public.review_attempt('00000000-0000-0000-0000-0000000aa505', 'excellent');
select set_config('t.next', public.next_portion(current_setting('t.p')::uuid)->>'id', true);
select pg_temp.check((select title from teaching_portions where id = current_setting('t.next')::uuid) = 'Page 13',
  'next portion: Page 12 → Page 13');
select pg_temp.check((select array_agg(role order by role) from portion_resources
                      where portion_id = current_setting('t.next')::uuid) = array['instruction', 'model'],
  'instruction and model carry over; the page does not');
-- Individual pace: Page 13 only for Ahmad.
select pg_temp.check(public.assign_portion(current_setting('t.next')::uuid,
  array[current_setting('t.a')::uuid]) = 1, 'assign to one learner');
reset role;

-- Another teacher of another course sees none of it.
select pg_temp.login_as_id(current_setting('t.ot')::uuid);
set local role authenticated;
select pg_temp.check(public.portion_board(current_setting('t.p')::uuid) is null, 'other teacher: no board');
select pg_temp.check(not exists (select 1 from submissions), 'other teacher: no submissions');
select pg_temp.expect_error($q$select public.review_attempt('00000000-0000-0000-0000-0000000aa502', 'correct')$q$,
  'submission not found');
select pg_temp.check(not exists (select 1 from teacher_notes), 'other teacher: no notes');
reset role;

-- Versioning: replacing the page keeps history for assigned portions.
select pg_temp.login_as('admin_1');
set local role authenticated;
insert into media_assets (id, kind, resource_type, delivery, public_id, format, uploaded_by)
values ('00000000-0000-0000-0000-0000000aaf31', 'image', 'image', 'authenticated', 'sidra/p/page12-v2',
        'jpg', app_private.current_user_id());
select set_config('t.v2', public.replace_resource('00000000-0000-0000-0000-0000000aad01',
  '00000000-0000-0000-0000-0000000aaf31')->>'id', true);
select pg_temp.check((select resource_id from portion_resources
                      where portion_id = current_setting('t.p')::uuid and role = 'page')
                     = '00000000-0000-0000-0000-0000000aad01', 'assigned portion keeps the version learners saw');
select pg_temp.check((select version from resources where id = current_setting('t.v2')::uuid) = 2,
  'new version recorded');
reset role;

-- Content library: where a resource is used.
select pg_temp.login_as('admin_1');
set local role authenticated;
select pg_temp.check((select count(*) from public.resource_usages('00000000-0000-0000-0000-0000000aad02') u
                      where u->>'target' = 'portion') >= 1, 'usage lists the portions using it');
reset role;
select pg_temp.login_as_id(current_setting('t.a')::uuid);
set local role authenticated;
select pg_temp.check(not exists (select 1 from public.resource_usages('00000000-0000-0000-0000-0000000aad02')),
  'learners cannot list usages');
reset role;

select 'ALL TEACHING TESTS PASSED' as result;
