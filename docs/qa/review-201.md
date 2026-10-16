# Review #201 — past-day flags (fbe074a)

Core. 4 files, +91/-24. Static review (no Swift toolchain here).

**Verdict: PASS.** No should-fix. R5 closed. R4 stays open for Builder B's day-boundary PR.

## The changed Tuesday expectation is justified
WeekViewTests: Tuesday isRest went false → true.

The past branch replays each day as it looked that morning, using only what came before. Walking through it:

- perWeek 4. Monday was trained.
- On Tuesday morning: before = 1, so due = 4 − 1 = 3.
- The days left are Tue..Sun (6). Monday was trained, so Tuesday drops out of the pool, leaving Wed..Sun (5).
- The spread steps are round(i·4/2) for i = 0, 1, 2, giving 0, 2 and 4. Those land on Wed, Fri and Sun.
- Tuesday was not due, so it was a planned rest. The old `false` was the bug: before #201, past empty days never got isRest.

## Checked
- `wasDue` and `isRest` are mutually exclusive on past days. Both are false when `pastRhythm` is nil, which covers no plan or an explicit nil.
- `sessionsPerWeek: 0` (an explicit 0 passed in) becomes nil through the `> 0` filter, so pastRhythm is nil and neither flag is set, as the coordinator described.
- Refactor: the forward spread now goes through `spread`. A workout under way today is now inserted even when due ≥ the days ahead. That's harmless, because training already holds every day ahead in that case.
- Index 0 (Monday) reads the previous week's last day (Sunday, via finishedWorkouts(onDay:)) for "trained yesterday", so the rule holds across the week seam.
- `spread` handles the edges: due ≥ days gives every day, due 0 or 1 gives the first day of the pool, and an empty pool gives an empty set. When due > 1 and the pool has a single day, `(left−1) = 0` makes every step land on index 0. Safe.
- TesseraDay forcing `firstWeekday = 2` applies everywhere TesseraDay builds weeks (week stats, Review windows). The test pins it. **R5 closed.**
- New WeekPastDayTests cover 3 a week, a seeded plan and no plan.

## Lows
- **F1:** the seeded-rhythm fallback (cycle ≤ 3 → ×2 capped at 6, else count capped at 7) copies the app's PlanRhythm formula into Core. If one changes, the other drifts. Later, move it to one shared place in Core and have the app call it.
- **F2:** flags are computed for past days before first use too. Review must keep its firstUse gate when it switches to these flags, or a new user sees "rest" or "missed" on days before they installed.
- **F4:** a plan that stores `sessionsPerWeek` 0, with nothing passed in, gives no rhythm for the days ahead. The past falls back to the seeded cycle formula, so past days show rest/due while days ahead show the next routine. That's rare, since the app always passes its count. Fix later by having an explicit plan 0 also mean no past rhythm.
- **F3:** a perf note only. `wasDue` calls `finishedWorkouts(onDay:)` once per past Monday. That's negligible.

## Still open elsewhere
- **R4 (Builder B):** ReviewPage.swift:13, :117, :121, :142 use `calendar.startOfDay(for: now)`. It should use TesseraDay's today when Review moves to these flags.
