import 'dart:typed_data';

import 'package:notenest/core/errors/app_exception.dart';

Future<Uint8List> readBoundedFile(
  String path, {
  required void Function(int byteLength) validateLength,
}) async {
  throw const ImportExportException(
    'Filesystem path reading is unavailable on this platform.',
  );
}
