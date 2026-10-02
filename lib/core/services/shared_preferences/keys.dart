import '../../models/quiz_theme.dart';

abstract class PrefKeys {
  static const locale = 'appLocale';
  static const firstOpening = 'appFirstOpening';
  static const enableNotifications = 'enableNotifications';
  static const bestScore = 'bestScore';
  static const musicEnabled = 'musicEnabled';
  static const soundEnabled = 'soundEnabled';

  // The full game keeps the legacy key, so the record set before themes
  // existed carries over.
  static String bestScoreFor(QuizTheme theme) => theme == QuizTheme.all ? bestScore : '${bestScore}_${theme.name}';

  static String docLastItem(String categoryFolder) => 'docLastItem_$categoryFolder';
  static String docLastOffset(String categoryFolder) => 'docLastOffset_$categoryFolder';
}
