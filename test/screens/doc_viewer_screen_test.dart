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

  // Not pumpAndSettle: MainRoute (and its infinite-shake ankh footer) stays
  // mounted underneath every nested route pushed on top of it, same as in
  // main_screen_test.dart — pump a bounded number of frames instead.
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

  group('DocSectionsScreen', () {
    testWidgets('renders the 3 category buttons', (tester) async {
      await pumpAt(tester, const DocSectionsRoute().location);

      expect(find.text(t.gods), findsOneWidget);
      expect(find.text(t.cosmogonies), findsOneWidget);
      expect(find.text(t.myths), findsOneWidget);
    });
  });

  group('DocViewerScreen', () {
    testWidgets('gods: opens on the Introduction item and lists all deities in the drawer', (tester) async {
      await pumpAt(tester, const GodsDocRoute().location);

      expect(find.text(t.introTitle), findsWidgets);

      await tester.tap(find.byIcon(Icons.menu));
      await settle(tester);

      expect(find.widgetWithText(ListTile, t.anubis), findsOneWidget);
    });

    testWidgets('selecting a deity from the drawer loads its content', (tester) async {
      await pumpAt(tester, const GodsDocRoute().location);

      await tester.tap(find.byIcon(Icons.menu));
      await settle(tester);
      await tester.tap(find.widgetWithText(ListTile, t.anubis));
      await settle(tester);

      expect(find.text(t.anubis), findsWidgets);
    });

    testWidgets('cosmogonies: lists Heliopolis in the drawer', (tester) async {
      await pumpAt(tester, const CosmogoniesDocRoute().location);

      await tester.tap(find.byIcon(Icons.menu));
      await settle(tester);

      expect(find.widgetWithText(ListTile, t.heliopolisTitle), findsOneWidget);
    });

    testWidgets('myths: lists the Osirian myth in the drawer', (tester) async {
      await pumpAt(tester, const MythsDocRoute().location);

      await tester.tap(find.byIcon(Icons.menu));
      await settle(tester);

      expect(find.widgetWithText(ListTile, t.mythOsirienTitle), findsOneWidget);
    });
  });
}
