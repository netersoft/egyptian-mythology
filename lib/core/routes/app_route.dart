import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../view/redirection.dart';
import '../../view/screens/account/settings_screen.dart';
import '../../view/screens/documentation/doc_sections_screen.dart';
import '../../view/screens/documentation/doc_viewer_screen.dart';
import '../../view/screens/main_screen.dart';
import '../../view/screens/other/about_screen.dart';
import '../../view/screens/quiz/instructions_screen.dart';
import '../../view/screens/stats/stats_screen.dart';
import '../models/doc_category.dart';
import 'swipeable_page_route.dart';

part 'app_route.g.dart';

class RedirectionExtra {
  final List<String> routes;
  final Map<String, dynamic> params;
  const RedirectionExtra({this.routes = const [], this.params = const {}});
}

@TypedGoRoute<RedirectionRoute>(path: '/')
class RedirectionRoute extends GoRouteData with $RedirectionRoute {
  const RedirectionRoute({this.$extra});

  final RedirectionExtra? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) => const Redirection();
}

@TypedGoRoute<MainRoute>(
  path: '/main',
  routes: [
    TypedGoRoute<SettingsRoute>(path: 'other/settings'),
    TypedGoRoute<AboutRoute>(path: 'other/about'),
    TypedGoRoute<DocSectionsRoute>(
      path: 'doc',
      routes: [
        TypedGoRoute<GodsDocRoute>(path: 'gods'),
        TypedGoRoute<CosmogoniesDocRoute>(path: 'cosmogonies'),
        TypedGoRoute<MythsDocRoute>(path: 'myths'),
      ],
    ),
    TypedGoRoute<InstructionsRoute>(path: 'quiz/instructions'),
    TypedGoRoute<StatsRoute>(path: 'stats'),
  ],
)
class MainRoute extends GoRouteData with $MainRoute {
  const MainRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MainScreen();
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => SwipeablePage<void>(builder: (context) => const SettingsScreen());
}

class AboutRoute extends GoRouteData with $AboutRoute {
  const AboutRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => SwipeablePage<void>(builder: (context) => const AboutScreen());
}

class DocSectionsRoute extends GoRouteData with $DocSectionsRoute {
  const DocSectionsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => SwipeablePage<void>(builder: (context) => const DocSectionsScreen());
}

class GodsDocRoute extends GoRouteData with $GodsDocRoute {
  const GodsDocRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      SwipeablePage<void>(builder: (context) => const DocViewerScreen(category: DocCategory.gods));
}

class CosmogoniesDocRoute extends GoRouteData with $CosmogoniesDocRoute {
  const CosmogoniesDocRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      SwipeablePage<void>(builder: (context) => const DocViewerScreen(category: DocCategory.cosmogonies));
}

class MythsDocRoute extends GoRouteData with $MythsDocRoute {
  const MythsDocRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      SwipeablePage<void>(builder: (context) => const DocViewerScreen(category: DocCategory.myths));
}

class InstructionsRoute extends GoRouteData with $InstructionsRoute {
  const InstructionsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => SwipeablePage<void>(builder: (context) => const InstructionsScreen());
}

class StatsRoute extends GoRouteData with $StatsRoute {
  const StatsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => SwipeablePage<void>(builder: (context) => const StatsScreen());
}
