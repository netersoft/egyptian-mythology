import 'package:egyptian_mythology/core/models/doc_category.dart';
import 'package:egyptian_mythology/core/services/documentation/reading_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_utils.dart';

void main() {
  late MockSharedPreferencesService prefs;
  late Map<String, Object> store;
  late ReadingProgressRepository repository;

  setUp(() async {
    prefs = MockSharedPreferencesService();
    store = {};
    when(() => prefs.getString(any())).thenAnswer((i) => store[i.positionalArguments[0]] as String?);
    when(() => prefs.getDouble(any())).thenAnswer((i) => store[i.positionalArguments[0]] as double?);
    when(() => prefs.setString(any(), any())).thenAnswer((i) async {
      store[i.positionalArguments[0] as String] = i.positionalArguments[1] as String;
      return true;
    });
    when(() => prefs.setDouble(any(), any())).thenAnswer((i) async {
      store[i.positionalArguments[0] as String] = i.positionalArguments[1] as double;
      return true;
    });

    await setupTestLocator(sharedPreferencesService: prefs);
    repository = ReadingProgressRepository();
  });

  tearDown(teardownTestLocator);

  group('ReadingProgressRepository', () {
    test('has nothing to resume before anything was read', () {
      expect(repository.lastItemId(DocCategory.gods), isNull);
      expect(repository.lastOffset(DocCategory.gods), 0);
    });

    test('remembers the last page and scroll offset per category', () async {
      await repository.save(DocCategory.gods, 'anubis', 420);
      await repository.save(DocCategory.myths, 'myth_mort', 80);

      expect(repository.lastItemId(DocCategory.gods), 'anubis');
      expect(repository.lastOffset(DocCategory.gods), 420);
      expect(repository.lastItemId(DocCategory.myths), 'myth_mort');
      expect(repository.lastOffset(DocCategory.myths), 80);
      expect(repository.lastItemId(DocCategory.cosmogonies), isNull);
    });
  });
}
