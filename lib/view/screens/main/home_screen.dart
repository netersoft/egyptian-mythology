import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../components/misc/status.dart';

// NOTE: placeholder content kept just compiling for Phase 0 — replaced by the
// real Egyptian Mythology main menu in Phase 2 of the migration plan.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Status(
    icon: Icons.auto_awesome,
    text: context.t.appNameAlt,
  );
}
