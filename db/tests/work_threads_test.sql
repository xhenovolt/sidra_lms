-- 0043: learner work as a thread — many attempts, many files, replies from
-- both sides without a verdict, what each attempt is for, and who may see it.

select set_config('w.t', app_private.create_account('Ustadh Wt', null, null, 'wt_teacher',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('w.t')::uuid, 'teacher');
select set_config('w.o', app_private.create_account('Other Wt', null, null, 'wt_other',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('w.o')::uuid, 'teacher');
select set_config('w.a', app_private.create_account('Ahmed Wt', null, null, 'wt_ahmed',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('w.b', app_private.create_account('Bilal Wt', null, null, 'wt_bilal',
  'learner', false, 'learner-pass-1', false)::text, true);

insert into courses (id, slug, title, subject, access, progression, status, language)
values ('00000000-0000-0000-0000-00000009a001', 'wt-quran', 'WT Quran', 'Quran',
        'restricted', 'open', 'published', 'en');
insert into course_staff (course_id, user_id, role)
values ('00000000-0000-0000-0000-00000009a001', current_setting('w.t')::uuid, 'teacher');
insert into course_enrolments (course_id, user_id, status, source)
select '00000000-0000-0000-0000-00000009a001', u, 'active', 'admin_grant'
from unnest(array[current_setting('w.a')::uuid, current_setting('w.b')::uuid]) u;

-- Learners' recordings and photos, and the teacher's voice notes.
insert into media_assets (id, kind, resource_type, delivery, public_id, format, uploaded_by)
select ('00000000-0000-0000-0000-0000009bf' || n)::uuid, k::media_kind,
       case when k = 'image' then 'image' else 'video' end, 'authenticated',
       'sidra/wt/' || n, case when k = 'image' then 'jpg' else 'm4a' end, u::uuid
from (values ('a01', 'audio', current_setting('w.a')), ('a02', 'audio', current_setting('w.a')),
             ('a03', 'image', current_setting('w.a')), ('a04', 'image', current_setting('w.a')),
             ('a05', 'audio', current_setting('w.a')), ('a06', 'audio', current_setting('w.a')),
             ('b01', 'audio', current_setting('w.b')),
             ('c01', 'audio', current_setting('w.t')), ('c02', 'audio', current_setting('w.t')),
             ('d01', 'audio', current_setting('w.o'))) v(n, k, u);

-- Teacher: a group and a portion for both learners.
select pg_temp.login_as_id(current_setting('w.t')::uuid);
set local role authenticated;
select set_config('w.g', public.save_teaching_group('00000000-0000-0000-0000-00000009a001', 'WT Group',
  array[current_setting('w.a')::uuid, current_setting('w.b')::uuid])->>'id', true);
select set_config('w.p', public.save_portion('00000000-0000-0000-0000-00000009a001', 'Ayat al-Kursi',
  current_setting('w.g')::uuid, null, 'Recite 2:255 and send it.', 'en')->>'id', true);
select public.assign_portion(current_setting('w.p')::uuid);
reset role;

-- ------------------------------------------ several attempts, targeted --
select pg_temp.login_as_id(current_setting('w.a')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.send_work('00000000-0000-0000-0000-00000009a5ff', 'portion',
  current_setting('w.p')::uuid, null, '[{"media_asset_id": "00000000-0000-0000-0000-0000009bfa01"}]',
  '{"kind": "ayah", "surah": 115, "ayah_start": 1}')$q$, 'unknown target');
select pg_temp.expect_error($q$select public.send_work('00000000-0000-0000-0000-00000009a5fe', 'portion',
  current_setting('w.p')::uuid, null, '[{"media_asset_id": "00000000-0000-0000-0000-0000009bfa01"}]',
  '{"kind": "block", "block_id": "00000000-0000-0000-0000-00000000dead"}')$q$, 'not found');
select pg_temp.expect_error($q$select public.send_work('00000000-0000-0000-0000-00000009a5fd', 'portion',
  current_setting('w.p')::uuid, null, '[{"media_asset_id": "00000000-0000-0000-0000-0000009bfb01"}]')$q$,
  'your own uploads');

-- Attempt 1: a recitation of the ayah.
select public.send_work('00000000-0000-0000-0000-00000009a501', 'portion', current_setting('w.p')::uuid,
  null, '[{"media_asset_id": "00000000-0000-0000-0000-0000009bfa01", "file_name": "r1.m4a"}]',
  '{"kind": "ayah", "surah": 2, "ayah_start": 255, "ayah_end": 255, "label": "2:255"}');
-- Noticed a mistake: attempt 2 before the teacher answers — two photos and a recording.
select public.send_work('00000000-0000-0000-0000-00000009a502', 'portion', current_setting('w.p')::uuid,
  'Here is my writing too.',
  '[{"media_asset_id": "00000000-0000-0000-0000-0000009bfa02", "file_name": "r2.m4a"},
    {"media_asset_id": "00000000-0000-0000-0000-0000009bfa03", "file_name": "p1.jpg"},
    {"media_asset_id": "00000000-0000-0000-0000-0000009bfa04", "file_name": "p2.jpg"}]',
  '{"kind": "page_line", "page": 14, "line": 3, "label": "Page 14, line 3"}');
-- The phone retries the same send (flaky network): nothing new.
select public.send_work('00000000-0000-0000-0000-00000009a502', 'portion', current_setting('w.p')::uuid,
  'Here is my writing too.', '[{"media_asset_id": "00000000-0000-0000-0000-0000009bfa02"}]',
  '{"kind": "whole"}');
reset role;

select pg_temp.check((select count(*) from submissions where portion_id = current_setting('w.p')::uuid
                      and user_id = current_setting('w.a')::uuid) = 2, 'two attempts, the retry added none');
select pg_temp.check((select status from submissions where id = '00000000-0000-0000-0000-00000009a501') = 'superseded'
                     and (select status from submissions where id = '00000000-0000-0000-0000-00000009a502') = 'submitted',
  'the first attempt is kept but no longer waiting');
select pg_temp.check((select count(*) from submission_files
                      where submission_id = '00000000-0000-0000-0000-00000009a502') = 3, 'three files in one attempt');
select pg_temp.check((select target->>'surah' from submissions where id = '00000000-0000-0000-0000-00000009a501') = '2'
                     and (select target->>'line' from submissions where id = '00000000-0000-0000-0000-00000009a502') = '3',
  'each attempt keeps what it was for (a retry does not change it)');

-- ----------------------------------------- the teacher answers, in parts --
select pg_temp.login_as_id(current_setting('w.t')::uuid);
set local role authenticated;
select public.work_reply('00000000-0000-0000-0000-00000009a601', '00000000-0000-0000-0000-00000009a502',
  'voice', 'Listen to the madd here.', '00000000-0000-0000-0000-0000009bfc01', null,
  '{"kind": "ayah", "surah": 2, "ayah_start": 255}', '{"title": "Madd in al-Kursi"}');
select public.work_reply('00000000-0000-0000-0000-00000009a602', '00000000-0000-0000-0000-00000009a502',
  'text', 'Repeat the line slowly.');
-- replay of the same reply: stored once
select public.work_reply('00000000-0000-0000-0000-00000009a602', '00000000-0000-0000-0000-00000009a502',
  'text', 'Repeat the line slowly.');
select set_config('w.c', (select correction_id::text from work_messages
                          where id = '00000000-0000-0000-0000-00000009a601'), true);
select pg_temp.check(current_setting('w.c') <> '', 'the voice note was saved to the library');
-- reused (a reference, not a copy of the audio)
select public.work_reply('00000000-0000-0000-0000-00000009a603', '00000000-0000-0000-0000-00000009a502',
  'correction', null, null, current_setting('w.c')::uuid);
select pg_temp.expect_error($q$select public.work_reply('00000000-0000-0000-0000-00000009a6f1',
  '00000000-0000-0000-0000-00000009a502', 'voice', null, '00000000-0000-0000-0000-0000009bfa05')$q$,
  'your own uploads');
reset role;
select pg_temp.check((select count(*) from work_messages
                      where submission_id = '00000000-0000-0000-0000-00000009a502') = 3, 'three teacher responses');
select pg_temp.check((select status from submissions where id = '00000000-0000-0000-0000-00000009a502') = 'under_review'
                     and (select status from portion_learners where portion_id = current_setting('w.p')::uuid
                          and user_id = current_setting('w.a')::uuid) = 'under_review',
  'answering without a verdict puts the work under review, not marked');
select pg_temp.check((select count(*) from corrections where id = current_setting('w.c')::uuid
                      and media_asset_id = '00000000-0000-0000-0000-0000009bfc01' and use_count = 1) = 1,
  'the correction audio is stored once and its reuse counted');
select pg_temp.check((select count(*) from notifications where user_id = current_setting('w.a')::uuid
                      and kind = 'work_reply') = 3, 'Ahmed is told of each response');
select pg_temp.check(exists (select 1 from audit_log where entity = 'work_messages'
                             and entity_id = '00000000-0000-0000-0000-00000009a601'), 'responses are audited');

-- ------------------------------------------------- Ahmed replies back --
select pg_temp.login_as_id(current_setting('w.a')::uuid);
set local role authenticated;
select pg_temp.check(app_private.can_read_media('00000000-0000-0000-0000-0000009bfc01'),
  'Ahmed can hear the teacher''s voice note');
select pg_temp.check(app_private.can_read_media('00000000-0000-0000-0000-0000009bfc01'),
  'and the library correction sent to him');
select public.work_reply('00000000-0000-0000-0000-00000009a604', '00000000-0000-0000-0000-00000009a502',
  'voice', 'Is this better?', '00000000-0000-0000-0000-0000009bfa05');
select pg_temp.expect_error($q$select public.work_reply('00000000-0000-0000-0000-00000009a6f2',
  '00000000-0000-0000-0000-00000009a502', 'correction', null, null, current_setting('w.c')::uuid)$q$,
  'not allowed');
select pg_temp.expect_error($q$update work_messages set body = 'changed'
  where id = '00000000-0000-0000-0000-00000009a604'$q$, 'permission denied');
select pg_temp.check((select count(*) from jsonb_array_elements(
                        public.work_thread('portion', current_setting('w.p')::uuid)->'events') e
                      where e->>'type' = 'attempt') = 2
                     and (select count(*) from jsonb_array_elements(
                        public.work_thread('portion', current_setting('w.p')::uuid)->'events') e
                      where e->>'type' = 'message') = 4,
  'Ahmed sees his whole thread: 2 attempts, 4 messages');
select pg_temp.check((public.work_thread('portion', current_setting('w.p')::uuid)->'events'->0->>'submission_id')
                     = '00000000-0000-0000-0000-00000009a501', 'oldest first');
reset role;
select pg_temp.check((select count(*) from notifications where user_id = current_setting('w.t')::uuid
                      and kind = 'work_reply') = 1, 'the teacher is told Ahmed replied');

-- ---------------------------------------------------------- isolation --
select pg_temp.login_as_id(current_setting('w.b')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.work_thread('portion', current_setting('w.p')::uuid,
  current_setting('w.a')::uuid)$q$, 'not found');
select pg_temp.expect_error($q$select public.work_reply('00000000-0000-0000-0000-00000009a6f3',
  '00000000-0000-0000-0000-00000009a502', 'text', 'hi')$q$, 'not found');
select pg_temp.check((select count(*) from work_messages) = 0, 'Bilal reads none of Ahmed''s messages');
select pg_temp.check(not app_private.can_read_media('00000000-0000-0000-0000-0000009bfc01'),
  'nor the teacher''s voice note to Ahmed');
select pg_temp.check(not app_private.can_read_media('00000000-0000-0000-0000-0000009bfa05'),
  'nor Ahmed''s reply');
select pg_temp.check((select count(*) from jsonb_array_elements(
                        public.work_thread('portion', current_setting('w.p')::uuid)->'events')) = 0,
  'his own thread is empty');
reset role;

select pg_temp.login_as_id(current_setting('w.o')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.work_thread('portion', current_setting('w.p')::uuid,
  current_setting('w.a')::uuid)$q$, 'not found');
select pg_temp.expect_error($q$select public.work_reply('00000000-0000-0000-0000-00000009a6f4',
  '00000000-0000-0000-0000-00000009a502', 'voice', null, '00000000-0000-0000-0000-0000009bfd01')$q$,
  'not found');
select pg_temp.check(not app_private.can_read_media('00000000-0000-0000-0000-0000009bfa02'),
  'a teacher of another group cannot hear Ahmed');
reset role;

-- ------------------------------------ verdicts: try again, then correct --
select pg_temp.login_as_id(current_setting('w.t')::uuid);
set local role authenticated;
select pg_temp.check(jsonb_array_length(public.work_thread('portion', current_setting('w.p')::uuid,
  current_setting('w.a')::uuid)->'events') = 6, 'the teacher sees the whole thread');
select public.review_attempt('00000000-0000-0000-0000-00000009a502', 'correction_required', 'Try once more.');
reset role;
select pg_temp.login_as_id(current_setting('w.a')::uuid);
set local role authenticated;
select public.send_work('00000000-0000-0000-0000-00000009a503', 'portion', current_setting('w.p')::uuid,
  null, '[{"media_asset_id": "00000000-0000-0000-0000-0000009bfa06"}]', '{"kind": "whole"}');
reset role;
select pg_temp.login_as_id(current_setting('w.t')::uuid);
set local role authenticated;
select public.review_attempt('00000000-0000-0000-0000-00000009a503', 'correct', 'Correct.');
reset role;
select pg_temp.check((select status from portion_learners where portion_id = current_setting('w.p')::uuid
                      and user_id = current_setting('w.a')::uuid) = 'completed'
                     and (select attempts from portion_learners where portion_id = current_setting('w.p')::uuid
                          and user_id = current_setting('w.a')::uuid) = 3,
  'accepted on the third attempt, all three kept');
select pg_temp.check((select string_agg(status::text, ',' order by attempt) from submissions
                      where portion_id = current_setting('w.p')::uuid
                        and user_id = current_setting('w.a')::uuid) = 'superseded,resubmission_requested,reviewed',
  'history: what was sent, what was corrected, what was accepted');
select pg_temp.login_as_id(current_setting('w.a')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.send_work('00000000-0000-0000-0000-00000009a504', 'portion',
  current_setting('w.p')::uuid, 'more', '[]')$q$, 'complete');
reset role;
