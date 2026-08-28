import 'package:egyptian_mythology/core/routes/app_route.dart';
import 'package:egyptian_mythology/core/routes/router.dart';
import 'package:egyptian_mythology/core/services/i18n/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> pumpAt(WidgetTester tester, String location) async {
    await tester.pumpWidget(
      ProviderScope(
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

  group('QuizPlayScreen', () {
    testWidgets('loads and displays the first question with 4 answer choices', (tester) async {
      await pumpAt(tester, const QuizPlayRoute().location);

      expect(find.text('Score: 0'), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(4));
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
}
