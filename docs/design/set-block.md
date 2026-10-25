# The set block: weight in place, smaller reps with more drama (build sheet, Kaushik's 6:45 PM correction)

> **Sweep 16 Oct (item 19):** parts of this sheet are amended by `sweep-19.md` (no dots, one base, the context line). Where they differ, `sweep-19.md` wins.

Kaushik liked the weight dial's animation. But the strip takes too much room on a busy screen, and it doesn't scroll sideways. He asked for two changes:
- The number itself should be editable in place: scroll on it, like the reps number on the side.
- The other dial should be smaller, with more drama.

Reading "the round dial for the sets count" as the reps drum is my inference: it's the only other dial on the screen. This sheet removes `WeightDial` and its plus and minus keys from the workout, makes the weight numeral a reel, makes `RepsDrum` one row, and gives the freed space to the plates, drawn.

Recording: `recordings/set-block.mp4` (source `studies/set-block.html`):
1. Drag the weight numeral: 80, then 82.5, 85, and back to 82.5. Plates drop on and lift off the drawn bar.
2. Drag reps from 8 to 9. It beats last time, so a cadmium stroke paints under it.
3. Hold Log set: rest takes the number row, and the rest horizon takes the plates' place. Drag it right for +15.

## The weight numeral, in place
- **The numeral is the control.** It's Numeral 80 Light (today it's 72), tabular, with "kg" at 21 on its baseline.
- **Drag up or down on it:** up is heavier, one load per 12pt. These are the `WeightDial` detents and its momentum: a flick carries on and settles exactly on a load.
- **While the finger is down,** the neighbours show above and below at Title 34 Light, `ink` 35%. "80" has "77.5" 48pt above it and "82.5" below. They fade in (180ms) and fade out (220ms) on lift-off. Nothing else frames the number.
- **Each step rolls:** the old value leaves the way the finger moves (200ms, scale 0.82, 3pt blur). The new one arrives from the other side with the settle spring (300ms).
- **Haptics:** `.selection` per load, skipping a tick that comes under 30ms after the last. `.impact(weight: .light)` fires only when a plate of 5 kg or more goes on or off. Master's heavy tick on each 10 kg line goes.
- **Tap the numeral** to type a weight **in place**: the numeral becomes a field at the same size, with `@FocusState`, `.decimalPad`, the text selected and a keyboard "Done". There's no alert. On commit it snaps to the nearest load (ties go lighter). If it snapped, a label line under it reads "81 ISN'T LOADABLE; 80" for 2s. Reps types the same way, with the number pad.
- **VoiceOver:** an adjustable element ("82.5 kilograms, 25, 5 and 1.25 per side"). Increment and decrement step one load. The plus and minus keys go; this is their non-gesture path.
- **Sideways swipes** stay with the exercise lane, as today. The numeral owns vertical drags only.

## Reps: one row, with drama
- **One value shows,** at **56 Light** (today 48, in a 3-row drum). It sits on the weight's line: "82.5 kg × 9". The "×" is Title 34 at 60%. The drum is 80pt wide (today 92) and 60pt tall (today 132).
- **Dragging** works like the weight: the neighbours show at 34 Light, 35%, only while the finger is down. Each step is **28pt**, with no acceleration. Bounds are 1 to 50, matching the logger.
- **The landing has the drama:**
  1. The new number rolls in with the settle spring, and the whole number pops: scale 1, then 1.12, then 1 (320ms, settle spring).
  2. Five ink droplets (5×4, cream 55%) flick off it in the direction of travel and fade (300 to 420ms).
  3. When reps pass last time, the ghost "LAST 8" fades and a short cadmium stroke paints under the number, left to right (260ms). It goes when reps drop back to last time or below. `.impact(.rigid)` fires on the beat.
  4. Tess says "One more than last time." (only once per set, and only while nothing else is speaking).
- The drama is **only on hand changes.** A prefilled value or Undo moves the number with a plain roll.

## The freed space: the plates, drawn
The strip and its keys gave back about 120pt between the number row and the key. It now holds what he looks at between sets: `PlateStack(..., drawsPlates: true)`, drawn large.
- **The bar:** a side view, painted, with the collar at x 172. One side's plates are drawn outward, in standard plate colours (25 signal red, 20 blue, 10 green, 5 cream, 2.5 dark, 1.25 chrome), with rough edges. The tallest plate is 150pt.
- **Under it,** in labels: "25 + 5 + 1.25 EACH SIDE".
- **When the weight changes,** new plates drop on from 30pt above with the settle spring, staggered 60ms. Removed plates lift 26pt and fade (220ms). It's the old dial's animation, now attached to something real.
- **Dumbbells and machines** have no plates: the space stays empty, and the number row moves down 40pt to sit nearer the thumb.

## Rest
- **The number row** becomes the countdown, as today: "1:30 rest" in the rest colour.
- **The plates fade,** and the rest horizon draws across their place (3pt, workout rest colour, rough edge, 500ms). It drains right to left. It's the same horizon as the Live Activity.
- **The horizon takes the dial's rest gestures:** drag right for +15 (the line grows under the finger), and fling left to skip. A label under it reads "DRAG RIGHT +15 · FLING LEFT TO GO" for the first three rests only.
- Tapping the countdown still adds 15, and the key reads "Skip rest", as today.

## Owner
Builder A:
- `Features/Workout/WorkoutModeView.swift` (`numberRow`; the `WeightDial` row and `PlateStepKey` removed; `setArea`).
- A new `WeightReel`, built from `WeightDial`'s gesture and detent code.
- `Instruments/RepsDrum.swift` (one row).
- `PlateStack` (large drawing, with drop-on and lift-off).
- `RestHorizon`.

## Research's feel check (#189, `docs/research/inplace-number.md`): these win
- **One detent per loadable weight,** from Core's `Dial` (2.5 kg on the starter barbell, 2 kg on dumbbells, irregular racks as listed). It's never a fixed kg step.
- **The axis locks once,** at 10pt of travel. If the move is more sideways than vertical, the whole gesture belongs to the exercise lane.
- **Acceleration:** 12pt per load up to 250pt/s, rising linearly to 2.5× at 1000pt/s. The first 48pt of every drag is always 1×. Accumulate fractional detents per sample. The gain, coast and fixture rows go into a pure function in Core, tested with a Swift Testing table.
- **A visible coast after a fling:**
  - Length: clamp(predicted extra / 12 × 0.5, −24, 24) detents.
  - It plays out over min(0.25 + 0.03n, 0.8)s, easing out, with each detent rolling and the last landing on the settle spring.
  - `weight` (and the plates) commit once, at the end.
  - A touch stops the coast on the detent showing.
- **Bounds:** the numeral rubber-bands 0.3pt per pt, up to 16pt, and springs back. One `.impact(flexibility: .rigid, intensity: 0.6)` per touch.
- **Reduce Motion:** a fling still lands on the same value, in one crossfade with one haptic. There's no pop, no droplets and no rubber-band.
- **VoiceOver:**
  - The reel is the element: label "Weight", adjustable, value "82.5 kilograms, 25, 5 and 1.25 per side".
  - Hint: "Swipe up or down to change by one load. Double tap to type."
  - Reps reads "9, one more than last time".
  - Remove `.accessibilityHidden(true)` from the numeral.
- **Dynamic Type:** the numeral stays at 80. "kg", "×", the plate line and the neighbours scale to `.xxLarge`. The row uses `ViewThatFits` with a 64pt numeral fallback.
