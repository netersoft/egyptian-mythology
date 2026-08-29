import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

// The doc HTML illustrations mix raster (png/jpg) and SVG art; the core
// package's default asset image loader can't decode SVG, so intercept it
// here and hand SVG sources to flutter_svg instead. Illustrations are also
// mostly given a fixed height (not width: 100%), so the package's default
// left-aligned block rendering leaves them flush against the left edge --
// center them instead.
class DocWidgetFactory extends WidgetFactory {
  @override
  Widget? buildImageWidget(BuildTree tree, ImageSource src) {
    final url = src.url;
    if (url.startsWith('asset:') && url.toLowerCase().endsWith('.svg')) {
      final assetPath = url.substring('asset:'.length);
      return Center(
        child: SvgPicture.asset(
          assetPath,
          height: src.height,
          width: src.width,
          semanticsLabel: src.image?.alt ?? src.image?.title,
        ),
      );
    }

    final image = super.buildImageWidget(tree, src);
    return image == null ? null : Center(child: image);
  }
}
