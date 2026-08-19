# NoteNest Release Guide

This guide describes how to prepare, verify, package, and publish a NoteNest release without committing signing secrets or claiming checks that were not run.

Current release-candidate target: **2.0.12** (`2.0.12+2012`).

## Release principles

- Release from a clean, reviewed commit.
- Keep package version, visible app version, changelog, release notes, and documentation synchronized.
- Use the Flutter SDK version pinned by `.flutter-version`; the current NoteNest 2.0.12 release-candidate pin is **3.44.7**.
- Keep the exact Flutter version in CI, platform-build, and release workflows synchronized with `.flutter-version`; the version-sync gate enforces this relationship.
- Generate native runners using the documented script and treat a bootstrap patch-verification failure as a release blocker until the template change is reviewed.
- Generate Drift code using the pinned project dependencies.
- Run the full quality gate before packaging.
- Build each native target on a supported host OS.
- Keep signing credentials outside Git.
- Record exact results and limitations in `what_changed.md`.
- Do not publish an artifact if a blocker/critical data-loss defect is known.

## Versioning

`pubspec.yaml` uses Flutter's version format:

```yaml
version: 2.0.12+2012
```

- `2.0.12` is the user-facing semantic version.
- `+2012` is the platform build number for this release candidate.
- `AppStrings.version` must be exactly `2.0.12`.
- `CHANGELOG.md` must contain a `## [2.0.12]` section.
- `docs/releases/2.0.12.md` must exist and contain the exact package/visible version values.
- `.flutter-version` must be an exact semantic SDK pin and every Flutter GitHub Actions workflow pin must match it.

The repository enforces these relationships with:

```bash
python tool/check_version_sync.py
```

Before a future release:

1. Choose the semantic version.
2. Increment the platform build number as required.
3. Update `pubspec.yaml`.
4. Update `AppStrings.version`.
5. Add/update the matching changelog section.
6. Add `docs/releases/<version>.md`.
7. Update `.flutter-version` and every Flutter workflow together if the SDK changes.
8. Run `python tool/check_version_sync.py` before other release work.
9. Confirm `README.md`, privacy/security docs, roadmap, and handoff still match behavior.

## Clean checkout verification

Prefer a fresh clone or a clean worktree:

```bash
git status --short
git clean -ndx
```

Review before using any destructive clean command. Verify the SDK first:

```bash
flutter --version
```

For the current 2.0.12 release candidate this must report Flutter **3.44.7**. Then verify version metadata before generating environment-dependent files:

```bash
python tool/check_version_sync.py
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

`tool/bootstrap_platforms.py` validates that the required Android authentication/minimum-SDK/AppCompat configuration and the iOS Face ID usage description were actually applied. If a future Flutter template changes those paths, the script is expected to fail instead of silently producing an incompletely patched runner.

## Quality gate

Run:

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

`tool/check_version_sync.py` verifies package/UI/changelog/release-note synchronization and Flutter workflow pin synchronization. `tool/check_repo.py` enforces the required repository/documentation/automation baseline. `tool/check_repository_reference.py` proves that every tracked path is represented exactly once in the exhaustive repository catalog. `tool/check_markdown_links.py` validates repository-local links in tracked Markdown without depending on live third-party sites. Run `flutter doctor -v` and record relevant host/toolchain versions for reproducibility.

## Manual product smoke test

Use fictional data and exercise:

1. Fresh first run/onboarding.
2. Create, edit, autosave, rapidly edit again, then close/reopen the note to confirm the newest draft wins.
3. Place the caret at offset zero in a note that starts with an empty line and verify Heading/Bullet/Checklist formatting applies to that first line.
4. Folder, tags, color, pin, and favorite.
5. Verify note-color selection has a visible selected cue and usable touch target.
6. Full-text search.
7. Archive/unarchive.
8. Trash/restore.
9. Permanent delete confirmation.
10. Version snapshot/restore.
11. Markdown import/export, including a title that would be a reserved/invalid filename on Windows.
12. Oversized Markdown/text import rejection beyond 16 MiB.
13. JSON backup export and conflict-safe restore.
14. Oversized JSON backup rejection beyond 64 MiB.
15. Theme modes.
16. Large text.
17. Reduced motion.
18. Repository/funding/business/support email links from About.
19. Release-updates link from Settings.
20. External-link failure feedback on a platform/device where an external handler is unavailable.
21. Optional app lock on a supported device and safe failure on unsupported targets.
22. Controlled root-app teardown where practical to confirm owned settings/database resources dispose without lifecycle errors.

Do not use real personal notes for release testing.

## Accessibility release check

Follow the matrix in [`accessibility.md`](accessibility.md). At minimum:

- Keyboard traversal on a desktop build.
- Screen-reader/semantics review on at least one mobile build.
- 200% or maximum reasonable text scaling review for critical screens.
- Narrow and wide window/device layouts.
- Dark and light themes.
- Reduced-motion setting.
- Destructive action labels/confirmations.
- Editor color selection must expose a non-color selected cue and comfortable target.
- External-link failure messages must remain reachable/readable.

Document known non-blocking gaps honestly.

## Android

Host: Windows, macOS, or Linux with Android toolchain supported by the pinned Flutter version.

Compile checks:

```bash
flutter build apk --release
flutter build appbundle --release
```

For store distribution, configure signing outside source control. Keep keystore files/passwords and `key.properties` out of Git.

Before publishing:

- Verify application ID/package identity.
- Verify version is `2.0.12` and build number is `2012`.
- Verify minimum/target SDK values from generated/current Android files.
- Review requested permissions.
- Test the signed artifact on a representative device.
- Verify optional local authentication behavior.
- Verify file-picker and external-link behavior.

## Windows

Host: Windows with supported Visual Studio C++ desktop tooling.

```powershell
flutter build windows --release
```

The output directory is under `build/windows/.../Release` according to the current Flutter generator/toolchain.

If creating an installer/package later, document the packaging tool and signing process separately. Do not commit code-signing private keys.

## Linux

Host: Linux with Flutter desktop native prerequisites.

```bash
flutter build linux --release
```

Distribution packaging varies by target distro/package format. A release artifact should state what runtime/library assumptions it has rather than implying one binary works identically on every Linux distribution.

## macOS

Host: macOS/Xcode.

```bash
flutter build macos --release
```

Distribution outside local testing may require Apple signing/notarization. Keep certificates/private credentials out of the repository.

## iOS

Host: macOS/Xcode.

Compile validation without signing:

```bash
flutter build ios --release --no-codesign
```

A distributable archive requires Apple developer signing/provisioning. Verify the Face ID usage description remains present when optional app lock is enabled by platform configuration.

## Release artifacts

Artifacts should be named clearly with product, version, and platform/architecture where meaningful.

Example naming conventions for 2.0.12:

```text
notenest-2.0.12-android.apk
notenest-2.0.12-windows-x64.zip
notenest-2.0.12-linux-x64.tar.gz
notenest-2.0.12-macos.zip
```

Do not rename an unsigned/no-codesign validation artifact in a way that suggests it is store-ready.

## Checksums

For downloadable archives/binaries, publish SHA-256 checksums generated from the final artifacts.

Linux/macOS:

```bash
shasum -a 256 <artifact>
```

Windows PowerShell:

```powershell
Get-FileHash <artifact> -Algorithm SHA256
```

Checksums detect accidental corruption/download mismatch; they are not a replacement for code signing.

## Git tag

After the exact release commit has passed required checks:

```bash
git tag -a v2.0.12 -m "NoteNest 2.0.12"
git push origin v2.0.12
```

Do not move a published release tag to a different commit. If a released version has a problem, publish a new patch version.

## GitHub release notes

Use [`releases/2.0.12.md`](releases/2.0.12.md) as the release-candidate source. Final release notes should include:

- User-facing additions/changes/fixes.
- Security/privacy changes without prematurely disclosing an unpatched vulnerability.
- Migration/backup compatibility notes.
- Supported/verified platforms.
- Known limitations.
- Upgrade instructions if needed.
- Artifact checksums/signing status.
- Link to full `CHANGELOG.md`.

Avoid marketing claims such as “bug-free” or “fully secure.” State what was actually verified.

## Release workflow automation

GitHub Actions generates compile-validation artifacts for supported targets. The workflow uses the same exact Flutter SDK version as the project pin so a tagged build cannot silently move to a newer stable SDK. The separate platform-build workflow is also path-filtered for bundled `assets/**`, source, build metadata, and runner-bootstrap changes so asset-only changes cannot bypass compile verification.

Automated artifacts still require review. Store signing secrets should be configured only in appropriate protected CI secrets/environments and only when a distribution workflow is intentionally added. The project does not embed any real release signing secret.

## Branch protection recommendation

For `main`, enable a branch ruleset/protection rule that, where available for the repository/account plan:

- Requires pull requests for non-emergency changes.
- Requires the CI quality status check.
- Requires branches to be up to date before merge when practical.
- Prevents force pushes/deletion.
- Requires conversation resolution.
- Restricts bypass permissions appropriately.

If a solo-maintainer workflow needs direct maintenance pushes, choose rules that preserve practical recovery while still preventing accidental history rewrite.

## Final 2.0.12 release checklist

- [x] `pubspec.yaml` set to `2.0.12+2012`.
- [x] `AppStrings.version` set to `2.0.12`.
- [x] Matching changelog section prepared.
- [x] Matching `docs/releases/2.0.12.md` prepared.
- [x] Version/toolchain synchronization checker added to CI.
- [x] Repository-reference checker added to CI.
- [x] Native bootstrap now verifies required platform patches instead of silently accepting template drift.
- [x] Platform-build workflow includes bundled asset changes in its verification paths.
- [ ] `python tool/check_version_sync.py` passes on clean checkout/CI.
- [ ] `.flutter-version` matches CI/platform/release workflow Flutter versions on the verified candidate.
- [ ] `python tool/check_repository_reference.py` passes on the exact candidate.
- [ ] `flutter --version` matches the project pin on verification hosts.
- [ ] `what_changed.md` finalized for 2.0.12 verification results.
- [ ] Clean checkout/setup succeeds.
- [ ] Drift generation succeeds.
- [ ] Formatter passes.
- [ ] Analyzer passes.
- [ ] Tests pass.
- [ ] Repository policy scan passes.
- [ ] Markdown local-link scan passes.
- [ ] Secret scan passes.
- [ ] Dependency/security review complete.
- [ ] Android build verified.
- [ ] Windows build verified on Windows.
- [ ] Linux build verified on Linux.
- [ ] macOS build verified on macOS.
- [ ] iOS no-codesign compile verified on macOS.
- [ ] Manual primary journeys verified.
- [ ] Serialized autosave final-draft behavior manually verified.
- [ ] First-line editor formatting boundary manually smoke-tested.
- [ ] Root dependency teardown lifecycle manually/automatically verified where practical.
- [ ] Bounded oversized import rejection manually verified through real picker/provider behavior.
- [ ] External-link success/failure paths verified on representative targets.
- [ ] Accessibility checks recorded.
- [ ] Privacy/security documentation matches build.
- [ ] Runtime screenshots captured from verified builds.
- [ ] Signing status clearly recorded.
- [ ] Release notes prepared from the candidate notes.
- [ ] Tag points to exact verified commit.
- [ ] Checksums generated for distributed artifacts.
