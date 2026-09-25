-- 0004 API functions (called by the app as POST /rpc/<name>).
--
-- Business rules that must be trusted live here, not in the app:
-- enrolment, teacher unlocks and reviews, progress merge, quiz scoring,
-- role changes, signed media URLs.
--
-- Errors use SQLSTATE 'PTnnn' so the Data API answers with HTTP nnn.

-- ============================================================= profile ==

-- Creates or refreshes the caller's user row from their Clerk identity.
-- Role is never taken from the client: new users are always learners.
create or replace function public.ensure_profile(
  p_display_name text default null,
  p_email text default null,
  p_avatar_url text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_clerk text := app_private.clerk_id();
  v_user users%rowtype;
begin
  if v_clerk is null then
    raise exception 'not signed in' using errcode = 'PT401';
  end if;
  insert into users (clerk_user_id, display_name, email, avatar_url)
  values (v_clerk, p_display_name, p_email, p_avatar_url)
  on conflict (clerk_user_id) do update set
    display_name = coalesce(excluded.display_name, users.display_name),
    email = coalesce(excluded.email, users.email),
    avatar_url = coalesce(excluded.avatar_url, users.avatar_url)
  returning * into v_user;

  if not v_user.is_active then
    raise exception 'account disabled' using errcode = 'PT403';
  end if;

  insert into learner_profiles (user_id) values (v_user.id)
  on conflict do nothing;

  return jsonb_build_object(
    'id', v_user.id, 'role', v_user.role,
    'display_name', v_user.display_name, 'email', v_user.email,
    'avatar_url', v_user.avatar_url);
end;
$$;

-- ============================================================ enrolment ==

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
  if v_course.access <> 'free' then
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

-- Admin-only: grants access to paid/restricted courses (later: payments).
create or replace function public.grant_enrolment(
  p_user_id uuid, p_course_id uuid, p_teacher_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_enrolment course_enrolments%rowtype;
begin
  if not app_private.is_admin() then
    raise exception 'administrators only' using errcode = 'PT403';
  end if;
  insert into course_enrolments (course_id, user_id, status, source, teacher_id, granted_by)
  values (p_course_id, p_user_id, 'active', 'admin_grant', p_teacher_id, app_private.current_user_id())
  on conflict (course_id, user_id) do update set
    status = 'active',
    teacher_id = coalesce(excluded.teacher_id, course_enrolments.teacher_id),
    granted_by = excluded.granted_by
  returning * into v_enrolment;
  return to_jsonb(v_enrolment);
end;
$$;

create or replace function public.set_enrolment_status(
  p_enrolment_id uuid, p_status enrolment_status)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_enrolment course_enrolments%rowtype;
begin
  select * into v_enrolment from course_enrolments where id = p_enrolment_id;
  if not found then raise exception 'enrolment not found' using errcode = 'PT404'; end if;
  if not app_private.is_course_staff(v_enrolment.course_id) then
    raise exception 'staff only' using errcode = 'PT403';
  end if;
  update course_enrolments set status = p_status,
    completed_at = case when p_status = 'completed' then now() else completed_at end
  where id = p_enrolment_id returning * into v_enrolment;
  return to_jsonb(v_enrolment);
end;
$$;

-- ==================================================== teacher gating ==

create or replace function public.unlock_lesson(
  p_user_id uuid, p_lesson_id uuid, p_note text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_course uuid;
  v_unlock lesson_unlocks%rowtype;
begin
  select course_id into v_course from lessons where id = p_lesson_id;
  if v_course is null then raise exception 'lesson not found' using errcode = 'PT404'; end if;
  if not app_private.is_course_staff(v_course) then
    raise exception 'only the course teacher can unlock lessons' using errcode = 'PT403';
  end if;
  if not exists (
    select 1 from course_enrolments
    where course_id = v_course and user_id = p_user_id and status = 'active'
  ) then
    raise exception 'learner is not actively enrolled' using errcode = 'PT409';
  end if;

  insert into lesson_unlocks (user_id, lesson_id, course_id, reason, unlocked_by, note)
  values (p_user_id, p_lesson_id, v_course,
          case when app_private.is_admin() then 'admin_override' else 'teacher_approved' end::unlock_reason,
          app_private.current_user_id(), p_note)
  on conflict (user_id, lesson_id) do update set note = coalesce(excluded.note, lesson_unlocks.note)
  returning * into v_unlock;
  return to_jsonb(v_unlock);
end;
$$;

create or replace function public.revoke_lesson_unlock(p_user_id uuid, p_lesson_id uuid)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  if not app_private.is_course_staff((select course_id from lessons where id = p_lesson_id)) then
    raise exception 'staff only' using errcode = 'PT403';
  end if;
  delete from lesson_unlocks where user_id = p_user_id and lesson_id = p_lesson_id;
end;
$$;

-- Teacher marks a learner on a lesson. If passed (and p_unlock_next), the
-- next lesson in the course sequence is unlocked for that learner.
create or replace function public.review_lesson(
  p_user_id uuid,
  p_lesson_id uuid,
  p_outcome review_outcome,
  p_score numeric default null,
  p_feedback text default null,
  p_unlock_next boolean default true,
  p_feedback_audio_asset_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_course uuid;
  v_review lesson_reviews%rowtype;
  v_next uuid;
begin
  select course_id into v_course from lessons where id = p_lesson_id;
  if v_course is null then raise exception 'lesson not found' using errcode = 'PT404'; end if;
  if not app_private.is_course_staff(v_course) then
    raise exception 'only the course teacher can review learners' using errcode = 'PT403';
  end if;

  insert into lesson_reviews (user_id, lesson_id, course_id, teacher_id, outcome,
                              score, feedback, feedback_audio_asset_id)
  values (p_user_id, p_lesson_id, v_course, app_private.current_user_id(), p_outcome,
          p_score, p_feedback, p_feedback_audio_asset_id)
  returning * into v_review;

  if p_outcome = 'passed' then
    insert into learner_progress (user_id, lesson_id, course_id, status, completed_at)
    values (p_user_id, p_lesson_id, v_course, 'completed', now())
    on conflict (user_id, lesson_id) do update
      set status = 'completed',
          completed_at = coalesce(learner_progress.completed_at, now());

    if p_unlock_next then
      v_next := app_private.next_lesson(p_lesson_id);
      if v_next is not null then
        insert into lesson_unlocks (user_id, lesson_id, course_id, reason, unlocked_by)
        values (p_user_id, v_next, v_course, 'teacher_approved', app_private.current_user_id())
        on conflict (user_id, lesson_id) do nothing;
      end if;
    end if;
  end if;

  return jsonb_build_object('review', to_jsonb(v_review), 'unlocked_lesson_id', v_next);
end;
$$;

-- Ordered live lessons with the caller's lock state (for outlines and
-- next/previous navigation). Visible for published courses or to staff.
create or replace function public.course_lesson_order(p_course_id uuid)
returns table (lesson_id uuid, seq int, is_unlocked boolean)
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select s.lesson_id, s.seq, app_private.can_read_lesson(s.lesson_id)
  from app_private.lesson_sequence(p_course_id) s
  where app_private.current_user_id() is not null
  order by s.seq
$$;

-- ============================================================ progress ==

-- Idempotent, conflict-safe progress upsert used by the offline outbox.
--   * same p_op_id twice → returns the first result, applies nothing
--   * 'completed' is sticky; it never regresses
--   * position/last-access follow the newest client timestamp
--   * sequential courses unlock the next lesson on completion
create or replace function public.record_progress(
  p_op_id uuid,
  p_lesson_id uuid,
  p_status progress_status,
  p_last_position jsonb default '{}',
  p_client_updated_at timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_prior jsonb;
  v_row learner_progress%rowtype;
  v_course courses%rowtype;
  v_next uuid;
  v_result jsonb;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;

  select result into v_prior from sync_operations where op_id = p_op_id and user_id = v_me;
  if found then return v_prior; end if;

  if not app_private.can_read_lesson(p_lesson_id) then
    raise exception 'lesson is locked' using errcode = 'PT403';
  end if;
  -- Clamp device clocks that run ahead of the server.
  p_client_updated_at := least(p_client_updated_at, now() + interval '5 minutes');

  insert into learner_progress (user_id, lesson_id, course_id, status, last_position,
                                completed_at, last_accessed_at, client_updated_at)
  values (v_me, p_lesson_id, (select course_id from lessons where id = p_lesson_id),
          p_status, coalesce(p_last_position, '{}'),
          case when p_status = 'completed' then p_client_updated_at end,
          p_client_updated_at, p_client_updated_at)
  on conflict (user_id, lesson_id) do update set
    status = case
      when learner_progress.status = 'completed' then 'completed'::progress_status
      when excluded.status = 'completed' then 'completed'::progress_status
      else greatest(learner_progress.status, excluded.status) end,
    completed_at = coalesce(learner_progress.completed_at, excluded.completed_at),
    last_position = case when excluded.client_updated_at >= learner_progress.client_updated_at
                         then excluded.last_position else learner_progress.last_position end,
    last_accessed_at = greatest(learner_progress.last_accessed_at, excluded.last_accessed_at),
    client_updated_at = greatest(learner_progress.client_updated_at, excluded.client_updated_at)
  returning * into v_row;

  select * into v_course from courses where id = v_row.course_id;
  if v_row.status = 'completed' and v_course.progression = 'sequential' then
    v_next := app_private.next_lesson(p_lesson_id);
    if v_next is not null then
      insert into lesson_unlocks (user_id, lesson_id, course_id, reason)
      values (v_me, v_next, v_row.course_id, 'auto_sequential')
      on conflict (user_id, lesson_id) do nothing;
    end if;
  end if;

  v_result := to_jsonb(v_row) || jsonb_build_object('unlocked_lesson_id', v_next);
  insert into sync_operations (op_id, user_id, op_type, result)
  values (p_op_id, v_me, 'record_progress', v_result);
  return v_result;
end;
$$;

-- ========================================================= assessments ==

-- Submits (or idempotently re-submits) an attempt. The server scores
-- choice questions; free-text and recitation wait for a teacher.
--   p_attempt = {id, assessment_id, started_at, submitted_at, client_score,
--                answers: [{question_id, selected_option_ids, text_answer,
--                           media_asset_id}]}
create or replace function public.submit_attempt(p_attempt jsonb)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_id uuid := (p_attempt->>'id')::uuid;
  v_assessment assessments%rowtype;
  v_existing quiz_attempts%rowtype;
  v_answer jsonb;
  v_q assessment_questions%rowtype;
  v_selected uuid[];
  v_correct uuid[];
  v_is_correct boolean;
  v_score numeric := 0;
  v_max numeric := 0;
  v_needs_teacher boolean := false;
  v_status attempt_status;
  v_passed boolean;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  if v_id is null then raise exception 'attempt id required' using errcode = 'PT400'; end if;

  select * into v_existing from quiz_attempts where id = v_id;
  if found then
    if v_existing.user_id <> v_me then
      raise exception 'attempt id conflict' using errcode = 'PT409';
    end if;
    return public.attempt_result(v_id);
  end if;

  select * into v_assessment from assessments
  where id = (p_attempt->>'assessment_id')::uuid and status = 'published';
  if not found then raise exception 'assessment not found' using errcode = 'PT404'; end if;

  if not (
    (v_assessment.lesson_id is not null and app_private.can_read_lesson(v_assessment.lesson_id))
    or (v_assessment.lesson_id is null and app_private.is_enrolled(v_assessment.course_id))
  ) then
    raise exception 'assessment is locked' using errcode = 'PT403';
  end if;

  if v_assessment.max_attempts is not null and (
    select count(*) from quiz_attempts
    where assessment_id = v_assessment.id and user_id = v_me
  ) >= v_assessment.max_attempts then
    raise exception 'no attempts remaining' using errcode = 'PT409';
  end if;

  insert into quiz_attempts (id, assessment_id, user_id, status, started_at, submitted_at, client_score)
  values (v_id, v_assessment.id, v_me, 'submitted',
          coalesce((p_attempt->>'started_at')::timestamptz, now()),
          least(coalesce((p_attempt->>'submitted_at')::timestamptz, now()), now()),
          (p_attempt->>'client_score')::numeric);

  for v_q in select * from assessment_questions where assessment_id = v_assessment.id loop
    v_max := v_max + v_q.points;
    select a into v_answer
    from jsonb_array_elements(coalesce(p_attempt->'answers', '[]')) a
    where (a->>'question_id')::uuid = v_q.id
    limit 1;

    v_selected := coalesce(
      (select array_agg(x::uuid) from jsonb_array_elements_text(v_answer->'selected_option_ids') x),
      '{}');

    if v_q.question_type in ('single_choice', 'multiple_choice', 'true_false')
       and v_assessment.grading = 'auto' then
      select coalesce(array_agg(id order by id), '{}') into v_correct
      from assessment_options where question_id = v_q.id and is_correct;
      v_is_correct := (select coalesce(array_agg(s order by s), '{}') from unnest(v_selected) s) = v_correct
                      and cardinality(v_correct) > 0;
      if v_is_correct then v_score := v_score + v_q.points; end if;
    else
      v_is_correct := null;
      v_needs_teacher := true;
    end if;

    if v_answer is not null then
      insert into learner_answers (attempt_id, question_id, selected_option_ids, text_answer,
                                   media_asset_id, is_correct, points_awarded)
      values (v_id, v_q.id, v_selected, v_answer->>'text_answer',
              (v_answer->>'media_asset_id')::uuid, v_is_correct,
              case when v_is_correct is null then null
                   when v_is_correct then v_q.points else 0 end);
    end if;
  end loop;

  if v_needs_teacher then
    v_status := 'submitted';
  else
    v_status := 'graded';
    v_passed := v_max = 0 or (v_score / v_max * 100) >= v_assessment.pass_mark_percent;
  end if;

  update quiz_attempts set
    status = v_status,
    score = case when v_needs_teacher then null else v_score end,
    max_score = v_max,
    passed = v_passed,
    graded_at = case when v_needs_teacher then null else now() end
  where id = v_id;

  return public.attempt_result(v_id);
end;
$$;

-- Result as the learner may see it. Per-question correctness is revealed
-- for practice quizzes only; graded ones show just the overall result.
create or replace function public.attempt_result(p_attempt_id uuid)
returns jsonb
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select jsonb_build_object(
    'id', t.id, 'assessment_id', t.assessment_id, 'status', t.status,
    'score', t.score, 'max_score', t.max_score, 'passed', t.passed,
    'client_score', t.client_score, 'submitted_at', t.submitted_at,
    'teacher_feedback', t.teacher_feedback,
    'answers', case when a.kind = 'practice'
      then (select coalesce(jsonb_agg(jsonb_build_object(
              'question_id', la.question_id, 'is_correct', la.is_correct,
              'points_awarded', la.points_awarded,
              'teacher_feedback', la.teacher_feedback)), '[]')
            from learner_answers la where la.attempt_id = t.id)
      else '[]'::jsonb end)
  from quiz_attempts t
  join assessments a on a.id = t.assessment_id
  where t.id = p_attempt_id
    and (t.user_id = app_private.current_user_id()
         or app_private.is_course_staff(a.course_id))
$$;

-- Teacher grades the free-text / recitation parts of an attempt.
--   p_grades = [{question_id, points, feedback}]
create or replace function public.grade_attempt(
  p_attempt_id uuid, p_grades jsonb, p_feedback text default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_attempt quiz_attempts%rowtype;
  v_assessment assessments%rowtype;
  v_g jsonb;
  v_score numeric;
begin
  select * into v_attempt from quiz_attempts where id = p_attempt_id;
  if not found then raise exception 'attempt not found' using errcode = 'PT404'; end if;
  select * into v_assessment from assessments where id = v_attempt.assessment_id;
  if not app_private.is_course_staff(v_assessment.course_id) then
    raise exception 'staff only' using errcode = 'PT403';
  end if;

  for v_g in select * from jsonb_array_elements(coalesce(p_grades, '[]')) loop
    insert into learner_answers (attempt_id, question_id, points_awarded, teacher_feedback, is_correct)
    select p_attempt_id, q.id,
           least(greatest((v_g->>'points')::numeric, 0), q.points),
           v_g->>'feedback',
           (v_g->>'points')::numeric >= q.points
    from assessment_questions q
    where q.id = (v_g->>'question_id')::uuid and q.assessment_id = v_assessment.id
    on conflict (attempt_id, question_id) do update set
      points_awarded = excluded.points_awarded,
      teacher_feedback = excluded.teacher_feedback,
      is_correct = excluded.is_correct;
  end loop;

  select coalesce(sum(points_awarded), 0) into v_score
  from learner_answers where attempt_id = p_attempt_id;

  update quiz_attempts set
    status = 'graded', score = v_score,
    passed = max_score = 0 or v_score / max_score * 100 >= v_assessment.pass_mark_percent,
    graded_by = app_private.current_user_id(), graded_at = now(),
    teacher_feedback = coalesce(p_feedback, teacher_feedback)
  where id = p_attempt_id;

  return public.attempt_result(p_attempt_id);
end;
$$;

-- ================================================================ admin ==

create or replace function public.set_user_role(p_user_id uuid, p_role app_role)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_user users%rowtype;
begin
  if not app_private.is_admin() then
    raise exception 'administrators only' using errcode = 'PT403';
  end if;
  if p_user_id = app_private.current_user_id() and p_role <> 'admin' then
    raise exception 'you cannot remove your own administrator role' using errcode = 'PT409';
  end if;
  perform set_config('sidra.role_change', 'allowed', true);
  update users set role = p_role where id = p_user_id returning * into v_user;
  if not found then raise exception 'user not found' using errcode = 'PT404'; end if;
  return jsonb_build_object('id', v_user.id, 'role', v_user.role);
end;
$$;

create or replace function public.set_course_status(p_course_id uuid, p_status publish_status)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v_course courses%rowtype;
begin
  if not app_private.is_course_staff(p_course_id, true) then
    raise exception 'curriculum editors only' using errcode = 'PT403';
  end if;
  update courses set
    status = p_status,
    content_version = content_version + 1,
    published_at = case when p_status = 'published' then coalesce(published_at, now()) else published_at end
  where id = p_course_id returning * into v_course;
  return to_jsonb(v_course);
end;
$$;

-- ================================================================ media ==

create or replace function app_private.can_read_media(p_asset_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select
    app_private.current_app_role() in ('teacher', 'admin')
    or exists (select 1 from media_assets m where m.id = p_asset_id
               and m.uploaded_by = app_private.current_user_id())
    or exists (select 1 from courses c where c.thumbnail_asset_id = p_asset_id and c.status = 'published')
    or exists (select 1 from books b where b.cover_asset_id = p_asset_id and b.status = 'published')
    or exists (select 1 from lesson_content_blocks b
               where b.media_asset_id = p_asset_id and app_private.can_read_lesson(b.lesson_id))
    or exists (select 1 from assessment_questions q join assessments a on a.id = q.assessment_id
               where q.prompt_media_asset_id = p_asset_id
                 and a.lesson_id is not null and app_private.can_read_lesson(a.lesson_id))
    or exists (select 1 from lesson_reviews r
               where r.feedback_audio_asset_id = p_asset_id
                 and r.user_id = app_private.current_user_id())
$$;

-- Returns a delivery URL for an asset the caller may see. Private
-- ('authenticated') assets get a Cloudinary signed URL computed here, so the
-- API secret never leaves the database.
create or replace function public.media_url(
  p_asset_id uuid, p_transformation text default null)
returns text
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_m media_assets%rowtype;
  v_cloud text := app_private.setting('cloudinary_cloud_name');
  v_secret text := app_private.setting('cloudinary_api_secret');
  v_source text;
  v_to_sign text;
  v_sig text := '';
  v_version text := '';
begin
  if app_private.current_user_id() is null then
    raise exception 'not signed in' using errcode = 'PT401';
  end if;
  select * into v_m from media_assets where id = p_asset_id;
  if not found then raise exception 'media not found' using errcode = 'PT404'; end if;
  if not app_private.can_read_media(p_asset_id) then
    raise exception 'media is locked' using errcode = 'PT403';
  end if;
  if v_cloud is null then
    raise exception 'media service not configured' using errcode = 'PT503';
  end if;
  if p_transformation is not null and p_transformation !~ '^[a-z0-9_,:./-]+$' then
    raise exception 'invalid transformation' using errcode = 'PT400';
  end if;

  v_source := v_m.public_id || coalesce('.' || v_m.format, '');
  if v_m.version is not null then v_version := 'v' || v_m.version || '/'; end if;

  if v_m.delivery = 'authenticated' then
    if v_secret is null then
      raise exception 'media signing not configured' using errcode = 'PT503';
    end if;
    v_to_sign := concat_ws('/', p_transformation, v_source);
    v_sig := 's--' || substr(
      translate(encode(digest(v_to_sign || v_secret, 'sha1'), 'base64'), '+/', '-_'),
      1, 8) || '--/';
  end if;

  return format('https://res.cloudinary.com/%s/%s/%s/%s%s%s%s',
    v_cloud, v_m.resource_type, v_m.delivery, v_sig,
    coalesce(p_transformation || '/', ''), v_version, v_source);
end;
$$;

-- Parameters for a signed direct upload to Cloudinary. Staff may upload
-- anywhere under sidra/; learners only into their own submissions folder
-- (e.g. recitation recordings).
create or replace function public.sign_media_upload(p_folder text default null)
returns jsonb
language plpgsql volatile security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_folder text;
  v_ts text := extract(epoch from now())::bigint::text;
  v_secret text := app_private.setting('cloudinary_api_secret');
  v_to_sign text;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  if v_secret is null then
    raise exception 'media signing not configured' using errcode = 'PT503';
  end if;
  if app_private.current_app_role() in ('teacher', 'admin') then
    v_folder := 'sidra/' || coalesce(nullif(regexp_replace(p_folder, '[^a-z0-9_/-]', '', 'g'), ''), 'content');
  else
    v_folder := 'sidra/submissions/' || v_me;
  end if;

  -- Cloudinary: sha1 of alphabetically sorted params + secret, hex.
  v_to_sign := format('folder=%s&timestamp=%s&type=authenticated', v_folder, v_ts);
  return jsonb_build_object(
    'cloud_name', app_private.setting('cloudinary_cloud_name'),
    'api_key', app_private.setting('cloudinary_api_key'),
    'folder', v_folder, 'timestamp', v_ts, 'type', 'authenticated',
    'signature', encode(digest(v_to_sign || v_secret, 'sha1'), 'hex'));
end;
$$;
