import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../../models/doc_category.dart';
import '../../models/doc_item.dart';
import '../../models/doc_search_result.dart';
import '../../models/glossary_entry.dart';
import '../i18n/translations.g.dart';

// Cosmogonies and myths each ship as one HTML file per item. Gods ship as a
// single gods.html with one <section id="..."> per deity (matching the
// legacy app's WebView + #anchor navigation) — split into per-god fragments
// here instead, since HtmlWidget has no anchor-scroll equivalent.
class DocumentationService {
  static const _cosmogonyFileIds = ['intro', 'heliopolis', 'hermopolis', 'memphis', 'thebes'];
  static const _mythFileIds = ['myth_intro', 'myth_circadien', 'myth_mort', 'myth_osirien', 'myth_lointaine', 'myth_famine'];
  // The glossary page is built from assets/glossary/, not from an HTML file.
  static const _referenceFileIds = ['glossary', 'map', 'chronology'];
  static const glossaryPageId = 'glossary';

  // French is the source text; a page or glossary not translated yet falls
  // back to it rather than leaving a hole in the other locales.
  static const _sourceLocale = 'fr';

  final _godsContentCache = <String, Map<String, String>>{};
  final _searchIndexCache = <String, List<_IndexedPage>>{};
  final _glossaryCache = <String, List<GlossaryEntry>>{};
  Future<AssetManifest>? _manifest;

  Future<List<DocItem>> loadItems(DocCategory category, String locale, Translations t) async {
    switch (category) {
      case DocCategory.gods:
        await _ensureGodsLoaded(locale);
        return _godsContentCache[locale]!.keys.map((id) => DocItem(id: id, title: _godTitle(id, t))).toList();
      case DocCategory.cosmogonies:
        return _cosmogonyFileIds.map((id) => DocItem(id: id, title: _itemTitle(id, t))).toList();
      case DocCategory.myths:
        return _mythFileIds.map((id) => DocItem(id: id, title: _itemTitle(id, t))).toList();
      case DocCategory.reference:
        return _referenceFileIds.map((id) => DocItem(id: id, title: _itemTitle(id, t))).toList();
    }
  }

  Future<String> loadContent(DocCategory category, String id, String locale, Translations t) async {
    final String html;
    final isGlossary = category == DocCategory.reference && id == glossaryPageId;
    if (category == DocCategory.gods) {
      await _ensureGodsLoaded(locale);
      html = _godsContentCache[locale]![id] ?? '';
    } else if (isGlossary) {
      html = _glossaryPage(await glossary(locale));
    } else {
      final raw = await _loadWithFallback((l) => 'assets/docs/$l/${category.folder}/$id.html', locale);
      html = _rewriteImageSrcs(_extractBody(raw));
    }

    // A god's own page doesn't link to itself, and the glossary doesn't link
    // its terms back to themselves. A locale without its own glossary yet
    // gets no term links rather than definitions in another language.
    final linkTerms = !isGlossary && await _exists(_glossaryPath(locale));
    final links = <String, String>{
      if (linkTerms)
        for (final entry in await glossary(locale))
          for (final alias in entry.aliases) alias: '$glossaryLinkPrefix${entry.id}',
      for (final MapEntry(key: name, value: godId) in _godNames(t).entries) name: '$godLinkPrefix$godId',
    };
    final linked = linkMentions(html, links, exclude: {if (category == DocCategory.gods) '$godLinkPrefix$id'});
    return locale == 'fr' ? frenchSpacing(linked) : linked;
  }

  // The glossary of [locale], sorted by term as the reader would expect.
  Future<List<GlossaryEntry>> glossary(String locale) async {
    final cached = _glossaryCache[locale];
    if (cached != null) return cached;

    final raw = await _loadWithFallback(_glossaryPath, locale);
    final entries = (jsonDecode(raw) as List<dynamic>).map((e) {
      final entry = GlossaryEntry.fromJson(e as Map<String, dynamic>);
      if (locale != 'fr') return entry;
      return GlossaryEntry(id: entry.id, term: entry.term, aliases: entry.aliases, definition: frenchSpacing(entry.definition));
    }).toList()..sort((a, b) => foldForSearch(a.term).compareTo(foldForSearch(b.term)));
    return _glossaryCache[locale] = entries;
  }

  static String _glossaryPath(String locale) => 'assets/glossary/glossary_$locale.json';

  Future<bool> _exists(String asset) async {
    final manifest = await (_manifest ??= AssetManifest.loadFromAssetBundle(rootBundle));
    return manifest.listAssets().contains(asset);
  }

  Future<String> _loadWithFallback(String Function(String locale) path, String locale) async =>
      rootBundle.loadString(path(await _exists(path(locale)) ? locale : _sourceLocale), cache: false);

  static String _glossaryPage(List<GlossaryEntry> entries) => [
    '<section>',
    for (final entry in entries) '<h3>${entry.term}</h3><p>${entry.definition}</p>',
    '</section>',
  ].join('\n');

  // Searches every page of every category, ignoring case and accents ("re"
  // finds "Rê", "amon" finds "Amón"). Pages whose title matches come first,
  // then pages whose text does, each with an excerpt around its first match.
  Future<List<DocSearchResult>> search(String query, String locale, Translations t) async {
    final needle = foldForSearch(query.trim());
    if (needle.length < 2) return const [];

    final pages = await _searchIndex(locale, t);
    final byTitle = <DocSearchResult>[];
    final byText = <DocSearchResult>[];

    for (final page in pages) {
      if (page.foldedTitle.contains(needle)) {
        byTitle.add(DocSearchResult(category: page.category, item: page.item, imageAsset: page.imageAsset));
        continue;
      }
      final at = page.foldedText.indexOf(needle);
      if (at < 0) continue;

      const before = 40;
      const after = 90;
      final start = at <= before ? 0 : page.text.lastIndexOf(' ', at - before) + 1;
      final end = at + needle.length + after >= page.text.length ? page.text.length : page.text.indexOf(' ', at + needle.length + after);
      final excerpt = page.text.substring(start, end < 0 ? page.text.length : end);
      final prefix = start > 0 ? '…' : '';
      byText.add(
        DocSearchResult(
          category: page.category,
          item: page.item,
          imageAsset: page.imageAsset,
          snippet: '$prefix$excerpt${end >= 0 && end < page.text.length ? '…' : ''}',
          matchStart: prefix.length + at - start,
          matchEnd: prefix.length + at - start + needle.length,
        ),
      );
    }
    return [...byTitle, ...byText];
  }

  Future<List<_IndexedPage>> _searchIndex(String locale, Translations t) async {
    final cached = _searchIndexCache[locale];
    if (cached != null) return cached;

    final pages = <_IndexedPage>[];
    for (final category in DocCategory.values) {
      for (final item in await loadItems(category, locale, t)) {
        final html = await loadContent(category, item.id, locale, t);
        final text = htmlToText(html);
        final image = _firstAssetImage.firstMatch(html)?.group(1);
        pages.add(_IndexedPage(category, item, text, foldForSearch(item.title), foldForSearch(text), image));
      }
    }
    return _searchIndexCache[locale] = pages;
  }

  // Inline tags sit inside a word run ("<a>Maat</a>'s") and must vanish
  // without a trace; any other tag separates blocks, so becomes a space.
  static final _inlineTags = RegExp(r'</?(a|b|i|em|strong|span|sup|sub|small)\b[^>]*>', caseSensitive: false);
  static final _tags = RegExp('<[^>]*>');
  static final _firstAssetImage = RegExp(r'<img[^>]*\bsrc="asset:([^"]+)"');
  static final _spaces = RegExp(r'\s+');
  static const _entities = {'&nbsp;': ' ', '&amp;': '&', '&lt;': '<', '&gt;': '>', '&quot;': '"', '&#39;': "'", '&rsquo;': '’'};

  static String htmlToText(String html) {
    var text = html.replaceAll(_inlineTags, '').replaceAll(_tags, ' ');
    _entities.forEach((entity, char) => text = text.replaceAll(entity, char));
    return text.replaceAll(_spaces, ' ').trim();
  }

  static const _accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ù': 'u',
    'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y', 'œ': 'o', 'æ': 'a', 'ß': 's', '’': "'",
  };

  // Lowercases and strips accents one character at a time, so the folded
  // string keeps the original's length and match offsets map straight back
  // onto the original text for the excerpt.
  static String foldForSearch(String text) {
    final out = StringBuffer();
    for (final char in text.split('')) {
      final lower = char.toLowerCase();
      out.write(lower.length == 1 ? (_accents[lower] ?? lower) : char);
    }
    return out.toString();
  }

  // French puts a space inside guillemets and before : ; ! ? -- a plain one
  // lets the line wrap right there, leaving a lone "»" or ":" at the start of
  // a line. Make those spaces non-breaking, in text only (never in tags).
  static final _breakableFrenchSpace = RegExp('(«) +| +([»:;!?])');

  static String frenchSpacing(String html) => html.replaceAllMapped(_tagOrText, (m) {
    final text = m.group(2);
    if (text == null) return m.group(0)!;
    return text.replaceAllMapped(_breakableFrenchSpace, (s) => s.group(1) != null ? '${s.group(1)}\u00A0' : '\u00A0${s.group(2)}');
  });

  // Links schemes handled by DocViewerScreen: doc:gods/<god id> opens a god's
  // page, glossary:<entry id> shows the definition of a glossary term.
  static const godLinkPrefix = 'doc:gods/';
  static const glossaryLinkPrefix = 'glossary:';

  // Name as written in the docs -> god page id, in the current language.
  // Paired pages ("Geb & Nut") are reachable from either name.
  Map<String, String> _godNames(Translations t) => {
    for (final id in _godIds)
      for (final name in _godTitle(id, t).split('&')) name.trim(): id,
  };

  static final _tagOrText = RegExp('(<[^>]*>)|([^<]+)');
  static final _noLinkTags = RegExp(r'^<(/?)(a|h[1-6])\b', caseSensitive: false);
  static final _whitespace = RegExp(r'\s+');

  static String linkGodMentions(String html, Map<String, String> names, {String? excludeId}) => linkMentions(
    html,
    names.map((name, id) => MapEntry(name, '$godLinkPrefix$id')),
    exclude: {if (excludeId != null) '$godLinkPrefix$excludeId'},
  );

  // Turns the first mention of each name into a link to its href, the way an
  // encyclopedia links a term once per article (several names sharing an
  // href, like "Geb" and "Nut", count as one). Only text content is touched
  // -- never tags or attribute values (alt="Isis") -- and nothing inside
  // existing links or headings. Names match whole words only, longest first,
  // so "Amun-Re" wins over "Amun" and "Re", and a multi-word name still
  // matches when the source wraps it across lines ("Horus\n\t\tthe Elder").
  // Hrefs in [exclude] stay unlinked.
  static String linkMentions(String html, Map<String, String> hrefs, {Set<String> exclude = const {}}) {
    if (hrefs.isEmpty) return html;
    final sorted = hrefs.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    final pattern = RegExp(
      '(?<![\\p{L}\\p{N}_-])(${sorted.map((name) => name.split(' ').map(RegExp.escape).join(r'\s+')).join('|')})(?![\\p{L}\\p{N}_-])',
      unicode: true,
    );

    final linked = {...exclude};
    var noLinkDepth = 0;
    final out = StringBuffer();

    for (final match in _tagOrText.allMatches(html)) {
      final tag = match.group(1);
      if (tag != null) {
        final noLink = _noLinkTags.firstMatch(tag);
        if (noLink != null && !tag.endsWith('/>')) noLinkDepth += noLink.group(1) == '/' ? -1 : 1;
        out.write(tag);
        continue;
      }

      final text = match.group(2)!;
      if (noLinkDepth > 0) {
        out.write(text);
        continue;
      }
      out.write(
        text.replaceAllMapped(pattern, (m) {
          final name = m.group(0)!;
          final href = hrefs[name.replaceAll(_whitespace, ' ')]!;
          if (!linked.add(href)) return name;
          return '<a href="$href">$name</a>';
        }),
      );
    }
    return out.toString();
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
    'myth_lointaine' => t.mythLointaineTitle,
    'myth_famine' => t.mythFamineTitle,
    'glossary' => t.glossaryTitle,
    'map' => t.mapTitle,
    'chronology' => t.chronologyTitle,
    _ => fileId,
  };

  static const _godIds = [
    'amemet', 'amon', 'amon_re', 'anubis', 'apophis', 'aton', 'atoum', 'bastet', 'bes', 'chou_tefnout', 'geb_nout', //
    'hapi', 'haroeris', 'hathor', 'heka', 'horus', 'isis', 'khepri', 'khnum', 'khonsou', 'maat', 'min', 'montou', 'mout',
    'nefertem', 'neith', 'nekhbet', 'nephtys', 'osiris', 'ouadjet', 'ptah', 're', 'satis_anouket', 'sekhmet', 'selkis',
    'seshat', 'seth', 'sobek', 'sokar', 'thot', 'toueris', 'wepwawet',
  ];

  String _godTitle(String id, Translations t) => switch (id) {
    'intro' => t.introTitle,
    'amemet' => t.amemet,
    'amon' => t.amon,
    'amon_re' => t.amonRe,
    'anubis' => t.anubis,
    'apophis' => t.apophis,
    'aton' => t.aton,
    'atoum' => t.atoum,
    'bastet' => t.bastet,
    'bes' => t.bes,
    'chou_tefnout' => t.chouTefnout,
    'geb_nout' => t.gebNout,
    'hapi' => t.hapi,
    'haroeris' => t.haroeris,
    'hathor' => t.hathor,
    'heka' => t.heka,
    'horus' => t.horus,
    'isis' => t.isis,
    'khepri' => t.khepri,
    'khnum' => t.khnoum,
    'khonsou' => t.khonsou,
    'maat' => t.maat,
    'min' => t.min,
    'montou' => t.montou,
    'mout' => t.mout,
    'nefertem' => t.nefertem,
    'neith' => t.neith,
    'nekhbet' => t.nekhbet,
    'nephtys' => t.nephtys,
    'osiris' => t.osiris,
    'ouadjet' => t.ouadjet,
    'ptah' => t.ptah,
    're' => t.re,
    'satis_anouket' => t.satisAnouket,
    'sekhmet' => t.sekhmet,
    'selkis' => t.selkis,
    'seshat' => t.seshat,
    'seth' => t.seth,
    'sobek' => t.sobek,
    'sokar' => t.sokar,
    'thot' => t.thot,
    'toueris' => t.toueris,
    'wepwawet' => t.wepwawet,
    _ => id,
  };
}

class _IndexedPage {
  final DocCategory category;
  final DocItem item;
  final String text;
  final String foldedTitle;
  final String foldedText;
  final String? imageAsset;

  const _IndexedPage(this.category, this.item, this.text, this.foldedTitle, this.foldedText, this.imageAsset);
}
