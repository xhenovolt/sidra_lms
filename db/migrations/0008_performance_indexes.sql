-- 0008 indexes for the lookups RLS helpers perform on every request.
--
-- can_read_lesson / is_enrolled / is_course_staff / can_read_media run per
-- row, so their predicates must be index-backed.

create index if not exists course_enrolments_user
  on course_enrolments (user_id, status);

create index if not exists course_staff_user
  on course_staff (user_id);

-- Recursive walks up/down the curriculum tree (lesson_is_live, sequence).
create index if not exists curriculum_nodes_parent
  on curriculum_nodes (parent_id);

create index if not exists lessons_unit
  on lessons (unit_id);

-- can_read_media(): which blocks / courses / books reference an asset.
create index if not exists lesson_content_blocks_media
  on lesson_content_blocks (media_asset_id) where media_asset_id is not null;
create index if not exists courses_thumbnail
  on courses (thumbnail_asset_id) where thumbnail_asset_id is not null;
create index if not exists books_cover
  on books (cover_asset_id) where cover_asset_id is not null;
create index if not exists assessment_questions_media
  on assessment_questions (prompt_media_asset_id)
  where prompt_media_asset_id is not null;
create index if not exists lesson_reviews_audio
  on lesson_reviews (feedback_audio_asset_id)
  where feedback_audio_asset_id is not null;
create index if not exists media_assets_uploader
  on media_assets (uploaded_by);

create index if not exists assessments_lesson
  on assessments (lesson_id);
create index if not exists assessments_course
  on assessments (course_id);

-- Teacher console: pending attempts per assessment.
create index if not exists quiz_attempts_status
  on quiz_attempts (assessment_id, status);
