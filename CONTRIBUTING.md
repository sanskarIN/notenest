# Contributing to NoteNest

Thank you for improving NoteNest. The project values small, understandable changes that preserve its local-first privacy model and remain maintainable across **Android, iOS/iPadOS, Windows, macOS, Linux, and Web**.

## Before you start

1. Read the [Code of Conduct](CODE_OF_CONDUCT.md).
2. Read the [Security Policy](SECURITY.md); do not publicly disclose an unpatched vulnerability.
3. Check existing issues/PRs.
4. Discuss large architecture/storage/platform changes before writing a large patch.

## Development environment

Follow [docs/setup.md](docs/setup.md), then:

```bash
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Project commit identity:

```bash
git config user.email "sanskarin@outlook.in"
```

Never commit signing credentials, tokens, secret `.env` values, real databases/backups, personal note exports, or browser storage dumps.

## Branches

```bash
git switch main
git pull --ff-only
git switch -c feat/short-description
```

Common prefixes: `feat/`, `fix/`, `docs/`, `test/`, `refactor/`, `chore/`.

## Code standards

- Follow Dart/Flutter idioms and strict analyzer policy.
- Keep storage details out of widgets.
- Keep UI concerns out of repositories.
- Keep platform/plugin behavior behind services or conditional implementations.
- Do not import native-only APIs such as `dart:io` from code reachable by Web unless protected by conditional compilation.
- Treat unsupported platform capabilities as explicit states, not uncaught plugin errors.
- Validate untrusted imports before persistence.
- Never add custom cryptography or a custom password/biometric system simply to claim feature parity.
- Preserve accessibility semantics, keyboard/browser focus, contrast, text/zoom scaling, touch targets, and reduced motion.
- Do not add required accounts, note sync, analytics, tracking, or advertising to core local functionality without an explicit architecture/privacy change.

## Six-platform review rule

Every code/dependency change must consider:

- Android
- iOS/iPadOS
- Windows
- macOS
- Linux
- Web

A package being importable from Dart does not prove that every Flutter platform implementation exists. Document safe fallback behavior where capability differs.

For Web-specific changes, consider browser storage, file picker/download semantics, native-only imports, worker/WASM serving, keyboard/focus, browser zoom, and deployment-origin behavior.

## Database changes

Any released schema modification must:

1. Increment `AppDatabase.schemaVersion`.
2. Add deterministic migration logic.
3. Preserve representative existing fictional data.
4. Update FTS infrastructure if indexed columns change.
5. Add migration tests from the previous released schema.
6. Verify native SQLite and Web SQLite behavior.
7. Review backup compatibility independently.
8. Update architecture/changelog/release docs.

Never silently reinterpret a released column.

## Generated platform/code artifacts

Drift `*.g.dart` files and generated Flutter runner trees are intentionally untracked.

Generate:

```bash
python tool/bootstrap_platforms.py
dart run build_runner build --delete-conflicting-outputs
```

Bootstrap also obtains the Web `sqlite3.wasm` / `drift_worker.js` pair matching the reviewed Drift version. Do not substitute arbitrary assets from another Drift release.

## Dependency changes

Before adding/updating a package:

- Check maintenance status/license.
- Check Flutter/Dart requirements.
- Check implementations on all six project targets.
- Review permissions/network/privacy/storage behavior.
- Review Web compilation and hosting/runtime implications.
- Rebuild every affected target.

When changing Drift, review/update the Web runtime asset pairing in the same change.

The stable 2.0.12 baseline still requires the genuine Flutter-3.44.7-generated `pubspec.lock` tracked by issue #8; never hand-write lockfile hashes/versions.

## Tests

Choose the lowest reliable regression layer:

- pure/core unit tests;
- repository/database tests;
- widget/accessibility tests;
- Chrome Web platform-boundary tests;
- platform integration/runtime tests where required.

Full deterministic gate:

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

Web boundary verification:

```bash
python tool/bootstrap_platforms.py
flutter test --platform chrome test/web/web_platform_smoke_test.dart
flutter build web --release
```

Run applicable native release/debug builds described in [docs/release.md](docs/release.md).

Never claim a platform/check passed if you did not run it.

## Commits

Use meaningful atomic Conventional Commits, for example:

```text
feat: add note sort preference
fix: keep web lock gate usable
test: cover browser platform fallback
docs: document web persistence
ci: verify web release build
```

Do not create empty/meaningless churn solely to increase commit count.

## Pull requests

A good PR:

- Has one clear purpose.
- Explains user-visible/platform behavior.
- Lists affected targets and safe unavailable paths.
- Includes regression tests where practical.
- Includes verified runtime screenshots for UI changes when practical and privacy-safe.
- Records accessibility/privacy/security impact.
- Updates documentation/changelog/handoff as needed.
- Has no knowingly unreported formatter/analyzer/test/build failures.

Use the repository PR template.

## Documentation discipline

Documentation is part of the product. Commands/platform claims must match source/automation.

When changing:

- bootstrap/build setup → README + setup + release docs;
- platform boundary → architecture/security/privacy/testing docs as relevant;
- dependency/toolchain → lockfile/version/release docs;
- tracked file set → repository reference;
- current checkpoint → `what_changed.md`.

All **108 current tracked paths** are cataloged exactly once in [docs/repository-reference.md](docs/repository-reference.md). Run:

```bash
python tool/check_repository_reference.py
```

## Reporting bugs

Use the bug report template and include:

- version/commit;
- Flutter version where relevant;
- platform;
- OS/device or browser/version/origin context;
- fictional reproduction steps;
- expected/actual behavior;
- redacted minimal logs.

Never publish a real note database, backup, or browser storage contents.

## Feature requests

Explain the user problem before prescribing an implementation. Requests should preserve local-first, accessible, non-intrusive behavior and explicitly consider the six-platform impact.

## License

Contributions may be distributed under the repository's [MIT License](LICENSE).
