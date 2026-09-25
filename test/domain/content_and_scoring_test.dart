import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/features/assessments/domain/assessment_models.dart';
import 'package:sidra_lms/features/assessments/domain/practice_scoring.dart';
import 'package:sidra_lms/features/lessons/domain/content_blocks.dart';
import 'package:sidra_lms/features/progress/domain/progress_models.dart';

Map<String, dynamic> block(
  String type, {
  Map<String, dynamic> body = const {},
  String? media,
  String? assessment,
}) => {
  'id': 'b-$type',
  'position': 0,
  'block_type': type,
  'body': body,
  'media_asset_id': media,
  'assessment_id': assessment,
};

void main() {
  group('ContentBlock.fromJson', () {
    test('parses every supported type', () {
      final parsed = [
        block('heading', body: {'text': 'Intro', 'level': 1}),
        block('rich_text', body: {'text': '**bold**'}),
        block('image', media: 'm1', body: {'caption': 'Alif'}),
        block('audio', media: 'm2'),
        block('video', media: 'm3'),
        block('attachment', media: 'm4', body: {'title': 'Worksheet'}),
        block(
          'quran_text',
          body: {'arabic': 'بِسْمِ ٱللَّهِ', 'surah': 1, 'verse_start': 1},
        ),
        block(
          'translation',
          body: {'text': 'In the name of Allah', 'language': 'en'},
        ),
        block('transliteration', body: {'text': 'Bismillah'}),
        block('reference', body: {'citation': 'Sahih al-Bukhari 1'}),
        block('callout', body: {'text': 'Note', 'tone': 'warning'}),
        block('assessment', assessment: 'a1'),
        block('divider'),
      ].map(ContentBlock.fromJson).toList();

      expect(parsed.map((b) => b.runtimeType), [
        HeadingBlock,
        RichTextBlock,
        ImageBlock,
        AudioBlock,
        VideoBlock,
        AttachmentBlock,
        QuranTextBlock,
        TranslationBlock,
        TransliterationBlock,
        ReferenceBlock,
        CalloutBlock,
        AssessmentBlock,
        DividerBlock,
      ]);
      expect((parsed[6] as QuranTextBlock).reference, '1:1');
      expect((parsed[10] as CalloutBlock).tone, CalloutTone.warning);
      expect(parsed.map((b) => b.mediaAssetId).whereType<String>(), [
        'm1',
        'm2',
        'm3',
        'm4',
      ]);
    });

    test('unknown future block types degrade gracefully', () {
      final b = ContentBlock.fromJson(block('interactive_map'));
      expect(b, isA<UnknownBlock>());
      expect((b as UnknownBlock).type, 'interactive_map');
    });

    test('media block without media becomes unknown, not a crash', () {
      expect(ContentBlock.fromJson(block('audio')), isA<UnknownBlock>());
    });
  });

  group('scorePractice', () {
    Assessment quiz({AssessmentKind kind = AssessmentKind.practice}) =>
        Assessment(
          id: 'a',
          courseId: 'c',
          title: 'Quiz',
          kind: kind,
          grading: GradingMode.auto,
          passMarkPercent: 50,
          questions: const [
            Question(
              id: 'q1',
              assessmentId: 'a',
              position: 0,
              type: QuestionType.singleChoice,
              prompt: 'Verses in Al-Fatihah?',
              points: 1,
              options: [
                AnswerOption(
                  id: 'o1',
                  questionId: 'q1',
                  position: 0,
                  label: '5',
                  isCorrect: false,
                ),
                AnswerOption(
                  id: 'o2',
                  questionId: 'q1',
                  position: 1,
                  label: '7',
                  isCorrect: true,
                ),
              ],
            ),
            Question(
              id: 'q2',
              assessmentId: 'a',
              position: 1,
              type: QuestionType.multipleChoice,
              prompt: 'Pick the Makki surahs',
              points: 2,
              options: [
                AnswerOption(
                  id: 'x',
                  questionId: 'q2',
                  position: 0,
                  label: 'Al-Fatihah',
                  isCorrect: true,
                ),
                AnswerOption(
                  id: 'y',
                  questionId: 'q2',
                  position: 1,
                  label: 'Al-Ikhlas',
                  isCorrect: true,
                ),
                AnswerOption(
                  id: 'z',
                  questionId: 'q2',
                  position: 2,
                  label: 'Al-Baqarah',
                  isCorrect: false,
                ),
              ],
            ),
          ],
        );

    test('exact set match required for multiple choice', () {
      final r = scorePractice(quiz(), {
        'q1': const Answer(questionId: 'q1', selectedOptionIds: {'o2'}),
        'q2': const Answer(questionId: 'q2', selectedOptionIds: {'x'}),
      });
      expect(r.score, 1);
      expect(r.maxScore, 3);
      expect(r.correctByQuestion, {'q1': true, 'q2': false});
      expect(r.passed, isFalse); // 33% < 50%
    });

    test('all correct passes; unanswered counts as wrong', () {
      final r = scorePractice(quiz(), {
        'q2': const Answer(questionId: 'q2', selectedOptionIds: {'x', 'y'}),
      });
      expect(r.score, 2);
      expect(r.percent, 66);
      expect(r.passed, isTrue);
      expect(r.correctByQuestion['q1'], isFalse);
    });

    test('refuses to score graded assessments on the device', () {
      expect(
        () => scorePractice(quiz(kind: AssessmentKind.graded), const {}),
        throwsStateError,
      );
    });
  });

  group('LessonProgress.mergeWith', () {
    final t0 = DateTime.utc(2026, 1, 1);
    LessonProgress p(
      ProgressStatus s,
      DateTime at, {
      Map<String, dynamic> pos = const {},
      bool synced = true,
    }) => LessonProgress(
      lessonId: 'l',
      courseId: 'c',
      status: s,
      lastPosition: pos,
      updatedAt: at,
      synced: synced,
      completedAt: s == ProgressStatus.completed ? at : null,
    );

    test('completion is sticky even if the newer update is in_progress', () {
      final merged = p(ProgressStatus.completed, t0).mergeWith(
        p(ProgressStatus.inProgress, t0.add(const Duration(hours: 1))),
      );
      expect(merged.status, ProgressStatus.completed);
      expect(merged.completedAt, t0);
    });

    test('position follows the newest update', () {
      final merged = p(ProgressStatus.inProgress, t0, pos: {'block': 5})
          .mergeWith(
            p(
              ProgressStatus.inProgress,
              t0.subtract(const Duration(minutes: 5)),
              pos: {'block': 1},
            ),
          );
      expect(merged.lastPosition['block'], 5);
    });

    test('unsynced local change stays marked unsynced', () {
      final merged = p(
        ProgressStatus.inProgress,
        t0,
      ).mergeWith(p(ProgressStatus.inProgress, t0, synced: false));
      expect(merged.synced, isFalse);
    });
  });

  test('CourseProgressSummary flags learners waiting for their teacher', () {
    final s = CourseProgressSummary.fromJson({
      'course_id': 'c',
      'enrolment_id': 'e',
      'enrolment_status': 'active',
      'total_lessons': 10,
      'completed_lessons': 3,
      'unlocked_lessons': 3,
      'progress_percent': 30,
      'next_lesson_id': null,
    });
    expect(s.awaitingTeacher, isTrue);
    expect(s.isActive, isTrue);
  });
}
