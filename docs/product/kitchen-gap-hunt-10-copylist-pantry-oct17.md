# Gap hunt 10 (static, read only)

Repo /home/user/Tessera at origin/master (47365b0). CopyList = PR #866 (merge dd3697a, fix commit 88e1395). No Swift toolchain, so nothing was run. Every claim has a file:line I read; "(inferred)" marks a reading I did not see executed. Fixtures made up. No Claude key printed or stored. Paths below are relative to /home/user/Tessera; `LR` = TesseraCore/Sources/TesseraCore/Lists/ListReuse.swift, `LRT` = TesseraCore/Tests/TesseraCoreTests/ListReuseTests.swift.

## 1. CopyList acceptance table (lists-acceptance.md section 4c, 13.x, decisions.md:446, starter-lists.md)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| 4c: new list, same sections and items | PASS (sections are per-item `section` values, so an empty named section cannot exist or copy; inferred) | LR:177-195 | aCopyHasTheSameItemsAllOpenAndTheOriginalStays (LRT:274) |
| 4c: items keep quantity and section, in order | PASS | LR:184-191 | same (LRT:274) |
| 4c: all open | PASS (isDone/checkedAt never copied, default false) | LR:184-195 | same asserts `!isDone`; checkedAt nil not asserted |
| 4c: in one op | PASS (one `apply`, inferred) | LR:161-197 | partial: comment says "One op" but only asserts undo removes the list (LRT:274) |
| 4c: original untouched | PASS | LR:162 reads only | same asserts item still done and count 2 |
| 4c: nothing in API or copy says "template" | PASS (inferred; the word is only in a code comment) | LR:128 | no test |
| 4d/G: Groceries cannot be copied, nor named Groceries | PASS | LR:169-171 | aTakenNameOpensThatList... (LRT:294) |
| Blank name refused | PASS | LR:166-168 | LRT:294 |
| Name already a list opens that list, nothing copied | PASS | LR:172-176, LR:220-223 | LRT:294 (receipt "Lisbon, already a list" after 88e1395) |
| Receipt "Lisbon, copied from Packing" (decisions.md:446) | PASS | LR:214-217 | LRT:274 |
| Reusable flag carries; #pick-one and "picked:" stamp do not | PASS | LR:153-160, LR:179-181 | flagsDoNotCopyExceptReusable (LRT:311) |
| Undo removes the copy | PASS | op log, inferred | LRT:274 (`engine.undo`) |
| 13.8: a private row still reads "Private item" in the copy | PASS (word rule, not a flag) | Lists.swift:307-312 | aPrivateRowStillReadsPrivateItemInTheCopy (LRT:332) |
| Private new name never in summary or receipt | PASS | LR:199-217 | aPrivateNameIsNeverInTheLine (LRT:344) |
| Private source name never in the receipt | PASS (sourceName uses shownName, LR:204-207) | LR:204 | no test (LRT:344 uses a public source) |
| Day log: "New list: Lisbon" | PASS for a public name | DayStory.swift:91, 319-325 | aCopiedListIsANewListLine (DayStoryTests.swift:287) |
| Day log: private list name masked | FAIL (G75) | DayStory.swift:322-324, 474-482 | no test |
| Name wall: key, secret value or money in the new name | FAIL (G77) | LR:161-177 | no test |
| Registered, decodes from a tool call | PASS | ActionRegistry.swift:20, 80 | no test (LRT:204 covers setListReusable and resetList only) |
| Hidden from Claude as a tool | PASS | LR:130 `isOfferedToModel: false` | no test |
| Phrase "copy packing for lisbon" (starter-lists.md:32, decisions.md:446) | NOT BUILT | TesseraRuntime.swift:73 says "lists slice 8"; no `copy` rule in TessGrammar*.swift (grep) | no test |
| Screen entry point (a Copy word on a list page) | NOT BUILT | grep of Features/ and App/ finds no `CopyList` | no test |
| Copy of a note's @links (`about` refs) and item date | NOT BUILT / NOT PROVABLE (only quantity, section, notes text copy; `about` is a refList, SystemCatalog.swift:275) | LR:187 | no test (G83) |
| Copy of a running list starts no run | PASS (inferred; process is a separate object) | LR:161-197 | no test |
| starter-lists.md: Gym bag, Leaving the house, Packing seeded, reusable, user-deletable, never reinstalled | NOT BUILT | grep `Gym bag`/`Leaving the house` in non-test Swift finds nothing | no test |
| 13.5/13.9 Lists side counts private items as a count | NOT PROVABLE here (out of the #866 diff) | n/a | n/a |

## 3. Running list and shelf copy audit (US English, lowercase clocks, the banned words, money only with amount, receipts thing-first with "on", HomeLines caps)

Read: Features/Lists/ListsCopy.swift, ListsShelf.swift, ListsView.swift literals (grep), Features/Home/NowPage.swift:520-600, HomeLines.swift:225-245, 295-345, 515-550, ListRuns.swift:1-30, ProcessTable.swift:140-160, Shopping/receipts in Lists.swift.

Strings found, all PASS the rules: "Packing, 6 left." / "nothing left." (ListsCopy.swift:107-110), "Packing, done. 3 left." (:112-115), "RUNNING, 9 LEFT" (:117-119, comma), "Packing has 9 left." (:121-125), "2 lists, 1 running" (:6-9), "Just Groceries" (ListsShelf.swift:75-76), "Packing, running" (ListsCopy.swift:104), Now ledger step "6 left" / "nothing left" (NowPage.swift:589), HomeLines "Packing: 6 left." / "Packing: paused, 3 left." / "Packing: all done." (HomeLines.swift:237-243), context = the name only when `fitsContext` (<= 6 words, <= 32 chars, HomeLines.swift:189-193, 342), detail "6 left." / "All done." (HomeLines.swift:396-398). No clock, "at" or money word in any of them. No "Archive" on screen (ListsView.swift:59).

Gaps: G78, G79, G80, G81, G82.

## 4. Wall paths for a copied private list or row

Facts: privacy in lists is by words, not a stored flag. `ListContents.shownName` (ListRuns.swift:19-21) and `AddListItem.shownTitle` (Lists.swift:309-312) decide at read time, so a copy of a medicine row stays private by itself (LRT:332) and a private source copied under a public name is simply public (correct under the word rule, but see Product ruling in G85). Paths checked:

| Path | Result | file:line |
|---|---|---|
| Copy receipt, summary | masked | LR:199-217 |
| Check / remove / move receipts on the copied row | masked | Lists.swift:309-312, 353-359 |
| Run line (Now step, ledger) | masked at write and at read | ListRuns.swift:10-21, NowPage.swift:583-589 |
| Home hero for a list fact | masked | HomeLines.swift:545-549 |
| Shelf row and Tess line | masked | ListsShelf.swift:95-98 |
| Process-table basket note | masked | ProcessTable.swift:156 |
| Day log "New list: <title>" | LEAK (G75) | DayStory.swift:322-324 |
| Week review rows, Tess memory turnover | LEAK by the same lines (G75, G76) | ReviewWeek.swift:147, 186; TessMemory+Turnover.swift:66-70 |
| New list name = key / secret / money | stored raw in title and op log (G77) | LR:177 |
| Copy phrase to Claude | whole phrase goes (G84) | TessModel.swift:95-102, architecture.md:47 |
| Spotlight, App Intents | none (copyList in-app only; no CSSearchableItem in repo) | TesseraRuntime.swift:73 |

## Gaps (G73 onward)

**G73. CopyList has no caller (important).** No grammar rule, no Tess line, no screen. `copyList` is "in-app only for now" with no in-app (TesseraRuntime.swift:73; grep of Features/ App/ TessGrammar*). Fix: add `copy <list> for <name>` to TessGrammar and a Copy word on the list page. Owner: Core engine (grammar), Builder B screen (word).

**G74. Three starter lists are not seeded (important).** starter-lists.md:1-32 vs no seed in Sources/. Also no rule for "never reinstalled once deleted". Fix: seed Gym bag, Leaving the house, Packing through the paste path then SetListReusable, with a seeded-once flag. Owner: Core engine; Product ruling on the seeded-once marker.

**G75. Day log names a private list (blocker, privacy).** `DayStory` prints `"\(lead) \(lookup.title(of: object))"` for createList and copyList (DayStory.swift:322-324); `title(of:)` masks only cooks and recipes (DayStory.swift:474-482). A list named "Lexapro refills" reads "New list: Lexapro refills" in the Day log and in the week review rows (ReviewWeek.swift:147, 186). Existing for createList, but #866 widened it and 88e1395 added the line without a private case. Fix: in `title(of:)` return `ListContents.shownName` for list-class objects; add a test "New list: Private list". Owner: Core engine.

**G76. Memory turnover filter lets a medicine name pass (important, privacy).** `recentLine` filters with `SecretWords` and `PrivateFacts.isWalled` only (TessMemory+Turnover.swift:66-70). `isBodyShaped` flags a medicine only when a number is present (PrivateFacts.swift:121-122), and `EngineWall.isHealth` (which also catches a bare medicine, EngineWall.swift:48-56) is not called. So "New list: Lexapro refills" survives into a memory line, and Home's pack takes memory lines (architecture.md:40). Fix: swap the guard for `ObjectPrivacy.isPrivateWord`. Owner: Core engine.

**G77. CopyList accepts any new name (blocker for key shape, important for secrets and money).** `apply` trims and checks emptiness and "groceries" only (LR:163-171); the title goes to the op log raw (LR:177). `ListsCopy.add` guards key-shaped text (ListsCopy.swift:~125) but CopyList and CreateList do not. A pasted key or "password is hunter2" becomes a list title; masking happens only at read (isPrivateWord), and the stored op keeps the words. Fix: refuse in `apply` when `looksLikeClaudeKey(name)`, `SecretWords.hasValue(name)` or `PrivateFacts.isMoneyShaped(name)` ("Private note, kept." route as 8b). Same for CreateList. Owner: Core engine; Product ruling whether a money-shaped list name is refused or stripped.

**G78. A running list has no hero on Now (important, inferred).** NowPage branch 1 requires `model.session` and the workout's own id (NowPage.swift:46-48); branch 2 reads `ledger.first`, and `ledger` holds suspended and waiting only, "the running process is shown as Now, not here" (ProcessTable.swift:53-60). No branch handles a running list, cook or shop process (`facts.fact(process:)` has just those two callers, NowPage.swift:47, 56). So lists-acceptance section 5 "Now's line reads Packing, 6 left" shows only after the run is suspended. Fix: add a branch `else if let process = model.processes.running()` before the rest/plan branches, rendering `HomeLines.line(for: facts.fact(process:))`. Owner: Builder B screen. Confirm on a phone (Phone only).

**G79. NowPicker takes the raw list title (low).** `runningItem` sets `title: store.displayTitle(of: subject)` (NowPicker.swift:63), unmasked for a list, and `nextStep: running.nextStep`, the stored string (NowPicker.swift:67). Today nothing renders it for a list (G78) but the first fix to G78 that reads `top.item.title` would leak. Fix: use `ListContents.shownName` when the subject is a list. Owner: Core engine.

**G80. Three separators for one fact (low).** "Packing: 6 left." (HomeLines.swift:243), "Packing, 6 left" (ListRuns.swift:13), "Packing has 6 left." (ListsCopy.swift:124). Cooks and shops share the colon form (HomeLines.swift:230-232), so it may be intended. Also a paused list with 0 left reads "Packing: all done." and drops "paused" (HomeLines.swift:238 guard runs before :239). Fix: reorder the guard; Product to confirm the colon. Owner: Product ruling; Core engine.

**G81. Doc and code disagree on the Lists context (low).** lists-acceptance.md 13.3 "2 lists, Packing running" vs ListsCopy.swift:6-9 "2 lists, 1 running" (marked Product Oct 17). The code is probably right (a name in the context could be private). Fix: update 13.3. Owner: Product ruling (doc).

**G82. Two wall predicates for list names (low, inferred).** Engine uses `ObjectPrivacy.isPrivateWord` with `BodyWeight.lastKg` (ObjectPrivacy.swift:86-90); the shelf and ledger use `isPrivateRecipeTitle` with a caller-passed `lastWeightKg` (ListsShelf.swift:95-98, NowPage.swift:586). Same word sets; they differ only on a bare-number weight name, and when the caller passes nil. Fix: one helper `ListContents.shownName(_:lastWeightKg:)`. Owner: Core engine.

**G83. Copy drops item links and date (low).** Only `quantity`, `section` and `notes` are copied (LR:187-195). `about` links are not, and notes text with `@Bench Press` becomes plain text unless `set("notes")` re-reads links (not verified, inferred). Item date is not in the catalog (SystemCatalog.swift:269-278), so acceptance 6 dated items has nowhere to copy. Fix: copy `about`; Product ruling that a copy never carries dates (a trip copy should not land on Today). Owner: Core engine; Product ruling.

**G84. Copy phrase goes whole to Claude, then fails (important).** Not a grammar rule, so "copy packing for lisbon" is a miss; the Oct 17 ruling lets a grammar miss go whole to Claude, medicine and money words included (TessModel.swift:90-102, architecture.md:47). `copyList` is not offered to the model (LR:130), so the phrase leaves the phone and nothing happens. With a private list name, e.g. "copy lexapro refills for lisbon" the name leaves. Fix: G73's grammar rule makes it a phone-only rule; until then offer a one-line miss. Owner: Core engine; Product ruling on whether list-verb misses may reach Claude.

**G85. A private list copied under a public name stays public (Product ruling).** Under the word rule that is correct for the name, and rows keep their own words. Product should confirm a copy of a list with any private row keeps no extra "private" mark. No code change needed if confirmed. Owner: Product ruling.

**G86. CopyList test gaps (low).** No test for: decode via `perform(named:)`, a private source name in the receipt, a key-shaped or secret name, one-op count (the op count), Day log with a private name, the running-list hero. Fix: add the six tests next to LRT:274-352. Owner: Core engine.

### Pantry v2 walked against Recipes (area 2)

Reality on master: there is no stored pantry state. `PantryLedger` is an app-side, read-only inference from shop clears and finished cooks (PantryLedger.swift:5-10, 100-135). The catalog's Ingredient has only `aisle` and `isStaple` (SystemCatalog.swift:280-284), no `state`, `lastBoughtAt` or `usualSkippedAt`. Pantry-acceptance P/W/Feeds lines (pantry-acceptance.md "Engine") are NOT BUILT: no "out of milk" rule (grep of TesseraTess finds none), no `RecipeMath.missing` (RecipeMath.swift has `scaled` only), no CAN COOK, no peek state words (RecipePage.swift:353-370 dims staples and to-taste only), no state-word cycle (PantryFront.swift:5, PantryView.swift:11).

**G87. Recipes never read the pantry (important).** `PantryLedger` is referenced only inside Features/Kitchen/Pantry*. `AddRecipeToGroceries` skips staples, to-taste, optional and "covered" lines, where covered means a checked row in the basket (Groceries.swift:453-462, 487-498). An ingredient the ledger calls "in" (bought last week) is added again. Spec: "planning a recipe skips lines whose ingredient is in" (pantry-acceptance.md Feeds; Core 4). Fix: after stored state lands, add an "in" cover rule beside `covered`. Owner: Core engine.

**G88. The ledger must move to Core before CAN COOK can exist (important).** `RecipeMath.missing`, `AddRecipeToGroceries` and the grammar live in TesseraCore, which cannot import Features/Kitchen (PantryLedger.swift:10 "the shape Core lifts into TesseraCore later"). Fix: lift the type and add `Ingredient.state` + `lastBoughtAt` fields; derived events then become the migration seed. Owner: Core engine.

**G89. What CAN COOK would claim vs what Recipes and Pantry read (important, design-time).**
1. Staples: Pantry never makes a staple low or out by cooking (PantryLedger.swift:149-153, 175-178) but does show a staple that a shop clear made "in" and would show a typed "out of salt" as OUT (entries filter has no staple test, :60-66). Spec W counts "non-staple lines" only, so CAN COOK would say "0 missing" for a recipe while Pantry lists salt OUT.
2. Optional and to-taste lines: Pantry and Groceries skip them (PantryLedger.swift:150, Groceries.swift:462); spec W is silent, so `missing` could name "1 missing: parsley" for an optional garnish.
3. Unknown counts as "to check" (spec W), and unknown is every ingredient on day one, so every recipe reads "N to check" and the ranking has no signal until a week of shop clears.
4. Private ingredient: Pantry's label is "Private item" (PantryLedger.swift:163-169); `missing` must use the same label or "1 missing: <medicine>" prints the word. A private recipe's CAN COOK order and count are visible on the shelf; the row must still read "Private recipe" (13.11).
5. Sources differ: Recipes reads recipe lines + `isStaple` + `AisleGuide.isStaple` (Groceries.swift:456-457); Pantry's `isStaple` is the same pair (PantryLedger.swift:176-178). Keep one helper so they cannot drift.
Fix: put staples, optional, to-taste and the private label into the one `missing` helper and test the five cases. Owner: Core engine; Product ruling on 2 and 3.

**G90. States stored state can reach that the screen never shows (low).** `have` and `unknown` never list on the front (PantryLedger.swift:60 drops unknown; S8 hides in). A stored "in" or "unknown" is visible only on the Ingredient page, so "out of milk" then "have milk" removes the line with no word on the front except the receipt. A stored state on a deleted ingredient is filtered (:60). A stored state on a private ingredient shows as a "Private item" line not tappable (PantryLedger.swift:163-169) yet counts in the hero ("4 out"). Fix: confirm in S-rows; add a "N private" count or leave as is. Owner: Product ruling.

**G91. Pantry copy promise not met (low).** S12 Tess line `Say "out of milk" and I'll keep it.` needs the phrase; PantryView.swift:96 knowingly skips it. Fix: ship with the phrase (G92) or drop the line. Owner: Builder B screen.

**G92. "Out of milk" parsing holes (important, inferred from the spec because no rule exists).** Listing what a rule must handle:
- Body and non-food phrases: "out of breath", "out of bed", "out of time", "out of range" (TessGrammar.swift:112 already uses it for kit range).
- Tense and shape: "ran out of milk", "milk is out", "milk's gone", "no more rice" (also "no more reps"), "we're out of eggs", "out of milk and eggs" (two things, one op), "out of oat milk", "out of 2% milk".
- Collisions: "have rice" vs "have a call at 3"; "got milk" vs the dated past note rule ("bought milk sat" is an ordinary note, PrivateFacts.swift:7-10).
- Walls: "out of lexapro" must be state + Groceries row as "Private item, on Groceries." (TessCaptureEngine.swift:243-246, 383-403 already do this for a plain add); "out of milk $4" strips the price (EngineWall.withoutPrice); a key-shaped tail refuses.
- Non-food: "out of chalk" belongs to a Gym bag list item, not an ingredient; an unknown name needs a decision (create an Ingredient? ask?).
- Already on Groceries: receipt "Milk, already on Groceries." with no UNDO (pantry-acceptance.md S10).
Fix: write the fixtures first (made-up phrases above), then the rule. Owner: Core engine; Product ruling on "got milk" and unknown names.

## Counts

20 gaps, G73-G92: 2 blocker (G75, G77), 9 important (G73, G74, G76, G78, G84, G87, G88, G89, G92), 9 low (G79, G80, G81, G82, G83, G85, G86, G90, G91). CopyList table: 25 rows; 16 PASS, 2 FAIL, 4 NOT BUILT, 1 NOT PROVABLE, 2 PASS-with-no-test notes.

## Still open

- Where the copy phrase and Copy word land (Lists slice 8, Builder B).
- The three starter lists and their seeded-once rule.
- Stored `Ingredient.state` / `lastBoughtAt`, the "out of milk" and "have rice" rules, `RecipeMath.missing`, CAN COOK, the peek state words, the "in" cover rule on recipe planning.
- Whether a list-verb grammar miss may reach Claude.
- Whether Now shows a running list as the hero (G78) and which separator it uses (G80).
- Architecture lists "the list names" as sent to Claude in Kitchen and Capture packs (architecture.md:46-47); the code I read (ClaudeTessModel.swift, TessModelCapture.swift) builds no list-name context yet. NOT PROVABLE that names are masked when it is built; require `ListContents.shownName` there.

## Phone only

- G78: whether a running list actually shows on Now with no workout (needs a run on the phone).
- Day log and week review showing "New list: Private list" after the G75 fix; VoiceOver reading of "Private item" and "Private list" on the copy; Dynamic Type AX3 on the shelf with a long copied name (wraps, never cut, 13.11 style).
- Copy under Reduce Motion, haptic on the Copy word, and the UNDO window (4 s for a new list).
- Seeing the three starter lists on first launch and after deleting one and relaunching.
