import 'package:flutter/services.dart' show rootBundle;

import '../../models/doc_category.dart';
import '../../models/doc_item.dart';
import '../i18n/translations.g.dart';

// Cosmogonies and myths each ship as one HTML file per item. Gods ship as a
// single gods.html with one <section id="..."> per deity (matching the
// legacy app's WebView + #anchor navigation) — split into per-god fragments
// here instead, since HtmlWidget has no anchor-scroll equivalent.
class DocumentationService {
  static const _cosmogonyFileIds = ['intro', 'heliopolis', 'hermopolis', 'memphis', 'thebes'];
  static const _mythFileIds = ['myth_intro', 'myth_circadien', 'myth_mort', 'myth_osirien'];

  final _godsContentCache = <String, Map<String, String>>{};

  Future<List<DocItem>> loadItems(DocCategory category, String locale, Translations t) async {
    switch (category) {
      case DocCategory.gods:
        await _ensureGodsLoaded(locale);
        return _godsContentCache[locale]!.keys.map((id) => DocItem(id: id, title: _godTitle(id, t))).toList();
      case DocCategory.cosmogonies:
        return _cosmogonyFileIds.map((id) => DocItem(id: id, title: _itemTitle(id, t))).toList();
      case DocCategory.myths:
        return _mythFileIds.map((id) => DocItem(id: id, title: _itemTitle(id, t))).toList();
    }
  }

  Future<String> loadContent(DocCategory category, String id, String locale) async {
    if (category == DocCategory.gods) {
      await _ensureGodsLoaded(locale);
      return _godsContentCache[locale]![id] ?? '';
    }

    final raw = await rootBundle.loadString('assets/docs/$locale/${category.folder}/$id.html', cache: false);
    return _rewriteImageSrcs(_extractBody(raw));
  }

  Future<void> _ensureGodsLoaded(String locale) async {
    if (_godsContentCache.containsKey(locale)) return;

    final raw = await rootBundle.loadString('assets/docs/$locale/gods/gods.html', cache: false);
    final map = <String, String>{};

    final introMatch = RegExp(r'<header id="intro">([\s\S]*?)</header>').firstMatch(raw);
    if (introMatch != null) {
      map['intro'] = _rewriteImageSrcs(introMatch.group(1)!);
    }

    for (final match in RegExp(r'<section id="([^"]+)">([\s\S]*?)</section>').allMatches(raw)) {
      // Each section opens with an <h2> repeating the deity's name -- already
      // shown as the AppBar title, so drop it here rather than duplicate it.
      final body = match.group(2)!.replaceFirst(RegExp(r'^\s*<h2>.*?</h2>\s*', dotAll: true), '');
      map[match.group(1)!] = _rewriteImageSrcs(body);
    }

    _godsContentCache[locale] = map;
  }

  String _extractBody(String html) => RegExp(r'<body[^>]*>([\s\S]*)</body>').firstMatch(html)?.group(1) ?? html;

  String _rewriteImageSrcs(String html) => html.replaceAll(RegExp(r'src="\.\./\.\./res/'), 'src="asset:assets/docs/res/');

  String _itemTitle(String fileId, Translations t) => switch (fileId) {
    'intro' || 'myth_intro' => t.introTitle,
    'heliopolis' => t.heliopolisTitle,
    'hermopolis' => t.hermopolisTitle,
    'memphis' => t.memphisTitle,
    'thebes' => t.thebesTitle,
    'myth_circadien' => t.mythCircadienTitle,
    'myth_mort' => t.mythMortTitle,
    'myth_osirien' => t.mythOsirienTitle,
    _ => fileId,
  };

  String _godTitle(String id, Translations t) => switch (id) {
    'intro' => t.introTitle,
    'amemet' => t.amemet,
    'amon' => t.amon,
    'amon_re' => t.amonRe,
    'anubis' => t.anubis,
    'aton' => t.aton,
    'bastet' => t.bastet,
    'bes' => t.bes,
    'chou_tefnout' => t.chouTefnout,
    'geb_nout' => t.gebNout,
    'hapi' => t.hapi,
    'hathor' => t.hathor,
    'horus' => t.horus,
    'isis' => t.isis,
    'khnum' => t.khnoum,
    'khonsou' => t.khonsou,
    'maat' => t.maat,
    'min' => t.min,
    'mout' => t.mout,
    'neith' => t.neith,
    'nekhbet' => t.nekhbet,
    'nephtys' => t.nephtys,
    'osiris' => t.osiris,
    'ouadjet' => t.ouadjet,
    'ptah' => t.ptah,
    're' => t.re,
    'sekhmet' => t.sekhmet,
    'selkis' => t.selkis,
    'seth' => t.seth,
    'sobek' => t.sobek,
    'thot' => t.thot,
    'toueris' => t.toueris,
    _ => id,
  };
}
