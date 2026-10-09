import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every app language has a privacy policy', () {
    final locales = Directory('assets/i18n').listSync().map((f) => f.uri.pathSegments.last.split('.').first).toList();

    expect(locales, isNotEmpty);
    for (final locale in locales) {
      final policy = File('assets/docs/$locale/privacy_policy.html');
      expect(policy.existsSync(), isTrue, reason: locale);
      expect(policy.readAsStringSync(), contains('<h1>'), reason: locale);
    }
  });

  // flutter_svg ignores <style> blocks: shapes styled by a class lose their colors
  // (Heka, Montu, Satet & Anuket showed nothing). Colors must be presentation
  // attributes (fill="…") or a style="" attribute.
  test('no SVG relies on CSS', () {
    final svgs = Directory('assets').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.svg')).toList();

    expect(svgs, isNotEmpty);
    for (final svg in svgs) {
      final content = svg.readAsStringSync();
      expect(content, isNot(contains('<style')), reason: svg.path);
      expect(content, isNot(contains(' class="')), reason: svg.path);
    }
  });
}
