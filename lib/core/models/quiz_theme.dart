import '../services/i18n/translations.g.dart';
import 'quiz_question_model.dart';

// A quiz restricted to one part of the documentation. A question belongs to
// the section its "learn more" page is in (question_refs.json).
enum QuizTheme {
  all,
  gods,
  cosmogonies,
  myths;

  bool includes(QuizQuestionModel question) => this == all || (question.ref?.startsWith('$name/') ?? false);

  String label(Translations t) => switch (this) {
    all => t.fullQuiz,
    gods => t.gods,
    cosmogonies => t.cosmogonies,
    myths => t.myths,
  };
}
