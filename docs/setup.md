# NoteNest Setup Guide

This guide prepares a clean machine for the current **NoteNest 2.0.12** release candidate (`2.0.12+2012`). The project targets **Android, iOS/iPadOS, Windows, macOS, Linux, and Web** from one Flutter codebase.

## Reproducible baseline

NoteNest release/development verification is intentionally pinned:

- Flutter **3.44.7** from `.flutter-version`.
- Dart **3.12.2** from that Flutter SDK.
- A committed resolver-generated `pubspec.lock` containing the current **129-package** dependency graph.
- `file_picker 12.0.0`.
- Drift **2.34.3** plus matching Web worker/WASM assets.
- iOS/iPadOS deployment floor **14.0** for the current file-picker dependency.

Normal setup must restore the committed graph with:

```bash
flutter pub get --enforce-lockfile
```

Do not delete or regenerate `pubspec.lock` during ordinary setup simply to make a dependency problem disappear. A deliberate dependency change is a reviewed source change and must produce a reviewed new lockfile with the pinned toolchain.

## 1. Required tools

Install:

- Git.
- Flutter SDK **3.44.7**.
- Dart supplied by Flutter.
- Python 3 for repository/bootstrap tools.
- A development editor such as VS Code or Android Studio.
- Native platform tooling for the targets you build.
- Chrome when running the Web platform regression locally.
- Network access during platform bootstrap so Drift's matching Web runtime assets can be downloaded.

Verify the common tools:

```bash
git --version
flutter --version
dart --version
python --version
flutter doctor -v
```

On Windows, `py --version` may be used instead of `python --version`.

For final 2.0.12 verification, Flutter must report **3.44.7**.

## 2. Clone and configure Git

```bash
git clone https://github.com/sanskarIN/notenest.git
cd notenest
git status
git branch --show-current
```

Optional project commit identity:

```bash
git config user.name "Sanskar"
git config user.email "sanskarin@outlook.in"
```

## 3. Verify project metadata

Run before platform generation or release work:

```bash
python tool/check_version_sync.py
```

Windows alternative:

```powershell
py tool/check_version_sync.py
```

The check synchronizes package/build version, visible application version, changelog/release notes, `.flutter-version`, and the Flutter pins in CI/platform/release workflows.

## 4. Generate platform runners

```bash
python tool/bootstrap_platforms.py
```

Windows:

```powershell
py tool/bootstrap_platforms.py
```

The script runs Flutter project generation with `--no-pub`, so runner creation does **not** silently change the dependency graph. It generates Android, iOS, Linux, macOS, Windows, and Web runners and then applies/verifies NoteNest-specific requirements.

### Android bootstrap requirements

The generated Android target is checked/patched for:

- `FlutterFragmentActivity`, required by the authentication integration.
- `USE_BIOMETRIC` permission.
- Minimum SDK **24**.
- AppCompat dependency/theme baseline.

### iOS / iPadOS bootstrap requirements

The generated Apple mobile target is checked/patched for:

- Face ID usage description.
- Explicit deployment target **iOS 14.0+**, matching the current file-picker 12 platform requirement.

### Windows bootstrap requirements

The generated Windows target receives the MSVC compatibility definition required by the current `local_auth_windows` implementation on modern Visual Studio/GitHub-hosted toolchains. Python also invokes Flutter `.bat`/`.cmd` launchers through the Windows command interpreter rather than attempting to execute batch files as native binaries.

### Web bootstrap requirements

The generated Web target obtains:

- `sqlite3.wasm`
- `drift_worker.js`

from the matching **Drift 2.34.3** release. The bootstrap validates the direct Drift pin and basic downloaded payload signatures and fails if the dependency/runtime pairing drifts.

Generated runner trees and Web runtime inputs remain intentionally untracked.

## 5. Restore locked dependencies

```bash
flutter pub get --enforce-lockfile
```

This is the normal command for contributors, CI, platform compilation, and release packaging. If the manifest, lockfile, hosted package hashes, or solver result disagree, fix the source/dependency change deliberately rather than bypassing the lock.

## 6. Generate Drift code

```bash
dart run build_runner build
```

Generated `*.g.dart` files are intentionally untracked.

Continuous generation during database development:

```bash
dart run build_runner watch
```

## 7. Run the quality gate

```bash
python tool/check_version_sync.py
flutter pub get --enforce-lockfile
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
python tool/check_repo.py
python tool/check_repository_reference.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

Browser-specific platform regression:

```bash
flutter test --platform chrome test/web/web_platform_smoke_test.dart
```

The repository-reference gate currently expects **109 tracked files**, including `pubspec.lock`.

## 8. Run a development target

List devices:

```bash
flutter devices
```

Run one:

```bash
flutter run -d <device-id>
```

Browser example:

```bash
flutter run -d chrome
```

## Android setup

Install Android Studio or equivalent Android command-line tooling, required SDK/build-tools packages, and a compatible JDK.

Useful checks:

```bash
flutter doctor --android-licenses
flutter doctor -v
flutter devices
flutter build apk --debug
```

Release builds:

```bash
flutter build apk --release
flutter build appbundle --release
```

Keep keystores, passwords, signing properties, and store credentials outside Git.

## Windows setup

Use Windows with Visual Studio and the **Desktop development with C++** workload plus a compatible Windows SDK.

```powershell
flutter config --enable-windows-desktop
flutter doctor -v
py tool/bootstrap_platforms.py
flutter pub get --enforce-lockfile
dart run build_runner build
flutter build windows --release
```

VS Code by itself does not replace the Visual Studio C++ toolchain.

The current bootstrap has been verified against the modern GitHub-hosted Windows/Visual Studio toolchain; do not remove its coroutine compatibility definition without rechecking `local_auth_windows` compilation.

## Linux setup

Install Flutter's Linux desktop prerequisites for your distribution. Typical packages include compiler tools, CMake, Ninja, GTK development headers, and pkg-config.

Ubuntu-family example:

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
flutter config --enable-linux-desktop
flutter doctor -v
flutter build linux --release
```

The current `local_auth` dependency has no Linux implementation. NoteNest therefore reports app-lock device authentication unavailable while keeping the rest of the app usable.

## macOS setup

Install Xcode/command-line tools and CocoaPods where required by Flutter/plugins.

```bash
flutter config --enable-macos-desktop
flutter doctor -v
flutter build macos --release
```

Distribution may additionally require signing/notarization.

## iOS / iPadOS setup

Requires macOS and Xcode. The current project targets **iOS 14.0+**.

Compile without distribution signing:

```bash
flutter doctor -v
flutter build ios --release --no-codesign
```

Real-device/App Store distribution requires valid Apple signing and provisioning. Never commit certificates, profiles, or credentials.

## Web setup

Run locally:

```bash
flutter run -d chrome
```

Run the browser platform regression:

```bash
flutter test --platform chrome test/web/web_platform_smoke_test.dart
```

Build:

```bash
flutter build web --release
```

### Web database deployment

When hosting `build/web`:

- Serve `sqlite3.wasm` as `application/wasm`.
- Keep `drift_worker.js` and `sqlite3.wasm` reachable at the configured paths.
- Verify create/edit/search after deployment.
- Verify reload and browser-restart persistence on the intended origin.
- Verify Markdown/backup import and download/export on the intended browser.
- Verify the actual browser storage backend rather than assuming OPFS.

Compatible cross-origin isolation can enable Drift's preferred OPFS-backed path. Browser note data remains tied to browser/profile/origin and may be removed by site-data controls, so JSON backup is the portable recovery path.

### Web app lock

`local_auth 3.0.2` has no Web implementation. NoteNest deliberately reports authentication unavailable instead of inventing a custom browser credential system.

## Clean rebuild

A safe repository rebuild does not require deleting real application/browser user data.

```bash
flutter clean
python tool/check_version_sync.py
python tool/bootstrap_platforms.py
flutter pub get --enforce-lockfile
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter test --platform chrome test/web/web_platform_smoke_test.dart
python tool/check_repo.py
python tool/check_repository_reference.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

## Deliberate dependency upgrade workflow

Dependency maintenance is different from normal setup.

Inspect first:

```bash
flutter pub outdated
```

Then deliberately edit `pubspec.yaml` and resolve with the pinned Flutter SDK:

```bash
flutter pub get
```

Review the resulting `pubspec.lock` diff carefully. For hosted packages, the lock includes exact versions and content hashes. Never hand-author those values.

Then verify:

```bash
python tool/check_version_sync.py
python tool/bootstrap_platforms.py
flutter pub get --enforce-lockfile
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter test --platform chrome test/web/web_platform_smoke_test.dart
python tool/check_repo.py
python tool/check_repository_reference.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

Rebuild **every affected target**. When changing Drift, review/update the matching Web worker/WASM version in `tool/bootstrap_platforms.py`. When changing file-picker or another platform plugin, review platform minimum versions, permissions, native registration/build tooling, and import/export behavior.

## Runtime checks before stable 2.0.12

Automated compilation is necessary but not sufficient. Before the stable tag, use fictional data and verify at minimum:

- Rapid edit → Back preserves the newest draft.
- Save failures keep the editor open with usable feedback.
- Markdown/text selection/import/export and oversize rejection on representative native targets.
- JSON backup export/restore and oversize/malformed rejection.
- Web persistence across page reload and browser restart on the real deployment origin.
- Web file import/download behavior and worker/WASM reachability/MIME.
- Repository/funding/release/mail links and no-handler feedback.
- App-lock supported paths on representative Android/iOS/macOS/Windows devices.
- Web/Linux unavailable app-lock paths remain usable.
- Settings persistence and rapid setting changes.
- Keyboard/browser focus, zoom/large text, screen-reader semantics, light/dark themes, compact/wide layouts, and reduced motion.
- Runtime screenshots from the exact candidate.
- Signing, artifact, and SHA-256 checksum status.

## Secrets and local configuration

Core NoteNest requires no secret `.env` values. Never commit credentials, Android/Apple signing material, API tokens, real note databases, real backups, or private user data.

See [`../SECURITY.md`](../SECURITY.md).

## Related documentation

- [`development.md`](development.md)
- [`architecture.md`](architecture.md)
- [`testing.md`](testing.md)
- [`release.md`](release.md)
- [`releases/2.0.12.md`](releases/2.0.12.md)
- [`troubleshooting.md`](troubleshooting.md)
