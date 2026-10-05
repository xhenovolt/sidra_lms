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
  Release('2.41.0', DateTime(2026, 10, 5), 'Pay ahead, receipts and refunds', [
    'Monthly, weekly or termly courses: pay for several periods at once (for example 5 months for 100,000) and learn without paying again until they end. Sidra shows the exact amount and the date it covers until.',
    'Every confirmed payment gets a numbered receipt, showing the months it pays for. Learners find all their payments and receipts under Profile › My payments, and can save a receipt as a PDF.',
    'Refunds: an agreed refund is owed to the learner until finance pays it back and records the transaction ID (Payments and fees › Refunds).',
    'Download financial reports and the journal as PDF or Excel.',
    'Sidra compares its MarzPay payments with MarzPay\x27s own records (money in, amount, fee) and shows any difference.',
    'Accounting rules page: the rules the books follow, a PDF for the accountant, and a record of who confirmed them.',
  ]),
  Release('2.40.0', DateTime(2026, 10, 4), 'Full finance: real double-entry books', [
    'Finance home shows what Almuntahha has right now: cash, bank, MarzPay share and mobile money, with this month\x27s income and expenses, what learners owe and bills to pay.',
    'Every payment, MarzPay fee (the real amount MarzPay charged), refund, reversal and expense is booked automatically as a balanced entry. Nothing can be edited afterwards; mistakes are reversed.',
    'Record money in (donations, loans), money out, moves between accounts, bills (paid in full or in parts), equipment and its yearly wear.',
    'Accounts with statements, the journal, and reports: income and expenses, balance sheet, cash flow, trial balance and budget against actual.',
    'Count cash, bank and MarzPay against the books and explain any difference; close a month when it is final.',
    'Starting amounts are entered by finance staff from real records; Sidra never guesses a balance.',
  ]),
  Release('2.39.1', DateTime(2026, 10, 3), 'Up-to-date About page', [
    'This page now lists every release, with older ones folded away.',
    'A short summary of what Sidra does.',
  ]),
  Release('2.39.0', DateTime(2026, 10, 3), 'Fast on every network', [
    'Works on Wi-Fi: networks at schools, offices and some homes blocked Sidra\x27s connection, so it only worked on mobile data. Sidra now connects the same way websites do, on any Wi-Fi or mobile data.',
    'Much faster: each screen\x27s information arrives in one quick request instead of many (about half a second instead of several seconds).',
    'Sidra starts connecting the moment it opens, so the first screen waits less.',
    'A course page and the course builder load in one go.',
  ]),
  Release('2.38.0', DateTime(2026, 10, 2), 'Paid courses and safer payments', [
    'A paid course opens only after its payment is confirmed. Being enrolled is not enough.',
    'Mobile money payments are confirmed with MarzPay by Sidra\x27s server, not by what the phone reports.',
    'Fee waivers can have a start and an end date.',
    'A refund closes the course; paying again reopens it.',
    'Links to paid audio and video expire after a while, and offline copies are removed when a learner\x27s access ends.',
  ]),
  Release(
    '2.37.0',
    DateTime(2026, 10, 1),
    'Bring your learners from WhatsApp',
    [
      'Import learners from the phone\x27s contacts, a spreadsheet (CSV or Excel), a pasted list or a WhatsApp group export. Check the list before importing, and undo an import.',
      'Each learner gets an invitation code and activates their own account.',
      'Keep every learner\x27s place: record where they had reached in the book on WhatsApp, and attach their old recordings.',
      'Phone numbers written like 0772… are understood.',
    ],
  ),
  Release('2.36.0', DateTime(2026, 9, 30), 'Instant notifications', [
    'Notifications arrive within seconds, even when Sidra is closed.',
    'Tapping a notification opens the page it is about.',
  ]),
  Release('2.35.0', DateTime(2026, 9, 30), 'Test transactions', [
    'Finance staff can make real small MarzPay collections and payouts and watch each step as it happens, from the menu.',
  ]),
  Release(
    '2.34.0',
    DateTime(2026, 9, 30),
    'Work as a conversation; repeating fees',
    [
      'Each piece of work is a thread: several attempts, the teacher\x27s replies and the learner\x27s answers in one place.',
      'Uploads show real progress.',
      'Fees can repeat: weekly, monthly, termly or over a set period, not only once.',
      'Settings no longer jump while scrolling; the account menu opens again.',
    ],
  ),
  Release(
    '2.33.0',
    DateTime(2026, 9, 29),
    'Pay inside Sidra; import contacts',
    [
      'Pay course fees with mobile money without leaving the app.',
      'Add learners from the phone\x27s contacts.',
    ],
  ),
  Release('2.31.0', DateTime(2026, 9, 29), 'Control centre and dashboard', [
    'A settings control centre, a MarzPay test centre and diagnostics for administrators.',
    'Dashboard figures open to show the learners and items behind them.',
  ]),
  Release('2.30.0', DateTime(2026, 9, 29), 'Messages and profile photos', [
    'Staff can message each other inside Sidra.',
    'View a profile photo full size, and change it.',
  ]),
  Release('2.29.0', DateTime(2026, 9, 29), 'Problem reports and late work', [
    'Learners can report a problem with their work; teachers answer it.',
    'Rules for late work, and a notification when an upload has finished.',
  ]),
  Release('2.28.0', DateTime(2026, 9, 29), 'Devices and sign-in protection', [
    'Administrators see which phones are signed in and can sign them out.',
    'Protection against repeated password guessing.',
  ]),
  Release('2.27.0', DateTime(2026, 9, 29), 'Run Sidra without the developer', [
    'Organisation settings can be changed in the app by administrators.',
    'Security fix for internal database functions.',
  ]),
  Release('2.26.0', DateTime(2026, 9, 28), 'Teacher inbox', [
    'Teachers get an inbox of work to review, with "review next".',
    'The real Sidra logo on the launch screen.',
  ]),
  Release(
    '2.24.0',
    DateTime(2026, 9, 28),
    'Course rules and word-by-word marking',
    [
      'Course rules decide how learners move forward.',
      'Learners submit work from a lesson; teachers mark a recitation word by word.',
      'Choose which notifications you receive.',
    ],
  ),
  Release('2.23.0', DateTime(2026, 9, 28), 'Capture, view and browse', [
    'Add course content straight from the phone: take a photo, record video or audio, scan many pages into one PDF, or paste text.',
    'See the size of every file before it is uploaded.',
    'Files open inside Sidra: pictures, audio, video, PDFs and text. Office documents open in the phone\x27s document app.',
    'Uploads no longer time out after the phone has been idle.',
    'Top courses (most enrolled) carousel; courses in a grid or a list.',
    'Administrators can preview the app as a learner.',
  ]),
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
