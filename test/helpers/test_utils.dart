import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_starter/core/helpers/router/navigation_helper.dart';
import 'package:flutter_starter/core/services/audio/audio_service.dart';
import 'package:flutter_starter/core/services/di/locator.dart';
import 'package:flutter_starter/core/services/documentation/documentation_service.dart';
import 'package:flutter_starter/core/services/hive/service.dart';
import 'package:flutter_starter/core/services/shared_preferences/service.dart';
import 'package:mocktail/mocktail.dart';

class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}

class MockNavigationHelper extends Mock implements NavigationHelper {}

class MockAudioService extends Mock implements AudioService {}

Future<void> setupTestLocator({
  SharedPreferencesService? sharedPreferencesService,
  NavigationHelper? navigationHelper,
  HiveService? hiveService,
  AudioService? audioService,
  DocumentationService? documentationService,
}) async {
  await dotenv.load();

  if (!locator.isRegistered<SharedPreferencesService>()) {
    locator.registerSingleton<SharedPreferencesService>(
      sharedPreferencesService ?? MockSharedPreferencesService(),
    );
  }

  if (!locator.isRegistered<NavigationHelper>()) {
    locator.registerSingleton<NavigationHelper>(
      navigationHelper ?? MockNavigationHelper(),
    );
  }

  if (hiveService != null && !locator.isRegistered<HiveService>()) {
    locator.registerSingleton<HiveService>(hiveService);
  }

  if (!locator.isRegistered<AudioService>()) {
    final audio = audioService ?? MockAudioService();
    if (audio is MockAudioService) {
      when(audio.startMusic).thenAnswer((_) async {});
      when(audio.playClick).thenAnswer((_) async {});
    }
    locator.registerSingleton<AudioService>(audio);
  }

  if (!locator.isRegistered<DocumentationService>()) {
    locator.registerSingleton<DocumentationService>(documentationService ?? DocumentationService());
  }
}

void teardownTestLocator() {
  if (locator.isRegistered<SharedPreferencesService>()) {
    locator.unregister<SharedPreferencesService>();
  }
  if (locator.isRegistered<NavigationHelper>()) {
    locator.unregister<NavigationHelper>();
  }
  if (locator.isRegistered<HiveService>()) {
    locator.unregister<HiveService>();
  }
  if (locator.isRegistered<AudioService>()) {
    locator.unregister<AudioService>();
  }
  if (locator.isRegistered<DocumentationService>()) {
    locator.unregister<DocumentationService>();
  }
}
