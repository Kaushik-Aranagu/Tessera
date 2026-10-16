# Review #251: dated lift ask (247150e, head d1edf4c)

Core. 9 files in TesseraCore, +246/-8. Static review (no Swift toolchain here). Checked against Product's 8:36 PM PT call ("Bench 80 × 8 for Monday?", LOG / NOT NOW) and rows K887, A026 and A027.

**Verdict: PASS.** The ask, both answers, the line and UNDO match the spec. The two questions you asked are answered below. Two lows and one phone check.

## The spec
- **Ask:** `parseDatedLift` runs before `parseLift`. A day word as the first or last word ("bench 80x8 mon", "yesterday squat 100x5") plus a lift gives `.askDatedLift`. The line is exactly "Bench 80 × 8 for Monday?" (or "Bench 3 × 10 at 70 for Wednesday?"). Nothing is written. Tested, and also tested inside a live workout.
- **LOG:** a tap (`answer(.log)`) or saying "log", "log it", "yes", "yep" or "yeah". It runs `LogExercise(on: noon of that day)` by `.tess` and says "Bench 80 × 8 logged for Monday.".
- **UNDO:** the whole capture is one op. Its record reverts the sets, and also the workout if one was created, so UNDO leaves nothing behind.
- **NOT NOW:** "not now", "no" or "nope" writes nothing, with an empty line. Any other phrase drops the ask and is read as usual (same as SQ8). Tested.
- **Never a task:** today's own day name logs as an ordinary lift, and the test asserts no task is created.
- **× in lift lines:** "Bench 3 × 10 at 80. Added to today." ✓

## When Monday has no workout yet
`pastWorkout(on:)` (TrainingActions.swift) looks for a *finished* workout whose `startedAt` falls on that 4 AM day:
- **If there is one,** the sets join it, in that exercise's last entry or a new one. A second dated lift for the same day joins the same workout (tested).
- **If there isn't,** it creates a workout titled "Workout", with `startedAt` = `endedAt` = noon that day, no routine and no process. Nothing appears on Now, and no rest timer or Live Activity starts.
  - The ledger dates workouts by `endedAt ?? startedAt` (TrainingLedger.swift:251), so the sets count for Monday: that day becomes "trained", and history, PRs and e1RM file them on Monday.
  - It shows as a 0-minute workout called "Workout". That's fine as a record. Naming it after the plan's session for that day would be nicer later.

## When the day named is in the future
**It can't be.** `back = (today's weekday − named weekday + 7) % 7`, so a day name always means the most recent one: 1 to 6 days back, or today when `back` is 0.
- "bench 80x8 sat" said on a Friday means *last* Saturday, six days back. There's no "next Saturday" reading.
- "tomorrow" and "next monday" aren't day words here. "next monday" leaves "bench 80x8 next", which isn't a lift, so the grammar doesn't read it and it goes to the model. Nothing is written by the grammar.
- 4 AM day: at 01:00 Tuesday (still his Monday), "mon" is today and logs normally, and "yesterday" is Sunday. That's consistent with TesseraDay.
- So a future day never writes and never asks. It's only worth a line if Product wants "bench Sat" on a Friday to mean planning, but nothing in the spec asks for that.

## Lows
- **D1:** a Monday workout that was started but never finished (left open, before the 6 h auto-finish ran) isn't matched, because only finished workouts count. LOG then creates a second "Workout" for Monday. That's rare, since auto-finish closes it. Fix if wanted: match any workout started that day.
- **D2:** each set's `loggedAt` is the real now (Thursday), not Monday (`LogSet`, TrainingActions.swift:67). The ledger files by the workout, so history is right. But anything that sorts or shows sets by `loggedAt` (a Day log, "last set" lookups) will place these on Thursday. Consider stamping `loggedAt` with the workout's day when `on` is set.

## Phone check
- After LOG for a past day, open the exercise page and Review. Monday's dab should show trained, and the set should appear in the exercise's history under Monday. This confirms the training index picks up sets written into an old, finished workout.
