# QA review: #644 (Core D1, set notation covers only its own token)

Head: 4110015d. Merge-tree clean on master 51848c3f. 4 files, +124/-6 (HomeDonePack, PrivateFacts, two test files). Package only.

## Verdict: FIX FIRST (1 medium: a new global lift-word guard re-opens weigh-ins), rest PASS

### What works (hand-traced against the regexes)
- withoutNotation strips only the set token (NxN, "80 for 8" up to 3 and 2 digits, "N reps"), then money and body are read on the rest. "Weigh in 182.4 lb 5x5" (bare-weight, body word + decimal), "Rent 1850 for 5x5" (amount + money word), "paid 40 for 5x5 class" (spend), "Morning 82.4 5x5" (decimal + only day words) and "Locker 4417 by 2" in the pack (the by-rule needs a 1-3 digit bar, so 4417 stays and trips the 3-plus digit rule) are all walled.
- "Bench 82.4 kg 5x5", "bench 82.50 x 8", "Push B 5x5 80 for 8" and "80 for 8" stay plain inside his band: the set token is removed, and a lift named beside the number makes it the bar.
- Pack: weigh word or bmi with any number walls; build(store:) reads his weight itself; the internal lastWeightKg overload is test-only; walled rows assert no pack at all; structural Mirror test pins the eight fields; W13 vitals reach every surface.

### Medium: the lift-word guard in isBareWeight is too broad and runs on every surface
PrivateFacts.isBareWeight now returns false whenever the phrase names any word in the new PrivateFacts.liftWords and no weigh word, before the band check. That list includes everyday words: push, pull, lift, bar, carry, hip, leg, legs, calf, fly, raise, chin, clean, press, row, dip, set. Regression versus master:
- "82.4 kg this morning, leg day after" with last weigh-in 82: band rule used to wall it; now isBareWeight is false, and the later unit/decimal rule needs every other word to be a day word ("leg", "day", "after" are not), so it passes.
- Same with no weigh-in on file: the "body word + decimal" rule is skipped by the same early return.
- "was 82.4 low before push day?" is the same path. These reach the router, notes, tasks and Claude, which is the walls class that must fail closed.
Fix: apply the guard only when the lift word is adjacent to the number (within two tokens before it, or directly after its unit), and only for real lift names (squat, bench, deadlift, ohp, press, row, curl, lunge, rdl, snatch, pullup, dip, thrust). Drop the generic words from the guard (push, pull, lift, bar, carry, hip, leg, legs, calf, fly, raise, chin, clean). They can stay in the pack's barOfASet check only if that also requires adjacency. Add rows: "82.4 kg this morning, leg day after" and "was 82.4 low before push day?" walled with lastWeightKg 82 and nil; "squat 82 kg" and "Bench 82.4 kg 5x5" plain at 82.

### Lows
1. Pre-existing, not new: the for/by notation strip has no rep context, so "weighed 82 kg for 3 days" loses its number to withoutNotation and may pass (the old isTraining guard had the same hole). Require "reps" after the count, or a lift word, or an x form for the for/by variants.
2. "Morning push 82.4 5x5": with "push" counted as a lift, the pack's barOfASet strips "82.4 5x5" and the title is not walled; goes away with the medium fix.
3. Rows N3/N4 are good; add the two medium rows above in WallsBypassTests so the guard is pinned on a non-pack surface.

## Re-verify at c9673b15: PASS (merge-tree clean on master ed1df369)
Medium closed. isBareWeight's bar guard now needs every number in the phrase within two words of a real lift name (liftNames: squat, bench, deadlift, ohp, press, row, curl, lunge, rdl, snatch, pullup, dip, thrust) and no weigh word. Traced: "82.4 kg this morning, leg day after" and "was 82.4 low before push day?" have no lift name, so the guard is off and the band rule walls them at 82; "squat 82 kg", "Bench 82.4 kg 5x5", "bench 80 for 8" stay plain at 82 and nil. A second number away from the lift keeps the guard off (fails closed). for/by is a set only with reps after or a lift named, so "weighed 82 kg for 3 days" keeps its 82 and is walled (tested). The pack's barOfASet uses liftNames too.

Ruling on Core's deviation: ACCEPT. With no weigh-in on file, "was 82.4 low before push day?" stays plain, because a decimal then walls only beside a body word or unit (BN04 walled, BN05/BN06 plain). That is the existing Product rule, not new; the "kg" variant is walled with nil, as the test asserts.

Lows (not blocking):
1. "Push B 5x5 80 for 8" is no longer plain inside his band. Core's example list says it should be, but the by/for strip now needs reps or a lift, and "Push B" is not a lift name, so "80 for" reads as 80 with unit "for" (not in otherUnits); with a weigh-in of 82, 80 is within 10% and the title is walled (isBareWeight true). It fails closed, so only a missing Claude line, but the test was quietly swapped to "bench 80 for 8" and the W14 pack row runs at lastWeightKg nil. Fix: when the phrase already had an NxN token stripped, treat a following "N for M" as part of the set, or add "for" and "by" to otherUnits; add a row "Push B 5x5 80 for 8" at lastWeightKg 82 expecting a pack.
2. "bench day 82.4 kg this morning" (a lift name within two words of the number, no weigh word) is still read as a bar. Contrived; tighten to "lift name directly before the number or after its unit" if it ever shows up.

## Merge re-check at b1e8103c: PASS (merge-tree clean on master f1283c87)
Core merged master 5e2769f4 (which carries #638) instead of rebasing. Checked only the resolution: PrivateFacts now holds #638's isCountNoun and notNouns once, beside #644's withoutNotation, liftNames and numbersBesideALift; isBareWeight's number guard reads `!otherUnits.contains($0) && !isCountNoun($0)` and keeps the new lift-adjacent guard. HomeDonePack.swift is unchanged since c9673b15. WallsBypassTests keeps both test blocks with no duplicate @Test names. No other source file differs from the c9673b15 review. The two lows from c9673b15 stand.
