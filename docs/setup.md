# NoteNest Setup Guide

This guide starts from a clean machine and gets the repository ready for development. NoteNest targets Android, Windows, Linux, macOS, and is iOS-ready. Native builds must be produced on operating systems supported by Flutter for those targets.

## 1. Required tools

You need:

- Git.
- Flutter SDK compatible with `pubspec.yaml`.
- Dart (included with Flutter).
- Python 3 for `tool/bootstrap_platforms.py`.
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

Use the official Flutter installation instructions for your operating system and stable channel. Keep the SDK in a user-writable development directory rather than a protected system folder.

After adding Flutter's `bin` directory to `PATH`, verify:

```bash
flutter --version
dart --version
flutter doctor -v
```

Resolve `flutter doctor` errors relevant to the platforms you intend to use.

### Updating Flutter

Before upgrading an established project, read Flutter release notes and dependency compatibility. A normal stable-channel update is:

```bash
flutter channel stable
flutter upgrade
flutter doctor -v
```

After an upgrade, regenerate platform runners and generated Dart code, then run the full quality suite before committing compatibility changes.

## 4. Editor setup

### VS Code

Recommended extensions:

- Dart (publisher: Dart Code).
- Flutter (publisher: Dart Code).

Helpful built-in/workspace behavior:

- Format on save using the Dart formatter.
- Show analyzer diagnostics.
- Do not use an extension that rewrites generated Drift files manually.

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

For project commits, configure the requested email locally:

```bash
git config user.email "sanskarin@outlook.in"
```

Optionally configure your display name if not already configured:

```bash
git config user.name "Sanskar"
```

## 6. Generate native platform runners

The repository intentionally generates runner templates from the installed Flutter SDK:

```bash
python tool/bootstrap_platforms.py
```

On Windows, if `python` is not registered but the launcher is:

```powershell
py tool/bootstrap_platforms.py
```

The script runs Flutter's project generator for Android, iOS, Linux, macOS, and Windows, then applies NoteNest-specific native requirements:

- Android activity uses `FlutterFragmentActivity` for `local_auth` compatibility.
- Android minimum SDK is patched to the project baseline.
- iOS `Info.plist` gets a Face ID usage description for optional app lock.

The script is intended to be re-runnable after a clean checkout or Flutter upgrade.

## 7. Fetch dependencies

```bash
flutter pub get
```

If dependency resolution fails after an SDK upgrade, do not immediately widen every version constraint. First inspect the solver message, Flutter/Dart version, and package compatibility.

## 8. Generate Drift code

```bash
dart run build_runner build --delete-conflicting-outputs
```

This creates `lib/data/database/app_database.g.dart` and other generated output required by Drift. Generated `*.g.dart` files are ignored by Git and should be regenerated locally/CI.

For continuous generation while editing schema/query declarations:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## 9. Verify the repository

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
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

Release artifacts require your own secure signing configuration; never commit keystores/passwords.

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

The bootstrap script uses only Python's standard library; no `pip install` is required.

## Clean rebuild

When generated/native state becomes suspicious:

```bash
flutter clean
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Do not delete user application data on a real device simply to fix a compile problem.

## Dependency upgrade workflow

Before changing dependencies:

```bash
flutter pub outdated
```

Upgrade deliberately, review changelogs/migrations, then:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

For native-plugin upgrades, rebuild on every affected target before release.

## Secrets and local configuration

Core NoteNest requires no secret `.env` values. `.env.example` exists only as a safe placeholder for future non-secret build configuration.

Never commit:

- `.env` values with credentials.
- Android keystores or `key.properties`.
- Apple signing files.
- API tokens.
- Real note databases/backups.

See [SECURITY.md](../SECURITY.md).

## Next steps

- Development workflow: [development.md](development.md)
- Architecture: [architecture.md](architecture.md)
- Testing: [testing.md](testing.md)
- Troubleshooting: [troubleshooting.md](troubleshooting.md)
