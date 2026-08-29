import 'package:flutter/material.dart';

// Mirrors the legacy app's bg_gradient_black.xml -- a subtle top-to-bottom
// darkening used behind text blocks to set them apart from the pyramid
// backdrop (PyramidBackground's own overlay, the instructions text box on
// InstructionsScreen, the score list on StatsScreen, ...).
abstract class AppDecorations {
  static const darkGradientBox = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x60000000), Color(0x80000000), Color(0x60000000)],
    ),
  );
}
