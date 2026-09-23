import 'package:egyptian_mythology/core/models/doc_category.dart';
import 'package:egyptian_mythology/core/services/documentation/documentation_service.dart';
import 'package:egyptian_mythology/core/services/i18n/translations.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final docs = DocumentationService();

  setUp(() async {
    await LocaleSettings.setLocaleRaw('en');
  });

  group('DocumentationService', () {
    test('loads all 36 god items (intro + 35 deities) with resolved titles', () async {
      final items = await docs.loadItems(DocCategory.gods, 'en', t);

      expect(items.length, 36);
      expect(items.first.id, 'intro');
      expect(items.first.title, 'Introduction');
      expect(items.firstWhere((i) => i.id == 'anubis').title, 'Anubis');
      expect(items.firstWhere((i) => i.id == 'amon_re').title, 'Amun-Re');
      expect(items.firstWhere((i) => i.id == 'apophis').title, 'Apophis');
      expect(items.firstWhere((i) => i.id == 'nefertem').title, 'Nefertem');
      expect(items.firstWhere((i) => i.id == 'sokar').title, 'Sokar');
      expect(items.firstWhere((i) => i.id == 'wepwawet').title, 'Wepwawet');
    });

    test('loads all 5 cosmogony items with resolved titles', () async {
      final items = await docs.loadItems(DocCategory.cosmogonies, 'en', t);

      expect(items.map((i) => i.id).toList(), ['intro', 'heliopolis', 'hermopolis', 'memphis', 'thebes']);
      expect(items.firstWhere((i) => i.id == 'heliopolis').title, 'Heliopolis Cosmogony');
    });

    test('loads all 4 myth items with resolved titles', () async {
      final items = await docs.loadItems(DocCategory.myths, 'en', t);

      expect(items.map((i) => i.id).toList(), ['myth_intro', 'myth_circadien', 'myth_mort', 'myth_osirien']);
      expect(items.firstWhere((i) => i.id == 'myth_circadien').title, 'Myth of the Day Cycle');
    });

    test('loads a single god fragment with asset-scheme image rewrite', () async {
      final html = await docs.loadContent(DocCategory.gods, 'anubis', 'en', t);

      expect(html, contains('Anubis'));
      expect(html, contains('src="asset:assets/docs/res/pictures/gods/anubis.svg"'));
      expect(html, isNot(contains('../../res/')));
    });

    test('loads cosmogony content with asset-scheme image rewrite', () async {
      final html = await docs.loadContent(DocCategory.cosmogonies, 'heliopolis', 'en', t);

      expect(html, contains('src="asset:assets/docs/res/pictures/cosmogonies/heliopolis_banner.jpg"'));
      expect(html, isNot(contains('<html>')));
    });

    test('loads myth content with asset-scheme image rewrite', () async {
      final html = await docs.loadContent(DocCategory.myths, 'myth_mort', 'en', t);

      expect(html, contains('src="asset:assets/docs/res/pictures/myths/myth_mort_banner.jpg"'));
    });

    test('gods.html is parsed per locale (en and fr differ)', () async {
      final en = await docs.loadContent(DocCategory.gods, 'anubis', 'en', t);
      final fr = await docs.loadContent(DocCategory.gods, 'anubis', 'fr', t);

      expect(en, isNot(equals(fr)));
    });

    // A section id the code doesn't know (the French file once used "khnoum"
    // for "khnum") shows its raw id as the page title and breaks god links.
    test('every god page has a translated title in every locale', () async {
      for (final locale in AppLocale.values) {
        final translations = await locale.build();
        final items = await docs.loadItems(DocCategory.gods, locale.languageCode, translations);

        expect(items, hasLength(36), reason: locale.languageCode);
        for (final item in items) {
          expect(item.title, isNot(item.id), reason: '${locale.languageCode}: ${item.id}');
        }
      }
    });

    group('linkGodMentions', () {
      const names = {'Isis': 'isis', 'Osiris': 'osiris', 'Amun': 'amon', 'Amun-Re': 'amon_re', 'Re': 're'};
      String link(String id, String name) => '<a href="${DocumentationService.godLinkPrefix}$id">$name</a>';

      test('links only the first mention of each god', () {
        final html = DocumentationService.linkGodMentions('<p>Isis and Osiris. Later, Isis again.</p>', names);

        expect(html, '<p>${link('isis', 'Isis')} and ${link('osiris', 'Osiris')}. Later, Isis again.</p>');
      });

      test('never touches tags or attribute values', () {
        final html = DocumentationService.linkGodMentions('<img alt="Isis" src="isis.png"><p>Isis</p>', names);

        expect(html, '<img alt="Isis" src="isis.png"><p>${link('isis', 'Isis')}</p>');
      });

      test('skips text inside headings and existing links', () {
        final html = DocumentationService.linkGodMentions('<h2>Isis</h2><a href="x">Osiris</a><p>Isis, Osiris</p>', names);

        expect(html, '<h2>Isis</h2><a href="x">Osiris</a><p>${link('isis', 'Isis')}, ${link('osiris', 'Osiris')}</p>');
      });

      test('matches whole names only, preferring the longest one', () {
        final html = DocumentationService.linkGodMentions('<p>Amun-Re, Reborn, Isisian, Amun, Re</p>', names);

        expect(html, '<p>${link('amon_re', 'Amun-Re')}, Reborn, Isisian, ${link('amon', 'Amun')}, ${link('re', 'Re')}</p>');
      });

      test("doesn't link a god's own page to itself", () {
        final html = DocumentationService.linkGodMentions('<p>Isis and Osiris</p>', names, excludeId: 'isis');

        expect(html, '<p>Isis and ${link('osiris', 'Osiris')}</p>');
      });
    });

    test('loadContent links god mentions in the current language, excluding the page itself', () async {
      final osiris = await docs.loadContent(DocCategory.gods, 'osiris', 'en', t);
      expect(osiris, contains('${DocumentationService.godLinkPrefix}isis'));
      expect(osiris, isNot(contains('${DocumentationService.godLinkPrefix}osiris')));

      final heliopolis = await docs.loadContent(DocCategory.cosmogonies, 'heliopolis', 'en', t);
      expect(heliopolis, contains('<a href="${DocumentationService.godLinkPrefix}geb_nout">Geb</a>'));
    });

    group('search', () {
      test('ignores queries shorter than 2 characters', () async {
        expect(await docs.search(' a ', 'en', t), isEmpty);
      });

      test('lists title matches before text matches', () async {
        final results = await docs.search('anubis', 'en', t);

        expect(results.first.category, DocCategory.gods);
        expect(results.first.item.id, 'anubis');
        expect(results.first.snippet, isEmpty);
        expect(results.skip(1).every((r) => r.snippet.isNotEmpty), isTrue);
      });

      test('ignores case and accents, and locates the match in the excerpt', () async {
        await LocaleSettings.setLocaleRaw('fr');
        final results = await docs.search('MAAT', 'fr', t);

        final maat = results.firstWhere((r) => r.item.id == 'maat');
        expect(maat.item.title, 'Maât');

        final textHit = results.firstWhere((r) => r.snippet.isNotEmpty);
        expect(DocumentationService.foldForSearch(textHit.snippet.substring(textHit.matchStart, textHit.matchEnd)), 'maat');
        await LocaleSettings.setLocaleRaw('en');
      });

      test("carries each page's first illustration for the result thumbnail", () async {
        final results = await docs.search('heliopolis', 'en', t);

        final god = (await docs.search('anubis', 'en', t)).first;
        expect(god.imageAsset, 'assets/docs/res/pictures/gods/anubis.svg');
        final cosmogony = results.firstWhere((r) => r.item.id == 'heliopolis');
        expect(cosmogony.imageAsset, 'assets/docs/res/pictures/cosmogonies/heliopolis_banner.jpg');
      });

      test('returns nothing for an unknown word', () async {
        expect(await docs.search('xylophone', 'en', t), isEmpty);
      });
    });

    test('htmlToText drops inline tags without adding spaces, and separates blocks', () {
      expect(
        DocumentationService.htmlToText('<p>heavier than <a href="doc:gods/maat">Maat</a>\'s <b>feather</b>.</p><p>Next&nbsp;one</p>'),
        "heavier than Maat's feather. Next one",
      );
    });

    test('foldForSearch lowercases and strips accents without changing the length', () {
      const text = 'Amón-Rê, Maât & Œuvre';
      final folded = DocumentationService.foldForSearch(text);

      expect(folded, 'amon-re, maat & ouvre');
      expect(folded.length, text.length);
    });

    group('reference', () {
      test('lists the glossary, the map and the timeline', () async {
        final items = await docs.loadItems(DocCategory.reference, 'en', t);

        expect(items.map((i) => i.id).toList(), ['glossary', 'map', 'chronology']);
        expect(items.first.title, t.glossaryTitle);
      });

      test('builds the glossary page from its entries, sorted, without linking terms to themselves', () async {
        final fr = await AppLocale.fr.build();
        final html = await docs.loadContent(DocCategory.reference, 'glossary', 'fr', fr);

        expect(html, contains('<h3>Ka</h3>'));
        expect(html.indexOf('<h3>Akh</h3>'), lessThan(html.indexOf('<h3>Uræus</h3>')));
        expect(html, isNot(contains(DocumentationService.glossaryLinkPrefix)));
      });

      test('pages not translated yet fall back to French instead of failing', () async {
        final html = await docs.loadContent(DocCategory.reference, 'chronology', 'de', t);

        expect(html, contains('Ancien Empire'));
      });

      test('links the first mention of glossary terms, but not in a locale without its own glossary', () async {
        final fr = await AppLocale.fr.build();
        final heliopolis = await docs.loadContent(DocCategory.cosmogonies, 'heliopolis', 'fr', fr);
        expect(heliopolis, contains('<a href="${DocumentationService.glossaryLinkPrefix}nun">Noun</a>'));
        expect(RegExp('${DocumentationService.glossaryLinkPrefix}nun"').allMatches(heliopolis), hasLength(1));

        final german = await docs.loadContent(DocCategory.cosmogonies, 'heliopolis', 'de', await AppLocale.de.build());
        expect(german, isNot(contains(DocumentationService.glossaryLinkPrefix)));
      });
    });
  });
}
