# NoteNest Privacy

Last updated: 2026-08-19
Current release-candidate target: **2.0.12**

This document describes the privacy behavior of the open-source NoteNest code in this repository. A distributor who modifies the app, adds services, or publishes a store build is responsible for updating privacy disclosures so they match that build.

## Summary

Core NoteNest is designed to work without a NoteNest account, advertising network, analytics service, or project-operated cloud server. Note content is stored locally using Drift/SQLite. The user explicitly chooses when to import/export a file, enable operating-system-backed app lock, or open an external project/support/funding/release link.

## Data stored locally

NoteNest may store the following on the device:

- Note identifiers.
- Note titles and bodies.
- Folder names.
- Tags.
- Note color choice.
- Pinned/favorite/archive/trash state.
- Creation/update timestamps.
- Note version snapshots.
- Appearance preferences.
- Text-scale and reduced-motion preferences.
- Onboarding completion state.
- Whether optional app lock is enabled.

These values support normal app functionality. Current project code does not upload them to a NoteNest-operated service.

## Full-text search

Search is performed locally using SQLite FTS5. Indexed content includes note title, body, folder, and serialized tags. The search index is stored with the local database environment and maintained by database triggers.

Collection-specific folder/tag filter options are also computed locally from the corresponding note collection.

## Import and export

When the user chooses an import or export action, NoteNest uses the platform file picker. Depending on the operating system and provider, the picker may expose local or third-party/cloud storage locations. The user controls the selected source/destination.

Supported project flows include:

- Importing UTF-8 Markdown/text as a new note.
- Exporting a note as Markdown.
- Exporting NoteNest data and version snapshots as JSON.
- Restoring a validated NoteNest JSON backup.

For native imports, NoteNest requests a cached file path rather than eager file bytes, then applies its own bounded read before decoding:

- Markdown/text ceiling: 16 MiB.
- JSON backup ceiling: 64 MiB.

The platform picker/provider may still cache or access the file before NoteNest receives the path. That provider's privacy behavior is outside NoteNest's direct control.

Exported files are no longer protected by NoteNest itself. Their privacy depends on where the user saves, copies, sends, or backs them up.

## Backup contents and validation

A NoteNest JSON backup can contain note content and version history. Treat backups as sensitive user files. The current backup format is readable JSON and must not be described as encrypted.

Restore validation checks application identity, supported schema version, expected field types, serialized tags, identifiers/relationships, 32-bit color values, explicit UTC timestamps, and note timestamp ordering before database changes. Newer local notes are preserved when an older backup copy conflicts.

These validation rules protect integrity/reliability; they do not make an exported JSON backup private or encrypted.

## Preferences

Non-sensitive app preferences are stored separately from note data, including appearance, text scale, reduced motion, onboarding completion, and whether app lock is enabled.

NoteNest does not intentionally store note bodies, passwords, biometric templates, or authentication secrets in this preference store.

The application treats reported preference-write failures as errors. Visible preference state is restored to the last persisted value when applicable; onboarding completion is persisted before leaving onboarding.

## Optional app lock

If enabled and supported, NoteNest asks the operating system to authenticate the user through `local_auth`. The app does not implement its own biometric matching and does not receive or store biometric templates.

App lock is an access-control convenience. It is **not** a claim that the SQLite database is independently encrypted at rest. Device lock, operating-system security, filesystem protections, and disk encryption remain important.

## External links

User-initiated external actions include:

- GitHub/repository information.
- GitHub Releases information.
- Buy Me a Coffee funding.
- Business/support email actions.

Opening one hands the URI/email action to the operating system and the user's chosen external application. The privacy practices of that external service/app then apply.

NoteNest uses a small launcher service that contains platform launcher failures/exceptions and reports failure to the UI. It does not make the destination itself part of NoteNest's trusted local data boundary.

## Analytics and advertising

The current repository does not intentionally include analytics, behavioral tracking, advertising SDKs, or a required donation flow. Funding is optional and does not unlock core functionality.

If a fork/distributor adds analytics, crash reporting that uploads data, ads, remote sync, accounts, AI processing, telemetry, or other networking, this privacy document must be revised before distribution.

## Network access

Core note creation, editing, organization, search, snapshots, settings, and backup processing are designed for offline use. NoteNest has no project-operated remote notes API in the current architecture.

External links are network-capable only because the user explicitly opens an external URI/application. Platform package managers, operating systems, store clients, external browsers/mail clients, storage providers, and development tooling may independently use the network; that behavior is outside the core app's local note processing.

## Permissions

NoteNest should request only permissions needed by enabled platform features. File access is mediated through file-picker capabilities, and optional app lock relies on supported device authentication. Native runner configuration is generated from the documented bootstrap process.

Any future permission must have a clear user benefit and corresponding privacy documentation.

## Logs

Application code should not log raw note content, backups, passwords, tokens, or sensitive authentication information. Contributors should redact personal file paths and note content from diagnostics before posting them publicly.

## Children and accounts

The current app does not require an account, collect a declared age, or operate a remote user-profile system. Distributors must review applicable store and legal requirements for their target audience and region; this repository is not a substitute for legal advice.

## Data deletion

Within the app:

- Moving a note to trash keeps it recoverable locally.
- Restoring removes the trash state.
- Permanently deleting a note removes its current database row and, through configured foreign-key behavior, associated version rows.
- Emptying trash permanently deletes all notes currently marked as trashed.

Copies may still exist outside NoteNest if the user previously exported/backed up data or if the operating system/filesystem/provider maintains backups.

## Data portability

Users can export NoteNest data as JSON and individual notes as Markdown. The JSON format includes a version identifier so incompatible backup formats can be rejected instead of silently misinterpreted.

Generated Markdown filenames are normalized for cross-platform filesystem compatibility. This filename normalization does not alter the note content stored inside the exported file.

## Security

Security practices and responsible disclosure are documented in [`SECURITY.md`](SECURITY.md). Do not send private note data in a public issue to demonstrate a bug.

## Changes to privacy behavior

A change that introduces new data collection, remote transmission, third-party SDK processing, account requirements, or a materially different storage model should include:

1. Architecture/security review.
2. Updated privacy documentation.
3. Updated UI disclosure/consent where applicable.
4. Tests for opt-in/default behavior.
5. Changelog entry.

## Contact

- Business: `sanskarin@outlook.in`
- Business: `sanskarin.business@gmail.com`
- Support: `supportramsandesh@gmail.com`
- GitHub: <https://github.com/sanskarIN>

---

**Made by the Sanskar**
