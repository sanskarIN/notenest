# Security Policy

Security and privacy are product requirements for NoteNest. Current release-candidate target: **2.0.12**. Report vulnerabilities responsibly so users have a chance to update before public technical disclosure.

## Supported versions

| Version | Supported |
|---|---:|
| Latest published release | ✅ when present |
| `main` / current release candidate | ✅ development target |
| Older releases | ❌ unless specifically listed |

## Reporting a vulnerability

**Do not open a public GitHub issue for an unpatched vulnerability.**

Private contacts:

- `sanskarin@outlook.in`
- `supportramsandesh@gmail.com`

Include affected version/commit/platform/browser, category/impact, fictional-data reproduction, required conditions, redacted logs, and suggested mitigation when known. Never send real credentials, signing keys, private databases/backups, or unrelated personal information.

## Security model

NoteNest is local-first across Android, iOS/iPadOS, Windows, macOS, Linux, and Web:

- Notes are stored through Drift/SQLite in the local application/browser environment.
- Core use needs no NoteNest account or project-operated notes API.
- Search is local SQLite FTS5.
- Backups/imports/exports are user-triggered.
- App lock delegates to OS/device authentication only where `local_auth` is implemented.
- External links open only after user action.

Local-first architecture reduces remote service attack surface, but it does **not** automatically encrypt SQLite/browser storage. Device security, OS/browser profile security, filesystem/site-data protections, exported backups, and disk encryption remain important.

## Web trust boundary

The Web build introduces a static-hosting/runtime boundary without introducing project-operated note sync.

Drift Web loads:

- `sqlite3.wasm`
- `drift_worker.js`

from the deployed app origin according to the configured relative URIs. The platform bootstrap obtains those assets from the matching Drift **2.34.3** release and performs basic type/sanity checks.

Security requirements for Web distribution:

- Use HTTPS for public deployment.
- Serve the intended generated bundle and the matching worker/WASM pair.
- Serve `sqlite3.wasm` with `application/wasm`.
- Review hosting/CDN behavior, cache controls, and any third-party scripts separately from NoteNest source.
- Do not inject analytics, remote note processing, or unrelated scripts without privacy/security review.
- Treat browser storage as local data subject to site-data clearing/profile compromise.
- Use JSON backup for portable recovery rather than treating browser internal storage as a cross-origin sync format.

Cross-origin isolation can improve the available Drift storage path on compatible browsers/hosts, but enabling COOP/COEP is a deployment decision that must be validated with the actual origin/resources.

## Trust boundaries

Treat as untrusted or unreliable:

- JSON backups.
- Markdown/text imports.
- File names/paths/bytes/streams selected by users.
- Native/cloud document providers.
- Browser file picker/download behavior.
- Browser storage and deployment-origin configuration.
- External-link launcher results/exceptions.
- Preference persistence results.
- Platform authentication availability/results.
- Future deep links/share/sync payloads.

A plugin/API call returning a Future does not mean the operation succeeded.

## File/import safety

Requirements:

- Treat selected content as untrusted.
- Use expected picker types/extensions where practical.
- Enforce **16 MiB** Markdown/text and **64 MiB** JSON backup ceilings.
- Require strict UTF-8 before text/JSON processing.
- Never execute imported note content.

Native targets:

- Avoid eager picker `withData` loading.
- Use cached path + `BoundedFileReader` where available.
- Validate reported length before streaming and cumulative length during streaming.

Web:

- Request the browser picker's read-stream mode instead of its eager byte-loading default.
- Keep `withData` disabled for NoteNest Web imports.
- Validate picker-reported length before consuming the stream.
- Validate cumulative streamed bytes before adding each chunk to the final NoteNest buffer.
- Re-validate an in-memory byte value if a provider/plugin supplies one despite the stream-first request.
- Do not compile/use `dart:io` path access in the browser.

Size ceilings are reliability/memory guardrails, not trust guarantees. Browser/provider internals can still have their own memory/cache behavior outside NoteNest's direct control.

## Backup restore safety

Restore rejects malformed input before transaction writes. Validation includes:

- `app == "NoteNest"`.
- Supported backup schema.
- Typed notes/versions and required fields.
- Serialized string tags.
- Non-blank identifiers without surrounding whitespace.
- Unique incoming note IDs.
- Valid note/version relationships.
- Null or 32-bit ARGB colors.
- Explicit UTC timestamps ending in `Z`.
- `updatedAt >= createdAt`.
- Valid lifecycle combinations including no archived+trashed and no pinned+trashed.

Restore is transactional and newer local note revisions win older backup conflicts.

## SQL/search safety

Search values are transformed into bound Drift/SQLite variables. Never interpolate untrusted text into executable SQL. FTS query changes require punctuation/quote regressions.

## Export filename safety

Generated Markdown filenames normalize invalid/control characters, trailing dots/spaces, Windows reserved device names, excessive basename length, and Unicode truncation boundaries.

Filename compatibility is not a content-trust signal.

## Settings/preference safety

Preferences are for non-sensitive settings only.

- Never store credentials, biometric data, or note content there.
- Treat failed preference setters as storage failures.
- Serialize ordering-sensitive writes.
- Roll back failed optimistic values when appropriate.
- Persist onboarding completion before navigation.
- Surface failures without exposing raw plugin internals.

## Authentication and app lock

Current `local_auth 3.0.2` support is used on supported Android/iOS/macOS/Windows environments. Web and Linux currently report app-lock device authentication unavailable.

Requirements:

- Never implement home-grown biometric matching.
- Never store biometric templates.
- Never store a plaintext custom app password just to create false platform parity.
- Never claim app lock encrypts the database.
- Unsupported platforms must remain usable even if a stale app-lock-enabled preference exists.

If encrypted-at-rest storage is introduced later, it needs a separate threat model, migration/recovery design, maintained cryptographic library, and security review.

## External-link safety

Feature code uses `ExternalLinkService` rather than direct plugin invocation.

- Open only after explicit user action.
- Use intended trusted project/contact URIs.
- Contain launcher refusal/exceptions.
- Show failure feedback.
- Do not treat a successful launch as a trusted response from the external destination.

## Secrets

Never commit:

- API keys/access tokens.
- GitHub tokens.
- Passwords/recovery codes.
- Private signing keys/certificate passwords.
- Android keystores or Apple/Windows signing material.
- Secret `.env` values.
- Real user databases/backups.
- Private endpoints intended to remain secret.

If a secret is committed, deleting it later is insufficient: revoke/rotate it and clean history where appropriate.

## Generated platform source policy

Android, iOS, Linux, macOS, Windows, Web runner trees plus Flutter `.metadata` are generated from the pinned toolchain/bootstrap recipe and are ignored by Git. `tool/check_repo.py` enforces that the generated runner prefixes remain untracked and that the required ignore rules are present.

The application dependency lockfile is deliberately **not** ignored because stable application releases require it to become tracked once issue #8 is completed.

## Dependencies and supply chain

- Dependencies are declared in `pubspec.yaml`.
- Flutter is pinned to **3.44.7**.
- Drift Web runtime assets are tied by bootstrap policy to direct dependency Drift **2.34.3**.
- Dependabot tracks supported dependency/workflow ecosystems.
- Dependency changes require review of maintenance status, platform coverage, permissions, privacy, persistence/file/plugin behavior, and Web runtime compatibility.
- A `drift` version change must update/review the Web runtime asset pin in the same workstream.

### Application lockfile requirement

Stable 2.0.12 must commit the genuine resolver-generated `pubspec.lock` produced by Flutter 3.44.7. Issue #8 tracks this. Do not fabricate lockfile hashes/versions.

After the lock is committed, final CI/release verification should enforce it so dependency resolution cannot silently drift between verified and published artifacts.

## Logging

Do not log raw note content, backups, credentials/tokens, sensitive authentication details, complete imported content, private browser storage contents, or unredacted personal paths/origins.

## Platform permissions/capabilities

Use least privilege. A new native permission or browser capability requires user benefit, architecture/security review, and matching privacy/release documentation.

## Release integrity

`tool/check_version_sync.py` prevents partial release/toolchain version bumps. `tool/check_repo.py` protects required cross-platform source/automation/generated-runner policy, and `tool/check_repository_reference.py` currently requires all **108 tracked files** to be cataloged.

These are integrity/process controls, not cryptographic artifact authenticity. Distributed native artifacts still need appropriate signing; distributed files should have checksums as documented in [`docs/release.md`](docs/release.md).

## Security review checklist for 2.0.12

Before stable tag:

- [ ] Resolver-generated `pubspec.lock` committed/reviewed/enforced.
- [ ] Version/repository/reference/link/secret gates pass.
- [ ] Formatter/analyzer/Flutter tests pass.
- [ ] Dependency/advisory review complete.
- [ ] Android/Linux/Windows/macOS/iOS/Web build matrix green.
- [ ] Chrome browser fallback test green.
- [ ] Malformed/oversized native and Web imports exercised.
- [ ] Backup UTC/color/identifier/lifecycle validation verified.
- [ ] Native/Web file picker/export behavior verified.
- [ ] Web worker/WASM MIME/reachability and persistence verified on intended origin.
- [ ] Settings rollback/onboarding persistence verified.
- [ ] External-link success/failure verified.
- [ ] Supported app-lock targets verified.
- [ ] Web/Linux unavailable app-lock paths verified usable.
- [ ] Destructive confirmations and newer-local restore preservation verified.
- [ ] Permissions/deployment headers/hosting scripts reviewed.
- [ ] Privacy documentation matches actual distribution.
- [ ] No sensitive debug logging or real user data in repository/artifacts.

## Out of scope for current architecture

There is no NoteNest-operated user account/session/backend, so server-side account takeover, NoteNest session cookies, project API CSRF/rate limits, or server database authorization are not current product surfaces unless a future release introduces them.

A Web host may of course have its own server/CDN configuration vulnerabilities; those are distribution/deployment responsibilities unless they arise from NoteNest's required serving configuration.

Potential weaknesses in Flutter, SQLite, Drift, `shared_preferences`, `file_picker`, `local_auth`, or `url_launcher` should also be reported upstream where appropriate; NoteNest-specific mitigation reports are still useful.
