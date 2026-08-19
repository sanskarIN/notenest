# NoteNest Setup Guide

This guide starts from a clean machine and gets the repository ready for development and the current **2.0.12** release candidate. NoteNest targets Android, Windows, Linux, macOS, and is iOS-ready. Native builds must be produced on operating systems supported by Flutter for those targets.

## 1. Required tools

You need:

- Git.
- Flutter SDK **3.44.7**, pinned by `.flutter-version` and the GitHub Actions workflows.
- Dart (included with Flutter).
- Python 3 for repository/bootstrap quality tools.
- A code editor such as VS Code or Android Studio.
- Native platform tooling for the target you want to build.

Do not install a separate random Dart SDK ahead of Flutter unless you have a specific reason; Flutter ships a compatible Dart SDK.

## 2. Install Git

Verify:

```bash
git --version
```

Use the official Git installer/package manager for your operating system. On Windows, Git for Windows is the common choice. On macOS, Xcode Command Line Tools or a package manager can provide Git. On Linux, use the distribution package manager.

## 3. Install Flutter

Use the official Flutter installation instructions for your operating system and stable channel. Keep the SDK in a user-writable development directory rather than a protected system folder. For reproducible NoteNest work, select the version recorded in `.flutter-version` instead of silently using a newer stable release.

After adding Flutter's `bin` directory to `PATH`, verify:

```bash
flutter --version
dart --version
flutter doctor -v
```

`flutter --version` should report **3.44.7** for the current NoteNest 2.0.12 release-candidate toolchain. Resolve `flutter doctor` errors relevant to the platforms you intend to use.

### Updating Flutter

Flutter upgrades are deliberate project changes. Do not update only a developer machine while leaving CI on another SDK. When adopting a new Flutter release:

1. Review Flutter release notes and package compatibility.
2. Update `.flutter-version`.
3. Update the exact `flutter-version` used in CI, platform-build, and release workflows.
4. Regenerate platform runners and generated Dart code.
5. Run the full quality and native build suites before merging the upgrade.

A developer may use their preferred Flutter version manager, but it must resolve the project to the pinned version before verification.

## 4. Editor setup

### VS Code

Recommended extensions:

- Dart (publisher: Dart Code).
- Flutter (publisher: Dart Code).

Helpful behavior:

- Format on save using the Dart formatter.
- Show analyzer diagnostics.
- Do not manually edit generated Drift files.

### Android Studio

Install the Flutter plugin; it brings Dart integration. Keep Android SDK/SDK tools updated through the SDK Manager. Use an Android emulator or physical device for runtime testing.

## 5. Clone NoteNest

```bash
git clone https://github.com/sanskarIN/notenest.git
cd notenest
```

Check the current branch:

```bash
git status
git branch --show-current
```

For local project commits, configure the requested email:

```bash
git config user.email "sanskarin@outlook.in"
```

Optionally configure your display name:

```bash
git config user.name "Sanskar"
```

## 6. Verify release metadata

Before dependency generation or release work, run:

```bash
python tool/check_version_sync.py
```

For the current candidate it verifies:

- `pubspec.yaml` is `2.0.12+2012`.
- `AppStrings.version` is `2.0.12`.
- `CHANGELOG.md` contains the 2.0.12 section.
- `docs/releases/2.0.12.md` exists and contains the exact package/visible version values.

On Windows use `py` if that is your Python launcher.

## 7. Generate native platform runners

The repository intentionally generates runner templates from the pinned Flutter SDK:

```bash
python tool/bootstrap_platforms.py
```

On Windows:

```powershell
py tool/bootstrap_platforms.py
```

The script runs Flutter's project generator for Android, iOS, Linux, macOS, and Windows, then applies NoteNest-specific native requirements:

- Android activity uses `FlutterFragmentActivity` for `local_auth` compatibility.
- Android minimum SDK is patched to the project baseline.
- iOS `Info.plist` gets a Face ID usage description for optional app lock.

The script is intended to be re-runnable after a clean checkout or intentional Flutter upgrade.

## 8. Fetch dependencies

```bash
flutter pub get
```

If dependency resolution fails after an SDK upgrade, do not immediately widen every version constraint. First inspect the solver message, Flutter/Dart version, and package compatibility.

## 9. Generate Drift code

```bash
dart run build_runner build --delete-conflicting-outputs
```

This creates `lib/data/database/app_database.g.dart` and other generated output required by Drift. Generated `*.g.dart` files are ignored by Git and should be regenerated locally/CI.

For continuous generation while editing schema/query declarations:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## 10. Verify the repository

Run the complete quality gate:

```bash
python tool/check_version_sync.py
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
python tool/check_repo.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

If all applicable commands pass, list runnable devices:

```bash
flutter devices
```

Then launch:

```bash
flutter run -d <device-id>
```

## Android setup

Install:

- Android Studio or Android command-line tooling.
- Android SDK platform/build tools accepted by the installed Flutter version.
- Android SDK command-line tools.
- A compatible JDK (Flutter/Android Studio may manage/recommend one).

Accept required Android licenses:

```bash
flutter doctor --android-licenses
```

Verify:

```bash
flutter doctor -v
flutter devices
```

For a physical device, enable developer options/USB debugging and authorize the computer. For an emulator, create a current virtual device through Android Studio Device Manager.

Build smoke test:

```bash
flutter build apk --debug
```

Release candidates should additionally compile the release artifacts documented in [`release.md`](release.md). Release artifacts require your own secure signing configuration; never commit keystores/passwords.

## Windows desktop setup

Use Windows with Visual Studio's **Desktop development with C++** workload and the Windows SDK components required by the installed Flutter version.

Verify:

```powershell
flutter config --enable-windows-desktop
flutter doctor -v
flutter devices
```

Build:

```powershell
flutter build windows --release
```

Visual Studio Code is an editor; it does not replace the native Visual Studio C++ build toolchain for Flutter Windows desktop builds.

## Linux desktop setup

Install Flutter's Linux desktop prerequisites for your distribution. Typical requirements include a C/C++ compiler, CMake, Ninja, GTK development headers, and pkg-config.

Then:

```bash
flutter config --enable-linux-desktop
flutter doctor -v
flutter build linux --release
```

Package names vary by distribution, so use Flutter's current Linux desktop documentation rather than copying package names meant for another distro/version.

## macOS desktop setup

Install current Xcode and command-line tools, accept the Xcode license, and configure Xcode's active developer directory if needed.

Then:

```bash
flutter config --enable-macos-desktop
flutter doctor -v
flutter build macos --release
```

CocoaPods may be required by plugins/native dependencies. If `flutter doctor` reports it missing for your target, install/repair CocoaPods using its supported installation method.

## iOS setup

An iOS build requires macOS with Xcode. After runner generation:

```bash
flutter doctor -v
flutter build ios --release --no-codesign
```

The no-codesign build is suitable for compile validation. Installing/distributing on real devices or the App Store requires Apple signing identities/provisioning under your account.

Never commit Apple signing secrets, exported certificates, or private provisioning material.

## Python setup

Verify:

```bash
python --version
```

or on Windows:

```powershell
py --version
```

The repository Python tools use only the standard library; no `pip install` is required.

Current maintenance scripts include:

- `tool/bootstrap_platforms.py`
- `tool/check_version_sync.py`
- `tool/check_repo.py`
- `tool/check_markdown_links.py`
- `tool/security_scan.py`

## Clean rebuild

When generated/native state becomes suspicious:

```bash
flutter clean
python tool/check_version_sync.py
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
python tool/check_repo.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

Do not delete user application data on a real device simply to fix a compile problem.

## Dependency upgrade workflow

Before changing dependencies:

```bash
flutter pub outdated
```

Upgrade deliberately, review changelogs/migrations, then:

```bash
python tool/check_version_sync.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
python tool/check_repo.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

For native-plugin upgrades, rebuild on every affected target before release.

## Runtime/plugin smoke checks for 2.0.12

A compile/test pass does not replace real platform checks. Before stable 2.0.12, exercise at least:

- Markdown/text file selection and bounded oversized-file rejection.
- JSON backup selection, restore, and oversized-file rejection.
- Repository/funding/release links and `mailto:` actions.
- No-handler/external-link failure feedback where practical.
- Optional local authentication supported/unsupported paths.
- Settings persistence across restart.
- Rapid settings changes and rapid note edits.

Use fictional note data.

## Secrets and local configuration

Core NoteNest requires no secret `.env` values. `.env.example` exists only as a safe placeholder for future non-secret build configuration.

Never commit:

- `.env` values with credentials.
- Android keystores or `key.properties`.
- Apple signing files.
- API tokens.
- Real note databases/backups.

See [`../SECURITY.md`](../SECURITY.md).

## Next steps

- Development workflow: [`development.md`](development.md)
- Architecture: [`architecture.md`](architecture.md)
- Testing: [`testing.md`](testing.md)
- Release: [`release.md`](release.md)
- 2.0.12 release candidate: [`releases/2.0.12.md`](releases/2.0.12.md)
- Troubleshooting: [`troubleshooting.md`](troubleshooting.md)
