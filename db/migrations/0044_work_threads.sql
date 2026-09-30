-- 0044 Learner work as a thread, not a single hand-in.
--
-- What was wrong (audit, 2026-09-30): the tables already allowed many
-- attempts per learner (submissions.attempt), many files per attempt
-- (submission_files) and many reviews per attempt (submission_reviews).
-- The limits were in the functions and the app:
--   * submit_portion / submit_lesson_work / submit_work refused a new
--     attempt while the last one waited ("already sent; wait for your
--     teacher"), so a learner who noticed a mistake could not send again;
--   * every teacher answer had to be a final verdict (review_attempt), so a
--     teacher could not send a voice note, then a text, then decide;
--   * a learner could not answer the teacher except by a whole new attempt;
--   * nothing recorded WHAT part of the work (line, ayah, exercise) an
--     attempt was for.
--
-- The thread of one learner's work on one portion / lesson / assignment is
-- all their submissions (attempts) for it, in order, with:
--   * submission_files: the attempt's attachments (unchanged);
--   * submission_reviews: the teacher's verdicts (unchanged);
--   * work_messages (new): everything said in between — teacher voice or
--     text or a library correction, learner replies — without a verdict;
--   * submissions.target (new): what the attempt is for.
-- Nothing is ever overwritten: a newer attempt SUPERSEDES a waiting older
-- one (kept, shown, no longer counted as waiting). Existing submissions and
-- reviews need no conversion: each is already an attempt / verdict of its
-- thread.

-- (The 'superseded' status was added by 0043: a new enum value can't be
-- used in the transaction that adds it.)

-- ------------------------------------------------------------ targets --

alter table submissions add column target jsonb;

-- What part of the work something is about. One of:
--   {"kind":"whole"}
--   {"kind":"block","block_id":…,"start":0,"end":12,"quote":"…"}   text range in a lesson block
--   {"kind":"ayah","surah":2,"ayah_start":255,"ayah_end":255}
--   {"kind":"page_line","page":14,"line":3,"line_end":3}
--   {"kind":"exercise","exercise":"Question 4"}
--   {"kind":"other"}
-- plus an optional human "label" ("Page 14, line 3").
create or replace function app_private.valid_work_target(t jsonb)
returns boolean
language sql immutable
as $$
  select t is null or (
    jsonb_typeof(t) = 'object'
    and t->>'kind' in ('whole', 'block', 'ayah', 'page_line', 'exercise', 'other')
    and length(coalesce(t->>'label', '')) <= 200
    and length(coalesce(t->>'quote', '')) <= 1000
    and length(coalesce(t->>'exercise', '')) <= 200
    and case t->>'kind'
      when 'block' then
        (t->>'block_id') ~ '^[0-9a-f-]{36}$'
        and coalesce(t->>'start', '0') ~ '^\d{1,7}$' and coalesce(t->>'end', '0') ~ '^\d{1,7}$'
        and coalesce((t->>'start')::int, 0) <= coalesce((t->>'end')::int, coalesce((t->>'start')::int, 0))
      when 'ayah' then
        (t->>'surah') ~ '^\d{1,3}$' and (t->>'surah')::int between 1 and 114
        and (t->>'ayah_start') ~ '^\d{1,3}$' and (t->>'ayah_start')::int between 1 and 286
        and coalesce(t->>'ayah_end', t->>'ayah_start') ~ '^\d{1,3}$'
        and coalesce((t->>'ayah_end')::int, (t->>'ayah_start')::int) between (t->>'ayah_start')::int and 286
      when 'page_line' then
        (t->>'page') ~ '^\d{1,4}$' and (t->>'page')::int >= 1
        and coalesce(t->>'line', '1') ~ '^\d{1,3}$' and coalesce((t->>'line')::int, 1) >= 1
        and coalesce(t->>'line_end', t->>'line', '1') ~ '^\d{1,3}$'
        and coalesce((t->>'line_end')::int, (t->>'line')::int, 1) >= coalesce((t->>'line')::int, 1)
      when 'exercise' then length(trim(coalesce(t->>'exercise', ''))) > 0
      else true end)
$$;

alter table submissions add constraint submissions_target_valid
  check (app_private.valid_work_target(target));

-- --------------------------------------------------- the conversation --

create table work_messages (
  -- client-generated: a reply sent twice (retry, flaky network) is stored once
  id uuid primary key,
  submission_id uuid not null references submissions (id) on delete cascade,
  author_id uuid references users (id) on delete set null,
  author_role text not null check (author_role in ('learner', 'teacher')),
  kind text not null check (kind in ('text', 'voice', 'file', 'correction')),
  body text check (length(body) <= 4000),
  media_asset_id uuid references media_assets (id) on delete restrict,
  correction_id uuid references corrections (id) on delete set null,
  target jsonb check (app_private.valid_work_target(target)),
  created_at timestamptz not null default now(),
  check (case kind
           when 'text' then length(trim(coalesce(body, ''))) > 0
           when 'voice' then media_asset_id is not null
           when 'file' then media_asset_id is not null
           when 'correction' then correction_id is not null end),
  check (kind <> 'correction' or author_role = 'teacher')
);
create index work_messages_submission on work_messages (submission_id, created_at);
create index work_messages_media on work_messages (media_asset_id) where media_asset_id is not null;

alter table work_messages enable row level security;
-- Read-only to the app; written only through work_reply(). Immutable.
create policy work_messages_read on work_messages for select to public using (
  exists (select 1 from submissions s where s.id = submission_id
          and (s.user_id = app_private.current_user_id()
               or app_private.teaches(s.course_id, s.lesson_id)
               or (s.portion_id is not null and app_private.teaches_portion(s.portion_id)))));
grant select on work_messages to authenticated, sidra_app;
create trigger work_messages_audit after insert on work_messages
  for each row execute function app_private.audit();

-- Who may act on a submission as its learner or as its teacher.
create or replace function app_private.work_role(s submissions)
returns text
language sql stable security definer
set search_path = public, app_private, pg_temp
as $$
  select case
    when s.user_id = app_private.current_user_id() then 'learner'
    when app_private.teaches(s.course_id, s.lesson_id)
         or (s.portion_id is not null and app_private.teaches_portion(s.portion_id)) then 'teacher'
  end
$$;

-- ----------------------------------------------- media access (voice) --

-- Media in a work message is as private as the work itself: the learner and
-- the people who teach it. (Checked before the general rules, which would
-- let any content uploader read it.)
do $$
declare v_src text;
begin
  v_src := pg_get_functiondef('app_private.can_read_media(uuid)'::regprocedure);
  if position('when exists (select 1 from submission_files f where f.media_asset_id = p_asset_id) then' in v_src) = 0 then
    raise exception 'can_read_media changed; update 0044';
  end if;
  execute replace(v_src,
    'when exists (select 1 from submission_files f where f.media_asset_id = p_asset_id) then',
    'when exists (select 1 from work_messages w where w.media_asset_id = p_asset_id) then
      exists (select 1 from work_messages w join submissions s on s.id = w.submission_id
              where w.media_asset_id = p_asset_id and app_private.work_role(s) is not null)
    when exists (select 1 from submission_files f where f.media_asset_id = p_asset_id) then');
  -- Library corrections sent as a message reach that learner too.
  v_src := pg_get_functiondef('app_private.can_read_media(uuid)'::regprocedure);
  if position('                                 where r.correction_id = c.id
                                   and s.user_id = app_private.current_user_id())))' in v_src) = 0 then
    raise exception 'can_read_media corrections changed; update 0044';
  end if;
  execute replace(v_src, '                                 where r.correction_id = c.id
                                   and s.user_id = app_private.current_user_id())))',
    '                                 where r.correction_id = c.id
                                   and s.user_id = app_private.current_user_id())
                      or exists (select 1 from work_messages w join submissions s on s.id = w.submission_id
                                 where w.correction_id = c.id
                                   and s.user_id = app_private.current_user_id())))');
end $$;

-- ------------------------------------- a newer attempt may follow one --

-- Older attempts still waiting are superseded (kept, no longer "waiting").
create or replace function app_private.supersede_waiting(
  p_user uuid, p_portion uuid, p_lesson uuid, p_assignment uuid, p_except uuid)
returns void
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
begin
  update submissions set status = 'superseded', updated_at = now()
  where user_id = p_user and id <> p_except
    and status in ('submitted', 'received', 'under_review')
    and case when p_portion is not null then portion_id = p_portion
             when p_assignment is not null then assignment_id = p_assignment
             else lesson_id = p_lesson and portion_id is null and assignment_id is null end;
end;
$$;

do $$
declare v_src text;
begin
  -- portions
  v_src := pg_get_functiondef('public.submit_portion(uuid, uuid, text, jsonb)'::regprocedure);
  if position('  if v_pl.status in (''submitted'', ''under_review'') then
    raise exception ''already sent; wait for your teacher'' using errcode = ''PT409'';
  end if;' in v_src) = 0 then
    raise exception 'submit_portion changed; update 0044';
  end if;
  v_src := replace(v_src, '  if v_pl.status in (''submitted'', ''under_review'') then
    raise exception ''already sent; wait for your teacher'' using errcode = ''PT409'';
  end if;', '  -- (0043) a newer attempt may follow a waiting one');
  v_src := replace(v_src, '  update portion_learners set status = ''submitted'', attempts = attempts + 1,',
    '  perform app_private.supersede_waiting(v_me, v.id, null, null, v_sub.id);
  update portion_learners set status = ''submitted'', attempts = attempts + 1,');
  execute v_src;

  -- a lesson's own work
  v_src := pg_get_functiondef('public.submit_lesson_work(uuid, uuid, text, jsonb)'::regprocedure);
  if position('  if found and v_prev.status in (''submitted'', ''received'', ''under_review'') then
    raise exception ''already handed in; wait for your teacher'' using errcode = ''PT409'';
  end if;' in v_src) = 0 or position('returning * into v_sub;' in v_src) = 0 then
    raise exception 'submit_lesson_work changed; update 0044';
  end if;
  v_src := replace(v_src, '  if found and v_prev.status in (''submitted'', ''received'', ''under_review'') then
    raise exception ''already handed in; wait for your teacher'' using errcode = ''PT409'';
  end if;', '  -- (0043) a newer attempt may follow a waiting one');
  v_src := replace(v_src, 'returning * into v_sub;',
    'returning * into v_sub;
  perform app_private.supersede_waiting(v_me, null, p_lesson_id, null, v_sub.id);');
  execute v_src;

  -- assignments
  v_src := pg_get_functiondef('public.submit_work(uuid, uuid, text, jsonb)'::regprocedure);
  if position('  if found and v_prev.status not in (''resubmission_requested'', ''returned'') then
    raise exception ''already handed in; wait for your teacher'' using errcode = ''PT409'';
  end if;' in v_src) = 0 or position('returning * into v_sub;' in v_src) = 0 then
    raise exception 'submit_work changed; update 0044';
  end if;
  v_src := replace(v_src, '  if found and v_prev.status not in (''resubmission_requested'', ''returned'') then
    raise exception ''already handed in; wait for your teacher'' using errcode = ''PT409'';
  end if;', '  if found and v_prev.status = ''reviewed'' then
    raise exception ''this work was already marked'' using errcode = ''PT409'';
  end if;');
  v_src := replace(v_src, 'returning * into v_sub;',
    'returning * into v_sub;
  perform app_private.supersede_waiting(v_me, null, null, p_assignment_id, v_sub.id);');
  execute v_src;
end $$;

-- One entry point for any work, with what it is for. p_kind: portion |
-- lesson | assignment. Idempotent on p_submission_id (the app's id).
create or replace function public.send_work(
  p_submission_id uuid, p_kind text, p_target_id uuid, p_text text default null,
  p_files jsonb default '[]', p_target jsonb default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare v jsonb;
begin
  if not app_private.valid_work_target(p_target) then
    raise exception 'unknown target' using errcode = 'PT422';
  end if;
  if p_target->>'kind' = 'block' and not exists (
       select 1 from lesson_content_blocks b where b.id = (p_target->>'block_id')::uuid
         and app_private.can_read_lesson(b.lesson_id)) then
    raise exception 'that part of the lesson was not found' using errcode = 'PT404';
  end if;
  v := case p_kind
         when 'portion' then public.submit_portion(p_submission_id, p_target_id, p_text, p_files)
         when 'lesson' then public.submit_lesson_work(p_submission_id, p_target_id, p_text, p_files)
         when 'assignment' then public.submit_work(p_submission_id, p_target_id, p_text, p_files)
       end;
  if v is null then raise exception 'unknown kind of work' using errcode = 'PT422'; end if;
  -- (only on the first send; a retry returns the stored attempt unchanged)
  update submissions set target = p_target
  where id = p_submission_id and user_id = app_private.current_user_id() and target is null
    and p_target is not null;
  return (select to_jsonb(s) from submissions s where s.id = p_submission_id);
end;
$$;

-- ------------------------------------------------ replies, both sides --

-- A reply on an attempt, from its learner or from a teacher, WITHOUT a
-- verdict (verdicts stay review_attempt). Teacher: text, voice, file, or a
-- library correction; p_save_as keeps a voice note in the library.
-- Learner: text, voice or file. Idempotent on p_id.
create or replace function public.work_reply(
  p_id uuid, p_submission_id uuid, p_kind text, p_body text default null,
  p_media_asset_id uuid default null, p_correction_id uuid default null,
  p_target jsonb default null, p_save_as jsonb default null)
returns jsonb
language plpgsql security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v submissions%rowtype;
  v_role text;
  v_msg work_messages%rowtype;
  v_correction uuid := p_correction_id;
  v_title text;
  v_t uuid;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  select * into v_msg from work_messages where id = p_id;
  if found then
    if v_msg.author_id is distinct from v_me then raise exception 'not yours' using errcode = 'PT403'; end if;
    return to_jsonb(v_msg);
  end if;
  select * into v from submissions where id = p_submission_id;
  v_role := case when found then app_private.work_role(v) end;
  if v_role is null then raise exception 'work not found' using errcode = 'PT404'; end if;
  if p_kind not in ('text', 'voice', 'file', 'correction')
     or (p_kind = 'correction' and v_role <> 'teacher') then
    raise exception 'not allowed' using errcode = 'PT403';
  end if;
  if not app_private.valid_work_target(p_target) then
    raise exception 'unknown target' using errcode = 'PT422';
  end if;
  if p_media_asset_id is not null and not exists (
       select 1 from media_assets where id = p_media_asset_id and uploaded_by = v_me) then
    raise exception 'files must be your own uploads' using errcode = 'PT403';
  end if;
  if v_correction is not null and not exists (
       select 1 from corrections where id = v_correction and archived_at is null) then
    raise exception 'correction not found' using errcode = 'PT404';
  end if;
  if p_save_as is not null and v_role = 'teacher' and p_kind = 'voice' then
    insert into corrections (title, explanation, category_id, media_asset_id, language, tags,
                             course_id, lesson_id, created_by)
    values (coalesce(nullif(trim(p_save_as->>'title'), ''), 'Correction'),
            nullif(trim(coalesce(p_save_as->>'explanation', p_body)), ''),
            nullif(p_save_as->>'category_id', '')::uuid, p_media_asset_id,
            nullif(p_save_as->>'language', ''),
            coalesce(array(select jsonb_array_elements_text(p_save_as->'tags')), '{}'),
            v.course_id, v.lesson_id, v_me)
    returning id into v_correction;
  end if;

  insert into work_messages (id, submission_id, author_id, author_role, kind, body,
                             media_asset_id, correction_id, target)
  values (p_id, v.id, v_me, v_role, p_kind, nullif(trim(p_body), ''),
          p_media_asset_id, v_correction, p_target)
  returning * into v_msg;
  if p_kind = 'correction' then
    update corrections set use_count = use_count + 1 where id = v_correction;
  end if;

  v_title := coalesce((select title from teaching_portions where id = v.portion_id),
                      (select title from assignments where id = v.assignment_id),
                      (select title from lessons where id = v.lesson_id), 'Your work');
  if v_role = 'teacher' then
    -- The teacher is on it: waiting work is now under review.
    update submissions set status = 'under_review', updated_at = now()
    where id = v.id and status in ('submitted', 'received');
    update portion_learners set status = 'under_review'
    where portion_id = v.portion_id and user_id = v.user_id and status = 'submitted';
    perform app_private.notify(v.user_id, 'work_reply', v_title,
      'Your teacher responded to your work.',
      jsonb_build_object('portion_id', v.portion_id, 'lesson_id', v.lesson_id,
                         'course_id', v.course_id, 'assignment_id', v.assignment_id,
                         'submission_id', v.id));
  else
    -- The same people a new attempt would reach, and anyone who already
    -- answered this attempt.
    for v_t in
      select t from app_private.portion_teachers(v.portion_id) t where v.portion_id is not null
      union
      select t from app_private.lesson_teachers(v.lesson_id) t
      where v.portion_id is null and v.lesson_id is not null
      union
      select rv.reviewer_id from submission_reviews rv where rv.submission_id = v.id
      union
      select w.author_id from work_messages w where w.submission_id = v.id and w.author_role = 'teacher'
    loop
      continue when v_t is null;
      perform app_private.notify(v_t, 'work_reply',
        (select display_name from users where id = v_me) || ' · ' || v_title,
        'Replied to your correction.',
        jsonb_build_object('portion_id', v.portion_id, 'lesson_id', v.lesson_id,
                           'course_id', v.course_id, 'submission_id', v.id, 'learner_id', v.user_id));
    end loop;
  end if;
  return to_jsonb(v_msg);
end;
$$;

-- ------------------------------------------------------------ the thread --

-- Everything in one learner's work on one portion / lesson / assignment,
-- oldest first: attempts (with files and target), verdicts and replies.
-- p_user_id: the learner (teachers); defaults to me.
create or replace function public.work_thread(
  p_kind text, p_target_id uuid, p_user_id uuid default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, app_private, pg_temp
as $$
declare
  v_me uuid := app_private.current_user_id();
  v_user uuid := coalesce(p_user_id, v_me);
  v_ids uuid[];
  v_role text;
begin
  if v_me is null then raise exception 'not signed in' using errcode = 'PT401'; end if;
  select array_agg(s.id order by s.attempt) into v_ids from submissions s
  where s.user_id = v_user
    and case p_kind when 'portion' then s.portion_id = p_target_id
                    when 'assignment' then s.assignment_id = p_target_id
                    when 'lesson' then s.lesson_id = p_target_id and s.portion_id is null
                                       and s.assignment_id is null
                    else false end;
  -- Authorised by the attempts themselves (never by the ids passed in).
  if v_user <> v_me then
    if v_ids is null or exists (select 1 from submissions s where s.id = any (v_ids)
                                and app_private.work_role(s) is distinct from 'teacher') then
      raise exception 'work not found' using errcode = 'PT404';
    end if;
    v_role := 'teacher';
  else
    v_role := 'learner';
  end if;

  return jsonb_build_object(
    'kind', p_kind, 'target_id', p_target_id, 'role', v_role,
    'learner', (select jsonb_build_object('id', u.id, 'name', u.display_name,
                                          'avatar_url', u.avatar_url)
                from users u where u.id = v_user),
    'participation', (select to_jsonb(pl) from portion_learners pl
                      where p_kind = 'portion' and pl.portion_id = p_target_id and pl.user_id = v_user),
    'events', coalesce((select jsonb_agg(e order by ts, ord) from (
        select s.submitted_at as ts, 0 as ord, jsonb_build_object(
          'type', 'attempt', 'at', s.submitted_at,
          'submission_id', s.id, 'attempt', s.attempt, 'status', s.status,
          'text', s.text_answer, 'target', s.target,
          'files', (select coalesce(jsonb_agg(jsonb_build_object(
                      'media_asset_id', f.media_asset_id, 'file_name', f.file_name,
                      'mime_type', f.mime_type, 'bytes', f.bytes,
                      'kind', (select kind from media_assets where id = f.media_asset_id))
                      order by f.position), '[]')
                    from submission_files f where f.submission_id = s.id)) e
        from submissions s where s.id = any (coalesce(v_ids, '{}'))
        union all
        select rv.created_at, 1, jsonb_build_object(
          'type', 'review', 'at', rv.created_at,
          'id', rv.id, 'submission_id', rv.submission_id, 'result', rv.result,
          'feedback', rv.feedback, 'score', rv.score,
          'author', (select display_name from users where id = rv.reviewer_id),
          'correction_asset_id', rv.correction_asset_id,
          'correction', (select jsonb_build_object('id', c.id, 'title', c.title,
                                 'explanation', c.explanation, 'media_asset_id', c.media_asset_id)
                         from corrections c where c.id = rv.correction_id))
        from submission_reviews rv where rv.submission_id = any (coalesce(v_ids, '{}'))
        union all
        select w.created_at, 2, jsonb_build_object(
          'type', 'message', 'at', w.created_at,
          'id', w.id, 'submission_id', w.submission_id, 'author_role', w.author_role,
          'author', (select display_name from users where id = w.author_id),
          'kind', w.kind, 'body', w.body, 'media_asset_id', w.media_asset_id,
          'media_kind', (select kind from media_assets where id = w.media_asset_id),
          'target', w.target,
          'correction', (select jsonb_build_object('id', c.id, 'title', c.title,
                                 'explanation', c.explanation, 'media_asset_id', c.media_asset_id)
                         from corrections c where c.id = w.correction_id))
        from work_messages w where w.submission_id = any (coalesce(v_ids, '{}'))
      ) q), '[]'));
end;
$$;

revoke all on function public.send_work(uuid, text, uuid, text, jsonb, jsonb),
  public.work_reply(uuid, uuid, text, text, uuid, uuid, jsonb, jsonb),
  public.work_thread(text, uuid, uuid) from public, anonymous;
grant execute on function public.send_work(uuid, text, uuid, text, jsonb, jsonb),
  public.work_reply(uuid, uuid, text, text, uuid, uuid, jsonb, jsonb),
  public.work_thread(text, uuid, uuid) to authenticated, sidra_app;

select app_private.lock_down_functions();
