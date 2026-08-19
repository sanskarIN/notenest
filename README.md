<div align="center">
  <img src="assets/branding/notenest_logo.svg" alt="NoteNest logo" width="112" height="112">

# NoteNest

**Your thoughts, safely nested.**

A polished, private, offline-first notes app built with Flutter, Dart, Drift, and SQLite.

[![CI](https://github.com/sanskarIN/notenest/actions/workflows/ci.yml/badge.svg)](https://github.com/sanskarIN/notenest/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-sanskarIN-FFDD00?logo=buy-me-a-coffee&logoColor=000000)](https://buymeacoffee.com/sanskarIN)

**Made by the Sanskar**
</div>

---

## Why NoteNest?

NoteNest is designed for people who want a serious notes experience without needing an account, cloud service, or permanent internet connection. Notes live in a local Drift/SQLite database, search uses SQLite FTS5, edits autosave, earlier content is preserved as snapshots, and users can explicitly export or restore their own data.

The repository is intentionally structured as a production-oriented portfolio project rather than a framework demo. It includes modular application code, validation, tests, security and privacy documentation, GitHub automation, accessibility guidance, release procedures, and a detailed continuation log in [`what_changed.md`](what_changed.md).

## Screenshots

Real device captures belong in [`docs/assets/screenshots/`](docs/assets/screenshots/). Until a Flutter-enabled build environment produces verified captures, the repository uses a clearly labeled illustrative layout reference rather than presenting a mockup as a real screenshot.

![Illustrative NoteNest layout reference](docs/assets/screenshots/layout-reference.svg)

## Features

### Notes and organization

- Create and edit notes with automatic local saving.
- Pin important notes.
- Mark notes as favorites.
- Archive notes without deleting them.
- Move notes to trash, restore them, delete one permanently, or empty trash.
- Organize with folders and comma-separated tags.
- Give notes optional colors.
- Filter by collection, folder, and tag.
- Fast full-text search backed by SQLite FTS5.

### Writing experience

- Distraction-free editor mode.
- Markdown-lite helpers for headings, emphasis, bullet lists, and checklists.
- Accessible text sizing and Material 3 typography.
- Autosave debounce to avoid unnecessary writes.
- Version snapshots before changed content is persisted.
- Restore an earlier version from note history.

### Import, export, and recovery

- Import Markdown, Markdown-like text, and UTF-8 text files as notes.
- Export a note as Markdown with small front matter metadata.
- Export all notes and snapshots as human-readable JSON.
- Validate backup application identity, schema version, field types, and timestamps before restoring.
- Conflict-safe restore: a backup does not overwrite a newer local note.
- Restore operations use a database transaction.

### Privacy and security

- Core functionality is local and requires no account.
- Optional device-authentication app lock through `local_auth` where the platform supports it.
- No analytics, ads, remote note synchronization, tracking SDKs, or production secrets are required by the core app.
- No custom cryptography.
- Secrets and signing material are excluded from source control.
- Security policy and responsible-disclosure process are documented.

### Product quality

- Responsive layout for phones, tablets, and desktops.
- Bottom navigation on compact layouts and navigation rail on wider layouts.
- Light, dark, and system appearance modes.
- Adjustable text scale and reduced-motion preference.
- Keyboard- and semantics-friendly Material controls.
- Empty, loading, error, destructive-confirmation, and progress states.
- English first, with Flutter localization delegates and centralized user-facing project strings ready for future localization work.
- Dedicated Settings and About areas.

## Supported platforms

| Platform | Project target | Notes |
|---|---:|---|
| Android | ✅ Primary | Local auth can use device credentials/biometrics where available. |
| Windows | ✅ Primary | Responsive desktop layout and local SQLite storage. |
| Linux | ✅ Primary | Responsive desktop layout and local SQLite storage. |
| macOS | ✅ Primary | Responsive desktop layout and local SQLite storage. |
| iOS | 🟡 Ready | Runner bootstrap and Face ID usage-description patch are provided; release signing requires an Apple environment. |

Native runner templates are generated reproducibly with [`tool/bootstrap_platforms.py`](tool/bootstrap_platforms.py) so contributors use the Flutter version installed in their environment instead of relying on stale generated templates.

## Technology stack

- **UI:** Flutter + Material 3
- **Language:** Dart
- **Persistence:** Drift + SQLite
- **Search:** SQLite FTS5
- **Settings:** `shared_preferences`
- **Device app lock:** `local_auth`
- **File selection/export:** `file_picker`
- **External links:** `url_launcher`
- **Identifiers:** UUID v7
- **Testing:** `flutter_test`, in-memory Drift/SQLite tests
- **Automation:** GitHub Actions + Dependabot

## Quick start

### 1. Install prerequisites

Install Flutter and the native build requirements for the platform you intend to run. Then confirm Flutter is healthy:

```bash
flutter doctor -v
```

Full operating-system setup instructions are in [`docs/setup.md`](docs/setup.md).

### 2. Clone the repository

```bash
git clone https://github.com/sanskarIN/notenest.git
cd notenest
```

For commits made on behalf of this project, configure the requested author email locally:

```bash
git config user.email "sanskarin@outlook.in"
```

### 3. Generate native platform runners

```bash
python tool/bootstrap_platforms.py
```

On Windows, use `py` instead of `python` if that is how Python is installed:

```powershell
py tool/bootstrap_platforms.py
```

### 4. Install packages and generate Drift code

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 5. Run the app

List available targets:

```bash
flutter devices
```

Run on one target:

```bash
flutter run -d <device-id>
```

## Development setup

A normal development loop is:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
flutter run
```

For continuous Drift generation during model work:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

See [`docs/development.md`](docs/development.md) for module boundaries, conventions, generated-code handling, database changes, and contribution workflow.

## Testing

Run all automated tests:

```bash
flutter test
```

Run with coverage:

```bash
flutter test --coverage
```

Before submitting a pull request, run the complete local quality gate:

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
```

The test strategy and test-suite map are documented in [`docs/testing.md`](docs/testing.md).

## Build and release

After native runners are generated, common release commands are:

```bash
flutter build apk --release
flutter build appbundle --release
flutter build windows --release
flutter build linux --release
flutter build macos --release
flutter build ios --release --no-codesign
```

Only run commands supported by the host operating system. Android and Apple store releases additionally require signing identities that **must not** be committed to this repository.

See [`docs/release.md`](docs/release.md) for versioning, clean-build verification, signing boundaries, artifacts, and release checklist.

## Architecture overview

NoteNest is a modular monolith with explicit dependency wiring:

```text
lib/
├── app/                 # Composition root and settings controller
├── core/                # Constants, errors, theme, pure utilities
├── data/
│   ├── database/        # Drift schema, database and FTS infrastructure
│   └── repositories/    # Notes, settings and backup persistence
├── domain/              # UI-independent filter/value models
├── features/
│   ├── about/
│   ├── home/
│   ├── notes/
│   ├── onboarding/
│   └── settings/
├── services/            # Platform-facing app lock and file transfer
├── widgets/             # Reusable presentation components
└── main.dart            # Application entry point
```

The UI does not directly create the database or platform services. [`AppDependencies`](lib/app/app_dependencies.dart) owns composition, repositories isolate persistence behavior, and pure helpers stay outside Flutter widgets where practical.

Read the complete design in [`docs/architecture.md`](docs/architecture.md) and architecture decisions in [`docs/adr/`](docs/adr/).

## Data model

The first schema contains:

- `notes`: current note state, organization metadata, color, lifecycle flags, and UTC timestamps.
- `note_versions`: pre-change snapshots tied to a note with a foreign key and cascade deletion.
- `notes_fts`: an FTS5 virtual index maintained by SQLite triggers for title, body, folder, and serialized tags.

Database schema changes must increment `schemaVersion`, add a migration, and include migration coverage. Do not edit released schema behavior in place.

## Privacy

NoteNest stores core note data locally. It does not require a NoteNest account or upload note contents to a project-operated server. Exporting a file, opening an external project/support link, or using platform authentication happens only in response to a user action.

Read [`PRIVACY.md`](PRIVACY.md) before distributing a modified build, especially if you add networking, telemetry, sync, or third-party SDKs.

## Security

- Never commit signing keys, API keys, tokens, passwords, private endpoints, `.env` secrets, or real user databases.
- Validate imported backup data before database writes.
- Treat imported note files as untrusted text.
- Use platform-maintained authentication rather than storing a custom password credential.
- Report suspected vulnerabilities privately according to [`SECURITY.md`](SECURITY.md).

## Accessibility

The project aims for WCAG-oriented practices rather than claiming formal certification. It uses semantic controls, tooltips, scalable typography, theme-aware colors, touch-friendly Material controls, reduced-motion preference, and responsive layouts. Manual screen-reader and keyboard checks are part of the release checklist.

See [`docs/accessibility.md`](docs/accessibility.md).

## Performance

The hot path for note discovery uses FTS5 rather than loading and substring-scanning note bodies in Dart. Note content writes are debounced, and list filtering is kept lightweight for the current local-first scope. Performance budgets and measurement guidance are in [`docs/performance.md`](docs/performance.md).

## Project documentation

- [`docs/setup.md`](docs/setup.md) — tool installation and clean-clone setup
- [`docs/development.md`](docs/development.md) — development workflow and conventions
- [`docs/architecture.md`](docs/architecture.md) — system design and dependency boundaries
- [`docs/testing.md`](docs/testing.md) — test strategy and quality gates
- [`docs/accessibility.md`](docs/accessibility.md) — accessibility requirements and manual checks
- [`docs/performance.md`](docs/performance.md) — performance budgets and profiling
- [`docs/release.md`](docs/release.md) — packaging and release process
- [`docs/troubleshooting.md`](docs/troubleshooting.md) — common setup/build/runtime problems
- [`docs/adr/`](docs/adr/) — architecture decision records
- [`what_changed.md`](what_changed.md) — exact continuation and verification handoff

## Contributing

Contributions are welcome. Read [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) before opening a pull request.

Small, reviewable Conventional Commits are preferred, for example:

```text
feat: add note sorting control
fix: preserve newer note during restore
test: cover malformed backup timestamps
docs: document Linux setup
```

## Roadmap

The current roadmap is maintained in [`ROADMAP.md`](ROADMAP.md). Future work should remain coherent with NoteNest's offline-first privacy model; a feature should not introduce a required cloud dependency merely to increase feature count.

## Support and contact

- Business: [sanskarin@outlook.in](mailto:sanskarin@outlook.in)
- Business: [sanskarin.business@gmail.com](mailto:sanskarin.business@gmail.com)
- Support: [supportramsandesh@gmail.com](mailto:supportramsandesh@gmail.com)
- GitHub: <https://github.com/sanskarIN>
- Repository: <https://github.com/sanskarIN/notenest>
- Buy Me a Coffee: <https://buymeacoffee.com/sanskarIN>

See [`SUPPORT.md`](SUPPORT.md) for what information to include in a support request.

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
