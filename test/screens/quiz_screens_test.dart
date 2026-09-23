import 'package:egyptian_mythology/core/models/quiz_mistake.dart';
import 'package:egyptian_mythology/core/models/quiz_question_model.dart';
import 'package:egyptian_mythology/core/models/quiz_theme.dart';
import 'package:egyptian_mythology/core/providers/quiz/quiz_review_provider.dart';
import 'package:egyptian_mythology/core/routes/app_route.dart';
import 'package:egyptian_mythology/core/routes/router.dart';
import 'package:egyptian_mythology/core/services/i18n/translations.g.dart';
import 'package:egyptian_mythology/view/screens/quiz/quiz_play_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_utils.dart';

void main() {
  setUp(() async {
    await setupTestLocator();
    await LocaleSettings.setLocaleRaw('en');
  });

  tearDown(teardownTestLocator);

  // Not pumpAndSettle: MainRoute (infinite-shake ankh footer) stays mounted
  // underneath every nested route, and QuizPlayScreen runs a real 1s
  // countdown Timer.periodic -- neither ever "settles".
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
  }

  Future<void> pumpAt(WidgetTester tester, String location, {List<Override> overrides = const []}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: TranslationProvider(
          child: MaterialApp.router(
            routerConfig: createRouter(initialLocation: location, observers: const []),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  group('InstructionsScreen', () {
    testWidgets("renders the instructions and navigates to the quiz on Let's play", (tester) async {
      await pumpAt(tester, const InstructionsRoute().location);

      expect(find.text(t.instructions), findsOneWidget);

      await tester.tap(find.text(t.letsPlay));
      await settle(tester);

      expect(find.text('Score: 0'), findsOneWidget);
    });
  });

  group('InstructionsScreen themes', () {
    testWidgets('starts a game on the chosen theme', (tester) async {
      await pumpAt(tester, const InstructionsRoute().location);

      await tester.tap(find.byKey(const ValueKey('quiz_theme_myths')));
      await tester.pump();
      await tester.tap(find.text(t.letsPlay));
      await settle(tester);

      expect(tester.widget<QuizPlayScreen>(find.byType(QuizPlayScreen)).theme, QuizTheme.myths);
    });
  });

  group('QuizPlayScreen', () {
    testWidgets('loads and displays the first question with 4 answer choices', (tester) async {
      await pumpAt(tester, const QuizPlayRoute().location);

      expect(find.text('Score: 0'), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(4));
    });

    testWidgets('backgrounding the app pauses the quiz until the player taps Resume', (tester) async {
      await pumpAt(tester, const QuizPlayRoute().location);

      // The test binding stops producing frames while hidden/paused, so the
      // overlay is checked once back in the foreground -- which is also what
      // the player actually sees.
      [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text(t.quizPaused), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('quiz_resume')));
      await tester.pump();
      expect(find.text(t.quizPaused), findsNothing);
    });
  });

  group('GameOverScreen', () {
    testWidgets('shows congratulations when all questions were answered', (tester) async {
      await pumpAt(tester, const GameOverRoute(score: 340, finish: true, isRecord: false).location);

      expect(find.text(t.congratulations), findsOneWidget);
      expect(find.text('Score: 340'), findsWidgets);
    });

    testWidgets('shows "well done" (no congrat banner text) when lives ran out with a positive score', (tester) async {
      await pumpAt(tester, const GameOverRoute(score: 50, finish: false, isRecord: false).location);

      expect(find.text(t.bravo), findsOneWidget);
      expect(find.text(t.congratulations), findsNothing);
    });

    testWidgets('shows the record label when isRecord is true', (tester) async {
      await pumpAt(tester, const GameOverRoute(score: 999, finish: true, isRecord: true).location);

      expect(find.text(t.scoreRecord), findsOneWidget);
    });

    testWidgets('hides the record label when isRecord is false', (tester) async {
      await pumpAt(tester, const GameOverRoute(score: 10, finish: false, isRecord: false).location);

      expect(find.text(t.scoreRecord), findsNothing);
    });

    testWidgets('the Main Menu action navigates back to MainScreen', (tester) async {
      await pumpAt(tester, const GameOverRoute(score: 0, finish: false, isRecord: false).location);

      await tester.tap(find.byIcon(Icons.home));
      await settle(tester);

      expect(find.text(t.documentation), findsOneWidget);
    });
  });

  group('QuizReviewScreen', () {
    testWidgets('the game-over screen offers the review only after mistakes', (tester) async {
      await pumpAt(tester, const GameOverRoute(score: 10, finish: false, isRecord: false).location);
      expect(find.byKey(const ValueKey('review_mistakes')), findsNothing);
    });

    testWidgets('lists each mistake with the right answer and opens the page that covers it', (tester) async {
      await pumpAt(
        tester,
        const GameOverRoute(score: 10, finish: false, isRecord: false).location,
        overrides: [quizReviewProvider.overrideWith(_OneMistake.new)],
      );
      await tester.tap(find.byKey(const ValueKey('review_mistakes')));
      await settle(tester);

      expect(find.text(t.yourAnswer(value: 'Anubis')), findsOneWidget);
      expect(find.text(t.correctAnswer(value: 'Osiris')), findsOneWidget);
      expect(find.textContaining('rules the afterlife', findRichText: true), findsOneWidget);

      await tester.tap(find.text(t.learnMore));
      await settle(tester);

      expect(find.descendant(of: find.byType(AppBar), matching: find.text(t.osiris)), findsOneWidget);
    });
  });
}

class _OneMistake extends QuizReview {
  @override
  List<QuizMistake> build() => const [
    QuizMistake(
      question: QuizQuestionModel(
        id: 1,
        question: 'Who judges the dead?',
        answer: 'Osiris',
        choices: ['Osiris', 'Anubis', 'Thoth', 'Horus'],
        explanation: 'Osiris rules the afterlife.',
        ref: 'gods/osiris',
      ),
      given: 'Anubis',
    ),
  ];
}
