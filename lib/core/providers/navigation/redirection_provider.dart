import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../helpers/router/navigation_helper.dart';
import '../../routes/app_route.dart';
import '../../services/di/locator.dart';

part 'redirection_provider.g.dart';

final _navigationHelper = locator<NavigationHelper>();

@riverpod
class Redirection extends _$Redirection {
  @override
  int build() => 0;

  Future redirect(WidgetRef ref) async {
    _navigationHelper.pushReplacement(const MainRoute().location);
  }
}
