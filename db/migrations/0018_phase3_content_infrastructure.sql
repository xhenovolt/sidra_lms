-- Phase 3: content infrastructure.
--   * languages of delivery (course, lesson, content block, teacher)
--   * learning tracks, course prerequisites, catalogue visibility
--   * lesson learning outcomes and optional Qur'an references
--   * resource library: Cloudinary uploads OR external URLs (future
--     providers fit the same row), attached to course / unit / book /
--     section / lesson / assignment, with verified previews
--   * assignments, learner submissions, teacher review
--   * submission files readable only by their owner and their teachers
--   * move a lesson within a course, copy it to another course
--   * payments-server heartbeat and MarzPay diagnostics
-- Nothing is dropped; every change is additive.

-- ----------------------------------------------------------- languages --

create table languages (
  code text primary key check (code ~ '^[a-z]{2,3}(-[A-Za-z0-9]{2,8})?$'),
  name text not null,
  native_name text,
  direction text not null default 'ltr' check (direction in ('ltr', 'rtl')),
  position int not null default 100,
  is_active boolean not null default true
);
insert into languages (code, name, native_name, direction, position) values
  ('en', 'English', 'English', 'ltr', 1),
  ('ar', 'Arabic', 'العربية', 'rtl', 2),
  ('lg', 'Luganda', 'Luganda', 'ltr', 3),
  ('sw', 'Kiswahili', 'Kiswahili', 'ltr', 4),
  ('so', 'Somali', 'Soomaali', 'ltr', 5),
  ('ur', 'Urdu', 'اردو', 'rtl', 6),
  ('fr', 'French', 'Français', 'ltr', 7),
  ('rw', 'Kinyarwanda', 'Ikinyarwanda', 'ltr', 8),
  ('ha', 'Hausa', 'Hausa', 'ltr', 9)
on conflict (code) do nothing;
alter table languages enable row level security;
create policy languages_read on languages for select to public using (true);
create policy languages_write on languages for all to public
  using (app_private.has_permission('settings.manage'))
  with check (app_private.has_permission('settings.manage'));
grant select on languages to anonymous, authenticated, sidra_app;
grant insert, update on languages to authenticated, sidra_app;

create or replace function app_private.check_languages(p_codes text[])
returns boolean
language sql stable
as $$
  select coalesce(bool_and(exists (select 1 from languages l where l.code = c)), true)
  from unnest(coalesce(p_codes, '{}')) c
$$;

-- ------------------------------------------------------ learning tracks --
-- Reading ≠ recitation ≠ tajwid ≠ Qur'anic Arabic ≠ tafsir ≠ hifz.

create table learning_tracks (
  key text primary key check (key ~ '^[a-z][a-z0-9_]*$'),
  name text not null,
  description text,
  position int not null default 100
);
insert into learning_tracks (key, name, description, position) values
  ('quran_reading', 'Qur''an reading', 'Decoding the Arabic script of the Qur''an correctly.', 1),
  ('quran_recitation', 'Qur''an recitation', 'Reciting Qur''anic text accurately and fluently.', 2),
  ('tajwid', 'Tajwīd', 'Knowing and applying the rules that govern recitation.', 3),
  ('quranic_arabic', 'Qur''anic Arabic', 'Understanding the vocabulary, grammar and structures of Qur''anic Arabic.', 4),
  ('arabic_language', 'Arabic language', 'General Arabic language study.', 5),
  ('tafsir', 'Tafsīr', 'Meanings and scholarly explanation of the Qur''an.', 6),
  ('hifz', 'Ḥifẓ', 'Memorising and accurately reproducing the Qur''an.', 7),
  ('hadith', 'Ḥadīth', null, 8),
  ('fiqh', 'Fiqh', null, 9),
  ('aqidah', '''Aqīdah', null, 10),
  ('sirah', 'Sīrah', null, 11),
  ('other', 'Other', null, 99)
on conflict (key) do nothing;
alter table learning_tracks enable row level security;
create policy tracks_read on learning_tracks for select to public using (true);
create policy tracks_write on learning_tracks for all to public
  using (app_private.has_permission('settings.manage'))
  with check (app_private.has_permission('settings.manage'));
grant select on learning_tracks to anonymous, authenticated, sidra_app;
grant insert, update on learning_tracks to authenticated, sidra_app;

-- ------------------------------------------------------ course changes --

alter table courses
  add column track_key text references learning_tracks (key) on delete set null,
  add column delivery_languages text[] not null default '{}',
  add column visibility text not null default 'catalogue'
    check (visibility in ('catalogue', 'hidden')),
  add column target_learner text,
  add column metadata jsonb not null default '{}' check (jsonb_typeof(metadata) = 'object'),
  add constraint courses_languages_known check (app_private.check_languages(delivery_languages));
alter table courses add constraint courses_language_fk
  foreign key (language) references languages (code) not valid;
alter table courses validate constraint courses_language_fk;
grant update (track_key, delivery_languages, visibility, target_learner, metadata)
  on courses to authenticated, sidra_app;

alter table books add constraint books_language_fk
  foreign key (language) references languages (code) not valid;

-- Hidden courses are seen only by their learners and staff.
drop policy courses_read on courses;
create policy courses_read on courses for select to public using (
  (status = 'published'
   and (visibility = 'catalogue'
        or exists (select 1 from course_enrolments e
                   where e.course_id = courses.id
                     and e.user_id = app_private.current_user_id())))
  or app_private.is_course_staff(id));

create table course_prerequisites (
  course_id uuid not null references courses (id) on delete cascade,
  requires_course_id uuid not null references courses (id) on delete cascade,
  primary key (course_id, requires_course_id),
  check (course_id <> requires_course_id)
);
alter table course_prerequisites enable row level security;
create policy prerequisites_read on course_prerequisites for select to public using (true);
create policy prerequisites_write on course_prerequisites for all to public
  using (app_private.is_course_staff(course_id, true))
  with check (app_private.is_course_staff(course_id, true));
grant select on course_prerequisites to anonymous, authenticated, sidra_app;
grant insert, delete on course_prerequisites to authenticated, sidra_app;

-- Finished a course: marked completed, or every published lesson done.
create or replace function app_private.completed_course(p_user_id uuid, p_course_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (select 1 from course_enrolments
                 where user_id = p_user_id and course_id = p_course_id
                   and status = 'completed')
      or (exists (select 1 from lessons where course_id = p_course_id and status = 'published')
          and not exists (
            select 1 from lessons l
            where l.course_id = p_course_id and l.status = 'published'
              and not exists (select 1 from learner_progress p
                              where p.lesson_id = l.id and p.user_id = p_user_id
                                and p.status = 'completed')))
$$;

create or replace function app_private.require_prerequisites(p_course_id uuid)
returns void
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare v_missing text;
begin
  select string_agg(c.title, ', ') into v_missing
  from course_prerequisites p join courses c on c.id = p.requires_course_id
  where p.course_id = p_course_id
    and not app_private.completed_course(app_private.current_user_id(), p.requires_course_id);
  if v_missing is not null then
    raise exception 'finish % first', v_missing using errcode = 'PT409';
  end if;
end;
$$;

-- Learners' own paths into a course respect prerequisites (staff grants
-- remain an administrative decision).
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.enrol_in_course(uuid)'::regprocedure);
  if position('if v_course.access <> ''free'' or not v_course.self_enrol then' in v_src) = 0 then
    raise exception 'enrol_in_course changed; update 0018';
  end if;
  execute replace(v_src,
    'if v_course.access <> ''free'' or not v_course.self_enrol then',
    'perform app_private.require_prerequisites(p_course_id);
  if v_course.access <> ''free'' or not v_course.self_enrol then');

  v_src := pg_get_functiondef('public.start_course_payment(uuid, text)'::regprocedure);
  if position('  -- One prompt at a time' in v_src) = 0 then
    raise exception 'start_course_payment changed; update 0018';
  end if;
  execute replace(v_src, '  -- One prompt at a time',
    '  perform app_private.require_prerequisites(p_course_id);
  -- One prompt at a time');
end $$;

-- -------------------------------------------------------- lesson fields --

alter table lessons
  add column objectives text[] not null default '{}',
  add column delivery_language text references languages (code),
  add column quran_surah int check (quran_surah between 1 and 114),
  add column quran_ayah_start int check (quran_ayah_start > 0),
  add column quran_ayah_end int,
  add column juz int check (juz between 1 and 30),
  add column hizb int check (hizb between 1 and 60),
  add column mushaf_page int check (mushaf_page between 1 and 604),
  add column metadata jsonb not null default '{}' check (jsonb_typeof(metadata) = 'object'),
  add constraint lessons_ayah_range check (
    quran_ayah_end is null or (quran_ayah_start is not null and quran_ayah_end >= quran_ayah_start)),
  add constraint lessons_ayah_needs_surah check (quran_ayah_start is null or quran_surah is not null);

alter table curriculum_nodes
  add column delivery_language text references languages (code);

-- ------------------------------------------------------------ resources --

create table resources (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('document', 'image', 'audio', 'video', 'link', 'other')),
  title text not null check (length(trim(title)) > 0),
  description text,
  language text references languages (code),
  -- where the bytes live: an uploaded file (Cloudinary today) or a URL
  provider text not null check (provider in ('cloudinary', 'external', 'storage')),
  media_asset_id uuid references media_assets (id) on delete restrict,
  url text check (url is null or (url ~* '^https?://[a-z0-9]' and url !~ '\s' and length(url) <= 2000)),
  file_name text,
  mime_type text,
  extension text,
  bytes bigint check (bytes is null or bytes >= 0),
  checksum text,
  -- external links: what the preview found (title, description,
  -- thumbnail, site, content type) or {"status":"unavailable"}
  preview jsonb,
  verified_by uuid references users (id) on delete set null,
  verified_at timestamptz,
  -- also visible to people not enrolled (e.g. a course brochure)
  is_public boolean not null default false,
  version int not null default 1 check (version > 0),
  replaces_id uuid references resources (id) on delete set null,
  uploaded_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((provider = 'cloudinary' and media_asset_id is not null)
         or (provider = 'external' and url is not null)
         or provider = 'storage'),
  check (provider <> 'external' or kind = 'link' or url is not null)
);

create table assignments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses (id) on delete cascade,
  lesson_id uuid references lessons (id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  instructions text,
  submission_types text[] not null default '{image,document}'
    check (submission_types <@ array['image', 'document', 'audio', 'video', 'text']
           and cardinality(submission_types) > 0),
  max_files int not null default 5 check (max_files between 1 and 20),
  max_score numeric(6, 2) check (max_score is null or max_score > 0),
  due_at timestamptz,
  status publish_status not null default 'draft',
  position int not null default 0,
  created_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index assignments_lesson on assignments (lesson_id);
create index assignments_course on assignments (course_id);

create or replace function app_private.check_assignment()
returns trigger
language plpgsql
as $$
begin
  if new.lesson_id is not null and not exists (
    select 1 from lessons where id = new.lesson_id and course_id = new.course_id) then
    raise exception 'lesson belongs to another course';
  end if;
  return new;
end;
$$;
create trigger assignments_check before insert or update on assignments
  for each row execute function app_private.check_assignment();

create table resource_links (
  id uuid primary key default gen_random_uuid(),
  resource_id uuid not null references resources (id) on delete cascade,
  course_id uuid references courses (id) on delete cascade,
  unit_id uuid references course_units (id) on delete cascade,
  book_id uuid references books (id) on delete cascade,
  node_id uuid references curriculum_nodes (id) on delete cascade,
  lesson_id uuid references lessons (id) on delete cascade,
  assignment_id uuid references assignments (id) on delete cascade,
  position int not null default 0,
  status publish_status not null default 'published',
  created_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now(),
  check (num_nonnulls(course_id, unit_id, book_id, node_id, lesson_id, assignment_id) = 1)
);
create index resource_links_lesson on resource_links (lesson_id);
create index resource_links_course on resource_links (course_id);
create index resource_links_resource on resource_links (resource_id);

-- The course a link belongs to (null for books).
create or replace function app_private.link_course(k resource_links)
returns uuid
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce(
    k.course_id,
    (select course_id from course_units where id = k.unit_id),
    (select course_id from curriculum_nodes where id = k.node_id),
    (select course_id from lessons where id = k.lesson_id),
    (select course_id from assignments where id = k.assignment_id))
$$;

create or replace function app_private.can_read_assignment(p_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (
    select 1 from assignments a where a.id = p_id and (
      app_private.is_course_staff(a.course_id)
      or app_private.teaches(a.course_id, a.lesson_id)
      or (a.status = 'published' and (
            (a.lesson_id is not null and app_private.can_read_lesson(a.lesson_id))
            or (a.lesson_id is null and app_private.is_enrolled(a.course_id))))))
$$;

create or replace function app_private.can_read_resource(p_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (
    select 1 from resources r where r.id = p_id and (
      r.uploaded_by = app_private.current_user_id()
      or app_private.has_permission('courses.view')
      or app_private.has_permission('content.upload')
      or exists (
        select 1 from resource_links k where k.resource_id = r.id and (
          app_private.is_course_staff(app_private.link_course(k))
          or (k.status = 'published' and (
                (k.lesson_id is not null and app_private.can_read_lesson(k.lesson_id))
             or (k.assignment_id is not null and app_private.can_read_assignment(k.assignment_id))
             or (k.book_id is not null and app_private.current_user_id() is not null
                 and exists (select 1 from books b where b.id = k.book_id and b.status = 'published'))
             or (coalesce(k.course_id, k.unit_id, k.node_id) is not null and (
                   app_private.is_enrolled(app_private.link_course(k))
                   or (r.is_public and exists (
                         select 1 from courses c where c.id = app_private.link_course(k)
                           and c.status = 'published'))))))))))
$$;

-- Who may attach / edit resources on a course's material.
create or replace function app_private.can_author(p_course_id uuid, p_lesson_id uuid default null)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.has_permission('content.upload')
      or app_private.has_permission('curriculum.edit')
      or (p_course_id is not null and (app_private.is_course_staff(p_course_id, true)
                                       or app_private.teaches(p_course_id, p_lesson_id)))
$$;

alter table resources enable row level security;
create policy resources_read on resources for select to public
  using (app_private.can_read_resource(id));
create policy resources_insert on resources for insert to public with check (
  uploaded_by = app_private.current_user_id()
  and (app_private.has_permission('content.upload')
       or app_private.has_permission('curriculum.edit')
       or app_private.current_app_role() = 'teacher'));
create policy resources_update on resources for update to public
  using (uploaded_by = app_private.current_user_id()
         or app_private.has_permission('content.upload'))
  with check (uploaded_by = app_private.current_user_id()
              or app_private.has_permission('content.upload'));
grant select, insert, update on resources to authenticated, sidra_app;

alter table resource_links enable row level security;
create policy resource_links_read on resource_links for select to public
  using (app_private.can_read_resource(resource_id));
create policy resource_links_write on resource_links for all to public
  using (case when book_id is not null then app_private.has_permission('books.manage')
              else app_private.can_author(app_private.link_course(resource_links), lesson_id) end)
  with check (case when book_id is not null then app_private.has_permission('books.manage')
                   else app_private.can_author(app_private.link_course(resource_links), lesson_id) end);
grant select, insert, update, delete on resource_links to authenticated, sidra_app;

alter table assignments enable row level security;
create policy assignments_read on assignments for select to public
  using (app_private.can_read_assignment(id));
create policy assignments_write on assignments for all to public
  using (app_private.can_author(course_id, lesson_id))
  with check (app_private.can_author(course_id, lesson_id));
grant select, insert, update, delete on assignments to authenticated, sidra_app;

do $$
declare t text;
begin
  foreach t in array array['resources', 'resource_links', 'assignments'] loop
    execute format('create trigger %I after insert or update or delete on %I
                      for each row execute function app_private.audit()', t || '_audit', t);
  end loop;
end $$;

-- ------------------------------------------------------- content blocks --

alter table lesson_content_blocks
  add column language text references languages (code),
  add column audience text not null default 'all' check (audience in ('all', 'staff')),
  add column resource_id uuid references resources (id) on delete restrict,
  add column assignment_id uuid references assignments (id) on delete restrict;

create or replace function app_private.valid_block(
  p_type content_block_type, p_body jsonb, p_media uuid, p_assessment uuid)
returns boolean
language sql immutable
as $$
  select case p_type
    when 'heading' then jsonb_typeof(p_body->'text') = 'string'
      and coalesce((p_body->>'level')::int, 2) between 1 and 3
    when 'rich_text' then jsonb_typeof(p_body->'text') = 'string'
      and coalesce(p_body->>'format', 'markdown') in ('markdown', 'plain')
    when 'image' then p_media is not null
    when 'audio' then p_media is not null
    when 'video' then p_media is not null
    when 'attachment' then p_media is not null
    when 'quran_text' then jsonb_typeof(p_body->'arabic') = 'string'
      and (p_body->'surah' is null or (p_body->>'surah')::int between 1 and 114)
    when 'translation' then jsonb_typeof(p_body->'text') = 'string'
      and jsonb_typeof(p_body->'language') = 'string'
    when 'transliteration' then jsonb_typeof(p_body->'text') = 'string'
    when 'reference' then jsonb_typeof(p_body->'citation') = 'string'
    when 'callout' then jsonb_typeof(p_body->'text') = 'string'
      and coalesce(p_body->>'tone', 'info') in ('info', 'note', 'warning')
    when 'assessment' then p_assessment is not null
    when 'divider' then true
    when 'external_link' then jsonb_typeof(p_body->'url') = 'string'
      and p_body->>'url' ~* '^https?://[a-z0-9]'
      and p_body->>'url' !~ '\s'
      and length(p_body->>'url') <= 2000
      and coalesce(p_body->>'provider', 'web') in ('youtube', 'telegram', 'web')
    else true   -- resource / assignment: checked by lesson_content_blocks_refs
  end
$$;
alter table lesson_content_blocks add constraint lesson_content_blocks_refs check (
  (block_type <> 'resource' or resource_id is not null)
  and (block_type <> 'assignment' or assignment_id is not null));

-- Teacher notes (audience = staff) never reach learners.
drop policy blocks_read on lesson_content_blocks;
create policy blocks_read on lesson_content_blocks for select to public using (
  app_private.can_read_lesson(lesson_id)
  and (audience = 'all'
       or app_private.is_course_staff((select course_id from lessons where id = lesson_id))
       or app_private.teaches((select course_id from lessons where id = lesson_id), lesson_id)));

-- -------------------------------------------------------- submissions --

create type submission_status as enum (
  'submitted', 'received', 'under_review', 'reviewed', 'returned', 'resubmission_requested');

create table submissions (
  -- client-generated: a queued offline submission is sent once
  id uuid primary key,
  assignment_id uuid not null references assignments (id) on delete restrict,
  user_id uuid not null references users (id) on delete cascade,
  course_id uuid not null references courses (id) on delete cascade,
  lesson_id uuid references lessons (id) on delete set null,
  attempt int not null default 1 check (attempt > 0),
  status submission_status not null default 'submitted',
  text_answer text,
  submitted_at timestamptz not null default now(),
  reviewed_by uuid references users (id) on delete set null,
  reviewed_at timestamptz,
  feedback text,
  score numeric(6, 2) check (score is null or score >= 0),
  feedback_audio_asset_id uuid references media_assets (id) on delete set null,
  updated_at timestamptz not null default now(),
  unique (assignment_id, user_id, attempt)
);
create index submissions_course_status on submissions (course_id, status, submitted_at desc);
create index submissions_user on submissions (user_id, submitted_at desc);

create table submission_files (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references submissions (id) on delete cascade,
  media_asset_id uuid not null references media_assets (id) on delete restrict,
  file_name text,
  mime_type text,
  bytes bigint,
  position int not null default 0
);
create index submission_files_media on submission_files (media_asset_id);

alter table submissions enable row level security;
alter table submission_files enable row level security;
create policy submissions_read on submissions for select to public
  using (user_id = app_private.current_user_id()
         or app_private.teaches(course_id, lesson_id));
create policy submission_files_read on submission_files for select to public
  using (exists (select 1 from submissions s where s.id = submission_id));
grant select on submissions, submission_files to authenticated, sidra_app;
do $$
declare t text;
begin
  foreach t in array array['submissions', 'submission_files'] loop
    execute format('create trigger %I after insert or update or delete on %I
                      for each row execute function app_private.audit()', t || '_audit', t);
  end loop;
end $$;

-- Learner hands in work. Files must be ones they uploaded themselves.
create or replace function public.submit_work(
  p_submission_id uuid, p_assignment_id uuid, p_text text default null,
  p_files jsonb default '[]')
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_a assignments%rowtype;
  v_prev submissions%rowtype;
  v_sub submissions%rowtype;
  v_file jsonb;
  v_pos int := 0;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  -- Idempotent: the same queued submission sent twice is one submission.
  select * into v_sub from submissions where id = p_submission_id;
  if found then
    if v_sub.user_id <> v_me then raise exception 'not yours' using errcode = 'PT403'; end if;
    return to_jsonb(v_sub);
  end if;

  select * into v_a from assignments where id = p_assignment_id and status = 'published';
  if not found or not (
       (v_a.lesson_id is not null and app_private.can_read_lesson(v_a.lesson_id))
       or (v_a.lesson_id is null and app_private.is_enrolled(v_a.course_id))) then
    raise exception 'assignment not found' using errcode = 'PT404';
  end if;
  if jsonb_array_length(coalesce(p_files, '[]')) = 0 and coalesce(trim(p_text), '') = '' then
    raise exception 'add a photo, file or answer' using errcode = 'PT422';
  end if;
  if jsonb_array_length(coalesce(p_files, '[]')) > v_a.max_files then
    raise exception 'at most % files', v_a.max_files using errcode = 'PT422';
  end if;
  if exists (select 1 from jsonb_array_elements(coalesce(p_files, '[]')) f
             where not exists (select 1 from media_assets m
                               where m.id = (f->>'media_asset_id')::uuid
                                 and m.uploaded_by = v_me)) then
    raise exception 'files must be your own uploads' using errcode = 'PT403';
  end if;

  select * into v_prev from submissions
  where assignment_id = p_assignment_id and user_id = v_me
  order by attempt desc limit 1;
  if found and v_prev.status not in ('resubmission_requested', 'returned') then
    raise exception 'already handed in; wait for your teacher' using errcode = 'PT409';
  end if;

  insert into submissions (id, assignment_id, user_id, course_id, lesson_id, attempt, text_answer)
  values (p_submission_id, v_a.id, v_me, v_a.course_id, v_a.lesson_id,
          coalesce(v_prev.attempt, 0) + 1, nullif(trim(p_text), ''))
  returning * into v_sub;

  for v_file in select * from jsonb_array_elements(coalesce(p_files, '[]')) loop
    insert into submission_files (submission_id, media_asset_id, file_name, mime_type, bytes, position)
    values (v_sub.id, (v_file->>'media_asset_id')::uuid, v_file->>'file_name',
            v_file->>'mime_type', (v_file->>'bytes')::bigint, v_pos);
    v_pos := v_pos + 1;
  end loop;
  return to_jsonb(v_sub);
end;
$$;

create or replace function app_private.submission_json(s submissions)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select to_jsonb(s) || jsonb_build_object(
    'learner', (select display_name from users where id = s.user_id),
    'assignment_title', (select title from assignments where id = s.assignment_id),
    'lesson_title', (select title from lessons where id = s.lesson_id),
    'course_title', (select title from courses where id = s.course_id),
    'reviewer', (select display_name from users where id = s.reviewed_by),
    'files', (select coalesce(jsonb_agg(jsonb_build_object(
                'media_asset_id', f.media_asset_id, 'file_name', f.file_name,
                'mime_type', f.mime_type, 'bytes', f.bytes,
                'kind', (select kind from media_assets where id = f.media_asset_id))
                order by f.position), '[]')
              from submission_files f where f.submission_id = s.id))
$$;

create or replace function public.my_submissions(p_assignment_id uuid default null)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.submission_json(s) from submissions s
  where s.user_id = app_private.current_user_id()
    and (p_assignment_id is null or s.assignment_id = p_assignment_id)
  order by s.submitted_at desc
  limit 100
$$;

-- Teacher's queue: only work in lessons they teach.
create or replace function public.teacher_submissions(
  p_course_id uuid default null, p_lesson_id uuid default null,
  p_status submission_status default null, p_limit int default 50, p_offset int default 0)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.submission_json(s) from submissions s
  where app_private.teaches(s.course_id, s.lesson_id)
    and (p_course_id is null or s.course_id = p_course_id)
    and (p_lesson_id is null or s.lesson_id = p_lesson_id)
    and (p_status is null or s.status = p_status)
  order by (s.status in ('submitted', 'received', 'under_review')) desc, s.submitted_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0)
$$;

create or replace function public.review_submission(
  p_submission_id uuid, p_status submission_status,
  p_feedback text default null, p_score numeric default null,
  p_feedback_audio_asset_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v submissions%rowtype; v_max numeric;
begin
  select * into v from submissions where id = p_submission_id for update;
  if not found or not app_private.teaches(v.course_id, v.lesson_id) then
    raise exception 'submission not found' using errcode = 'PT404';
  end if;
  if p_status = 'submitted' then
    raise exception 'choose a review status' using errcode = 'PT422';
  end if;
  select max_score into v_max from assignments where id = v.assignment_id;
  if p_score is not null and v_max is not null and p_score > v_max then
    raise exception 'score cannot exceed %', v_max using errcode = 'PT422';
  end if;
  update submissions set
    status = p_status,
    feedback = coalesce(nullif(trim(p_feedback), ''), feedback),
    score = coalesce(p_score, score),
    feedback_audio_asset_id = coalesce(p_feedback_audio_asset_id, feedback_audio_asset_id),
    reviewed_by = case when p_status in ('reviewed', 'returned', 'resubmission_requested')
                       then app_private.current_user_id() else reviewed_by end,
    reviewed_at = case when p_status in ('reviewed', 'returned', 'resubmission_requested')
                       then now() else reviewed_at end,
    updated_at = now()
  where id = v.id returning * into v;
  return app_private.submission_json(v);
end;
$$;

-- ------------------------------------------------------- media access --
-- Submission files: only the learner and the people who teach that lesson.
-- Everything else: console content staff, the uploader, and anyone who may
-- read the lesson / resource / course it is part of. (Replaces the rule
-- that let every teacher and admin read every file.)
create or replace function app_private.can_read_media(p_asset_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case
    when exists (select 1 from submission_files f where f.media_asset_id = p_asset_id) then
      exists (select 1 from submission_files f join submissions s on s.id = f.submission_id
              where f.media_asset_id = p_asset_id
                and (s.user_id = app_private.current_user_id()
                     or app_private.teaches(s.course_id, s.lesson_id)))
    else
      app_private.has_permission('courses.view')
      or app_private.has_permission('content.upload')
      or exists (select 1 from media_assets m where m.id = p_asset_id
                 and m.uploaded_by = app_private.current_user_id())
      or exists (select 1 from courses c where c.thumbnail_asset_id = p_asset_id
                 and (c.status = 'published' or app_private.is_course_staff(c.id)))
      or exists (select 1 from books b where b.cover_asset_id = p_asset_id and b.status = 'published')
      or exists (select 1 from lesson_content_blocks b
                 where b.media_asset_id = p_asset_id and app_private.can_read_lesson(b.lesson_id))
      or exists (select 1 from assessment_questions q join assessments a on a.id = q.assessment_id
                 where q.prompt_media_asset_id = p_asset_id
                   and a.lesson_id is not null and app_private.can_read_lesson(a.lesson_id))
      or exists (select 1 from lesson_reviews r
                 where r.feedback_audio_asset_id = p_asset_id
                   and (r.user_id = app_private.current_user_id()
                        or r.teacher_id = app_private.current_user_id()))
      or exists (select 1 from submissions s
                 where s.feedback_audio_asset_id = p_asset_id
                   and (s.user_id = app_private.current_user_id()
                        or app_private.teaches(s.course_id, s.lesson_id)))
      or exists (select 1 from resources r
                 where r.media_asset_id = p_asset_id and app_private.can_read_resource(r.id))
  end
$$;

alter table media_assets
  add column file_name text,
  add column mime_type text,
  add column checksum text;

-- ------------------------------------------------- move / copy lessons --

create or replace function public.move_lesson(
  p_lesson_id uuid, p_unit_id uuid default null, p_node_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v lessons%rowtype; v_pos int;
begin
  select * into v from lessons where id = p_lesson_id for update;
  if not found or not app_private.is_course_staff(v.course_id, true) then
    raise exception 'lesson not found' using errcode = 'PT404';
  end if;
  if p_node_id is not null and not exists (
       select 1 from curriculum_nodes where id = p_node_id and course_id = v.course_id) then
    raise exception 'that section belongs to another course' using errcode = 'PT422';
  end if;
  if p_unit_id is not null and not exists (
       select 1 from course_units where id = p_unit_id and course_id = v.course_id) then
    raise exception 'that unit belongs to another course' using errcode = 'PT422';
  end if;
  select coalesce(max(position) + 1, 0) into v_pos from (
    select position from lessons
     where course_id = v.course_id and id <> v.id
       and node_id is not distinct from p_node_id
       and (p_node_id is not null or unit_id is not distinct from p_unit_id)
    union all
    select position from curriculum_nodes
     where course_id = v.course_id
       and parent_id is not distinct from p_node_id
       and (p_node_id is not null or unit_id is not distinct from p_unit_id)) t;
  update lessons set node_id = p_node_id,
    unit_id = case when p_node_id is null then p_unit_id end,
    position = v_pos, updated_at = now()
  where id = v.id returning * into v;
  return to_jsonb(v);
end;
$$;

-- A draft copy (with its content and resources) in another course.
create or replace function public.copy_lesson(
  p_lesson_id uuid, p_course_id uuid,
  p_unit_id uuid default null, p_node_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v lessons%rowtype; v_new lessons%rowtype; v_pos int;
begin
  select * into v from lessons where id = p_lesson_id;
  if not found or not app_private.is_course_staff(v.course_id) then
    raise exception 'lesson not found' using errcode = 'PT404';
  end if;
  if not app_private.is_course_staff(p_course_id, true) then
    raise exception 'not allowed to edit that course' using errcode = 'PT403';
  end if;
  if p_node_id is not null and not exists (
       select 1 from curriculum_nodes where id = p_node_id and course_id = p_course_id) then
    raise exception 'that section belongs to another course' using errcode = 'PT422';
  end if;
  if p_unit_id is not null and not exists (
       select 1 from course_units where id = p_unit_id and course_id = p_course_id) then
    raise exception 'that unit belongs to another course' using errcode = 'PT422';
  end if;
  select coalesce(max(position) + 1, 0) into v_pos from lessons
  where course_id = p_course_id and node_id is not distinct from p_node_id
    and (p_node_id is not null or unit_id is not distinct from p_unit_id);

  insert into lessons (course_id, unit_id, node_id, title, summary, position,
                       estimated_minutes, is_preview, status, objectives, delivery_language,
                       quran_surah, quran_ayah_start, quran_ayah_end, juz, hizb,
                       mushaf_page, metadata)
  values (p_course_id, case when p_node_id is null then p_unit_id end, p_node_id,
          v.title, v.summary, v_pos, v.estimated_minutes, v.is_preview, 'draft',
          v.objectives, v.delivery_language, v.quran_surah, v.quran_ayah_start,
          v.quran_ayah_end, v.juz, v.hizb, v.mushaf_page,
          v.metadata || jsonb_build_object('copied_from', v.id))
  returning * into v_new;

  -- Quizzes and assignments belong to one course; they are not copied.
  insert into lesson_content_blocks (lesson_id, position, block_type, body, media_asset_id,
                                     language, audience, resource_id)
  select v_new.id, position, block_type, body, media_asset_id, language, audience, resource_id
  from lesson_content_blocks
  where lesson_id = v.id and block_type not in ('assessment', 'assignment');

  insert into resource_links (resource_id, lesson_id, position, status, created_by)
  select resource_id, v_new.id, position, status, app_private.current_user_id()
  from resource_links where lesson_id = v.id;
  return to_jsonb(v_new);
end;
$$;

-- ----------------------------------------------- teacher languages --

alter table users add column languages text[] not null default '{}'
  check (app_private.check_languages(languages));

create or replace function public.set_user_languages(p_user_id uuid, p_languages text[])
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not (p_user_id = app_private.current_user_id()
          or app_private.has_permission('teachers.create')
          or app_private.has_permission('learners.edit')) then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  if not app_private.check_languages(p_languages) then
    raise exception 'unknown language' using errcode = 'PT422';
  end if;
  update users set languages = coalesce(p_languages, '{}') where id = p_user_id;
end;
$$;

-- ------------------------------------------- payments server status --

create table app_private.payment_server_status (
  id int primary key default 1 check (id = 1),
  last_seen timestamptz not null,
  version text,
  public_url text,
  started_at timestamptz
);

create table payment_diagnostics (
  id uuid primary key default gen_random_uuid(),
  requested_by uuid references users (id) on delete set null,
  requested_at timestamptz not null default now(),
  started_at timestamptz,
  finished_at timestamptz,
  status text not null default 'queued' check (status in ('queued', 'running', 'done', 'failed')),
  -- [{key, label, result: pass|warning|fail, message}]
  results jsonb not null default '[]'
);
alter table payment_diagnostics enable row level security;
create trigger payment_diagnostics_audit after insert on payment_diagnostics
  for each row execute function app_private.audit();

create or replace function payments_api.heartbeat(p_version text, p_public_url text default null)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  insert into app_private.payment_server_status (id, last_seen, version, public_url, started_at)
  values (1, now(), p_version, p_public_url, now())
  on conflict (id) do update set last_seen = now(), version = excluded.version,
    public_url = excluded.public_url
$$;

create or replace function payments_api.claim_diagnostic()
returns uuid
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update payment_diagnostics set status = 'running', started_at = now()
  where id = (select id from payment_diagnostics where status = 'queued'
              order by requested_at limit 1 for update skip locked)
  returning id
$$;

create or replace function payments_api.finish_diagnostic(p_id uuid, p_results jsonb)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update payment_diagnostics set status = 'done', finished_at = now(), results = p_results
  where id = p_id
$$;

-- Database side of the duplicate-notification test: a fake payment is
-- settled twice inside a savepoint that is always rolled back.
create or replace function payments_api.selftest_idempotency()
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_user uuid := (select id from users order by created_at limit 1);
  v_first text; v_second text; v_count int;
begin
  begin
    insert into payments (user_id, amount, currency, method, status, provider_uuid)
    values (v_user, 1000, 'UGX', 'marzpay', 'processing', 'selftest-' || gen_random_uuid());
    select payments_api.settle(provider_uuid, 'successful', 1000, 'SELFTEST')
      into v_first from payments where provider_uuid like 'selftest-%' and status = 'processing';
    select payments_api.settle(provider_uuid, 'successful', 1000, 'SELFTEST')
      into v_second from payments where provider_uuid like 'selftest-%';
    select count(*) into v_count from payments
    where provider_uuid like 'selftest-%' and status = 'verified';
    raise exception using errcode = 'P0100', message = 'rollback';
  exception when sqlstate 'P0100' then
    null;  -- everything above is undone
  end;
  return jsonb_build_object('first', v_first, 'second', v_second, 'verified_rows', v_count);
end;
$$;

-- Unmatched / stuck payments, for the reconciliation test.
create or replace function payments_api.reconciliation_report()
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select jsonb_build_object(
    'stuck', (select count(*) from payments where method = 'marzpay'
              and status in ('initiated', 'processing') and created_at < now() - interval '30 minutes'),
    'verified_without_access', (
      select count(*) from payments p
      join courses c on c.id = p.course_id and c.access = 'paid'
      where p.status = 'verified'
        and (select outstanding from app_private.course_balance(p.user_id, p.course_id)) = 0
        and not exists (select 1 from course_enrolments e where e.user_id = p.user_id
                        and e.course_id = p.course_id and e.status in ('active', 'completed'))),
    'amount_mismatch_waiting', (select count(*) from payments where method = 'marzpay'
                                and status = 'pending'),
    'latest_provider_uuid', (select provider_uuid from payments where provider_uuid is not null
                             and provider_uuid not like 'selftest-%'
                             order by created_at desc limit 1))
$$;

create or replace function public.request_payment_diagnostics()
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v uuid;
begin
  if not (app_private.has_permission('settings.manage')
          or app_private.has_permission('finance.verify_payment')) then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  insert into payment_diagnostics (requested_by) values (app_private.current_user_id())
  returning id into v;
  perform pg_notify('sidra_payments', 'diagnostics');
  return v;
end;
$$;

create or replace function public.payment_integration_status()
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case when not (app_private.has_permission('settings.manage')
                        or app_private.has_permission('finance.view')) then null
  else jsonb_build_object(
    'server_last_seen', (select last_seen from app_private.payment_server_status),
    'server_version', (select version from app_private.payment_server_status),
    'server_public_url', (select public_url from app_private.payment_server_status),
    'server_online', coalesce((select last_seen > now() - interval '90 seconds'
                               from app_private.payment_server_status), false),
    'latest_run', (select to_jsonb(d) from payment_diagnostics d
                   order by requested_at desc limit 1)) end
$$;

-- --------------------------------------------------------- grants --

do $$
declare r record;
begin
  for r in select p.oid::regprocedure as fn
           from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.proname in (
             'submit_work', 'my_submissions', 'teacher_submissions', 'review_submission',
             'move_lesson', 'copy_lesson', 'set_user_languages',
             'request_payment_diagnostics', 'payment_integration_status') loop
    execute format('revoke all on function %s from public', r.fn);
    execute format('grant execute on function %s to authenticated, sidra_app', r.fn);
  end loop;
end $$;
revoke all on all functions in schema payments_api from public;
grant execute on all functions in schema payments_api to sidra_payments;
grant execute on function app_private.check_languages(text[]) to authenticated, sidra_app;
grant execute on function app_private.can_read_resource(uuid), app_private.can_read_assignment(uuid),
  app_private.can_author(uuid, uuid), app_private.link_course(resource_links),
  app_private.completed_course(uuid, uuid), app_private.require_prerequisites(uuid)
  to authenticated, sidra_app;
