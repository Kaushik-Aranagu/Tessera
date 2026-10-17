# Review #665 (Core: small lows from #641 and the key test, TessGrammar under the complexity limit)

Head dc324dd9, merge-tree clean against master 789be4eb. Static review. Nothing changes on screen, so Design is not needed.

**Verdict: FIX FIRST (one item). The rest is PASS.**

## FIX FIRST
`AppModel.launchDefaults` adds a raw `ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"]` read in App/AppModel.swift:85.
- Our data-safety rule is no raw ProcessInfo reads outside LaunchFlags. `scripts/ops/premerge_check.py` also treats an added `ProcessInfo` in a non-test Swift file as a STOP (reports only for tests), so the premerge check fails this PR.
- Fix (either): (a) pass the defaults in. `AppModel.init(context:launchDefaults: UserDefaults = .standard)`, and the app tests pass a throwaway suite. No environment sniffing, and the phone path is `.standard` by construction. Or (b) `NSClassFromString("XCTestCase") != nil` instead of the environment read. I prefer (a).

## Checked, correct
- writeFirstRestWeekday: the key is set whether or not the write succeeded; the guard branch still decides. This closes my #641 low (a failed write rescanned the op log on every launch). A failed write now means Sunday is not set and not retried; that is accepted and noted in the comment.
- `-resetDemo` removes the key in TesseraApp, behind LaunchFlags (simulator-only). Under any demo flag AppModel skips the write entirely (`!demo`), so the removal just lets the next normal simulator launch decide again. Harmless. The removal runs after AppModel.init, which does not matter for the same reason.
- TessGrammar.parseBeforeTasks returns `Parse??`: `.some(x)` is a parse, `.some(nil)` is the question (no write), `nil` is "none applies". The switch in `parse` maps all three correctly and the rule order is unchanged (note, recipe, question, rest weekday).
- ClaudeKeyTests: the prefix is built from two pieces; the assertion is the same.

## Lows
1. The throwaway suite leaves a plist per test run; `removePersistentDomain(forName:)` in teardown would tidy it.
2. The doc comment on parseBeforeTasks has an odd line break.
3. App tests still queued on the lock; the PASS needs the app count.

## Delta d813e40e: PASS
AppModel.init(context:launchDefaults: = .standard); the static ProcessInfo read is gone (grep of AppModel and TesseraTests: no ProcessInfo). Every `AppModel(context:` call in TesseraTests passes `.testSuite()` (grep finds none without it). testSuite() removes its persistent domain on each call, so no plist piles up. Low: the suite name is fixed, so parallel tests can wipe each other's decision mid-run; harmless, since each wants a clean decision.
