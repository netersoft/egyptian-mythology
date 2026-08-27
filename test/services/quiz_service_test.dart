import 'package:flutter_starter/core/services/quiz/quiz_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final quizService = QuizService();

  group('QuizService', () {
    test('loads all 101 English questions with 4 choices each, answer included', () async {
      final questions = await quizService.loadQuestions(localeCode: 'en');

      expect(questions.length, 101);
      expect(questions.map((q) => q.id).toSet(), List.generate(101, (i) => i + 1).toSet());
      for (final q in questions) {
        expect(q.choices.length, 4);
        expect(q.choices, contains(q.answer));
        expect(q.question, isNotEmpty);
      }
    });

    test('loads all 101 French questions with 4 choices each, answer included', () async {
      final questions = await quizService.loadQuestions(localeCode: 'fr');

      expect(questions.length, 101);
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
  });
}
