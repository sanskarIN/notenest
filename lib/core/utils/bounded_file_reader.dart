import 'dart:typed_data';

import 'package:notenest/core/utils/bounded_file_reader_stub.dart'
    if (dart.library.io) 'package:notenest/core/utils/bounded_file_reader_io.dart'
    as implementation;

abstract final class BoundedFileReader {
  static Future<Uint8List> read(
    String path, {
    required void Function(int byteLength) validateLength,
  }) {
    return implementation.readBoundedFile(
      path,
      validateLength: validateLength,
    );
  }
}
