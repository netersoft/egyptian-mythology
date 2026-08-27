import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_theme.dart';

// NOTE: placeholder — the real quiz instructions + "let's play" flow lands
// in the quiz phase of the migration plan.
class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.t.quiz),
      backgroundColor: AppTheme.getAppbarBgColor(),
      foregroundColor: Colors.white,
    ),
    body: Center(child: Text(context.t.instructions)),
  );
}
