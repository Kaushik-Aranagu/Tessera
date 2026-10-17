# Haptic moments fixture (one haptic per finish, capture landing)

Covers discovery gaps 1, 2, 3 and 8 (ops/discovery-gaps.md). Sources: design/task-reward.md ("Made", "Done", "The haptics map", "Changes to what's built") and Tessera master a8c3e6e (line numbers are from that commit; re-run the greps in section 3 before fixing). Owners: Builder B (Home, capture, Groceries), Builder A (workout), Core or DesignSystem for the pattern API, QA for HouseRulesTests.

Vocabulary: arm = `.selection` when a swipe reaches 140 pt; release = the finish moment; made = `Haptic.made`; done = `Haptic.done` (three-beat pattern, `.success` fallback). Counts are cues per single user action, over the whole second after it.

## 1. Moments table

| # | Moment | Fires today (file:line) | Map says (task-reward.md) | Must fire |
|---|---|---|---|---|
| 1 | Task finish by swipe on a Home row | Arm: raw `.selection` on `armed`, HomeQueue.swift:266. Release: raw `.impact(medium 0.8)` on `finishes`, HomeQueue.swift:280 (bumped in `finish()`, :433). Then TessSoul raw `.success` on `doneCount`, TessSoul.swift:129 (`playDone`, SoulRouter.swift:287). Two haptics at release. | arm `.selection`; release done pattern; fleck reaches now `.fleckReachesNow` (soft 0.4, only when the fleck is built); TessSoul plays none | `.selection` x1 at arm, then `.done` x1 at release. Soul adds 0. Fleck cue 0 until the fleck exists, then 1. |
| 2 | Task finish by the hero key (NowPage) | Raw `.impact(medium 0.8)` on `finishes`, NowPage.swift:118 (bumped at :313). Plus TessSoul `.success` (TessSoul.swift:129) when the soul goes Done. No arm. | "Done from anywhere else gets the same pattern: the hero's finish" | `.done` x1. No arm cue (a key press, not a swipe). Soul 0. |
| 3 | Task finish by VoiceOver Done (Home row) | `.accessibilityAction(named: "Done")` calls `finish()`, HomeQueue.swift:285, so release impact :280 plus soul `.success`. No arm (correct). | same as a release, no arm | `.done` x1, `.selection` x0. |
| 4 | Task finish by VoiceOver Done on the hero | Hero has no named Done action in master (grep of NowPage.swift finds none); the key's own activation reaches `finish(_:)`, NowPage.swift:312. | same as 2 | `.done` x1 through the key's accessibility activation. If a named action is added, same count. |
| 5 | Task finish said or typed ("call the bank done") | Capture commit, BottomChrome.swift:501-530, `soul.handle(.committed)` then `.success` on `isBright`, BottomChrome.swift:131. | Done pattern from anywhere; rule 3: one source per moment | `.done` x1 (not `.made`, not `.success`). Row on screen or not does not change the count. |
| 6 | Workout finish (LOG AND FINISH hold, FINISH key, ExerciseStrip "Finish workout") | `finish()` plays `moment.play(best ? .newBest : .done)`, WorkoutModeView.swift:704; seat-path guard at :199 and comment :198 keep the seated set from also playing. Engine warm at :172. Correct today. | done pattern; new best `.success` in place of the set's tap, never both | `.done` x1; or `.newBest` x1 when the finishing set was a best (then `.done` x0, `.setLogged` x0). |
| 7 | Shop finish (Groceries) | Not built. `toggleShop`, GroceriesView.swift:265-274, only starts or suspends (`StartShop`, `SuspendProcess`); plays nothing. `Haptic.done` doc names "the shop finished" (Haptics.swift:7). | done pattern | `.done` x1 when a shop finishes (gap 13). Start and suspend: 0. |
| 8 | Capture landing, task (typed) | Raw `.success` on `soul.isBright`, BottomChrome.swift:131. `Haptic.made` is played only at TrainingPage.swift:156 (and RoutinesPage via cue). | `.made` x1 at the landing (t=420) | `.made` x1; `.success` x0; no other cue. |
| 9 | Capture landing, note (typed) | Same path and same `.success`, BottomChrome.swift:131. | made | `.made` x1. |
| 10 | Capture landing, grocery (typed) | Same `.success`, BottomChrome.swift:131. Groceries' own landed tap is a different action (row check), GroceriesView.swift:190. | made ("Groceries landed") | `.made` x1; Groceries view open or not does not add a second. |
| 11 | Capture landing, task, note, grocery (spoken) | `speak(hold:)` BottomChrome.swift:582, `finishListening` :619, dry 3.0 s, then `commit(clean)` :658 and the same `.success`. | made, 3 s ghost then landing | `.made` x1 per landing. The Reduce Motion 0.8 s dry (:652) does not change the count. |
| 12 | Capture of several items ("Two tasks added") | One commit, one `.success`. | one made for the last landing | `.made` x1 for the whole phrase. |
| 13 | Plan kept | Not checked in this fixture; map: made, once for the plan. | made x1 | `.made` x1, rows' stagger adds 0. |
| 14 | Listening start (Speak tap or hold) | None. `Haptic.listening` is defined (Haptics.swift:13 area, `.listening` case) and never played; `speak(hold:)` BottomChrome.swift:582-588 and `listener.start` :598 play nothing; SpeechListener.swift has no haptic. Tess-opens `.selection` is raw, BottomChrome.swift:130 (`opens`, :245). | `.listening` (soft 0.5) when listening starts | `.listening` x1 when `start` returns nil (it listens). A refusal (:598-608) fires 0. Tess opens `.selection` x1 on the surface opening, not on the hold path that opens no surface. |
| 15 | Set logged | `moment.play(seated.records.isEmpty ? .setLogged : .newBest)`, WorkoutModeView.swift:202; edit sheet `.setLogged` on `saveHaptic`, :207 (bumped :619). | `.setLogged` rigid; new best `.success` in place, never both | one of `.setLogged` or `.newBest`, x1. |
| 16 | Undo, capture/Tess | Raw `.decrease` on `undos`, BottomChrome.swift:132 (bumped :744). | `.decrease` | `.undo` x1. |
| 17 | Undo, workout set | `.undo` on `undoHaptic`, WorkoutModeView.swift:205 (bumped :118, :264). | `.undo` | `.undo` x1. |
| 18 | Undo, routines | `haptic.play(.undo)`, RoutinesPage.swift:275. | `.undo` | `.undo` x1. |
| 19 | Undo of a finished task | No haptic path found in HomeQueue.swift or NowPage.swift. The Tess line's UNDO reaches the BottomChrome undo (row 16). | `.decrease` | `.undo` x1 total, from one source. |

Not now (swipe left): raw `.impact(light)` on `moves`, HomeQueue.swift:281; must be `.notNow` x1, arm `.selection` x1. Pick-up: raw `.impact(light 0.5)` on `holding`, HomeQueue.swift:267; must be `.pickedUp` x1.

## 2. Cases that must fire nothing

1. Reduce Motion on: haptics still fire beat for beat (task-reward.md "Reduce Motion"). Test asserts the same cue list with and without it.
2. System Haptics off (iOS Settings): zero. `.sensoryFeedback` honors it; the Core Haptics `DonePattern.play()` path (Haptics.swift) checks only `supportsHaptics`, so the harness must verify the pattern also stays silent. Propose the gate below.
3. Low Power Mode: zero haptics, per the request. Nothing in Haptics.swift gates on it today (TessSoul.swift:95 reads `isLowPowerModeEnabled` for visuals only). Needs a Core/DesignSystem decision; the fixture encodes it as the target.
4. Quiet hours (23:00 to 07:00): only haptics under his finger and his own timers. Zero for Tess-initiated landings, answers and `.timeUp` from a Tess line.
5. A failed save (the `perform` helper from gap 5): zero cues, no reward animation, one plain line. `fixtures/perform-failures.md` does not exist yet; when Research adds it, link each of its call-site families (task finish NowPage.swift:314, HomeQueue op, grocery check GroceriesView.swift:233, set log WorkoutSession, routine edit RoutineEditor.swift:201) to a zero-cue case here.
6. A walled private capture (SecretWords, PrivateFacts at TessCaptureEngine.swift:59-60 and the other wall sites in discovery-gaps.md): still plays its one `.made` at the landing, and says no word (no echo of the phrase, no line in Tess's voice). The cue count is 1, the spoken-line count is 0.
7. A refused listen (SpeechListener refusal, BottomChrome.swift:598-608), "Didn't catch that.", `heardNothing`, "Nothing to undo.": zero.
8. A miss, an empty commit, a key-shaped phrase (`refuseKey`, BottomChrome.swift:463): zero.
9. Scroll, page appear, Day log lines landing, Tess speaking by herself, a bound while a finger keeps pushing: zero (map "Never").
10. No `.error` or `.warning` feedback anywhere.
11. Doubled gesture: a second finish call on a task already finished, or VoiceOver Done after a swipe on the same row: zero extra.

## 3. Static rules for HouseRulesTests (raw call sites to retire)

Rule: no `.sensoryFeedback(` in Features, App or DesignSystem except inside DesignSystem/Haptics.swift (`TesseraFeedbackModifier`). Fresh grep on master a8c3e6e (`git grep -n 'sensoryFeedback(' -- Features App DesignSystem`), 31 sites in 18 files. Gap 3 said about 25; the list below is current.

- DesignSystem/InkActions.swift:78
- DesignSystem/LookSentence.swift:69, :70 (the :70 pin is `.pinned`)
- DesignSystem/Paint.swift:306, :307, :308 (every PaintKey)
- Features/Backup/BackupView.swift:103
- Features/Command/BottomChrome.swift:130, :131 (`.success`, becomes `.made`), :132 (`.undo`)
- Features/Command/CaptureParts.swift:141
- Features/Exercise/CarriageRail.swift:47
- Features/Exercise/ExercisePage.swift:210 (`.success`, `added`; decide made)
- Features/Groceries/GroceriesView.swift:190, :344, :517 (`.aisleCleared`)
- Features/Home/HomeQueue.swift:266 (arm), :267 (`.pickedUp`), :280 (becomes `.done`), :281 (`.notNow`)
- Features/Home/NowPage.swift:118 (becomes `.done`)
- Features/Home/ReviewPage.swift:312
- Features/Plans/RoutineEditor.swift:93
- Features/Recipes/PasteRecipe.swift:137 (`.success`, becomes `.made`)
- Features/Recipes/PortionDrum.swift:45
- Features/Recipes/RecipePage.swift:142 (`.success`, sent)
- Features/Tess/TessSoul.swift:129 (delete: soul plays none)

Also required: TessSoul.swift has no `.success`; BottomChrome.swift has no `.success`; the only `DonePattern.play()` caller is the modifier in Haptics.swift (one source per moment); `Haptic.fleckReachesNow` has a caller or an item that drops it.

## 4. Swift Testing names and the cue seam

Seam today: partial. `HapticCue` (Haptics.swift) is a value type with `haptic` and `count`, bumped by `play(_:)`, and views hold it in `@State` (RoutinesPage.swift:21, RepsRow.swift:29, WeightReel.swift:34, WorkoutModeView.swift:56). A test can read `count` only for a cue it owns. There is no seam for the trigger-based form (`tesseraFeedback(.made, trigger:)`), whose `system` cue is `private @State` inside `TesseraFeedbackModifier`, and `.done` goes straight to the static `DonePattern.play()` with no counter. So a view-level "one `.done` per finish" cannot be counted today.

Smallest seam (DesignSystem, about 15 lines): a main-actor `HapticLog` in Haptics.swift with `static var observer: ((Haptic) -> Void)?`, called once in `TesseraFeedbackModifier.onChange` before the `.done` branch, and by `HapticCue` consumers through the same modifier. Tests install a recorder, drive the view model or view (UI-less where the finish logic is a function, e.g. `finish()` extracted to the model), and assert the recorded list. The same function can hold the policy gate (System Haptics, Low Power, quiet hours) so section 2 is testable with an injected `HapticPolicy`. Row 14 and the soul rule need the soul to stop owning a haptic, so `TessSoul` gets no modifier at all.

Names:
- `taskFinishBySwipePlaysSelectionThenOneDone`
- `taskFinishByHeroKeyPlaysExactlyOneDone`
- `taskFinishByVoiceOverDonePlaysOneDoneAndNoSelection`
- `taskFinishNeverPlaysSoulSuccess`
- `taskFinishSaidOrTypedPlaysOneDoneNotMade`
- `workoutFinishPlaysOneDoneOrOneNewBestNeverBoth`
- `shopFinishPlaysOneDoneAndStartPlaysNone`
- `captureLandingPlaysOneMadeForTaskNoteGroceryTyped`
- `captureLandingPlaysOneMadeForSpokenPhrase`
- `captureOfTwoTasksPlaysOneMade`
- `walledPrivateCapturePlaysOneMadeAndSaysNothing`
- `listeningStartPlaysListeningOnceAndRefusalPlaysNone`
- `setLoggedPlaysOneTapAndNewBestReplacesIt`
- `undoPlaysOneDecreaseFromEachSurface`
- `reduceMotionKeepsEveryHaptic`
- `lowPowerAndSystemHapticsOffPlayNothing`
- `quietHoursSilenceTessInitiatedHaptics`
- `failedSaveFiresNoHapticAndNoRewardLine`
- `houseRulesNoRawSensoryFeedbackOutsideHaptics`
- `houseRulesOnlyModifierCallsDonePattern`
