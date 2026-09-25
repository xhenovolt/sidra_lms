import '../../../shared/models/json.dart';

enum PublishStatus { draft, published, archived }

enum Difficulty { beginner, intermediate, advanced }

enum CourseAccess { free, paid, restricted }

enum Progression { teacherGated, sequential, open }

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
    this.progression = Progression.teacherGated,
    this.status = PublishStatus.draft,
    this.estimatedHours,
    this.learningObjectives = const [],
    this.prerequisites,
    this.contentVersion = 1,
    this.updatedAt,
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
  final Progression progression;
  final PublishStatus status;
  final double? estimatedHours;
  final List<String> learningObjectives;
  final String? prerequisites;
  final int contentVersion;
  final DateTime? updatedAt;

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
    'progression': enumToDb(progression),
    'status': enumToDb(status),
    'estimated_hours': estimatedHours,
    'learning_objectives': learningObjectives,
    'prerequisites': prerequisites,
    'content_version': contentVersion,
    'updated_at': updatedAt?.toIso8601String(),
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

  Json toJson() => {
    'id': id,
    'course_id': courseId,
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
