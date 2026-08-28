import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/routes/app_route.dart';
import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../components/backgrounds/pyramid_background.dart';
import '../../components/buttons/menu_button.dart';
import '../../components/misc/app_header_card.dart';
import '../../themes/app_colors.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  void _startQuiz(BuildContext context) {
    unawaited(locator<AudioService>().playClick());
    const QuizPlayRoute().push(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PyramidBackground(
      child: SafeArea(
        child: Column(
          children: [
            AppHeaderCard(title: context.t.quiz),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  context.t.instructions,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.yellow, fontSize: 16, height: 1.5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
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
