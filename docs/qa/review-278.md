# QA review 278: the ink line on PaintKey (#278)

Merge ec3071c, head 897faad, 4 files (+116/-22, plus docs/recordings/28-ink-line.mp4). Static review; no toolchain here.

**Verdict: PASS.** No reverts against the first parent, and no data paths are touched. One should-fix: the two completion moments, the release sheen and the tip bead, are written so SwiftUI never shows them (I1). The coordinator's two notes are confirmed.

## What it builds (ink-line.md)
- **`InkLine`** is a lens shape: thickest just left of centre, a hairline at both ends, with `thickness` animatable (Paint.swift, end of file). The two quad controls sit ±t from the midline, so the drawn width is about t. It sits 7 pt under the baseline and never behind the letters. This replaces the PaintKey band that Kaushik found too heavy.
- **States:**
  - At rest: 2.5 pt at 75% once dried.
  - Wet on touch: 4 pt at 100% (2.5 pt under Reduce Motion).
  - A hold empties it to a 0.9 pt trace at 35%, then repaints 2.5 to 3.6 pt left to right under the thumb. That's the same `fill` mask as before.
- **Arrival:** it draws in from the left over about 360 ms, then dries to 75%. Under Reduce Motion it is shown at once and `dry` is skipped.
- **Strike** (`StrikeRenderer`) is 2.5 pt, down from 4, which matches the line.
- **CarriageRail:** 40 × 2, down from 64 × 4. It's ink at rest and live only while paging (`isPaging`, more than 0.02 off a whole page), which fits no-dots C5.
- All motion goes through `withTesseraAnimation`, `.tesseraAnimation` or `MotionPolicy.resolve`, except the bead's raw `withAnimation`, which only runs when `!reduceMotion`. The line stays `accessibilityHidden` and doesn't take hits.

## Should-fix
- **I1: the sheen and the bead never show.**
  - **Sheen:** `runSheen()` sets `sheen = 0`, then animates `sheen = 1` in the same update, and the band's visibility is `.opacity(sheen > 0 && sheen < 1 ? 1 : 0)`. SwiftUI builds the body once with the final value, 1, so that condition is false and the opacity is 0. Only the offset interpolates, under a band you can't see. From the second release on, 0 then 1 in one update is no change at all.
  - **Bead:** `complete()` sets `beadOpacity = 1` without animation, then, in the same update, animates it to 0 (delayed 0.2 s). SwiftUI coalesces the changes, so the opacity goes from 0 to 0 and the bead never appears.
  - Fix: drive both from a trigger, for example `.keyframeAnimator(initialValue: Bead(), trigger: completions)` with r 0 → 5 → 7 and opacity 1 → 0 over 520 ms, and the same pattern for the sheen on a `releases` counter. Keyframe values interpolate per frame, so the conditions see the in-between values.
  - The recording can confirm it: a hold's release should show a light band running along the line and a bead at the tip.

## The coordinator's notes
- `.opacity(holding ? 1 : 1)` in the `InkLine` stack is a no-op. Delete it.
- The doc comment at Paint.swift:227-230 still says the hold "bloom[s] at the tip and fire[s]". It should say "a bead swells at the tip and it fires".

## Lows
- **L1:** `arrive()` keys on `drawnIn` in `@State`, so a PaintKey inside a lazy stack that is recycled draws in again when it scrolls back in. That's fine for primary actions, which are rarely in lists; worth knowing for item 90 rows.
- **L2:** the sheen colour uses `ThemeStore.shared.paintLook.isDark`. That matches the workout (held look) and Home, so it's correct.
