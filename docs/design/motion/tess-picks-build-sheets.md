# Tess picks: one build sheet per board idea (Builder A)

Replaces `docs/design/motion/tess-picks-build-sheets.md`, which mapped "the eleven" to sections of `tess-motion.md`. The eleven are the ideas on the board `tess-ideas.html` (idea 1 to 11, all picked by Kaushik), plus idea 12, the mouth. Docs only. Values come from `tess-picks.md` (sections 18a to 18f, 20), `tess-motion-build.md` and, where an idea needs a rule, `tess-ideas-13-15.md`. Anything chosen here is marked (lab default).

Build order from the board (`tess-ideas.html`, intro): 1 and 2, then 3 and 4, then the mouth (12), then 5, 6 and 10, then 7, 8 and 9, and 11 last.

**The eleven ideas ship directly, with no switch.** The only switch is the eyes setting in Settings > Review (Off / Eyes / Eyes and mouth, default Off). There is no "Tess motion picks" switch.

Rules on every sheet (`tess-picks.md:10-21`):
- The soul plays no haptic of her own, except idea 3's one tick (`tess-picks.md:18`). If a moment already has a haptic, that stays the only one.
- Each idea plays at most once per trigger, never loops, never runs while she is carried, and never cuts a mode above it (`tess-picks.md:19-20`).
- The blink always stays in Reduce Motion and Low Power (`tess-picks.md:21`).
- House rule: Low Power (LP) = Reduce Motion (RM) unless the doc says otherwise; where the doc differs it is shown and marked "Design to confirm".
- Test names: `tess-picks.md` gives test descriptions, not names; the camelCase names below are (lab default) names for those described tests.
- Code location: `tess-picks.md` names no file for most ideas; it says each one plugs into the router (`SoulRouter.swift`, `tess-motion-build.md:25`) and is keyed to an event, not a screen (`tess-picks.md:14-17`).

---

## Idea 1, Lights that follow the page
- Sees: while she works, her reading lights hop to the words the ask touches, rest on each, and skip around; the dock lights drift on slow noise (board).
- Code: `askClaude(kind, touched:)` event on the router; readers in `SoulFrame.swift` and `TessSoul.swift` (`tess-picks.md:36`, `tess-motion-build.md:16`). Each page maps touched objects to rects through the free-ground preference (`tess-picks.md:37`, `tess-motion-build.md:19`).
- Values: hop 340 ms with a 10 pt arc up, dwell 380 ms, sweep +/-45% of the word's width, never the same word twice in a row (`tess-picks.md:38`). Dock-light noise: three summed sines per light, periods 3.5 to 9.5 s, about +/-1 pt, seeded per working state (`tess-picks.md:40`). Fewer than two touched words on screen: the as-built sweep (`tess-picks.md:39`). Never in `.live` (`tess-picks.md:42`).
- Normal: all of it. RM: no readers (`tess-picks.md:43`). LP: no readers, the noise freezes, six lights hold still (`tess-picks.md:44`).
- Haptics: none.
- VoiceOver: not announced; her line is the announcement (lab default, docs say nothing).
- Tests (lab default names): `readersDwellOnTouchedRectsInJobOrder`, `twoWorkingStatesWithSameTouchedDifferInDockPaths` (`tess-picks.md:45`), `readersFallBackToSweepUnderTwoWords`.
- Eyes setting: works with eyes Off; the eyes are gone while she is split anyway (`tess-picks.md:41`).

## Idea 2, She wakes with you
- Sees: on the first open of the day her eyes open from closed and she gives one slow stretch, once a day (board).
- Code: router event `firstOpenOfDay` from `foregrounded` with "woke on" kept per day (`tess-picks.md:50`); the stretch in `TessSoul.swift` (file not named in the docs: Builder A picks).
- Values: lids 0.25 for 1.0 s, open over 400 ms ease-out; stretch at 1.5 s, mains 22% wider and about 20% shorter (s 1 to 1.22) over 600 ms ease-in-out, back over 700 ms; one blink at 3.4 s; mouth at rest (`tess-picks.md:51`). Day boundary 04:00, outside quiet hours 23:00 to 07:00 (`tess-picks.md:50`). Skipped in a live workout, Speak, or with an ask waiting; the day still counts as woken (`tess-picks.md:52`).
- Normal: as above. RM: no stretch, eyes open with a 200 ms crossfade (`tess-picks.md:54`). LP: same as RM (`tess-picks.md:55`).
- Haptics: none (`tess-picks.md:56`).
- VoiceOver: not announced (lab default).
- Tests (lab default names): `twoForegroundsOneDayGiveOneWake`, `foregroundsAt0359And0530And0701WakeOnlyAt0701` (`tess-picks.md:57`), `wakeSkippedInLiveWorkoutStillCountsDay`.
- Eyes setting: Eyes Off: the stretch only (`tess-picks.md:53`).

## Idea 3, Stroke her
- Sees: swipe a finger across her and a ripple runs through the paint, she blinks, and you feel one soft tick (board).
- Code: the pan in `Features/Command/BottomChrome.swift` (band emits the event, `tess-picks.md:229`); new haptic case `.soulStroke` in `DesignSystem/Haptics.swift` (`tess-picks.md:66`, file per `tess-motion-build.md:18`); ripple in `TessSoul.swift` (lab default).
- Values: pan starts outside her 64 pt hit area, inside the band (736 to 820), crosses her and leaves within 700 ms, at least 40 pt (`tess-picks.md:64`). Ripple: 4 pt x e^(-2.6k) x sin(0.25 x x - 16k), y 0.6 of that on a cosine, 1.6 s; one blink 50 ms after the finger leaves; mouth curve +0.5 for 900 ms (`tess-picks.md:65`). A second stroke within 1.6 s restarts with no second tick (`tess-picks.md:67`). Refused while working, listening, carried, or an ask waits (`tess-picks.md:68`). Not in `.live` (`tess-picks.md:70`).
- Normal: ripple, blink, tick. RM: no ripple; one blink and the tick (`tess-picks.md:71`). LP: ripple at 30 fps (`tess-picks.md:72`). Design to confirm: the doc keeps the ripple in LP.
- Haptics: one soft tick as the finger enters her, `.impact(flexibility: .soft, intensity: 0.3)`; the only haptic of hers on any idea (`tess-picks.md:66`).
- VoiceOver: not announced; no custom action (lab default).
- Tests (lab default names): `panStartingOnSoulIsNotAStroke`, `panAcrossSoulInUnder700msIsOneStrokeWithOneTick`, `bandPanCrossingSoulOnRecipePageDoesNotOpenPeek` (`tess-picks.md:73`).
- Eyes setting: Eyes Off: the ripple and the tick, no blink or gaze (`tess-picks.md:69`).

## Idea 4, She wears the day
- Sees: each thing you finish leaves her a little richer in colour; by evening she is deeper, at 4 AM she starts plain, no number anywhere (board).
- Code: file not named in the docs: Builder A picks. It rides the beat (`tess-picks.md:79`, `TessSoul.swift` `beat()` per `tess-motion-build.md:20`) and multiplies the day's palette (`tess-picks.md:85`). Event `taskDone`, `thingFinished` from the diff (`tess-picks.md:230`).
- Values: +0.10 saturation per done, applied at the beat's 520 ms; beat carries an extra +0.25 that dries away; cap +0.40 (four dones); undone within UNDO does not count; resets at 04:00 over the first idle minute, never a visible step (`tess-picks.md:78-80`). Drawn everywhere, `.live` included (`tess-picks.md:81`). Do not copy the clip's holes in the list (`tess-picks.md:86`).
- Normal / RM / LP: the same in all three, colour is not motion (`tess-picks.md:83-84`).
- Haptics: none; the done's own haptic stays the only one.
- VoiceOver: not announced (lab default).
- Tests (lab default names): `fiveDonesGivePointFourZeroSaturation`, `undoneDoneAddsNothing`, `resetsToZeroAt0400` (`tess-picks.md:87`).
- Eyes setting: works with eyes Off (`tess-picks.md:82`).

## Idea 12, The mouth
- Sees: one short line under her eyes that turns with the moment, never a frown at him (board).
- Code: `SoulMouth` beside `SoulEyes`, same overlay and frame; router exposes `expression: SoulExpression` (curve, tilt, open) (`tess-picks.md:124-125`). File not named in the docs: Builder A picks (`TessSoul.swift` / `SoulFrame.swift`, lab default).
- Values (`tess-picks.md:97-101`): 2.6 pt below the eyes' mean, 5.6 pt wide, 1.1 pt stroke, round caps, eyes' dark at 70%. `curve` 1.7 pt at +1, ends lift 0.5 pt; `tilt` 0.9 pt at +1, right corner only; `open` 2.7 x 2.8 pt. Rows (`tess-picks.md:105-115`): idle +0.2; listening open 0.75; thinking +0.2 tilt +0.4; reply +1.0 for 1.5 s then 600 ms; beat +1.0 for 940 ms; ask waiting +0.3 tilt +0.4; `claudeFailed` -0.35 for 1.2 s, the only dip; asleep 0 and 4.4 pt wide; rest clock still. Every shape change 250 ms ease-in-out (`tess-picks.md:117`). In `.live`: idle shape only (`tess-picks.md:121`).
- Normal: as above. RM: 150 ms crossfade, no glance offset (`tess-picks.md:122`). LP: same as RM (`tess-picks.md:123`).
- Haptics: none.
- VoiceOver: not announced (lab default).
- Tests (lab default names): `mouthMapsEveryModeToItsRow`, `mouthNeverBelowMiddleExceptClaudeFailed` (`tess-picks.md:126-127`), `mouthAbsentUnlessEyesAndMouthState`.
- Eyes setting: plays only in Eyes and mouth; in Eyes or Off there is no mouth, and it never plays without eyes (`tess-picks.md:119`, board: "with eyes off there is no face").

## Idea 5, She sleeps at night
- Sees: from 11 PM to 7 AM her eyes are closed, her colour muted and she breathes slowly; open the app late and one eye opens first (board).
- Code: moves as-built `resting` end from 06:00 to 07:00 (`tess-picks.md:134`); Core moves it (`tess-picks.md:256`); soul side in `TessSoul.swift` (lab default).
- Values: lids 0.25, no blink, clock 0.45x, saturation -0.35, scale 0.92, mouth flat and narrow (`tess-picks.md:135`). On open: right eye 250 ms after arrival over 350 ms, glance 0.4 left and 0.3 up; left 2.4 s later over 400 ms; clock back to 1x over 1.2 s, saturation and scale over 1.5 s; back to sleep after 60 s alone over 3 s (`tess-picks.md:136`). Never in `.live` (`tess-picks.md:139`). Not idea 2's wake (`tess-picks.md:137`).
- Normal: as above. RM: same values, no clock slow-down, crossfades instead of eye opens (`tess-picks.md:140`). LP: same (`tess-picks.md:141`).
- Haptics: none.
- VoiceOver: not announced (lab default).
- Tests (lab default names): `openingAt2330OpensRightEyeFirst`, `asleepAt0659AwakeAt0700` (`tess-picks.md:142`), `liveWorkoutAtNightIsAwake`.
- Eyes setting: Eyes Off: the slow breath, the colour and the size only (`tess-picks.md:138`).

## Idea 6, She watches what you hold
- Sees: while you lift a row to move it her eyes follow the row; on the drop she looks back and blinks (board).
- Code: events `rowLifted / rowMoved / rowDropped` from every reorderable list (`tess-picks.md:147, 231`); gaze in `TessSoul.swift` (lab default).
- Values: eyes follow the row centre, x -1, y clamped to (row y - her y) / 600; on the drop one blink after 200 ms, back ahead over 300 ms; mouth at rest; refused while working or carried (`tess-picks.md:148-151`).
- Normal: as above. RM: no glance, nothing (`tess-picks.md:152`). LP: not specified in the docs (house rule: same as RM).
- Haptics: none; the list's own drag haptics stay the only ones.
- VoiceOver: not announced (lab default).
- Tests (lab default names): `heldRowAtY400GivesGazeYMinusPointSixThree` (`tess-picks.md:153`), `dropGivesOneBlink`, `refusedWhileWorkingOrCarried`.
- Eyes setting: needs eyes; with eyes Off it does nothing (`tess-picks.md:150`).

## Idea 10, She watches the rest clock
- Sees: in the last seconds of a rest her eyes move to the timer; at Go the timer owns the moment and she looks back (board).
- Code: event `restEnding(rect)` from the live workout only (`tess-picks.md:158, 235`); gaze in `TessSoul.swift` (lab default).
- Values: eyes only, to (-1, -1) over 300 ms, stay; at Go back over 300 ms with one blink at Go + 100 ms; no lean, colour, sound, haptic, ask or mouth change (`tess-picks.md:159`). Last 10 s of the rest (`tess-picks.md:158`). Narrow exception to "no looking around in a live workout" (`tess-picks.md:161`).
- Normal: as above. RM: nothing (`tess-picks.md:162`). LP: not specified in the docs (house rule: same as RM).
- Haptics: none.
- VoiceOver: not announced (lab default).
- Tests (lab default names): `restEndingChangesGazeAndNothingElse` (`tess-picks.md:163`), `goReturnsGazeWithBlinkAtPlus100ms`.
- Eyes setting: needs eyes; with eyes Off it does nothing (`tess-picks.md:160`). Mouth holds, whatever it was (`tess-picks.md:115`).

## Idea 7, A nudge before the next thing
- Sees: ten minutes before something with a time, she leans toward the list once and glances at it, then settles (board).
- Code: event `upcoming(rect)` from Core's scheduler, once per item (`tess-picks.md:170, 232`); lean in `TessSoul.swift` (lab default).
- Values: lean 4 pt toward the row (0.6 x, 0.8 y), out 400 ms ease-out, hold 1.3 s, back 500 ms on the house curve; eyes to the row, one blink at the end; only with the app open and the row on screen; never in quiet hours or `.live` (`tess-picks.md:171-175`).
- Normal: as above. RM: eyes only, no lean (`tess-picks.md:176`). LP: same as RM (`tess-picks.md:177`).
- Haptics: none; not a notification.
- VoiceOver: not announced (lab default).
- Tests (lab default names): `onlyOneUpcomingPerItem`, `secondEmitForSameItemDoesNothing` (`tess-picks.md:178`), `noNudgeInQuietHours`.
- Eyes setting: Eyes Off: the lean only (`tess-picks.md:174`). RM with eyes off: nothing (`tess-picks.md:176`).

## Idea 8, She hears you type
- Sees: when you type to her, each finished word gives her one tiny pulse, like her breath with your voice (board).
- Code: event `wordTyped` from the capture field (`tess-picks.md:183, 233`); pulse in `TessSoul.swift` (lab default).
- Values: scale +0.06 over 80 ms, back over 250 ms; no glow, no haptic; at most one pulse per 180 ms; mouth at rest (`tess-picks.md:184-186`).
- Normal: as above. RM: no pulse (`tess-picks.md:188`). LP: pulses at most every 400 ms (`tess-picks.md:189`). Design to confirm: the doc differs from the house rule.
- Haptics: none.
- VoiceOver: not announced (lab default).
- Tests (lab default names): `fourWordsWithin300msGiveAtMostTwoPulses` (`tess-picks.md:190`), `pulseNeverFasterThan180ms`, `lowPowerPulseGapIs400ms`.
- Eyes setting: Eyes Off: the pulse only, so it works with eyes Off (`tess-picks.md:187`).

## Idea 9, She peeks at the end of a list
- Sees: when you scroll to the bottom of a page she rises a few points as if looking over the last row, then settles (board).
- Code: event `reachedEnd` from every scrolling page (`tess-picks.md:195, 234`); never from a run's or a side's rubber band (`tess-picks.md:240`). Rise in `TessSoul.swift` (lab default).
- Values: within 8 pt of the last row, once per page visit; rise 5 pt over 350 ms ease-out, hold 1.6 s, down over 500 ms on the house curve; eyes up at 0.5 x / 1 y, one blink at the top; not while roaming, working, carried or an ask waits; never in `.live` (`tess-picks.md:195-199`).
- Normal: as above. RM: nothing (`tess-picks.md:200`). LP: not specified in the docs (house rule: same as RM).
- Haptics: none.
- VoiceOver: not announced (lab default).
- Tests (lab default names): `twoScrollsToEndInOneVisitGiveOnePeek`, `leavingAndComingBackGivesAnotherPeek` (`tess-picks.md:201`), `noPeekWhileWorking`.
- Eyes setting: Eyes Off: the rise only, so it works with eyes Off (`tess-picks.md:198`).

## Idea 11, She sits under the glass
- Sees: tilt the phone and she shifts a point or two, her outer lights a little more, as if just under the screen (board).
- Code: `CMMotionManager` device attitude, in `TessSoul.swift` (lab default; file not named in the docs: Builder A picks); updates stop with her `TimelineView` (`tess-picks.md:206, 209`).
- Values: 30 Hz, low-pass 0.15; mains up to +/-2 pt x and +/-1.4 pt y, satellites x1.7 of that; eyes +/-0.6 / +/-0.4, mouth follows the eyes; off when carried, working, listening, `.live`, Speak, cook mode, or flat within 3 degrees for 2 s (`tess-picks.md:206-208`). Energy log run (a) must stay Low (`tess-picks.md:209`).
- Normal: as above. RM: off, no motion manager started. LP: off (board; `tess-picks.md:206`).
- Haptics: none.
- VoiceOver: not announced (lab default).
- Tests (lab default names): `reduceMotionStartsNoMotionManager` (`tess-picks.md:210`), `lowPowerStartsNoMotionManager`, `flatOnTableStopsShift`.
- Eyes setting: the body shift works with eyes Off; the eyes and mouth follow only when they are on (`tess-picks.md:207`).

---

## Review switch (Settings > Review)

**One switch. Label: Tess has eyes** (`tess-picks.md:11`, `tess-picks.md:119`; `tess-motion-build.md:15` has the line under Settings > Tess, now in Review per Product). Setting key `tess.eyes` (`tess-motion-build.md:15`); the three-state value is (lab default) an enum in `SettingsStore`. Default Off.

- **Off:** Before and after: Tess is a soft glow with no face. Ideas that need eyes stay quiet; the rest still play.
- **Eyes:** Before and after: Tess gets two small eyes that blink and glance. She wakes, looks at what you hold, and checks the rest clock. No mouth.
- **Eyes and mouth:** Before and after: Tess also gets a small line under her eyes that turns up with her good news. It never frowns at you, and it never shows without the eyes.

Ideas that do nothing with Off: 6, 10 (and the eye parts of 2, 3, 5, 7, 8, 9, 11). Idea 12 plays only in Eyes and mouth.

---

## Asks

- **Design: Low Power vs Reduce Motion.** The docs differ from the house rule on idea 3 (ripple stays in LP at 30 fps, `tess-picks.md:72`), idea 8 (LP pulses every 400 ms, `tess-picks.md:189`), and idea 1 (LP freezes the noise, RM says nothing of it, `tess-picks.md:43-44`). Ideas 6, 9 and 10 give no LP row. Sheets follow the doc where it speaks; confirm.
- **Design: opacity in Reduce Motion.** `tess-motion.md:222` says the soul's mode is never shown by opacity; `tess-motion.md:226` makes the idle breath an opacity pulse (0.85 to 1 over 3.2 s) in RM. Read here as: modes never use opacity, the breath may.
- **Idle fps:** `tess-motion.md:226` still says 20 fps in Low Power; `tess-motion.md:242` and `tess-motion-build.md:24` say 30 fps. 30 wins (`tess-motion.md:242`); Builder A follows 30.
- **Design: idea 5 vs idea 2 at 07:00.** Idea 5 moves the as-built wake from 06:00 to 07:00 (`tess-picks.md:134`); `tess-motion-build.md` still lists no such change. Core owns it (`tess-picks.md:256`); confirm no other doc still says 06:00.
