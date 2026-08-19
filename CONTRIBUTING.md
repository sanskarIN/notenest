# Contributing to NoteNest

Thank you for improving NoteNest. The project values small, understandable changes that preserve its offline-first privacy model and remain maintainable across Android and desktop platforms.

## Before you start

1. Read the [Code of Conduct](CODE_OF_CONDUCT.md).
2. Read the [Security Policy](SECURITY.md). Do not open a public issue for a vulnerability that could put users or data at risk.
3. Check existing issues and pull requests to avoid duplicating work.
4. For a large architectural change, open a feature discussion/issue first so the design can be agreed before a large implementation is written.

## Development environment

Follow [docs/setup.md](docs/setup.md), then generate platform runners and dependencies:

```bash
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Configure the requested project commit email if you are contributing under this repository identity:

```bash
git config user.email "sanskarin@outlook.in"
```

Do not commit signing credentials, tokens, `.env` secrets, local databases, or personal note exports.

## Branches

Create a focused branch from the current default branch:

```bash
git switch main
git pull --ff-only
git switch -c feat/short-description
```

Suggested prefixes include `feat/`, `fix/`, `docs/`, `test/`, `refactor/`, and `chore/`.

## Code standards

- Follow Dart and Flutter idioms.
- Keep analyzer strictness enabled.
- Prefer explicit dependency wiring over hidden service locators or mutable globals.
- Keep UI concerns out of repositories.
- Keep storage details out of widgets.
- Keep reusable pure logic in `core/` or domain modules where practical.
- Validate imported/untrusted data before persistence.
- Never add custom cryptography when a maintained platform/library primitive is suitable.
- Keep user-facing destructive actions reversible where practical; permanently destructive operations require clear confirmation.
- Preserve accessibility semantics, keyboard usability, contrast, text scaling, and reduced-motion behavior.
- Do not add required cloud accounts, analytics, tracking, or advertising to core offline functionality.

## Database changes

Any released-schema modification must:

1. Increment `AppDatabase.schemaVersion`.
2. Add a forward migration in the migration strategy.
3. Preserve existing user data.
4. Update FTS triggers/indexes when indexed columns change.
5. Add a migration test from the previous schema.
6. Update `docs/architecture.md`, `CHANGELOG.md`, and any backup schema rules if required.

Never silently reinterpret an existing column in a way that corrupts previously stored values.

## Generated code

Drift-generated `*.g.dart` files are intentionally ignored. Regenerate them before analysis/tests:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated native platform runners are also produced using:

```bash
python tool/bootstrap_platforms.py
```

Do not hand-edit generated files unless the change is part of the documented bootstrap patching process.

## Tests

Every behavior change should have the smallest useful regression coverage. Appropriate layers include:

- Pure unit tests for parsers/helpers.
- Repository/database tests with an in-memory SQLite database.
- Widget tests for interaction and accessibility behavior.
- Integration/end-to-end coverage for important multi-screen journeys when platform tooling is available.

Run the quality gate before opening a pull request:

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
```

If you change platform-specific code, also run the applicable release/debug build described in [docs/release.md](docs/release.md).

## Commits

Use meaningful, atomic commits. Conventional Commits are preferred:

```text
feat: add note sort preference
fix: avoid overwriting newer restore target
test: cover invalid backup timestamp
docs: clarify Windows setup
refactor: isolate note filtering rules
perf: reduce repeated note list reads
ci: verify Android build
chore: update dependency constraints
```

Do not create empty commits or meaningless churn solely to increase commit count.

## Pull requests

A good pull request:

- Has one clear purpose.
- Explains user-visible behavior and architectural impact.
- Links related issues.
- Includes tests for changed behavior.
- Includes screenshots for visible UI changes when possible.
- Notes accessibility and privacy impact.
- Updates documentation and changelog entries when appropriate.
- Has no unresolved formatter/analyzer/test failures.

The PR template contains a detailed checklist.

## Documentation changes

Documentation is part of the product. Commands must match the repository. Do not claim a workflow, platform build, test result, or screenshot exists unless it actually exists.

When changing setup/build requirements, update all directly affected documents rather than leaving conflicting instructions.

## Reporting bugs

Use the bug report template and include:

- NoteNest version/commit.
- Flutter version.
- Operating system/device.
- Reproduction steps.
- Expected vs actual result.
- Relevant logs with private note content and local paths redacted.

Never publish a real notes database or sensitive backup just to reproduce a bug. Create a minimal fictional fixture instead.

## Feature requests

Explain the problem before prescribing an implementation. Requests that preserve the product's local-first, accessible, non-intrusive character are the best fit.

## License

By contributing code or documentation, you agree that your contribution may be distributed under the repository's [MIT License](LICENSE).
