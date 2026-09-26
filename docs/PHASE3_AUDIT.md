# Phase 3 audit: before any change (v2.5.0)

Traced end to end in code, migrations 0001–0016 and the live Neon database.
Live data: three test courses (draft or archived), no books, two users.
**"Introduction to Quran Recitation" does not exist** in the database or the
code, so Phase 3 creates it rather than strengthening an existing course.

## A. Works today
- **Curriculum engine:** courses, optional units, a tree of sections
  (`curriculum_nodes`, any depth, typed, with page/chapter/surah/verse
  fields), lessons, ordered typed content blocks, books with custom
  structures (e.g. Surah → Verse). Admins add, edit, reorder, publish and
  delete sections and lessons from the course editor's outline.
- **Access:** RLS on every table. `can_read_lesson` requires a published
  lesson, course and ancestors, an active enrolment inside its date window,
  and an unlock (teacher-gated) or preview / open progression. Tested,
  including a learner tampering with requests.
- **Media:** Cloudinary private ("authenticated") delivery. The database
  signs each URL after `can_read_media`; learners upload only into
  `sidra/submissions/<their id>`.
- **Assessments:** quizzes (single/multi choice, true/false, short answer,
  recitation), teacher-graded mode, `grade_attempt`.
- **Teaching:** teacher review and unlock, unit-scoped teachers,
  `teaches()`.
- **Payments and finance** (v2.5.0): MarzPay through the payments server,
  manual payments, waivers, refunds, expenses, summary.
- **Offline:** per-user SQLite cache, outbox for progress and quiz
  attempts, offline media downloads.

## B. Exists but incomplete
- **Language:** `courses.language` holds ONE code, is not in the course
  form and is never shown. `books.language` is shown nowhere. Lessons and
  blocks have no language.
- **Files:** content blocks accept image, audio, video and "attachment",
  but the file picker is typed, the lesson editor offers no documents, and
  `media_assets` has no MIME type, file name, checksum or version.
- **External resources:** the `external_link` block (v2.3.0) recognises
  YouTube and Telegram, but only by URL: there is no real metadata fetch,
  no "verified" state, and nothing at course, unit or node level.
- **Lessons:** no learning outcomes, no Qur'an reference fields (only
  sections have them), and they can't be moved to another section or
  copied to another course.
- **Course access:** `access` covers free, paid and restricted
  (invitation). There is no hidden-from-catalogue option and no
  prerequisites (only free text).
- **MarzPay:** works end to end (live-tested up to the PIN), but there is
  no admin test area and no way to see if the payments server is alive.

## C. Hardcoded that should be data
- Language choices (there are none; `'en'` is assumed).
- Learning tracks (reading, recitation, tajwid, Qur'anic Arabic, tafsir,
  hifz…): only a free-text `subject`.

## D. Duplicated
- `pickLocalFile` plus per-screen upload code; one resource uploader
  replaces them.
- Two ways to link out: the `reference.url` block and the
  `external_link` block. Kept for compatibility; resources supersede both.

## E. Missing entirely
- A generic resource library: provider = Cloudinary | external URL |
  future storage. Resources attached to course, unit, book, section,
  lesson or assignment.
- Assignments, learner submissions, submission files, the teacher review
  queue.
- Language catalogue, course and lesson languages, teacher languages.
- Course prerequisites and catalogue visibility.
- Payment diagnostics and the payments-server heartbeat.
- An idempotent curriculum seed.

## F. Blocks representing the Qur'an curriculum correctly
No tracks (reading vs recitation vs tajwid vs Arabic). No lesson
objectives. No lesson-level Qur'an references. No prerequisites. No
provisional / needs-verification marker.

## G. Blocks admins attaching resources
Only one media file per block and no documents in the lesson editor. No
PDF/Office/audio library, no resource attached to a course or unit, no
preview before learners see it.

## H. Blocks teachers receiving work
There are no assignment or submission tables. Learners can upload files,
but nothing links them to a lesson, a teacher or a review.

## I. Access issues
- **SECURITY:** `can_read_media` lets ANY teacher or admin persona read
  ANY file, including learners' private submissions in courses they don't
  teach. Fixed in 0018: submission files are readable only by their owner
  and by people who teach that lesson.
- Signed Cloudinary URLs don't expire. A learner who shares a URL shares
  the file, although URLs are only issued to people allowed to see it.
  Expiring URLs need Cloudinary token auth (paid add-on); recorded as a
  known limit.

## J. Blocks MarzPay testing
The secret lives only on the payments server (correct), so the app can't
test MarzPay directly. Tests must run on the server and report back
through the database, which also works when the server has no public
address.

## Decisions
- **Lessons stay owned by one course.** Many-to-many would make progress,
  unlocks and ordering ambiguous ("which course's next lesson?"). Reuse is
  by **Copy to another course**; **Move** handles restructuring within a
  course.
- **Seeded courses are "In review" and "By invitation".** The curriculum is
  a provisional proposal and needs scholarly verification. Nothing reaches
  learners until an admin reviews and publishes it.
- **Arabic is content language, not delivery language.** Blocks carry
  their own language (a Qur'an block is `ar`); the course and lesson
  delivery language (e.g. English) is separate.
