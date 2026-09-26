import '../../../shared/models/json.dart';
import 'external_link.dart';

/// A typed piece of lesson content. Lessons are an ordered list of these,
/// so a lesson can mix text, Quranic Arabic, audio, video, images and quizzes
/// in any sequence the teacher chooses.
sealed class ContentBlock {
  const ContentBlock({required this.id, required this.position});

  final String id;
  final int position;

  /// Parses a `lesson_content_blocks` row. Unknown types (added to the
  /// database after this app version) become [UnknownBlock] rather than
  /// crashing, so older apps keep working.
  static ContentBlock fromJson(Json j) {
    final id = j.str('id');
    final position = j.integer('position');
    final body = j.obj('body');
    final media = j.strOrNull('media_asset_id');
    final type = j.strOrNull('block_type');

    String text([String key = 'text']) => (body[key] as String?) ?? '';

    return switch (type) {
      'heading' => HeadingBlock(
        id: id,
        position: position,
        text: text(),
        level: (body['level'] as num?)?.toInt() ?? 2,
      ),
      'rich_text' => RichTextBlock(
        id: id,
        position: position,
        text: text(),
        isMarkdown: (body['format'] as String? ?? 'markdown') == 'markdown',
      ),
      'image' when media != null => ImageBlock(
        id: id,
        position: position,
        mediaAssetId: media,
        caption: body['caption'] as String?,
      ),
      'audio' when media != null => AudioBlock(
        id: id,
        position: position,
        mediaAssetId: media,
        title: body['title'] as String?,
        transcript: body['transcript'] as String?,
      ),
      'video' when media != null => VideoBlock(
        id: id,
        position: position,
        mediaAssetId: media,
        title: body['title'] as String?,
      ),
      'attachment' when media != null => AttachmentBlock(
        id: id,
        position: position,
        mediaAssetId: media,
        title: body['title'] as String? ?? 'Attachment',
      ),
      'quran_text' => QuranTextBlock(
        id: id,
        position: position,
        arabic: text('arabic'),
        surah: (body['surah'] as num?)?.toInt(),
        verseStart: (body['verse_start'] as num?)?.toInt(),
        verseEnd: (body['verse_end'] as num?)?.toInt(),
      ),
      'translation' => TranslationBlock(
        id: id,
        position: position,
        text: text(),
        language: body['language'] as String? ?? 'en',
        translator: body['translator'] as String?,
      ),
      'transliteration' => TransliterationBlock(
        id: id,
        position: position,
        text: text(),
      ),
      'reference' => ReferenceBlock(
        id: id,
        position: position,
        citation: text('citation'),
        source: body['source'] as String?,
        url: body['url'] as String?,
      ),
      'callout' => CalloutBlock(
        id: id,
        position: position,
        text: text(),
        tone: switch (body['tone']) {
          'warning' => CalloutTone.warning,
          'note' => CalloutTone.note,
          _ => CalloutTone.info,
        },
      ),
      'assessment' when j.strOrNull('assessment_id') != null => AssessmentBlock(
        id: id,
        position: position,
        assessmentId: j.str('assessment_id'),
      ),
      'divider' => DividerBlock(id: id, position: position),
      'external_link' => switch (parseExternalLink(text('url'))) {
        final uri? => ExternalLinkBlock(
          id: id,
          position: position,
          uri: uri,
          title: body['title'] as String?,
          description: body['description'] as String?,
        ),
        null => UnknownBlock(id: id, position: position, type: 'external_link'),
      },
      _ => UnknownBlock(id: id, position: position, type: type ?? 'null'),
    };
  }

  /// Media asset referenced by this block, if any (for downloads).
  String? get mediaAssetId => switch (this) {
    ImageBlock(:final mediaAssetId) ||
    AudioBlock(:final mediaAssetId) ||
    VideoBlock(:final mediaAssetId) ||
    AttachmentBlock(:final mediaAssetId) => mediaAssetId,
    _ => null,
  };
}

class HeadingBlock extends ContentBlock {
  const HeadingBlock({
    required super.id,
    required super.position,
    required this.text,
    this.level = 2,
  });
  final String text;
  final int level;
}

class RichTextBlock extends ContentBlock {
  const RichTextBlock({
    required super.id,
    required super.position,
    required this.text,
    this.isMarkdown = true,
  });
  final String text;
  final bool isMarkdown;
}

class ImageBlock extends ContentBlock {
  const ImageBlock({
    required super.id,
    required super.position,
    required this.mediaAssetId,
    this.caption,
  });
  @override
  final String mediaAssetId;
  final String? caption;
}

class AudioBlock extends ContentBlock {
  const AudioBlock({
    required super.id,
    required super.position,
    required this.mediaAssetId,
    this.title,
    this.transcript,
  });
  @override
  final String mediaAssetId;
  final String? title;
  final String? transcript;
}

class VideoBlock extends ContentBlock {
  const VideoBlock({
    required super.id,
    required super.position,
    required this.mediaAssetId,
    this.title,
  });
  @override
  final String mediaAssetId;
  final String? title;
}

class AttachmentBlock extends ContentBlock {
  const AttachmentBlock({
    required super.id,
    required super.position,
    required this.mediaAssetId,
    required this.title,
  });
  @override
  final String mediaAssetId;
  final String title;
}

class QuranTextBlock extends ContentBlock {
  const QuranTextBlock({
    required super.id,
    required super.position,
    required this.arabic,
    this.surah,
    this.verseStart,
    this.verseEnd,
  });
  final String arabic;
  final int? surah;
  final int? verseStart;
  final int? verseEnd;

  String? get reference {
    if (surah == null) return null;
    if (verseStart == null) return '$surah';
    if (verseEnd == null || verseEnd == verseStart) return '$surah:$verseStart';
    return '$surah:$verseStart–$verseEnd';
  }
}

class TranslationBlock extends ContentBlock {
  const TranslationBlock({
    required super.id,
    required super.position,
    required this.text,
    required this.language,
    this.translator,
  });
  final String text;
  final String language;
  final String? translator;
}

class TransliterationBlock extends ContentBlock {
  const TransliterationBlock({
    required super.id,
    required super.position,
    required this.text,
  });
  final String text;
}

class ReferenceBlock extends ContentBlock {
  const ReferenceBlock({
    required super.id,
    required super.position,
    required this.citation,
    this.source,
    this.url,
  });
  final String citation;
  final String? source;
  final String? url;
}

enum CalloutTone { info, note, warning }

class CalloutBlock extends ContentBlock {
  const CalloutBlock({
    required super.id,
    required super.position,
    required this.text,
    this.tone = CalloutTone.info,
  });
  final String text;
  final CalloutTone tone;
}

class AssessmentBlock extends ContentBlock {
  const AssessmentBlock({
    required super.id,
    required super.position,
    required this.assessmentId,
  });
  final String assessmentId;
}

class DividerBlock extends ContentBlock {
  const DividerBlock({required super.id, required super.position});
}

class UnknownBlock extends ContentBlock {
  const UnknownBlock({
    required super.id,
    required super.position,
    required this.type,
  });
  final String type;
}

/// A link to material hosted elsewhere (YouTube, Telegram, a website).
class ExternalLinkBlock extends ContentBlock {
  const ExternalLinkBlock({
    required super.id,
    required super.position,
    required this.uri,
    this.title,
    this.description,
  });
  final Uri uri;
  final String? title;
  final String? description;

  LinkProvider get provider => linkProviderOf(uri);
}
