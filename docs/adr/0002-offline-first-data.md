# ADR 0002: Offline-first local data ownership

- Status: Accepted
- Date: 2026-08-19

## Context

NoteNest is a simple notes product whose core value must remain available without internet, a cloud subscription, or forced sign-in. Notes may contain personal/sensitive information, so remote processing should not be introduced implicitly.

The app still needs portability and recovery. Users need explicit ways to move or back up their data without turning every edit into a network operation.

## Decision

Core NoteNest data is local-first:

- Current notes and snapshots are stored in a local SQLite database.
- Search is local using SQLite FTS5.
- Core use requires no NoteNest account.
- Backup/export is explicit and user-triggered.
- Markdown import/export is explicit and user-triggered.
- Settings use local preferences.
- Optional app lock delegates to local operating-system authentication.
- Project/support/funding links open externally only after user action.

No implicit remote synchronization, telemetry, advertising, or analytics is required by the core app.

## Backup decision

Provide a versioned JSON backup containing notes and snapshots. Restore must validate the file before mutation and preserve a newer local note when an older backup note conflicts.

Individual Markdown export provides a portable human-readable format for note content; JSON remains the higher-fidelity app backup.

## Consequences

### Positive

- Core note-taking works offline.
- Reduced remote attack/privacy surface.
- No server availability dependency.
- No account lifecycle/recovery burden for core use.
- Users can keep/export their own data.
- Testing can be deterministic without production credentials.

### Tradeoffs

- No automatic multi-device sync in the initial architecture.
- User-managed backup files can themselves contain sensitive content.
- App lock is not equivalent to independently encrypted database storage.
- OS/device backup behavior remains outside the app's direct control.
- Conflict resolution is simple timestamp preservation rather than a rich per-field merge UI.

## Privacy requirements

A future change that sends note content or metadata off-device must not be smuggled in as a routine dependency update. It requires:

1. A new architecture/security review and ADR.
2. Updated `PRIVACY.md` and `SECURITY.md`.
3. Clear user-facing disclosure/consent where applicable.
4. A threat model and deletion/export story.
5. Tests for local/offline behavior and opt-in/default behavior.
6. A migration/compatibility plan.

## Encryption clarification

This decision does not claim application-level encryption at rest. If encrypted database storage is introduced, it requires a maintained cryptographic/storage library, key lifecycle/recovery design, migration strategy, and separate ADR/security review.

## Alternatives considered

### Required account + cloud sync

Rejected for the initial product because it violates the core offline/no-forced-sign-in requirement and adds operational/privacy complexity.

### Plain Markdown files as the only storage model

Provides portability but complicates structured lifecycle flags, snapshots, atomic multi-field updates, indexed search, and future migration behavior. Markdown remains an export/import format instead.

### No backup format

Rejected because local-first ownership should include a deliberate portability/recovery path.

## Follow-up rules

- Keep backup schema explicitly versioned.
- Keep restore validation transactional/conflict-safe.
- Keep documentation honest about local database encryption limitations.
- Do not add remote data processing without a new decision record.
