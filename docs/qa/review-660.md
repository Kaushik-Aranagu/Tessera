# Review #660 (Core: key tail out of results, redirect lint narrowed)

Head 1372ea65, merge-tree clean against master ade45389. Static review. Design not needed (Product ruled the wording).

**Verdict: QA PASS at 1372ea65.**

## Checked
- ClaudeKeyCheck.Result is now { outcome, line, saved: Bool }. line(.works) is exactly "Key saved." and finish(...) never puts any part of the key in the result.
- ClaudeSection derives the tail itself from the keychain as an interim, and clears the clipboard only when result.saved and outcome is not badKey. Builder B's ios/key-no-tail PR removes the interim tail.
- noResultOrLineCarriesAnyPartOfTheKey builds the secret from pieces and checks every 4-character run against the result description across statuses and every outcome line.
- HouseRulesTests: roots widened (Sources, Features, App, Widgets, Shared, DesignSystem). A Claude file is one with any of the four markers. Every Claude request needs NoRedirects.shared. delegate: redirects is allowed once, in RecipeLinkReader.swift only. This matches my #656 asks, and each rule has a negative test.

## Lows (none block)
1. The view still reads the keychain for the tail until Builder B's PR lands. Make sure it is removed once and not reintroduced.
2. The key test covers the result and its lines, not the ledger or logs. Earlier reviews show the ledger holds the request id only.
3. The Claude-site set equality is brittle. HomeDoneWording.swift must stay conditional until #658 merges.
4. saved is true for post-save failure outcomes, same as the old non-nil last4. A one-line comment on the field would help.
