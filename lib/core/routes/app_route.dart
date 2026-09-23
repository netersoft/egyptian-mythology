import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../view/redirection.dart';
import '../../view/screens/account/settings_screen.dart';
import '../../view/screens/documentation/doc_search_screen.dart';
import '../../view/screens/documentation/doc_sections_screen.dart';
import '../../view/screens/documentation/doc_viewer_screen.dart';
import '../../view/screens/main_screen.dart';
import '../../view/screens/other/about_screen.dart';
import '../../view/screens/quiz/game_over_screen.dart';
import '../../view/screens/quiz/instructions_screen.dart';
import '../../view/screens/quiz/quiz_play_screen.dart';
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
        TypedGoRoute<ReferenceDocRoute>(path: 'reference'),
        TypedGoRoute<DocSearchRoute>(path: 'search'),
      ],
    ),
    TypedGoRoute<InstructionsRoute>(path: 'quiz/instructions'),
    TypedGoRoute<QuizPlayRoute>(path: 'quiz/play'),
    TypedGoRoute<GameOverRoute>(path: 'quiz/game-over'),
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
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      SwipeablePage<void>(key: state.pageKey, builder: (context) => const SettingsScreen());
}

class AboutRoute extends GoRouteData with $AboutRoute {
  const AboutRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      SwipeablePage<void>(key: state.pageKey, builder: (context) => const AboutScreen());
}

class DocSectionsRoute extends GoRouteData with $DocSectionsRoute {
  const DocSectionsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      SwipeablePage<void>(key: state.pageKey, builder: (context) => const DocSectionsScreen());
}

class GodsDocRoute extends GoRouteData with $GodsDocRoute {
  // Opens straight on one page (?item=anubis) -- used by god-name links and
  // search results -- instead of resuming the last read one.
  const GodsDocRoute({this.item});

  final String? item;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => SwipeablePage<void>(
    key: state.pageKey,
    builder: (context) => DocViewerScreen(category: DocCategory.gods, initialItemId: item),
  );
}

class CosmogoniesDocRoute extends GoRouteData with $CosmogoniesDocRoute {
  const CosmogoniesDocRoute({this.item});

  final String? item;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => SwipeablePage<void>(
    key: state.pageKey,
    builder: (context) => DocViewerScreen(category: DocCategory.cosmogonies, initialItemId: item),
  );
}

class MythsDocRoute extends GoRouteData with $MythsDocRoute {
  const MythsDocRoute({this.item});

  final String? item;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => SwipeablePage<void>(
    key: state.pageKey,
    builder: (context) => DocViewerScreen(category: DocCategory.myths, initialItemId: item),
  );
}

class ReferenceDocRoute extends GoRouteData with $ReferenceDocRoute {
  const ReferenceDocRoute({this.item});

  final String? item;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => SwipeablePage<void>(
    key: state.pageKey,
    builder: (context) => DocViewerScreen(category: DocCategory.reference, initialItemId: item),
  );
}

class DocSearchRoute extends GoRouteData with $DocSearchRoute {
  const DocSearchRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      SwipeablePage<void>(key: state.pageKey, builder: (context) => const DocSearchScreen());
}

class InstructionsRoute extends GoRouteData with $InstructionsRoute {
  const InstructionsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      SwipeablePage<void>(key: state.pageKey, builder: (context) => const InstructionsScreen());
}

class QuizPlayRoute extends GoRouteData with $QuizPlayRoute {
  const QuizPlayRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      SwipeablePage<void>(key: state.pageKey, builder: (context) => const QuizPlayScreen());
}

class GameOverRoute extends GoRouteData with $GameOverRoute {
  const GameOverRoute({required this.score, required this.finish, required this.isRecord});

  final int score;
  final bool finish;
  final bool isRecord;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => SwipeablePage<void>(
    key: state.pageKey,
    // GameOverScreen's PopScope(canPop: false) blocks the back button/gesture,
    // but the swipe-anywhere-to-go-back detector on SwipeablePage runs
    // independently of that -- disable it too, or a stray drag can pop this
    // route straight back into a fresh QuizPlayScreen.
    canSwipe: false,
    builder: (context) => GameOverScreen(score: score, finish: finish, isRecord: isRecord),
  );
}

class StatsRoute extends GoRouteData with $StatsRoute {
  const StatsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      SwipeablePage<void>(key: state.pageKey, builder: (context) => const StatsScreen());
}
