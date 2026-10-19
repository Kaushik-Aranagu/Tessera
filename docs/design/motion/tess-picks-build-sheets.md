# Tess picks: one build sheet per pick (Builder A)

From Product's huddle push (Oct 19): the eyes and mouth and the picked ideas ship behind two Review switches in Settings, "Tess eyes and mouth" and "Tess motion picks". One short sheet per pick, in build order, with the Review wording for each switch at the end. Docs only. Values come from `tess-motion.md`, `tess-motion-build.md` and, for the mouth, `tess-picks.md` (section 18c); anything chosen here is marked lab default.

Order (lab default where it differs from the docs): `tess-motion-build.md:5-9` gives eyes, working, drag with docks, roam. Those four go first, in that order. The mouth rides right after the eyes (same switch, same overlay). The rest follow in the numeric order of `tess-motion.md`: (2) idle, (6) reward beat, (7) living colour, (8) listening and asks, (9) outside the app, (11) recut looks, (12) a minute at rest.

Numbering note: `tess-motion.md` has sections 1 to 9, 11 and 12 as picks (there is no section 10), so the numbers below are those section numbers. Sections 13 to 15 are rules (Low Power, event contract, lens), not picks.

Rules that hold on every sheet (from the brief and `tess-motion.md:20-22, 222, 336`):
- LP = RM = no extra motion. In Reduce Motion and Sleep the soul keeps full opacity, never diffused or dimmed (G225/D4, `tess-motion.md:222`).
- The soul never plays a haptic of her own. VoiceOver: the soul is not announced; her line is announced as the band's own text (lab default, the docs say nothing on VoiceOver for the soul).
- Every sheet's "Code" is from `tess-motion-build.md:14-26`. A pick with no file there gets the standard line.
- Switch A = "Tess eyes and mouth". Switch B = "Tess motion picks". Both default off.

---

## Eyes (1), Switch A
- Sees: two tiny dark dots on her that blink and glance, so she has somewhere to look from.
- Code: `Features/Tess/TessSoul.swift`, `TessSoul.eyes: Bool`, drawn after the canvas (`tess-motion-build.md:14`). Setting key `tess.eyes`, default no (`tess-motion-build.md:15`).
- Values: 3.2 x 3.5 pt ovals, 8.4 pt apart, 3 pt above the mean of the three main dabs, dark pigment (`ink` on light looks, `ground` on dark) at 82% normal blend (`tess-motion.md:30-32`). Blink 160 ms, height to 0.25, every 3 to 8 s, one in five a double with 250 ms between (`tess-motion.md:33`). Glance up to 3 pt sideways, 2.2 pt up or down, spring 300 ms bounce 0.05 (`tess-motion.md:34`). Done: out in 120 ms, back 200 ms after it ends (`tess-motion.md:36`). No blink while listening (`tess-motion.md:138`).
- Normal: all of the above, shown in idle, listening, needs you, resting; whole-only in thinking and working.
- Reduce Motion: dots sit still, the blink stays (160 ms, no travel), no glance (`tess-motion.md:37, 227`).
- Low Power: same as Reduce Motion for the brief's rule; the doc keeps the glance in LP (`tess-motion.md:227`), see Doubts.
- Haptics: none.
- VoiceOver: not announced, `accessibilityHidden` (lab default).
- Tests: `eyesBlinkGapStaysThreeToEightSeconds`, `eyesHiddenDuringDoneAndBackAfterTwoHundredMs`, `eyesNoBlinkWhileListening`.
- Switch hides: with Switch A off, no eyes are drawn and no glance or blink exists.

## Mouth, extra pick, Switch A
- Sees: a tiny dark line under the eyes that turns up a little with her moments, never down at him.
- Code: file not named in `tess-motion-build.md`; `tess-picks.md:124` says `SoulMouth` beside `SoulEyes`, drawn in the same overlay, with `expression: SoulExpression` (curve, tilt, open) on the router. Keep it in `TessSoul.swift`/`SoulFrame.swift` unless a page needs a preference.
- Values (`tess-picks.md:97-101`): 2.6 pt below the eyes' mean, 5.6 pt wide, 1.1 pt stroke, round caps, eyes' dark at 70%. `curve` 1.7 pt at +1, `tilt` 0.9 pt at +1, `open` soft o 2.7 x 2.8 pt. Idle +0.2; listening open 0.75; reply +1.0 for 1.5 s then 600 ms; beat +1.0 for 940 ms; ask waiting +0.3 tilt +0.4; `claudeFailed` -0.35 for 1.2 s, the only dip (`tess-picks.md:105-113`). Every shape change 250 ms ease-in-out (`tess-picks.md:117`). Gone with the eyes in working and Done.
- Normal: as above, only with eyes on.
- Reduce Motion: 150 ms crossfade between shapes, no glance offset (`tess-picks.md:122`).
- Low Power: same as Reduce Motion (`tess-picks.md:123`).
- Haptics: none.
- VoiceOver: not announced (lab default).
- Tests: `mouthMapsEveryModeToItsRow`, `mouthNeverBelowMiddleExceptClaudeFailed`, `mouthAbsentWhenEyesOff`.
- Switch hides: with Switch A off there is no mouth, and with the eyes off it never shows.

## Working (5), Switch B
- Sees: her colour fades, she splits into faint lights that drift (and scan the rows she reads), then they come back together and Done plays.
- Code: `Mode.working(reading: [CGRect]?)` in `SoulParameters.swift` (a `working` row), `SoulFrame.swift` (six children, constellation, readers), `TessSoul.swift` (readers' canvas) (`tess-motion-build.md:16`). Router decides working vs thinking (`tess-motion-build.md:17`).
- Values (`tess-motion.md:83-87`): fade 500 ms to saturation 0.62, contrast 1.0, opacity 90%, halo 0. Split 900 ms into 12 lights, 11 to 15 pt radius, blur 5, alpha 0.55 (readers 0.42), cobalt child within 8 pt of the dock. Gather 820 ms (constellation 680 ms). Colour back from 300 ms into the gather over 550 ms. Frame budget in `tess-motion-build.md:36-39`.
- Normal: full version, readers only on a page that declares free ground (`tess-motion-build.md:32`).
- Reduce Motion: 200 ms crossfade to the loosened pose, mains 1.5x from centre, opacity 1, grade and halo unchanged, 200 ms back (`tess-motion.md:230`).
- Low Power: six lights, no readers, 30 fps, colour back over the same 550 ms (`tess-motion.md:230`). No extra motion beyond that.
- Haptics: none from the soul. The raw `.success` at `TessSoul.swift:143` is deleted (index H9; Done plays `.done` through the haptic map).
- VoiceOver: not announced; the line ("Planning your day.") is the announcement (`tess-motion.md:90`).
- Tests: `workingSaturationIsPointSixTwoAtHalfSecond`, `workingLightsLandWithinOnePointAtGather`, `workingLowPowerHasSixLightsNoReaders`.
- Switch hides: with Switch B off the soul stays whole and uses thinking's pulse for long asks.

## Drag with docks (4), Switch B
- Sees: hold and move her, she lifts above the finger, and settles at the bottom right or bottom left dock.
- Code: `Features/Command/BottomChrome.swift` (`soulKey` gesture), `DesignSystem/Haptics.swift` (`.soulPickUp`, `.soulDrop`); soul side in `TessSoul.swift` (`tess-motion-build.md:18`).
- Values (`tess-motion.md:69-72`): pick-up at 10 pt before the 400 ms timer, grow 1.22 over 160 ms, 44 pt above the fingertip over 180 ms, halo +12%. Paint lag capped 14 pt. Drop on the house spring 420 ms bounce 0.12, size back over 300 ms. Flick over 600 pt/s projects 0.18 s. Docks (346, 779) and (47, 779). Bottom-left drop moves the band's line, lens, ask words and UNDO to x 96, band stays 736 to 820 (`tess-motion.md:74`). Key `tess.dock.<page>`.
- Normal: as above.
- Reduce Motion: 200 ms crossfade to the dock on release, no carry lag, no grow (`tess-motion.md:229`).
- Low Power: same as Reduce Motion for the brief's rule; the doc keeps drag unchanged in LP (`tess-motion.md:229`), see Doubts.
- Haptics: none from the soul. The gesture's `.soulPickUp` (soft 0.5) and `.soulDrop` (`.selection`) belong to `BottomChrome` (B) (`tess-motion.md:331-332`).
- VoiceOver: not announced; add no custom action (lab default).
- Tests: `dragTenPointsBeforeHoldStartsDragNotListener`, `dragDropPicksNearestDock`, `dragBottomLeftMovesBandWordsToX96`.
- Switch hides: with Switch B off she cannot be picked up and the hold-to-talk, tap and double tap stay as built.

## Roam (3), Switch B
- Sees: she walks to the row she is changing, works beside its last word, and walks home.
- Code: `TessSoul.place`, free-ground rects per page, ride-and-release on scroll, the 80 x 80 clear test; `SoulTravel` as built; each page reports free ground through a preference (`tess-motion-build.md:19`).
- Values (`tess-motion.md:49-52`): arc 760 ms (x `0.55, 0, 0.15, 1`, y `0.3, 0, 0.25, 1`), 40 pt after the row's last word, 6 pt above its baseline; works with lights in 20 x 12 pt, no readers; Done in place only with an 80 x 80 clear, else home first. Never under 56 x 44 free (`tess-motion.md:17`). Releases at baseline y 130 or y 700 (`tess-motion.md:58`).
- Normal: as above, page by page, Home first (`tess-motion-build.md:9`).
- Reduce Motion: no travel, she stays home and the line names the row (`tess-motion.md:228`).
- Low Power: no roam, she stays at the dock, work runs there (`tess-motion.md:228`).
- Haptics: none.
- VoiceOver: not announced; the line names the row.
- Tests: `roamNeverWhereFreeGroundUnder56By44`, `roamReleasesWhenRowPassesY130`, `roamRefusedInLowPowerAndLiveWorkout`.
- Switch hides: with Switch B off she never leaves the dock, and Done plays at home.

## Idle (2), as built
- Sees: the calm breathing she already has; with eyes on, the lift reads as her looking up.
- Code: no new code; `SoulParameters.idle` as built (`tess-motion.md:42`).
- Values: 9 s period, drawn at 0.62, one dab at a time (`tess-motion.md:42`). Tick 30 fps (`tess-motion.md:213`).
- Normal: as built. Reduce Motion: still frame, breath is opacity only 0.85 to 1 over 3.2 s, blink stays (`tess-motion.md:226`). Low Power: no extra motion, halo breath held at its mean (`tess-motion.md:226`).
- Haptics: none. VoiceOver: not announced.
- Tests: `idleAddsNoModeChangeOrHapticOverSixtySeconds`, `idleReduceMotionBreathIsOpacityOnly`.
- Switch hides: nothing; idle is as built and the glance only exists under Switch A.

## Her beat in a reward (6), Switch B
- Sees: when he finishes a task she takes one small breath in and brightens, with a blink if eyes are on.
- Code: `TessSoul.swift` `beat()`, called from QueueRow, hero, habits, Groceries (B) and the workout finish (A) (`tess-motion-build.md:20`).
- Values (`tess-motion.md:105-107`): 940 ms overlay; at 520 ms (0 for a fleck leaving the soul) satellites pull to 55% over 180 ms, release over 320 ms; brighten 1 to 1.12; saturation 1.45 to 1.75 to 1.45 dried over 900 ms; one 160 ms blink.
- Normal: as above. Reduce Motion: no gather, no glance, brighten as a 200 ms crossfade, blink stays (`tess-motion.md:114`). Low Power: no extra motion; doc keeps it unchanged (`tess-motion.md:235`).
- Haptics: none from the soul (`tess-motion.md:101`).
- VoiceOver: not announced.
- Tests: `beatEndsWithinNineHundredFortyMs`, `beatPlaysNoHapticFromSoul`, `beatNeverStartsDonesPour`.
- Switch hides: with Switch B off a finished task gives no beat; the row's own motion stays.

## Living colour in motion (7), Switch B
- Sees: when the day's palette changes, her three colours pool in one after another and dry.
- Code: `TessSoul.repaint(to:)`, `SoulPalette.look(_:living:)`, `SoulRenderer.dab` (`tess-motion-build.md:21`).
- Values (`tess-motion.md:122-124`): order cobalt, vermilion, cadmium, 120 ms apart; 900 ms `0.3, 0, 0.2, 1` per dab; swell 1.12, lift 0.2 (mid only on dark looks), in over 250 ms; dry at start + 2.8 s. Idle only; work wins if it starts (`tess-motion.md:127`).
- Normal: as above. Reduce Motion: one 600 ms crossfade, no swell (`tess-motion.md:130`). Low Power: no repaint starts, waits for the next idle (`tess-motion.md:236`).
- Haptics: none.
- VoiceOver: not announced.
- Tests: `repaintPoolOrderAndStaggerHold`, `repaintDeferredInLowPower`, `repaintInFlightDriesWithinFiveHundredMsWhenWorkStarts`.
- Switch hides: with Switch B off the palette change is a plain cut with no pool.

## While she listens or asks (8), Switch B for the lab additions
- Sees: with eyes on she looks up at him while he talks and at her question while an ask waits; the lean and slow breath come back after.
- Code: `TessSoul.swift` and the router; `BottomChrome` emits (B) (`tess-motion-build.md:25`).
- Values (`tess-motion.md:138-141`): eyes up while listening, no blink; ask wait breath 3.2 s to 4.8 s, lean 4 pt, glance x -3 y +1.3; return 300 ms. No roam, split or repaint while listening or an ask waits.
- Normal: as above. Reduce Motion: no travel to the bloom, no lean, eyes hold (`tess-motion.md:147`). Low Power: no extra motion; doc keeps the lean (`tess-motion.md:233`).
- Haptics: none; the ask's own `.selection` is not hers.
- VoiceOver: not announced.
- Tests: `listeningNoBlinkWhileListenerActive`, `askWaitBlocksRoamSplitRepaint`, `askLeanReturnsWithinThreeHundredMs`.
- Switch hides: the eye moves need Switch A; the lean, breath and no-roam rules ride Switch B.

## Outside the app (9), Switch A for the glance
- Sees: widgets and Live Activities have none of her; coming back from one she sits at rest and glances once at the return line.
- Code: nothing in the extension target; the glance on a return line and `Mode.working` entered without the split on becoming active (`tess-motion-build.md:22`).
- Values (`tess-motion.md:163`): glance spring 300 ms, x -3, y +1.3, eyes back after 420 ms, no blink, no beat, no haptic. Mid-work return: drawn mid-constellation, no split-in (`tess-motion.md:165`).
- Normal: as above. Reduce Motion: the glance stays (a spring under 300 ms) (`tess-motion.md:167`). Low Power: nothing to change (`tess-motion.md:238`).
- Haptics: none.
- VoiceOver: not announced.
- Tests: `returnLineGivesGlanceNoBeatNoHaptic`, `activeWhileWorkingSkipsSplit`, `extensionTargetsContainNoSoulSource`.
- Switch hides: the glance needs the eyes (Switch A); the no-split return needs Switch B.

## The soul on the recut looks (11), as built
- Sees: nothing new; her three dabs follow each look's own colours.
- Code: nothing to build for the dabs (`tess-motion-build.md:23`); `repaint(to:)` is cancelled on a look switch and eyes hold during `PaintFlood` (`TessSoul.swift`).
- Values: pale stops 0.58 / 0.42 and halo 0.08 / 0.05 on Porcelain, Plein, Celadon (`tess-motion.md:182-183`); flood 700 ms, no repaint until it has dried (`tess-motion.md:193`).
- Normal: as above. Reduce Motion: 150 ms crossfade (`tess-motion.md:237`). Low Power: same, 150 ms crossfade (`tess-motion.md:237`).
- Haptics: none. VoiceOver: not announced.
- Tests: `pleinUsesPaleStopsAndHalo`, `lookSwitchCancelsRepaintInOneFrame`, `noBlinkWhilePaintFloodRuns`.
- Switch hides: nothing; looks work with both switches off.

## A minute of Home at rest (12), as built
- Sees: nothing but breath and a blink for a whole minute.
- Code: no new code; budget check on `TessSoul.swift` (`tess-motion.md:212-217`).
- Values: 7 to 15 blinks, gaps 3 to 8 s, tick 30 fps, under 2 ms a frame, `TessSoul.body` evaluated once (`tess-motion.md:207, 213-215`).
- Normal: as above. Reduce Motion: opacity breath and blink only (`tess-motion.md:226`). Low Power: no extra motion; 30 fps in every mode (`tess-motion.md:242`).
- Haptics: none. VoiceOver: not announced.
- Tests: `minuteAtRestPostsNoHapticLineOrModeChange`, `minuteAtRestBlinkCountSevenToFifteen`.
- Switch hides: nothing; blinks need Switch A, the rest is as built.

---

## Review switches (Settings > Review)

**Switch 1. Label: Tess eyes and mouth** (default off)
- Before and after: Before, Tess is a soft glow. After, she has two small eyes and a mouth that turns up when she has good news.
- Turns on: `tess.eyes` (eyes, blink, glance, the return glance) and the mouth (`SoulMouth`). The mouth never shows without the eyes (`tess-picks.md:119`).

**Switch 2. Label: Tess motion picks** (default off)
- Before and after: Before, Tess stays in her corner and works quietly. After, she walks to the row she changes, you can move her, and she splits into lights while she works.
- Turns on: working (5), drag with docks (4), roam (3), her reward beat (6), living colour (7), the listening and ask additions (8), the no-split return (9). Idle (2), recut looks (11) and a minute at rest (12) are as built and never hidden.

---

## Asks

- **Design:** Low Power. The house rule is LP = RM. `tess-motion.md:227-229` keeps the eyes' glance and the whole drag unchanged in Low Power, and Working in Low Power keeps six lights at 30 fps (`tess-motion.md:230`). The sheets give the house rule and cite the doc line; confirm which wins per pick.
- **Design:** Reduce Motion breath. `tess-motion.md:222` says modes are never shown by opacity; `:226` and `:339` make the breath an opacity pulse (0.85 to 1). Read here as: modes never use opacity, the breath itself may pulse.
- **Product:** the count. `tess-motion.md` has no section 10, so "11 picks" is read as sections 1 to 9, 11 and 12, with eyes carrying the mouth. If Product means a different eleven (for example with the lens, section 15), those sheets still need adding.
- **Product:** the switch split. The docs have one setting ("Tess has eyes", `tess-motion-build.md:15`); Switch B and which picks it gates are lab defaults.
- **Idle fps:** `tess-motion.md:226` still says 20 fps in Low Power; `:242` and `tess-motion-build.md:24` say 30 fps, which is used here. Builder A follows 30.
