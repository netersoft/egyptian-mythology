import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_theme.dart';

// NOTE: placeholder — the real Gods/Cosmogonies/Myths section picker lands
// in the documentation-viewer phase of the migration plan.
class DocSectionsScreen extends StatelessWidget {
  const DocSectionsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.t.documentation),
      backgroundColor: AppTheme.getAppbarBgColor(),
      foregroundColor: Colors.white,
    ),
    body: Center(child: Text(context.t.documentation)),
  );
}
