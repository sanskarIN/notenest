# ADR 0001: Flutter + Drift modular monolith

- Status: Accepted
- Date: 2026-08-19

## Context

NoteNest must provide a polished offline-first notes experience on Android, Windows, Linux, macOS, with an iOS-ready codebase. The project needs reliable local persistence, migrations, tests, responsive UI, and maintainable boundaries without inventing a remote backend that core note-taking does not require.

The implementation also needs to be approachable as a strong open-source portfolio project rather than fragmented across unnecessary services.

## Decision

Use:

- Flutter for cross-platform presentation/application runtime.
- Dart for application code.
- Drift as the typed persistence layer.
- SQLite as the local database.
- SQLite FTS5 for full-text search.
- A modular-monolith source layout with explicit dependency wiring.
- Small repository/service/controller abstractions rather than microservices or a required backend.

The primary dependency flow is presentation → controller → repository/service → local infrastructure.

## Why Flutter

Flutter provides one UI codebase for the requested mobile/desktop targets while still allowing native platform integration where required. Material 3, semantics, responsive layout tools, localization support, and strong testing tooling fit the project requirements.

## Why Drift/SQLite

The notes domain benefits from:

- Transactional writes.
- Explicit schema/versioning.
- Local persistence without a server.
- Foreign keys for version-history cleanup.
- FTS5 search.
- Deterministic in-memory database tests.

Drift provides typed Dart APIs/code generation over SQLite while preserving access to custom SQL required for FTS infrastructure.

## Why a modular monolith

A backend/microservice architecture would add deployment, authentication, networking, failure modes, privacy surface, and maintenance cost without improving core offline notes. A modular monolith keeps boundaries clear while allowing later extraction if an actual independently deployed service becomes necessary.

## Consequences

### Positive

- Core notes work offline.
- One primary UI/application language.
- Typed database access.
- Database transactions/migrations available.
- FTS search stays local.
- Repositories/services are testable independently of screens.
- Platform plugins can be isolated behind services.
- No server is required to run/develop core features.

### Tradeoffs

- Native plugin behavior still needs platform-specific build/runtime testing.
- Generated Drift code is required before analysis/build.
- Flutter desktop packaging/signing remains OS-specific.
- Very large libraries may eventually need more SQL-side filtering/pagination.
- A future optional sync service would require a new architecture/security decision rather than being “free” from the current design.

## Alternatives considered

### Separate native apps

Would maximize platform-specific integration but significantly duplicate feature/domain work and increase maintenance burden for the requested platform count.

### Simple JSON/files only

Easier initial persistence but weaker transactional updates, querying, migration discipline, FTS search, and integrity around snapshots/restores.

### Required cloud database/backend

Conflicts with the offline-first/no-required-account product direction and adds unnecessary privacy/operational complexity.

### Microservices

No independently scalable/deployable service boundary currently exists. This would be premature complexity.

## Follow-up rules

- Keep database schema changes migrated/tested.
- Keep UI out of direct table mutation.
- Keep platform behavior behind narrow services.
- Add a new ADR before introducing a required backend, alternate primary database, or large state-management architecture change.
