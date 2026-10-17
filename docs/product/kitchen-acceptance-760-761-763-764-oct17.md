# Kitchen acceptance of #760, #761, #763 and #764: static read

**Superseded in part (added by the Kitchen lead).** After this read, #766 (79c5ecb, "Groceries Add line through the wall") landed: walled lines stay in the draft with their line, no UNDO, never a silent clear. Every finding below that says the Groceries Add line has no wall, no spoken line, no UNDO behaviour or no A4 tests, or that a block paste clears the whole draft (W5), describes ce8b940 and is to be re-read against #766 in the next acceptance. The Core wall, Lists, "Recipe gone." and plate-label findings are unaffected.

*Kitchen helper, Oct 17. Read-only against origin/master (ce8b940). Nothing was built or run: no Swift toolchain here, so "pass-by-read" means the code and the test's assertions agree on paper, not that the test is green. Merge commits: #761 d70f50c, #760 77e25ed, #763 b06d2d9, #764 ce8b940. Paths are repo-relative; line numbers are from origin/master. No key-shaped string is quoted anywhere below.*

Verdict words: PASS (built, evidence), FAIL (built but wrong), NOT BUILT, NOT PROVABLE (needs the phone, or tokens not traced).

---

## 1. #763 Core's Groceries wall (`AddGroceries.apply`)

What changed: `Groceries.swift:474-485` runs every line through `AddGroceries.kept` (`:500-503`, which calls `AddListItem.kept`) before parsing; `summary` and `receipt` use the kept lines only (`:505-525`). `AddListItem.kept` (`Lists/Lists.swift:153-166`) now refuses a key-shaped line first, treats a cooking measure as not money ("1.25 cups flour"), and adds `isSumOnly` (`:169-179`) so "$40 at costco" (strips to "at costco") is a sum. `EngineWall.withoutPrice` (`Tess/EngineWall.swift:71-76`) strips a trailing bare two-place decimal. The Bar's `.groceries` branch says the kept lines (`TessCaptureEngine.swift:357-375`).

Tests that exist: `TesseraCore/Tests/TesseraCoreTests/GroceriesWallTests.swift`: `priceComesOffAndTheThingStays` (3 arguments), `numbersThatAreAmountsStay` (4), `aWalledLineNeverLandsAsARow` (6), `privateItemRowShowsPrivateItem`, `mixedBatchKeepsTheCleanLinesOnly`, `theWallIsOnTheActionNotTheCaller`, `withoutPriceTakesABareTwoPlaceDecimal`.

### A1 (spec table, Core tests)

| Spec test / clause | Verdict | Evidence | Covering test |
|---|---|---|---|
| `priceComesOffAndTheThingStays` ("milk $4" gives row "milk", receipt "Milk, on Groceries") | PASS | `Groceries.swift:479` (kept), `EngineWall.swift:72`; receipt `:515-525` | `priceComesOffAndTheThingStays` (same name) |
| `priceWordsComeOff` ("eggs 3 dollars") | PASS | `EngineWall.swift:73` | `priceComesOffAndTheThingStays` argument 2 |
| `bareDecimalPriceComesOff` ("milk 4.99", A0 gap 1) | PASS | `EngineWall.swift:75` regex `\s+\d+[.,]\d{2}\s*$` | argument 3 and `withoutPriceTakesABareTwoPlaceDecimal` |
| `numbersThatAreAmountsStay`: "2 lb chicken", "14 oz can tomatoes", "6 eggs" | PASS | none of the strip regexes match; not money-shaped (`PrivateFacts.swift:36-52`) | `numbersThatAreAmountsStay` |
| same, "2 for 1 crackers" | NOT PROVABLE | By read it survives (no sign, no word, no two-place decimal), but the test swapped it for "1.25 cups flour" | no test for this input |
| same, "amount kept on the share" (assert `GroceryShare.amount`/`unit`) | NOT BUILT (as a test) | The test only asserts `rows().count == 1` (`GroceriesWallTests.swift` line for `numbersThatAreAmountsStay`) | weaker than the spec |
| same, "1.5 kg rice" (one place keeps its number) | PASS by read | `withoutPrice` asserted for it | `withoutPriceTakesABareTwoPlaceDecimal` |
| `sumOnlyNeverLandsAsARow` ("$40 at costco", "rent 2100 fri", "$40") throws `invalidArguments`, nothing written | PASS | `isSumOnly` `Lists.swift:169-179` (the A0 gap 2 fix, on `given` not on the string); `apply` throws "nothing to add" `Groceries.swift:487-489` | `aWalledLineNeverLandsAsARow` (asserts throws, `rows().isEmpty`, `engine.history().isEmpty`) |
| `secretWithAValueNeverLandsAsARow` ("wifi password is tacocat12", "reset the garage code 4471") | PASS | `SecretWords.isSecretListLine(given)` in `kept` `Lists.swift:162` | same test |
| `claudeKeyNeverLandsAsARow` (key built at run time) | PASS | `Lists.swift:154` first guard; fixture built from parts (`GroceriesWallTests.swift` `keyLine`) | same test. The spec's extra `looksLikeClaudeKey(keyLine)` self-check is not asserted, but a non-key fixture would fail the throws check anyway |
| `privateItemRowShowsPrivateItem` ("lexapro": row stored in his words, receipt "Private item, on Groceries") | PASS | `shown(_:in:)` `Groceries.swift:493-496`; receipt `:512-525` | `privateItemRowShowsPrivateItem` (asserts `rows() == ["lexapro"]` and both strings) |
| `mixedBatchKeepsTheCleanLinesOnly` (receipt "Milk and eggs, on Groceries", no word of the walled line) | PASS | `receipt` uses kept lines only `:513-525` | `mixedBatchKeepsTheCleanLinesOnly` (also undo empties the rows) |
| `wallIsOnTheActionNotTheCaller` (action, `addToList` tool and Bar give the same row) | PASS | wall is inside `apply`; Bar test drives `capture("buy milk 4.99")` | `theWallIsOnTheActionNotTheCaller` (renamed with "the") |
| Common assertion: no "$", "4.99", "tacocat", key in summary or receipt | PASS | `everythingShown()` helper | `priceComesOffAndTheThingStays`, `mixedBatchKeepsTheCleanLinesOnly` |
| Common assertion: UNDO after a kept line returns the store to before (object count) | PASS (partly) | `engine.undo(record)` then `rows().isEmpty` in the mixed test | object/op-count equality not asserted |
| W6: no create op and no soft-deleted object carries the walled text | PASS | `engine.history().isEmpty` after the throw | `aWalledLineNeverLandsAsARow`; soft-deleted objects are not scanned |
| Receipt strings carry a full stop ("Milk, on Groceries.") | PASS (by layer) | Core receipts have no stop (`record.receipt == "Milk, on Groceries"` is what the test pins); the Bar adds it (`TessCaptureEngine.swift:375`); the Add line adds none (see W1) | n/a |
| Risk to watch (not in the spec) | NOT PROVABLE | A measure with a two-place decimal and a unit not in the `measured` list (`Lists.swift:157-160` lists cups, spoons, g, ml, l, oz; "never kg or lb") reads as money by `isMoneyShaped` (`PrivateFacts.swift:51`): "1.25 lb chicken" would be walled and not written. Not tested either way | no test |

### A2 (Bar path)

| Spec test | Verdict | Evidence | Covering test |
|---|---|---|---|
| `barBuyMilkWithPrice` ("buy milk $4" gives "Milk, on Groceries.") | PASS by read | grammar `TessGrammar+Kitchen.swift:68-76` keeps the raw line, action strips, Bar says kept lines `TessCaptureEngine.swift:358-375` | none for "$4" on the Bar; the 4.99 case is the only Bar run |
| `barBuyMilkBareDecimal` ("buy milk 4.99") row "milk", line has no "4.99" | PASS | same | `theWallIsOnTheActionNotTheCaller` (asserts the row and `!bar.line.contains("4.99")`; does not assert the exact line "Milk, on Groceries.") |
| `barBareMilkPrice` (bare "milk $4" lands "milk", RULED C1) | NOT BUILT | No bare-price rule in the grammar: no buy verb or comma gives nil (`TessGrammar+Kitchen.swift:49-52,68-76`); `EngineWall.withoutPrice` has no grammar caller (grep: callers are `Lists.swift:155` and `EngineWall.swift:81` only) | no test |
| `barSumOnlyIsNotARow` ("$40 at costco", "rent 2100 fri": miss line, no note) | PASS by read (unchanged) | sum branch `TessGrammar.swift:122-135`; bare gets no past verb so no note | no new test |
| `barPastTenseSumIsAPrivateNote` | PASS by read (unchanged) | `TessCaptureEngine.swift:324-332` | no new test |
| `barSecretIsRefusedBeforeAnything` | PASS by read (unchanged) | `parseSecret` first `TessGrammar.swift:73-75`, `:504-528`; line `TessCaptureEngine.swift:332` | no new test |
| `barKeyIsRefused` (exact key line, no miss-log entry) | PASS by read | `TessRouter.run` refuses first (`TessModel.swift:85`, `keyLine == claudeKeyLine` `:76`); miss log guarded `TessCaptureEngine.swift:59` | `ClaudeKeyTests.swift:159,239` (older tests, not a "buy" phrase) |
| `barPrivateItem` ("buy lexapro": "Private item, on Groceries.") | PASS by read | `TessCaptureEngine.swift:372-374` | no Bar test; the action half is `privateItemRowShowsPrivateItem` |
| `barAlreadyOnStillWorks` ("Milk, already on Groceries.") | PASS by read | `:360-370` still sees a `.create` op | older tests (KitchenGaps2 and others call it); none added here |

### A3 and A4 (Add line, app side)

| Clause | Verdict | Evidence |
|---|---|---|
| W1 Add line: "milk $4" gives row "milk" | PASS | Add line calls `AddGroceries` (`Features/Groceries/GroceriesView.swift:224`), now walled |
| W1 Add line receipt "Milk, on Groceries." with UNDO | NOT BUILT | `add()` `:220-229` speaks nothing at all: no `TessVoice` line, no UNDO |
| W2 sum-only: nothing written | PASS | action throws, nothing written |
| W2 / A3 wording "That stays on this phone." and W3 "That one stays out of Groceries." and the key line on the Add line | NOT BUILT | `add()` is `guard (try? ...) != nil else { return }` (`:224`): silent, draft stays. Nothing is told to him |
| W3 secret: nothing written | PASS | as above |
| W5 block, per line: clean lines land, walled line stays in the field | FAIL | `:224-227` clears the whole draft on any success, so the walled line is lost, not kept. Combined receipt ("Tacos, 9 added. 1 private note, kept.") also not built (spec says out of scope) |
| W6 UNDO after a kept line | NOT BUILT on the Add line (no UNDO offered); PASS in Core (`engine.undo`) | |
| A4 `GroceriesAddLineTests` (extract `GroceriesCopy.submit`) | NOT BUILT | no such file or outcome enum |
| A4 `privateRecipeIngredientNeverNamesTheRecipe` | NOT BUILT | not in this PR |

---

## 2. #760 first Lists slice (shelf, list page, Add line, fold, UNDO)

Files: `Features/Lists/ListsView.swift` (new, 333 lines), `ListsShelf.swift`, `ListsCopy.swift`, door in `Features/Home/HomeSpatialView.swift` (`case lists`, Kitchen page `ForEach([.groceries, .lists, .pantry, .recipes])`). Tests: `TesseraTests/ListsShelfTests.swift` (6: `stateWords`, `theNewestTouchedTakesTheHeroAndTheNextTwoTheTitle`, `aWalledListNameReadsPrivateList`, `addingToAnOlderListMakesItTheHero`, `theAddReceiptIsTheEnginesAndNeverEchoesAWalledLine`, `aPrivateListNameIsMaskedInTheReceiptAndAnEmptyPageSaysSo`), `ListsCopyTests.swift` (5 incl. new `theAddReceiptNamesTheThingFirst`). No view test exists; every View clause is pass-by-read.

### Shelf (rows 9.x, 13.1, 13.3, 13.4)

| Row | Verdict | Evidence | Test |
|---|---|---|---|
| 9.1 back word "‹ KITCHEN" | PASS | `ListsView.swift:31` `BackWord(title: "Kitchen")` | no test |
| 9.1 "LISTS" in labels | PASS | `:33-36` Title role | no test |
| 9.1 context "6 lists, packing running" | NOT BUILT (running part); the count PASS | `ListsShelf.swift:86-87`, `ListsCopy.swift:7-10`. The text of the row is stale against Product's Oct 17 ruling ("2 lists, 1 running") and no caller passes `running:` | `ListsCopyTests` (formatter only) |
| 9.2 sizes by last touched (56, two at 34, rest 21 at 75%) | PASS | `ListsShelf.swift:82` tiers; `touched` counts items too `:92-94`; 75% `ListsView.swift:80`; point sizes NOT PROVABLE (tokens `.hero/.title/.body`) | `theNewestTouchedTakesTheHero...`, `addingToAnOlderListMakesItTheHero` |
| 9.2 running list first and largest; two runs, newer first | NOT BUILT | no run state in the slice | none |
| 9.3 "3 OF 7", "EMPTY" | PASS | `ListsShelf.swift:97-105` | `stateWords` |
| 9.3 "14 TO BUY" under Groceries | PASS with a wording drift | built "14 TO GET" / "NOTHING TO GET" (`:99`); the row text in `lists-screens-acceptance.md` still says TO BUY, sheet 87 and AI-12 say "to get". Fix the row, not the code | `stateWords` |
| 9.3 "RUNNING, 9 LEFT", "REUSABLE", "PICK ONE" | NOT BUILT | `ListsCopy.runState` (`:35-37`) exists and is tested but has no caller | `theStateWordUsesAComma` (formatter) |
| 9.4 names settle with a stagger | PASS by read | `.entrance(2 + min(index, 4))` `ListsView.swift:47`; timing NOT PROVABLE | none |
| 9.5 paste makes a ghost list | NOT BUILT | | none |
| 9.6 Groceries once, opens Groceries | PASS | `ListsShelf.swift:73-77`, `ListsView.swift:90-93` `openLink(.groceries)` | none |
| 9.6 "Put away" word at the foot | NOT BUILT | no put-away field | none |
| 9.7 door "Lists" under Groceries on the Kitchen page | PASS | `HomeSpatialView.swift` diff (`ForEach([.groceries, .lists, .pantry, .recipes]`) | none (no `HomeLink` test touched) |
| 9.7 "PACKING, 9 LEFT" label, 0.94 to 1 zoom over 420 ms; "lists" in the ghost row opens the shelf | NOT BUILT / NOT PROVABLE | not in the diff | none |
| 13.1 empty shelf: "Just Groceries", Groceries at 56 "NOTHING TO GET", "No other lists yet." | PASS | `ListsShelf.swift:86`, `:99`; `ListsView.swift:51-56` | `stateWords` (state word only) |
| 13.1 Tess `Say "new list: packing" and I'll start it.` | NOT BUILT | no Tess slot on the shelf | none |
| 13.3 one other list: "2 lists" with Packing at 56 and Groceries at 34 | PASS | tiers by touch, not by "Packing at 56": the newer one is the hero | `theNewestTouched...` |
| 13.3 Tess "Packing has 9 left."; long-shelf fade into Tess's band | NOT BUILT | `ListsCopy.tess` has no caller | `tessSaysWhatsLeft` (formatter) |
| 13.4 state word comma form | PASS (formatter only) | `ListsCopy.swift:35-37` | `theStateWordUsesAComma` |

### List page, Add line, fold, UNDO (rows 10.x, 13.x as built)

| Row | Verdict | Evidence | Test |
|---|---|---|---|
| 10.1 context line above the hero | PASS | `ListsView.swift:126-135` (context, then hero) | `aPrivateListNameIsMasked...` covers `pageContext` |
| 10.1 option words labels line under the hero | NOT BUILT | | none |
| 10.2 rows 48 pt, amounts at 600, sections as margin words, no checkboxes or separators | PASS (x 64 and sizes NOT PROVABLE) | `:209` min 48, `:204` semibold amount, `:142-147` section title, `:151` indent 42 | none |
| 10.3 tap strikes, sinks, fold counts up | PASS (strike), NOT PROVABLE (sink, Tick haptic) | `StrikeRenderer` `:208`, `CheckListItem` after 420 ms (150 under Reduce Motion) `:216-225`; fold `.numericText` `:293`; no `sensoryFeedback` in the file | none |
| 10.4 tap fold shows done items and a tap takes one back; hold 0.7 s clears | PASS | `:270-288`, `:296-297` | none |
| 10.4 reusable "4 done. Hold to reset." and the un-paint | NOT BUILT | | none |
| 10.5 to 10.7 option words, paging, run seam | NOT BUILT | | none |
| 10.8 Add line: "Rice, on Packing." with UNDO 4 s | PASS | engine receipt `Lists.swift:206-215`, `ListsCopy.spoken` adds the stop `:19-22`, `TessVoice.say(..., undo:, holds: .seconds(4))` `ListsView.swift:263-264`; under VoiceOver `TessVoice.hold` forces 10 s (`HomeQueue.swift:45-52`) | `theAddReceiptIsTheEnginesAndNeverEchoesAWalledLine` ("Rice, on Packing.") |
| 10.8 several items: "Passport and adapter, on Packing." | NOT BUILT | one field, one `AddListItem` (`:251-265`); no comma split | none |
| 10.8 bare phrase on a list page goes to that list (G6) from the Bar | NOT BUILT | Add line only | none |
| Add line wall on Lists: price off, medicine "Private item", money-only or secret becomes a private note, never an item (13.10) | PASS | `AddListItem.apply` `Lists.swift:119-125`; spoken as "Private note, kept." with UNDO 4 s | same test (asserts no "$", "1200", "hunter2", no "on Packing" for the secret) |
| Add line failure line "Didn't save that. Try again." | PASS, with a flaw | `:255-258` says it, but `draft = ""` is cleared first (`:253`) so his text is lost on failure. Groceries keeps its draft (`GroceriesView.swift:223`); Lists does not. A pasted key throws in `CreateNote` (`Notes.swift:111`), so it says "Didn't save that." rather than the key line | none |
| 10.9 swipe remove, 13.6 | NOT BUILT | no `RemoveListItem` use | none |
| 10.10 remove by phrase | NOT BUILT | | none |
| 10.11 clear done carries 10 s UNDO | PASS | `clear` `:307-313` passes `undo: record` with no `holds`, so `hold(undo: true)` is 10 s; "3 done, cleared." `ListsCopy.swift:30-32` | `theAddReceiptNamesTheThingFirst` (asserts the string only) |
| 10.11 "done" ask, RESET, put away | NOT BUILT | | none |
| 10.12 back word "‹ LISTS", empty page "nothing on it yet" | PASS | `:125`, `ListsCopy.swift:25-27` | `aPrivateListNameIsMasked...` |
| 10.12 empty-shelf line "Paste a list anywhere to make one." | superseded by 13.1 "No other lists yet." (built) | | |
| 13.8 private item reads "Private item" until tapped; fold masked; receipt thing first | PASS | `ShopTrip.label/maskedLabel` `:198`, `:276-280`; engine receipt | `...NeverEchoesAWalledLine` ("advil" gives "Private item, on Packing.") |
| 13.8 "Private item, removed." / "back on" | NOT BUILT | no remove | none |
| 13.9 Lists side, KEPT PRIVATE; 13.5 side | NOT BUILT | | none |
| 13.2 "new list: packing" receipt and repeat-name rule | NOT BUILT | `CreateList` untouched (see G40) | none |
| A walled list name reads "Private list" on the shelf, page hero and receipt | PASS | `ListsShelf.swift:108-110`, `ListsView.swift:121`, `:261-263` | `aWalledListNameReadsPrivateList`, `aPrivateListNameIsMasked...` |
| Deleted list page reads "List gone." | PASS (extra) | `:176-181` | none |
| Everywhere: UNDO 4 s for a new capture, 10 s for a change | PASS | Add 4 s, clear 10 s | none |
| Everywhere: nothing under 16 pt; Dynamic Type AX one column; Reduce Motion; recording | NOT PROVABLE | tokens not traced; no recording in the diff | none |

Copy scan of #760's new strings ("Lists", "No other lists yet.", "nothing on it yet", "3 done, cleared.", "List gone.", "RUNNING, 2 LEFT", "Packing has 2 left."): no "at" before a clock, no clocks, no "record", no standalone "pin". Clean.

---

## 3. #764 "Recipe gone.", the "on Recipes." receipt, the Pantry hero test

Diff: `RecipesEntry.swift` keeps `@State opened` (`let id = opened ?? Self.opening(...)`, set `.onAppear`); `RecipePage.swift:431-434` adds `RecipeCopy.saved`; `PasteRecipe.swift:249` calls it for the saved line; `PantryLedgerTests.swift` adds a test.

| Clause | Verdict | Evidence | Test |
|---|---|---|---|
| K87.3 / G53 receipt "Carbonara, on Recipes." | PASS | `RecipePage.swift:433`, drawn at `PasteRecipe.swift:249` | `pastesReceiptNamesTheThingFirst` |
| K87.3 private: "Private recipe, on Recipes." (title masked before the helper, no title word on screen) | PASS | `savedTitle` `PasteRecipe.swift:26-29` runs `RecipeCopy.shownTitle` with the wall, then `saved` | `pastesReceiptNamesTheThingFirst` (title "Rent 1200 stew", a money-shaped one) |
| K87.3 the same with a secret-word title | NOT PROVABLE | same code path, no case | no test |
| K87.3 hero, original page title and VoiceOver header read "Private recipe" | PASS by read, from #752/#756, not this PR | `kitchen-acceptance-752-756-758-oct17.md` section 2 | `RecipeTitleWallTests` (older cases) |
| K87.3 "ingredient column and steps stay as written" | PASS | `RecipeTitleWallTests` older case ("Private recipe\nSimmer.") | |
| Receipt shape: thing first, "on", no "at", no clock, no "record", no "pin" | PASS | | |
| "Recipe gone." stays instead of jumping to another recipe (G51 interim, note 1 of the 752-756-758 doc) | PASS by read | `opened ?? opening(...)` `RecipesEntry.swift:22`, `.onAppear` sets it `:23-27`; `RecipePage` falls to "Recipe gone." when the object is gone (`RecipePage.swift:162-173`) | `theRecipeOpenedStaysChosenSoAGoneOneSaysSo` is weak: it asserts `opening(requested:rows: [])` returns the requested id, which was already true before the PR. The new `@State opened` path has no test |
| "Back to the list" returns to the shelf | NOT BUILT | still `dismiss()` to Home (`RecipePage.swift:168`); the shelf (K87.1) does not exist | none |
| K87.4 "Recipe link, kept for later." offline, never the URL aloud | NOT BUILT here, not in this PR | `RecipeLinkLine.saved` (`TesseraCore/Sources/TesseraTess/RecipeLinkReader.swift:54-56`) still returns "X saved." with no UI caller; it is pinned by `RecipeLinkTests.swift:277` as the old wording. Dead copy; delete or reword with K87.4 |
| K89.1 Pantry hero after a private cook: hero counts the out and low, Tess slot empty | PASS by read | `PantryLedger.hero` `:72-79`; `cookUses` ignores the recipe title and counts limes (Produce, out) and ground beef (low) `PantryLedger.swift:148-165`; `lastCookUsedUp` returns nil for a private title `:96-100` ("Wifi code lasagna" carries secret words "wifi" and "code", `SecretWords.swift:11,22-28`) | `aPrivateCookStillMovesThePantryHero` (asserts "Nothing yet" before, `lastCookUsedUp() == nil` and hero "1 out, 1 low" after) |
| K89.1 "Tess slot is empty" through `PantryFront.tess` | NOT PROVABLE | test checks `lastCookUsedUp()`, not `PantryFront.tess` (which maps it, `PantryFront.swift:27`); the spec asked for the `PantryFrontTests` form | no `PantryFrontTests` case added |
| K89.1 "no string in the view or its accessibility tree contains the recipe's words or 'Private recipe took'" | NOT PROVABLE | no view or accessibility-tree assertion | no test |
| K89.1 ordinary recipe unchanged: "Tacos took the cilantro and limes." | PASS (older) | `PantryLedgerTests` first case asserts names and recipe | `aShopMakesThingsInThenACookMakesThemLowAndProduceOut` |

---

## 4. #761 ObjectPlate photo label

What it changed: `Features/Objects/ObjectPlate.swift` (+ `PlateWashTests`). The init no longer takes a caller-built `photoLabel: String?`; it takes `title` and `site` and builds the label itself, so a raw string cannot be passed. A private plate's VoiceOver label is exactly "Photo of Private recipe" with no site (before: "Photo of Private recipe, from <site>"); a public one is "Photo of Tacos, from example.com" or "Photo of Tacos". The `.accessibilityLabel` on the photo is now the built label (`photoLabel ?? "Photo"` is gone).

Kitchen rows touched: `recipe-plate-acceptance.md` P9 (VoiceOver reads a photo after the title, "Photo of Sheet-pan paprika chicken, from budgetbytes.com"; PASS for the public shape) and P4 (a private recipe shows no photo, no pigment; the code already nulls `photo` and `pigments` when `isPrivate`, PASS by read). Private recipes never get an image: the plate holds `photo = isPrivate ? nil : photo`. Test: `PlateWashTests.aPrivatePlateHasNoPigmentAndAMaskedLabel` (asserts `plate.photoLabel == "Photo of Private recipe"`, no pigments, and the two public shapes). Nothing in app code constructs `ObjectPlate` yet (grep of `ObjectPlate(` finds only the tests), so P1 to P3 and P5 to P8, P14 to P19 (fetch, cap, guards) are NOT BUILT and unaffected. No Kitchen row beyond P4 and P9 is touched.

---

## 5. Gap rows now closed, and what is still open

CLOSED by these PRs (only the parts really built):
- **Groceries Add-line / Bar wall in Core (spec A1 and the Core halves of W1 to W3, W6; C1 for "buy milk $4" / "buy milk 4.99").** Closed in Core and for "buy" phrasing on the Bar. Not closed: bare "milk $4" on the Bar, and everything the Add line says or does after the wall (below).
- **G53 receipt** (K87.3): "Private recipe, on Recipes." and "Carbonara, on Recipes." built and tested at the helper level. The private-title wall itself was already closed by #752.
- **K89.1 Pantry hero after a private cook**: closed at the ledger level (hero counts it, no Tess line source); the `PantryFront.tess` and accessibility-tree halves are not asserted.
- **Recipe gone stays (G3/G51 interim, note 1)**: closed by read; the new state has no test.
- **#761**: closes only the plate-label wall (the label cannot be built from a raw string and drops the site on a private plate).

NOT closed (do not mark closed):
- **G40** (list lookup refusal, repeat list name, 13.2): untouched. `TessTools.list(named:)` and `CreateList` are not in any of the four diffs.
- **G43** (Done shopping has no UNDO or failure line) and **G44** (shop never goes idle): untouched.
- **G49** ("1 list"): the new shelf avoids it (Groceries is always present, "Just Groceries" when alone), but the formatter is unchanged and 13.3 text is stale; leave open until the row text is fixed.
- **G51 proper** (Recipes shelf; "Back to the list" to the shelf), **K87.4** (link-kept line; the old "X saved." helper is dead copy).
- **Add-line half of the wall** (W1 receipt with UNDO, W2/W3 spoken lines, W5 draft behavior, A4 tests): open, owner Builder B.
- **Lists**: running, reusable, pick-one, put-away, option words, paging, remove (10.9, 10.10, 13.6, 13.8 removal), Lists side (13.5, 13.9), Tess slot (13.1, 13.3), multi-item Add, bare-phrase-to-list, the door's label and zoom, and the draft being lost on a failed Lists add.
- **Doc drift to fix**: 9.3 "14 TO BUY" should read "14 TO GET"; 9.1 and 13.3 context text should read the ruled "N lists, N running"; 9.7 and 13.x rows describe features not built.

Test-gap list worth adding (cheap): a Bar test for the exact line "Milk, on Groceries." and for bare "milk $4"; an amount-kept assertion for the four amount lines; "1.25 lb chicken" decision; a `RecipeView` test for `opened`; a `PantryFront.tess == nil` case.

---

## 6. Phone only

- Lists door and shelf: Home, Kitchen page, tap Lists; confirm Groceries once, sizes by last touched, state words, "Just Groceries" when alone.
- Add line receipt: open a list, type "rice", return; the line reads "Rice, on <list>." and UNDO lasts about 4 s (10 s with VoiceOver on). Type "wifi password hunter2" and "rent $1200": each reads "Private note, kept." and no item appears.
- Fold: check two items, tap "2 done" (shows them, tap one to take it back), hold 0.7 s to clear; the line reads "2 done, cleared." with UNDO for 10 s.
- Groceries Add line: type "milk $4" then "milk 4.99": row "milk" both times and (today) no spoken line; type "$40 at costco": nothing lands and nothing is said (expected FAIL against W2 wording).
- Groceries Add line block: paste three lines with one walled; confirm the walled line is gone from the field (expected FAIL for W5).
- Bar: say "buy milk $4" (row "milk", line "Milk, on Groceries."), then the bare "milk $4" (expected miss until C1 is built).
- Paste a recipe whose title is private (a money or secret word): the saved line reads "Private recipe, on Recipes." and the hero reads "Private recipe".
- Recipe gone: open a recipe from Kitchen, delete it from another place (or undo its save), come back; the page reads "Recipe gone." and does not jump to another recipe.
- Pantry after a private cook: cook a private recipe to DONE; the hero changes ("1 out, ...") and the Tess slot is empty; VoiceOver reads no recipe words.
- Plate label: VoiceOver on a recipe with a photo reads "Photo of <title>, from <site>"; not reachable yet (nothing builds the plate), so wait for the plate wiring.
- Sizes, spacing, stagger timing, haptics, Reduce Motion crossfade and Dynamic Type AX on the shelf and list page; recording for #760.
