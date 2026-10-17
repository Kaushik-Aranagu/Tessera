# Capture-miss routing for grocery phrases (rows CM1..CM14)

*Kitchen lead, 2026-10-17. For K25. Decision 2:33 AM Oct 17: a capture miss (grammar can't read the phrase) may go to Claude with everything but the key, behind "Tess asks Claude" (`missesGoToClaude`) and the $50 cap. Price rule stands from 2:09 (strip, drop, item stays; receipt "Milk, on Groceries."), money test from 2:22. Today's code (`TessCaptureEngine.swift:55-62`) skips the miss log for any line with a secret word or `PrivateFacts.isWalled`; `CaptureMissLog.record` refuses only key shapes and cuts to 200 chars. Pairs with kitchen-misfire-rows.md A and B. "Log" = capture-misses.jsonl line (text, at, route, source "ghost row").*

Rule used by every row: **the price is stripped from the phrase once, before anything leaves the engine** (log and send see the same stripped text). Default taken.

| # | Input | Expected log row | Expected send (switch on) | Expected result | Test name |
|---|---|---|---|---|---|
| CM1 | a couple of limes for the tacos $3 | text "a couple of limes for the tacos", route "grammar", source "ghost row" | "a couple of limes for the tacos" (no $3), cloud mark | ghost row Limes on Groceries; "for tacos" kept as the row's note only if Claude returns it; no 3 or $ anywhere on the row; receipt "Limes, on Groceries." | `captureMissGroceryPriceStrippedBeforeSend` |
| CM2 | out of the good olive oil 12.99 | "out of the good olive oil" | same stripped text | Olive oil on Groceries ("good" in the name, default taken); no price on row, note or receipt; Pantry state, if built, sets it out | `captureMissOutOfOilDropsPrice` |
| CM3 | tomatoes x2 4.50 | "tomatoes x2" (x2 is a pack count, not a price) | "tomatoes x2" | "Tomatoes x2" on Groceries; 4.50 gone | `captureMissQuantityKeptPriceDropped` |
| CM4 | 2 for $5 avocados at the corner shop | "2 for avocados at the corner shop" is wrong; log "avocados at the corner shop" (the 2:09 strip takes "2 for $5" whole) | same | Avocados on Groceries; store name dropped from the row (default taken: shop name is not an item) | `captureMissTwoForPriceStrip` |
| CM5 | 6 eggs 3.20 and a tub of the greek yoghurt | "6 eggs and a tub of the greek yoghurt" | same | 2 rows: "6 eggs" (number kept, a pack), Greek yoghurt; receipt "Eggs and Greek yoghurt, on Groceries." (two-item receipt wording default taken) | `captureMissTwoItemsOnePrice` |
| CM6 | milk 4.99 (grammar reads it) | none: not a miss | nothing sent | Milk on Groceries via grammar, price dropped, "Milk, on Groceries." | `groceryPriceNeverMissesWhenGrammarReads` |
| CM7 | $40 at costco | none (money-only line, today's guard; stays) | nothing sent: a money-only line has no grocery item to ask about (default taken, narrower than 2:33; flag below) | no row; private dated note (2:09, 2:06) | `captureMissMoneyOnlyLineNotLoggedNotSent` |
| CM8 | tomatoes 450 | none | nothing sent | passes the money test only if 3+ digit with no unit noun: default taken, treated as money-only, not a grocery; private dated note | `captureMissBareThreeDigitIsMoney` |
| CM9 | the wifi password is limes4tacos, get limes | none (secret word) | not sent as phrase text (default taken: secret lines stay off the log; the send is allowed by 2:33, but a strip-then-send of "get limes" would split the line, so none) | private note "Private note, kept."; no grocery row | `captureMissSecretWordLineKeptOnPhone` |
| CM10 | out of my metformin 40 | none (body/health: log stays walled) | sent, price stripped ("out of my metformin"), cloud mark, per 2:33 | a row titled "Private item" on Groceries (house rule for a walled item); the drug name never on the row or receipt; receipt "Private item, on Groceries." | `captureMissWalledItemTitledPrivateItem` |
| CM11 | a key-shaped string (built in test code with ClaudeSection.fakeKey, never written here) then "limes $3" | none | never sent, never logged; key never carried | nothing written; "Didn't catch that." | `captureMissKeyShapeNeverLoggedNeverSent` |
| CM12 | a couple of limes for the tacos $3, switch off | log row as CM1 (text stripped) | nothing sent | "Didn't catch that." and no row (misses stay a log line only) | `captureMissSwitchOffNoSend` |
| CM13 | a couple of limes for the tacos $3, Claude fails or offline | log row as CM1 | send attempted once; retry queue (inbox) re-screens the stripped text, not the original | "Claude is busy. Kept it for later."; on retry the same result as CM1 | `captureMissRetryKeepsStrippedText` |
| CM14 | 300-char grocery ramble ending "$3" | text cut to 200 after the strip, so a price past char 200 never reaches the file | stripped full text, sent whole | items as Claude returns them; no price | `captureMissStripBeforeTruncate` |

## Checks that hold on every row
- No digit-with-currency or decimal price string in the log file, in the request body, on any row, note or receipt (grep test over the three).
- Every Claude-made ghost row keeps the cloud mark; first send shows the one-time "Sent ... to Claude" line (once, 8:28 PM).
- Receipts use "{Thing}, on Groceries."; the price is never echoed, even as "not saved".

## Open, defaults taken
1. **Strip before send, not only before log.** 2:33 permits sending prices; the default drops them anyway so the result and the wire agree. If he wants Claude to see prices, only the log row changes (CM1's send).
2. **Money-only lines (CM7, CM8) stay off Claude.** 2:33 says "money too"; the default keeps the guard because there is nothing for a grocery route to parse. Needs Product's yes.
3. **Log still skips walled lines** (secret, body, money): 2:33 changed the send, not the file. Core removes the lock on the send path only.
4. **"Private item" title for walled grocery items (CM10)** is inferred from the lists rule (2:09: body items stay items, walled from Claude), now sent per 2:33; title wording is Design's call.
5. Two-item receipt wording (CM5) and "good" kept in the name (CM2) are Kitchen's picks.
