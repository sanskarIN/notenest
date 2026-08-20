# NoteNest Release Guide

This guide defines how to prepare, verify, package, and publish NoteNest without committing secrets or claiming checks that were not run.

Current release-candidate target: **2.0.12** (`2.0.12+2012`).

## Release principles

- Release only from an exact reviewed commit.
- Keep package/UI/changelog/version-specific release notes synchronized.
- Use Flutter **3.44.7** from `.flutter-version`; all Flutter workflows must match it.
- Commit the real resolver-generated application lockfile before stable release; never fabricate dependency versions/hashes.
- Generate all six platform runners with the bootstrap script.
- Treat native patch drift, Drift Web runtime mismatch, or Web asset download/validation failure as blockers.
- Generate Drift Dart code from the pinned dependency graph.
- Run the full deterministic quality gate.
- Verify Android, iOS, Windows, macOS, Linux, and Web compilation.
- Run representative real-device/browser accessibility/runtime checks.
- Keep signing credentials outside Git.
- Record exact results/limitations in `what_changed.md`.
- Do not tag/publish while a critical data-loss/security/release blocker is known.

## Version and dependency reproducibility

Current metadata:

```yaml
version: 2.0.12+2012
```

Required relationships:

- Package semantic version: `2.0.12`.
- Build number: `2012`.
- Visible `AppStrings.version`: `2.0.12`.
- `CHANGELOG.md`: matching 2.0.12 section.
- `docs/releases/2.0.12.md`: matching package/visible values.
- `.flutter-version`: exact `3.44.7`.
- CI/platform/release Flutter pins: exact `3.44.7`.

Verify:

```bash
python tool/check_version_sync.py
```

### `pubspec.lock` blocker for 2.0.12

NoteNest is an application and stable release builds must use a committed resolver-generated dependency lock. GitHub issue #8 tracks completion.

From a clean checkout with Flutter **3.44.7**:

```bash
flutter pub get
```

Then review and commit the generated `pubspec.lock`, add it to the exhaustive repository reference, and re-run final verification. Do not manually invent the lock contents. After the lock is committed, final CI/release dependency installation should enforce the committed graph using the supported locked/enforced command for the pinned toolchain.

Stable `v2.0.12` is blocked until this is complete.

## Clean checkout preparation

```bash
git status --short
git clean -ndx
flutter --version
python tool/check_version_sync.py
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Review before any destructive `git clean` operation.

`tool/bootstrap_platforms.py` generates Android/iOS/Linux/macOS/Windows/Web runners, applies/verifies Android/iOS authentication requirements, and prepares the Drift Web runtime assets matching direct dependency Drift **2.34.3**.

## Deterministic quality gate

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

Also record `flutter doctor -v` on relevant build hosts.

## Web-specific automated gate

```bash
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test --platform chrome test/web/web_platform_smoke_test.dart
flutter build web --release
```

The Chrome regression proves the browser-safe app-lock/filesystem fallbacks compile and behave safely. It does not prove persistence/file-download behavior on a deployed production origin.

## Manual product smoke test

Use fictional data only and exercise:

1. First-run onboarding persistence.
2. Create/edit/autosave/rapid edit/close/reopen newest-draft behavior.
3. Heading/Bullet/Checklist at caret offset zero on an empty first line.
4. Folder/tags/color/pin/favorite.
5. Non-color selected cue for note color.
6. Full-text search.
7. Archive/unarchive.
8. Trash/restore/permanent delete/empty trash.
9. Version snapshot/restore.
10. Markdown import/export and cross-platform filename edge cases.
11. >16 MiB Markdown/text rejection.
12. JSON backup export/restore/conflict behavior.
13. >64 MiB backup rejection.
14. Theme/text-scale/reduced-motion persistence.
15. Repository/funding/mail/releases links and failure feedback.
16. Supported app-lock authentication and background/resume behavior.
17. Unsupported app-lock behavior on Web/Linux: app remains accessible and Settings reports unavailable.
18. Controlled root-app teardown where practical.
19. Web create/edit/search → reload → browser restart persistence.
20. Web Markdown/backup download and re-import.

## Accessibility release check

Follow [`accessibility.md`](accessibility.md). At minimum verify:

- Keyboard traversal on desktop and Web.
- Browser focus visibility and common zoom/text-scale conditions.
- Screen-reader/semantics on representative mobile plus browser/desktop coverage where practical.
- Narrow/wide layouts.
- Dark/light themes.
- Reduced motion.
- Destructive confirmations.
- Note-color non-color selection cue and target size.
- Failure/status messages remain reachable/readable.

Document limitations instead of claiming certification.

## Platform compile and runtime checks

### Android

```bash
flutter build apk --release
flutter build appbundle --release
```

Before distribution verify package identity, 2.0.12/2012 version values, permissions/minimum SDK, signed artifact behavior, file picker, links, and supported authentication. Keep signing material outside Git.

### iOS / iPadOS

Host: macOS/Xcode.

```bash
flutter build ios --release --no-codesign
```

Distribution requires Apple signing/provisioning. Verify Face ID usage configuration and supported authentication on a representative device.

### Windows

```powershell
flutter build windows --release
```

Verify local storage, file picker/save, links, keyboard navigation, resize behavior, and Windows authentication on a capable system.

### macOS

```bash
flutter build macos --release
```

Distribution may require signing/notarization. Verify storage/file/link/authentication behavior on a representative macOS system.

### Linux

```bash
flutter build linux --release
```

Record distro/runtime assumptions. Verify storage, file picker/save, links, keyboard/resize behavior, and the expected unavailable app-lock state.

### Web

```bash
flutter test --platform chrome test/web/web_platform_smoke_test.dart
flutter build web --release
```

Deploy the **actual `build/web` output** to the intended host/origin and verify:

- App loads without missing worker/WASM errors.
- `sqlite3.wasm` is served as `application/wasm`.
- `drift_worker.js` and `sqlite3.wasm` remain reachable at the configured root-relative URIs.
- Create/edit/search works.
- Data survives reload and browser restart under normal storage settings.
- Markdown import/export and backup export/restore work.
- Oversized browser-selected files are rejected.
- App lock is visibly unavailable without blocking the app.
- External links/mail handlers behave as expected.
- Browser keyboard/focus/zoom/screen-reader behavior is checked.

For compatible hosts/browsers, cross-origin isolation can enable Drift's optimal OPFS-backed mode. If those headers are unavailable, verify/document the actual fallback storage mode rather than claiming OPFS.

Browser-local data is tied to browser/profile/origin and can be removed by site-data controls. Backups are the portable recovery path.

## GitHub Actions release matrix

The platform workflow verifies:

- Android release compile.
- Linux release compile.
- Windows release compile.
- macOS release compile.
- unsigned iOS release compile.
- Web Chrome smoke regression.
- Web release compile.

The release workflow additionally uploads Android/Linux/Windows/macOS/iOS-validation and Web outputs. Artifacts are evidence of build output, not store signing/runtime certification.

## Artifact naming

Examples:

```text
notenest-2.0.12-android.apk
notenest-2.0.12-windows-x64.zip
notenest-2.0.12-linux-x64.tar.gz
notenest-2.0.12-macos.zip
notenest-2.0.12-web.zip
```

Never label an unsigned/no-codesign artifact as store-ready.

## Checksums

Publish SHA-256 checksums for distributed archives/binaries.

Linux/macOS:

```bash
shasum -a 256 <artifact>
```

Windows PowerShell:

```powershell
Get-FileHash <artifact> -Algorithm SHA256
```

Checksums are integrity metadata, not a substitute for signing/authenticity.

## Web deployment headers

At minimum ensure your server emits the correct WebAssembly MIME type. Optional cross-origin isolation for supported Drift/OPFS operation normally involves compatible COOP/COEP configuration; validate it against your hosting/CDN requirements and any third-party resources before enabling it.

Do not add telemetry, remote note processing, or unrelated third-party scripts merely to host the static Web bundle without reviewing privacy/security documentation.

## Release notes

Use [`releases/2.0.12.md`](releases/2.0.12.md) as the candidate source. Final notes should state:

- User-facing changes/fixes.
- Supported **and actually verified** platforms.
- Browser storage/deployment limitations where relevant.
- Security/privacy changes without disclosing an unpatched vulnerability.
- Backup compatibility.
- Signing status.
- Artifact/checksum details.
- Known limitations.

Avoid “bug-free”, “perfectly secure”, or similar unsupported claims.

## Branch protection recommendation

For `main`, where repository/account settings permit:

- Require pull requests for non-emergency changes.
- Require quality/platform checks.
- Require current branches when practical.
- Require conversation resolution.
- Prevent force pushes/deletion.
- Restrict bypass permissions.

A solo-maintainer flow can preserve emergency maintenance without allowing accidental history rewrite.

## Git tag

Only after the **exact final release commit** passes the full checklist:

```bash
git tag -a v2.0.12 -m "NoteNest 2.0.12"
git push origin v2.0.12
```

Never move a published release tag. Publish a new patch version for post-release fixes.

## Final 2.0.12 release checklist

### Metadata/reproducibility

- [x] `pubspec.yaml` = `2.0.12+2012`.
- [x] Visible version = `2.0.12`.
- [x] Matching changelog/release notes exist.
- [x] Flutter 3.44.7 pin synchronized across workflows.
- [x] Six-platform source/bootstrap/build automation implemented.
- [x] Repository reference updated to 108 tracked files for cross-platform additions.
- [ ] Resolver-generated `pubspec.lock` committed and cataloged (issue #8).
- [ ] Final dependency installation enforces the committed lock.

### Quality/security

- [ ] Version sync passes on exact final candidate.
- [ ] Drift generation succeeds.
- [ ] Formatter passes.
- [ ] Analyzer passes.
- [ ] Flutter tests/coverage pass.
- [ ] Repository policy passes.
- [ ] 108-file reference check passes.
- [ ] Markdown-link scan passes.
- [ ] Secret scan passes.
- [ ] Dependency/security review complete.

### Platform automation

- [ ] Android release compile green.
- [ ] Linux release compile green.
- [ ] Windows release compile green.
- [ ] macOS release compile green.
- [ ] iOS no-codesign compile green.
- [ ] Chrome Web fallback smoke green.
- [ ] Web release compile green.

### Manual/runtime/accessibility

- [ ] Primary note/editor/lifecycle journeys verified.
- [ ] Native and browser import/export/size limits verified.
- [ ] Backup export/restore verified with fictional data.
- [ ] Supported app-lock targets verified.
- [ ] Web/Linux unavailable app-lock paths verified usable.
- [ ] Web persistence/reload/restart verified on intended deployment origin.
- [ ] Web MIME/worker/WASM serving verified.
- [ ] External links success/failure verified.
- [ ] Keyboard/screen-reader/large-text/zoom/themes/reduced-motion checks recorded.
- [ ] Runtime screenshots captured from verified builds.

### Distribution

- [ ] Signing status recorded.
- [ ] Final artifacts reviewed.
- [ ] SHA-256 checksums generated.
- [ ] Final release notes identify verified platform scope honestly.
- [ ] `v2.0.12` points to the exact fully verified commit.
