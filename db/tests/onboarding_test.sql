-- 0047: learner onboarding & WhatsApp migration.

select set_config('ob.t', app_private.create_account('Ustadh Ob', null, null, 'ob_teacher',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('ob.t')::uuid, 'teacher');
select set_config('ob.o', app_private.create_account('Other Teacher Ob', null, null, 'ob_other',
  'learner', false, 'staff-pass-1', false)::text, true);
insert into user_roles (user_id, role_key) values (current_setting('ob.o')::uuid, 'teacher');
-- Already in Sidra (Scenario C), stored as +256…
select set_config('ob.ex', app_private.create_account('Fatuma Existing', '+256772000111', null, null,
  'learner', false, 'learner-pass-1', false)::text, true);

insert into courses (id, slug, title, subject, access, price_amount, price_currency, progression, status, language) values
  ('00000000-0000-0000-0000-000000071001', 'ob-yassarna', 'OB Yassarna', 'Quran', 'restricted', null, null, 'open', 'published', 'en'),
  ('00000000-0000-0000-0000-000000071002', 'ob-paid', 'OB Paid', 'Quran', 'paid', 20000, 'UGX', 'open', 'published', 'en');
insert into course_staff (course_id, user_id, role) values
  ('00000000-0000-0000-0000-000000071001', current_setting('ob.t')::uuid, 'teacher'),
  ('00000000-0000-0000-0000-000000071002', current_setting('ob.t')::uuid, 'teacher');

-- ------------------------------------------------- preview (no writes) --
select pg_temp.login_as('admin_1');
set local role authenticated;
select set_config('ob.prev', (select jsonb_agg(p)::text from public.onboarding_preview($j$[
  {"name": "Ahmed Musa",      "phone": "0772 123 401"},
  {"name": "Fatuma Ali",      "phone": "256772000111"},
  {"name": "Fatuma Existing", "phone": "0752 999 888"},
  {"name": "",                "phone": "0772 123 402"},
  {"name": "Bad Number",      "phone": "12345"},
  {"name": "Ahmed Again",     "phone": "+256 772 123 401"},
  {"name": "No Contact"}
]$j$, '00000000-0000-0000-0000-000000071001') p), true);
reset role;
select pg_temp.check((select string_agg(e->>'status', ',' order by (e->>'row')::int)
                      from jsonb_array_elements(current_setting('ob.prev')::jsonb) e)
                     = 'new,existing,possible_duplicate,invalid,invalid,repeated,invalid',
  'each row classified: new, existing (other format), same name, missing name, bad number, repeated, no contact');
select pg_temp.check((current_setting('ob.prev')::jsonb->1->'matches'->0->>'user_id') = current_setting('ob.ex'),
  'the existing learner is found though the number was written 256…');
select pg_temp.check((current_setting('ob.prev')::jsonb->1->'matches'->0->>'phone') like '%••••%',
  'and their number is shown masked');
select pg_temp.check((current_setting('ob.prev')::jsonb->0->>'phone') = '+256772123401', 'numbers normalised');
select pg_temp.check(not exists (select 1 from users where phone = '+256772123401'), 'preview wrote nothing');

-- ----------------------------------- Scenario A + B: a WhatsApp group of 50 --
select pg_temp.login_as('admin_1');
set local role authenticated;
select set_config('ob.res', public.onboard_learners(
  jsonb_build_object(
    'source', 'whatsapp', 'label', 'Yassarna A (WhatsApp)',
    'course_id', '00000000-0000-0000-0000-000000071001',
    'new_group_name', 'Yassarna Intermediate A',
    'teacher_id', current_setting('ob.t'),
    'previous_platform', 'WhatsApp', 'previous_group', 'Yassarna Intermediate A',
    'default_position', '{"kind": "page_line", "page": 18, "label": "Page 18"}'::jsonb,
    'default_status', 'in_progress', 'invite', true),
  (select jsonb_agg(jsonb_build_object('name', 'Learner ' || n, 'phone', '07720' || lpad(n::text, 5, '0'))
                    || case when n = 1 then '{"position": {"kind": "page_line", "page": 21}, "status": "in_progress"}'::jsonb
                            when n = 2 then '{"position": {"kind": "page_line", "page": 14, "line": 3},
                                              "status": "correction_required", "last_feedback": "Repeat line 3"}'::jsonb
                            when n = 3 then '{"position": {"kind": "unknown"}, "status": "unknown"}'::jsonb
                            else '{}'::jsonb end)
   from generate_series(1, 50) n)
  || jsonb_build_array(
       jsonb_build_object('name', 'Fatuma Ali', 'phone', '256772000111', 'action', 'create'),
       jsonb_build_object('name', 'Fatuma Ali', 'phone', '256772000111', 'action', 'use_existing',
                          'existing_user_id', current_setting('ob.ex')),
       jsonb_build_object('name', 'Bad Number', 'phone', '12345'),
       jsonb_build_object('name', 'Not Coming', 'phone', '0772999000', 'action', 'skip'))
)::text, true);
reset role;
select pg_temp.check((current_setting('ob.res')::jsonb->>'created')::int = 50
                     and (current_setting('ob.res')::jsonb->>'matched')::int = 1
                     and (current_setting('ob.res')::jsonb->>'skipped')::int = 1
                     and (current_setting('ob.res')::jsonb->>'rejected')::int = 2,
  '50 created, 1 matched, 1 skipped, 2 rejected (duplicate refused, bad number): nothing dropped silently');
select pg_temp.check(exists (select 1 from jsonb_array_elements(current_setting('ob.res')::jsonb->'rows') r
                             where r->>'outcome' = 'rejected' and r->>'reason' like '%already in Sidra%'),
  'creating the existing number again is refused with the reason');
select pg_temp.check((select count(*) from users where phone = '+256772000111') = 1, 'no duplicate learner');
select set_config('ob.g', current_setting('ob.res')::jsonb->>'group_id', true);
select pg_temp.check((select count(*) from teaching_group_members where group_id = current_setting('ob.g')::uuid) = 51
                     and exists (select 1 from teaching_group_teachers where group_id = current_setting('ob.g')::uuid
                                 and user_id = current_setting('ob.t')::uuid),
  'one SIDRA teaching group with all 51 and its teacher');
select pg_temp.check((select count(*) from course_enrolments
                      where course_id = '00000000-0000-0000-0000-000000071001' and status = 'active') = 51,
  'all enrolled in the course');
select pg_temp.check((select count(*) from users u where u.created_via = 'whatsapp'
                      and not exists (select 1 from app_private.credentials c where c.user_id = u.id)) = 50,
  'imported learners have no password until they activate');
select pg_temp.check((select count(*) from jsonb_array_elements(current_setting('ob.res')::jsonb->'rows') r
                      where r->>'invitation_code' ~ '^[A-Z2-9]{4}-[A-Z2-9]{4}$') = 50,
  'each new learner has an invitation code (the existing one already has a password)');
select set_config('ob.l1', (select id::text from users where phone = '+256772000001'), true);
select set_config('ob.l2', (select id::text from users where phone = '+256772000002'), true);
select pg_temp.check((select position->>'page' from learner_positions where user_id = current_setting('ob.l1')::uuid) = '21'
                     and (select position->>'line' from learner_positions where user_id = current_setting('ob.l2')::uuid) = '3'
                     and (select position->>'kind' from learner_positions
                          where user_id = (select id from users where phone = '+256772000003')) = 'unknown'
                     and (select position->>'page' from learner_positions
                          where user_id = (select id from users where phone = '+256772000010')) = '18',
  'each keeps their own place: page 21, page 14 line 3, unknown (honest), page 18 (the group default)');
select pg_temp.check((select source = 'whatsapp' and previous_group = 'Yassarna Intermediate A'
                             and last_known_status = 'correction_required' and last_feedback = 'Repeat line 3'
                      from learner_migrations where user_id = current_setting('ob.l2')::uuid),
  'where they came from is kept');
select pg_temp.check((select processed = 54 and source = 'whatsapp' from import_batches
                      where id = (current_setting('ob.res')::jsonb->>'batch_id')::uuid), 'the import is recorded');

-- The teacher's board: who is ready and who still needs a position.
select set_config('ob.l3', (select id::text from users where phone = '+256772000003'), true);
select pg_temp.login_as_id(current_setting('ob.t')::uuid);
set local role authenticated;
select pg_temp.check((select count(*) from public.migration_board('00000000-0000-0000-0000-000000071001',
                        current_setting('ob.g')::uuid) b where (b->>'ready')::boolean = false) = 1,
  'one learner still needs their position confirmed');
select public.set_learner_positions('00000000-0000-0000-0000-000000071001', jsonb_build_array(
  jsonb_build_object('user_id', current_setting('ob.l3'),
                     'position', '{"kind": "page_line", "page": 16}'::jsonb, 'status', 'in_progress')));
select pg_temp.check((select count(*) from public.migration_board('00000000-0000-0000-0000-000000071001') b
                      where (b->>'ready')::boolean = false) = 0, 'now everyone is placed');
select pg_temp.check((select jsonb_typeof(c->'last_verdict') = 'null' and c->'position'->>'line' = '3'
                             and c->'migration'->>'source' = 'whatsapp'
                      from public.learner_continuity(current_setting('ob.l2')::uuid,
                                                     '00000000-0000-0000-0000-000000071001') c),
  'where did this learner stop: page 14 line 3, from WhatsApp');
reset role;

-- Another course's teacher sees nothing of this.
select pg_temp.login_as_id(current_setting('ob.o')::uuid);
set local role authenticated;
select pg_temp.expect_error($q$select * from public.migration_board('00000000-0000-0000-0000-000000071001')$q$, 'not allowed');
select pg_temp.expect_error($q$select public.onboard_learners('{"source": "csv",
  "course_id": "00000000-0000-0000-0000-000000071001"}', '[]')$q$, 'not allowed');
select pg_temp.check((select count(*) from public.learner_continuity(current_setting('ob.l2')::uuid)) = 0,
  'nor their learners'' records');
reset role;

-- A teacher importing into a PAID course cannot give it away free.
select pg_temp.login_as_id(current_setting('ob.t')::uuid);
set local role authenticated;
select public.onboard_learners('{"source": "contacts", "course_id": "00000000-0000-0000-0000-000000071002", "invite": false}',
  '[{"name": "Paid Learner", "phone": "0772555444"}]');
reset role;
select pg_temp.check((select status from course_enrolments e join users u on u.id = e.user_id
                      where u.phone = '+256772555444') = 'pending', 'paid course: pending payment');

-- ------------------------------------------------ Scenario F: activation --
select set_config('ob.code', (select r->>'invitation_code' from jsonb_array_elements(current_setting('ob.res')::jsonb->'rows') r
                              where r->>'phone' = '+256772000002'), true);
-- Self-registering with that number points to the invitation instead.
select pg_temp.expect_error($q$select auth_api.register('+256772000002', 'learner-pass-9', 'Learner 2')$q$,
  'invited_account');
select pg_temp.check((auth_api.app_activate('0772000002', 'WRON-GCOD', 'learner-pass-9'))->>'error' = 'invalid_code',
  'a wrong code is refused');
select pg_temp.check((auth_api.app_activate('0772 000 002', lower(current_setting('ob.code')), 'learner-pass-9'))
                     ->>'access_token' is not null, 'the right code (any case, local number) signs them in');
select pg_temp.check((auth_api.app_activate('0772000002', current_setting('ob.code'), 'learner-pass-9'))->>'error'
                     = 'already_active', 'a code works once');
select pg_temp.check(app_private.account_state(current_setting('ob.l2')::uuid) = 'active', 'now active');
select pg_temp.check((auth_api.login('+256772000002', 'learner-pass-9'))->>'id' = current_setting('ob.l2'),
  'and signs in normally with their own password');
-- Continue where you left off: the learner sees their own place.
select pg_temp.login_as_id(current_setting('ob.l2')::uuid);
set local role authenticated;
select pg_temp.check((select c->'position'->>'page' = '14' and c->>'position_status' = 'correction_required'
                             and jsonb_array_length(c->'attachments') = 0
                      from public.learner_continuity() c), 'continue where you left off: page 14');
reset role;
-- Five wrong codes kill an invitation.
select set_config('ob.l5', (select id::text from users where phone = '+256772000005'), true);
select auth_api.app_activate('0772000005', 'AAAA-AAA' || n, 'learner-pass-9') from generate_series(1, 5) n;
select pg_temp.check(app_private.account_state(current_setting('ob.l5')::uuid) = 'imported',
  'after 5 wrong tries the code is dead (a new one is needed)');

-- ----------------------------------------------------- safe rollback --
select pg_temp.login_as('admin_1');
set local role authenticated;
select pg_temp.expect_error($q$select public.rollback_import((current_setting('ob.res')::jsonb->>'batch_id')::uuid, 'yes')$q$,
  'type UNDO');
select set_config('ob.rb', public.rollback_import((current_setting('ob.res')::jsonb->>'batch_id')::uuid, 'UNDO')::text, true);
reset role;
select pg_temp.check((current_setting('ob.rb')::jsonb->>'removed')::int = 49
                     and (current_setting('ob.rb')::jsonb->>'kept_with_activity')::int = 1
                     and (current_setting('ob.rb')::jsonb->>'unlinked_existing')::int = 1,
  'undo removes the 49 never-activated learners, keeps the one who activated, unlinks the existing one');
select pg_temp.check(exists (select 1 from users where id = current_setting('ob.ex')::uuid)
                     and not exists (select 1 from course_enrolments where user_id = current_setting('ob.ex')::uuid
                                     and course_id = '00000000-0000-0000-0000-000000071001'),
  'the existing learner is never deleted — only what the import added');
select pg_temp.check(exists (select 1 from users where id = current_setting('ob.l2')::uuid),
  'the learner who signed in stays');
