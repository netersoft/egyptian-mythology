import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/models/doc_category.dart';
import '../../../core/models/doc_search_result.dart';
import '../../../core/routes/app_route.dart';
import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/documentation/documentation_service.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_colors.dart';

// Full-text search across the three documentation categories. Results open
// the matching page as a new screen, so back returns to this list with the
// query intact.
class DocSearchScreen extends StatefulWidget {
  const DocSearchScreen({super.key});

  @override
  State<DocSearchScreen> createState() => _DocSearchScreenState();
}

class _DocSearchScreenState extends State<DocSearchScreen> {
  final _docs = locator<DocumentationService>();
  final _controller = TextEditingController();
  Timer? _debounce;

  String _query = '';
  List<DocSearchResult> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () => _search(query));
  }

  Future<void> _search(String query) async {
    final results = await _docs.search(query, LocaleSettings.instance.currentLocale.languageCode, t);
    if (!mounted || query != _controller.text) return;
    setState(() {
      _query = query.trim();
      _results = results;
    });
  }

  void _open(DocSearchResult result) {
    unawaited(locator<AudioService>().playClick());
    FocusScope.of(context).unfocus();
    final item = result.item.id;
    unawaited(switch (result.category) {
      DocCategory.gods => GodsDocRoute(item: item).push<void>(context),
      DocCategory.cosmogonies => CosmogoniesDocRoute(item: item).push<void>(context),
      DocCategory.myths => MythsDocRoute(item: item).push<void>(context),
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.black,
    appBar: AppBar(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.goldenYellow,
      title: TextField(
        key: const ValueKey('doc_search_field'),
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        cursorColor: AppColors.goldenYellow,
        style: const TextStyle(color: AppColors.goldenYellow, fontSize: 18),
        decoration: InputDecoration(
          hintText: context.t.searchHint,
          hintStyle: const TextStyle(color: AppColors.goldenRod),
          border: InputBorder.none,
        ),
        onChanged: _onChanged,
        onSubmitted: _search,
      ),
      actions: [
        if (_controller.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _controller.clear();
              _onChanged('');
            },
          ),
      ],
    ),
    body: _query.length < 2
        ? const SizedBox.shrink()
        : _results.isEmpty
        ? Center(
            child: Text(context.t.noResults, style: const TextStyle(color: AppColors.goldenRod, fontSize: 16)),
          )
        : ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: _results.length,
            separatorBuilder: (context, index) => const Divider(color: AppColors.blackRussian, height: 1),
            itemBuilder: (context, index) => _ResultTile(result: _results[index], onTap: () => _open(_results[index])),
          ),
  );
}

class _ResultTile extends StatelessWidget {
  final DocSearchResult result;
  final VoidCallback onTap;

  const _ResultTile({required this.result, required this.onTap});

  IconData get _icon => switch (result.category) {
    DocCategory.gods => Icons.groups,
    DocCategory.cosmogonies => Icons.auto_awesome,
    DocCategory.myths => Icons.auto_stories,
  };

  @override
  Widget build(BuildContext context) {
    final snippet = result.snippet;
    return ListTile(
      onTap: onTap,
      leading: _Thumbnail(result: result, fallback: _icon),
      title: Text(
        result.item.title,
        style: const TextStyle(color: AppColors.goldenYellow, fontWeight: FontWeight.bold),
      ),
      subtitle: snippet.isEmpty
          ? Text(result.category.title(context.t), style: const TextStyle(color: AppColors.goldenRod))
          : Text.rich(
              TextSpan(
                style: const TextStyle(color: Colors.white70),
                children: [
                  TextSpan(text: snippet.substring(0, result.matchStart)),
                  TextSpan(
                    text: snippet.substring(result.matchStart, result.matchEnd),
                    style: const TextStyle(color: AppColors.goldenYellow, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: snippet.substring(result.matchEnd)),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}

// The page's own illustration, cropped to a square: gods are full-length
// portraits, so the crop keeps the top (head and crown, what identifies
// them); cosmogony/myth banners are landscape, so it keeps the centre.
// Falls back to the category icon if a page has no illustration.
class _Thumbnail extends StatelessWidget {
  final DocSearchResult result;
  final IconData fallback;

  const _Thumbnail({required this.result, required this.fallback});

  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    final asset = result.imageAsset;
    final alignment = result.category == DocCategory.gods ? Alignment.topCenter : Alignment.center;
    final icon = Icon(fallback, color: AppColors.goldenRod);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: _size,
        height: _size,
        color: AppColors.blackRussian,
        alignment: Alignment.center,
        child: asset == null
            ? icon
            : asset.toLowerCase().endsWith('.svg')
            // Sized by the parent, not width/height: SvgPicture shrinks its
            // own box to the picture's aspect ratio when given both, which
            // leaves nothing for BoxFit.cover to crop.
            ? SizedBox.square(
                dimension: _size,
                child: SvgPicture.asset(asset, fit: BoxFit.cover, alignment: alignment),
              )
            : Image.asset(
                asset,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                alignment: alignment,
                cacheWidth: 144,
                errorBuilder: (context, error, stackTrace) => icon,
              ),
      ),
    );
  }
}
