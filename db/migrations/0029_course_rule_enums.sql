-- Course rules: two more ways the next lesson unlocks (own migration: new
-- enum values cannot be used in the transaction that adds them).
--   after_submission  handing in the lesson's work unlocks the next lesson
--   after_approval    the teacher must mark the work passed (score at or
--                     above the course's pass mark)
alter type progression_mode add value if not exists 'after_submission';
alter type progression_mode add value if not exists 'after_approval';
alter type unlock_reason add value if not exists 'work_submitted';
alter type unlock_reason add value if not exists 'work_approved';
