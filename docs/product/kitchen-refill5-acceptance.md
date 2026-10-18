# Kitchen REFILL 5, Lane 2: acceptance rows K29 to K33

*Kitchen lead, 2026-10-17 (board `kitchen.md` line 52, "2:45 AM REFILL 5", Lane 2). Docs only, no code. Design sheets found and read: `/mnt/project-files/tessera/design/lists-recipes-87.md` (sheet 87, Lists and Recipes front) and `/mnt/project-files/tessera/design/imagery-88.md` (sheet 88, Imagery); neither is under `docs/design` on master. Row format and numbering follow `grocery-capture-miss-acceptance.md` (CM), `recipe-plate-acceptance.md` (P), `lists-acceptance.md` and `kitchen-v2-acceptance.md`. Each row is runnable: an action, then the expected result with the exact copy. Decision "2:40" in the board text is cited as the board gives it; no 2:40 AM Oct 17 entry exists in `decisions.md` on master, so the rows treat the board's wording as the ruling (see "Assumptions").*

**House rules used by every row.** Receipts name the thing first and use "on" ("Milk, on Groceries."). No "at" before a time. Clocks are lowercase ("8:30 pm"). Digits for counts. US English and units. A walled thing reads "Private item", "Private recipe" or "Private note". List @links are ink, underlined, never cobalt; cobalt is Tess's voice only. Quiet hours 23:00 to 07:00; the day starts at 4 AM. Money appears only with an amount or a currency sign. No row, fixture or log in this file contains a key or a key-shaped string; tests build any needed fake with `ClaudeSection.fakeKey`. No row runs a live Claude call: Claude is a stub in every test.

---

## K29. Cook mode, capture-miss voice phrase "add 2 lbs chicken $9"

Decision (board, 2:40): the grocery lands, the price is dropped, and the phrase never enters the miss log when it is walled. "What was sent" shows "Private phrase" and the time only when the phrase was walled. Pairs with CM1 to CM14 in `grocery-capture-miss-acceptance.md` (strip once, before anything leaves the engine; receipt "{Thing}, on Groceries.") and `cook-mode-acceptance.md`. "Miss log" = `capture-misses.jsonl`. "Sent log" = the receipts rows under WHAT WAS SENT (sheet 80), which hold no words that were sent.

Setup for rows 1 to 6: cook mode open on a running cook, "Tess asks Claude" on, a stubbed Claude, grammar unable to read the phrase.

| # | Action | Expected |
|---|---|---|
| K29.1 | Speak "add 2 lbs chicken $9" in cook mode; the grammar reads it | Chicken lands on Groceries as "Chicken", quantity "2 lbs"; no 9 and no $ on the row, note, receipt or anywhere on screen. Tess's receipt: "Chicken, on Groceries." Cook mode keeps its step, timers and resume point untouched; no screen change beyond the receipt |
| K29.2 | Speak "add 2 lbs chicken $9"; the grammar misses and the stub returns one item | Same result as K29.1: "Chicken, on Groceries.", quantity "2 lbs", price gone. The text the stub receives is "add 2 lbs chicken" (the price stripped once, before the send; the request body holds no digit-with-currency and no "$") |
| K29.3 | After K29.2, open Settings, Claude, WHAT WAS SENT, then the job's receipts | One new row with the time only, lowercase, no "at" (for example "9:05 am"), under the job that handled it. Not "Private phrase": the phrase was not walled. No words from the phrase appear on the row |
| K29.4 | Speak a walled grocery phrase in cook mode: "out of my metformin $40" | Row titled "Private item" on Groceries; the drug name never on the row, receipt or Tess's line. Receipt: "Private item, on Groceries." The price is dropped. The miss log gets no line (walled phrases stay out of the miss log) |
| K29.5 | After K29.4, open WHAT WAS SENT receipts | The row reads "Private phrase" and the time ("9:07 am"), nothing else: no words, no price, no item name. The 30-day count rises by 1 and equals the sum of the job counts (sheet 80). The same phrase is in no other log |
| K29.6 | Count log lines: run K29.2 and K29.4, then read the miss log | The miss log holds the K29.2 line only if the grammar missed it (text "add 2 lbs chicken", route "grammar", source "ghost row", no price); it holds nothing for K29.4. A grep over the miss log, the request bodies and the rows for `\$\d` and `\d+\.\d{2}` finds nothing |
| K29.7 | Repeat K29.2 with "Tess asks Claude" off | Nothing is sent and no sent-log row is added. The phrase stays a log line only; Tess says "Didn't catch that." and no row lands (CM12) |
| K29.8 | Repeat K29.2 while a step timer is within 10 s of ending | The grocery receipt does not displace the timer's flare or notification (the in-app flare replaces the banner, `cook-mode-acceptance.md`); both appear, the receipt in the UNDO slot at Tess's band |
| K29.9 | Speak "add 2 lbs chicken $9", then tap UNDO inside the slot | New capture, so the slot is 4 s (10 s under VoiceOver). UNDO restores the exact prior Groceries state; Tess says "Chicken, taken back." Cook mode is unchanged |
| K29.10 | Speak "add 2 lbs chicken $9" with a key-shaped string built by `ClaudeSection.fakeKey` earlier in the same phrase | Nothing is sent, nothing is logged, no row; Tess says "Didn't catch that." (CM11). The key never appears in the sent log, the miss log or a request |
| K29.11 | Quiet hours: run K29.1 at 23:30 | The grocery lands and the receipt shows as normal (an on-screen receipt is not a notification). No notification is created for it. The sent log time reads "11:30 pm" |
| K29.12 | VoiceOver: run K29.1 | Announced once, high priority, focus does not move: "Chicken, on Groceries." For K29.4: "Private item, on Groceries." Never the price, never the drug name |

---

## K30. Recipes imagery against sheet 88: empty, loading, failed image, dark

Sheet 88 rule: an image is information or identity, small, on the phone, never decoration. Plate geometry 393 x 56 pt, full bleed, opaque to y 34 and melting by y 56, scrolls away with the page; wash (34% of the object's pigment, grain at 55%) WITHDRAWN (drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18), photo only; photo dries in over 380 ms (150 ms crossfade under Reduce Motion). Complements P1 to P19 in `recipe-plate-acceptance.md`; this block adds the four named states. Photo fetch happens once, at Save.

| # | State | Action | Expected |
|---|---|---|---|
| K30.1 | Empty (class page) | Open Recipes with no recipe saved | Context line "None yet". Row area shows "No recipes yet." at 66% ink. Tess (cobalt, her band only): "Paste a link or a page and I'll read it." No art, no wash, no plate, no pocket, no drawing, no placeholder icon, no "add a photo" prompt, no guilt, no count |
| K30.2 | Empty (recipe, no photo and no ingredients) | Open a typed recipe with zero ingredient lines | No plate: no wash, no colour, no drawing (drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18); title and back word untouched |
| K30.3 | Empty (recipe, typed) | Open a typed recipe with ingredient lines "paprika", "sweet potato", "lemon" | No plate and no ingredient-colour pigment (drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18); the page reads the same on every open |
| K30.4 | Loading | Save a recipe from a link whose og-image is slow, then open the page at first paint | Nothing is drawn at first paint (no wash). No spinner, no grey box, no placeholder icon, no skeleton, no progress. The page never waits on the image |
| K30.5 | Loading | The image arrives while the page is open | The photo dries in over the wash in 380 ms (opacity 0 to 1, blur 5 to 0, saturation .6 to 1). Under Reduce Motion: a 150 ms crossfade. The title and rows do not move |
| K30.6 | Loading | Open the same recipe again | The photo is already on the phone: shown with no fetch, no second request; the dry-in does not replay |
| K30.7 | Failed image | Save a recipe whose og-image returns 404, 5xx, times out, or is offline | The recipe saves and shows no plate (K30.3 rules). No error line, no "image failed", no retry loop, no second request. Tess says nothing about the image. Re-saving from the link is the only refresh |
| K30.8 | Failed image | Og-image over 2 MB, over 16 megapixels, `image/svg+xml`, `text/html`, or a file that claims `image/jpeg` but will not decode | Same as K30.7: no plate, silence (P15, P16) |
| K30.9 | Failed image | Offline recipe link at Save | The recipe link waits (K33); no plate is drawn for a recipe that does not exist yet. When it is read later, the plate follows K30.4 and K30.7 |
| K30.10 | Dark (Obsidian) | Open a recipe with a photo, then one without, in Obsidian | No wash in either theme (drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18); the photo, where there is one, has the same 380 ms dry-in over the ground `#121014`; the plate still melts by y 56; ink 245,242,236. The pale-food shading rule is withdrawn with the wash |
| K30.11 | Dark | Open the empty class page in Obsidian | "No recipes yet." at 66% ink stays readable (6.9 to 1 on Obsidian per sheet 87); Tess's line in her cobalt `#86B4FF`; context uses `#B8A3FF`. No plate |
| K30.12 | Dark | Open a Private recipe in Obsidian and in Porcelain | Plain ground in both: no photo, no plate. Zero requests for its image at Save (P17); making a recipe Private deletes its stored photo |
| K30.13 | Dynamic Type AX3 | Open a recipe with a photo at AX3 | The plate stays 393 x 56 pt (points, not scaled); the title and rows move down under it; Tess's band at 686 to 820 and the page's 50 pt fade from 686 are unchanged |
| K30.14 | VoiceOver | Focus a recipe with a photo, then one with no photo | Photo: one image read right after the title, "Photo of Sheet-pan paprika chicken, from budgetbytes.com". No photo: no plate, no stop. The empty class page has no image stop |
| K30.15 | Scope | Open Groceries, Pantry, Lists, Paste and cook mode | No image or drawing on any of them (P12). The Ingredient page has no plate or pocket (drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18); the Kitchen medium widget wash is open for Product (`kitchen-standin-sweep-oct18.md`) and is never a photo |

---

## K31. Lists empty state and 100-item scroll against sheet 87, undo slot 4 s / 10 s

Sheet 87: Lists is the shelf in the sweep-19 frame (Title "Lists"); Groceries is always on the shelf, so "empty" means no other list. Taking a thing away is one gesture, one line and a way back. UNDO is one app-wide slot: 4 s for a new capture, 10 s for a remove or a change, 10 s under VoiceOver (a flat window, `decisions.md` 1:48 PM Oct 16, C3). Extends `lists-acceptance.md` and `lists-screens-acceptance.md`.

| # | Action | Expected |
|---|---|---|
| K31.1 | Open Lists with only Groceries | Context "Just Groceries". Groceries at Hero 56 with its state word "NOTHING TO GET". One quiet line "No other lists yet." Tess (cobalt): `Say "new list: packing" and I'll start it.` No dotted outline, no illustration, no count, no button |
| K31.2 | Open the side on the empty shelf (right edge or the middle) | Opens straight to "Nothing else to show yet." Never a dead end; left edge returns |
| K31.3 | Open Lists with Packing running and Groceries | Context "2 lists, Packing running". Packing at 56 with "RUNNING, 6 LEFT" (comma, never " · "), Groceries at 34. Tess: "Packing has 6 left." |
| K31.4 | Open a list with 100 items | Scrolls as one sheet under the pinned back word; every row shows its full text (a long name wraps, never cut); nothing is dropped, paged or virtualized away from VoiceOver; count line reads "100" with digits; the sheet fades into Tess's band over 40 pt ending at y 736 |
| K31.5 | Scroll 100 items from top to bottom and back at 120 Hz, then check at AX3 | No dropped frames beyond the scroll budget in the performance test; at AX3 one column, rows at least 44 pt, Title 58, names wrap in full, Tess at most 3 lines |
| K31.6 | In the 100-item list, check item 57, then use "Uncheck all" | Item 57 checks in one op; the count rolls ("43 left" to "42 left", digits). "Uncheck all" is one op and one undo restoring every `checkedAt`. No row jumps position |
| K31.7 | Add one item by voice ("add rice") to the 100-item list | New capture: receipt "Rice, on Groceries." in the UNDO slot; UNDO is shown for 4 s; at 4 s the slot closes silently. A tap on UNDO inside 4 s restores the exact previous state and says "Rice, taken back." |
| K31.8 | Swipe left on "Rice" in the 100-item list and commit past 96 pt | REMOVE rises in `live` at 60 pt; rows close up; the count rolls ("101 to get" to "100 to get"); Tess: "Rice, removed." with UNDO. The slot is 10 s |
| K31.9 | Tap UNDO at 9 s after K31.8 | The row returns in the same position, wet, with `checkedAt` as it was; Tess: "Rice, back on Groceries." At 10 s with no tap, the slot closes silently and the removal stands |
| K31.10 | Change an item's quantity (a change, not a capture) | Slot is 10 s; receipt names the thing first, for example "Rice, 2 lbs." UNDO: "Rice, taken back." |
| K31.11 | VoiceOver on: remove an item and leave focus elsewhere for 30 s | The slot stays 10 s and does not extend while focus rests on UNDO (VO20 and VO40 are struck). Announced once, high priority, focus does not move: "Rice, removed." A VoiceOver custom action Remove on the row does the same; Check off is the other action |
| K31.12 | VoiceOver on: add one item by voice | The slot is 10 s, not 4 s. Announced: "Rice, on Groceries." |
| K31.13 | A second change inside an open slot | The one app-wide slot is replaced by the newest line; the earlier action's UNDO is gone (one slot, not a stack) |
| K31.14 | A Private item among the 100 | Its row reads "Private item" at 66% ink and nothing else; removal says "Private item, removed." and UNDO says "Private item, back on Groceries." Its words are in no row, Tess line, VoiceOver, Spotlight or count line |
| K31.15 | Reduce Motion on | The row leaving and every side stop use a 150 ms crossfade; the count change does not count up |
| K31.16 | Copy sweep on the Lists screens | No "at" before a time; no "…"; no " · "; no "Archive" (the word is "put away"); no cobalt on any @link (ink, underlined); cobalt only on Tess's line |

---

## K32. Week plan with a private recipe: label, widget, Siri read-out

Sheet 87 and 88: a private recipe's name appears nowhere (row, context, side, Tess, VoiceOver, Spotlight, index, widget, Siri). Its label masks as "Private recipe". The Kitchen widget shows plain ground with no pigment and no recipe title. Siri follows the private-task precedent ("Private task, 8 pm.", no "at"; `decisions.md` 5:58 PM Oct 16). Related: `kitchen-widget-wash-acceptance.md` KW-W8 (its bare "Private" is replaced by the ruled "Private recipe, 7 pm.") and `meal-plan-groceries-acceptance.md`.

Setup: week plan holds tacos (Thu) as an ordinary recipe and a recipe named in test code "Sunday secret stew" marked Private, planned for Friday, 7 pm. The stew's name is never typed in expected copy below; the test asserts its absence.

| # | Surface | Action | Expected |
|---|---|---|---|
| K32.1 | Kitchen week side | Open the week's cooks | Thursday reads "TACOS, THURSDAY"; Friday reads "Private recipe, Friday" at 66% ink with its "N to buy" count, nothing tappable that reveals the name. The count equals the front's |
| K32.2 | Kitchen front | Open the week plan | The Friday row's label is "Private recipe" with its day; the row opens the recipe on the phone with a tap like any row |
| K32.3 | Recipes class page | Open Recipes with 38 recipes, 2 private | Context "38 recipes, 2 private". The two rows read "Private recipe" with their day. KEPT PRIVATE on the side: "Private recipe", 2, nothing tappable behind it |
| K32.4 | Tess | Open the week with the private recipe as the top | Tess says "Private recipe" if it is the top; never its name. Example: "Private recipe is the one you cook most." Cobalt only on her line |
| K32.5 | Medium widget | Add the Kitchen medium widget with Friday's private cook next | Plain ground, no wash, no pigment, no recipe title. The only copy is "Private recipe" with the time lowercase and no "at": "Private recipe, 7 pm." Light, dark, tinted and clear modes all show the same words |
| K32.6 | Small and quiet widgets | Add each with the private cook next | Plain ground; small widget shows "Private recipe" and the time only ("7 pm"); no title, no photo, no wash, no ingredient |
| K32.7 | Widget cache | Read the widget's timeline and shared container | Neither holds the recipe's name, photo, ingredients or notes; only the string "Private recipe" and the time |
| K32.8 | Siri | Ask "What's for dinner Friday?" | Siri says "Private recipe, 7 pm." Never the name, never an ingredient, never "at". Ask "What's for dinner Thursday?" and Siri says "Tacos, 7 pm." |
| K32.9 | Siri | Ask "What's on the plan this week?" | Siri reads each cook in order; the private one is spoken as "Private recipe" with its day. Digits are spoken as counts ("2 cooks this week"). Never its name |
| K32.10 | Siri, locked phone | Run K32.8 with the phone locked | Same text; the private cook's line is "Private recipe, 7 pm." and nothing about it is displayed on the lock screen |
| K32.11 | Spotlight and index | Search the stew's name in Spotlight and in the area index | No result for it; a search for "Private recipe" returns nothing that opens the stew. No donation to Siri suggestions carries its name |
| K32.12 | Notifications and Live Activity | A reminder for Friday's cook is due 6 pm | The notification title reads "Private recipe" and the body the time ("7 pm"); no name. Quiet hours 23:00 to 07:00 apply: a reminder inside them is held to 07:00. A cook Live Activity for a private recipe shows "Private recipe" only |
| K32.13 | VoiceOver | Focus the Friday row, then the widget | "Private recipe, Friday"; the widget reads "Private recipe, 7 pm". Custom action names never include the name |
| K32.14 | Groceries from the plan | Add Friday's ingredients to Groceries | Receipts name the thing first: "Private item, on Groceries." for any item that is walled; ordinary items "Olive oil, on Groceries." The recipe's name is not written on any grocery row's note |
| K32.15 | Claude | Run every Kitchen job with the week planned | The sent log and request bodies hold nothing from the private recipe (no name, no text, no ingredients); a recipe-reading job for it makes zero requests. A stubbed Claude records nothing about it |
| K32.16 | Make a recipe private after it is planned | Make "Tacos" Private on Thursday | Row, side, Tess, widget, Siri and Spotlight switch to "Private recipe" on the next render; its stored photo is deleted (P4); making it public again does not bring the photo back until a re-save from its link |

---

## K33. Offline recipe-link retry; the retry inbox is live-only for walled phrases

Decision (board, 2:40): offline recipe-link retry rows, and the retry inbox (TessInbox) is live-only for walled phrases, meaning a walled phrase is never queued to disk for later; it works only while the app is live and online. Builds on `kitchen-error-states-acceptance.md` ER1 and ER5 ("Recipe link, kept for later."; "Read 1 waiting. 1 to check."), the 11:35 AM Oct 16 decision (the inbox retry must screen every wall), and CM13 (retry re-screens the stripped text).

| # | Action | Expected |
|---|---|---|
| K33.1 | Offline, paste a recipe link on the Paste screen | Tess (cobalt, in the UNDO slot at her band): "Recipe link, kept for later." Never the URL. The link waits as one TessInbox item; typed text stays in the box. No UNDO, no tap, no error colour. No haptic |
| K33.2 | Go back online with the app open | The link reads itself once (a single page GET through the link-fetch guard: https only, at most 5 redirects (ruled Oct 17 8:40 AM), no private-network addresses, 10 s timeout). It lands as a ghost recipe and never commits alone. Receipt: "Read 1 waiting. 1 to check." |
| K33.3 | Relaunch the app offline, then online | The waiting item survives the relaunch; on the next online open it is read exactly once (no duplicate ghost recipe if the app foregrounds twice) |
| K33.4 | Retry fails again (timeout, 8 s per request, 15 s whole) | Same line "Recipe link, kept for later."; the item stays queued; there is no loop and no tap; it retries when the app next comes to the foreground, not in the background |
| K33.5 | Retry returns a page that is too big or odd (3 MB, wrong content type, more than 5 redirects, non-https hop, private host) | The item leaves the queue; line "That page is too big or odd to read safely. Paste the text instead." The link stays in the box; nothing is stored |
| K33.6 | Retry on a link whose page text holds a secret word or a money-shaped span | The money-shaped spans are stripped from the page text before any send (2:40 PM Oct 16 decision 1); a secret word skips the Claude send and the read happens by the on-phone reader alone. No page text is sent that the wall forbids |
| K33.7 | Offline, speak a grocery phrase that is not walled ("add 2 lbs chicken $9") and the grammar misses | Tess: "Claude is busy. Kept it for later." The stripped text ("add 2 lbs chicken") is queued, not the original. On retry the same result as K29.2: "Chicken, on Groceries." (CM13) |
| K33.8 | Offline, speak a walled phrase ("out of my metformin $40") | It is not queued. Nothing is written to the inbox on disk, in memory beyond the screen, the miss log or the sent log. Tess: "Private item, on Groceries." only if the on-phone grammar can place it; otherwise "Didn't catch that." Nothing waits |
| K33.9 | After K33.8, go online, relaunch, wait 5 minutes | No Claude call occurs for that phrase at any time (the stub records zero calls); nothing reappears from the inbox. The phrase cannot be recovered from the app's files (a grep of the store, inbox and logs finds no word of it) |
| K33.10 | Online, speak the same walled phrase | Handled live per CM10: "Private item, on Groceries." The sent log row reads "Private phrase" and the time, nothing else (K29.5); the miss log has no line |
| K33.11 | The app is killed with a live walled phrase mid-flight | On next launch the phrase is gone, not retried and not asked about; the user is told nothing; no inbox row exists. (Live-only means a lost phrase is lost, by design) |
| K33.12 | Queue a mix: 1 recipe link, 1 unwalled grocery phrase, 1 walled phrase, offline; go online | Drain: "Read 1 waiting. 1 to check." for the link; the grocery phrase drains with its receipt; the walled phrase was never queued (K33.8). The queue count shown anywhere equals the items held, in digits |
| K33.13 | Key-shaped string in a queued phrase (fake built in test code) | Never queued, never sent, never logged: "Didn't catch that." |
| K33.14 | "Tess asks Claude" off while items are queued | The queued items are held (not sent, not lost); the recipe link still reads through the on-phone reader; the grocery phrase waits until the switch is on, then re-screens and sends once. Switching off never sends |
| K33.15 | Quiet hours | A queue drain between 23:00 and 07:00 posts no notification and no sound; receipts show on screen when the app is opened. Day boundary: a link queued at 3:30 am belongs to the previous day until 4 AM |
| K33.16 | VoiceOver | The "kept for later" line is announced once, high priority, focus does not move; the drain line is announced the same way. "Read 1 waiting. 1 to check." is read in full, digits as given |
| K33.17 | Copy sweep | No "offline" or "you're offline" wording on any screen (offline is not a state); no URL, key, private word or "…" in any line; no "at" before a time |

---

## Assumptions and flags

1. **Board decision "2:40" has no text on master.** `decisions.md` has no entry for 2:40 on Oct 17. K29 and K33 follow the board line as written: walled phrases stay out of the miss log (K29), and the retry inbox is live-only for walled phrases (K33). If the real ruling differs in detail (for instance whether a walled send is allowed at all, as 2:33 AM Oct 17 permits in CM10), K29.4, K29.5, K33.8 and K33.10 need a one-line change.
2. **K29.5 reading.** "Private phrase" with the time is the sent-log receipt row for a walled phrase that was sent (stripped, per CM10); a walled phrase that is not sent leaves no receipt row at all. Both leave the miss log empty.
3. **K32 copy is RULED (Design, Oct 17, via the chief of staff).** With no time the line reads "Private recipe, today." or "Private recipe, tonight." (add one row for each if a build shows the no-time case). Originally inferred: "Private recipe, 7 pm." for the widget, Siri and notification is taken from sheet 87 ("Private recipe") plus the Siri precedent "Private task, 8 pm."; this supersedes the widget wash file's default of the single word "Private" (KW-W8).
4. **K31 numbers.** The 100-item count line, "42 left", and the 120 Hz scroll check are test choices, not sheet text; sheet 87's long state draws 9 lists and 38 recipes, so a 100-item list is an extension of its "long" rule (one sheet, nothing cut).
5. **Defaults taken, not ruled:** the miss-log line for K29.2 carries the stripped text only; the notification title for a private cook (K32.12) is "Private recipe"; the lost walled phrase after a kill (K33.11) is silent.
