import 'package:egyptian_mythology/core/models/score_entry_model.dart';
import 'package:egyptian_mythology/core/routes/app_route.dart';
import 'package:egyptian_mythology/core/routes/router.dart';
import 'package:egyptian_mythology/core/services/i18n/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_utils.dart';

void main() {
  late MockScoresRepository mockScoresRepository;
  late List<ScoreEntryModel> scores;
  var bestScore = 0;

  // The real app gets intl date symbols loaded by GlobalMaterialLocalizations;
  // these tests pump a bare MaterialApp, so load them explicitly.
  setUpAll(initializeDateFormatting);

  setUp(() async {
    mockScoresRepository = MockScoresRepository();
    scores = [];
    bestScore = 0;

    when(() => mockScoresRepository.getAll()).thenAnswer((_) => scores);
    when(() => mockScoresRepository.getBestScore()).thenAnswer((_) => bestScore);
    when(() => mockScoresRepository.clear()).thenAnswer((_) async {
      scores = [];
      bestScore = 0;
    });

    await setupTestLocator(scoresRepository: mockScoresRepository);
    await LocaleSettings.setLocaleRaw('en');
  });

  tearDown(teardownTestLocator);

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

  group('StatsScreen', () {
    testWidgets('shows the empty state and a best score of 0 when no scores were recorded', (tester) async {
      await pumpAt(tester, const StatsRoute().location);

      expect(find.text(t.noScore), findsOneWidget);
      expect(find.text('Best Score: 0'), findsOneWidget);
    });

    group('with existing scores', () {
      setUp(() {
        scores = [
          ScoreEntryModel(score: 100, playedAt: DateTime(2024, 1, 1, 10)),
          ScoreEntryModel(score: 250, playedAt: DateTime(2024, 1, 2, 11, 5)),
        ];
        bestScore = 250;
      });

      testWidgets('lists recorded scores and the current best score', (tester) async {
        await pumpAt(tester, const StatsRoute().location);

        expect(find.text(t.noScore), findsNothing);
        expect(find.text('100'), findsOneWidget);
        expect(find.text('250'), findsOneWidget);
        expect(find.text('Best Score: 250'), findsOneWidget);
      });

      testWidgets('formats score dates in the current app language', (tester) async {
        await pumpAt(tester, const StatsRoute().location);
        expect(find.text('Jan 2, 2024 11:05'), findsOneWidget);

        await LocaleSettings.setLocaleRaw('fr');
        await pumpAt(tester, const StatsRoute().location);
        expect(find.text('2 janv. 2024 11:05'), findsOneWidget);
      });

      testWidgets('falls back to the raw legacy string for an unparseable old entry', (tester) async {
        scores = [const ScoreEntryModel(score: 40, date: 'garbled')];
        await pumpAt(tester, const StatsRoute().location);

        expect(find.text('garbled'), findsOneWidget);
      });

      testWidgets('Delete asks for confirmation and clears the history when confirmed', (tester) async {
        await pumpAt(tester, const StatsRoute().location);
        await tester.tap(find.text(t.delete));
        await settle(tester);

        expect(find.text(t.confirmDeleteScores), findsOneWidget);

        await tester.tap(find.text(t.yes));
        await settle(tester);

        verify(() => mockScoresRepository.clear()).called(1);
        expect(find.text(t.noScore), findsOneWidget);
        expect(find.text('Best Score: 0'), findsOneWidget);
      });

      testWidgets('Delete does nothing when cancelled', (tester) async {
        await pumpAt(tester, const StatsRoute().location);
        await tester.tap(find.text(t.delete));
        await settle(tester);

        await tester.tap(find.text(t.cancel));
        await settle(tester);

        verifyNever(() => mockScoresRepository.clear());
        expect(find.text('100'), findsOneWidget);
      });

      testWidgets('Progress opens the score progression chart', (tester) async {
        await pumpAt(tester, const StatsRoute().location);
        await tester.tap(find.text(t.progress));
        await settle(tester);

        expect(find.text(t.scoresProgress), findsOneWidget);
      });
    });
  });
}
