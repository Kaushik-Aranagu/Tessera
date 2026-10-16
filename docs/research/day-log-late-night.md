# Day log after midnight: 6 synthetic days (board item 72)

For: Core (`DayStory`), Builder B (page). Date: 2026-10-16. Copy from `day-log-copy.md` (Product took its defaults at
7:34 PM PT: column "07:10", 24 h; inside sentences and VoiceOver "6:12 pm"). Rules from `late-night.md` S8,
`day-boundary.md`, `fixtures/dst-travel.md` (rules 1 to 8), `day-log-first.md` (folding rules 1 to 12).
Traced by hand on origin/master 21f335a (15 Oct 19:33 PT). No Swift toolchain, nothing run.

## What master has

- **No `DayStory`, `DayLine` or `Features/DayLog/`** (`git ls-tree` and `git grep DayStory` find nothing). So each day
  below is traced against the obvious calendar-day fold: `day-log-first.md` rule 1 written as
  `calendar.startOfDay(for: record.createdAt)` on `OpRecord`s, grouped per day, then rules 2 to 12.
- `TesseraDay.day(of:)` (`Engine/TesseraDay.swift:22-26`) reads the wall-clock hour: hour < 4 is the day before. DST
  is right for free. `RollForwardTasks.logicalDay` now calls it (`Tasks/RollForward.swift:71-73`), so dst-travel D17 is fixed.
- Stored times are plain `Date`s (seconds since 2001), no zone field. `OpRecord.createdAt` is `.now` at perform
  (`Model/Models.swift:521`, `Actions/ActionEngine.swift:52-58`); set `loggedAt` `.now`, `doneAt` `time ?? .now`,
  workout `startedAt`/`endedAt` (`Actions/TrainingActions.swift:67, 420, 200-201, 230-233`).
- A past-dated note moves only the **object's** `createdAt` to its `on` date (`Notes/Notes.swift:106-108`); its
  `OpRecord.createdAt` stays the moment he said it.
- Workouts already bucket right: `finishedWorkouts(onDay:)` keys by `TesseraDay.day(of: startedAt)`, cached per
  revision and zone (`Training/WorkoutSummary.swift:92-101`). Done tasks: `Tasks.swift:41-45` uses the 04:00 interval.
- Column clock: `Format.clock` is `Calendar.current` hour and minute, "%02d:%02d" (`App/AppClock.swift:47-50`).

Zone is Los Angeles unless said. Blocks show the right page; "Calendar fold" is the trace.

## Day 1. Wed 21 Oct: a set at 00:40 inside a workout started 23:20
Records: 19:05 two `createTask`; Push Day B `startWorkout` 23:20, sets 23:28 to 23:58, set Thu 00:40 (Incline 30 × 10,
a PR), `finishWorkout` Thu 00:52.
```
WED 21
19:05  Added 2 tasks
23:20  Push Day B, 92 min. Incline 30 × 10, PR.
```
VoiceOver: "11:20 pm, Push Day B, 92 minutes. Incline 30 by 10, PR." Seen live at 00:45 (state 11): the block is
still TODAY, line "23:20  Push Day B, 5 sets"; at 04:00 it relabels WED 21 without moving.
**Calendar fold: wrong day, and split.** The 00:40 set and the finish have `createdAt` on Thu 22, so WED 21 gets
"23:20  Push Day B, 4 sets. Incline 27.5 × 10." (no finish in its records) and THU 22 gets a second line for the same
workout, "00:40  Push Day B, 92 min. Incline 30 × 10, PR." At 00:45 TODAY is already Thu and the running line sits
under it. Master's ledger has it right on Wed (`WorkoutSummary.swift:100-101`), so Day log and Home would disagree.

## Day 2. Thu 22 Oct: a note at 02:10, and one said for "yesterday"
Records: 08:30 `setTaskDone` call the bank; Fri 02:10 `createNote` "hotel ideas"; Fri 02:12 `createNote`
"watered the plants yesterday" with `on` = Wed 21 12:00 (logical today is Thu, so yesterday is Wed; Tess's 12:00, C4).
```
THU 22
08:30  Done: call the bank
02:10  Note: hotel ideas
```
and on WED 21 (Day 1), sorted by instant, a new first line: `12:00  Note: watered the plants`.
**Calendar fold: two wrong days.** "hotel ideas" lands on FRI 23 at 02:10. The past-dated note lands on FRI 23 at
02:12, because the fold reads the record's time, not the note's `on`. Even with `TesseraDay` on `OpRecord.createdAt`
it lands on Thu 22, one day late. Fix: date a note by its object's `createdAt` (`Notes.swift:107`), not its record.

## Day 3. Fri 23 Oct: a task finished at 03:55
Records: 18:40 to 19:20 cook ramen; Sat 03:55 `setTaskDone` pay rent.
```
FRI 23
18:40  Cooked ramen, 40 min
03:55  Done: pay rent
```
**Calendar fold: wrong day.** "03:55  Done: pay rent" moves to SAT 24, above Saturday's morning lines. Home's done
list on master counts it on Friday (`Tasks.swift:44-45`), so again two screens disagree.

## Day 4. Sat 24 Oct: a capture at 04:05, and a workout from 03:50 to 04:30
Records: Sat 04:05 `createTask` (1); 11:30 shop finished, 14 items; Sun 03:50 Pull Day A `startWorkout`, one set at
03:58, four sets 04:02 to 04:25 (top Row 60 × 10), `finishWorkout` 04:30.
```
SAT 24
04:05  Added 1 task
11:30  Shopped, 14 items
03:50  Pull Day A, 40 min. Row 60 × 10.
SUN 25        (empty, 45%, unless Sunday adds something)
```
Seen live at 04:10: TODAY is Sun 25 and is empty; the running "03:50  Pull Day A, 2 sets" sits on SAT 24 (start day).
**Calendar fold:** the 04:05 capture is right (Sat). The whole workout is **wrong**: 03:50 is after midnight, so it
reads "03:50  Pull Day A, 40 min. Row 60 × 10." first on SUN 25. A `TesseraDay` fold per record (not per group root)
is also wrong: SAT 24 gets "03:50  Pull Day A, 1 set. Row 55 × 10." and SUN 25 "04:02  Pull Day A, 40 min..."
Fix: a group takes its root's `startedAt` day, as `WorkoutSummary.swift:101` does.

## Day 5. Mon 26 Oct: travel night, LA to New York (dst-travel trip)
Records: 07:30 PDT done water the plants; Mobility 21:40 to 22:15 PDT, finished at the gate; in flight, phone still
on PDT, Tue 01:30 PDT (08:30Z) note "seat 14C, no sleep"; landed, Tue 06:55 EDT `createTask` (2).
Read in LA at 22:20 PDT: TODAY, `07:30  Done: water the plants`, `21:40  Mobility, 35 min`. Read in New York, Tue 07:00 EDT (times in the current zone, days in the zone each item was logged, dst-travel rule 7):
```
MON 26
10:30  Done: water the plants
00:40  Mobility, 35 min
04:30  Note: seat 14C, no sleep
TODAY
06:55  Added 2 tasks
```
**Master's fallback (no stored zone, `TesseraDay` in the current zone):** the note is 04:30 EDT, so it moves to Tue 27
as "04:30  Note: seat 14C, no sleep" above 06:55. **Wrong day** until a zone is stored (dst-travel Q1). Mobility
(00:40 EDT) stays Monday. **Calendar fold in EDT:** Mobility and the note both move to TUE 27 (wrong). In LA, before
landing, the note is already on Tue 27 (wrong).

## Day 6. Sat 31 Oct: DST fall back, two 01:30s on 1 Nov
Records: 20:00 to 20:50 PDT cook dal tadka; Push Day B 00:50 PDT (07:50Z) to 01:20 PST (09:20Z), top Bench 82.5 × 8;
note "hall light out" at the first 01:30 (PDT, 08:30Z); `setTaskDone` bins at the second 01:30 (PST, 09:30Z).
```
SAT 31
20:00  Cooked dal tadka, 50 min
00:50  Push Day B, 90 min. Bench 82.5 × 8.
01:30  Note: hall light out
01:30  Done: bins
```
The day runs 25 h (Sat 11:00Z to Sun 12:00Z). Both 01:30s print "01:30", in instant order, no zone tag.
**Calendar fold: wrong day** for the last three (all on SUN 1). Two more traps: minutes from wall clock
(01:20 minus 00:50) give "30 min", not 90; and a sort or key on the "HH:mm" text puts the two 01:30s together or
merges them. Sort and measure on `Date`.

## Wrong-day cases (calendar fold unless said)

| # | Day | Item | Right | Goes to |
|---|---|---|---|---|
| 1 | 1 | Push Day B 23:20 to 00:52 | WED 21, one line | split: WED 21 sets line plus THU 22 finished line |
| 2 | 2 | Note 02:10 | THU 22 | FRI 23 |
| 3 | 2 | Note "yesterday" at 02:12 | WED 21, 12:00 | FRI 23 (calendar), THU 22 (`TesseraDay` on the record) |
| 4 | 3 | Done 03:55 | FRI 23 | SAT 24 |
| 5 | 4 | Pull Day A 03:50 to 04:30 | SAT 24 | SUN 25 (calendar); split SAT/SUN (`TesseraDay` per record) |
| 6 | 5 | Mobility 21:40 PDT read in NY | MON 26 | TUE 27 (calendar in EDT) |
| 7 | 5 | In-flight note 01:30 PDT | MON 26 | TUE 27 (calendar, and master's no-zone fallback) |
| 8 | 6 | Workout, note, done after 00:00 | SAT 31 | SUN 1 (and "30 min" if measured on the wall clock) |

Right in every fold: the 04:05 capture, all lines before midnight. Only #7 survives a correct fold (needs a zone).

**Open (defaults):** a workout running past 04:00 stays on its start block, not TODAY (Day 4). Monday read in New
York prints "10:30, 00:40, 04:30" (Day 5): accept until a zone is stored, then print the logged zone's times.

## Swift Testing names, Core's Day log v1

`TesseraCore/Tests/TesseraCoreTests/DayStoryLateNightTests.swift`. Every test builds
`Calendar(identifier: .gregorian)` with `timeZone` set to `America/Los_Angeles` or `America/New_York` and passes it in;
never `.current`. Records and objects come from the instants above in UTC; a fake `DayLookup`.

- Day 1: `setAfterMidnightStaysInWorkoutStartedBefore`, `workoutAcrossMidnightShowsAbsoluteMinutes` ("92 min"),
  `runningWorkoutAt0045IsUnderToday` (sets form, no minutes)
- Day 2: `noteAt0210BelongsToEveningBefore`, `pastDatedNoteUsesItsOnDateNotRecordTime` (Wed 21, 12:00)
- Day 3: `taskDoneAt0355IsOnDayBefore`
- Day 4: `captureAt0405OpensTheNewDay`, `recordsAt035959And040000FallOnEitherSide`,
  `workoutStarted0350FinishedAfter0400StaysOnStartDay` (Sun 25 empty), `groupDayComesFromRootNotEachRecord`
- Day 5: `redEyeTimesPrintInCurrentZone` ("21:40" in LA, "00:40" in NY), `redEyeWorkoutStaysOnMondayInNewYork`,
  `inFlightNoteKeepsLoggedZoneDay` (`withKnownIssue` until a zone field exists)
- Day 6: `fallBackNightPrintsTwo0130LinesInInstantOrder`, `fallBackWorkoutMinutesAreAbsolute` (90, not 30),
  `fallBackNightIsOneDayOf25Hours` (nothing before 12:00Z on 1 Nov lands on Sun 1)
- Format: `columnClockIsTwentyFourHourZeroPadded` ("00:40"), `voiceOverTimeIsSentenceForm` ("11:20 pm, ...")
- Cache: `zoneSwapWithoutWriteRebucketsDays` (same records, LA then NY calendar, no stale keys)
