# Review: Tess capture engine + processes (origin/master 5601a24, static only)

## What checks out
- No force unwraps, `try!` or `fatalError` in TesseraTess or Processes. A missing system class makes the lookup return
  nil or throw `missingSystemClass`, and `ActionEngine.perform` rolls back a half-applied transaction. No crash path found.
- All or nothing holds: `performSets` takes back earlier parts when one fails, `TessTools.run` rolls back to its mark,
  Claude's `discard` and the on-device `catch` both drop pending records.
- The 4 AM day: `parseDatedLift`, `TessDates.pastDay`, "tomorrow", `when()` (small hours name the weekday), the model's
  "still <day>" line and `answerQuery` windows all go through `TesseraDay`.
- One running process: `StartProcess`, `ResumeProcess` and `makeRunning` suspend every other running process in the
  same transaction. `touchWorkoutProcess` picks a suspended workout back up. `FinishWorkout`, `FinishCooking` and
  `FinishShop` end their open process.
- Ghosts: a discarded ghost never seats sets. `commitCapture` commits every record from the phrase, and
  `undoLastCapture` reverts all of them.
- On every `.active`, `tidyProcesses` wraps up a workout suspended for 6 h and drops `session` once `endedAt` is set.

## Findings

### P1 (high): UNDO on "Push A, no sets, not saved." leaves a workout that is open but has no process
- Where: `TesseraCore/Sources/TesseraCore/Processes/ProcessTable.swift:136-142`. `wrapUp` performs `EndProcess`, then
  `DeleteObject`, and `Note.undo` holds only the delete record.
- Scenario: he opens Push A, logs nothing, and leaves it. The next morning Tess says "Push A, no sets, not saved." and
  he taps UNDO. The workout comes back with `startedAt` set and no `endedAt`, but its process stays `done`. It is not on
  Now, not in the ledger and has no Resume (`pickUpRunningWorkout` needs a running process). Days later he types
  "bench 80x8". `LogExercise.activeWorkout` (`TrainingActions.swift:381-387`) picks this orphan as "in progress", so
  the sets land in last week's workout under the line "Added to today." No process starts, so nothing shows as running.
- Fix: make the wrap-up one record (EndProcess and DeleteObject in one action, e.g. a `DiscardEmptyWorkout` action) so
  UNDO also reopens the process as suspended. Also have `activeWorkout` skip workouts that have no open process.
- Owner: Core.

### P2 (high): undoing a capture that started a workout leaves `AppModel.session` on a deleted workout
- Where: `App/AppModel.swift:297-308` (`undoLastCapture`), `:636-648` (`adoptCapturedSets` calls
  `pickUpRunningWorkout`), `:341` (tidy only clears `session` when `endedAt != nil`).
- Scenario: on Home with nothing running he types "bench 80x8". `LogExercise` creates a workout, starts its process and
  logs the set. The ghost dries, and `adoptCapturedSets` sets `session` to the new workout. He taps UNDO. The workout,
  its entry and its process are deleted, but `session` stays (a deleted workout has `endedAt == nil`, so tidy keeps it
  too).
  - Training still shows the running plan with RESUME (`TrainingPage.swift:21`).
  - The Ask bar says "Tell me a set." and offers "Back to Workout".
  - `todaysRoutine` is hidden because it requires `session == nil`.
  - Every set phrase passes `entry: session.currentEntry` (deleted, but `store.object(id:)` still returns it), so
    `LogSet` throws `objectNotFound` and Tess answers "Didn't save that. Tap to retry." until relaunch.
- Fix: after any undo or discard (and in `tidyProcesses`), set `session = nil` when `session.workout.isDeleted`, or when
  the process table has no open process for it. In `ask()`, pass `entry` only when it exists and its workout has no
  `endedAt`.
- Owner: Builder B (AppModel and Ask bar). Tell Builder A.

### T1 (high): times from the model with no zone are stored as UTC
- Where: `TesseraCore/Sources/TesseraTess/TessTools.swift:344-349` (`date(_:)`), used by `createTask` (`:116`) and
  `rescheduleTask` (`:137`). The context line (`TessModelCapture.swift:55-66`, also used by Claude) gives local time
  with no offset.
- Scenario: a phrase the grammar misses, such as "remind me about the dentist around 3 thursday", goes to the model.
  The model sends `"startsAt":"2026-10-22T15:00:00"`. The strict `.iso8601` parse fails, and the fallback
  `Date.ISO8601FormatStyle` defaults to GMT. In Pacific time the task lands at 8 AM. On a UTC+ zone near midnight it
  can land on another day. The tests only use `...Z` strings, so they pass.
- Fix: give the fallback `timeZone: .current` (or the context calendar's zone), and put the zone offset in the
  `today is ...` context line.
- Owner: Core.

### T2 (medium): a second live ask, or a kill inside the 2 s dry time, strands a pending record for good
- Where: `Features/Workout/WorkoutModeView.swift:273-286` (live `ask` has no busy guard; `LiveAskField.submit` closes
  the sheet, `WorkoutParts.swift:389-401`), `App/AppModel.swift:238-251` (`land` overwrites `pendingCaptures` and
  `pendingCaptureID` without committing the earlier ones), `ActionEngine.swift:120` (`commitExpired` is never called
  from the app).
- Scenario: in a live workout he asks "did a superset of curls 12 at 15" (model route, a few seconds), reopens the
  field and says "80 for 8". The grammar lands first, then the model's capture replaces it in `pendingCaptures`. The
  first record's dry timer then sees a different id and returns. That record stays `.pending` for good:
  - no observers fire;
  - the Day log leaves it out (`DayStory.swift:143` keeps only `.committed`);
  - UNDO cannot reach it.
  The same happens if the app is killed within 2 s of any capture. Two overlapping captures also clear each other's
  `engine.attribution`.
- Fix: in `land`, commit any `pendingCaptures` still held before replacing them. Call `engine.commitExpired()` in
  `tidyProcesses` (launch and foreground). Guard the live ask with an in-flight flag like the Bar's `isBusy`.
- Owner: Builder B (`land`, tidy). Builder A (live ask guard).

### T3 (medium): a back-dated lift into an open past workout revives it and back-dates today's workout
- Where: `TrainingActions.swift:361-372` (`pastWorkout` matches an unfinished workout that day), `:345-349` (stamp
  falls back to `startedAt`), `:81-83` plus `WorkoutProgress.swift:61-68` (`LogSet(time:)` calls
  `touchWorkoutProcess(at: stamp)`), `ProcessActions.swift:365-372` (`suspendRunning` writes `lastTouchedAt = stamp`).
- Scenario: Monday at 23:00 he opens a workout and leaves it suspended. At 05:00 Tuesday (inside 6 h, so tidy hasn't
  wrapped it) he starts today's workout and says "bench 80x8 mon", then taps LOG. Monday's process becomes running
  again, and today's running workout is suspended with `lastTouchedAt` set to Mon 23:00. On the next foreground, tidy
  sees today's workout idle for more than 6 h and wraps it up with `FinishWorkout(time: Mon 23:00)`, so `endedAt` comes
  before `startedAt`. Monday's workout is now Now.
- Fix: a back-dated `LogSet` (`time != nil`) should not change process state (skip `makeRunning`, and touch with `.now`
  at most). `pastWorkout` should skip a workout that still has an open process, or finish it first.
- Owner: Core.

### T4 (medium): `LogExercise` picks "today's workout" by creation order, not by the process table
- Where: `TrainingActions.swift:381-387` (`objects(of:).last { startedAt != nil && endedAt == nil }`). Every `.lift`
  from the grammar, and the models' `logSet` tool, comes through here.
- Scenario: Push A (made earlier) is suspended in the ledger and he starts a planned Pull B that was created before it,
  so Pull B is running. Typing "bench 80x8" with a different exercise in focus logs into Push A, the last one created.
  `touchWorkoutProcess` then makes Push A running and suspends Pull B, which is the one on screen.
- Fix: use `ProcessTable.openWorkout()`'s subject first (running, then the most recent suspended), and only then fall
  back to creating a workout. Add a test with two unfinished workouts.
- Owner: Core.

### T5 (low): Tess's cook and shop starts ignore the capture clock
- Where: `TessCaptureEngine.swift:345` (`StartCooking(recipe:)`, no `time`) and `:357` (`StartShop()`). The timer,
  next-step and finish paths do pass `context.now`.
- Scenario: under `-demoTime 18:10`, "cook carbonara" stamps the process with wall-clock `startedAt` and
  `lastTouchedAt`, while tidy and the ledger use `AppClock.now`. Idle times and the ledger's 3-day window read wrong
  in demos. DEBUG only.
- Fix: pass `time: context.now` to both.
- Owner: Core.

Dropped after tracing (no real input found): two running processes through normal actions or guarded undo; the
on-device `catch` leaving committed ghosts (nothing commits before `land`); a suspended cook or shop that can't resume
(the ledger's Resume goes through `ResumeProcess`).
