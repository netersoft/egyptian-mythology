import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/routes/app_route.dart';
import '../../core/services/audio/audio_service.dart';
import '../../core/services/di/locator.dart';
import '../../core/services/i18n/translations.g.dart';
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.black, AppColors.blackRussian],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _MainMenuHeader(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MenuButton(
                        icon: Icons.import_contacts,
                        label: context.t.documentation,
                        onTap: () => _navigate(() => const DocSectionsRoute().push(context)),
                      ),
                      _MenuButton(
                        icon: Icons.extension,
                        label: context.t.quiz,
                        onTap: () => _navigate(() => const InstructionsRoute().push(context)),
                      ),
                      _MenuButton(
                        icon: Icons.assessment,
                        label: context.t.stats,
                        onTap: () => _navigate(() => const StatsRoute().push(context)),
                      ),
                      _MenuButton(
                        icon: Icons.build,
                        label: context.t.settings,
                        onTap: () => _navigate(() => const SettingsRoute().push(context)),
                      ),
                      _MenuButton(
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

class _MainMenuHeader extends StatelessWidget {
  const _MainMenuHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2160),
      curve: Curves.easeIn,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/egyptian/ankh_launcher.png', width: 100, height: 100),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.t.appNameAlt, style: const TextStyle(color: AppColors.gray, fontSize: 12)),
                _TypewriterText(
                  text: context.t.mainMenu,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const _TypewriterText({required this.text, this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _shown = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    var charCount = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 75), (timer) {
      if (charCount >= widget.text.length) {
        timer.cancel();
        return;
      }
      charCount++;
      if (mounted) setState(() => _shown = widget.text.substring(0, charCount));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(_shown, style: widget.style);
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 52,
          decoration: BoxDecoration(color: AppColors.goldenYellow, borderRadius: BorderRadius.circular(42)),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: onTap,
            child: Container(
              width: 250,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.goldenYellow, AppColors.goldenRod],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.black),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
