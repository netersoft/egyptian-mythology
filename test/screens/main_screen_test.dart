import 'package:egyptian_mythology/core/routes/app_route.dart';
import 'package:egyptian_mythology/core/routes/router.dart';
import 'package:egyptian_mythology/core/services/i18n/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_utils.dart';

void main() {
  setUp(() async {
    final mockScoresRepository = MockScoresRepository();
    when(mockScoresRepository.getAll).thenReturn([]);
    when(mockScoresRepository.getBestScore).thenReturn(0);

    await setupTestLocator(scoresRepository: mockScoresRepository);
    await LocaleSettings.setLocaleRaw('en');
  });

  tearDown(teardownTestLocator);

  // Not pumpAndSettle: the ankh footer's shake animation repeats forever by
  // design (matches the legacy app), so "settle" never arrives once it
  // starts — pump a bounded number of frames instead.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp.router(
            routerConfig: createRouter(
              initialLocation: const MainRoute().location,
              // Skips AppNavigatorObserver, which writes straight to a real
              // Hive `helper` box unrelated to what this test exercises.
              observers: const [],
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  group('MainScreen', () {
    testWidgets('renders all 5 main menu buttons', (tester) async {
      await pumpApp(tester);

      expect(find.text(t.documentation), findsOneWidget);
      expect(find.text(t.quiz), findsOneWidget);
      expect(find.text(t.stats), findsOneWidget);
      expect(find.text(t.settings), findsOneWidget);
      expect(find.text(t.about), findsOneWidget);
    });

    testWidgets('tapping Documentation navigates to the doc sections screen', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text(t.documentation));
      await settle(tester);

      // The doc sections placeholder shows the same label in its app bar.
      expect(find.text(t.documentation), findsWidgets);
    });

    testWidgets('tapping Quiz navigates to the instructions screen', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text(t.quiz));
      await settle(tester);

      expect(find.text(t.instructions), findsOneWidget);
    });

    testWidgets('tapping Stats navigates to the stats screen', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text(t.stats));
      await settle(tester);

      expect(find.text(t.noScore), findsOneWidget);
    });

    testWidgets('tapping Settings navigates to the settings screen', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text(t.settings));
      await settle(tester);

      expect(find.text(t.language), findsOneWidget);
    });

    testWidgets('tapping About navigates to the about screen', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text(t.about));
      await settle(tester);

      expect(find.text(t.appNameAlt), findsOneWidget);
    });

    testWidgets('back navigation shows the exit confirmation dialog', (tester) async {
      await pumpApp(tester);

      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(find.text(t.exitTitle), findsOneWidget);
      expect(find.text(t.exitMsg), findsOneWidget);
    });
  });
}
