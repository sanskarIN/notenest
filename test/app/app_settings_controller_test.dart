import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/app/app_settings_controller.dart';
import 'package:notenest/data/repositories/settings_repository.dart';

void main() {
  test('loads settings atomically into current and persisted state', () async {
    final _FakeSettingsStore store = _FakeSettingsStore(
      themeMode: ThemeMode.dark,
      fontScale: 1.2,
      reduceMotion: true,
      onboardingComplete: true,
      appLockEnabled: true,
    );
    final AppSettingsController controller = AppSettingsController(store);

    await controller.load();

    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.fontScale, 1.2);
    expect(controller.reduceMotion, isTrue);
    expect(controller.onboardingComplete, isTrue);
    expect(controller.appLockEnabled, isTrue);
    expect(controller.initialized, isTrue);

    controller.dispose();
  });

  test('rolls a failed theme write back to the last persisted value', () async {
    final _FakeSettingsStore store = _FakeSettingsStore()..failThemeWrites = true;
    final AppSettingsController controller = AppSettingsController(store);
    await controller.load();

    await expectLater(
      controller.setThemeMode(ThemeMode.dark),
      throwsStateError,
    );

    expect(controller.themeMode, ThemeMode.system);
    expect(store.themeMode, ThemeMode.system);

    controller.dispose();
  });

  test('serializes rapid theme writes so the newest value persists last', () async {
    final _FakeSettingsStore store = _FakeSettingsStore();
    final AppSettingsController controller = AppSettingsController(store);
    await controller.load();

    final Completer<void> firstStarted = Completer<void>();
    final Completer<void> releaseFirst = Completer<void>();
    store.firstThemeWriteStarted = firstStarted;
    store.releaseFirstThemeWrite = releaseFirst;

    final Future<void> dark = controller.setThemeMode(ThemeMode.dark);
    final Future<void> light = controller.setThemeMode(ThemeMode.light);

    await firstStarted.future;
    expect(store.themeWrites, <ThemeMode>[ThemeMode.dark]);
    expect(controller.themeMode, ThemeMode.light);

    releaseFirst.complete();
    await Future.wait<void>(<Future<void>>[dark, light]);

    expect(
      store.themeWrites,
      <ThemeMode>[ThemeMode.dark, ThemeMode.light],
    );
    expect(store.themeMode, ThemeMode.light);
    expect(controller.themeMode, ThemeMode.light);

    controller.dispose();
  });

  test('rolls app-lock state back when preference persistence fails', () async {
    final _FakeSettingsStore store = _FakeSettingsStore()
      ..failAppLockWrites = true;
    final AppSettingsController controller = AppSettingsController(store);
    await controller.load();

    await expectLater(
      controller.setAppLockEnabled(value: true),
      throwsStateError,
    );

    expect(controller.appLockEnabled, isFalse);
    expect(store.appLockEnabled, isFalse);

    controller.dispose();
  });
}

final class _FakeSettingsStore implements SettingsStore {
  _FakeSettingsStore({
    this.themeMode = ThemeMode.system,
    this.fontScale = 1,
    this.reduceMotion = false,
    this.onboardingComplete = false,
    this.appLockEnabled = false,
  });

  ThemeMode themeMode;
  double fontScale;
  bool reduceMotion;
  bool onboardingComplete;
  bool appLockEnabled;

  bool failThemeWrites = false;
  bool failAppLockWrites = false;
  Completer<void>? firstThemeWriteStarted;
  Completer<void>? releaseFirstThemeWrite;
  final List<ThemeMode> themeWrites = <ThemeMode>[];

  @override
  Future<ThemeMode> getThemeMode() async => themeMode;

  @override
  Future<double> getFontScale() async => fontScale;

  @override
  Future<bool> getReduceMotion() async => reduceMotion;

  @override
  Future<bool> getOnboardingComplete() async => onboardingComplete;

  @override
  Future<bool> getAppLockEnabled() async => appLockEnabled;

  @override
  Future<void> setThemeMode(ThemeMode value) async {
    themeWrites.add(value);
    if (themeWrites.length == 1 && releaseFirstThemeWrite != null) {
      firstThemeWriteStarted?.complete();
      await releaseFirstThemeWrite!.future;
    }
    if (failThemeWrites) throw StateError('theme write failed');
    themeMode = value;
  }

  @override
  Future<void> setFontScale(double value) async {
    fontScale = value;
  }

  @override
  Future<void> setReduceMotion({required bool value}) async {
    reduceMotion = value;
  }

  @override
  Future<void> setOnboardingComplete({required bool value}) async {
    onboardingComplete = value;
  }

  @override
  Future<void> setAppLockEnabled({required bool value}) async {
    if (failAppLockWrites) throw StateError('app-lock write failed');
    appLockEnabled = value;
  }
}
