-- 0047 Learner onboarding & migration (WhatsApp, contacts, CSV/Excel, manual).
--
-- Audit (2026-10-01): a learner is users + learner_profiles; signing in
-- needs a row in app_private.credentials. The earlier contact import
-- created accounts with temporary passwords. There was no notion of an
-- import, of where a learner came from, of an invitation, or of "where did
-- this learner stop".
--
-- This keeps ONE learner model and adds:
--   * imported learners: a normal users row WITHOUT credentials — they exist,
--     can be enrolled, grouped and taught for, but cannot sign in until they
--     accept an invitation (no default passwords);
--   * invitations: a single-use code (hashed, expiring, 5 tries) that the
--     learner enters with their phone/email to set their own password
--     (auth_api.app_activate). States: imported → invited → active;
--   * import batches (+ items): who imported what, from which source, with
--     counts, errors and a SAFE rollback that only removes what the batch
--     created and never a learner with activity;
--   * learner_migrations: provenance per learner and course (source,
--     previous platform/group, last known status/feedback/date, notes);
--   * learner_positions: "where did this learner stop" per course — a page /
--     line, ayah range, exercise, lesson, or explicitly UNKNOWN;
--   * migration_attachments: historical evidence (exported chats, photos,
--     recordings) kept as Historical / Imported with its provenance;
--   * preview → onboard: every row classified (new / existing / possible
--     duplicate / repeated / invalid) on the server before anything is
--     written; duplicates are never created silently.

-- --------------------------------------------------------- provenance --

create or replace function app_private.valid_source(s text)
returns boolean language sql immutable
as $$ select s in ('sidra', 'manual', 'contacts', 'csv', 'excel', 'whatsapp', 'other_lms', 'api') $$;

alter table users
  add column created_via text not null default 'sidra' check (app_private.valid_source(created_via)),
  add column import_batch_id uuid;

create table import_batches (
  id uuid primary key default gen_random_uuid(),
  source text not null check (app_private.valid_source(source) and source <> 'sidra'),
  label text,
  course_id uuid references courses (id) on delete set null,
  group_id uuid references teaching_groups (id) on delete set null,
  created_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now(),
  processed int not null default 0,
  created int not null default 0,
  matched int not null default 0,
  skipped int not null default 0,
  rejected int not null default 0,
  rolled_back_at timestamptz,
  rolled_back_by uuid references users (id) on delete set null,
  rollback_report jsonb
);
alter table users add constraint users_import_batch_fk
  foreign key (import_batch_id) references import_batches (id) on delete set null;

-- One line per input row: what happened and what the batch added (so a
-- rollback can take back exactly that).
create table import_batch_items (
  batch_id uuid not null references import_batches (id) on delete cascade,
  row_no int not null,
  name text,
  phone text,
  email text,
  external_id text,
  outcome text not null check (outcome in ('created', 'matched', 'skipped', 'rejected')),
  reason text,
  user_id uuid references users (id) on delete set null,
  added_enrolment boolean not null default false,
  added_to_group boolean not null default false,
  primary key (batch_id, row_no)
);

-- ------------------------------------------- where did they stop / from --

create table learner_migrations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users (id) on delete cascade,
  course_id uuid references courses (id) on delete cascade,
  source text not null check (app_private.valid_source(source)),
  previous_platform text check (length(previous_platform) <= 100),
  previous_group text check (length(previous_group) <= 200),
  last_known_status text not null default 'unknown'
    check (last_known_status in ('unknown', 'not_started', 'in_progress', 'correction_required', 'completed')),
  last_feedback text check (length(last_feedback) <= 2000),
  last_known_on date,
  note text check (length(note) <= 4000),
  external_id text check (length(external_id) <= 100),
  batch_id uuid references import_batches (id) on delete set null,
  imported_by uuid references users (id) on delete set null,
  imported_at timestamptz not null default now(),
  unique nulls not distinct (user_id, course_id)
);

-- A learner's current position in a course: what the teacher continues from.
-- {"kind":"unknown"} is a real, honest value ("needs confirmation").
create or replace function app_private.valid_position(p jsonb)
returns boolean language sql immutable
as $$
  select p is null
      or (jsonb_typeof(p) = 'object' and p->>'kind' = 'unknown')
      or (jsonb_typeof(p) = 'object' and p->>'kind' = 'lesson'
          and (p->>'lesson_id') ~ '^[0-9a-f-]{36}$' and length(coalesce(p->>'label', '')) <= 200)
      or app_private.valid_work_target(p)
$$;

create table learner_positions (
  user_id uuid not null references users (id) on delete cascade,
  course_id uuid not null references courses (id) on delete cascade,
  position jsonb not null default '{"kind": "unknown"}' check (app_private.valid_position(position)),
  status text not null default 'unknown'
    check (status in ('unknown', 'not_started', 'in_progress', 'correction_required', 'completed')),
  note text check (length(note) <= 2000),
  source text not null default 'teacher' check (source in ('migration', 'teacher', 'sidra')),
  set_by uuid references users (id) on delete set null,
  set_at timestamptz not null default now(),
  primary key (user_id, course_id)
);

-- Historical evidence brought from elsewhere: shown as Imported, never as
-- if it had been made in Sidra.
create table migration_attachments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users (id) on delete cascade,
  course_id uuid references courses (id) on delete cascade,
  media_asset_id uuid not null references media_assets (id) on delete restrict,
  title text check (length(title) <= 200),
  source text not null default 'whatsapp' check (app_private.valid_source(source)),
  original_date date,
  note text check (length(note) <= 2000),
  batch_id uuid references import_batches (id) on delete set null,
  imported_by uuid references users (id) on delete set null,
  imported_at timestamptz not null default now()
);
create index migration_attachments_user on migration_attachments (user_id, course_id);
create index migration_attachments_media on migration_attachments (media_asset_id);

-- ------------------------------------------------------- invitations --

create table app_private.learner_invitations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users (id) on delete cascade,
  code_hash text not null,
  expires_at timestamptz not null default now() + interval '30 days',
  attempts int not null default 0,
  created_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now(),
  used_at timestamptz,
  revoked_at timestamptz
);
create index learner_invitations_user on app_private.learner_invitations (user_id, created_at desc);

-- All learner-facing access stays behind functions; staff read through
-- functions too (no direct grants on these tables).
alter table import_batches enable row level security;
alter table import_batch_items enable row level security;
alter table learner_migrations enable row level security;
alter table learner_positions enable row level security;
alter table migration_attachments enable row level security;

do $$
declare t text;
begin
  foreach t in array array['import_batches', 'learner_migrations', 'learner_positions', 'migration_attachments'] loop
    execute format('create trigger %I after insert or update or delete on %I
                    for each row execute function app_private.audit()', t || '_audit', t);
  end loop;
end $$;

-- ----------------------------------------------------------- helpers --

-- +256… for Uganda mobiles written any common way (0772…, 256772…,
-- +256 772…); other numbers in full international form (+…); else null.
create or replace function app_private.canonical_phone(p text)
returns text
language plpgsql immutable
as $$
declare v text;
begin
  if nullif(trim(coalesce(p, '')), '') is null then return null; end if;
  v := app_private.normalize_ug_phone(p);
  if v is not null then return v; end if;
  v := regexp_replace(p, '[\s().-]', '', 'g');
  if v like '00%' then v := '+' || substr(v, 3); end if;
  if v ~ '^\+[1-9][0-9]{7,14}$' then return v; end if;
  return null;
end;
$$;

create or replace function app_private.can_onboard(p_course uuid)
returns boolean language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.has_permission('learners.edit')
      or (p_course is not null and app_private.teaches(p_course))
$$;

-- imported (no credentials, no open invitation) | invited | active
create or replace function app_private.account_state(p_user uuid)
returns text language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case
    when exists (select 1 from app_private.credentials c where c.user_id = p_user) then 'active'
    when exists (select 1 from app_private.learner_invitations i where i.user_id = p_user
                 and i.used_at is null and i.revoked_at is null and i.expires_at > now()
                 and i.attempts < 5) then 'invited'
    else 'imported' end
$$;

-- A fresh single-use code for an account that has never signed in
-- (earlier codes stop working). Returned once; stored hashed.
create or replace function app_private.new_invitation(p_user uuid)
returns text
language plpgsql volatile security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_alpha text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_code text := '';
  v_bytes bytea := gen_random_bytes(8);
begin
  if exists (select 1 from app_private.credentials where user_id = p_user) then
    raise exception 'this learner has already activated their account' using errcode = 'PT409';
  end if;
  for i in 0..7 loop
    v_code := v_code || substr(v_alpha, (get_byte(v_bytes, i) % length(v_alpha)) + 1, 1);
  end loop;
  v_code := substr(v_code, 1, 4) || '-' || substr(v_code, 5, 4);
  update app_private.learner_invitations set revoked_at = now()
  where user_id = p_user and used_at is null and revoked_at is null;
  insert into app_private.learner_invitations (user_id, code_hash, created_by)
  values (p_user, encode(digest(replace(v_code, '-', ''), 'sha256'), 'hex'), app_private.current_user_id());
  return v_code;
end;
$$;

-- -------------------------------------------------------- 1. preview --

-- Classifies rows WITHOUT writing anything. Each row:
--   {"name","phone","email","external_id"} →
--   {"row","name","phone" (canonical),"email","status","reasons":[…],
--    "matches":[{"user_id","name","phone" (masked),"email" (masked),"why"}]}
-- status: new | existing | possible_duplicate | repeated | invalid
create or replace function public.onboarding_preview(p_rows jsonb, p_course_id uuid default null)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare
  r jsonb;
  i int := 0;
  v_name text; v_raw_phone text; v_phone text; v_email text;
  v_status text; v_reasons text[]; v_matches jsonb;
  v_seen_phone text[] := '{}';
  v_seen_email text[] := '{}';
begin
  if not app_private.can_onboard(p_course_id) then
    raise exception 'not allowed to add learners' using errcode = 'PT403';
  end if;
  if jsonb_typeof(coalesce(p_rows, '[]')) <> 'array' or jsonb_array_length(coalesce(p_rows, '[]')) > 2000 then
    raise exception 'send at most 2000 rows at a time' using errcode = 'PT422';
  end if;
  for r in select * from jsonb_array_elements(coalesce(p_rows, '[]')) loop
    i := i + 1;
    v_name := nullif(trim(coalesce(r->>'name', '')), '');
    v_raw_phone := nullif(trim(coalesce(r->>'phone', '')), '');
    v_phone := app_private.canonical_phone(v_raw_phone);
    v_email := lower(nullif(trim(coalesce(r->>'email', '')), ''));
    v_reasons := '{}';
    v_matches := '[]';
    if v_name is null then v_reasons := array_append(v_reasons, 'missing_name'); end if;
    if v_raw_phone is not null and v_phone is null then v_reasons := array_append(v_reasons, 'invalid_phone'); end if;
    if v_email is not null and v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
      v_reasons := array_append(v_reasons, 'invalid_email');
      v_email := null;
    end if;
    if v_phone is null and v_email is null and not ('invalid_phone' = any (v_reasons)) then
      v_reasons := array_append(v_reasons, 'no_phone_or_email');
    end if;

    if cardinality(v_reasons) > 0 then
      v_status := 'invalid';
    elsif v_phone = any (v_seen_phone) or v_email = any (v_seen_email) then
      v_status := 'repeated';
      v_reasons := array_append(v_reasons, 'repeated_in_list');
    else
      -- exact: same phone, or same email
      select coalesce(jsonb_agg(jsonb_build_object(
               'user_id', u.id, 'name', u.display_name,
               'phone', app_private.mask_phone(u.phone),
               'email', case when u.email is null then null
                             else left(u.email, 2) || '•••' || substr(u.email, position('@' in u.email)) end,
               'why', case when u.phone = v_phone then 'same_phone' else 'same_email' end,
               'state', app_private.account_state(u.id))), '[]')
        into v_matches
      from users u
      where u.removed_at is null
        and ((v_phone is not null and u.phone = v_phone)
             or (v_email is not null and lower(u.email) = v_email));
      if jsonb_array_length(v_matches) > 0 then
        v_status := 'existing';
      else
        -- similar: the same name (another number / email)
        select coalesce(jsonb_agg(jsonb_build_object(
                 'user_id', u.id, 'name', u.display_name,
                 'phone', app_private.mask_phone(u.phone), 'why', 'same_name',
                 'state', app_private.account_state(u.id))), '[]')
          into v_matches
        from (select * from users u
              where u.removed_at is null
                and lower(regexp_replace(trim(u.display_name), '\s+', ' ', 'g'))
                    = lower(regexp_replace(v_name, '\s+', ' ', 'g'))
              limit 5) u;
        v_status := case when jsonb_array_length(v_matches) > 0 then 'possible_duplicate' else 'new' end;
      end if;
      if v_phone is not null then v_seen_phone := v_seen_phone || v_phone; end if;
      if v_email is not null then v_seen_email := v_seen_email || v_email; end if;
    end if;

    return next jsonb_build_object(
      'row', i, 'name', v_name, 'phone', v_phone, 'raw_phone', v_raw_phone, 'email', v_email,
      'external_id', nullif(trim(coalesce(r->>'external_id', '')), ''),
      'status', v_status, 'reasons', to_jsonb(v_reasons), 'matches', v_matches);
  end loop;
end;
$$;

-- ------------------------------------------------------- 2. onboarding --

-- Imports rows as decided in the preview, in ONE transaction.
-- p_options: {"source","label","course_id","group_id" | "new_group_name",
--   "teacher_id","previous_platform","previous_group","default_position",
--   "default_status","last_known_on","invite": true}
-- p_rows: [{"name","phone","email","external_id","note","last_feedback",
--   "action": "create"|"use_existing"|"create_separate"|"skip",
--   "existing_user_id","position","status"}]
-- A row that cannot be imported is REJECTED with its reason (the others
-- still go in); nothing is ever silently dropped or duplicated.
create or replace function public.onboard_learners(p_options jsonb, p_rows jsonb)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  o jsonb := coalesce(p_options, '{}');
  v_me uuid := app_private.current_user_id();
  v_course uuid := nullif(o->>'course_id', '')::uuid;
  v_group uuid := nullif(o->>'group_id', '')::uuid;
  v_teacher uuid := nullif(o->>'teacher_id', '')::uuid;
  v_source text := coalesce(nullif(o->>'source', ''), 'manual');
  v_invite boolean := coalesce((o->>'invite')::boolean, true);
  v_paid boolean;
  v_admin boolean := app_private.has_permission('enrolments.manage');
  v_batch import_batches%rowtype;
  r jsonb;
  i int := 0;
  v_action text; v_name text; v_phone text; v_email text; v_user uuid;
  v_outcome text; v_reason text; v_code text;
  v_added_enrol boolean; v_added_group boolean;
  v_pos jsonb; v_status text;
  v_out jsonb := '[]';
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  if not app_private.can_onboard(v_course) then
    raise exception 'not allowed to add learners' using errcode = 'PT403';
  end if;
  if not app_private.valid_source(v_source) or v_source = 'sidra' then
    raise exception 'unknown source' using errcode = 'PT422';
  end if;
  if jsonb_typeof(coalesce(p_rows, '[]')) <> 'array' or jsonb_array_length(coalesce(p_rows, '[]')) > 2000 then
    raise exception 'send at most 2000 rows at a time' using errcode = 'PT422';
  end if;
  if not app_private.valid_position(o->'default_position') then
    raise exception 'the starting position is not valid' using errcode = 'PT422';
  end if;
  if v_course is not null then
    select access = 'paid' into v_paid from courses where id = v_course;
    if not found then raise exception 'course not found' using errcode = 'PT404'; end if;
  elsif v_group is not null or nullif(o->>'new_group_name', '') is not null then
    raise exception 'choose the course for the group' using errcode = 'PT422';
  end if;
  -- The teacher must teach the course.
  if v_teacher is not null and not exists (
       select 1 from course_staff s where s.course_id = v_course and s.user_id = v_teacher) then
    raise exception 'that teacher does not teach this course' using errcode = 'PT422';
  end if;
  -- An existing group must belong to the course; a new one is created now.
  if v_group is not null and not exists (
       select 1 from teaching_groups where id = v_group and course_id = v_course) then
    raise exception 'that group belongs to another course' using errcode = 'PT422';
  end if;
  if v_group is null and nullif(trim(coalesce(o->>'new_group_name', '')), '') is not null then
    insert into teaching_groups (course_id, name, description, created_by)
    values (v_course, trim(o->>'new_group_name'),
            nullif(trim(coalesce(o->>'previous_group', '')), ''), v_me)
    returning id into v_group;
    insert into teaching_group_teachers (group_id, user_id)
    select v_group, t from unnest(array_remove(array[v_me, v_teacher], null)) t
    where exists (select 1 from course_staff s where s.course_id = v_course and s.user_id = t)
       or t = v_teacher
    on conflict do nothing;
  elsif v_group is not null and v_teacher is not null then
    insert into teaching_group_teachers (group_id, user_id) values (v_group, v_teacher)
    on conflict do nothing;
  end if;

  insert into import_batches (source, label, course_id, group_id, created_by)
  values (v_source, nullif(trim(coalesce(o->>'label', '')), ''), v_course, v_group, v_me)
  returning * into v_batch;

  for r in select * from jsonb_array_elements(coalesce(p_rows, '[]')) loop
    i := i + 1;
    v_action := coalesce(r->>'action', 'create');
    v_name := nullif(trim(coalesce(r->>'name', '')), '');
    v_phone := app_private.canonical_phone(r->>'phone');
    v_email := lower(nullif(trim(coalesce(r->>'email', '')), ''));
    v_user := null; v_outcome := null; v_reason := null; v_code := null;
    v_added_enrol := false; v_added_group := false;
    begin
      if v_action = 'skip' then
        v_outcome := 'skipped';
      elsif v_action = 'use_existing' then
        select id into v_user from users
        where id = nullif(r->>'existing_user_id', '')::uuid and removed_at is null;
        if v_user is null then raise exception 'the chosen existing learner was not found'; end if;
        v_outcome := 'matched';
      elsif v_action in ('create', 'create_separate') then
        if v_name is null then raise exception 'name is required'; end if;
        if nullif(trim(coalesce(r->>'phone', '')), '') is not null and v_phone is null then
          raise exception 'invalid phone number';
        end if;
        if v_email is not null and v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
          raise exception 'invalid email';
        end if;
        if v_phone is null and v_email is null then raise exception 'a phone number or email is needed'; end if;
        -- Never a second account for the same phone / email.
        if exists (select 1 from users where phone = v_phone) then
          raise exception 'this phone number is already in Sidra: choose the existing learner';
        end if;
        if v_email is not null and exists (select 1 from users where lower(email) = v_email) then
          raise exception 'this email is already in Sidra: choose the existing learner';
        end if;
        -- create (not create_separate) refuses a same-name learner too:
        -- the preview asked the person to decide.
        if v_action = 'create' and exists (
             select 1 from users where removed_at is null
               and lower(regexp_replace(trim(display_name), '\s+', ' ', 'g'))
                   = lower(regexp_replace(v_name, '\s+', ' ', 'g'))) then
          raise exception 'a learner with this name exists: use them, or create a separate learner';
        end if;
        v_user := gen_random_uuid();
        insert into users (id, auth_subject, display_name, phone, email, created_via, import_batch_id)
        values (v_user, v_user::text, v_name, v_phone, v_email, v_source, v_batch.id);
        insert into learner_profiles (user_id, notes) values (v_user, nullif(trim(coalesce(r->>'note', '')), ''));
        v_outcome := 'created';
      else
        raise exception 'unknown action %', v_action;
      end if;

      if v_user is not null and v_course is not null then
        if not exists (select 1 from course_enrolments where course_id = v_course and user_id = v_user) then
          -- Paid courses: only finance-allowed staff open them for free;
          -- otherwise the learner is enrolled pending payment.
          insert into course_enrolments (course_id, user_id, status, source, granted_by,
                                         fee_amount, fee_currency)
          select v_course, v_user,
                 case when c.access = 'paid' and not v_admin then 'pending'::enrolment_status
                      else 'active'::enrolment_status end,
                 'admin_grant', v_me,
                 case when c.access = 'paid' then c.price_amount end,
                 case when c.access = 'paid' then c.price_currency end
          from courses c where c.id = v_course;
          v_added_enrol := true;
        end if;
        if v_group is not null and not exists (
             select 1 from teaching_group_members where group_id = v_group and user_id = v_user) then
          insert into teaching_group_members (group_id, user_id) values (v_group, v_user);
          v_added_group := true;
        end if;
      end if;

      if v_user is not null then
        v_pos := coalesce(r->'position', o->'default_position');
        v_status := coalesce(nullif(r->>'status', ''), nullif(o->>'default_status', ''), 'unknown');
        if not app_private.valid_position(v_pos) then raise exception 'invalid current position'; end if;
        if v_status not in ('unknown', 'not_started', 'in_progress', 'correction_required', 'completed') then
          raise exception 'invalid status';
        end if;
        insert into learner_migrations (user_id, course_id, source, previous_platform, previous_group,
                                        last_known_status, last_feedback, last_known_on, note,
                                        external_id, batch_id, imported_by)
        values (v_user, v_course, v_source,
                nullif(trim(coalesce(o->>'previous_platform', '')), ''),
                nullif(trim(coalesce(o->>'previous_group', '')), ''),
                v_status, nullif(trim(coalesce(r->>'last_feedback', '')), ''),
                nullif(o->>'last_known_on', '')::date, nullif(trim(coalesce(r->>'note', '')), ''),
                nullif(trim(coalesce(r->>'external_id', '')), ''), v_batch.id, v_me)
        on conflict (user_id, course_id) do update set
          source = excluded.source, previous_platform = coalesce(excluded.previous_platform, learner_migrations.previous_platform),
          previous_group = coalesce(excluded.previous_group, learner_migrations.previous_group),
          last_known_status = excluded.last_known_status,
          last_feedback = coalesce(excluded.last_feedback, learner_migrations.last_feedback),
          last_known_on = coalesce(excluded.last_known_on, learner_migrations.last_known_on),
          note = coalesce(excluded.note, learner_migrations.note),
          external_id = coalesce(excluded.external_id, learner_migrations.external_id),
          batch_id = excluded.batch_id, imported_by = excluded.imported_by, imported_at = now();
        if v_course is not null then
          insert into learner_positions (user_id, course_id, position, status, source, set_by)
          values (v_user, v_course, coalesce(v_pos, '{"kind": "unknown"}'), v_status, 'migration', v_me)
          on conflict (user_id, course_id) do update set
            position = excluded.position, status = excluded.status, source = 'migration',
            set_by = v_me, set_at = now();
        end if;
        if v_invite and app_private.account_state(v_user) <> 'active' then
          v_code := app_private.new_invitation(v_user);
        end if;
      end if;
    exception when others then
      v_outcome := 'rejected';
      v_reason := sqlerrm;
      v_user := null; v_code := null;
      v_added_enrol := false; v_added_group := false;
    end;

    insert into import_batch_items (batch_id, row_no, name, phone, email, external_id, outcome,
                                    reason, user_id, added_enrolment, added_to_group)
    values (v_batch.id, i, v_name, v_phone, v_email, nullif(trim(coalesce(r->>'external_id', '')), ''),
            v_outcome, v_reason, v_user, v_added_enrol, v_added_group);
    v_out := v_out || jsonb_build_object('row', i, 'name', v_name, 'phone', v_phone,
                                         'outcome', v_outcome, 'reason', v_reason,
                                         'user_id', v_user, 'invitation_code', v_code);
  end loop;

  update import_batches set
    processed = i,
    created = (select count(*) from import_batch_items where batch_id = v_batch.id and outcome = 'created'),
    matched = (select count(*) from import_batch_items where batch_id = v_batch.id and outcome = 'matched'),
    skipped = (select count(*) from import_batch_items where batch_id = v_batch.id and outcome = 'skipped'),
    rejected = (select count(*) from import_batch_items where batch_id = v_batch.id and outcome = 'rejected')
  where id = v_batch.id returning * into v_batch;

  return jsonb_build_object('batch_id', v_batch.id, 'group_id', v_group,
                            'processed', v_batch.processed, 'created', v_batch.created,
                            'matched', v_batch.matched, 'skipped', v_batch.skipped,
                            'rejected', v_batch.rejected, 'rows', v_out);
end;
$$;

-- --------------------------------------------------- 3. invitations --

-- A new code for a learner who has not activated yet (the old one stops
-- working). For admins, or teachers of a course the learner is in.
create or replace function public.issue_invitation(p_user_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_code text;
begin
  if not (app_private.has_permission('learners.edit')
          or exists (select 1 from course_enrolments e where e.user_id = p_user_id
                     and app_private.teaches(e.course_id))) then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  v_code := app_private.new_invitation(p_user_id);
  return jsonb_build_object('code', v_code,
    'name', (select display_name from users where id = p_user_id),
    'phone', (select phone from users where id = p_user_id),
    'expires_at', now() + interval '30 days');
end;
$$;

-- The learner, on the sign-in screen: phone or email + invitation code +
-- their own new password → signed in. Wrong codes count (5 per code);
-- every failure gives the same answer (no account enumeration).
create or replace function auth_api.app_activate(
  p_identifier text, p_code text, p_password text, p_device jsonb default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, auth_api, pg_temp
as $$
declare
  v_user uuid;
  v_inv app_private.learner_invitations%rowtype;
  v_phone text := app_private.canonical_phone(p_identifier);
  v_code text := upper(regexp_replace(coalesce(p_code, ''), '[\s-]', '', 'g'));
  v_dev uuid;
begin
  if v_phone is not null then
    select id into v_user from users where phone = v_phone and is_active and removed_at is null;
  else
    select id into v_user from users where lower(email) = lower(trim(coalesce(p_identifier, '')))
      and is_active and removed_at is null;
  end if;
  if v_user is not null and exists (select 1 from app_private.credentials where user_id = v_user) then
    return jsonb_build_object('error', 'already_active');
  end if;
  select * into v_inv from app_private.learner_invitations
  where user_id = v_user and used_at is null and revoked_at is null and expires_at > now() and attempts < 5
  order by created_at desc limit 1;
  if v_inv.id is null then return jsonb_build_object('error', 'invalid_code'); end if;
  if v_inv.code_hash <> encode(digest(v_code, 'sha256'), 'hex') then
    update app_private.learner_invitations set attempts = attempts + 1 where id = v_inv.id;
    return jsonb_build_object('error', 'invalid_code');
  end if;
  perform auth_api._check_password(p_password);
  insert into app_private.credentials (user_id, password_hash)
  values (v_user, crypt(p_password, gen_salt('bf', 10)));
  update app_private.learner_invitations set used_at = now() where id = v_inv.id;
  v_dev := app_private.upsert_device(v_user, p_device, true);
  perform app_private.auth_event('account_activated', v_user, v_dev, p_identifier);
  return auth_api._session(v_user, auth_api.issue_refresh(v_user, null, v_dev), v_dev);
end;
$$;

-- Self-registration with the number of a learner the school already added
-- says so (instead of "taken"), pointing to the invitation code.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('auth_api.register(text, text, text)'::regprocedure);
  if position('    raise exception ''identifier_taken'' using errcode = ''SA409'';' in v_src) = 0 then
    raise exception 'register changed; update 0047';
  end if;
  execute replace(v_src, '    raise exception ''identifier_taken'' using errcode = ''SA409'';',
    '    if exists (select 1 from users u where ((v_id.kind = ''email'' and lower(u.email) = v_id.value)
                                            or (v_id.kind = ''phone'' and u.phone = v_id.value))
               and not exists (select 1 from app_private.credentials c where c.user_id = u.id)) then
      raise exception ''invited_account'' using errcode = ''SA409'';
    end if;
    raise exception ''identifier_taken'' using errcode = ''SA409'';');
end $$;

-- ------------------------------------------ 4. positions & continuity --

create or replace function app_private.can_see_learner_course(p_user uuid, p_course uuid)
returns boolean language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select p_user = app_private.current_user_id()
      or app_private.has_permission('learners.view')
      or (p_course is not null and app_private.teaches(p_course)
          and exists (select 1 from course_enrolments e where e.user_id = p_user and e.course_id = p_course))
$$;

-- Set where learners are (bulk, each entry may differ). Teachers of the
-- course or learner editors. Unknown is allowed — never invent progress.
create or replace function public.set_learner_positions(p_course_id uuid, p_entries jsonb)
returns int
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare e jsonb; n int := 0;
begin
  if not app_private.can_onboard(p_course_id) then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  for e in select * from jsonb_array_elements(coalesce(p_entries, '[]')) loop
    if not exists (select 1 from course_enrolments where course_id = p_course_id
                   and user_id = (e->>'user_id')::uuid) then
      raise exception 'a learner is not in this course' using errcode = 'PT422';
    end if;
    if not app_private.valid_position(e->'position') then
      raise exception 'invalid position' using errcode = 'PT422';
    end if;
    if e->'position'->>'kind' = 'lesson' and not exists (
         select 1 from lessons where id = (e->'position'->>'lesson_id')::uuid and course_id = p_course_id) then
      raise exception 'that lesson is in another course' using errcode = 'PT422';
    end if;
    insert into learner_positions (user_id, course_id, position, status, note, source, set_by)
    values ((e->>'user_id')::uuid, p_course_id, coalesce(e->'position', '{"kind": "unknown"}'),
            coalesce(nullif(e->>'status', ''), 'unknown'), nullif(trim(coalesce(e->>'note', '')), ''),
            'teacher', app_private.current_user_id())
    on conflict (user_id, course_id) do update set
      position = excluded.position, status = excluded.status,
      note = coalesce(excluded.note, learner_positions.note), source = 'teacher',
      set_by = excluded.set_by, set_at = now();
    n := n + 1;
  end loop;
  return n;
end;
$$;

-- "Where did this learner stop?" — per course: position, last portion, last
-- submission, last feedback, next action, where they came from, history.
-- For the learner themself, their teachers and learner viewers.
create or replace function public.learner_continuity(p_user_id uuid default null, p_course_id uuid default null)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare v_user uuid := coalesce(p_user_id, app_private.current_user_id());
begin
  if v_user is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  return query
  with courses_of as (
    select e.course_id from course_enrolments e
    where e.user_id = v_user and (p_course_id is null or e.course_id = p_course_id)
    union
    select m.course_id from learner_migrations m
    where m.user_id = v_user and m.course_id is not null and (p_course_id is null or m.course_id = p_course_id)
  )
  select jsonb_build_object(
    'user_id', v_user,
    'learner', (select display_name from users where id = v_user),
    'account_state', app_private.account_state(v_user),
    'course_id', c.id, 'course_title', c.title,
    'position', p.position, 'position_status', p.status, 'position_note', p.note,
    'position_source', p.source, 'position_set_at', p.set_at,
    'last_portion', (select jsonb_build_object('id', tp.id, 'title', tp.title, 'status', pl.status)
                     from portion_learners pl join teaching_portions tp on tp.id = pl.portion_id
                     where pl.user_id = v_user and tp.course_id = c.id
                     order by tp.assigned_at desc nulls last limit 1),
    'last_submission_at', (select max(s.submitted_at) from submissions s
                           where s.user_id = v_user and s.course_id = c.id),
    'last_verdict', (select jsonb_build_object('result', rv.result, 'feedback', rv.feedback,
                                               'at', rv.created_at, 'target', s.target)
                     from submission_reviews rv join submissions s on s.id = rv.submission_id
                     where s.user_id = v_user and s.course_id = c.id
                     order by rv.created_at desc limit 1),
    'migration', (select to_jsonb(m) - 'imported_by' || jsonb_build_object(
                           'imported_by_name', (select display_name from users where id = m.imported_by))
                  from learner_migrations m where m.user_id = v_user and m.course_id = c.id),
    'attachments', (select coalesce(jsonb_agg(jsonb_build_object(
                             'id', a.id, 'title', a.title, 'media_asset_id', a.media_asset_id,
                             'kind', (select kind from media_assets where id = a.media_asset_id),
                             'source', a.source, 'original_date', a.original_date, 'note', a.note,
                             'imported_at', a.imported_at,
                             'imported_by', (select display_name from users where id = a.imported_by))
                             order by a.imported_at), '[]')
                    from migration_attachments a
                    where a.user_id = v_user and a.course_id = c.id
                      and v_user <> app_private.current_user_id()))
  from courses_of co
  join courses c on c.id = co.course_id
  left join learner_positions p on p.user_id = v_user and p.course_id = c.id
  where app_private.can_see_learner_course(v_user, c.id)
  order by c.title;
end;
$$;

-- The migration board: learners of a course / group with source, position
-- and what still needs doing (activation, position).
create or replace function public.migration_board(p_course_id uuid, p_group_id uuid default null)
returns setof jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not (app_private.has_permission('learners.view') or app_private.teaches(p_course_id)) then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  return query
  select jsonb_build_object(
    'user_id', u.id, 'name', u.display_name, 'phone', u.phone,
    'source', coalesce(m.source, u.created_via), 'previous_group', m.previous_group,
    'account_state', app_private.account_state(u.id),
    'position', p.position, 'status', coalesce(p.status, 'unknown'),
    'ready', p.position is not null and p.position->>'kind' <> 'unknown',
    'imported_at', m.imported_at)
  from course_enrolments e
  join users u on u.id = e.user_id and u.removed_at is null
  left join learner_migrations m on m.user_id = u.id and m.course_id = e.course_id
  left join learner_positions p on p.user_id = u.id and p.course_id = e.course_id
  where e.course_id = p_course_id and e.status in ('active', 'pending')
    and (p_group_id is null or exists (select 1 from teaching_group_members gm
                                       where gm.group_id = p_group_id and gm.user_id = u.id))
  order by (p.position is null or p.position->>'kind' = 'unknown') desc, u.display_name;
end;
$$;

-- Historical evidence (exported chat, photos, recordings) for a learner.
create or replace function public.add_migration_attachment(
  p_user_id uuid, p_course_id uuid, p_media_asset_id uuid, p_title text default null,
  p_source text default 'whatsapp', p_original_date date default null, p_note text default null)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_id uuid;
begin
  if not app_private.can_onboard(p_course_id) then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  if not exists (select 1 from media_assets where id = p_media_asset_id
                 and uploaded_by = app_private.current_user_id()) then
    raise exception 'files must be your own uploads' using errcode = 'PT403';
  end if;
  insert into migration_attachments (user_id, course_id, media_asset_id, title, source,
                                     original_date, note, imported_by)
  values (p_user_id, p_course_id, p_media_asset_id, nullif(trim(coalesce(p_title, '')), ''),
          p_source, p_original_date, nullif(trim(coalesce(p_note, '')), ''),
          app_private.current_user_id())
  returning id into v_id;
  return v_id;
end;
$$;

-- Historical attachments: the learner's teachers and learner viewers only
-- (an exported group chat mentions other people).
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('app_private.can_read_media(uuid)'::regprocedure);
  if position('when exists (select 1 from submission_files f where f.media_asset_id = p_asset_id) then' in v_src) = 0 then
    raise exception 'can_read_media changed; update 0047';
  end if;
  execute replace(v_src,
    'when exists (select 1 from submission_files f where f.media_asset_id = p_asset_id) then',
    'when exists (select 1 from migration_attachments a where a.media_asset_id = p_asset_id) then
      app_private.has_permission(''learners.view'')
      or exists (select 1 from migration_attachments a where a.media_asset_id = p_asset_id
                 and a.course_id is not null and app_private.teaches(a.course_id))
    when exists (select 1 from submission_files f where f.media_asset_id = p_asset_id) then');
end $$;

-- ---------------------------------------------- 5. history & rollback --

create or replace function public.import_history(p_limit int default 50)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select to_jsonb(b) || jsonb_build_object(
    'created_by_name', (select display_name from users where id = b.created_by),
    'course_title', (select title from courses where id = b.course_id),
    'group_name', (select name from teaching_groups where id = b.group_id))
  from import_batches b
  where b.created_by = app_private.current_user_id() or app_private.has_permission('learners.view')
  order by b.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
$$;

create or replace function public.import_batch_items(p_batch_id uuid)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select to_jsonb(i) || jsonb_build_object('account_state',
           case when i.user_id is not null then app_private.account_state(i.user_id) end)
  from import_batch_items i
  join import_batches b on b.id = i.batch_id
  where i.batch_id = p_batch_id
    and (b.created_by = app_private.current_user_id() or app_private.has_permission('learners.view'))
  order by i.row_no
$$;

-- Takes back what ONE import added: its enrolments / group places for
-- matched learners, and the learners it created — but only those who never
-- activated and have no activity (work, payments, progress, messages);
-- those are kept and listed. Existing learners are never deleted.
create or replace function public.rollback_import(p_batch_id uuid, p_confirm text)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  b import_batches%rowtype;
  it import_batch_items%rowtype;
  v_removed int := 0; v_kept int := 0; v_unlinked int := 0;
  v_kept_names text[] := '{}';
  v_report jsonb;
begin
  select * into b from import_batches where id = p_batch_id for update;
  if not found then raise exception 'import not found' using errcode = 'PT404'; end if;
  if not (b.created_by = app_private.current_user_id() or app_private.has_permission('learners.edit')) then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  if b.rolled_back_at is not null then raise exception 'already undone' using errcode = 'PT409'; end if;
  if coalesce(p_confirm, '') <> 'UNDO' then
    raise exception 'type UNDO to confirm' using errcode = 'PT422';
  end if;
  for it in select * from import_batch_items where batch_id = b.id and user_id is not null loop
    if it.outcome = 'created'
       and not exists (select 1 from app_private.credentials where user_id = it.user_id)
       and not exists (select 1 from submissions where user_id = it.user_id)
       and not exists (select 1 from payments where user_id = it.user_id)
       and not exists (select 1 from learner_progress where user_id = it.user_id)
       and not exists (select 1 from messages where sender_id = it.user_id)
       and not exists (select 1 from import_batch_items x where x.user_id = it.user_id
                       and x.batch_id <> b.id) then
      delete from users where id = it.user_id;
      v_removed := v_removed + 1;
    elsif it.outcome = 'created' then
      v_kept := v_kept + 1;
      v_kept_names := v_kept_names || coalesce(it.name, '?');
    else
      if it.added_to_group then
        delete from teaching_group_members where group_id = b.group_id and user_id = it.user_id;
      end if;
      if it.added_enrolment and not exists (select 1 from payments where user_id = it.user_id
                                            and course_id = b.course_id) then
        delete from course_enrolments where course_id = b.course_id and user_id = it.user_id;
      end if;
      delete from learner_migrations where user_id = it.user_id and batch_id = b.id;
      v_unlinked := v_unlinked + 1;
    end if;
  end loop;
  v_report := jsonb_build_object('removed', v_removed, 'kept_with_activity', v_kept,
                                 'kept_names', to_jsonb(v_kept_names), 'unlinked_existing', v_unlinked);
  update import_batches set rolled_back_at = now(), rolled_back_by = app_private.current_user_id(),
    rollback_report = v_report where id = b.id;
  return v_report;
end;
$$;

-- ------------------------------------------------------------ grants --

revoke all on function public.onboarding_preview(jsonb, uuid), public.onboard_learners(jsonb, jsonb),
  public.issue_invitation(uuid), public.set_learner_positions(uuid, jsonb),
  public.learner_continuity(uuid, uuid), public.migration_board(uuid, uuid),
  public.add_migration_attachment(uuid, uuid, uuid, text, text, date, text),
  public.import_history(int), public.import_batch_items(uuid), public.rollback_import(uuid, text)
  from public, anonymous;
grant execute on function public.onboarding_preview(jsonb, uuid), public.onboard_learners(jsonb, jsonb),
  public.issue_invitation(uuid), public.set_learner_positions(uuid, jsonb),
  public.learner_continuity(uuid, uuid), public.migration_board(uuid, uuid),
  public.add_migration_attachment(uuid, uuid, uuid, text, text, date, text),
  public.import_history(int), public.import_batch_items(uuid), public.rollback_import(uuid, text)
  to authenticated, sidra_app;

-- The sign-in screen may call app_activate (like app_login).
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('app_private.lock_down_functions()'::regprocedure);
  if position('''app_register'', ''app_login''' in v_src) = 0 then
    raise exception 'lock_down_functions changed; update 0047';
  end if;
  execute replace(v_src, '''app_register'', ''app_login''', '''app_register'', ''app_login'', ''app_activate''');
end $$;

select app_private.lock_down_functions();
