# NoteNest Performance

NoteNest is a local-first application. Performance work should be measured against real workflows and library sizes rather than adding complexity based on assumptions.

## User-perceived priorities

In order:

1. Opening the notes list should feel immediate for ordinary local libraries.
2. Typing in the editor must remain responsive.
3. Autosave must not block input.
4. Search should return quickly without scanning every body in Dart.
5. Navigation/filtering should not introduce fake delays.
6. Backup/restore may take longer for large libraries but must communicate real progress and preserve integrity.
7. Memory use should remain bounded enough for target devices.

## Initial budgets

These are engineering targets to validate on representative release builds, not guaranteed timing contracts across all hardware:

| Workflow | Initial target |
|---|---:|
| Editor keystroke UI work | No visible frame hitch; avoid synchronous storage work in handler |
| Autosave debounce | ~650 ms after last edit before write attempt |
| Search debounce | ~220 ms after last search edit |
| Search in 10k-note fictional library | Aim for < 150 ms database/search processing on representative modern hardware |
| Notes list initial query at 10k notes | Measure; optimize if > 250 ms database/filter processing |
| Backup validation/restore | No partial writes; prioritize integrity over arbitrary speed target |
| Main UI frame budget | Target smooth platform refresh behavior; investigate repeated >16.7 ms UI work at 60 Hz |

The 10k-note timing figures are provisional budgets and must be replaced/annotated with reproducible measurements before release claims are made.

## Current performance choices

### FTS5 search

Full note text is indexed by SQLite FTS5. Search is performed in the database rather than applying `String.contains` to every note body in Dart.

Benefits:

- Database-optimized inverted index.
- Prefix term search.
- Relevance ranking through `bm25`.
- Lower Dart-side text scanning cost for large bodies.

### Debounced search

`NotesController` uses a short debounce before querying as the search field changes. This avoids issuing a full search for every rapid keystroke.

### Debounced autosave

`NoteEditorPage` waits for a short idle period before saving content. `NoteRepository.saveContent` additionally compares existing normalized values and returns without writing/snapshotting unchanged content.

### Lazy grid construction

`GridView.builder` creates visible note-card widgets lazily rather than constructing the entire UI list at once.

### Local-only hot path

Normal note browsing/editing does not wait for remote network requests.

## Known scale limitations to measure

The first implementation deliberately favors simplicity. Known areas that may need optimization after profiling:

### Candidate loading then Dart filtering

`NoteRepository.list` fetches an FTS or complete candidate list, then applies collection/folder/tag filtering in Dart and sorts it. At very large libraries, push more filtering/order into SQL and introduce keyset pagination.

### Folder/tag enumeration

`folders()` and `tags()` currently read note rows and derive sets in Dart. This is acceptable for a simple local library but can be replaced with dedicated normalized tag/folder tables or SQL aggregation if measurements justify it.

### Multiple reads per browser refresh

`NotesController.load` requests notes, folders, and tags separately. A future repository query/result object could combine work or run appropriate operations concurrently after verifying database behavior.

### Snapshot growth

Version snapshots currently have no automatic retention limit. Very active notes can accumulate history. A future retention feature should be explicit/user-safe and never silently destroy history without documented policy.

### Backup memory use

Backup JSON is currently assembled/decoded in memory. Very large libraries may benefit from streaming export/import or bounded file-size validation. Do not complicate the format until realistic fixture profiling shows a need.

## Benchmark fixture plan

Create deterministic fictional fixtures at:

- 100 notes.
- 1,000 notes.
- 10,000 notes.
- 50,000 notes for stress profiling, not necessarily routine CI.

Vary:

- Short vs long bodies.
- Folder/tag cardinality.
- Archived/trashed ratios.
- Snapshot count.
- Unicode content.
- Search terms with high/low match frequency.

Fixtures must not contain real personal data.

## Measurement methodology

For meaningful UI measurements:

1. Use profile/release mode rather than debug-mode timing claims.
2. Record platform/device/CPU/RAM/Flutter version/commit.
3. Warm up where appropriate, but separately record cold-start behavior.
4. Repeat runs and report median plus meaningful spread.
5. Use Flutter DevTools performance/memory views for frame/CPU/memory analysis.
6. Change one major variable at a time.

For repository/search benchmarks, measure the database operation separately from widget rendering when diagnosing bottlenecks.

## Flutter profiling commands

Profile on a supported device:

```bash
flutter run --profile -d <device-id>
```

Use Flutter DevTools from the URL/tool integration printed by Flutter. Avoid interpreting debug-mode asserts/hot reload overhead as release performance.

Build release artifacts for realistic startup/package behavior:

```bash
flutter build apk --release
flutter build windows --release
flutter build linux --release
flutter build macos --release
```

Only run host-supported targets.

## Database profiling

When optimizing a query:

- Inspect actual SQL/query plan where practical.
- Add indexes based on query patterns, not speculation.
- Verify index write cost and migration impact.
- Benchmark with realistic cardinality.
- Preserve FTS trigger correctness.

If moving collection/folder/tag filtering into SQL, ensure equivalent lifecycle semantics with regression tests.

## Memory

Watch for:

- Large note bodies retained in multiple controller/widget copies.
- Full-library JSON backups held in memory.
- Unbounded snapshot lists loaded at once.
- File-picker byte arrays for large imports.
- Controllers/listeners/timers not disposed.

A performance fix that introduces data loss or unsafe partial writes is unacceptable.

## Startup

Startup currently initializes dependencies/settings/database before rendering the full application. If startup profiling later shows a bottleneck:

- Measure settings vs database open separately.
- Consider displaying a real bootstrap loading surface.
- Do not use fake splash delays.
- Do not defer database migrations in a way that lets old code operate on an incompatible schema.

## Search quality vs speed

Search speed is not useful if results are wrong. Preserve tests for title/body/folder/tag matching and collection filtering when optimizing.

Possible future improvements:

- SQL-side lifecycle/folder/tag filters joined with FTS.
- Search snippets/highlights.
- Query cache for repeated identical searches only if measurement shows value.
- Keyset pagination preserving ranking/order.

## Performance pull-request checklist

A PR claiming a performance improvement should include:

- Baseline scenario and measurement.
- New measurement under the same scenario.
- Platform/build mode/toolchain.
- Fixture size.
- Functional regression tests.
- Memory/write-cost tradeoffs.
- Any new index/migration/storage cost.

Avoid claims such as “10× faster” without reproducible data.

## Release performance notes

Before publishing stable performance claims, update this file with dated measurements from verified release/profile builds. Until then, numeric budgets above remain targets used to guide profiling rather than promises.
