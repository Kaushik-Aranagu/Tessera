# Review #218: Claude key store (2892ac1, head 5a24f54)

Core. 6 files, +522/-2. Static review: I read the code but couldn't build or run it, because there's no Swift toolchain here. Checked against research/claude-key-test.md and settings-claude.md, and Product's calls ($10 fixed cap, Test on paste, REMOVE as a tap with 10 s UNDO).

**Verdict: PASS.**
- The key doesn't reach any log, op, object, backup or export in this PR.
- The cap is correct for a single call but isn't a hard stop when calls run at the same time (K11). Only the key Test spends today, so that doesn't block this PR, but it must be fixed before the first real Claude use ships.
- Two lows and two notes for the app side.

## Where the key could leak, all checked
- **Storage:** Keychain only. Generic password, `WhenUnlockedThisDeviceOnly`, `kSecAttrSynchronizable false`. It's read once into a local and goes only in that request's `Authorization: Bearer` header.
  - I checked the header choice against Anthropic's authentication page today: Bearer is the documented header for API keys, and `x-api-key` is legacy. Pricing for `claude-haiku-5-5` is $0.10/$0.50 per MTok, which matches 100/500 n$ per token.
- **Network:** an ephemeral `URLSession`, so nothing is cached.
- **Tess Call rows:** they hold use, model, tokens, cost, latency, outcome and request ID, never the key. They're written with `store.create`, with no op, so undo and the op log never see them.
  - Backups copy the SQLite file. A device-only Keychain item isn't in any backup or export.
- **Errors:** the outcome is mapped from the status, `error_code` and one documented message prefix. Nothing from the response body is shown or stored, and caught errors aren't logged.
- **Paste screen:** `notAKey` returns before saving or sending. A 401 deletes the key. `last4` is the only part kept for display.
- **Ask bar:** `TessRouter.run` refuses any text containing `sk-ant-` before any route runs, so it never becomes a note and so never reaches a backup.
  - The miss log is guarded twice: in TessCaptureEngine, and inside `CaptureMissLog.record`.

## K11 (should-fix before T3/T4): the cap isn't a hard stop when calls run at the same time
- **The problem:** `canSpend` (ClaudeKey.swift:110) only adds up rows already recorded, and a call's row is written after its response arrives (`finish`, or the future planner's `record`). So two calls that start before either finishes both pass at $9.99. The month then goes over $10 by whatever was in flight.
  - The ledger is `@MainActor`, but there's an `await` between the check and the record, so being on the main actor doesn't help.
  - Today only the key Test's 1-token fallback spends, so the overshoot is tiny. The first planner or Ask use makes it real.
- **The fix:** reserve, then settle.
  - Add `reserve(estimate) -> Reservation?` on the ledger. It checks `monthTotal + pending + estimate <= cap` and adds to an in-memory `pending` total in the same synchronous call. Because that call has no `await`, it's atomic on the main actor.
  - After the call, record the real cost and release the reservation. On error, cancel or timeout, just release it.
  - The estimate must use `max_tokens`, which covers thinking: Haiku 5.5 thinks by default.
- **Test:** two concurrent fake calls, each estimated at 60% of the remaining budget. Exactly one should run.

## Lows
- **K12:** the moved-endpoint fallback posts to `base.appendingPathComponent("")`. On Foundation that most likely gives `/v1/messages/`, with a trailing slash, which the API can 404. The result would be "I couldn't check that key" in exactly the case the fallback exists for.
  - The stub test doesn't check the path.
  - Fix: `path.isEmpty ? base : base.appendingPathComponent(path)`, and assert the URL in `aMovedEndpointFallsBackToOneTokenAndIsPriced`.
- **K13:** `cost` uses the up-to-100K price. Haiku 5.5 charges $0.50/$2.50 above 100K input tokens. That can't happen for the Test, but a long Plan-my-day context could under-count. Add the tier when the planner lands.

## Notes for the app side (Builder A, Settings: Claude)
- **REMOVE with 10 s UNDO:** keep the removed key only in memory for the 10 s and call `keys.save` again on UNDO. It must never go through ActionEngine or an op, because an op would put the key in the op log and every backup after it.
  - Clear the in-memory copy when the window closes.
  - The field shows `...last4` only.
- **Tess Call rows** are ordinary `.thing` objects with no hidden flag. Any page that lists all objects (search, recents, an "everything" view) must exclude the Tess Call class, or every key Test shows up as a "keyCheck call" item.
- **Other free-text inputs** don't go through the router guard: the recipe paste screen, and typing inside a note. Pasting a key there would store it. That's low risk, since he'd have to paste it on purpose. The same `sk-ant-` refusal could go in PasteRecipe's parse.

## Product calls
- **$10 fixed cap:** done, `capNano` is a constant. At the cap a working key reads "Key saved. Claude paused until Nov 1." (the 1st of next month, local midnight). Tested.
- **Test on paste:** `test(pasted:)` saves the key, then checks it with free `count_tokens`. Each of K1–K10 has a one-line Tess message, with no "!" and under 12 words.
- **REMOVE:** `delete()` exists. The UNDO is app-side, as noted above.
