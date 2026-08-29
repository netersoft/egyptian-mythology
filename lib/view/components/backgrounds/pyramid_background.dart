import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../themes/app_decorations.dart';

// Legacy menu screens (MainActivity, DocSectionsActivity, ...) all share the
// same desert/pyramid backdrop (ic_pyramid) darkened by a translucent black
// gradient (bg_gradient_black) so the gold UI on top stays readable.
class PyramidBackground extends StatelessWidget {
  final Widget child;

  const PyramidBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      SvgPicture.asset('assets/images/egyptian/bg_pyramid.svg', fit: BoxFit.cover),
      const DecoratedBox(decoration: AppDecorations.darkGradientBox),
      child,
    ],
  );
}
