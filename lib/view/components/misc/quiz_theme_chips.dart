import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/quiz_theme.dart';
import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_colors.dart';

// One chip per quiz theme, the selected one filled in gold: picks the theme
// to play on InstructionsScreen, and the theme whose scores to show on
// StatsScreen. Each chip is keyed '<keyPrefix>_<theme name>'.
//
// With [includeEverything], a first "All" chip (keyed '<keyPrefix>_everything')
// selects null: every game, whatever its theme.
class QuizThemeChips extends StatelessWidget {
  final QuizTheme? selected;
  final ValueChanged<QuizTheme?> onSelected;
  final String keyPrefix;
  final bool includeEverything;

  const QuizThemeChips({
    required this.selected,
    required this.onSelected,
    this.keyPrefix = 'quiz_theme',
    this.includeEverything = false,
    super.key,
  });

  Widget _chip(BuildContext context, {required QuizTheme? theme, required String key, required String label}) => ChoiceChip(
    key: ValueKey('${keyPrefix}_$key'),
    label: Text(label),
    selected: theme == selected,
    showCheckmark: false,
    selectedColor: AppColors.goldenRod,
    backgroundColor: AppColors.blackRussian,
    side: const BorderSide(color: AppColors.goldenRod),
    labelStyle: TextStyle(color: theme == selected ? AppColors.black : AppColors.goldenYellow),
    onSelected: (_) {
      unawaited(locator<AudioService>().playClick());
      onSelected(theme);
    },
  );

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 4,
    children: [
      if (includeEverything) _chip(context, theme: null, key: 'everything', label: context.t.everything),
      for (final theme in QuizTheme.values) _chip(context, theme: theme, key: theme.name, label: theme.label(context.t)),
    ],
  );
}
