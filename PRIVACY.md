# NoteNest Privacy

Last updated: 2026-08-19

This document describes the privacy behavior of the open-source NoteNest code in this repository. A distributor who modifies the app, adds services, or publishes a store build is responsible for updating privacy disclosures so they match that build.

## Summary

The core NoteNest application is designed to work without a NoteNest account, advertising network, analytics service, or project-operated cloud server. Note content is stored locally using Drift/SQLite. The user explicitly chooses when to import/export a file or open an external project/support link.

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

## Import and export

When the user chooses an import or export action, NoteNest uses the platform file picker. Depending on the operating system and file-picker implementation, the system may show storage providers available to the user, including providers managed by third parties. The user controls the selected destination/source.

Supported project flows include:

- Importing UTF-8 Markdown/text as a new note.
- Exporting a note as Markdown.
- Exporting NoteNest data and version snapshots as JSON.
- Restoring a validated NoteNest JSON backup.

Exported files are no longer protected by NoteNest itself. Their privacy depends on where the user saves, copies, sends, or backs them up.

## Backup contents

A NoteNest JSON backup can contain note content and version history. Treat backups as sensitive user files. The current backup format is readable JSON and must not be described as encrypted.

Restore validation checks that the data identifies as a NoteNest backup, uses a supported schema version, and contains expected field types/timestamps before applying changes. Newer local notes are preserved when an older backup copy conflicts.

## Optional app lock

If enabled and supported, NoteNest asks the operating system to authenticate the user through `local_auth`. The app does not implement its own biometric matching and does not receive or store biometric templates.

App lock is an access-control convenience. It is **not** a claim that the SQLite database is independently encrypted at rest. Device lock, operating-system security, filesystem protections, and disk encryption remain important.

## External links

The About screen includes user-initiated links for:

- GitHub/repository information.
- Buy Me a Coffee funding.
- Business/support email.

Opening one of these links hands the URL or email action to the operating system and the user's chosen external application. The privacy practices of the external service/app then apply.

## Analytics and advertising

The current repository does not intentionally include analytics, behavioral tracking, advertising SDKs, or a required donation flow. Funding is optional and does not unlock core functionality.

If a fork/distributor adds analytics, crash reporting that uploads data, ads, remote sync, accounts, AI processing, telemetry, or other networking, this privacy document must be revised before distribution.

## Network access

Core note creation, editing, organization, search, snapshots, and local settings are designed for offline use. NoteNest has no project-operated remote notes API in the current architecture.

Platform package managers, operating systems, store clients, external browsers/mail clients, and development tooling may independently use the network; that is outside the core app's local note-processing behavior.

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
- Permanently deleting a note removes its current database row and, through the configured foreign-key behavior, its associated version rows.
- Emptying trash permanently deletes all notes currently marked as trashed.

Copies may still exist outside NoteNest if the user previously exported/backed up data or if the operating system/filesystem maintains backups.

## Data portability

Users can export NoteNest data as JSON and individual notes as Markdown. The JSON format includes a version identifier so incompatible backup formats can be rejected instead of silently misinterpreted.

## Security

Security practices and responsible disclosure are documented in [SECURITY.md](SECURITY.md). Do not send private note data in a public issue to demonstrate a bug.

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
