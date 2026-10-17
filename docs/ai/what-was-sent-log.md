# Board item: "What was sent" log (draft for ai.md, REFILL 2)

Note: origin/master docs/ops/board/ai.md (21 lines) has no "REFILL 2" or B1-B6 text, so I could not match the item's number. Slot it where Product wants it.

**Item.** A phone-local log of every Claude request, so Kaushik can open Settings and see exactly what left the phone, word for word as Claude received it. Docs and spec only; Core builds it after AI-2 (`ClaudeClient`). It adds no new network path and sends nothing.

## 1. One row per request
New system class `TessSent` under `/system/tess` (name open to Core). One row per request that was built, written next to the `TessCall` ledger row and linked to it by `requestID` and an object link. `TessCall` stays the numbers; `TessSent` holds the words, so the payload can be purged without touching spend.

| Field | Content |
|---|---|
| job | `TessUse` raw value (homeLines, planMyDay, askSubject, misses, ask, recipe, groceries, weekStory, colour) |
| sentAt | Date; shown in house time (the 4 AM day, Pacific labels), same clock as the ledger row |
| payload | The request body after the walls ran and handles were applied, exactly as sent: system, messages, tool schema. Handles show as h1, s1; the handle map is NOT stored |
| bytes | UTF-8 byte count of the body, the number the 1,200-byte caps check |
| model | claude-haiku-5-5 or claude-sonnet-5-5 |
| tokensIn, tokensOut | From the response `usage`; blank if no response |
| costNano | Same number as the `TessCall` row, shown as n$ and dollars |
| outcome | Reuse the ledger words plus: sent-ok, refused-cap, refused-wall, offline, timeout, badKey, rejected |

Refused-before-send rows (wall hit, cap) have NO payload and bytes 0: nothing left, and the row says so ("Not sent: stays on this phone"). That matches `ask-subject-pack.md` section 4 (a refused ask makes no Claude event) only if Product wants those rows shown; default is to show them in a quiet "Held back" count, not as events.

## 2. Never stored
- Any key value or any part of it: no last-4, no hash, no header copy. The `x-api-key` header is never in `payload`. The log writer drops the header map before it sees the request, and a final scan refuses to write a row that is key-shaped (`looksLikeClaudeKey`).
- Raw private note text. Notes are in no pack; if a body ever holds one, the row is not written.
- Money or body values, and any text a wall tripped on (`SecretWords.mentions`, `PrivateFacts.isWalled`). If a wall trips, there is no call (home-pack-walls-audit gaps 1 and 9), so there is nothing to log.
- The handle map (h1 to real id), real object ids, and any private memory line.
- The response text. It is not what left the phone.

The log is the same string the packer built, written after the last wall (the bypass scan of audit gap 4), so it can only hold what was allowed out. Run the same walls over the payload once more before the insert; a hit drops the payload and keeps a metadata-only row.

## 3. Retention and place
- Keep 30 days or the last 500 rows, whichever is fewer, trimmed at the 04:00 turnover. "Clear what was sent" in Settings deletes payloads at once; spend rows stay.
- Lives in `tessera.sqlite` through `ObjectStore` (GRDB), never in UserDefaults or a file. Additive migration at the next catalog number: v9 is pinned and v10 is held by #407, so v11 (Core confirms at build time). Older builds ignore it.
- In backups? Default NO: payloads are excluded from export and backup (smaller, and a restored copy should not carry old requests). Product to confirm.
- No op row (like `TessCall`): not something he did, undo never sees it.

## 4. Settings
Under "Tess asks Claude", a line "What was sent" with a count ("12 this week"). It opens a list, newest first: job word, time, "1.1 KB", model, cost. Tap a row to see the payload in plain reading type, handles shown as h1/s1 with a line "Names on this phone are swapped for handles before sending". A top line states what is never in it. Rows with no payload read "Held back on this phone". Empty state when the switch is off: "Nothing has been sent." No card grid; a ledger-style list in the house type. Reduce Motion and Dynamic Type respected; payload text selectable, no share sheet.

## 5. Lines up with the other docs
- `spend-projection.md`: one `TessSent` row per `TessCall` row; costNano is copied, never recomputed. Month total and the $40 / $50 lines still read only `TessCall`. A test proves the two sums agree.
- `a4-bypass-check.md`: the log is the evidence for paths 1 to 4; a pack that carries a walled exercise name or last set would show in the log. The log must not become a new bypass: it stores only the post-wall payload.
- `home-pack-walls-audit.md`: wall hit means no call, so no payload row (gap 9). Fixtures W1 to W3 hard-fail strings must be absent from the stored payload too.
- `ask-subject-pack.md`: `askSubject` rows show subject handle, class, and `name` only for Ingredient and Exercise; the 1,200-byte cap equals the logged `bytes`; the 21st ask in a day writes no row.

## 6. Tests (Core)
1. `sentLogRowMatchesLedgerRowCostAndRequestID`
2. `sentLogNeverContainsKeyOrKeyShapedText`
3. `sentLogOmitsPayloadWhenWallTripsAndWritesNoCallRow`
4. `sentLogPayloadHasHandlesNotRealIdsAndNoHandleMap`
5. `sentLogBytesEqualsEncodedBodyLengthForAskSubjectPacks`
6. `sentLogTrimsToThirtyDaysAndFiveHundredAtTurnover`
7. `sentLogClearKeepsSpendRowsAndMonthTotal`
8. `sentLogMigrationIsAdditiveAndOlderBuildOpensStore`

Acceptance: Settings list shows a real Home done call and a held-back ask on the simulator with `-fakeClaudeKey`; no key text anywhere in the store dump (grep the sqlite file).
