import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_theme.dart';

// NOTE: placeholder — the real score history + progress graph lands in the
// stats phase of the migration plan.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.t.stats),
      backgroundColor: AppTheme.getAppbarBgColor(),
      foregroundColor: Colors.white,
    ),
    body: Center(child: Text(context.t.noScore)),
  );
}
