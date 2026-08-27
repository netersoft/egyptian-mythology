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
    final html = await _docs.loadContent(widget.category, item.id, LocaleSettings.instance.currentLocale.languageCode);
    if (!mounted) return;
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
      backgroundColor: AppColors.black,
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
    body: DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.black),
      child: _html == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldenYellow))
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: HtmlWidget(
                _html!,
                factoryBuilder: DocWidgetFactory.new,
                textStyle: const TextStyle(fontFamily: 'papyrus', color: AppColors.goldenYellow, fontSize: 16),
              ),
            ),
    ),
  );
}
