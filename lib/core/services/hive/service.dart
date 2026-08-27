import 'package:hive_ce_flutter/hive_flutter.dart';

import 'hive_registrar.g.dart';
import 'keys.dart';

class HiveService {
  static HiveService? _instance;

  static Future<HiveService?> getInstance() async {
    _instance ??= HiveService();

    await _instance?.openBoxes();

    return _instance;
  }

  Box? scoresBox;
  Box? helperBox;

  HiveService();

  Future<void> openBoxes() async {
    // Register adapters
    Hive.registerAdapters();

    scoresBox = await Hive.openBox(HiveKeys.scores);
    helperBox = await Hive.openBox(HiveKeys.helper);
  }
}
