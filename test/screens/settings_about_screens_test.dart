import 'package:egyptian_mythology/core/routes/app_route.dart';
import 'package:egyptian_mythology/core/routes/router.dart';
import 'package:egyptian_mythology/core/services/i18n/translations.g.dart';
import 'package:egyptian_mythology/view/screens/other/credits_screen.dart';
import 'package:egyptian_mythology/view/screens/other/privacy_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_utils.dart';

void main() {
  late MockAudioService mockAudioService;

  setUp(() async {
    mockAudioService = MockAudioService();
    when(mockAudioService.startMusic).thenAnswer((_) async {});
    when(mockAudioService.playClick).thenAnswer((_) async {});
    when(() => mockAudioService.isMusicEnabled).thenReturn(true);
    when(() => mockAudioService.isSoundEnabled).thenReturn(true);
    when(() => mockAudioService.setMusicEnabled(any())).thenAnswer((_) async {});
    when(() => mockAudioService.setSoundEnabled(any())).thenAnswer((_) async {});

    await setupTestLocator(audioService: mockAudioService);
    await LocaleSettings.setLocaleRaw('en');
  });

  tearDown(teardownTestLocator);

  // Not pumpAndSettle: MainRoute (infinite-shake ankh footer) stays mounted
  // underneath every nested route, same as in main_screen_test.dart.
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

  group('SettingsScreen', () {
    testWidgets('renders language, music, and sound tiles', (tester) async {
      await pumpAt(tester, const SettingsRoute().location);

      expect(find.text(t.language), findsOneWidget);
      expect(find.text(t.music), findsOneWidget);
      expect(find.text(t.song), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(2));
    });

    testWidgets('toggling the sound switch calls AudioService.setSoundEnabled(false)', (tester) async {
      await pumpAt(tester, const SettingsRoute().location);

      await tester.tap(find.byType(Switch).first);
      await settle(tester);

      verify(() => mockAudioService.setSoundEnabled(false)).called(1);
    });

    testWidgets('toggling the music switch calls AudioService.setMusicEnabled(false)', (tester) async {
      await pumpAt(tester, const SettingsRoute().location);

      await tester.tap(find.byType(Switch).last);
      await settle(tester);

      verify(() => mockAudioService.setMusicEnabled(false)).called(1);
    });
  });

  group('AboutScreen', () {
    testWidgets('renders app name, credits, and the contact/rate/share actions', (tester) async {
      await pumpAt(tester, const AboutRoute().location);

      expect(find.text(t.appNameAlt), findsOneWidget);
      expect(find.text(t.credits), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('opens the sources and credits page', (tester) async {
      await pumpAt(tester, const AboutRoute().location);

      await tester.ensureVisible(find.byKey(const ValueKey('about_credits')));
      await tester.tap(find.byKey(const ValueKey('about_credits')));
      await settle(tester);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await settle(tester);

      expect(find.byType(CreditsScreen), findsOneWidget);
      expect(find.textContaining('Jeff Dahl', findRichText: true), findsWidgets);
    });

    testWidgets('opens the privacy policy', (tester) async {
      await pumpAt(tester, const AboutRoute().location);

      await tester.ensureVisible(find.byKey(const ValueKey('about_privacy')));
      await tester.tap(find.byKey(const ValueKey('about_privacy')));
      await settle(tester);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await settle(tester);

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.textContaining('No data collected', findRichText: true), findsWidgets);
    });
  });
}
