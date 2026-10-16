# QA review 289: F2 follow-up, weightless N×M on every kit (#289)

PR head 1bc173f on base f867f50. Three files: TessGrammar+Lift.swift, TessGrammar.swift and SetLossTests.swift (+33/-7). Static review; no toolchain here. No deletions or reverts.

**Verdict: PASS, with one should-fix (F3).** F2 is closed for the cases I named: N below the kit's lightest real load. The question was whether any weightless N×M can still write N kg. Two can.

## What's right
- **Lightest real load:** it's now `detents.first { $0 > 0 }` (TessGrammar+Lift.swift:48). So "lat pulldown 3x8" and "leg press 3x8" ask (F2a, F2b).
- **Dumbbells and kettlebells:** with N ≤ 6, a last weight in focus and N under half of it, Tess asks for the set count (Q8). With no last weight, she asks "at what weight?" (:58-67). "curls 3x8" asks (F2c); "curls 14x10" logs (F2f).
- **"at N" as a time:** now also when the kit can't load N exactly (:78). "lat pulldown 3x8 at 7" goes to the model (F2d), while "curl 3x10 at 12" still logs 12 kg.
- **L3:** `tess\s+(?=\d)` strips "Tess" before a number only, so "Tess 80 for 8" logs a set. "Tess dinner fri" and "Tess's birthday" keep their Tess. Tested.
- **Barbells, EZ and Smith bars** (lightest 20 or 10): every N ≤ 10 is below the bar, so it never writes N kg.

## F3 (should-fix): N that is itself a loadable weight on a machine or cable
- Machines and cables load in 5s, so in "leg press 5x5", "lat pulldown 10x10" and "cable row 5x10" N is a real load. `first < lightest` is false, and `light` is only for dumbbells and kettlebells (:58). So these log **5 kg × 5** or **10 kg × 10**. 5×5 and 10×10 are common schemes.
- The same holds with a last weight in focus. With Leg Press at 100 kg in focus, "leg press 5x5" logs 5 kg, because the half-the-last-weight ask (:59) is dumbbell-only.
- **Fix:** make `light` cover every non-bodyweight kit, with a higher threshold for machines and cables:
  `let light = first <= (kit == .machine || kit == .cable ? 10 : 6)`
  - In focus, N under half the last weight asks for the set count.
  - With no last weight, Tess asks "at what weight?".
  - Barbells are unaffected (always below the bar).

  Add rows: "leg press 5x5" asks; "lat pulldown 10x10" asks; with Leg Press at 100 in focus, "leg press 5x5" asks for the set count.
- **Same hole, low:** a custom equipment `increment` (FixedLoads strides from 0, so the lightest is the increment, often 2.5) and the band or no-kit default (2.5 steps). There, "3x8" logs 3 kg. No built-in exercise uses bands, so the rule above covers this if it applies to every kit except bodyweight.

Not data-unsafe: each case is one visible set with a receipt and UNDO.

## Addendum: new head f687e16 (F3 follow-up, rebased on 620878b)
Re-reviewed f687e16 (TessGrammar+Lift.swift, SetLossTests.swift). The rule the coordinator gave Core: on any non-bodyweight kit, a bare N×M with N ≤ 10 and no "at" or unit never writes N kg. It asks, or Q8's set-count ask decides when a last weight is in focus.

**Verdict: PASS with nothing in focus. One should-fix remains with a last weight in focus (F4).**
- **Nothing in focus: closed for every kit.** The block at TessGrammar+Lift.swift:51-61 no longer looks at detents or kit. Any non-bodyweight lift with a bare N ≤ 10, no unit and no last weight asks "at what weight?" (:55-57). That covers barbell, machine, cable, dumbbell, kettlebell, band, no kit and custom increments. Tested by F3a-F3d and F3g.
- **A unit said logs:** "leg press 5 kg x 5" logs 5 kg (`unitSaid`, set in `read` before the check; F3f).
- **"at N" off the kit's loads:** a small "at N" (≤ 12) that matches no detent, after converting pounds, now asks instead of going to the model as a time (:69-73). So "curls 3x10 at 5" asks (F3e) and "bench 3x5 at 7" asks (QA274, now an ask).
- **In focus, N ≤ 6 and under half the last weight:** the set-count ask, as in Q8 (:58-61). Tested for Bench at 80 and Leg Press at 100.

### F4 (should-fix): in focus, N from 7 to 10 still logs N kg
With a last weight in focus, the only ask is `first <= 6, first < last.weight / 2` (:58). Anything else falls through to the normal parse. So with Bench at 80 kg in focus, "bench 8x8" logs **8 kg × 8**, below the 20 kg bar. With Lat Pulldown at 55 in focus, "lat pulldown 10x10" logs 10 kg. The previous head caught the barbell case with its lightest-load check, so this is a regression for N from 7 to 10 below the bar.
**Fix:** inside the in-focus branch, ask for the set count whenever `first < last.weight / 2`, for any N ≤ 10 (drop `first <= 6` for a named lift; Q8's 6 stays for a bare "10x8"). If N is close to the last weight, it logs, which is right ("curls 8x10" at 10 kg last). Add rows: Bench at 80 in focus + "bench 8x8" gives the set-count ask; Lat Pulldown at 55 in focus + "lat pulldown 10x10" gives the set-count ask.

### Low
- **F5:** "bench 3 sets of 8 at 7" logs 3×8 at 7 kg. The sets-said path removes "at" (:12-16), so `weightAfterAt` is never set, and the small-"at N" ask at :69 doesn't apply. Set `weightAfterAt` when the "sets of" phrase is followed by "at N".
