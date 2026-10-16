# QA review 348: WeekFacts lens for Design 46 (Core)

*QA, Oct 16, about 1:35 AM Pacific. PR #348, `core/week-facts`, head `36abe0e`, from `19c1dfd`. Static review.
Trial merge onto master: clean, 2 files (`DayLog/WeekFacts.swift` +193, tests +117). Rules only; no app and no
catalog change.*

## Verdict: PASS

Checked against Design 46 and Research's notes:

- **Planned counts from first use.** Days before the first non-system op have `planned = nil` and `wasDue = false`,
  and are flagged `beforeFirstUse` (`WeekFacts.swift:86, 94-97`). `plannedDays` counts days that were trained, were
  due, or have a routine ahead, all from first use (`:105-107`). Test: `countsTheWeekFromFirstUse`.
- **trainedDays** counts days, not sessions (`:108`), so two workouts in one day count once.
- **next is nil when the plan has ended**, judged from `startsOn` and `weeks` (`:181-185`), and nil with no plan
  (test `:108-115`).
- **No body, money or notes.** The struct carries only routine titles, short exercise names, record kinds, task
  counts and recipe titles. The test mirrors the struct and checks that no "weight" or "money" field appears
  (`:88`). Tasks count by `doneAt` (the day he did them), and cooks by `cookedAt`. `objects(of:)` already drops
  deleted objects, and the explicit `!isDeleted` checks are belt and braces.
- **bestLines**: at most one line per day and three in all. A record comes first, then a first time, then the
  fullest (`:133-152`; test `:91-102`). `lines(onDay:)` reads a day key at noon, so the 04:00 rule can't push it
  back a day (`:121-129`).

## Lows

- **L1. bestLines ranks by DayStory's wording.** It looks for ", PR.", the "New " / "Saved " prefixes and " min"
  (`:139-142`). If a Day log string changes, the ranking changes silently. A `kind` or flag on `DayLine` would be
  sturdier.
- **L2. `firstUse()` scans every op on each call** (`:156-158`). On the 5-year history that's the whole op log per
  Review render. Caching it, or reading the oldest non-system op from GRDB, would fix it.
- **L3. Some tests are loose.**
  - `plannedDays >= 2 && <= 6` (`:79`) doesn't pin the number.
  - `records.isEmpty || …` (`:84`) is always true.
  - Pinning both to the fixture's actual values would catch a regression.
- **L4. Two comments disagree.** `Day.date` is documented as "the day's 04:00 start" (`:8`), but `lines(onDay:)`
  says the key is a midnight (`:124`). The code treats it as the midnight key.
- **L5. `hasEnded` adds `weeks × 7 × 86400` seconds**, which is an hour off across a DST change. That's harmless at
  the plan's last midnight.
- **L6.** `nextRoutine(in:)` is called without `now:`. That's fine on master; once #341 lands, pass
  `now: now, calendar: calendar` for fixed-days plans.
