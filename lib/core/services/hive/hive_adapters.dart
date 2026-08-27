import 'package:hive_ce/hive.dart';

import '../../enums/app_brightness.dart';

part 'hive_adapters.g.dart';

@GenerateAdapters([
  AdapterSpec<AppBrightness>(),
], firstTypeId: 100)
class HiveAdapters {}
