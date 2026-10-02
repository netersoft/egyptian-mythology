import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/doc_category.dart';
import '../../../core/models/doc_item.dart';
import '../../../core/routes/app_route.dart';
import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/documentation/documentation_service.dart';
import '../../../core/services/documentation/reading_progress_repository.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/tools/constants/store.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_decorations.dart';
import 'doc_widget_factory.dart';

class DocViewerScreen extends StatefulWidget {
  final DocCategory category;
  // Page to open on, overriding the saved reading position (god links).
  final String? initialItemId;

  const DocViewerScreen({required this.category, this.initialItemId, super.key});

  @override
  State<DocViewerScreen> createState() => _DocViewerScreenState();
}

class _DocViewerScreenState extends State<DocViewerScreen> {
  final _docs = locator<DocumentationService>();
  final _progress = locator<ReadingProgressRepository>();
  final _scrollController = ScrollController();
  Timer? _saveProgressDebounce;

  List<DocItem>? _items;
  DocItem? _selected;
  // Last item asked for -- guards against an older, slower load resolving
  // after a newer one (e.g. tapping "next" twice quickly) and overwriting it.
  DocItem? _requested;
  String? _html;
  bool _showTitle = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadItems());
  }

  @override
  void dispose() {
    // Flush a pending save so leaving right after scrolling isn't lost.
    if (_saveProgressDebounce?.isActive ?? false) {
      _saveProgressDebounce!.cancel();
      _saveProgress();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showTitle = _scrollController.offset < 100;
    if (showTitle != _showTitle) setState(() => _showTitle = showTitle);

    _saveProgressDebounce?.cancel();
    _saveProgressDebounce = Timer(const Duration(milliseconds: 500), _saveProgress);
  }

  void _saveProgress() {
    final selected = _selected;
    if (selected == null || !_scrollController.hasClients) return;
    unawaited(_progress.save(widget.category, selected.id, _scrollController.offset));
  }

  Future<void> _loadItems() async {
    final items = await _docs.loadItems(widget.category, LocaleSettings.instance.currentLocale.languageCode, t);
    if (!mounted) return;
    setState(() => _items = items);
    if (items.isEmpty) return;

    final requested = items.where((item) => item.id == widget.initialItemId).firstOrNull;
    if (requested != null) {
      await _selectItem(requested);
      return;
    }

    // Resume on the page (and scroll position) the reader left this category
    // on; the id may be gone if the content changed, so fall back to the start.
    final lastId = _progress.lastItemId(widget.category);
    final resumed = items.where((item) => item.id == lastId).firstOrNull;
    if (resumed == null) {
      await _selectItem(items.first);
    } else {
      await _selectItem(resumed, restoreOffset: _progress.lastOffset(widget.category));
    }
  }

  Future<void> _selectItem(DocItem item, {double restoreOffset = 0}) async {
    _requested = item;
    final html = await _docs.loadContent(widget.category, item.id, LocaleSettings.instance.currentLocale.languageCode, t);
    if (!mounted || !identical(item, _requested)) return;
    _saveProgressDebounce?.cancel();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() {
      _selected = item;
      _html = html;
      _showTitle = true;
    });
    if (restoreOffset > 0) {
      unawaited(_restoreScroll(item, restoreOffset));
    } else {
      unawaited(_progress.save(widget.category, item.id, 0));
    }
  }

  // HtmlWidget lays its content out over several frames (and illustrations
  // grow the page as they decode), so the saved offset may not be reachable
  // yet on the first frame -- retry briefly until the page is tall enough,
  // then clamp. Gives up as soon as the reader scrolls or changes page.
  Future<void> _restoreScroll(DocItem item, double offset) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted || !identical(item, _selected) || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.pixels != 0) return;
      if (position.maxScrollExtent >= offset || attempt == 39) {
        _scrollController.jumpTo(math.min(offset, position.maxScrollExtent));
        return;
      }
    }
  }

  void _onSelect(DocItem item) {
    Navigator.of(context).pop();
    unawaited(locator<AudioService>().playClick());
    unawaited(_selectItem(item));
  }

  void _onPage(DocItem item) {
    unawaited(locator<AudioService>().playClick());
    unawaited(_selectItem(item));
  }

  // God-name links (doc:gods/<id>) open that god's page as a new screen, so
  // back returns to the page the link was followed from, like on the web.
  // Glossary terms (glossary:<id>) show their definition in a sheet instead,
  // so looking a word up doesn't lose the reader's place.
  bool _onTapUrl(String url) {
    if (url.startsWith(DocumentationService.godLinkPrefix)) {
      unawaited(locator<AudioService>().playClick());
      unawaited(GodsDocRoute(item: url.substring(DocumentationService.godLinkPrefix.length)).push<void>(context));
      return true;
    }
    if (url.startsWith(DocumentationService.glossaryLinkPrefix)) {
      unawaited(locator<AudioService>().playClick());
      unawaited(_showDefinition(url.substring(DocumentationService.glossaryLinkPrefix.length)));
      return true;
    }
    return false;
  }

  Future<void> _showDefinition(String id) async {
    final entries = await _docs.glossary(LocaleSettings.instance.currentLocale.languageCode);
    final entry = entries.where((e) => e.id == id).firstOrNull;
    if (entry == null || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.blackRussian,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          key: const ValueKey('glossary_sheet'),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.term,
                style: const TextStyle(color: AppColors.goldenYellow, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              HtmlWidget(entry.definition, textStyle: const TextStyle(color: AppColors.goldenYellow, fontSize: 16)),
              if (widget.category != DocCategory.reference)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      unawaited(locator<AudioService>().playClick());
                      unawaited(const ReferenceDocRoute(item: DocumentationService.glossaryPageId).push<void>(context));
                    },
                    child: Text(t.seeGlossary, style: const TextStyle(color: AppColors.goldenRod)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // God links are underlined; glossary terms get a dotted underline, so the
  // reader can tell "opens a page" from "shows a definition". Figures drop
  // the browser-default 40px side margins: on a phone they shrank every
  // illustration, and made the labels of the map and family tree too small.
  static Map<String, String>? _elementStyle(String? tag, String? href) {
    if (tag == 'figure') return const {'margin': '1em 0'};
    if (tag != 'a') return null;
    final isTerm = href?.startsWith(DocumentationService.glossaryLinkPrefix) ?? false;
    return {'color': '#DAA520', 'text-decoration': 'underline', if (isTerm) 'text-decoration-style': 'dotted'};
  }

  void _share() {
    unawaited(locator<AudioService>().playClick());
    unawaited(
      SharePlus.instance.share(
        ShareParams(text: widget.category.shareText(t, Store.playStoreUrl), subject: t.shareAppTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.black,
    appBar: AppBar(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.goldenYellow,
      title: AnimatedOpacity(
        opacity: _showTitle ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Text(_selected?.title ?? widget.category.title(t)),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: t.search,
          onPressed: () {
            unawaited(locator<AudioService>().playClick());
            unawaited(const DocSearchRoute().push<void>(context));
          },
        ),
        IconButton(icon: const Icon(Icons.share), tooltip: t.share, onPressed: _share),
      ],
    ),
    drawer: Drawer(
      backgroundColor: Colors.transparent,
      child: DecoratedBox(
        decoration: AppDecorations.darkGradientBox,
        child: _items == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.goldenYellow))
            : ListView(
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: AppColors.blackRussian),
                    child: Center(
                      child: Text(
                        widget.category.title(t),
                        style: const TextStyle(color: AppColors.goldenYellow, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  for (final item in _items!)
                    ListTile(
                      title: Text(
                        item.title,
                        style: TextStyle(color: item.id == _selected?.id ? AppColors.goldenYellow : Colors.white),
                      ),
                      selected: item.id == _selected?.id,
                      onTap: () => _onSelect(item),
                    ),
                ],
              ),
      ),
    ),
    body: _html == null
        ? const Center(child: CircularProgressIndicator(color: AppColors.goldenYellow))
        : SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HtmlWidget(
                  _html!,
                  factoryBuilder: DocWidgetFactory.new,
                  onTapUrl: _onTapUrl,
                  customStylesBuilder: (element) => _elementStyle(element.localName, element.attributes['href']),
                  textStyle: const TextStyle(color: AppColors.goldenYellow, fontSize: 16),
                ),
                _buildPager(),
              ],
            ),
          ),
  );

  // Previous/next cards at the end of the content, docs-site style: shown
  // once the page has been read rather than as a fixed bar eating reading
  // space. Not a horizontal swipe -- SwipeablePage already claims
  // swipe-anywhere for back navigation.
  Widget _buildPager() {
    final items = _items;
    final index = items == null || _selected == null ? -1 : items.indexWhere((item) => item.id == _selected!.id);
    if (index < 0) return const SizedBox.shrink();

    final previous = index > 0 ? items![index - 1] : null;
    final next = index < items!.length - 1 ? items[index + 1] : null;

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: previous == null
                  ? const SizedBox.shrink()
                  : _DocPageCard(
                      key: const ValueKey('doc_previous_page'),
                      label: t.previous,
                      title: previous.title,
                      isNext: false,
                      onTap: () => _onPage(previous),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: next == null
                  ? const SizedBox.shrink()
                  : _DocPageCard(
                      key: const ValueKey('doc_next_page'),
                      label: t.next,
                      title: next.title,
                      isNext: true,
                      onTap: () => _onPage(next),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocPageCard extends StatelessWidget {
  final String label;
  final String title;
  final bool isNext;
  final VoidCallback onTap;

  const _DocPageCard({required this.label, required this.title, required this.isNext, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final alignment = isNext ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = isNext ? TextAlign.end : TextAlign.start;

    return Material(
      color: AppColors.blackRussian,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.goldenRod),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: alignment,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isNext) const Icon(Icons.chevron_left, color: AppColors.goldenRod, size: 18),
                  Text(label, style: const TextStyle(color: AppColors.goldenRod, fontSize: 12)),
                  if (isNext) const Icon(Icons.chevron_right, color: AppColors.goldenRod, size: 18),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: textAlign,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.goldenYellow, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
