enum QuizPhase { loading, playing, gameOver }

const _sentinel = Object();

class QuizState {
  final QuizPhase phase;
  final String question;
  final List<String> choices;
  final int score;
  final int life;
  final int remainingSeconds;
  final int? selectedIndex;
  final int? correctIndex;
  final bool allQuestionsAnswered;
  final bool isRecord;
  final bool isPaused;

  const QuizState({
    this.phase = QuizPhase.loading,
    this.question = '',
    this.choices = const [],
    this.score = 0,
    this.life = 3,
    this.remainingSeconds = 20,
    this.selectedIndex,
    this.correctIndex,
    this.allQuestionsAnswered = false,
    this.isRecord = false,
    this.isPaused = false,
  });

  QuizState copyWith({
    QuizPhase? phase,
    String? question,
    List<String>? choices,
    int? score,
    int? life,
    int? remainingSeconds,
    Object? selectedIndex = _sentinel,
    Object? correctIndex = _sentinel,
    bool? allQuestionsAnswered,
    bool? isRecord,
    bool? isPaused,
  }) => QuizState(
    phase: phase ?? this.phase,
    question: question ?? this.question,
    choices: choices ?? this.choices,
    score: score ?? this.score,
    life: life ?? this.life,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    selectedIndex: identical(selectedIndex, _sentinel) ? this.selectedIndex : selectedIndex as int?,
    correctIndex: identical(correctIndex, _sentinel) ? this.correctIndex : correctIndex as int?,
    allQuestionsAnswered: allQuestionsAnswered ?? this.allQuestionsAnswered,
    isRecord: isRecord ?? this.isRecord,
    isPaused: isPaused ?? this.isPaused,
  );
}
