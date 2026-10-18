# Kitchen REFILL 8, Lane 1 and Lane 2 rows: acceptance rows K51 to K55 and K58

*Kitchen lead, 2026-10-17 (board `kitchen.md` line 58, "3:14 AM REFILL 8"). Docs only, no code. Format and numbering follow `kitchen-refill7-acceptance.md` (K43 to K47) and `kitchen-refill6-lane1-acceptance.md` (K34 to K38). Read and checked against: those files, `kitchen-refill6-lane2-acceptance.md`, `pantry-acceptance.md` (S5, S6), `kitchen-refill5-pantry-acceptance.md` (K27.13, K27.19), `groceries-ai-acceptance.md` section 4, and the rulings listed below. Where an earlier file already holds a row, this file points at it and adds only what changes. Rows that change an earlier ruling say so and name the row they replace: K51 replaces K46.24 and flag F4; K52 settles flag F2; K53 settles flag F3; K54 settles flag F5; K55 settles assumption 1 of REFILL 7; K58 replaces K27.13 and S6. Copy not yet ruled is marked "proposed, Product to rule".*

**Rulings used by every row.**
- A photo is read on the phone; the picture never goes to Claude and is not stored.
- Link and reader asks happen only on his tap, and never retry on their own.
- Trip mode always reads a Private item as "Private item"; one tap strikes it, nothing shows its words (K51, as ruled by G102, Oct 17).
- A locked phone's Siri reads ordinary titles; a private one is read as "a private item" (K52).
- No restore after the 10 s delete window (K54).
- Receipts name the thing first and use "on" ("Milk, on Groceries."). No "at" before a time. Clocks are lowercase ("8:30 pm"). Digits for counts. US English and US units.
- A walled thing reads "Private item", "Private recipe" or "Private note". On the widget, in Siri and in a notification a private recipe reads "Private recipe, 7 pm."
- Money and body facts never go to Claude. Cobalt is Tess's voice only; every other link is ink, underlined. Quiet hours 23:00 to 07:00; the day starts at 4 AM.
- No row runs a live Claude call: Claude is a stub in every test. No row, fixture or log holds a key or key-shaped text (tests build any fake with `ClaudeSection.fakeKey`).

**UNDO windows (`UndoWindow`, decisions 12:45 PM Oct 16).** A new thing: 4 s. A change to something that already exists: 10 s. With VoiceOver on, every UNDO: 10 s. The window pauses while the app is backgrounded or the phone is locked. One UNDO slot, last write wins. Every UNDO has a line saying what it took back, thing first ("Milk, taken back.").

**Fixtures.**
- **Dal** and **Tacos** as in `kitchen-refill6-lane1-acceptance.md`. Tacos planned Thursday, 7 pm, 2 open rows. Dal Friday, 6:30 pm.
- **Sunday secret stew**: a recipe marked Private, planned tonight, 7 pm. Its name is never typed in an expected line; every row asserts its absence.
- **Trip list**: 11 open rows over produce (3), dairy and eggs (2), meat (1), cans and jars (2), pantry (1), frozen (1), household (1), plus **two** Private items: "Ozempic refill" (other) and "rent 2100" typed as an item (other). Their words are never typed in an expected line. Ordinary rows: "Milk", "Eggs", "Spinach".
- The clock is the app clock (`-demoTime`), simulator only.

---

## K51. Trip mode: a Private item always reads "Private item" (G102, Oct 17)

**Source rules.** In the trip (K46) a walled row reads "Private item". It always reads "Private item". One tap strikes it (puts it in the basket) like any other row. Nothing shows its words: there is no reveal and no "Shows it" hint. **Ruling G102 (Product, Oct 17) supersedes the earlier tap-to-reveal rule (K51, B8).** This replaces K46.24 (a plain tap opened the words with no re-mask) and closes flag F4. Words going back under the mask never applies, because they are never shown. Walled rows are still never offered in USUALLY (K44.8).

| # | Action | Expected |
|---|---|---|
| K51.1 | Hold the page title to start the trip with the Trip list | The two walled rows read "Private item" in the Other aisle (the words of neither appear anywhere, including the accessibility tree). Ordinary rows read as themselves. The count line still counts them: "13 to get" (digits). One `.impact` haptic, as K46.1 |
| K51.2 | Tap the first "Private item" row | The row stays "Private item" and one tap strikes it (puts it in the basket), like any other row. Nothing shows its words. The second "Private item" row still reads "Private item" and is unaffected. The same haptic as striking an ordinary row. No Tess line, no UNDO slot used by the tap itself (a UNDO already showing keeps its remaining time) |
| K51.3 | REMOVED by G102 (Oct 17) | Was: second tap moves the reveal. There is no reveal, so there is nothing to move. Flag F1 is moot |
| K51.4 | REMOVED by G102 (Oct 17) | Was: tap a shown row to hide it again. No row is ever shown. A struck row taps back like any ordinary struck row (K46.17) |
| K51.5 | Swipe a "Private item" row right to strike it | It strikes and sinks and reads "Private item" in strikethrough; the words are never shown. Swipe right again undoes it, as K46.17 |
| K51.6 | Check Milk, add "foil", scroll, change aisle | Milk and foil act as in K46. Every private row reads "Private item" through a scroll, an aisle change and a check elsewhere |
| K51.7 | Press the side button to lock, then unlock | Back on the trip, every private row reads "Private item". The locked screen, the app switcher snapshot and any Live Activity or widget never held the words |
| K51.8 | Tap DONE (nothing checked) | "Nothing to clear." (proposed, Product to rule; K46.21). Back on the plain list, the walled rows read "Private item" |
| K51.9 | Switch to another app and return | Every private row reads "Private item" on return. The app switcher snapshot taken meanwhile shows "Private item" |
| K51.10 | Kill the app with a private row struck; reopen | The trip returns with the same checked rows and hero (K46.15). Every walled row reads "Private item". Words are never stored on screen state because they are never shown |
| K51.11 | He checks off the last Other-aisle row, so the hero advances | The private rows read "Private item" throughout. Nothing about the words is on screen |
| K51.12 | Add a walled item on the Add line during the trip ("Ozempic refill") | Tess: "Private item, on Groceries." with UNDO 4 s (a new row; 10 s with VoiceOver). UNDO line "Private item, taken back." (proposed, Product to rule). The new row lands as "Private item" |
| K51.13 | Rows from a Private recipe's share (K46.25) | Each reads as itself unless walled. No row says "for Private recipe" or the recipe's name. A walled one among them follows K51.2 |
| K51.14 | VoiceOver on | A private row reads "Private item" with the hint "Puts it in the basket" (G102). After the tap it is struck and VoiceOver never reads the words; there is no "Double tap to show" or "Double tap to hide" and no custom action that reveals. The hero count reads "Other, 2 to get, Private item and Private item" with no words. UNDO stays 10 s |
| K51.15 | AX3 and Bold Text | Private and ordinary rows both wrap to as many lines as needed; nothing is cut with an ellipsis; nothing covers the Add line or the UNDO slot |
| K51.16 | Dump the request log, sent log, ledger, widget timeline, notification payloads and capture-miss log after K51.1 to K51.15 (K51.3 and K51.4 removed) | None holds a walled row's words. The trip made no Claude request (K46.16) |
| K51.17 | Copy sweep | The only new words are "Private item" and the VoiceOver hint "Puts it in the basket". No "hidden", "locked", "reveal", "Shows it", "tap to show" in view text; no lock icon; no cobalt (the mask and the words are ink) |

---

## K52. Locked-phone Siri reads: ordinary titles are read, private ones are "a private item"

**Source rules.** A read writes nothing and needs no Face ID, so it works on a locked phone (K32.10, K45.13). This settles flag F2: **an ordinary title is read aloud on a locked phone**. A private title is never read: Siri says "a private item" in a sentence. The recipe plan keeps its own wording on every surface: "Private recipe, 7 pm." for a recipe plan on the widget and in Siri (K32.8 to K32.10, K45.14). Writes still need Face ID (K45.2, K45.3), unchanged. Setup: the phone locked, Face ID not used, Siri heard by voice.

| # | Action | Expected |
|---|---|---|
| K52.1 | Locked: "what's for dinner" (Tacos tonight, 7 pm) | Siri speaks and shows "Tacos, 7 pm." with no Face ID prompt. Nothing opens |
| K52.2 | Locked: "what's for dinner" when tonight's cook is the stew | Exactly "Private recipe, 7 pm." (not "a private item"). Never the name, an ingredient or a step. Nothing about it is drawn on the lock screen; Siri donations and Spotlight hold no stew name |
| K52.3 | Locked: "what's for dinner" with a plan that is a plain task titled "Dinner with Maya, 7 pm" | An ordinary title: read as it is, "Dinner with Maya, 7 pm." |
| K52.4 | Locked: "what's on my list" with ordinary tasks "Call dentist" and "Pick up parcel" | Siri reads both as written: "2 on your list: Call dentist, Pick up parcel." (proposed, Product to rule). Digits for counts |
| K52.5 | Locked: the same read when one task is a Private item or Private note | The ordinary titles are read; the private one is "a private item": "3 on your list: Call dentist, Pick up parcel and a private item." (proposed, Product to rule). Words of the private one never spoken or shown |
| K52.6 | Locked: "what's on Groceries" with Milk and Eggs open plus one walled row | "3 on Groceries: Milk, Eggs and a private item." (proposed, Product to rule). The lone private row alone reads "1 on Groceries: a private item." |
| K52.7 | Locked: "what's on Groceries" and the only rows are walled | "2 on Groceries: 2 private items." (proposed, Product to rule). Never a count of words, never an aisle for them |
| K52.8 | A title that trips the money or body check, such as "weigh-in 82.5 kg" or "rent 2100" | Treated as walled: "a private item". No number, unit or amount is spoken or shown on the lock screen |
| K52.9 | Locked: "add milk" | Face ID is asked (K45.2). Writes are not made readable by this row. On a Face ID failure: "Face ID needed to add to Groceries." and nothing is written (K45.3) |
| K52.10 | Locked: read an ordinary title that was made private after it was planned | The next read says "a private item" (or "Private recipe, 7 pm." for a recipe plan). No cached old title survives in a donation, a Spotlight result or the on-screen text |
| K52.11 | Locked, Siri's on-screen text | Equals what is spoken, word for word. No emoji, no "at" before a time, no cobalt, no cut-off ellipsis |
| K52.12 | Unlocked: the same reads | The same words as locked. Unlocking never reveals a private word through Siri, and no app screen shows it in the trip either (G102, K51) |
| K52.13 | Claude and logs | No Claude request. The sent log, ledger and capture-miss log hold no title, private or ordinary. An unparsed phrase holding a secret word, money or a body fact is not logged |
| K52.14 | Copy sweep | "a private item" is lowercase inside a sentence and "Private item" at the start of a line or receipt. "Private recipe, 7 pm." keeps its capital. No "hidden", "locked" or "redacted" spoken |

---

## K53. "Dinner" definition rows

**Source rules.** "What's for dinner" and the dinner word wherever it is read (Siri, the widget caption, Home, Tess) resolves one plan by this order. (1) The slot tagged dinner on that day. (2) Otherwise the last cook that day that starts after 4 pm. (3) Otherwise there is no dinner, and Siri says what it says for an empty week: "Nothing planned." (reused from K45.16 and KW-W7; this is not a new copy). This settles flag F3 (the later one) and refines it: a cook before 4 pm is never dinner unless it is tagged. Time of day is the app clock; the day starts at 4 AM, so a 1 am cook counts for the day before. "What's for lunch" is not defined here (K45.17 stays: it gives the cook nearest noon or tagged lunch).

| # | Action | Expected |
|---|---|---|
| K53.1 | Today: Tacos tagged dinner at 6 pm, Dal at 8 pm untagged. "What's for dinner" | The tagged slot wins over a later cook: "Tacos, 6 pm." |
| K53.2 | Today: Dal at noon and Tacos at 7 pm, nothing tagged | The last cook after 4 pm: "Tacos, 7 pm." (K45.17) |
| K53.3 | Today: Dal at 5 pm and Tacos at 7 pm, nothing tagged | The last after 4 pm, not the first: "Tacos, 7 pm." |
| K53.4 | Today: only Dal at noon, nothing tagged | No dinner. Siri: "Nothing planned." Dal is not read as dinner. In the app, Tess says "Nothing planned." and the Home row does not name Dal under a dinner word |
| K53.5 | Today: Dal at 3:59 pm and nothing else; then move it to 4:00 pm | At 3:59 pm: "Nothing planned." At 4:00 pm: it counts, "Dal, 4 pm." The cutoff is "after 4 pm" read as 4:00 pm or later; proposed, Product to rule (flag F2) |
| K53.6 | Today: Dal at noon tagged dinner | The tag wins: "Dal, 12 pm." (ruled Oct 17, decisions 3:55: clocks write "12 pm", never "noon"). A tagged slot is dinner at any hour |
| K53.7 | Today: two cooks tagged dinner (Tacos 6 pm, Dal 8 pm) | The later tagged one: "Dal, 8 pm." Tess adds nothing. Proposed, Product to rule (flag F3) |
| K53.8 | Today: the tagged dinner is the stew | Exactly "Private recipe, 7 pm." (K45.14). The tag never reveals the name. A private recipe after 4 pm with no tag reads the same |
| K53.9 | Today: a dinner cook without a time (tagged or the only one) | "Tacos, tonight." (K45.15); private "Private recipe, tonight." A cook with no time is not "after 4 pm", so an untagged one with no time is not dinner: "Nothing planned." Proposed, Product to rule (flag F4) |
| K53.10 | Today: the tagged dinner is already cooked (done) | It is skipped; the next open dinner by this order is read; none: "Nothing planned." (K45.18) |
| K53.11 | "What's for dinner tomorrow" and "what's for dinner Friday" | The same order on that day: "Dal, 6:30 pm."; the stew Friday, 7 pm: "Private recipe, 7 pm." None: "Nothing planned." Never "Nothing planned tomorrow." |
| K53.12 | Cook at 1 am today by the 4 AM boundary (it belongs to yesterday) | Not today's dinner. Between midnight and 4 AM "today" is still the earlier day; a 1 am cook is read by the day it counts for |
| K53.13 | The cook was moved from lunch to evening, or a tag was added or removed | The next read follows the new state; no cached old answer survives. The widget timeline reloads (KW-W10) |
| K53.14 | Widget and Home vs Siri | All three name the same recipe and time for dinner: "Tacos, 7 pm." / "Tacos tonight, 2 to buy." (Home) / "Tacos, 7 pm." (widget). Tess's line and Home never disagree |
| K53.15 | The planned recipe was deleted (K54) | It is not read. The rule runs over what is left; none: "Nothing planned." |
| K53.16 | No Claude, no logs | The rule is a plain function on the phone. No request, no ledger row, no capture-miss entry |
| K53.17 | Copy sweep | "Nothing planned." exactly, with the period. No "no meals", "nothing for dinner", "free night". Clocks lowercase, no "at" before a time, digits for counts |

---

## K54. Recipe delete: the 10 s window and no restore after it

**Source rules.** Extends K47. Deleting a recipe is a change to something that exists: UNDO for 10 s (10 s under VoiceOver as well). The receipt names the thing first: "Tacos, removed." UNDO line "Tacos, taken back." When the window ends, the delete is **final**: there is no restore route anywhere (no Review restore, no phrase, no Trash, no backup row; this settles flag F5). Because the window is the only way back, the recipe's shares on Groceries leave in the same op (G7, K47.2) and cannot return after it. The gone recipe's page reads "Recipe gone." with one button "Back to the list". The window pauses while the app is backgrounded or the phone is locked (so the 10 s counts foreground time). One UNDO slot: a later write replaces the earlier delete's UNDO, and the earlier delete is then final at that moment (last write wins).

### The window across surfaces

| # | Action | Expected |
|---|---|---|
| K54.1 | Week: open the Thursday sheet and tell Tess "delete the tacos recipe" | "Tacos, removed." with UNDO for 10 s. Thursday's task becomes a plain dated task "Tacos" with no recipe dab and no "N to buy" (K47.7) |
| K54.2 | Lists: with Tacos open from a List item "@Tacos", tell Tess to delete it | "Tacos, removed." with UNDO 10 s. The item keeps its words and reads "Tacos" in plain ink, not underlined, not tappable (K47.13) |
| K54.3 | Widget: the Kitchen medium widget shows Tacos next; delete from the app | Within one reload the widget shows "Dal, 6:30 pm." or, with none, "Nothing planned" (KW-W7). The widget has no UNDO of its own and no delete action; its tap on the deleted recipe opens "Recipe gone." (K54.10) |
| K54.4 | Tap UNDO at 9 s on any of the three | The recipe returns with source text, notes, cook log and serves; the plan, the Lists link, the widget row and every Groceries share return in the same step ("for tacos" under each, the onion row "5 onions" again). UNDO line "Tacos, taken back." (K47.5) |
| K54.5 | Do nothing for 10 s with the app in the foreground | The UNDO leaves with no further line. The delete is final |
| K54.6 | Delete, lock the phone for 5 minutes, unlock | The window paused while locked. Unlocking inside the remaining time still offers UNDO; the receipt shows the remaining seconds, not a fresh 10 |
| K54.7 | Delete, then within 10 s add "milk" on Groceries | The later write replaces the slot. "Milk, on Groceries." with UNDO 4 s. The earlier delete's UNDO is gone and the delete is final from this moment. Proposed, Product to rule (flag F5): the one-slot rule means a later write can cut the window short |
| K54.8 | VoiceOver on: delete and wait | UNDO is 10 s (a change is already 10 s). It is announced once: "Tacos, removed. Undo." |

### After the window: nothing brings it back

| # | Action | Expected |
|---|---|---|
| K54.9 | After K54.5 open Groceries | No row says "for tacos". Rows only for Tacos are gone; shared rows keep their other amounts (the onion row reads "2 onions"). Checked rows stay. No amount includes a deleted share. Nothing on the screen offers to bring a recipe back |
| K54.10 | Open the deleted recipe from a stale route (back stack, widget tap, old Spotlight result, `tessera://recipe/<id>`) | The page reads "Recipe gone." centred in the context color (not cobalt), no title, no key, no navigation bar, and one button "Back to the list" that returns to Recipes. Not "This recipe is gone. Undo brings it back." (the string on master today, which would now be a lie after the window) |
| K54.11 | Search for the recipe in Tess ("bring back the tacos recipe", "restore tacos", "undo that") | No restore phrase exists. Tess: "Tacos is gone. I can't bring it back." (proposed, Product to rule). "Undo that" inside the 10 s is the UNDO key; after it, nothing. Never "Restored" |
| K54.12 | Review's process trail and Settings | The trail reads "Tacos, removed." as a line of history only. It carries no restore key, row action or "recover" path. No Trash or "Recently removed" screen exists anywhere |
| K54.13 | Backup taken after the window | It holds no row for the recipe and no row carrying a deleted share. Restoring the backup into a fresh install does not bring back a recipe removed before the backup was taken. A backup taken between the delete and the UNDO also holds no share |
| K54.14 | Recipe cooked twice, then deleted and finalized | The cooks stay in the log and in Review's counts (K47.12); the log line reads the short name; tapping it opens "Recipe gone." There is no way to re-attach the cook to a new recipe by name |
| K54.15 | Delete, finalize, then import or paste a recipe called Tacos again | A new recipe with a new id. It does not reuse the old plan, share, cook log, wash or link; the List item "@Tacos" stays plain ink. Nothing says "this was removed before" |
| K54.16 | Private recipe delete | "Private recipe, removed." with UNDO 10 s; UNDO line "Private recipe, taken back." (K47.10). After the window "Recipe gone." with "Back to the list" and nothing of the name. Its "Private item" masks stay masks |
| K54.17 | Delete while a cook of it is open or running | Refused: "Tacos is cooking now." (K47.11, proposed). Nothing is deleted, so no window starts |
| K54.18 | A scheduled cook reminder and a Siri read after the window | The reminder was cancelled with the delete and does not return after it; nothing fires for a gone recipe. Siri does not read the recipe (K53.15, K45.19) |
| K54.19 | Claude | A delete sends nothing to Claude and a final delete does not call Claude. The sent log holds nothing |
| K54.20 | Copy sweep | "removed", "taken back", "Recipe gone.", "Back to the list". Never "deleted", "trash", "bin", "Are you sure", "recover", "restore" in view text. No emoji, no cobalt on "Recipe gone." |

---

## K55. Photo import: on-device read, failure rows

**Source rules.** Settles the first assumption of REFILL 7 and extends K43. The photo is read **on the phone**: its words are read on the device and become a page of text. **The image never goes to Claude and is not stored**: not in the request, the sent log, the ledger, the recipe, a backup, a cache, a thumbnail or the capture-miss log. The text then goes through the same ladder as a link: the deterministic parser first; Claude only if the parser finds no recipe, only when "Tess asks Claude" is on, a key is set and money is left, and only on his tap. Every line that would go to Claude passes `ClaudeRecipeReader.sendable` first (secret words, money, body facts and a Claude key are cut line by line; a page of only cut lines is never sent). A reply passes `outputIsUnsafe` or is dropped whole. **No self-retry**: a failed ask stays failed until he taps again. Money and body facts never go to Claude. Save and UNDO are the link path's (K43.2). Setup: a stub text reader that returns fixture text per picture, a stub Claude with a recorded request log, "Tess asks Claude" on and keyed, $0 spent, online, unless the row says otherwise.

### Reading on the phone, nothing stored

| # | Action | Expected |
|---|---|---|
| K55.1 | Paste screen: choose a clear photo of a printed Dal recipe | The words are read on the device. Request log empty, sent log empty. Tess (cobalt): "Reading the photo…" (proposed, Product to rule). The parser finds the recipe and says "10 ingredients, 2 steps, 2 timers." (`RecipeLinkLine.found`). A ghost, not saved |
| K55.2 | Tap Save | "Dal saved." with UNDO 10 s (K43.2). UNDO line "Dal taken back." The source text holds the recognised words. **No photo is stored**: after Save, a scan of the app container and the backup finds no image bytes, file name or thumbnail for it; the recipe page has no photo |
| K55.3 | Leave the screen without Save, then force-quit | The picture and its text are not kept. Reopening the paste screen shows nothing from the photo. No "draft" row |
| K55.4 | Choose a photo with airplane mode on | The read works offline. A parser result shows with no notice (ER12). If the parser finds nothing and Claude would be needed: "Photo, kept for later." in the UNDO slot (proposed, Product to rule). It asks nothing when he is back online; ASK CLAUDE waits for his tap |
| K55.5 | Dump the request log, sent log, ledger, widget timeline, Spotlight index and notification payloads after K55.1 to K55.4 | None holds the picture, its file name, its location data or its date. The ledger holds job, model, token counts, outcome and latency only |

### Failures, with plain fallback lines

| # | Action | Expected |
|---|---|---|
| K55.6 | Blurry: a photo whose words read as fewer than 20 characters or scattered letters | No ghost. The text is too short to be worth Claude, so **no ASK CLAUDE key and no request**. Tess: "I couldn't read that photo. Try it in better light, or paste the text." (proposed, Product to rule). No row, no receipt, nothing in the capture-miss log. The picture is dropped |
| K55.7 | Blurry but half readable: 6 of 10 ingredient lines read, no method | The ghost holds the 6 lines. Tess: "The steps are missing. Paste them below." (proposed, Product to rule; twin of `RecipeLinkLine.stepsPaywalled`). Save works. No garbled line is repaired, guessed or invented. Nothing is sent unless he taps ASK CLAUDE |
| K55.8 | No text at all: a photo of a plate, a landscape, a blank page | No ghost, no key. Tess: "No text in that photo. Paste the text instead." (proposed, Product to rule). No request, no row, no receipt |
| K55.9 | Non-recipe text: a menu board, a street sign, a receipt | The parser finds no recipe. Tess: "No recipe in that photo. Paste the text instead." (`RecipeLinkLine.noRecipe` with "photo" for "page"; proposed, Product to rule). ASK CLAUDE is offered once (K55.12). On his tap Claude answers exactly "no recipe" and the same line shows. No ghost, row or receipt |
| K55.10 | Price-heavy: a basket screenshot with "Lentils $2.49", "Olive oil 7.99", "Total $31.20", "2 for $5 spinach" beside real lines ("1 cup red lentils") | The prices are dropped on the phone. If the parser alone finds a recipe, no request is made. If Claude is needed, the request body holds no "$", no "2.49", "7.99" or "31.20" and no "total" (assert line by line). Recipe-sized measures survive ("1.25 cups flour" keeps its amount; "paid 12.50 pounds" and "2.50 g usd" are cut). The ghost has no price in a line, note, title or source text, and the receipt mentions no money. **Money never goes to Claude** |
| K55.11 | Price-heavy and nothing else: every line of the page is cut | **No request is sent.** Tess: "No recipe in that photo. Paste the text instead." No ledger row |
| K55.11b | A card that also carries a body fact ("weigh-in 82.5 kg"), a phone number, a "login" or a "password" line | Those lines are cut before sending. If the reply echoes any of them (phone number, link, address, markup character, login word, secret word, currency amount), the whole reply is dropped and the fallback line from K55.9 shows. The sent log and request body hold none of the cut lines |

### Only on his tap, no self-retry

| # | Action | Expected |
|---|---|---|
| K55.12 | Photo with no parser result, "Tess asks Claude" on, keyed | Tess: "No recipe card there." plus one ink key ASK CLAUDE (proposed, Product to rule). **No request until he taps it.** Leaving the screen sends nothing and queues nothing. Before the tap the ledger has 0 rows and the sent log is empty |
| K55.13 | Tap ASK CLAUDE | While it works: "Asking Claude to read the recipe." One request: `claude-haiku-5-5`, `max_tokens` 4096, 20 s, one user message of cut, trimmed text under the system text that says the page is data. **No image, file name, location, date, other recipe or memory.** One ledger row, job "recipe reader" |
| K55.14 | Stub returns a clean recipe | Tess: "Claude read it. Check it, then save." (`RecipeLinkLine.claudeRead`). A ghost, not saved. Save and UNDO as K55.2 |
| K55.15 | Stub reply fails an output check (a link or address; markup; a currency amount or phone number; "login", "password" or a secret word; steering words; over-length title, ingredient or step; fewer than 2 ingredients; no steps; cut off at `max_tokens`) | Dropped **whole**, never trimmed. Tess: "No recipe in that photo. Paste the text instead." Nothing saved. The tokens stay in the ledger with outcome "nothing" (or "max_tokens") |
| K55.16 | The call fails: timeout past 20 s; 429 or 5xx; 401 or 403; offline during the call | "Claude didn't answer in time. Paste the text instead." / "Claude's busy right now. Paste the text instead." / "Claude couldn't use your key. Paste the text instead." / "You're offline. I'll read it when you're back." (the words are kept; nothing is sent on return). **No automatic retry**: after the wait, the screen, a relaunch or coming back online, the request log shows exactly the one request. ASK CLAUDE returns as a key and only his tap sends again |
| K55.17 | Gate: switch off; no key; at the $50 cap; at $45 | Off or no key: ASK CLAUDE is never drawn, no request. At the cap: no request, no ledger row, "Claude's paused until Nov 1. Paste the text instead." (`RecipeLinkLine.paused`). At $45 the reader still runs (it does not step aside at $40) |
| K55.18 | Save with a failed or empty step: tap Save when the write cannot complete (disk full or store error) | Tess, error line: "Didn't save. Try again." (ER). The ghost stays, nothing is half written, no recipe row, no ledger row for a save. Tapping Save again retries; nothing retries on its own |
| K55.19 | Private by content: a photo whose title or lines trip the secret, money or body check | Cut lines never reach Claude. The saved recipe is a Private recipe: "Private recipe saved." with UNDO 10 s; UNDO line "Private recipe taken back." (proposed, Product to rule). The name is never spoken. A recipe already private: ASK CLAUDE sends zero requests, "Private recipe. I won't send it to Claude." (proposed, Product to rule) |
| K55.20 | Two pictures that are two halves of one recipe; then 5 pictures | The texts are joined in the order chosen and parsed as one page. With 5, the first 4 are used and Tess says "Using the first 4." (proposed, Product to rule). Never one request per picture |
| K55.21 | VoiceOver and AX3 | Each notice is read once, as written. ASK CLAUDE is "Ask Claude to read this photo". UNDO is 10 s. Reduce Motion: the ghost dries by a 150 ms crossfade |
| K55.22 | Copy sweep | No "OCR", "scan", "AI", "model", "token", "Haiku" in view text; "…" only on the reading line; no "at" before a time; US English; cobalt only on Tess's lines |

---

## K58. Pantry USUALLY HAVE shows 4 names

**Source rules.** This replaces the Pantry front's three-name rule: S6 in `pantry-acceptance.md` ("Rice, coffee and 2 more": two named, then the count) and K27.13 in `kitchen-refill5-pantry-acceptance.md`. The USUALLY HAVE line at the foot of the Pantry front now names **up to 4** things on one line, then "and N more" for the rest. It is words only (ink, tappable, as S5), at the foot above Tess's band, and it never sums, counts quantities, prices or notifies. The Groceries USUALLY line is a different line with its own cap of 4 names (K44.2) and is not changed. Group label "USUALLY HAVE" at 13/700 (K27.14).

**Order (proposed, Product to rule).** The same rank as Groceries USUALLY: most overdue first (days since the last buy over its usual gap), then more buys in the window, then name A to Z. Ties never reorder between opens.

| # | Action | Expected |
|---|---|---|
| K58.1 | Pantry with 0 usual items | The USUALLY HAVE label is not drawn, no line, no gap. The page ends with the last group. No "none yet" line |
| K58.2 | 1 usual item (Rice) | "Rice" alone. No comma, no "and" |
| K58.3 | 2 usual items | "Rice and coffee". No Oxford comma with two |
| K58.4 | 3 usual items | "Rice, coffee and eggs" (proposed, Product to rule: the S5 form "Rice, coffee, eggs" without "and" is replaced so the 4 and 5+ forms read the same; flag F6) |
| K58.5 | 4 usual items | All four named, no count: "Rice, coffee, eggs and tea". Nothing says "and 0 more". (Replaces K27.13, where 4 read "Rice, coffee and 2 more") |
| K58.6 | 5 usual items | Four named, then the rest: "Rice, coffee, eggs, tea and 1 more". Digits, "and 1 more" at 55% ink, never "and one more", never "1 others" |
| K58.7 | 6 usual items | "Rice, coffee, eggs, tea and 2 more" (replaces K27.13's 6-name form "Rice, coffee and 2 more") |
| K58.8 | 12 usual items | "Rice, coffee, eggs, tea and 8 more". The count line never changes the four names it shows |
| K58.9 | Tap "and 2 more" | It opens nothing and does nothing (it is not a key). The hidden names appear only as they become the top 4, so the line is never expandable and has no menu. Proposed, Product to rule (flag F7). VoiceOver reads it as text, not as a button |
| K58.10 | Tap a shown name | It joins Groceries: "Rice, on Groceries." with UNDO 4 s (a new add; 10 s under VoiceOver). UNDO line "Rice, taken back." The name leaves the line and the next one takes its place at once. From a set of 5, the line then reads "Coffee, eggs, tea and oats" (4 names, no count, never "and 0 more"). |
| K58.11 | Left swipe on a shown name | Skips it until its next gap (`usualSkippedAt`, S5). Tess: "Rice, not now." with UNDO 10 s (a change; proposed, Product to rule), UNDO line "Rice, taken back." The line refills to 4 names from the rest, in order |
| K58.12 | Dismiss or tap down to 3, then back up to 5 (undo) | The line follows the set at every step: "Coffee, eggs and tea" (3), then on UNDO the four-and-1-more form returns in the same order. No flicker, no wrong count |
| K58.13 | A name longer than the line ("Extra-virgin olive oil from the big bottle") | Wraps to the next line whole; no name is cut with an ellipsis. At AX3 the line takes as many lines as it needs; nothing covers Tess's band at 736 to 820 (bottom inset equals the band; K26.18) |
| K58.14 | Standard type on iPhone 17 with 4 normal names | One line where it fits, two where it does not. The seam between names is a comma and a space only; no bullets, chips or pills |
| K58.15 | A walled ingredient among the usual items (a medicine or supplement) | It reads "Private item" in the name's place and counts as one of the 4 names (K27.19): "Rice, Private item, eggs and tea". With two walled items, "Private item" appears twice and each takes a slot; their words appear nowhere (front, side, index, Home, widget, Spotlight, Tess, accessibility tree). Tapping it adds "Private item, on Groceries." (UNDO 4 s) and the row lands masked. Flag F1 |
| K58.16 | A walled item that would be the 5th name | It is counted inside "and N more" like any name: "Rice, coffee, eggs, tea and 1 more". The count never names it |
| K58.17 | VoiceOver | Reads "Usually have. Rice, coffee, eggs, tea and 2 more." Each shown name is a button with hint "Adds to your list" and custom action "Not now". A masked name reads "Private item". "and 2 more" reads as text. UNDO is 10 s |
| K58.18 | Home's Pantry line and the index row | They agree with the front: the same four names and count if they show names at all. Tess and Home never disagree (S13). Proposed: the index row shows no names, so it cannot disagree |
| K58.19 | Offline, Claude off or on | The line is computed on the phone from the buy history. No Claude request from USUALLY HAVE or the Pantry (Core 7, 6.7). Nothing notifies, badges or turns red |
| K58.20 | Group order | USUALLY HAVE stays the last group below OUT and LOW and above Tess's band. When there is nothing out or low it is the only group (S11: hero "Nothing out"). When the only group is a long wrapping line the hero and the line never disagree |
| K58.21 | Copy sweep | "USUALLY HAVE", "and N more" with digits. Never "and two more", "+2", "…", "see all", "suggested", "recommended", "running low" |

---

## Assumptions and flags

**Assumptions taken (not ruled; Product to rule).**
1. Proposed copy, each marked in its row: Siri's lists "2 on your list: Call dentist, Pick up parcel." and its private forms (K52.4 to K52.7); the trip's VoiceOver hint "Puts it in the basket" (Groceries) or "Checks it off" (list), per G102; "Private item, taken back."; "Tacos is gone. I can't bring it back." (K54.11); the photo lines "Reading the photo…", "Photo, kept for later.", "I couldn't read that photo. Try it in better light, or paste the text.", "No text in that photo. Paste the text instead.", "The steps are missing. Paste them below.", "No recipe card there.", "Using the first 4."; "Private recipe saved.", "Private recipe. I won't send it to Claude."; "Rice, not now."; and the Pantry joiner forms in K58.
2. Ruled copy reused word for word: "Milk, on Groceries.", "Private item, on Groceries.", "Private note, kept.", "Private recipe, 7 pm." and its no-time forms, "Nothing planned.", "Recipe gone." with "Back to the list", "Cleared N from the basket.", "Didn't save. Try again.", and `RecipeLinkLine` (`found`, `claudeRead`, `noRecipe`, `paused` and the Claude failure lines).
3. UNDO windows: a new row 4 s, a change 10 s, 10 s with VoiceOver; one slot, last write wins. A trip strike is its own undo and claims no slot (K46.17).
4. There is no trip reveal (G102, Oct 17): a private row always reads "Private item" and one tap strikes it (K51).
5. The 4 AM day boundary applies to "dinner" (K53.12) and the quiet hours are unchanged.

**Flags.**
- **F1 (K51.3, K58.15). Several private rows at once.** **Resolved by G102 (Oct 17): there is no reveal, so no row is ever shown.** In Pantry USUALLY HAVE, a private name takes a slot as "Private item" while Groceries USUALLY never draws a mask (K44.8). The two ruled behaviors differ; Product to say whether the Pantry line should also hide privates entirely (then K58.15 and K58.16 change).
- **F2 (K53.5). The 4 pm cutoff.** "After 4 pm" is read as 4:00 pm or later. Product to say if 4:00 pm sharp is dinner.
- **F3 (K53.7). Two dinner-tagged slots.** The later one wins (proposed).
- **F4 (K53.9). A cook with no time** counts as dinner only when tagged. An untagged, untimed cook is "Nothing planned."
- **F5 (K54.7). One UNDO slot and a delete.** A later write replaces the delete's UNDO and the delete is final from that moment, which can cut the 10 s short. Product to say whether a delete keeps its own slot for the full 10 s.
- **F6 (K58.4). Three-name form.** S5 reads "Rice, coffee, eggs"; K58 reads "Rice, coffee and eggs". `pantry-acceptance.md` S5 and S6 and `kitchen-refill5-pantry-acceptance.md` K27.13 need the matching edit once ruled.
- **F7 (K58.9). "and N more" is not a control.** Product to say whether it should open the rest.
- **F8. Stale earlier rows.** K46.24 and flag F4 of REFILL 7 (a plain tap opens words, no re-mask), K45.13 and flag F2 (locked ordinary read), K45.17 and flag F3 (later cook), K47.6 and flag F5 (no restore after the window) are superseded by K51, K52, K53 and K54 once ruled. `pantry-light.md` rule 9 still says at most 3 names.
- **F9. Build targets.** Nothing on master reads a photo, masks a trip row on tap, scopes the locked Siri read by title, or deletes a recipe. K51, K52, K54 and K55 are targets for Core and Builder B; K54.10 fails on master (the page still says "This recipe is gone. Undo brings it back.").
