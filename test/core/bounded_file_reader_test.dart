import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/errors/app_exception.dart';
import 'package:notenest/core/utils/bounded_file_reader.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'notenest-bounded-reader-',
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test(
    'reads a native file when every observed length is within the limit',
    () async {
      final File file = File('${directory.path}/note.md');
      await file.writeAsBytes(<int>[1, 2, 3, 4]);

      final bytes = await BoundedFileReader.read(
        file.path,
        validateLength: (int length) {
          if (length > 4) {
            throw const ImportExportException('too large');
          }
        },
      );

      expect(bytes, <int>[1, 2, 3, 4]);
    },
  );

  test(
    'rejects a file whose reported size exceeds the configured limit',
    () async {
      final File file = File('${directory.path}/backup.json');
      await file.writeAsBytes(<int>[1, 2, 3, 4, 5]);

      await expectLater(
        BoundedFileReader.read(
          file.path,
          validateLength: (int length) {
            if (length > 4) {
              throw const ImportExportException('too large');
            }
          },
        ),
        throwsA(isA<ImportExportException>()),
      );
    },
  );

  test('wraps missing-file failures as import/export errors', () async {
    await expectLater(
      BoundedFileReader.read(
        '${directory.path}/missing.md',
        validateLength: (_) {},
      ),
      throwsA(isA<ImportExportException>()),
    );
  });
}
