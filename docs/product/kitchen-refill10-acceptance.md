# Kitchen REFILL 10, Lane 1: acceptance rows K71 to K75 and K79

*Kitchen lead, 2026-10-17 (board `kitchen.md` line 62, "3:57 AM REFILL 10"; K71 to K75 are Lane 1, K79 is Lane 2 and is written here with them because it shares the recipe page). Docs only, no code. Format follows `kitchen-refill9-lane1-acceptance.md` (K61 to K65), `kitchen-refill8-acceptance.md` and `kitchen-refill7-acceptance.md`. Read and checked against: those files, `kitchen-gap-hunt-5.md` (G26 to G33), `kitchen-counts-vs-claude-acceptance.md` (KC), `kitchen-error-states-acceptance.md` (ER6, ER10, ER14), `kitchen-refill6-lane1-acceptance.md` (K36, aisle moves), `kitchen-copy-recheck-oct17.md`, `decisions.md` (B8, I-4, Q1, 5:51 PM Oct 16), `TesseraCore/Sources/TesseraCore/Export/TesseraBackup.swift` and `TesseraExport.swift` on master. "Fails today" was read from master's code, not run. Every copy line is either ruled (cited) or marked "proposed, Product to rule".*

**What master does today (read from code).**
- `TesseraBackup.write(from:to:)` copies the **whole database** with GRDB's backup API. There is no filter, so one copy kind exists; the iCloud copy and the local copies are the same bytes. Ruling 2 needs the iCloud copy to be written differently from the local ones. That is a build target (K72).
- `TesseraExport` writes every object's `title` and `values` in plain, and every `OpEntry.summary` and `ops` payload in plain. No mask exists. Ruling 6 is a build target (K74).
- `restore(into:)` takes an empty store and keeps ids. A restored export has no way to carry a word that was masked out. That is by design (K74).
- Nothing on master marks a recipe Private (G21), no Kitchen switch exists in Settings (G30, now ruled out), and `RecipeLinkReader` does not read the "Tess asks Claude" switch (G32). So K71, K72 (iCloud half), K73, K74 and K79 are **rows for a build to meet**. K75 fails on master only where the aisle drag itself is unbuilt (K36).

**Rulings used by every row (decisions 3:55 AM Oct 17, numbered as given).**
1. A recipe made Private by the title wall stays Private and cannot be switched off. A self-marked Private recipe can be switched off.
2. A private recipe stays **out of the iCloud copy** (B8) and **in local Backups**.
3. Clocks write "12 pm" (the other form is not used anywhere in this file). Lowercase ("7 pm", "7:30 pm").
4. Aisle-change receipt: "Chicken, moved to Dairy and eggs." Saves read "on <list>." ("Milk, on Groceries.").
5. "Tess asks Claude: no" covers the recipe-link read tap and shows the ER6 line.
6. The JSON export masks private words.
7. No Kitchen switch in Settings.
8. Copy "Private recipe, kept.", "Tacos, no longer private.", "Face ID needed to change a recipe." is OK.

**Standing rules.** Receipts name the thing first. No "at" before a time. Digits for counts. US English. A walled thing reads "Private item", "Private recipe", "Private note". UNDO windows: a new thing 4 s, a change to something that exists 10 s, 10 s with VoiceOver on every UNDO; the window pauses while the app is backgrounded or the phone is locked; one slot, last write wins; every UNDO has a line saying what it took back, thing first. Cobalt is Tess's voice only. Money and body facts never go to Claude. Quiet hours 23:00 to 07:00; the day starts at 4 AM. No row, fixture or log holds a Claude key or key-shaped text (tests build any fake with `ClaudeSection.fakeKey`). No row runs a live Claude call.

**Fixtures.**
- **Tacos**: a plain recipe, planned Thursday 7 pm.
- **Wifi code lasagna**: title trips the wall (a secret word). It is made Private by the wall.
- **Sunday stew**: a plain-titled recipe he marks Private himself (self-marked). Its name is never typed in an expected line; every row asserts its absence.
- **Passcode stew**: both at once (self-marked and a wall word in the title).
- **Groceries**: Chicken (Meat and seafood), Milk (Dairy and eggs), one walled row "Ozempic refill" (a Private item in Other), the stew's 3 share rows.
- **Test seams (proposed, no product change)**: `RecordingClaude` from the KC file (per call: job, body, time; empty list means zero calls), plus `StubPageFetcher` that counts fetches of the linked page itself and `StubFaceID` that returns success, cancel, failure or "not available". Flag F10.

---

## K71. Title-wall-locked Private versus self-marked Private

**Source rules.** Ruling 1 and ruling 8. This replaces K61.9, K61.10 and flag F1 of REFILL 9 where they differ (F1 is answered). Two ways a recipe reads Private, and they behave differently on the one switch row labelled **"Private recipe"**:
- **Wall-made.** The title trips the wall (secret word, money or body shape, PF4). The switch is on and locked. It cannot be switched off. The recipe stays Private (read below as **sticky**, flag F1).
- **Self-marked.** He turned the switch on. It can be turned off.

A recipe can be both; the wall wins and the switch is locked.

| # | Action | Expected |
|---|---|---|
| K71.1 | Open Tacos (plain, not marked) | Switch row "Private recipe", off, enabled. VoiceOver: "Private recipe, switch, off." No lock icon, no helper text, no cobalt |
| K71.2 | Turn it on (self-mark) | House spring (Reduce Motion: 150 ms crossfade). One `.light` haptic. Tess (cobalt) in the UNDO slot: "Private recipe, kept." UNDO 10 s (a change to something that exists; ruling 8). Every surface reads "Private recipe" on the next render (K32.16, K61.5) |
| K71.3 | Tap UNDO at 9 s | Switch returns to off; every surface reads "Tacos". UNDO line "Private recipe, taken back." (proposed, Product to rule; carried from K61.2). The slot closes |
| K71.4 | Wait 10 s after K71.2, no UNDO | The slot closes with no further line. The mark stands |
| K71.5 | VoiceOver on, repeat K71.2 | UNDO is 10 s (the same as a change), announced once as "Private recipe, kept. Undo." The slot pauses while the app is backgrounded or the phone is locked; unlocking inside the remaining time offers UNDO with the remaining seconds, not a fresh window |
| K71.6 | Turn the self-marked Tacos off, after the window | Allowed. Receipt "Tacos, no longer private." (ruling 8) with UNDO 10 s. UNDO line "Tacos, taken back." means the mark returns; proposed wording "Private recipe, kept." is not reused here because the thing is named first (proposed, Product to rule). Every surface returns to "Tacos" |
| K71.7 | Turn it off inside the first 10 s with no UNDO | Two changes in a row: the slot holds the second ("Tacos, no longer private."). The first window is final. One slot, last write wins |
| K71.8 | Open "Wifi code lasagna" (wall-made) | Switch is on and **locked**. Page title reads "Private recipe". VoiceOver: "Private recipe, switch, on, dimmed." No lock icon. Nothing offers to switch it off |
| K71.9 | Tap the locked switch; drag it; VoiceOver activate | Nothing happens: no haptic, no receipt, no UNDO, no error line, no Face ID prompt. The state never flips even for a frame |
| K71.10 | Open the recipe's other controls (scale, edit, delete, share) while wall-made | They work as for any recipe (subject to K79). Only the switch is locked. No control reveals the title |
| K71.11 | Type a new recipe titled "Wifi code lasagna" and Save | Saved as wall-made. Receipt "Private recipe saved." (proposed, Product to rule; carried from K43.20 and K61.17). UNDO 4 s for a recipe typed by hand (a new thing, ruling AQ15); 10 s for a recipe saved from a paste or photo (K43.2 rules that path, flag F2). UNDO line "Private recipe, taken back." and the recipe leaves |
| K71.12 | Rename plain Tacos to "Wifi code tacos" | On the next render the recipe reads "Private recipe", the switch shows on and **locked**, although the stored self-mark was off. This is a change: receipt "Private recipe, kept." with UNDO 10 s. UNDO restores the old title and the unlocked state |
| K71.13 | Rename the wall-made "Wifi code tacos" back to "Tacos" | **Sticky reading (flag F1):** it stays Private, the switch stays on and locked, the page title reads "Private recipe" and the title field still shows "Tacos" only to him on the edit form. There is no way to clear it from the page |
| K71.14 | A self-marked Sunday stew whose title is then renamed to trip the wall | Both flags are true; the wall wins; the switch locks. Renaming it clean again leaves it self-marked and the switch is **enabled** (it was his own mark), so he may switch it off. The wall-made flag stays recorded only if the wall was ever the reason (sticky) |
| K71.15 | A recipe that is already both (Passcode stew); open it | Switch on, locked. "Private recipe, switch, on, dimmed." Same as K71.8 |
| K71.16 | Cook, plan, widget, Siri, notifications for a wall-made recipe | Identical to a self-marked one: "Private recipe, 7 pm." on the widget, Siri and notifications (KW-W8); "Private recipe done." on Home. The reason a recipe is Private is never shown on any surface |
| K71.17 | Tess grammar: "make the lasagna public" on a wall-made recipe | Tess (cobalt): "That one stays private." (proposed, Product to rule). Nothing changes, no UNDO. For a self-marked recipe the same phrase reads K71.6 |
| K71.18 | Tess grammar: "make the stew private" on a recipe already Private | No second write, no receipt of a change. Tess: "Private recipe, kept." is **not** repeated; she says nothing new (proposed). No UNDO |
| K71.19 | Counts: Recipes page context | "38 recipes, 2 private" with both counted (KC rule: on-screen counts keep private things). Wall-made and self-marked count the same |
| K71.20 | Spotlight, area index, request log, sent log, ledger, notification payload, widget timeline, accessibility tree | None holds the title of either kind. Both read "Private recipe" (K61.5, K61.14) |
| K71.21 | A wall-made recipe is a link read or paste result ("Wifi code lasagna" from a page) | The ghost shows as "Private recipe" before Save; the switch on the ghost is already on and locked; ASK CLAUDE is never drawn (K43.21) |
| K71.22 | Copy sweep | "Private recipe", "Private recipe, kept.", "Tacos, no longer private.", "Private recipe, taken back.", "Private recipe saved.". No "hidden", "secret", "locked" in user text, no lock icon, no emoji, no "at" before a time. Cobalt only on Tess's lines. VoiceOver says "dimmed", not "locked" |

---

## K72. iCloud copy versus local Backups for private recipes

**Source rules.** Ruling 2, with B8 (private memories stay out of the iCloud copy), I-4 (restoring an iCloud copy keeps the phone's private rows, never wipes them) and the 5:51 PM Oct 16 ruling (a local copy holds everything). This **settles flag F3 of REFILL 9**: K61.23 put a private recipe in the iCloud copy; that is now wrong and K61.23 and K61.24 are replaced by this set. The local kinds: "Save a copy" and the "Before-restore" copies kept in `Documents/Backups`. The iCloud kind: the rolling daily copy written to the iCloud Drive folder he picked ("iCloud Drive/Tessera"). On master all kinds are the same whole-database copy (`TesseraBackup.write`), so the filter is a **build target**.

**What "out" means (proposed, Product to rule, flag F4).** The iCloud copy omits the private recipe's object, its ingredient and step rows, its plan tasks, its cook records, its notes, and every link to it. A plain grocery row that carries a share "for" the recipe stays, with the share dropped, so nothing dangles. Private items and private notes follow their own rulings (Q1 stands: a private note rides in his iCloud Drive copy) and are not changed here.

| # | Action | Expected |
|---|---|---|
| K72.1 | Mark Sunday stew Private; tap "Save a copy" in Backups | The local copy holds the stew **with its mark and its real name**. A copy holds everything (5:51 PM Oct 16). Nothing from it goes to Claude |
| K72.2 | Restore that local copy on a fresh install | The stew returns still Private and self-marked (switch on, enabled). It reads "Private recipe" on every surface at once. Its plan, cooks and share rows return. **Round trip keeps Private** |
| K72.3 | Restore a local copy holding the wall-made "Wifi code lasagna" | It returns Private, switch on and **locked** (K71.8), even if the build reads the title rule on open. Wall-made origin survives the round trip (sticky) |
| K72.4 | Let the daily copy run to the iCloud folder with the stew and the lasagna on the phone | The iCloud file holds neither recipe nor any of their rows. Open the file's tables (test seam) and search for both titles and an ingredient word: zero hits. Counts of other recipes are unchanged |
| K72.5 | Same moment, the local rolling copy and "Save a copy" | Both hold the stew and the lasagna. The two copies differ by exactly the private recipes' rows and nothing else (assert row-count difference per class) |
| K72.6 | Restore the iCloud copy on the same phone (the stew exists on the phone) | The phone's stew is **kept** (I-4: never wipes). The restore adds back anything older and removes nothing private. After it, the stew still reads "Private recipe" and its plan and cooks are intact. The confirm line is unchanged ("Replace everything with the copy from Tuesday 14 October?") |
| K72.7 | Restore the iCloud copy on a fresh install | The stew and the lasagna are **not there**; nothing half-built: no plan task, no share row, no dangling link. Recipes page counts exclude them ("36 recipes", no "private" part for them). One quiet line under the confirm: "Private recipes stay out of the iCloud copy." (proposed, Product to rule) |
| K72.8 | Backups side "WHAT'S IN ONE" | The existing ruled line says a copy holds private things. It must not be false for the iCloud kind: it names the difference once. Proposed, Product to rule: "A copy on this phone holds private things. The iCloud copy leaves private recipes out." Names no private recipe |
| K72.9 | Delete the stew (K54) and finalize, then make a local copy | Absent from the copy. The Private mark means nothing for a deleted recipe. A copy made inside the 10 s window holds neither the recipe nor its rows |
| K72.10 | Switch the stew off Private (self-marked), then run the iCloud copy | The stew **is** in the next iCloud copy with its real title. The previous day's iCloud copy, written while it was private, does not hold it. Copies are replaced by the rule for his 4 AM day, so day D's copy holds all of D as of its last write |
| K72.11 | Switch it on again after K72.10, then run the iCloud copy the same day | The same-day iCloud file is rewritten and no longer holds the stew. The file's name is unchanged ("Tessera-2026-10-17.tessera"). Nothing in the filename or Backups page names a recipe |
| K72.12 | Restore a copy made **before** the Private field existed (an older copy lacking the field) | Restore succeeds: no crash, no refusal (the newer-version refusal fires only for a copy newer than the build). The self-mark reads as **off** for every recipe in it (the older copy never had one). A recipe whose title trips the wall reads Private again on the first open after the restore, by the title rule (PF4, G28). Nothing half marked. A Before-restore copy of the phone is taken first and holds the marks |
| K72.13 | After K72.12, a recipe the phone had marked Private is not in the older local copy | Restoring replaces the whole store: it is gone from the phone's live data and **kept in the Before-restore copy** with its mark (G26 line: "That copy has 6 recipes. The 9 you have now are kept in Backups.", proposed, Product to rule). For an iCloud copy I-4 applies instead (K72.6) |
| K72.14 | Restore a copy from a newer build | Refused with the existing newer-version line; no partial write (B5, B6). Unchanged by this row |
| K72.15 | A copy where the stew's Private mark is present but its rows were filtered (corrupt hybrid, a test fixture) | Restore refuses to build a half recipe: the recipe is dropped whole and the log notes "damaged" only as the existing damaged line; no crash |
| K72.16 | Backup fixtures and every copy | None holds a Claude key or key-shaped text (decisions 8:33 PM and 9:53 PM Oct 15). The iCloud filter does not change that |
| K72.17 | Tess asks Claude "no" and "yes" while copies run | Copies never go to Claude. Zero calls on the stub either way |
| K72.18 | Copy sweep | New words (all proposed): "Private recipes stay out of the iCloud copy." and the side line in K72.8. no "hidden", no "secret", no emoji, no "at" before a time |

---

## K73. Recipe-link read tap with "Tess asks Claude: no"

**Source rules.** Ruling 5 and ER6. The switch (`missesGoToClaude`, shown "Tess asks Claude: yes/no" in Settings, Claude) now covers his own READ tap on a recipe link. This **resolves G32** (which left the reader off the switch) and **replaces the G32 proposed line** "Claude is off. Paste the text instead." with the ER6 line. Master ignores the switch for the reader today (`RecipeLinkReader` never reads it), so with "no" a tap still reaches Claude: **fails today**.

The line (ER6, ruled): **"Couldn't find a recipe on that page. Paste the text instead."** It appears in Tess's band on the paste screen, ink body 19 with Tess's cobalt, no UNDO, no haptic. The link stays in the box.

What "no network call" means here (flag F5): **zero calls to Claude** (the `RecordingClaude` list is empty and the sent log gains no row). Fetching the linked page itself is the on-phone reader, not Claude (K37.15, the deterministic parser), and is counted on `StubPageFetcher`, asserted separately. If Product means "no fetch of the page either", rows K73.2 and K73.3 change together.

| # | Action | Expected |
|---|---|---|
| K73.1 | Settings, Claude: "Tess asks Claude" set to no, a key present. Open the paste screen, paste a link to a page with **no recipe card** (no JSON-LD, no recognizable text), tap READ | Tess: "Couldn't find a recipe on that page. Paste the text instead." The link stays in the box. No ghost, no row, no ledger row, no sent-log row. `RecordingClaude` calls: 0. Page fetcher calls: at most 1 (the page itself) |
| K73.2 | Same switch, a link to a page **with** a recipe card (JSON-LD) | The on-phone reader paints the ghost recipe alone. No ER6 line, no cobalt warning. Calls to Claude: 0 (K37.15). The switch does not block the page fetch |
| K73.3 | Same switch, a link to a page the parser finds partial (10 ingredients, no steps) | The ghost holds what was read; the paywall-style line of ER7 may appear; ASK CLAUDE is **never drawn** while the switch is no (K43.17). Calls to Claude: 0 |
| K73.4 | Switch is no; wait 60 s on the paste screen; leave and return | Nothing is sent and nothing is queued at any point. The link is kept in the box only if it was typed there. Leaving the screen sends nothing |
| K73.5 | Switch is no and offline; paste a link and tap READ | Offline is not a state for on-phone work (ER12), but the fetch needs the connection: "Recipe link, kept for later." (ER1, ruled) and the link waits as one TessInbox item. When he is back online it reads **only on his tap** (no self-retry), and with the switch still no that tap ends as K73.1 or K73.2. Calls to Claude: 0 throughout |
| K73.6 | Switch is no and an inbox item exists from before; drain it by tapping | The tap reads on the phone and ends as K73.1 or K73.2. Nothing is sent to Claude. The item leaves the inbox once read or once ER6 is shown (the link stays in the box) |
| K73.7 | Flip the switch to yes, tap READ again on the K73.1 link | A Claude read may be offered by the existing rules (ASK CLAUDE appears once, K43.12) and goes only on his tap. The ER6 line leaves when the screen changes. The ledger gains a row only if he taps the ask |
| K73.8 | Flip the switch to no while a Claude read is in flight | The in-flight call is allowed to finish and is not cancelled; no new call starts. The next tap obeys the switch. Calls after the flip: 0 (proposed, Product to rule, flag F6) |
| K73.9 | Switch is no and no key | Same ER6 line. ER10 ("No Claude key yet.") is **not** shown, because no Claude-only ask is drawn (K43.17). One line, not two |
| K73.10 | Switch is no; a link whose page is a private recipe by title (a wall word) | The on-phone reader may paint the ghost; it reads "Private recipe" and ASK CLAUDE is never drawn (K43.21). If the parser finds nothing, the line is ER6 and never carries the title or the URL |
| K73.11 | Settings sheet words | The existing "Tess asks Claude: yes/no" line stands. A second one-line under the switch is **proposed, Product to rule**: "Tess asks Claude: no. Links and groceries stay on this phone." (carried from G32). Not asserted as copy until ruled |
| K73.12 | Receipts: Settings, Claude, receipts after K73.1 to K73.10 | Unchanged. If no call was ever made: "Nothing has gone to Claude yet." (existing). No "Recipe link" row (G31) |
| K73.13 | Dump logs after the run: request log, sent log, ledger, capture-miss log, crash text | None holds the URL, the page text or a recipe word. The capture-miss log is not written for a link (it is a grocery and capture log) |
| K73.14 | VoiceOver and AX3 | The ER6 line is read once as written, not repeated on re-render. At AX3 it wraps to at most 3 lines in Tess's band and never truncates. Reduce Motion: it replaces Tess's line by a 150 ms crossfade |
| K73.15 | Grocery miss while the switch is no (the twin from G32) | The row lands as typed (for example "oatmilk"), no receipt other than the normal "Oatmilk, on Groceries.", nothing sent. Unchanged and reused here |
| K73.16 | Copy sweep | The ER6 line is written with a straight apostrophe ("Couldn't") and the stop after "page" and after "instead". No "Claude is off." on this path, no "limit", no emoji |

---

## K74. JSON export masking for Kitchen data

**Source rules.** Ruling 6. This **answers G28's open half** ("keep the words or mask them") with mask, and makes the proposed screen line "This file has your words as you wrote them." wrong. Master writes titles, values and op-log text in plain (`TesseraExport.init(context:)`, `OpEntry.summary`, `ops`). The export stays the readable "take my data elsewhere" file and stays **lossless for everything that is not private**: ids, classes, fields, links and dates are kept, so a restore keeps its shape. Backups (`.tessera`) is the lossless copy for private things (K72).

**Mask (proposed, Product to rule, flag F7).** A private object's `title` and every text `values` entry become the object's label: "Private recipe", "Private item", "Private note". A recipe's step lines and ingredient lines become "Private recipe" and "Private item" respectively. A source link on a private recipe is blanked. Numbers that belong to a private thing (servings, minutes) are kept as plain numbers only when they are not a body or money fact; any body or money value is dropped entirely (money and body facts are the wall's own, K29, W1). The `isPrivate` flag itself is exported (it is a flag, not a word), so a restore knows the thing is Private.

| # | Action | Expected |
|---|---|---|
| K74.1 | Fixture: Sunday stew (self-marked), Wifi code lasagna (wall-made), "Ozempic refill" (Private item), one Private note, 2 plain recipes. Export JSON | The file is valid JSON in the existing format (`tessera-export`, version unchanged unless Core bumps it, flag F8). Search the whole file for "Sunday stew", "Wifi code", "Ozempic", every ingredient word and step word of the private recipes: **zero hits** |
| K74.2 | Look at the private recipe's entry | `title` "Private recipe". Its ingredient values read "Private item", its step values read "Private recipe", its note reads "Private note". Ids, `classID`, `parentID`, `sortIndex`, dates and links are kept |
| K74.3 | Counts are kept | Number of recipes, ingredient rows, steps, grocery rows, cooks and links in the export equals the number in the store. The Kitchen counts a reader would compute from the file equal the screen ("38 recipes, 2 private"; "20 to get"). Assert per class: unmasked count equals masked count |
| K74.4 | Public Kitchen data | Tacos and the plain rows export **exactly** as before this change (byte-identical entries). Nothing public is masked or reworded |
| K74.5 | The op log in the export | `summary` and `ops` payloads that name a private thing are masked the same way ("Added Private recipe", not "Added Sunday stew"). Old and new values inside `ops` for a private object are masked. Op counts, ids and timestamps are kept. An un-masked op would defeat K74.1, so this is its own assertion |
| K74.6 | The Claude section, keys, `restoredAt` | The export holds no Claude key and no key-shaped text, as before. The settings entry for "Tess asks Claude" is exported as its state only |
| K74.7 | Deleted private recipe (soft-deleted, `deletedAt` set) | Masked the same way; it is not exported in clear because it is deleted |
| K74.8 | A recipe switched off Private (self-marked, switched off before the export) | Exported in clear, as any plain recipe. A recipe switched **on** a moment before is masked: the export reads the mark at the moment of the export |
| K74.9 | A wall-made recipe renamed to a clean title (sticky, K71.13) | Still masked, because its wall mark is stored (sticky). Its stored clean title does not leak |
| K74.10 | Restore an export on a fresh install (empty store) | Restore succeeds. The stew returns as a recipe titled "Private recipe", still **Private** (the flag was exported), with its masked ingredient and step rows. The lasagna returns still wall-made and locked. The real words are **not** recoverable from the file, and nothing pretends they are. Counts match the pre-export screen |
| K74.11 | After K74.10, switch the self-marked stew off | Allowed (self-marked). The recipe then shows its stored title, which is "Private recipe". The receipt names the thing first, so it reads "Private recipe, no longer private." (the stored title; proposed, Product to rule, flag F9). No words come back from anywhere |
| K74.12 | After K74.10, open Grocery and the week | Walled rows read "Private item"; shares for the stew read as shares of a Private recipe. No dangling link. Plan tasks are titled "Private recipe" |
| K74.13 | Export screen line | The old proposed "This file has your words as you wrote them." is **dropped**. Proposed, Product to rule: "Private things are masked in this file. A Backups copy keeps them." The screen line contains no private word |
| K74.14 | Share sheet and file name | The file name is "Tessera-export-2026-10-17.json" or the existing name. It never carries a recipe or item word. The share sheet text carries no title |
| K74.15 | Restore a pre-change export (an older file with plain private words) | It restores as-is; the build does not mask on import. A recipe whose title trips the wall reads Private on first open (PF4). Nothing is refused for being unmasked |
| K74.16 | Export, then restore into a store that is not empty | Refused with the existing `storeNotEmpty` outcome; nothing changes. Unchanged |
| K74.17 | Zero Claude calls during export and restore | `RecordingClaude` list is empty either way. The export is never sent to Claude |
| K74.18 | Copy sweep | New words (proposed): K74.13's line. "Private recipe", "Private item", "Private note" are the only mask words. No "redacted", "hidden", "secret", "removed", no emoji |

---

## K75. Aisle-change receipt: "X, moved to <aisle>."

**Source rules.** Ruling 4. Builds on K36 (REFILL 6 Lane 1). K36.3 and K36.14 already say "Chicken, moved to Produce." for a row; this set fixes every path and the private form. Aisle names and walk order are ruled (`us-shop-acceptance.md` K7.1 to K7.3): Produce, Bakery, Dairy and eggs, Meat and seafood, Cans and jars, Pantry, Spices, Frozen, Household, Other. The receipt ends with the aisle name and a stop: **"Chicken, moved to Dairy and eggs."** (the "and" is part of the aisle name). A save reads **"on <list>."**: "Milk, on Groceries.". The aisle-title reorder receipt "Dairy and eggs, moved." (K36.7) is a different action and is unchanged. UNDO for an aisle change is 10 s (a change), UNDO line thing first: "Chicken, taken back."

Setup: Groceries with Produce (onion, cilantro), Dairy and eggs (milk), Meat and seafood (chicken), Cans and jars (tomatoes), Other ("Ozempic refill", a Private item).

| # | Action | Expected |
|---|---|---|
| K75.1 | Long-press Chicken and drag it into Dairy and eggs | The row lifts with a haptic, others make room in 320 ms, and it lands only inside an aisle. Tess (cobalt) in the UNDO slot: "Chicken, moved to Dairy and eggs." UNDO 10 s. The row now sits in Dairy and eggs. "Chicken" learns that aisle (K36.3) |
| K75.2 | Drag Chicken into Produce | "Chicken, moved to Produce." Single-word aisle, single stop |
| K75.3 | Tap UNDO inside 10 s | The row returns to its old aisle and position. Line "Chicken, taken back." The taught aisle is restored too (K36.4). The slot closes |
| K75.4 | Do nothing for 10 s | The slot closes with no line; the move stands (K36.5). VoiceOver on: announced once as "Chicken, moved to Dairy and eggs. Undo." |
| K75.5 | VoiceOver: focus a row, custom action "Move to aisle", pick Dairy and eggs | A picker in walk order. Choosing moves the row without dragging; high-priority announcement once: "Chicken, moved to Dairy and eggs." Focus does not move. UNDO stays reachable the flat 10 s, no pause while focus sits on it (K36.15) |
| K75.6 | Drop a row into the aisle it is already in | No change, no receipt, no UNDO, no haptic. (A reorder inside the aisle is not an aisle change) |
| K75.7 | Drop outside the list or on Tess's band | The drag cancels with a spring back (Reduce Motion: 150 ms crossfade). Nothing changes, no receipt (K36.10) |
| K75.8 | Row with a quantity and a share ("Chicken, 1 lb", for tacos) | The receipt names the item only: "Chicken, moved to Dairy and eggs." No quantity, no "for tacos" in the line. The row keeps both (K36.12) |
| K75.9 | Name with a stop or a long name ("Mac and cheese") | "Mac and cheese, moved to Pantry." One stop at the end; the name's own words are not altered. At AX3 the line wraps up to 3 lines and never truncates the aisle name |
| K75.10 | Drag the Private item "Ozempic refill" from Other to Pantry | The row reads "Private item" at 66% ink for the whole drag (K36.9). Receipt "Private item, moved to Pantry." (replaces K36.9's "Private item, moved." where the aisle is known). UNDO 10 s; UNDO line "Private item, taken back." The words appear in no receipt, label, VoiceOver string or Tess line |
| K75.11 | VoiceOver on the Private item | Reads "Private item, Other" on focus. "Move to aisle" picker works. Announcement "Private item, moved to Pantry." No item word spoken |
| K75.12 | A recipe-linked share row for a Private recipe, moved | The row's words read as themselves unless walled. The receipt names the **item**, never the recipe: "Onion, moved to Produce." or "Private item, moved to Produce." if the item is walled. No receipt says "for Private recipe" |
| K75.13 | Two moves within 10 s | The second claim replaces the first in the one slot (K36.11). The earlier UNDO is gone; the newest line is on screen. The earlier move stands |
| K75.14 | Move, then add "milk" within 10 s | "Milk, on Groceries." with UNDO 4 s (a new row) replaces the slot. The move stands and can no longer be undone from the slot |
| K75.15 | Teaching: after K75.1, add "chicken" again | It lands in Dairy and eggs (one move teaches the item). Receipt "Chicken, on Groceries." The starting guess for other items is unchanged. "Chicken thighs" is a new key and uses the starting guess (K36.5) |
| K75.16 | Siri: "move chicken to produce" | Not in the current grammar; the phrase takes the existing miss path and writes nothing (flag F11). If Product adds it, the spoken receipt is the same words, a locked phone asks Face ID like any write (K45.2), and a walled item reads "Private item, moved to Produce." |
| K75.17 | Tess grammar: "put the milk in frozen" | Proposed only, not ruled (flag F11). If built, the same receipt, "Milk, moved to Frozen." and UNDO 10 s |
| K75.18 | Widget and notifications | An aisle change is silent: no widget reload for its own sake, no notification, no badge. Home's "N to buy" count is unchanged by a move |
| K75.19 | Dump logs after a move of a Private item | The request log, sent log, ledger and capture-miss log hold no item word. Zero calls on `RecordingClaude`. The learned-aisle key for a walled item is stored on the phone only and never sent (K29) |
| K75.20 | Copy sweep | "X, moved to <aisle>." exactly: capital first letter of the thing, comma, "moved to", the aisle name as ruled, a stop. Not "Moved Chicken to Produce.", not "in <aisle>" (that is `kitchen-copy-recheck-oct17.md` item 1: the tap-USUALLY receipt "Milk, in Dairy and eggs." is its own open row), not "at". no emoji |

---

## K79. Face ID on recipe change rows

**Source rules.** Ruling 8 ("Face ID needed to change a recipe." is OK). The rule from K45.2 for a write on a locked phone: Face ID is asked like any write, and on failure or cancel **nothing is written**. This set extends it to the recipe page itself: edit, delete, mark Private and unmark Private. What counts as "locked" is flag F12: **proposed, Product to rule**, the app's own lock (Face ID on app open, if on) and a locked phone; with neither, no prompt appears. A read, scaling the view and cooking never ask (a read writes nothing). The prompt uses the system sheet; the reason string is "Change a recipe." (proposed).

Change rows are: edit (title, ingredients, steps, note, servings), delete, mark Private, unmark Private. UNDO afterwards does not ask Face ID again inside its own window (proposed, flag F13).

| # | Action | Expected |
|---|---|---|
| K79.1 | App unlocked (Face ID done at open, window open), edit Tacos' title | No prompt. The edit saves. Receipt as the existing recipe-edit line; UNDO 10 s (a change) |
| K79.2 | App locked (lock engaged or phone locked), tap Edit on Tacos | The system Face ID sheet appears. On success the edit form opens and the edit proceeds. On cancel: the form does not open; Tess (cobalt): "Face ID needed to change a recipe." in the UNDO slot (ruling 8), no UNDO, no haptic other than the system's. Nothing is written |
| K79.3 | Face ID fails twice | Same as cancel: the line "Face ID needed to change a recipe." and nothing written. The page stays readable; the recipe is unchanged. One `.warning` haptic only if his finger did not save (ER14 rule) |
| K79.4 | Delete Tacos while locked; Face ID succeeds | The recipe leaves the shelf with the existing delete flow (K54): "Tacos is gone." with UNDO 10 s (proposed wording kept from K54; the line reuses K54, not new) and nothing finalizes before the window ends. Face ID is asked **once**, before the delete, never again for UNDO |
| K79.5 | Delete while locked; Face ID cancelled | The recipe stays. "Face ID needed to change a recipe." No delete, no UNDO, no change in the plan or Groceries |
| K79.6 | Mark Sunday stew Private while locked; Face ID succeeds | The switch flips, "Private recipe, kept." with UNDO 10 s (K71.2). Face ID asked once |
| K79.7 | Mark Private while locked; Face ID cancelled | The switch **snaps back to off** (no half state), the line is "Face ID needed to change a recipe." Nothing stored, nothing re-indexed, every surface keeps the name |
| K79.8 | Unmark a self-marked recipe while locked; Face ID succeeds | "Tacos, no longer private." UNDO 10 s (ruling 8). The name returns on every surface on the next render. The Face ID prompt comes **before** the name is shown anywhere, so unmarking never reveals a name to a bystander when the prompt is cancelled |
| K79.9 | Unmark while locked; cancelled | The switch stays on. Line "Face ID needed to change a recipe." The name stays hidden everywhere |
| K79.10 | The wall-made recipe (locked switch) while locked | The switch is locked as K71.9: no prompt, no line, nothing. Face ID is asked only where a change can happen. The other change rows on that page (edit, delete) ask as K79.2 and K79.4 |
| K79.11 | No Face ID hardware, or Face ID not enrolled | Falls back to the **device passcode** sheet (the same system prompt, a policy that allows passcode). Success proceeds; cancel behaves as K79.2. The line on cancel is still "Face ID needed to change a recipe." (the same ruled copy; flag F14: it names Face ID on a phone without it) |
| K79.12 | No Face ID hardware **and** no passcode set | No lock exists, so the change proceeds with no prompt, as on an unlocked app (proposed, Product to rule). Nothing is refused for a missing lock. An iPhone-only app on a simulator without Face ID enrolled behaves as this row |
| K79.13 | Locked phone, Siri: "mark tacos private" | A write. Face ID is asked like any write (K45.2, K61.31). Success: Siri says "Private recipe, kept." Failure or cancel: nothing is written and Siri says "Face ID needed to change a recipe." (K61.31, proposed there, ruled here). Siri never speaks the name |
| K79.14 | Locked phone, Siri: "what's for dinner" | A read: no Face ID, no write. Unchanged (K61.30) |
| K79.15 | Tess grammar on a locked app: "delete the lasagna" | A write: the same prompt and the same copy on cancel. The wall-made recipe is deletable (only the Private switch is locked). Success: the delete flow with UNDO 10 s. Phrase is not logged in the miss log if it holds a wall word |
| K79.16 | Background the app during the prompt, return | The prompt is cancelled by the system. Treated as cancel: nothing written, line "Face ID needed to change a recipe." appears once on return. The UNDO slot, if any was open from before, is paused and then resumes with its remaining time |
| K79.17 | VoiceOver on | The prompt and the line are read once each. The line is announced as written, once, high priority. Focus returns to the control he tapped |
| K79.18 | Face ID succeeds and the save itself fails (ER14) | "Didn't save. Try again." ("Private recipe didn't save. Try again." when private) Ruled Oct 17 (4:35): a private "Didn't save" variant keeps the same form and prints only the kind (e.g. "Didn't save that. Private item."), never a private word.. The edit stays in the field. A retry does not ask Face ID again inside 30 s of the success (proposed, flag F13) |
| K79.19 | Request log, sent log, ledger after K79.1 to K79.18 | No row. Face ID results never leave the phone. Zero calls on `RecordingClaude`. No private word in any log |
| K79.20 | Copy sweep | The only new line: "Face ID needed to change a recipe." (ruled). With the other ruled lines, no "unlock", "authenticate", "biometric", "denied", "hidden". No emoji, no "at" before a time. It never carries the recipe name |

---

## Assumptions and flags

**Assumptions taken (not ruled; Product to rule).**
1. Proposed copy, each marked in its row: "Private recipe, taken back." (K71.3); "Private recipe saved." (K71.11); "That one stays private." (K71.17); "Private recipes stay out of the iCloud copy." and "A copy on this phone holds private things. The iCloud copy leaves private recipes out." (K72.7, K72.8); "Private things are masked in this file. A Backups copy keeps them." (K74.13, replaces G28's proposed "This file has your words as you wrote them."); "Private recipe, no longer private." (K74.11); "Private item, moved to <aisle>." and "Private item, taken back." (K75.10); "Change a recipe." as the Face ID reason (K79).
2. Ruled copy reused word for word: "Private recipe, kept.", "Tacos, no longer private.", "Face ID needed to change a recipe." (ruling 8); "Chicken, moved to Dairy and eggs." and "Milk, on Groceries." (ruling 4); the ER6 line "Couldn't find a recipe on that page. Paste the text instead."; "Recipe link, kept for later." (ER1); "Nothing has gone to Claude yet."; "Didn't save. Try again." (ER11, ER14). Clocks: "12 pm" is the house form and no row needs a clock.
3. The iCloud copy is the rolling daily copy in the folder he picked; "local Backups" is "Save a copy", the Before-restore copies and the local rolling copy. Master writes one whole-database kind only.
4. UNDO windows as stated; the wall-made mark is stored, so exports and copies carry it.
5. No Kitchen switch exists in Settings (ruling 7), so no row here toggles Kitchen. G30 is closed by that ruling and its proposed word "Kitchen: shown / hidden" is dropped.

**Flags.**
- **F1 (K71.13, K71.14). Sticky or live?** Ruling 1 says a wall-made recipe "stays Private." Read as **sticky** (the wall's mark is stored, so renaming it clean does not clear it). Cost: a typo in a title can lock a recipe Private for good, with no way out from the page. The other reading (live: the lock follows the title) is how K61.10 was written. Product to confirm. K74.9 and K72.3 depend on sticky.
- **F2 (K71.11). New-recipe window.** K43.2 rules 10 s for paste and photo saves, AQ15 rules 4 s for a new thing. K71.11 gives 4 s to a recipe typed by hand and 10 s to a pasted one. Product to confirm the split.
- **F3. K61.23 and K61.24 are replaced.** They put the private recipe in the iCloud copy. REFILL 9's F3 is answered by ruling 2. Both files need a matching edit; this file edits neither.
- **F4 (K72 source rules). What leaves with a private recipe.** The iCloud filter drops the recipe, its rows, plan tasks, cooks, notes and links, and keeps plain grocery rows with the share dropped. Q1 (a private note rides in iCloud) still stands and sits oddly beside B8 (private memories stay out). Core and Product to confirm which private things stay in the iCloud copy besides recipes.
- **F5 (K73). "No network call."** Read as zero calls to Claude; the page fetch is the on-phone reader and still runs. If Product means the fetch too, ER6 would show for every link and a recipe card page could not be read with the switch off. Product to say.
- **F6 (K73.8). Switch flipped in flight.** Proposed: the in-flight call finishes, no new one starts.
- **F7 (K74 source rules). The mask words and shape.** Labels per object, ingredient lines "Private item", source link blanked, body and money values dropped. Product and Core to rule, with the op-log payloads (K74.5) as the part most likely to be missed.
- **F8 (K74.1). Export version.** A masked export is the same format; Core to say whether `currentVersion` bumps. A restore of an old plain export must still work (K74.15).
- **F9 (K74.11). A restored masked recipe switched off Private** shows the title "Private recipe" and the receipt "Private recipe, no longer private." because no real name survives. Product to confirm that is acceptable, or to block switching off for a recipe restored from an export.
- **F10. Test seams.** `RecordingClaude` is from the KC file. `StubPageFetcher` and `StubFaceID` are proposed new seams; the real names may differ in the build.
- **F11 (K75.16, K75.17). Voice and Tess moves.** No grammar for moving a row between aisles exists on master. Rows are written if it is added; they are not a build request.
- **F12 (K79 source rules). What "locked" means.** The app lock and a locked phone are assumed. No app lock setting exists in this file's sources. Product to say which gate applies on an unlocked phone. If none, K79.1 to K79.9 apply only to the Siri and Tess paths on a locked phone.
- **F13 (K79 source rules, K79.18). UNDO and retry do not re-ask Face ID** inside their own window (proposed, with 30 s for a retry).
- **F14 (K79.11). The ruled line names Face ID** on a phone with no Face ID. Left as ruled; Product may want a passcode wording.
- **F15. Build targets.** Nothing in K71, K72 (iCloud half), K73, K74 or K79 exists on master. K75 depends on the K36 drag build. Do not read any "fails today" as a regression.
- **F16. Replaced and related rows.** K61.9, K61.10, K61.23, K61.24 (this file replaces them), K36.9 (the Private item receipt gains the aisle: "Private item, moved to <aisle>."), G28 (export line), G30 (closed by ruling 7), G32 (the proposed "Claude is off." line replaced by ER6).
