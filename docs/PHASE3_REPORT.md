# Phase 3 report: Qur'an catalogue, content infrastructure, hardening

Versions 2.6.0 to 2.8.x. The audit written before any change is
`docs/PHASE3_AUDIT.md`.

## 1. What existed before Phase 3
- A flexible curriculum engine: units, a section tree of any depth, typed
  content blocks, books with custom structures.
- Teacher-gated access enforced by RLS.
- Private Cloudinary media with URLs signed in the database.
- Quizzes, including teacher-graded ones.
- Payments and finance, with MarzPay live-tested up to the PIN prompt.
- Offline cache and outbox.

## 2. What was missing
- Languages of delivery.
- A resource library and external resources with honest previews.
- Assignments and learner submissions.
- Lesson learning outcomes and Qur'an references.
- Learning tracks, prerequisites, hidden courses.
- Moving and copying lessons.
- A MarzPay test area.
- Any real curriculum. "Introduction to Qur'an Recitation" did not exist in
  the code or the database, so it was created, not strengthened.

## 3. Migrations
| Migration | Content |
|---|---|
| 0017_phase3_enums | Block types `resource` and `assignment`; media kind `other` |
| 0018_phase3_content_infrastructure | Languages (9 seeded), learning tracks (12), course track, extra languages, visibility, target learner, metadata; prerequisites (enforced on self-enrol and payment); lesson outcomes, language and Qur'an reference (sūrah, āyāt, juz', ḥizb, page); section language; `resources` (cloudinary, external or storage) and `resource_links` (course, unit, book, section, lesson, assignment); `assignments`, `submissions`, `submission_files`, `submit_work`, `teacher_submissions`, `review_submission`; teachers-only blocks and block language; `move_lesson`, `copy_lesson`; teacher languages; payments-server heartbeat, `payment_diagnostics`, idempotency self-test, reconciliation report |
| 0019_seed_quran_catalogue | Idempotent seed functions and the catalogue |

Everything is additive; no data was dropped.

## 4. Seeded catalogue (live on Neon)
| Course | Track | Units | Sections | Lessons | Blocks | Assessments | Assignments |
|---|---|---|---|---|---|---|---|
| Yassarna: Beginners | Qur'an reading | 5 | 0 | 20 | 28 | 5 | 3 |
| Yassarna: Intermediate | Qur'an reading | 5 | 0 | 12 | 5 | 3 | 1 |
| Yassarna: Advanced | Tajwīd | 5 | 0 | 16 | 5 | 2 | 0 |
| Introduction to Arabic Language | Qur'anic Arabic | 5 | 0 | 15 | 14 | 3 | 1 |
| Introduction to Qur'an Recitation | Qur'an recitation | 4 | 4 (Sūrahs 1, 112, 113, 114) | 12 | 10 | 1 | 2 |
| **Total** | | **24** | **4** | **75** | **62** | **14** | **7** |

- **Books:** two reference books with structures: Yassarnal-Qurʾān by stage and lesson, and the Madinah muṣḥaf by sūrah and āyah.
- **Prerequisites:** Beginners → Intermediate → Advanced. Beginners is also required for Recitation and for Arabic.
- **Status:** all "In review", by invitation, English delivery, every lesson with a measurable outcome and marked *provisional*.

Quality over volume: blocks are short, original explanations and practice
text, not filler. Lessons without blocks still have their title, outcome
and place, for teachers to complete.

## 5. Resources and files
- **Resource model:** each resource has a provider (Cloudinary today; `external` for URLs; `storage` for a future provider) and stores file name, MIME type, extension, size, checksum, language, version and what it replaces, plus uploader, order and published or hidden state.
- **File types:** PDF, DOC/DOCX, PPT/PPTX, XLS/XLSX, TXT, JPG/JPEG/PNG/WEBP, MP3/WAV/M4A/AAC, MP4/MOV. Documents upload as Cloudinary "raw" files, always private.
- **Access:** controlled by `can_read_resource`: enrolled and allowed to read the lesson, or course staff, or a public resource on a published course.

## 6. External link preview
- **Sources:** YouTube and Vimeo through oEmbed. Other pages: `og:` tags and `<title>`, reading at most 512 KB, following up to 5 redirects, with a 10-second limit.
- **Files:** a linked PDF or audio file is described by its type and name, never downloaded in full.
- **Safety:** only http(s) links are accepted; `javascript:`, `data:`, `file:`, `intent:` and anything else are refused before any request, and the database refuses them too. Only text and https thumbnails are displayed; nothing from the page is executed or rendered as HTML.
- **Honesty:** when there is no preview, the card says so, with the reason. The admin chooses "Looks right: save" (recorded as *checked* by them) or "I trust it: save" (*not checked*).

## 7. Learner submissions
- **Flow:** the teacher creates an assignment; the learner takes a photo, picks one from the gallery or attaches a file (or types an answer); the teacher reviews it (received → under review → reviewed, returned, or asked for a new try); the learner sees the feedback and can hand in attempt 2.
- **Idempotent:** each submission id is generated on the phone, so a retry is the same submission.
- **Upload states:** waiting to upload, uploading, failed with retry. Each file is uploaded once, even across retries, and queued work is sent automatically when back online.

## 8. Languages
- **Model:** a `languages` table with direction (rtl/ltr); a course has a main and extra languages; a lesson or section can override; a block or resource has its own language; users have teaching languages.
- **Display:** learners see "Taught in English" on courses and lessons, even when blocks are Arabic.

## 9. MarzPay testing
The tests run on the payments server, which holds the secret. The admin
requests them from Settings → Payments, and results come back through
the database.

**Live results (2026-09-27):** 9 PASS, 2 WARNING, 0 FAIL.
- **Warning 1:** there is no public webhook address yet, so payments are confirmed by polling.
- **Warning 2:** reading the balance needs the server's IP to be whitelisted; collections don't need it.

## 10. Security and access-control changes
- **Fixed file access:** any teacher or admin persona could read any file, including other learners' private submissions. Now only the owner and the people who teach that lesson can open a submission.
- **Teacher notes:** learners can't read teachers-only blocks (RLS).
- **Hidden courses:** only enrolled learners and staff see them.
- **Prerequisites:** enforced in the database for self-enrolment and payment.
- **Submitting work:** needs the right to read the lesson, and every file must be the learner's own upload.
- **Seed functions:** can't be called by app users.
- **Git history:** checked before the first push: no `.env`, config, keystore, or database, Cloudinary or MarzPay secret was ever committed.

## 11. Offline
Unchanged and working: lesson content, progress, quizzes, downloads.

New: queued submissions with visible states. Resources and assignments are
read online; new fields on courses and lessons are cached with them.

## 12. Tests
| Suite | Result |
|---|---|
| Database: 12 suites (new: `phase3_test` 98 statements, `catalogue_test` 45) | all pass |
| Flutter: 115 tests (new: `phase3_test` ×4, `link_preview_test` ×6) | all pass |
| Live: MarzPay diagnostics against real MarzPay and Neon | pass (9 PASS / 2 WARNING) |
| Live: learner pays 500 UGX (v2.5.0) | prompt delivered to the phone; not completed (PIN not entered) |

**Acceptance scenarios from the brief:**
1. **Yassarna Beginners visible and readable.** Database test: an admin publishes the course and enrols learner A; A reads lesson 1 and its content but not the teacher's note. Admin screens show course facts, curriculum, resources and assessments.
2. **Add a lesson.** Database test: added to Stage 3, it appears immediately after the last lesson of Stage 3.
3. **Resource.** Database test: a PDF attached to a lesson; the enrolled learner gets a signed link, the other learner is refused. Widget test: the learner sees it.
4. **Image submission.** Database test: photo handed in, teacher sees and opens it, reviews with feedback, learner reads it and resubmits. Widget test: teacher review.
5. **External resource.** Unit tests of previews (YouTube, web page, file, 404, unsafe links); database test with a verified YouTube link.
6. **Language.** Widget test: an English lesson with Arabic Qur'an text shows "Taught in English".
7. **Intermediate** and 8. **Advanced.** Database test: three separate courses, tracks and units. Advanced tajwīd content needed no schema change.
9. **MarzPay.** Live diagnostics above; widget test of the screen.
10. **Access control.** Database test: learner B can't open content, self-enrol, insert an enrolment or insert an unlock. SQLite isn't a security boundary; every read goes through RLS.

**Not tested:**
- on a physical phone (the Phase 3 build was installed but not exercised by a person);
- real uploads of large videos;
- a completed MarzPay payment.

## 13. Needs human scholarly verification
- All Qur'anic text (al-Fātiḥah, 112–114, istiʿādhah, basmalah, 2:2 example): against a printed muṣḥaf.
- Yassarna stage and lesson order against the institution's edition. Page numbers are deliberately absent.
- Tajwīd details and madd counts (Ḥafṣ via ash-Shāṭibiyyah assumed).
- Stop-sign conventions of the class muṣḥaf.
- Word glosses in the Arabic course.
- The etiquette lesson where schools of fiqh differ.

## 14. Needs a real MarzPay environment
- A completed collection (enter the PIN), a declined one, and a webhook to a public HTTPS address.
- IP whitelisting if balance checks are wanted.
- The payments server deployed somewhere always on.

## 15. Known limits (next steps)
- **Resources at unit and section level:** supported in the database but not yet in the admin UI (course, lesson and assignment are).
- **Teacher languages:** stored, with no admin UI yet.
- **Audio hand-ins:** attach a file recorded elsewhere; there is no in-app recorder.
- **Cloudinary signed URLs don't expire:** anyone given a link can reuse it. Expiring links need Cloudinary token authentication.
- **Offline:** resources and assignments aren't cached for offline use yet.
