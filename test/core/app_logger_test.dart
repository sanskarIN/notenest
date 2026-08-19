import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/logging/app_logger.dart';

void main() {
  const AppLogger logger = AppLogger();

  test('redacts fields whose keys can contain private note data', () {
    final Map<String, Object?> sanitized = logger.sanitizeFields(
      <String, Object?>{
        'noteTitle': 'Private title',
        'body': 'Private body',
        'token': 'secret-token-value',
        'count': 3,
        'operation': 'restore',
      },
    );

    expect(sanitized['noteTitle'], '[redacted]');
    expect(sanitized['body'], '[redacted]');
    expect(sanitized['token'], '[redacted]');
    expect(sanitized['count'], 3);
    expect(sanitized['operation'], 'restore');
  });

  test('does not serialize arbitrary objects into logs', () {
    final Map<String, Object?> sanitized = logger.sanitizeFields(
      <String, Object?>{'value': Object()},
    );

    expect(sanitized['value'], 'Object');
  });

  test('truncates long non-sensitive strings', () {
    final String longValue = List<String>.filled(200, 'a').join();
    final Map<String, Object?> sanitized = logger.sanitizeFields(
      <String, Object?>{'operation': longValue},
    );

    expect(sanitized['operation'], isA<String>());
    expect((sanitized['operation']! as String).length, 121);
  });
}
