import 'package:egyptian_mythology/core/models/quiz_question_model.dart';
import 'package:egyptian_mythology/core/models/quiz_state.dart';
import 'package:egyptian_mythology/core/providers/quiz/quiz_provider.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_utils.dart';

List<QuizQuestionModel> _questions(int count) => List.generate(
  count,
  (i) => QuizQuestionModel(id: i + 1, question: 'Question $i', answer: 'Answer$i', choices: ['Answer$i', 'Wrong${i}a', 'Wrong${i}b', 'Wrong${i}c']),
);

void main() {
  late MockQuizService mockQuizService;
  late MockScoresRepository mockScoresRepository;

  setUp(() async {
    mockQuizService = MockQuizService();
    mockScoresRepository = MockScoresRepository();

    when(() => mockQuizService.loadQuestions()).thenAnswer((_) async => _questions(10));
    when(() => mockScoresRepository.getBestScore()).thenReturn(0);
    when(() => mockScoresRepository.add(any())).thenAnswer((_) async {});

    await setupTestLocator(quizService: mockQuizService, scoresRepository: mockScoresRepository);
  });

  tearDown(teardownTestLocator);

  // quizControllerProvider is autoDispose; without an active listener it
  // gets torn down (and silently recreated on the next read) between
  // statements, which is why we pin it alive for the container's lifetime.
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(quizControllerProvider, (_, _) {});
    return container;
  }

  group('QuizController', () {
    test('initial state is loading', () {
      final container = makeContainer();
      expect(container.read(quizControllerProvider).phase, QuizPhase.loading);
    });

    test('start loads the first question with a fresh 20s timer and 3 lives', () {
      fakeAsync((async) {
        final container = makeContainer();
        container.read(quizControllerProvider.notifier).start();
        async.flushMicrotasks();

        final state = container.read(quizControllerProvider);
        expect(state.phase, QuizPhase.playing);
        expect(state.question, 'Question 0 ?');
        expect(state.choices, containsAll(['Answer0', 'Wrong0a', 'Wrong0b', 'Wrong0c']));
        expect(state.remainingSeconds, 20);
        expect(state.life, 3);
        expect(state.score, 0);
      });
    });

    test('countdown ticks down every second', () {
      fakeAsync((async) {
        final container = makeContainer();
        container.read(quizControllerProvider.notifier).start();
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 3));

        expect(container.read(quizControllerProvider).remainingSeconds, 17);
      });
    });

    test('correct answer awards remainingSeconds * 10 points and advances to the next question', () {
      fakeAsync((async) {
        final container = makeContainer();
        container.read(quizControllerProvider.notifier).start();
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 5));

        final beforeAnswer = container.read(quizControllerProvider);
        final correctIndex = beforeAnswer.choices.indexOf('Answer0');

        container.read(quizControllerProvider.notifier).answer(correctIndex);
        async.elapse(const Duration(milliseconds: 2200));

        final state = container.read(quizControllerProvider);
        expect(state.score, 150);
        expect(state.question, 'Question 1 ?');
        expect(state.remainingSeconds, 20);
        expect(state.life, 3);
      });
    });

    test('wrong answer costs a life, resets the streak, and advances to the next question', () {
      fakeAsync((async) {
        final container = makeContainer();
        container.read(quizControllerProvider.notifier).start();
        async.flushMicrotasks();

        final beforeAnswer = container.read(quizControllerProvider);
        final wrongIndex = beforeAnswer.choices.indexWhere((c) => c != 'Answer0');

        container.read(quizControllerProvider.notifier).answer(wrongIndex);
        async.elapse(const Duration(milliseconds: 2200));

        final state = container.read(quizControllerProvider);
        expect(state.life, 2);
        expect(state.phase, QuizPhase.playing);
        expect(state.question, 'Question 1 ?');
        expect(state.score, 0);
      });
    });

    test('letting the timer run out reveals the correct answer, then costs a life', () {
      fakeAsync((async) {
        final container = makeContainer();
        container.read(quizControllerProvider.notifier).start();
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 20));

        final revealed = container.read(quizControllerProvider);
        expect(revealed.remainingSeconds, 0);
        expect(revealed.question, 'Question 0 ?');
        expect(revealed.correctIndex, revealed.choices.indexOf('Answer0'));
        expect(revealed.selectedIndex, isNull);
        expect(revealed.life, 3);

        async.elapse(const Duration(milliseconds: 2200));

        final state = container.read(quizControllerProvider);
        expect(state.life, 2);
        expect(state.question, 'Question 1 ?');
        expect(state.correctIndex, isNull);
      });
    });

    test('answering while the timed-out answer is being revealed is ignored', () {
      fakeAsync((async) {
        final container = makeContainer();
        final notifier = container.read(quizControllerProvider.notifier)..start();
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 20));

        final revealed = container.read(quizControllerProvider);
        notifier.answer(revealed.correctIndex!);
        async.elapse(const Duration(milliseconds: 2200));

        final state = container.read(quizControllerProvider);
        expect(state.score, 0);
        expect(state.life, 2);
        expect(state.question, 'Question 1 ?');
      });
    });

    test('losing all 3 lives ends the game without completing all questions', () {
      fakeAsync((async) {
        final container = makeContainer();
        container.read(quizControllerProvider.notifier).start();
        async.flushMicrotasks();

        for (var q = 0; q < 3; q++) {
          final state = container.read(quizControllerProvider);
          final wrongIndex = state.choices.indexWhere((c) => c != 'Answer$q');
          container.read(quizControllerProvider.notifier).answer(wrongIndex);
          async.elapse(const Duration(milliseconds: 2200));
        }

        final state = container.read(quizControllerProvider);
        expect(state.phase, QuizPhase.gameOver);
        expect(state.allQuestionsAnswered, isFalse);
        expect(state.life, 0);
        verify(() => mockScoresRepository.add(0)).called(1);
      });
    });

    test('gains a life back only after 6 correct answers in a row while below 3 lives', () {
      fakeAsync((async) {
        final container = makeContainer();
        container.read(quizControllerProvider.notifier).start();
        async.flushMicrotasks();

        var q = 0;

        // Lose a life first so life < 3 and the streak starts mattering.
        var state = container.read(quizControllerProvider);
        container.read(quizControllerProvider.notifier).answer(state.choices.indexWhere((c) => c != 'Answer$q'));
        async.elapse(const Duration(milliseconds: 2200));
        q += 1;
        expect(container.read(quizControllerProvider).life, 2);

        // 5 correct answers in a row: streak climbs but life is unchanged.
        for (var i = 0; i < 5; i++) {
          state = container.read(quizControllerProvider);
          container.read(quizControllerProvider.notifier).answer(state.choices.indexOf('Answer$q'));
          async.elapse(const Duration(milliseconds: 2200));
          q += 1;
        }
        expect(container.read(quizControllerProvider).life, 2);

        // The 6th correct answer in a row restores the lost life.
        state = container.read(quizControllerProvider);
        container.read(quizControllerProvider.notifier).answer(state.choices.indexOf('Answer$q'));
        async.elapse(const Duration(milliseconds: 2200));

        expect(container.read(quizControllerProvider).life, 3);
      });
    });

    test('answering the last question ends the game with allQuestionsAnswered=true and persists the score', () {
      when(() => mockQuizService.loadQuestions()).thenAnswer((_) async => _questions(1));

      fakeAsync((async) {
        final container = makeContainer();
        container.read(quizControllerProvider.notifier).start();
        async.flushMicrotasks();

        final beforeAnswer = container.read(quizControllerProvider);
        container.read(quizControllerProvider.notifier).answer(beforeAnswer.choices.indexOf('Answer0'));
        async.elapse(const Duration(milliseconds: 2200));

        final state = container.read(quizControllerProvider);
        expect(state.phase, QuizPhase.gameOver);
        expect(state.allQuestionsAnswered, isTrue);
        expect(state.score, greaterThan(0));
        verify(() => mockScoresRepository.add(state.score)).called(1);
      });
    });

    test('isRecord is true only when the final score beats the previous best', () {
      when(() => mockQuizService.loadQuestions()).thenAnswer((_) async => _questions(1));
      when(() => mockScoresRepository.getBestScore()).thenReturn(50);

      fakeAsync((async) {
        final container = makeContainer();
        container.read(quizControllerProvider.notifier).start();
        async.flushMicrotasks();

        final beforeAnswer = container.read(quizControllerProvider);
        container.read(quizControllerProvider.notifier).answer(beforeAnswer.choices.indexOf('Answer0'));
        async.elapse(const Duration(milliseconds: 2200));

        expect(container.read(quizControllerProvider).isRecord, isTrue);
      });
    });

    // Leaving QuizPlayScreen (back swipe) mid-feedback disposes the autoDispose
    // controller while answer() is still awaiting its feedback delay.
    test('leaving the quiz during answer feedback does not touch the disposed controller', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final subscription = container.listen(quizControllerProvider, (_, _) {});
        final notifier = container.read(quizControllerProvider.notifier)..start();
        async.flushMicrotasks();

        Object? error;
        final correctIndex = container.read(quizControllerProvider).choices.indexOf('Answer0');
        notifier.answer(correctIndex).catchError((Object e) => error = e);
        subscription.close();
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 30));

        expect(error, isNull);
        expect(async.pendingTimers, isEmpty);
      });
    });
  });
}
