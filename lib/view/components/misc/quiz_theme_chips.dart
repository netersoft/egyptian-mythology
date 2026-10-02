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
class QuizThemeChips extends StatelessWidget {
  final QuizTheme selected;
  final ValueChanged<QuizTheme> onSelected;
  final String keyPrefix;

  const QuizThemeChips({required this.selected, required this.onSelected, this.keyPrefix = 'quiz_theme', super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final theme in QuizTheme.values)
        ChoiceChip(
          key: ValueKey('${keyPrefix}_${theme.name}'),
          label: Text(theme.label(context.t)),
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
        ),
    ],
  );
}
