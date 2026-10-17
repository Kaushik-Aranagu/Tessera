# QA review: #643 (Core 0al, Home done pack wall)

Head: fe29955f. Merge-tree clean on master. 3 files, +241 (HomeDonePack.swift new, 6 lines in PrivateFacts, tests). Nothing calls HomeDonePack yet (git grep: only its own file and tests), so no Claude call can happen from this PR.

## Verdict: PASS at fe29955f, with one must-fix before 0t wires it

What goes in the pack: title, finish clock, day label, bests (names), sinceLastDays, the rules line, counts and clock digits, names. No weights, reps, volume, notes, health or money field exists. Title and every best name go through isWalled (secret words, key shape, money, body, then a loose-number rule); any hit means no pack and no call. noSets and nothingToAdd skip before the wall, which is safe (no call either way). Numbers licensed to a returned line come only from counts and the clock, never from the title (W14). W1-W16 table, W13 vital rule (heart rate, blood pressure, hrv, spo2, bp n/n beside set notation) and a built-from-pieces key (W15) are all asserted.

### Must-fix before 0t (not blocking this merge): training notation exempts weigh-ins
isWalled relies on isBodyShaped, whose first guard is `!isTraining(lower)` (isTraining = "NxN" or "N reps"). With any notation present, isBodyShaped returns false before it reaches the weigh-word and bare-weight checks. The pack's own loose-number rule is also skipped when isTraining is true. So a title like "Weigh in 82.4 kg 5x5" or "Morning 82.4 5x5" is not walled and would go to Claude as title and name. W13 closed this for vitals only. Fix in the pack (keep PrivateFacts's bar-weight rule, MB31/MB32): wall when a weigh word (weigh, weighed, weigh-in, weight, bw, bmi) appears with a number, or a decimal appears beside a body unit with no lift word, even when notation is present. Add rows: "Weigh in 82.4 kg 5x5", "Morning 82.4 5x5", and keep "Push B 5x5 80 for 8" and "Bench 82.4 kg 5x5" (a bar) passing.

### Lows
1. The caller supplies lastWeightKg; a nil weakens the bare-weight check silently. When 0t wires it, take the store (or call BodyWeight.lastKg inside build) so a caller cannot pass nil by mistake.
2. The W13 vital rule sits in PrivateFacts.isBodyShaped, so it applies on every surface (router, notes, tasks), not just the Home pack: "heart rate zone 2 run" as a task or note becomes a private one. Probably wanted (decisions 7:31 PM), but add one WallsBypassTests row so the wider reach is pinned.
3. Rows set hardFail on json that is "" when walled, so those asserts pass trivially; the real assertion is `.failure(.walled)`. Fine, just noting.
