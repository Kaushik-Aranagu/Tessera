# Cook clock page, VoiceOver finish keys, Low Power haptics, keep-awake

For: Builder A (workout, Live Activities, the haptic map), Builder B (Recipes page, Kitchen), Core (engine, process table), Design (specs), QA. Docs only; nothing was built or run (no Swift toolchain here). Rests on Product's 9:07 PM PT Oct 17 rulings G228, G229, G223 and G218 (`decisions.md` line 1007; the CLOCK CORRECTION at line 937 means every stamp from 1:41 PM on is PT as written in the entry, nothing here is a future ruling), on the gap hunt that raised them (`docs/product/kitchen-gap-hunt-16-cook-recipe-lowpower-voiceover-oct17.md`), and on research REFILL item 8 (`ops/board/research.md`, 9:15 PM PT Oct 17). VO5 to VO24 are the existing rows in `voiceover-recipe-clock-lists.md`; they are referenced here, not restated.

Status words: **traced** means I read the master line and it does what the row says; **inferred** follows from code not read in full; **gap** means master has nothing for it. Owners: Builder A = training, workout, widgets, Live Activities; Builder B = Home, ask slot, Groceries, Recipes, Lists, Kitchen week; Core = engine and privacy; Design = specs.

Master facts read (`origin/master` bed4ea3b):
- No cook screen exists. `RecipePage.cookModeReady` is `false` (`Features/Recipes/RecipePage.swift:13`) and the Cook key is built only behind it (`RecipePage.swift:160`; `Features/Home/NowPage.swift:242-246`). `Features/Kitchen/` holds only `CookModeCopy` and the pantry files.
- Zero hits for `isIdleTimerDisabled` in any Swift file, the workout included.
- `isLowPowerModeEnabled` is read in one place, `Features/Tess/TessSoul.swift:109`. `DesignSystem/Haptics.swift` and `MotionPolicy.swift` never read it.
- `PaintKey` (`DesignSystem/Paint.swift`) gives every key, hold or tap, a default VoiceOver action that completes (`Paint.swift:314`), and its hint doc says the hint names the effect, never the gesture (`Paint.swift:250-253`).
- `docs/research/fixtures/haptic-moments.md` is on master (the gap hunt named `docs/design/haptic-moments.md`, which is not); its item 3 carries the G223 ruling and #941 corrects it (LP09).

## 1. G228: the clock page is the cook (CK)

Ruled: Design 69 replaces sheet 12's cover. VO5 to VO24 govern the cook screen. K84 rows carry over only where the clock page has the same thing: K84.14 and K84.26 (Done), K84.22 (timer end), K84.25 (receipt), K84.27. K84.20's "Next" bar and cover reading order do not apply. Kitchen adds a one-paragraph map in `cook-mode-acceptance.md`.

| Id | Input | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| CK01 | Open a recipe, press Cook | the clock page is the cook screen; no separate cover screen is pushed | `cookModeReady` false, no cook view (`RecipePage.swift:13,160`) | gap | Builder A | `cookOpensTheClockPageNotACover` |
| CK02 | VoiceOver on the clock page, swipe forward from the top | order is VO5 to VO24: steps, the key row (STOP with minutes left), INGREDIENTS word; no cover heading, no "Step N of M" line apart from the step value | none | gap | Builder A | `clockPageReadingOrderFollowsVO5ToVO24` |
| CK03 | Clock page during a cook | no "Next" bar element exists in the tree (K84.20 does not apply) | `CookModeCopy.next` and `nextHint` still exist (`Features/Kitchen/CookModeCopy.swift:9-10`), unused | inferred | Builder A | `clockPageHasNoNextBar` |
| CK04 | Same page | no heading "Weeknight dal, cooking" element (K84.20 cover heading) | `CookModeCopy.heading` exists (`CookModeCopy.swift:18-20`), unused | inferred | Builder A | `clockPageHasNoCoverHeading` |
| CK05 | A private recipe cooked on the clock page | every spoken name reads "Private recipe", never the title | wall string traced in `CookModeCopy.heading` (`CookModeCopy.swift:71-73`) and tested (`TesseraTests/CookModeCopyTests.swift:31-34`); the clock page has no caller | inferred | Core | `clockPageNamesAPrivateRecipeAsPrivateRecipe` |
| CK06 | Timer ends while the clock page is open | line "Simmer, done." with a Stop action (K84.22); announced once as "Simmer is done."; focus does not move | strings traced (`CookModeCopy.swift:27-35`, tests `CookModeCopyTests.swift:9-14`); no announcement, no page | gap | Builder A | `timerEndAnnouncesOnceAndKeepsFocus` |
| CK07 | A step runs over (VO14) | held step value "Time's up, waiting for you"; actions "Next step", "5 more minutes"; announced once, not each minute | none | gap | Builder A | `overrunStepAnnouncesOnceAndOffersTwoActions` |
| CK08 | Done pressed, receipt (K84.25, VO20) | announce "Paprika chicken, cooked."; one Undo; context line then "cooked today" | none | gap | Builder A | `finishAnnouncesTheCookedReceipt` |
| CK09 | Durations spoken on the clock page | words, not letters: "8 minutes", "1 hour 5 minutes", "under a minute" | `CookModeCopy.duration` traced (`CookModeCopy.swift:53-64`, tests `CookModeCopyTests.swift:16-22`) | traced (formatter only) | Builder A | `durationsAreWords` (exists as `durationsInWords`) |
| CK10 | K84 rows that name something the clock page lacks (K84.20 reading order, Next bar) | marked not applicable in `kitchen-cook-mode-accessibility-acceptance.md`; QA does not fail the build on them | the gap hunt calls out two live orders (G228); spec edit not on master | gap | Design | `docsMarkK84_20AsSupersededByVO5ToVO24` (a docs check, not Swift; QA runs it by reading) |
| CK11 | Cook-mode targets on the clock page | at least 64 pt, 88 pt from AX1 up | `CookModeCopy.minTarget` traced (`CookModeCopy.swift:67-69`, tests `CookModeCopyTests.swift:36-39`); whether the clock page keeps K84's sizes is not ruled | inferred | Design | `clockPageTargetsKeepTheMinimum` |

## 2. G229: finish keys are named-action-only for VoiceOver (FK)

Ruled: the newer ruling wins. A double tap on Done speaks the hint "Hold to finish"; the named action "Finish" completes (K84.26). Product's 9:18 PM PT Oct 17 answer extends it to every key that finishes or clears: cook Done, Finish workout, Groceries Done, Clear the basket, Lists Reset. Keys that start something (Start shopping, timer start, Cook) keep double-tap. It binds VoiceOver's double tap only. VO19 is amended (it wanted a default action that finishes and a hint that does not say hold).

| Id | Input | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| FK01 | VoiceOver double tap on Done (hold key, last step) | the cook does not finish; VoiceOver speaks "Hold to finish" | `PaintKey` always adds `.accessibilityAction { complete() }`, so a double tap completes (`Paint.swift:314`) | gap | Builder A | `doubleTapOnDoneDoesNotFinish` |
| FK02 | Done's hint | "Hold to finish" | string traced (`CookModeCopy.swift:13`, test `CookModeCopyTests.swift:26`); `PaintKey` doc says hints never name the gesture (`Paint.swift:250-253`), so the shared key needs an opt-out | traced (string), gap (wiring) | Builder A | `doneHintIsHoldToFinish` |
| FK03 | Done's custom actions | exactly one named action, "Finish", which completes the cook | string traced (`CookModeCopy.swift:15`); no wiring | traced (string), gap (wiring) | Builder A | `finishNamedActionCompletesTheCook` |
| FK04 | Done's default action | none (named-action-only); VoiceOver lists "Finish" in the actions rotor | `Paint.swift:314` adds a default action | gap | Builder A | `doneHasNoDefaultVoiceOverAction` |
| FK05 | A timer-start key (tap key, `isTap: true`) | double tap starts the timer; no named action needed | tap keys complete on `complete()` (`Paint.swift:307,314`) | inferred | Builder A | `timerStartKeepsDoubleTapStart` |
| FK06 | Other finish or clear keys (Finish workout, Groceries Done, Clear the basket, Lists Reset) | same rule as Done: no VoiceOver default action, hint "Hold to finish" style, one named finishing action. Start keys (Start shopping, timer start, Cook) keep double-tap | Groceries has a named "Start shopping" (`GroceriesView.swift:404`); workout has named "Finish workout" (`WorkoutModeView.swift:678`, `ExerciseStrip.swift:119`) next to a default action | gap | Builder A (workout), Builder B (Groceries, Lists) | `finishAndClearKeysAreNamedActionOnly` |
| FK07 | VO19 as amended | Done: label "Done"; value "4 minutes left" (VO19's value); button; hint "Hold to finish"; action "Finish"; no hint "Finishes the cook" | `voiceover-recipe-clock-lists.md` VO19 still lists the old hint and default action | gap | Design | `vo19MatchesG229` (doc edit, no Swift) |
| FK08 | Voice Control "Tap Done" or Switch Control activation on Done | activates the key's Finish action directly; never a dead control. Only VoiceOver's double tap is named-action-only | none | gap | Builder A | `voiceControlAndSwitchControlFinishDirectly` |
| FK09 | Finish by a real hold, VoiceOver off | completes after the hold; same receipt and Undo as CK08 | hold path exists in `PaintKey` (`Paint.swift:285-312`); no cook caller | inferred | Builder A | `holdFinishStillCompletes` |

## 3. G223: Low Power haptics (LP)

Ruled: in Low Power his own touches and the timer-end alert keep their haptics (Product's answer: the haptic map wins, so "timer-end success" reads as `timeUp`, heavy impact) (a missed timer is worse than a buzz). Tess-initiated landings (the bead lighting a step) follow quiet hours only: no haptic 23:00 to 07:00, while his touches and the timer-end alert always play. That needs a small gate in `Haptics` (not only scheduling dates). The fixture is corrected to match: no "zero haptics". Low Power itself follows Reduce Motion for motion (D5, per the gap hunt); that part is G219 and is not repeated.

| Id | Input | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| LP01 | Low Power on, his touch on a key (tap, hold start, step change) | the haptic plays exactly as with Low Power off | no Low Power read in `Haptics.swift` (whole file), so every haptic plays | traced | Builder A | `lowPowerKeepsHisOwnTouchHaptics` |
| LP02 | Low Power on, a kitchen timer ends with the app on screen | `timeUp` (heavy impact) plays | `Haptic.timeUp` exists, "or a kitchen timer ends" (`Haptics.swift:36-37,64`); only caller is the workout rest (`WorkoutModeView.swift:140`); no kitchen timer caller | traced (haptic), gap (caller) | Builder A | `lowPowerKeepsTimerEndHaptic` |
| LP03 | Low Power on, bead lights a step (Tess-initiated) | haptic only outside 23:00-07:00; with Low Power alone nothing changes | no cook caller; no quiet-hours gate in `Haptics.swift` (quiet hours exist only for dates, `TesseraCore/Sources/TesseraTess/TessGrammar.swift:721,769`); Haptics needs a small gate | gap | Builder A | `beadLandingFollowsQuietHoursOnly` |
| LP04 | Bead lights a step inside quiet hours, Low Power off | no haptic from 23:00 to 07:00; his touches and the timer-end alert still play | none | gap | Builder A | `beadLandingIsSilentInQuietHours` |
| LP05 | Bead lights a step outside quiet hours, Low Power on | haptic plays (Low Power is not a reason to silence it) | none | gap | Builder A | `lowPowerDoesNotSilenceTheBead` |
| LP06 | Reduce Motion on | haptics keep beat for beat (K84.17 to K84.19, per the gap hunt's reading of D5) | no Reduce Motion read in `Haptics.swift` | inferred | Builder A | `reduceMotionKeepsHaptics` |
| LP07 | Low Power on, timer ends with the app in the background | the local notification alert is the signal; not changed by Low Power | no local notification exists on master: no `UNUserNotificationCenter` call in `App`, `Features` or `TesseraCore/Sources` (G217) | gap | Core | `backgroundTimerRingsInLowPower` |
| LP08 | Low Power on, a missed timer (screen off at end) | a notification is delivered; haptic follows the system, nothing app-side to suppress | none | gap | Core | `missedTimerStillNotifies` |
| LP09 | Docs: the haptic fixture | `docs/research/fixtures/haptic-moments.md` is on master; its item 3 states the G223 ruling and #941 corrects it (timer-end reads `timeUp`). Verify that wording after #941 lands | file read on master; item 3 still says "timer-end success" until #941 | inferred | Design | `hapticFixtureMatchesG223` (doc check, no Swift) |
| LP10 | Low Power toggled mid-cook | next haptic and next motion follow the new state with no relaunch | `TessSoul` caches the flag at a mode change only (`TessSoul.swift:109`); no power-state observer | gap | Builder A | `lowPowerChangeAppliesWithoutRelaunch` |
| LP11 | The Core observer for tests (D6: HapticLog) | tests can count cues, including `.done` and the trigger form | `HapticCue.count` covers them poorly (board `core.md:264`) | gap | Core | `hapticLogCountsEveryCue` |

## 4. G218: keep-awake rule (KA)

Ruled: keep-awake is a screen-on rule. The idle timer is off only while the cook page is visible, the scene is active, and (a timer runs or the last step change was under 45 min ago; the 45 min edge is exclusive, so at 45:00 the screen may sleep). It returns on the idle rule, Finish, leaving, backgrounding, and re-arms on any touch on the cook page, for a fresh 45 min. G217 (blocker) stands: a kitchen timer must be able to ring (local notification) before `cookModeReady` flips; boarded on ios-a.

| Id | Input | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| KA01 | Cook page visible, scene active, timer running | `isIdleTimerDisabled` is true | no hit anywhere | gap | Builder A | `idleTimerOffWhileATimerRuns` |
| KA02 | Cook page visible, active, no timer, last step change 44 min ago | true | none | gap | Builder A | `idleTimerOffInsideFortyFiveMinutes` |
| KA03 | Same, last step change exactly 45 min ago | false (the edge is exclusive: at 45:00 the screen may sleep) | none | gap | Builder A | `idleTimerReturnsAtFortyFiveMinutes` |
| KA04 | Same, then any touch on the cook page | re-arms: true again for a fresh 45 min window (a touch restarts the clock; it need not be a step change) | none | gap | Builder A | `touchRearmsKeepAwake` |
| KA05 | Finish pressed | false at once | none | gap | Builder A | `finishReleasesTheIdleTimer` |
| KA06 | Leave the clock page (back word, VO24) while the cook runs | false at once; the cook itself keeps running | none | gap | Builder A | `leavingReleasesTheIdleTimer` |
| KA07 | Scene goes inactive or background | false | none; scene phase is read on the recipe page only for other work (`RecipePage.swift:201`) | gap | Builder A | `backgroundingReleasesTheIdleTimer` |
| KA08 | Scene returns active, timer still running | true again without a touch | none | gap | Builder A | `foregroundWithATimerRearms` |
| KA09 | Timer ends, last step change 50 min ago, page left open | false after the timer ends (no timer, past 45) | none | gap | Builder A | `idleTimerReleasesAfterTheLastTimerEnds` |
| KA10 | Another page of the app is on top of the cook (Settings, Groceries) | false (page not visible) | none | gap | Builder A | `hiddenCookPageDoesNotHoldTheScreenAwake` |
| KA11 | Never two owners | one writer sets the flag; a workout and a cook cannot disagree | the workout does not set it either, so there is no writer today | gap | Builder A | `oneOwnerSetsTheIdleTimer` |
| KA12 | The process idle rule for a cook (G221) | a cook is suspended by `suspendIfIdle` on the same 45 min rule | returns nil for anything but a workout, a shop or a list (`ProcessTable.swift:89-99`); `tidyProcesses` calls it (`App/AppModel.swift:395`) | gap | Core | `suspendIfIdleHandlesACook` |
| KA13 | G217 gate: timer set, then `cookModeReady` | the flag cannot be true unless a local notification is scheduled for each running timer | `StartKitchenTimer` writes an object with `endsAt` only (`TesseraCore/Sources/TesseraCore/Kitchen/Cooking.swift:222-243`, per the gap hunt); no scheduler | gap | Core | `cookModeNeedsARingingTimerFirst` |
| KA14 | Cook page in Low Power, keep-awake on | keep-awake rule unchanged by Low Power (the ruling gives Low Power no part) | none | inferred | Builder A | `lowPowerDoesNotChangeKeepAwake` |

## Counts

45 rows (statuses revised after Product's answers: LP09 moves from gap to inferred). A row with two parts is counted under its first word.

| Status | Rows |
|---|---|
| traced (CK09, FK02, FK03, LP01, LP02; FK02, FK03 and LP02 also carry a wiring or caller gap) | 5 |
| inferred (LP09 added) | 10 |
| gap (including the doc-edit rows CK10, FK07) | 30 |

By group: CK 11, FK 9, LP 11, KA 14. Rows CK10, FK07 and LP09 are doc edits or checks, not Swift.

## Open questions

For Design (Product has not ruled on these):
1. Q7 (CK10, FK07): edit K84.20 and VO19 so only one reading order stands, and mark which K84 rows survive (K84.14, K84.26, K84.22, K84.25, K84.27).
2. Q9 (CK11): do K84's 64 pt and 88 pt targets carry over to the clock page's keys?
3. Q10 (FK02): `PaintKey`'s hint doc forbids naming the gesture; Done's ruled hint is "Hold to finish". Should `PaintKey` get an explicit opt-out for this one key?

Answered by Product (decisions.md lines 1011-1012, 9:18 PM PT Oct 17, defaults, reversible) and folded into the rows above: G229 covers every finish or clear key (old Q1); `timeUp` plays in Low Power (old Q2); haptic quiet hours, with a gate in Haptics (old Q3); the 45 min edge is exclusive (old Q4); any touch re-arms 45 min (old Q5); named-action-only is VoiceOver double tap only (old Q6). Old Q8 is closed by the LP09 check.
