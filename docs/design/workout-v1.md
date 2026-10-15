# Workout v1 (live, painterly)

A dark painterly ground. The workout is a foreground process: it rises as a full-screen cover. Sparse: one exercise, one number, one action. Mockup: `mockups/PleinWorkout.dc.html`.

## Layout and axes
- **x** = exercises. **y** = sets (drawn as strokes). **z** = the exercise's object page.

| y | Element |
|---|---|
| 0 | **Lit process seam** (see materials.md) |
| 56 | "Push Day A, 12:48" in Fraunces italic 21, secondary colour, with the clock ticking. "1 / 5" sits on the right in labels |
| 92 | **Exercise lane**, Fraunces 48, weight 640: one name per 322pt page. The next name peeks in at 28% cream. Tap the name to zoom into the exercise |
| 176 | **Sets as brushstrokes**: one 64×20 stroke per set (see below) |
| 210 | **Subline**, Fraunces italic 21, e.g. "set 3 of 4, last was 82.5 × 8" |
| 270 | **Weight**: Fraunces 72, weight 600, tabular lining numerals, with "kg" in italic 21. Plate maths below it in labels: "31.25 KG A SIDE" |
| 252–384 (right) | **Reps drum**, with "reps" in italic 18 at 55% below it |
| 470 | **Weight dial** |
| 624 | **Hold-to-log key**, 240×62, with "82.5 × 8" beside it in labels |
| 756 | **Tess bar** (dark glass), with the soul in screen blend |

### Sets as brushstrokes
- **Logged set:** a 9pt stroke in its paint colour. The colour cycles vermilion → cobalt → cadmium → sage from set to set.
- **Current set:** a dashed 2pt cream guide that breathes (opacity 0.45↔0.9, 2.4s).
- **Future sets:** a dashed guide at 22%.

## Reps drum
- No box, slot or lens: just numbers in a vertical snap scroll, 92 wide, three rows visible at a 44pt pitch.
- The top and bottom fade out through a mask.
- The centre value is Fraunces 48 in cream, prefixed "× ". Neighbours are 21pt at 35%.
- Size and colour transition over 160ms as it rolls.
- It defaults to the target reps.

## Weight dial: the precise part
- **Ticks:** hairlines with nothing behind them, one every 2.5 kg at a 14pt pitch, 0–160 kg.
  - Minor ticks are 1pt wide: 11pt tall, or 18pt every 5 kg, at cream 38%.
  - Every 10 kg is a 1.5pt × 30pt major tick at cream 90%, with a label below it.
- **Edges:** fade out over the outer 25% on each side.
- **Needle:** fixed at the centre, a 2pt × 44pt vermilion line with a 10pt glow.
- **Momentum:** a flick settles on a valid plate load.
- **Haptics:** `.sensoryFeedback(.selection)` on every tick and `.impact(weight: .heavy)` on every 10 kg.
- **Default:** the last set's weight, so most sets need no input.
- **Accessibility:** an adjustable action, plus a "Type value" action that opens a keypad.

## Hold to log
- A cream key with the same paint behaviour as Home.
- While you hold, vermilion spreads through it from the thumb side over 800ms, and the label turns light: "Keep holding".
- **When a set is logged:**
  1. **The stroke paints in:** the set's brushstroke draws left to right over 700ms with `cubic(.3,.7,.2,1)`. Haptics: a rigid impact, then `.success`.
  2. **Tess plays `done`** (a pour-in merge plus a ring splash).
  3. **Rest begins in the same place,** fading in over 320ms:
     - The weight numeral becomes the countdown in cadmium, "2:30" with "rest" after it, using the tick motif.
     - The dial dims to 35% and can't be dragged.
     - A cadmium wash with a 2pt cadmium edge covers the dial and drains every second.
     - The key reads "Skip rest".
  4. **When rest ends,** the dial turns back into weight.

## A possible PR
- When the dialled weight × reps would beat the best e1RM (`w × (1 + r/30)`):
  - The subline turns cadmium: "set 3: this would be a new best".
  - The numeral carries the glint motif (a `#FFE2A8` sheen every 3s).
  - Tess says "Go on. You have this."
- **When it's logged:** Tess blooms twice, then the subline reads "a new best: e1RM 107.7" and Tess says "That one goes on the wall."
- `.bouncy` is allowed only here. No confetti.

## When an exercise is finished
- **Exercise:** the subline reads "all 4 sets in. Swipe for the next.", and the key becomes "Next exercise", which pages the lane.
- **Whole workout:** the strokes gather into one painted mark and drop into today's day stroke on Home. This is still to design.
