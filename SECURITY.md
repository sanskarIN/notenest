# Security Policy

Security and privacy are product requirements for NoteNest. The current release-candidate target is **2.0.12**. Please report vulnerabilities responsibly so users have a reasonable chance to update before details are made public.

## Supported versions

Until stable release history exists, security fixes target the current `main` branch and the latest published release. Once multiple maintained release lines exist, this table will be updated explicitly.

| Version | Supported |
|---|---:|
| Latest published release | ✅ when present |
| `main` / current release candidate | ✅ development target |
| Older releases | ❌ unless specifically listed |

## Reporting a vulnerability

**Do not open a public GitHub issue for an unpatched vulnerability.**

Send a private report to:

- `sanskarin@outlook.in`
- `supportramsandesh@gmail.com`

Use a subject such as `NoteNest security report: <short description>`.

Include, when known:

1. Affected version, commit, and platform.
2. Vulnerability category and expected impact.
3. Minimal reproducible steps using fictional/test data.
4. Whether exploitation requires local access, a malicious import/backup file, user interaction, external link handling, or another condition.
5. Relevant logs with personal paths, note content, identifiers, and secrets redacted.
6. A suggested mitigation or patch if you have one.
7. Whether you intend to publish details later and any reasonable disclosure timeline you are proposing.

Never send real credentials, signing keys, private user databases, or unrelated personal data as proof.

## Response process

The maintainer aims to:

1. Acknowledge a complete report as practical.
2. Reproduce and classify the issue.
3. Develop a minimal safe fix plus a regression test where feasible.
4. Review whether backup compatibility, migrations, documentation, or release artifacts also need changes.
5. Publish a patched version before public technical details when coordinated disclosure is warranted.
6. Credit the reporter if requested and appropriate.

No fixed response-time guarantee is made by this volunteer/open-source project.

## Security model

NoteNest is intentionally local-first:

- Core notes are stored in a local SQLite database managed through Drift.
- Core use requires no NoteNest account and no project-operated cloud API.
- Full-text search is local via SQLite FTS5.
- Backups are user-triggered files.
- Optional app lock delegates authentication to the operating system through `local_auth`.
- Repository, support, funding, email, and release links open only after user action.

This architecture reduces remote attack surface but does **not** make the local database automatically encrypted. Device storage protection, OS account security, backups, filesystem permissions, and full-disk encryption remain important. App lock controls app access; it must not be described as database-at-rest encryption.

## Trust boundaries

Treat the following as untrusted input or unreliable platform boundaries:

- JSON backup files.
- Markdown/text imports.
- File names and paths selected by users.
- Platform file-provider results.
- External-link launcher results/exceptions.
- Local preference persistence results.
- Future deep links, share intents, or synchronization payloads if introduced.

Platform/plugin success must not be assumed merely because an API call returned a future.

## File/import safety

Import code must:

- Treat selected files and bytes as untrusted.
- Require expected file types in the picker where practical.
- Avoid requesting eager `withData` loading for native imports.
- Read the native cached file through `BoundedFileReader`.
- Check reported file length before streaming and accumulated bytes after each chunk.
- Enforce 16 MiB for Markdown/text and 64 MiB for NoteNest JSON backups.
- Validate strict UTF-8 before text/JSON processing.
- Avoid executing imported content.

The size ceilings are reliability/memory guardrails, not a claim that every smaller file is trustworthy. A platform/cloud provider may still perform its own caching before NoteNest receives a local path.

## Backup restore safety

Current backup restore rejects malformed input before transaction writes. Validation includes:

- `app == "NoteNest"`.
- Supported backup schema version.
- Typed note/version lists and required fields.
- Serialized `tags` must decode to a list of strings.
- Note and version identifiers cannot be blank or contain surrounding whitespace.
- Incoming note IDs must be unique.
- Version records must reference an incoming or existing note.
- Note/version `colorValue` must be null or an integer in the 32-bit ARGB range `0x00000000` through `0xFFFFFFFF`.
- Stored note/version timestamps must be explicit UTC strings ending in `Z`.
- A note's `updatedAt` cannot precede its `createdAt`.

After validation, restore uses a database transaction and keeps a newer local note instead of replacing it with an older imported copy.

Any future backup-format extension should preserve fail-before-write behavior and add compatibility tests.

## SQL/search safety

Search terms are normalized and supplied through bound Drift/SQLite variables. Do not interpolate untrusted user/import values into executable SQL syntax.

FTS query-building changes require regression tests for punctuation/quotes and collection filtering.

## Export filename safety

Generated Markdown filenames must:

- Replace cross-platform invalid/control characters.
- Remove prohibited trailing dots/spaces.
- Protect Windows reserved device names.
- Remain within the configured basename limit.
- Preserve complete Unicode code points during truncation.

A safe filename is a filesystem-compatibility control, not a content-trust signal.

## Settings/preference safety

Small non-sensitive preferences use a settings repository boundary.

Requirements:

- Do not store credentials, biometric material, or note content in preferences.
- Treat a reported failed preference write as a storage failure.
- Serialize preference mutations whose order affects final state.
- Restore the last persisted visible value when an optimistic write fails and no newer request superseded it.
- Persist onboarding completion before leaving the onboarding screen.
- Surface failure to the user without exposing raw plugin exceptions.

## External-link safety

Feature widgets should not directly invoke the launcher plugin. `ExternalLinkService` contains launcher failures/exceptions and returns a safe boolean result to the caller.

Requirements:

- Open only after explicit user action.
- Use only intended URI values from trusted project configuration/user-visible contact data.
- Show failure feedback when the platform cannot open the URI.
- Do not interpret an external launch as a trusted response from the destination.

## Secrets

The public repository must never contain:

- API keys or access tokens.
- GitHub personal access tokens.
- Passwords or recovery codes.
- Private signing keys or certificate passwords.
- Android keystores, Apple certificates/profiles, or Windows signing credentials.
- Production secrets or generated `.env` values.
- Real user note databases or backups.
- Private endpoints intended to remain secret.

`.gitignore` protects common secret/signing files, but contributors remain responsible for reviewing changes before committing.

If a secret is committed, deleting the file in a later commit is insufficient. Revoke/rotate it immediately and remove it from history when appropriate.

## Dependencies and supply chain

- Dependencies are declared in `pubspec.yaml`.
- Dependabot configuration tracks GitHub Actions and supported package ecosystems where available.
- CI performs release-version synchronization, code generation, formatter/analyzer/tests, repository/documentation checks, and a lightweight secret scan.
- Flutter is pinned to **3.44.7** for the current 2.0.12 candidate in `.flutter-version` and Flutter workflows rather than following an unbounded moving stable SDK.
- Dependency changes should be reviewed for maintenance status, permissions, native behavior, privacy impact, and changed persistence/file/plugin contracts.
- Avoid adding a package for behavior that can be implemented safely and simply with existing dependencies or standard APIs.

## Logging

Do not log raw note bodies, titles, backups, authentication details containing sensitive platform information, credentials, tokens, or full imported file content. Debug logs containing local paths should be sanitized before users publish them.

## Authentication and app lock

The optional app lock uses the operating system's supported authentication mechanisms. Do not:

- Implement a home-grown biometric protocol.
- Store biometric templates.
- Store a plaintext app password.
- Claim that app lock encrypts the SQLite database.

If encrypted-at-rest storage is introduced later, it requires a separate architecture/security review, migration design, recovery story, and maintained cryptographic library.

## Platform permissions

Use least privilege. NoteNest should request only permissions required by enabled features. A new permission requires documentation explaining why it is needed and how related data is used.

## Release metadata integrity

`tool/check_version_sync.py` prevents partial release bumps by requiring package/UI/changelog/release-note version agreement. It is a release-integrity control, not a cryptographic authenticity mechanism.

A published artifact still needs appropriate signing and checksum practices described in [`docs/release.md`](docs/release.md).

## Security review checklist for 2.0.12

Before a stable 2.0.12 tag:

- [ ] `python tool/check_version_sync.py` passes.
- [ ] Review dependency changes and advisories.
- [ ] Search repository history/current tree for accidental secrets.
- [ ] Run formatter, analyzer, tests, repository/link checks, and supported release builds.
- [ ] Exercise malformed and oversized Markdown/backup inputs.
- [ ] Verify native imports use bounded reads rather than eager NoteNest byte loading.
- [ ] Verify strict backup UTC/color/identifier validation.
- [ ] Verify settings persistence failure/rollback behavior on representative platforms.
- [ ] Verify onboarding does not transition on failed persistence.
- [ ] Verify external-link success and no-handler/failure behavior.
- [ ] Verify destructive actions require intended confirmation.
- [ ] Verify restore keeps newer local data.
- [ ] Review native permission/configuration changes.
- [ ] Confirm privacy documentation matches runtime behavior.
- [ ] Confirm no debug-only sensitive logging is enabled.
- [ ] Update this policy if the threat model changed.

## Out of scope for the current architecture

Because NoteNest has no project-operated backend or user account system, reports about server-side session cookies, server CORS, server CSRF, server rate limiting, or remote account takeover are not applicable unless a future release introduces such a service.

Potential weaknesses in Flutter, SQLite, Drift, `shared_preferences`, `file_picker`, `local_auth`, or `url_launcher` should also be reported upstream to relevant maintainers when appropriate; a NoteNest-specific report is still useful if the project needs a mitigation.
