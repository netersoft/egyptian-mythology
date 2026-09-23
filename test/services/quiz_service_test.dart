import 'package:egyptian_mythology/core/services/quiz/quiz_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final quizService = QuizService();

  group('QuizService', () {
    test('loads all 144 English questions with 4 choices each, answer included', () async {
      final questions = await quizService.loadQuestions(localeCode: 'en');

      expect(questions.length, 144);
      expect(questions.map((q) => q.id).toSet(), List.generate(144, (i) => i + 1).toSet());
      for (final q in questions) {
        expect(q.choices.length, 4);
        expect(q.choices, contains(q.answer));
        expect(q.question, isNotEmpty);
      }
    });

    test('loads all 144 French questions with 4 choices each, answer included', () async {
      final questions = await quizService.loadQuestions(localeCode: 'fr');

      expect(questions.length, 144);
      for (final q in questions) {
        expect(q.choices.length, 4);
        expect(q.choices, contains(q.answer));
      }
    });

    test('shuffles the question order', () async {
      final first = await quizService.loadQuestions(localeCode: 'en');
      final second = await quizService.loadQuestions(localeCode: 'en');

      expect(first.map((q) => q.id).toList(), isNot(second.map((q) => q.id).toList()));
    });

    // Catches names that lost their leading letter when the data was
    // translated from French (e.g. "Ouadjet" -> "uadjet" instead of "Wadjet").
    test('every bundled answer choice starts with a capital letter or a digit', () async {
      for (final code in ['fr', 'en', 'de', 'es', 'pt']) {
        final questions = await quizService.loadQuestions(localeCode: code);
        for (final q in questions) {
          for (final choice in q.choices) {
            expect(choice, isNot(matches(RegExp(r'^\p{Ll}', unicode: true))), reason: '$code #${q.id}: "$choice"');
          }
        }
      }
    });
  });
}
