# v1 gap audit

Research lab, 2026-10-15.

- **Master audited:** `285b34ab6abc1ad4786e7b78dc9b5b6e4e92e704` (merge of #87, committed 2026-10-15 11:58 PT). Nothing on master changes app code after #84 (data safety).
- **Method:** fetched `origin/master` and read it with `git log`, `git ls-tree`, `git show` and `git grep`. Each slice in `../product/ship-list.md` was checked against the app code (`App/`, `Features/`, `Widgets/`, `Shared/`), the engine (`TesseraCore/`) and tests, plus the QA notes in `docs/qa/`. A slice counts as "on master" only when it reaches a screen, not just the engine.
- **Limits:** I read the code but could not build or run the app, the simulator or the phone. Feel, motion and timing are not judged here.

**Counts:** 15 on master, 3 partly, 1 missing.

## Slices

| # | Slice | Status | Evidence | What's missing |
|---|---|---|---|---|
| 1 | Seed his real plan | on master | `TesseraCore/.../Catalog/StarterContent.swift`, `StarterContentTests.swift`; #23, #46 (`aa65c1f`, `089a8a1`) | Nothing. `-resetDemo` kit bug K12 was fixed in #70. |
| 2 | Prefilled one-hold logging | on master | `Training/Prefill.swift`, `Features/Workout/WorkoutSession.swift` `loadDefaults`, `PrefillTests.swift`; #24, #46, #47, #48, #70 | G1 still open: Home says "Bench Press is ready for 20 today" for the empty bar (`Features/Home/TrainingPage.swift:116-120`). |
| 3 | Dial and drum work for real | on master | `Training/Dial.swift`, `Features/Workout/Instruments/WeightDial.swift`, `RepsDrum.swift`, `PlateStack.swift`, `DialTests.swift`; #26, #46 | Dial feel needs a hand check. |
| 4 | Finish and see it saved | on master | `Training/WorkoutSummary.swift`, `Features/Workout/WorkoutFinishView.swift`, `TrainingPage.swift` `DoneTraining`; #27, #46 (`9ab1b22`) | Nothing found in code. |
| 5 | Now drains as a bar | on master | `Features/Home/NowPage.swift` `DrainBar` (line 184); #46 (`464475e`) | Nothing. |
| 6 | Exercise page v0 | on master | `Training/ExerciseOverview.swift`, `Features/Exercise/ExercisePage.swift`, `ExerciseDigest.swift`; #31, #46 | Nothing. |
| 7 | PR hint and moment | on master | `Training/RecordHint.swift`, `WorkoutSession.swift:311` `recordHint`, `WorkoutParts.swift:124`, celebration in `WorkoutModeView.swift:136-140`; #28, #46 | Celebration is a glint, haptic and Tess motif; check it reads as "the moment". |
| 8 | Edit and undo any set | partly | Undo: long-press the last stroke (`LiveSetStrokes.swift:36`), `WorkoutModeView.swift:88`, Bar "Undo" (`AppModel.swift:216`). Edit: `EditSet` exists in `Actions/TrainingActions.swift:87`; #8, #84 | No UI calls `EditSet`: a logged set can't be tapped and changed. Undo covers only the last set. |
| 9 | Swap exercise in a session | on master | `Training/Swaps.swift`, `Features/Workout/SwapPanel.swift`, `ExerciseSwaps.swift`, pull down on the name in `WorkoutParts.swift:74-86`; #31, #33 | Nothing. |
| 10 | Routine editing | partly | Engine: `Actions/RoutineEditing.swift` (`MoveSlot`, `EditSlot`, `SwapSlotExercise`), `AddSlot` in `PlanActions.swift`, `RoutineEditingTests.swift`; #29. App: only "add to routine" from `ExercisePage.swift:242` | No routine editor screen, and no remove-slot action in the engine. Reorder in live mode is today only (`ExerciseStrip.swift:66`). |
| 11 | Week view | on master | `Training/WeekView.swift`, `PlanSchedule.swift`, `Features/Plans/WeekPage.swift` `DaysAcross`, `ledger.nextRoutine` in `PlanData.swift:19`; #30 | Nothing. |
| 12 | Quick Capture "log bench 80x8" | on master | `TesseraTess/TessGrammar.swift`, ghost rows and `captureDryTime = 2` in `App/AppModel.swift:125-218`, `Features/Command/BottomChrome.swift`, `CountsAndCaptureTests.swift:18`; #16, #32, #70, #84 | Nothing. Multi-set undo fixed in #84 (B3). |
| 13 | Polish pass on live mode | on master | Seat and stroke paint-in (`LiveSetStrokes.swift`), rest on the dial (`WeightDial.swift:19-30`), PR glint (`WorkoutModeView.swift:399`), haptics (`:142-144`, `:419`), Reduce Motion via `MotionPolicy` throughout; #11, #25, #46 | No dedicated polish PR. This is the premium moment and only a phone session can sign it off. |
| 14 | Double progression | partly | `Training/Progression.swift` `nextTarget` (+2.5 BB, +2 DB defaults), used by `StartRoutine` (`PlanActions.swift:127`) and the exercise page (`ExerciseDigest.swift:118`); `WorkoutsModelTests.swift:117`; #10 | Live mode ignores it: `Prefill.swift:41-43` returns last time's weight before the raised `targetWeight`, so set 1 opens at last week's load. |
| 15 | Weekly sets per muscle | on master | `Features/Plans/WeekPage.swift` `MuscleWindow`, `PlanData.muscleSets`, `Catalog/MuscleLibrary.swift`; #25, #30 | Nothing. |
| 16 | Month heatmap and counts | on master | `PlanSchedule.swift:67` `monthCounts`, `Features/Plans/MonthPage.swift` (tap a day, `:103-105`); #32 | Nothing. |
| 17 | Voice in the gym | missing | Grammar handles "same", "8", "80 x 8" (`TessGrammar.swift:11`, `:84`), but no Speech framework or mic usage string anywhere; the Bar's `mic` glyph (`BottomChrome.swift:94`) is decorative | Hold the Bar to talk: speech capture into the existing grammar. |
| 18 | Rep maxes table, e1RM trend | on master | `TrainingLedger.swift:165` `trend(days: 90)`, `ExerciseViews.swift:77` `RepMaxGrid`, 90-day stroke in `ExercisePaint.swift:29`; #25, #31 | Nothing. |
| 19 | HealthKit write | on master | `App/Health/HealthExporter.swift`, wired in `App/TesseraApp.swift:38`, `App/Tessera.entitlements`, usage strings in `project.yml:60-61`; #34 | Untested on device (see below). |

## Biggest gaps for the huddle

1. **Progression doesn't reach the dial (slice 14).** He'll hit 4 × 8 on bench and next session still opens at the same weight. One-line order change in `Prefill.swift` (prefer a raised target over last time), plus a test.
2. **No way to fix a mistyped set (slice 8).** Undo only takes back the last set. The engine action is there; it needs a tap-to-edit on logged strokes.
3. **Voice is missing (slice 17)**, and the Bar shows a mic that does nothing. Either wire speech or hide the glyph before he taps it.
4. **No routine editor (slice 10).** He can't drop or reorder an exercise in his plan, only for today. Needs a remove-slot action and a plain editor.
5. **Home still says "ready for 20" on a fresh start (G1).** First impression on the phone; `TrainingPage.swift:116-120` should use the same first-time test as `Prefill.swift`.

## Done but unverified on device

- **Rest Live Activity** (`Widgets/RestLiveActivity.swift`, `Shared/RestIntents.swift`, `RestActivityController.swift`): draining countdown on the Lock Screen and Dynamic Island, +15s, Skip, and Done (`LogPlannedSetIntent`) logging a set without opening the app, including after a relaunch (#33). Run `docs/qa/gym-flow.md` section E.
- **HealthKit write (#34):** permission prompt, one workout per finish, no duplicates after a relaunch, empty workouts skipped.
- **Signing under free provisioning:** master now carries `App/Tessera.entitlements` with `com.apple.developer.healthkit`, while CLAUDE.md still says "No entitlements yet". Check the personal team (`DEVELOPMENT_TEAM: WMP2WF3P54`) can sign the app with HealthKit plus the `TesseraWidgets` extension. If it can't, drop the entitlement for this install rather than block the review. Free profiles also expire after 7 days.
- **Siri, Shortcuts and Spotlight** (`TesseraIntents`, `AppIntentsPackageLink.swift`): App Intents need no entitlement but only show up on a real install.
- **Haptics, dial feel and the finish animation (slices 3, 7, 13):** the simulator has no haptics.
- **On-device Tess model path** (`TessModelCapture.swift`): needs Apple Intelligence on the phone; the grammar fallback is what the simulator exercises.
- **Kill and resume mid-workout** (`App/WorkoutResume.swift`): gym-flow section D, worth one try on the phone.
