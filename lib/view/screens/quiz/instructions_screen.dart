import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/quiz_theme.dart';
import '../../../core/routes/app_route.dart';
import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../components/backgrounds/pyramid_background.dart';
import '../../components/buttons/menu_button.dart';
import '../../components/misc/app_header_card.dart';
import '../../components/misc/centered_scrollable.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_decorations.dart';

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  QuizTheme _theme = QuizTheme.all;

  void _startQuiz(BuildContext context) {
    unawaited(locator<AudioService>().playClick());
    unawaited(QuizPlayRoute(theme: _theme == QuizTheme.all ? null : _theme).push<void>(context));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PyramidBackground(
      child: SafeArea(
        child: Column(
          children: [
            AppHeaderCard(title: context.t.quiz),
            Expanded(
              child: CenteredScrollable(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: AppDecorations.darkGradientBox,
                  child: Text(
                    context.t.instructions,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.yellow, fontSize: 16, height: 1.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final theme in QuizTheme.values)
                    ChoiceChip(
                      key: ValueKey('quiz_theme_${theme.name}'),
                      label: Text(theme.label(context.t)),
                      selected: theme == _theme,
                      showCheckmark: false,
                      selectedColor: AppColors.goldenRod,
                      backgroundColor: AppColors.blackRussian,
                      side: const BorderSide(color: AppColors.goldenRod),
                      labelStyle: TextStyle(color: theme == _theme ? AppColors.black : AppColors.goldenYellow),
                      onSelected: (_) {
                        unawaited(locator<AudioService>().playClick());
                        setState(() => _theme = theme);
                      },
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: MenuButton(
                icon: Icons.play_arrow,
                label: context.t.letsPlay,
                onTap: () => _startQuiz(context),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
