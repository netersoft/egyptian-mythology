import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/routes/app_route.dart';
import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../components/backgrounds/pyramid_background.dart';
import '../../components/buttons/menu_button.dart';
import '../../themes/app_colors.dart';

class DocSectionsScreen extends StatelessWidget {
  const DocSectionsScreen({super.key});

  void _navigate(BuildContext context, VoidCallback push) {
    unawaited(locator<AudioService>().playClick());
    push();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.t.docTitle),
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.goldenYellow,
    ),
    body: PyramidBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MenuButton(
              icon: Icons.groups,
              label: context.t.gods,
              onTap: () => _navigate(context, () => const GodsDocRoute().push(context)),
            ),
            MenuButton(
              icon: Icons.auto_awesome,
              label: context.t.cosmogonies,
              onTap: () => _navigate(context, () => const CosmogoniesDocRoute().push(context)),
            ),
            MenuButton(
              icon: Icons.auto_stories,
              label: context.t.myths,
              onTap: () => _navigate(context, () => const MythsDocRoute().push(context)),
            ),
          ],
        ),
      ),
    ),
  );
}
