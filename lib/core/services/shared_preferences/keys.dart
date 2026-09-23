abstract class PrefKeys {
  static const locale = 'appLocale';
  static const firstOpening = 'appFirstOpening';
  static const enableNotifications = 'enableNotifications';
  static const bestScore = 'bestScore';
  static const musicEnabled = 'musicEnabled';
  static const soundEnabled = 'soundEnabled';

  static String docLastItem(String categoryFolder) => 'docLastItem_$categoryFolder';
  static String docLastOffset(String categoryFolder) => 'docLastOffset_$categoryFolder';
}
