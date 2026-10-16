# Training week one: what to count

*Board item 31. Research worker, 2026-10-16. Traced by hand on `origin/master` at `15fc404` (Merge #162). No build was run. Modelled on `docs/product/kitchen-week-one.md`. Paths that start with `Core/` are under `TesseraCore/Sources/TesseraCore/`.*

Kaushik's first full week of workouts runs **Monday 19 Oct to Sunday 25 Oct 2026, Pacific time** (PDT all week, so UTC-7). Settings: PPL x2 (6 sessions a week, one rest day), kg, a missed day rolls on, a workout left idle wraps up after 6 h. This page says what to count from his data at the end of that week, so the next Training slice is scoped from what he did, not from guesses. Most of it comes from the op log without asking him anything.

## How to read the log

- The log is the `op` table in `Application Support/Tessera/tessera.sqlite` (`Core/Model/TesseraDatabaseSchema.swift:39-49`). Columns: `id`, `action` (the descriptor name, such as `logSet`), `actor` (`user`, `tess`, `intent`, `system`), `state` (`committed`, `pending`, `undone`), `summary`, `createdAt` and `updatedAt` (Unix seconds), `ops` (JSON `[Op]`), `objectIDs` (JSON array, in op order), `route` and `model` (Tess only).
- One row is one action. A nested action records only the outer name: `startRoutine` hides its `startWorkout`, `logNextSet` hides its `logSet`, `finishWorkoutEarly` hides its `finishWorkout`.
- **Undo leaves no row.** `ActionEngine.undo` (Core/Actions/ActionEngine.swift:131-137) flips the record's `state` to `undone` and bumps `updatedAt`. That is the only trace: no actor, no route, no source.
- A Tess ghost row that he dismisses is also `undone` (`discard` calls `undo`, :106-110). Tell it apart by time: a discard lands within the 2 s grace period, so `updatedAt - createdAt < 3`.
- Set fields live in the `ops` JSON. A choice value encodes as `{"choice":{"_0":"lockScreen"}}`, so `CAST(ops AS TEXT) LIKE '%"_0":"lockScreen"%'` finds a set's source. Set sources on master: `hold`, `dial`, `lockScreen`, `tess`, `manual`, `intent` (`Core/Training/SetKinds.swift:13-15`).
- Every query below uses this week filter. Copy the file off the phone first (Files or a backup), and run read-only.

```sql
-- the week: Mon 19 Oct 00:00 PDT to Mon 26 Oct 00:00 PDT
WITH wk AS (SELECT * FROM op WHERE createdAt >= 1792393200 AND createdAt < 1792998000)
```

Caveat for every count: App Intents don't save (oplog-health B3). A Lock Screen Done or a Siri action that runs in the background can be lost if iOS kills the app before autosave, and then it never reaches the log. Lost actions undercount, they never overcount.

## The counts

### 1. Sets per session

- **Actions:** `logSet`, `logNextSet`, `logExercise` (one `logExercise` can log several sets), sessions from `startRoutine`.
- **How:** count live set objects per workout, not op rows, so undone and removed sets drop out on their own.

```sql
SELECT w.title, datetime(MIN(o.createdAt), 'unixepoch', '-7 hours') AS started, COUNT(s.id) AS sets
FROM object w
JOIN object e ON e.parentID = w.id AND e.deletedAt IS NULL
JOIN object s ON s.parentID = e.id AND s.deletedAt IS NULL
JOIN wk o ON o.action = 'startRoutine' AND json_extract(o.objectIDs, '$[0]') = w.id
WHERE w.deletedAt IS NULL
GROUP BY w.id ORDER BY started;
```

- **Good:** 15 to 25 sets a session, close to the routine's planned total (`targetSets` summed over entries). It means the plan fits and he logs as he goes.
- **Worrying:** under 10, or well under plan on most days. Either the plan is too long for his time, or he stops logging part way and trains from memory. Check against count 9 (auto-finished sessions) before deciding which.

### 2. Edits to logged sets

- **Actions:** `editSet`. The `clearRPE` argument is not stored as such: a real clear shows as a `setValue` on the `rpe` field with no `new` key.
- **How:**

```sql
SELECT COUNT(*) AS edits,
       SUM(CAST(ops AS TEXT) = '[]') AS empty_edits
FROM wk WHERE action = 'editSet' AND state = 'committed';
```

- **Bug found while tracing:** the live screen never sends `clearRPE`. `WorkoutSession.saveEdit` (Features/Workout/WorkoutSession+Edit.swift:35-46) sends `EditSet(set:weight:reps:rpe:)` with `rpe: nil` when he clears the RPE, and nil means "leave as is". The RPE stays, Tess says "Set 2 is 80 × 8 now.", and if weight and reps didn't change the log gets an `editSet` row with `ops = '[]'`. So `empty_edits` counts his attempts to clear an RPE. Smallest fix: pass `clearRPE: row.rpe != nil && rpe == nil` and `rpe` only when it is not nil. Owner: Builder A.
- **Good:** 0 to 2 edits a session. Logging is accurate first time.
- **Worrying:** more than 1 edit for every 5 sets, or edits that always touch the same field. Weight edits point at the dial (prefill or detents wrong). Rep edits point at the drum. Any `empty_edits` at all means he met the bug above.

### 3. Swaps

- **Actions:** `swapExercise` (descriptor name of `SwapEntryExercise`, Core/Training/ExerciseOverview.swift:36-44, today only). Count `swapSlotExercise` separately: that one changes the routine for good.

```sql
SELECT action, actor, COUNT(*) FROM wk
WHERE action IN ('swapExercise','swapSlotExercise') AND state = 'committed'
GROUP BY action, actor;
-- what he swapped to: the summary reads "Swapped to <exercise> for today"
SELECT summary, COUNT(*) FROM wk WHERE action = 'swapExercise' AND state = 'committed' GROUP BY summary;
```

- **Good:** 0 to 2 in the week, spread over different exercises. Swap is a rescue for a busy gym.
- **Worrying:** the same exercise swapped every time it comes up (the routine is wrong for him; a permanent `swapSlotExercise` should be offered), or a `swapExercise` undone straight away (the swap panel's choices are wrong).

### 4. Set removals

- **Actions:** `deleteObject` on a set (the editor's Remove, WorkoutSession+Edit.swift:49-71). An undone `logSet` is a different thing (count 5).

```sql
SELECT COUNT(*) FROM wk o
JOIN object s ON s.id = json_extract(o.objectIDs, '$[0]')
JOIN object e ON e.id = s.parentID
JOIN object w ON w.id = e.parentID
JOIN classDef c ON c.id = w.classID AND c.systemKey = 'system.workout'
WHERE o.action = 'deleteObject' AND o.state = 'committed';
```

- **Good:** 0 or 1. Removal is for a set logged by mistake, which undo already covers.
- **Worrying:** several, mostly on the last set of an exercise: he logs an extra set by accident (a long hold, or Lock Screen Done pressed twice). Compare with count 7.

### 5. Undo use, split into in-app, Siri and Lock Screen

- **Actions:** any record with `state = 'undone'`. Undo of a set: `logSet`, `logNextSet`, `logExercise`. Undo of an edit: `editSet`, `deleteObject`, `swapExercise`.

```sql
SELECT action, actor, COUNT(*) AS undone
FROM wk WHERE state = 'undone'
  AND NOT (actor = 'tess' AND updatedAt - createdAt < 3)  -- leave out dismissed ghost rows
GROUP BY action, actor;
-- seconds from the action to its undo
SELECT action, ROUND(updatedAt - createdAt) AS secs FROM wk WHERE state = 'undone' ORDER BY secs;
```

- **The split can't be read.** Undo writes no row and no actor (see "How to read the log"). On master there are four paths: the live screen (`WorkoutSession.undoLastSet` and `undoLast`), the Ask Tess bar (`AppModel.undoLastCapture`, App/AppModel.swift:220-232), Home's bar (`Features/Command/BottomChrome.swift:110`), and Siri's "Undo last set" (`UndoLastSetIntent`, TesseraIntents/Intents.swift:59-74, wired in App/AppIntentsPackageLink.swift:19). **There is no Lock Screen undo on master:** the Live Activity has Done, +15, Skip rest and Skip set only (Shared/RestIntents.swift:5-14), so the Lock Screen count is 0 by construction.
- **Good:** a few undos, almost all within 10 s of the action. Undo is a safety net he trusts.
- **Worrying:** many set undos followed by a fresh `logSet` within a minute (he is fixing numbers by undo and re-log, which means editing is too hard), or any undo more than 5 minutes later (he found a mistake late, so the trail isn't visible enough).

### 6. Rest timer skips and extends

- **Actions:** none. `skipRest` and `extendRest(by:)` (Features/Workout/WorkoutSession.swift:427-445) change session state, then `persistRest` (WorkoutSession+Rest.swift:26-41) overwrites the process's `resumePoint` on the store, with no op (oplog-health B1). The Live Activity's +15 and Skip go through the same two functions (LiveWorkout.swift:25-28).
- **How:** **can't be counted.** The resume point keeps only the latest rest, so even the final state of each rest is lost on the next set.
- **Good, once measurable:** skips under 1 in 5 rests and few extends. The default rest times fit.
- **Worrying:** skips on most rests for one exercise (rest too long, lower `restSeconds` for it), or +15 on most rests (too short). Skips that all come from the Lock Screen mean he isn't looking at the app between sets, which is fine and says the Live Activity is doing its job.

### 7. Lock Screen Done taps

- **Actions:** `logSet` or `logNextSet` with `actor = 'user'` and set source `lockScreen`. The Live Activity's Done calls `session.logSet(source: .lockScreen)` with the default actor `.user` (LiveWorkout.swift:19-24). Siri's "Log Next Set" (`LogNextSetIntent`) also stores source `lockScreen`, but with `actor = 'intent'`, so the actor tells them apart.

```sql
SELECT actor, state, COUNT(*) FROM wk
WHERE action IN ('logSet','logNextSet') AND CAST(ops AS TEXT) LIKE '%"_0":"lockScreen"%'
GROUP BY actor, state;
```

- **Good:** a real share of sets, say a third or more. He logs without unlocking, which is the point of the Live Activity.
- **Worrying:** none at all (he hasn't found it, or it doesn't show), or Done taps that are often undone or removed (the planned set was wrong, so Done logged numbers he didn't lift).

### 8. Tess phrases vs taps for logging sets

- **Actions and how they split:**
  - Phrases: `actor = 'tess'` on `logSet` or `logExercise` (TesseraTess/TessCaptureEngine.swift:79-96), split by `route` (`grammar`, `onDevice`, `claude`). Siri's "Log a Set" shortcut is `actor = 'intent'` on `logExercise`.
  - Taps: `actor = 'user'` on `logSet` or `logNextSet`, split by source (`hold`, `dial`, `lockScreen`).

```sql
SELECT action, actor, COALESCE(route, '-') AS route,
       CASE WHEN CAST(ops AS TEXT) LIKE '%"_0":"lockScreen"%' THEN 'lockScreen'
            WHEN CAST(ops AS TEXT) LIKE '%"_0":"hold"%' THEN 'hold'
            WHEN CAST(ops AS TEXT) LIKE '%"_0":"dial"%' THEN 'dial'
            WHEN CAST(ops AS TEXT) LIKE '%"_0":"tess"%' THEN 'tess'
            ELSE 'other' END AS source,
       COUNT(*) AS n,
       SUM(state = 'undone') AS undone
FROM wk WHERE action IN ('logSet','logNextSet','logExercise')
GROUP BY 1, 2, 3, 4 ORDER BY n DESC;
```

- **Partial gap:** "Tell Tess" from Siri (`TellTessIntent`) runs the same capture as the Bar with `commitImmediately`, so it is also `actor = 'tess'`, source `tess`. A spoken phrase and a typed one can't be told apart. Smallest fix: `TessContext` gets a `via` value, and `TessCaptureEngine` passes `source: .intent` on `LogSet` when it came from the intent. Owner: Core.
- **Good:** taps carry the session (hold and Lock Screen), and phrases fill gaps such as a set he forgot to log. Few Tess sets undone or discarded.
- **Worrying:** phrases undone or discarded often (the grammar misreads gym talk: look at their `summary` lines), or almost no taps (the dial and drum are too slow, and he has moved to typing).

### 9. Sessions started vs finished vs auto-finished at 6 h

- **Actions:**
  - Started: `startRoutine` (from the week page, Now or Siri), `startWorkout` (a task linked to a workout, App/AppModel.swift:440), and a `logExercise` that had to create a workout.
  - Finished by him: `finishWorkout` with `actor` `user` or `intent`, and `finishWorkoutEarly`.
  - Auto-finished: `finishWorkout` with `actor = 'system'`, paired with `endProcess` (reason `wrappedUp`), from `ProcessTable.wrapUp` (Core/Processes/ProcessTable.swift:120-127). This only fires on the next launch or foreground after the workout was suspended and idle for 6 h, and it sets `endedAt` to the last touch, not the wrap-up time.

```sql
SELECT action, actor, COUNT(*) FROM wk
WHERE state = 'committed'
  AND action IN ('startRoutine','startWorkout','finishWorkout','finishWorkoutEarly')
GROUP BY action, actor;
```

- **Good:** 6 started, 6 finished by him, 0 auto-finished.
- **Worrying:** any auto-finish. He walked out without finishing, so the finish step is either hidden or not worth his time, and the Health workout and the summary land late. Several `finishWorkoutEarly` mean the routines are too long.

### 10. Missed days rolled on

- **Actions:** none record a miss. That is on purpose: the plan is a rolling sequence with no debt (`TrainingLedger.nextRoutine`, Core/Training/PlanSchedule.swift:3-21), and the week view never shows a past day as missed (Core/Training/WeekView.swift:28). `rollForwardTasks` is for tasks, not training, and is still not called on master (oplog-health B6), so it doesn't apply here.
- **How:** derive it. A missed day is a Pacific day in the week with no workout started, beyond the one rest day that PPL x2 allows. "Rolled on" holds if each `startRoutine` starts the routine after the last finished one.

```sql
-- workouts per Pacific day, with the routine (summary reads "Started <routine>")
SELECT date(createdAt, 'unixepoch', '-7 hours') AS day, GROUP_CONCAT(summary, ' / ') AS started
FROM wk WHERE action = 'startRoutine' AND state = 'committed'
GROUP BY day ORDER BY day;
-- missed days = 7 - (days in this list) - 1
```

- **Check by eye:** the routines should follow Push A, Pull A, Legs A, Push B, Pull B, Legs B with no gaps. A routine started out of order means he overrode the roll (from the week page), which is worth asking about.
- **Note:** the app's own week uses `Calendar.current`, which starts on Sunday in a US locale. This page's week starts Monday, so the app's "this week" and this count can disagree on the Sunday.
- **Good:** 0 or 1 missed days, and the sequence never skips a routine.
- **Worrying:** 2 or more missed days, or the same routine started twice in a row (he restarted after a bad session, or the next routine shown wasn't the one he expected).

### 11. PRs hit

- **Actions:** none. The live screen decides a PR in memory (`ledger.recordsBeaten`, `ledger.shouldCelebrate`, WorkoutSession.swift:325-358) and keeps it in `bests`, which is session state.
- **How:** derive it in Swift from the sets, using only history before each set.

```swift
// Swift sketch, run against a copy of the store (for example in a test target).
let ledger = TrainingLedger(store: store, classes: classes)
var best: [UUID: Double] = [:]   // exercise class id -> best e1RM so far
var prs: [(exercise: String, e1RM: Double, at: Date)] = []
let weekStart = Date(timeIntervalSince1970: 1_792_393_200)
let weekEnd = Date(timeIntervalSince1970: 1_792_998_000)
for set in ledger.allLoggedSetsOldestFirst() {        // every working set ever, by loggedAt
    guard let e1RM = ledger.e1RM(weight: set.weight, reps: set.reps, rpe: set.rpe) else { continue }
    let previous = best[set.exercise.id] ?? 0
    if (weekStart..<weekEnd).contains(set.loggedAt), previous > 0, e1RM > previous {
        prs.append((set.exercise.name, e1RM, set.loggedAt))
    }
    best[set.exercise.id] = max(previous, e1RM)
}
```

  `allLoggedSetsOldestFirst` is not a real API; build it from the training index or from `ledger.loggedSet` over each workout's entries. Warm-ups are already left out by `loggedSet`.
- **Gap, small:** this gives PRs earned, not PRs he saw celebrated (one per exercise per session). That is fine for week one.
- **Good:** a few e1RM PRs on the main lifts. It is his first logged week on a new plan, so early PRs are expected and the celebration should have fired.
- **Worrying:** zero PRs while sets per session look normal (the prefill or starting weights are too light), or a PR on almost every set (no history came across, so every set "beats" nothing; check the legacy import).

### 12. Time from opening the app to the first set

- **Actions:** none for the app opening. Nothing records a launch or a foreground.
- **Proxy that works today:** time from `startRoutine` to the first set of that workout.

```sql
SELECT s.summary AS session,
       ROUND(MIN(l.createdAt) - s.createdAt) AS secs_to_first_set
FROM wk s
JOIN object w ON w.id = json_extract(s.objectIDs, '$[0]')
JOIN object e ON e.parentID = w.id
JOIN object st ON st.parentID = e.id
JOIN wk l ON json_extract(l.objectIDs, '$[0]') = st.id
WHERE s.action = 'startRoutine' AND l.action IN ('logSet','logNextSet')
GROUP BY s.id;
```

- **Good:** under 5 minutes from start to the first set (most of that is a warm-up), and steady across the week.
- **Worrying:** over 10 minutes often (he starts the routine at home or in the car), or the true number (open to first set) is long while start to first set is short: the path from Home to "start" is too slow. Only the second needs the missing data.

## Gaps: what the op log doesn't record

| Count | What is missing | Smallest fix | Owner |
|---|---|---|---|
| 5. Undo split | Who undid a record and from where. Undo flips `state` only | Add `undoneVia TEXT` and `undoneAt REAL` to `op` (migration `v3`), set by `ActionEngine.undo(_:via:)` with `inApp`, `tessBar`, `siri`, `lockScreen`. `undoLatestSet` takes `via` too | Core (column, API, `UndoLastSetIntent`); Builder A (the live screen's two calls) |
| 6. Rest skips and extends | Everything. `persistRest` writes the resume point with no op (oplog-health B1) | A small local `usage` table in Core (`kind`, `at`, `detail`, never synced, never in undo), with one call from `skipRest` and `extendRest` carrying `inApp` or `lockScreen`. No op, so undo and the trail stay clean | Core (table, API); Builder A (two call sites) |
| 12. Open to first set | App launch and foreground times | One `usage` row (`kind = "foreground"`) from the scene phase change. Same table as above | Core (table); Builder B (the call in `App/`, as in oplog-health B6) |
| 8. Siri phrase vs typed phrase | Both are `actor = tess`, source `tess` | `TessContext.via`; `TessCaptureEngine` passes `source: .intent` from `TellTessIntent` | Core |
| 2. Clearing an RPE | Not a gap, a bug: the clear never happens and the log gets an empty `editSet` | Send `clearRPE` from `saveEdit` | Builder A |
| 11. PRs celebrated | Only PRs earned can be derived | None for week one | |

The `usage` table is the same idea as the Kitchen lead's capture-miss log (`kitchen-week-one.md`, gap 1). One table for both, with a `kind` column, is the smallest version. It must never leave the phone. If Core can land it before Monday 19 Oct, counts 6 and 12 work in week one; if not, week one skips them and asks question 1 below instead.

## What to notice without counting

- Anything he does outside the app between sets: a timer on the Clock app, numbers in Notes, a photo of the whiteboard.
- The first thing he says about training when asked nothing.

## Three questions for the end of the week (ask in one message, each answerable in a word)

1. **Rest timer: keep?** (Yes or no. Recommended default: **yes**. A no, or "only on the Lock Screen", moves rest from the dial to the Live Activity alone.)
2. **Swap: easy enough?** (Yes or no. Recommended default: **yes**. A no puts the swap panel's choices and a "swap for good" option ahead of new features.)
3. **Finish: forgotten?** (Yes or no. Recommended default: **no**. A yes, or any auto-finish in count 9, makes finishing automatic once the last planned set is logged.)

Then scope the next Training slice from the answers and the counts above, in one message to Product, with a recommendation.
