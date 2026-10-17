# Review #674 (Core: fileProtection option so tests pass on a locked Mac)

Head 17d287b3, merge-tree clean against master 0ec0ab3a. Package-only, no screen change. Design not needed.

**Verdict: QA PASS.**

- Both stores keep `.completeFileProtection` as the default: `TessMemoryStore.fileProtection` (init argument and property, both default complete) and `ClaudeHomeDone.fileProtection`. The forget-log write and the reapply write both use `[.atomic, protection]`; the Home cache write uses `[.atomic, fileProtection]`; the backup exclusion line after it is untouched.
- Production call sites: App/AppModel.swift:399 `TessMemoryStore(engine: engine)` and App/AppModel.swift:93 `ClaudeHomeDone(keys:ledger:cacheURL:)` pass nothing. A grep of everything outside Tests for `fileProtection:` or `.fileProtection =` finds only the definitions. Only the two test files pass `[]`.
- The new test asserts both defaults equal `.completeFileProtection`.
- Lows: both are `public var`, so a future caller could weaken them at run time; making them `let` where the tests don't need to change them, or adding a HouseRules scan that allows `fileProtection` assignments only under Tests, would pin that. CaptureMissLog's write is not touched by this PR (separate).
