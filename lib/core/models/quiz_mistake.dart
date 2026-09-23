import 'quiz_question_model.dart';

// A question the player got wrong, or let the timer run out on ([given] is
// then null), kept for the review after the game.
class QuizMistake {
  final QuizQuestionModel question;
  final String? given;

  const QuizMistake({required this.question, this.given});
}
