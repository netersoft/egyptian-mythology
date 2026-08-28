import 'dart:io';

import 'package:egyptian_mythology/core/services/hive/hive_registrar.g.dart';
import 'package:egyptian_mythology/core/services/hive/keys.dart';
import 'package:egyptian_mythology/core/services/hive/service.dart';
import 'package:egyptian_mythology/core/services/scores/scores_repository.dart';
import 'package:egyptian_mythology/core/services/shared_preferences/keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_utils.dart';

void main() {
  late Directory tempDir;
  late MockSharedPreferencesService mockPrefs;
  late ScoresRepository repository;
  int? bestScore;

  setUpAll(Hive.registerAdapters);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scores_repository_test');
    Hive.init(tempDir.path);

    final hiveService = HiveService()..scoresBox = await Hive.openBox(HiveKeys.scores);

    mockPrefs = MockSharedPreferencesService();
    bestScore = 0;
    when(() => mockPrefs.getInt(PrefKeys.bestScore, defaultValue: any(named: 'defaultValue'))).thenAnswer((_) => bestScore);
    when(() => mockPrefs.setInt(PrefKeys.bestScore, any())).thenAnswer((invocation) async {
      bestScore = invocation.positionalArguments[1] as int;
      return true;
    });

    await setupTestLocator(sharedPreferencesService: mockPrefs, hiveService: hiveService);

    repository = ScoresRepository();
  });

  tearDown(() async {
    teardownTestLocator();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('ScoresRepository', () {
    test('getAll returns an empty list when no scores were recorded', () {
      expect(repository.getAll(), isEmpty);
    });

    test('add appends a score entry with a formatted date', () async {
      await repository.add(120);

      final all = repository.getAll();
      expect(all, hasLength(1));
      expect(all.single.score, 120);
      expect(all.single.date, isNotEmpty);
    });

    test('add accumulates multiple entries in insertion order', () async {
      await repository.add(100);
      await repository.add(250);

      final all = repository.getAll();
      expect(all.map((e) => e.score).toList(), [100, 250]);
    });

    test('add updates the best score only when the new score is higher', () async {
      await repository.add(100);
      expect(repository.getBestScore(), 100);

      await repository.add(50);
      expect(repository.getBestScore(), 100);

      await repository.add(300);
      expect(repository.getBestScore(), 300);
    });

    test('clear wipes both the score history and the best score', () async {
      await repository.add(100);
      await repository.add(300);

      await repository.clear();

      expect(repository.getAll(), isEmpty);
      expect(repository.getBestScore(), 0);
    });
  });
}
