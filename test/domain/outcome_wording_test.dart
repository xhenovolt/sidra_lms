import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/features/lessons/presentation/lesson_screen.dart';

void main() {
  test('outcomes read naturally for learners', () {
    expect(
      learnerFacingOutcome('The learner names and pronounces ا ب ت.'),
      'Names and pronounces ا ب ت.',
    );
    expect(
      learnerFacingOutcome('the learner reads fluently'),
      'Reads fluently',
    );
    expect(learnerFacingOutcome('Reads short sūrahs.'), 'Reads short sūrahs.');
  });
}
