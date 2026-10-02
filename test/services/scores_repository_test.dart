import 'dart:io';

import 'package:egyptian_mythology/core/models/quiz_theme.dart';
import 'package:egyptian_mythology/core/models/score_entry_model.dart';
import 'package:egyptian_mythology/core/services/di/locator.dart';
import 'package:egyptian_mythology/core/services/hive/hive_adapters.dart';
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
  late Map<String, int> prefs;

  setUpAll(Hive.registerAdapters);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scores_repository_test');
    Hive.init(tempDir.path);

    final hiveService = HiveService()..scoresBox = await Hive.openBox(HiveKeys.scores);

    mockPrefs = MockSharedPreferencesService();
    prefs = {};
    when(() => mockPrefs.getInt(any(), defaultValue: any(named: 'defaultValue'))).thenAnswer((invocation) => prefs[invocation.positionalArguments[0]]);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((invocation) async {
      prefs[invocation.positionalArguments[0] as String] = invocation.positionalArguments[1] as int;
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

    test('add appends a score entry timestamped with the current time', () async {
      final before = DateTime.now();
      await repository.add(120);

      final all = repository.getAll();
      expect(all, hasLength(1));
      expect(all.single.score, 120);
      expect(all.single.playedAt, isNotNull);
      expect(all.single.playedAt!.isBefore(before.subtract(const Duration(seconds: 1))), isFalse);
    });

    test('getAll backfills playedAt from the legacy date string of entries saved up to 2.0.3', () async {
      await locator<HiveService>().scoresBox!.put(HiveKeys.scoresList, [
        const ScoreEntryModel(score: 80, date: 'Mon 01.01.2024 - 10:05'),
        const ScoreEntryModel(score: 90, date: 'garbled'),
      ]);

      final [parsed, unparseable] = repository.getAll();
      expect(parsed.playedAt, DateTime(2024, 1, 1, 10, 5));
      expect(unparseable.playedAt, isNull);
      expect(unparseable.date, 'garbled');
    });

    test('entries written to disk by the pre-2.0.4 adapter (no playedAt field) still load', () async {
      final box = locator<HiveService>().scoresBox!;
      await box.close();

      Hive.registerAdapter(_LegacyScoreEntryAdapter(), override: true);
      final legacyBox = await Hive.openBox(HiveKeys.scores);
      await legacyBox.put(HiveKeys.scoresList, [const ScoreEntryModel(score: 150, date: 'Tue 02.01.2024 - 11:00')]);
      await legacyBox.close();

      Hive.registerAdapter(ScoreEntryModelAdapter(), override: true);
      locator<HiveService>().scoresBox = await Hive.openBox(HiveKeys.scores);

      final entry = repository.getAll().single;
      expect(entry.score, 150);
      expect(entry.playedAt, DateTime(2024, 1, 2, 11));
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

    test('clear wipes the score history and the best score of every theme', () async {
      await repository.add(100);
      await repository.add(300);
      await repository.add(80, QuizTheme.gods);

      await repository.clear();

      expect(repository.getAll(), isEmpty);
      expect(repository.getAll(QuizTheme.gods), isEmpty);
      expect(repository.getBestScore(), 0);
      expect(repository.getBestScore(QuizTheme.gods), 0);
    });

    test('keeps a separate history and record per theme', () async {
      await repository.add(100);
      await repository.add(40, QuizTheme.gods);
      await repository.add(60, QuizTheme.gods);
      await repository.add(500, QuizTheme.myths);

      expect(repository.getAll().map((e) => e.score), [100]);
      expect(repository.getAll(QuizTheme.gods).map((e) => e.score), [40, 60]);
      expect(repository.getAll(QuizTheme.cosmogonies), isEmpty);
      expect(repository.getBestScore(), 100);
      expect(repository.getBestScore(QuizTheme.gods), 60);
      expect(repository.getBestScore(QuizTheme.myths), 500);
    });

    test('keeps the pre-themes record as the full game record', () async {
      prefs[PrefKeys.bestScore] = 420;

      expect(repository.getBestScore(), 420);
      expect(repository.getBestScore(QuizTheme.gods), 0);
    });
  });
}

// Byte-for-byte copy of the ScoreEntryModelAdapter generated before playedAt
// was added (2 fields: date at index 0, score at index 1).
class _LegacyScoreEntryAdapter extends TypeAdapter<ScoreEntryModel> {
  @override
  final typeId = 138;

  @override
  ScoreEntryModel read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, ScoreEntryModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.score);
  }
}
