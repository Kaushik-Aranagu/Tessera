# QA review: #654 (Core, my #644 lows + HouseRules lint)

Head: 820ee948. Merge-tree clean on master. 3 files, +46/-4 (PrivateFacts, new HouseRulesTests, WallsBypassTests). Package only.

## Verdict: PASS at 820ee948 (lows, none blocking)

### #644 lows closed (hand-traced)
- "Push B 5x5 80 for 8" at 82: withoutNotation now treats any phrase that already held an N x M set (`crossed != lower`) as lifted for the for/by form, so "80 for 8" is stripped and the title stays plain. Test asserts it at lastWeightKg 82.
- "bench day 82.4 kg this morning": numbersBesideALift now counts a number only when a lift name is the word right before it, or right after it with at most a body unit between ("bench 82.4", "82 kg squat"). "day" breaks the adjacency, the guard is off, the band rule walls it at 82 and the kg + decimal rule walls it with no weigh-in. Both asserted; "82 kg squat" stays plain at 82.
- Over-wall side effect (fails closed): "squat at 82 kg" or "squat day 82" now count as his weight when the weigh-in is near 82. Acceptable.

### HouseRulesTests lint: right idea, too narrow to hold the line
It reads TesseraTess sources and fails when a line containing `session.data(for:` or `session.bytes(for:` lacks `delegate:`. Gaps, any of which lets a fifth Claude call skip NoRedirects without failing:
1. Only those two spellings on one line. `urlSession.data(for:`, `self.session.data`, `session.upload(for:`, `.download(`, `.dataTask(`, `URLSession.shared.data(from:)`, or a call whose `delegate:` argument moves to the next line (a false positive) are unmatched or mishandled.
2. It accepts any `delegate:`, not NoRedirects: the page fetch legitimately passes its own redirect delegate, but a Claude call with some other delegate would pass.
3. Only TesseraTess is scanned; TesseraIntents, the app target and other TesseraCore folders are not.
Fix: scan Sources, Features and App for the regex `\.(data|bytes|upload|download|dataTask|uploadTask|downloadTask)\(` on any receiver plus `URLSession.shared`, join each statement over the next two lines before looking for `delegate:`, assert any file naming `anthropic.com` or `ClaudeKeyCheck.base` passes `NoRedirects.shared` at every request, and assert that the four known sites exist (count == 4) so a rename can't empty the lint. Add one negative test that feeds the checker a string without a delegate and expects a hit.

### Lows
1. `crossed != lower` is phrase-wide, not adjacent: "weighed 82 kg for 3 days after 5x5 bench" strips "82 kg for 3" because a set appears anywhere, and a surface with no weigh-in on file would then miss the weight. Contrived; tighten to a for/by form within a few words of the set token if it ever shows.
2. The 82-band pack row for "Push B 5x5 80 for 8" is asserted on isWalled only; add the pack row (lastWeightKg 82, expects a pack) so the done-pack path is pinned too.
