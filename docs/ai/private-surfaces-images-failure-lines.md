# Private-label surfaces, images, failure lines and the month roll (board 9:50 PM REFILL, R2 to R5)

For: Product, then Core (R2, R3, R5), Builder B (R4 lines). From: AI architecture. Docs only: no Claude calls, no key use, no key content. Read against master at Oct 18, 5 AM PT. **[code]** = read in Swift on master; **[docs]** = from a docs page, not re-read in code; **[unbuilt]** = no code on master yet. `docs/product/decisions.md` is the source of every ruling, cited by its stamp (the Oct 17 clock correction applies; stamp and real time name the same entry).

## R2. Private-label surfaces: no Claude call, and which pack field is dropped

Rule used everywhere: **one `isPrivateText` function, the widest wall (G105)**; a masked surface shows its kind word ("Private note", "Private item", "Private workout"), never the words. Claude is never sent a masked surface's words. The one door where private words can reach Claude is a capture-miss phrase he typed or spoke himself (his "all but the key", Oct 17); nothing below is a stored object being sent.

| Surface (label) | Where it can appear | Can it reach any Claude job? | Pack field dropped or replaced | Status |
|---|---|---|---|---|
| Private note ("Private note", never its words) | Notes index, Review, Home | **No job packs notes.** Notes are in no pack (injection audit; capture's `createNote` tool writes a note but never reads one). | none to drop: there is no notes field | [docs]; `createNote` is write-only [code, TessTools.swift] |
| Private recipe ("Private recipe"; rows "Private item"; As pasted shows only "Private recipe") | Recipes, Pantry, Groceries, Kitchen widget | **Recipe reader** sends fetched page text, never a stored recipe. **Grocery link job** [unbuilt] sends item names by handle. | Recipe reader: nothing from a stored recipe is in the pack. Grocery link (proposed, spec not final): a walled item name goes as the class word "item" and its row is left out of the pairs | recipe reader [code]; grocery link [unbuilt, spec in side-jobs] |
| Private item (an ingredient used only by private recipes; sticky mask `pantryPrivate`, G198) | Pantry, Groceries | Only through **askSubject** or **fillFacts** (both [unbuilt]), which take an Ingredient name | `name` is replaced by the class word "ingredient"; no `fields`; a walled question builds no payload | spec: `ask-subject-pack.md` with the one-function ruling; `pre-review-notes-oct17.md` checks W1 to W9 |
| Private task (a task whose title is walled) | Today, Home, Plan my day | **Plan my day** sends task titles | A walled or secret-worded title goes as `task`/`busy`; its handle stays so the time slot is kept; the reply is checked with the same wall | [code, `PlanWording.swift`] |
| Private workout (a routine whose title is walled) | Home hero, Done hero, receipts, Live Activity | **Home done line** pack carries the routine title | A walled pack is refused whole (no call, no row). The phone's own Home line shows the real title until the mask lands at `WorkoutSummary.swift:92` | Claude side [code, reviewed #658]; phone side open (gap-lane part 2, section 4) |
| Private list ("Private list") | Lists | **No job packs lists.** Capture's `addToList`, `createList` tools write only | none to drop | [code, TessTools.swift] |
| Private body weight, money, health | Body, Money screens | Never in a pack. Only a capture-miss phrase he typed himself may carry them | n/a | per `architecture.md` never-leaves bullets |

**Checks for Core (each is a test, no key, no call):**
- R2-1. For each surface above that appears in a pack ("Private task", "Private workout", "Private item"), build the pack with a private title and assert the title is absent from the request body, the ledger row and the What was sent row; the class word or the drop is what the body holds.
- R2-2. A masked label ("Private item") is never itself fed back as a name: a pack that would contain a label string is treated as walled, not sent.
- R2-3. The label survives into the reply check: a Claude reply that quotes any masked title is dropped (same wall as the pack).

## R3. No image ever reaches Claude

Ruling: Product 8:37 PM, sheet 88: "no image ever goes to Claude"; the recipe plate's og-image is fetched on the phone, stays on the phone and out of backups.

**Every input on every Claude path, and its type:**

| Job | Inputs | Any image field? |
|---|---|---|
| capture | phrase (text), date line, current exercise name, last set (kg x reps), 11 tool definitions | No |
| question (`answerQuery`) | question text, counts from allow-listed classes | No |
| paste | pasted text | No |
| recipe link | fetched page text (about 1,500 characters before the first "ingredient" and up to 22,000 after, cap 24,000) | No: only text is extracted; the page's og-image is a separate on-phone fetch [unbuilt] and is never put in the request |
| Plan my day | task and routine titles and times (JSON) | No |
| Home done lines | counts, bests, routine title | No |
| keyCheck | the key in a header only; fallback body "Hi" | No |
| askSubject, fillFacts, linkItems, week story, living colour | text packs [unbuilt] | No (specs carry text only) |

**Evidence on master:** a search of `TesseraCore/Sources/TesseraTess` for `image`, `base64`, `media_type` and image type names returns no hits [code]; `ClaudeClient` builds only text content. **Test (R3-1):** `noClaudeRequestHoldsAnImageBlock`: build one request per job (fixtures), decode the body, assert every content block type is `text` or `tool_use`/`tool_result` and that no `source`, `media_type` or `data:` string appears. **Review stance:** any new pack field that is a URL to an image, a `data:` URI or a file is a stop; a recipe pack carries the recipe's text only, never its `ogImage`, plate or `sourceURL` image.

## R4. Failure lines aligned with sheet 84

Lines (Product's list from sheet 84; I could not read the sheet itself, so these are as relayed): busy **"Claude is busy. Kept it for later."**, timeout **"Claude didn't answer in time. Kept it for later."**, switch off **"Claude is off."**, no key **"No Claude key yet."** "Drains" = the work waits and runs later.

| Job | Busy | Timeout | Off | No key | Drains? |
|---|---|---|---|---|---|
| capture | busy line; a live phrase waits in `TessInbox` | timeout line; a live phrase waits | "Claude is off." and the on-device/grammar route runs | "No Claude key yet." then the same route | **Yes for a live phrase. A walled phrase never drains: not queued, not logged (Product, #987 ruling); the ask slot shows one plain line and the text stays in his box.** |
| Plan my day | "Claude is busy. Here's your usual plan." | "Claude didn't answer in time. Here's your usual plan." | rules plan, no line | rules plan, no line | No (rules plan stands; same-pack reuse spends nothing) |
| Recipe reader | "Recipe link, kept for later." (kept) | same | "Claude is off. Paste the text instead." (dropped) | "Add your Claude key in Settings." (proposed in gap-lane-oct17, section d; unconfirmed in code) | A kept link is read again on his tap; automatic retry is proposed, not built (gap-lane part 3, section 1) |
| Home lines, done lines | none shown (rules lines stay) | none shown | none | none | No. A done line timeout is final; a Home line retries on the next pack change |
| Week story, living colour | none shown | none shown | none | none | No (background; the next scheduled run) |
| askSubject, fillFacts | the phone answers alone / a decline stores nothing | same | button hidden or "Claude is off." | hidden | No (asked once, ever, for fillFacts) |
| keyCheck | "Claude is busy right now. I kept the key." | "Claude didn't answer in time." | n/a | n/a | TEST again by hand |

**Differences from the older B2 table for Core and Builder B:** (1) the timeout line gains "Claude didn't answer in time." (the older table says "timed out"); (2) "No Claude key yet." replaces "No key" wording where a Claude line is shown; (3) a walled capture phrase is the one row that does not drain; (4) pointer words inside lines follow `ClaudeWhere` (Review now, Settings later; `settings-claude-page-spec.md` section 5).

## R5. Ledger month roll: ruling and the code disagree

**Ruling (decisions 8:24 PM, "Month reset clock"):** the ledger month rolls on house time: a use at 2 am on the 1st counts toward the old month until 4 am, the same boundary as the day (`TesseraDay`, `startHour = 4`).

**Code today [code]:** `monthTotal(now:calendar:)` filters rows with `calendar.dateInterval(of: .month, for: now)`, a calendar month starting at **00:00** on the 1st (`ClaudeKey.swift:111-114`), and its comment at `:84` says "not his 4 AM day". `docs/research/settings-claude.md` says the same (00:00 on the 1st). So a use between 00:00 and 04:00 on the 1st counts toward the new month in code, the old month by the ruling. **Finding for Core:** shift the instant by the day-start offset before taking the month interval (e.g. `now - 4 h` for the lookup, and the same shift for each row's `createdAt`), and make the paused line's date and the "of $50" meter agree.

**Test names for Core to paste (all with a fixed clock and a fixed Los Angeles calendar):**
- `useAt0159OnTheFirstCountsTowardTheOldMonth`
- `useAt0400OnTheFirstCountsTowardTheNewMonth`
- `useAt0359OnTheFirstIsStillTheOldMonthsCap` (a month capped on the 31st still refuses at 03:59 on the 1st)
- `useAt0400OnTheFirstIsAllowedAfterACappedMonth`
- `useAt2359OnTheLastDayCountsTowardThatMonth`
- `pausedLineAt0200OnTheFirstStillSaysUntilThatDate` ("Paused until Nov 1." until 4 am, then gone)
- `fallBackNight_Nov1_2026_StillRollsAt0400LocalTime` (the repeated 1 to 2 am hour; the boundary is 4 am by the wall clock)
- `monthLabelAndMeterAgreeAtTheBoundary` (the Settings meter total and the canSpend check read the same month at 03:59 and 04:00)
- `rowsKeepOneMonthWhenTheTimeZoneChanges` (a travel zone change must not move a row into another month; use the stored instant and the house calendar)

**Docs to change when Core lands it:** `settings-claude.md` "Month" rule (00:00 becomes 04:00 house time), the comment at `ClaudeKey.swift:84`, and `architecture.md` where it says the cap "resets on the 1st".
