-- Phase 3.5: the WhatsApp teaching method, done properly.
--
--   permanent content      courses → lessons → resources (Page 12 image…)
--   teaching group         "Yassarna Beginners — Group A" (learners + teachers)
--   teaching portion       what a teacher assigns at a point in time:
--                          "Page 12 · Group A · Monday", with its page image,
--                          instruction voice note and model recitation —
--                          each stored ONCE as a resource and linked
--   participation          one row per learner per portion (own status)
--   attempts               submissions (existing table; now also for portions)
--   reviews                every teacher verdict, never overwritten
--   corrections            reusable correction recordings, categorised
--
-- One teacher action serves every learner; every learner still gets an
-- individual review. Additive: nothing existing is dropped.

create type participation_status as enum (
  'assigned', 'opened', 'submitted', 'under_review', 'correction_required', 'completed');
create type review_result as enum (
  'excellent', 'correct', 'minor_correction', 'correction_required', 'needs_explanation');

-- ------------------------------------------------------------- groups --

create table teaching_groups (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses (id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  description text,
  created_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now(),
  archived_at timestamptz,
  unique (course_id, name)
);
create table teaching_group_members (
  group_id uuid not null references teaching_groups (id) on delete cascade,
  user_id uuid not null references users (id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (group_id, user_id)
);
create index teaching_group_members_user on teaching_group_members (user_id);
create table teaching_group_teachers (
  group_id uuid not null references teaching_groups (id) on delete cascade,
  user_id uuid not null references users (id) on delete cascade,
  primary key (group_id, user_id)
);

-- ----------------------------------------------------------- portions --

create table teaching_portions (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses (id) on delete cascade,
  group_id uuid references teaching_groups (id) on delete set null,
  -- the permanent lesson this portion teaches (optional)
  lesson_id uuid references lessons (id) on delete set null,
  title text not null check (length(trim(title)) > 0),
  sequence int not null default 1,
  instructions text,
  -- language the teacher explains in (the page itself may be Arabic)
  instruction_language text references languages (code),
  submission_types text[] not null default '{audio}'
    check (submission_types <@ array['image', 'document', 'audio', 'video', 'text']
           and cardinality(submission_types) > 0),
  requires_submission boolean not null default true,
  due_at timestamptz,
  status text not null default 'draft' check (status in ('draft', 'assigned', 'closed')),
  previous_id uuid references teaching_portions (id) on delete set null,
  created_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now(),
  assigned_at timestamptz,
  updated_at timestamptz not null default now()
);
create index teaching_portions_group on teaching_portions (group_id, sequence desc);
create index teaching_portions_course on teaching_portions (course_id, created_at desc);

-- The shared files of a portion. A resource row is ONE stored file; 25
-- learners read the same row.
create table portion_resources (
  id uuid primary key default gen_random_uuid(),
  portion_id uuid not null references teaching_portions (id) on delete cascade,
  resource_id uuid not null references resources (id) on delete restrict,
  role text not null check (role in ('page', 'instruction', 'model', 'worksheet', 'other')),
  position int not null default 0,
  unique (portion_id, resource_id, role)
);
create index portion_resources_resource on portion_resources (resource_id);

create table portion_learners (
  id uuid primary key default gen_random_uuid(),
  portion_id uuid not null references teaching_portions (id) on delete cascade,
  user_id uuid not null references users (id) on delete cascade,
  status participation_status not null default 'assigned',
  last_result review_result,
  attempts int not null default 0,
  assigned_at timestamptz not null default now(),
  opened_at timestamptz,
  last_submitted_at timestamptz,
  completed_at timestamptz,
  unique (portion_id, user_id)
);
create index portion_learners_user on portion_learners (user_id, status);
create index portion_learners_portion on portion_learners (portion_id, status);

-- Attempts: the existing submissions table serves both assignments and
-- portions (one of the two).
alter table submissions alter column assignment_id drop not null;
alter table submissions
  add column portion_id uuid references teaching_portions (id) on delete restrict,
  add constraint submissions_one_target check (num_nonnulls(assignment_id, portion_id) = 1);
create unique index submissions_portion_attempt on submissions (portion_id, user_id, attempt)
  where portion_id is not null;

-- ------------------------------------------------------- corrections --

create table correction_categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references correction_categories (id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  position int not null default 0,
  created_at timestamptz not null default now(),
  unique (parent_id, name)
);

create or replace function app_private.seed_category(p_parent text, p_name text, p_pos int)
returns void language sql as $$
  insert into correction_categories (id, parent_id, name, position)
  values (app_private.seed_id('correction-category:' || coalesce(p_parent || '/', '') || p_name),
          case when p_parent is not null
               then app_private.seed_id('correction-category:' || p_parent) end,
          p_name, p_pos)
  on conflict do nothing
$$;
-- Starting taxonomy (fully editable by staff).
do $$
begin
  perform app_private.seed_category(null, 'Pronunciation (letters)', 0);
  perform app_private.seed_category('Pronunciation (letters)', l, i::int)
  from unnest(array['ع', 'ح', 'خ', 'ه', 'ء', 'ص', 'ض', 'ط', 'ظ', 'ق', 'غ', 'ذ', 'ث', 'س / ص', 'ت / ط', 'د / ض', 'ذ / ظ / ز', 'ك / ق'])
       with ordinality as t(l, i);
  perform app_private.seed_category(null, 'Ḥarakāt', 1);
  perform app_private.seed_category('Ḥarakāt', l, i::int)
  from unnest(array['Fatḥah', 'Kasrah', 'Ḍammah', 'Tanwīn', 'Sukūn', 'Shaddah', 'Madd (long vowels)'])
       with ordinality as t(l, i);
  perform app_private.seed_category(null, 'Tajwīd', 2);
  perform app_private.seed_category('Tajwīd', l, i::int)
  from unnest(array['Ghunnah', 'Qalqalah', 'Madd', 'Iẓhār', 'Idghām', 'Iqlāb', 'Ikhfāʾ', 'Tafkhīm / tarqīq', 'Mīm sākinah'])
       with ordinality as t(l, i);
  perform app_private.seed_category(null, 'Reading', 3);
  perform app_private.seed_category('Reading', l, i::int)
  from unnest(array['Joining letters', 'Stopping', 'Starting again', 'Fluency', 'Repeated letters', 'Skipped or added words'])
       with ordinality as t(l, i);
end $$;
drop function app_private.seed_category(text, text, int);

create table corrections (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(trim(title)) > 0),
  explanation text,
  category_id uuid references correction_categories (id) on delete set null,
  media_asset_id uuid references media_assets (id) on delete restrict,
  language text references languages (code),
  tags text[] not null default '{}',
  course_id uuid references courses (id) on delete set null,
  lesson_id uuid references lessons (id) on delete set null,
  created_by uuid references users (id) on delete set null,
  use_count int not null default 0,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (media_asset_id is not null or coalesce(trim(explanation), '') <> '')
);
create index corrections_category on corrections (category_id) where archived_at is null;

create table submission_reviews (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references submissions (id) on delete cascade,
  reviewer_id uuid references users (id) on delete set null,
  result review_result not null,
  feedback text,
  score numeric(6, 2),
  -- a reusable correction from the library…
  correction_id uuid references corrections (id) on delete set null,
  -- …and/or a recording made just for this learner
  correction_asset_id uuid references media_assets (id) on delete set null,
  created_at timestamptz not null default now()
);
create index submission_reviews_submission on submission_reviews (submission_id, created_at desc);
create index submission_reviews_correction on submission_reviews (correction_id);

create table teacher_notes (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references users (id) on delete cascade,
  course_id uuid references courses (id) on delete cascade,
  author_id uuid references users (id) on delete set null,
  body text not null check (length(trim(body)) > 0),
  created_at timestamptz not null default now()
);
create index teacher_notes_learner on teacher_notes (learner_id, created_at desc);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users (id) on delete cascade,
  kind text not null,
  title text not null,
  body text,
  data jsonb not null default '{}',
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index notifications_user on notifications (user_id, read_at, created_at desc);

alter table resources
  add column tags text[] not null default '{}',
  add column archived_at timestamptz;

-- ------------------------------------------------------------ access --

-- Does the caller teach this portion? Its group's teachers, or anyone who
-- teaches the course / lesson.
create or replace function app_private.teaches_portion(p_portion_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (
    select 1 from teaching_portions p where p.id = p_portion_id and (
      app_private.teaches(p.course_id, p.lesson_id)
      or (app_private.has_permission('teaching.review') and exists (
            select 1 from teaching_group_teachers t
            where t.group_id = p.group_id and t.user_id = app_private.current_user_id()))))
$$;

create or replace function app_private.teaches_group(p_group_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (
    select 1 from teaching_groups g where g.id = p_group_id and (
      app_private.teaches(g.course_id)
      or (app_private.has_permission('teaching.review') and exists (
            select 1 from teaching_group_teachers t
            where t.group_id = g.id and t.user_id = app_private.current_user_id()))))
$$;

create or replace function app_private.in_portion(p_portion_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (select 1 from portion_learners
                 where portion_id = p_portion_id and user_id = app_private.current_user_id())
$$;

do $$
declare t text;
begin
  foreach t in array array['teaching_groups', 'teaching_group_members', 'teaching_group_teachers',
                           'teaching_portions', 'portion_resources', 'portion_learners',
                           'correction_categories', 'corrections', 'submission_reviews',
                           'teacher_notes', 'notifications'] loop
    execute format('alter table %I enable row level security', t);
    execute format('grant select on %I to authenticated, sidra_app', t);
  end loop;
  foreach t in array array['teaching_groups', 'teaching_group_members', 'teaching_portions',
                           'portion_resources', 'correction_categories', 'corrections',
                           'submission_reviews', 'teacher_notes'] loop
    execute format('create trigger %I after insert or update or delete on %I
                      for each row execute function app_private.audit()', t || '_audit', t);
  end loop;
end $$;

create policy groups_read on teaching_groups for select to public
  using (app_private.teaches_group(id)
         or exists (select 1 from teaching_group_members m
                    where m.group_id = id and m.user_id = app_private.current_user_id()));
create policy group_members_read on teaching_group_members for select to public
  using (user_id = app_private.current_user_id() or app_private.teaches_group(group_id));
create policy group_teachers_read on teaching_group_teachers for select to public
  using (app_private.teaches_group(group_id)
         or exists (select 1 from teaching_group_members m
                    where m.group_id = teaching_group_teachers.group_id
                      and m.user_id = app_private.current_user_id()));
create policy portions_read on teaching_portions for select to public
  using (app_private.teaches_portion(id)
         or (status <> 'draft' and app_private.in_portion(id)));
create policy portion_resources_read on portion_resources for select to public
  using (app_private.teaches_portion(portion_id) or app_private.in_portion(portion_id));
create policy portion_learners_read on portion_learners for select to public
  using (user_id = app_private.current_user_id() or app_private.teaches_portion(portion_id));
create policy categories_read on correction_categories for select to public
  using (app_private.current_user_id() is not null);
create policy categories_write on correction_categories for all to public
  using (app_private.has_permission('teaching.review') or app_private.has_permission('content.upload'))
  with check (app_private.has_permission('teaching.review') or app_private.has_permission('content.upload'));
grant insert, update, delete on correction_categories to authenticated, sidra_app;
-- Staff browse the library; learners see only corrections sent to them.
create policy corrections_read on corrections for select to public
  using (app_private.has_permission('teaching.review')
         or app_private.has_permission('content.upload')
         or created_by = app_private.current_user_id()
         or exists (select 1 from submission_reviews r join submissions s on s.id = r.submission_id
                    where r.correction_id = corrections.id
                      and s.user_id = app_private.current_user_id()));
create policy corrections_update on corrections for update to public
  using (created_by = app_private.current_user_id() or app_private.has_permission('content.upload'))
  with check (created_by = app_private.current_user_id() or app_private.has_permission('content.upload'));
grant update (title, explanation, category_id, language, tags, archived_at, updated_at)
  on corrections to authenticated, sidra_app;
create policy reviews_read on submission_reviews for select to public
  using (exists (select 1 from submissions s where s.id = submission_id
                 and (s.user_id = app_private.current_user_id()
                      or app_private.teaches(s.course_id, s.lesson_id)
                      or (s.portion_id is not null and app_private.teaches_portion(s.portion_id)))));
-- Private teacher notes: never visible to learners.
create policy notes_read on teacher_notes for select to public
  using (app_private.has_permission('teaching.review')
         and (author_id = app_private.current_user_id()
              or app_private.teaches(course_id)
              or app_private.has_permission('learners.view')));
create policy notifications_read on notifications for select to public
  using (user_id = app_private.current_user_id());

-- Submissions of a portion are also readable by its teachers.
drop policy submissions_read on submissions;
create policy submissions_read on submissions for select to public
  using (user_id = app_private.current_user_id()
         or app_private.teaches(course_id, lesson_id)
         or (portion_id is not null and app_private.teaches_portion(portion_id)));

-- Resources: also readable through portions (participants and teachers).
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
      or exists (select 1 from portion_resources pr join teaching_portions tp on tp.id = pr.portion_id
                 where pr.resource_id = r.id
                   and (app_private.teaches_portion(tp.id)
                        or (tp.status <> 'draft' and app_private.in_portion(tp.id))))
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
                     or app_private.teaches(s.course_id, s.lesson_id)
                     or (s.portion_id is not null and app_private.teaches_portion(s.portion_id))))
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
      -- correction recordings: the library (staff) and the learners they were sent to
      or exists (select 1 from corrections c where c.media_asset_id = p_asset_id
                 and (app_private.has_permission('teaching.review')
                      or exists (select 1 from submission_reviews r join submissions s on s.id = r.submission_id
                                 where r.correction_id = c.id
                                   and s.user_id = app_private.current_user_id())))
      or exists (select 1 from submission_reviews r join submissions s on s.id = r.submission_id
                 where r.correction_asset_id = p_asset_id
                   and (s.user_id = app_private.current_user_id()
                        or app_private.teaches(s.course_id, s.lesson_id)
                        or (s.portion_id is not null and app_private.teaches_portion(s.portion_id))))
  end
$$;

-- ------------------------------------------------------ notifications --

create or replace function app_private.notify(
  p_user uuid, p_kind text, p_title text, p_body text, p_data jsonb)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  insert into notifications (user_id, kind, title, body, data)
  values (p_user, p_kind, p_title, p_body, coalesce(p_data, '{}'))
$$;

-- Teachers of a portion: its group's teachers, else the course teachers.
create or replace function app_private.portion_teachers(p_portion_id uuid)
returns setof uuid
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select distinct u from (
    select t.user_id as u from teaching_portions p
    join teaching_group_teachers t on t.group_id = p.group_id
    where p.id = p_portion_id
    union
    select s.user_id from teaching_portions p
    join course_staff s on s.course_id = p.course_id
    where p.id = p_portion_id
      and not exists (select 1 from teaching_group_teachers t
                      join teaching_portions p2 on p2.group_id = t.group_id
                      where p2.id = p_portion_id)) x
$$;

create or replace function public.my_notifications(p_limit int default 50)
returns setof notifications
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select * from notifications where user_id = app_private.current_user_id()
  order by created_at desc limit least(greatest(coalesce(p_limit, 50), 1), 200)
$$;

create or replace function public.mark_notifications_read(p_ids uuid[] default null)
returns void
language sql security definer
set search_path = public, app_private, pg_temp
as $$
  update notifications set read_at = now()
  where user_id = app_private.current_user_id() and read_at is null
    and (p_ids is null or id = any (p_ids))
$$;

-- ------------------------------------------------------------ groups --

create or replace function public.save_teaching_group(
  p_course_id uuid, p_name text, p_learner_ids uuid[] default '{}',
  p_group_id uuid default null, p_description text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v teaching_groups%rowtype; v_bad int;
begin
  if not app_private.teaches(p_course_id) then
    raise exception 'only the course''s teachers can make groups' using errcode = 'PT403';
  end if;
  select count(*) into v_bad from unnest(coalesce(p_learner_ids, '{}')) u
  where not exists (select 1 from course_enrolments e where e.course_id = p_course_id
                    and e.user_id = u and e.status in ('active', 'pending'));
  if v_bad > 0 then
    raise exception '% of the chosen learners are not enrolled in this course', v_bad
      using errcode = 'PT422';
  end if;
  if p_group_id is null then
    insert into teaching_groups (course_id, name, description, created_by)
    values (p_course_id, trim(p_name), p_description, app_private.current_user_id())
    returning * into v;
    insert into teaching_group_teachers (group_id, user_id)
    values (v.id, app_private.current_user_id()) on conflict do nothing;
  else
    update teaching_groups set name = trim(p_name), description = p_description
    where id = p_group_id and course_id = p_course_id returning * into v;
    if not found then raise exception 'group not found' using errcode = 'PT404'; end if;
  end if;
  delete from teaching_group_members where group_id = v.id
    and user_id <> all (coalesce(p_learner_ids, '{}'));
  insert into teaching_group_members (group_id, user_id)
  select v.id, u from unnest(coalesce(p_learner_ids, '{}')) u on conflict do nothing;
  return to_jsonb(v);
end;
$$;

-- Groups the caller teaches, with counts for the teacher's home screen.
create or replace function public.my_teaching_groups()
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select jsonb_build_object(
    'id', g.id, 'name', g.name, 'course_id', g.course_id, 'course_title', c.title,
    'learners', (select count(*) from teaching_group_members m where m.group_id = g.id),
    'waiting', (select count(*) from portion_learners pl join teaching_portions p on p.id = pl.portion_id
                where p.group_id = g.id and pl.status = 'submitted'),
    'latest_portion', (select jsonb_build_object('id', p.id, 'title', p.title, 'sequence', p.sequence,
                                                 'status', p.status, 'assigned_at', p.assigned_at)
                       from teaching_portions p where p.group_id = g.id
                       order by p.sequence desc, p.created_at desc limit 1))
  from teaching_groups g join courses c on c.id = g.course_id
  where g.archived_at is null and app_private.teaches_group(g.id)
  order by c.title, g.name
$$;

-- ---------------------------------------------------------- portions --

create or replace function public.save_portion(
  p_course_id uuid, p_title text, p_group_id uuid default null,
  p_lesson_id uuid default null, p_instructions text default null,
  p_instruction_language text default null,
  p_submission_types text[] default '{audio}', p_due_at timestamptz default null,
  p_portion_id uuid default null, p_sequence int default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v teaching_portions%rowtype; v_seq int;
begin
  if not (app_private.teaches(p_course_id, p_lesson_id)
          or (p_group_id is not null and app_private.teaches_group(p_group_id))) then
    raise exception 'only the course''s teachers can create portions' using errcode = 'PT403';
  end if;
  if p_group_id is not null and not exists (
       select 1 from teaching_groups where id = p_group_id and course_id = p_course_id) then
    raise exception 'that group belongs to another course' using errcode = 'PT422';
  end if;
  if p_portion_id is null then
    select coalesce(max(sequence), 0) + 1 into v_seq from teaching_portions
    where course_id = p_course_id and group_id is not distinct from p_group_id;
    insert into teaching_portions (course_id, group_id, lesson_id, title, sequence, instructions,
                                   instruction_language, submission_types, due_at, created_by)
    values (p_course_id, p_group_id, p_lesson_id, trim(p_title), coalesce(p_sequence, v_seq),
            p_instructions, p_instruction_language, coalesce(p_submission_types, '{audio}'),
            p_due_at, app_private.current_user_id())
    returning * into v;
  else
    update teaching_portions set title = trim(p_title), lesson_id = p_lesson_id,
      instructions = p_instructions, instruction_language = p_instruction_language,
      submission_types = coalesce(p_submission_types, submission_types), due_at = p_due_at,
      sequence = coalesce(p_sequence, sequence), updated_at = now()
    where id = p_portion_id and course_id = p_course_id returning * into v;
    if not found then raise exception 'portion not found' using errcode = 'PT404'; end if;
  end if;
  return to_jsonb(v);
end;
$$;

-- Link a shared resource (page image, instruction, model…) to a portion.
create or replace function public.set_portion_resource(
  p_portion_id uuid, p_resource_id uuid, p_role text, p_remove boolean default false)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.teaches_portion(p_portion_id) then
    raise exception 'portion not found' using errcode = 'PT404';
  end if;
  if p_remove then
    delete from portion_resources
    where portion_id = p_portion_id and resource_id = p_resource_id and role = p_role;
  else
    if not app_private.can_read_resource(p_resource_id) then
      raise exception 'resource not found' using errcode = 'PT404';
    end if;
    insert into portion_resources (portion_id, resource_id, role, position)
    values (p_portion_id, p_resource_id, p_role,
            (select count(*) from portion_resources where portion_id = p_portion_id))
    on conflict do nothing;
  end if;
end;
$$;

-- Hand a portion to the whole group (p_user_ids null) or to chosen learners.
create or replace function public.assign_portion(p_portion_id uuid, p_user_ids uuid[] default null)
returns int
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v teaching_portions%rowtype; v_count int; v_bad int;
begin
  select * into v from teaching_portions where id = p_portion_id;
  if not found or not app_private.teaches_portion(p_portion_id) then
    raise exception 'portion not found' using errcode = 'PT404';
  end if;
  if p_user_ids is null and v.group_id is null then
    raise exception 'choose learners or a group' using errcode = 'PT422';
  end if;
  if p_user_ids is not null then
    select count(*) into v_bad from unnest(p_user_ids) u
    where not exists (select 1 from course_enrolments e where e.course_id = v.course_id
                      and e.user_id = u and e.status = 'active');
    if v_bad > 0 then
      raise exception '% of the chosen learners are not actively enrolled', v_bad
        using errcode = 'PT422';
    end if;
  end if;

  with targets as (
    select coalesce(u, m.user_id) as user_id
    from (select unnest(p_user_ids) as u) x
    full join (select user_id from teaching_group_members where group_id = v.group_id
               and p_user_ids is null) m on false
  ), ins as (
    insert into portion_learners (portion_id, user_id)
    select v.id, t.user_id from targets t
    where t.user_id is not null
      and exists (select 1 from course_enrolments e where e.course_id = v.course_id
                  and e.user_id = t.user_id and e.status = 'active')
    on conflict (portion_id, user_id) do nothing
    returning user_id
  )
  select count(*) into v_count from (
    select app_private.notify(i.user_id, 'portion_assigned', v.title,
                              coalesce(left(v.instructions, 140), 'New learning for today'),
                              jsonb_build_object('portion_id', v.id))
    from ins i) n;

  update teaching_portions set status = 'assigned', assigned_at = coalesce(assigned_at, now()),
    updated_at = now()
  where id = v.id;
  return v_count;
end;
$$;

-- The next portion in a sequence: same group, course and instructions;
-- the model and instruction recordings carry over, the page does not.
-- "Page 11" becomes "Page 12".
create or replace function public.next_portion(p_previous_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v teaching_portions%rowtype; v_new teaching_portions%rowtype; v_title text; m text[];
begin
  select * into v from teaching_portions where id = p_previous_id;
  if not found or not app_private.teaches_portion(p_previous_id) then
    raise exception 'portion not found' using errcode = 'PT404';
  end if;
  m := regexp_match(v.title, '^(.*?)(\d+)(\D*)$');
  v_title := case when m is null then v.title || ' (next)'
                  else m[1] || (m[2]::int + 1) || m[3] end;
  insert into teaching_portions (course_id, group_id, lesson_id, title, sequence, instructions,
                                 instruction_language, submission_types, previous_id, created_by)
  values (v.course_id, v.group_id, app_private.next_lesson(v.lesson_id), v_title, v.sequence + 1,
          v.instructions, v.instruction_language, v.submission_types, v.id,
          app_private.current_user_id())
  returning * into v_new;
  insert into portion_resources (portion_id, resource_id, role, position)
  select v_new.id, resource_id, role, position from portion_resources
  where portion_id = v.id and role in ('instruction', 'model');
  return to_jsonb(v_new);
end;
$$;

-- --------------------------------------------------------- learners --

create or replace function app_private.portion_json(p teaching_portions, p_user uuid)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select jsonb_build_object(
    'id', p.id, 'title', p.title, 'instructions', p.instructions,
    'instruction_language', p.instruction_language,
    'submission_types', p.submission_types, 'due_at', p.due_at, 'assigned_at', p.assigned_at,
    'course_id', p.course_id, 'course_title', c.title, 'course_language', c.language,
    'group_name', (select name from teaching_groups g where g.id = p.group_id),
    'lesson_id', p.lesson_id,
    'resources', (select coalesce(jsonb_agg(jsonb_build_object(
                    'id', r.id, 'role', pr.role, 'kind', r.kind, 'title', r.title,
                    'media_asset_id', r.media_asset_id, 'url', r.url, 'language', r.language,
                    'mime_type', r.mime_type, 'file_name', r.file_name)
                    order by pr.position), '[]')
                  from portion_resources pr join resources r on r.id = pr.resource_id
                  where pr.portion_id = p.id),
    'participation', (select to_jsonb(pl) from portion_learners pl
                      where pl.portion_id = p.id and pl.user_id = p_user),
    'attempts', (select coalesce(jsonb_agg(jsonb_build_object(
                   'id', s.id, 'attempt', s.attempt, 'status', s.status,
                   'submitted_at', s.submitted_at, 'text', s.text_answer,
                   'files', (select coalesce(jsonb_agg(jsonb_build_object(
                               'media_asset_id', f.media_asset_id, 'file_name', f.file_name,
                               'mime_type', f.mime_type,
                               'kind', (select kind from media_assets where id = f.media_asset_id))
                               order by f.position), '[]')
                             from submission_files f where f.submission_id = s.id),
                   'reviews', (select coalesce(jsonb_agg(jsonb_build_object(
                                 'id', rv.id, 'result', rv.result, 'feedback', rv.feedback,
                                 'score', rv.score, 'created_at', rv.created_at,
                                 'reviewer', (select display_name from users where id = rv.reviewer_id),
                                 'correction_asset_id', rv.correction_asset_id,
                                 'correction', (select jsonb_build_object(
                                     'id', co.id, 'title', co.title, 'explanation', co.explanation,
                                     'media_asset_id', co.media_asset_id)
                                   from corrections co where co.id = rv.correction_id))
                                 order by rv.created_at desc), '[]')
                               from submission_reviews rv where rv.submission_id = s.id))
                   order by s.attempt desc), '[]')
                 from submissions s where s.portion_id = p.id and s.user_id = p_user))
  from courses c where c.id = p.course_id
$$;

-- "What do I do now?": the learner's current portions, newest first.
create or replace function public.learner_today()
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.portion_json(p, app_private.current_user_id())
  from portion_learners pl join teaching_portions p on p.id = pl.portion_id
  where pl.user_id = app_private.current_user_id()
    and p.status <> 'draft'
    and (pl.status <> 'completed' or pl.completed_at > now() - interval '7 days')
  order by (pl.status = 'correction_required') desc,
           (pl.status in ('assigned', 'opened')) desc,
           p.assigned_at desc nulls last
  limit 30
$$;

create or replace function public.open_portion(p_portion_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v teaching_portions%rowtype;
begin
  select * into v from teaching_portions where id = p_portion_id and status <> 'draft';
  if not found or not app_private.in_portion(p_portion_id) then
    raise exception 'portion not found' using errcode = 'PT404';
  end if;
  update portion_learners set opened_at = coalesce(opened_at, now()),
    status = case when status = 'assigned' then 'opened'::participation_status else status end
  where portion_id = p_portion_id and user_id = app_private.current_user_id();
  return app_private.portion_json(v, app_private.current_user_id());
end;
$$;

-- Learner hands in a recording / photo / document for a portion.
-- Idempotent on p_submission_id (queued offline uploads).
create or replace function public.submit_portion(
  p_submission_id uuid, p_portion_id uuid, p_text text default null, p_files jsonb default '[]')
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v teaching_portions%rowtype;
  v_pl portion_learners%rowtype;
  v_sub submissions%rowtype;
  v_file jsonb; v_pos int := 0; v_t uuid;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  select * into v_sub from submissions where id = p_submission_id;
  if found then
    if v_sub.user_id <> v_me then raise exception 'not yours' using errcode = 'PT403'; end if;
    return to_jsonb(v_sub);
  end if;
  select * into v from teaching_portions where id = p_portion_id and status = 'assigned';
  select * into v_pl from portion_learners where portion_id = p_portion_id and user_id = v_me
  for update;
  if v.id is null or v_pl.id is null then
    raise exception 'portion not found' using errcode = 'PT404';
  end if;
  if v_pl.status in ('submitted', 'under_review') then
    raise exception 'already sent; wait for your teacher' using errcode = 'PT409';
  end if;
  if v_pl.status = 'completed' then
    raise exception 'this portion is complete' using errcode = 'PT409';
  end if;
  if jsonb_array_length(coalesce(p_files, '[]')) = 0 and coalesce(trim(p_text), '') = '' then
    raise exception 'add a recording, photo or file' using errcode = 'PT422';
  end if;
  if exists (select 1 from jsonb_array_elements(coalesce(p_files, '[]')) f
             where not exists (select 1 from media_assets m
                               where m.id = (f->>'media_asset_id')::uuid and m.uploaded_by = v_me)) then
    raise exception 'files must be your own uploads' using errcode = 'PT403';
  end if;

  insert into submissions (id, portion_id, user_id, course_id, lesson_id, attempt, text_answer)
  values (p_submission_id, v.id, v_me, v.course_id, v.lesson_id, v_pl.attempts + 1,
          nullif(trim(p_text), ''))
  returning * into v_sub;
  for v_file in select * from jsonb_array_elements(coalesce(p_files, '[]')) loop
    insert into submission_files (submission_id, media_asset_id, file_name, mime_type, bytes, position)
    values (v_sub.id, (v_file->>'media_asset_id')::uuid, v_file->>'file_name',
            v_file->>'mime_type', (v_file->>'bytes')::bigint, v_pos);
    v_pos := v_pos + 1;
  end loop;
  update portion_learners set status = 'submitted', attempts = attempts + 1,
    last_submitted_at = now(), opened_at = coalesce(opened_at, now())
  where id = v_pl.id;

  for v_t in select * from app_private.portion_teachers(v.id) loop
    perform app_private.notify(v_t,
      case when v_pl.attempts > 0 then 'resubmission' else 'submission' end,
      (select display_name from users where id = v_me) || ' · ' || v.title,
      case when v_pl.attempts > 0 then 'Tried again (attempt ' || (v_pl.attempts + 1) || ')'
           else 'Sent their work' end,
      jsonb_build_object('portion_id', v.id, 'submission_id', v_sub.id));
  end loop;
  return to_jsonb(v_sub);
end;
$$;

-- ---------------------------------------------------------- teachers --

-- One portion, every learner, their status and latest attempt: the
-- teacher's review board.
create or replace function public.portion_board(p_portion_id uuid)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case when not app_private.teaches_portion(p_portion_id) then null else
    jsonb_build_object(
      'portion', (select to_jsonb(p) || jsonb_build_object(
                    'course_title', (select title from courses where id = p.course_id),
                    'group_name', (select name from teaching_groups where id = p.group_id),
                    'resources', (select coalesce(jsonb_agg(jsonb_build_object(
                        'id', r.id, 'role', pr.role, 'kind', r.kind, 'title', r.title,
                        'media_asset_id', r.media_asset_id, 'url', r.url) order by pr.position), '[]')
                      from portion_resources pr join resources r on r.id = pr.resource_id
                      where pr.portion_id = p.id))
                  from teaching_portions p where p.id = p_portion_id),
      'learners', (select coalesce(jsonb_agg(x order by x->>'sort', x->>'name'), '[]') from (
        select jsonb_build_object(
          'user_id', pl.user_id, 'name', u.display_name, 'status', pl.status,
          'last_result', pl.last_result, 'attempts', pl.attempts,
          'last_submitted_at', pl.last_submitted_at,
          'sort', case pl.status when 'submitted' then '0' when 'under_review' then '1'
                                 when 'correction_required' then '2' when 'opened' then '3'
                                 when 'assigned' then '4' else '5' end,
          'latest', (select jsonb_build_object(
                        'id', s.id, 'attempt', s.attempt, 'submitted_at', s.submitted_at,
                        'text', s.text_answer,
                        'files', (select coalesce(jsonb_agg(jsonb_build_object(
                                    'media_asset_id', f.media_asset_id, 'file_name', f.file_name,
                                    'mime_type', f.mime_type,
                                    'kind', (select kind from media_assets where id = f.media_asset_id))
                                    order by f.position), '[]')
                                  from submission_files f where f.submission_id = s.id))
                     from submissions s where s.portion_id = pl.portion_id and s.user_id = pl.user_id
                     order by s.attempt desc limit 1)) as x
        from portion_learners pl join users u on u.id = pl.user_id
        where pl.portion_id = p_portion_id) t))
  end
$$;

-- The teacher's verdict on one attempt. Optionally a library correction,
-- a new recording, or both — and the new recording can be saved to the
-- library in the same step (p_save_as: {title, category_id, explanation,
-- tags, language}).
create or replace function public.review_attempt(
  p_submission_id uuid, p_result review_result,
  p_feedback text default null, p_correction_id uuid default null,
  p_correction_asset_id uuid default null, p_score numeric default null,
  p_save_as jsonb default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v submissions%rowtype;
  v_p teaching_portions%rowtype;
  v_correction uuid := p_correction_id;
  v_review submission_reviews%rowtype;
  v_ok boolean := p_result in ('excellent', 'correct', 'minor_correction');
begin
  select * into v from submissions where id = p_submission_id for update;
  if not found or not (app_private.teaches(v.course_id, v.lesson_id)
                       or (v.portion_id is not null and app_private.teaches_portion(v.portion_id))) then
    raise exception 'submission not found' using errcode = 'PT404';
  end if;
  if p_correction_asset_id is not null and not exists (
       select 1 from media_assets where id = p_correction_asset_id
         and uploaded_by = app_private.current_user_id()) then
    raise exception 'record the correction yourself' using errcode = 'PT403';
  end if;
  if v_correction is not null and not exists (
       select 1 from corrections where id = v_correction and archived_at is null) then
    raise exception 'correction not found' using errcode = 'PT404';
  end if;

  if p_save_as is not null and p_correction_asset_id is not null then
    insert into corrections (title, explanation, category_id, media_asset_id, language, tags,
                             course_id, lesson_id, created_by)
    values (coalesce(nullif(trim(p_save_as->>'title'), ''), 'Correction'),
            nullif(trim(p_save_as->>'explanation'), ''),
            nullif(p_save_as->>'category_id', '')::uuid, p_correction_asset_id,
            nullif(p_save_as->>'language', ''),
            coalesce(array(select jsonb_array_elements_text(p_save_as->'tags')), '{}'),
            v.course_id, v.lesson_id, app_private.current_user_id())
    returning id into v_correction;
  end if;

  insert into submission_reviews (submission_id, reviewer_id, result, feedback, score,
                                  correction_id, correction_asset_id)
  values (v.id, app_private.current_user_id(), p_result, nullif(trim(p_feedback), ''), p_score,
          v_correction,
          case when p_save_as is not null then null else p_correction_asset_id end)
  returning * into v_review;
  if v_correction is not null then
    update corrections set use_count = use_count + 1 where id = v_correction;
  end if;

  update submissions set
    status = case when v_ok then 'reviewed'::submission_status
                  when p_result = 'needs_explanation' then 'returned'::submission_status
                  else 'resubmission_requested'::submission_status end,
    feedback = coalesce(nullif(trim(p_feedback), ''), feedback),
    score = coalesce(p_score, score),
    reviewed_by = app_private.current_user_id(), reviewed_at = now(), updated_at = now()
  where id = v.id;

  if v.portion_id is not null then
    select * into v_p from teaching_portions where id = v.portion_id;
    update portion_learners set last_result = p_result,
      status = case when v_ok then 'completed'::participation_status
                    else 'correction_required'::participation_status end,
      completed_at = case when v_ok then now() else null end
    where portion_id = v.portion_id and user_id = v.user_id;
  end if;

  perform app_private.notify(v.user_id,
    case when v_ok then 'reviewed' else 'correction' end,
    coalesce(v_p.title, 'Your work'),
    case p_result
      when 'excellent' then 'Excellent! Your teacher approved it.'
      when 'correct' then 'Correct. Well done.'
      when 'minor_correction' then 'Correct, with a small note from your teacher.'
      when 'correction_required' then 'Your teacher sent a correction. Listen and try again.'
      else 'Your teacher will explain this with you.' end,
    jsonb_build_object('portion_id', v.portion_id, 'submission_id', v.id));
  return to_jsonb(v_review);
end;
$$;

create or replace function public.mark_under_review(p_submission_id uuid)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v submissions%rowtype;
begin
  select * into v from submissions where id = p_submission_id;
  if not found or not (app_private.teaches(v.course_id, v.lesson_id)
                       or (v.portion_id is not null and app_private.teaches_portion(v.portion_id))) then
    raise exception 'submission not found' using errcode = 'PT404';
  end if;
  update submissions set status = 'under_review' where id = v.id and status in ('submitted', 'received');
  update portion_learners set status = 'under_review'
  where portion_id = v.portion_id and user_id = v.user_id and status = 'submitted';
end;
$$;

-- "Who needs me?": everything waiting on the caller, most urgent first.
create or replace function public.teacher_attention(p_stale_days int default 2)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  with mine as (
    select pl.*, p.title, p.course_id, p.group_id, u.display_name as learner
    from portion_learners pl
    join teaching_portions p on p.id = pl.portion_id
    join users u on u.id = pl.user_id
    where p.status = 'assigned' and app_private.teaches_portion(p.id)
  ), row_json as (
    select m.*, jsonb_build_object('portion_id', m.portion_id, 'title', m.title,
      'user_id', m.user_id, 'learner', m.learner, 'status', m.status, 'attempts', m.attempts,
      'last_submitted_at', m.last_submitted_at, 'assigned_at', m.assigned_at,
      'group', (select name from teaching_groups where id = m.group_id)) as j
    from mine m
  )
  select jsonb_build_object(
    'new_submissions', (select coalesce(jsonb_agg(j order by last_submitted_at), '[]') from row_json
                        where status in ('submitted', 'under_review') and attempts = 1),
    'resubmissions', (select coalesce(jsonb_agg(j order by last_submitted_at), '[]') from row_json
                      where status in ('submitted', 'under_review') and attempts > 1),
    'correction_required', (select coalesce(jsonb_agg(j order by learner), '[]') from row_json
                            where status = 'correction_required'),
    'not_submitted', (select coalesce(jsonb_agg(j order by assigned_at), '[]') from row_json
                      where status in ('assigned', 'opened')
                        and assigned_at < now() - make_interval(days => p_stale_days)),
    'falling_behind', (
      select coalesce(jsonb_agg(jsonb_build_object('user_id', user_id, 'learner', learner,
                                                   'open_portions', n)), '[]')
      from (select user_id, learner, count(*) n from row_json
            where status in ('assigned', 'opened', 'correction_required')
            group by user_id, learner having count(*) >= 3) t))
$$;

-- -------------------------------------------------------- corrections --

create or replace function public.search_corrections(
  p_query text default null, p_category_id uuid default null, p_limit int default 30)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select jsonb_build_object(
    'id', c.id, 'title', c.title, 'explanation', c.explanation,
    'category_id', c.category_id,
    'category', (select name from correction_categories where id = c.category_id),
    'parent_category', (select p.name from correction_categories k
                        join correction_categories p on p.id = k.parent_id
                        where k.id = c.category_id),
    'media_asset_id', c.media_asset_id, 'language', c.language, 'tags', c.tags,
    'use_count', c.use_count, 'created_at', c.created_at,
    'created_by', (select display_name from users where id = c.created_by))
  from corrections c
  where (app_private.has_permission('teaching.review') or app_private.has_permission('content.upload'))
    and c.archived_at is null
    and (p_category_id is null or c.category_id = p_category_id
         or c.category_id in (select id from correction_categories where parent_id = p_category_id))
    and (nullif(trim(p_query), '') is null
         or c.title ilike '%' || trim(p_query) || '%'
         or c.explanation ilike '%' || trim(p_query) || '%'
         or trim(p_query) = any (c.tags)
         or exists (select 1 from correction_categories k where k.id = c.category_id
                    and k.name ilike '%' || trim(p_query) || '%'))
  order by c.use_count desc, c.created_at desc
  limit least(greatest(coalesce(p_limit, 30), 1), 100)
$$;

create or replace function public.save_correction(
  p_title text, p_media_asset_id uuid default null, p_explanation text default null,
  p_category_id uuid default null, p_tags text[] default '{}', p_language text default null,
  p_course_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v corrections%rowtype;
begin
  if not (app_private.has_permission('teaching.review') or app_private.has_permission('content.upload')) then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  if p_media_asset_id is not null and not exists (
       select 1 from media_assets where id = p_media_asset_id
         and (uploaded_by = app_private.current_user_id() or app_private.has_permission('content.upload'))) then
    raise exception 'recording not found' using errcode = 'PT404';
  end if;
  insert into corrections (title, explanation, category_id, media_asset_id, language, tags,
                           course_id, created_by)
  values (trim(p_title), nullif(trim(p_explanation), ''), p_category_id, p_media_asset_id,
          p_language, coalesce(p_tags, '{}'), p_course_id, app_private.current_user_id())
  returning * into v;
  return to_jsonb(v);
end;
$$;

-- --------------------------------------------------------- teacher notes --

create or replace function public.add_teacher_note(
  p_learner_id uuid, p_body text, p_course_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v teacher_notes%rowtype;
begin
  if not (app_private.has_permission('teaching.review')
          and (p_course_id is null or app_private.teaches(p_course_id))) then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  insert into teacher_notes (learner_id, course_id, author_id, body)
  values (p_learner_id, p_course_id, app_private.current_user_id(), trim(p_body))
  returning * into v;
  return to_jsonb(v);
end;
$$;

create or replace function public.learner_notes(p_learner_id uuid)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select to_jsonb(n) || jsonb_build_object('author', (select display_name from users where id = n.author_id))
  from teacher_notes n
  where n.learner_id = p_learner_id
    and app_private.has_permission('teaching.review')
    and (n.author_id = app_private.current_user_id() or app_private.teaches(n.course_id)
         or app_private.has_permission('learners.view'))
  order by n.created_at desc limit 50
$$;

-- ---------------------------------------------------------- analytics --

create or replace function public.teaching_analytics(p_days int default 30)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  with period as (select now() - make_interval(days => greatest(coalesce(p_days, 30), 1)) as since),
  scope as (
    select s.* from submissions s, period
    where s.portion_id is not null and s.submitted_at >= period.since
      and (app_private.has_permission('reports.view') or app_private.has_permission('courses.view')
           or app_private.teaches_portion(s.portion_id))
  ),
  first_reviews as (
    select distinct on (r.submission_id) r.submission_id, r.created_at, r.reviewer_id, r.result
    from submission_reviews r join scope s on s.id = r.submission_id
    order by r.submission_id, r.created_at
  )
  select jsonb_build_object(
    'days', p_days,
    'submissions', (select count(*) from scope),
    'reviewed', (select count(*) from first_reviews),
    'waiting', (select count(*) from scope s where not exists
                (select 1 from submission_reviews r where r.submission_id = s.id)),
    'avg_review_hours', (select round(avg(extract(epoch from fr.created_at - s.submitted_at) / 3600)::numeric, 1)
                         from first_reviews fr join scope s on s.id = fr.submission_id),
    'first_try_correct_percent', (
      select round(100.0 * count(*) filter (where fr.result in ('excellent', 'correct', 'minor_correction'))
                   / nullif(count(*), 0))
      from first_reviews fr join scope s on s.id = fr.submission_id where s.attempt = 1),
    'by_teacher', (select coalesce(jsonb_agg(x order by (x->>'reviews')::int desc), '[]') from (
      select jsonb_build_object('teacher', u.display_name, 'reviews', count(*)) x
      from submission_reviews r join scope s on s.id = r.submission_id
      join users u on u.id = r.reviewer_id group by u.display_name) t),
    'top_corrections', (select coalesce(jsonb_agg(x), '[]') from (
      select jsonb_build_object('id', c.id, 'title', c.title, 'uses', count(*),
        'category', (select name from correction_categories where id = c.category_id)) x
      from submission_reviews r join scope s on s.id = r.submission_id
      join corrections c on c.id = r.correction_id
      group by c.id, c.title, c.category_id order by count(*) desc limit 10) t),
    'top_categories', (select coalesce(jsonb_agg(x), '[]') from (
      select jsonb_build_object('category', k.name, 'uses', count(*)) x
      from submission_reviews r join scope s on s.id = r.submission_id
      join corrections c on c.id = r.correction_id
      join correction_categories k on k.id = c.category_id
      group by k.name order by count(*) desc limit 10) t),
    'repeat_resubmitters', (select coalesce(jsonb_agg(x), '[]') from (
      select jsonb_build_object('learner', u.display_name, 'portions', count(*)) x
      from portion_learners pl join users u on u.id = pl.user_id
      where pl.attempts >= 3 and app_private.teaches_portion(pl.portion_id)
      group by u.display_name order by count(*) desc limit 10) t),
    'incomplete', (select count(*) from portion_learners pl join teaching_portions p on p.id = pl.portion_id, period
                   where pl.status <> 'completed' and p.assigned_at < now() - interval '3 days'
                     and p.assigned_at >= period.since
                     and (app_private.has_permission('reports.view') or app_private.teaches_portion(p.id))))
$$;

-- Teacher / institution audio library: instructions, models, corrections.
create or replace function public.audio_library(p_query text default null, p_mine boolean default true)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select * from (
    select jsonb_build_object('type', 'resource', 'id', r.id, 'title', r.title,
      'role', (select pr.role from portion_resources pr where pr.resource_id = r.id limit 1),
      'media_asset_id', r.media_asset_id, 'language', r.language, 'tags', r.tags,
      'created_at', r.created_at,
      'uses', (select count(*) from portion_resources pr where pr.resource_id = r.id)) j
    from resources r
    where r.kind = 'audio' and r.archived_at is null
      and (not p_mine or r.uploaded_by = app_private.current_user_id())
      and (app_private.has_permission('teaching.review') or app_private.has_permission('content.upload'))
      and (nullif(trim(p_query), '') is null or r.title ilike '%' || trim(p_query) || '%'
           or trim(p_query) = any (r.tags))
    union all
    select jsonb_build_object('type', 'correction', 'id', c.id, 'title', c.title, 'role', 'correction',
      'media_asset_id', c.media_asset_id, 'language', c.language, 'tags', c.tags,
      'created_at', c.created_at, 'uses', c.use_count)
    from corrections c
    where c.archived_at is null and c.media_asset_id is not null
      and (not p_mine or c.created_by = app_private.current_user_id())
      and (app_private.has_permission('teaching.review') or app_private.has_permission('content.upload'))
      and (nullif(trim(p_query), '') is null or c.title ilike '%' || trim(p_query) || '%'
           or trim(p_query) = any (c.tags))
  ) x
  order by (j->>'created_at') desc
  limit 200
$$;

-- Institutional content library for administrators.
create or replace function public.content_library(
  p_kind text default null, p_query text default null, p_include_archived boolean default false)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select to_jsonb(r) || jsonb_build_object(
    'uploader', (select display_name from users where id = r.uploaded_by),
    'used_in_lessons', (select count(*) from resource_links k where k.resource_id = r.id),
    'used_in_portions', (select count(*) from portion_resources pr where pr.resource_id = r.id),
    'roles', (select coalesce(jsonb_agg(distinct pr.role), '[]') from portion_resources pr
              where pr.resource_id = r.id))
  from resources r
  where (app_private.has_permission('content.upload') or app_private.has_permission('courses.view'))
    and (p_include_archived or r.archived_at is null)
    and (p_kind is null or r.kind = p_kind)
    and (nullif(trim(p_query), '') is null or r.title ilike '%' || trim(p_query) || '%'
         or r.file_name ilike '%' || trim(p_query) || '%' or trim(p_query) = any (r.tags))
  order by r.created_at desc
  limit 300
$$;

-- A better scan / recording replaces a resource: a NEW version row. Course
-- content moves to it; portions already assigned keep the version their
-- learners saw.
create or replace function public.replace_resource(p_resource_id uuid, p_media_asset_id uuid,
  p_file_name text default null, p_mime_type text default null, p_bytes bigint default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v resources%rowtype; v_new resources%rowtype;
begin
  select * into v from resources where id = p_resource_id;
  if not found or not (v.uploaded_by = app_private.current_user_id()
                       or app_private.has_permission('content.upload')) then
    raise exception 'resource not found' using errcode = 'PT404';
  end if;
  insert into resources (kind, title, description, language, provider, media_asset_id, file_name,
                         mime_type, extension, bytes, is_public, version, replaces_id, tags,
                         uploaded_by)
  values (v.kind, v.title, v.description, v.language, 'cloudinary', p_media_asset_id,
          coalesce(p_file_name, v.file_name), coalesce(p_mime_type, v.mime_type),
          v.extension, p_bytes, v.is_public, v.version + 1, v.id, v.tags,
          app_private.current_user_id())
  returning * into v_new;
  update resource_links set resource_id = v_new.id where resource_id = v.id;
  update portion_resources pr set resource_id = v_new.id
  from teaching_portions p
  where pr.portion_id = p.id and pr.resource_id = v.id and p.status = 'draft';
  update resources set archived_at = now() where id = v.id;
  return to_jsonb(v_new);
end;
$$;

-- --------------------------------------------------------- grants --

do $$
declare r record;
begin
  for r in select p.oid::regprocedure as fn
           from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.proname in (
             'my_notifications', 'mark_notifications_read', 'save_teaching_group',
             'my_teaching_groups', 'save_portion', 'set_portion_resource', 'assign_portion',
             'next_portion', 'learner_today', 'open_portion', 'submit_portion', 'portion_board',
             'review_attempt', 'mark_under_review', 'teacher_attention', 'search_corrections',
             'save_correction', 'add_teacher_note', 'learner_notes', 'teaching_analytics',
             'audio_library', 'content_library', 'replace_resource') loop
    execute format('revoke all on function %s from public', r.fn);
    execute format('grant execute on function %s to authenticated, sidra_app', r.fn);
  end loop;
end $$;
revoke all on function app_private.notify(uuid, text, text, text, jsonb),
  app_private.portion_teachers(uuid), app_private.portion_json(teaching_portions, uuid)
  from public;
grant execute on function app_private.teaches_portion(uuid), app_private.teaches_group(uuid),
  app_private.in_portion(uuid) to authenticated, sidra_app;
grant update (title, description, language, tags, archived_at, is_public) on resources
  to authenticated, sidra_app;

-- ------------------------------------------- read-back after insert --
-- FIX: the app inserts and reads the row back (INSERT … RETURNING). Read
-- policies that looked the row up by id (can_read_resource(id) …) could
-- not see a row inserted by the same statement, so PostgreSQL reported
-- "new row violates row-level security policy". Each policy now also
-- checks the row's own columns.
drop policy resources_read on resources;
create policy resources_read on resources for select to public
  using (uploaded_by = app_private.current_user_id()
         or app_private.has_permission('courses.view')
         or app_private.has_permission('content.upload')
         or app_private.can_read_resource(id));

drop policy assignments_read on assignments;
create policy assignments_read on assignments for select to public
  using (app_private.can_author(course_id, lesson_id)
         or app_private.can_read_assignment(id));

drop policy media_read on media_assets;
create policy media_read on media_assets for select to public
  using (uploaded_by = app_private.current_user_id()
         or app_private.can_read_media(id));
