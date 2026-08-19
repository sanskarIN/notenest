# NoteNest Accessibility

NoteNest aims for WCAG-oriented inclusive design across mobile and desktop. This document describes implementation expectations and release checks; it does **not** claim formal WCAG certification.

## Principles

- Core workflows must not depend on color alone.
- Interactive controls need understandable names and sufficiently large targets.
- Keyboard users should be able to reach and activate important desktop actions.
- Text must remain usable when scaled.
- Layouts must adapt to narrow/wide windows without hiding essential functionality.
- Screen-reader users should receive useful semantics rather than decorative noise.
- Optional motion should respect reduced-motion preference.
- Destructive actions must communicate consequences clearly.

## Current foundations

The app primarily uses standard Flutter Material controls, which provide baseline semantics/focus behavior. Project-specific additions include:

- Tooltips for icon-only note/editor actions.
- A semantic label on note cards.
- A semantic save-state indicator.
- Material buttons/chips/list tiles rather than tiny custom hit areas.
- Responsive `NavigationBar` and `NavigationRail`.
- Adjustable app text scale.
- Reduced-motion preference propagated through `MediaQuery.disableAnimations`.
- Light/dark color schemes generated from a stable seed.
- Text/icons accompanying destructive lifecycle actions.

## Text scaling

Settings currently allow an additional scale from 90% to 140%. The operating system/framework may also provide accessibility text scaling. UI changes should be tested with increased system text size, not only the in-app setting.

Avoid fixed-height containers around multiline text. Prefer wrapping, flexible layout, and scrollable surfaces.

Critical screens to verify at large text sizes:

- Onboarding.
- Notes search/filter row.
- Note cards.
- Editor app bar and metadata fields.
- Settings segmented theme control.
- About contact tiles.
- Confirmation dialogs.

If a layout cannot fit horizontally, it should adapt/scroll rather than clip important labels.

## Color and contrast

Material color schemes provide a baseline, but custom note colors use translucent surfaces and must keep foreground text/theme colors readable.

Rules:

- Never encode archive/trash/favorite state only through note color.
- Selected state should have icon/text/shape cues in addition to color.
- Do not place arbitrary user-chosen color directly behind low-contrast custom text without contrast handling.
- Check both light and dark themes.
- Check disabled controls remain distinguishable without appearing active.

## Keyboard navigation

Desktop release review should verify, using only keyboard where practical:

1. Reach navigation destinations.
2. Reach search field.
3. Create/open a note.
4. Move among title/body/folder/tags controls.
5. Reach formatting and action buttons.
6. Open/choose popup-menu actions.
7. Navigate Settings controls.
8. Confirm/cancel destructive dialogs.
9. Return/back without pointer use.

Flutter's default focus traversal should be preserved unless a custom order is clearly needed. If a future layout creates confusing traversal, define an explicit focus order and test it.

## Shortcuts

The initial app uses standard text/editor keyboard behavior but does not yet advertise a custom global shortcut set. Future shortcuts should:

- Have a discoverable UI/menu/help surface.
- Avoid overriding common OS/text-editing shortcuts.
- Have equivalent pointer/touch access.
- Be testable on desktop.

## Screen readers and semantics

Manual release checks should include TalkBack (Android) and, when available, VoiceOver (iOS/macOS) or a relevant desktop accessibility tool.

Verify announcements for:

- Navigation destinations and selected state.
- Note card name.
- Favorite/pin/archive/trash actions.
- Search/filter controls.
- Editor title/body fields.
- Autosave state.
- Version restore actions.
- Theme/text-size/app-lock settings.
- Import/export controls.
- External links on About.

Decorative imagery should not create noisy repeated announcements. The logo can have a meaningful description in documentation; in-app icons paired with text generally do not need duplicate custom labels beyond the control semantics.

## Touch targets

Use standard Material buttons, icon buttons, chips, switches, sliders, and list tiles. Do not shrink icon-only actions into visually compact regions that become difficult to tap.

When adding custom gestures, provide a visible/focusable control alternative and semantic action.

## Motion

The reduced-motion preference sets `MediaQuery.disableAnimations`. New custom animation should read/respect that preference or be non-essential enough to disable cleanly.

Avoid:

- Fake loading delays.
- Constant decorative motion.
- Rapid flashing.
- Required drag gestures when a button/menu alternative can perform the same action.

## Error and status communication

Status should be concise and understandable:

- Loading: progress indicator where work is real.
- Empty: icon + title + descriptive message + relevant action.
- Error: message + retry when appropriate.
- Save: semantic/icon state with text meaning available to assistive technology.
- Destructive actions: confirmation explaining irreversibility only where necessary.

Do not communicate “saved” solely by changing an icon color.

## Forms and validation

Current editor fields use clear labels/hints for Folder and Tags. Future forms should:

- Use persistent labels when the value's meaning could become ambiguous.
- Associate error text with the field.
- Avoid validation only through red borders.
- Preserve entered data when validation fails.
- Put focus on the first actionable error only when that improves rather than disrupts navigation.

## Responsive layout

Test at representative widths rather than device names. Current major thresholds:

- Compact navigation below 760 logical pixels.
- Navigation rail at 760+.
- Extended rail at 1120+.
- Notes grid expands from one through four columns.

Resize desktop windows while content is open. Essential controls must not disappear unexpectedly.

## Localization readiness

Even English-only UI should be designed for future longer translations:

- Do not encode meaning in fixed English abbreviations.
- Avoid narrow fixed-width text controls.
- Allow wrapping in informational content.
- Future RTL support requires directional layout review rather than merely adding a locale.

## Manual release matrix

Record the result in a release issue or `what_changed.md`.

| Check | Android | Windows | Linux | macOS | iOS |
|---|---:|---:|---:|---:|---:|
| Large text | Required primary | Required | Required | Required | Before advertised release |
| Keyboard | External keyboard where useful | Required | Required | Required | External keyboard optional |
| Screen reader | TalkBack required primary | Review | Review | VoiceOver review | VoiceOver before advertised release |
| Light/dark | Required | Required | Required | Required | Required |
| Reduced motion | Required | Required | Required | Required | Required |
| Narrow/wide layout | Phone/tablet | Window resize | Window resize | Window resize | Phone/tablet |

“Required” here means required before claiming the corresponding platform was manually release-verified, not that every contributor needs every device for every code change.

## Automated testing opportunities

Useful tests include:

- Widget semantics labels for custom controls.
- Layout smoke tests at multiple surface sizes.
- Text-scale overflow regression tests.
- Focus traversal tests for important desktop screens.
- Test that destructive dialogs expose cancel/confirm actions.

Golden tests should be added only where they remain stable and provide more value than maintenance noise across Flutter versions.

## Accessibility bugs

Treat a blocked core workflow for keyboard/screen-reader/large-text users as a real product defect, not cosmetic polish. Add a regression test whenever the behavior is deterministic enough to automate.

When reporting, include platform, assistive technology, text scale, reproduction steps, and fictional content. Avoid attaching private notes.

## Checklist for UI pull requests

- [ ] Icon-only controls have a tooltip/accessible name.
- [ ] Status is not color-only.
- [ ] Text can scale without critical clipping.
- [ ] Narrow layout remains usable.
- [ ] Wide layout does not create unreachable controls.
- [ ] Keyboard focus behavior remains logical on desktop.
- [ ] Screen-reader reading order remains sensible.
- [ ] Reduced motion is respected by new non-essential animation.
- [ ] Destructive actions explain consequence appropriately.
- [ ] New custom gestures have an accessible alternative.
