import 'quiz_theme.dart';

class ScoreEntryModel {
  final int score;

  // When the game ended. Null only on entries saved by app versions up to
  // 2.0.3, which stored just the preformatted [date] string --
  // ScoresRepository.getAll() backfills it from that string on read.
  final DateTime? playedAt;

  // Legacy preformatted timestamp ("Mon 03.09.2026 - 14:05", English weekday
  // whatever the app language). Kept so older entries still deserialize, and
  // as a display fallback if one can't be parsed; new entries leave it empty.
  final String date;

  // QuizTheme.name of the game, stored as a plain string so the Hive adapter
  // needs no enum adapter. Null on entries saved before themes existed, which
  // were all full games.
  final String? theme;

  const ScoreEntryModel({required this.score, this.playedAt, this.date = '', this.theme});

  QuizTheme get quizTheme => QuizTheme.values.asNameMap()[theme] ?? QuizTheme.all;
}
