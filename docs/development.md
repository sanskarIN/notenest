# NoteNest Development Guide

Current release-candidate target: **2.0.12** (`2.0.12+2012`).

## Daily workflow

From the repository root:

```bash
python tool/check_version_sync.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
```

For active schema/repository work, keep Drift generation running:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

Run the app on a selected target:

```bash
flutter devices
flutter run -d <device-id>
```

## Repository layout

```text
assets/branding/               Editable project artwork
docs/                          Engineering/product/release documentation
lib/app/                       Composition root and app-wide state
lib/core/                      Constants, errors, logging, theme, pure utilities
lib/data/database/             Drift schema and database infrastructure
lib/data/repositories/         Persistence boundaries
lib/domain/                    UI-independent domain/value models
lib/features/                  Feature-specific presentation/controllers
lib/services/                  Platform/file/external-link boundaries
lib/widgets/                   Reusable widgets
test/app/                      Application-controller tests
test/core/                     Pure/core regression tests
test/data/                     Repository/database/preferences tests
test/features/                 Feature-controller tests
test/services/                 Service-boundary tests
test/widgets/                  Widget/accessibility behavior tests
tool/                          Reproducible project maintenance scripts
.github/                       Repository automation/templates
```

## Dependency direction

Prefer this direction:

```text
widgets/features
      ↓
controllers
      ↓
repositories/services
      ↓
database/plugins/platform APIs
```

Pure utilities and domain types may be used upward where appropriate. Database/plugin types should not leak throughout unrelated widgets.

## Adding a note feature

A normal feature change should answer:

1. Is this current-note data, a setting, or transient UI state?
2. Does it require a database schema change/migration?
3. Does it affect backup compatibility?
4. Does it affect full-text search?
5. Does it affect collection-scoped folder/tag metadata?
6. Does it affect privacy/permissions or external platform services?
7. What is the smallest appropriate test layer?
8. How does it behave on compact and desktop layouts?
9. How is it exposed to keyboard/screen-reader users?
10. Does documentation/release metadata need updating?

For example, adding a `sortOrder` preference usually belongs in settings rather than a `notes` column, while a per-note reminder timestamp would likely belong in note data and backup serialization.

## Editing database schema

Do not confuse the app version (`2.0.12`) with the Drift database schema version (`1`). They evolve independently.

Do not edit a released database schema and leave `schemaVersion` unchanged.

For a future database migration:

```dart
@override
int get schemaVersion => 2;
```

Add a deterministic `onUpgrade` path using Drift's `Migrator`, then write tests that open/upgrade from a version-1 fixture. Update backup behavior separately if the interchange format also changes.

FTS maintenance is manual SQL infrastructure in `AppDatabase`; indexed-column changes may require trigger/table reconstruction.

## Repositories

Repositories own persistence invariants. Keep methods intention-revealing:

- `archive(noteId)` is preferable to exposing arbitrary column writes to UI.
- `restoreJson` owns validation/merge rules rather than asking a screen to implement them.
- Collection folder/tag metadata should reuse the same lifecycle predicate as collection listing.

When a repository method contains multi-step state changes that must succeed together, use a transaction.

## UI controllers

Controllers should stay feature-scoped.

`NotesController` owns browser loading/error/filter state and calls `NoteRepository`. It uses generation numbers so stale async loads do not overwrite newer requests. Collection changes clear folder/tag filters because those filter values are collection-scoped.

When adding state:

- Avoid putting unrelated settings into `NotesController`.
- Dispose timers/listeners.
- Guard async callbacks against updates after disposal.
- Avoid triggering database work on every keystroke when debouncing is appropriate.
- Protect against stale async completion when multiple requests can overlap.

## Editor behavior

The editor intentionally stores raw text rather than introducing a rich document model. Markdown-lite toolbar actions transform selected/current-line text. This keeps storage/search/export straightforward.

If proposing rich text later, first define:

- Storage representation.
- Plain-text/full-text-search representation.
- Markdown import/export lossiness.
- Migration path for existing notes.
- Accessibility behavior.

## Autosave

`Debouncer` delays high-frequency save submissions. `AsyncSerialQueue` then guarantees submitted editor drafts are persisted in order. `NoteRepository.saveContent` compares normalized values before writing and creates a pre-change snapshot only when relevant content differs.

Do not remove the serial queue and reintroduce concurrent saves without replacing its ordering guarantee. Do not add fake loading delays. Save indicators should reflect actual persisted/current draft state.

## Settings development

Preferences stay behind `SettingsStore`/`SettingsRepository` and `AppSettingsController`.

Rules:

- Do not store credentials or note content in preferences.
- Treat a failed platform preference write as a real persistence failure.
- Serialize mutations when write ordering affects the final saved value.
- If a visible optimistic setting write fails, restore the last successfully persisted value unless the UI has already moved to a newer requested value.
- Onboarding is persistence-first: do not leave onboarding until completion was saved.
- Surface a concise user-visible failure message at the UI boundary.

When adding a preference, update the store interface, repository, controller, tests, and relevant docs together.

## Import/export development

All imported files/bytes are untrusted.

A native importer should:

- Avoid eager full-byte picker loading when a cached path is available.
- Enforce a byte ceiling before constructing the complete NoteNest buffer.
- Re-check accumulated bytes while streaming.
- Require expected encoding.
- Avoid executing embedded content.
- Validate schema/structure before state changes.
- Have deterministic malformed/oversized-input tests.

Current limits:

- Markdown/text: 16 MiB.
- NoteNest JSON backup: 64 MiB.

A new export format should include enough version metadata to detect incompatibility.

Generated filenames must remain cross-platform-safe and should not split Unicode surrogate pairs/code points during truncation.

## Backup development

Backup schema versioning is independent from the Drift schema and app version.

Current restore invariants include:

- Correct app/schema identifiers.
- Typed fields.
- Strict serialized tag arrays.
- Explicit UTC timestamps ending in `Z`.
- `updatedAt` must not precede `createdAt`.
- `colorValue` must be null or a 32-bit ARGB integer.
- IDs cannot contain surrounding whitespace.
- Duplicate incoming IDs are rejected.
- Version records must reference an incoming/existing note.
- Writes begin only after validation.
- Newer local notes win conflicts.

Any relaxation/tightening needs compatibility analysis and regression coverage.

## External-link development

Do not call `launchUrl` directly from feature widgets. Use `ExternalLinkService` so plugin/platform failures are contained and testable.

The caller is responsible for context-specific feedback when `open()` returns `false`.

Add real-platform smoke testing for new URI schemes.

## App-lock development

Do not store biometric material or a plaintext password. Device authentication stays behind `AppLockService`.

Platform-specific native changes for `local_auth` should be represented in the reproducible bootstrap script and documented, then verified on relevant targets.

App lock gates UI access; it does not encrypt the SQLite database.

## Adding dependencies

Before adding a package:

- Verify it is maintained and compatible with the supported Flutter/Dart baseline.
- Check whether existing dependencies or standard APIs already solve the problem.
- Review native permissions and network behavior.
- Review license compatibility.
- Add only the minimum package needed.
- Run tests/builds affected by native plugins.

Update `pubspec.yaml`, documentation if setup changes, and lock state once generated by the supported toolchain.

## Version/release metadata

A version change is not complete until these agree:

- `pubspec.yaml` semantic version/build number.
- `AppStrings.version`.
- `CHANGELOG.md` release section.
- `docs/releases/<version>.md`.

Verify with:

```bash
python tool/check_version_sync.py
```

Do not hand-edit one version surface and assume the rest will follow automatically.

## Formatting and analysis

Formatting check:

```bash
dart format --output=none --set-exit-if-changed lib test
```

Apply formatting:

```bash
dart format lib test
```

Static analysis:

```bash
flutter analyze
```

`analysis_options.yaml` enables strict casts/inference/raw types plus project lint rules. Do not suppress a lint globally merely to silence one difficult line; fix the issue or use the smallest justified local suppression with an explanatory comment.

## Tests

Run all:

```bash
flutter test
```

Run one file:

```bash
flutter test test/data/note_repository_test.dart
```

Run with coverage:

```bash
flutter test --coverage
```

See [`testing.md`](testing.md) for the current test inventory and platform verification plan.

## Native runners

Generate/re-generate:

```bash
python tool/bootstrap_platforms.py
```

After Flutter upgrades, review generated runner differences and verify NoteNest's script patches still match upstream output. If template structure changes, update the script/docs rather than silently skipping a required patch.

## Debugging database behavior

Use fictional test data. Prefer `NativeDatabase.memory()` tests for repository behavior.

When diagnosing FTS:

- Verify `notes` contains expected current rows.
- Verify FTS triggers exist.
- Rebuild the FTS index only as a controlled diagnostic/migration step.
- Keep user search input in SQL variables.

Do not ask users to publish their real SQLite file.

## Error messages

User-facing errors should be:

- Actionable.
- Non-technical when technical detail does not help.
- Clear about preserved local data when true.
- Free of secrets/private note content.

Developer detail belongs in safe diagnostics, not an unbounded exception dump shown to end users.

## Accessibility during development

For every UI change:

- Navigate by keyboard on desktop where applicable.
- Check icon buttons/custom controls have names/tooltips/semantics.
- Increase text size and look for clipping.
- Test narrow and wide windows.
- Ensure status/selection is not color-only.
- Respect reduced-motion preference for optional animation.
- Verify failure feedback remains reachable to assistive technology.

See [`accessibility.md`](accessibility.md).

## Documentation discipline

When behavior changes, update the closest source of truth in the same workstream. Examples:

- Setup command changed → `README.md` + `docs/setup.md`.
- Architecture boundary changed → `docs/architecture.md` and ADR if material.
- Migration behavior changed → architecture/migration docs.
- User data behavior changed → `PRIVACY.md`.
- Security boundary changed → `SECURITY.md`.
- Release process/version changed → `CHANGELOG.md`, `docs/release.md`, and `docs/releases/<version>.md`.
- Current checkpoint changed → `what_changed.md`.

## Commit discipline

Small meaningful commits improve review and continuation. Prefer one cohesive change per commit and run the smallest relevant check first. Before a release boundary, run the complete quality suite.

Recommended local identity:

```bash
git config user.email "sanskarin@outlook.in"
```

## Finishing a change

Before marking work complete:

```bash
python tool/check_version_sync.py
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
python tool/check_repo.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

Then run native builds/runtime checks relevant to the change. Document environment-blocked verification accurately instead of claiming it passed.
