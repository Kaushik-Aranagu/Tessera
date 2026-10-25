# The ink line: a thinner mark under action words (replaces the 19pt stroke)

Kaushik, Oct 15, 8:26 PM PT: the thick underline that shows up in most places is too thick, and he doesn't like it as much. Refine it or replace it.

Recording: `recordings/ink-line.mp4` (source `studies/ink-line.html`), Porcelain, before on the left and after on the right, showing arrival, a tap and a hold. Still: `mockups/ink-line.png`.

This sheet supersedes the stroke's size and placement in `no-buttons.md` and the 60% resting value in `no-dots.md` C11. The idea is unchanged: one action word per screen, sitting on its paint, with no button shape.

## The ink line (picked)
The word sits on a fine tapered swash instead of in a highlighter band. It reads like a pen line drawn under the word: thickest just left of centre and fading to a hairline at both ends.

**Shape:** `InkLine`, a lens.
- Path on a box w × 12: `M0 6 Q 0.42w (6 − t) w 5.6 Q 0.58w (6 + t) 0 6 Z`, where `t` is the thickness.
- At rest `t` is **2.5pt**.
- There's no displacement roughness. The taper is the hand.

**Placement:**
- The line sits *under* the word, never behind the letters. Its centre is **7pt below the baseline**.
- It runs from 2pt before the first letter to 4pt past the last.
- The word's own type (Title 34/500) is unchanged.

**Colour:**
- The action's paint, unchanged: `live` for Finish, the class pigment for Start, and so on.
- At rest it's **75% opacity**. It's thin, so it stays readable as the action.
- It never glows at rest on any look.

**Motion (where the drama lives):**
- **Arrival:** the line draws in from the left at 100% (360ms, house curve), then dries to 75% (`Theme.Motion.dry`).
- **Tap, touch down:** the word dips 1pt, and the line wets: `t` goes 2.5 → 4pt and opacity goes to 100% (120ms). There's no vertical stretch and no blur.
- **Tap, release:** a sheen runs along the line, left to right (520ms, house curve).
  - The sheen is a white band at 85% on light looks, and the look's `sheen` on dark looks.
  - Then the line dries back to 2.5pt at 75%.
- **Hold:**
  1. The line empties to a **0.9pt trace at 35%**.
  2. It repaints left to right under the thumb over the hold duration, thickening from 2.5 to 3.6pt as it fills (same curve as today).
  3. **On completion, a bead swells at the tip:** a circle in the paint, radius 0 → 5 → 7pt as it fades (520ms).
  4. The line settles back to 2.5pt.
  5. The haptic is unchanged.
- **Let go early:** the paint drains back (220ms, ease-in), as today.
- **Reduce Motion:** no sheen and no bead. The line appears at rest, and a hold fills with no thickening.

## The other thick marks, thinned to match
| Mark | Today | After | Owner |
|---|---|---|---|
| PaintKey stroke, `DesignSystem/Paint.swift:300-324` | `InkStroke`, 19pt tall, behind the lower third of the letters, 82% at rest, wet ×1.65 with blur | `InkLine` as above: 12pt frame, offset so its centre is 7pt below the baseline, `.padding(.leading, -2)` and 4pt trailing, 75% at rest. Delete the y-scale and blur wetting. | A |
| Hero completion strike, `DesignSystem/TextEffects.swift:60` | 4pt | 2.5pt, same taper (round caps, 0.6 → 1 → 0.6 width over its length, or a plain 2.5pt round stroke if a taper is costly). | A |
| Day stroke, `Features/Home/DayStrip.swift:156-160` | A 20pt band plus a 24pt soft pass, with the 26pt amber wet tip | **6pt**, one pass, with no soft pass. It rests at 60% through `daySpectrum` (`no-dots.md` C7). Now is the stroke's end: its last 14pt are 1.5pt thicker, with a breathing sheen. | B |
| Day stroke session marks, `DayStrip.swift:167` | 9pt `live` with a glow | 4pt `live` with no glow, landing wet when a session finishes. | B |
| Page rail carriage, `HomeSpatialView.swift:330-340`, `CarriageRail.swift:28-36` | 64 × 4 | 40 × 2, in `ink` at rest, turning `live` while paging (`no-dots.md` C5). | B (Home), A (Exercise, Plans) |
| Recipe amount under-stroke, `PasteRecipe.swift` (`Brushstroke`, 3.5pt) | 3.5pt | 2pt, drying to 35% (`no-dots.md`). | B |

The set strokes in the workout are data (a stroke per set), not underlines. They stay as `set-block.md` has them.

## Accessibility
Nothing changes for VoiceOver. The hit area stays the full row width at 64pt.
