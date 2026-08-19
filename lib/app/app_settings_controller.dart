import 'package:flutter/material.dart';
import 'package:notenest/data/repositories/settings_repository.dart';

final class AppSettingsController extends ChangeNotifier {
  AppSettingsController(this._repository);

  final SettingsRepository _repository;

  ThemeMode themeMode = ThemeMode.system;
  double fontScale = 1;
  bool reduceMotion = false;
  bool onboardingComplete = false;
  bool appLockEnabled = false;
  bool initialized = false;

  Future<void> load() async {
    themeMode = await _repository.getThemeMode();
    fontScale = await _repository.getFontScale();
    reduceMotion = await _repository.getReduceMotion();
    onboardingComplete = await _repository.getOnboardingComplete();
    appLockEnabled = await _repository.getAppLockEnabled();
    initialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (themeMode == value) return;
    themeMode = value;
    notifyListeners();
    await _repository.setThemeMode(value);
  }

  Future<void> setFontScale(double value) async {
    final double normalized = value.clamp(0.9, 1.4).toDouble();
    if (fontScale == normalized) return;
    fontScale = normalized;
    notifyListeners();
    await _repository.setFontScale(normalized);
  }

  Future<void> setReduceMotion({required bool value}) async {
    if (reduceMotion == value) return;
    reduceMotion = value;
    notifyListeners();
    await _repository.setReduceMotion(value: value);
  }

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    notifyListeners();
    await _repository.setOnboardingComplete(value: true);
  }

  Future<void> setAppLockEnabled({required bool value}) async {
    if (appLockEnabled == value) return;
    appLockEnabled = value;
    notifyListeners();
    await _repository.setAppLockEnabled(value: value);
  }
}
