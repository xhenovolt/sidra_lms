-- Course rules and lesson work.
--
-- How the next lesson unlocks (courses.progression):
--   open              every lesson is open
--   sequential        finishing (reading) a lesson unlocks the next
--   after_submission  handing in the lesson's work unlocks the next
--   after_approval    the teacher marks the work; a pass (score >= the
--                     course pass mark) unlocks the next
--   teacher_gated     the teacher unlocks each lesson by hand
--
-- In after_submission / after_approval courses a lesson needs handed-in work
-- (a recording, photo, scan, file or text) unless the lesson says it does
-- not (lessons.work_required = false). Learners cannot mark such a lesson
-- finished themselves. Teachers mark the work word by word; every verdict
-- is kept. Admins can switch any kind of notification off, for everyone or
-- for one course.

alter table courses
  add column pass_mark_percent int not null default 70 check (pass_mark_percent between 0 and 100),
  add column max_attempts int check (max_attempts is null or max_attempts > 0);
grant update (pass_mark_percent, max_attempts, progression) on courses to authenticated, sidra_app;

alter table lessons add column work_required boolean;   -- null: follow the course
grant update (work_required) on lessons to authenticated, sidra_app;

create or replace function app_private.lesson_needs_work(p_lesson_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce(l.work_required, c.progression in ('after_submission', 'after_approval'))
  from lessons l join courses c on c.id = l.course_id
  where l.id = p_lesson_id
$$;

-- Lesson work lives in submissions too (no assignment, no portion).
alter table submissions drop constraint submissions_one_target;
alter table submissions add constraint submissions_one_target check (
  num_nonnulls(assignment_id, portion_id) <= 1
  and (assignment_id is not null or portion_id is not null or lesson_id is not null));
create unique index submissions_lesson_attempt on submissions (lesson_id, user_id, attempt)
  where assignment_id is null and portion_id is null;

alter table submission_reviews
  add column score_percent numeric(5, 2) check (score_percent is null or score_percent between 0 and 100),
  -- [{"i": word index, "w": the word, "m": "ok" | "weak" | "wrong", "n": note}]
  add column word_marks jsonb check (word_marks is null or jsonb_typeof(word_marks) = 'array');

-- ------------------------------------------------------- notifications --

-- Off switches: org setting 'notify_<kind>' = 'false' (everyone), or the
-- course's metadata {"notify": {"<kind>": false}}.
create or replace function app_private.notification_allowed(p_kind text, p_course_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select coalesce((select value from org_settings where key = 'notify_' || p_kind), 'true') <> 'false'
     and coalesce((select (metadata->'notify'->>p_kind)::boolean from courses where id = p_course_id), true)
$$;

create or replace function app_private.notify(
  p_user uuid, p_kind text, p_title text, p_body text, p_data jsonb)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_course uuid := coalesce(
    nullif(p_data->>'course_id', '')::uuid,
    (select course_id from teaching_portions where id = nullif(p_data->>'portion_id', '')::uuid),
    (select course_id from submissions where id = nullif(p_data->>'submission_id', '')::uuid));
begin
  if not app_private.notification_allowed(p_kind, v_course) then return; end if;
  insert into notifications (user_id, kind, title, body, data)
  values (p_user, p_kind, p_title, p_body, coalesce(p_data, '{}'));
end;
$$;

-- Everyone who teaches a lesson (course staff; unit-scoped teachers only
-- for their units).
create or replace function app_private.lesson_teachers(p_lesson_id uuid)
returns setof uuid
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select distinct s.user_id
  from lessons l
  join course_staff s on s.course_id = l.course_id
  join users u on u.id = s.user_id and u.is_active and u.role in ('teacher', 'admin')
  where l.id = p_lesson_id
    and (not exists (select 1 from course_staff_units cu
                     where cu.course_id = s.course_id and cu.user_id = s.user_id)
         or exists (select 1 from course_staff_units cu
                    where cu.course_id = s.course_id and cu.user_id = s.user_id
                      and cu.unit_id = app_private.lesson_unit(l.id)))
$$;

-- ------------------------------------------------------ progression --

create or replace function app_private.complete_and_unlock(
  p_user uuid, p_lesson_id uuid, p_reason unlock_reason)
returns uuid
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_course uuid; v_next uuid;
begin
  select course_id into v_course from lessons where id = p_lesson_id;
  insert into learner_progress (user_id, lesson_id, course_id, status, completed_at,
                                last_accessed_at, client_updated_at)
  values (p_user, p_lesson_id, v_course, 'completed', now(), now(), now())
  on conflict (user_id, lesson_id) do update
    set status = 'completed', completed_at = coalesce(learner_progress.completed_at, now());
  v_next := app_private.next_lesson(p_lesson_id);
  if v_next is not null then
    insert into lesson_unlocks (user_id, lesson_id, course_id, reason, unlocked_by)
    values (p_user, v_next, v_course, p_reason,
            case when p_reason = 'work_approved' then app_private.current_user_id() end)
    on conflict (user_id, lesson_id) do nothing;
  end if;
  return v_next;
end;
$$;

-- Learners cannot mark a lesson that needs work as finished themselves.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.record_progress(uuid, uuid, progress_status, jsonb, timestamptz)'::regprocedure);
  if position('  -- Clamp device clocks that run ahead of the server.' in v_src) = 0 then
    raise exception 'record_progress changed; update 0030';
  end if;
  execute replace(v_src, '  -- Clamp device clocks that run ahead of the server.',
    '  if p_status = ''completed'' and app_private.lesson_needs_work(p_lesson_id) then
    p_status := ''in_progress'';   -- finished only when the work is handed in / passed
  end if;
  -- Clamp device clocks that run ahead of the server.');
end $$;

-- ------------------------------------------------------- lesson work --

create or replace function app_private.lesson_work_json(s submissions)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.submission_json(s) || jsonb_build_object(
    'pass_mark', (select pass_mark_percent from courses where id = s.course_id),
    'progression', (select progression from courses where id = s.course_id),
    'avatar_url', (select avatar_url from users where id = s.user_id),
    'reviews', (select coalesce(jsonb_agg(jsonb_build_object(
                  'id', r.id, 'result', r.result, 'feedback', r.feedback,
                  'score_percent', r.score_percent, 'word_marks', r.word_marks,
                  'created_at', r.created_at,
                  'reviewer', (select display_name from users where id = r.reviewer_id),
                  'correction_asset_id', r.correction_asset_id,
                  'correction', (select jsonb_build_object('id', c.id, 'title', c.title,
                                   'explanation', c.explanation, 'media_asset_id', c.media_asset_id)
                                 from corrections c where c.id = r.correction_id))
                  order by r.created_at desc), '[]')
                from submission_reviews r where r.submission_id = s.id))
$$;

-- Hand in the work for a lesson. Idempotent on p_submission_id.
create or replace function public.submit_lesson_work(
  p_submission_id uuid, p_lesson_id uuid, p_text text default null, p_files jsonb default '[]')
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_lesson lessons%rowtype;
  v_course courses%rowtype;
  v_prev submissions%rowtype;
  v_sub submissions%rowtype;
  v_file jsonb; v_pos int := 0; v_t uuid; v_next uuid;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  select * into v_sub from submissions where id = p_submission_id;
  if found then
    if v_sub.user_id <> v_me then raise exception 'not yours' using errcode = 'PT403'; end if;
    return app_private.lesson_work_json(v_sub);
  end if;
  select * into v_lesson from lessons where id = p_lesson_id;
  if not found or not app_private.can_read_lesson(p_lesson_id)
     or not app_private.is_enrolled(v_lesson.course_id) then
    raise exception 'lesson not found' using errcode = 'PT404';
  end if;
  select * into v_course from courses where id = v_lesson.course_id;
  if jsonb_array_length(coalesce(p_files, '[]')) = 0 and coalesce(trim(p_text), '') = '' then
    raise exception 'add a recording, photo, file or answer' using errcode = 'PT422';
  end if;
  if exists (select 1 from jsonb_array_elements(coalesce(p_files, '[]')) f
             where not exists (select 1 from media_assets m
                               where m.id = (f->>'media_asset_id')::uuid and m.uploaded_by = v_me)) then
    raise exception 'files must be your own uploads' using errcode = 'PT403';
  end if;
  select * into v_prev from submissions
  where lesson_id = p_lesson_id and user_id = v_me and assignment_id is null and portion_id is null
  order by attempt desc limit 1;
  if found and v_prev.status in ('submitted', 'received', 'under_review') then
    raise exception 'already handed in; wait for your teacher' using errcode = 'PT409';
  end if;
  if found and v_prev.status = 'reviewed' then
    raise exception 'this work was already approved' using errcode = 'PT409';
  end if;
  if v_course.max_attempts is not null and coalesce(v_prev.attempt, 0) >= v_course.max_attempts then
    raise exception 'no attempts left; ask your teacher' using errcode = 'PT409';
  end if;

  insert into submissions (id, user_id, course_id, lesson_id, attempt, text_answer)
  values (p_submission_id, v_me, v_lesson.course_id, p_lesson_id, coalesce(v_prev.attempt, 0) + 1,
          nullif(trim(p_text), ''))
  returning * into v_sub;
  for v_file in select * from jsonb_array_elements(coalesce(p_files, '[]')) loop
    insert into submission_files (submission_id, media_asset_id, file_name, mime_type, bytes, position)
    values (v_sub.id, (v_file->>'media_asset_id')::uuid, v_file->>'file_name',
            v_file->>'mime_type', (v_file->>'bytes')::bigint, v_pos);
    v_pos := v_pos + 1;
  end loop;

  -- Handing in is enough in after_submission courses.
  if v_course.progression = 'after_submission' then
    v_next := app_private.complete_and_unlock(v_me, p_lesson_id, 'work_submitted');
  end if;

  for v_t in select * from app_private.lesson_teachers(p_lesson_id) loop
    perform app_private.notify(v_t, 'lesson_work',
      'New work from ' || coalesce((select display_name from users where id = v_me), 'a learner'),
      v_lesson.title || case when v_sub.attempt > 1 then ' · attempt ' || v_sub.attempt else '' end,
      jsonb_build_object('submission_id', v_sub.id, 'lesson_id', p_lesson_id,
                         'course_id', v_lesson.course_id));
  end loop;
  return app_private.lesson_work_json(v_sub) || jsonb_build_object('unlocked_lesson_id', v_next);
end;
$$;

create or replace function public.my_lesson_work(p_lesson_id uuid)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.lesson_work_json(s) from submissions s
  where s.lesson_id = p_lesson_id and s.user_id = app_private.current_user_id()
    and s.assignment_id is null and s.portion_id is null
  order by s.attempt desc
$$;

-- Teacher's queue of lesson work (newest waiting first).
create or replace function public.teacher_lesson_work(
  p_status text default 'waiting', p_course_id uuid default null, p_limit int default 100)
returns setof jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select app_private.lesson_work_json(s) from submissions s
  where s.assignment_id is null and s.portion_id is null and s.lesson_id is not null
    and app_private.teaches(s.course_id, s.lesson_id)
    and (p_course_id is null or s.course_id = p_course_id)
    and (p_status is null or p_status = 'all'
         or (p_status = 'waiting' and s.status in ('submitted', 'received', 'under_review'))
         or (p_status = 'reviewed' and s.status in ('reviewed', 'returned', 'resubmission_requested')))
  order by (s.status in ('submitted', 'received', 'under_review')) desc, s.submitted_at
  limit least(greatest(coalesce(p_limit, 100), 1), 300)
$$;

-- The lesson's own text, word by word, for marking (Qur'an / Arabic blocks).
create or replace function public.lesson_marking_text(p_lesson_id uuid)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case when not app_private.teaches((select course_id from lessons where id = p_lesson_id),
                                           p_lesson_id) then null
  else coalesce(jsonb_agg(w order by b.position, w_i), '[]') end
  from lesson_content_blocks b,
       lateral (select word as w, ordinality as w_i
                from regexp_split_to_table(trim(coalesce(b.body->>'arabic', b.body->>'text')), '\s+')
                     with ordinality as t(word, ordinality)
                where word !~ '^[0-9٠-٩۰-۹]+$') words
  where b.lesson_id = p_lesson_id and b.block_type = 'quran_text'
$$;

-- The teacher's verdict on lesson work: result, optional score (from word
-- marks or typed), word marks, feedback and a correction. A pass unlocks
-- the next lesson (unless the course is open or teacher-gated by hand).
create or replace function public.review_lesson_work(
  p_submission_id uuid, p_result review_result,
  p_score_percent numeric default null, p_word_marks jsonb default null,
  p_feedback text default null, p_correction_id uuid default null,
  p_correction_asset_id uuid default null, p_save_as jsonb default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v submissions%rowtype;
  v_course courses%rowtype;
  v_review jsonb;
  v_passed boolean;
  v_next uuid;
begin
  select * into v from submissions where id = p_submission_id;
  if not found or v.assignment_id is not null or v.portion_id is not null then
    raise exception 'lesson work not found' using errcode = 'PT404';
  end if;
  select * into v_course from courses where id = v.course_id;
  v_passed := p_result in ('excellent', 'correct', 'minor_correction')
              and (p_score_percent is null or p_score_percent >= v_course.pass_mark_percent);
  -- A score below the pass mark is a correction, whatever button was used.
  v_review := public.review_attempt(
    p_submission_id,
    case when v_passed or p_result not in ('excellent', 'correct', 'minor_correction')
         then p_result else 'correction_required'::review_result end,
    p_feedback, p_correction_id, p_correction_asset_id, null, p_save_as);
  update submission_reviews set score_percent = p_score_percent, word_marks = p_word_marks,
    score = coalesce(score, p_score_percent)
  where id = (v_review->>'id')::uuid;
  update submissions set score = p_score_percent where id = v.id;

  if v_passed then
    if v_course.progression in ('after_approval', 'after_submission', 'sequential') then
      v_next := app_private.complete_and_unlock(v.user_id, v.lesson_id, 'work_approved');
    else
      -- open: everything is open already; teacher_gated: the teacher
      -- unlocks the next lesson by hand. Either way the lesson is done.
      insert into learner_progress (user_id, lesson_id, course_id, status, completed_at)
      values (v.user_id, v.lesson_id, v.course_id, 'completed', now())
      on conflict (user_id, lesson_id) do update set status = 'completed',
        completed_at = coalesce(learner_progress.completed_at, now());
    end if;
  end if;
  return v_review || jsonb_build_object('passed', v_passed, 'unlocked_lesson_id', v_next,
                                        'pass_mark', v_course.pass_mark_percent);
end;
$$;

-- Learner notifications name the lesson for lesson work.
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('public.review_attempt(uuid, review_result, text, uuid, uuid, numeric, jsonb)'::regprocedure);
  if position('coalesce(v_p.title, ''Your work'')' in v_src) = 0 then
    raise exception 'review_attempt changed; update 0030';
  end if;
  v_src := replace(v_src, 'coalesce(v_p.title, ''Your work'')',
    'coalesce(v_p.title, (select title from lessons where id = v.lesson_id), ''Your work'')');
  -- Tapping the notification opens the lesson.
  execute replace(v_src,
    'jsonb_build_object(''portion_id'', v.portion_id, ''submission_id'', v.id)',
    'jsonb_build_object(''portion_id'', v.portion_id, ''submission_id'', v.id,
                       ''lesson_id'', v.lesson_id, ''course_id'', v.course_id)');
end $$;

do $$
declare r record;
begin
  for r in select p.oid::regprocedure as fn
           from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.proname in (
             'submit_lesson_work', 'my_lesson_work', 'teacher_lesson_work',
             'lesson_marking_text', 'review_lesson_work') loop
    execute format('revoke all on function %s from public', r.fn);
    execute format('grant execute on function %s to authenticated, sidra_app', r.fn);
  end loop;
end $$;
grant execute on function app_private.lesson_needs_work(uuid) to authenticated, sidra_app;
