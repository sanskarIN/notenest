import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:notenest/core/constants/app_strings.dart';

final class AppLockService {
  AppLockService({LocalAuthentication? authentication})
      : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  Future<bool> canAuthenticate() async {
    try {
      return await _authentication.isDeviceSupported();
    } on LocalAuthException {
      return false;
    } on MissingPluginException {
      return false;
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
        localizedReason: AppStrings.unlockReason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
