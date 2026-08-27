import 'package:hive_ce/hive.dart';

import '../../enums/app_brightness.dart';
import '../../models/score_entry_model.dart';

part 'hive_adapters.g.dart';

@GenerateAdapters([
  AdapterSpec<AppBrightness>(),
  AdapterSpec<ScoreEntryModel>(),
], firstTypeId: 100)
class HiveAdapters {}
