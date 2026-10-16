# Review #248: Core set guard, SQ8 ask (fdcaee4, head bf5a704)

Core. 19 files, all in TesseraCore, +624/-93. Static review (no Swift toolchain here). Checked against research/fixtures/grammar-regression.md (SQ8 at 7:53 PM PT, edges at 8:07 PM PT) and set-logger.md Q01 to Q28.

**Verdict: PASS.** Every Q8 decision is built and tested. Two should-fix gaps (Q9, Q10), both small. Rows A169, A170, K874, Q5/K883, Q7a/b, K888 and K889 move from fail to pass.

## The Q8 decisions, traced in `setCount` (TessGrammar+Live.swift)
| Decision | Code | Fixture |
|---|---|---|
| Bare `N x M`, N ≤ 6 and under half the last weight, asks | `count <= 6 && Double(count) < last.weight / 2`: strict, so exactly half logs | Q01-Q03, Q11 (barbell), D473, K817, K876-K878 ✓; K891 (4 at 8 logs) ✓ |
| Bodyweight lift always asks, first set too | `asks = bodyweight || …`; no last set doesn't stop it | Q13, Q14 (10x6), Q15, Q19/K894 ✓ |
| A unit said logs | `kilos?`/`kgs` → `kg` before parsing (K888); `x`-shape regex only matches bare numbers | Q23, Q26, K882, K888 ✓ |
| N ≥ 7 logs, snapped | not an ask → `parseRelativeSet` + `snap` (the old light-kit model hand-off is gone) | Q04, K889 (7 → 6, lighter of the tie) ✓ |
| No last set: only bodyweight asks | `last.map {…} == true` is false with no set | Q18/K893 ✓ |
| Another phrase drops the ask | `pendingAsk = nil` first; only a said answer resolves; anything else is read as usual | Q28/K895, `anotherPhraseDropsTheAsk` ✓ |
| Exact lines | `"\(count) × \(reps): \(count) sets, or \(count) kg?"`, `+` on bodyweight | ✓ tested verbatim |

- **Routing:** an SQ8 ask comes back `.handled` with `asking: .setCount`, so the router stops there (no model call, no miss log). A line ask (`.ask`) comes back `.asked`, so the on-device model still gets a go, and Tess's question is the answer only if no route understands it. `theAskIsNotAMiss` is tested.
- **Answers:** "sets", "2 sets", "kg", "2 kg", "+2 kg", "kilos" all resolve. SETS logs N sets at the last weight, or bodyweight. KG snaps to the kit, and below the lightest load writes nothing ("2 kg isn't loadable here", Q11). Undo takes back every set the line named. `pendingAsk` lives on `runtime.tess`, which AppModel keeps, so a spoken answer on the next phrase works.
- **A169/A170:** `parseSetAndErrand` splits on "and then", "then", "and" or a comma. Both halves must write, and the rest mustn't look like another set. The errand is read with no workout in focus. ✓
- **K874 / Q7a/b:** "bench 80 for 8, 81" logs 80x8 and asks "81 for how many reps?". "bench 80x8, 6" is two sets, no longer the "Squat 100, 5" shortcut. ✓
- **Q5 / K883:** the warm-up word is read before the RPE, so "warmup 60x5 @7" keeps both. ✓
- **Other:**
  - The receipts lead with the name ("Set 3 logged. 80 × 8, RPE 8.").
  - "nearest load to 81" replaces "81 isn't loadable", so the set-logger fixtures and install-day script step 7 need the new line.
  - Overnight lines lead with the name.
  - `canSpend` is internal, which closes N1 (review-230).
  - `writeRolling` saves first, which closes the #239 follow-up.
  - The key line is `TessRouter.keyLine`.

## Should-fix
- **Q9: an RPE or kind word skips the SQ8 ask.** `setCount` runs only when `rpe == nil, kind == nil`.
  - So "2x10 @8" on dumbbells logs 2 kg × 10 @8.
  - "3x10 @8" on a barbell parses as 3 kg × 10 and snaps to the 20 kg bar.
  - "warmup 2x10" logs a 2 kg warm-up.
  - SQ8 says a bare `N x M` with no unit asks. Before #248, the light-kit check sent most of these to the model.
  - Fix: run the `setCount` test on the core whatever the RPE or kind. When it would ask, return the ask, or `Live(parse: nil)` for the model, since the ask can't carry an RPE yet.
  - Add rows: "2x10 @8" (db) and "3x10 at 8" (bar) should ask; "4 kg x 10 @8" logs.
- **Q10: the new yes/no line asks have no "yes".**
  - "skip" now asks "Skip set 2?", and "+5" asks "+5 kg: on the next set?". Only the SQ8 ask is remembered (`pendingAsk`). A line ask isn't remembered at all, so his natural reply "yes" (or "no") is read fresh.
  - In a live workout "yes" isn't a set, so it falls through to the task rules or the model. That probably gives a task "Yes", but I haven't traced `parseTask` for a lone "yes", so add a row.
  - Fix (pick one):
    - Word these as statements that need no reply ("Skip is the screen's key.", "+5 kg goes on the next set: use the dial.").
    - Or treat a bare "yes", "no", "ok" or "sure" in a live workout as `ignoredInWorkout`.
  - Fixture rows: "yes" after "skip", and "yes" after "+5" → no write.

## Notes for the app (Builder A / B)
- The SQ8 ask's two answers as ghost rows ("2 sets" / "2 kg") call `TessCaptureEngine.answer(_:context:)`. Nothing in the app calls it yet, so today only a spoken answer works. Showing the question as a line is enough for now.
- Copy moved in Core: install-day-script step 7 ("81 isn't loadable") and step 8 ("Same again @9, logged.") now read "Set N logged. 80 × 8, nearest load to 81." and "Set N logged, same again, RPE 9." I'll fold this into the script re-check.
