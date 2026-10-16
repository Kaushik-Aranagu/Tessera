# QA review 274: set-loss rows (#274)

Merge b15f51f, head 7dd4e85, 8 files in TesseraCore (+278/-61). Static review; no toolchain here. Research's 108 rerun passed all ten rows (research/set-loss-rerun-274.md).

**Verdict: PASS.** No reverts against the first parent. No blockers. One Product call about bodyweight lifts (B1, below): it doesn't contradict the decision when no workout is running, but it does in a live workout.

## What it closes
- **Set-loss rows, each one in `SetLossTests`:**
  - A171: "bench 80x8 dentist fri" in a workout gives a set plus a dated task.
  - A059 / A162 / A163 / A167: a lift and an errand in either order, joined by "and", "then", "and then" or a comma.
  - A181: "pull ups 3x8" gives 3 sets at bodyweight.
  - A182: "curls 15x12" gives Dumbbell Curl 15 × 12.
  - A183: "bench 80x8 today" logs now.
  - A184: "bench 80x8 at 7" goes to the model and never becomes a task called "Bench 80x8".
  - A027: "Back Squat" reads "Squat" in lines.
  - K885 (#262).
  - KEEP rows guard "ohp 3x8 at 45" and "bench 80x8 heavy".
- **How the lift-and-errand reader works** (`parseLiftAndErrand`, TessGrammar+Live.swift):
  - The errand side must be a non-set write, and a task must have a date or time (`.task(_, nil)` is refused), so a stray word never becomes an undated task.
  - With no joining word, it only cuts after a numbered word.
  - A cut never starts on a set word ("to", "at", "for", "reps", "rpe", …), so "80 x 6 to failure at 9" stays one set (tested live).
  - A day word alone is left for the dated-lift ask.
  - It now also runs when no workout is open (entry nil), but only when the phrase has a digit.
- **Dated lift:** it moved to TessGrammar+Dated.swift unchanged, plus "today", which logs at once.
- **Closes review-262 R1:** `parseInFocus` re-enters at most once (`spokenRead`).
- **Closes the review-258 lows:**
  - `restWeekday` outside 1 to 7 reads as empty (TesseraSettings.swift:80-82).
  - `WriteSettings` brings a soft-deleted settings object back (`deletedAt = nil`), so a write is never invisible to `read()`.
  - Both are tested in SettingsTests.

## B1: bodyweight N × M, Product's question
**The decision** (decisions.md, Q8, 7:53 PM PT): "On a bodyweight lift a bare N x M always asks: '5 × 5: 5 sets, or +5 kg?'". grammar-regression SQ8 scopes it: "The rule holds in a live workout".

**What #274 does** (TessGrammar.swift `parseLift`):
- On a bodyweight exercise, a bare scheme "N x M" (no "at", no unit) with a whole N of 10 or less becomes N sets of M at 0 kg, with no ask.
- N of 11 or more still reads as N kg added, with no ask.

**When no workout is open** ("pull ups 3x8" from Home), it doesn't contradict the decision:
- Q8 is a live rule.
- The ask (`TessSetCountAsk`) needs an exercise entry in focus, so there is nothing to ask with outside a workout.
- Research's A181 row expects exactly 3 sets at bodyweight.
- Before #274, this invented a 3 kg × 8 set.

**In a live workout, it does contradict the decision.**
- With Dips in focus, a bare "10x8" still asks through `setCount` (TessGrammar+Live.swift:141), as Q8 says.
- But "dips 10x8", with the name, doesn't match the live set shapes: `looksLikeSet` is anchored on a digit (:262). So `parseInFocus` returns nil, and `parse` falls through to `parseLift`, which logs 10 sets of 8 without asking.
- So the same set asks or doesn't depending on whether he says the exercise name. No test covers the named live case; `SetLossTests.idle` only checks A181 with no workout.

**Recommendation:**
- Keep A181 as is when no workout is open.
- In a live workout, when the named lift is the bodyweight exercise in focus, send a bare N x M through the same `setCount` ask: "10 × 8: 10 sets, or +10 kg?".
- It's a few lines in `parseLift`: when `entry` is linked to `exercise` and the lift is bodyweight, return `setCount(...)` instead of converting. Add one live test.
- **Until it lands:** "dips 10x8" in a workout logs 10 sets. That is wrong only if he meant +10 kg, which he'd normally say as "+10 for 8" (S706). That risk is small, so it isn't a blocker for Oct 22, but Product should confirm the rule.

## Lows
- **L1:** with `at` weights, the time guard for A184 comes after `parseLift`, so "bench 3x5 at 7" logs 3 × 5 at 7 kg rather than asking about 7 pm. That's rare, and the "at N" load form is the documented way to say a weight.
- **L2:** the "curls" and "curl" aliases now resolve to Dumbbell Curl. If his history has sets under a "Curl" class, new sets go to a different exercise. Check his library before the install; a fresh library only has Dumbbell Curl (ExerciseLibraryTests).
