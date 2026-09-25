-- 0005 Row Level Security, views and grants for the Neon Data API.
--
-- Roles (created by Neon when the Data API is enabled):
--   authenticated  requests carrying a valid Clerk JWT
--   anonymous      requests without a token — granted NOTHING
--
-- Rule of thumb: learners read through RLS; every write that affects
-- access, progress or grading goes through a SECURITY DEFINER function
-- in 0004, never a direct table write.

create or replace function app_private.can_read_assessment(p_assessment_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (
    select 1 from assessments a
    where a.id = p_assessment_id
      and (
        app_private.is_course_staff(a.course_id)
        or (a.status = 'published' and (
              (a.lesson_id is not null and app_private.can_read_lesson(a.lesson_id))
              or (a.lesson_id is null and app_private.is_enrolled(a.course_id))))
      )
  )
$$;

-- Course is visible in the catalogue (published) or to its staff.
create or replace function app_private.can_see_course(p_course_id uuid)
returns boolean
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select exists (select 1 from courses where id = p_course_id and status = 'published')
         or app_private.is_course_staff(p_course_id)
$$;

-- ============================================================ enable RLS ==

do $$
declare t text;
begin
  foreach t in array array[
    'users', 'learner_profiles', 'media_assets', 'courses', 'course_units',
    'books', 'book_structures', 'book_structure_levels', 'course_books',
    'curriculum_nodes', 'lessons', 'lesson_content_blocks', 'assessments',
    'assessment_questions', 'assessment_options', 'course_staff',
    'course_enrolments', 'lesson_unlocks', 'lesson_reviews',
    'learner_progress', 'quiz_attempts', 'learner_answers', 'sync_operations'
  ] loop
    execute format('alter table %I enable row level security', t);
  end loop;
end $$;

-- ================================================================ people ==

create policy users_read on users for select to authenticated using (
  id = app_private.current_user_id()
  or app_private.is_admin()
  or exists (select 1 from course_enrolments e
             where e.user_id = users.id and app_private.is_course_staff(e.course_id))
  or exists (select 1 from course_staff s where s.user_id = users.id)  -- teacher names
);
create policy users_update_self on users for update to authenticated
  using (id = app_private.current_user_id())
  with check (id = app_private.current_user_id());

create policy learner_profiles_read on learner_profiles for select to authenticated using (
  user_id = app_private.current_user_id()
  or app_private.is_admin()
  or exists (select 1 from course_enrolments e
             where e.user_id = learner_profiles.user_id and app_private.is_course_staff(e.course_id))
);
create policy learner_profiles_update_self on learner_profiles for update to authenticated
  using (user_id = app_private.current_user_id())
  with check (user_id = app_private.current_user_id());

-- ================================================================= media ==

create policy media_read on media_assets for select to authenticated
  using (app_private.can_read_media(id));
create policy media_insert on media_assets for insert to authenticated with check (
  uploaded_by = app_private.current_user_id()
  and (
    app_private.current_app_role() in ('teacher', 'admin')
    or public_id like 'sidra/submissions/' || app_private.current_user_id() || '/%'
  )
);
create policy media_admin on media_assets for update to authenticated
  using (app_private.is_admin()) with check (app_private.is_admin());
create policy media_admin_delete on media_assets for delete to authenticated
  using (app_private.is_admin());

-- ============================================================ curriculum ==

create policy courses_read on courses for select to authenticated
  using (status = 'published' or app_private.is_course_staff(id));
create policy courses_insert on courses for insert to authenticated
  with check (app_private.is_admin());
create policy courses_update on courses for update to authenticated
  using (app_private.is_course_staff(id, true))
  with check (app_private.is_course_staff(id, true));
create policy courses_delete on courses for delete to authenticated
  using (app_private.is_admin());

-- Units, nodes and lessons: outline readable when published; editors write.
do $$
declare t text;
begin
  foreach t in array array['course_units', 'curriculum_nodes', 'lessons'] loop
    execute format($f$
      create policy %1$s_read on %1$I for select to authenticated using (
        (status = 'published' and exists (
           select 1 from courses c where c.id = %1$I.course_id and c.status = 'published'))
        or app_private.is_course_staff(course_id));
      create policy %1$s_write on %1$I for all to authenticated
        using (app_private.is_course_staff(course_id, true))
        with check (app_private.is_course_staff(course_id, true));
    $f$, t);
  end loop;
end $$;

create policy books_read on books for select to authenticated
  using (status = 'published' or app_private.current_app_role() in ('teacher', 'admin'));
create policy books_write on books for all to authenticated
  using (app_private.is_admin()) with check (app_private.is_admin());

create policy book_structures_read on book_structures for select to authenticated
  using (exists (select 1 from books b where b.id = book_id));  -- inherits books RLS
create policy book_structures_write on book_structures for all to authenticated
  using (app_private.is_admin()) with check (app_private.is_admin());

create policy book_levels_read on book_structure_levels for select to authenticated
  using (exists (select 1 from book_structures s where s.id = structure_id));
create policy book_levels_write on book_structure_levels for all to authenticated
  using (app_private.is_admin()) with check (app_private.is_admin());

create policy course_books_read on course_books for select to authenticated
  using (app_private.can_see_course(course_id));
create policy course_books_write on course_books for all to authenticated
  using (app_private.is_course_staff(course_id, true))
  with check (app_private.is_course_staff(course_id, true));

-- CONTENT is gated by unlocks — this is what enforces teacher gating.
create policy blocks_read on lesson_content_blocks for select to authenticated
  using (app_private.can_read_lesson(lesson_id));
create policy blocks_write on lesson_content_blocks for all to authenticated
  using (app_private.is_course_staff((select course_id from lessons where id = lesson_id), true))
  with check (app_private.is_course_staff((select course_id from lessons where id = lesson_id), true));

-- =========================================================== assessments ==

create policy assessments_read on assessments for select to authenticated
  using (app_private.can_read_assessment(id));
create policy assessments_write on assessments for all to authenticated
  using (app_private.is_course_staff(course_id, true))
  with check (app_private.is_course_staff(course_id, true));

create policy questions_read on assessment_questions for select to authenticated
  using (app_private.can_read_assessment(assessment_id));
create policy questions_write on assessment_questions for all to authenticated
  using (app_private.is_course_staff((select course_id from assessments where id = assessment_id), true))
  with check (app_private.is_course_staff((select course_id from assessments where id = assessment_id), true));

-- Options carry is_correct: staff only on the base table. Learners use the
-- learner_assessment_options view below.
create policy options_staff on assessment_options for all to authenticated
  using (app_private.is_course_staff((
    select a.course_id from assessment_questions q join assessments a on a.id = q.assessment_id
    where q.id = question_id), true))
  with check (app_private.is_course_staff((
    select a.course_id from assessment_questions q join assessments a on a.id = q.assessment_id
    where q.id = question_id), true));
create policy options_staff_read on assessment_options for select to authenticated
  using (app_private.is_course_staff((
    select a.course_id from assessment_questions q join assessments a on a.id = q.assessment_id
    where q.id = question_id)));

-- Correct answers are exposed only for practice quizzes (so they can be
-- scored offline). Graded quizzes are always scored by submit_attempt().
create view public.learner_assessment_options with (security_barrier) as
  select o.id, o.question_id, o.position, o.label,
         case when a.kind = 'practice' then o.is_correct end as is_correct
  from assessment_options o
  join assessment_questions q on q.id = o.question_id
  join assessments a on a.id = q.assessment_id
  where app_private.can_read_assessment(a.id);

-- ===================================================== enrolment & gating ==

create policy course_staff_read on course_staff for select to authenticated using (
  user_id = app_private.current_user_id()
  or app_private.is_course_staff(course_id)
  or app_private.can_see_course(course_id)
);
create policy course_staff_admin on course_staff for all to authenticated
  using (app_private.is_admin()) with check (app_private.is_admin());

create policy enrolments_read on course_enrolments for select to authenticated using (
  user_id = app_private.current_user_id() or app_private.is_course_staff(course_id));

create policy unlocks_read on lesson_unlocks for select to authenticated using (
  user_id = app_private.current_user_id() or app_private.is_course_staff(course_id));

create policy reviews_read on lesson_reviews for select to authenticated using (
  user_id = app_private.current_user_id() or app_private.is_course_staff(course_id));

create policy progress_read on learner_progress for select to authenticated using (
  user_id = app_private.current_user_id() or app_private.is_course_staff(course_id));

create policy attempts_read on quiz_attempts for select to authenticated using (
  user_id = app_private.current_user_id()
  or app_private.is_course_staff((select course_id from assessments where id = assessment_id)));

-- Per-answer correctness is staff-only; learners use attempt_result().
create policy answers_staff_read on learner_answers for select to authenticated using (
  app_private.is_course_staff((
    select a.course_id from quiz_attempts t join assessments a on a.id = t.assessment_id
    where t.id = attempt_id)));

-- sync_operations: no policies → no direct access (functions only).

-- ================================================================ grants ==

revoke all on all tables in schema public from anonymous, authenticated;
revoke all on all functions in schema public from public, anonymous;
revoke all on all functions in schema app_private from public;
alter default privileges in schema public revoke execute on functions from public;
alter default privileges in schema app_private revoke execute on functions from public;

grant usage on schema public to authenticated;
-- Needed so RLS policies (evaluated as the caller) can call the helpers.
-- The schema is NOT exposed by the Data API and app_private.settings /
-- app_private.setting() stay inaccessible.
grant usage on schema app_private to authenticated;
grant execute on function
  app_private.clerk_id(),
  app_private.current_user_id(),
  app_private.current_app_role(),
  app_private.is_admin(),
  app_private.is_course_staff(uuid, boolean),
  app_private.is_enrolled(uuid),
  app_private.lesson_is_live(uuid),
  app_private.can_read_lesson(uuid),
  app_private.can_read_media(uuid),
  app_private.can_read_assessment(uuid),
  app_private.can_see_course(uuid),
  app_private.valid_block(content_block_type, jsonb, uuid, uuid)
to authenticated;

grant select on
  users, learner_profiles, media_assets, courses, course_units, books,
  book_structures, book_structure_levels, course_books, curriculum_nodes,
  lessons, lesson_content_blocks, assessments, assessment_questions,
  assessment_options, course_staff, course_enrolments, lesson_unlocks,
  lesson_reviews, learner_progress, quiz_attempts, learner_answers,
  learner_assessment_options
to authenticated;

-- Self-service profile edits (role/is_active are not grantable columns).
grant update (display_name, avatar_url) on users to authenticated;
grant update (preferred_locale, timezone, phone, guardian_name, guardian_phone)
  on learner_profiles to authenticated;

-- Curriculum authoring (RLS narrows these to admins / course editors).
grant insert, update, delete on
  course_units, curriculum_nodes, lessons, lesson_content_blocks,
  assessments, assessment_questions, assessment_options,
  books, book_structures, book_structure_levels, course_books, course_staff
to authenticated;
grant insert on courses to authenticated;
grant update (slug, title, subtitle, description, subject, difficulty, language,
              thumbnail_asset_id, access, price_amount, price_currency,
              progression, estimated_hours, learning_objectives, prerequisites)
  on courses to authenticated;
grant delete on courses to authenticated;
grant insert on media_assets to authenticated;
grant update (title, alt_text, downloadable) on media_assets to authenticated;
grant delete on media_assets to authenticated;

grant execute on function
  public.ensure_profile(text, text, text),
  public.enrol_in_course(uuid),
  public.grant_enrolment(uuid, uuid, uuid),
  public.set_enrolment_status(uuid, enrolment_status),
  public.unlock_lesson(uuid, uuid, text),
  public.revoke_lesson_unlock(uuid, uuid),
  public.review_lesson(uuid, uuid, review_outcome, numeric, text, boolean, uuid),
  public.course_lesson_order(uuid),
  public.record_progress(uuid, uuid, progress_status, jsonb, timestamptz),
  public.submit_attempt(jsonb),
  public.attempt_result(uuid),
  public.grade_attempt(uuid, jsonb, text),
  public.set_user_role(uuid, app_role),
  public.set_course_status(uuid, publish_status),
  public.media_url(uuid, text),
  public.sign_media_upload(text)
to authenticated;
