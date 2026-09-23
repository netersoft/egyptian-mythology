import 'package:egyptian_mythology/view/themes/app_text_scaler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTextScaler', () {
    test('applies the Papyrus compensation at the default system scale', () {
      expect(AppTextScaler(TextScaler.noScaling).scale(10), closeTo(12, 1e-9));
    });

    test('stacks on top of the user system text scale instead of replacing it', () {
      expect(AppTextScaler(const TextScaler.linear(1.3)).scale(10), closeTo(15.6, 1e-9));
    });

    test('caps the system text scale to keep fixed-height widgets from overflowing', () {
      expect(AppTextScaler(const TextScaler.linear(3)).scale(10), closeTo(10 * maxSystemTextScale * papyrusCompensation, 1e-9));
    });

    test('equal system scalers produce equal AppTextScalers', () {
      expect(AppTextScaler(const TextScaler.linear(1.1)), AppTextScaler(const TextScaler.linear(1.1)));
      expect(AppTextScaler(const TextScaler.linear(1.1)), isNot(AppTextScaler(const TextScaler.linear(1.2))));
    });
  });
}
