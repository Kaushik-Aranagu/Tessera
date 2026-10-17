# Review: PR #305, TessInbox "Waiting for Tess" (head 803f6da)

QA thread, Oct 15 PT. Static review (no Swift toolchain here). Files: `TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift`, `TesseraCore/Sources/TesseraTess/ClaudeTessModel.swift`, `TesseraCore/Sources/TesseraTess/TessInbox.swift` (new), `Tests/TesseraCoreTests/ClaudeRouteTests.swift`. Base 5950350. It doesn't overlap the #303 files now on master.

**Verdict: FIX FIRST (one fix, S1).** The v5 migration is additive and launch-safe, and nothing waiting is sent without "Tess asks Claude". But reading the inbox throws away phrases Claude never read.

## 1. v5 migration on an existing v4 store: PASS

- The only catalog change is a new class, `tessWaiting` ("Waiting for Tess", parent Thing, one date field `saidAt`), at SystemCatalog.swift:23 and :236-239, plus the version going from 4 to 5 at :319.
- `seed(in:)` (:331 on) inserts a missing class with a stable id and adds missing fields. A version bump only refreshes names, symbols and colours on classes he hasn't edited. That's the same path v4 took for settings. No objects or values are rewritten, and nothing is removed.
- Launch: seeding runs inside the existing lifecycle (`ObjectStore+Lifecycle.swift:17` and the `try?` at :68). Nothing new can throw on launch.
- Rollback: a v4 build opening a v5 store skips unknown system keys (`SystemCatalog.swift:433`, `continue`), so the rollback rule holds. Waiting rows just sit there unseen.
- Low (L1): there's no test that seeds v4, then v5, and checks that the existing objects and the settings row are unchanged. Worth one test in a later PR; not blocking.

## 2. Nothing waiting is sent without the switch: PASS

- Queueing happens only inside `ClaudeTessModel.run`, in the offline catch (ClaudeTessModel.swift:110-113). The router only calls a model whose `isAvailable` is true (TessModel.swift:73). `isAvailable` (ClaudeTessModel.swift:45-46) needs a key, `sendsMisses()` (the "Tess asks Claude" switch, read at each call) and no pause. So with the switch off nothing is queued.
- `readWaiting` (TessInbox.swift:55) checks `claude.isAvailable(for: .capture)` before every item. If he turns the switch off after a phrase was saved, the phrase stays on the phone and is never sent.
- Siri and Shortcuts: `readWaiting` returns early on `commitImmediately` (:52), `run` refuses them (ClaudeTessModel.swift:51), and each request is forced to `commitImmediately = false`. Tested in `nothingWaitsForSiriAndAKeyNeverWaits`.
- Key: `add` refuses any text containing "the Claude key prefix", anywhere in the phrase and in any case (ClaudeKeyGuard.swift:5-6). Tested.
- Duplicates: the same phrase waits once (tested).
- Each read is a normal `run`: it reserves against the $10 cap, writes a ledger row, and the result comes back as pending ghosts that he has to keep (tested: `state == .pending`).

## 3. S1: readWaiting drops phrases Claude never read (must fix)

At TessInbox.swift:62-69 only the offline line keeps a phrase. Every other `.asked` result removes it, and all of these are failures where Claude gave no answer:
- busy: "Claude is busy right now."
- timeout
- bad key
- "Didn't catch that." (other)
- "Claude paused until …", when reserving fails near the cap even though `isPaused` was still false (ClaudeTessModel.swift:57-61)

So "No connection. Saved it for Claude." can end up quietly losing the phrase on the next open if Claude is busy or the key has lapsed.

Fix: remove a phrase only on `.handled` or `.missed` (Claude replied, whatever it made of it). On any `.asked`, keep it and stop the loop the same way the offline case does. Timeout is the one case that might have been paid. Keeping it is still better than losing it, because the next try is one call. Add a test: 529 on read, then `waitingCount == 1`.

## 4. Lows (not blocking)

- L2: a waiting row is an ordinary Thing object in the store (it is written without ops). Builder B should leave it out of generic Thing lists and search, the same way `tessCall` rows are handled, and show it only as "1 waiting for Tess".
- L3: waiting phrases live in the database, so they go into backups, unlike the miss log. That's fine because it's his own words, but it's worth one line in the backups section of the docs.
- L4: when the switch is off, phrases already waiting stay forever. Builder B could show them with a way to clear them.
- The old line "No connection, so Claude didn't see that." still shows for a retry that is offline again and when queueing is refused (a key or a duplicate). Fine.

## Must fix before merge
1. S1: keep the phrase on every `.asked` failure (busy, timeout, bad key, other, paused), plus a test.

## Addendum: head 252708c (GitHub head confirmed), S1 CLOSED, now PASS

- TessInbox.swift:61-71: `.handled` removes the phrase and returns the capture, and `.missed` removes it (Claude read it and made nothing of it). Any `.asked` result (offline, busy, timeout, bad key, other, cap) keeps the phrase and stops the loop.
- `.missed` can only come from a reply here. `run` returns it early only for `commitImmediately` (forced false here) or a missing key (blocked by `isAvailable`), and it maps every send error to a `Failure`, which becomes `.asked`.
- Test: a 529 on read leaves `waitingCount == 1` and returns nothing. The later online read still empties the inbox.
- The lows L1-L4 stand and are not blocking.
