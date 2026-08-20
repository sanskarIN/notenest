# NoteNest Privacy

Last updated: 2026-08-20
Current release-candidate target: **2.0.12**

This document describes the privacy behavior of the open-source NoteNest code in this repository. A distributor who modifies the app, hosting, services, or store build is responsible for updating disclosures to match that distribution.

## Summary

Core NoteNest works without a NoteNest account, advertising network, analytics service, or project-operated note-sync server. Note content remains in local application/browser storage. Users explicitly choose when to import/export data or open an external project/support/funding/release link.

NoteNest targets Android, iOS/iPadOS, Windows, macOS, Linux, and Web. Platform storage mechanisms differ, but the core architecture does not introduce project-operated note synchronization merely because a Web build exists.

## Local data

NoteNest may store locally:

- Note IDs, titles, bodies, folders, tags, colors, timestamps, and lifecycle flags.
- Note version snapshots.
- Appearance/text-scale/reduced-motion preferences.
- Onboarding completion state.
- Whether optional app lock is enabled.

Current project code does not intentionally upload these values to a NoteNest-operated note service.

### Native targets

Drift uses local SQLite storage appropriate to the Flutter platform/runtime.

### Web

Drift uses browser-local SQLite through generated `sqlite3.wasm` and `drift_worker.js` runtime assets. Browser storage is associated with the browser/profile/origin and is subject to that browser's storage policies. Users or browsers can clear site data; private/incognito sessions may have different persistence rules.

A Web host necessarily serves/downloads the static Flutter bundle, worker, WASM, images, and other application assets. Downloading those application resources is different from NoteNest uploading users' note contents. A distributor that adds telemetry, remote APIs, third-party scripts, CDN logging beyond normal hosting, or note processing must disclose that separately.

JSON backup export is the portable recovery mechanism between installations/browser origins/profiles; raw browser database storage should not be treated as a sync format.

## Full-text search

Search runs locally using SQLite FTS5 over title, body, folder, and serialized tags. Collection-specific filter metadata is also computed from local note state.

## Import and export

Users initiate file operations through `file_picker`.

Supported flows:

- Import UTF-8 Markdown/text.
- Export a note as Markdown.
- Export notes/version history as JSON.
- Restore a validated NoteNest JSON backup.

Limits:

- Markdown/text: **16 MiB**.
- JSON backup: **64 MiB**.

### Native import boundary

Native targets request picker-provided cached paths and use bounded incremental reads before decoding. A platform/cloud document provider may perform its own caching/access before NoteNest receives a local path; provider privacy rules are outside NoteNest's direct control.

### Web import boundary

Browsers do not expose native filesystem paths in the same way. NoteNest requests picker bytes on Web, validates the picker-reported size, and validates actual byte/stream length before UTF-8/format processing.

Browser file selection/download behavior is controlled partly by the browser. Exported files leave NoteNest's local storage boundary and their privacy depends on where the user saves, uploads, shares, or backs them up.

## Backup contents and validation

A NoteNest JSON backup can contain complete note content and version history. It is readable JSON and **not encrypted**.

Restore validation checks app/schema identity, types, tags, IDs/relationships, UTC timestamps, timestamp order, 32-bit colors, and lifecycle combinations before writes. Newer local notes are preserved in conflicts.

Integrity validation does not make an exported backup confidential.

## Preferences

Non-sensitive preferences include appearance, text scale, reduced motion, onboarding completion, and app-lock enabled state.

NoteNest does not intentionally store note bodies, passwords, biometric templates, or authentication secrets in preferences. Reported persistence failures are treated as errors and visible state rolls back when appropriate; onboarding is persistence-first.

## Optional app lock

Where `local_auth` is implemented, NoteNest delegates authentication to the operating system. It does not perform biometric matching or receive/store biometric templates.

Current dependency support means device authentication is available only on supported Android/iOS/macOS/Windows environments. Web and Linux currently report app lock unavailable. NoteNest intentionally does not create a custom browser/Linux credential system merely to claim parity.

App lock is UI access control, **not SQLite/browser-database encryption at rest**.

## External links

User-triggered external actions include repository/GitHub Releases, funding, and business/support email links. The chosen browser/mail/external application and destination service then apply their own privacy practices.

`ExternalLinkService` contains launcher failures but does not make those destinations part of NoteNest's local trusted data boundary.

## Analytics and advertising

The current repository intentionally includes no analytics, behavioral tracking, advertising SDK, or required donation flow. Funding is optional and does not unlock core functionality.

A fork/distributor adding analytics, crash uploading, ads, remote sync, accounts, AI processing, telemetry, or other remote processing must revise privacy/security/user disclosures before distribution.

## Network access

Native core note workflows are designed for local/offline operation after app/dependency installation. Web must load its static application assets from its host before it can run; after load, core note operations remain browser-local under the current architecture.

Network-capable actions also occur when the user deliberately opens external links or uses a file provider that itself accesses cloud storage.

Development/bootstrap tooling downloads the pinned Drift Web runtime assets while preparing builds. That build-time dependency is not a runtime note-upload path.

## Web hosting considerations

A distributor of the Web build controls the deployment origin, TLS, server/CDN logs, cache policy, headers, and any added scripts. Those deployment choices can materially affect privacy and must be reviewed separately.

NoteNest itself does not require third-party analytics scripts to host the static Web bundle.

Cross-origin isolation headers may be configured for optimal Drift browser storage on compatible deployments. They are serving/runtime configuration, not permission to add unrelated cross-origin trackers.

## Permissions

Request only capabilities required by enabled platform features. Native file access is mediated through picker capabilities; supported device authentication uses OS APIs. Browser file selection/download uses browser-mediated user actions.

Any future permission/capability must have a clear user benefit and matching documentation.

## Logs

Application code should not log raw note text, backups, credentials, tokens, biometric/authentication data, or sensitive paths. Contributors must redact private paths/origins/storage contents before public bug reports.

## Data deletion

- Trash keeps a note recoverable locally.
- Restore removes trash state.
- Permanent delete removes the current note and cascading version rows from the active NoteNest database.
- Empty trash permanently removes all trashed rows.

Copies may still exist in exported backups/files, operating-system/browser backups, provider caches, browser synchronization of site data if enabled by the browser vendor, or other user-controlled storage outside NoteNest.

Clearing browser site data can delete Web-local NoteNest data independently of in-app deletion actions.

## Data portability

Users can export JSON backups and individual Markdown notes. The backup format has its own version identity so incompatible payloads can be rejected.

Use JSON backup for cross-platform migration/recovery rather than copying internal SQLite/browser storage files.

## Children and accounts

The current app does not require an account, collect a declared age, or operate a remote user-profile service. Distributors must assess applicable store/legal requirements for their audience and region.

## Security

See [`SECURITY.md`](SECURITY.md). Never include real note data or backups in a public issue.

## Changes to privacy behavior

Any new data collection, remote transmission, third-party SDK processing, account requirement, hosting script, sync path, or materially different storage model requires:

1. Architecture/security review.
2. Updated privacy documentation.
3. Appropriate UI disclosure/consent.
4. Tests for defaults/opt-in behavior.
5. Changelog/release-note updates.

## Contact

- Business: `sanskarin@outlook.in`
- Business: `sanskarin.business@gmail.com`
- Support: `supportramsandesh@gmail.com`
- GitHub: <https://github.com/sanskarIN>

---

**Made by the Sanskar**
