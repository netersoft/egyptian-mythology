import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../view/screens/main_screen.dart';

part 'main_provider.g.dart';

@riverpod
class Main extends _$Main {
  @override
  MainState build() => const MainState();

  Widget selectAppBar() => MainScreen.defaultAppBar(state);
}

class MainState {
  const MainState();
}
