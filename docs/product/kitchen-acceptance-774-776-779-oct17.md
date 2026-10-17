# Kitchen acceptance of #776, #779 and #774: static read

Static only, against origin/master ba73a22 (nothing built or run; no Swift toolchain). Merges read by `git diff <merge>^1 <merge>`: #776 38215b9, #779 f08a0b6, #774 b4451e2. "PASS" means the clause is met by the code at the line given; every test named was read, none was run. Specs: K87 (`kitchen-groceries-screen-walk-oct17.md`), K88 (`kitchen-lists-screen-walk-oct17.md`), the #759 `kept()` spec (`kitchen-test-specs-wall-g40-g43-g44-oct17.md`, section A), `kitchen-gap-hunt-8-recipes-oct17.md`, and the open rows of `kitchen-acceptance-765-767-769-771-oct17.md`.

Refs: Lists = `TesseraCore/Sources/TesseraCore/Lists/Lists.swift`, RLR = `TesseraCore/Sources/TesseraTess/RecipeLinkReader.swift`, RLT = `TesseraCore/Tests/TesseraCoreTests/RecipeLinkTests.swift`, GWT = `TesseraCore/Tests/TesseraCoreTests/GroceriesWallTests.swift`, HRT = `TesseraCore/Tests/TesseraCoreTests/HouseRulesTests.swift`, LC = `Features/Lists/ListsCopy.swift`, LV = `Features/Lists/ListsView.swift`, RS = `Features/Recipes/RecipesShelf.swift`, RSV = `Features/Recipes/RecipesShelfView.swift`, RE = `Features/Recipes/RecipesEntry.swift`, RP = `Features/Recipes/RecipePage.swift`.

## 1. #776 (Core: recipe units out of the price wall)

Changes: the unit list in `RecipeLinkReader.withoutMeasures` and in `AddListItem.kept` gains pints, pt, quarts, qt, gallons, gal, cl, dl, sticks; cl joins g and ml in the "under 1000" group. The test file also gets a lint-only `try await` reorder.

| Clause | Verdict | File:line | Covering test |
|---|---|---|---|
| pint, quart, gallon (and the short forms pt, qt, gal) read as a measure after a two-place amount in the recipe wall | PASS | RLR:390 (unit alternation), RLR:393-395 (amount of 10 or less passes) | `moreRecipeMeasuresAreNotMoney` ("1.50 pints milk", "0.75 pt cream", "1.25 quarts stock", "2.50 qt broth", "1.25 gallons water", "0.50 gal juice"), RLT:462-466 |
| dl, cl read as a measure; cl uses the under-1000 bound with g and ml | PASS | RLR:390, RLR:394 | same test ("2.50 dl cream", "33.00 cl beer"). dl is on the 10-or-less bound by read; no case above 10 dl |
| stick (butter) reads as a measure | PASS | RLR:390 | same test ("1.50 sticks butter") |
| kg and lb stay walled | PASS | neither unit is in RLR:390; the guard at RLR:384-388 still stops a weigh word, a currency word or a currency sign | `bodyUnitsStayWalled` ("8.50 kg today", "9.20 lb this morning"), RLT:470; the earlier `moneyAndHisWeightKeepTheirAmounts`, RLT:457, still holds ("182.50 lb", "7.80 lbs" and the rest) |
| Same unit set on the Lists path, so a line typed on the Add line agrees with the recipe wall | PASS | Lists:208-212 | `numbersThatAreAmountsStay` ("1.25 cups flour"), GWT:44; see section 2 for the thing-after rule added by #779 |
| A currency sign or a currency word still beats a unit | PASS | RLR:386-388 returns the line unchanged | `moneyAndHisWeightKeepTheirAmounts` ("$1.25 cups", "2.50 g usd", "paid 12.50 pounds for shoes"), RLT:457 |
| Output only widens what is sent: no unit removes a line that was kept before | PASS | the regex only gains alternatives; the closure is unchanged | `aMeasureWithTwoDecimalsIsNotMoney`, RLT:444 |
| Recipe path has no "thing after it" guard, so "milk 3.49 gallon" in page text passes the wall with its price | NOTE (low, not in the clause) | RLR:390 has no trailing-word rule; #779 added one on the Lists path only (Lists:209) | no test |
| Lint reorder of `try await` in the Claude-off test | PASS (no change in meaning) | RLT:365 | `step.read` test around RLT:362 |

Verdict: accepted.

## 2. #779 (Core: price before a list unit, sum-only)

Changes: the measure strip in `AddListItem.kept` now needs a thing after the unit and replaces the whole match with "1 x" (Lists:208-212), so "milk 3.49 gallon" stays a price. The sum-only check (Lists:239-250) is not edited by #779; it keeps its #759 form. HRT gets a stricter fileProtection token check (QA on #778), unrelated to Kitchen.

| Clause | Verdict | File:line | Covering test |
|---|---|---|---|
| "milk 3.49 gallon" and "ice cream 5.99 pint" (price, unit, no thing after) become a private note | PASS | Lists:208-212 (no `\s+[a-z]` after the unit, so no strip), Lists:215-220 (price shape not an amount, so a note) | `aPriceBeforeAListUnitIsStillAPrice`, GWT:162-168 (both lines give nil) |
| "1.25 cups flour" (measure with a thing) stays a row | PASS | Lists:208-212 | GWT:168 and `numbersThatAreAmountsStay`, GWT:44 |
| "2 gallons milk" keeps (no two-place decimal) | PASS | no strip applies | GWT:167 |
| "1.25 lb chicken" keeps via the amount rule, unaffected by the strip | PASS | Lists:214, Lists:225-235 | GWT:166, `moreAmountsLand`, GWT:117 |
| Trailing bare two-place decimal still strips ("milk 4.99" gives "milk") | PASS (unchanged) | EngineWall.swift:75 | `priceComesOffAndTheThingStays`, GWT:34; `moreAmountsLand` ("milk 4.99.") |
| Sum-only check: "$40 at costco", "rent 2100 fri", "$40" never land | PASS (unchanged by #779) | Lists:239-250 (judged on `given`; filler words and shop and currency words dropped) | `aWalledLineNeverLandsAsARow`, GWT:51 |
| Sum-only with a unit: "$40 at costco" cannot be rescued by the new strip | PASS | the strip needs two places then a unit then a thing; a currency sign line is stripped to "at costco" first and ends sum-only | GWT:51 |
| **Known low: "at", "for", "from", "on" after a unit or price are never read as the thing** | **FAIL (not handled)** | Measure path: Lists:209 accepts any letter after the unit, so "milk 3.49 gallon at costco" and "3.49 gallon on sale" count as a measure with a thing, are not price-shaped, are not sum-only (Lists:243-249 leaves "milk" and "gallon"), and land with the price kept. Amount path: Lists:232 `neverFood` lacks for, from, on; only "at" is stopped, and only by chance (it is in `dayWords`, PrivateFacts.swift:67), so "1.25 lb at costco" is walled but "1.25 lb for dinner", "1.25 lb from costco" and "1.25 lb on sale" are read as an amount of a thing and kept. After a currency sign these words are handled (filler list, Lists:243) | no test: GWT:162-168 has no case with a following at, for, from or on |
| No key-shaped literal in the new tests | PASS | GWT:162-168, RLT:462-472 | search of the three diffs for the Claude key prefix finds nothing |
| HRT scan takes only the exact token (`.completeFileProtection`, not `...UnlessOpen`) | PASS (out of Kitchen scope) | HRT:122 | `theProtectionScanSeesAnOptOut`, HRT:137-142 (UnlessOpen and UntilFirstUserAuthentication both flagged) |
| Side effect: the replaced text reads "1 xlour" for "1.25 cups flour" (match eats the first letter of the thing) | NOTE (harmless: `measured` is only fed to the price-shape check) | Lists:208-212 | no test |

Verdict: accepted for its own clauses (price before a list unit); the known low (at, for, from, on after a unit or price) is not handled and stays open for Core.

## 3. #774 (Builder B, "recipes-shelf-lows": the branch name is right; the coordinator's "Lists add" covers only part)

What it actually changes (9 files, app side only, no Core): (1) the Lists Add line gets a testable `ListsCopy.add` that clears a Claude key and keeps the typed text on a failure; (2) the Recipes shelf: one cook read, short name in Tess's line, year on old dates, Tess speaks once per visit, a "Paste a recipe" door on an empty shelf kept inside the shelf's stack; (3) a deleted recipe stays on screen and reads "Recipe gone." (testable `isGone`, `shown`).

### 3a. Lists Add line (Kitchen on #760, Product key rule)

| Clause | Verdict | File:line | Covering test |
|---|---|---|---|
| A Claude key typed or pasted on the Lists Add line is never written: nothing is performed, the field clears, Tess says the key line ("It goes in Review, under Claude.") | PASS | LC:49-56 (checked on the trimmed text before `perform`), LV:253-258 | `aKeyClearsTheFieldAndIsNeverWritten`, ListsCopyTests.swift:35 (fixture joined at run time; asserts no write, empty draft, the shared `claudeKeyLine`, no op) |
| Any other failure keeps the typed text and says "Didn't save that. Try again." | PASS | LC:57, LV:255-258 (draft only cleared when `attempt.draft` is empty) | `anotherFailureKeepsTheTypedText`, ListsCopyTests.swift:42 (draft "rice " kept untrimmed) |
| Blank draft clears and writes nothing | PASS | LC:51-52 | `aBlankDraftClears`, ListsCopyTests.swift:47 |
| A kept line still gets its receipt thing first with UNDO 4 s ("Rice, on Packing.") | PASS (unchanged, Lists only) | LV:259-266 | `theAddReceiptNamesTheThingFirst`, ListsCopyTests.swift:29 (text only; the hold and UNDO wiring in `add()` has no test) |
| Walled line on the Lists page still becomes "Private note, kept" / "Private item, on Packing." | PASS (unchanged) | Lists:178-184 via LV:259-266 | `theAddReceiptNamesTheThingFirst` ("Private item, on Packing."); no case through `ListsCopy.add` |
| Key line says the same words as Groceries and the Bar | PASS | LC:55 uses `claudeKeyLine` (ClaudeKeyGuard.swift:4) | ListsCopyTests.swift:35 |
| A key in the middle of a longer line: whole line cleared, rest not kept | NOTE (accepted edge; Paste cuts the key and keeps the rest, the Add line does not) | LC:54-56 | no test |
| `add()` wiring (field set, `say` call, early return without a list) | NOT PROVABLE | LV:251-266 | no test of the view; the decisions are in `ListsCopy.add` |

### 3b. Recipes shelf lows (QA on #765)

| Clause | Verdict | File:line | Covering test |
|---|---|---|---|
| Every cook read once and grouped by recipe, not once per row; last cook is the row's day; count unchanged | PASS | RS:27-42 | `aPrivateRecipeIsOnlyPrivateRecipeAndCounted`, RecipesShelfTests.swift:34; `tessLines`, :42 (counts 2 and 0) |
| Tess's line uses the short name ("Sheet-pan paprika chicken, cooked 1 time.") | PASS | RS:54-62 (`RecipeCopy.shortName`, RP:438) | `tessUsesTheShortNameAndOldDatesCarryTheYear`, RecipesShelfTests.swift:56 |
| A private recipe in Tess's line stays "Private recipe" | PASS by read | RS:36-37 masks first, then the short name of the mask | no test for a private name in a Tess line |
| Dates from an earlier year carry the year ("Oct 3, 2025"); this year stays "Sep 3" | PASS | RS:80-82 | same test (both cases, Pacific time) |
| Tess speaks once per visit, not every time the shelf reappears | PASS by read | RSV:24, RSV:97-98 (state lives on the stack's root page) | no test |
| Empty shelf has a way in: "Paste a recipe" | PASS by read | RSV:58-61, RSV:13, RSV:107-119 (Paste pushed inside the shelf's own stack; a save moves on to the page) | no test |
| Paste from the shelf: back lands on the shelf, not Home | PASS by read | RSV:13 (destination in the shelf stack) | no test |
| Deleting the shown recipe keeps its page, which reads "Recipe gone." with a way back (G3) | PASS | RE:64-66 (`shown`: the opened id wins), RP:45 and RP:474-477 (`isGone`), RP:165-168 | `deletingTheShownRecipeKeepsItsPageWhichSaysRecipeGone`, RecipeTitleWallTests.swift:54 (asserts `shown` and `isGone` true/false; the "Recipe gone." text itself is a view line) |
| Empty shelf Tess line "Paste a link or a page and I'll read it." (K30.1, 13.12) | NOT BUILT | RS:54-62 still returns nil with no rows | `emptyIsNoneYet` still pins nil |

## Open rows from the previous acceptance doc: which of these PRs close them

| Row | Closed by #776 / #779 / #774? | Why |
|---|---|---|
| G54 (link on Paste never read; Save with no line) | No | no file touched |
| G56 (Cook key suspends a running workout) | No | no file touched |
| G57 (portion drum stops at 12) | No | no file touched |
| G58 (swipe-to-Groceries failure, "0 to buy") | No | no file touched |
| G59 ("Untitled recipe", first line as title) | No | no file touched |
| G60 (context line "1.6 h", "94 days ago") | No | no file touched |
| G43 app half (Done shopping line, UNDO, failure) | No | `GroceriesView` not in any of the three |
| G52(c) (back from the page shows the paste screen's saved bar) | No, and a second route now has it | the new shelf Paste door (RSV:107-119) pushes the page on top of the Paste screen, so back returns to its old saved bar with a live UNDO, same as `RecipeView` |
| Kept-line receipt and UNDO on the Groceries Add line (K36.2, K87) | No | the Lists page already spoke the receipt with UNDO 4 s before #774; Groceries `add()` (GroceriesView.swift:223-241) is unchanged and still silent for a kept line |
| Failed Add on Lists leaves nothing said / ER11 for Lists add | Yes, closed by #774 | LC:57, LV:255-258 |
| Key on the Lists Add line | Yes, closed by #774 | LC:54-56 |
| `add()` has no outcome test | Partly: Lists `add` decisions now tested (3 cases); the Groceries add and the view wiring are not | ListsCopyTests.swift:35-51 |
| #765 gaps: Tess line long title, year on dates, speaks every appearance, shelf N reads, empty-shelf door | Yes, closed by #774 | section 3b |
| #765 gap: which day the row shows | Still unruled (code keeps the last cook) | RS:42 |
| #765 gap: empty-shelf Tess line K30.1 | No | NOT BUILT above |
| Known low with Core: at, for, from, on after a unit or price | No (see #779 row) | Lists:209, Lists:232 |

## Still open

- Core: at, for, from, on after a unit or price are read as the thing (Lists:209 measure path; Lists:232 amount path misses for, from, on). A line such as "milk 3.49 gallon at costco" lands with its price. Needs a stop list on both paths and a test.
- Core: recipe wall has no thing-after guard, so a price like "milk 3.49 gallon" in a page line is sent as a measure (low).
- G43 app half: the Done key is silent, has no UNDO and no failure line (GroceriesView.swift:327-334); the four app tests are not written.
- G52(c): back from the recipe page shows the paste screen's saved bar with a live UNDO, now on both the old opener and the new shelf door; the 6-word cap on the short name.
- Kept-line receipt and UNDO on the Groceries Add line (K36.2, K87); ER11 for Groceries check, uncheck, clear done and shop start.
- Empty-shelf Tess line (K30.1) and the Recipes side (13.13).
- G54, G56, G57, G58, G59, G60 untouched; the Tess phrase route of G55.
- Tests missing: a private name in a Tess line, the 1-cook and tie cases, the shelf's once-per-visit speech, the Lists `add()` wiring, a key in the middle of a Lists line.
- Lists still lacks the K88 engine slices (remove item, `AddListItems`, the other phrases); not in scope here.

## Phone only

- Lists: open Packing, type a Claude key on the Add line: the field clears and Tess says "That looks like a Claude key. It goes in Review, under Claude."; nothing lands on the list and there is no UNDO.
- Lists: add "rice": "Rice, on Packing." with UNDO holding 4 s (10 s with VoiceOver). Add "lexapro": "Private item, on Packing."
- Lists failed add cannot be forced by hand; leave it to a test.
- Groceries Add line, price before a unit: type "milk 3.49 gallon" and "ice cream 5.99 pint": both stay out of the list; "1.25 cups flour", "2 gallons milk" and "1.25 lb chicken" land. Then try "milk 3.49 gallon at costco" and "1.25 lb on sale": expect them to land today (the open low).
- Recipes shelf: a recipe cooked last year shows "Oct 3, 2025" in its row; one cooked this year shows "Sep 3" style. A long title (over six words) reads short in Tess's line. Leave the shelf for a recipe and come back: Tess does not repeat herself.
- Empty shelf: "Paste a recipe" opens Paste inside the shelf; back from it lands on the shelf, not Home. Save a recipe, let the page open, press its back word: the old saved bar with UNDO shows (G52(c)).
- Delete the recipe you are looking at (from another door or a Shortcut): the page stays and reads "Recipe gone." with "Back to the list" returning to the shelf.
- Recipe link read with a page that has "1.50 pints" and "33.00 cl" lines: they go to Claude as measures; "8.50 kg today" never leaves the phone.
- Reduce Motion, Dynamic Type AX3 and VoiceOver on the shelf rows and the Add line (13.14).

## Since this read (coordinator note, Oct 17, 9:40 am PT)

Not re-read in code; these are reported by the coordinator and need their own acceptance when each merges.

- The #779 open low (a price before at, for, from or on) is fixed in Core's #787: those words are stripped after a price and never count as the thing, with five test lines. One remainder is with Core: "eggs 4.99 at costco" keeps "at costco" in the item. The recipe-path guard raised on #776 is also with Core.
- The kept-line receipt and UNDO on Groceries is in Builder B's next PR.
- The empty-shelf Tess line (K30.1) is in #782.
- G56 is #783 plus Builder B's app half.
