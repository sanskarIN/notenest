# NoteNest Development Guide

## Daily workflow

From the repository root:

```bash
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
docs/                          Engineering and product documentation
lib/app/                       Composition root and app-wide state
lib/core/                      Shared constants/errors/theme/pure utilities
lib/data/database/             Drift schema and database infrastructure
lib/data/repositories/         Persistence boundaries
lib/domain/                    UI-independent domain/value models
lib/features/                  Feature-specific presentation/controllers
lib/services/                  Platform/file boundaries
lib/widgets/                   Reusable widgets
test/                          Automated tests
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
database/plugins
```

Pure utilities and domain types may be used upward where appropriate. Database/plugin types should not leak throughout unrelated widgets.

## Adding a note feature

A normal feature change should answer:

1. Is this current-note data, a setting, or a transient UI state?
2. Does it require a schema change/migration?
3. Does it affect backup compatibility?
4. Does it affect full-text search?
5. Does it affect privacy/permissions?
6. What is the smallest appropriate test layer?
7. How does it behave on compact and desktop layouts?
8. How is it exposed to keyboard/screen-reader users?

For example, adding a `sortOrder` preference usually belongs in settings rather than a `notes` column, while adding a per-note reminder timestamp would likely belong in note data and backup serialization.

## Editing database schema

Do not edit a released schema and leave `schemaVersion` unchanged.

For a future migration:

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

When a repository method contains multi-step state changes that must succeed together, use a transaction.

## UI controllers

Controllers should stay feature-scoped. `NotesController` currently owns browser loading/error/filter state and calls `NoteRepository`.

When adding state:

- Avoid putting unrelated settings into `NotesController`.
- Dispose timers/listeners.
- Guard async callbacks against updates after disposal.
- Avoid triggering database work on every keystroke when debouncing is appropriate.

## Editor behavior

The editor intentionally keeps raw text rather than introducing a rich document model. Markdown-lite toolbar actions transform selected/current-line text. This avoids complicated serialization and keeps Markdown export straightforward.

If proposing rich text later, first define:

- Storage representation.
- Plain-text/full-text-search representation.
- Markdown import/export lossiness.
- Migration path for existing notes.
- Accessibility behavior.

## Autosave

`Debouncer` delays high-frequency saves. `NoteRepository.saveContent` compares normalized values before writing and creates a pre-change snapshot only when relevant content differs.

Do not add fake loading delays. Save indicators should reflect actual work.

## Import/export development

All imported bytes are untrusted. A new importer should:

- Enforce/validate encoding.
- Avoid executing embedded content.
- Validate schema/structure before state changes.
- Have deterministic malformed-input tests.
- Avoid inserting unbounded deeply nested structures into memory without a size/risk review.

A new export format should include enough version metadata to detect incompatibility.

## App-lock development

Do not store biometric material or a plaintext password. Device authentication stays behind `AppLockService`.

Platform-specific native changes for `local_auth` should be represented in the reproducible bootstrap script and documented, then verified on the relevant platform.

## Adding dependencies

Before adding a package:

- Verify it is actively maintained and compatible with the supported Flutter/Dart baseline.
- Check whether existing dependencies or standard Flutter/Dart APIs already solve the problem.
- Review native permissions and network behavior.
- Review license compatibility.
- Add only the minimum package needed.
- Run all tests/builds affected by native plugins.

Update `pubspec.yaml`, documentation if setup changes, and dependency lock state once generated by the supported toolchain.

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

See [testing.md](testing.md) for strategy and future integration/golden plans.

## Native runners

Generate/re-generate:

```bash
python tool/bootstrap_platforms.py
```

After Flutter upgrades, review the diff produced by generated runner templates and verify that NoteNest's script patches still match upstream output. If upstream template structure changes, update the script and its docs rather than silently skipping a required patch.

## Debugging database behavior

Use fictional test data. Prefer an in-memory `NativeDatabase.memory()` test for repository behavior.

When diagnosing FTS:

- Verify `notes` contains the expected current row.
- Verify FTS triggers exist.
- Rebuild the FTS index only as a controlled diagnostic/migration step.
- Keep user search input in SQL variables.

Do not ask users to publish their real SQLite file.

## Error messages

User-facing errors should be:

- Actionable.
- Non-technical when technical detail does not help.
- Clear that local data remains local when that is true.
- Free of secrets/private note content.

Developer detail belongs in safe diagnostics, not in an unbounded exception dump shown to end users.

## Accessibility during development

For every UI change:

- Navigate it by keyboard on desktop when applicable.
- Check icon buttons have tooltips/semantic purpose.
- Increase text size and look for clipping.
- Test narrow and wide windows.
- Ensure status is not communicated only by color.
- Respect reduced-motion preference for optional animation.

See [accessibility.md](accessibility.md).

## Documentation discipline

When behavior changes, update the closest source of truth in the same pull request. Examples:

- Setup command changed → `README.md` + `docs/setup.md`.
- Migration behavior changed → `docs/architecture.md` + ADR/migration notes.
- User data behavior changed → `PRIVACY.md`.
- Security boundary changed → `SECURITY.md`.
- Release process changed → `docs/release.md`.
- Current work checkpoint changed → `what_changed.md`.

## Commit discipline

Small meaningful commits improve review and continuation. Prefer one cohesive change per commit and run the smallest relevant check first. Before a phase/release boundary, run the complete quality suite.

Recommended local identity:

```bash
git config user.email "sanskarin@outlook.in"
```

## Finishing a change

Before marking work complete:

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
```

Then run native builds relevant to the change. Document any environment-blocked verification accurately instead of claiming it passed.
