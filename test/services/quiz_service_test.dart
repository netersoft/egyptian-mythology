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

    group('formatQuestion', () {
      test('adds a question mark when missing, preceded by a non-breaking space in French', () {
        expect(QuizService.formatQuestion('Qui est Osiris', 'fr'), 'Qui est Osiris\u00A0?');
        expect(QuizService.formatQuestion('Who is Osiris', 'en'), 'Who is Osiris?');
      });

      test('never doubles a question mark already in the source text', () {
        expect(QuizService.formatQuestion('Wer ist Osiris?', 'de'), 'Wer ist Osiris?');
        expect(QuizService.formatQuestion('¿Quién es Osiris?', 'es'), '¿Quién es Osiris?');
        expect(QuizService.formatQuestion('Qui est Osiris ?', 'fr'), 'Qui est Osiris\u00A0?');
      });

      test('trims surrounding whitespace', () {
        expect(QuizService.formatQuestion('  Who is Osiris  ', 'en'), 'Who is Osiris?');
      });
    });

    test('every bundled question ends with exactly one question mark, in every locale', () async {
      for (final code in ['fr', 'en', 'de', 'es', 'pt']) {
        final questions = await quizService.loadQuestions(localeCode: code);
        for (final q in questions) {
          expect(q.question, endsWith('?'), reason: '$code #${q.id}');
          expect(q.question, isNot(matches(r'\?\s*\?$')), reason: '$code #${q.id}');
        }
      }
    });
  });
}
