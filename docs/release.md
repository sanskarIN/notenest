# NoteNest Release Guide

This guide describes how to prepare, verify, package, and publish a NoteNest release without committing signing secrets or claiming checks that were not run.

## Release principles

- Release from a clean, reviewed commit.
- Keep version, changelog, and documentation synchronized.
- Use the Flutter SDK version pinned by `.flutter-version`; the current NoteNest 1.0.0 release-candidate pin is **3.44.7**.
- Keep the exact Flutter version in CI, platform-build, and release workflows synchronized with `.flutter-version`.
- Generate native runners using the documented script.
- Generate Drift code using the pinned project dependencies.
- Run the full quality gate before packaging.
- Build each native target on a supported host OS.
- Keep signing credentials outside Git.
- Record exact results and limitations in `what_changed.md`.
- Do not publish an artifact if a blocker/critical data-loss defect is known.

## Versioning

`pubspec.yaml` uses Flutter's version format:

```yaml
version: 1.0.0+1
```

- `1.0.0` is the user-facing semantic version.
- `+1` is the build number used by platforms that require an incrementing integer.

Before release:

1. Choose the semantic version.
2. Increment the build number as required.
3. Move relevant `CHANGELOG.md` entries from `Unreleased` into a dated release section.
4. Update any visible version constant used by the About UI.
5. Confirm `README.md`, privacy/security docs, and roadmap still match behavior.
6. Confirm `.flutter-version` and every Flutter GitHub Actions workflow use the same SDK version.

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

For the current 1.0.0 release candidate this must report Flutter **3.44.7**. Then generate environment-dependent files:

```bash
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Quality gate

Run:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
python tool/check_repo.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

`tool/check_markdown_links.py` validates repository-local links in tracked Markdown without depending on live third-party sites. Run `flutter doctor -v` and record relevant host/toolchain versions for reproducibility.

## Manual product smoke test

Use fictional data and exercise:

1. Fresh first run/onboarding.
2. Create, edit, autosave, rapidly edit again, then close/reopen the note to confirm the newest draft wins.
3. Folder, tags, color, pin, and favorite.
4. Verify note-color selection has a visible selected cue and usable touch target.
5. Full-text search.
6. Archive/unarchive.
7. Trash/restore.
8. Permanent delete confirmation.
9. Version snapshot/restore.
10. Markdown import/export, including a title that would be a reserved/invalid filename on Windows.
11. Oversized Markdown/text import rejection beyond 16 MiB.
12. JSON backup export and conflict-safe restore.
13. Oversized JSON backup rejection beyond 64 MiB.
14. Theme modes.
15. Large text.
16. Reduced motion.
17. Settings/About links.
18. Optional app lock on a supported device and safe failure on unsupported targets.

Do not use real personal notes for release testing.

## Accessibility release check

Follow the matrix in [`docs/accessibility.md`](accessibility.md). At minimum:

- Keyboard traversal on a desktop build.
- Screen-reader/semantics review on at least one mobile build.
- 200% or maximum reasonable text scaling review for critical screens.
- Narrow and wide window/device layouts.
- Dark and light themes.
- Reduced-motion setting.
- Destructive action labels/confirmations.
- Editor color selection must expose a non-color selected cue and comfortable target.

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
- Verify version/build number.
- Verify minimum/target SDK values from generated/current Android files.
- Review requested permissions.
- Test the signed artifact on a representative device.
- Verify optional local authentication behavior.

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

Artifacts should be named clearly with:

- Product.
- Version.
- Platform/architecture where meaningful.

Example naming conventions:

```text
notenest-1.0.0-android.apk
notenest-1.0.0-windows-x64.zip
notenest-1.0.0-linux-x64.tar.gz
notenest-1.0.0-macos.zip
```

Do not rename an unsigned/no-codesign validation artifact in a way that suggests it is store-ready.

## Checksums

For downloadable archives/binaries, publish SHA-256 checksums generated from the final artifacts. Examples:

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

After the release commit has passed required checks:

```bash
git tag -a v1.0.0 -m "NoteNest 1.0.0"
git push origin v1.0.0
```

Do not move a published release tag to a different commit. If a released version has a problem, publish a new patch version.

## GitHub release notes

Release notes should include:

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

GitHub Actions generates compile-validation artifacts for supported targets. The workflow uses the same exact Flutter SDK version as the project pin so a tagged build cannot silently move to a newer stable SDK.

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

## Final release checklist

- [ ] Version/build number updated.
- [ ] `AppStrings.version` matches.
- [ ] `.flutter-version` matches CI/platform/release workflow Flutter versions.
- [ ] `flutter --version` matches the project pin on verification hosts.
- [ ] Changelog release section dated.
- [ ] `what_changed.md` updated.
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
- [ ] Oversized import rejection manually verified where picker integration is supported.
- [ ] Accessibility checks recorded.
- [ ] Privacy/security documentation matches build.
- [ ] Runtime screenshots captured from verified builds.
- [ ] Signing status clearly recorded.
- [ ] Release notes prepared.
- [ ] Tag points to exact verified commit.
- [ ] Checksums generated for distributed artifacts.
