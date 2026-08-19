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
    expect(await repository.getAppLockEnabled(), isFalse);
  });

  test('persists appearance and privacy choices', () async {
    final SettingsRepository repository = SettingsRepository();

    await repository.setThemeMode(ThemeMode.dark);
    await repository.setFontScale(1.2);
    await repository.setReduceMotion(value: true);
    await repository.setAppLockEnabled(value: true);

    expect(await repository.getThemeMode(), ThemeMode.dark);
    expect(await repository.getFontScale(), 1.2);
    expect(await repository.getReduceMotion(), isTrue);
    expect(await repository.getAppLockEnabled(), isTrue);
  });
}
