import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/errors/app_exception.dart';
import 'package:notenest/core/utils/bounded_file_reader.dart';
import 'package:notenest/services/app_lock_service.dart';

void main() {
  test('web fallbacks remain safe when native facilities are unavailable', () async {
    if (!kIsWeb) return;

    final AppLockService appLock = AppLockService();
    expect(await appLock.canAuthenticate(), isFalse);
    expect(await appLock.authenticate(), isFalse);

    await expectLater(
      BoundedFileReader.read(
        '/native-paths-are-unavailable-on-web',
        validateLength: (_) {},
      ),
      throwsA(isA<ImportExportException>()),
    );
  });
}
