import 'package:egyptian_mythology/core/helpers/router/navigation_helper.dart';
import 'package:egyptian_mythology/core/services/audio/audio_service.dart';
import 'package:egyptian_mythology/core/services/di/locator.dart';
import 'package:egyptian_mythology/core/services/documentation/documentation_service.dart';
import 'package:egyptian_mythology/core/services/hive/service.dart';
import 'package:egyptian_mythology/core/services/quiz/quiz_service.dart';
import 'package:egyptian_mythology/core/services/scores/scores_repository.dart';
import 'package:egyptian_mythology/core/services/shared_preferences/service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mocktail/mocktail.dart';

class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}

class MockNavigationHelper extends Mock implements NavigationHelper {}

class MockAudioService extends Mock implements AudioService {}

class MockQuizService extends Mock implements QuizService {}

class MockScoresRepository extends Mock implements ScoresRepository {}

Future<void> setupTestLocator({
  SharedPreferencesService? sharedPreferencesService,
  NavigationHelper? navigationHelper,
  HiveService? hiveService,
  AudioService? audioService,
  DocumentationService? documentationService,
  QuizService? quizService,
  ScoresRepository? scoresRepository,
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

  if (!locator.isRegistered<QuizService>()) {
    locator.registerSingleton<QuizService>(quizService ?? QuizService());
  }

  if (!locator.isRegistered<ScoresRepository>()) {
    locator.registerSingleton<ScoresRepository>(scoresRepository ?? ScoresRepository());
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
  if (locator.isRegistered<QuizService>()) {
    locator.unregister<QuizService>();
  }
  if (locator.isRegistered<ScoresRepository>()) {
    locator.unregister<ScoresRepository>();
  }
}
