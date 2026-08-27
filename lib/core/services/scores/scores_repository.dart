import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../models/score_entry_model.dart';
import '../di/locator.dart';
import '../hive/keys.dart';
import '../hive/service.dart';
import '../shared_preferences/keys.dart';
import '../shared_preferences/service.dart';

class ScoresRepository {
  Box get _box => locator<HiveService>().scoresBox!;

  SharedPreferencesService get _prefs => locator<SharedPreferencesService>();

  List<ScoreEntryModel> getAll() {
    final raw = _box.get(HiveKeys.scoresList, defaultValue: <ScoreEntryModel>[]) as List;
    return raw.cast<ScoreEntryModel>();
  }

  int getBestScore() => _prefs.getInt(PrefKeys.bestScore, defaultValue: 0) ?? 0;

  Future<void> add(int score) async {
    final entries = getAll()..add(ScoreEntryModel(date: _formatNow(), score: score));
    await _box.put(HiveKeys.scoresList, entries);

    if (score > getBestScore()) {
      await _prefs.setInt(PrefKeys.bestScore, score);
    }
  }

  Future<void> clear() async {
    await _box.delete(HiveKeys.scoresList);
    await _prefs.setInt(PrefKeys.bestScore, 0);
  }

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Mirrors the legacy app's "E dd.MM.yyyy '-' HH:mm" score timestamp format.
  String _formatNow() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${_weekdays[now.weekday - 1]} ${two(now.day)}.${two(now.month)}.${now.year} - ${two(now.hour)}:${two(now.minute)}';
  }
}
