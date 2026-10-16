# QA review 262: spoken numbers normaliser (#262)

Merge 12f1c43, head 926ce1b, 7 files (+411/-8). Static review; no toolchain here.

**Verdict: PASS.** No reverts against the first parent. No blockers.

## What it closes
- **K885**: "a hundred, five" reads as "100, 5" in a live workout, never groceries (SpokenNumbersTests `aHundredCommaFiveIsNeverGroceries`).
- **K811/K812**: "ten ten ten" stays three numbers.
- **P1 (review-254)**: `pastWorkout` (TrainingActions.swift:343-357) now prefers the day's last workout that already has the exercise, else the day's last. Closed.
- **P2 (review-254)**: dated sets are stamped at the workout's `endedAt`, else `startedAt` (TrainingActions.swift:333), so a past day's set never sits before an evening one. Closed.
- × replaces x in the Intents and TessModel lines.

## The recursion (coordinator's note)
TessGrammar.swift:117-123 calls `parseInFocus(spoken, ...)` on the normalised phrase with no depth cap. It terminates in practice: the second pass normalises an already-normalised string, `numbers()` is idempotent, so `spoken == phrase` stops it. Every test row checks that idempotence (SpokenNumbersTests.swift:65). Leftover words like a bare "plus" also produce the same string and stop. A one-pass cap (a `normalised: Bool` parameter) is still right as a cheap guard against a future rule that isn't idempotent. **Low, R1**; Core already has the ask.

## Lows
- **R1**: cap the re-entry at one pass (above).
- **R2**: the pre-pass runs only when an exercise is in focus, so number words in errands outside a workout ("call mum at seven") are untouched. Inside a live workout a mixed phrase gets its numbers converted, which the set guard then reads; acceptable, and worth one fixture ("bench eighty for eight, call mum at seven").
- **R3**: trailing "for" becomes 4 only after exactly one number, and "k" becomes kg only after a number. Both match the fixtures; no case found where a plain word is converted.
