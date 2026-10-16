# QA review: PR #363, plan days and WeekFacts lows (Core)

Head `c55d623263ad724b323dd836f9e68bdfbcb3003b` (core/plan-days-2, off master f2f10f9). Static review; Core reports
421 package tests green on the Mac. Trial merge onto master: clean. 6 files, +188/-42, engine and tests only: no app
code, no catalog bump, no migration, no flags.

## Verdict: PASS

## Acceptance rows
- **Product: Drop clears the routine's days.** `DropRoutineFromPlan` sets `fixedWeekdays` to nil in the same
  transaction, so UNDO brings the days back with the routine. Test `droppingClearsDaysAndReAddingReconciles`.
- **Product: Add reconciles newer-pick-wins.** `AddRoutineToPlan` now returns `[WeekdayHandoff]` from the shared
  `PlanSchedule.take`, the same code `SetRoutineWeekdays` uses, so a routine arriving with days takes them and the
  result names who lost which day (test: Thursday handed from the first routine). #359's only caller
  (RoutinesPage.swift:143) reads `.record` / `.output` generically, so the Void → array change compiles there.
- **Fixed mode with no days rolls on.** `hasFixedDays` gates both `nextRoutine` and `week(containing:)`; summary
  "Push A, no fixed days." Test `fixedModeWithNoDaysRollsOn`.
- **Research R1.** One best per exercise across the week (`records` de-duplicated on the short name).
- **Research R2.** When this week has no day for the next routine, the next week is searched (Sunday → Monday). Test
  `nextDayLooksIntoNextWeek`.
- **Research R5 / Product 3113e2f.** A first use at or after 17:00 leaves that day before first use unless he trained
  that day; then it counts and is due. Test `aLateFirstUseIsNotDueUnlessHeTrained`.
- **#348 lows.** `bestLines` ranks on the objects (a workout with a `wasRecord` set, then a routine, list, recipe or
  plan created this week, then other workouts), not the wording; `firstUse` cached per store revision; `hasEnded`
  counts calendar days; `nextRoutine` gets `now` and `calendar`.
- **T11/T12** are #359's UI checks (hold-release, one tick per day tap); nothing here changes them.

## Lows
- **L1. Two words for the same moment.** Core's summary is "Push A, no fixed days." while #359's Tess line for
  the same tap is "Push A has no fixed day." (RoutineEditor.swift:529, `receipt`). Design picks one; the other
  follows. This is the one visible string, as the brief said.
- **L2.** With FIXED DAYS on and no routine holding a day, the engine now rolls on, but the plan line still reads
  "fixed days". That is my #359 L5; Tess's line could say "Pick a day." until one is picked.
- **L3.** R1 keeps only the first kind per exercise, so a squat 5RM and e1RM on the same week show as one
  "Squat" record of the first kind. Research asked to keep the kinds for Review's band; fine for the line count.
- **L4.** R2 searches the next calendar week, not "the next 7 days" as the comment says: on a Monday it can reach 13
  days out. Harmless for the line; fix the comment or the window.
- **L5.** `firstUseCache` is a process-wide static keyed by `ObjectIdentifier(store.context)` plus revision. A test
  store created at a reused address with the same revision would get the old answer. Same pattern as #356's
  `lastTurnoverDay`. Keying on a per-context token would remove it.
- **L6.** `take` walks `siblings(of:)`, so a routine in two plans takes and drops days across both. There's one plan
  today.
