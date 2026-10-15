# QA review: Core's second hotfix #80, and Tess, processes and HealthKit

*Repo maintainer, 2026-10-15. This was a static read of master after #80 (2d874bf), with no Swift toolchain, so nothing was built or run.*

## Hotfix #80: status of earlier findings

**Fixed (traced):** H1, H2, H3, H4, K6, G2, N2 (the copy no longer promises an undo; no real undo was added), N3, N4, and the Fix 6 test.

**Partly fixed:**
- **H5 / K2.** `bench 80x8, 82.5x6` now logs two sets. `80x8, 80x8, 80x6` still returns nothing, even with an entry in focus: `parseLift("80x8")` has no exercise, and `parseRelativeSet` only accepts `80 x 8` with spaces. The doc comment at `TessGrammar.swift:119-120` says it works. The test row was removed instead of fixed.
- **N1.** Opening and leaving a note no longer rewrites it. Typing still drops the blank line after the heading, because `join` is lossy. See also B2.
- **Grammar trace tests.** Three rows still accept "nothing" as a pass.

**Still open:** G1 (iOS build, `Features/Home/TrainingPage.swift:115-119`). D1–D4 are waiting on their own PR.

All 20 must-keep phrases (buy milk, comma groceries, timers, dated cooks, lifts, relative sets, tasks, notes, lists, rest and plank timers) still parse as intended.

## New bugs from #80

- **B1 (medium): the second comma set repeats the first set's numbers.** `TessGrammar.swift:136-138`
  - **What's wrong:** only the `NxM` form is stripped from the carried-forward words.
  - **Failure:** `bench 80 for 8, 82.5 for 6` logs bench 80×8 twice (82.5×6 is lost). `squat 100 5, 105 5` does the same.
  - **Fix:** carry forward only the exercise words.
- **B2 (medium): an edit undone back to the original note text is never saved.** `Features/Notes/NoteEditor.swift:130`
  - **What's wrong:** `openedAs` isn't updated after a save.
  - **Failure:** type a change, wait for the autosave, then type back to the original. `save()` sees the original text, returns early, and the edited version stays.
  - **Fix:** set `openedAs = trimmed` after each successful save.
- **B3 (medium): Undo after a multi-set capture removes only the first set.** `App/AppModel.swift:164`, `:189`, `:216-218`
  - **Failure:** `bench 80x8, 82.5x6`, let it commit, tap Undo. The 82.5×6 set stays.
  - **Fix:** keep every record of the capture and undo them in reverse.
- **B4 (low): a partial failure inside `.sets` leaves an orphaned pending op.** `TessCaptureEngine.swift:26-38`
  - **Fix:** discard the records already performed in the catch.
- **B5 (low, design risk): any undated "get" of three words or fewer becomes groceries.** `TessGrammar+Kitchen.swift:155`
  - **Failure:** `get a haircut` and `get mum a card` both become grocery items.

## Tess, processes and HealthKit (older merges)

- **P1 (high for daily use): idle suspension uses the workout rule for every process.** `App/AppModel.swift:229-231`, `Processes/ProcessTable.swift:77-81`
  - **What's wrong:** the limit is rest + 10 minutes for whatever is running. A shop's `lastTouchedAt` only changes on StartShop, because `refreshShopLine` doesn't touch it.
  - **Failure:** check items for 15 minutes, then unlock or switch back. The shop is suspended mid-trip. A started task, or a cook on a long timer, gets the same treatment.
  - **Fix:** auto-suspend workouts only, or give each app its own limit, and set `lastTouchedAt` from shop and cook actions.
- **P2 (high for daily use): a workout suspended while the live cover is up never comes back to running.** `App/AppModel.swift:228-240`, `Training/WorkoutProgress.swift:60-65`
  - **Failure:** lock the phone through a rest longer than rest + 10 minutes, unlock, and keep logging. The process stays suspended: Home shows "Resume", and "log next set" from Siri or the Action button says "No workout running".
  - **Fix:** skip `suspendIfIdle` while `isWorkoutPresented`, or resume when the cover shows. Have `touchWorkoutProcess` make a suspended process running.
- **P3 (medium): FinishWorkoutIntent and LogNextSetIntent miss a suspended workout.** `TesseraIntents/Intents.swift:47`, `:104`
  - **What's wrong:** they use the running process, else only the first ledger row (which can be a task, shop or cook).
  - **Fix:** use the newest open process whose subject is a workout.
- **P4 (medium): the on-device model can call the system action `rollForwardTasks` with a made-up time.** `TessModelCapture.swift:84-87`
  - **Failure:** "push my tasks to Monday" can move every unfinished task to Monday, bump its roll count, and send six-times-rolled ones to Later. Through Tell Tess it commits with no ghost row.
  - **Fix:** use an explicit tool allowlist instead of a name-suffix filter.

**Checked and fine:**
- Ghost rows commit and discard correctly.
- Two processes can't run at once.
- `tidy` has no day-boundary problems.
- The HealthKit sync id and version prevent duplicate writes, and it skips empty workouts.
