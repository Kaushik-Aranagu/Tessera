# Workout v1 (live, painterly)

A dark painterly ground. The workout is a foreground process: it rises as a full-screen cover. Sparse: one exercise, one number, one action. Mockups: `mockups/WorkoutTight.dc.html` (the set, dial, drum and hold, in Inter Tight; `PleinWorkout` is the same screen in the retired serif) and `mockups/LiveDetails.dc.html` (the strip, swap, top-set check, effort, rest drags, finish and lock-screen undo; tap each moment to play it). Behaviour follows Product's `workouts.md`, section 2.

## Layout and axes
- **x** = exercises. **y** = sets (drawn as strokes). **z** = the exercise's object page.

| y | Element |
|---|---|
| 0 | **The strip:** the lit process seam, split into one segment per exercise (see The strip) |
| 56 | "Push Day A, 12:48" in 21/400, secondary colour, with the clock ticking. "1 / 5" sits on the right in labels |
| 92 | **Exercise lane**, Inter Tight 44, weight 500, tracking −3.5%: one name per 322pt page. The next name peeks in at 28% cream. Tap the name to zoom into the exercise |
| 176 | **Sets as brushstrokes**: one 64×20 stroke per set (see below) |
| 210 | **Subline**, 21/400, e.g. "set 3 of 4, last was 82.5 × 8" |
| 270 | **Weight**: the numeral tier (Inter Tight 80, Light 300, −4%, tabular), with "kg" at 21/400. Plate maths below it in labels: "31.25 KG A SIDE" |
| 252–384 (right) | **Reps drum**, with "reps" at 18/400 at 55% below it |
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
- The centre value is Inter Tight 48 Light in cream. Neighbours are 21pt at 35%.
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
- **Exercise:** the subline reads "all 4 sets in. Swipe for the next.", and the key becomes "Next exercise", which pages the lane. After the last set's rest, the strip advances on its own (Product default).

## The strip (the top seam)
- The process seam on the top edge **is** the exercise strip. It is split into one segment per exercise, 3pt tall, with 4pt gaps, edge to edge.
  - Done: cream at 82%.
  - Current: vermilion, lit (`0 0 10px rgba(217,86,63,.8)`), with the process glint travelling along it every 4.5s.
  - Remaining: cream at 20%.
  - No dots, no labels.
- **Pull down on the seam** (or tap it) to drop the running order over the top of the screen: a dark glass sheet (`rgba(28,24,40,.82)`, 22pt blur, radius 34 at the bottom corners) sliding down over 460ms with `cubic(.2,.9,.25,1)`.
  - "RUNNING ORDER" in labels at y 62, then one row per exercise at a 64pt pitch: the name at 28/500, the scheme in labels on the right ("3 × 12"). The current row is cream with a 3×30pt lit vermilion bar on its left edge and "SET 3 OF 4" in cadmium; the rest are at 50%.
  - **Hold a name and drag** to reorder: the row lifts (scale 1.03, a 14pt shadow, cream 10% fill) and the others close up around it (420ms). This is for today only; the plan keeps its order. Footer: "Hold a name and drag. Today only; the plan keeps its order."
  - Swipe up or tap outside to close.

## Swap within the movement
- **Pull down on the exercise name.** The name follows the finger (up to about 10pt, rubber-banded), and the alternatives drop in under it as a glass panel (from 16pt above, blur 6→0, 420ms). The set strokes fade out under it.
- Two groups, each headed in labels: **SAME FAMILY**, then **SAME MOVEMENT**. Rows are 56pt: the name at 24/500, the converted load at 21 on the right. An estimated load is marked "≈" ("≈ 32 each"). Show at most 4 rows; ranking follows Product (muscle overlap, then the gym's kit).
- Footer at 18: "≈ is an estimate. Bench stays in the plan."
- **Picking one** fills the row with a cobalt wash, closes the panel, and writes the new name in from the right (the hero entrance). Long names step down a size (34pt for "Dumbbell bench press"). The plate line reads "AN ESTIMATE FROM BENCH" in cobalt, and the subline "swapped for today, set 3 of 4" in cobalt. Tess: "Bench stays in the plan."

## Top-set check
- Only when the first working set's RPE is 2 or more above the slot's target. Never anything else between sets.
- One line from Tess **inside the set area** (y 394, under the plate maths, 250pt wide), 21/1.25 in cobalt `#9DBFE6`, breathing gently (opacity 0.78↔1, 1.6s): "That was heavy. Drop to 77.5 for the rest?" A cobalt brushstroke paints in under it (700ms), which marks it as tappable.
- **One tap** accepts: the weight rises in at 77.5, the plate maths and dial follow, Tess plays `done`, and the line becomes "Done. 77.5 for sets 2 to 4." without the stroke. The remaining sets re-preset. Ignoring it is fine; it leaves when the next set is logged.

## Effort (RPE), only when wanted
- Hidden by default. **Pull up on the reps drum** to slide out the stop-slider between the plate maths and the dial (y 404, 60pt tall), revealed left to right over 520ms.
- Nine stops from 6 to 10 in half steps along a hairline. Whole numbers are labelled at 21 (Light, 45%); half steps are small dabs only.
- The chosen stop: its number at 26/500 in cream, and its dab grows to 18pt in cadmium with a soft cadmium glow. Each stop is a selection haptic.
- The subline turns cadmium and says it in words: "RPE 8, two left in the tank". The set is logged with it, and the honest e1RM uses it.

## Rest on the dial: +15 and skip are drags
- During rest, the dial dims to 35% and drains (as above). It now also takes two drags:
  - **Drag right past the needle: +15.** The dial follows the finger, the cadmium fill grows, and a "+15" label rises above the fill's edge. The countdown rolls up (1:42 → 1:57). The note reads "+15. Drag again for more."
  - **Fling left: skip.** The fill drains to nothing in 420ms, and "Go" rises in where the countdown was (14pt, blur 6→0). The note reads "Skipped. Set 4 is up."
- **One-tap twins** (every drag needs one): tap the countdown for +15, and the key reads "Skip rest".
- When rest ends on its own, the next set rises to eye level already prefilled, and one glint sweeps across the numeral.

## Finishing the workout
- After the last set of the last exercise, the key reads "Hold to finish". It fills like hold to log (0.8s), with Tess saying "Last one. Hold to finish."
- **The finish:** the set view clears. "Thursday, 18:10 to 19:08" (21, secondary) and the hero "Push Day A, done" (56/500) enter from below.
- **The gather:** all of the session's set strokes appear scattered across the middle of the screen in their paint colours. After about 400ms they draw together to the centre, rotating level and shrinking (1.9s, staggered 22ms each, `cubic(.5,0,.2,1)`). As they meet, **one painted mark** draws across (16pt, wet-edged, a gradient through the session's colours, with a 30pt blurred halo underneath) over 900ms.
- Then "58 MIN, 9,840 KG MOVED" in labels, and "It drops into today on Home." The strip on the top edge goes fully cream.
- Tess plays `done` (unchanged) and says the one-line summary in her voice: "6 exercises, 22 sets. New best: 85 × 5."
- Swiping down drops the mark into today's day stroke on Home, where it becomes the Workout object.

## Undo
- In the app, a logged set can be undone until the next set is touched: the Tess bar shows "Logged." with **Undo** on the right. No toast timer, never "Are you sure?".
- On the lock screen, Done shows its own Undo until that rest ends (see `live-activity.md`). Both share one undo stack, through the op log.

## Instrument rules (from Research's instrument-robustness brief)
- **Targets:** 44pt is the floor; aim for **60pt** on the key and the dial, with 12pt of dead space between unrelated controls. Keep instruments **20pt off the left edge** (the back swipe).
- **Holds:** 0.5–0.8s, never longer (hold to log 0.8s, Home's hold to finish 0.7s), with `maximumDistance` about 20pt so a sliding thumb still counts.
- **Every drag has a one-tap twin:** the dial gets minus and plus one plate; rest gets tap for +15 and "Skip rest"; the set row has named actions "Log set", "Same as last" and "Undo".
- **Gesture ownership:** the exercise pager owns horizontal. The dial owns horizontal only inside its own band, decided on the first 10–20pt of movement; the drum owns vertical. In live mode, defer the system's bottom-edge gesture.
- **One haptic per meaning:** tick = one step, clunk = logged, its own pattern for a record; never reuse one for opposite outcomes. Fire the tick sound on the same frame. Offer a haptics and sound switch.
- **Accessibility:** the dial and drum are adjustable elements with spoken values ("82.5 kilograms, 31.25 a side"). Under Reduce Motion, momentum becomes a snap and rolls become crossfades, but the hold still fills and every haptic stays. Logged sets change shape, not only colour.
