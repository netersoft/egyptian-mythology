import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/quiz_mistake.dart';

part 'quiz_review_provider.g.dart';

// Mistakes of the last finished game. Kept alive because QuizController is
// autoDispose and goes away with QuizPlayScreen, while the game-over screen
// and the review read these afterwards.
@Riverpod(keepAlive: true)
class QuizReview extends _$QuizReview {
  @override
  List<QuizMistake> build() => const [];

  void set(List<QuizMistake> mistakes) => state = List.unmodifiable(mistakes);
}
