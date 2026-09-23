import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The docs reference their pictures by relative path (../../res/...), which
// nothing resolves at build time: a renamed or deleted image only shows up
// as a blank figure at runtime. Check every reference against the disk.
void main() {
  final pages = Directory('assets/docs').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.html'));
  final src = RegExp(r'src="\.\./\.\./(res/[^"]+)"');

  for (final page in pages) {
    test('every image in ${page.path} exists', () {
      final missing = [
        for (final match in src.allMatches(page.readAsStringSync()))
          if (!File('assets/docs/${match.group(1)}').existsSync()) match.group(1),
      ];
      expect(missing, isEmpty);
    });
  }
}
