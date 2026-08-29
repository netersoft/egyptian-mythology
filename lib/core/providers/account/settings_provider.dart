import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../helpers/router/navigation_helper.dart';
import '../../routes/app_route.dart';
import '../../services/di/locator.dart';
import '../../services/i18n/translations.g.dart';
import '../../services/shared_preferences/keys.dart';
import '../../services/shared_preferences/service.dart';

part 'settings_provider.g.dart';

final _navigationHelper = locator<NavigationHelper>();

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  @override
  SettingsState build() => const SettingsState();

  final SharedPreferencesService prefs = locator<SharedPreferencesService>();

  void toggleEnableNotificationsState(bool newState) {
    prefs.setBool(PrefKeys.enableNotifications, newState);
  }

  bool? getEnableNotificationsState() => prefs.getBool(PrefKeys.enableNotifications, defaultValue: true);

  Future<void> changeLanguage(String newValue) async {
    final navigator = _navigationHelper.navigatorKey.currentState;
    await LocaleSettings.setLocaleRaw(newValue);
    await prefs.setString(PrefKeys.locale, newValue);

    try {
      _navigationHelper.go(const SettingsRoute().location);
      if (navigator != null && navigator.mounted) {
        Phoenix.rebirth(navigator.context);
      }
    } catch (e) {
      _navigationHelper.pushReplacement(const RedirectionRoute().location);
    }
  }
}

class SettingsState {
  final bool isLoading;

  const SettingsState({this.isLoading = false});

  SettingsState copyWith({bool? isLoading}) => SettingsState(isLoading: isLoading ?? this.isLoading);
}
