import 'doc_category.dart';
import 'doc_item.dart';

class DocSearchResult {
  final DocCategory category;
  final DocItem item;

  // Asset path of the page's first illustration (a god's portrait, a
  // cosmogony/myth banner), shown as the result's thumbnail.
  final String? imageAsset;

  // Excerpt of the page text around the first match (empty when only the
  // title matched), with [matchStart]/[matchEnd] locating the match in it.
  final String snippet;
  final int matchStart;
  final int matchEnd;

  const DocSearchResult({
    required this.category,
    required this.item,
    this.imageAsset,
    this.snippet = '',
    this.matchStart = 0,
    this.matchEnd = 0,
  });
}
