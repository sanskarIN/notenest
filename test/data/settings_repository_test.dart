import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/data/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('uses safe default settings', () async {
    final SettingsRepository repository = SettingsRepository();

    expect(await repository.getThemeMode(), ThemeMode.system);
    expect(await repository.getFontScale(), 1);
    expect(await repository.getReduceMotion(), isFalse);
    expect(await repository.getOnboardingComplete(), isFalse);
    expect(await repository.getAppLockEnabled(), isFalse);
  });

  test('persists appearance and privacy choices', () async {
    final SettingsRepository repository = SettingsRepository();

    await repository.setThemeMode(ThemeMode.dark);
    await repository.setFontScale(1.2);
    await repository.setReduceMotion(value: true);
    await repository.setOnboardingComplete(value: true);
    await repository.setAppLockEnabled(value: true);

    expect(await repository.getThemeMode(), ThemeMode.dark);
    expect(await repository.getFontScale(), 1.2);
    expect(await repository.getReduceMotion(), isTrue);
    expect(await repository.getOnboardingComplete(), isTrue);
    expect(await repository.getAppLockEnabled(), isTrue);
  });

  test('clamps persisted text scale into the supported range', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accessibility.fontScale': 9.0,
    });
    final SettingsRepository repository = SettingsRepository();

    expect(await repository.getFontScale(), 1.4);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'accessibility.fontScale': 0.1,
    });
    expect(await repository.getFontScale(), 0.9);
  });
}
