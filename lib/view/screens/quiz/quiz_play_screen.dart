import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/quiz_state.dart';
import '../../../core/providers/quiz/quiz_provider.dart';
import '../../../core/routes/app_route.dart';
import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../components/backgrounds/pyramid_background.dart';
import '../../components/buttons/menu_button.dart';
import '../../themes/app_colors.dart';

class QuizPlayScreen extends ConsumerStatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen> {
  // Scoped to this screen (not AppLifecycleLayer) so backgrounding the app
  // only pauses a quiz that's actually on screen. Resuming is left to the
  // player via the pause overlay, rather than restarting the countdown the
  // moment the app comes back.
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onHide: () => ref.read(quizControllerProvider.notifier).pause());
    unawaited(ref.read(quizControllerProvider.notifier).start());
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);

    ref.listen(quizControllerProvider, (previous, next) {
      if (next.phase == QuizPhase.gameOver) {
        GameOverRoute(
          score: next.score,
          finish: next.allQuestionsAnswered,
          isRecord: next.isRecord,
        ).pushReplacement(context);
      }
    });

    return Scaffold(
      body: PyramidBackground(
        child: Stack(
          children: [
            SafeArea(
              child: state.phase == QuizPhase.loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.goldenYellow))
                  : Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1280 / 821,
                          child: Image.asset('assets/images/egyptian/play_banner.png', width: double.infinity, fit: BoxFit.contain),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Row(
                                children: List.generate(
                                  3,
                                  (i) => Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Opacity(
                                      opacity: i < state.life ? 1 : 0.15,
                                      child: Image.asset('assets/images/egyptian/ic_ankh.png', width: 24, height: 24),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                context.t.score(value: state.score),
                                style: const TextStyle(color: AppColors.yellow, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      state.question,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppColors.yellow, fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _TimerBadge(seconds: state.remainingSeconds),
                                  const SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: _AnswerButton(state: state, index: 0)),
                                            const SizedBox(width: 12),
                                            Expanded(child: _AnswerButton(state: state, index: 1)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(child: _AnswerButton(state: state, index: 2)),
                                            const SizedBox(width: 12),
                                            Expanded(child: _AnswerButton(state: state, index: 3)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            if (state.isPaused) const _PauseOverlay(),
          ],
        ),
      ),
    );
  }
}

// Covers the question and answers while paused, so the board can't be
// played until the player explicitly resumes.
class _PauseOverlay extends ConsumerWidget {
  const _PauseOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Positioned.fill(
    child: ColoredBox(
      color: const Color(0xE6000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_outline, color: AppColors.goldenYellow, size: 72),
            const SizedBox(height: 12),
            Text(
              context.t.quizPaused,
              style: const TextStyle(color: AppColors.goldenYellow, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            MenuButton(
              key: const ValueKey('quiz_resume'),
              icon: Icons.play_arrow,
              label: context.t.resume,
              onTap: () {
                unawaited(locator<AudioService>().playClick());
                ref.read(quizControllerProvider.notifier).resume();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _TimerBadge extends StatelessWidget {
  final int seconds;

  const _TimerBadge({required this.seconds});

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: math.pi / 4,
    child: Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0x75000000),
        border: Border.all(color: const Color(0x90000000), width: 4),
      ),
      child: Transform.rotate(
        angle: -math.pi / 4,
        child: Text(
          '$seconds',
          style: const TextStyle(color: AppColors.yellow, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}

class _AnswerButton extends ConsumerWidget {
  final QuizState state;
  final int index;

  const _AnswerButton({required this.state, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inFeedback = state.selectedIndex != null;
    final isCorrectChoice = inFeedback && index == state.correctIndex;
    final isWrongChoice = inFeedback && index == state.selectedIndex && index != state.correctIndex;

    final gradientColors = isWrongChoice
        ? const [AppColors.red, AppColors.red]
        : isCorrectChoice
        ? const [AppColors.limeGreen, AppColors.lime]
        : const [AppColors.goldenYellow, AppColors.goldenRod];

    final label = index < state.choices.length ? state.choices[index] : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: inFeedback ? null : () => ref.read(quizControllerProvider.notifier).answer(index),
        child: Container(
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: gradientColors),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
