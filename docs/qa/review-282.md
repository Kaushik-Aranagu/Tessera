# QA review 282: grammar follow-up (#282)

Merge 7f1feb7, head 65707a5, 6 files in TesseraCore (+122/-15). Static review; no toolchain here.

**Verdict: PASS, with one should-fix (F1, a new wrong write).** No reverts against the first parent.

## What it closes
- **review-274 B1** (Product, 9:40 PM PT): with a bodyweight lift in focus, a named "pull ups 10x8" now asks "10 × 8: 10 sets, or +10 kg?", like a bare "10x8" (TessGrammar.swift:398-402). With no workout open it stays 3 sets (A181). Tested (`aNamedBodyweightLiftInFocusAsks`).
  - In a live workout, the ask comes from the final `parseLift(text, entry)`. `liftPart` drops asks, so the lift-and-errand reader can't swallow it.
- **review-274 L1:** "bench 3x5 at 7" now goes to the model. A number after "at" that is 12 or less and lighter than the kit's lightest load is read as a time (:407-411). Tested (QA274).
- **review-262 / SPK, the TessSpoken `where` bug:** in `case "times", "into" where …`, Swift applies the `where` only to the last pattern. So "times" always became x, "kilos" and "kgs" always became kg, and so on. Each rule now needs a number beside it ("times square", "pounds of flour" stay). Tested (`spokenUnitsNeedANumberBesideThem`).
- **The wake word:** "Okay Tess, 80 for 8." strips "okay/hey tess" before parsing. In a workout it's a set, never groceries (R113a).
- **Groceries:**
  - "oat milk and eggs for groceries" and "eggs on the shopping list" go to the list (SPK1, SPK2).
  - "80 for 8", "80 by 8" and "N reps" are never shopping items in a comma list.
- **Receipts:**
  - A bodyweight lift says "Pull-Up 3 × 8. Added to today." (no "at 0").
  - The dated ask and its Log line say "Squat" (A027).
- **The miss line** offers an example only where it fits: "Try “80 × 8”." in a workout, "Try “milk, eggs”." on the shopping list, and nothing elsewhere. That drops the old "bench 80 × 8" hint from every miss.
- **"8 reps only"** (en-IN emphasis) reads as 8 (R113b).

## Should-fix
- **F1: "bench 3 sets of 8" now logs a 3 kg bench set.**
  - `parseLift` rewrites "N sets of M" to "NxM" (TessGrammar.swift:387). That's right when a weight follows ("3 sets of 8 at 80", R113c).
  - With no weight, "bench 3x8" reads as weight × reps: `readScheme`'s else branch gives 3 kg × 8 and sets `weightFromScheme`. 3 kg passes every guard (the at-time guard only checks weights after "at"), so:
    - with no workout open it writes "Bench Press 3 × 8 at 3";
    - with Bench in focus it writes a 3 kg set, because `parseLive` doesn't match "bench …" and the final `parseLift` returns `.set`.
  - Before #282 this phrase didn't parse and went to the model.
  - The same rewrite makes "dips 3 sets of 10" with Dips in focus ask "3 sets, or +3 kg?", even though he said "sets".
  - Fix: don't rewrite "N sets of M" into the ambiguous "NxM". Read it straight into `lift.sets` and `lift.reps`, keep `weightFromScheme` false, and let a missing weight return nil (the model asks), or 0 on a bodyweight lift.
  - Tests: "bench 3 sets of 8" gives nil, "dips 3 sets of 10" in focus gives 3 sets at 0, and "pull ups 3 sets of 8" with no workout gives 3 sets.

## Lows
- **G1:** the new groceries pattern takes any "X for/on/to groceries" with no date. So "spent $40 on groceries", a natural Money phrase for him, lands "spent $40" on the shopping list. Skip it when the left side has a currency sign or a past-tense verb ("spent", "paid", "bought"); that sentence belongs to Money when it lands.
- **W1:** the wake-word strip matches "tess" at a word boundary, so "Tess's ideas list" loses "Tess" and becomes "'s ideas list". Require a comma, colon or space after "tess" (`tess(?:[,.:]\s*|\s+)`).
