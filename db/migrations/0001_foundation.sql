-- 0001 foundation: extensions, private schema, enums, identity helpers.
--
-- Identity: the Neon Data API validates the Clerk JWT and pg_session_jwt
-- exposes its `sub` claim via auth.user_id(). Everything that needs "who is
-- calling" goes through app_private.clerk_id() so there is exactly one
-- place that reads the token.

create extension if not exists pgcrypto;
create extension if not exists pg_session_jwt;

-- Not exposed through the Data API. Holds secrets and internal helpers.
create schema if not exists app_private;
revoke all on schema app_private from public;

-- ---------------------------------------------------------------- enums --
create type app_role as enum ('learner', 'teacher', 'admin');
create type publish_status as enum ('draft', 'published', 'archived');
create type difficulty_level as enum ('beginner', 'intermediate', 'advanced');
create type course_access as enum ('free', 'paid', 'restricted');

-- How a learner moves through a course:
--   teacher_gated: a teacher unlocks each next lesson (Almuntahha default)
--   sequential:    completing a lesson unlocks the next automatically
--   open:          every published lesson is available once enrolled
create type progression_mode as enum ('teacher_gated', 'sequential', 'open');

create type enrolment_status as enum ('pending', 'active', 'suspended', 'completed', 'withdrawn');
create type enrolment_source as enum ('self_free', 'admin_grant', 'payment');
create type course_staff_role as enum ('teacher', 'editor');
create type unlock_reason as enum ('first_lesson', 'teacher_approved', 'auto_sequential', 'admin_override');
create type review_outcome as enum ('passed', 'needs_revision');
create type progress_status as enum ('not_started', 'in_progress', 'completed');

create type content_block_type as enum (
  'heading', 'rich_text', 'image', 'audio', 'video', 'quran_text',
  'translation', 'transliteration', 'reference', 'attachment',
  'assessment', 'callout', 'divider'
);

create type media_kind as enum ('image', 'audio', 'video', 'document');
-- Cloudinary delivery type: 'upload' = public URL, 'authenticated' = signed.
create type media_delivery as enum ('upload', 'authenticated');

create type assessment_kind as enum ('practice', 'graded');
create type grading_mode as enum ('auto', 'teacher');
create type question_type as enum ('single_choice', 'multiple_choice', 'true_false', 'short_answer', 'recitation');
create type attempt_status as enum ('in_progress', 'submitted', 'graded');

-- ------------------------------------------------------------- helpers --

-- Clerk user id (JWT `sub`) of the caller, or null when there is no
-- validated token (e.g. migrations run as the owner).
create or replace function app_private.clerk_id()
returns text
language plpgsql stable
as $$
begin
  return auth.user_id();
exception when others then
  return null;
end;
$$;

create or replace function app_private.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Server-side secrets (e.g. Cloudinary API secret). Written by
-- tool/migrate.dart from the local .env; never by the app.
create table app_private.settings (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

create or replace function app_private.setting(p_key text)
returns text
language sql stable
as $$ select value from app_private.settings where key = p_key $$;
