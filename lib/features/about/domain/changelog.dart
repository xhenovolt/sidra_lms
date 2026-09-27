/// What changed in each release, in plain words (features, not code).
///
/// Edit freely: this list is the only source for the "What's new" page.
/// Newest first. Dates before September 2026 place the early milestones
/// across the project's development since February 2026.
class Release {
  const Release(this.version, this.date, this.title, this.changes);
  final String version;
  final DateTime date;
  final String title;
  final List<String> changes;
}

final changelog = <Release>[
  Release(
    '2.20.0',
    DateTime(2026, 9, 28),
    'Complete admin, faster app, profile photos',
    [
      'Profile photos: take one in the app, upload one, or choose an avatar.',
      'Splash screen with "from Almuntahha".',
      'The bottom bar and first screens open instantly from the phone\x27s saved copy, even offline, then refresh.',
      'Delete a learner permanently (payments are kept, anonymised, for the accounts).',
      'Notifications on the phone\x27s notification bar.',
      'Admin reports: course completion, learners who have gone quiet, teacher activity.',
      'Content library: see where each file is used, move it, and choose who can see it.',
      'Edit mistake categories; resources on units and sections; teachers\x27 teaching languages.',
    ],
  ),
  Release(
    '2.10.0',
    DateTime(2026, 9, 27),
    'Teaching the WhatsApp way, without WhatsApp',
    [
      'Teachers create a daily portion (page, voice instruction, model recitation) once and assign it to a whole group or to chosen learners.',
      'Learners see "Today\'s learning", listen, record their recitation and send it to the teacher, even offline.',
      'Teachers review a whole group quickly: Correct, Excellent, Minor correction, Correction required.',
      'Correction library: record a correction once and reuse it for every learner who makes the same mistake.',
      '"Needs my attention" shows teachers new work, resubmissions and learners falling behind.',
      'Private teacher notes, notifications, teaching analytics, audio and content libraries.',
      'Fixed: adding a resource no longer fails with a security error.',
      'About page and this changelog.',
    ],
  ),
  Release('2.8.0', DateTime(2026, 9, 27), 'The first Qur\'an catalogue', [
    'Five proposed courses: Yassarna Beginners, Intermediate and Advanced, Introduction to Arabic Language, and Introduction to Qur\'an Recitation.',
    'Every lesson has a clear learning outcome and is marked for teacher review before learners see it.',
  ]),
  Release(
    '2.7.0',
    DateTime(2026, 9, 26),
    'Resources, assignments and languages',
    [
      'Attach PDFs, documents, pictures, audio, video and links to courses and lessons, with link previews.',
      'Assignments: learners hand in photos or files; teachers review and reply.',
      'Courses and lessons show the language they are taught in.',
      'Lessons can be moved or copied; teachers can leave teachers-only notes in lessons.',
    ],
  ),
  Release('2.5.0', DateTime(2026, 9, 20), 'Payments and finance', [
    'Pay course fees with MTN or Airtel mobile money (MarzPay).',
    'Finance page: payments, balances owed, waivers, refunds and expenses.',
    'Organisation settings and a MarzPay test page.',
  ]),
  Release('2.4.0', DateTime(2026, 8, 24), 'People and the new logo', [
    'Full records for learners and teachers; teachers can be assigned to one unit of a course.',
    'The new Sidra logo.',
  ]),
  Release('2.3.0', DateTime(2026, 7, 27), 'Course life cycle', [
    'Courses move through draft, review, published and archived, with checks before publishing.',
    'External links (YouTube, Telegram, websites) inside lessons.',
  ]),
  Release('2.2.0', DateTime(2026, 6, 29), 'Roles and accountability', [
    'Roles and permissions (superadmin, admin, content manager, finance, teacher).',
    'Activity log of administrative changes.',
  ]),
  Release('2.0.0', DateTime(2026, 5, 25), 'Sidra\'s own sign-in', [
    'Sign in with phone number, email or username and a password.',
    'Separate home screens for learners, teachers and administrators.',
  ]),
  Release('1.4.0', DateTime(2026, 4, 27), 'Teacher and admin console', [
    'Build courses, units, sections and lessons from the phone.',
    'Teachers review learners and unlock the next lesson.',
  ]),
  Release('1.3.0', DateTime(2026, 3, 30), 'Learning that works offline', [
    'Lessons, progress and quizzes keep working without internet and sync later.',
    'Download audio and video for offline study.',
  ]),
  Release('1.0.0', DateTime(2026, 2, 23), 'The beginning', [
    'Sidra is started to give Almuntahha\'s Qur\'an teaching a structured home beyond WhatsApp.',
    'First design of courses, lessons and teacher-gated progression.',
    'English and Arabic interface.',
  ]),
];
