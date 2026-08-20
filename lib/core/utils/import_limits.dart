import 'package:notenest/core/errors/app_exception.dart';

abstract final class ImportLimits {
  static const int maxMarkdownBytes = 16 * 1024 * 1024;
  static const int maxBackupBytes = 64 * 1024 * 1024;

  static void validateMarkdownBytes(int byteLength) {
    _validate(
      byteLength: byteLength,
      maxBytes: maxMarkdownBytes,
      label: 'note',
    );
  }

  static void validateBackupBytes(int byteLength) {
    _validate(
      byteLength: byteLength,
      maxBytes: maxBackupBytes,
      label: 'backup',
    );
  }

  static void _validate({
    required int byteLength,
    required int maxBytes,
    required String label,
  }) {
    if (byteLength < 0) {
      throw ArgumentError.value(
        byteLength,
        'byteLength',
        'must not be negative',
      );
    }
    if (byteLength > maxBytes) {
      final int maxMiB = maxBytes ~/ (1024 * 1024);
      throw ImportExportException(
        'The selected $label is larger than the supported $maxMiB MiB import limit.',
      );
    }
  }
}
