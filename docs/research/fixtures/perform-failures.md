# Fixtures: a failed `perform` says so (discovery gap 5, task BZ)

Read against origin/master. Principle from the discovery item: Tess's line and the data never disagree. Every row below is a Swift Testing case with made-up values. No Claude calls are involved.

## The one expected result (every failure row)

- Exactly one plain line through `TessVoice.shared.say` (HomeQueue.swift:32), no Undo button (`undo: nil`): **"Didn't save. Try again."** It lives in tess-voice.md:67 as "Didn't save that. Tap to retry."; flag for Product: a thing-first variant when the subject is known ("Pay rent didn't save. Try again.", "Bench 80 x 8 didn't save. Try again.") reads better and matches decisions.md:43 (receipts stay thing-first). The helper should take an optional `subject:` and fall back to the bare line. Straight apostrophes only.
- No reward animation (no strike, no fleck, no sink-to-basket, no `model.touch()` reward spring), no counter bump (`finishes`, `moves`, `landed`, `haptic`, `ticks`), data unchanged (`store` objects and `engine.history()` equal before and after).
- No haptic at all. The map says "Nothing scolds: there is no error or warning case" (Haptics.swift:6), so a failure plays nothing; the case that must NOT fire is named per family.
- Undo failure: `ActionEngine.undo` does not throw, it returns `ReplayOutcome` (ActionEngine.swift:17-22: `.applied`, `.partial`, `.nothingToDo`). A failed undo is `.nothingToDo` or `.partial` while the store write threw. Proposed line for Product to rule on: **"Didn't undo. Try again."**, with the original change left in place and `Haptic.undo` (Haptics.swift:21) silent.

## How a test injects the throw

`ActionEngine` is a `final class` (ActionEngine.swift:11) and `AppModel.engine` is the concrete type (AppModel.swift:183), so a fake engine needs a seam first. Two injection routes, both from existing patterns:

1. **Stale target, no seam needed.** Build the real in-memory stack the way TesseraTests does (`TesseraSchema.makeContainer(inMemory: true)` then `AppModel(context:)`, AppModelTests.swift:8,11; WorkoutSessionTests.swift:8-14, `DemoData.prepare(model)` at :18), delete the target with `DeleteObject`, then drive the call site. `perform` throws `ActionError.wrongClass` or `invalidArguments`, the pattern in `invalidActionsWriteNothing` (TesseraCore/Tests/TesseraCoreTests/ActionEngineTests.swift:122-139).
2. **Throwing action or performer.** An inline `EngineAction` whose `apply` throws, as `Halfway` does (ActionEngineTests.swift:145-163, which also proves the rollback: `store.objects(of:)` empty and `engine.history()` empty). For call sites, Core adds a `performer` seam (protocol `ActionPerforming` with `perform` and `undo`, default the real engine) and ships `ThrowingPerformer` in test support; `AppModel` keeps `engine` as the default performer.

The `@State` counters (`finishes`, `moves`, `landed`, `haptic`) live in views and cannot be read from a unit test. Rule for the call sites: move the "perform, then reward or fail" decision into a model method that returns `Bool`/the new helper's result (AppModel already has `finish(taskID:)`, AppModel.swift:548), and have the view bump its counter only on success. The unit test asserts the result; a UI test row (TesseraUITests, e.g. HomeQueueUITests.swift) asserts no haptic trigger and the line on screen.

## Owners

| Part | Owner |
|---|---|
| `perform` helper returning a result plus the failure line, `ActionPerforming` seam, `ThrowingPerformer` | Core |
| Home row, hero, AppModel finish, Review, Week, Plans, Workout, Exercise call sites | Builder A |
| Groceries, Recipes, Notes, capture call sites | Builder B |
| Fault-injection tests (the cases below) | QA, with the owner of each area |

## Call-site counts (grep of `try? ...perform` in Features and App at origin/master: 52, matching the discovery item)

| Family | Sites | Count |
|---|---|---|
| Task finish | AppModel.swift:549; NowPage.swift:314; HomeQueue.swift:451; ReviewView.swift:331 (demo walk) | 4 |
| Grocery list and shop | GroceriesView.swift:203, 233, 247, 256, 268, 270, 278, 749, 750, 753 | 10 |
| Set log and workout edit | WorkoutSession.swift:368, 371, 558, 619, 621; WorkoutSession+Edit.swift:38, 52 | 7 |
| Routine edit | RoutineEditor.swift:201, 508; RoutinesPage.swift:144, 145, 183, 215, 236; ExercisePage.swift:241; WeekPage.swift:70 | 9 |
| Workout start and finish (AppModel) | AppModel.swift:558, 568, 649 | 3 |
| Task move (Not now, plan) | HomeQueue.swift:471; HomePlan.swift:149, 177 | 3 |
| Notes and capture | NotesView.swift:40, 121; NoteEditor.swift:171, 180; CaptureParts.swift:194 | 5 |
| Recipes | RecipePage.swift:158, 184; PasteRecipe.swift:200 | 3 |
| Processes, AppModel plumbing, demo | AppModel.swift:210, 353, 380; DemoData.swift:126, 130, 136; ReviewView.swift:333, 334 | 8 |
| **Total** | | **52** |

The last row is system or demo work with no visible reward; it is listed so the count reconciles and is not a fixture family. CaptureParts.swift:194-202 already shows a failure line ("Couldn't save that."): it is the model to copy and is the one string that decisions.md:43 says must get a straight apostrophe.

## Family 1: task finish (Home row and hero key)

Swallowed results: Home row `try? ... .record` at HomeQueue.swift:451 (then `model.touch()` spring and `voice.say("\(entry.title), done.", undo: record)` at :453-456, after `finishes += 1` at :433); hero NowPage.swift:314 (`finishes += 1` at :313 runs BEFORE the write; "Done. Next one is up." at :320); hero key and Lock Screen path `AppModel.finish(taskID:)` AppModel.swift:549 (`touch()` regardless). Reward haptic today: raw `.sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: finishes)` at NowPage.swift:118 and HomeQueue.swift:280 (item 3 moves it to `Haptic.done`). Must NOT fire: `Haptic.done` (Haptics.swift:11, the three-beat finish) and `Haptic.fleckReachesNow`.

Injection: stale task (delete it, then finish) or `ThrowingPerformer`; HomeDataTests.swift:176 already calls `model.finish(taskID: current.id)` on a demo model, so reuse its setup. Spy on the voice with `TessVoice.shared.note` (HomeQueue.swift:29).

| Row | Setup | Expected | Test name | Owner |
|---|---|---|---|---|
| 1a throw on first write | Task "Pay rent" open; performer throws on `SetTaskDone` | One line "Pay rent didn't save. Try again." (bare fallback "Didn't save. Try again."), no Undo; `isDone` still false; `engine.history()` unchanged; `finishes` not bumped; no strike, no fleck, no `Haptic.done`; row stays in the queue and the hero stays the hero | `finishFailureShowsOneLineAndKeepsTaskOpen` (HomeQueue), `heroFinishFailureKeepsHeroAndSaysSo` (NowPage), `keyFinishFailureSaysSoAndDoesNotTouch` (`AppModel.finish`) | Core (helper), Builder A (3 sites) |
| 1b throw on undo | Finish succeeds, then Undo with a performer whose `undo` yields `.nothingToDo` and the store write throws | Line "Didn't undo. Try again."; task stays done; the "done" line is not replaced by a false "Taken back"; `Haptic.undo` silent | `undoFinishFailureLeavesTaskDoneAndSaysSo` | Core, Builder A |
| 1c success unchanged | Normal finish | "Pay rent, done." with Undo, or "Done. Next one is up." when `currentTask(around:)` is non-nil; `finishes` +1 once; `Haptic.done` once; `isDone` true; exactly one `SetTaskDone` op | `finishSuccessIsUnchanged` | Builder A |

## Family 2: grocery check and uncheck

Swallowed results: check `_ = try? ...CheckListItem(item:time:)` at GroceriesView.swift:233 inside `withTesseraAnimation`, followed by `striking.remove`, the sink-to-basket (:215-221 animation) and the breathe at :237-241, all unconditional; uncheck GroceriesView.swift:247 (`_ = try?` then `model.touch()`). Other rewards: raw `.sensoryFeedback(.impact(weight: .light), trigger: landed)` at :190 and the basket line. Must NOT fire: `Haptic.aisleCleared` (Haptics.swift:39) and `Haptic.made` (Haptics.swift:9); on a failed shop finish (:278) also `Haptic.done`.

Injection: delete the list item (`DeleteObject`) before the tap, or `ThrowingPerformer`; list setup from TesseraCore/Tests/TesseraCoreTests/GroceryTests.swift and ListTests.swift (same `makeContainer(inMemory: true)` stack).

| Row | Setup | Expected | Test name | Owner |
|---|---|---|---|---|
| 2a throw on first write | Item "oat milk" open; performer throws on `CheckListItem` | Line "Oat milk didn't save. Try again."; item still open (`done` false), not struck, no sink animation, no breathe; `sinking` empty; no `Haptic.aisleCleared`; basket count unchanged | `checkFailureKeepsItemOpenAndSaysSo` | Core, Builder B |
| 2b throw on undo (uncheck) | Item checked; uncheck with `done: false` throws | Line "Didn't undo. Try again."; item stays in the basket; no `model.touch()` re-layout animation; `Haptic.undo` silent. Same for the toast Undo at GroceriesView.swift:642 (`_ = model.engine.undo(record)`) | `uncheckFailureKeepsItemChecked`, `groceryUndoFailureKeepsLine` | Core, Builder B |
| 2c success unchanged | Normal check, then uncheck | Strike, sink, breathe play once; item moves to basket and back; ops `CheckListItem` x2; reduce motion path unchanged | `checkAndUncheckSuccessIsUnchanged` | Builder B |

## Family 3: set log (LogSet and LogNextSet), the worst case

Swallowed result: WorkoutSession.swift:368 (`LogNextSet`, one hold on an untouched prefill) and :371 (`LogSet`); `guard let result = performed else { return }` at :376 drops the failure silently: no line, no feedback. A lost set in the gym is the worst case, so this family adds the rule: **the typed set stays in the field** (`weight`, `reps`, `rpe` keep their values, the dial does not turn into the rest countdown, and the next hold tries again). Also not on failure: `loggedCount`, `undoable`, `lastSeated`, `restTotal`, `bests`. Must NOT fire: `Haptic.setLogged` (Haptics.swift:25), `Haptic.newBest` (:27), `Haptic.repsMeetLast`, `Haptic.repsBeatLast`. The same family covers the edit/delete at WorkoutSession+Edit.swift:38 and :52 and `engine.undo(undoable.record)` at WorkoutSession.swift:456.

Injection: WorkoutSessionTests.swift pattern (`startedSession()` at :16-21, `model.session`, `session.logSet()`), with a stale entry (delete `currentEntry` first) or `ThrowingPerformer`. Existing cousins: SetLoggerTests.swift, SetLossTests.swift and SiriParityTests.swift in TesseraCore/Tests for the Core side of `LogNextSet`.

| Row | Setup | Expected | Test name | Owner |
|---|---|---|---|---|
| 3a throw on first write | Bench Press, dial at 80 x 8; hold to log with `LogSet` throwing (and again with `LogNextSet` via `isAtPrefill`) | Line "Bench 80 x 8 didn't save. Try again." (bare fallback "Didn't save. Try again."); `session.weight == 80`, `session.reps == 8`, rpe unchanged; no set object created (`setRows(of:)` count unchanged); `loggedCount`, `undoable`, `lastSeated`, `restTotal` unchanged; no rest countdown; no `Haptic.setLogged`/`.newBest` | `logSetFailureKeepsTypedSetInField`, `logNextSetFailureKeepsPrefilledSet` | Core (helper), Builder A (WorkoutSession) |
| 3b throw on undo | Set logged, then `undoLastSet()` (WorkoutSession.swift:453) with undo failing | Line "Didn't undo. Try again."; the set row stays and `undoable` stays so Undo can be tried again; dial not rewound; `Haptic.undo` silent (WorkoutModeView.swift:205 `undoHaptic` not bumped) | `undoLastSetFailureKeepsSetAndUndo` | Core, Builder A |
| 3c success unchanged | Normal log of 80 x 8, a new best case, and a `LogNextSet` hold | One set, `Haptic.setLogged` (or `.newBest` in its place), rest countdown starts, receipt "Bench 80 x 8, logged." with Undo, `loggedCount` +1 | `logSetSuccessIsUnchanged`, `logNextSetSuccessIsUnchanged` | Builder A |

## Family 4: routine edit

Swallowed results: `run(_:)` returns nil at RoutineEditor.swift:201 (`try? model.engine.perform(action, by: .user).record`); the guard at :190 returns, so that path is already quiet but shows nothing (no line). The other sites show their own success line regardless: RoutineEditor.swift:508, RoutinesPage.swift:144-145 (create then add to plan), :183 (schedule mode), :215 (move), :236 (drop), ExercisePage.swift:241 (add to a routine), WeekPage.swift:70. Reward today: `haptic += 1` (RoutineEditor.swift:191) driving `.sensoryFeedback(.selection, trigger: haptic)` at :93, and the `Receipt.routineEdit` line. Must NOT fire: `Haptic.selection` (Haptics.swift:15) via `haptic`/`ticks`, and `Haptic.made` for a created routine; `Haptic.pinned` is unrelated.

Injection: RoutineEditingTests.swift (Core) for the action side; app side from ExerciseAndPlansTests.swift (TesseraTests) with a deleted routine or slot, or `ThrowingPerformer`. Note RoutinesPage.swift:144-145 is a two-step create then add: if the second throws, the first must be undone or the line must say so (one plain line, no half-state shown as done).

| Row | Setup | Expected | Test name | Owner |
|---|---|---|---|---|
| 4a throw on first write | Routine "Push A", add slot "Overhead Press"; `AddSlot` throws | One line "Didn't save. Try again." (the edit has no single thing to name; keep bare); slot count unchanged; `last` and `line` not set to the receipt; `haptic` not bumped; no snappy animation; for RoutinesPage:144-145 no orphan "Pull B" routine remains | `routineEditFailureKeepsRoutineAndSaysSo`, `createThenAddFailureLeavesNoOrphan` | Core, Builder A (Plans, Exercise, Week) |
| 4b throw on undo | Edit succeeds, then `undo()` (RoutineEditor.swift:216) fails | Line "Didn't undo. Try again."; `last` kept so Undo is still offered; the slot stays; `Receipt.takenBack` is not shown; `haptic` not bumped | `routineUndoFailureKeepsEditAndSaysSo` | Core, Builder A |
| 4c success unchanged | Normal add, swap, remove | Receipt line from `Receipt.routineEdit` (ReceiptsTests.swift), `haptic` +1 once, `last` set, `model.touch()` once | `routineEditSuccessIsUnchanged` | Builder A |

## Other families with a visible reward (same 3 rows each, shorter)

| Family | Swallowed result | Must NOT fire | 1a throw on first write | 1b throw on undo | 1c success unchanged | Owner |
|---|---|---|---|---|---|---|
| 5 Workout finish | AppModel.swift:568 (`endWorkout` dismisses the session regardless), WorkoutSession.swift:619, 621 | `Haptic.done` | `finishWorkoutFailureKeepsSessionOpen`: session stays presented, "Didn't save. Try again." | `finishWorkoutUndoFailureKeepsFinish` (WorkoutSession.swift:439) | `finishWorkoutSuccessIsUnchanged` | Core, Builder A |
| 6 Task move (Not now, plan) | HomeQueue.swift:471, HomePlan.swift:149, 177 | `Haptic.notNow` (Haptics.swift:19), `Haptic.pickedUp` | `moveFailureKeepsRowAndSaysSo`: `moves` not bumped, row slides back | `moveUndoFailureKeepsMove` | `moveSuccessIsUnchanged` | Core, Builder A |
| 7 Note create and delete | NotesView.swift:40, 121; NoteEditor.swift:171, 180 | `Haptic.made` | `noteCreateFailureKeepsDraftText`: typed text stays in the field | `noteDeleteUndoFailureKeepsNote` | `noteCreateSuccessIsUnchanged` | Core, Builder B |
| 8 Recipe actions | RecipePage.swift:158, 184; PasteRecipe.swift:200 | `Haptic.made` | `recipeAddToGroceriesFailureAddsNothing`: pasted text stays | `recipeUndoFailureKeepsGroceries` | `recipeActionsSuccessUnchanged` | Core, Builder B |

## Done when

Each family passes its three rows with a performer that throws, the 52 sites are either routed through the helper or marked system-only in the table above, and the unit tests assert `TessVoice.shared.note?.text`, `note?.undo == nil`, the object counts and `engine.history()` before and after. Gate for the haptic rows: a recorded `Haptic` trigger list stays empty in the failure rows (Core exposes the trigger through the same test seam the haptic-map work in discovery item 3 adds).
