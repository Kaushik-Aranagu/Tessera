# Kitchen REFILL 7, Lane 1: acceptance rows K43 to K47

*Kitchen lead, 2026-10-17 (board `kitchen.md` line 56, "3:08 AM REFILL 7", Lane 1). Docs only, no code. Format and numbering follow `kitchen-refill6-lane1-acceptance.md` (K34 to K38) and `kitchen-refill6-lane2-acceptance.md` (K39 to K41). Read and checked against: those two files, `kitchen-refill5-acceptance.md` (K32 private recipe), `kitchen-widget-wash-acceptance.md` (KW-W7, KW-W8), `kitchen-error-states-acceptance.md` (ER), `paste-hardening-acceptance.md`, `groceries-ai-acceptance.md` (sections 2, 4, 5, 6), `meal-plan-groceries-acceptance.md`, `us-shop-acceptance.md` (K7), `kitchen-v2-acceptance.md` (gap hunt G1 to G5), `kitchen-gap-hunt-2.md` (G7), `docs/ai/job-trigger-table.md` (C2), `docs/research/recipe-link-fetch.md`, `docs/research/pantry-light.md`, and `TesseraCore/Sources/TesseraTess/RecipeLinkReader.swift` (`RecipeLinkLine`, `ClaudeRecipeReader.sendable`, `outputIsUnsafe`). There is no separate recipe-link acceptance file; the link rules live in `recipe-link-fetch.md`, `paste-hardening-acceptance.md` and the code. Where an existing file already holds a row, this file points at it and adds only what is missing. Nothing on master reads a photo, and no screen deletes a recipe; rows for those are build targets.*

**House rules used by every row.** Receipts name the thing first and use "on" ("Milk, on Groceries."). No "at" before a time. Clocks are lowercase ("8:30 pm"). Digits for counts. US English and US units. A walled thing reads "Private item", "Private recipe" or "Private note"; on the widget, in Siri and in a notification a private recipe reads "Private recipe, 7 pm." Cobalt is Tess's voice only; every other link is ink, underlined. Quiet hours are 23:00 to 07:00; the 4 AM day boundary applies. Money and body facts never go to Claude. Grocery asks have no daily cap; the limits are the $50/month cap and the $40 step-aside (K39). Link and reader asks fire only on his tap. Timers he started ring in quiet hours (K35.10). Known pairs ("mac and cheese") are one row. No row runs a live Claude call: Claude is a stub in every test, and no fixture, log or row here holds a key or key-shaped text (tests build any fake with `ClaudeSection.fakeKey`).

**UNDO windows used below (`UndoWindow`, decisions 12:45 PM Oct 16).** A new thing: 4 s. A change to something that already exists: 10 s. With VoiceOver on, every UNDO: 10 s. The window pauses while the app is backgrounded or the phone is locked. One UNDO slot, last write wins. Every UNDO has a line saying what it took back, thing first ("Milk, taken back.").

**Fixtures used below.**
- **Dal** and **Tacos** as in `kitchen-refill6-lane1-acceptance.md`.
- **Sunday secret stew**: a recipe marked Private, planned tonight, 7 pm. Its name is never typed in an expected line; every row asserts its absence.
- **Grocery history for USUALLY**: milk bought on days 0, 7, 14, 21, 28 and 35 (steady gap 7); eggs on days 0, 7, 14 and 40 (irregular); oat milk on days 3, 17 and 31 (gap 14); lemons only through Tacos shares; "Ozempic refill" (walled) typed 4 times, a week apart.
- The clock is the app clock (`-demoTime`), simulator only.

---

## K43. Recipe import from a photo or screenshot (the reader job)

**Source rules.** The reader job is `ClaudeRecipeReader` (model `claude-haiku-5-5`, 4,096 output tokens, 20 s; "recipe reader" in C2: a tap, runs to $50, does not step aside at $40). A photo import adds one step in front of it that the phone does alone: it reads the picture's words on the device and builds a page of text. That text goes through the same ladder as a link: the deterministic parser first, and Claude only if the parser finds no recipe, only on his tap, only with "Tess asks Claude" on, a key and money left. **The picture itself never leaves the phone** (proposed, Product to rule; the price-heavy case is why: prices cannot be cut from pixels, but they can be cut from text). Every line that would go to Claude passes `ClaudeRecipeReader.sendable` first (secret words, money, body facts and a Claude key cut line by line; a page of only cut lines is never sent). The reply passes `outputIsUnsafe`; a reply that fails is dropped whole, never trimmed. The ghost, Save and UNDO are the link path's. Failure copy reuses `RecipeLinkLine` word for word where it fits and says "photo" only where "page" would be wrong.

Setup: a stub text reader that returns fixture text per picture, a stub Claude with a recorded request log, "Tess asks Claude" on and keyed, $0 spent, online, unless the row says otherwise.

### The happy path

| # | Action | Expected |
|---|---|---|
| K43.1 | Paste screen: choose a photo of a printed Dal recipe (clear, upright) | The words are read on the device. No Claude request (log empty). Tess (cobalt, her band): "Reading the photo…" (proposed, Product to rule; the link twin is "Reading nytimes.com…"). The parser finds the recipe; the ghost Dal paints and Tess says "10 ingredients, 2 steps, 2 timers." (`RecipeLinkLine.found`). Nothing is saved until he taps Save |
| K43.2 | Tap Save | Receipt "Dal saved." with UNDO for 10 s (recipe paste gets 10 s, undo audit). UNDO line "Dal taken back." and the recipe leaves. Source text holds the recognised words. **No photo is stored** (v1: no photos), no source link; the plate is the Kitchen green wash (K30.2) |
| K43.3 | Import a screenshot of a social caption with the recipe in the text | As K43.1. Hashtags, emoji and "Jump to Recipe" lines are dropped as noise (paste-hardening gap 3); the recipe reads clean |
| K43.4 | Choose a photo with airplane mode on | Reading the picture works offline, so a parser result shows with no notice (ER12). If the parser finds nothing and Claude would be needed: the words are kept and Tess says "Photo, kept for later." in the UNDO slot (proposed, Product to rule; twin of ER1's "Recipe link, kept for later."). It asks nothing on its own when he is back online; ASK CLAUDE waits for his tap (K43.12) |
| K43.5 | Choose 2 pictures that are two halves of one recipe | The texts are joined in the order picked and parsed as one page. More than 4 pictures: the first 4 are used and Tess says "Using the first 4." (proposed, Product to rule). Never one request per picture |

### Failure rows

| # | Action | Expected |
|---|---|---|
| K43.6 | Blurry: a photo whose words read as under 20 characters or scattered letters | No ghost. The page is too short to be worth Claude, so **no ASK CLAUDE key and no request**. Tess: "I couldn't read that photo. Try it in better light, or paste the text." (proposed, Product to rule). No row, no receipt, nothing in the capture-miss log, the picture is not kept |
| K43.7 | Blurry but half readable: 6 of 10 ingredient lines read, no method | Partial, like a paywalled page. Tess: "The steps are missing. Paste them below." (proposed twin of `RecipeLinkLine.stepsPaywalled`). The ghost holds the 6 lines; Save works; no garbled line is repaired or invented by the phone; nothing is sent unless he taps ASK CLAUDE |
| K43.8 | Non-recipe: a menu board, a street sign or a receipt | The parser finds no recipe. Tess: "No recipe in that photo. Paste the text instead." (`RecipeLinkLine.noRecipe` with "photo" for "page"; proposed, Product to rule). With Claude on, ASK CLAUDE is offered once (K43.12); on his tap Claude answers exactly "no recipe" and the same line shows. No ghost, row or receipt |
| K43.9 | Price-heavy: a basket screenshot with "Lentils $2.49", "Olive oil 7.99", "Total $31.20", "2 for $5 spinach" beside real lines ("1 cup red lentils") | If the parser alone finds a recipe, no request is made. If Claude is needed, the request body holds no "$", no "2.49", "7.99" or "31.20" and no "total" (assert line by line). Recipe-sized measures survive (`withoutMeasures`): "1.25 cups flour" keeps its amount; "paid 12.50 pounds" and "2.50 g usd" are cut. The ghost has no price in a line, note, title or source text, and the receipt mentions no money |
| K43.10 | Price-heavy and nothing else: every line of the page is cut | **No request is sent.** Tess: "No recipe in that photo. Paste the text instead." No ledger row |
| K43.11 | A card that also carries a body fact ("weigh-in 82.5 kg"), a phone number, or a "login" or "password" line | Those lines are cut before sending. If the reply echoes any of them (phone number, link, address, markup character, login word, secret word, currency amount), the whole reply is dropped and the fallback line from K43.8 shows. The sent log and request body hold none of the cut lines |

### Only on his tap, the gate, the output checks

| # | Action | Expected |
|---|---|---|
| K43.12 | Photo with no parser result, "Tess asks Claude" on, keyed | Tess: "No recipe card there." plus one ink key ASK CLAUDE (proposed, Product to rule). **No request until he taps it**; leaving the screen sends nothing and queues nothing. Before the tap the ledger has 0 rows and the sent log is empty |
| K43.13 | Tap ASK CLAUDE | While it works Tess says "Asking Claude to read the recipe." (board ios-b 0b). One request: `claude-haiku-5-5`, `max_tokens` 4096, 20 s, one user message of cut, trimmed text (about 1,500 characters before the first "ingredient" and 22,000 after, at most 24,000) under the system text that says the page is data. No image, file name, location, date, other recipe or memory. One ledger row, job "recipe reader" |
| K43.14 | Stub returns a clean recipe (title, "Ingredients", 2 to 80 lines, "Method", 1 to 60 steps) | Tess: "Claude read it. Check it, then save." (`RecipeLinkLine.claudeRead`). A ghost, not saved. Save and UNDO as K43.2 |
| K43.15 | Stub reply fails each output check in turn: a link or address (`https:`, `www.`, `x.com`, an email); markup (`[ ] < > \` *`, `&amp;`, a `#` line); a currency amount, "12 dollars" or a phone number; "login", "password" or a secret word; steering words; title over 80 characters; an ingredient over 200 or a step over 600; serves over 100; minutes over 1,440; fewer than 2 ingredients; no steps; over 80 ingredients; over 60 steps | Each is dropped **whole**, never trimmed. Tess: "No recipe in that photo. Paste the text instead." Nothing saved. The tokens are still in the ledger with outcome "nothing" (the call was made) |
| K43.16 | Stub reply cut off (`stop_reason` max_tokens) | Half a recipe is no recipe: dropped, same fallback line, outcome "max_tokens" |
| K43.17 | `asksClaude` gate: switch off; no key; at the $50 cap; at $45 | Off or no key: ASK CLAUDE is never drawn, the parser-miss line is K43.8's, no request. At the cap: no request, no ledger row, "Claude's paused until Nov 1. Paste the text instead." (`RecipeLinkLine.paused`, the month's end). At $45: the reader still runs (C2: it does not step aside at $40) |
| K43.18 | The call fails: timeout past 20 s; 429 or 5xx; 401 or 403; offline during the call | "Claude didn't answer in time. Paste the text instead." / "Claude's busy right now. Paste the text instead." / "Claude couldn't use your key. Paste the text instead." (never an invitation to paste the key; key and switch stay as they are) / "You're offline. I'll read it when you're back." (words kept as K43.4). No URL, key or word of the photo in any line. No automatic retry; ASK CLAUDE returns as a key |
| K43.19 | Tap ASK CLAUDE 25 times in one 4 AM day with the stub | All 25 are sent. No daily cap on this job; no notice about a day limit |

### Private recipe masking

| # | Action | Expected |
|---|---|---|
| K43.20 | Import a photo whose title or lines trip the secret, money or body checks (the stew fixture) | Cut lines never reach Claude (K43.9). The saved recipe is a "Private recipe": shelf, week, widget, Siri and notifications read "Private recipe" (K32, K41). Tess: "Private recipe saved." with UNDO 10 s; UNDO line "Private recipe taken back." (proposed, Product to rule). The name is never spoken |
| K43.21 | A recipe already private, then ASK CLAUDE | Zero requests (K32.15). Tess: "Private recipe. I won't send it to Claude." (proposed, Product to rule). The parser result still works on the phone |
| K43.22 | After K43.1 to K43.21, dump the request log, sent log, ledger, widget timeline and notification payloads | None holds the picture, its file name, a price, a body fact, a private line or the stew's name. The ledger holds job, model, token counts, outcome and latency only |
| K43.23 | VoiceOver and AX3 on the picker, ghost and notice | Each notice is read once, as written. ASK CLAUDE is "Ask Claude to read this photo". UNDO is 10 s. Reduce Motion: the ghost dries by a 150 ms crossfade |
| K43.24 | Copy sweep | No "OCR", "scan", "AI", "model", "token" or "Haiku" in any line; no "at" before a time; "…" only on the reading line; US English; cobalt only on Tess's lines |

---

## K44. Grocery history and "usual items" suggestions

**Source rules.** USUALLY is ruled in `groceries-ai-acceptance.md` section 4 and built on `pantry-light.md` rules 1 to 9: a typed buy, 3 or more in the 56 days ending at the last buy, a steady gap U, due from 0.85 U to 2 U days after the last buy; recipe-only and irregular items never. The surface is the USUALLY label and a line of ink words, **at most 4 names**, most overdue first, last in the aisle window and in the trip. It never notifies, badges, shows on Home, turns red, or asks Claude. Tap: the word flies to its aisle as a ghost row. Long-press: "Bought 6 times in 8 weeks, about weekly." History is `checkedAt`; a cleared item still counts as a buy, an item removed with its recipe does not.

| # | Action | Expected |
|---|---|---|
| K44.1 | Day 43 (milk last bought day 35, U 7), open Groceries | USUALLY (label at 55% ink) over "Milk". On day 38 the line is empty and takes no space (milk is due from day 41). Words only: no verb, no plus, no count, date or price. Never "eggs" (irregular), never "lemons" (recipe-only) |
| K44.2 | A fixture with 6 due names | At most 4 show, most overdue first (days since over U), then more buys in the window, then name. The line wraps to at most 2 lines at AX3 and never scrolls |
| K44.3 | Long-press "Milk" | "Bought 6 times in 8 weeks, about weekly." (digits; U 14 reads "about every 2 weeks"). A count and a rhythm only, **never a sum**: no total quantity ("12 cartons"), no spend, no price, no "per month", no average per shop. It lets go on release |
| K44.4 | Tap "Milk" | The word flies to its aisle as a wet ghost row (dries in 1.4 s). Tess: "Milk, in Dairy and eggs." with UNDO for 4 s (a new row; 10 s with VoiceOver). UNDO line "Milk, taken back." and the word returns. No Claude request, no ledger row |
| K44.5 | Swipe "Oat milk" away (dismiss) | The word leaves; `usualSkippedAt` is written on its ingredients; it stays quiet until the next buy. Tess: "Oat milk, not now." with UNDO for 10 s (a change; proposed, Product to rule). UNDO line "Oat milk, taken back." and the word returns |
| K44.6 | Finish the trip (DONE) while "Milk" was shown and not added | "Milk" goes quiet until its next buy (rule 8). UNDO of the clear (10 s) undoes the quiet. A word he tapped (so bought) is not marked skipped |
| K44.7 | Milk is already on the list (open or checked, any form: "whole milk", "2% milk") | Not shown (rule 7). Remove the row and, if still due, it can show again |
| K44.8 | Walled item: "Ozempic refill" typed 4 times a week apart, or any title that trips the secret, money or body check | **Never offered in USUALLY**, and no "Private item" word is drawn there either (a mask word would still say something private recurs on a surface he may show). It has no long-press history line and no count is readable. The rows read "Private item" where lists show them (Lists' `privateItemLabel`) and the add receipt is "Private item, on Groceries." Editing the words clear of the wall does not backfill old buys into USUALLY |
| K44.9 | Type "milk $4" four times | Each lands as "milk" (price stripped, W1); no price in history, USUALLY, the long-press line or a backup |
| K44.10 | Two buys 2 days apart, then 3 days apart | Count once, then twice (rule 1). "Semi skimmed milk" and "milk" are one group; "oat milk" is not |
| K44.11 | Fewer than 3 buys, or an item whose shares all name a recipe | Never shown. No "learning" line, no empty state, no Tess line |
| K44.12 | Leave the app 3 days with milk due | No notification, badge, Home offer, Live Activity or widget row. No path adds an item without a tap (grep of `AddGroceries` callers: his tap, the Add line, a paste, a recipe add, a Tess capture) |
| K44.13 | Run the day with a stub Claude recording | Zero requests from USUALLY or history. The link ask (K39) never receives USUALLY words or `checkedAt` (its pack is handles and ingredient titles only) |
| K44.14 | Tap "Milk" (4 s window), then within 4 s swipe "Oat milk" away | One slot, last write wins: the later line replaces the earlier, and UNDO takes back only the later change. The milk row stays |
| K44.15 | Offline; VoiceOver | Works offline (on the phone). VoiceOver reads "Usually", then each name as a button with hint "Adds to your list" and custom action "Not now". UNDO is 10 s |
| K44.16 | Copy sweep | No "suggestion", "recommended", "AI", "running low" or "you usually run out"; the words are ink; cobalt only on receipts |

---

## K45. Kitchen Siri phrases: "add milk" and "what's for dinner"

**Source rules.** Bare food goes to Groceries (`lists-slice-8-phrases.md` L8-53); a named list wins ("add milk to packing" gives "Milk, on Packing."). Siri writes need Face ID (decisions: Tell Tess and Add a Task; Core 0ac). The plan read-out follows K32.8 to K32.10: a private cook is "Private recipe, 7 pm." (never the name or an ingredient). "What's for dinner" is a grammar rule over today's plan (day-one KW29); its in-app reply is "Tacos tonight, 2 to buy." Prices on a title are stripped (`groceries-ai-acceptance.md` section 6). Siri and the Shortcuts intent give the same words. Setup: Tacos planned today, 7 pm with 2 open rows, Dal tomorrow, 6:30 pm, the stew Friday, 7 pm.

### Writes

| # | Action | Expected |
|---|---|---|
| K45.1 | Unlocked: "add milk" | Siri says "Milk, on Groceries." One new row in Dairy and eggs. One op by Siri; on the next app open it is undoable, and Siri writes reach 300 records back |
| K45.2 | Locked: "add milk" | Face ID is asked. On success the same words and the row lands; the app does not open |
| K45.3 | Locked: Face ID fails twice or is cancelled | **Nothing is written**: no row, op or queue. Siri says "Face ID needed to add to Groceries." (proposed, Product to rule). The phrase is not kept for retry |
| K45.4 | "add milk and eggs"; "add mac and cheese"; "add salt and pepper" | "Milk and eggs, on Groceries." as 2 rows (proposed, Product to rule); the other two are one row each ("Mac and cheese, on Groceries.") per the known-pairs ruling |
| K45.5 | "add milk $4" | Price stripped, item kept: "Milk, on Groceries." No "$4" spoken or stored (W1) |
| K45.6 | "add 2 lemons"; "add a dozen eggs" | "Lemons, on Groceries." The row keeps what he said ("2 lemons", "1 dozen eggs"); digits for counts |
| K45.7 | A walled item ("add Ozempic refill"); then "add rent 2100 friday" | The first is written and Siri says "Private item, on Groceries." (never the words). The second is not a grocery: a private dated note, "Private note, kept.", Groceries unchanged (W2) |
| K45.8 | "add milk to packing"; then "add milk" | "Milk, on Packing."; then Groceries, never Packing |
| K45.9 | "add milk" twice within 1 minute | The second finds the open row: "Milk, already on Groceries." (proposed, Product to rule); no second row. A checked milk row is not open, so a new row is added |
| K45.10 | During a live workout; offline | Works both ways. A grocery write is not a workout write; the workout screen is not interrupted; offline shows no notice (ER12) |

### Reads

| # | Action | Expected |
|---|---|---|
| K45.11 | Unlocked: "what's for dinner" | Siri: "Tacos, 7 pm." (K32.8 form). In the app, Tess: "Tacos tonight, 2 to buy." Dal tomorrow is not read unless asked |
| K45.12 | "what's for dinner Friday"; "what's for dinner tomorrow" | "Private recipe, 7 pm."; "Dal, 6:30 pm." Never the stew's name, an ingredient or a step |
| K45.13 | Locked: "what's for dinner" (Tacos today) | Same words, "Tacos, 7 pm." (K32.10: a read writes nothing, no Face ID). Whether an ordinary title may be read locked is flag F2 |
| K45.14 | Locked, next cook is the stew | Exactly "Private recipe, 7 pm." Nothing about it is displayed on the lock screen; Siri donations and Spotlight hold no stew name (K32.11) |
| K45.15 | The cook has a day but no time | "Tacos, tonight." / "Tacos, Friday."; private: "Private recipe, tonight." / "Private recipe, Friday." (KW-W8) |
| K45.16 | Nothing planned today | "Nothing planned." (the widget's empty copy, KW-W7; proposed here for Siri, Product to rule). Never "no meals" |
| K45.17 | Two cooks today: Dal at noon, Tacos, 7 pm | "what's for dinner" gives the later: "Tacos, 7 pm."; "what's for lunch" gives "Dal, noon." Flag F3 |
| K45.18 | The only cook today is already done | Skipped: the next open plan today is read; none: "Nothing planned." |
| K45.19 | The planned recipe was deleted (K47); the recipe was made private after planning | Deleted: not read, the plan follows K47.7. Made private: the next read is "Private recipe, 7 pm." (K32.16); no cached old name survives in a donation |
| K45.20 | "what's on the plan this week" | One cook per line in order; private ones "Private recipe, Friday." Count first: "2 cooks this week." (K32.9) |
| K45.21 | Claude and logs | Neither phrase calls Claude. The sent log, ledger and capture-miss log hold nothing; an unparsed phrase holding a secret word, money or a body fact is not logged |
| K45.22 | Siri's on-screen text | Equals what is spoken. No emoji, no "at" before a time, no cobalt |

---

## K46. Shopping-trip mode: in-store checklist, aisle order, offline, one hand

**Source rules.** The trip is the at-the-shop mode of slice 13, started by holding the page title: the hero is the current aisle in large type with a lit seam, in walk order (produce, bakery, dairy and eggs, meat and seafood, cans and jars, pantry, spices, frozen, household, other; K7.3), and "then X" names the next aisle. USUALLY is last in the trip (K44). The link ask never runs while shopping, and groceries never notify, badge or start a Live Activity (`groceries-ai-acceptance.md` sections 2 and 5). A checked row strikes in ink and sinks; DONE clears the basket ("Cleared 3 from the basket.") and `FinishShop` runs the quiet rule (K44.6). Setup: 11 open rows over produce (3), dairy and eggs (2), meat (1), cans and jars (2), pantry (1), frozen (1), household (1) and a "Private item" in other.

### Start and aisle order

| # | Action | Expected |
|---|---|---|
| K46.1 | Hold the page title | The page becomes the trip; one `.impact` haptic. The hero is the first aisle with open rows (Produce), lit seam beneath; other aisles follow in walk order. Count line "11 to get". Tess says nothing |
| K46.2 | Read the line under the hero | "then Dairy and eggs": the next aisle with open rows, skipping empty ones. On the last aisle there is no "then" line. Never "Next:" |
| K46.3 | Check the last Produce row | It strikes in ink and sinks. With no open rows the hero advances by a 380 ms slide (Reduce Motion: 150 ms crossfade), "then" updates, one `.success` haptic. An aisle never appears twice (review-309 S1) |
| K46.4 | Drag a row to another aisle | It teaches that item's aisle (starting guess only); the aisle order does not change; no per-store order in v1 (`kitchen-v2-backlog.md`) |
| K46.5 | Check a Frozen row first | It strikes wherever it is; the hero stays on the first aisle with open rows. The trip never forces an order |
| K46.6 | Uncheck a struck row | It rises back to its aisle; if that aisle was passed, the hero returns to it |

### One-handed use

| # | Action | Expected |
|---|---|---|
| K46.7 | iPhone 17, right thumb only, no grip shift: check a row, change aisle, add a row, DONE, UNDO | Every control is in the lower 55% of the screen or is a swipe in it. The Add line and UNDO slot are in Tess's band (y 736 to 820). Nothing needs a top-corner tap |
| K46.8 | Left thumb only | The same set works; a swipe either way on a row works (swipe right strikes; swipe left dismisses a USUALLY word) |
| K46.9 | Mistouch | Rows are at least 44 pt tall; a strike needs a swipe past 40% of the width or a tap on the check area; vertical scroll wins over a brush |
| K46.10 | Maximum brightness | Ink at AA on Porcelain; the seam and struck rows stay legible; no meaning by color alone |
| K46.11 | Leave the screen on while the trip is open (proposed, Product to rule) | The idle timer is off in the trip and back on at DONE or on leaving the page. The side button locks as usual and the trip resumes where it was |
| K46.12 | AX3 and Bold Text | Hero and rows grow, the count line wraps to 2 lines, nothing covers the Add line or UNDO slot |

### Offline

| # | Action | Expected |
|---|---|---|
| K46.13 | Airplane mode: start, check 4 rows, add "foil", move a row, finish | Everything works with no notice (ER12). Nothing waits to send |
| K46.14 | Lose signal mid-trip and regain it | No banner, spinner or line; nothing re-reads; nothing queued for Claude |
| K46.15 | Kill the app mid-trip and reopen | The trip returns with the same checked rows and hero |
| K46.16 | Claude during the trip | None: no link ask, no Tess line. A pending ask waits for the next natural trigger after DONE |

### Check, add, undo slots

| # | Action | Expected |
|---|---|---|
| K46.17 | Check "Milk" | No receipt line (the strike is the receipt); swipe right again to undo it. No slot claim, so 11 strikes do not replace the slot 11 times (proposed, Product to rule) |
| K46.18 | Type "foil" on the Add line | Tess: "Foil, on Groceries." with UNDO for **4 s** (a new row; **10 s** with VoiceOver). UNDO line "Foil, taken back." The row lands in Household; it does not take the hero |
| K46.19 | Add a row, then within 4 s check another | The check claims nothing; the add's UNDO keeps its remaining window; the next add replaces the slot |
| K46.20 | DONE with 4 checked and 3 left | Tess: "Cleared 4 from the basket." with UNDO for **10 s** (a change; 10 s with VoiceOver). UNDO line "Cleared 4, taken back." and the rows return struck. The 3 open rows stay |
| K46.21 | DONE with nothing checked | Tess: "Nothing to clear." (proposed, Product to rule). No op, no UNDO |
| K46.22 | The window runs while the phone is locked in a pocket | It pauses while locked and backgrounded; unlocking inside the remaining time still offers UNDO; after the window it is gone and nothing else changes |
| K46.23 | VoiceOver on | UNDO stays 10 s. The hero reads "Produce, 3 to get, then Dairy and eggs." A row reads its name, amount and "for tacos"; a struck row reads "got". Custom actions: "Check", "Move to another aisle" |

### Privacy and the planned cook

| # | Action | Expected |
|---|---|---|
| K46.24 | A walled row in the trip | It reads "Private item" on the list; a plain tap opens its words, as a Private note does (decisions 8:14 PM Oct 16: no Face ID gate). Flag F4 |
| K46.25 | Rows from a Private recipe's share | Each reads as itself unless walled; no row says "for Private recipe" or the recipe's name |
| K46.26 | Home while the trip is open | The planned cook's row "2 to buy" counts down as he checks; at 0 it returns to the time (`groceries-ai-acceptance.md` section 5). No notification, Live Activity or widget change |

---

## K47. Recipe delete, undo and restore across Week, Lists and widget

**Source rules.** No screen deletes a recipe on master (`undo-lines.md` W13); the route is Tess ("delete the tacos recipe") or UNDO of the save. A gone recipe's page reads "Recipe gone." (centred, the page's own line in the context color, not cobalt) with one button "Back to the list" (ruled, decisions 3:00 Oct 17; `kitchen-v2-acceptance.md` G3, failing on master until Core lands it). **Gap G7** (`kitchen-gap-hunt-2.md`): a delete leaves the recipe's share in the Groceries rows. Rows keep the deleted amounts (an onion row reads "5 onions" with only "2 onions" explainable), the "for tacos" label silently vanishes (links to deleted objects are filtered), and `toBuy(for:)` still counts that id, because `RemoveRecipeFromGroceries` runs only from a skip or a re-add. **Expected after the fix:** a delete does to Groceries what a skip does (`decisions.md` line 282), in the same undoable op. Receipt "Tacos, removed." with UNDO 10 s (a change; proposed, Product to rule). Fixture: Tacos planned Thursday, 7 pm (7 rows, "for tacos" under each, the onion row also carries a typed "2 onions"), Dal Friday, 6:30 pm, a List item "@Tacos", the Kitchen medium widget with Tacos next.

### Delete and what follows (G7)

| # | Action | Expected |
|---|---|---|
| K47.1 | Tell Tess "delete the tacos recipe" | "Tacos, removed." with UNDO for 10 s (short name, thing first). One op, one UNDO, no question first. A name matching two recipes: Tess asks which, with both full titles, and deletes nothing yet |
| K47.2 | Open Groceries right after (G7) | Rows only for Tacos are gone. Shared rows keep their other amounts: the onion row reads "2 onions" (the recipe's 3 leave). No row says "for tacos"; no quantity includes a deleted recipe's share. Checked rows stay. The count line falls from "9 to get, for tacos and 2 more" to the rows left |
| K47.3 | Some Tacos rows were already bought | Checked rows stay struck; open rows go. A row also for Dal loses only the Tacos share and keeps "for dal" |
| K47.4 | A row linked by the Claude ask (KEEP wrote a link-only share on "scallions") | The link-only share leaves; the typed row stays with its typed amount and learned aisle; no "for ..." remains. A delete sends nothing to Claude |
| K47.5 | Tap UNDO within 10 s | The recipe returns with source text, notes, cook log and serves; the plan returns; the rows return **in the same step**, each with its original share and "for tacos"; the onion row reads "5 onions" again; the count line is "9 to get, for tacos and 2 more". UNDO line "Tacos, taken back." One tap, never a half state |
| K47.6 | Let the 10 s pass | The delete is final in the slot; the op log keeps it for Review's process trail. No restore route afterward (flag F5). No further line |

### Week

| # | Action | Expected |
|---|---|---|
| K47.7 | Open the week after the delete | Thursday's task no longer links a recipe. It stays as a plain dated task titled as captured ("Tacos"), no recipe dab, no "N to buy", and a cook cannot start from it (proposed, Product to rule). A plan he made is not silently dropped. Side and front counts still agree (K32.1) |
| K47.8 | Home on Thursday | The row reads "Tacos" with its time and no GROCERIES key; keys are DONE and MOVE as for any task. "Tacos tonight, 2 to buy." is gone |
| K47.9 | UNDO (K47.5) after the week was opened | Thursday returns to "TACOS, THURSDAY" with its link and count; Home returns to "Tacos tonight, 2 to buy." |
| K47.10 | Delete the Private recipe (the stew) | "Private recipe, removed." with UNDO 10 s; UNDO line "Private recipe, taken back." (proposed, Product to rule). Never the name. Its rows go the same way; "Private item" masks stay masks. It has no stored photo to restore (P4) |
| K47.11 | Delete while a cook of it is open or running | Refused: "Tacos is cooking now." (proposed, Product to rule). Nothing is deleted until the cook ends |
| K47.12 | Delete a recipe cooked twice | The cooks stay in the log and in Review's counts ("Cook 2 of 4" does not change); the log line reads the short name; tapping it opens "Recipe gone." UNDO restores the link |

### Lists

| # | Action | Expected |
|---|---|---|
| K47.13 | Open the List with "@Tacos" | The link to a deleted object drops out. The item keeps its words and reads "Tacos" as plain ink, not underlined, not tappable (proposed, Product to rule). After UNDO it is the underlined ink link again (the link is only filtered, never removed) |
| K47.14 | Open the deleted recipe from a stale route (back stack, widget tap, old Spotlight result, `tessera://recipe/<id>`) | The page reads "Recipe gone." centred in the context color, no title, no key, no navigation bar, and one button "Back to the list" that returns to Recipes. Not "This recipe is gone. Undo brings it back." (the code's string today) |
| K47.15 | The recipe page is open when Tess deletes it; then UNDO | The page changes to "Recipe gone." in place (150 ms crossfade); on UNDO it returns at its old scroll point. No crash or blank page |
| K47.16 | Recipes shelf | The row leaves with a 380 ms collapse (Reduce Motion: 150 ms crossfade); the count falls ("37 recipes"); on UNDO it returns in place. Spotlight and the area index drop it on delete and restore it on UNDO; a private one is never indexed (K32.11) |
| K47.17 | A List item "buy @Tacos ingredients" | Reads "buy Tacos ingredients" in plain ink; the link returns on UNDO |

### Widget and other surfaces

| # | Action | Expected |
|---|---|---|
| K47.18 | Kitchen medium widget with Tacos next; delete Tacos | The timeline reloads; within one reload it shows the next cook ("Dal, 6:30 pm.") or, with none, "Nothing planned" (KW-W7), plain ground. The deleted name, photo and wash are gone from the shared cache |
| K47.19 | UNDO the delete | The timeline reloads and the widget returns to Tacos with the same wash pixels (seeded by the recipe id; KW-W10, KW-W11) |
| K47.20 | Delete while the widget is off screen, then add it | It shows the post-delete state; a deleted recipe never gets a wash |
| K47.21 | Lock Screen accessory widgets | Inline and rectangular show the next cook or "Nothing planned"; circular shows the next time or the plain Kitchen mark |
| K47.22 | Siri and reminders after the delete | "what's for dinner" does not read Tacos (K45.19). A scheduled cook reminder is cancelled with the delete and returns with UNDO; nothing fires for a gone recipe. A private recipe's reminder title stays "Private recipe" until cancelled |
| K47.23 | Backup and Review | The process trail reads "Tacos, removed."; a backup taken after UNDO has the recipe; a backup taken between delete and UNDO holds no row carrying a deleted share |
| K47.24 | Copy sweep | The words are "removed", "taken back", "Recipe gone.", "Back to the list"; never "deleted", "trash", "bin" or "Are you sure"; no emoji; no cobalt on "Recipe gone." |

---

## Assumptions and flags

**Assumptions taken (not ruled; Product to rule).**
1. A photo is read on the phone and the picture never goes to Claude (K43). If Product wants Claude to see images, the money wall cannot hold for K43.9 and the rows change.
2. No photo is stored for a recipe imported from a picture in v1 (K43.2).
3. Proposed copy, each marked in its row: the K43 photo lines and the ASK CLAUDE key, "Private recipe saved.", "Oat milk, not now.", Siri's "Face ID needed to add to Groceries.", "Milk, already on Groceries.", "Milk and eggs, on Groceries." and "Nothing planned." for Siri, the trip's "Nothing to clear." and "Cleared 4, taken back.", and K47's "Tacos, removed.", "Private recipe, removed.", "Tacos is cooking now." and the plain-text link and plain-task outcomes.
4. Ruled copy reused word for word: `RecipeLinkLine` (`found`, `saved`, `takenBack`, `claudeRead`, `claudeTimeout`, `claudeBusy`, `badKey`, `paused`, `offline`, `noRecipe`), "Milk, on Groceries.", "Private item, on Groceries.", "Private note, kept.", "Private recipe, 7 pm." and its no-time forms, "Recipe gone." with "Back to the list", "Cleared N from the basket.".
5. UNDO: a new row 4 s, a change 10 s, 10 s with VoiceOver. A strike in the trip is its own undo and claims no slot.

**Flags.**
- **F1. Stale count.** `pantry-light.md` rule 9 says at most 3 names; `groceries-ai-acceptance.md` section 4 and Design 47 say 4. K44.2 follows 4; pantry-light needs the edit.
- **F2. Locked read of an ordinary title.** K32.10 says the locked read gives the same text, while the widget lets the system redact an ordinary title (K41.1). Whether Siri may speak "Tacos, 7 pm." without Face ID is not ruled (K45.13). The private case is safe either way.
- **F3. Which cook is "dinner"** when two are planned the same day (K45.17) is not ruled; proposed: the later one.
- **F4. "Private item" hides what he must buy in the store** (K46.24). Notes open on a plain tap; Groceries has no ruling. Product to rule whether the trip shows the words on an unlocked phone.
- **F5. No restore after the 10 s window** (K47.6). A "bring back" phrase or a Review restore is neither built nor ruled.
- **F6. G7 fails today.** K47.2, K47.5, K47.13 and K47.14 fail on master until Core lands share removal in the delete op and the "Recipe gone." page (already failing as G3).
- **F7. Build targets.** Nothing on master reads a picture (K43), draws the history long-press line, or has the one-handed trip checks; these rows are targets for Core and Builder B.
- **F8. Job table.** A photo import adds no new job: it is the "recipe reader" job (C2) with a different source, so it keeps the same trigger, priority and $40 rule.
