import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/navigation/redirection_provider.dart';
import '../core/services/i18n/translations.g.dart';
import 'components/backgrounds/pyramid_background.dart';
import 'themes/app_colors.dart';

/// Redirection screen
class Redirection extends ConsumerStatefulWidget {
  const Redirection({super.key});

  @override
  RedirectionState createState() => RedirectionState();
}

class RedirectionState extends ConsumerState<Redirection> {
  @override
  void initState() {
    super.initState();

    FlutterNativeSplash.remove();
  }

  /// Builds a FlutterSplashScreen widget mirroring the legacy activity_splash.xml:
  /// pyramid backdrop, "EGYPTIAN" / "MYTHOLOGY" title, indeterminate loading bar.
  ///
  /// When the splash screen ends, it calls the [redirect] method of the [redirectionProvider]
  /// with the current [BuildContext].
  @override
  Widget build(BuildContext context) {
    ref.watch(redirectionProvider);

    return FlutterSplashScreen(
      useImmersiveMode: true,
      duration: const Duration(milliseconds: 2000),
      splashScreenBody: PyramidBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                context.t.splashTitleLine1,
                textAlign: TextAlign.center,
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  fontFamily: 'caladea',
                  fontWeight: FontWeight.bold,
                  fontSize: 42,
                  color: AppColors.white,
                ),
              ),
              Text(
                context.t.splashTitleLine2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'macondo',
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                  color: AppColors.white,
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.all(24),
                child: LinearProgressIndicator(
                  color: AppColors.yellow,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
      onInit: () {},
      onEnd: () {
        ref.read(redirectionProvider.notifier).redirect(ref);
      },
    );
  }
}
