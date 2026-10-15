# Day log fixtures: five days for DayStory

For: Core engine. Date: 2026-10-15
Read with: `../day-log-first.md` (the 12 fold rules), `year-of-data.md` (generator shapes and names), `../tess-voice.md` (line voice).
Checked against origin/master at 1a9c218 (Merge #141, core/ranker).

## What master has

- **No DayStory yet.** `git grep DayStory origin/master` finds it only in `docs/research/day-log-first.md`. There is no `DayLog/` folder, no `DayLine`, no `DayLookup`. The only "day line" on master is `WorkoutFinishView.dayLine` ("Tuesday, 07:10 to 08:02"), which is unrelated.
- **The 04:00 day start exists** as `RollForward.dayStartHour = 4` (`Tasks/RollForward.swift`). Reuse it. Do not confuse it with `DayLoad.load(dayStartHour: 7)`, which is the start of the plannable day, not the day boundary.
- **`OpRecord`** (`Model/Models.swift`): `action` (the descriptor name), `actorRaw`, `stateRaw`, `summary`, `createdAt`, `updatedAt`, `opsData` (the `[Op]`), `objectIDs` (derived from the ops, first-seen order), `routeRaw`, `model`. The public `init(action:actor:summary:ops:state:)` sets `createdAt = .now`, so fixtures set `createdAt` by hand after init. **A record does not store the action's arguments.** Anything like "done or reopen" has to be read from the `setValue` ops.
- **`OpState`**: `committed`, `pending`, `undone`. `ActionEngine.undo` flips the same record to `undone` and `redo` flips it back, so undo-then-redo is one committed record. `commitExpired` turns old `pending` rows into `committed`.
- **`ActionRegistry.descriptors`** holds 50 actions. Their names match the 50 in `day-log-first.md` exactly (diffed name by name). Watch one trap: the Swift type `SwapEntryExercise` has the action name `swapExercise`.
- **Merged today and relevant here:** live workout (#134), rest day on Now (#132, `Training/RestDay.swift`), groceries follow-up and design pass (#131, #124), starter lists (#137), Backups restore confirm (#120), v1 engine gaps (`removeSlot`, #122), ranker (#141). Rest days and Backups add **no** actions, so a rest day leaves no record and DayStory cannot see it.

### Names to flag

- **Named in `day-log-first.md` but missing on master:** none of the 50 action names. Missing types and classes: `DayStory`, `DayLine`, `DayLookup` (to be built), `DayNote`, a calendar `Event`, and Health. The doc already parks the last three.
- **Not action names, so never use them in fixtures:** `completeTask`, `rescheduleTask`, `addToList` and `answerQuery` are Tess tool names in `TesseraTess/TessTools.swift`. A Tess call lands in the op log under the registry name (`setTaskDone`, `moveTask`, `addListItem`), and `answerQuery` writes nothing.
- `year-of-data.md` names `DoChore`, `ChoreFine`, `LogSpend` and other actions that are not on master. None are used here.

## Conventions for all five days

- Calendar: Gregorian, `Europe/London` (BST in September), Monday first. All times are local. Day start 04:00.
- Ids are labels: `W` workout, `E` exercise entry, `S` set, `T` task, `N` note, `G` grocery item, `L` list item, `K` recipe, `C` cook, `KT` kitchen timer, `P` process. The fake lookup maps each label to a fixed UUID.
- The fake `DayLookup` returns titles exactly as stored. **The fold never changes case.** Fixture titles follow the doc's examples (lowercase common nouns), but routine names come from `DemoData` ("Push Day A", "Pull Day A", "Leg Day A").
- `topSet(inWorkout:)` in the fake returns a fixed answer per workout, given in each day's notes. In the app it reads `TrainingLedger`, which never sees an undone set (undoing a `create` soft-deletes it) and always sees the edited values.
- Expected lines are written as `"HH:mm text"`, with one space. The "Also:" tail has no time. The day header ("Tue Sep 15") is not part of `lines(...)`.
- Rule numbers refer to the 12 rules in `day-log-first.md`. "Kept, L2" means the record feeds expected line 2.

## Day 1: Tue Sep 15, push day, a shop and a note

Lookup: W1 "Push Day A"; T1 "call the bank" (created Sep 14); N1 "shoulder felt fine"; G1 to G14 sit under the Groceries list (`Groceries.listID`). `topSet(W1)` = ("Bench 82.5 x 8", isPR: true).

| # | Time | Actor | Action | Key fields | State | Rule |
|---|---|---|---|---|---|---|
| 1 | 07:10 | user | `startRoutine` | routine=Push Day A; creates W1, E1 Bench, E2 OHP, E3 Incline | committed | Kept, L1: group start (5) |
| 2 | 07:12 | user | `logSet` | entry=E1, 60 x 10, isWarmup=true | committed | Joins W1 (5) |
| 3 | 07:15 | user | `logSet` | entry=E1, 82.5 x 8; `recordsBeaten` not empty | committed | Joins W1; top set and PR (7) |
| 4 | 07:19 | user | `logNextSet` | entry=E1, logs 82.5 x 7 | committed | Joins W1 (5) |
| 5 | 07:24 | user | `logSet` | entry=E1, 80 x 8 | committed | Joins W1 (5) |
| 6 | 07:31 | tess | `logSet` | entry=E2, 45 x 8 (said "ohp 45 x 8") | committed | Joins W1; Tess counts like the user (2) |
| 7 | 07:35 | user | `logNextSet` | entry=E2, logs 45 x 7 | committed | Joins W1 (5) |
| 8 | 07:42 | user | `logSet` | entry=E3, 30 x 10 | committed | Joins W1 (5) |
| 9 | 07:46 | user | `logNextSet` | entry=E3, logs 30 x 9 | committed | Joins W1 (5) |
| 10 | 08:02 | user | `finishWorkout` | workout=W1 | committed | Ends W1: 52 min (7) |
| 11 | 12:40 | user | `setTaskDone` | task=T1, done=true (ops: `setValue` done=true) | committed | Kept, L2: 1 done, so named (8) |
| 12 | 13:05 | user | `moveTask` | task=T2, to=Thu Sep 17 | committed | Dropped (3) |
| 13 | 17:30 | user | `startShop` | creates P1, subject=Groceries | committed | Kept, L3: shop group start (5) |
| 14 to 27 | 17:32 to 17:50 | user | `checkListItem` x14 | item=G1 to G14, done=true | committed | Join P1 by time window (5) |
| 28 | 17:52 | user | `finishShop` | clears 14, ends P1 | committed | Ends P1; 14 ticked (5, 6) |
| 29 | 21:40 | user | `createNote` | body="shoulder felt fine\nno click on the last set", title from first line | committed | Kept, L4: 1 note, so named (8) |

Expected lines:

```
07:10 Push Day A, 52 min. Bench 82.5 x 8, PR.
12:40 Done: call the bank
17:30 Shopped, 14 items
21:40 Note: shoulder felt fine
```

Notes: the warm-up (row 2) is a set in the group but is never the top set. Bench 82.5 x 8 (e1RM 104.5) beats OHP 45 x 8 and Incline 30 x 10. Rule 9 orders the four lines by start time.

## Day 2: Sun Sep 20, planned rest day, tasks and a cook

Sunday has no slot in the Push Pull Legs plan, so `RestDay.restDay(plan:at:)` answers "rest". That is a read, not a record, so nothing in the story says "rest day".

Lookup: T4 "book the dentist", T5 "renew passport photo", T6 "water the plants", T7 "pay the gas bill", T0 "call mum" (created Sep 18); K1 "dal tadka"; C1 is a cook of K1; KT1 sits under C1; H1, H2, H3 under the list "Home".

| # | Time | Actor | Action | Key fields | State | Rule |
|---|---|---|---|---|---|---|
| 1 | 04:20 | system | `rollForwardTasks` | rolls 2 open tasks to today | committed | Dropped (2: system; also 3) |
| 2 | 08:30 | tess | `createTask` | title="book the dentist", due=Thu | committed | Kept, L1: capture (8) |
| 3 | 08:30 | tess | `createTask` | title="renew passport photo" | committed | Kept, L1 (8) |
| 4 | 08:31 | user | `createTask` | title="water the plants" | committed | Kept, L1 (8) |
| 5 | 09:00 | tess | `createTask` | title="pay the gas bill" (ghost row) | pending | Dropped (2) |
| 6 | 10:05 | user | `setTaskDone` | task=T6, done=true | committed | Kept, L2: done (8) |
| 7 | 11:00 | user | `setTaskDone` | task=T0, done=true | committed | Kept, L2: 2 dones, so both named (8) |
| 8 | 12:15 | user | `startCooking` | recipe=K1, serves=2; creates C1 | committed | Kept, L3: cook group start (5) |
| 9 | 12:18 | user | `goToCookStep` | cook=C1, step=2 | committed | Dropped (3) |
| 10 | 12:25 | user | `startKitchenTimer` | label="simmer", minutes=20, cook=C1; creates KT1 | committed | Dropped (3) |
| 11 | 12:45 | user | `stopKitchenTimer` | timer=KT1 | committed | Dropped (3) |
| 12 | 12:50 | user | `goToCookStep` | cook=C1, step=5 | committed | Dropped (3) |
| 13 | 13:05 | user | `finishCooking` | cook=C1 | committed | Ends C1: 50 min (5, 6) |
| 14 | 18:05 | user | `checkListItem` | item=H1 on Home, done=true | committed | Kept, L4: tick (8) |
| 15 | 18:06 | user | `checkListItem` | item=H2 on Home, done=true | committed | Kept, L4 (8) |
| 16 | 18:30 | user | `moveListItem` | item=H3, index=0 | committed | Dropped (3) |

Expected lines:

```
08:30 Added 3 tasks
10:05 Done: water the plants, call mum
12:15 Cooked dal tadka, 50 min
18:05 Ticked 2 on Home
```

Notes: "water the plants" is created (row 4) and done (row 6) on the same day, so it counts in both the capture and the done line. The pending ghost row (row 5) does not make it "4 tasks". Names in a "Done:" line follow time order.

## Day 3: Wed Sep 30, unfinished workout plus other things

This is the `year-of-data.md` day where one workout is left suspended at set 3. There is no `finishWorkout` and no `finishWorkoutEarly`, so rule 6 shows sets instead of minutes.

Lookup: N2 "slept 5 hours"; W2 "Pull Day A"; T8 "send the invoice"; T4 "book the dentist" (created earlier); K3 "omelette"; C2 a cook of K3. `topSet(W2)` = ("Row 60 x 10", isPR: false).

| # | Time | Actor | Action | Key fields | State | Rule |
|---|---|---|---|---|---|---|
| 1 | 06:45 | user | `createNote` | body="slept 5 hours" | committed | Kept, L1: 1 note (8) |
| 2 | 07:15 | user | `startRoutine` | routine=Pull Day A; creates W2, E1 Row, E2 Pulldown, E3 Curl | committed | Kept, L2: group start (5) |
| 3 | 07:18 | user | `logSet` | entry=E1, 60 x 10 | committed | Joins W2; set 1 (6) |
| 4 | 07:22 | user | `logNextSet` | entry=E1, logs 60 x 9 | committed | Joins W2; set 2 (6) |
| 5 | 07:27 | intent | `logNextSet` | entry=E1, logs 60 x 8 (Action button) | committed | Joins W2; set 3; intent counts (2, 6) |
| 6 | 07:29 | user | `suspendProcess` | the workout process for W2 | committed | Dropped (3) |
| 7 | 09:10 | user | `addGroceries` | lines=["oat milk", "eggs", "spinach"]; creates 3 items under Groceries | committed | Kept, L3: capture (8) |
| 8 | 09:11 | tess | `createTask` | title="send the invoice"; creates T8 | committed | Kept, L3 (8) |
| 9 | 13:00 | user | `setTaskDone` | task=T8, done=true | committed | Kept, L4 (8) |
| 10 | 13:02 | user | `setTaskDone` | task=T4, done=true | committed | Cancelled by row 11 (4) |
| 11 | 13:03 | user | `setTaskDone` | task=T4, done=false (reopen) | committed | Dropped with row 10 (4) |
| 12 | 20:30 | user | `startCooking` | recipe=K3; creates C2 | committed | Kept, L5: cook group (5) |
| 13 | 20:40 | user | `finishCooking` | cook=C2 | committed | Ends C2: 10 min (5, 6) |

Expected lines:

```
06:45 Note: slept 5 hours
07:15 Pull Day A, 3 sets. Row 60 x 10.
09:10 Added 1 task, 3 groceries
13:00 Done: send the invoice
20:30 Cooked omelette, 10 min
```

Notes: the capture line starts at 09:10 (the first capture), and it lists tasks before groceries whatever came first. The 3 grocery items sit under the Groceries list, but no shop is running at 09:10, so they are a capture and not part of a shop. A `finishWorkout` on Oct 1 would still belong to this day (rule 1), and the line would then switch to minutes.

## Day 4: Thu Sep 24, busy day that hits the 6-line cap

Lookup: W3 "Leg Day A"; tasks T11 "pack adapters", T12 "print boarding pass", T13 "order euros", T14 "cancel the milk", T15 "message Ana about keys"; older tasks T16 "return the library book", T17 "top up the Oyster card", T18 "email the landlord"; notes N3 to N6; L1 to L4 under "Lisbon packing" (list created Sep 21); K2 "shakshuka"; C3 a cook of K2; G15 to G26 under Groceries. `topSet(W3)` = ("Squat 100 x 5", isPR: false).

| # | Time | Actor | Action | Key fields | State | Rule |
|---|---|---|---|---|---|---|
| 1 | Sep 24 03:59 | user | `createNote` | body="cant sleep, flight list" | committed | Dropped: belongs to Sep 23 (1) |
| 2 | 05:50 | user | `startRoutine` | routine=Leg Day A; creates W3, E1 Squat, E2 RDL, E3 Lunge | committed | Kept, L1: group start (5) |
| 3 | 05:55 | user | `logSet` | entry=E1, 100 x 5 | committed | Joins W3 (5) |
| 4 | 05:59 | user | `logNextSet` | entry=E1, logs 100 x 5 | committed | Joins W3 (5) |
| 5 | 06:03 | user | `logNextSet` | entry=E1, logs 100 x 4 | committed | Joins W3 (5) |
| 6 | 06:12 | user | `logSet` | entry=E2, 90 x 8 | committed | Joins W3 (5) |
| 7 | 06:16 | user | `logNextSet` | entry=E2, logs 90 x 8 | committed | Joins W3 (5) |
| 8 | 06:25 | user | `logSet` | entry=E3, 24 x 10 | committed | Joins W3 (5) |
| 9 | 06:30 | user | `logNextSet` | entry=E3, logs 24 x 10 | committed | Joins W3 (5) |
| 10 | 06:48 | user | `finishWorkoutEarly` | workout=W3 | committed | Ends W3: 58 min; "early" never shown (7) |
| 11 | 07:05 | user | `rollForwardTasks` | 3 tasks to today | committed | Dropped (3) |
| 12 to 16 | 08:30, 08:30, 08:30, 08:31, 08:31 | tess | `createTask` x5 | T11 to T15 | committed | Kept, L2: capture, 5 tasks (8) |
| 17 | 09:00 | user | `setTaskDone` | task=T16, done=true | committed | Tail: done (8, 10) |
| 18 | 09:40 | user | `setTaskDone` | task=T17, done=true | committed | Tail (8, 10) |
| 19 | 10:15 | user | `createNote` | body="hotel ideas" | committed | Tail: note (8, 10) |
| 20 to 23 | 11:00, 11:03, 11:08, 11:12 | user | `checkListItem` x4 | item=L1 to L4 on Lisbon packing, done=true | committed | Tail: ticks (8, 10) |
| 24 | 12:10 | tess | `addGroceries` | lines=["eggs", "peppers", "feta", "tinned tomatoes"] | committed | Kept, L2: 4 groceries (8) |
| 25 | 12:30 | user | `setTaskDone` | task=T18, done=true | committed | Tail (8, 10) |
| 26 | 13:10 | user | `createRecipe` | title="shakshuka", 8 lines, 5 steps; creates K2 | committed | Kept, L3: own line |
| 27 | 13:25 | user | `editRecipe` | recipe=K2, serves=2 | committed | Dropped (3) |
| 28 | 14:20 | user | `createNote` | body="Ana's address" | committed | Tail (8, 10) |
| 29 | 16:00 | user | `setTaskDone` | task=T14, done=true | committed | Tail (8, 10) |
| 30 | 17:30 | user | `startShop` | creates P2, subject=Groceries | committed | Kept, L4: shop group (5) |
| 31 to 42 | 17:32 to 17:58 | user | `checkListItem` x12 | item=G15 to G26, done=true | committed | Join P2 by time window (5) |
| 43 | 18:05 | user | `finishShop` | clears 12, ends P2 | committed | Ends P2 (5, 6) |
| 44 | 19:15 | user | `startCooking` | recipe=K2; creates C3 | committed | Kept, L5: cook group (5) |
| 45 | 19:20 | user | `startKitchenTimer` | label="simmer", minutes=10, cook=C3 | committed | Dropped (3) |
| 46 | 19:45 | user | `finishCooking` | cook=C3 | committed | Ends C3: 30 min (5, 6) |
| 47 | 22:05 | user | `createNote` | body="gym kit for the hotel" | committed | Tail (8, 10) |
| 48 | Sep 25 01:10 | user | `createNote` | body="remember the charger" | committed | Tail: still Sep 24 before 04:00 (1, 8, 10) |
| 49 | Sep 25 04:00 | user | `createTask` | title="check in online" | committed | Dropped: belongs to Sep 25 (1) |

Before the cap there are 8 candidate lines:

| Time | Candidate | Kind | Count |
|---|---|---|---|
| 05:50 | Leg Day A, 58 min. Squat 100 x 5. | group | n/a |
| 08:30 | Added 5 tasks, 4 groceries | capture | 9 |
| 09:00 | 4 tasks done | done | 4 |
| 10:15 | 4 notes | note | 4 |
| 11:00 | Ticked 4 on Lisbon packing | tick | 4 |
| 13:10 | Saved shakshuka | own line | n/a |
| 17:30 | Shopped, 12 items | group | n/a |
| 19:15 | Cooked shakshuka, 30 min | group | n/a |

Rule 10 as applied here: the cap is 6 lines including the tail, so 5 timed lines fit. Groups and own lines take 4. The one free slot goes to the loose line with the largest count (capture, 9). The rest merge into the tail, in time order of their first record, in lowercase, ending with a period.

Expected lines:

```
05:50 Leg Day A, 58 min. Squat 100 x 5.
08:30 Added 5 tasks, 4 groceries
13:10 Saved shakshuka
17:30 Shopped, 12 items
19:15 Cooked shakshuka, 30 min
Also: 4 tasks done, 4 notes, ticked 4 on Lisbon packing.
```

Notes: "cancel the milk" (T14) is captured at 08:31 and done at 16:00, so it counts in both. With 4 dones the line is a count, not names (3 or more). The tail's `objectIDs` should be the union of its parts, in time order, and its `time` is nil. Squat 100 x 5 (e1RM 116.7) beats RDL 90 x 8 (114.0) and Lunge 24 x 10.

## Day 5: Mon Sep 28, undo churn and edits that all drop out

Everything except the workout cancels, is undone, is pending, is system or is an edit.

Lookup: W4 "Leg Day A"; S2 is the 100 x 5 squat set, edited to 102.5 x 5; T9 "buy chalk"; T10 "stretch hips" (created earlier); K4 "carbonara"; N7 an older note; L5, L6 under Lisbon packing. `topSet(W4)` = ("Squat 102.5 x 5", isPR: false): the undone 1000 x 5 set is soft-deleted, so the ledger never sees it, and S2 is read after the edit. The best squat on file is 105 x 5, so no PR.

| # | Time | Actor | Action | Key fields | State | Rule |
|---|---|---|---|---|---|---|
| 1 | 18:20 | user | `startRoutine` | routine=Leg Day A; creates W4, E1 Squat, E2 RDL | committed | Kept, L1: group start (5) |
| 2 | 18:24 | user | `logSet` | entry=E1, 60 x 8, isWarmup=true | committed | Joins W4 (5) |
| 3 | 18:28 | user | `logSet` | entry=E1, 100 x 5; creates S2 | committed | Joins W4 (5) |
| 4 | 18:31 | tess | `logSet` | entry=E1, 1000 x 5 (misheard "100 x 5") | undone | Dropped (2); would have been a PR |
| 5 | 18:32 | user | `logNextSet` | entry=E1, logs 100 x 5 | committed | Joins W4 (5) |
| 6 | 18:35 | user | `logNextSet` | entry=E1, logs 100 x 5 | undone | Dropped (2) |
| 7 | 18:36 | user | `editSet` | set=S2, weight=102.5 | committed | Dropped (3); the line reads the new value |
| 8 | 18:38 | user | `logNextSet` | entry=E1, logs 100 x 4; undone, then redone | committed | Joins W4: redo restores it (2, 5) |
| 9 | 18:45 | user | `logSet` | entry=E2, 90 x 8 | committed | Joins W4 (5) |
| 10 | 18:49 | user | `logNextSet` | entry=E2, logs 90 x 8 | committed | Joins W4 (5) |
| 11 | 18:53 | user | `logNextSet` | entry=E2, logs 90 x 7 | undone | Dropped (2) |
| 12 | 18:55 | user | `editSet` | set on E2, rpe=8 | committed | Dropped (3) |
| 13 | 19:02 | user | `finishWorkout` | workout=W4 (tapped too soon) | undone | Dropped (2) |
| 14 | 19:08 | user | `finishWorkout` | workout=W4 | committed | Ends W4: 48 min (7) |
| 15 | 19:20 | user | `createTask` | title="buy chalk"; creates T9 | committed | Cancelled by row 16 (4) |
| 16 | 19:21 | user | `deleteObject` | object=T9 | committed | Dropped (3, 4) |
| 17 | 19:30 | user | `addRecipeToGroceries` | recipe=K4, serves=2; creates 6 items under Groceries | committed | Cancelled by row 18 (4) |
| 18 | 19:32 | user | `removeRecipeFromGroceries` | recipe=K4; soft-deletes the 6 items | committed | Dropped (3, 4) |
| 19 | 19:40 | user | `createNote` | body="ideas for Lisbon" | undone | Dropped (2) |
| 20 | 19:45 | user | `editNote` | note=N7, body changed | committed | Dropped (3) |
| 21 | 20:00 | user | `setTaskDone` | task=T10, done=true | committed | Cancelled by row 22 (4) |
| 22 | 20:01 | user | `setTaskDone` | task=T10, done=false | committed | Dropped (3, 4) |
| 23 | 20:10 | tess | `createTask` | title="pay rent" (ghost row) | pending | Dropped (2) |
| 24 | 20:30 | user | `moveListItem` | item=L5, section="Bag" | committed | Dropped (3) |
| 25 | 20:31 | user | `moveListItem` | item=L6, index=0 | committed | Dropped (3) |
| 26 | 20:35 | user | `renameObject` | object=L6, title="universal adapter" | committed | Dropped (3) |
| 27 | 21:00 | system | `createList` | name="Packing" (a starter list seeded at launch) | committed | Dropped (2) |
| 28 | 21:30 | user | `renameListSection` | list=Lisbon packing, from="Misc" to="Bag" | committed | Dropped (3) |

Expected lines:

```
18:20 Leg Day A, 48 min. Squat 102.5 x 5.
```

Notes: 6 sets stand (rows 2, 3, 5, 8, 9, 10), but the workout finished, so the line shows minutes, not sets. Rule 4 for rows 17 and 18 needs no special pairing: each of the 6 items is created and soft-deleted the same day, so the general create plus delete rule cancels them. Taking row 14 away (leaving 13 undone) should turn the line into "18:20 Leg Day A, 6 sets. Squat 102.5 x 5." That makes a good extra test.

## Rule ambiguities found

1. **The shop has no object to group under.** `startShop` runs `StartProcess(subject: Groceries list)`, so grocery items sit under the Groceries list, and so do the items `addGroceries` creates. `groupRoot(of:)` cannot tell a shop tick from a capture. These fixtures group by time window: `checkListItem` on a Groceries item between `startShop` and the `finishShop` (or `endProcess`) of the same process. "N items" counts those committed ticks with done=true. It is not `finishShop`'s cleared count, since `ClearDoneItems` also clears items ticked before the shop started.
2. **Arguments are not stored.** `setTaskDone` done or reopen, `checkListItem` checked or unchecked, and warm-ups can only be read from the record's `setValue` ops (the new value of the Done, Checked or Kind field). The fold needs the field ids, through the lookup or the class catalog.
3. **Capture kinds conflict in the doc.** Tue Oct 6 shows one line ("Added 4 tasks, 3 groceries"), but Thu Oct 8 shows "Added 7 tasks" with "5 groceries" in the tail. These fixtures use one capture line with tasks first, then groceries.
4. **Which loose lines go into the tail.** Rule 10 says the smallest counts go to the tail, but the Oct 8 example keeps "4 tasks done" and tails "5 groceries". These fixtures keep the largest counts and order the tail by first time. Day 4 changes if captures split by kind (see 3).
5. **Case.** The doc writes "Push day A" and lowercases titles after a colon, while `DemoData` stores "Push Day A". These fixtures show titles exactly as stored. A store with "Dal tadka" would read "Cooked Dal tadka, 50 min".
6. **Top set across exercises.** The best raw e1RM across lifts favours high-rep or machine work (leg press 160 x 12 has an e1RM of 224). Day 4 avoids this. A per-workout rule such as "first compound" or "best against its own record" would be safer.
7. **Small gaps:** minute rounding is not stated (all fixtures use whole minutes); singular forms ("1 task") are not shown in the doc; `addListItem` on a normal list has no wording, and `addRecipeToGroceries` has its own wording ("Added groceries for dal tadka") even though it is listed as a capture (these fixtures only use it in a cancelled pair); a task created and done on the same day counts in both lines here; `pending` rows later commit through `commitExpired`, so rule 12 holds only once nothing is pending.
8. **Rest days are not in the log.** A rest day comes from `RestDay.restDay`, not from a record, so any "rest day" header would need that read.

## Swift Testing stubs

Put these in `TesseraCore/Tests/TesseraCoreTests/DayStoryFixtureTests.swift`. `DayFixtures` (a test helper, not shown) builds each day from its table: one `OpRecord(action:actor:summary:ops:state:)` per row with the ops the action would write, then `createdAt` set to the row's time, plus a `FakeDayLookup` holding the titles, group roots and top sets listed above.

```swift
import Foundation
@testable import TesseraCore
import Testing

/// One fixture day from research/fixtures/day-log-days.md.
struct DayFixture {
    let date: Date
    let records: [OpRecord]
    let lookup: FakeDayLookup
}

@Suite("DayStory: five fixture days")
struct DayStoryFixtureTests {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        calendar.firstWeekday = 2
        return calendar
    }()

    /// "HH:mm text" for a timed line; the "Also:" tail has no time.
    static func render(_ lines: [DayLine]) -> [String] {
        lines.map { line in
            guard let time = line.time else { return line.text }
            let parts = calendar.dateComponents([.hour, .minute], from: time)
            let hour = parts.hour ?? 0, minute = parts.minute ?? 0
            let clock = (hour < 10 ? "0" : "") + "\(hour):" + (minute < 10 ? "0" : "") + "\(minute)"
            return clock + " " + line.text
        }
    }

    static func story(_ day: DayFixture) -> [String] {
        render(DayStory.lines(for: day.records, on: day.date, calendar: calendar, lookup: day.lookup))
    }

    @Test("Day 1: push day, a shop and a note")
    func pushDay() throws {
        let expected = [
            "07:10 Push Day A, 52 min. Bench 82.5 x 8, PR.",
            "12:40 Done: call the bank",
            "17:30 Shopped, 14 items",
            "21:40 Note: shoulder felt fine",
        ]
        #expect(try Self.story(DayFixtures.pushDay()) == expected)
    }

    @Test("Day 2: planned rest day with tasks and a cook")
    func restDay() throws {
        let expected = [
            "08:30 Added 3 tasks",
            "10:05 Done: water the plants, call mum",
            "12:15 Cooked dal tadka, 50 min",
            "18:05 Ticked 2 on Home",
        ]
        #expect(try Self.story(DayFixtures.restDay()) == expected)
    }

    @Test("Day 3: unfinished workout shows sets, not minutes")
    func unfinishedWorkout() throws {
        let expected = [
            "06:45 Note: slept 5 hours",
            "07:15 Pull Day A, 3 sets. Row 60 x 10.",
            "09:10 Added 1 task, 3 groceries",
            "13:00 Done: send the invoice",
            "20:30 Cooked omelette, 10 min",
        ]
        #expect(try Self.story(DayFixtures.unfinishedWorkout()) == expected)
    }

    @Test("Day 4: busy day caps at 6 lines with an Also tail")
    func busyDay() throws {
        let expected = [
            "05:50 Leg Day A, 58 min. Squat 100 x 5.",
            "08:30 Added 5 tasks, 4 groceries",
            "13:10 Saved shakshuka",
            "17:30 Shopped, 12 items",
            "19:15 Cooked shakshuka, 30 min",
            "Also: 4 tasks done, 4 notes, ticked 4 on Lisbon packing.",
        ]
        let lines = try Self.story(DayFixtures.busyDay())
        #expect(lines == expected)
        #expect(lines.count <= 6)
    }

    @Test("Day 5: undo churn and edits drop out")
    func undoChurn() throws {
        let expected = [
            "18:20 Leg Day A, 48 min. Squat 102.5 x 5.",
        ]
        #expect(try Self.story(DayFixtures.undoChurn()) == expected)
    }
}
```
