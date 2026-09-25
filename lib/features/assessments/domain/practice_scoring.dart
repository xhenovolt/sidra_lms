import 'assessment_models.dart';

class PracticeScore {
  const PracticeScore({
    required this.score,
    required this.maxScore,
    required this.passed,
    required this.correctByQuestion,
  });

  final double score;
  final double maxScore;
  final bool passed;
  final Map<String, bool> correctByQuestion;

  int get percent => maxScore == 0 ? 100 : (score / maxScore * 100).floor();
}

/// Scores a PRACTICE attempt on the device, using the same rule as the
/// server's submit_attempt(): a choice question is correct only when the
/// selected set equals the correct set exactly. Non-choice questions score 0
/// locally (a teacher grades those).
///
/// Throws [StateError] for graded assessments. Their answers are never on
/// the device, and their score must come from the server.
PracticeScore scorePractice(
  Assessment assessment,
  Map<String, Answer> answers,
) {
  if (!assessment.canTakeOffline) {
    throw StateError('Graded assessments are scored by the server only');
  }
  var score = 0.0;
  var max = 0.0;
  final correct = <String, bool>{};
  for (final q in assessment.questions) {
    max += q.points;
    if (!q.isChoice) continue;
    final expected = {
      for (final o in q.options)
        if (o.isCorrect == true) o.id,
    };
    final given = answers[q.id]?.selectedOptionIds ?? const <String>{};
    final ok =
        expected.isNotEmpty &&
        given.length == expected.length &&
        given.containsAll(expected);
    correct[q.id] = ok;
    if (ok) score += q.points;
  }
  final passed = max == 0 || (score / max * 100) >= assessment.passMarkPercent;
  return PracticeScore(
    score: score,
    maxScore: max,
    passed: passed,
    correctByQuestion: correct,
  );
}
