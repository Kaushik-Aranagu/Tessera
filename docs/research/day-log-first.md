# Day log, first cut (M4 slice 5, smallest form)

For: Core engine, Builder B, Product. Date: 2026-10-15
Inputs: `../product/ship-list-m4.md` slice 5, `day-log.md`, `shutdown-daylog-copy.md`, `tess-voice.md`, and `Op.swift`, `Models.swift` (`OpRecord`), `ActionEngine.swift`, `ActionRegistry.swift` on origin/master (5258866).

## What the op log holds today

Two levels. An `OpRecord` is one named action (`action`, `actor`, `state`, `summary`, `createdAt`, `ops`, `objectIDs`). Inside it, `ops` lists 7 primitive `Op` cases: `create`, `softDelete`, `restore`, `setTitle`, `setSortIndex`, `setValue`, `setLinks`. Primitives say what bytes changed, not what happened, so none of them reads as a story line on its own. **The Day log folds `OpRecord`s by `action` name and looks inside `ops` only to find objects.** `OpState` is `committed`, `pending` (a ghost row) or `undone`. Undo writes no new record: it flips the same record to `undone`, and redo flips it back, so an undo pair is already one record and the fold just drops `undone`. `Actor` is `user`, `tess`, `intent` or `system` (seeding, migration). Master has no `DayNote`, calendar `Event` or Health mount yet.

## The 50 actions on master

| Action(s) | Story? | How |
|---|---|---|
| `startWorkout`, `startRoutine`, `logSet`, `logNextSet`, `logExercise`, `addExercise`, `swapExercise`, `finishWorkout`, `finishWorkoutEarly` | Fold | One workout line: name, minutes, top set or PR. "Early" is never shown |
| `startCooking`, `finishCooking` | Fold | "Cooked carbonara, 35 min" |
| `startShop`, `finishShop`, plus grocery `checkListItem` in between | Fold | "Shopped, 14 items" |
| `createTask`, `addGroceries`, `addRecipeToGroceries`, `addListItem` | Fold | One capture line: "Added 4 tasks, 3 groceries" |
| `setTaskDone` (done) | Fold | 1 or 2: "Done: call the bank"; 3 or more: "5 tasks done" |
| `checkListItem` (checked, not groceries) | Fold | "Ticked 6 on Lisbon packing" |
| `createNote` | Fold | 1: "Note: hotel ideas"; 2 or more: "3 notes" |
| `createRecipe`, `createList`, `createRoutine`, `createPlan` | Own line | A new thing: "Saved dal tadka", "New list: Lisbon packing" |
| `editSet`, `editRecipe`, `editNote`, `renameObject`, `renameListSection`, `moveListItem`, `clearDoneItems`, `addSlot`, `moveSlot`, `editSlot`, `removeSlot`, `swapSlotExercise` | Drop | Edits, reorders, tidying, plan editing; lines read current values anyway |
| `deleteObject`, `removeRecipeFromGroceries`, `setTaskDone` (reopen) | Drop | Same day, they cancel their pair (rule 4) |
| `moveTask`, `rollForwardTasks`, `waitOnTask`, `startTask` | Drop | Moving or starting is not doing, and can read as debt |
| `goToCookStep`, `startKitchenTimer`, `stopKitchenTimer`, `startProcess`, `saveContext`, `suspendProcess`, `resumeProcess`, `endProcess` | Drop | Steps inside a cook, and plumbing for Now |

So 20 actions fold into a line, 4 get their own line, and 26 drop (`setTaskDone` and `checkListItem` sit in two rows, by argument).

## Folding rules, in order

1. **Pick the day.** A record belongs to the day of `createdAt` in the phone's time zone, with days starting at 04:00 (as in Shutdown). A workout belongs to the day it started.
2. **Keep what stands.** Drop `pending`, `undone` and `actor == .system` records. Tess, intent and user count the same.
3. **Drop the 26 edit and plumbing actions.**
4. **Cancel same-day pairs.** An object created and soft-deleted the same day drops both. Same for done then reopened, and a recipe added to groceries then removed.
5. **Group processes.** Records whose objects sit under one workout, cook or shop join that group. A group is one line at its start time.
6. **Skip empty groups.** A workout with 0 sets, a cook or shop with no finish: no line. A workout with sets but no finish shows sets instead of minutes.
7. **Fill the workout line.** "{name}, {min} min. {top set}." Top set is the best by e1RM. If a set beat a record (`TrainingLedger.recordsBeaten`), name that set and add "PR".
8. **Count the loose items.** Leftover dones, captures, notes and ticks fold into one line per kind, at the time of the first one.
9. **Order by time**, oldest first, with the start time as "07:10".
10. **Cap at 6 lines.** Keep groups and own lines first, then merge the smallest counts into one tail: "Also: 2 notes, 4 groceries."
11. **Empty days show only the date.** A run of them collapses to one row, "Oct 1 to 4". Empty days are never counted.
12. **Same input, same lines.** No randomness, so a past day reads the same on every scrub.

## Ten days, rendered

Voice from `tess-voice.md`: past tense, digits, units once, under 12 words a line, no praise, no "only", no "missed", no colour. Nothing grades the day. Notes in brackets explain the fold and are not shown.

```
Tue Oct 13  (gym day)
07:10  Push day A, 52 min. Bench 82.5 x 8, PR.
12:40  Done: call the bank
19:30  Cooked carbonara, 35 min
Wed Oct 14  (rest day)
09:15  Added 3 tasks
18:05  Ticked 2 on Home
21:40  Note: shoulder felt fine
Sat Oct 10  (cook and shop day)
10:20  Saved dal tadka
10:25  Added groceries for dal tadka
11:30  Shopped, 14 items
18:45  Cooked dal tadka, 50 min
Thu Oct 8  (chaotic day, 31 records)
06:50  Pull day, 61 min. Row 70 x 10.
08:30  4 tasks done
09:00  Added 7 tasks
13:15  New list: Lisbon packing
17:40  Cooked omelette, 10 min
       Also: 3 notes, 5 groceries, ticked 4 on Lisbon packing.
Fri Oct 9  (near-empty day)
20:10  Done: renew passport photo
Mon Oct 5  (undo churn: 11 sets with 3 undone, 2 edits, a task made and deleted, 2 reorders)
18:20  Legs, 48 min. Squat 100 x 5.
Sun Oct 11  (travel day)
07:05  Ticked 9 on Lisbon packing
07:30  Done: water the plants
14:55  Note: gate B32, seat 14C
22:10  Added 2 tasks
Oct 1 to 4  (empty run: one thin row, no lines)
Tue Oct 6  (mostly Tess; 2 dismissed ghost rows; workout never finished)
08:05  Added 4 tasks, 3 groceries
12:30  Pull day, 9 sets. Curl 14 x 12.
16:00  Done: send the invoice, book the dentist
Wed Oct 7  (late night: workout 23:20 to 00:35 stays on Wednesday)
19:00  Cooked ramen, 40 min
23:20  Push day B, 75 min. Incline 30 x 10, PR.
```

## Left out of v1

- **Undo from a past day.** Lines link to their object; undo stays where it lives today. **"today: ..." and `DayNote`.** No class on master; make it slice 5b. **Health, calendar and "Travel day".** Slices 1 and 2 aren't on master; travel can't be told from a busy day without them.
- **The Tess line (slot A), Shutdown counts, per-day cache, scrubber rail, "on this day", focus blocks.** Slot A and Shutdown read this fold later; fold on read for now, since a year of records is small.

## Smallest Core slice

`TesseraCore/Sources/TesseraCore/DayLog/DayStory.swift`: pure, no store writes, no UI.

```swift
public struct DayLine: Equatable, Sendable {  // time nil for the "Also:" tail; tap opens objectIDs.first
    public let time: Date?; public let text: String; public let objectIDs: [UUID]
}
public protocol DayLookup {       // a fake in tests; ObjectStore + TrainingLedger in the app
    func title(of id: UUID) -> String?
    func groupRoot(of id: UUID) -> UUID?   // the workout, cook or shop above this object
    func topSet(inWorkout id: UUID) -> (text: String, isPR: Bool)?
}
public enum DayStory {
    public static func dayStart(for date: Date, calendar: Calendar) -> Date  // 04:00 rule
    public static func lines(for records: [OpRecord], on day: Date, calendar: Calendar, lookup: some DayLookup) -> [DayLine]
}
```

Done when (Swift Testing, `swift test` in `TesseraCore/`):
1. The 10 days above, built as records and a fake lookup, give exactly the lines shown. Each of the 26 drop actions alone gives `[]`; `pending`, `undone` and `system` records give `[]`; undo then redo brings the line back.
2. Create plus delete on one day gives `[]`; across two days, the create stays on day 1. A workout from 23:20 to 00:35 lands on its start day; a record at 03:59 lands on the day before.
3. 20 loose items give at most 6 lines, the last starting "Also:". Every line is under 12 words, with no "!", "only", "missed", "should" or "streak".
4. A new action in `ActionRegistry` without a fold rule fails a test.

## Screen hook for Builder B

`Features/DayLog/`: call `DayStory.lines(for: engine.history(limit: .max), on: day, calendar: .current, lookup: store)` per day, and refresh when `ActionEngine.observe` fires. One vertical list, today at the bottom, pull down for the past (default in `day-log.md`). Each day: the date, then its lines with times in a quiet column; empty runs are one thin row. Tapping a line opens `objectIDs.first`. No red, no badges, no count of empty days. Rough is fine; the Design studio pass comes after.
