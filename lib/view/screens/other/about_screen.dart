import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_theme.dart';

// NOTE: placeholder — the real credits/share/rate/contact screen lands in
// the settings & about phase of the migration plan.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.t.about),
      backgroundColor: AppTheme.getAppbarBgColor(),
      foregroundColor: Colors.white,
    ),
    body: Center(child: Text(context.t.appNameAlt)),
  );
}
