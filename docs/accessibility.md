# NoteNest Accessibility

NoteNest aims for WCAG-oriented inclusive design across mobile, desktop, and Web. This document describes implementation expectations and release checks; it does **not** claim formal WCAG certification.

## Principles

- Core workflows must not depend on color alone.
- Interactive controls need understandable names and usable targets.
- Keyboard users must be able to reach important desktop/Web actions.
- Browser focus must remain visible and logical.
- Text must remain usable under system scaling and browser zoom.
- Layouts must adapt to narrow/wide windows/viewports.
- Screen-reader users should receive useful semantics rather than decorative noise.
- Optional motion should respect reduced-motion preference.
- Destructive actions must communicate consequences clearly.
- Unsupported platform capabilities must be explained without blocking unrelated workflows.

## Current foundations

NoteNest primarily uses standard Flutter Material controls plus project-specific accessibility rules:

- Tooltips for icon-only note/editor actions.
- Semantic note-card and save-state information.
- Note-color swatches with a 48 logical-pixel interaction target, explicit selected semantics, and a visible checkmark so state is not color-only.
- Material buttons/chips/list tiles instead of tiny custom hit areas.
- Responsive `NavigationBar` / `NavigationRail`.
- Adjustable application text scale.
- Reduced-motion preference through `MediaQuery.disableAnimations`.
- Light/dark themes.
- Text/icons alongside destructive lifecycle actions.
- Collection-specific empty states with context-valid actions.
- App-lock availability text in Settings so Web/Linux users are not presented with an impossible security action.

## Text scaling and browser zoom

Settings provide an additional 90%–140% scale. OS/framework accessibility scaling may add more. Web users may also zoom the page/browser.

Do not rely on fixed heights around multiline text. Prefer wrapping, flexible layout, and scrolling.

Verify at large text/zoom on:

- Onboarding.
- Notes search/filter controls.
- Note cards.
- Editor app bar/metadata fields.
- Settings controls.
- About/contact tiles.
- Confirmation dialogs.
- Web narrow and wide viewport layouts.

If horizontal space is insufficient, adapt/scroll rather than clip essential labels.

## Color and contrast

- Never encode archive/trash/favorite state only in note color.
- Selected state needs icon/text/shape cues in addition to color.
- Custom note colors must retain readable foregrounds.
- Check light and dark themes.
- Disabled controls must remain distinguishable.

The note-color palette uses a checkmark plus selected semantics; the default/no-color option also has a reset cue.

## Keyboard and browser focus

Desktop/Web release review should verify using keyboard only where practical:

1. Reach navigation destinations.
2. Reach search/filter controls.
3. Create/open a note.
4. Move among title/body/folder/tags.
5. Reach formatting/action buttons.
6. Open/use popup menus.
7. Navigate Settings controls.
8. Confirm/cancel destructive dialogs.
9. Reach About/external links.
10. Return/back without requiring pointer/touch.

On Web also verify:

- visible focus indication;
- Tab/Shift+Tab order;
- browser Back does not unexpectedly destroy unsaved state;
- common browser shortcuts are not unnecessarily intercepted;
- zoom does not make key controls unreachable.

Preserve Flutter's default focus traversal unless an explicit order is genuinely clearer.

## Shortcuts

The current app does not advertise a custom global shortcut set. Future shortcuts should be discoverable, avoid overriding standard OS/browser text/navigation shortcuts, have pointer/touch equivalents, and be tested across relevant desktop/Web targets.

## Screen readers and semantics

Manual checks should include representative tools such as TalkBack, VoiceOver, Windows accessibility tooling, and a browser/desktop screen-reader path when available.

Verify announcements for:

- navigation destinations and selected state;
- note-card identity;
- favorite/pin/archive/trash actions;
- search/filter controls;
- editor title/body fields;
- save state;
- color choices/selection;
- version restore;
- theme/text/app-lock settings;
- import/export controls;
- About external actions;
- app-lock unavailable state where applicable.

Decorative imagery should not create noisy repeated announcements.

## Touch/pointer targets

Use standard Material buttons/icon buttons/chips/switches/sliders/list tiles. Custom note-color targets use `AppTokens.minimumTouchTarget` = 48 logical pixels.

Custom gestures should have a visible/focusable/semantic alternative. Pointer hover must not be required to discover essential actions.

## Motion

Reduced motion sets `MediaQuery.disableAnimations`. New non-essential animation should respect it.

Avoid fake delays, constant decorative motion, rapid flashing, or required drag gestures when a button/menu alternative can exist.

## Error and status communication

- Loading: progress only for real work.
- Empty: icon + title + explanation + valid action.
- Error: concise message + retry where useful.
- Save: semantic/text meaning, not icon color alone.
- Destructive action: clear confirmation when irreversible.
- Unsupported capability: explain unavailable state while keeping unrelated functionality accessible.

## Forms and validation

- Use persistent labels where meaning could become ambiguous.
- Associate errors with the relevant field.
- Do not communicate validation only via red borders.
- Preserve entered data after validation failure.
- Use focus movement only when it helps rather than disrupts navigation.

## Responsive layout

Current major thresholds:

- compact navigation below 760 logical pixels;
- navigation rail at 760+;
- extended rail at 1120+;
- notes grid expands up to four columns.

Resize desktop windows and browser viewports with content open. Essential controls must not disappear.

## Web-specific accessibility

Web support adds browser behavior to the release matrix:

- Test keyboard/focus on the deployed Web build, not only `flutter run`.
- Test at common browser zoom levels including 200% where practical.
- Verify page/worker loading failures do not leave inaccessible blank states.
- Verify browser file import/download controls remain operable without pointer-only assumptions.
- App-lock should be announced as unavailable rather than leaving a disabled unlabeled switch.
- Test at least one screen-reader/browser combination appropriate to the claimed browser support before a stable Web release claim.

## Localization readiness

English-only UI should still allow longer future translations. Avoid fixed English abbreviations, narrow fixed-width labels, and assumptions incompatible with RTL. A locale is not supported until major journeys are reviewed in it.

## Manual release matrix

Record actual results in release tracking / `what_changed.md`.

| Check | Android | iOS/iPadOS | Windows | macOS | Linux | Web |
|---|---:|---:|---:|---:|---:|---:|
| Large text / zoom | Required | Required | Required | Required | Required | Required incl. browser zoom |
| Keyboard | External keyboard where useful | External keyboard useful | Required | Required | Required | Required |
| Screen reader | TalkBack | VoiceOver | Review | VoiceOver | Review | Browser/AT review |
| Light/dark | Required | Required | Required | Required | Required | Required |
| Reduced motion | Required | Required | Required | Required | Required | Required |
| Narrow/wide | Phone/tablet | Phone/tablet | Window resize | Window resize | Window resize | Viewport resize |
| Import/export operability | Required | Required | Required | Required | Required | Required browser flow |
| App-lock presentation | Supported-device check | Supported-device check | Supported-device check | Supported-device check | Unavailable state | Unavailable state |

“Required” means required before claiming that target was manually release-verified, not that every contributor needs every device for every code change.

## Automated testing opportunities

Useful automation includes:

- semantics labels for custom controls;
- layout smoke tests at multiple sizes;
- text-scale overflow regressions;
- focus traversal for important desktop/Web screens;
- destructive dialog action semantics;
- unsupported-capability state semantics.

Current deterministic coverage protects note-color selected state/target size, collection-specific empty actions, editor recovery/save-before-pop behavior, About failure feedback, and Web platform capability fallbacks. Golden tests should be added only where stable enough to justify maintenance.

## Accessibility bugs

A blocked core workflow for keyboard/screen-reader/large-text/browser-zoom users is a product defect, not cosmetic polish. Add a regression test when deterministic.

Bug reports should include platform/browser, assistive technology, text/zoom scale, fictional reproduction data, and viewport/device size without exposing private notes.

## UI pull-request checklist

- [ ] Icon-only controls have accessible names/tooltips.
- [ ] Status/selection is not color-only.
- [ ] Custom targets meet the shared minimum.
- [ ] Text/zoom does not critically clip.
- [ ] Compact/wide layouts remain usable.
- [ ] Keyboard/browser focus order remains logical.
- [ ] Screen-reader reading order is sensible.
- [ ] Reduced motion is respected.
- [ ] Destructive consequences are clear.
- [ ] Custom gestures have alternatives.
- [ ] Unsupported platform capability states are understandable and do not block unrelated use.
