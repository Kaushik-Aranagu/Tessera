# Title progress as one clip (board item 23, for Builder A)

Source: `docs/design/studies/title-progress.html` (design item 72, round 2, Kaushik 1:50 PM PT Oct 16, approved) on branch `claude/project-thread-b3tu3f`; type scale from sheet 86 option C (`docs/design/type-round-86.md`). Reference clips: `recordings/picks/tess-pick-title-progress.mp4` (Obsidian) and `tess-pick-title-progress-reduce-motion.mp4`, scene `pick-title-progress` in `prototype/tess-motion.html` (`node record.mjs pick-title-progress obsidian <out.mp4> 2`, `RM=1` for Reduce Motion). Done never changes: this sheet adds nothing to Done itself, only to the title it sits on.

## The idea
The whole title moves together. As the thing gets done it grows bolder and its ink leans toward the area's colour. The key word wears the colour from the start. At done every effect joins (full weight, full colour, a strike drawn through), then it dries to quiet ink with the strike kept. No half-and-half split; every in-between state looks finished.

## Type (sheet 86 C, Title token)
52 pt, line height 56, Inter Tight variable, no italics. Rest tracking -3%. Weight runs on the variable axis: **500 + 150 x p**, so p 1 lands exactly on the C title weight 650. The key word is **+90** over the title at every stage (sheet 86 C) and takes the area colour at 72% mixed with ink. The study drew the same effect at 44 pt, 500 + 140 p; the clip uses the 52 pt token and 150 so the end state equals the sheet 86 token.

## Per-stage table
p is progress, 0 to 1, capped at 0.85 until done. In the study a workout's p is `sets done / sets planned x 0.85`; a cook uses steps the same way.

| Stage | p | Weight (title / key word) | Ink to colour mix (title) | Key word | Strike | Timing and curve |
|---|---|---|---|---|---|---|
| Rest | 0 | 500 / 590 | 0% | colour 72% (once started); at rest, plain ink | none | none |
| Started (set 1) | 0 | 500 / 590 | 0% | colour fades in 0 to 72% | none | key word 600 ms, house curve (0.3, 0, 0.2, 1) |
| A third in (5 of 20) | 0.2125 | 532 / 622 | 12.8% | 72% | none | p tween 600 ms, house curve |
| Two thirds (10 of 20) | 0.425 | 564 / 654 | 25.5% | 72% | none | same |
| Three quarters (15 of 20) | 0.6375 | 596 / 686 | 38.3% | 72% | none | same |
| Last set (20 of 20) | 0.85 | 628 / 718 | 51% | 72% | none | same |
| Done | 1 | 650 / 740 | 60%, then 72% for one lift | 72% | 3 pt, x-height, left to right, wraps with the lines | p to 1 in 300 ms; strike 420 ms ease-out (0, 0, 0.58, 1) starting after the 300 ms; one 260 ms brighten (+12 points of mix up and back, ease-out); hold 900 ms |
| Dried | 0 | 500 / 500 | ink at 50% (title and key word alike) | no colour | kept, ink at 50% | 2 s ease-in-out (0.42, 0, 0.58, 1), starting 1.56 s after done begins; tracking returns to -3% |

Tracking tightens 1.2% of an em per unit of p (-3% to -4.2%) so the line holds its width while the weight grows; the title must not rewrap as it thickens. The strike is a 3 pt line at 58% of the line box from the top (the x-height), drawn left to right as one length across wrapped lines, and takes the title colour.

## The dry-back
Done is the moment of effort; the page lives with the result for hours, so it settles. Weight and colour (title and key word) ease to ink at 50% and weight 500 over 2 s; the strike stays, at the same 50%. The key word loses its +90 and its colour with the rest. After the dry the title is final; reopening the page shows the dried state with no replay.

## Reduce Motion
No growing, no draw-in, no brighten. Each stage change is a **150 ms crossfade** to the new state (the quiet-versions rule for MotionPolicy-owned changes, `tess-quiet-versions.md` item 4); the key word's colour crossfades in at set 1; at done the title crossfades to full weight and colour and **the strike appears by the same crossfade** (full length, no left-to-right draw); the dry-back is one 150 ms crossfade at the same moment (done + 1.56 s). The ending frame is identical to the full version. Clip: `tess-pick-title-progress-reduce-motion.mp4`.

## Low Power
Same values and same end states. Drop the 260 ms brighten, run the tweens at 30 fps. The dry-back still takes 2 s. Reduce Motion wins when both are on.

## Private-label behaviour
A private title is the same effect on the same schedule. The weight, colour, strike and dry-back run off p exactly as for a public title and never reveal more or differently: the key word is the label's private word (the stand-in the screen shows), the words that change with the stage (bench set 1 to fly set 4 to done) are not shown for a private title, the stage text under it is the generic stand-in, and nothing about the stage or p reaches the accessibility label, the widget, the Live Activity text or the haptics beyond what a private label already allows. Private labels do not skip the strike.

## One haptic rule
The **done haptic only**: one `.success` at the moment p reaches 1 and the strike starts (Done's own, per `tess-quiet-versions.md`). None per stage, none for the key word, none for the brighten, none for the dry-back. Reduce Motion: the same single haptic.

## Tests
- p 0 renders plain ink at weight 500; p 1 renders weight 650, title mix 60%, strike drawn.
- Weight and mix are linear in p; the key word is always title weight + 90 until the dry, and 72% colour once set 1 lands.
- p never exceeds 0.85 until done.
- The title does not rewrap between p 0 and p 1 at Dynamic Type default and at AX1.
- The strike wraps across lines as one left-to-right length; at done its total length equals the sum of line widths.
- After the dry-back: weight 500, ink 50%, strike present and at 50%; reopening shows that state with no animation.
- Reduce Motion: no tween over 150 ms, the strike's progress is a single crossfade, no brighten.
- Low Power: no brighten; end state the same.
- Private title: identical timings and values; no stage word in labels or logs.
- Exactly one haptic per completion; zero while p rises; none on a replay of a dried title.
- Forcing the area colour per area (Training, Kitchen, Review, Today) changes only the colour token; the schedule is identical.
- Interrupt: p going backwards (a set undone) tweens down in 600 ms, never below 0; undoing from done removes the strike with the same 150 ms crossfade and returns to the stage's p.

## Values for Builder A
```
title.size            52 pt, line height 56 (sheet 86 C Title)
title.weight(p)       500 + 150 * p          // variable axis, not named weights
title.tracking(p)     -0.03 - 0.012 * p  em
title.keyWeight       title.weight + 90
title.mix(p)          0.60 * p               // ink -> areaColour, oklab
title.keyMix          0.72 * ramp(set1)      // ramp 600 ms, house curve
p.cap                 0.85 until done
stage tween           600 ms, curve (0.3, 0, 0.2, 1)
done                  p -> 1 in 300 ms; strike 420 ms ease-out (0,0,0.58,1); brighten 260 ms (+0.12 mix, up and back); hold 900 ms
strike                3 pt, y = 58% of line box, colour = title colour, left to right across wrapped lines
dry                   starts done + 1.56 s; 2 s ease-in-out; weight 500, ink 50%, tracking -0.03, strike kept at 50%
reduceMotion          every change 150 ms crossfade; strike by crossfade; no brighten
lowPower              no brighten, 30 fps tweens
haptic                .success once at done
```
Gaps (lab defaults, Design to overrule): the brighten is the study's brightness(1.12) filter, restated here as +12 points of mix, and the strike's 58% line position is the study's; the stage p values at 52 pt use the study's 5, 10, 15, 20 of 20 sets.
