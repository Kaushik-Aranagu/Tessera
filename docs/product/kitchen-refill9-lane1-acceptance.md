# Kitchen REFILL 9, Lane 1: acceptance rows K61 to K65

*Kitchen lead, 2026-10-17 (board `kitchen.md` line 60, "3:27 AM REFILL 9", Lane 1). Docs only, no code. Format follows `kitchen-refill8-acceptance.md` (K51 to K58) and `kitchen-refill7-acceptance.md` (K43 to K47). Read and checked against: those two files, `kitchen-gap-hunt-4.md` (G19 to G25), `kitchen-refill6-lane2-acceptance.md`, `kitchen-refill5-acceptance.md` (K32), `kitchen-widget-wash-acceptance.md` (KW-W7, KW-W8, KW-W17), `meal-plan-groceries-acceptance.md`, `cook-mode-acceptance.md`, `decisions.md` (Backups and privacy rulings), `TesseraCore/Sources/TesseraCore/Home/HomeLines.swift` and `Format/HouseTime.swift`. Every copy line is either ruled (cited) or marked "proposed, Product to rule". "Fails today" was read from master's code, not run. Where an earlier row is replaced, the row says so.*

**Build targets.** Nothing on master marks a recipe Private (G21: `SystemCatalog` Recipe has no private field; the walls judge by title only), `NowPage` never calls `fact(plannedCook:recipe:)` or `fact(doneCook:)` (G19), there is no Kitchen widget (`Widgets/` holds only the rest Live Activity), and there is no Pantry or Groceries USUALLY HAVE code. So K61, the widget and Siri parts of K62 and K64, and K63 are **rows for a build to meet**, not checks of a shipped thing. K65 and the Home half of K62 fail on master today for the reasons given in their rows.

**Rulings used by every row.**
- Receipts name the thing first and use "on" ("Milk, on Groceries."). No "at" before a time (decisions 5:11 PM Oct 16, app-wide, Home included). Clocks are lowercase ("8:30 pm", `HouseTime.clock`). Digits for counts. US English and US units.
- A walled thing reads "Private item", "Private recipe" or "Private note". On the widget, in Siri and in a notification a private cook reads "Private recipe, 7 pm." (KW-W8, ruled Oct 17).
- On-screen counts keep private things with their names hidden; anything sent to Claude drops them. Money and body facts never go to Claude.
- UNDO windows (`UndoWindow`, decisions 12:45 PM Oct 16): a new thing 4 s, a change to something that exists 10 s, with VoiceOver on every UNDO 10 s. The window pauses while the app is backgrounded or the phone is locked. One slot, last write wins. Every UNDO has a line saying what it took back, thing first ("Milk, taken back."; a removal "Thing is back.", decisions 1:48 PM Oct 16).
- Quiet hours are 23:00 to 07:00 (a reminder is held to 07:00; a timer he started still rings). The day starts at 4 AM. Cobalt is Tess's voice only.
- No row runs a live Claude call (Claude is a stub in every test). No row, fixture or log holds a key or key-shaped text (tests build any fake with `ClaudeSection.fakeKey`).
- The clock is the app clock (`-demoTime`), simulator only.

**Fixtures.**
- **Tacos**: planned Thursday, 7 pm, 2 open rows still to buy. **Dal**: Friday, 6:30 pm.
- **Sunday secret stew**: a recipe he marks Private in K61, planned tonight, 7 pm, 2 open rows. Its name is never typed in an expected line; every row asserts its absence.
- **Plain fixtures for K64**: Tacos 7 pm, Dal at noon, Soup 5 pm, Chili 3:59 pm, Rice 4:00 pm, Beans 4:01 pm.

---

## K61. Mark a recipe Private: toggle, label, wall, undo, Backups, widget, Siri

**Source rules.** G21 ruled the seam as open: today the wall judges a recipe by its title words (`kitchen-week-one-private-filter.md` PF4), and no control marks one. This row set builds the control. The recipe page gets one switch row, label **"Private recipe"**, off by default, ink, no lock icon, no cobalt. Turning it on is a change to something that exists (10 s UNDO). A recipe whose title trips the walls (a secret word, money or a body shape) reads as Private with the switch **on and locked on**: it stays Private and cannot be switched off; a self-marked Private recipe can be switched off (ruled Oct 17 (decisions 3:55); flag F1). Everything K32 already rules for a private recipe (label, side, Tess, widget, Siri, Spotlight, notifications, Groceries masks, Claude) is reused here by number, not restated; this set adds the trigger and what the switch must do on every surface the moment it flips. **Backups follows the ruled copy-holds-everything line** (decisions 5:51 PM Oct 16: "the Backups copy holds everything, private notes, body weight and money included, because a restore must work"; 12:12 PM Oct 16 B8: private memories stay out of the iCloud copy; ruled Oct 17 (decisions 3:55): a private recipe stays out of the iCloud copy but is in local Backups). The mark is stored on the recipe, so a local copy carries it. Setup: Tacos, the stew, and a recipe "Dal" open on its page, Claude stub on.

### The switch

| # | Action | Expected |
|---|---|---|
| K61.1 | Open Tacos, look at the page | One row reads "Private recipe" with a switch, off. No lock icon, no helper text, no cobalt. VoiceOver: "Private recipe, switch, off." |
| K61.2 | Turn it on | The switch flips with the house spring (Reduce Motion: a 150 ms crossfade). One `.light` haptic. Tess (cobalt): "Private recipe, kept." with UNDO 10 s (a change; copy ruled Oct 17 (decisions 3:55)). UNDO line "Private recipe, taken back." (proposed). The page title, shelf row, Week row, Tess and index now read "Private recipe" on the next render (K32.16). The name is gone from every surface listed in K61.5 |
| K61.3 | Tap UNDO at 9 s | The switch returns to off; every surface reads "Tacos" again. UNDO line "Private recipe, taken back." The photo deleted by K32.16 and P4 does **not** return until a re-save from its link (K32.16) |
| K61.4 | Do nothing for 10 s | The UNDO leaves with no further line. VoiceOver on: 10 s, announced once as "Private recipe, kept. Undo." |
| K61.5 | After K61.2, search for every place the name could be: Tasks, Plan, Week, the day log, Home, Lists links, the widget timeline, notification payloads, Spotlight, the area index, Siri donations, the accessibility tree, the request log, the sent log, the ledger, the capture-miss log | None holds "Tacos". Every one that names the recipe says "Private recipe". The plan task's stored title reads "Private recipe" (G21, proposed) so Tasks and the day log never held the name after the flip |
| K61.6 | Turn it off after the window | Change to something that exists: "Tacos, shown." is **not** the line. The receipt names the thing first: "Tacos, no longer private." with UNDO 10 s (copy ruled Oct 17 (decisions 3:55); only a self-marked recipe can be switched off, K61.9). Every surface returns to "Tacos". Spotlight and the index take it back on the next index pass |
| K61.7 | Turn it on, then within 10 s add "milk" on Groceries | "Milk, on Groceries." with UNDO 4 s replaces the slot (last write wins); the Private mark stays and cannot be undone from the slot any more. The mark is a normal stored change |
| K61.8 | Tacos is planned and has Groceries rows "for tacos"; turn it on | Open rows keep their words unless walled. No grocery row says "for tacos" or "for Private recipe" (K46.25). A row that is walled reads "Private item" |

### Locked by the title wall

| # | Action | Expected |
|---|---|---|
| K61.9 | Open a recipe titled "Wifi code lasagna" (PF4) | The switch is on and locked (ruled Oct 17 (decisions 3:55): a title-wall Private recipe cannot be switched off). Tapping it does nothing and shows no error. Page title reads "Private recipe". VoiceOver: "Private recipe, switch, on, dimmed." |
| K61.10 | Rename Tacos to "Wifi code tacos" | The recipe reads "Private recipe" on the next render although the switch was off. The switch shows on and locked. Renaming back does not clear it: a recipe the title wall made Private stays Private (ruled Oct 17 (decisions 3:55); reading of the ruling, Product to confirm if rename-back should release it). A self-marked recipe keeps its switch and can be switched off |
| K61.11 | Cook the locked recipe: say "cook wifi code lasagna friday 7pm" | Receipt "Private recipe, Friday 7 pm." with UNDO 10 s (G21; the existing ruled grammar is "Cook X, Friday 7 pm" for plain ones; proposed, Product to rule). The task title is "Private recipe". The walled name is never spoken |

### Wall: the name never leaves

| # | Action | Expected |
|---|---|---|
| K61.12 | With the stew private, run every Kitchen job with a stub Claude recording (link ask, reader, grocery link ask, Tess pack) | Zero requests carry its name, text, steps, ingredient lines or notes (K32.15). A recipe-reading job for it makes zero requests. The tools that count (Week "N cooks", the recipes glance) still count it on screen; the request bodies drop it. Tess's pack lists "private recipe" nowhere |
| K61.13 | Open the stew's page and tell Tess "send this to Claude" or tap ASK CLAUDE on it | ASK CLAUDE is never drawn. Tess: "Private recipe. I won't send it to Claude." (reused from K43.21, proposed there) |
| K61.14 | Dump logs and caches after K61.1 to K61.13: request log, sent log, ledger, capture-miss log, notification payloads, widget timeline, Spotlight, area index, Siri donations, crash text | None holds the name. The ledger holds job, model, token counts, outcome and latency only. A phrase that tripped a wall is not written to the miss log |
| K61.15 | Spotlight and the area index | The private recipe is never indexed: a search for its name returns nothing; "Private recipe" returns nothing that opens it (K32.11). Making it private removes the existing entry; making it public again re-adds it on the next pass |
| K61.16 | On-screen counts | The Recipes class page context reads "38 recipes, 2 private" with the stew counted; its row reads "Private recipe" with its day; KEPT PRIVATE on the side lists "Private recipe", 2, nothing tappable behind it (K32.3). Counts keep private things; only what leaves the phone drops them (K68) |

### Undo slots

| # | Action | Expected |
|---|---|---|
| K61.17 | Mark a **new** recipe Private while saving it from a paste: tap Save with the switch on | A new thing: "Private recipe saved." with UNDO 4 s (a new row; proposed, Product to rule). K43.20 and K55.19 say 10 s for the photo path; the recipe save itself is a new thing and the paste save path rules it (K43.2, 10 s). **Conflict, flag F2**: the paste/photo save already rules 10 s; this row follows that path and keeps 10 s |
| K61.18 | Toggle an existing recipe | A change: 10 s (K61.2) |
| K61.19 | VoiceOver on, either case | UNDO 10 s, announced once. The slot pauses while the app is backgrounded or the phone is locked; unlocking inside the remaining time still offers UNDO with the remaining seconds, not a fresh window |
| K61.20 | Toggle, then toggle back before 10 s without UNDO | Two changes: the slot holds the second ("Tacos, no longer private." / "Private recipe, kept."). The first window is final |

### Backups (the copy holds everything; the iCloud copy follows its own rule)

| # | Action | Expected |
|---|---|---|
| K61.21 | Mark the stew Private, then "Save a copy" in Backups | The local copy holds the recipe **with its mark and its real name**, because a restore must work (decisions 5:51 PM Oct 16: "A copy holds everything, Private note, weight and money included."). Restoring it on a fresh install brings the recipe back still marked Private; it reads "Private recipe" on every surface at once. Nothing from the copy goes to Claude |
| K61.22 | Backups side "WHAT'S IN ONE" | It lists recipes. It says the copy holds private things (the existing ruled line). It does not name a single private recipe |
| K61.23 | The iCloud Drive copy | Private notes ride in it if the folder is his own (decisions Q1, Oct 16: "a private note rides in his iCloud Drive backup, since the folder is his"). **Flag F3, ruled Oct 17 (decisions 3:55)**: a private recipe stays OUT of the iCloud copy (B8) but IS in local Backups (K61.21). Expected: an iCloud copy made with the stew private holds no title, ingredient or step of it; I-4 applies, so a restore from that copy keeps the phone's private recipe. The row's earlier text (recipe rides in the iCloud copy) is replaced. K61.24 is unchanged |
| K61.24 | Restore an older copy taken before the mark | The recipe returns as the older copy had it (public). A restore never leaves a recipe half marked. A Before-restore copy is taken first, as for any restore, and holds the mark |
| K61.25 | Restore into a build with a newer catalog | Refused with the existing newer-version line; no partial write (decisions 12:12 PM Oct 16, B5/B6). Nothing here changes it |
| K61.26 | Backup fixtures and logs | No Claude key, and no key-shaped string, in the copy or in any row. The Claude key never rides in a copy (decisions 8:33 PM Oct 15 and 9:53 PM Oct 15) |
| K61.27 | A recipe that is **deleted** and finalized (K54) | Absent from every copy taken after the window; the Private mark means nothing for it. A copy taken inside the 10 s holds neither the recipe's shares nor its row after the delete |

### Widget and Siri

| # | Action | Expected |
|---|---|---|
| K61.28 | Medium widget, the stew planned 7 pm; then mark Tacos Private while it is next | Plain ground, no wash, no pigment, no title: "Private recipe, 7 pm." in light, dark, tinted and clear (KW-W8, K32.5). The widget reloads on the flip (KW-W11 means the wash seed stays for a recipe that is still public). With no time: "Private recipe, today." or "Private recipe, tonight." |
| K61.29 | Small and quiet widgets | Plain ground; small shows "Private recipe" and "7 pm" only (K32.6). The timeline and shared container hold no name, photo, ingredient or note (K32.7) |
| K61.30 | Siri: "what's for dinner" with the private recipe at 7 pm | "Private recipe, 7 pm." Never the name, an ingredient or a step; no "at" (K32.8). Locked phone: the same words, a read writes nothing and needs no Face ID, and nothing is drawn on the lock screen (K32.10, K52.2). "Private recipe" keeps its capital in a sentence; "a private item" is the lowercase form for items only (K52.14) |
| K61.31 | Siri: "mark tacos private" | A write: Face ID is asked like any write (K45.2). On success Siri says "Private recipe, kept." (proposed, Product to rule) and never repeats the name. On a Face ID failure: nothing is written and Siri says "Face ID needed to change a recipe." (proposed) |
| K61.32 | Tess grammar: "make the stew private" and "tacos private" | Same result as K61.2. "make it public" is the inverse and reads K61.6. A phrase that holds a wall word is not logged |
| K61.33 | Notification for Friday's cook | Title "Private recipe", body "7 pm"; no name. Inside quiet hours it is held to 07:00 (K32.12). A cook Live Activity shows "Private recipe" only |
| K61.34 | Copy sweep | New words: "Private recipe", "Private recipe, kept.", "Tacos, no longer private.", "Private recipe, taken back.", "Face ID needed to change a recipe.". No "hidden", "secret", "locked", "redacted"; no lock icon; no emoji; no "at" before a time; no cobalt except Tess's line. |

---

## K62. Home cook-line rows: planned, cooking, done, private, quiet hours

**Source rules.** G19 and G20. `fact(plannedCook:recipe:)` and `fact(doneCook:)` exist in `HomeLines.swift` but `NowPage` never calls them, so a planned cook shows as a plain timed task titled "Cook tacos" and a finished cook leaves Home. G20: `cookWhen` and the workout twins write `"\(title) at \(clock)"`, which breaks the no-"at" ruling. The house copy: **hero** "Tacos, 7 pm"; **row line** "Tacos, 7 pm, 2 to buy." (ruled; the no-time form "Tacos tonight, 2 to buy." is K53.14); **cooking** "Tacos, on step 2." (ruled) and, before step 1, "Tacos, cooking."; **done** "Tacos done." (private, "Private recipe done.", ruled). Home reads the one fact, so **Tess's line and Home never disagree** (K53.14). The widget and Siri quote Home. Half hours keep the clock: "Tacos, 7:30 pm". The GROCERIES key opens Groceries.

**HomeLines caps (`fitsContext`, `fitsDetail`).** The context slot is **at most 6 words and 32 characters with no stop** ("2 to buy", "nothing to buy", "8:10 pm"). The detail slot is **one sentence of at most 14 words and 80 characters with its stop**. A line that fails is refused, not cut. The row line and the hero are not in either slot; they are the fact's own words and are not capped, but they must not wrap past 2 lines at AX3.

### Planned

| # | Action | Expected |
|---|---|---|
| K62.1 | Monday: say "cook tacos thursday" (Thursday 7 pm, 2 rows to buy). Thursday 6 pm, open Home | Hero "Tacos, 7 pm". Row line "Tacos, 7 pm, 2 to buy." Context slot "2 to buy". GROCERIES key opens Groceries. Never "Cook tacos", never "Tacos at 7 pm" (G19, G20). Fails today: plain task "Cook tacos", no count, no key |
| K62.2 | Half hour: plan "cook tacos thursday 7:30pm" | "Tacos, 7:30 pm" and "Tacos, 7:30 pm, 2 to buy." |
| K62.3 | Plan with no time, Thursday evening (day part evening, shutdown or late) | "Tacos tonight, 2 to buy." Hero "Tacos tonight". Before the evening, "Tacos today, 2 to buy." (existing `cookWhen`) |
| K62.4 | Plan for tomorrow, opened tonight | "Tacos tomorrow, 2 to buy." Hero "Tacos tomorrow" (existing). With a time tomorrow, same line, the time not shown |
| K62.5 | Nothing left to buy (0 open rows) | "Tacos, 7 pm, nothing to buy." Context slot "nothing to buy" (14 characters, 3 words, fits). 1 row: "1 to buy" (digit) |
| K62.6 | Two cooks planned today (Tacos 7 pm, Dal 8 pm) | Home shows the nearest first; each line reads as above; neither line says "dinner" unless it is the dinner by K64 |
| K62.7 | Compare the same planned cook on the hero, the row, the index, Siri and the widget | Same words: "Tacos, 7 pm" / "Tacos, 7 pm, 2 to buy." / index "Tacos, 7 pm" / Siri "Tacos, 7 pm." / widget "Tacos, 7 pm" with "2 to buy" beside it. Tess's line and Home never disagree |
| K62.8 | Caps check on the planned cook's slots | Context "2 to buy" passes `fitsContext` (3 words, 8 characters, no stop). A detail sentence for a planned cook, if one is added, passes `fitsDetail`. Nothing is added unless it fits |
| K62.9 | The workout twin: plan Push A at 6 pm | "Push A, 6 pm" (proposed, Product to rule: the same rule, the same fix). Never "Push A at 6 pm". A paused set keeps its existing ruling; not changed here |

### Cooking

| # | Action | Expected |
|---|---|---|
| K62.10 | Hold start on the planned cook, before step 1 | Row line "Tacos, cooking." Hero "Tacos". The planned line is replaced in place (no second Tacos line) |
| K62.11 | Go to step 2 | "Tacos, on step 2." Hero "Tacos, step 2". Context slot, if one is shown, passes `fitsContext` |
| K62.12 | Pause the cook | Home reads the paused fact; the cook line is not "on step" and not "done". Existing paused ruling applies; no new copy here |
| K62.13 | Close the app and reopen mid-cook | Same line, same step. The cook is the same running object as the plan (KW30): one line, not two |
| K62.14 | Abandon: leave the cook open past the idle rule | The cook suspends under the existing rule; Home shows the plan again ("Tacos, 7 pm, 2 to buy." if still future, "Tacos tonight, 2 to buy." if its time passed) and not "done" |

### Done

| # | Action | Expected |
|---|---|---|
| K62.15 | Hold DONE at 8:10 pm | Row line "Tacos done." Hero "Tacos done". Context slot "8:10 pm" (`DayStoryClock.sentenceTime`; 2 words, fits). It stays until 4:00 am; at 3:59 am it is still there; at 4:00 am it leaves and Home has no Tacos line (G19) |
| K62.16 | Two cooks done today | Newest first by `cooksFinished`; each reads "<Name> done." with its own clock |
| K62.17 | Hold DONE at 12:40 am | It belongs to the day before by the 4 AM day. Home keeps it until 4:00 am that same night, then it leaves. Not "Tacos done yesterday" |
| K62.18 | Delete the recipe after a cook (K54) | The finished line keeps the short name from the cook log; tapping opens "Recipe gone." (K54.14) |

### Private

| # | Action | Expected |
|---|---|---|
| K62.19 | The stew planned tonight, 7 pm, opened at 6 pm | Hero "Private recipe, 7 pm". Row line "Private recipe, 7 pm, 2 to buy." (proposed, Product to rule: the count is shown on Home because Home is his own screen and the count is a number; the widget, Siri and notifications drop it and read "Private recipe, 7 pm.", ruled). The name is nowhere on the page, the accessibility tree or the Home index entry |
| K62.20 | Start the cook | "Private recipe, cooking." (proposed, Product to rule, G21). Then "Private recipe, on step 2." (proposed, G25) |
| K62.21 | Hold DONE | "Private recipe done." (ruled). Leaves at 4:00 am like any cook |
| K62.22 | No time, private | "Private recipe tonight, 2 to buy." / "Private recipe today, 2 to buy." (proposed; the ruled no-count forms for the widget and Siri are "Private recipe, tonight." / "Private recipe, today.") |
| K62.23 | The Groceries rows for the stew | Each reads as itself unless walled ("Private item"). The GROCERIES key on the Home row opens Groceries, never the recipe (the recipe is not named anywhere) |
| K62.24 | Home line, widget, Siri, and Tess's line for the stew | The same two words in common: "Private recipe". Where one surface adds the count (Home) and the others do not, that is the only difference. Tess never says its name or any ingredient |

### Quiet hours (23:00 to 07:00) and the 4 AM day

| # | Action | Expected |
|---|---|---|
| K62.25 | At 23:30, Home with Tacos done at 21:10 | "Tacos done." still shows. Quiet hours quiet notifications, not Home's text. Nothing on Home pulses, flares or sounds |
| K62.26 | A planned cook still open at 23:30 (Tacos, 7 pm, not started) | Day part late: "Tacos tonight, 2 to buy." is wrong for a timed plan; the timed form stays "Tacos, 7 pm, 2 to buy." until 4:00 am. Nothing marks it overdue (KW25: a missed plan rolls forward like any task) |
| K62.27 | A cook reminder due at 22:50 is delivered; one due at 23:10 | 22:50 is delivered. 23:10 is held to 07:00 with the same title ("Tacos", or "Private recipe") and body ("7 pm"). Home's text is unchanged either way |
| K62.28 | A kitchen timer he started at 22:50 that ends at 23:20 | It rings. A timer he started always rings in quiet hours (decisions: quiet hours do not mute what he started). The cook line stays "Tacos, on step 2." |
| K62.29 | Quiet hours and the private cook | Notification title "Private recipe", body "7 pm"; held to 07:00; Home's line equal to K62.19 |
| K62.30 | 3:59 am versus 4:00 am | At 3:59 am yesterday's cook is today's earlier day and Home keeps its done line. At 4:00 am a new day starts, the done line leaves, and a plan for the new day reads as in K62.1 |

### All lines

| # | Action | Expected |
|---|---|---|
| K62.31 | VoiceOver on each line | Reads exactly the row text with the stop. A private line reads "Private recipe, 7 pm, 2 to buy." |
| K62.32 | Copy sweep | No "at" before a time, no emoji, no "cook" verb in front of the name, lowercase clocks, digits for counts, no stop on the hero or context slot, one stop at the end of the row line. |

---

## K63. Groceries USUALLY HAVE: the Private item mask

**Source rules.** Decisions 3:25 AM Oct 17, #2 (ruled): a Private item is masked as **"Private item"** inside USUALLY HAVE, as on Pantry (K58.15, K27.19). This **fixes K44.8**, which said a walled item is never offered in USUALLY and that no mask word is drawn there; K44.8 is replaced by these rows. The name is never typed in an expected line. The Groceries line names up to 4 things, last in the aisle window and in the trip (K44.2); the Pantry line names up to 4 (K58). USUALLY never notifies, badges, shows on Home, turns red or asks Claude. Setup: milk (steady gap 7), eggs, oat milk, and **"Ozempic refill"** typed 4 times a week apart (walled; words never typed in an expected line), with the grocery history of `kitchen-refill7-acceptance.md`.

| # | Action | Expected |
|---|---|---|
| K63.1 | Day 43: open Groceries with the private item due | USUALLY (label at 55% ink) over "Milk, Private item" (two names). The private item takes a slot like any name. Its words, aisle and count appear nowhere |
| K63.2 | A private item is the only usual item | USUALLY over "Private item" alone. No comma, no "and" |
| K63.3 | Two private items among the usual | "Private item" appears twice and each takes a slot: "Milk, Private item and Private item". The 2 look identical, which is the point |
| K63.4 | 4 usual items, one private | All four named: "Milk, Private item, eggs and tea". Nothing says "and 0 more" (K58.5) |
| K63.5 | 5 usual items, the 5th is private | It is counted inside "and 1 more" like any name: "Milk, eggs, tea, oats and 1 more". The count never names it (K58.16). Digits; "and 1 more" at 55% ink; never "+1" |
| K63.6 | Tap "Private item" in USUALLY | It joins Groceries: "Private item, on Groceries." with UNDO 4 s (a new add; 10 s with VoiceOver). UNDO line "Private item, taken back." (proposed in K51.12, Product to rule). The new row lands masked; it is not auto-shown. The name leaves the line and the next takes its place |
| K63.7 | Left swipe on "Private item" | It skips until its next gap (`usualSkippedAt`). Tess: "Private item, not now." with UNDO 10 s (a change; proposed, Product to rule). UNDO line "Private item, taken back." The line refills to 4 names |
| K63.8 | Long-press "Private item" | No history line. It does not read "Bought 6 times in 8 weeks" (that would give a private count away). Nothing opens (flag F4: K44.8's "no long-press history" stands) |
| K63.9 | Editing the words so the wall no longer trips | It stops being masked on the next render. Old buys are **not** back-filled (K44.8 stands: editing the words clear of the wall does not back-fill old buys into USUALLY) |
| K63.10 | Trip mode (K51) | USUALLY in the trip is last. A private word is "Private item" there too; tapping it adds the row; tapping a masked **row** reveals per K51.2. The USUALLY name never reveals on tap |
| K63.11 | VoiceOver | "Usually. Milk, Private item, eggs, tea and 1 more." Each shown name is a button with hint "Adds to your list"; a masked name reads "Private item". UNDO 10 s |
| K63.12 | Pantry versus Groceries | The same private item is "Private item" in both lines. Order is the same most-overdue rank; the two lines never disagree on whether it is present. Home never shows USUALLY (K44) |
| K63.13 | What leaves the phone | USUALLY makes no Claude request. A stub records zero; the link ask (K39) never receives USUALLY words or `checkedAt`. A private item's buy history is in no pack (anything sent to Claude drops private things; K68) |
| K63.14 | Dump the sent log, ledger, widget timeline, notifications and Spotlight | None holds the item's words. No widget shows USUALLY at all |
| K63.15 | Copy sweep | "Private item" at the start of a name, never "a private item" on screen (that lowercase form is for Siri sentences only, K52.14); no "hidden", "locked", "redacted"; no lock icon; no cobalt; no "at" before a time |

---

## K64. The 4:00 pm boundary and "Dinner": DST and midnight

**Source rules.** Ruled: **4:00 pm itself is NOT after 4 pm** (replaces K53.5 and flag F2 of REFILL 8, which proposed 4:00 pm sharp as dinner). Dinner for a day is, in this order: (1) the slot tagged dinner on that day; (2) otherwise the **last** cook of that day that starts **after** 4 pm; (3) otherwise no dinner, and Siri says "Nothing planned." (K45.16, KW-W7). The day starts at 4 AM, so a 1 am cook counts for the day before. Time of day is the app clock. A cook with no time is not "after 4 pm" (K53.9, flag F4 there). A tagged slot is dinner at any hour. The rule is a plain function on the phone: no request, no ledger row. Copy: "Tacos, 7 pm." in Siri and the widget; "Tacos tonight, 2 to buy." on Home (K53.14). Clocks come from `HouseTime.clock`, so noon reads "12 pm" (ruled Oct 17 (decisions 3:55); flag F5). Setup: the plain fixtures above, `-demoTime` set per row, US Pacific.

### The boundary

| # | Action | Expected |
|---|---|---|
| K64.1 | Today: only Chili at 3:59 pm, nothing tagged. "What's for dinner" | "Nothing planned." Chili is not dinner |
| K64.2 | Only Rice at 4:00 pm sharp, nothing tagged | "Nothing planned." 4:00 pm itself is not after 4 pm (ruled; replaces K53.5). Home does not name Rice under a dinner word |
| K64.3 | Only Beans at 4:01 pm | "Beans, 4:01 pm." The first minute that counts is 4:01 pm |
| K64.4 | Soup 5 pm and Tacos 7 pm, nothing tagged | The last after 4 pm: "Tacos, 7 pm." |
| K64.5 | Rice 4:00 pm and Soup 5 pm | "Soup, 5 pm." Rice is not a candidate. Move Rice to 4:01 pm and it is still before Soup: "Soup, 5 pm." (the last wins) |
| K64.6 | Rice at 4:00 pm tagged dinner | The tag wins at any hour: "Rice, 4 pm." |
| K64.7 | Two cooks tagged dinner (Tacos 6 pm, Dal 8 pm) | The later tagged one, "Dal, 8 pm." (proposed, F3 of REFILL 8) |
| K64.8 | Move a cook from 3:59 pm to 4:00 pm, then to 4:01 pm, with the widget on | After each move the next read follows the new state; no cached old answer; the widget reloads (KW-W10). 3:59 pm and 4:00 pm: "Nothing planned"; 4:01 pm: it appears |
| K64.9 | A tagged dinner that is already cooked | Skipped; the next open dinner by this order is read; none: "Nothing planned." (K53.10) |
| K64.10 | The stew at 4:00 pm untagged | Not dinner: "Nothing planned." At 4:01 pm: "Private recipe, 4:01 pm." The tag never reveals the name (K53.8) |

### Midnight and the 4 AM day

| # | Action | Expected |
|---|---|---|
| K64.11 | 1:00 am Friday (still Thursday by the 4 AM day), Tacos planned Thursday 7 pm: "What's for dinner" | "Tacos, 7 pm." for Thursday's day. Not "tomorrow". Between midnight and 4 AM "today" is the earlier day |
| K64.12 | 1:00 am Friday: "What's for dinner Friday" | Friday's dinner by the order, e.g. "Dal, 6:30 pm." Not Thursday's |
| K64.13 | A cook planned at 12:30 am Friday | It belongs to Thursday's day (before 4 AM). It is not Friday's dinner and it is not "after 4 pm" Thursday either unless tagged or it is after 4 pm of that day. At 12:30 am it is not dinner. Home shows it as a timed plan |
| K64.14 | 3:59 am versus 4:00 am Friday | At 3:59 am Thursday's dinner is still today's. At 4:00 am the day rolls: Thursday's plan is not today's dinner any more; Friday's is |
| K64.15 | A cook finished at 11:55 pm Thursday and a cook finished at 1:30 am Friday | Both file on Thursday (the 4 AM day). "What's for dinner" at 2 am: both are done and skipped; "Nothing planned." |
| K64.16 | Month edge (G23): a cook finished 1:30 am on Nov 1 | It counts in October (his day): "Overnight oats, second time this month." (G23 proposed). A finish at 4:10 am Nov 1 starts November. The dinner rule uses the same day |

### DST

| # | Action | Expected |
|---|---|---|
| K64.17 | Spring forward (US, 2:00 am becomes 3:00 am), Sunday March 8: Tacos 7 pm planned. At 1:59 am, 3:00 am and 3:59 pm ask "What's for dinner" | "Tacos, 7 pm." each time. The day is 23 hours long; 4 AM and 4 pm are fixed clock times, so the cutoff is still 4:00 pm wall clock. No double-count, no skipped read |
| K64.18 | Spring forward day, Beans planned 4:01 pm | Counts as after 4 pm. Rice at 4:00 pm does not. Nothing shifts by an hour because the clock jumped before noon |
| K64.19 | Fall back (US, 2:00 am returns to 1:00 am), Sunday November 1 (2026): Tacos planned 7 pm. Ask at 1:30 am (first), 1:30 am (second), 3:59 am and 4:00 am | At 1:30 am both times the day is still Saturday's: "Tacos, 7 pm." for Saturday's day. At 4:00 am Sunday the day rolls. The day is 25 hours long; the rule never reads the same 1:30 am as two different days |
| K64.20 | A cook planned for 1:30 am on fall-back night | It exists once and belongs to Saturday's day. Its clock reads "1:30 am" (one line, not two); the second 1:30 am does not restart it or mark it done twice |
| K64.21 | The day, a cook and a reminder across the change | A reminder set for 7 pm fires at 7 pm wall clock on both DST days. Quiet hours (23:00 to 07:00) are wall clock too: on the 25-hour night they last 8 real hours, on the 23-hour night 6 |
| K64.22 | Travel: the phone's zone changes between planning and asking | The plan is read in the phone's current zone; no row stores an offset the read ignores. "7 pm" stays the clock the plan was set for (KW22: wherever he is, the 4 AM boundary of the phone's zone) |
| K64.23 | Widget, Siri and Home across DST and midnight | All three name the same recipe and time; none says "at"; none says "dinner" when there is none ("Nothing planned." or "Nothing planned" on the widget, KW-W7). Tess and Home never disagree |
| K64.24 | Copy sweep | "Nothing planned." exactly, with the period. No "no meals", "free night", "nothing for dinner", "Nothing planned tomorrow." Lowercase clocks, digits, no "at" before a time |

---

## K65. Timers up to 24 h: the cap, its line, and no silent no-op

**Source rules.** `StartKitchenTimer` refuses a length of 0 or over 24 h (1,440 minutes). Today the grammar (`parseTimer`) accepts any number and unit and the engine answers with "Didn't save that. A timer needs a length." for a timer he did give a length (G22); and a recipe step of "48 hours" is offered as a timer (G9). **Ruled line: "Timers run up to 24 h."** The cap itself is unchanged (a longer cap, G9's 72 h alternative, would move every row below together). A refusal makes no timer, no ghost row, no UNDO, no haptic and no change to the step, the resume point or the other running timers; it is never a silent no-op and never writes to the capture-miss log (it was a grammar hit, not a miss). The existing length line for 0 stays as it is. Tess's reply is in the UNDO slot at her band, cobalt, body size, replacing her last line. Setup: a cook open on step 2 with one timer running ("Roast"), Claude stub.

| # | Action | Expected |
|---|---|---|
| K65.1 | Say "timer bread 1500" (1,500 minutes, 25 h) | No timer. Tess: "Timers run up to 24 h." No ghost row, no UNDO, no haptic. "Roast" keeps running; the step, the resume point and the Live Activity are unchanged |
| K65.2 | Say "timer rise 25 hours" | Same: "Timers run up to 24 h." No timer, no write |
| K65.3 | Say "timer rise 48 hours" and "timer rise 2 days" | Same line. "2 days" is 48 h and is refused (proposed, Product to rule that "days" is parsed at all; if the grammar does not read it, the phrase is not a timer and takes the existing miss path, flag F6) |
| K65.4 | Say "timer rise 24 hours" | Works: the timer starts. Label "Rise", reads "Rise, 24 h." in the stack and the Lock Screen Live Activity. The notification is scheduled 24 h on. Receipt follows the existing timer receipt (not restated here) |
| K65.5 | Say "timer rise 1440" (minutes) | Works (exactly 24 h). Same as K65.4 |
| K65.6 | Say "timer rise 24 hours 1 minute" and "timer rise 1441" | Refused with "Timers run up to 24 h." 24 h 1 min is one minute over the cap. No timer, no write |
| K65.7 | Say "timer eggs 0" | The existing length line: "A timer needs a length." with no "Didn't save that." (G22). Not "Timers run up to 24 h." Nothing written |
| K65.8 | Say "timer eggs" with no length | The existing grammar answer for a missing length; not the cap line. Nothing written |
| K65.9 | A step that says "Cure the salmon in the fridge for 48 hours." | The step shows "48 hours" as plain ink text with no timer key and no timer word. Tapping the step does nothing: no haptic, no error, nothing red, no cap line (G9: the UI stops offering a timer the engine refuses). The step finishes by hand with Next. The recipe clock is unchanged. **This is a different case from K65.1**: a spoken timer he asks for is answered with the cap line; a timer that was never offered is not |
| K65.10 | A step that says "rest 24 hours" | Offered as a timer; works at exactly 24 h as K65.4 |
| K65.11 | A step that says "overnight" or "12 to 24 hours" | "12 to 24 hours" counts the lower bound, 12 h, so it is offered (cook-mode ruling 2). "Overnight" has no number and is plain text |
| K65.12 | Say "5 more minutes" on a held step when the extension would pass 24 h in total | The existing stretch runs per step and restarts its own timer under the same id; if the new end would be more than 24 h from its start, it is refused with "Timers run up to 24 h." and the step is unchanged |
| K65.13 | Refusal while two other timers run | The two timers keep their ends and notifications. The cap line replaces nothing but Tess's last line. UNDO slot unchanged if one was showing (a refusal claims no slot) |
| K65.14 | VoiceOver | The cap line is read once, as written. Focus does not move. Reduce Motion: the line appears by a 150 ms crossfade |
| K65.15 | Dump logs after K65.1 to K65.14 | No capture-miss entry, no ledger row, no request. The sent log holds nothing. The scheduled-notification list holds exactly the allowed timers |
| K65.16 | Locked phone and Siri: "start a 25 hour timer" | A write: Face ID is asked like any write (K45.2). After it, Siri says "Timers run up to 24 h." and starts nothing. On a Face ID failure nothing is written |
| K65.17 | Private cook (the stew) | The cap line is the same words; it never carries the recipe name. A timer label for a private cook shows "Step 3" or the verb, never the name (K32) |
| K65.18 | Copy sweep | "Timers run up to 24 h." with the capital T, the digit, the space before "h" and the stop. No "limit", "maximum", "too long", "Didn't save that." with it. Digits for counts. No emoji |

---

## Assumptions and flags

**Assumptions taken (not ruled; Product to rule).**
1. Proposed copy, each marked in its row: "Private recipe, kept." and its UNDO line "Private recipe, taken back." (K61.2); "Tacos, no longer private." (K61.6); "Face ID needed to change a recipe." (K61.31), where "Private recipe, kept.", "Tacos, no longer private." and "Face ID needed to change a recipe." are ruled Oct 17 (decisions 3:55); Home's private row line "Private recipe, 7 pm, 2 to buy." and the no-time forms (K62.19, K62.22); "Private recipe, cooking." and "Private recipe, on step 2." (K62.20, G21, G25); "Private item, not now." (K63.7); "Push A, 6 pm" (K62.9); the Home count shown for a private cook; and the plan task's stored title "Private recipe" (G21).
2. Ruled copy reused word for word: "Tacos, 7 pm, 2 to buy.", "Tacos, on step 2.", "Private recipe, 7 pm.", "Private recipe done.", "Private recipe, today." and "Private recipe, tonight.", "Nothing planned.", "Milk, on Groceries.", "Private item, on Groceries.", "Timers run up to 24 h.", "Recipe gone." with "Back to the list", "Private recipe. I won't send it to Claude." (reused from K43.21).
3. UNDO windows: a new row 4 s, a change 10 s, 10 s with VoiceOver; one slot, last write wins.
4. Backups: the copy holds everything and the mark is stored with the recipe, so a restore brings it back marked.
5. The 4 AM day and the 23:00 to 07:00 quiet hours are unchanged; DST is read as wall clock.

**Flags.**
- **F1 (K61.9, K61.10). Locked-on switch.** A recipe whose title trips the wall reads Private with the switch on and locked. Ruled Oct 17 (decisions 3:55): a title-wall recipe stays Private and cannot be switched off; a self-marked one can.
- **F2 (K61.17). New recipe window.** K43.2 and K55.19 rule 10 s for a recipe save from paste or photo; K61.17 first said 4 s for a new thing. Kept at 10 s to match the save path. Product to confirm.
- **F3 (K61.23). iCloud copy.** Decisions 12:12 PM Oct 16 B8 keep private memories out of the iCloud copy; decisions Q1 and 5:51 PM Oct 16 put private notes and "everything" in a copy his own folder holds. A private recipe is treated as part of "everything". Ruled Oct 17 (decisions 3:55): a private recipe stays out of the iCloud copy (B8) and is in local Backups; the phone's is kept on restore, as I-4 does.
- **F4 (K63.8). Long-press on a masked name.** No history line. Product to confirm.
- **F5 (K64.6). Noon.** `HouseTime.clock` writes "12 pm" for noon; K53.6 and the board wording said "noon". Ruled Oct 17 (decisions 3:55): clocks write "12 pm", never "noon"; K53.6 and K45.17 are edited to match. The 4:00 pm rows use "4 pm" and "4:01 pm" so they are unaffected.
- **F6 (K65.3). Days in a timer phrase.** "timer rise 2 days" is not in the current grammar; if unparsed it takes the miss path rather than the cap line.
- **F7. Replaced rows.** K44.8 (a walled item is never offered in USUALLY and no mask word is drawn) is replaced by K63. K53.5 and flag F2 of REFILL 8 (4:00 pm sharp is dinner) are replaced by the ruling in K64. Both files need a matching edit once this lands; this file edits neither.
- **F8. Build targets.** No recipe-Private switch, no Kitchen widget, no Pantry or USUALLY HAVE code, and no Siri read exist on master. K62.1, K62.15, K62.19 to K62.21, K65.1 and K65.2 fail on master today (the Home calls are unwired and the engine cap line is the generic length line).
- **F9. Edge:** K62.22 and K62.26 assume `DayPart` maps hours 0 to 3 to the earlier night; Core to confirm before the Home build.
