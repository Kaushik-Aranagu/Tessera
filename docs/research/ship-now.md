# Research add-ons to the ship list

*Research lab, 2026-10-15 16:05. Product's `docs/product/ship-list.md` is the build order, so follow it. This page holds only the research findings it doesn't cover yet, each tied to the slice it belongs to. Everything else in the briefs has either shipped, been decided (GRDB, op log, Process, the 72-exercise library, the rest Live Activity, What's running) or been deferred in the ship list.*

## While building slices 2, 3 and 12: instrument rules (iOS build)

These cost almost nothing if they go in with the first version, and are painful to retrofit. Source: `instrument-robustness.md`.

- **Hold to log:** about 0.6 s, with about 20 pt of finger drift allowed. Undo lasts until the next set is touched.
- **Targets** are 60 pt or more. Instruments stay 20 pt clear of the left edge so the back swipe never fires by accident.
- **The dial** claims only vertical or rotational drags, and horizontal paging owns sideways swipes. The dial gets plus/minus one-plate taps as a non-gesture path.
- **VoiceOver:** the dial and drum use `.accessibilityAdjustableAction` with a spoken value like "80 kilograms, 30 per side". Don't use `accessibilityRepresentation { Slider }`.
- **Reduce Motion:** momentum becomes a direct snap, and every haptic stays.

## Slices 4 and 11: Tess's lines (iOS build, Tess engine)

Use the voice guide in `tess-voice.md` as written. It is a one-line rule, counts not streaks, and under 12 words. Ready-made lines for the finish summary (slice 4) and the capture confirmation (slice 11) are in its examples table. The ~230-token system prompt is ready for when the on-device model comes in.

## Rough extra for Home: draining Now bar (iOS build, Design studio)

Now's countdown is drawn as a bar that drains, not as a number. It is effort S and makes time visible, which is the strongest ADHD finding in `personal-os-and-productivity.md`. It isn't in the ship list, so Product can decide where it slots in.

## Nothing else

No other research items are ready to ship now. Every other item is in the ship list's own order or deferral list.
