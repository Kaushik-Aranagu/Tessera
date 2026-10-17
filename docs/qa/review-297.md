# QA review 297: the set block (#297)

PR head 095c3df on base 308f778, which already merges master 620878b. 10 files (+659/-685) plus the recording `docs/recordings/30-set-block.mp4`. Static review plus a read of the recording; no toolchain here.
- New: WeightReel, WeightField, RepsRow, RestHorizon.
- Changed: PlateStack (large drawing) and WorkoutModeView.
- Removed: WeightDial.swift (the view), RepsDrum.swift, and `PlateStepKey` from WorkoutParts.swift.

**Verdict: PASS on the code. Logging, UNDO and the grammar's load model are untouched. The recording doesn't show a set being logged, the rest horizon, typing a weight, or Porcelain (R1).**

## The coordinator's two checks
1. **Each set logs through the existing actions with UNDO: yes, unchanged.**
   - `WorkoutSession.swift` isn't touched; neither are `keyRow` and the Log set hold. The new views only bind `session.weight` and `repsBinding`, as the old dial and drum did.
   - So a set still goes through `session` → `LogSet` with its UNDO, and edits through `EditSet`.
   - The weight reel writes `weight` as the finger moves. That's view state until Log set, exactly as the old dial's drag did, so nothing reaches the store before the hold.
2. **The removed `WeightDial` isn't the grammar's: right.**
   - Only the app-module **view** `struct WeightDial: View` (Features/Workout/Instruments/WeightDial.swift) is deleted.
   - Core's model `TesseraCore.WeightDial` (TesseraCore/Sources/TesseraCore/Training/Dial.swift) and `ObjectStore.weightDial(for:)` stay. The grammar (TessGrammar+Lift.swift:50, TessGrammar+Live.swift:24) and `WorkoutSession.weightDial(of:)` (:288, now spelled `TesseraCore.WeightDial`) use them.
   - Nothing left in the app names the deleted view, `RepsDrum` or `PlateStepKey`. The two remaining "WeightDial" mentions are comments about Core's model.

## What's right
- **Weight:**
  - Drag the numeral; the feel is Core's `ScrubFeel`, which has its own tests. Tap it to type.
  - Typing (WeightField) snaps to the nearest loadable weight, a tie goes lighter, and "81 isn't loadable; 80" shows for 2 s. A comma decimal is accepted.
  - `session.detents` is never empty (WorkoutSession.swift:303-307 falls back to 2.5 steps), so the `detents[...]` subscripts in WeightReel can't go out of range.
- **VoiceOver:** the old plus and minus keys were the non-gesture path. Now:
  - the reel is adjustable (swipe up or down by one load) and double tap types;
  - reps are adjustable from 1 to 50 and say "9, one more than last time";
  - the horizon has "Add 15 seconds" and "Skip rest" actions.
  - That covers what PlateStepKey gave.
- **Motion:** all animation goes through `tesseraAnimation` / `withTesseraAnimation`. With Reduce Motion on there are no neighbours, droplets, pop or rubber band, a coast lands at once, and plates fade instead of dropping.
- **Recording 30:** 590×1282 at 60 fps (2189 frames, 36.5 s), Obsidian. It shows the reel scrubbing 82.5 → 105 with the plates redrawn (25+15+2.5), the context line "beats 7RM", reps rising 7 → 11 with the cadmium stroke, and "Best e1RM yet, if it goes."

## R1 (before Design's sign-off, not a code change): the recording leaves out the parts that write or time
Recording 30 never logs a set and never rests. So it doesn't show:
- the Log set hold, then UNDO, with the new block;
- the rest horizon draining, drag right for +15, fling left to skip, and the first-three-rests hint;
- tap to type, including a snap ("81 isn't loadable; 80");
- Porcelain.

**Ask Builder A for one more clip covering those four.** The horizon is the one new gesture that drives real actions (`extendRest`, `skipRest`).

## Lows
- **L1:** RestHorizon's drag right sits in the gutter, close to the left edge (WorkoutModeView `platesOrRest(...).padding(.horizontal, Theme.Spacing.gutter)`). The old row kept 20 pt clear "so the back swipe never fires from the minus key" (the removed comment). A drag right starting near the edge may start the back swipe instead of +15. Check it on the device, or inset the horizon's hit area by 20 pt on the left.
- **L2:** `RepsRow.onBeat` is never passed (WorkoutModeView builds `RepsRow(reps:ghost:isLocked:)`), so Tess's "One more than last time." doesn't fire. The stroke and haptic do. Wire it, or drop the parameter.
- **L3:** `WorkoutSession.stepWeight(up:)` has no caller now that the step keys are gone. Delete it, or keep it for a hardware-key path.
- **L4:** `@AppStorage("restHorizonHints")` counts down on every `onAppear`, including a rest that reappears after an edit. That's harmless; the hint just goes a rest early.

## Addendum: head a9a6db8 (GitHub head confirmed), PASS

This head adds two commits on top of 095c3df. 3effbf3 adds clip 31, the H1 stress run. a9a6db8 adds Design's fixes and clip 32. The branch base is still 620878b. A trial merge onto current master (f274252 and later) is clean, and none of master's 27 changed files touch `Features/Workout`. The removed `stepWeight` has no caller on master outside the files this PR changes.

- **R1, closed by clip 32** (`docs/recordings/32-set-block-porcelain.mp4`: 590×1282, 60 fps, 6526 frames, 108.8 s, Porcelain). Contact sheet at one frame every 3 s:
  - Typing 81 shows "Goes to the nearest weight the gym can load." and lands on 80.
  - Dragging reps to 11 shows the cadmium stroke and "One more than last time."
  - The Log set hold leads to rest 3:00 with the horizon label "DRAG RIGHT +15 · FLING LEFT TO GO" and UNDO.
  - UNDO brings back set 1 at 80 × 11, and logging again starts rest 3:00.
  - Dragging right shows "+15. Drag again for more."
  - A fling skips to "set 2 of 4, last was 80 × 11".
- **L1, closed.** RestHorizon now reads the drag in global coordinates and ignores any drag that starts within 20 pt of the screen's left edge (RestHorizon.swift, `startLocation.x > 20` in both onChanged and onEnded). So +15 never competes with the back swipe.
- **L2, closed.** `onBeat` now sets "One more than last time." in Tess's corner for 4 s, only when no other reply is showing, and clears it only if it's still that line (WorkoutModeView.swift:465-475). The line appears in clip 32.
  - Low: the comment says "once per set", but dragging back to last time and up again fires it again. Harmless.
- **L3, closed.** `stepWeight(up:)` and its test are removed. The test for detents and plates per side stays.
- **L4, closed.** The hint counts down once per seated set (`hintedSet` against `session.lastSeated?.setID`), not on every reappearance.
- Rest controls: the "+15" and "Skip" words under the horizon are gone. +15 is still a tap on the countdown (with a VoiceOver label and hint) or the horizon's drag and its accessibility action. Skip rest is still the PaintKey or a fling. Nothing is lost.
- **Note for Design, not a QA blocker.** `RepsRow` no longer dries the stroke to ink after 1.2 s. It stays cadmium for as long as reps beat last time, which is what set-block.md:32 says. That's resting colour, against no-dots.md and colour-at-rest. The "a new best: e1RM 109.3" line during rest is also cadmium for the whole rest in clip 32. Design should confirm both.
