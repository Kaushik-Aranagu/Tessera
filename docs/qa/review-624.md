# QA review: #624 Research, fixtures/home-pack-walls.md (W1 to W14)

Head 1ca0076. Docs only (the fixture file and one README line). Reviewed at walls depth against Product decisions 7:31 PM, docs/ai/home-pack-walls-audit.md (A2) and the code on master/engine-wall.

## Checks
- Key-shaped text: none. No key prefix, no long token; the only "secrets" are made-up phrases (tacocat, 0000, 4417, 1234, "Locker code"), which the house rules allow.
- Rows W1-W8 and W10-W11 match the A2 audit section 3 (same inputs, no call on a trip, call on the control cases). Gap 1 (any field trips means no call, never a partial pack), gap 2 (`numbers` from facts and clock digits only), gap 7 (decimal or 3-plus digits refused unless training notation) are all represented.
- 7:31 rulings applied correctly: W13 "heart rate" walls beside 5x5 (predicate change); W9 gap 7 for the Home pack only; W12 skip before the wall; W14 title with notation numbers passes, any wall hit is no call.
- Predicate notes check out against engine-wall: W8 "Morning 82.2" is walled by the day-word rule even with no lastWeightKg; the bare-weight 10% rule adds the lastKg case.

## Fixes (small, fixture text only)
1. **Hard-fail strings that can appear in the request for other reasons.** `$` (W7), `heart` (W13), `sick` (W11) and `Locker` (W2) are matched against "the captured request body, all roles, tool schema included". The system prompt (VOICE + DONE_RULES) and the job doc list the forbidden word classes (health, money), so a generic `heart`/`sick`/`$` can be present in a correct request and fail a correct implementation. Use the full fixture token instead: `$40`, `heart rate day`, `sick, bp`, `Locker code`, and say the scan covers the user-controlled fields (title, bests, names, numbers) plus the encoded body for the full token.
2. **W14's hard-fail column changes meaning.** Every other row is a string absent from the request body; W14 says "digits 80 in `numbers`", while the 7:31 ruling lets the title (with 5x5 80 for 8) ride in the pack. Say so: hard-fail is "5, 80 or 8 in the `numbers` array" and the title string "Push B 5x5 80 for 8" is expected in the body.
3. **W12 tests the wrong path.** Its suggested test name (`...TitleHasSecretWord`) passes whether or not the skip-before-wall rule exists. Split: W12a a 0-set workout with the secret title (assert the skip path, no call, and that the wall function is not reached); W12b the same title with sets and a best (the wall path). Also say "Expected: no call (skip)", not "Wall holds".
4. **Add W15 (key-shaped title).** A routine named with a Claude-key-shaped string must never reach the pack; `looksLikeClaudeKey`/withoutClaudeKeys is the wall for it, and A2 has no row for it. Use a made-up non-key phrase in the fixture and describe the case in words (do not put a key-shaped literal in docs).
5. **Add W16 (renamed routine).** A2 section 4 names `renameObjectOnRoutineStillReachesPackWallWhenSourceUnwalled`, but the fixture table has no row for a title renamed after creation (RenameObject is exempt at the engine). One row: routine "Push B" renamed to "Gym pin 1234 day", expect no call.

Verdict: PASS with fixes 1-3 (text); 4-5 are additions Core's 0al tests will want. None blocks merging the fixtures, but fix 1 should land before Core copies the hard-fail strings into tests.
