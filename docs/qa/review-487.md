# Review: #487 ios/fake-key-hygiene (Builder B)

QA, Oct 16 2026, ~12:55 PM PT. Head **542234f**, one commit and one file (Features/Settings/ClaudeSection.swift). It merges cleanly onto master. This is a static review.

## Verdict: PASS

- **No key-shaped literal is left in app code.** The fake key is now `ClaudeSection.fakeKey`: the two prefix halves joined, followed by 32 x's, built at run time. It sits inside `#if DEBUG` (ClaudeSection.swift:40-45). A grep for the key pattern over App/, Features/ and DesignSystem/ at 542234f finds nothing.
- **It can only be reached through the simulator path.** `fakeKey`'s only caller is `defaultKeys` (ClaudeSection.swift:51). There it sits behind `LaunchFlags.has("-fakeClaudeKey")`, and `LaunchFlags.allowed` is `true` only under `#if targetEnvironment(simulator)` (App/LaunchFlags.swift:8-14). Every other path returns `SystemKeychain()`. On his phone's Debug build the flag reads false, so the fake key is never built there.
- **It never touches the real key field, the Keychain or the ledger.** It only ever goes into `InMemoryKeychain`, never `SystemKeychain`. The same flag counts as a demo flag in AppModel.swift:119, which skips the settings migration and keeps Claude unwired. Nothing writes to the ledger without a call.
- **It is never printed or logged.** ClaudeSection.swift and ClaudeKey*.swift contain no `print`, `Logger`, `os_log`, `NSLog` or `dump`. The UI shows only the last four characters.

## Lows

- **R1:** The last four characters on screen are now "xxxx" instead of the old ones. Two places still name the old last four: the comment at ClaudeSection.swift:7, and Research's docs/research/install-day-script.md step 20 ("Key ends in ...", the expected line). Update them both on a later pass. The UITests don't assert on them.
