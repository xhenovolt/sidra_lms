import '../../../shared/models/json.dart';

enum PublishStatus { draft, inReview, published, archived }

enum Difficulty { beginner, intermediate, advanced }

enum CourseAccess { free, paid, restricted }

/// How the next lesson unlocks.
enum Progression {
  /// The teacher unlocks each lesson by hand.
  teacherGated,

  /// Finishing (reading) a lesson unlocks the next.
  sequential,

  /// Every lesson is open.
  open,

  /// Handing in the lesson's work unlocks the next.
  afterSubmission,

  /// The teacher marks the work; a pass (score >= pass mark) unlocks the next.
  afterApproval;

  /// Lessons need handed-in work by default.
  /// Learners hand in work and a teacher marks it (the learner never
  /// marks their own lesson finished), except in "open" / "in order"
  /// courses an administrator chose to be self-paced.
  bool get needsWork =>
      this == afterSubmission || this == afterApproval || this == teacherGated;
}

class Course {
  const Course({
    required this.id,
    required this.slug,
    required this.title,
    required this.subject,
    this.subtitle,
    this.description,
    this.difficulty = Difficulty.beginner,
    this.language = 'en',
    this.thumbnailAssetId,
    this.access = CourseAccess.free,
    this.priceAmount,
    this.priceCurrency,
    this.billingPeriod = 'once',
    this.billingIntervalDays,
    this.billingPeriods,
    this.progression = Progression.teacherGated,
    this.status = PublishStatus.draft,
    this.estimatedHours,
    this.learningObjectives = const [],
    this.prerequisites,
    this.contentVersion = 1,
    this.updatedAt,
    this.category,
    this.tags = const [],
    this.selfEnrol = true,
    this.reviewNote,
    this.publishedAt,
    this.archivedAt,
    this.trackKey,
    this.passMarkPercent = 70,
    this.maxAttempts,
    this.deliveryLanguages = const [],
    this.hidden = false,
    this.targetLearner,
    this.metadata = const {},
  });

  factory Course.fromJson(Json j) => Course(
    id: j.str('id'),
    slug: j.str('slug'),
    title: j.str('title'),
    subject: j.str('subject'),
    subtitle: j.strOrNull('subtitle'),
    description: j.strOrNull('description'),
    difficulty: enumByName(
      Difficulty.values,
      j.strOrNull('difficulty'),
      Difficulty.beginner,
    ),
    language: j.strOrNull('language') ?? 'en',
    thumbnailAssetId: j.strOrNull('thumbnail_asset_id'),
    access: enumByName(
      CourseAccess.values,
      j.strOrNull('access'),
      CourseAccess.restricted,
    ),
    priceAmount: j.numOrNull('price_amount'),
    priceCurrency: j.strOrNull('price_currency'),
    billingPeriod: j.strOrNull('billing_period') ?? 'once',
    billingIntervalDays: j.numOrNull('billing_interval_days')?.toInt(),
    billingPeriods: j.numOrNull('billing_periods')?.toInt(),
    progression: enumByName(
      Progression.values,
      j.strOrNull('progression'),
      Progression.teacherGated,
    ),
    status: enumByName(
      PublishStatus.values,
      j.strOrNull('status'),
      PublishStatus.draft,
    ),
    estimatedHours: j.numOrNull('estimated_hours'),
    learningObjectives: j.strList('learning_objectives'),
    prerequisites: j.strOrNull('prerequisites'),
    contentVersion: j.integer('content_version', fallback: 1),
    updatedAt: j.dateOrNull('updated_at'),
    category: j.strOrNull('category'),
    tags: j.strList('tags'),
    selfEnrol: j.boolean('self_enrol', fallback: true),
    reviewNote: j.strOrNull('review_note'),
    publishedAt: j.dateOrNull('published_at'),
    archivedAt: j.dateOrNull('archived_at'),
    trackKey: j.strOrNull('track_key'),
    passMarkPercent: j.integer('pass_mark_percent', fallback: 70),
    maxAttempts: j.intOrNull('max_attempts'),
    deliveryLanguages: j.strList('delivery_languages'),
    hidden: j.strOrNull('visibility') == 'hidden',
    targetLearner: j.strOrNull('target_learner'),
    metadata: Map<String, dynamic>.from((j['metadata'] as Map?) ?? const {}),
  );

  final String id;
  final String slug;
  final String title;
  final String? subtitle;
  final String? description;
  final String subject;
  final Difficulty difficulty;
  final String language;
  final String? thumbnailAssetId;
  final CourseAccess access;
  final double? priceAmount;
  final String? priceCurrency;

  /// once | weekly | monthly | termly | custom (every [billingIntervalDays]).
  final String billingPeriod;
  final int? billingIntervalDays;

  /// How many periods in all; null = while enrolled.
  final int? billingPeriods;
  final Progression progression;
  final PublishStatus status;
  final double? estimatedHours;
  final List<String> learningObjectives;
  final String? prerequisites;
  final int contentVersion;
  final DateTime? updatedAt;
  final String? category;
  final List<String> tags;

  /// Free courses: whether learners may enrol themselves.
  final bool selfEnrol;

  /// Note sent with a review submission, or feedback when returned to draft.
  final String? reviewNote;
  final DateTime? publishedAt;
  final DateTime? archivedAt;

  /// Learning track (quran_reading, tajwid, quranic_arabic…).
  final String? trackKey;

  /// Score needed to pass lesson work (after-approval courses).
  final int passMarkPercent;

  /// Attempts allowed per lesson (null: unlimited).
  final int? maxAttempts;

  /// Notification switched off for this course (metadata.notify).
  bool notifies(String kind) => (metadata['notify'] as Map?)?[kind] != false;

  /// Languages taught in besides [language] (the primary one).
  final List<String> deliveryLanguages;

  /// Not listed in the catalogue; only its learners and staff see it.
  final bool hidden;
  final String? targetLearner;
  final Map<String, dynamic> metadata;

  bool get needsReview => metadata['provisional'] == true;

  /// Primary language first, then the others.
  List<String> get languages => [
    language,
    ...deliveryLanguages.where((l) => l != language),
  ];

  bool get isFree => access == CourseAccess.free;

  Json toJson() => {
    'id': id,
    'slug': slug,
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'subject': subject,
    'difficulty': enumToDb(difficulty),
    'language': language,
    'thumbnail_asset_id': thumbnailAssetId,
    'access': enumToDb(access),
    'price_amount': priceAmount,
    'price_currency': priceCurrency,
    'billing_period': billingPeriod,
    'billing_interval_days': billingIntervalDays,
    'billing_periods': billingPeriods,
    'progression': enumToDb(progression),
    'status': enumToDb(status),
    'estimated_hours': estimatedHours,
    'learning_objectives': learningObjectives,
    'prerequisites': prerequisites,
    'content_version': contentVersion,
    'updated_at': updatedAt?.toIso8601String(),
    'category': category,
    'tags': tags,
    'self_enrol': selfEnrol,
    'review_note': reviewNote,
    'published_at': publishedAt?.toIso8601String(),
    'archived_at': archivedAt?.toIso8601String(),
    'track_key': trackKey,
    'pass_mark_percent': passMarkPercent,
    'max_attempts': maxAttempts,
    'delivery_languages': deliveryLanguages,
    'visibility': hidden ? 'hidden' : 'catalogue',
    'target_learner': targetLearner,
    'metadata': metadata,
  };
}

class CourseUnit {
  const CourseUnit({
    required this.id,
    required this.courseId,
    required this.title,
    required this.position,
    this.description,
    this.learningObjectives = const [],
    this.status = PublishStatus.published,
  });

  factory CourseUnit.fromJson(Json j) => CourseUnit(
    id: j.str('id'),
    courseId: j.str('course_id'),
    title: j.str('title'),
    position: j.integer('position'),
    description: j.strOrNull('description'),
    learningObjectives: j.strList('learning_objectives'),
    status: enumByName(
      PublishStatus.values,
      j.strOrNull('status'),
      PublishStatus.draft,
    ),
  );

  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int position;
  final List<String> learningObjectives;
  final PublishStatus status;

  Json toJson() => {
    'id': id,
    'course_id': courseId,
    'title': title,
    'description': description,
    'position': position,
    'learning_objectives': learningObjectives,
    'status': enumToDb(status),
  };
}

class Book {
  const Book({
    required this.id,
    required this.title,
    this.author,
    this.description,
    this.coverAssetId,
    this.language = 'ar',
    this.edition,
    this.isbn,
    this.copyrightNotes,
    this.status = PublishStatus.published,
  });

  factory Book.fromJson(Json j) => Book(
    id: j.str('id'),
    title: j.str('title'),
    author: j.strOrNull('author'),
    description: j.strOrNull('description'),
    coverAssetId: j.strOrNull('cover_asset_id'),
    language: j.strOrNull('language') ?? 'ar',
    edition: j.strOrNull('edition'),
    isbn: j.strOrNull('isbn'),
    copyrightNotes: j.strOrNull('copyright_notes'),
    status: enumByName(
      PublishStatus.values,
      j.strOrNull('status'),
      PublishStatus.draft,
    ),
  );

  final String id;
  final String title;
  final String? author;
  final String? description;
  final String? coverAssetId;
  final String language;
  final String? edition;
  final String? isbn;
  final String? copyrightNotes;
  final PublishStatus status;

  Json toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'description': description,
    'cover_asset_id': coverAssetId,
    'language': language,
    'edition': edition,
    'isbn': isbn,
    'copyright_notes': copyrightNotes,
    'status': enumToDb(status),
  };
}

/// One level of an admin-defined book structure (e.g. depth 1 = Surah).
class BookStructureLevel {
  const BookStructureLevel({
    required this.id,
    required this.structureId,
    required this.depth,
    required this.nodeType,
    required this.labelSingular,
    required this.labelPlural,
    this.usesPage = false,
    this.usesChapter = false,
    this.usesSurah = false,
    this.usesVerses = false,
  });

  factory BookStructureLevel.fromJson(Json j) => BookStructureLevel(
    id: j.str('id'),
    structureId: j.str('structure_id'),
    depth: j.integer('depth'),
    nodeType: j.str('node_type'),
    labelSingular: j.str('label_singular'),
    labelPlural: j.str('label_plural'),
    usesPage: j.boolean('uses_page'),
    usesChapter: j.boolean('uses_chapter'),
    usesSurah: j.boolean('uses_surah'),
    usesVerses: j.boolean('uses_verses'),
  );

  final String id;
  final String structureId;
  final int depth;
  final String nodeType;
  final String labelSingular;
  final String labelPlural;
  final bool usesPage;
  final bool usesChapter;
  final bool usesSurah;
  final bool usesVerses;

  Json toJson() => {
    'id': id,
    'structure_id': structureId,
    'depth': depth,
    'node_type': nodeType,
    'label_singular': labelSingular,
    'label_plural': labelPlural,
    'uses_page': usesPage,
    'uses_chapter': usesChapter,
    'uses_surah': usesSurah,
    'uses_verses': usesVerses,
  };
}

/// A node in a course's curriculum tree (chapter, surah, page, section…).
/// [nodeType] is free-form data, never switched on for layout.
class CurriculumNode {
  const CurriculumNode({
    required this.id,
    required this.courseId,
    required this.nodeType,
    required this.title,
    required this.position,
    this.unitId,
    this.parentId,
    this.bookId,
    this.structureLevelId,
    this.description,
    this.referenceLabel,
    this.pageStart,
    this.pageEnd,
    this.chapterNumber,
    this.surahNumber,
    this.verseStart,
    this.verseEnd,
    this.metadata = const {},
    this.status = PublishStatus.published,
  });

  factory CurriculumNode.fromJson(Json j) => CurriculumNode(
    id: j.str('id'),
    courseId: j.str('course_id'),
    unitId: j.strOrNull('unit_id'),
    parentId: j.strOrNull('parent_id'),
    bookId: j.strOrNull('book_id'),
    structureLevelId: j.strOrNull('structure_level_id'),
    nodeType: j.strOrNull('node_type') ?? 'section',
    title: j.str('title'),
    description: j.strOrNull('description'),
    position: j.integer('position'),
    referenceLabel: j.strOrNull('reference_label'),
    pageStart: j.intOrNull('page_start'),
    pageEnd: j.intOrNull('page_end'),
    chapterNumber: j.intOrNull('chapter_number'),
    surahNumber: j.intOrNull('surah_number'),
    verseStart: j.intOrNull('verse_start'),
    verseEnd: j.intOrNull('verse_end'),
    metadata: j.obj('metadata'),
    status: enumByName(
      PublishStatus.values,
      j.strOrNull('status'),
      PublishStatus.draft,
    ),
  );

  final String id;
  final String courseId;
  final String? unitId;
  final String? parentId;
  final String? bookId;
  final String? structureLevelId;
  final String nodeType;
  final String title;
  final String? description;
  final int position;
  final String? referenceLabel;
  final int? pageStart;
  final int? pageEnd;
  final int? chapterNumber;
  final int? surahNumber;
  final int? verseStart;
  final int? verseEnd;
  final Json metadata;
  final PublishStatus status;

  /// Human-readable locator built from whichever references are set.
  String? get locator {
    if (referenceLabel != null && referenceLabel!.isNotEmpty) {
      return referenceLabel;
    }
    final parts = <String>[];
    if (surahNumber != null) parts.add('Surah $surahNumber');
    if (verseStart != null) {
      parts.add(
        verseEnd != null && verseEnd != verseStart
            ? 'Verses $verseStart–$verseEnd'
            : 'Verse $verseStart',
      );
    }
    if (chapterNumber != null) parts.add('Chapter $chapterNumber');
    if (pageStart != null) {
      parts.add(
        pageEnd != null && pageEnd != pageStart
            ? 'Pages $pageStart–$pageEnd'
            : 'Page $pageStart',
      );
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Json toJson() => {
    'id': id,
    'course_id': courseId,
    'unit_id': unitId,
    'parent_id': parentId,
    'book_id': bookId,
    'structure_level_id': structureLevelId,
    'node_type': nodeType,
    'title': title,
    'description': description,
    'position': position,
    'reference_label': referenceLabel,
    'page_start': pageStart,
    'page_end': pageEnd,
    'chapter_number': chapterNumber,
    'surah_number': surahNumber,
    'verse_start': verseStart,
    'verse_end': verseEnd,
    'metadata': metadata,
    'status': enumToDb(status),
  };
}

class Lesson {
  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.position,
    this.unitId,
    this.nodeId,
    this.summary,
    this.estimatedMinutes,
    this.isPreview = false,
    this.status = PublishStatus.published,
    this.contentVersion = 1,
    this.objectives = const [],
    this.deliveryLanguage,
    this.quranSurah,
    this.quranAyahStart,
    this.quranAyahEnd,
    this.metadata = const {},
    this.workRequired,
  });

  factory Lesson.fromJson(Json j) => Lesson(
    id: j.str('id'),
    courseId: j.str('course_id'),
    unitId: j.strOrNull('unit_id'),
    nodeId: j.strOrNull('node_id'),
    title: j.str('title'),
    summary: j.strOrNull('summary'),
    position: j.integer('position'),
    estimatedMinutes: j.intOrNull('estimated_minutes'),
    isPreview: j.boolean('is_preview'),
    status: enumByName(
      PublishStatus.values,
      j.strOrNull('status'),
      PublishStatus.draft,
    ),
    contentVersion: j.integer('content_version', fallback: 1),
    objectives: j.strList('objectives'),
    deliveryLanguage: j.strOrNull('delivery_language'),
    quranSurah: j.intOrNull('quran_surah'),
    quranAyahStart: j.intOrNull('quran_ayah_start'),
    quranAyahEnd: j.intOrNull('quran_ayah_end'),
    metadata: Map<String, dynamic>.from((j['metadata'] as Map?) ?? const {}),
    workRequired: j['work_required'] as bool?,
  );

  final String id;
  final String courseId;
  final String? unitId;
  final String? nodeId;
  final String title;
  final String? summary;
  final int position;
  final int? estimatedMinutes;
  final bool isPreview;
  final PublishStatus status;
  final int contentVersion;

  /// Measurable learning outcomes.
  final List<String> objectives;

  /// Overrides the course language when set (a language code).
  final String? deliveryLanguage;
  final int? quranSurah;
  final int? quranAyahStart;
  final int? quranAyahEnd;
  final Map<String, dynamic> metadata;

  /// Seeded content waiting for a teacher / scholar to confirm it.
  bool get needsReview => metadata['provisional'] == true;

  /// Needs handed-in work: this lesson's own setting, else the course's rule.
  final bool? workRequired;
  bool needsWork(Course course) => workRequired ?? course.progression.needsWork;

  String? get quranReference => quranSurah == null
      ? null
      : quranAyahStart == null
      ? '$quranSurah'
      : quranAyahEnd == null || quranAyahEnd == quranAyahStart
      ? '$quranSurah:$quranAyahStart'
      : '$quranSurah:$quranAyahStart–$quranAyahEnd';

  Json toJson() => {
    'id': id,
    'course_id': courseId,
    'objectives': objectives,
    'delivery_language': deliveryLanguage,
    'quran_surah': quranSurah,
    'quran_ayah_start': quranAyahStart,
    'quran_ayah_end': quranAyahEnd,
    'work_required': workRequired,
    'metadata': metadata,
    'unit_id': unitId,
    'node_id': nodeId,
    'title': title,
    'summary': summary,
    'position': position,
    'estimated_minutes': estimatedMinutes,
    'is_preview': isPreview,
    'status': enumToDb(status),
    'content_version': contentVersion,
  };
}

/// Row of `course_lesson_order()`: server-computed sequence + lock state.
class LessonOrderEntry {
  const LessonOrderEntry({
    required this.lessonId,
    required this.seq,
    required this.isUnlocked,
  });

  factory LessonOrderEntry.fromJson(Json j) => LessonOrderEntry(
    lessonId: j.str('lesson_id'),
    seq: j.integer('seq'),
    isUnlocked: j.boolean('is_unlocked'),
  );

  final String lessonId;
  final int seq;
  final bool isUnlocked;

  Json toJson() => {
    'lesson_id': lessonId,
    'seq': seq,
    'is_unlocked': isUnlocked,
  };
}

/// One finding from `course_publish_check`.
class PublishIssue {
  const PublishIssue(this.code, [this.count]);
  factory PublishIssue.fromJson(Json j) =>
      PublishIssue(j.str('code'), j.intOrNull('count'));
  final String code;
  final int? count;
}

/// What stands between a course and publishing. [errors] block it;
/// [warnings] are worth fixing but do not.
class PublishCheck {
  const PublishCheck({required this.errors, required this.warnings});
  factory PublishCheck.fromJson(Json j) => PublishCheck(
    errors: [
      for (final e in (j['errors'] as List? ?? const []))
        PublishIssue.fromJson(Map<String, dynamic>.from(e as Map)),
    ],
    warnings: [
      for (final e in (j['warnings'] as List? ?? const []))
        PublishIssue.fromJson(Map<String, dynamic>.from(e as Map)),
    ],
  );
  final List<PublishIssue> errors;
  final List<PublishIssue> warnings;
  bool get ready => errors.isEmpty;
}
