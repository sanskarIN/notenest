# NoteNest Performance

NoteNest is a local-first application across Android, iOS/iPadOS, Windows, macOS, Linux, and Web. Performance work must be measured against real workflows and release/profile builds rather than justified by assumptions.

## User-perceived priorities

1. Notes list opens promptly for ordinary local libraries.
2. Editor typing stays responsive.
3. Autosave never blocks input.
4. FTS search avoids scanning every body in Dart.
5. Navigation/filtering has no fake delays.
6. Backup/restore communicates real work and preserves integrity.
7. Import memory stays bounded.
8. Web startup/database worker loading does not leave a blank or unusable app.
9. Browser persistence/search remains usable under the actual storage backend available on the deployment origin.

## Initial engineering budgets

These are profiling targets, not guaranteed timing contracts:

| Workflow | Initial target |
|---|---:|
| Editor keystroke UI work | No visible hitch; no synchronous storage in handlers |
| Autosave debounce | ~650 ms after final edit before submission |
| Search debounce | ~220 ms after final search edit |
| Search in 10k fictional notes | Aim for <150 ms database/search processing on representative modern hardware |
| Initial 10k-note list query | Measure; investigate >250 ms database/filter processing |
| Backup validation/restore | Integrity first; no partial writes |
| Main UI frame budget | Investigate repeated >16.7 ms UI work at 60 Hz |
| Web worker/WASM initialization | Measure on intended host/browser; no fixed release claim until benchmarked |

Replace or annotate numeric targets with reproducible measurements before publishing performance claims.

## Current performance choices

### SQLite FTS5

Full note text is indexed by SQLite FTS5. Search occurs in SQLite rather than `String.contains` scans across all note bodies in Dart.

### Debounced search and autosave

Search uses a short debounce. Editor saves are debounced and then serialized. `NoteRepository.saveContent` avoids redundant writes/snapshots when normalized content is unchanged.

### Lazy note-card construction

`GridView.builder` creates visible cards lazily rather than constructing the entire visual list at once.

### Local hot path

Core note browse/edit/search operations do not wait for a project-operated notes API.

On Web, the browser first loads the static Flutter bundle plus SQLite worker/WASM assets from the hosting origin. After startup, note operations use browser-local persistence under the current architecture.

## Native vs Web storage performance

Native targets use the normal Drift/SQLite platform path.

Web uses Drift with `sqlite3.wasm` + `drift_worker.js`. Browser performance depends on:

- browser engine/version;
- available Drift storage backend;
- whether the deployment provides conditions for the optimal OPFS path;
- device CPU/memory;
- origin storage/quota policy;
- cold worker/WASM/network cache state.

Do not extrapolate native SQLite benchmark numbers to Web or vice versa.

For Web benchmarks, record the browser, deployment origin, storage backend where observable, cache state, and whether cross-origin isolation is enabled.

## Import memory model

### Native

Picker-provided cached paths are read incrementally through `BoundedFileReader`; reported/cumulative lengths are validated before the final NoteNest buffer is allowed beyond the configured limit.

### Web

Browser picker bytes/streams are validated by reported size and actual cumulative length before UTF-8/structured processing. Browser APIs may already hold selected file data outside NoteNest's own final buffer, so profiling should distinguish browser/provider memory from application allocations where possible.

Limits remain:

- Markdown/text: 16 MiB.
- Backup JSON: 64 MiB.

## Known scale areas to measure

### Candidate loading + Dart filtering

`NoteRepository.list` can load an FTS/complete candidate set then apply collection/folder/tag filtering and sorting in Dart. Large libraries may benefit from more SQL-side filtering and keyset pagination.

### Folder/tag enumeration

Folder/tag choices are derived from note rows in Dart. Dedicated normalized tables or SQL aggregation should only be introduced if profiling justifies the added schema complexity.

### Multiple reads per browser refresh

`NotesController.load` obtains notes/folders/tags separately. A future repository result object may reduce repeated work after database behavior is measured.

### Snapshot growth

Snapshots currently have no automatic retention limit. A retention policy must be explicit/user-safe and never silently destroy history merely for performance.

### Backup memory

Structured backup export/import currently materializes JSON. Streaming/staged processing can be reconsidered only after realistic large-library profiling.

### Web startup/cache

Cold Web startup includes static bundle, worker, and WASM loading. Measure cold and warm cache separately. Avoid adding a fake splash delay to hide real initialization cost.

## Benchmark fixtures

Use deterministic fictional libraries at:

- 100 notes;
- 1,000 notes;
- 10,000 notes;
- 50,000 notes for stress profiling.

Vary body length, folder/tag cardinality, lifecycle ratios, snapshot counts, Unicode, and search match frequency.

Never benchmark with real private note data.

## Measurement method

1. Use profile/release mode for timing claims.
2. Record target, OS/browser, hardware, Flutter version, commit, and database/storage mode.
3. Separate cold vs warm runs.
4. Repeat and report median plus useful spread.
5. Use Flutter DevTools/browser performance tools as appropriate.
6. Measure database work separately from widget rendering when diagnosing bottlenecks.
7. Change one major variable at a time.

## Profiling commands

Native/profile target:

```bash
flutter run --profile -d <device-id>
```

Representative release builds:

```bash
flutter build apk --release
flutter build windows --release
flutter build linux --release
flutter build macos --release
flutter build web --release
```

Run only host-supported native targets.

For Web, profile both local development and the intended deployed release bundle because network/cache/headers/storage behavior can differ materially.

## Database profiling

When optimizing queries:

- inspect SQL/query plans where practical;
- add indexes based on measured query patterns;
- account for write/migration cost;
- benchmark realistic cardinality;
- preserve FTS trigger correctness;
- preserve identical lifecycle semantics;
- verify native and Web behavior.

## Memory watch list

- Large note bodies copied across multiple layers.
- Full-library JSON export/import buffers.
- Unbounded snapshot lists.
- Browser picker byte arrays/streams.
- Native file buffers.
- Controllers/listeners/timers not disposed.
- Browser worker/database memory after repeated navigation/imports.

A performance change that weakens integrity or introduces partial writes is unacceptable.

## Startup

Startup initializes settings/database before the full application surface. If profiling finds a bottleneck:

- measure settings vs DB vs Web worker/WASM separately;
- show a real loading/error surface if needed;
- never add fake waits;
- never allow old code to operate against an incomplete migration.

## Performance PR checklist

A PR claiming an improvement should provide:

- baseline and new measurement under the same scenario;
- platform/browser and build mode;
- hardware and Flutter/commit;
- fixture size;
- Web storage/backend/header state where relevant;
- functional regressions/tests;
- memory/write/migration tradeoffs.

Avoid unsupported statements such as “10× faster.”

## Release performance notes

Before stable performance claims, add dated measurements from verified release/profile builds. Until then, this document describes engineering targets and known pressure points rather than promises.
