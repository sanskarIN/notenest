import 'package:flutter/material.dart';
import 'package:notenest/core/errors/app_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsStore {
  Future<ThemeMode> getThemeMode();

  Future<void> setThemeMode(ThemeMode value);

  Future<double> getFontScale();

  Future<void> setFontScale(double value);

  Future<bool> getReduceMotion();

  Future<void> setReduceMotion({required bool value});

  Future<bool> getOnboardingComplete();

  Future<void> setOnboardingComplete({required bool value});

  Future<bool> getAppLockEnabled();

  Future<void> setAppLockEnabled({required bool value});
}

final class SettingsRepository implements SettingsStore {
  static const String _themeKey = 'appearance.theme';
  static const String _fontScaleKey = 'accessibility.fontScale';
  static const String _reduceMotionKey = 'accessibility.reduceMotion';
  static const String _onboardingKey = 'onboarding.complete';
  static const String _appLockKey = 'privacy.appLock';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<ThemeMode> getThemeMode() async {
    final String value = (await _prefs).getString(_themeKey) ?? 'system';
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> setThemeMode(ThemeMode value) async {
    final String encoded = switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    final bool saved = await (await _prefs).setString(_themeKey, encoded);
    _requireSaved(saved, 'theme');
  }

  @override
  Future<double> getFontScale() async =>
      (await _prefs).getDouble(_fontScaleKey) ?? 1;

  @override
  Future<void> setFontScale(double value) async {
    final double normalized = value.clamp(0.9, 1.4).toDouble();
    final bool saved = await (await _prefs).setDouble(_fontScaleKey, normalized);
    _requireSaved(saved, 'text-size');
  }

  @override
  Future<bool> getReduceMotion() async =>
      (await _prefs).getBool(_reduceMotionKey) ?? false;

  @override
  Future<void> setReduceMotion({required bool value}) async {
    final bool saved = await (await _prefs).setBool(_reduceMotionKey, value);
    _requireSaved(saved, 'reduced-motion');
  }

  @override
  Future<bool> getOnboardingComplete() async =>
      (await _prefs).getBool(_onboardingKey) ?? false;

  @override
  Future<void> setOnboardingComplete({required bool value}) async {
    final bool saved = await (await _prefs).setBool(_onboardingKey, value);
    _requireSaved(saved, 'onboarding');
  }

  @override
  Future<bool> getAppLockEnabled() async =>
      (await _prefs).getBool(_appLockKey) ?? false;

  @override
  Future<void> setAppLockEnabled({required bool value}) async {
    final bool saved = await (await _prefs).setBool(_appLockKey, value);
    _requireSaved(saved, 'app-lock');
  }

  void _requireSaved(bool saved, String setting) {
    if (!saved) {
      throw StorageException('Could not persist the $setting setting.');
    }
  }
}
