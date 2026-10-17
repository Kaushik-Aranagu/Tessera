# QA review: #656 (Core, notation lows + wider no-redirect lint)

Head: 859767a8. Merge-tree clean on master. 4 files, +98/-20 (PrivateFacts.withoutNotation, HouseRulesTests, two test files). Package only.

## Verdict: PASS at 859767a8 (lows, none blocking)

### Notation lows closed (hand-traced)
- "80 for 8" counts as part of a set only when it sits directly beside an N x M token (setBesideFor: set then for-form, or for-form then set); a lone N x M elsewhere no longer strips it. "weighed 82 kg for 3 days after 5x5 bench" keeps its 82 and is walled at 82 and with no weigh-in; "5x5 80 for 8" strips; "5x5 80 for 8 days" keeps the 80 (a time word after the second number makes it a span, never a set). The for-form with a lift named, and the reps form, are unchanged.
- Pack row W14b: "Push B 5x5 80 for 8" at lastWeightKg 82 gives a pack. The patterns are valid Swift regex (lookahead, grouping, top-level alternation); they are static try! like namedNumber and run in the 575 tests.

### Lint: much better, one deviation ruled
Scans TesseraCore/Sources, Features and App; request calls are `.data(for:`, `.data(from:`, `.bytes(for:|from:)`, `.upload(for:`, `.download(for:`, `.dataTask(with:` and any `URLSession.shared`, on any receiver; the statement is the line plus the next two; a Claude file (names the host or ClaudeKeyCheck.base) needs `NoRedirects.shared` at the call; the four known Claude sites must exist; four matcher cases are tested (bare, split, shared, wrong delegate in a Claude file).
Ruling on the RedirectGuard deviation: ACCEPT, tighten when convenient. RecipeLinkReader.swift legitimately fetches the recipe page with its own per-hop RedirectGuard and no key. The lint allows `delegate: redirects` in ANY Claude file, for any call, not only the page fetch. Narrow it: allow it in RecipeLinkReader.swift only, and assert counts (exactly four NoRedirects.shared request statements, exactly one `delegate: redirects` and only in that file).

### Lows
1. Roots miss Widgets, Shared and DesignSystem (the repo top level also has Resources and tools); a widget or shared helper that calls Claude would not be scanned. Add Widgets, Shared and DesignSystem to the roots; none uses URLSession today.
2. A Claude file is detected by the host string or ClaudeKeyCheck.base only. A file that builds the URL another way (host in a config, joined pieces) but sets the key header would count as non-Claude and could pass with any delegate. Also treat a file that names "x-api-key" or "anthropic-version" as a Claude file.
3. `.download(from:)`, `.uploadTask(with:)` and `.downloadTask(with:)` are not in the call list; add them. Calls with `delegate:` more than two lines below fail (fails closed, fine).
