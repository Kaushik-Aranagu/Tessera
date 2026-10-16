# Logs fill habits: 15 days of workouts, cooks and notes (board item 77)

For: Core ("Logs fill habits"), Builder B (habit page, Tess lines). Date: 2026-10-16. Research lab.
Inputs: `../habits.md`, `../m3-1-2-brief.md`, `../m3-lines.md` (A2 to A13, voice and Undo rule), `../day-log-late-night.md`,
`../../product/decisions.md` (5:14, 6:06, 6:37, 6:44, 7:34, 7:40 PM PT). Traced by hand on origin/master `e75f40f`
(15 Oct 19:47 PT). No Swift toolchain, nothing run.

## What master has (field names used below)

- **No `Habit`, `HabitCheckIn`, `HabitLedger` or `CheckInHabit`** in Swift. Shapes are the brief's: `Habit` (`target`,
  `rule` choice `workout`/`cook`, `pausedWeeks` text of Monday dates), `HabitCheckIn` (`habit` ref, `date`).
- `TesseraDay` (`Engine/TesseraDay.swift`): `day(of:)` puts 00:00 to 03:59 on the day before; `week(containing:)` is
  Monday 04:00 to the next Monday 04:00, with `firstWeekday = 2` forced. Use it for every key here.
- Workout: `startedAt`, `endedAt` (`SystemCatalog.swift:126-127`). `finishedWorkouts(onDay:)` keys by
  `TesseraDay.day(of: startedAt)` and needs `endedAt` (`WorkoutSummary.swift:92-120`). `summary(of:).sets` counts
  logged sets only (`loggedSet`).
- Cook: `recipe`, `serves`, `cookedAt`, `note` (`SystemCatalog.swift:252-257`). No `startedAt` on the Cook (the
  process holds it). `FinishCooking` stamps `cookedAt` (`Kitchen/Cooking.swift:222-241`); Tess says "Dal tadka, done."
- Note: `body`, `about` (`SystemCatalog.swift:203-206`). Capture says "Noted." or "Noted, linked."
  (`TessCaptureEngine.swift:136-145`). A note's day is its object's `createdAt` (decision 7:40 PM PT).

## Setup

Zone `America/Los_Angeles` (PDT to 1 Nov 02:00, then PST). Weeks: **W1** Mon 19 Oct to Sun 25 Oct, **W2** Mon 26 Oct
to Sun 1 Nov, **W3** Mon 2 Nov to Sun 8 Nov, each from Monday 04:00. Every habit exists before 19 Oct.

| Habit | `target` | `rule` | Ticks from | Paused |
|---|---|---|---|---|
| Gym | 3 | `workout` | a finished Workout with at least 1 logged set, on its `startedAt` day | W2 (`pausedWeeks` "2026-10-26") |
| Cook | 4 | `cook` | a Cook with `cookedAt`, on its `cookedAt` day | none |
| Read | 5 | none | manual check-in, or a note whose body starts "read {n} {unit}" (open rule 2) | none |

Count rule: per habit, the number of distinct `TesseraDay` days in the week that have a manual check-in or a matching
log. Nothing is stored for a log tick. "x of N" uses the target (decision 7:34 PM PT), never "of 7".

## The 15 days

Times are wall clock. "After" is the count for the week the tick lands in, read right after the line.

### Mon 19 Oct (W1)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 18:05 to 19:10 | Push A finished, 14 sets | Gym | Gym 1 of 3 | "Push A counted for Gym, 1 of 3." |
| 21:30 | note "read 30 pages of Dune before bed" | Read (starts read + number + unit) | Read 1 of 5 | "Note counted for Read, 1 of 5." |

### Tue 20 Oct (W1)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 07:00 to 07:08 | Legs A started and finished, **0 sets logged** | nothing (not trained) | Gym 1 of 3 | "Legs A, no sets, not saved." |
| 19:00 to 19:45 | Cook dal tadka finished | Cook | Cook 1 of 4 | "Dal tadka counted for Cook, 1 of 4." |

### Wed 21 Oct (W1, late night)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 22:50 to Thu 00:40 | Pull A finished, 15 sets | Gym, on **Wed** (`startedAt` day) | Gym 2 of 3 | "Pull A counted for Gym, 2 of 3." |
| Thu 01:10 | note "read 25 pages" | Read, on **Wed** (01:10 is before 04:00) | Read 2 of 5 | "Note counted for Read, 2 of 5." |

### Thu 22 Oct (W1)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 18:30 to 19:10 | Cook ramen finished | Cook | Cook 2 of 4 | "Ramen counted for Cook, 2 of 4." |
| 21:00 | note "Dune is getting slow, Paul meets the Fremen" | nothing (mentions a book, no "read {n}") | Read 2 of 5 | "Noted." |

### Sat 24 Oct (W1, two logs one day)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 10:00 to 11:05 | Legs A finished, 16 sets | Gym, reaches target | Gym 3 of 3 | "Legs A counted for Gym, done for the week." |
| 17:00 to 17:30 | Mobility finished, 6 sets | nothing new (Sat already in) | Gym 3 of 3 | none from habits; the finish's own line only |

### Sun 25 Oct (W1, cook never finished, late cook)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 11:00 | StartCooking shakshuka, never finished (no `cookedAt`) | nothing | Cook 2 of 4 | nothing from habits |
| 22:00 | "✓ read" | Read (manual) | Read 3 of 5 | "Read, 3 of 5 this week." |
| 23:45 to Mon 00:30 | Cook chilli finished at Mon 00:30 | Cook, on **Sun** and **W1** | Cook 3 of 4 | "Chilli counted for Cook, 3 of 4." |

W1 closes: Gym 3 of 3 (met), Cook 3 of 4, Read 3 of 5. At Mon 00:30 the page still shows W1; it turns at 04:00.

### Mon 26 Oct (W2, Gym paused)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 07:00 | "habit read" | Read | Read 1 of 5 | "Read, 1 of 5 this week." |
| 08:00 | hold Gym's count to pause | none | Gym "paused" | "Gym paused this week." (UNDO 4 s: "Gym pause taken back.") |

### Tue 27 Oct (W2, a log in a paused week)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 18:00 to 18:40 | Push A finished, 13 sets | Gym Tue is in; week stays out of history | Gym "paused" | "Push A counted for Gym. The week stays paused." |
| 19:00 to 19:30 | Cook dal tadka finished | Cook | Cook 1 of 4 | "Dal tadka counted for Cook, 1 of 4." |

### Thu 29 Oct (W2, manual tick plus a log)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 07:30 | "✓ read" | Read | Read 2 of 5 | "Read, 2 of 5 this week." |
| 18:20 to 19:00 | Cook ramen finished | Cook | Cook 2 of 4 | "Ramen counted for Cook, 2 of 4." |
| 22:15 | note "read 40 pages" | nothing new (Thu already in) | Read 2 of 5 | "Noted." |

### Sat 31 Oct (W2, undo removes the tick; fall-back night)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 19:30 to 20:15 | Cook pasta finished | Cook | Cook 3 of 4 | "Pasta counted for Cook, 3 of 4." |
| 20:15 (+2 s) | UNDO on that line (`cookedAt` cleared) | Cook Sat gone | Cook 2 of 4 | "Pasta taken back. Cook 2 of 4." |
| Sun 01:30 PST (09:30Z) | note "read 20 pages", at the second 01:30 | Read, on **Sat** (the day runs 25 h) | Read 3 of 5 | "Note counted for Read, 3 of 5." |

### Sun 1 Nov (W2, a tick at 03:50 Monday)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 11:00 to 11:40 | Cook shakshuka (a new Cook) finished | Cook | Cook 3 of 4 | "Shakshuka counted for Cook, 3 of 4." |
| Mon 03:50 | "✓ read" | Read, on **Sun** and **W2** | Read 4 of 5 | "Read, 4 of 5 this week." |

W2 closes: Gym paused (1 day in, left out of history), Cook 3 of 4, Read 4 of 5.

### Mon 2 Nov (W3, manual tick then a log, no double count)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 07:00 | "habit gym" (a class he did not log) | Gym (manual) | Gym 1 of 3 | "Gym, 1 of 3 this week." |
| 18:00 to 19:00 | Push A finished, 14 sets | nothing new (Mon already in) | Gym 1 of 3 | none from habits; the finish's own line only |

If that finish is undone, the manual check-in keeps Monday: "Push A taken back. Gym 1 of 3." (test only, not on the day).

### Wed 4 Nov (W3)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 17:30 to 18:40 | Legs A finished, 16 sets | Gym | Gym 2 of 3 | "Legs A counted for Gym, 2 of 3." |
| 19:20 to 20:00 | Cook dal tadka finished | Cook | Cook 1 of 4 | "Dal tadka counted for Cook, 1 of 4." |

### Fri 6 Nov (W3)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 07:00 to 08:00 | Pull A finished, 15 sets | Gym, reaches target | Gym 3 of 3 | "Pull A counted for Gym, done for the week." |
| 18:50 to 19:30 | Cook ramen finished | Cook | Cook 2 of 4 | "Ramen counted for Cook, 2 of 4." |
| 23:10 | note "read 30 pages" | Read | Read 1 of 5 | "Note counted for Read, 1 of 5." |

### Sat 7 Nov (W3, past the target, two cooks)
| Time | Log | Ticks | After | Tess says |
|---|---|---|---|---|
| 11:00 to 12:00 | Push A finished, 14 sets | Gym, past target | Gym 4 of 3 | "Push A counted for Gym, 4 this week." |
| 18:00 to 18:50 | Cook chilli finished | Cook | Cook 3 of 4 | "Chilli counted for Cook, 3 of 4." |
| 21:00 to 21:40 | Cook curry finished | nothing new (Sat already in) | Cook 3 of 4 | "Curry, done." (no habit line) |
| 22:30 | "✓ read" | Read | Read 2 of 5 | "Read, 2 of 5 this week." |

## Week totals and history (read Sat 7 Nov 23:00)

| Habit | W1 | W2 | W3 so far | `lastWeeks(3)` | History line (H6) |
|---|---|---|---|---|---|
| Gym (3) | 3 of 3, met | paused (1 day) | 4 of 3, met | met in 2 of 2 (W2 left out) | "Met in 2 of the last 2 weeks." |
| Cook (4) | 3 of 4 | 3 of 4 | 3 of 4 | met in 0 of 3 | none (H6 needs 1 met week) |
| Read (5) | 3 of 5 | 4 of 5 | 2 of 5 | met in 0 of 3 | none |

Never ticks: the 0-set Legs A (Tue 20 Oct), the unfinished shakshuka (Sun 25 Oct), the book-only note (Thu 22 Oct), the
pasta after UNDO (Sat 31 Oct). Never double: Sat 24 Oct Gym, Thu 29 Oct Read, Mon 2 Nov Gym, Sat 7 Nov Cook.

## Swift Testing names, Core's "Logs fill habits"

`TesseraCore/Tests/TesseraCoreTests/HabitsFromLogsTests.swift`. Build `Calendar(identifier: .gregorian)` with `timeZone`
`America/Los_Angeles` and pass it in (never `.current`); instants above in UTC; write through `ActionEngine` so undo is real.

- Counting: `finishedWorkoutTicksGymOnStartedAtDay`, `finishedCookTicksCookOnCookedAtDay`,
  `fifteenDaysGiveTheWeekTotalsTable` (parameterized by habit and week), `noCountIsWrittenToTheStore`
- Not trained: `workoutWithNoLoggedSetNeverTicks` (even with `endedAt` set), `cookWithoutCookedAtNeverTicks`
- One per day: `twoWorkoutsOneDayCountOnce`, `twoCooksOneDayCountOnce`, `manualCheckInAndLogSameDayCountOnce`,
  `noteAfterManualReadSameDayCountsOnce`
- Undo: `undoFinishCookingRemovesTheTick` (Cook 3 to 2 of 4), `undoFinishWithManualCheckInKeepsTheDay` (Gym stays 1)
- 4 AM day: `workoutFrom2250To0040TicksStartDay`, `noteAt0110TicksDayBefore`, `cookFinished0030MondayCountsInWeekBefore`,
  `checkInAt0350MondayCountsInWeekBefore`, `fallBackSecond0130NoteTicksSaturday`, `weekStartsMonday0400NotMidnight`
- Pause: `logInPausedWeekStillMarksTheDay`, `pausedWeekLeftOutOfLastWeeks` (Gym 2 of 2)
- Notes: `noteStartingReadNumberUnitTicksRead`, `noteMentioningABookDoesNotTick`, `editingTheNoteBodyDropsTheTick`
- Lines: `tessLineNamesSourceThenHabitAndCount` (table of every line above), `targetReachedSaysDoneForTheWeek`,
  `pastTargetSaysNThisWeek`, `secondLogSameDayAddsNoHabitLine`, `pausedWeekLineSaysWeekStaysPaused`

## Open rules (defaults taken, nothing blocked)

1. **Week edge.** `habits.md` says Monday 00:00; `TesseraDay.week(containing:)` starts Monday 04:00. Default: 04:00, so
   Mon 00:30 and 03:50 count for last week (decision 6:07 PM PT, one rule for every surface).
2. **Which notes tick Read.** Default: a note ticks a habit only when its body starts with the habit's name (any of
   "read", "reading") then a number and a unit word ("30 pages", "20 min"), the same shape as the brief's grammar row
   "read 20 pages". A note that only mentions a book never ticks. Counted on read like rule logs, keyed by the note
   object's `createdAt` day, so editing or deleting the note drops the tick. Needs no `rule` value.
3. **Second log the same day.** Default: no habit line at all; the finish keeps its own line ("Curry, done.").
   Alternative: "Read is already in for today." (A6), which is noise after a workout.
4. **Log in a paused week.** Default: the day is marked, the count shows "paused", the week stays out of `lastWeeks`,
   and the line is "{source} counted for {habit}. The week stays paused." (A7's form).
5. **Cook day.** Default: `TesseraDay.day(of: cookedAt)`, since the Cook has no `startedAt`. A cook from 23:45 to 03:50
   is the same day either way; only a cook running past 04:00 would differ.
6. **Rule tick when target is met or passed.** Default: "Legs A counted for Gym, done for the week." and "Push A counted
   for Gym, 4 this week." (A4 and A5 with the source named first).
7. **Undo with a manual check-in the same day.** Default: the count stays, and the line still carries it: "Push A taken
   back. Gym 1 of 3." (A9).

## Gaps on master

- No `Habit`, `HabitCheckIn`, `HabitLedger`, `CheckInHabit` or `PauseHabitWeek`; no habit grammar ("✓ read", "habit gym").
- `FinishWorkout` writes `endedAt` even with 0 logged sets, and `finishedWorkouts(onDay:)` returns that workout. Only
  the 6-hour wrap-up deletes an unlogged workout (`ProcessTable.swift:124-128`). The habit query must check
  `summary.sets >= 1`, and "Legs A, no sets, not saved." (decision 5:14 PM PT) has no code on master.
- No note-to-habit match exists (open rule 2), and no stored zone per log, so the fall-back note relies on the wall clock.
