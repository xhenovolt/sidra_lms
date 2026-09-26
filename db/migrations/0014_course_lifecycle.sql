-- Phase 2C: course lifecycle and richer course details.
--   draft → in_review → published → archived (→ restored to draft)
--   Publishing is gated by course_publish_check(): blocking problems stop it,
--   warnings are shown to the admin. Published courses are archived, never
--   deleted; only never-published drafts without learners can be deleted.
--   Lessons gain an external_link block (YouTube, Telegram, any web page).

alter table courses
  add column category text,
  add column tags text[] not null default '{}',
  add column self_enrol boolean not null default true,
  add column review_note text,
  add column archived_at timestamptz;

grant update (category, tags, self_enrol) on courses to authenticated, sidra_app;

create index courses_status_idx on courses (status);

-- ------------------------------------------------------ external links --

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
  end
$$;

-- ------------------------------------------------------ publish check --

create or replace function public.course_publish_check(p_course_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_course courses%rowtype;
  v_published int;
  v_drafts int;
  v_empty int;
  v_errors jsonb := '[]';
  v_warnings jsonb := '[]';
begin
  if not app_private.is_course_staff(p_course_id) then
    raise exception 'course not found' using errcode = 'PT404';
  end if;
  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course not found' using errcode = 'PT404'; end if;

  select count(*) filter (where status = 'published'),
         count(*) filter (where status in ('draft', 'in_review'))
    into v_published, v_drafts
    from lessons where course_id = p_course_id;
  select count(*) into v_empty
    from lessons l
   where l.course_id = p_course_id and l.status = 'published'
     and not exists (select 1 from lesson_content_blocks b where b.lesson_id = l.id);

  if v_published = 0 then
    v_errors := v_errors || jsonb_build_object('code', 'no_published_lessons');
  end if;
  if coalesce(trim(v_course.description), '') = '' then
    v_warnings := v_warnings || jsonb_build_object('code', 'no_description');
  end if;
  if v_course.thumbnail_asset_id is null then
    v_warnings := v_warnings || jsonb_build_object('code', 'no_thumbnail');
  end if;
  if v_empty > 0 then
    v_warnings := v_warnings || jsonb_build_object('code', 'empty_lessons', 'count', v_empty);
  end if;
  if v_drafts > 0 then
    v_warnings := v_warnings || jsonb_build_object('code', 'draft_lessons', 'count', v_drafts);
  end if;
  if v_course.progression = 'teacher_gated' and not exists (
       select 1 from course_staff where course_id = p_course_id and role = 'teacher') then
    v_warnings := v_warnings || jsonb_build_object('code', 'no_teacher');
  end if;

  return jsonb_build_object(
    'errors', v_errors,
    'warnings', v_warnings,
    'published_lessons', v_published);
end;
$$;

-- ------------------------------------------------------- transitions --

drop function public.set_course_status(uuid, publish_status);

create function public.set_course_status(
  p_course_id uuid, p_status publish_status, p_note text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_course courses%rowtype;
  v_from publish_status;
  v_publisher boolean;
  v_allowed boolean;
begin
  select * into v_course from courses where id = p_course_id for update;
  if not found then
    raise exception 'course not found' using errcode = 'PT404';
  end if;
  v_from := v_course.status;
  if v_from = p_status then
    return to_jsonb(v_course);
  end if;

  -- courses.publish, or an editor ASSIGNED to this course (not merely
  -- curriculum.edit, which only lets you submit for review).
  v_publisher := app_private.has_permission('courses.publish')
    or exists (select 1 from course_staff s
               where s.course_id = p_course_id and s.role = 'editor'
                 and s.user_id = app_private.current_user_id());

  if v_from = 'archived' and p_status <> 'draft' then
    raise exception 'restore this archived course to draft first' using errcode = 'PT409';
  end if;
  v_allowed := case
    when p_status = 'archived' or v_from = 'archived' then
      app_private.has_permission('courses.archive')
    when p_status = 'in_review' then
      v_from = 'draft' and (app_private.has_permission('curriculum.edit') or v_publisher)
    else v_publisher   -- publish, unpublish, return to draft
  end;
  if not v_allowed then
    raise exception 'not allowed to change this course''s status' using errcode = 'PT403';
  end if;

  if p_status in ('in_review', 'published')
     and jsonb_array_length(public.course_publish_check(p_course_id)->'errors') > 0 then
    raise exception 'this course is not ready: fix the problems listed first'
      using errcode = 'PT422';
  end if;

  update courses set
    status = p_status,
    content_version = content_version + 1,
    published_at = case when p_status = 'published' then coalesce(published_at, now())
                        else published_at end,
    archived_at = case when p_status = 'archived' then now() end,
    -- A note travels with a submission, or with a course sent back to draft.
    review_note = case when p_status = 'in_review'
                         or (p_status = 'draft' and v_from = 'in_review')
                       then nullif(trim(p_note), '') end,
    updated_at = now()
  where id = p_course_id returning * into v_course;
  return to_jsonb(v_course);
end;
$$;

revoke all on function public.set_course_status(uuid, publish_status, text),
                       public.course_publish_check(uuid) from public;
grant execute on function public.set_course_status(uuid, publish_status, text),
                          public.course_publish_check(uuid) to authenticated, sidra_app;

-- ---------------------------------------------------------- deletion --

drop policy courses_delete on courses;
create policy courses_delete on courses for delete to public
  using (app_private.has_permission('courses.archive'));

create or replace function app_private.guard_course_delete()
returns trigger
language plpgsql
as $$
begin
  if old.published_at is not null
     or exists (select 1 from course_enrolments where course_id = old.id) then
    raise exception 'this course has been published or has learners: archive it instead'
      using errcode = 'PT409';
  end if;
  return old;
end;
$$;

create trigger courses_guard_delete before delete on courses
  for each row execute function app_private.guard_course_delete();

-- --------------------------------------------------------- enrolment --

create or replace function public.enrol_in_course(p_course_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_course courses%rowtype;
  v_enrolment course_enrolments%rowtype;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  select * into v_course from courses where id = p_course_id and status = 'published';
  if not found then raise exception 'course not found' using errcode = 'PT404'; end if;
  if v_course.access <> 'free' or not v_course.self_enrol then
    raise exception 'this course requires access to be granted' using errcode = 'PT403';
  end if;

  insert into course_enrolments (course_id, user_id, status, source)
  values (p_course_id, v_me, 'active', 'self_free')
  on conflict (course_id, user_id) do update
    set status = case when course_enrolments.status = 'withdrawn'
                      then 'active'::enrolment_status
                      else course_enrolments.status end
  returning * into v_enrolment;

  return to_jsonb(v_enrolment);
end;
$$;

-- --------------------------------------------------------- dashboard --

create or replace function public.admin_overview()
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case when not app_private.has_permission('dashboard.view') then null else jsonb_build_object(
    'learners', (select count(*) from users where role = 'learner' and is_active),
    'teachers', (select count(*) from users where role = 'teacher' and is_active),
    'admins', (select count(*) from users where role = 'admin' and is_active),
    'disabled', (select count(*) from users where not is_active),
    'courses_published', (select count(*) from courses where status = 'published'),
    'courses_draft', (select count(*) from courses where status = 'draft'),
    'courses_in_review', (select count(*) from courses where status = 'in_review'),
    'courses_archived', (select count(*) from courses where status = 'archived'),
    'active_enrolments', (select count(*) from course_enrolments where status = 'active'),
    'active_learners_7d', (select count(distinct user_id) from learner_progress
                           where last_accessed_at > now() - interval '7 days'),
    'lessons_completed_7d', (select count(*) from learner_progress
                             where completed_at > now() - interval '7 days')
  ) end
$$;
