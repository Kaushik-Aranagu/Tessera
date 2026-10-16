# QA review: #377 trip zone fixes (Core, core/trip-zones)

Head `1f0b5c9`, from master 38466f1. Trial merge against master `21f406d` (which carries #369): **clean**.
8 files, +210 / -11, all inside TesseraCore. Static review; I have no Swift toolchain here, so "package 432 green" is Core's run.

## Verdict: PASS

T1, T2 and T3 from Research 127 (`research/fixtures/trip-rehearsal.md` rows 99-101) are fixed the way Research asked.
Six of the seven F rows are covered: R11, R12, R22, R24, R25 and R32. **R34 is not covered and doesn't need to be**:
it is T4 (`ExerciseDigest` "Today/Yesterday", Builder A), which Research marked "can wait". Please don't count
#377 as closing all seven F rows.

Data safety: no migration, no Catalog change, no launch flags, no ProcessInfo reads. It only reads the `op.zone`
column that is already there (schema v3). Old rows with a NULL zone fall back to the calendar's zone, so they
bucket exactly as they did before.

## What I checked

- **OpZones (OpZones.swift)**
  - The action names in `starts` and `finishes` all exist as real descriptors (TrainingActions.swift:202, 232, 266,
    302, 451; PlanActions.swift:100; Cooking.swift:223).
  - Priority is start, then last finish, then create. A start with a NULL zone is skipped, so it falls back to the
    create's zone. That matches `StoreDayLookup.zones` (DayStory.swift:433-454), so the Day log and the strip
    now agree, which is the R32 disagreement.
  - The result is cached per revision in `DerivedCache.opZones`.
- **`TesseraDay.day(of:in:)`**
  - Takes his 04:00 day in the zone the thing happened in, then rebuilds that year-month-day as a midnight in
    the reading calendar. The 06:30 EDT case gives the PDT midnight of Wednesday, as intended.
  - Keys still line up with `day(of:)` across DST, because both are `startOfDay` in the same calendar.
- **T1 (WorkoutSummary.swift:97-104)**: the zone stays in the cache key, as Research asked. Home
  (HomeSpatialView.swift:610) and Review (ReviewView.swift:86) both go through `finishedWorkouts(onDay:)`, so
  both pick this up.
- **T2 (Tasks.swift:41-49, WeekFacts.swift:200-222)**: for a row with no zone, `dayKey == today` gives the same
  answer as the old `start..<end` range, so nothing changes at home.
- **T3 (TessMemory+Turnover.swift)**: the guard, the "already written" check and the rule all use "2026-10-20"
  labels. I traced the case the test doesn't cover: the app is killed and relaunched in Los Angeles.
  - On relaunch the in-process guard is empty.
  - The stored line's `day` is the New York midnight, which reads as "2026-10-19" in Pacific, so `written` comes
    back false.
  - `write(rule: "recent.2026-10-20")` then finds the existing rule and updates that line in place
    (TessMemory.swift:649-655).
  - Result: still one "Tue:" line. R25 holds.
  - There are no old `recent.<epoch>` rules on his phone, because #356 isn't in the 444e72b install. The format
    change therefore needs no cleanup.

## Should fix (not blocking)

- **S1, scale.**
  - OpZones re-sorts the whole op log on every revision bump, so every logged set or ticked task re-sorts it.
  - The three callers share the cache, but on a 5-year history that is a full sort of every op after each write.
  - Please run `scripts/test.sh --scale` once and put the number in the PR.
  - If it shows up, there are two cheap fixes:
    - drop the sort, since operations are applied in order and only the first start and last finish matter; or
    - build the map incrementally from `touched`.

## Lows

- **L1.** OpZones and `StoreDayLookup.zones` hold the same rule in two copies. Research's T1 row asked for "the
  same rule". Have `StoreDayLookup` read from OpZones next time either file is touched, so the two can't drift.
- **L2.** `theTurnoverRunsOnceOnATravelDay` passes because of the in-process guard alone: same context, same
  label. Add a relaunch step (clear `lastTurnoverDay`, then run the turnover in Los Angeles) that pins the
  rule-dedupe path traced above. That is the path that actually protects the phone after an app kill.
- **L3.** On that relaunch, `wroteRecent` comes back true even though nothing new was written; the line was
  updated in place. Nothing reads it for UI today, so this is a comment-level note.
- **L4.** A task that is done, reopened and done again in another zone files under the zone of the last
  `setTaskDone`. That includes a "not done" toggle, but it doesn't matter, because only done tasks are bucketed.
  Noting it only so nobody "fixes" it.

## Acceptance

- In the code: R11, R12, R22, R24, R25 and R32 from trip-rehearsal.md.
- On the trip build: replay those rows on the Simulator with `TZ` and the clock flipped, Oct 26 build, before
  the trip.
- R34 stays open, Builder A's T4.

## Addendum: S1 measured (11:11 AM PT)

- Core ran the scale test at TESSERA_SCALE=1500.
  - The Day log read is 33 ms.
  - The build loop of 1,500 workouts plus 1,500 tasks took **1,792 s**. At 200 it took 1.5 s.
- The cause is the one S1 named: OpZones re-sorts the whole op log on every revision inside the write path.
- S1 is now a must-fix for the Oct 26 build. Core's fix PR makes OpZones incremental and drops the sort, with the
  latest finish by createdAt winning per object, and ScaleTests gets a budget for the 1,500 build. QA reviews it
  when it lands.
