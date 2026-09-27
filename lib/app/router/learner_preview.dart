import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Preview as learner": an administrator sees the learner app exactly as
/// learners do (their home, tabs and catalogue). Display only: the database
/// still knows who they are and checks every action. Lasts until Exit or
/// sign-out.
class LearnerPreview extends ValueNotifier<bool> {
  LearnerPreview() : super(false);
  bool get on => value;
  set on(bool v) => value = v;
}

final learnerPreviewProvider = Provider<LearnerPreview>((ref) {
  final p = LearnerPreview();
  ref.onDispose(p.dispose);
  return p;
});
