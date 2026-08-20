<div align="center">
  <img src="assets/branding/notenest_logo.svg" alt="NoteNest logo" width="112" height="112">

# NoteNest

**Your thoughts, safely nested.**

A private, offline-first notes app built with Flutter, Dart, Drift, and SQLite for **Android, iOS, Windows, macOS, Linux, and Web**.

**Current release-candidate target: 2.0.12 (`2.0.12+2012`)**

[![CI](https://github.com/sanskarIN/notenest/actions/workflows/ci.yml/badge.svg)](https://github.com/sanskarIN/notenest/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-sanskarIN-FFDD00?logo=buy-me-a-coffee&logoColor=000000)](https://buymeacoffee.com/sanskarIN)

**Made by the Sanskar**
</div>

---

## Release status

NoteNest `main` is a **2.0.12 release candidate**, not yet a claimed fully verified stable release.

The application now has source, runner bootstrap, platform fallbacks, browser persistence wiring, CI compile lanes, and release packaging for the complete Flutter target set: Android, iOS, Windows, macOS, Linux, and Web. “Supported project target” means the repository is implemented and automated for that platform; it does **not** mean every current 2.0.12 runtime/manual check has already completed successfully.

The package/visible/changelog/release-note versions and Flutter workflow pins are synchronized by `tool/check_version_sync.py`. The exhaustive repository map currently catalogs **108 tracked files** and is enforced by `tool/check_repository_reference.py`.

Stable `v2.0.12` remains blocked until the resolver-generated `pubspec.lock` tracked by issue #8 is committed with Flutter 3.44.7 and the exact resulting candidate passes the configured quality/security/six-platform builds plus documented manual accessibility/runtime/release checks.

See:

- [`CHANGELOG.md`](CHANGELOG.md)
- [`docs/releases/2.0.12.md`](docs/releases/2.0.12.md)
- [`docs/release.md`](docs/release.md)
- [`docs/repository-reference.md`](docs/repository-reference.md)
- [`what_changed.md`](what_changed.md)

## Why NoteNest?

NoteNest is designed for people who want a serious notes experience without requiring an account, project-operated cloud service, or permanent internet connection. Notes remain in local application/browser storage, search uses SQLite FTS5, edits autosave, prior content is preserved as snapshots, and users explicitly choose when to import/export files or open external project/support links.

The repository is production-oriented rather than a framework demo. It includes modular application code, validated storage/import boundaries, deterministic regression tests, cross-platform fallbacks, security/privacy documentation, GitHub automation, accessibility guidance, release procedures, and an engineering handoff.

## Screenshots

Verified runtime captures belong in [`docs/assets/screenshots/`](docs/assets/screenshots/). Until current-candidate captures are produced by release validation, the repository uses a clearly labeled illustrative reference rather than presenting a mockup as runtime evidence.

![Illustrative NoteNest layout reference](docs/assets/screenshots/layout-reference.svg)

## Features

### Notes and organization

- Create and edit local notes.
- Automatic local saving with debounced submission.
- Serialized editor writes so an older submitted autosave cannot overtake a newer one.
- Pin and favorite notes.
- Archive, trash, restore, permanently delete, or empty trash.
- Folders, normalized tags, and optional note colors.
- Collection/folder/tag filters with collection-scoped metadata.
- Switching collections clears stale filters from the previous collection.
- SQLite FTS5 full-text search.
- Collection-specific empty states avoid offering actions whose results would be hidden.

### Writing experience

- Distraction-free editor mode.
- Markdown-lite helpers for headings, emphasis, bullets, and checklists.
- Offset-zero prefix actions correctly target an empty first line.
- Material 3 typography and adjustable text scale.
- Immutable draft capture before each submitted save.
- Save-state feedback protected from stale completions.
- Version snapshots before changed persisted content.
- Version-history browser and restore.

### Import, export, and recovery

- Import UTF-8 Markdown, Markdown-like text, and text files.
- **Native targets:** use picker-provided cached paths and bounded incremental file streaming.
- **Web:** uses picker bytes/streams, validates picker-reported size, and re-validates actual received bytes before decoding.
- Markdown/text import ceiling: **16 MiB**.
- NoteNest JSON backup import ceiling: **64 MiB**.
- Strict UTF-8 decoding after bounds validation.
- Export individual notes as Markdown with NoteNest metadata.
- Cross-platform-safe Unicode filenames with Windows reserved-name/trailing-dot protection.
- Export notes and snapshots as validated human-readable JSON.
- Validate backup app identity, schema, field types, tags, IDs, relationships, UTC timestamps, timestamp order, lifecycle combinations, and 32-bit ARGB color values before restore writes.
- Conflict-safe restore keeps newer local revisions.
- Restore writes are transactional.

### Settings and onboarding reliability

- Light, dark, and system appearance modes.
- Adjustable text scale.
- Reduced-motion preference.
- Optional device-authentication app lock **where the platform/plugin supports it**.
- Unsupported app-lock targets remain usable and show the capability as unavailable rather than trapping the user behind an impossible unlock screen.
- Serialized preference writes and rollback after applicable persistence failures.
- Persistence-first onboarding.
- User-visible settings/onboarding persistence feedback.
- Root application teardown releases the owned settings controller and database.

### Privacy and security

- Core functionality is local and requires no NoteNest account.
- No required project-operated note sync, analytics, ads, tracking SDK, or production secret.
- No custom cryptography.
- App lock is UI access control, **not SQLite database encryption**.
- `local_auth` is used only where supported; Web and Linux currently treat app-lock device authentication as unavailable.
- Secrets/signing material are excluded from source control.
- Imports are bounded before decoding/structured processing.
- Backup data is validated before transactional writes.
- SQL search values are parameterized.
- Security policy and responsible-disclosure guidance are documented.

### Product quality

- Responsive layout for phones, tablets, desktop windows, and browser viewports.
- Bottom navigation on compact layouts and navigation rail on wider layouts.
- Keyboard- and semantics-friendly Material controls.
- 48 logical-pixel minimum custom color targets with visible non-color selected cues.
- Empty, loading, error, destructive-confirmation, save, and progress states.
- English-first localization structure.
- Centralized safe external-link service.
- Structured redacting diagnostic logger.

## Supported project targets

| Platform | Project target | Current platform design |
|---|---:|---|
| Android | ✅ Supported | Local Drift/SQLite, file import/export, responsive UI, supported device authentication. |
| iOS / iPadOS | ✅ Supported | Local Drift/SQLite, file import/export, Face ID usage configuration; distribution requires Apple signing. |
| Windows | ✅ Supported | Local Drift/SQLite, desktop-responsive UI, file import/export, supported Windows authentication. |
| macOS | ✅ Supported | Local Drift/SQLite, desktop-responsive UI, file import/export, supported macOS authentication. |
| Linux | ✅ Supported | Local Drift/SQLite, desktop-responsive UI and file import/export; app-lock device authentication is unavailable with current dependencies. |
| Web | ✅ Supported | Browser-local Drift SQLite via WASM/worker, browser file import/export and responsive UI; app-lock device authentication is unavailable. |

All six targets are included in platform automation. The current candidate still requires final completed CI/runtime/manual evidence before the table should be interpreted as a stable-release certification.

### Web persistence and hosting

The database factory uses Drift Web support with generated root assets:

- `sqlite3.wasm`
- `drift_worker.js`

`tool/bootstrap_platforms.py` downloads these from the **Drift 2.34.3** release, matching the project dependency, and refuses to proceed if the direct Drift pin changes without an explicit bootstrap review.

For deployment:

- Serve `sqlite3.wasm` with the correct WebAssembly MIME type (`application/wasm`).
- Serve the generated Flutter Web bundle and worker from the same deployment as expected by the root-relative configuration.
- Cross-origin isolation headers can enable Drift's optimal OPFS path on compatible hosts. Drift can use fallback browser storage when those headers are unavailable, so NoteNest does not require claiming every host has OPFS.
- Browser storage is local to the browser/profile/origin and can be cleared by browser/site-data controls. Use NoteNest JSON backup export for portable recovery.

## Technology stack

- **UI:** Flutter + Material 3
- **Language:** Dart
- **Persistence:** Drift + SQLite; SQLite WASM/worker on Web
- **Search:** SQLite FTS5
- **Settings:** `shared_preferences`
- **Device app lock:** `local_auth` where supported, safe unavailable fallback elsewhere
- **File selection/export:** `file_picker`
- **External links:** `url_launcher` behind `ExternalLinkService`
- **Identifiers:** UUID v7
- **Testing:** `flutter_test`, in-memory Drift/SQLite tests, Chrome Web smoke regression, injectable service/store boundaries
- **Automation:** GitHub Actions + Dependabot + repository Python quality tools

## Quick start

### 1. Install prerequisites

Install Flutter **3.44.7** and the host prerequisites for the target you intend to build.

```bash
flutter --version
flutter doctor -v
```

Full setup instructions: [`docs/setup.md`](docs/setup.md).

### 2. Clone

```bash
git clone https://github.com/sanskarIN/notenest.git
cd notenest
```

For local project commits:

```bash
git config user.email "sanskarin@outlook.in"
```

### 3. Verify version/toolchain metadata

```bash
python tool/check_version_sync.py
```

This verifies package/UI/changelog/release-note version synchronization, `.flutter-version`, and the Flutter pins in quality/platform/release workflows.

### 4. Generate all platform runners

```bash
python tool/bootstrap_platforms.py
```

On Windows:

```powershell
py tool/bootstrap_platforms.py
```

The bootstrap generates Android, iOS, Linux, macOS, Windows, and Web runners. It applies and verifies the Android/iOS authentication requirements and obtains/verifies the Web database runtime assets matching Drift 2.34.3. Network access is therefore required during bootstrap for those Web assets.

### 5. Resolve dependencies and generate Drift code

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Before stable 2.0.12 release work, generate and commit the real `pubspec.lock` with this pinned toolchain as required by issue #8; do not hand-author the lockfile.

### 6. Run

```bash
flutter devices
flutter run -d <device-id>
```

For a browser target, for example:

```bash
flutter run -d chrome
```

## Development workflow

```bash
python tool/check_version_sync.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
flutter run
```

For continuous Drift generation:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

See [`docs/development.md`](docs/development.md).

## Testing and quality gate

Primary test/quality commands:

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

Web-specific boundary regression:

```bash
flutter test --platform chrome test/web/web_platform_smoke_test.dart
```

Quality tools:

- `tool/check_version_sync.py` — app/release metadata plus exact Flutter workflow-pin synchronization.
- `tool/check_repo.py` — required repository/documentation/automation and source/generated/ignore policy.
- `tool/check_repository_reference.py` — exhaustive tracked-file documentation contract.
- `tool/check_markdown_links.py` — deterministic repository-local Markdown links.
- `tool/security_scan.py` — lightweight tracked credential-pattern scan.

See [`docs/testing.md`](docs/testing.md).

## Build and release

After bootstrap/code generation, target commands include:

```bash
flutter build apk --release
flutter build appbundle --release
flutter build windows --release
flutter build linux --release
flutter build macos --release
flutter build ios --release --no-codesign
flutter build web --release
```

Only run native commands supported by the host OS. Store/native distribution additionally requires signing identities that must stay outside Git. Web deployment must preserve the generated WASM/worker assets and correct serving behavior.

GitHub's platform-build workflow compiles all six targets, and the release workflow uploads a Web bundle alongside native validation/package artifacts.

Candidate details:

- [`docs/releases/2.0.12.md`](docs/releases/2.0.12.md)
- [`docs/release.md`](docs/release.md)

Do not create `v2.0.12` until the exact final commit passes all documented automated/platform/manual checks.

## Architecture overview

```text
lib/
├── app/                 # Composition root and application controllers
├── core/                # Constants, errors, logging, theme, pure/platform utilities
├── data/
│   ├── database/        # Drift schema, SQLite/FTS and Web database configuration
│   └── repositories/    # Notes, settings and backup persistence
├── domain/              # UI-independent filter/value models
├── features/            # About, home, notes, onboarding, settings
├── services/            # Cross-platform file transfer, app lock, external links
├── widgets/             # Reusable presentation controls
└── main.dart            # Application entry point
```

[`AppDependencies`](lib/app/app_dependencies.dart) owns composition and final settings/database cleanup. Repositories isolate storage invariants, services isolate plugin/platform boundaries, controllers own feature/application state, and conditional imports prevent browser builds from importing native-only filesystem/authentication implementation code.

Read [`docs/architecture.md`](docs/architecture.md) and [`docs/adr/`](docs/adr/).

## Data model

Drift schema version **1** contains:

- `notes`: current note state and organization/lifecycle metadata.
- `note_versions`: pre-change snapshots tied to a note with cascade deletion.
- `notes_fts`: FTS5 external-content index maintained by SQLite triggers.

On native targets Drift uses the normal platform SQLite path. On Web, Drift uses the generated compatible SQLite WASM/worker configuration and browser-local storage selection.

**Application version 2.0.12 does not mean database schema version 2.** These are independent version domains.

## Backup format

Backup schema versioning is also independent. Restore validates the full payload before writes and preserves newer local note revisions. JSON backup export/import is the portable recovery path across native installations and browser origins/profiles.

See [`docs/architecture.md`](docs/architecture.md), [`docs/testing.md`](docs/testing.md), and [`SECURITY.md`](SECURITY.md).

## Privacy

Core NoteNest note data remains local to the installed application or browser storage. The app does not require a NoteNest account or upload note contents to a project-operated server. File import/export and external URI launching happen only after explicit user actions.

The Web build necessarily downloads its static application bundle/SQLite runtime assets from whichever site hosts it. That delivery is different from uploading users' note contents; NoteNest has no project-operated note-sync path in core functionality.

Read [`PRIVACY.md`](PRIVACY.md) before distributing a modified build, especially if adding networking, telemetry, sync, accounts, AI processing, ads, or third-party data services.

## Security

- Never commit signing keys, API keys, tokens, passwords, private endpoints, `.env` secrets, or real user databases/backups.
- Treat imports/backups as untrusted bounded input.
- Validate backup structure before database writes.
- Keep user search values parameterized.
- Keep export filenames cross-platform/Unicode safe.
- Treat preference persistence failure as real storage failure.
- Use `ExternalLinkService` instead of direct launcher calls from feature widgets.
- Use OS authentication where supported rather than storing custom biometric/password credentials.
- Do not invent a browser app-lock password scheme merely to claim feature parity; unavailable platforms degrade safely.
- Report vulnerabilities privately according to [`SECURITY.md`](SECURITY.md).

## Accessibility

The project aims for WCAG-oriented inclusive behavior rather than claiming formal certification. It uses semantic Material controls, tooltips, scalable typography, theme-aware colors, touch-friendly custom controls, explicit non-color selection cues, reduced motion, responsive layouts, and safe visible failure states.

Manual screen-reader, keyboard, large-text, browser zoom/viewport, and representative-device checks remain release requirements. See [`docs/accessibility.md`](docs/accessibility.md).

## Performance

Note discovery uses SQLite FTS5. Editor/settings persistence has explicit async ordering. Native imports stream within limits; Web imports validate reported and actual picker data before decoding. Browser persistence performance depends on the storage backend available to Drift on the deployed origin/browser.

See [`docs/performance.md`](docs/performance.md).

## Project documentation

- [`docs/setup.md`](docs/setup.md) — tool installation and clean-clone setup
- [`docs/development.md`](docs/development.md) — development workflow/invariants
- [`docs/architecture.md`](docs/architecture.md) — system design and dependency boundaries
- [`docs/testing.md`](docs/testing.md) — regression strategy and quality gates
- [`docs/accessibility.md`](docs/accessibility.md) — accessibility requirements/manual checks
- [`docs/performance.md`](docs/performance.md) — performance budgets/profiling
- [`docs/release.md`](docs/release.md) — packaging/release/deployment process
- [`docs/releases/2.0.12.md`](docs/releases/2.0.12.md) — current release candidate
- [`docs/repository-reference.md`](docs/repository-reference.md) — exhaustive 108-file responsibility catalog
- [`docs/troubleshooting.md`](docs/troubleshooting.md) — setup/build/runtime recovery
- [`docs/adr/`](docs/adr/) — architecture decision records
- [`what_changed.md`](what_changed.md) — exact engineering/verification handoff

## Contributing

Contributions are welcome. Read [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) before opening a pull request. Small, reviewable Conventional Commits are preferred.

## Roadmap

See [`ROADMAP.md`](ROADMAP.md). Future features should remain coherent with NoteNest's local-first privacy model.

## Support and contact

- Business: [sanskarin@outlook.in](mailto:sanskarin@outlook.in)
- Business: [sanskarin.business@gmail.com](mailto:sanskarin.business@gmail.com)
- Support: [supportramsandesh@gmail.com](mailto:supportramsandesh@gmail.com)
- GitHub: <https://github.com/sanskarIN>
- Repository: <https://github.com/sanskarIN/notenest>
- Buy Me a Coffee: <https://buymeacoffee.com/sanskarIN>

See [`SUPPORT.md`](SUPPORT.md).

## Funding

NoteNest remains fully usable without donating. If the project helps you and you want to support continued work:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-sanskarIN-FFDD00?logo=buy-me-a-coffee&logoColor=000000)](https://buymeacoffee.com/sanskarIN)

## License

NoteNest is open source under the [MIT License](LICENSE).

Copyright © 2026 Sanskar.

---

<div align="center">
  <strong>Made by the Sanskar</strong>
</div>
