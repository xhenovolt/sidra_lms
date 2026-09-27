-- Permanently deleting learners (0021).

select set_config('t.gone', app_private.create_account('Gone Learner', '+256700111222', null, 'gone_l',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('t.payer', app_private.create_account('Paying Learner', '+256700333444', null, 'payer_l',
  'learner', false, 'learner-pass-1', false)::text, true);
select set_config('t.tch', app_private.create_account('Del Teacher', null, null, 'del_teacher',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('t.tch')::uuid, 'teacher');

insert into courses (id, slug, title, subject, access, progression, status, language)
values ('00000000-0000-0000-0000-0000000dd001', 'del-course', 'Del Course', 'Quran', 'restricted',
        'open', 'published', 'en');
insert into lessons (id, course_id, title, position, status)
values ('00000000-0000-0000-0000-0000000dd0a1', '00000000-0000-0000-0000-0000000dd001', 'L1', 0, 'published');
insert into course_enrolments (course_id, user_id, status, source)
select '00000000-0000-0000-0000-0000000dd001', u, 'active', 'admin_grant'
from unnest(array[current_setting('t.gone')::uuid, current_setting('t.payer')::uuid]) u;
insert into learner_progress (user_id, course_id, lesson_id, status, client_updated_at)
values (current_setting('t.gone')::uuid, '00000000-0000-0000-0000-0000000dd001',
        '00000000-0000-0000-0000-0000000dd0a1', 'completed', now());
insert into media_assets (id, kind, resource_type, delivery, public_id, format, uploaded_by)
values ('00000000-0000-0000-0000-0000000ddf01', 'audio', 'video', 'authenticated',
        'sidra/submissions/' || current_setting('t.gone') || '/r', 'm4a', current_setting('t.gone')::uuid);
insert into assignments (id, course_id, lesson_id, title, status)
values ('00000000-0000-0000-0000-0000000dde01', '00000000-0000-0000-0000-0000000dd001',
        '00000000-0000-0000-0000-0000000dd0a1', 'Read', 'published');
insert into submissions (id, assignment_id, user_id, course_id, lesson_id)
values ('00000000-0000-0000-0000-0000000dd501', '00000000-0000-0000-0000-0000000dde01',
        current_setting('t.gone')::uuid, '00000000-0000-0000-0000-0000000dd001',
        '00000000-0000-0000-0000-0000000dd0a1');
insert into submission_files (submission_id, media_asset_id)
values ('00000000-0000-0000-0000-0000000dd501', '00000000-0000-0000-0000-0000000ddf01');
insert into teacher_notes (learner_id, author_id, body)
values (current_setting('t.gone')::uuid, current_setting('t.tch')::uuid, 'Confuses ض and ظ');
insert into payments (user_id, course_id, amount, currency, method, status)
values (current_setting('t.payer')::uuid, '00000000-0000-0000-0000-0000000dd001', 5000, 'UGX',
        'cash', 'verified');

-- Teachers cannot delete learners.
select pg_temp.login_as_id(current_setting('t.tch')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select public.delete_learner(current_setting('t.gone')::uuid, 'Gone Learner')$q$,
  'not allowed');
reset role;

select pg_temp.login_as('admin_1');
set local role authenticated;
select pg_temp.expect_error($q$select public.delete_learner(current_setting('t.gone')::uuid, 'wrong name')$q$,
  'type the learner');
select pg_temp.expect_error($q$select public.delete_learner(current_setting('t.tch')::uuid, 'Del Teacher')$q$,
  'only learners');
select pg_temp.expect_error($q$select public.delete_learner(app_private.current_user_id(), 'x')$q$,
  'yourself');

-- No money history: erased entirely.
select pg_temp.check(public.delete_learner(current_setting('t.gone')::uuid, '  gone learner ',
  'Asked to leave')->>'mode' = 'deleted', 'learner deleted');
reset role;
select pg_temp.check(not exists (select 1 from users where id = current_setting('t.gone')::uuid),
  'account row gone');
select pg_temp.check(not exists (select 1 from course_enrolments where user_id = current_setting('t.gone')::uuid)
  and not exists (select 1 from learner_progress where user_id = current_setting('t.gone')::uuid)
  and not exists (select 1 from submissions where user_id = current_setting('t.gone')::uuid)
  and not exists (select 1 from teacher_notes where learner_id = current_setting('t.gone')::uuid),
  'learning data and notes gone');
select pg_temp.check(not exists (select 1 from media_assets where id = '00000000-0000-0000-0000-0000000ddf01')
  and exists (select 1 from app_private.media_purge where public_id like 'sidra/submissions/' || current_setting('t.gone') || '%'),
  'their recording removed and queued for Cloudinary deletion');
select pg_temp.check(not exists (select 1 from audit_log where entity = 'users'
  and entity_id = current_setting('t.gone') and changes::text like '%+256700111222%'),
  'no personal data left in the activity log');
select pg_temp.check(exists (select 1 from audit_log where action = 'learner.deleted'
  and entity_id = current_setting('t.gone') and note = 'Asked to leave'), 'deletion is recorded');

-- Money history: personal data erased, finance kept.
select pg_temp.login_as('admin_1');
set local role authenticated;
select pg_temp.check(public.delete_learner(current_setting('t.payer')::uuid, 'payer_l')->>'mode' = 'anonymised',
  'learner with payments anonymised');
select pg_temp.check(not exists (select 1 from public.admin_people('learner') p
                                 where p.id = current_setting('t.payer')::uuid),
  'removed learner no longer listed');
reset role;
select pg_temp.check((select display_name = 'Removed learner' and phone is null and username is null
                             and not is_active and removed_at is not null
                      from users where id = current_setting('t.payer')::uuid), 'row anonymised');
select pg_temp.check((select count(*) from payments where user_id = current_setting('t.payer')::uuid) = 1,
  'payment kept for the books');
select pg_temp.check(not exists (select 1 from app_private.credentials where user_id = current_setting('t.payer')::uuid),
  'cannot sign in any more');
select pg_temp.check(auth_api.login('payer_l', 'learner-pass-1')->>'error' = 'invalid_credentials',
  'sign-in refused');

select 'ALL DELETE TESTS PASSED' as result;
