## Summary

Describe the problem and the focused change made to solve it.

## User-visible behavior

Explain what changes for a NoteNest user. If there is no user-visible change, say so.

## Platform impact

Review all NoteNest targets: Android, iOS/iPadOS, Windows, macOS, Linux, and Web.

State which targets are affected and why. For platform/plugin/file/database changes, explain the behavior on unsupported targets instead of assuming universal capability.

## Verification

List the exact commands/checks run, for example:

```text
python tool/check_version_sync.py
python tool/bootstrap_platforms.py
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter test --platform chrome test/web/web_platform_smoke_test.dart
python tool/check_repo.py
python tool/check_repository_reference.py
python tool/check_markdown_links.py
python tool/security_scan.py
flutter build <platform> ...
flutter build web --release
```

Do not mark a command/platform as passing if it was not run.

## Screenshots / recordings

For UI changes, attach verified runtime captures when practical. Redact private note content/browser storage. For non-UI changes, write `Not applicable`.

## Privacy and security impact

- What data/storage/permissions/import/export/hosting behavior changed?
- Is any data newly transmitted off-device/browser?
- Did a dependency, native permission, browser capability, or deployment header change?
- Does `SECURITY.md` or `PRIVACY.md` need an update?

## Accessibility impact

Describe keyboard, browser focus/zoom, screen-reader/semantics, text scaling, reduced motion, color/status, touch targets, and compact/wide responsive behavior relevant to the change.

## Database / backup compatibility

If no database or backup format changed, write `Not applicable`.

If changed, document:

- Schema version/migration path.
- Native + Web database impact.
- Migration tests.
- FTS changes.
- Backup schema compatibility/conversion.
- Rollback/recovery considerations.

## Dependency / generated platform impact

For dependency/platform changes document:

- Flutter SDK compatibility.
- All six target implementations/capabilities.
- `pubspec.lock` update status when the lockfile baseline exists.
- Drift worker/WASM pairing if `drift` changed.
- Required bootstrap/workflow/release documentation changes.

## Checklist

- [ ] The change has one clear purpose and no unrelated churn.
- [ ] I did not commit secrets, signing material, real databases/backups, personal note content, or browser storage dumps.
- [ ] Generated Drift/platform runner files are not tracked accidentally.
- [ ] Formatting passes.
- [ ] Static analysis passes.
- [ ] Relevant automated tests pass.
- [ ] New/fixed behavior has regression coverage where practical.
- [ ] Web-reachable source does not accidentally import native-only APIs such as `dart:io`.
- [ ] Unsupported plugin/capability paths fail safely and keep the app usable.
- [ ] Relevant Android/iOS/Windows/macOS/Linux/Web builds/runtime checks were considered and accurately recorded.
- [ ] Destructive data behavior is clear and safe.
- [ ] UI changes work at compact and wide sizes, including browser viewports where applicable.
- [ ] UI changes remain usable with increased text/browser zoom.
- [ ] Icon/custom actions have accessible purpose/semantics.
- [ ] Documentation is updated where behavior/setup/platform support changed.
- [ ] `docs/repository-reference.md` reflects every tracked file added, removed, or renamed.
- [ ] `python tool/check_repository_reference.py` passes.
- [ ] `CHANGELOG.md` is updated for user-visible/release-relevant changes.
- [ ] `what_changed.md` is updated when this work changes the continuation checkpoint.
