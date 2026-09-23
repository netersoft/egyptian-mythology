import 'package:flutter/widgets.dart';

// Papyrus (the app-wide default font, matching the legacy app's global
// Calligraphy override) reads smaller than a standard UI sans at the same
// point size, so scale all text up to compensate -- as the legacy app's
// hand-picked sp values already did per-screen.
//
// The compensation is applied on top of the user's system text scale rather
// than replacing it, so accessibility font sizes still take effect (including
// Android 14+'s nonlinear scaling, since the system scaler is kept as-is).
// The system scale is capped so fixed-height widgets (quiz answer buttons,
// menu buttons) don't overflow at the largest accessibility sizes.
const papyrusCompensation = 1.2;
const maxSystemTextScale = 1.5;

class AppTextScaler extends TextScaler {
  final TextScaler system;

  AppTextScaler(TextScaler system) : system = system.clamp(maxScaleFactor: maxSystemTextScale);

  @override
  double scale(double fontSize) => system.scale(fontSize * papyrusCompensation);

  @Deprecated('Use scale() instead.')
  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => system.textScaleFactor * papyrusCompensation;

  @override
  bool operator ==(Object other) => other is AppTextScaler && other.system == system;

  @override
  int get hashCode => Object.hash(AppTextScaler, system);

  @override
  String toString() => 'AppTextScaler($system x $papyrusCompensation)';
}
