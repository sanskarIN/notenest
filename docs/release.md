# NoteNest Release Guide

This guide defines how to prepare, verify, package, and publish NoteNest without committing secrets or claiming checks that were not run.

Current release candidate: **2.0.12** (`2.0.12+2012`).

## Release principles

- Release only from an exact reviewed commit.
- Keep package/UI/changelog/version-specific release notes synchronized.
- Use Flutter **3.44.7** from `.flutter-version`; all Flutter workflows must match it.
- Restore the committed resolver-generated application graph with `flutter pub get --enforce-lockfile`.
- Never fabricate dependency versions or hosted-package content hashes.
- Generate all six platform runners with `tool/bootstrap_platforms.py`.
- Treat platform-template drift, dependency incompatibility, Drift Web runtime mismatch, or Web asset validation failure as blockers.
- Generate Drift code from the locked graph.
- Run the deterministic quality/security gate.
- Compile Android, iOS/iPadOS, Windows, macOS, Linux, and Web on the exact candidate.
- Run representative real-device/browser/runtime/accessibility checks before stable release.
- Keep signing credentials outside Git.
- Record exact limitations and verification status in `what_changed.md`.
- Never tag while a critical data-loss/security/release blocker remains unresolved.

## Release metadata and dependency reproducibility

Current version metadata:

```yaml
version: 2.0.12+2012
```

Required synchronized values:

- Package semantic version: `2.0.12`.
- Build number: `2012`.
- Visible `AppStrings.version`: `2.0.12`.
- Matching `CHANGELOG.md` section.
- Matching `docs/releases/2.0.12.md` notes.
- `.flutter-version`: `3.44.7`.
- CI/platform/release Flutter pin: `3.44.7`.

Verify:

```bash
python tool/check_version_sync.py
```

### Committed application lock

The 2.0.12 candidate now tracks a genuine Flutter-3.44.7 resolver-generated `pubspec.lock` for the current file-picker-12 dependency graph.

Current lock baseline:

- **129 resolved packages**.
- `file_picker 12.0.0` plus its federated platform packages.
- `intl 0.20.2`, matching Flutter 3.44.7's localization SDK pin.
- Drift `2.34.3` / drift_dev `2.34.5`.
- Lock SDK constraints compatible with Dart 3.12.2 / Flutter 3.44.7.

Automated quality, platform, and release workflows use:

```bash
flutter pub get --enforce-lockfile
```

A deliberate dependency change may run an unlocked resolver with the pinned Flutter SDK, but the resulting lockfile must be reviewed and committed before release verification. Do not manually author dependency hashes.

The exhaustive repository reference contains **109 tracked files**, including `pubspec.lock`.

## Clean checkout preparation

Inspect before destructive cleanup:

```bash
git status --short
git clean -ndx
flutter --version
dart --version
```

Then prepare the exact graph:

```bash
python tool/check_version_sync.py
python tool/bootstrap_platforms.py
flutter pub get --enforce-lockfile
dart run build_runner build
```

`tool/bootstrap_platforms.py` generates Android/iOS/Linux/macOS/Windows/Web runners with `--no-pub`, applies/verifies NoteNest platform requirements, and prepares matching Drift Web runtime assets.

Current generated-target requirements include:

- Android min SDK 24, FragmentActivity, biometric permission, AppCompat baseline.
- iOS/iPadOS Face ID usage text and explicit **iOS 14.0+** deployment floor.
- Windows compatibility for current MSVC/`local_auth_windows` coroutine behavior.
- Drift Web `sqlite3.wasm` + `drift_worker.js` pinned to Drift 2.34.3.

## Deterministic quality gate

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

Also record `flutter doctor -v` on relevant native build hosts when doing release validation outside CI.

## Web automated gate

```bash
python tool/bootstrap_platforms.py
flutter pub get --enforce-lockfile
dart run build_runner build
flutter test --platform chrome test/web/web_platform_smoke_test.dart
flutter build web --release
```

The Chrome regression proves browser-safe app-lock/filesystem boundaries compile and degrade safely. It does **not** prove deployed-origin persistence, download behavior, MIME configuration, or browser restart retention.

## Platform compile commands

### Android

```bash
flutter build apk --release
flutter build appbundle --release
```

Verify package identity, version/build values, generated permissions/min SDK, file picker behavior, links, and supported authentication. Distribution signing stays outside Git.

### iOS / iPadOS

Host: macOS/Xcode. Current minimum: **iOS 14.0+**.

```bash
flutter build ios --release --no-codesign
```

This validates compilation only. Real-device/App Store distribution requires Apple signing/provisioning.

### Windows

```powershell
flutter build windows --release
```

Verify storage, picker/save behavior, links, keyboard/resize behavior, and Windows authentication on representative systems. Do not remove the current bootstrap's MSVC compatibility definition without rebuilding against the current Windows toolchain.

### macOS

```bash
flutter build macos --release
```

Distribution may require signing/notarization. Verify storage, picker/save, links, and authentication on a representative host.

### Linux

```bash
flutter build linux --release
```

Record distro/runtime assumptions. Verify storage, picker/save, links, keyboard/resize behavior, and the expected unavailable app-lock state.

### Web

```bash
flutter test --platform chrome test/web/web_platform_smoke_test.dart
flutter build web --release
```

Deploy the actual `build/web` output to the intended host/origin and verify:

- App loads without worker/WASM errors.
- `sqlite3.wasm` is served as `application/wasm`.
- `drift_worker.js` and `sqlite3.wasm` are reachable.
- Create/edit/search works.
- Data survives reload and browser restart under normal storage settings.
- Markdown/backup import and export/download work.
- Oversized selected files are rejected.
- App lock reports unavailable without blocking the app.
- External links/mail handlers behave as expected.
- Keyboard/focus/zoom/screen-reader behavior is usable.

Compatible cross-origin isolation can enable Drift's preferred OPFS-backed mode. Where unavailable, verify/document the actual fallback rather than claiming OPFS.

Browser-local data is tied to browser/profile/origin and can be removed by site-data controls. JSON backups are the portable recovery path.

## Automated evidence reached during 2.0.12 hardening

A file-picker-12 diagnostic candidate completed the following before the final post-documentation rerun:

- Android release APK compile: **passed**.
- Linux release compile: **passed**.
- Windows release compile on current GitHub-hosted VS2026: **passed**.
- macOS release compile: **passed**.
- unsigned iOS release compile with explicit iOS 14 floor: **passed**.
- Chrome Web platform smoke: **passed**.
- Web release compile: **passed**.
- Repository secret scan: **passed**.
- Dependency review: **passed**.
- Flutter 3.44.7 dependency resolution/code generation: **passed**.
- Canonical Dart 3.12.2 formatting: **passed** after materialization.

An analyzer run on that materialized candidate reported only five style-level infos; those findings have since been fixed. Because source/documentation/workflow commits followed, the diagnostic matrix is evidence that the platform fixes work but is **not** the final release-candidate run. One exact final rerun remains required.

## Manual product smoke test

Use fictional data only and exercise:

1. First-run onboarding persistence.
2. Create/edit/autosave/rapid-edit/close/reopen newest-draft behavior.
3. Save-failure behavior during Back navigation.
4. Heading/Bullet/Checklist at caret offset zero on an empty first line.
5. Folder/tags/color/pin/favorite.
6. Non-color selected cue for note color.
7. Full-text search.
8. Archive/unarchive.
9. Trash/restore/permanent delete/empty trash.
10. Version snapshot/restore.
11. Markdown/text import/export and cross-platform filename edge cases.
12. >16 MiB Markdown/text rejection.
13. JSON backup export/restore/conflict behavior.
14. >64 MiB backup rejection and malformed-backup rejection.
15. Theme/text-scale/reduced-motion persistence.
16. Repository/funding/mail/releases links and failure feedback.
17. Supported app-lock authentication and background/resume behavior.
18. Web/Linux unavailable app-lock behavior remains usable.
19. Controlled root-app teardown where practical.
20. Web create/edit/search → reload → browser restart persistence.
21. Web Markdown/backup download and re-import.

## Accessibility release check

Follow [`accessibility.md`](accessibility.md). At minimum verify:

- Keyboard traversal on desktop and Web.
- Browser focus visibility and common zoom/text-scale conditions.
- Screen-reader/semantics on representative mobile plus browser/desktop coverage where practical.
- Narrow/wide layouts.
- Light/dark themes.
- Reduced motion.
- Destructive confirmations.
- Note-color non-color selection cue and target size.
- Failure/status feedback remains reachable and readable.

Document limitations rather than claiming formal certification.

## GitHub Actions release matrix

The platform-build workflow verifies:

- Android release compile.
- Linux release compile.
- Windows release compile.
- macOS release compile.
- unsigned iOS release compile.
- Chrome Web platform smoke.
- Web release compile.

All dependency restoration is lock-enforced.

The release workflow packages/uploads native/Web outputs for release validation. Artifacts are evidence of build output, **not** store signing, notarization, real-device behavior, or runtime certification.

## Artifact naming and checksums

Suggested names:

```text
notenest-2.0.12-android.apk
notenest-2.0.12-windows-x64.zip
notenest-2.0.12-linux-x64.tar.gz
notenest-2.0.12-macos.zip
notenest-2.0.12-web.zip
```

Never label unsigned/no-codesign output as store-ready.

Publish SHA-256 checksums for distributed artifacts.

Linux/macOS:

```bash
shasum -a 256 <artifact>
```

Windows PowerShell:

```powershell
Get-FileHash <artifact> -Algorithm SHA256
```

Checksums provide integrity metadata but do not replace signing/authenticity.

## Release notes

Use [`releases/2.0.12.md`](releases/2.0.12.md) as the candidate source. Final notes must distinguish:

- implemented target support;
- automated compilation evidence;
- representative runtime checks actually performed;
- browser storage/deployment limitations;
- signing/notarization status;
- artifact/checksum status;
- known limitations.

Avoid unsupported claims such as “bug-free” or “perfectly secure.”

## Branch protection recommendation

For `main`, where repository/account settings permit:

- Require pull requests for non-emergency changes.
- Require quality/security/platform checks.
- Require current branches where practical.
- Require conversation resolution.
- Prevent force pushes/deletion.
- Restrict bypass permissions.

## Stable tag

Only after the **exact final release commit** passes the complete checklist:

```bash
git tag -a v2.0.12 -m "NoteNest 2.0.12"
git push origin v2.0.12
```

Never move a published release tag. Publish a new patch version for post-release fixes.

## Final 2.0.12 checklist

### Metadata and reproducibility

- [x] `pubspec.yaml` = `2.0.12+2012`.
- [x] Visible version = `2.0.12`.
- [x] Matching changelog and release notes exist.
- [x] Flutter 3.44.7 pin synchronized across workflows.
- [x] Six-platform source/bootstrap/build automation implemented.
- [x] Resolver-generated `pubspec.lock` committed.
- [x] Repository reference catalogs **109 tracked files**, including the lock.
- [x] CI/platform/release dependency restoration enforces the committed lock.
- [x] CI temporary lock-materialization write permission removed; quality workflow is read-only.

### Quality and security — exact final candidate

- [ ] Version synchronization passes.
- [ ] Locked dependency restore passes.
- [ ] Drift generation passes.
- [ ] Formatter passes.
- [ ] Analyzer passes.
- [ ] Flutter tests/coverage pass.
- [ ] Repository policy passes.
- [ ] 109-file repository-reference check passes.
- [ ] Markdown-link scan passes.
- [ ] Secret scan passes.
- [ ] Dependency review passes.

### Platform automation — exact final candidate

- [ ] Android release compile green.
- [ ] Linux release compile green.
- [ ] Windows release compile green.
- [ ] macOS release compile green.
- [ ] iOS no-codesign compile green.
- [ ] Chrome Web smoke green.
- [ ] Web release compile green.

The same seven platform checks **have passed on the immediate file-picker-12 hardening candidate**, but must be repeated after the final documentation/lint/lock-enforcement commits so the release evidence matches one exact SHA.

### Manual/runtime/accessibility

- [ ] Primary note/editor/lifecycle journeys verified.
- [ ] Native and browser import/export/size limits verified.
- [ ] Backup export/restore/malformed-data behavior verified with fictional data.
- [ ] Supported app-lock targets verified on representative devices.
- [ ] Web/Linux unavailable app-lock paths verified usable.
- [ ] Web persistence/reload/restart verified on intended deployment origin.
- [ ] Web MIME/worker/WASM serving verified.
- [ ] External links success/failure verified.
- [ ] Keyboard/screen-reader/large-text/zoom/themes/reduced-motion checks recorded.
- [ ] Runtime screenshots captured from the exact candidate.

### Distribution

- [ ] Signing/notarization/store status recorded.
- [ ] Final artifacts reviewed.
- [ ] SHA-256 checksums generated.
- [ ] Final release notes identify verified scope honestly.
- [ ] `v2.0.12` points to the exact fully verified commit.

Stable status remains blocked until the unchecked exact-candidate and manual/distribution requirements are completed.
