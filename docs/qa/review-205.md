# Review #205: live-workout set guard, S701 to S706 (aec9ccd)

Core. 5 files, +284/-14. This is a static review: I traced the code by hand because there's no Swift toolchain here. I checked it against research/fixtures/set-logger.md (K775 to K814).

**Verdict:** PASS on the fixture rows. But the guard's promise ("no phrase said mid-workout loses a set or turns into a task") doesn't hold yet for dictated input. Q1 and Q2 below are should-fix, and both are small.

## Rows traced
All 37 typed rows give the expected parse in my hand trace: K775 to K809, K813 and K814. That includes every former wrong write in the SNAP, REPS, RPE and SETT groups, plus the LOADW and KIND misses. K796 (the comma list) snaps both parts.

K810 to K812 (NRM) are unchanged. They need the spoken normaliser, which isn't built yet.

Other things I checked:
- `parseForProcess` runs first, but in a workout it only takes `rest` and `timer`, so it can't take any of these rows.
- `-5` reaches `parseLive` with its sign, because `raw` is built from `phrase`, not from `text`.
- `bar for N` goes to the model on dumbbells: `WeightDial.bar` is nil unless the lift is plate-loaded.
- A snap tie goes to the lighter load (`detents.min` keeps the first).
- The snap line reads "Set 3. 80 x 8. 81 isn't loadable."
- RPE reaches `LogSet(rpe:)`.

## Should-fix

**Q1: a trailing period from dictation gets past the guard.**
- **Where:** TessGrammar+Live.swift:15. `raw` only trims whitespace, while the S702 regex, the `fail at N` regex and the RPE regex all end in `\d+$`. iOS dictation adds a period by default.
- **What breaks:**
  - `Same at 9.` and `8 at 9.` match no rule, so `parseLive` returns nil and the phrase falls to the task rule: a task "Same" at 21:00, and no set is logged. This is K799 again.
  - `Fail at 6.` becomes a task "Fail" (K801).
  - `-5.` and `+5.` miss S702. Then `text` (which `normalize` has trimmed) is "5", which passes S701 because 5 is below the bar. Result: a wrong set of 80 x 5 (K785, K786).
- **Fix:** strip trailing punctuation but keep a leading sign:
  `let raw = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacing(/[.!]+$/, with: "")`.
- **Rows to add:** `Same at 9.`, `-5.`, `Fail at 6.`.

**Q2: a phrase with a comma skips the guard.**
- **Where:** TessGrammar.swift:74, which runs `parseLive` only when `!phrase.contains(",")`. Dictation inserts commas.
- **What breaks:**
  - `100 for 5, at 8`: `parseCommaSets` fails on "at 8", so the phrase falls through to `parseCook`/`parseTask`. Result: a task "100 for 5" at 20:00 (K798's wrong write).
  - `8, 81`: the comma parts go through `parseRelativeSet` (TessGrammar.swift:292) with no S701 bound. Result: 80 x 8 and **80 x 81**.
- **Fix, two parts:**
  - (a) When the comma parse returns nil and there is an entry, fall back to `parseLive(phrase, text:, entry:)`. Its RPE regex already copes with "100 for 5," because `normalize` drops the comma.
  - (b) Inside the comma list, send each bare-number part through the S701 bound. Or simply run each part through `parseLive`, and send the whole list to the model if any part comes back as "ask".
- **Rows to add:** `100 for 5, at 8`, `8, 81`.

## Lows
- **Q3:** an out-of-range RPE on `same` or bare reps still becomes a task. `same at 11` and `8 at 4` reach TessGrammar+Live.swift:61, where `looksLikeSet("same")` is false, so the result is nil and the phrase goes to the task rule. That point is already inside the `isSetCore` branch, so it can always `return model`.
- **Q4:** S701's "within two loads" stops common bare reps on light kit.
  - On a pull-up with nothing added (last weight 0, detents 0 / 2.5 / 5), the bare reps 1 to 6 all go to the model.
  - After a 6 kg dumbbell set, `8` and `10` go to the model.
  - This follows the spec, so nothing is wrongly written, but it costs common entries. Suggestion: skip the check when the last weight is 0 on bodyweight. Research should weigh light dumbbells.
- **Q5:** a set kind plus an RPE drops to the model. The RPE regex runs on `raw`, after the kind has already been stripped from `core`, so `80 x 6 to failure at 9` and `warmup 60x5 @7` go to the model. That's a miss, never a wrong write. Running the RPE match on `core` fixes it.
- **Q6:** `0 x 8` on a barbell isn't snapped (the `weight > 0` guard in `snap`), so it logs a 0 kg bench set. Very rare.

## No clash
The changed files don't overlap #201 or #203. `Parse.set` gained two defaulted fields, and every pattern match was updated: TessCaptureEngine, parseCommaSets, TessTests and SetLoggerTests. Research should check the app target for any other `case let .set(` patterns that need the two extra fields.
