import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/models/quiz_theme.dart';
import '../../../core/providers/quiz/quiz_review_provider.dart';
import '../../../core/routes/app_route.dart';
import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../components/backgrounds/pyramid_background.dart';
import '../../components/buttons/icon_action_button.dart';
import '../../components/text/typewriter_text.dart';
import '../../themes/app_colors.dart';

class GameOverScreen extends ConsumerWidget {
  final int score;
  final bool finish;
  final bool isRecord;
  // Replay starts a new game on the same theme.
  final QuizTheme theme;

  const GameOverScreen({required this.score, required this.finish, required this.isRecord, this.theme = QuizTheme.all, super.key});

  void _navigate(BuildContext context, VoidCallback go) {
    unawaited(locator<AudioService>().playClick());
    go();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final mistakes = ref.watch(quizReviewProvider).length;
    final showCongrat = finish || score > 0;
    final congratText = finish ? t.congratulations : t.bravo;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        const MainRoute().go(context);
      },
      child: Scaffold(
        body: PyramidBackground(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        Center(
                          child: SvgPicture.asset('assets/images/egyptian/ic_anubis.svg', width: 260, height: 260),
                        ),
                        if (showCongrat)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              congratText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.goldenYellow, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (finish)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: TypewriterText(
                              text: t.quizFinishText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.yellow, fontSize: 16),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: TypewriterText(
                            text: t.score(value: score),
                            style: const TextStyle(color: AppColors.goldenRod, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isRecord)
                          Container(
                            width: double.infinity,
                            color: AppColors.limeGreen,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              t.scoreRecord,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        if (mistakes > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextButton.icon(
                              key: const ValueKey('review_mistakes'),
                              onPressed: () => _navigate(context, () => unawaited(const QuizReviewRoute().push<void>(context))),
                              icon: const Icon(Icons.fact_check, color: AppColors.goldenRod),
                              label: Text(
                                t.reviewMistakes(count: mistakes),
                                style: const TextStyle(color: AppColors.goldenRod, fontSize: 16, decoration: TextDecoration.underline),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconActionButton(
                        icon: Icons.replay,
                        tooltip: t.replay,
                        onTap: () => _navigate(context, () => QuizPlayRoute(theme: theme == QuizTheme.all ? null : theme).go(context)),
                      ),
                      IconActionButton(
                        icon: Icons.home,
                        tooltip: t.mainMenu,
                        onTap: () => _navigate(context, () => const MainRoute().go(context)),
                      ),
                      IconActionButton(
                        icon: Icons.timeline,
                        tooltip: t.stats,
                        onTap: () => _navigate(context, () => const StatsRoute().go(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
