import 'package:egyptian_mythology/core/models/doc_category.dart';
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
    testWidgets('renders the 4 category buttons and search', (tester) async {
      await pumpAt(tester, const DocSectionsRoute().location);

      expect(find.text(t.gods), findsOneWidget);
      expect(find.text(t.cosmogonies), findsOneWidget);
      expect(find.text(t.myths), findsOneWidget);
      expect(find.text(t.reference), findsOneWidget);
      expect(find.text(t.search), findsOneWidget);
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

  group('DocViewerScreen previous/next pager', () {
    final previousCard = find.byKey(const ValueKey('doc_previous_page'));
    final nextCard = find.byKey(const ValueKey('doc_next_page'));

    Future<void> tapCard(WidgetTester tester, Finder card) async {
      await tester.ensureVisible(card);
      await settle(tester);
      await tester.tap(card);
      await settle(tester);
    }

    testWidgets('first page shows only a next card, titled after the following page', (tester) async {
      await pumpAt(tester, const CosmogoniesDocRoute().location);
      await tester.ensureVisible(nextCard);

      expect(previousCard, findsNothing);
      expect(find.descendant(of: nextCard, matching: find.text(t.next)), findsOneWidget);
      expect(find.descendant(of: nextCard, matching: find.text(t.heliopolisTitle)), findsOneWidget);
    });

    testWidgets('tapping next loads the following page, which links back to the previous one', (tester) async {
      await pumpAt(tester, const CosmogoniesDocRoute().location);
      await tapCard(tester, nextCard);

      expect(find.descendant(of: find.byType(AppBar), matching: find.text(t.heliopolisTitle)), findsOneWidget);
      await tester.ensureVisible(previousCard);
      expect(find.descendant(of: previousCard, matching: find.text(t.introTitle)), findsOneWidget);
      expect(find.descendant(of: nextCard, matching: find.text(t.hermopolisTitle)), findsOneWidget);

      await tapCard(tester, previousCard);

      expect(find.descendant(of: find.byType(AppBar), matching: find.text(t.introTitle)), findsOneWidget);
    });

    testWidgets('last page shows only a previous card', (tester) async {
      await pumpAt(tester, const MythsDocRoute().location);
      await tester.tap(find.byIcon(Icons.menu));
      await settle(tester);
      await tester.tap(find.widgetWithText(ListTile, t.mythFamineTitle));
      await settle(tester);
      await tester.ensureVisible(previousCard);

      expect(nextCard, findsNothing);
      expect(find.descendant(of: previousCard, matching: find.text(t.mythLointaineTitle)), findsOneWidget);
    });
  });

  group('DocViewerScreen reading progress', () {
    late MockReadingProgressRepository progress;

    setUp(() async {
      teardownTestLocator();
      progress = MockReadingProgressRepository();
      registerFallbackValue(DocCategory.gods);
      when(() => progress.lastItemId(any())).thenReturn(null);
      when(() => progress.lastOffset(any())).thenReturn(0);
      when(() => progress.save(any(), any(), any())).thenAnswer((_) async {});
      await setupTestLocator(readingProgressRepository: progress);
    });

    ScrollPosition docScroll(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).last).position;

    testWidgets('reopens a category on the page the reader left it on', (tester) async {
      when(() => progress.lastItemId(DocCategory.gods)).thenReturn('anubis');

      await pumpAt(tester, const GodsDocRoute().location);

      expect(find.descendant(of: find.byType(AppBar), matching: find.text(t.anubis)), findsOneWidget);
    });

    testWidgets('restores the saved scroll offset on the resumed page', (tester) async {
      when(() => progress.lastItemId(DocCategory.cosmogonies)).thenReturn('heliopolis');
      when(() => progress.lastOffset(DocCategory.cosmogonies)).thenReturn(600);

      await pumpAt(tester, const CosmogoniesDocRoute().location);
      await settle(tester);

      expect(docScroll(tester).pixels, 600);
    });

    testWidgets('falls back to the first page when the saved page no longer exists', (tester) async {
      when(() => progress.lastItemId(DocCategory.gods)).thenReturn('removed_god');
      when(() => progress.lastOffset(DocCategory.gods)).thenReturn(600);

      await pumpAt(tester, const GodsDocRoute().location);

      expect(find.descendant(of: find.byType(AppBar), matching: find.text(t.introTitle)), findsOneWidget);
      expect(docScroll(tester).pixels, 0);
    });

    testWidgets('saves the page when switching to another one, then the scroll offset', (tester) async {
      await pumpAt(tester, const CosmogoniesDocRoute().location);
      verify(() => progress.save(DocCategory.cosmogonies, 'intro', 0)).called(1);

      await tester.tap(find.byIcon(Icons.menu));
      await settle(tester);
      await tester.tap(find.widgetWithText(ListTile, t.memphisTitle));
      await settle(tester);
      verify(() => progress.save(DocCategory.cosmogonies, 'memphis', 0)).called(1);

      await tester.drag(find.byType(Scrollable).last, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 600));
      verify(() => progress.save(DocCategory.cosmogonies, 'memphis', any(that: greaterThan(0)))).called(1);
    });
  });

  group('DocViewerScreen god links', () {
    testWidgets('tapping a god name opens that god page on top, and back returns', (tester) async {
      await pumpAt(tester, const MythsDocRoute().location);

      final osirisLink = find.textRange.ofSubstring('Osiris').first;
      await tester.ensureVisible(find.textContaining('Osiris', findRichText: true).first);
      await settle(tester);
      await tester.tapOnText(osirisLink);
      await settle(tester);

      expect(find.descendant(of: find.byType(AppBar), matching: find.text(t.osiris)), findsOneWidget);

      // System back (the viewer AppBar shows the drawer button, not a back one).
      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(find.descendant(of: find.byType(AppBar), matching: find.text(t.introTitle)), findsOneWidget);
    });

    testWidgets('a route with an item opens on that page instead of the saved one', (tester) async {
      await pumpAt(tester, const GodsDocRoute(item: 'isis').location);

      expect(find.descendant(of: find.byType(AppBar), matching: find.text(t.isis)), findsOneWidget);
    });
  });

  group('DocViewerScreen glossary links', () {
    testWidgets('tapping a glossary term shows its definition, which leads to the glossary', (tester) async {
      await LocaleSettings.setLocaleRaw('fr');
      await pumpAt(tester, const CosmogoniesDocRoute(item: 'heliopolis').location);

      await tester.ensureVisible(find.textContaining('Noun', findRichText: true).first);
      await settle(tester);
      await tester.tapOnText(find.textRange.ofSubstring('Noun').first);
      await settle(tester);

      expect(find.byKey(const ValueKey('glossary_sheet')), findsOneWidget);
      expect(find.textContaining('océan primordial', findRichText: true), findsWidgets);

      await tester.tap(find.text(t.seeGlossary));
      await settle(tester);

      expect(find.descendant(of: find.byType(AppBar), matching: find.text(t.glossaryTitle)), findsOneWidget);
    });
  });

  group('DocSearchScreen', () {
    final searchField = find.byKey(const ValueKey('doc_search_field'));

    Future<void> search(WidgetTester tester, String query) async {
      await tester.enterText(searchField, query);
      await tester.pump(const Duration(milliseconds: 250));
      await settle(tester);
    }

    testWidgets('lists matching pages and opens the tapped one, back returns to the results', (tester) async {
      await pumpAt(tester, const DocSearchRoute().location);
      await search(tester, 'heliopolis');

      final result = find.widgetWithText(ListTile, t.heliopolisTitle);
      expect(result, findsOneWidget);

      await tester.tap(result);
      await settle(tester);
      expect(find.descendant(of: find.byType(AppBar), matching: find.text(t.heliopolisTitle)), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(result, findsOneWidget);
    });

    testWidgets('shows an empty state when nothing matches', (tester) async {
      await pumpAt(tester, const DocSearchRoute().location);
      await search(tester, 'xylophone');

      expect(find.text(t.noResults), findsOneWidget);
    });

    testWidgets('is reachable from the viewer app bar', (tester) async {
      await pumpAt(tester, const MythsDocRoute().location);
      await tester.tap(find.byIcon(Icons.search));
      await settle(tester);

      expect(searchField, findsOneWidget);
    });
  });
}
