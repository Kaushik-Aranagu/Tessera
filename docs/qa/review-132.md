# QA: rest day on Now, PR #132 (master b4c4682, head 6fdc973)

*Repo maintainer (QA), 2026-10-15 23:10 UTC. Static read.* **PASS, with one wiring gap (E5) to close before the install.**

## Engine
- **The new week spread.**
  - When today trained nothing, yesterday did, and `due < ahead.count`, today is dropped from the pool and the spread starts tomorrow.
  - Bounds are safe:
    - `due < ahead.count` means `due ≤ pool.count`.
    - `due ≤ 1` uses `0 ..< min(due, left)`.
    - `due == left` gives the identity indexes.
    - Otherwise `round(i·(left−1)/(due−1))` stays within `0...left−1` and the indexes are distinct.
  - "Yesterday" looks across the week boundary (Sunday's workout makes Monday rest when there's room), which reads right.
- **PPL×2 (6 a week), traced Monday to Sunday training as it goes:**
  - Tue: the pool is Wed-Sun with 5 due, so Tue rests.
  - Wed: 5 due over 5 days, so every day trains.
  - Thu (with Mon and Wed done): 4 due over 4, so every day trains.
  - The result is one rest day early in the week and 6 sessions, as before. Before #132, the rest fell later in the week, because today always trained first.
- **`restDay`** returns nil if any workout started or scheduled today is unfinished. Otherwise it returns `isRest` for today, plus the next planned day this week, or the plan's next routine with `nextDay: nil`.
- K3: the hint is now "Undoes what Tess just said".

## E5 (should-fix before the phone): Home doesn't call `restDay` yet, but the week page already moved
- No app code calls `NowPicker.restDay` / `TrainingLedger.restDay`. Features/Plans/PlanData.swift:45 does call `week(containing:)`, so on the phone:
  - The week page marks today as rest.
  - Home's Now still offers the next routine as today's.
- That's a visible contradiction, and the new "rest after a training day" rule makes it more frequent. On PPL×2 it happens the day after his first session each week.
- Fix: wire NowPage to `NowPicker.restDay(plan:)` and show the line plus the next routine one tap away (iOS build / Builder B). Otherwise, hold the rule until it's wired.

## Lows
- **E6:** `week()` doesn't know about an unfinished workout. If he trains on a rest day, the week page shows today as rest while the workout runs (`restDay` guards this, `week` doesn't). Fix: in `week()`, treat today as training when `hasUnfinishedWorkout`.
- **E7:** `hasUnfinishedWorkout` scans every workout object on each call. That's fine now, but at 5-year scale it runs on every Now refresh. Limit it to `scheduledFor`/`startedAt` today, or to the running process.
