import 'package:flutter/material.dart';
import 'package:notenest/core/utils/async_serial_queue.dart';
import 'package:notenest/data/repositories/settings_repository.dart';

final class AppSettingsController extends ChangeNotifier {
  AppSettingsController(this._repository);

  final SettingsStore _repository;
  final AsyncSerialQueue _writes = AsyncSerialQueue();

  ThemeMode themeMode = ThemeMode.system;
  double fontScale = 1;
  bool reduceMotion = false;
  bool onboardingComplete = false;
  bool appLockEnabled = false;
  bool initialized = false;

  ThemeMode _persistedThemeMode = ThemeMode.system;
  double _persistedFontScale = 1;
  bool _persistedReduceMotion = false;
  bool _persistedAppLockEnabled = false;
  bool _disposed = false;

  Future<void> load() async {
    final ThemeMode nextThemeMode = await _repository.getThemeMode();
    final double nextFontScale = await _repository.getFontScale();
    final bool nextReduceMotion = await _repository.getReduceMotion();
    final bool nextOnboardingComplete = await _repository.getOnboardingComplete();
    final bool nextAppLockEnabled = await _repository.getAppLockEnabled();
    if (_disposed) return;

    themeMode = nextThemeMode;
    fontScale = nextFontScale;
    reduceMotion = nextReduceMotion;
    onboardingComplete = nextOnboardingComplete;
    appLockEnabled = nextAppLockEnabled;

    _persistedThemeMode = nextThemeMode;
    _persistedFontScale = nextFontScale;
    _persistedReduceMotion = nextReduceMotion;
    _persistedAppLockEnabled = nextAppLockEnabled;

    initialized = true;
    _notify();
  }

  Future<void> setThemeMode(ThemeMode value) {
    if (themeMode == value) return Future<void>.value();
    themeMode = value;
    _notify();
    return _writes.add(() async {
      try {
        await _repository.setThemeMode(value);
        _persistedThemeMode = value;
      } on Object {
        if (themeMode == value) {
          themeMode = _persistedThemeMode;
          _notify();
        }
        rethrow;
      }
    });
  }

  Future<void> setFontScale(double value) {
    final double normalized = value.clamp(0.9, 1.4).toDouble();
    if (fontScale == normalized) return Future<void>.value();
    fontScale = normalized;
    _notify();
    return _writes.add(() async {
      try {
        await _repository.setFontScale(normalized);
        _persistedFontScale = normalized;
      } on Object {
        if (fontScale == normalized) {
          fontScale = _persistedFontScale;
          _notify();
        }
        rethrow;
      }
    });
  }

  Future<void> setReduceMotion({required bool value}) {
    if (reduceMotion == value) return Future<void>.value();
    reduceMotion = value;
    _notify();
    return _writes.add(() async {
      try {
        await _repository.setReduceMotion(value: value);
        _persistedReduceMotion = value;
      } on Object {
        if (reduceMotion == value) {
          reduceMotion = _persistedReduceMotion;
          _notify();
        }
        rethrow;
      }
    });
  }

  Future<void> completeOnboarding() {
    if (onboardingComplete) return Future<void>.value();
    return _writes.add(() async {
      await _repository.setOnboardingComplete(value: true);
      if (_disposed) return;
      onboardingComplete = true;
      _notify();
    });
  }

  Future<void> setAppLockEnabled({required bool value}) {
    if (appLockEnabled == value) return Future<void>.value();
    appLockEnabled = value;
    _notify();
    return _writes.add(() async {
      try {
        await _repository.setAppLockEnabled(value: value);
        _persistedAppLockEnabled = value;
      } on Object {
        if (appLockEnabled == value) {
          appLockEnabled = _persistedAppLockEnabled;
          _notify();
        }
        rethrow;
      }
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
