# NoteNest Setup Guide

This guide starts from a clean machine and prepares the repository for development of the current **2.0.12** release candidate. NoteNest targets the complete Flutter platform set: **Android, iOS/iPadOS, Windows, macOS, Linux, and Web**.

## 1. Required tools

You need:

- Git.
- Flutter SDK **3.44.7**, pinned by `.flutter-version` and GitHub Actions.
- Dart (included with Flutter).
- Python 3 for repository/bootstrap tools.
- Network access during platform bootstrap so the matching Drift Web runtime assets can be obtained.
- An editor such as VS Code or Android Studio.
- Native platform tooling for whichever native target you intend to build.
- Chrome when running the Web smoke regression locally.

Do not install a separate random Dart SDK ahead of Flutter unless you have a specific reason; Flutter includes the compatible Dart SDK.

## 2. Install Git

Verify:

```bash
git --version
```

Use the supported Git installer/package manager for your OS.

## 3. Install Flutter

Use Flutter's official installation instructions and keep the SDK in a user-writable development location. For reproducible NoteNest work, select the version recorded in `.flutter-version` instead of silently following a newer stable channel.

Verify:

```bash
flutter --version
dart --version
flutter doctor -v
```

`flutter --version` must report **3.44.7** for final 2.0.12 verification.

### Updating Flutter

A Flutter upgrade is a project change, not a workstation-only update:

1. Review Flutter release/package compatibility.
2. Update `.flutter-version`.
3. Update exact `flutter-version` values in CI, platform-build, and release workflows.
4. Regenerate all six platform runners.
5. Re-run code generation, tests, browser smoke checks, and all affected platform builds.
6. Update release documentation before claiming the new toolchain.

`tool/check_version_sync.py` rejects workflow pin drift.

## 4. Editor setup

### VS Code

Recommended extensions:

- Dart (Dart Code).
- Flutter (Dart Code).

Enable Dart formatting/analyzer diagnostics and do not manually edit generated Drift files.

### Android Studio

Install Flutter/Dart integration and keep relevant Android SDK tooling available when building Android.

## 5. Clone NoteNest

```bash
git clone https://github.com/sanskarIN/notenest.git
cd notenest
```

Check state:

```bash
git status
git branch --show-current
```

Configure the requested project commit identity:

```bash
git config user.email "sanskarin@outlook.in"
git config user.name "Sanskar"
```

## 6. Verify release metadata

```bash
python tool/check_version_sync.py
```

For 2.0.12 this verifies the package/visible/changelog/release-note relationship plus the exact Flutter SDK pin used by the project and workflows.

On Windows, use `py` if that is your configured Python launcher.

## 7. Generate all platform runners

```bash
python tool/bootstrap_platforms.py
```

Windows:

```powershell
py tool/bootstrap_platforms.py
```

The bootstrap runs Flutter project generation for:

- Android
- iOS
- Linux
- macOS
- Windows
- Web

It then applies/verifies NoteNest platform requirements:

- Android `FlutterFragmentActivity` for `local_auth`.
- Android biometric permission, minimum SDK, AppCompat dependency/theme baseline.
- iOS Face ID usage description.
- Web `sqlite3.wasm` and `drift_worker.js` from the exact **Drift 2.34.3** release used by `pubspec.yaml`.
- Basic downloaded Web asset sanity checks and explicit failure if the Drift pin changes without bootstrap review.

The Web assets are generated build/runtime inputs and intentionally remain untracked with the rest of the generated platform runners.

## 8. Fetch dependencies

```bash
flutter pub get
```

### Required 2.0.12 lockfile completion

Stable 2.0.12 still requires the real resolver-generated `pubspec.lock` tracked by GitHub issue #8. Generate it from a clean checkout using Flutter **3.44.7**, review it, and commit the generated file. Do **not** hand-author dependency hashes/versions.

Once committed, final release verification should enforce the lock rather than silently resolving a different graph.

## 9. Generate Drift code

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated `*.g.dart` output is intentionally untracked and regenerated locally/CI.

Continuous mode:

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
python tool/check_repository_reference.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

Browser-specific boundary test:

```bash
flutter test --platform chrome test/web/web_platform_smoke_test.dart
```

Then list/run targets:

```bash
flutter devices
flutter run -d <device-id>
```

## Android setup

Install Android Studio or compatible Android command-line tooling, required SDK/build tools, and a compatible JDK.

```bash
flutter doctor --android-licenses
flutter doctor -v
flutter devices
flutter build apk --debug
```

Release verification additionally uses release APK/App Bundle compilation as documented in [`release.md`](release.md). Keep keystores/passwords outside Git.

## Windows desktop setup

Use Windows with Visual Studio **Desktop development with C++** and required Windows SDK components.

```powershell
flutter config --enable-windows-desktop
flutter doctor -v
flutter build windows --release
```

VS Code does not replace the native Visual Studio C++ build toolchain.

## Linux desktop setup

Install Flutter's Linux desktop prerequisites for your distribution (typically compiler, CMake, Ninja, GTK development headers, and pkg-config).

```bash
flutter config --enable-linux-desktop
flutter doctor -v
flutter build linux --release
```

The current `local_auth` dependency has no Linux implementation, so NoteNest reports app-lock device authentication unavailable on Linux rather than blocking the rest of the app.

## macOS desktop setup

Install Xcode/command-line tools and CocoaPods when required by current Flutter/plugins.

```bash
flutter config --enable-macos-desktop
flutter doctor -v
flutter build macos --release
```

## iOS / iPadOS setup

Requires macOS + Xcode.

```bash
flutter doctor -v
flutter build ios --release --no-codesign
```

The no-codesign command validates compilation. Real-device/App Store distribution requires your Apple signing/provisioning. Never commit signing credentials.

## Web setup

Flutter Web can be developed from a supported desktop host with a compatible browser.

Run in Chrome:

```bash
flutter run -d chrome
```

Run the browser platform regression:

```bash
flutter test --platform chrome test/web/web_platform_smoke_test.dart
```

Build the release bundle:

```bash
flutter build web --release
```

### Web database runtime

`AppDatabase` points Drift Web at root assets `sqlite3.wasm` and `drift_worker.js`. `tool/bootstrap_platforms.py` writes the matching Drift 2.34.3 assets into the generated `web/` runner before build.

When hosting `build/web`:

- Serve `sqlite3.wasm` with MIME type `application/wasm`.
- Do not omit or rename `drift_worker.js` / `sqlite3.wasm` without updating the database configuration.
- Keep the worker and WASM accessible from the deployed app root implied by the current relative URIs.
- For Drift's optimal OPFS-backed path on compatible browsers, configure cross-origin isolation headers when your host supports them. Drift can fall back to other browser storage modes when isolation is unavailable, so verify the actual backend on the intended host instead of assuming OPFS.
- Test page reload, browser restart, import/export, and storage retention on the real deployment origin.

Browser note data is local to the browser profile/origin and can be removed by site-data clearing/private browsing policies. JSON backup export is the portable recovery mechanism.

### Web app lock

`local_auth 3.0.2` does not implement Web. NoteNest therefore uses a browser-safe app-lock fallback that reports authentication unavailable. It does not create a custom browser password/biometric system merely to claim parity.

## Python setup

Verify:

```bash
python --version
```

or:

```powershell
py --version
```

Repository tools use the Python standard library only. Current tools include platform bootstrap, version sync, repository policy/reference validation, Markdown links, and secret scanning.

## Clean rebuild

```bash
flutter clean
python tool/check_version_sync.py
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter test --platform chrome test/web/web_platform_smoke_test.dart
python tool/check_repo.py
python tool/check_repository_reference.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

Do not delete real application/browser user data merely to repair a build environment.

## Dependency upgrade workflow

Before dependency changes:

```bash
flutter pub outdated
```

After a deliberate change:

```bash
python tool/check_version_sync.py
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test --platform chrome test/web/web_platform_smoke_test.dart
python tool/check_repo.py
python tool/check_repository_reference.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

When changing `drift`, review/update the bootstrap's Web runtime version in the same change and rebuild Web. For plugin changes, rebuild every affected target.

## Runtime/plugin smoke checks for 2.0.12

Before stable 2.0.12, use fictional data and verify:

- Markdown/text selection/import and oversized rejection on native plus Web.
- JSON backup export/restore and oversized rejection on native plus Web.
- Web local persistence across page reload and browser restart on the actual deployment origin.
- Web file download/save behavior.
- Repository/funding/release/mail links and no-handler feedback.
- App-lock supported paths on Android/iOS/macOS/Windows.
- App-lock unavailable-but-usable paths on Web/Linux.
- Settings persistence across restart/reload.
- Rapid settings changes and rapid note edits.
- Keyboard/browser navigation, zoom/large text, screen-reader semantics, dark/light themes, and reduced motion.

## Secrets and local configuration

Core NoteNest requires no secret `.env` values. Never commit credentials, Android/Apple signing material, API tokens, real note databases, real backups, or private user data.

See [`../SECURITY.md`](../SECURITY.md).

## Next steps

- Development workflow: [`development.md`](development.md)
- Architecture: [`architecture.md`](architecture.md)
- Testing: [`testing.md`](testing.md)
- Release: [`release.md`](release.md)
- 2.0.12 release candidate: [`releases/2.0.12.md`](releases/2.0.12.md)
- Troubleshooting: [`troubleshooting.md`](troubleshooting.md)
