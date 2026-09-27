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

/// The splash ("from Almuntahha") stays for at least this long at launch,
/// even when the session restores instantly. Some phones skip Android's
/// own branding image, so this is the one everyone sees.
class SplashHold extends ValueNotifier<bool> {
  SplashHold() : super(true) {
    Future<void>.delayed(minimum, () => value = false);
  }

  /// No minimum (tests).
  SplashHold.released() : super(false);
  static const minimum = Duration(milliseconds: 1200);
  bool get holding => value;
}

final splashHoldProvider = Provider<SplashHold>((ref) {
  final h = SplashHold();
  ref.onDispose(h.dispose);
  return h;
});
