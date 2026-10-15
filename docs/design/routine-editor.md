# Routine editor (v1 slice 10, steer)

For Builder A. There is no list rows, no `EditButton` and no edit mode: the routine page is always editable, the way a sheet of paper is. This follows `no-buttons.md`. Recording: `recordings/routine-editor.mp4` (source `studies/routine-editor.html`).

## The page
- **How you get here:** z from a routine name (on Training, the week, or the Now "Start" line), with the house zoom (scale 0.95→1, 420ms). The exercises come in down y with a 45ms stagger.
- **Top of the page:**
  - The path in labels: "TRAINING › ROUTINES".
  - The hero: the routine name at Hero 56.
  - The context line: "5 exercises, about 55 min". The minutes roll whenever the plan changes.
- **The exercises go down y, one every 84pt from y 196:**
  - The name at Title 34/500.
  - Under it, the scheme as a sentence at 21: "**4** × 6–8 · 82.5 kg". The set count, the rep range and the weight are each a **value word**.
- **"Add an exercise"** sits at 21 and 70% ink after the last one.

## Reorder: hold and drag on y
- **Hold a name for 0.4s:**
  - The row lifts: it scales to 1.03, its text gets a soft shadow (`0 10 18`, ink 28%), and hairline seams appear 6pt above and below it.
  - Haptic: `.impact(light)`.
- **Drag:**
  - The row follows the finger.
  - When it crosses the midpoint of a neighbour, that neighbour slides into the gap (320ms, house curve), with a `.selection` tick for each slot passed.
- **Release:** the row settles into its slot (260ms) and the seams fade. Tess says "Incline press goes second."
- Undo appears beside Tess's soul.

## Drop: swipe left
- **The row follows the finger.** Past 90pt, **DROP** rises in the right track in vermilion (the same pattern as FORGET and TOMORROW).
- **Release past 120pt:** the row slides out left with a 4pt blur (300ms). The rest close up and the minutes roll ("about 47 min").
- Tess says "Dips dropped." with **UNDO**.
- Below the threshold, it springs back.

## Change sets, reps or weight: tap the value word
- **Tapping a value word** shows the cobalt wash, and the scheme line **opens into a small drum in place**:
  - The numbers sit 34pt apart at 21/600, with the chosen one in ink and its neighbours at 30%.
  - The word "sets" follows them.
  - The left edge fades into the gutter.
- **Swipe** to step. Each step is a `.selection` tick with a slight overshoot (`cubic-bezier(.3,1.3,.5,1)`, 300ms).
- **Folding back:** lift and wait 0.8s, or tap anywhere else. The drum folds back into the sentence with the new value, and the minutes roll.
- **The rep range** opens the same drum with two values. The handle nearer to where you touched moves.
- **The weight** unfolds the real weight dial under the row (rows below make room, 320ms). Pick, then tap away.

## Change the exercise: tap the name
- **Tapping the name** shows the wash on it. Alternatives **from the same movement pattern** unfold under it at 21 and 65%, each 50ms after the last. The row's scheme dims to 30%.
- **Tap one:**
  - The old name blurs out.
  - The new one **writes itself in** (30ms per glyph, with a cobalt wash fading over 2.4s).
  - The scheme updates to that exercise's own last-used weight.
- Tess says "Pec deck, from 40 kg." with **UNDO**.
- Tapping the name again, or anywhere else, folds the alternatives away.

## Add an exercise
- **Tap "Add an exercise".** It becomes a 0.5pt cobalt writing line with a caret (no box, no sheet).
- **While you type**, matching exercises appear under it at 21. Tess's suggestion, the pattern this routine is missing, sits first in cobalt.
- **Picking one** writes it in as a new row with the glyph reveal.

## Accessibility and Reduce Motion
- **Each exercise is one element**: "Bench press, 4 sets of 6 to 8 at 82.5 kilograms".
- **Accessibility actions:**
  - Move up and Move down.
  - Drop.
  - Change exercise.
  - Adjustable for sets (increment and decrement).
- **Reduce Motion:** no lift scale or drift. Rows swap with a crossfade, drums change values with a crossfade, and names appear without the glyph reveal.
