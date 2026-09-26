# Sidra: guide for teachers and administrators

Everything is done inside the Sidra app. Open **Profile → Teacher console**.
(You only see it if an administrator has made you a teacher or admin.)

The console needs an internet connection. Learners can study offline; you
can't edit courses offline.

## For teachers: reviewing learners

1. Open the **Learners** tab. People **waiting for your review** are at the
   top. They have finished everything you have opened for them.
2. Tap a learner. You'll see the lesson they're on.
3. Choose **Passed** or **Needs revision**, give a score if you like, and
   write feedback.
4. Leave **Open the next lesson for this learner** switched on to let them
   continue. They'll see the next lesson, with its pictures, audio and voice
   notes, the next time they open the app.

Until you open a lesson, the learner can't see anything inside it. The
server enforces this, not just the app.

## For administrators: building a course

### 1. Add the book (once)

**Books tab → New book.** Fill in the title and author, and add a cover
picture if you have one. Then tap the book → **How is this book
organised?** and pick one:

| Choice | Use it for |
|---|---|
| Surah → Verse | the Quran, verse by verse |
| Page by page | Yassarna and other page-based books |
| Chapter → Section | most textbooks |
| Level → Unit → Chapter | multi-level theology series |
| Section → Topic | topic-based books |
| My own levels | anything else: type the level names |

### 2. Create the course

**Courses tab → New course.** Give it a name, subject, level and description,
and list what learners will learn. Then choose:

- **Who can join:** *Free* (learners join themselves), *Paid* or *By
  invitation* (you give access from the People tab).
- **How learners move forward:** *Teacher opens each next lesson* (the
  usual Almuntahha way), *Next lesson opens after finishing*, or *All
  lessons open*.

### 3. Build the outline

Open the course.

- **Units** (optional) group the course into big steps.
- **Link a book** to use its organisation.
- **Add section** creates, for example, *Surah Al-Fatihah*. Its menu has
  **Add part inside** (e.g. *Verses 1–3*) and **Add lesson**. The form asks
  only for the details that level needs (surah number, verses, page…).
- Use **Move up / Move down** to change the order. Lessons follow this order.

### 4. Write lessons

Tap a lesson, then **Add content**. You can mix, in any order:
text, headings, Quran text (Arabic), translation, transliteration,
pictures, audio, video, files, references, highlight boxes, a quiz, and
**links** to a YouTube video, a Telegram post or any website. Paste the link:
Sidra recognises YouTube and Telegram, shows a preview (with the video's
picture for YouTube), and opens it outside the app for learners. Only
ordinary web links (https://…) are accepted.
Use the **Preview** tab to see exactly what learners will see.

For a **quiz**, choose *practice* (works offline, answers shown after) or
*graded* (needs internet, answers stay hidden, scored by the server).

### 5. Review and publish

The **Status** card at the top of each course shows where it is:

| Status | Learners see it? | What happens next |
|---|---|---|
| **Draft** | No | Build it. **Submit for review** (with a note), or **Publish**. |
| **In review** | No | A reviewer **publishes** it, or **returns it to draft** saying what to fix. |
| **Published** | Yes | **Unpublish** hides it again; **Archive** retires it. |
| **Archived** | No | Records are kept. **Restore to draft** to bring it back. |

The card also lists what stands in the way. Red items block publishing
(for example, *publish at least one lesson*). Grey items are worth fixing
but don't block (no description, no cover image, lessons without content,
lessons still in draft, or no teacher on a teacher-gated course).

Who can do what comes from their role: **Academic Managers** and
**Admins** publish and archive; **Content Managers** submit for review.

While a course is live, new sections and lessons start **hidden**. Publish
each one from its menu when it's ready.

**Deleting:** only a course that was never published and has no learners
can be deleted. Every other course is **archived**, so enrolments, progress
and payments are never lost.

## Overview (administrators)

The dashboard shows live numbers (learners, teachers, courses published,
in draft and in review, enrolments, activity this week) and quick buttons to
**Add person** and **New course**. The bottom bar holds the main pages
(Dashboard, Courses, Learners, Review); **More** opens the menu with everything else;
it only lists the pages your role allows. The top and bottom bars slide
away while you scroll down a list and come back when you scroll up.

The **Courses** page can be searched by title, subject, category or tag,
and filtered by status. Archived courses are under **Archived**. Each course
can have a **category**, **tags**, and, for free courses, a switch for
whether learners may **enrol themselves**.

## People (administrators)

The menu has separate lists for **Learners**, **Teachers** and (superadmins)
**Administrators**. Type to search by name, phone, email or username; tap
**Active** or **Disabled** to narrow the list. Lists load 30 people at a
time; **Load more** fetches the next ones.

Tap a person to open their **record**: contact details, when they joined
and last signed in, the courses they are enrolled in with progress, what
they teach (and which units), their teacher reviews and quiz results, and
recent activity (if your role can see the activity log).

**Actions** (top right of the record):

- **Edit details:** name, phone, email, username.
- **Change role:** learner, teacher, or (superadmins only) administrator.
- **Superadmin** (superadmins only): can manage other administrators.
- **Reset password:** gives a temporary password.
- **Give access to a course:** for paid or invitation-only courses.
- **Make teacher of a course.**
- **Disable account:** signs them out everywhere. Nothing is deleted, and
  you can enable it again later.

**Add person** creates an account straight away. Sidra shows a temporary
password; give it to the person, and they choose their own the first time
they sign in. Only superadmins can create administrators, and Sidra always
keeps at least one superadmin.

## Course people

At the bottom of each course: its **teachers** (add or remove) and its
**learners** (add; set active, suspended or withdrawn). Tap anyone to open
their record.

A teacher can cover the **whole course** or only some **units**: open the
teacher's menu → **Limit to units…** and tick the units. They then see,
review and unlock only learners working in those units. Tick none to give
them the whole course again.

Only people whose role includes *reviewing learners* can review, unlock
lessons or grade quizzes. Content Managers edit content but cannot mark
learners. **Delete course**
only appears for courses that were never published; archive the others.

## Forgotten passwords

Everyone signs in with their **phone number** (with country code, e.g.
+256…), **email** or **username**, plus a password. If a learner forgets their password:

- **Teacher:** Learners tab → tap the learner → **Reset password**.
- **Administrator:** People tab → ⋮ → **Reset password**.

Sidra shows a temporary password such as `sidra-48213`. Give it to the
learner. When they sign in with it, they must choose a new password before
they can continue. All their other signed-in devices are signed out.

After 5 wrong attempts an account is locked for 15 minutes.
