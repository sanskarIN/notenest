import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

final class AppLockService {
  AppLockService({LocalAuthentication? authentication})
      : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  Future<bool> canAuthenticate() async {
    try {
      return await _authentication.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      if (!await canAuthenticate()) {
        return false;
      }
      return _authentication.authenticate(
        localizedReason: 'Unlock NoteNest to access your notes.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
