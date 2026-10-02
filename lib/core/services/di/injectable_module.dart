import 'package:injectable/injectable.dart';

import '../../helpers/router/navigation_helper.dart';
import '../audio/audio_service.dart';
import '../documentation/documentation_service.dart';
import '../documentation/reading_progress_repository.dart';
import '../hive/service.dart';
import '../quiz/quiz_service.dart';
import '../review/review_service.dart';
import '../scores/scores_repository.dart';
import '../shared_preferences/service.dart';

@module
abstract class AppModule {
  @singleton
  NavigationHelper get navigationHelper => NavigationHelper();

  @singleton
  @preResolve
  Future<SharedPreferencesService> get prefs async => (await SharedPreferencesService.getInstance())!;

  @singleton
  @preResolve
  Future<HiveService> get hive async => (await HiveService.getInstance())!;

  @singleton
  QuizService get quizService => QuizService();

  @singleton
  DocumentationService get documentationService => DocumentationService();

  @singleton
  ReadingProgressRepository get readingProgressRepository => ReadingProgressRepository();

  @singleton
  ScoresRepository get scoresRepository => ScoresRepository();

  @singleton
  AudioService get audioService => AudioService();

  @singleton
  ReviewService get reviewService => ReviewService();
}
