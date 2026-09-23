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
    return raw.cast<ScoreEntryModel>().map(_withPlayedAt).toList();
  }

  int getBestScore() => _prefs.getInt(PrefKeys.bestScore, defaultValue: 0) ?? 0;

  Future<void> add(int score) async {
    final entries = getAll()..add(ScoreEntryModel(score: score, playedAt: DateTime.now()));
    await _box.put(HiveKeys.scoresList, entries);

    if (score > getBestScore()) {
      await _prefs.setInt(PrefKeys.bestScore, score);
    }
  }

  Future<void> clear() async {
    await _box.delete(HiveKeys.scoresList);
    await _prefs.setInt(PrefKeys.bestScore, 0);
  }

  // Entries saved up to 2.0.3 only carry the legacy "E dd.MM.yyyy '-' HH:mm"
  // string (always an English weekday); recover the DateTime from it so they
  // can be displayed in the current app language like newer ones.
  static final _legacyDate = RegExp(r'^\w+ (\d{2})\.(\d{2})\.(\d{4}) - (\d{2}):(\d{2})$');

  static ScoreEntryModel _withPlayedAt(ScoreEntryModel entry) {
    if (entry.playedAt != null) return entry;
    final match = _legacyDate.firstMatch(entry.date.trim());
    if (match == null) return entry;
    final [day, month, year, hour, minute] = [for (var i = 1; i <= 5; i++) int.parse(match.group(i)!)];
    return ScoreEntryModel(score: entry.score, playedAt: DateTime(year, month, day, hour, minute), date: entry.date);
  }
}
