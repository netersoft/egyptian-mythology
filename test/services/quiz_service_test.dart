import 'package:egyptian_mythology/core/models/doc_category.dart';
import 'package:egyptian_mythology/core/services/documentation/documentation_service.dart';
import 'package:egyptian_mythology/core/services/i18n/translations.g.dart';
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

    // question_refs.json is shared by every locale: each question must point
    // at a documentation page that exists.
    test('every question links to an existing documentation page', () async {
      final docs = DocumentationService();
      final translations = await AppLocale.fr.build();
      final pages = {
        for (final category in [DocCategory.gods, DocCategory.cosmogonies, DocCategory.myths])
          for (final item in await docs.loadItems(category, 'fr', translations)) '${category.folder}/${item.id}',
      };

      for (final q in await quizService.loadQuestions(localeCode: 'fr')) {
        expect(pages, contains(q.ref), reason: '#${q.id}');
      }
    });

    test('every French question explains its answer', () async {
      for (final q in await quizService.loadQuestions(localeCode: 'fr')) {
        expect(q.explanation, isNotEmpty, reason: '#${q.id}');
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
