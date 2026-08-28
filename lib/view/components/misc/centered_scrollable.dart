import 'package:flutter/material.dart';

// Centers [child] vertically within the available space; falls back to
// scrolling from the top when the content is taller than the viewport
// (e.g. long instructions/credits text on a small screen).
class CenteredScrollable extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const CenteredScrollable({required this.child, this.padding, super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(child: child),
      ),
    ),
  );
}
