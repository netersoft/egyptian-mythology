import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../core/helpers/router/navigation_helper.dart';
import '../../core/providers/main_provider.dart';
import '../../core/routes/app_route.dart';
import '../../core/services/di/locator.dart';
import '../../core/services/i18n/translations.g.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import 'main/home_screen.dart';

// NOTE: this is a placeholder shell kept just compiling for Phase 0 — the
// real Egyptian Mythology main menu (Doc/Quiz/Stats/Settings/About) replaces
// this screen entirely in Phase 2 of the migration plan.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static Widget defaultAppBar(
    MainState mainProvider,
  ) => AppBar(
    elevation: 0.0,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/launcher/logo_reverse.svg',
          width: 90.0,
        ),
      ],
    ),
    actions: [
      IconButton(
        onPressed: () {
          locator<NavigationHelper>().push(const SettingsRoute().location);
        },
        icon: const Icon(
          Icons.settings,
          color: Colors.white,
        ),
      ),
    ],
    backgroundColor: AppTheme.getAppbarBgColor(),
    iconTheme: const IconThemeData(color: Colors.white),
  );

  @override
  Widget build(BuildContext context) => const KeyboardDismissOnTap(child: CentralContainer());
}

class CentralContainer extends ConsumerStatefulWidget {
  const CentralContainer({super.key});

  @override
  ConsumerState<CentralContainer> createState() => _CentralContainerState();
}

class _CentralContainerState extends ConsumerState<CentralContainer> {
  @override
  void initState() {
    super.initState();

    AppTheme.setStatusBarColor();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(AppBar().preferredSize.height),
      child: ref.read(mainProvider.notifier).selectAppBar(),
    ),
    body: const HomeScreen(),
    drawer: Drawer(
      backgroundColor: AppTheme.pickColor(
        light: Colors.white,
        dark: AppColors.blackRussian,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.pickColor(
                light: AppTheme.primaryColor,
                dark: AppColors.raisinBlack,
              ),
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                context.t.appNameAlt,
                style: const TextStyle(fontSize: 21, color: Colors.white),
              ),
            ),
          ),
          ListTile(
            title: Text(context.t.settings),
            leading: const Icon(Icons.settings),
            onTap: () {
              const SettingsRoute().push(context);
            },
          ),
        ],
      ),
    ),
  );
}
