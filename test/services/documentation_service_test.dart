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

      final chouTefnout = await docs.loadContent(DocCategory.cosmogonies, 'heliopolis', 'en', t);
      expect(chouTefnout, contains('<a href="${DocumentationService.godLinkPrefix}chou_tefnout">Chu</a>'));
    });
  });
}
