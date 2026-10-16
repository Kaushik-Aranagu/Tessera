# Review #254: Q9, Q10, D1, D2 and typed "by" (e7a5be4, head cfec50d)

Core. 8 files (5 source, 3 test), +139/-56. Static review (no Swift toolchain here).

**Verdict: PASS.** Q9, Q10 and D2 are closed. D1 is closed with one refinement (P1). A yes to an open ask is never swallowed.

## (1) A yes to an open ask is resolved before the live guard
- `TessCaptureEngine.capture` checks `pendingAsk` (SQ8), then `pendingDatedLift`, **before** `router.run`. Only the router reaches the grammar, and only the grammar reaches `parseLive`.
- So with "Bench 80 × 8 for Monday?" open, "yes" goes to `TessDatedLiftAsk.choice` → `.log` and returns. It never reaches the new yes/no line.
- With the SQ8 ask "2 × 10: 2 sets, or 2 kg?" open, "yes" isn't one of its answers (only sets/kg), so the ask drops. "yes" is then read fresh and gets "Say the set, like 85 × 8.". That's right, because yes doesn't answer an either/or. The dated-lift ask is still checked after, so if both were open the dated one still gets the yes.
- A tap on an answer (`answer(...)`) is separate and unaffected.

## Q10 closed
- In a live workout, a bare yes, yeah, yep, no, nope, ok, okay or sure now always gets "Say the set, like W × R." (from the last set), and never becomes a task. `.ask` is a line ask, so no model can turn it into a write unless it understands it.
- The two old yes/no questions are gone:
  - "+5" / "down 5" now says "Say the set, like 85 × 8." (last weight ± change).
  - "skip" says "Skip is on the workout screen."
- New: "81 kg" with no reps asks "81 kg for how many reps?".

## Q9 closed
- `setCount` now runs whatever RPE or kind came with it. "2x10 @8", "3x10 at 8" (bar) and "warmup 2x10" ask, and the ask carries `kind` and `rpe`, so either answer logs them. "3 sets of 10 @8" keeps both too. Tested.
- "by" is now a set shape everywhere ("80 by 8", "bench 80 by 8"), and looksLikeSet agrees.

## D2 closed
`LogSet(time:)` stamps `loggedAt` with the dated day (noon), and the workout's process is touched at that time, not now.

## (2) Two workouts on the day named: the later one gets the sets
`pastWorkout` now takes `.last` of that day's workouts, open or finished, in creation order. So with a morning session and an evening session on Monday, "bench 80x8 mon" → LOG goes into the evening one.
- **Is it right?** It's an acceptable default, and better than making a third workout. But one case reads wrong: if the bench was in the morning session, the set should join that one. Otherwise Monday shows bench split across two sessions.
- **P1 (low, small):** prefer the day's workout that already has an entry for that exercise; if none has it, keep `.last`. That's a one-line change in the closure order (check `orderedChildren` for the exercise's class first).
- **P2 (low):** when the set joins an existing workout, `loggedAt` is noon, which can fall before that workout's start (an 18:00 session). The ledger files by the workout, so history is right; only a loggedAt sort inside the day is off. Stamping the joined workout's `endedAt` (or `startedAt`) instead of noon would keep the order.
- **D1:** an open Monday workout is now matched (rare, given the 6 h auto-finish). Adding to it touches its process at Monday noon; harmless.
