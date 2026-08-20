# NoteNest Architecture

Current release-candidate target: **2.0.12** (`2.0.12+2012`).

## Goals

NoteNest is a local-first cross-platform notes application built as a **modular monolith**. The architecture should stay understandable to a small open-source team while protecting production concerns such as data integrity, browser/native differences, backup compatibility, accessibility, and reproducible releases.

Primary goals:

- Support Android, iOS/iPadOS, Windows, macOS, Linux, and Web from one Flutter codebase.
- Keep UI separate from persistence and plugin/platform details.
- Keep core note workflows local-first and account-free.
- Make storage/platform boundaries injectable/testable where practical.
- Preserve note/settings integrity under asynchronous failure and lifecycle changes.
- Keep platform-specific or unsupported capabilities behind explicit services/conditional implementations.
- Keep imports bounded and backups validated before writes.
- Keep schema/version/toolchain evolution deliberate.
- Treat accessibility/responsive behavior as architecture requirements rather than final polish.

## High-level structure

```text
┌──────────────────────────────────────────────────────────────┐
│ Flutter presentation                                        │
│ Home / Notes / Editor / Onboarding / Settings / About       │
└──────────────────────────────┬───────────────────────────────┘
                               │
┌──────────────────────────────▼───────────────────────────────┐
│ Application state/controllers                               │
│ NotesController / AppSettingsController                     │
└──────────────────────────────┬───────────────────────────────┘
                               │
┌──────────────────────────────▼───────────────────────────────┐
│ Repositories + platform services                            │
│ Notes / Backup / Settings / Files / App lock / Links        │
└──────────────────────────────┬───────────────────────────────┘
                               │
┌──────────────────────────────▼───────────────────────────────┐
│ Platform/runtime implementations                            │
│ Drift SQLite / SharedPreferences / picker / launcher        │
│ native dart:io boundaries OR browser-safe fallbacks         │
└──────────────────────────────────────────────────────────────┘
```

The browser is not modeled as “desktop with a filesystem.” Platform services explicitly distinguish browser and native capabilities.

## Composition root

`AppDependencies` owns application-wide construction:

- `AppDatabase`
- `NoteRepository`
- `BackupRepository`
- `SettingsRepository`
- `AppSettingsController`
- `FileTransferService`
- `AppLockService`
- `ExternalLinkService`
- logger/service dependencies

Construction cleans up partial resources if settings initialization fails. `NoteNestApp.dispose()` delegates final owned settings/database cleanup back to `AppDependencies.dispose()`.

Feature widgets should receive dependencies/controllers rather than creating storage/plugin objects ad hoc.

## Six-platform strategy

### Shared Flutter presentation

Responsive breakpoints/tokens allow the same feature layer to render:

- compact phone/browser widths with bottom navigation;
- tablet/wide browser layouts;
- desktop windows with navigation rail and keyboard interaction.

No feature should assume pointer-only, touch-only, or native-window-only interaction without an explicit platform reason.

### Generated runners

Platform runners are intentionally generated rather than treated as manually maintained source. `tool/bootstrap_platforms.py` creates:

- Android
- iOS
- Linux
- macOS
- Windows
- Web

The generated directories are build inputs, not part of the 108 tracked-source catalog.

### Native patch verification

Bootstrap enforces/validates Android `FlutterFragmentActivity`, biometric permission, minimum SDK, AppCompat dependency/themes, and iOS Face ID usage text. If Flutter templates drift, bootstrap fails instead of silently leaving authentication configuration incomplete.

### Web runtime preparation

The same bootstrap prepares Drift Web runtime assets from direct dependency Drift **2.34.3**:

- `sqlite3.wasm`
- `drift_worker.js`

The script compares its expected Drift Web version to `pubspec.yaml` and refuses to proceed if the direct dependency changes without an explicit asset review. Downloaded assets receive basic sanity validation before being written to the generated Web runner.

This keeps the browser SQLite runtime coupled to the package version that knows how to communicate with it.

## Database architecture

`AppDatabase` is Drift schema version **1**.

Logical storage contains:

- current notes;
- note-version snapshots;
- FTS5 external-content search table/triggers.

Foreign keys are enabled during open. FTS5 is created/rebuilt on database creation and maintained by triggers after note insert/update/delete.

### Native database

On Android/iOS/Windows/macOS/Linux, `drift_flutter` selects the normal local SQLite implementation for that runtime.

### Web database

The database factory explicitly supplies:

```text
sqlite3.wasm
drift_worker.js
```

through `DriftWebOptions`. Drift then selects an available browser-local storage strategy. Hosting should serve WASM with the correct MIME type; compatible cross-origin isolation can enable the optimal OPFS path. The architecture does not assume every deployment has OPFS—real release verification records the actual storage mode/behavior on the intended origin.

Browser data belongs to the browser/profile/origin and can be cleared outside NoteNest. The validated JSON backup format, not an internal database file, is the portable interchange/recovery boundary.

## Data/version domains

Do not conflate:

- app semantic version (`2.0.12`);
- Flutter package build number (`2012`);
- Flutter SDK pin (`3.44.7`);
- Drift schema version (`1`);
- backup schema version;
- dependency graph (`pubspec.lock`, once generated/committed).

A change in one domain does not automatically require incrementing all others, but release tooling/docs must identify coupled surfaces.

## Notes repository invariants

`NoteRepository` is the authoritative live-note persistence boundary. It owns:

- UUID-v7 creation;
- canonical tags;
- note listing/filtering;
- FTS-backed search;
- transactional content snapshots;
- version restore;
- pin/favorite/archive/trash operations;
- deletion/empty trash;
- collection-scoped folder/tag metadata.

Important invariants:

- Changed content creates a pre-change snapshot transactionally.
- A trashed note cannot be pinned.
- Trash/archive states remain consistent with backup validation.
- Collection metadata uses the same lifecycle predicate as collection listing.
- Search values become bound variables rather than executable SQL concatenation.

## Editor persistence model

The editor separates visible draft state from persistence completion.

1. User edits are debounced.
2. Every submitted save captures an immutable draft.
3. `AsyncSerialQueue` preserves submission order.
4. A save completion updates visible “saved” state only if that draft is still current.
5. Normal Back captures/submits the current draft and waits for success before allowing pop.
6. Export/history also waits for the current draft to save.
7. Failure leaves content editable and surfaces feedback.

Lifecycle saves use the same queue. Platform process termination is still a runtime concern and belongs in manual integration validation.

## Settings and onboarding model

`SettingsRepository` stores non-sensitive preferences behind `SettingsStore`.

`AppSettingsController`:

- loads settings atomically;
- serializes mutations;
- tracks last persisted values;
- rolls back a failed optimistic mutation when appropriate;
- prevents an older failure from overwriting a newer requested value.

Onboarding is persistence-first: the UI leaves onboarding only after completion persistence succeeds.

Settings never store note contents or authentication secrets.

## Cross-platform file-transfer boundary

`FileTransferService` owns picker/import/export orchestration.

### Native acquisition

Native picker operations avoid eager `withData` loading. A cached path is read through the bounded native reader:

- validate reported length;
- stream chunks;
- validate cumulative length;
- build final buffer only within the configured limit;
- translate filesystem failures to domain errors.

### Web acquisition

Shared code cannot assume a native path. On Web:

- picker data is requested;
- picker-reported size is validated;
- actual bytes/stream accumulation is revalidated;
- only then is UTF-8/format processing performed.

The shared `BoundedFileReader` is a conditional facade. Its `dart:io` implementation is compiled only on IO targets; browser builds select an unsupported-path stub so native filesystem code is not pulled into Web.

Limits:

- Markdown/text: 16 MiB.
- JSON backup: 64 MiB.

### Exports

Markdown/JSON exports use picker save behavior. Generated Markdown filenames are cross-platform and Unicode safe. On Web, export becomes browser download/save behavior rather than a native file path write.

## Backup boundary

`BackupRepository` is the portable interchange boundary across devices/platforms/browser origins.

Before writes, restore validates:

- app/schema identity;
- required value types;
- root/note/version UTC timestamps;
- note timestamp ordering;
- serialized/canonical tags;
- identifiers and relationships;
- 32-bit ARGB values;
- lifecycle combinations.

Only validated input enters the restore transaction. Newer local notes win conflicts and duplicate snapshots are not blindly duplicated.

Backups are readable JSON and are not encryption.

## App-lock capability architecture

App lock is intentionally a capability rather than a universal guarantee.

`app_lock_service.dart` conditionally selects:

- native `local_auth` implementation on IO targets;
- browser-safe unavailable implementation on Web.

The native wrapper converts missing plugin/platform/auth errors to a safe unavailable/failed result. This means Linux—which has no current `local_auth` implementation—also remains usable.

The root lock gate checks `canAuthenticate()` before attempting authentication. If a platform cannot authenticate, it does not leave the user stuck behind an impossible lock screen.

Settings separately checks capability before allowing app-lock enable. A stale already-enabled preference can still be disabled on an unsupported target.

Do not introduce a home-grown browser/Linux password system solely for parity. App lock is not at-rest database encryption.

## External-link boundary

`ExternalLinkService` centralizes repository, funding, support/business mail, and Releases launches. Feature code receives a safe boolean rather than raw plugin failure/exception behavior.

External destinations remain outside NoteNest's trusted local data boundary.

## Error handling

Expected platform/storage/import failures should cross boundaries as domain-safe results/exceptions and be translated into concise user feedback.

Avoid:

- leaking raw plugin exceptions into widget callbacks;
- swallowing persistence failure while showing success;
- retry loops without user control;
- logging private note/import contents.

## Logging

The project logger structures events and redacts sensitive key categories. Logs should never contain raw note bodies, backups, credentials, authentication material, or complete selected files. Browser origins/storage details and native personal paths should be redacted in public diagnostics.

## Accessibility architecture

Shared tokens enforce a 48 logical-pixel custom interaction target. Custom selection UI uses semantics and visible non-color cues.

Responsive design must consider:

- touch/pointer/keyboard;
- mobile system Back vs desktop/browser navigation;
- browser focus/zoom;
- text scaling;
- reduced motion;
- light/dark themes;
- screen reader semantics.

A compile-successful platform is not accessibility-certified.

## Security/privacy boundaries

Core design intentionally excludes:

- required sign-in;
- project-operated note sync;
- analytics/advertising SDKs;
- custom cryptography;
- custom biometric/password storage.

The Web host serves static app/runtime assets, which is not the same as receiving note contents. A distributor adding telemetry, scripts, remote processing, accounts, or sync changes the trust model and must update architecture/privacy/security documentation.

## Dependency and release reproducibility

Flutter is pinned exactly. Runtime/dev dependencies are pinned in `pubspec.yaml`.

Because NoteNest is an application, the final stable dependency graph must also be captured by the resolver-generated `pubspec.lock`. Issue #8 tracks that missing release blocker. The lock must be generated with Flutter 3.44.7 and never fabricated manually.

After the lock is committed, final verification should enforce it and all six platform builds must be rerun.

## Quality architecture

Deterministic gates include:

- release/toolchain version synchronization;
- Drift generation;
- formatting/analyzer/tests;
- repository policy;
- exhaustive 108-file reference validation;
- Markdown links;
- secret scan;
- Chrome Web fallback regression;
- Android/Linux/Windows/macOS/iOS/Web build matrix.

Manual validation remains required for real platform/plugin/browser storage, file providers, authentication, accessibility, screenshots, signing, and deployment behavior.

## Schema evolution

Schema 1 is the current initial schema. A future schema change must:

1. increment `schemaVersion`;
2. add deterministic migration logic;
3. test upgrade from representative previous-schema fictional data;
4. verify FTS/foreign keys/repository behavior after migration;
5. review backup compatibility independently;
6. test both native SQLite and Web SQLite runtime paths before release.

## Related decision records

- [`adr/0001-flutter-drift-modular-monolith.md`](adr/0001-flutter-drift-modular-monolith.md)
- [`adr/0002-offline-first-data.md`](adr/0002-offline-first-data.md)
- [`adr/0003-generated-platform-runners.md`](adr/0003-generated-platform-runners.md)

See [`testing.md`](testing.md), [`setup.md`](setup.md), [`release.md`](release.md), [`../PRIVACY.md`](../PRIVACY.md), and [`../SECURITY.md`](../SECURITY.md) for operational verification of these boundaries.
