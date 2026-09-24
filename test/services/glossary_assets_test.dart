import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// A glossary term only gets linked where its exact alias appears in the
// docs (possibly wrapped across source lines, as the linker allows), so a
// translated glossary whose aliases don't match the translated text
// ("canopic jars" vs "canopic vases") silently links nothing. Check every
// glossary against the French one and against its own locale's pages.
void main() {
  final glossaries = Directory('assets/glossary').listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
  final ids = _ids(File('assets/glossary/glossary_fr.json'));
  final tag = RegExp('<[^>]+>');

  for (final glossary in glossaries) {
    final locale = RegExp(r'glossary_(\w+)\.json$').firstMatch(glossary.path)!.group(1)!;

    test('the $locale glossary defines the same terms as the French one', () {
      expect(_ids(glossary), ids);
    });

    test('every $locale glossary term appears in the $locale docs', () {
      final text = Directory(
        'assets/docs/$locale',
      ).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.html')).map((f) => f.readAsStringSync().replaceAll(tag, ' ')).join('\n');

      final unused = [
        for (final entry in jsonDecode(glossary.readAsStringSync()) as List<dynamic>)
          if (!(entry['aliases'] as List<dynamic>).any(
            (alias) => RegExp(
              '(?<![\\p{L}\\p{N}_-])${(alias as String).split(' ').map(RegExp.escape).join(r'\s+')}(?![\\p{L}\\p{N}_-])',
              unicode: true,
            ).hasMatch(text),
          ))
            entry['id'],
      ];
      expect(unused, isEmpty);
    });
  }
}

Set<String> _ids(File glossary) => {
  for (final entry in jsonDecode(glossary.readAsStringSync()) as List<dynamic>) entry['id'] as String,
};
