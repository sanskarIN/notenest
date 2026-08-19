# Security Policy

Security and privacy are part of NoteNest's product requirements. Please report vulnerabilities responsibly so users have a reasonable chance to update before details are made public.

## Supported versions

Until a stable release history exists, security fixes target the current `main` branch and the latest published release. Once multiple maintained release lines exist, this table will be updated explicitly.

| Version | Supported |
|---|---:|
| Latest release | ✅ |
| `main` | ✅ development target |
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
4. Whether exploitation requires local access, a malicious import file, user interaction, or another condition.
5. Relevant logs with personal paths, note content, identifiers, and secrets redacted.
6. A suggested mitigation or patch if you have one.
7. Whether you intend to publish details later and any reasonable disclosure timeline you are proposing.

Never send real credentials, signing keys, private user databases, or unrelated personal data as proof.

## Response process

The maintainer aims to:

1. Acknowledge a complete report as practical.
2. Reproduce and classify the issue.
3. Develop a minimal safe fix plus a regression test where feasible.
4. Review whether backup compatibility, migration behavior, documentation, or releases also need changes.
5. Publish a patched version before public technical details when the risk warrants coordinated disclosure.
6. Credit the reporter if requested and appropriate.

No fixed response-time guarantee is made by this volunteer/open-source project.

## Security model

NoteNest is intentionally local-first:

- Core notes are stored in a local SQLite database managed through Drift.
- Core use requires no NoteNest account and no project-operated cloud API.
- Full-text search is local via SQLite FTS5.
- Backups are user-triggered files.
- Optional app lock delegates authentication to the operating system through `local_auth` rather than implementing custom password or biometric verification.
- External project, support, and funding links open only after a user action.

This architecture reduces remote attack surface but does **not** make a local database automatically encrypted. Device storage protection, OS account security, backups, filesystem permissions, and full-disk encryption remain important. The app-lock feature controls app access; it must not be described as database-at-rest encryption.

## Trust boundaries

Treat the following as untrusted input:

- JSON backup files.
- Markdown/text imports.
- File names and paths selected by users.
- Future deep links, share intents, or synchronization payloads if those features are introduced.

Current backup restore validates application identity, backup schema version, required value types, timestamps, serialized tags, and note/version relationships before database changes. Restore writes occur transactionally, and newer local notes are not replaced by older imported copies.

## Secrets

The public repository must never contain:

- API keys or access tokens.
- GitHub personal access tokens.
- Passwords or recovery codes.
- Private signing keys or certificate passwords.
- Android keystores, Apple certificates/profiles, or Windows signing credentials.
- Production secrets or generated `.env` values.
- Real user note databases or backups.
- Private production endpoints that are intended to remain secret.

`.gitignore` protects common secret/signing files, but contributors remain responsible for reviewing changes before committing.

If a secret is committed, deleting the file in a later commit is insufficient. Revoke/rotate the secret immediately and remove it from history when appropriate.

## Dependencies and supply chain

- Dependencies are declared in `pubspec.yaml`.
- Dependabot configuration tracks GitHub Actions and supported package ecosystems where GitHub can do so.
- CI uses pinned major action versions from established providers and performs formatter/analyzer/test checks.
- The Flutter SDK is pinned to the repository's release-candidate version in `.flutter-version` and CI/release workflows rather than following an unbounded moving stable channel.
- Dependency changes should be reviewed for maintenance status, permissions, native behavior, and privacy impact.
- Avoid adding a package for behavior that can be implemented safely and simply with existing dependencies or Flutter/Dart APIs.

## File and backup safety

Import/export code must:

- Treat selected files and their bytes as untrusted.
- Require expected file types in the picker where practical.
- Avoid requesting eager `withData` loading for native imports.
- Read the native cached file through a bounded reader that checks the reported file length and every streamed chunk before adding it to the final buffer.
- Enforce the current import ceilings: 16 MiB for Markdown/text and 64 MiB for NoteNest JSON backups.
- Validate UTF-8 decoding.
- Parse and validate JSON before writes.
- Reject unsupported backup schema versions.
- Validate backup note/version relationships before opening the restore transaction.
- Avoid executing imported content.
- Normalize generated export filenames for cross-platform reserved characters/names.
- Avoid interpolating untrusted values into SQL syntax; use Drift/query parameters.

The size bounds are memory-safety/reliability guardrails, not a claim that every file below the limit is trustworthy. The platform picker may still perform its own caching before NoteNest receives a local file path, and structured content validation still applies after the bounded read and decoding steps.

## Logging

Do not log raw note bodies, titles, backups, authentication results containing sensitive platform detail, credentials, or tokens. Debug logs that include local paths should be sanitized before users publish them in issues.

## Authentication and app lock

The optional app lock uses the operating system's supported authentication mechanisms. Do not:

- Implement a home-grown biometric protocol.
- Store biometric templates.
- Store a plaintext app password.
- Claim that app lock encrypts the SQLite database.

If stronger encrypted-at-rest storage is introduced later, it requires a separate architecture/security review, migration design, recovery story, and maintained cryptographic library.

## Platform permissions

Use least privilege. NoteNest should request only permissions required by enabled features. A new permission requires documentation explaining why it is needed and how the related data is used.

## Security review checklist for releases

Before a stable release:

- [ ] Review dependency changes and advisories.
- [ ] Search repository history/current tree for accidental secrets.
- [ ] Run formatter, analyzer, tests, repository/link checks, and supported release builds.
- [ ] Exercise malformed and oversized import/backup inputs.
- [ ] Verify native imports use bounded reads rather than eager byte loading.
- [ ] Verify destructive actions require intended confirmation.
- [ ] Verify restore keeps newer local data.
- [ ] Review native permission/configuration changes.
- [ ] Confirm privacy documentation matches runtime behavior.
- [ ] Confirm no debug-only sensitive logging is enabled.
- [ ] Update this policy if the threat model changed.

## Out of scope for the current architecture

Because NoteNest has no project-operated backend or user account system, reports about server-side session cookies, server CORS, server CSRF, server rate limiting, or remote account takeover are not applicable unless a future release introduces such a service.

Potential weaknesses in Flutter, SQLite, Drift, or operating-system authentication should also be reported upstream to the relevant maintainers when appropriate; a NoteNest-specific report is still useful if the project needs a mitigation.
