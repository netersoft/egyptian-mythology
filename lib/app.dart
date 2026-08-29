import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/lifecycle/app_lifecycle_layer.dart';
import 'core/routes/router.dart';
import 'core/services/i18n/translations.g.dart';
import 'view/themes/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    EasyLoading.instance
      ..indicatorType = EasyLoadingIndicatorType.ring
      ..maskColor = Colors.black.withValues(alpha: 0.2)
      ..loadingStyle = EasyLoadingStyle.custom
      ..maskType = EasyLoadingMaskType.custom
      ..backgroundColor = AppTheme.pickColor(
        light: Colors.white,
        dark: Colors.black,
      )
      ..indicatorColor = AppTheme.pickColor(
        light: AppTheme.primaryColor,
        dark: Colors.white,
      )
      ..progressColor = AppTheme.pickColor(
        light: AppTheme.primaryColor,
        dark: Colors.white,
      )
      ..textColor = AppTheme.getTextColor()
      ..dismissOnTap = false
      ..indicatorSize = 45.0
      ..radius = 5.0;

    return const AppLifecycleLayer(child: AppRouterView());
  }
}

class AppRouterView extends StatelessWidget {
  const AppRouterView({super.key});

  @override
  Widget build(BuildContext context) => TranslationProvider(
    child: Builder(
      builder: (context) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.setup(context),
        locale: TranslationProvider.of(context).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
        onGenerateTitle: (ctx) => t.appNameAlt,
        // Papyrus (the app-wide default font, matching the legacy app's global
        // Calligraphy override) reads smaller than a standard UI sans at the same
        // point size, so scale all text up to compensate -- as the legacy app's
        // hand-picked sp values already did per-screen.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.2)),
          child: EasyLoading.init()(context, child),
        ),
      ),
    ),
  );
}
