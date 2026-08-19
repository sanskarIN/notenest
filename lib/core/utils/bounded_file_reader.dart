import 'dart:io';
import 'dart:typed_data';

import 'package:notenest/core/errors/app_exception.dart';

abstract final class BoundedFileReader {
  static Future<Uint8List> read(
    String path, {
    required void Function(int byteLength) validateLength,
  }) async {
    if (path.trim().isEmpty) {
      throw const ImportExportException('Could not read the selected file.');
    }

    final File file = File(path);
    try {
      validateLength(await file.length());

      final BytesBuilder builder = BytesBuilder(copy: false);
      int total = 0;
      await for (final List<int> chunk in file.openRead()) {
        total += chunk.length;
        validateLength(total);
        builder.add(chunk);
      }
      return builder.takeBytes();
    } on ImportExportException {
      rethrow;
    } on FileSystemException catch (error) {
      throw ImportExportException('Could not read the selected file.', error);
    }
  }
}
