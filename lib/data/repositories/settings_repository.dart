import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SettingsRepository {
  static const String _themeKey = 'appearance.theme';
  static const String _fontScaleKey = 'accessibility.fontScale';
  static const String _reduceMotionKey = 'accessibility.reduceMotion';
  static const String _onboardingKey = 'onboarding.complete';
  static const String _appLockKey = 'privacy.appLock';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<ThemeMode> getThemeMode() async {
    final String value = (await _prefs).getString(_themeKey) ?? 'system';
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode value) async {
    final String encoded = switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await (await _prefs).setString(_themeKey, encoded);
  }

  Future<double> getFontScale() async =>
      (await _prefs).getDouble(_fontScaleKey) ?? 1;

  Future<void> setFontScale(double value) async {
    await (await _prefs).setDouble(_fontScaleKey, value.clamp(0.9, 1.4));
  }

  Future<bool> getReduceMotion() async =>
      (await _prefs).getBool(_reduceMotionKey) ?? false;

  Future<void> setReduceMotion({required bool value}) async {
    await (await _prefs).setBool(_reduceMotionKey, value);
  }

  Future<bool> getOnboardingComplete() async =>
      (await _prefs).getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingComplete({required bool value}) async {
    await (await _prefs).setBool(_onboardingKey, value);
  }

  Future<bool> getAppLockEnabled() async =>
      (await _prefs).getBool(_appLockKey) ?? false;

  Future<void> setAppLockEnabled({required bool value}) async {
    await (await _prefs).setBool(_appLockKey, value);
  }
}
