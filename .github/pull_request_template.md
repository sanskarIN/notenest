## Summary

Describe the problem and the focused change made to solve it.

## User-visible behavior

Explain what changes for a NoteNest user. If there is no user-visible change, say so.

## Verification

List the exact commands/checks run, for example:

```text
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter build <platform> ...
```

Do not mark a command as passing if it was not run.

## Screenshots / recordings

For UI changes, attach verified runtime captures when practical. Redact private note content. For non-UI changes, write `Not applicable`.

## Privacy and security impact

- What data/storage/permissions/import/export behavior changed?
- Is any data newly transmitted off-device?
- Did a dependency/native permission change?
- Does SECURITY.md or PRIVACY.md need an update?

## Accessibility impact

Describe keyboard, screen-reader/semantics, text scaling, reduced motion, color/status, and responsive-layout considerations relevant to the change.

## Database / backup compatibility

If no database or backup format changed, write `Not applicable`.

If changed, document:

- Schema version and migration path.
- Migration test added.
- FTS changes if any.
- Backup schema compatibility/conversion.
- Rollback/recovery considerations.

## Checklist

- [ ] The change has one clear purpose and no unrelated churn.
- [ ] I did not commit secrets, signing material, real databases, private backups, or personal note content.
- [ ] Generated Drift files are not tracked.
- [ ] Formatting passes.
- [ ] Static analysis passes.
- [ ] Relevant automated tests pass.
- [ ] New/fixed behavior has regression coverage where practical.
- [ ] Destructive data behavior is clear and safe.
- [ ] UI changes work at narrow and wide sizes.
- [ ] UI changes remain usable with increased text size.
- [ ] Icon-only actions have an accessible purpose/tooltip.
- [ ] Documentation has been updated where behavior/setup changed.
- [ ] CHANGELOG.md is updated for user-visible/release-relevant changes.
- [ ] `what_changed.md` is updated when this work changes the continuation checkpoint.
