# QA: Now ranker, PR #141 (master 1a9c218, head 4c0bd2b)

*Repo maintainer (QA), 2026-10-15 23:25 UTC. Static read.* **PASS (engine-only for now: no app code calls NowPicker, so the pick-order change has no effect on the phone yet).**

## What I checked
- **Precedence** (NowRanker.swift `rank`):
  - A running process comes first.
  - Then a timed task starting within 0-15 min. It beats the rest line (R05).
  - Then the rest day (`kind: .rest`, the next routine one tap away).
  - Then re-entry (3 or more days away).
  - Then the scored rank.
  - Suspended processes are filtered out through `ledger().subject`.
- **Scoring:**
  - soon 40 − min/3 within 90 min, or 40 while the task is running to its end.
  - due today +20.
  - carried +10.
  - day part +15.
  - last action within 30 min +15.
  - day full −10 (untimed only).
  - incumbent +15.
- **Ties** keep the incumbent, then go to the stalest `updatedAt`, then A to Z. With the +15 bonus plus the tie hold, a challenger needs more than 15 to take Now, as specified.
- Only one ask (Shop) survives. Shop needs 8 or more open items, the evening, nothing running, and not declined today.
- **The pick-order change the coordinator flagged:** a timed task more than 90 min out scores 0 soon points, so a carried task (+10) now outranks it. This matches context-packing §5.
- **E6 closed:** `week()` forces today into training when `hasWorkoutUnderway`.
- **E7 closed:** the scan is limited to workouts created in the last 14 days.
- DayLoad skips today's scheduled workout on a rest day.

## Should-fix
- **N1: `area(of:)` files `setTaskDone` under training.**
  - The matcher checks `"set"` (training) before `"task"`, so the commonest task action, setTaskDone, maps to `.training`.
  - After he ticks off a task, the last-action +15 then goes to training candidates (today's scheduled workout) instead of tasks.
  - Fix: test `"task"` before the training words, or match exact action names. `CheckListItem` → groceries has the same family of issue once Lists ship (a packing list isn't Groceries).
- **N2: `pick()` passes a bare RankContext(now:calendar:).** No plan, incumbent, lastAction or daysAway, so `pick` never shows the rest day, never holds the incumbent and never does re-entry. Builder B's E5 hookup should call `rank(RankContext(plan:, incumbent:, lastAction: lastAction(), daysAway: daysAway(at:)))` rather than `pick`. Otherwise Now flips between equal items on every refresh.

## Lows
- N3: re-entry picks the smallest candidate that `fits(part)`, but untimed tasks never fit (no part, no start). It only fires for timed tasks or offers in the current day part, and otherwise falls through to the scored rank. Fix: count untimed tasks as fitting.
- N4: `Candidate.fits` uses `Calendar.current`, not `context.calendar`. This only matters in tests with a fixed calendar or time zone.
- N5: `hasWorkoutUnderway` keys on `createdAt` within 14 days. That's fine today, because workouts are created when started (no pre-scheduled workouts exist), but it would miss a pre-made scheduled workout once plans create them ahead.
