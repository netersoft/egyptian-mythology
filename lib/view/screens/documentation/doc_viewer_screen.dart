import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/doc_category.dart';
import '../../../core/models/doc_item.dart';
import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/documentation/documentation_service.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_decorations.dart';
import 'doc_widget_factory.dart';

// Mirrors the legacy app's Play Store share link; there's no publish target
// yet, but the package id (com.neteru.ankh) is kept for continuity.
const _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.neteru.ankh';

class DocViewerScreen extends StatefulWidget {
  final DocCategory category;

  const DocViewerScreen({required this.category, super.key});

  @override
  State<DocViewerScreen> createState() => _DocViewerScreenState();
}

class _DocViewerScreenState extends State<DocViewerScreen> {
  final _docs = locator<DocumentationService>();
  final _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showTitle = _scrollController.offset < 100;
    if (showTitle != _showTitle) setState(() => _showTitle = showTitle);
  }

  Future<void> _loadItems() async {
    final items = await _docs.loadItems(widget.category, LocaleSettings.instance.currentLocale.languageCode, t);
    if (!mounted) return;
    setState(() => _items = items);
    if (items.isNotEmpty) await _selectItem(items.first);
  }

  Future<void> _selectItem(DocItem item) async {
    _requested = item;
    final html = await _docs.loadContent(widget.category, item.id, LocaleSettings.instance.currentLocale.languageCode);
    if (!mounted || !identical(item, _requested)) return;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() {
      _selected = item;
      _html = html;
      _showTitle = true;
    });
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

  void _share() {
    unawaited(locator<AudioService>().playClick());
    unawaited(
      SharePlus.instance.share(
        ShareParams(text: widget.category.shareText(t, _playStoreUrl), subject: t.shareAppTitle),
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
