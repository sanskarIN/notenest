import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/utils/safe_file_name.dart';

void main() {
  group('SafeFileName', () {
    test('replaces cross-platform invalid filename characters', () {
      expect(
        SafeFileName.fromTitle('Plan: Q3 / ideas?'),
        'Plan- Q3 - ideas-',
      );
    });

    test('protects Windows reserved device names', () {
      expect(SafeFileName.fromTitle('CON'), '_CON');
      expect(SafeFileName.fromTitle('nul.txt'), '_nul.txt');
      expect(SafeFileName.fromTitle('LPT9'), '_LPT9');
    });

    test('removes trailing dots and spaces', () {
      expect(SafeFileName.fromTitle('Release notes...   '), 'Release notes');
    });

    test('uses fallback when normalization leaves no usable name', () {
      expect(SafeFileName.fromTitle('...   '), 'untitled-note');
    });

    test('preserves Unicode and enforces the maximum length', () {
      expect(SafeFileName.fromTitle('नोट्स 2026'), 'नोट्स 2026');
      final String longTitle = List<String>.filled(120, 'a').join();
      expect(
        SafeFileName.fromTitle(longTitle).length,
        SafeFileName.maxLength,
      );
    });
  });
}
