# Offline inbox drain (G648) and the 8 s cap (G655): build spec and test vectors, plus the #1066 handle check

For: Product, then Core (drain, cap, log rows) and Builder B (the lines, Now and Receipts). From: AI architecture. Docs only: no Claude calls, no key use, no key content. Read against master f5fd3a8 and Core's #1066 at db1cd77b. **[code]** = read in Swift; **[ruling]** = from Product's relay of decisions 3:58 PM Oct 18 and 4:xx PM Oct 19 (those entries are **not on master yet**, so the wording below is Product's summary, to be matched against `decisions.md` when it lands); **[proposed]** = my call where no ruling or sheet exists.

**Rulings used (stamps: decisions 3:58 PM Oct 18 and 4:xx PM Oct 19; `decisions.md` on master lags, so Product confirmed the wording by message on Oct 19 and the answers below are final, not defaults):** a log row exists only when a request really goes out; a drained phrase writes one row; walls are re-checked at read time; a waiting phrase is deleted after it is sent; seven days at most; Cancel on the wait.

## 0. The drain is already wired (the gap-hunt row is stale)

`docs/research/fixtures/gap-hunt-23-claude-layer.md` rows 2 and CL32 say `readWaiting` has no caller. It has one: `AppModel.drainWaitingPhrases()` (`App/AppModel.swift:292`), called on every foreground (`App/TesseraApp.swift:95`), guarded by no pending ghost, no workout on screen and `waitingCount > 0`. It lands at most 3 ghosts per drain (`TessCaptureEngine.maxDrainedGhosts`), oldest first, expires after 7 days (`TessInbox.maxAge`), re-checks walls and the cook/timer hold per item (`readWaiting`), and removes an item once Claude read it (the `switch` on the result). What is **missing** against the rulings is listed in section 5 (rows D1 to D6). G648 is half built, not unbuilt.

## 1. State machine of one waiting phrase

States: **Typed**, **Queued**, **Checked**, **Sending**, **Removed**.

| From | Event | To | Writes | Shown |
|---|---|---|---|---|
| Typed | Claude route fails offline (before any connection), not a retry, phrase passes the add-time walls | Queued | One `Waiting for Tess` object (no op). **No Tess Sent row, no Tess Call row** [ruling, D1] | Ask slot: "No connection. Saved it for Claude." |
| Typed | Offline and the phrase is walled, secret-worded or key-shaped | (nothing) | Nothing queued, nothing logged | "Couldn't read that offline. Try again online." Text stays in the box |
| Queued | Foreground, switch on, key present, not paused, no ghost pending, no workout | Checked | Nothing | Now line "1 waiting for Claude" (section 3) |
| Queued | Seven days old at any foreground, whatever the switch | Removed | Nothing | Nothing (a count that drops) |
| Checked | Secret word, money, body fact or key shape **at read time** (walls re-run now, not trusted from add time) | Removed | Nothing | Nothing. It never leaves |
| Checked | Contains "timer", or a Cook is the running process | Queued | Nothing | Count stays. Never sent while that holds |
| Checked | Passes | Sending | Task starts with an 8 s deadline (section 4) | Drain line "Asking Claude" with CANCEL |
| Sending | A connection was made and Claude answered (ghosts, or read and understood nothing) | Removed | **One Tess Sent row and one Tess Call row** | Ghost(s), or nothing. Receipt rules in section 3 |
| Sending | Connection made, then busy (429, 5xx), bad key, no answer by the deadline | Queued | One Sent row and one Call row for that attempt [ruling: the request really went out] | One quiet line (section 3). O1 ruled: kept |
| Sending | Went offline again before any connection | Queued | Nothing | Nothing |
| Sending | CANCEL | Queued | If the body had been handed to the network: one Sent row and one Call row, outcome "cancelled"; else nothing | Line gone, count unchanged |
| Sending | Month cap reached | Queued | Nothing (a reserve that fails writes no request) | "Claude paused until Nov 1." once; counts as held back |

**O1 (ruled, Product Oct 19).** Keep the phrase after a busy or timed-out attempt; delete it after a successful send or at 7 days. Each real attempt that left writes its own Sent row. So: **delete on any answer; keep after busy, timeout, bad key, cancel (up to 7 days)**, as master does.

Rule that closes a loophole: a phrase that hits **Sending** twice for the same cause (two timeouts in a row) stays Queued but is not retried until the next foreground, never in a loop. The drain runs on foreground only, never on a timer [code, `readWaiting` doc comment].

## 2. Where a row is written (the "really goes out" rule)

A Tess Sent row and a Tess Call row are written **when a request was handed to the network and a connection was made**, and not otherwise.

- **Writes a row:** HTTP answer of any status, a timeout after connect, a cancel after the body was sent.
- **Writes no row:** not-connected / no route (`URLError` offline before connect), refused by a wall, too long, month cap, switch off, no key, Siri/Shortcuts, cook/timer hold.
- Today #1066 writes a Sent row on **every** failure including offline (`ClaudeTessModel.swift` diff: `logSent` after `ledger.record` in the `catch`), which breaks the rule: see D1. Ruled Oct 19: drop both the offline Sent row and the offline Call row. QA's `qa/review-1066.md` notes the same, and that the retry logs it a second time.
- A drained phrase writes **exactly one** row per attempt that went out, stamped with the **send time**, not the time he said it. The words are the phrase as stored.

## 3. What shows on Now and in Receipts

**Now** [proposed]. A waiting phrase is not a task and not a ghost, so it does not get a row. One quiet line under Tess's line, only while the count is above zero: **"1 waiting for Claude"** ("3 waiting for Claude"). Tap opens a short list of the phrases as he said them (they are unwalled by construction) with a **DROP** per phrase (`TessInbox.remove`) and one **DROP ALL** (`clearWaiting`, built but unused). No badge, no colour change, no haptic. Gone at zero. In Low Power the line still shows and the drain runs on the next foreground as normal. Nothing here ever shows a walled phrase's words.

**The drain wait** [proposed, same component as the live wait]. While a drained request is out: one line "Asking Claude" with CANCEL, the same line the live Ask wait uses (section 4). For a lone phrase the result keeps its own line; for two or more, "Offline, 2 read." [code `AppModel.swift:305-307`].

**Receipts** (Settings, Claude, Receipts). A drained phrase is an ordinary capture row: "A capture", newest first, the send time, model, cost. No "drained" word, no "offline" word. A timed-out attempt shows "A capture - Haiku - under 0.1 cents" with the ledger's outcome word. The Sent layer under a row shows the phrase as stored, or **"Private phrase"** if a wall catches it at log time (it cannot get there through the inbox, but live captures can).

**What was sent.** One row per attempt. Two attempts for one phrase are two rows with two send times.

## 4. The 8 s cap (G655)

**Today** [code `ClaudeTessModel.swift:23, 270`]: `timeout = 8` is `URLRequest.timeoutInterval`, an **idle** timeout per request, and the loop runs up to three rounds, so a slow reply can hold the Ask slot for about 25 s with nothing to tap.

**Build:**
1. **One deadline for the whole capture**: `deadline = start + 8 s`, shared by all rounds. Each `send` gets `timeoutInterval = min(8, deadline - now)`; before each round, if `deadline - now < 1 s` stop. Tool work between rounds is local and counts against the same clock.
2. **At the deadline:** discard any ghosts already made (as the current catch does), write the Call row with outcome `timeout` and the Sent row (the request went out), and answer **"Claude didn't answer in time."** [code `:260`, existing line]. Nothing is retried. The live phrase is **not** queued (only an offline failure queues); his text stays in the box.
3. **"Asking Claude" with CANCEL** appears as soon as the request is built, not after a delay, and goes when the call ends. CANCEL cancels the task: no ghosts, no line, text stays, the Sent and Call rows are written only if the body was already sent (outcome `cancelled`). Reduce Motion and VoiceOver: the line is announced once ("Asking Claude. Cancel"), CANCEL is a button in the Ask slot's order. Siri and Shortcuts never send, so no line.
4. **Drain uses the same cap** per phrase (8 s each, not 8 s for the lot), and the same line with CANCEL; CANCEL stops that phrase and ends the drain; the rest stay Queued.
5. The cap applies to every Claude job's request later (Home lines, Plan my day, recipe) as `min(job timeout, 8 s)` only where the job today waits longer; Plan my day and the recipe reader keep their own longer ceilings (`offline-retry-table.md`) because they run in the background, not in the Ask slot. This page covers capture and the drain.

## 5. Test vectors (Swift Testing, all with `RouteStub`, a fixed clock and a stub session; none uses a key or a live call)

Existing tests already cover the base cases and stay: `anOfflineMissWaitsAndIsReadLater`, `phrasesQueuedBeforeTheWallsNeverLeave`, `aPhraseUnsentAfterAWeekIsDeletedAndANewerOneStays`, `aWeekOldPhraseIsDeletedEvenWithClaudeOff`, `aCookRunningKeepsWaitingPhrasesHomeUntilItEnds`, `theFirstDrainedPhraseCarriesTheNoticeAndOnlyIt`, `aDrainLandsAtMostThreeGhostsAndTheRestKeepWaiting`, `nothingWaitsForSiriAndAKeyNeverWaits` (`ClaudeRouteTests.swift:298-401`). New:

| # | Test name | Setup | Expect |
|---|---|---|---|
| T1 | `anOfflineMissWritesNoSentRowAndNoCallRow` | Stub throws `notConnectedToInternet` on the first request | `TessSentLog.count == 0`; no Call row with outcome offline; the phrase is Queued; line "No connection. Saved it for Claude." |
| T2 | `aDrainedPhraseWritesExactlyOneSentRow` | Queue "log bench 80 for 8 from earlier", stub answers | One Sent row, `words == the phrase`, `createdAt == the drain time` (not the saidAt), `requestID` equal to the Call row's; the inbox is empty |
| T3 | `aDrainThatGoesOfflineAgainWritesNoRowAndKeepsThePhrase` | As T2 but stub is offline | No Sent row, no Call row, one item still waiting, not re-queued twice |
| T4 | `aWallAddedAfterQueueingStopsTheDrain` | Queue a phrase, then make it wall-matching (a body fact added to `BodyWeight`, or a secret word edited into the stored title) | No request (`RouteStub.requests.isEmpty`), item removed, no row |
| T5 | `aKeyShapedPhraseInTheInboxIsRemovedUnsent` | Insert a key-shaped title directly | No request, item removed, no row |
| T6 | `anAnsweredDrainDeletesThePhrase` | T2 | `inbox.waiting().isEmpty` and the store holds no object with that title (not only soft-deleted) |
| T7 | `aTimedOutDrainKeepsThePhraseAndWritesItsOwnRow` | Stub never answers; fake clock advances 8 s | One Sent row and one Call row (outcome timeout); item still waiting; the line is "Claude didn't answer in time."; a second foreground makes a second row |
| T8 | `aBusyDrainKeepsThePhrase` | Stub 529 | One row each; item waiting; no loop (one request per foreground) |
| T9 | `aPhraseSevenDaysAndOneSecondOldIsDeletedBeforeAnyRequest` | `now - (7*86400 + 1)` | Removed, no request; exactly seven days old is still read |
| T10 | `captureCallStopsAtEightSeconds` | Three-round tool conversation, stub delays 4 s each | Stops at 8 s wall clock (fake clock), no third request, ghosts discarded, outcome timeout, line "Claude didn't answer in time.", the live phrase is **not** queued |
| T11 | `eachRoundGetsTheRemainingTimeNotEightSeconds` | Round 1 takes 5 s | Round 2 `timeoutInterval == 3` (within 0.1 s) |
| T12 | `cancelStopsTheAskWithNoGhostsAndKeepsTheText` | Cancel while the stub is pending | No ghosts, no line, the text is still in the box, nothing queued; Sent and Call rows only if the stub saw the body |
| T13 | `cancelBeforeTheBodyIsSentWritesNoRow` | Cancel before `send` starts | No rows |
| T14 | `cancelDuringADrainKeepsEveryWaitingPhrase` | Two waiting, cancel the first | Both still waiting, the second never requested |
| T15 | `theAskingLineAppearsAtOnceAndGoesWithTheCall` | UI test on `AskSlotTests` pattern | The "Asking Claude" line and CANCEL are present within one frame of `isBusy`, gone after; VoiceOver label "Asking Claude. Cancel" |
| T16 | `nowShowsOneLineForWaitingPhrasesAndNeverTheirWords` | 2 waiting | Now shows "2 waiting for Claude"; the list shows the phrases; a walled phrase is never in the list (it was never queued) |
| T17 | `aSiriMissNeverQueuesOrLogs` | `commitImmediately` true | No request, no row, nothing queued (existing guard; pin it) |
| T18 | `theMonthCapStopsTheDrainWithoutARow` | Ledger at $50 | No request, no Sent row, `heldBack` +1, items kept |

Boundaries to hit in T9/T10: 7 days exactly, 7 days + 1 s, 8.0 s, 8.1 s, 599 / 600 / 601 characters on the first request.

## 6. Second pass: what-was-sent-log.md against Core's #1066 (`TessSent`, head db1cd77b)

What matches: one row per built request beside its Tess Call row, linked by `requestID`; no op row; local-only (in no backup copy, iCloud copy or export, `PrivateWords.localOnlyClassKeys`); a walled, secret-worded or key-shaped phrase stored as "Private phrase"; Clear deletes the rows for good and keeps the spend; a held-back count exists.

**Drift, each a row for Core unless marked (D = drift):**

| # | Drift | In the doc | In #1066 | Owner / action |
|---|---|---|---|---|
| D1 | **Rows on failures that never left.** The doc says a row for each request that was built; the new ruling says only when it really goes out. #1066 calls `logSent` in the `catch` after `ledger.record` for every failure, offline included. | `what-was-sent-log.md` section 1 | `ClaudeTessModel.swift` diff, `logSent` in the failure path | Core: skip the Sent row **and** the Call row when `failure.outcome == "offline"` (ruled Oct 19) |
| D2 | **"Word for word as Claude received it" is not true.** The capture request also carries a date line, the current exercise name, the last set and 11 tool definitions in the system prompt (`architecture.md` capture row). The row holds only `request.text`. | Sections 1 and 4: "exactly what left the phone" | `TessSentLog.record(words:)` is passed `request.text` only | **Ruled Oct 19:** the log holds everything that left in the request (the phrase plus the date line, the exercise and the last set) as sent, with handles. Core stores the whole variable part of the body, not `request.text` alone; the copy may then say "exactly" |
| D3 | **Handles.** The doc says payloads show handles (h1, s1) and the handle map is never stored. Capture sends the phrase whole with no handles, and the other jobs (Home lines, Plan my day, askSubject) are not logged yet. The test `whatWasSentHoldsWordsAsSentWithHandles` asserts only `words == route.miss`; no handle case exists. | Sections 1, 2, 4; test 4 | Test name overclaims; no handle path | **Ruled Oct 19:** make the handle tests real. Core: capture's pack applies handles where it names objects (the exercise, the last set), `whatWasSentHoldsWordsAsSentWithHandles` asserts a handle in the stored body and no real id, and add `sentLogPayloadHasHandlesNotRealIdsAndNoHandleMap` |
| D4 | **Fields.** The doc has job, sentAt, payload, bytes, model, tokens, cost, outcome. #1066 has `use`, `words`, `requestID` plus `createdAt`. Model, tokens, cost and outcome live on the linked Tess Call row (fine). `bytes` is on neither, yet the list shows "1.1 KB" and the 1,200-byte pack caps check it. | Section 1 | `SystemCatalog.swift` `tessSent` fields | Core: add `bytes` (UTF-8 length of the body sent), or drop "KB" from the list. Docs: say model, tokens, cost and outcome are read by `requestID` |
| D5 | **Retention.** 30 days or the last 500 rows, trimmed at the 04:00 turnover. #1066 keeps rows until Clear. | Section 3 | No trim | Core: trim at the turnover, with `sentLogTrimsToThirtyDaysAndFiveHundredAtTurnover` (doc test 6). **Ruled Oct 19:** 30 days or 500 rows, whichever first |
| D6 | **Wall language is stale in the doc, not in the code.** The doc says a wall hit means no call so nothing to log, and a key-shaped body is refused. Since #860 a walled miss goes whole, so a walled phrase **does** produce a row, stored as "Private phrase" (decisions 2:40 AM Oct 17 item 3). | Section 2 | Matches the ruling | Docs (me): fix section 2 in the log doc |
| D7 | **Migration.** The doc says catalog v11. #1066 seeds the new class with no version bump (the seed adds missing classes). | Section 3 | `SystemCatalog.swift` | Docs (me): fix; Core confirms an old build opens the store |
| D8 | **Held-back count.** The PR text counts cook/timer, walled-and-grammar-answered, too long and the month cap. In `ClaudeTessModel.swift` only two increments exist (too long, cap). I did not read the router change in `TessModel.swift`, so cook/timer and grammar-answered are unconfirmed. The count lives in `UserDefaults` as a number (no words), which is fine for a count. | Section 1 | `ClaudeMissFlags.heldBack` | Core: confirm all four causes increment; test `heldBackCountsEachCause` |
| D9 | **Drain rows.** Not covered by either text. A drained phrase must write one row per real attempt (section 2 above), and `logSent` runs for drained requests through `run`, so T2 should pass once D1 is fixed. | n/a | n/a | Core: T2 to T3 |
| D10 | **Stale cites to fix in other docs:** `gap-hunt-23-claude-layer.md` rows 2 and CL32 (the drain is wired, section 0); `offline-retry-table.md` does not mention the 8 s total deadline. | n/a | n/a | Research (gap-hunt row), me (retry table) |

## 7. Open for Product

None. O1, the offline rows, D2, D3 and D5 were ruled by Product on Oct 19; Product sends D1, D2, D3 and D5 to Core. Still mine: the Now line wording "1 waiting for Claude" and the DROP list (Design has not seen them).
