-- 0003 integrity triggers, access helpers and lesson sequencing.
--
-- All helpers are SECURITY DEFINER with a pinned search_path so RLS
-- policies can call them without recursion and without search_path
-- hijacking.

-- ======================================================== identity/roles ==

create or replace function app_private.current_user_id()
returns uuid
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select id from users
  where clerk_user_id = app_private.clerk_id() and is_active
$$;

create or replace function app_private.current_app_role()
returns app_role
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select role from users
  where clerk_user_id = app_private.clerk_id() and is_active
$$;

create or replace function app_private.is_admin()
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$ select coalesce(app_private.current_app_role() = 'admin', false) $$;

-- Staff of a course: admins, or teachers/editors assigned to it.
-- p_editor_only restricts to curriculum editors (plus admins).
create or replace function app_private.is_course_staff(
  p_course_id uuid, p_editor_only boolean default false)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.is_admin() or exists (
    select 1 from course_staff s
    join users u on u.id = s.user_id
    where s.course_id = p_course_id
      and s.user_id = app_private.current_user_id()
      and u.role in ('teacher', 'admin')
      and (not p_editor_only or s.role = 'editor')
  )
$$;

create or replace function app_private.is_enrolled(p_course_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (
    select 1 from course_enrolments
    where course_id = p_course_id
      and user_id = app_private.current_user_id()
      and status in ('active', 'completed')
  )
$$;

-- ===================================================== live curriculum ==

-- A lesson is "live" when it, its course, its unit and every ancestor node
-- are published. Unpublished anywhere up the chain hides it.
create or replace function app_private.lesson_is_live(p_lesson_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  with recursive chain as (
    select n.id, n.parent_id, n.status, n.unit_id
    from lessons l join curriculum_nodes n on n.id = l.node_id
    where l.id = p_lesson_id
    union all
    select n.id, n.parent_id, n.status, n.unit_id
    from curriculum_nodes n join chain c on n.id = c.parent_id
  )
  select exists (
    select 1 from lessons l
    join courses c on c.id = l.course_id
    left join course_units u on u.id = l.unit_id
    where l.id = p_lesson_id
      and l.status = 'published'
      and c.status = 'published'
      and (u.id is null or u.status = 'published')
  )
  and not exists (select 1 from chain where status <> 'published')
  and not exists (
    select 1 from chain ch join course_units u on u.id = ch.unit_id
    where u.status <> 'published'
  )
$$;

-- Linear order of live lessons in a course, derived from the tree:
-- (unit position, node positions root→leaf, lesson position).
-- Admins only maintain sibling positions; "next lesson" follows from this.
create or replace function app_private.lesson_sequence(p_course_id uuid)
returns table (lesson_id uuid, seq int)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  with recursive node_paths as (
    select n.id, n.unit_id, array[n.position] as path, n.status = 'published' as live
    from curriculum_nodes n
    where n.course_id = p_course_id and n.parent_id is null
    union all
    select n.id, coalesce(n.unit_id, p.unit_id), p.path || n.position,
           p.live and n.status = 'published'
    from curriculum_nodes n join node_paths p on n.parent_id = p.id
  ),
  lesson_paths as (
    select l.id,
           array[coalesce(u.position, -1)]
             || coalesce(np.path, '{}'::int[])
             || l.position as path
    from lessons l
    join courses c on c.id = l.course_id
    left join node_paths np on np.id = l.node_id
    left join course_units u on u.id = coalesce(l.unit_id, np.unit_id)
    where l.course_id = p_course_id
      and l.status = 'published'
      and c.status = 'published'
      and (l.node_id is null or np.live)
      and (u.id is null or u.status = 'published')
  )
  select id, (row_number() over (order by path, id))::int
  from lesson_paths
$$;

create or replace function app_private.next_lesson(p_lesson_id uuid)
returns uuid
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  with s as (
    select * from app_private.lesson_sequence(
      (select course_id from lessons where id = p_lesson_id))
  )
  select s2.lesson_id from s s1 join s s2 on s2.seq = s1.seq + 1
  where s1.lesson_id = p_lesson_id
$$;

-- The single rule deciding whether the caller may read a lesson's CONTENT
-- (blocks, media, assessments). Titles/outline are visible separately.
create or replace function app_private.can_read_lesson(p_lesson_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (
    select 1 from lessons l
    join courses c on c.id = l.course_id
    where l.id = p_lesson_id
      and (
        app_private.is_course_staff(c.id)
        or (
          app_private.lesson_is_live(l.id)
          and app_private.is_enrolled(c.id)
          and (
            l.is_preview
            or c.progression = 'open'
            or exists (
              select 1 from lesson_unlocks u
              where u.lesson_id = l.id
                and u.user_id = app_private.current_user_id()
            )
          )
        )
      )
  )
$$;

-- ========================================================= integrity ==

-- Nodes: same course as parent/unit; book level must follow the book's
-- structure depth; no cycles.
create or replace function app_private.check_curriculum_node()
returns trigger
language plpgsql
as $$
declare
  v_parent curriculum_nodes%rowtype;
  v_level book_structure_levels%rowtype;
  v_parent_depth int;
  v_book uuid;
begin
  if new.unit_id is not null and not exists (
    select 1 from course_units where id = new.unit_id and course_id = new.course_id
  ) then
    raise exception 'unit % is not in course %', new.unit_id, new.course_id;
  end if;

  if new.parent_id is not null then
    select * into v_parent from curriculum_nodes where id = new.parent_id;
    if v_parent.course_id <> new.course_id then
      raise exception 'parent node belongs to another course';
    end if;
    new.unit_id := coalesce(new.unit_id, v_parent.unit_id);
    if tg_op = 'UPDATE' and exists (
      with recursive up as (
        select id, parent_id from curriculum_nodes where id = new.parent_id
        union all
        select n.id, n.parent_id from curriculum_nodes n join up on n.id = up.parent_id
      ) select 1 from up where id = new.id
    ) then
      raise exception 'curriculum node cycle detected';
    end if;
  end if;

  if new.structure_level_id is not null then
    select * into v_level from book_structure_levels where id = new.structure_level_id;
    select book_id into v_book from book_structures where id = v_level.structure_id;
    new.book_id := coalesce(new.book_id, v_book);
    if new.book_id <> v_book then
      raise exception 'structure level does not belong to book %', new.book_id;
    end if;
    new.node_type := v_level.node_type;
    if v_parent.structure_level_id is not null then
      select depth into v_parent_depth from book_structure_levels
      where id = v_parent.structure_level_id
        and structure_id = v_level.structure_id;
      if v_parent_depth is not null and v_level.depth <> v_parent_depth + 1 then
        raise exception '% must sit directly under level %',
          v_level.label_singular, v_parent_depth;
      end if;
    end if;
  end if;
  return new;
end;
$$;

create trigger curriculum_nodes_check
  before insert or update on curriculum_nodes
  for each row execute function app_private.check_curriculum_node();

create or replace function app_private.check_lesson()
returns trigger
language plpgsql
as $$
declare v_node curriculum_nodes%rowtype;
begin
  if new.node_id is not null then
    select * into v_node from curriculum_nodes where id = new.node_id;
    if v_node.course_id <> new.course_id then
      raise exception 'node belongs to another course';
    end if;
    new.unit_id := coalesce(new.unit_id, v_node.unit_id);
  end if;
  if new.unit_id is not null and not exists (
    select 1 from course_units where id = new.unit_id and course_id = new.course_id
  ) then
    raise exception 'unit % is not in course %', new.unit_id, new.course_id;
  end if;
  if tg_op = 'UPDATE' and (new.title, new.summary) is distinct from (old.title, old.summary) then
    new.content_version := old.content_version + 1;
  end if;
  return new;
end;
$$;

create trigger lessons_check
  before insert or update on lessons
  for each row execute function app_private.check_lesson();

-- Validates the type-specific shape of a content block.
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
  end
$$;

alter table lesson_content_blocks add constraint lesson_content_blocks_valid
  check (app_private.valid_block(block_type, body, media_asset_id, assessment_id));

-- Any content edit bumps the lesson's content_version so clients re-download.
create or replace function app_private.bump_lesson_version()
returns trigger
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  update lessons set content_version = content_version + 1
  where id = coalesce(new.lesson_id, old.lesson_id);
  return null;
end;
$$;

create trigger lesson_content_blocks_version
  after insert or update or delete on lesson_content_blocks
  for each row execute function app_private.bump_lesson_version();

create or replace function app_private.check_assessment()
returns trigger
language plpgsql
as $$
begin
  if new.lesson_id is not null and not exists (
    select 1 from lessons where id = new.lesson_id and course_id = new.course_id
  ) then
    raise exception 'lesson belongs to another course';
  end if;
  if new.kind = 'practice' and new.grading = 'teacher' then
    raise exception 'practice assessments are auto-graded';
  end if;
  return new;
end;
$$;

create trigger assessments_check
  before insert or update on assessments
  for each row execute function app_private.check_assessment();

-- Keeps course_id consistent with lesson_id on per-lesson learner tables.
create or replace function app_private.fill_course_from_lesson()
returns trigger
language plpgsql
as $$
begin
  select course_id into new.course_id from lessons where id = new.lesson_id;
  if new.course_id is null then
    raise exception 'lesson % not found', new.lesson_id;
  end if;
  return new;
end;
$$;

create trigger lesson_unlocks_course before insert or update on lesson_unlocks
  for each row execute function app_private.fill_course_from_lesson();
create trigger lesson_reviews_course before insert or update on lesson_reviews
  for each row execute function app_private.fill_course_from_lesson();
create trigger learner_progress_course before insert or update on learner_progress
  for each row execute function app_private.fill_course_from_lesson();

-- Activating an enrolment unlocks the first lesson so learners have a
-- starting point in teacher-gated and sequential courses.
create or replace function app_private.unlock_first_lesson()
returns trigger
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_first uuid;
begin
  if new.status = 'active' and (tg_op = 'INSERT' or old.status <> 'active') then
    select lesson_id into v_first
    from app_private.lesson_sequence(new.course_id) where seq = 1;
    if v_first is not null then
      insert into lesson_unlocks (user_id, lesson_id, course_id, reason)
      values (new.user_id, v_first, new.course_id, 'first_lesson')
      on conflict (user_id, lesson_id) do nothing;
    end if;
  end if;
  return new;
end;
$$;

create trigger course_enrolments_first_unlock
  after insert or update of status on course_enrolments
  for each row execute function app_private.unlock_first_lesson();

-- Role changes are only possible through set_user_role() (admin).
create or replace function app_private.protect_user_role()
returns trigger
language plpgsql
as $$
begin
  if new.role is distinct from old.role
     and current_setting('sidra.role_change', true) is distinct from 'allowed' then
    raise exception 'role can only be changed by an administrator';
  end if;
  if new.clerk_user_id is distinct from old.clerk_user_id then
    raise exception 'clerk_user_id is immutable';
  end if;
  return new;
end;
$$;

create trigger users_protect_role before update on users
  for each row execute function app_private.protect_user_role();
