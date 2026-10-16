# Review #210: set guard dictation follow-up (e75f40f, head eb0835c)

Core changed 4 files (+94/-41). I reviewed it by reading the code and tracing each fixture by hand, because there's no Swift toolchain here.

**Verdict: PASS.** Nothing regresses, and Q1 to Q4 and Q6 are closed. Q5 is closed for the case that matters. Two new lows, Q7 and Q8, are listed below; neither is a regression.

## The RPE/kind reorder doesn't regress S701 to S706
`raw` is built first: lowercased, a trailing `.` or `!` stripped, commas turned into spaces, whitespace collapsed. `core = normalize(raw)`. The S706, S702 and fail checks still run on `raw`, before `core` is used. That matters because `normalize` trims a leading `-`.

I re-traced every row in the new order:

| Group | Rows | Result |
|---|---|---|
| Weights and reps | K775 to K784 | same as before |
| Signed numbers (on `raw`) | K785 to K787 | same as before |
| Drop and snap | K788 to K795 | same as before; tests now also assert "(said N)" |
| Pounds | K797 | same as before; tests now assert lb |
| RPE (reads `core`) | K798 to K800, B303 | same as before |
| Fail | K801 | same as before |
| Kind (now after RPE) | K802, K803 | same as before |
| Load words | K804 to K809 | same as before |
| No sets | K813, K814 | same as before |
| Others | A180, B309 | same as before |

- **The "3x10" rule doesn't touch any existing row.** It only applies to `.full` sets at 10 kg or under. Barbell rows under 20 kg were already going to the model through `snap`.
- **H625 (`38`) stays reps-only.**
  - 38 is in 1 to 50, isn't followed by "reps", and the lift isn't bodyweight.
  - It is about 17 detents from 80, so it's not near the last weight.
  - Result: `.repsOnly` 80 x 38, and the test now asserts "reps".
  - Research's partial cover (no pending-prompt state yet) is unchanged.

## Q1 to Q6
- **Q1:** `Same at 9.`, `8 at 9.`, `Fail at 6.`, `-5.` and `+5.` all trace as fixed, and there are rows Q1a to Q1e.
- **Q2:** `8, 81` asks (one part comes back as ask, so the counts differ and the result is nil). `100 for 5, at 8` is read as one phrase: " at 8" alone parses as nothing, so the parts are joined and read whole. Plain sets in a comma list are snapped one by one through `parseLive` (K796).
- **Q3:** an `at N` that isn't an RPE always goes to the model now.
- **Q4:** a bodyweight move with nothing added skips the near-weight check.
- **Q5:** `80 x 6 to failure at 9` gives failure @9.
  - What's left: `warmup 60x5 @7`, with warmup as a prefix, still goes to the model. `isSetCore("warmup 60x5")` is false, so the RPE isn't taken. It's a miss, not a wrong write.
  - The new `hasSuffix(" to failure") && looksLikeSet` clause in `isSetCore` repeats `looksLikeSet`, which isn't anchored at the end. It's harmless.
- **Q6:** `snap` now sends anything below the lightest load to the model, so `0 x 8` asks.
- **Research rerun:** `3x10` on dumbbells asks, and `24 reps` gives 24 x 24 reps.
- **Snap line:** the "isn't loadable" message now uses `%g`, so it says "81.25", not "81.3".

## New lows
- **Q7:** a comma list whose first part names the exercise still skips the guard on its other parts.
  - Example: `bench 80 for 8, 81`. `parseLive` can't read "bench 80 for 8", and the joined phrase fails too, so the old `parseCommaSets` path runs. Its bare part "81" goes through the unguarded `parseRelativeSet` (TessGrammar.swift ~306), which logs **80 x 81**.
  - It's rare mid-workout, but it's still a wrong write.
  - Fix: when `parseCommaSets` has an entry, its `parseRelativeSet` fallback should go through `parseLive` instead, and the whole list should go to the model if any part comes back as an ask.
- **Q8:** the "3x10" rule only catches set counts that aren't loadable weights.
  - These still log as weight × reps: `2x10`, `4x8` and `6x8` on dumbbells (2 kg steps), `5x5` on a cable stack (5 kg is a detent), and `5x5` or `10x6` on a pull-up (that much added).
  - This was already the behaviour before #210, so it's not a regression.
  - It's a call for Research and Product. One option is to ask when N x M has N ≤ 6 and the weight is under half the last weight.
