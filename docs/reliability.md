# NoteNest Reliability and Concurrency

This document records the reliability invariants that protect local note data and UI state. It is intended for maintainers reviewing editor, controller, persistence, lifecycle, and recovery changes.

## Reliability goals

NoteNest should remain predictable when:

- the user types rapidly
- multiple asynchronous loads overlap
- the app moves between foreground/background states
- file operations fail or are cancelled
- device authentication becomes unavailable
- imported data is malformed
- the local database returns an error
- a note is deleted while history exists
- the UI is resized between compact and wide layouts

The project does not attempt to hide every error. It aims to fail explicitly without losing newer local data or presenting raw private/internal details to the user.

## Persistence boundary

Widgets do not mutate Drift tables directly. Note state flows through `NoteRepository`; full backup/restore flows through `BackupRepository`.

This keeps persistence behavior testable with an in-memory SQLite database and provides one place to enforce lifecycle and snapshot rules.

## Notes-browser load ordering

`NotesController` owns the active collection/search/folder/tag filter and currently visible note list.

Every load receives a monotonically increasing generation. When asynchronous work finishes, results are committed only if that generation is still current.

This prevents the following race:

1. user starts search `a`
2. slow query `a` begins
3. user quickly changes to search `ab`
4. query `ab` finishes and displays correct results
5. old query `a` finishes later
6. without generation checking, stale `a` results overwrite `ab`

Older completions are ignored instead.

Search input is debounced, but debounce delay is not the correctness mechanism. Generation checking is still required because already-started operations can overlap.

## Debouncer lifecycle

`Debouncer` owns one timer at a time.

Rules:

- a new run cancels the previous timer
- disposal cancels the timer
- callbacks are not intentionally invoked after disposal
- asynchronous callbacks are explicitly launched rather than accidentally discarding a `Future`

Do not solve async races merely by increasing debounce durations.

## Editor save ordering

The editor uses `AsyncSerialQueue` for persistence operations.

Each requested save captures an immutable editor draft before it enters the queue. Capturing matters because live `TextEditingController` values may change before the queued operation executes.

Serial ordering prevents an older slow write from finishing after a newer write and replacing newer text.

The save indicator reflects the draft relationship:

- `idle` — current live draft differs from the last queued/completed save state
- `saving` — the current draft is being persisted
- `saved` — the completed persisted draft still matches current editor content
- `failed` — persistence of the current draft failed

If an older queued draft completes after the user has typed more, its completion does not falsely mark the newer live draft as saved.

## Snapshot behavior

`NoteRepository.saveContent` compares meaningful restorable fields before mutation.

A pre-change history snapshot is created only when content/organization values actually change. Re-saving identical content should not grow version history.

Permanent deletion and empty-trash deletion rely on the database foreign-key cascade so note history is removed with the note.

## Lifecycle save attempts

The editor requests a save on relevant lifecycle transitions and during disposal.

These are best-effort local persistence protections. Mobile operating systems can terminate processes abruptly; no application can guarantee arbitrary asynchronous work after process termination. Regular debounced autosave therefore remains the primary protection during active editing.

## Editor load failure

A note-editor database read can fail—for example because a note was removed or storage is unavailable.

The editor does not continue with empty controllers and risk overwriting unknown data. Instead it renders a safe retryable local-load error state.

User-facing error copy deliberately avoids raw database exception text.

## Formatting safety

Editor formatting operations normalize selection bounds before substring/replace operations, so reversed selections are safe.

Line-prefix actions handle a caret at offset zero explicitly rather than using a negative search boundary.

Formatting modifies only local editor text and then follows normal autosave behavior.

## Backup restore ordering

Backup input is fully parsed and relationship-validated before transactional mutation.

Conflict ordering uses note `updatedAt`:

- newer local note wins
- newer incoming note can replace older local state
- equal timestamp + identical state is a no-op
- equal timestamp + conflicting state is local-wins

The tie rule is intentionally conservative because equal timestamps do not prove that the backup is newer.

History records must reference a note included in the same backup; an existing unrelated local ID is not sufficient validation.

## App-lock recovery

App lock is an optional OS-authentication UI gate, not database encryption.

When enabled, the lock gate attempts device authentication on initial access and relevant resume events.

A reliability edge exists when app lock was previously enabled but the platform later reports authentication unavailable—for example after device configuration/plugin/platform changes. A UI gate with no recovery path can permanently block normal app access.

NoteNest therefore presents an explicit **Disable app lock** recovery action when device authentication is unavailable. The setting is persisted as disabled before normal home access resumes.

This recovery model is consistent with the documented security boundary: local database confidentiality ultimately depends on device/filesystem security, not a NoteNest-owned encryption key.

## File I/O failure behavior

File selection cancellation is a no-op.

Import validation failures do not intentionally mutate local note state.

`BoundedFileReader` prevents path-backed imports from reading arbitrarily large files into memory before enforcing configured limits.

Strict UTF-8 decoding rejects malformed text instead of silently changing bytes.

Export failures keep local notes unchanged and produce safe user-facing feedback.

## Startup failure behavior

Application bootstrap catches initialization failure at the outer boundary.

The UI displays a generic safe startup error rather than raw exception details. Structured diagnostic logging records only safe metadata such as the error type.

## Structured logging

`AppLogger` sanitizes fields before JSON serialization.

Sensitive key fragments are redacted. Arbitrary objects are represented by runtime type rather than `toString()` output. Non-sensitive long strings are bounded using Unicode-scalar-safe truncation.

Callers should still avoid passing private note/search/file content into logs. Redaction is defense in depth, not permission to log sensitive data.

## Adaptive navigation

Compact layouts expose the four primary note collections directly and place Settings/About behind a `More` sheet.

Wide layouts use `NavigationRail`.

The adaptive behavior is covered through app-level widget testing with an injected in-memory database. This avoids depending on filesystem plugins merely to verify navigation layout.

## Dependency injection for tests

`AppDependencies.create` accepts an optional `AppDatabase` and `AppLockService` while preserving production defaults.

This provides a narrow app-level test seam without introducing a global service locator or changing normal application composition.

Use in-memory database injection for deterministic widget/integration tests. Do not introduce production singleton state solely to simplify tests.

## Unicode reliability

Several user-visible or diagnostic paths enforce length bounds. Bounds operate on Unicode scalar values where truncation can occur:

- Markdown preview
- safe export filename
- structured log string

This avoids cutting supplementary Unicode characters between UTF-16 surrogate code units.

## Async callback discipline

The analyzer enables `discarded_futures` and `unawaited_futures`.

For UI callbacks that intentionally launch asynchronous work, use `unawaited(...)` only when the called operation owns its error/state handling. Otherwise make the callback asynchronous and await the result.

This keeps fire-and-forget behavior explicit during review.

## Regression map

Important reliability tests include:

- `test/core/async_serial_queue_test.dart`
- `test/core/bounded_file_reader_test.dart`
- `test/core/markdown_document_codec_test.dart`
- `test/core/safe_file_name_test.dart`
- `test/core/app_logger_test.dart`
- `test/data/note_repository_test.dart`
- `test/data/backup_repository_test.dart`
- `test/data/settings_repository_test.dart`
- `test/widgets/home_shell_navigation_test.dart`
- `test/widgets/note_editor_page_test.dart`
- `test/widgets/note_editor_accessibility_test.dart`
- `test/integration/note_lifecycle_integration_test.dart`
- `tool/test_bootstrap_platforms.py`

## Change-review checklist

When changing asynchronous/persistence code, ask:

- Can an older operation finish after a newer operation?
- What data is captured now versus read later?
- Can a disposed widget/controller receive the completion?
- Can a failed load fall through into a destructive empty state?
- Does a retry duplicate listeners or state?
- Can a malformed backup mutate anything before validation completes?
- Can an equal timestamp cause destructive ambiguity?
- Can a platform capability disappear after a preference was persisted?
- Does an intentionally ignored future have an explicit owner/error path?

A release should not weaken these invariants merely to silence a test or analyzer finding.
