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
    test('loads all 32 god items (intro + 31 deities) with resolved titles', () async {
      final items = await docs.loadItems(DocCategory.gods, 'en', t);

      expect(items.length, 32);
      expect(items.first.id, 'intro');
      expect(items.first.title, 'Introduction');
      expect(items.firstWhere((i) => i.id == 'anubis').title, 'Anubis');
      expect(items.firstWhere((i) => i.id == 'amon_re').title, 'Amun-Re');
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
      final html = await docs.loadContent(DocCategory.gods, 'anubis', 'en');

      expect(html, contains('Anubis'));
      expect(html, contains('src="asset:assets/docs/res/pictures/gods/anubis.svg"'));
      expect(html, isNot(contains('../../res/')));
    });

    test('loads cosmogony content with asset-scheme image rewrite', () async {
      final html = await docs.loadContent(DocCategory.cosmogonies, 'heliopolis', 'en');

      expect(html, contains('src="asset:assets/docs/res/pictures/cosmogonies/heliopolis_banner.jpg"'));
      expect(html, isNot(contains('<html>')));
    });

    test('loads myth content with asset-scheme image rewrite', () async {
      final html = await docs.loadContent(DocCategory.myths, 'myth_mort', 'en');

      expect(html, contains('src="asset:assets/docs/res/pictures/myths/myth_mort_banner.jpg"'));
    });

    test('gods.html is parsed per locale (en and fr differ)', () async {
      final en = await docs.loadContent(DocCategory.gods, 'anubis', 'en');
      final fr = await docs.loadContent(DocCategory.gods, 'anubis', 'fr');

      expect(en, isNot(equals(fr)));
    });
  });
}
