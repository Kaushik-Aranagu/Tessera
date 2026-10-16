# Review #230: Claude key hardening (419d6de, head 466b0bb)

Core. 6 files, +108/-23, all in TesseraCore. Static review (no Swift toolchain here).

**Verdict: PASS.** K11 and K12 closed, F4 and F6 closed on the Core side. One should-fix in the app (H1, Builder B), two notes.

## Checked
- **Header:** `x-api-key` only, no `Authorization` (ClaudeKey.swift:287; tested). Anthropic's auth page: Bearer is the main method, "the legacy `x-api-key` header is still supported". Either works.
- **401 keeps the key:** the `keys.delete()` is gone; every outcome keeps it (tested across the outcome table). `last4` is now returned for `.badKey` too.
- **Shared guard:** `looksLikeClaudeKey` (Diagnostics/ClaudeKeyGuard.swift), `.caseInsensitive` range. Now used by TessRouter.run, TessCaptureEngine's miss-log check and `CaptureMissLog.record`. Tested with mixed case end to end through the capture engine.
- **Wrapped paste:** all whitespace removed, then `hasPrefix("<key prefix>")` and length > 12. Tested ("<key prefix>TEST-abc\n def-1234" → joined).
- **F4 `.notSaved`:** a refused Keychain save returns before any request. Tested (no request sent).
- **F6:** offline/timeout/busy lines no longer promise a retry; they say "I kept the key". Matches the code now.
- **K12:** empty path posts to `base` itself; the test now asserts both absolute URLs. Closed.

## K11: closed, matches my two-concurrent-calls test
- `reserve` checks `monthTotal + pendingNano + estimate <= cap` and adds to `pendingNano` in one synchronous call. `TessUsageLedger` is `@MainActor` (ClaudeKey.swift:85), so the static is main-actor isolated and check-and-hold can't interleave. That's the fix from review-218.
- `pendingNano` is static, which is right: ledgers are value types created per use, so an instance total wouldn't be shared.
- In the key Test's fallback, `defer { ledger.settle(reservation) }` runs at the end of the `if` block, right after `send` returns or throws. The row is written by `finish` later in the same synchronous stretch, so there's no window where neither the hold nor the row counts. Error and cancel paths release too.
- `twoCallsAtOnceCannotBothPassTheCap`: 60% then 60% → first holds, second nil; after settle a third fits. That's the test I asked for. It's synchronous on the main actor, so it can't race the other cap tests even though Swift Testing runs tests in parallel.
- **Note N1:** `canSpend` is still public and doesn't hold anything. Future planner/Ask callers must use `reserve`/`settle`, not `canSpend`. Worth a doc comment saying so, or making `canSpend` internal when T3/T4 land.

## How ClaudeSection behaves now that a 401 keeps the key
Traced against ClaudeSection.swift on master:
- **Replace with a bad new key:** Core saves the new key, gets 401, keeps it; the app sees outcome ≠ works and re-saves `previous` (:270). Old key restored. ✓
- **Replace that fails to save (`.notSaved`):** nothing changed in the Keychain; the app re-saves `previous` anyway. Harmless. ✓
- **First paste, bad key (H1, should-fix, Builder B):** the bad key now stays in the Keychain. The app shows `...last4`, opens the field again with "That key didn't work. Check it, or paste it again?". But `ClaudeKeyWords.status` maps `badKey` to the default **"not checked"** (ClaudeSection.swift:13-17). Every later visit (`load()` reads the last keyCheck row) shows "...1234, not checked" for a key that was checked and refused.
  - Fix: add `case .badKey: "didn't work"` (and decide `.notSaved`, which has no key to describe, so it can stay default). Keep Test again and REMOVE visible in that state so he can clear it.
- **First paste, `.notSaved`:** `last4` nil, field closes, line "I couldn't save that key. Try again?". He has to tap to reopen; minor. Better: keep `writing = true` for `.notSaved` as for `.badKey`.

## Notes
- **N2:** BottomChrome, LiveAskField and PasteRecipe still have their own key checks (PasteRecipe's is case-sensitive, C6). Now that `looksLikeClaudeKey` is public in TesseraCore, the app can call it directly and drop the copies.
- Is the real key safe to type now? Still yes, and more so: a good key can't be deleted by any outcome.
