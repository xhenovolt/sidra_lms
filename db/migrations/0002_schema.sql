-- 0002 core schema.
--
-- Curriculum engine overview
--   course ─┬─ course_units (ordered)
--           └─ curriculum_nodes (tree; optional unit; optional book level)
--                 └─ lessons ── lesson_content_blocks (ordered, typed)
--   books ── book_structures ── book_structure_levels (depth 1..n)
--
-- A book's structure (e.g. Surah → Verse, Page → Lesson, Level → Unit →
-- Chapter) is DATA: admins define levels, and nodes created from that book
-- reference a level. The app renders whatever tree it receives, so a new
-- structure never needs an app release.

-- =============================================================== people ==

create table users (
  id uuid primary key default gen_random_uuid(),
  clerk_user_id text not null unique,
  display_name text,
  email text,
  avatar_url text,
  role app_role not null default 'learner',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table learner_profiles (
  user_id uuid primary key references users (id) on delete cascade,
  preferred_locale text not null default 'en' check (preferred_locale ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  timezone text,
  phone text,
  guardian_name text,
  guardian_phone text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ================================================================ media ==

create table media_assets (
  id uuid primary key default gen_random_uuid(),
  provider text not null default 'cloudinary' check (provider = 'cloudinary'),
  kind media_kind not null,
  -- Cloudinary resource_type: image | video (video also covers audio) | raw
  resource_type text not null check (resource_type in ('image', 'video', 'raw')),
  delivery media_delivery not null default 'authenticated',
  public_id text not null,
  format text,
  version bigint,
  bytes bigint check (bytes is null or bytes >= 0),
  duration_seconds numeric(10, 2),
  width int,
  height int,
  title text,
  alt_text text,
  -- Offline download allowed (copyright / licensing decision per asset).
  downloadable boolean not null default true,
  uploaded_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (resource_type, delivery, public_id)
);

-- ============================================================ curriculum ==

create table courses (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  title text not null check (length(trim(title)) > 0),
  subtitle text,
  description text,
  subject text not null,
  difficulty difficulty_level not null default 'beginner',
  language text not null default 'en',
  thumbnail_asset_id uuid references media_assets (id) on delete set null,
  access course_access not null default 'free',
  price_amount numeric(12, 2) check (price_amount is null or price_amount >= 0),
  price_currency text check (price_currency is null or price_currency ~ '^[A-Z]{3}$'),
  progression progression_mode not null default 'teacher_gated',
  status publish_status not null default 'draft',
  estimated_hours numeric(6, 1) check (estimated_hours is null or estimated_hours > 0),
  learning_objectives text[] not null default '{}',
  prerequisites text,
  -- Bumped on every publish; clients compare to decide what to refresh.
  content_version int not null default 1,
  published_at timestamptz,
  created_by uuid references users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (access <> 'paid' or (price_amount is not null and price_currency is not null))
);

create table course_units (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses (id) on delete cascade,
  title text not null,
  description text,
  position int not null check (position >= 0),
  learning_objectives text[] not null default '{}',
  status publish_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (course_id, position) deferrable initially deferred
);

create table books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author text,
  description text,
  cover_asset_id uuid references media_assets (id) on delete set null,
  language text not null default 'ar',
  edition text,
  isbn text check (isbn is null or isbn ~ '^[0-9Xx-]{10,17}$'),
  copyright_notes text,
  status publish_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table book_structures (
  id uuid primary key default gen_random_uuid(),
  book_id uuid not null references books (id) on delete cascade,
  name text not null,             -- e.g. "By surah and verse"
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index book_structures_one_default
  on book_structures (book_id) where is_default;

create table book_structure_levels (
  id uuid primary key default gen_random_uuid(),
  structure_id uuid not null references book_structures (id) on delete cascade,
  depth int not null check (depth between 1 and 8),
  node_type text not null check (node_type ~ '^[a-z][a-z0-9_]*$'),  -- surah, verse, page, chapter…
  label_singular text not null,   -- "Surah"
  label_plural text not null,     -- "Surahs"
  -- Which reference fields admins fill in at this level (drives admin forms).
  uses_page boolean not null default false,
  uses_chapter boolean not null default false,
  uses_surah boolean not null default false,
  uses_verses boolean not null default false,
  unique (structure_id, depth),
  unique (structure_id, node_type)
);

create table course_books (
  course_id uuid not null references courses (id) on delete cascade,
  book_id uuid not null references books (id) on delete restrict,
  unit_id uuid references course_units (id) on delete cascade,
  structure_id uuid references book_structures (id) on delete set null,
  position int not null default 0,
  is_primary boolean not null default true,
  primary key (course_id, book_id)
);

create table curriculum_nodes (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses (id) on delete cascade,
  unit_id uuid references course_units (id) on delete cascade,
  parent_id uuid references curriculum_nodes (id) on delete cascade,
  book_id uuid references books (id) on delete set null,
  structure_level_id uuid references book_structure_levels (id) on delete set null,
  node_type text not null default 'section' check (node_type ~ '^[a-z][a-z0-9_]*$'),
  title text not null,
  description text,
  position int not null check (position >= 0),
  reference_label text,           -- "Al-Fatihah 1:1–3", "p. 12"
  page_start int check (page_start is null or page_start > 0),
  page_end int,
  chapter_number int check (chapter_number is null or chapter_number > 0),
  surah_number int check (surah_number is null or surah_number between 1 and 114),
  verse_start int check (verse_start is null or verse_start > 0),
  verse_end int,
  metadata jsonb not null default '{}' check (jsonb_typeof(metadata) = 'object'),
  status publish_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (id <> parent_id),
  check (page_end is null or (page_start is not null and page_end >= page_start)),
  check (verse_end is null or (verse_start is not null and verse_end >= verse_start))
);
create index curriculum_nodes_course on curriculum_nodes (course_id, parent_id, position);

create table lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses (id) on delete cascade,
  unit_id uuid references course_units (id) on delete cascade,
  node_id uuid references curriculum_nodes (id) on delete cascade,
  title text not null,
  summary text,
  position int not null check (position >= 0),
  estimated_minutes int check (estimated_minutes is null or estimated_minutes > 0),
  -- Visible to every enrolled learner regardless of unlocks (e.g. intro).
  is_preview boolean not null default false,
  status publish_status not null default 'draft',
  content_version int not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index lessons_course on lessons (course_id);
create index lessons_node on lessons (node_id);

create table lesson_content_blocks (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references lessons (id) on delete cascade,
  position int not null check (position >= 0),
  block_type content_block_type not null,
  -- Type-specific fields; shape validated by app_private.valid_block().
  body jsonb not null default '{}' check (jsonb_typeof(body) = 'object'),
  media_asset_id uuid references media_assets (id) on delete restrict,
  assessment_id uuid,  -- FK added after assessments
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (lesson_id, position) deferrable initially deferred
);

-- ========================================================== assessments ==

create table assessments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses (id) on delete cascade,
  lesson_id uuid references lessons (id) on delete cascade,
  title text not null,
  instructions text,
  kind assessment_kind not null default 'practice',
  grading grading_mode not null default 'auto',
  pass_mark_percent int not null default 70 check (pass_mark_percent between 0 and 100),
  max_attempts int check (max_attempts is null or max_attempts > 0),
  time_limit_minutes int check (time_limit_minutes is null or time_limit_minutes > 0),
  status publish_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table lesson_content_blocks
  add constraint lesson_content_blocks_assessment_fk
  foreign key (assessment_id) references assessments (id) on delete restrict;

create table assessment_questions (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references assessments (id) on delete cascade,
  position int not null check (position >= 0),
  question_type question_type not null,
  prompt text not null,
  prompt_media_asset_id uuid references media_assets (id) on delete set null,
  points numeric(6, 2) not null default 1 check (points >= 0),
  explanation text,
  unique (assessment_id, position) deferrable initially deferred
);

create table assessment_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references assessment_questions (id) on delete cascade,
  position int not null check (position >= 0),
  label text not null,
  is_correct boolean not null default false,
  unique (question_id, position) deferrable initially deferred
);

-- ================================================== enrolment & gating ==

create table course_staff (
  course_id uuid not null references courses (id) on delete cascade,
  user_id uuid not null references users (id) on delete cascade,
  role course_staff_role not null default 'teacher',
  created_at timestamptz not null default now(),
  primary key (course_id, user_id)
);

create table course_enrolments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses (id) on delete cascade,
  user_id uuid not null references users (id) on delete cascade,
  status enrolment_status not null default 'active',
  source enrolment_source not null,
  teacher_id uuid references users (id) on delete set null,
  granted_by uuid references users (id) on delete set null,
  enrolled_at timestamptz not null default now(),
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (course_id, user_id)
);

-- The heart of teacher-gated progression: a learner can open a lesson's
-- content only if a row exists here (or the lesson is a preview, or the
-- course is 'open'). Only teachers/admins (or server-side automation) write.
create table lesson_unlocks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users (id) on delete cascade,
  lesson_id uuid not null references lessons (id) on delete cascade,
  course_id uuid not null references courses (id) on delete cascade,
  reason unlock_reason not null,
  unlocked_by uuid references users (id) on delete set null,
  note text,
  unlocked_at timestamptz not null default now(),
  unique (user_id, lesson_id)
);
create index lesson_unlocks_user_course on lesson_unlocks (user_id, course_id);

-- A teacher's evaluation of a learner on a lesson ("marking").
create table lesson_reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users (id) on delete cascade,
  lesson_id uuid not null references lessons (id) on delete cascade,
  course_id uuid not null references courses (id) on delete cascade,
  teacher_id uuid not null references users (id) on delete restrict,
  outcome review_outcome not null,
  score numeric(5, 2) check (score is null or score between 0 and 100),
  feedback text,
  feedback_audio_asset_id uuid references media_assets (id) on delete set null,
  created_at timestamptz not null default now()
);
create index lesson_reviews_user_lesson on lesson_reviews (user_id, lesson_id, created_at desc);

-- ============================================================= progress ==

create table learner_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users (id) on delete cascade,
  lesson_id uuid not null references lessons (id) on delete cascade,
  course_id uuid not null references courses (id) on delete cascade,
  status progress_status not null default 'in_progress',
  -- {"block": 3, "media_seconds": 41.5, "scroll": 0.62}
  last_position jsonb not null default '{}' check (jsonb_typeof(last_position) = 'object'),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  last_accessed_at timestamptz not null default now(),
  -- Device clock of the latest applied change (conflict resolution).
  client_updated_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, lesson_id)
);
create index learner_progress_user_course on learner_progress (user_id, course_id);

create table quiz_attempts (
  -- Client-generated UUID: resubmitting the same attempt is idempotent.
  id uuid primary key,
  assessment_id uuid not null references assessments (id) on delete cascade,
  user_id uuid not null references users (id) on delete cascade,
  status attempt_status not null default 'submitted',
  started_at timestamptz not null,
  submitted_at timestamptz,
  -- Authoritative (server-computed or teacher-assigned).
  score numeric(8, 2),
  max_score numeric(8, 2),
  passed boolean,
  -- What the device calculated offline (practice only; informational).
  client_score numeric(8, 2),
  graded_by uuid references users (id) on delete set null,
  graded_at timestamptz,
  teacher_feedback text,
  created_at timestamptz not null default now()
);
create index quiz_attempts_user on quiz_attempts (user_id, assessment_id);

create table learner_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references quiz_attempts (id) on delete cascade,
  question_id uuid not null references assessment_questions (id) on delete cascade,
  selected_option_ids uuid[] not null default '{}',
  text_answer text,
  media_asset_id uuid references media_assets (id) on delete set null,
  is_correct boolean,
  points_awarded numeric(6, 2),
  teacher_feedback text,
  unique (attempt_id, question_id)
);

-- Idempotency ledger for client sync operations (offline outbox replay).
create table sync_operations (
  op_id uuid primary key,
  user_id uuid not null references users (id) on delete cascade,
  op_type text not null,
  received_at timestamptz not null default now(),
  result jsonb
);
create index sync_operations_user on sync_operations (user_id, received_at desc);

-- ============================================================ triggers ==

do $$
declare t text;
begin
  foreach t in array array[
    'users', 'learner_profiles', 'media_assets', 'courses', 'course_units',
    'books', 'book_structures', 'curriculum_nodes', 'lessons',
    'lesson_content_blocks', 'assessments', 'course_enrolments',
    'learner_progress'
  ] loop
    execute format(
      'create trigger %I before update on %I
         for each row execute function app_private.touch_updated_at()',
      t || '_touch', t);
  end loop;
end $$;
