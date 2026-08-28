import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/routes/app_route.dart';
import '../../core/services/audio/audio_service.dart';
import '../../core/services/di/locator.dart';
import '../../core/services/i18n/translations.g.dart';
import '../components/backgrounds/pyramid_background.dart';
import '../components/buttons/menu_button.dart';
import '../components/misc/app_header_card.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    AppTheme.setStatusBarColor();
    unawaited(locator<AudioService>().startMusic());
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t.exitTitle),
        content: Text(dialogContext.t.exitMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.t.yes),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _navigate(VoidCallback push) {
    unawaited(locator<AudioService>().playClick());
    push();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      if (await _confirmExit() && context.mounted) {
        await SystemNavigator.pop();
      }
    },
    child: Scaffold(
      body: PyramidBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeaderCard(title: context.t.mainMenu),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MenuButton(
                        icon: Icons.import_contacts,
                        label: context.t.documentation,
                        onTap: () => _navigate(() => const DocSectionsRoute().push(context)),
                      ),
                      MenuButton(
                        icon: Icons.extension,
                        label: context.t.quiz,
                        onTap: () => _navigate(() => const InstructionsRoute().push(context)),
                      ),
                      MenuButton(
                        icon: Icons.assessment,
                        label: context.t.stats,
                        onTap: () => _navigate(() => const StatsRoute().push(context)),
                      ),
                      MenuButton(
                        icon: Icons.build,
                        label: context.t.settings,
                        onTap: () => _navigate(() => const SettingsRoute().push(context)),
                      ),
                      MenuButton(
                        icon: Icons.info_outline,
                        label: context.t.about,
                        onTap: () => _navigate(() => const AboutRoute().push(context)),
                      ),
                    ],
                  ),
                ),
              ),
              const _AnkhFooter(),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AnkhFooter extends StatefulWidget {
  const _AnkhFooter();

  @override
  State<_AnkhFooter> createState() => _AnkhFooterState();
}

class _AnkhFooterState extends State<_AnkhFooter> with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final AnimationController _shakeController;
  late final Animation<Offset> _slide;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _slide = Tween<Offset>(begin: const Offset(0, 3), end: Offset.zero).animate(_slideController);

    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 270));
    _shake = Tween<double>(begin: -8 * math.pi / 180, end: 8 * math.pi / 180).animate(_shakeController);

    unawaited(
      _slideController.forward().whenComplete(() {
        if (mounted) unawaited(_shakeController.repeat(reverse: true));
      }),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SlideTransition(
      position: _slide,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.rotate(angle: _shake.value, child: child),
            child: Image.asset('assets/images/egyptian/ic_ankh.png', width: 25, height: 25),
          ),
          const SizedBox(width: 4),
          const Text(
            'x3',
            style: TextStyle(color: AppColors.goldenYellow, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}
