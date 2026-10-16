# The set block: weight in place, smaller reps with more drama (build sheet, Kaushik's 6:45 PM correction)

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
- **Haptics:** `.selection` per load, and `.impact(.light)` when a plate goes on or off.
- **Tap the numeral** to type a weight. This is the existing `isTyping` path from `WeightDial`, moved here.
- **VoiceOver:** an adjustable element ("82.5 kilograms, 25, 5 and 1.25 per side"). Increment and decrement step one load. The plus and minus keys go; this is their non-gesture path.
- **Sideways swipes** stay with the exercise lane, as today. The numeral owns vertical drags only.

## Reps: one row, with drama
- **One value shows,** at **56 Light** (today 48, in a 3-row drum). It sits on the weight's line: "82.5 kg × 9". The "×" is Title 34 at 60%. The drum is 80pt wide (today 92) and 60pt tall (today 132).
- **Dragging** works like the weight: the neighbours show at 34 Light, 35%, only while the finger is down. Each step is 44pt.
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
