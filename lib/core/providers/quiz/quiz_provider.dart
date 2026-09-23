import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/quiz_question_model.dart';
import '../../models/quiz_state.dart';
import '../../services/audio/audio_service.dart';
import '../../services/di/locator.dart';
import '../../services/quiz/quiz_service.dart';
import '../../services/scores/scores_repository.dart';

part 'quiz_provider.g.dart';

// Mirrors the legacy PlayActivity exactly, including its quirks:
// - a life is only regained after 6 correct answers in a row (not 5 -- the
//   Java increments a 0-based counter and only grants the life once it
//   would exceed 5, i.e. on the 6th correct answer).
// - the feedback delay (flash the tapped/correct button, then advance) is
//   AppUtilities.DELAY / 2 = 2160ms.
const _feedbackDelay = Duration(milliseconds: 2160);
const _questionSeconds = 20;

// The provider is autoDispose, so leaving QuizPlayScreen mid-game (e.g. a
// back swipe during the feedback delay) disposes it while an await is still
// pending -- every async gap below re-checks ref.mounted before touching
// state, or Riverpod throws UnmountedRefException.

@riverpod
class QuizController extends _$QuizController {
  List<QuizQuestionModel> _questions = [];
  int _index = 0;
  int _correctStreak = 0;
  Timer? _timer;

  QuizService get _quizService => locator<QuizService>();

  ScoresRepository get _scoresRepository => locator<ScoresRepository>();

  AudioService get _audioService => locator<AudioService>();

  @override
  QuizState build() {
    ref.onDispose(() => _timer?.cancel());
    return const QuizState();
  }

  Future<void> start() async {
    _questions = await _quizService.loadQuestions();
    if (!ref.mounted) return;
    _index = 0;
    _correctStreak = 0;
    state = const QuizState(phase: QuizPhase.playing);
    _loadQuestion();
  }

  Future<void> answer(int selectedIndex) async {
    // Already showing feedback (answered, or timed out) -- ignore extra taps.
    if (state.correctIndex != null) return;
    _timer?.cancel();
    unawaited(_audioService.playClick());

    // _index was already advanced past the current question by _loadQuestion.
    final currentQuestion = _questions[_index - 1];
    final choices = state.choices;
    final correctIndex = choices.indexOf(currentQuestion.answer);

    if (choices[selectedIndex] == currentQuestion.answer) {
      final gained = state.remainingSeconds * 10;
      var life = state.life;
      if (life < 3) {
        if (_correctStreak < 5) {
          _correctStreak += 1;
        } else {
          life += 1;
          _correctStreak = 0;
        }
      }

      state = state.copyWith(score: state.score + gained, life: life, selectedIndex: selectedIndex, correctIndex: selectedIndex);
      await Future<void>.delayed(_feedbackDelay);
      if (!ref.mounted) return;
      _loadQuestion();
    } else {
      _correctStreak = 0;
      state = state.copyWith(selectedIndex: selectedIndex, correctIndex: correctIndex);
      await Future<void>.delayed(_feedbackDelay);
      if (!ref.mounted) return;
      await _loseLife();
    }
  }

  // Mirrors legacy's next(): checks whether there's a question left to show
  // -- ending the game if not -- then displays it and advances the index.
  void _loadQuestion() {
    _timer?.cancel();

    if (_index >= _questions.length) {
      unawaited(_finish(allQuestionsAnswered: true));
      return;
    }

    final currentQuestion = _questions[_index];
    _index += 1;
    final choices = List<String>.of(currentQuestion.choices)..shuffle();

    state = state.copyWith(
      phase: QuizPhase.playing,
      question: '${currentQuestion.question.trim()} ?',
      choices: choices,
      remainingSeconds: _questionSeconds,
      selectedIndex: null,
      correctIndex: null,
    );

    if (!state.isPaused) _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  // Called when the app leaves the foreground (QuizPlayScreen's lifecycle
  // listener): a phone call or an app switch must not burn through the
  // countdown and the player's lives. The feedback delay of an answer
  // already given keeps running -- only the countdown is frozen, and a
  // question loaded while paused waits for resume() to start its timer.
  void pause() {
    if (state.phase != QuizPhase.playing || state.isPaused) return;
    _timer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    if (!state.isPaused) return;
    state = state.copyWith(isPaused: false);
    // Mid-feedback (answered or timed out): the pending delay will load the
    // next question, which starts its own timer.
    if (state.phase == QuizPhase.playing && state.correctIndex == null) _startTimer();
  }

  void _tick() {
    unawaited(_audioService.playClick());

    final remaining = state.remainingSeconds - 1;
    if (remaining <= 0) {
      _timer?.cancel();
      _correctStreak = 0;
      unawaited(_onTimeout());
    } else {
      state = state.copyWith(remainingSeconds: remaining);
    }
  }

  // Unlike the legacy app (which moved straight on), flash the correct answer
  // for the same feedback delay as a wrong answer, so a timed-out question
  // still teaches the player something. selectedIndex stays null: no button
  // is marked wrong, only the right one is highlighted.
  Future<void> _onTimeout() async {
    final correctIndex = state.choices.indexOf(_questions[_index - 1].answer);
    state = state.copyWith(remainingSeconds: 0, correctIndex: correctIndex);
    await Future<void>.delayed(_feedbackDelay);
    if (!ref.mounted) return;
    await _loseLife();
  }

  Future<void> _loseLife() async {
    final life = state.life - 1;
    state = state.copyWith(life: life, selectedIndex: null, correctIndex: null);

    if (life <= 0) {
      await _finish(allQuestionsAnswered: false);
    } else {
      _loadQuestion();
    }
  }

  Future<void> _finish({required bool allQuestionsAnswered}) async {
    _timer?.cancel();
    final isRecord = state.score > _scoresRepository.getBestScore();
    await _scoresRepository.add(state.score);
    if (!ref.mounted) return;
    state = state.copyWith(phase: QuizPhase.gameOver, allQuestionsAnswered: allQuestionsAnswered, isRecord: isRecord);
  }
}
