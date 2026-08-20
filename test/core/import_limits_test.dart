import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/errors/app_exception.dart';
import 'package:notenest/core/utils/import_limits.dart';

void main() {
  group('ImportLimits', () {
    test('accepts files at the configured limits', () {
      expect(
        () => ImportLimits.validateMarkdownBytes(ImportLimits.maxMarkdownBytes),
        returnsNormally,
      );
      expect(
        () => ImportLimits.validateBackupBytes(ImportLimits.maxBackupBytes),
        returnsNormally,
      );
    });

    test('rejects an oversized Markdown import', () {
      expect(
        () => ImportLimits.validateMarkdownBytes(
          ImportLimits.maxMarkdownBytes + 1,
        ),
        throwsA(isA<ImportExportException>()),
      );
    });

    test('rejects an oversized backup import', () {
      expect(
        () => ImportLimits.validateBackupBytes(ImportLimits.maxBackupBytes + 1),
        throwsA(isA<ImportExportException>()),
      );
    });

    test('rejects impossible negative byte lengths', () {
      expect(() => ImportLimits.validateMarkdownBytes(-1), throwsArgumentError);
    });
  });
}
