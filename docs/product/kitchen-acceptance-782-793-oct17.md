# Kitchen acceptance of #782, #783, #786, #787, #788, #790, #791, #792, #793: static read

Static only, against origin/master ebffa03 (nothing built or run). Part A is the app side (#782, #786, #788, #790, #791, #793); Part B is Core (#783, #787, #792).

# Part A: app side

# App acceptance: #782, #791, #793, #788, #790, #786 (master ebffa03)

Static read only. Nothing was built or run; "covering test" names a test I read, not one that passed. Paths are under /home/user/Tessera. Line numbers are on master ebffa03. GV = Features/Groceries/GroceriesView.swift, GW = Features/Groceries/GroceriesWall.swift, PR = Features/Recipes/PasteRecipe.swift, RP = Features/Recipes/RecipePage.swift, RS = Features/Recipes/RecipesShelf.swift, RSV = Features/Recipes/RecipesShelfView.swift, LV = Features/Lists/ListsView.swift, LS = Features/Lists/ListsSwipe.swift.

Sections follow the order the PRs were asked for.

## 1. #782 (b71113a): Groceries add, Finish, Paste, empty-shelf Tess line

Diff: GV, GW, NowPage, PasteRecipe, RecipesShelf; tests GroceriesFinishTests, GroceriesKeyTests, GroceriesWallTests, RecipesShelfTests.

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| Add line is decided in a testable function (`GroceriesWall.add` returns draft, voice, undo) | PASS | GW:58-93; GV:225-236 | `keptLinesSpeakTheEnginesReceiptWithUndo` |
| Kept lines speak the engine's own receipt ("Milk and eggs, on Groceries.") with a full stop | PASS | GW:90 (receipt gets "." if missing); Core Kitchen/Groceries.swift:549-555 | `keptLinesSpeakTheEnginesReceiptWithUndo` |
| Add UNDO holds 4 s (10 s under VoiceOver) | PASS | GV:234 (`holds: .seconds(4)`); HomeQueue.swift:45-52 forces 10 s under VoiceOver | no test (hold is a view-side argument) |
| Draft clears after a clean add | PASS | GW:92; GV:228-231 | `keptLinesSpeakTheEnginesReceiptWithUndo` (`draft.isEmpty`) |
| Failed add keeps the draft minus any key and says "Didn't save that. Try again." with no UNDO | PASS (arrived in #791 as testable) | GW:81-85 | `aRefusedWriteKeepsTheDraftButNeverTheKey` (added by #791) |
| A key is cleared and never returns; line is the Claude key line | PASS | GW:48-50 (`heldDraft` drops `.key`) | `aKeyIsClearedAndNeverComesBack` |
| K36.2 "Milk, taken back." wording after UNDO of a Groceries add | NOT PROVABLE | none built; the band clears on UNDO | no test; wording unruled |
| G43 app half: Done says "Shopping, finished." | PASS | GV:332-346; `GroceriesCopy.finish` GV:753-762 (engine receipt "Shopping, finished" from Core Kitchen/Shopping.swift:78, stop added) | `finishSaysShoppingFinishedWithUndo` |
| G43: Done carries an UNDO that holds 10 s | PASS | GV:344 | `finishSaysShoppingFinishedWithUndo` (undo restores the checked row); the 10 s hold itself no test |
| G43: UNDO brings the shop (process) back, not only the rows | NOT PROVABLE | engine undo reverses `FinishShop` ops (Shopping.swift:61-66) | test asserts the row only; `undoAfterFinishPutsPantryBack` (the shop-state version) is not written |
| G43: failed finish says "Didn't save that. Try again.", keeps the basket open, no UNDO, no finish haptic | PASS by read | GV:335-339 (returns before `basketOpen = false` and `finished += 1`) | `finishFailureSaysDidntSave` (line and nil undo only; the basket and haptic are view code) |
| G43: the finish line names no item | PASS by read | receipt is a constant, Shopping.swift:78 | no test (`finishLineNamesNoItem` not written) |
| Finish plays the done pattern once, only on success | PASS (haptic form fixed in #793) | GV:210-211, 344-345 | no test |
| K30.1 empty shelf Tess line "Paste a link or a page and I'll read it." | PASS | RS:55-58; spoken once per visit RSV:109-115; matches lists-acceptance 13.12 | `emptyIsNoneYet` (RecipesShelfTests, now asserts the line) |
| Home planned-cook key: GROCERIES while something is left to buy; COOK at zero only when cook mode exists, otherwise no key | PASS | NowPage.swift:238-247, 266-282 | `groceriesWhileThereIsSomethingToBuy`, `cookAtNothingToBuy`, `noKeyAtZeroUntilCookModeLands` |
| Home COOK key draws nothing today (`cookModeReady` is false) | PASS (consistent with G55 ruling) | RP:13 | `noKeyAtZeroUntilCookModeLands` |
| G52(c): leaving Paste closes the saved bar and UNDO; back finds a fresh Paste | PASS by read, but the first cut broke the receipt (see #791) | PR:121, 241-249 | no test (view state) |
| Mixed add (kept + walled) keeps receipt and UNDO | FAIL in this PR, fixed by #791 | GW at this merge returned the wall line alone with no UNDO | `aWalledLineHoldsTheDraftWithNoUndo` asserted the old behaviour |

## 2. #791 (20a4cf4): mixed add keeps receipt + UNDO, Paste receipt survives the push, list remove plays .notNow

Diff: GW, ListsSwipe, ListsView, PasteRecipe; tests GroceriesWallTests, ListsRemoveTests.

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| Kept-line receipt and UNDO survive a walled sibling; wall line follows the receipt ("Eggs, on Groceries. That stays on this phone.") | PASS | GW:89-92 (receipt, then `spoken`, joined by a space) | `aMixedBatchKeepsTheReceiptAndUndoWithTheWallLineAfter` |
| The draft keeps only the walled lines (key never) | PASS | GW:92 | same test (`draft == "rent $1200"`) |
| UNDO takes back only what was written, never the walled line | PASS | GW:75-92 (op built from `split.kept`) | same test (undo non-nil); no test that undo leaves the wall line untouched |
| Only-walled lines have no UNDO and speak the wall line alone | PASS | GW:89-92 | `onlyWalledLinesHaveNoUndo` |
| Failed add (write refused) tested: draft minus the key, failure line, no UNDO | PASS | GW:75-85 (write passed in) | `aRefusedWriteKeepsTheDraftButNeverTheKey` |
| Failed add now also speaks nothing about walled siblings | NOTE (still the old minor) | GW:81-85 returns before the wall line | the test asserts the failure line only |
| Paste receipt survives the push: `closeUndo()` no longer runs right after `onSaved` | PASS | PR:233-237 | no test (view state) |
| UNDO window closes once Paste is covered or popped (`onDisappear`), so back shows a fresh page | PASS by read (shelf door pops Paste, old openers push over it; both fire `onDisappear`) | PR:121, 241-249; RSV:20-27; RecipesEntry.swift:27, 87 | no test |
| Receipt still visible for the 4 s hold (10 s under VoiceOver) before the page opens | PASS | PR:231-237 | no test |
| List remove plays `.notNow` from the list page (the row is gone by the time a row-level haptic would fire) | PASS | LV:112-114, 174, 230; LS:10-11 (old `.made` removed) | no test (haptic wiring) |
| Haptic plays only for a real remove (a refused write returns false before `removed += 1`) | PASS | LV:224-230 | no test |
| Armed tick: `.selection` once as the pull crosses 96 pt, cleared on release | PASS | LS:34, 41, 45 | no test |
| Undo of a row remove puts it back in place and keeps a done row done | PASS | LV:231-236 | `undoPutsTheRowBackInPlace`, `undoKeepsADoneRowDone` (ListsRemoveTests; uses `DeleteObject`, not a dedicated remove op) |

## 3. #793 (ebffa03): ER11 failure lines, wrapping grocery names

Diff: GV, RecipesShelfView. No test file changed.

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| ER11 check fails: "Didn't save that. Try again." and the row stays on the list | PASS by read | GV:278-286 | no test |
| ER11 check: no reward on a failed write | FAIL (minor) | GV:261-277 the strike, the dab arc and `landed` light tap all run before the write at :278, so a refused check still plays them | no test |
| ER11 uncheck fails: line spoken | PASS | GV:295-300 | no test |
| ER11 clear done fails: line spoken (success keeps "Cleared N from the basket." with UNDO) | PASS by read | GV:304-315 (`basketOpen = false` still runs on failure) | no test |
| ER11 shop start / suspend fails: line spoken | PASS | GV:318-329 | no test |
| ER11 finish fails: line (from #782, now the shared constant) | PASS | GV:332-346, 745, 759 | `finishFailureSaysDidntSave` |
| ER11 add fails: line, draft stays | PASS (from #769/#782) | GW:81-85 | `aRefusedWriteKeepsTheDraftButNeverTheKey` |
| One shared failure line, sentence form "Didn't save that. Try again." (ruled) | PASS | GV:745-750 | no test on `sayDidntSave` |
| ER11 `.warning` haptic | NOT BUILT, by design | DesignSystem/Haptics.swift:6 (no error or warning case exists) | n/a |
| ER11 "tap the line to retry" | NOT BUILT | the band has no retry | no test |
| ER11 remove fails | NOT BUILT on Groceries (no remove or swipe on Groceries) | n/a | n/a |
| Finish haptic is the house `.done` (no raw sensory feedback) | PASS | GV:210-211 | no test |
| Grocery names wrap, never cut (K36.19, AX rule) | PASS by read | GV:499 (`fixedSize(horizontal: false, vertical: true)`); no `lineLimit(1)` left in the file (only :709, a 2-line hint) | no test |
| K36.19 row at 44 pt or more, one column at AX3 | NOT PROVABLE | min row 48 pt per K87 walk | phone only |
| Paste back word: guard cleared when Paste leaves (see #790) | PASS | RSV:20, 125, 139 | no test |

## 4. #788 (2b2098e): G56 cook guard, app half

Diff: RecipePage; test CookWorkoutTests.

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| Workout running: the Cook key's action says "Workout running." and starts nothing (ruled: refuse) | PASS by read | RP:189-203; `RecipeCopy.startCook` RP:419-430 (Core `StartCooking.workoutRunningLine`, Cooking.swift:110-134) | `aRunningWorkoutRefusesTheCookWithItsLine` |
| No cook object is created on refusal | PASS | refusal thrown at Cooking.swift:134 before any write | same test (`.cook` objects empty) |
| The workout is not suspended | PASS | same test; Core guard ProcessActions.swift:258 | same test (`running()` is the workout, state `.running`) |
| No UNDO on the refusal (nothing was done) | PASS | RP:196-199 (`say(refusal)` only) | no test |
| Any other refusal says "Didn't save that. Try again." | PASS | RP:427-428 | `anyOtherRefusalSaysDidntSave` |
| Success is silent and unchanged | PASS | RP:201 | `withNoWorkoutTheCookStartsSilently` |
| The refusal is reachable from a tap today | NOT PROVABLE | the Cook key is not drawn while `cookModeReady` is false (RP:13, 126), so the app half cannot be seen until cook mode lands; the Tess phrase route already refuses (TessCaptureEngine.swift:506) | phone only after cook mode |
| Rest timer and Live Activity unchanged | NOT PROVABLE | engine leaves the workout running | phone only |

## 5. #790 (e5c1b38): Paste back word

Diff: ListsView (`BackWord` made non-private), RecipesShelfView.

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| Paste from the shelf shows a "‹ RECIPES" back word, bar hidden like the shelf | PASS by read | RSV:121-141; `BackWord` LV:344 | no test |
| Back from Paste lands on the shelf, not Home | PASS by read (the shelf owns a `NavigationPath`) | RSV:11-27 | no test |
| A save swaps Paste for the new recipe in the path, so back from the recipe is the shelf, never Paste | PASS by read | RSV:20-27 (`removeLast`, `append`) | no test |
| If he already went back, the save pops nothing and stays on the shelf | PASS | RSV:23 (`path.count == pasteDepth`); `pasteDepth` cleared when Paste leaves, RSV:20, 139 | no test (the guard is a pure comparison but not extracted) |
| VoiceOver and Switch Control have a way back with the bar hidden | PASS by read | RSV:130-137 (`BackWord` button) | no test |
| G52(c) on the shelf door: the saved bar is gone on return | PASS (with #791's `onDisappear`) | PR:121, 241-249 | no test |

## 6. #786 (815e933): Lists swipe to remove

Diff: ListsCopy, ListsSwipe (new), ListsView; test ListsCopyTests (later reshaped by #791).

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| Left swipe on a list row; REMOVE rises in the live colour from 60 pt, whole at 96 | PASS | LS:13-18, 23-31; LV:153 | `removeRisesFrom60AndIsWholeAt96` |
| Commits past 96 pt; short of it springs back | PASS | LS:44-48 | reveal math tested; commit and spring no test |
| Never a hold, red row, confirm or trash can | PASS | LS:21-52 | n/a |
| Horizontal-only gesture (vertical scroll wins) | PASS by read; NOT PROVABLE on device | LS:37-40 (`simultaneousGesture`, width greater than height) | phone only |
| Receipt thing first: "Rice, removed." | PASS for the string | ListsCopy.swift:32-34; LV:231 | `aRemoveNamesTheThingFirstAndUndoSaysWhereItWent` |
| Receipt first letter up (10.9: "the row as written, first letter up") | FAIL | LV:224 passes `item.text` as stored; the engine stores as typed and capitalizes only in its own receipts (Core Lists.swift:281, 294). A row stored as "rice" reads "rice, removed." The test passes the literal "Rice" so it cannot see this | no test |
| UNDO holds 10 s (10 s under VoiceOver) | PASS | LV:231 uses `takeBack`, default hold 10 s (HomeQueue.swift:45-52) | no test |
| UNDO says "Rice, back on Packing." | PASS by read | LV:232-235; ListsCopy.swift:37-39 | `aRemoveNamesTheThingFirstAndUndoSaysWhereItWent` (string only) |
| UNDO returns the row in the same place with its check as it was | PASS | LV:232 (`engine.undo`) | `undoPutsTheRowBackInPlace`, `undoKeepsADoneRowDone` (from #791) |
| Private row reads "Private item" in both lines, opened or not | PASS | LV:224 via `ShopTrip.maskedLabel` (ShopTrip.swift:30-32) | `aRemoveNamesTheThingFirst...` asserts "Private item, removed." for the label constant only |
| Failed remove: "Didn't save that. Try again.", row springs back | PASS | LV:225-228 | no test |
| VoiceOver gets a "Remove" action | PASS | LS:23 | no test |
| Rows close up; count rolls ("9 to get" to "8 to get") | NOT PROVABLE | rows close via `model.touch()` in the house animation (LV:229); no count line is asserted | phone only |
| Reduce Motion: a crossfade | NOT PROVABLE | LS:31 removes the rise offset; the row exit is the default transition | phone only |
| Swipe on Groceries rows ("Groceries and Packing alike", 13.6) | NOT BUILT | `.swipeToRemove` is applied only in LV:153 | no test |
| Dedicated remove op with the `checkedAt` rule (Core slice 1c) | NOT BUILT | the swipe uses `DeleteObject` | no test |

## Rows closed, by PR

| Open row (from the acceptance lists) | Closed by | Notes |
|---|---|---|
| G43 app half: Done line, UNDO, failure line | #782 | the shop-state UNDO test and the no-item test are still unwritten |
| G43 `finishShop` haptic | #782, #793 | house `.done` after #793 |
| K30.1 empty-shelf Tess line | #782 | test updated |
| Kept-line receipt and UNDO on the Groceries Add line (K87, K36.2) | #782 for all-kept batches, #791 for mixed batches | the "taken back" wording stays unruled |
| `add()` has no outcome test (765 doc) | #782, #791 | outcome is now a static function with five tests |
| Failed add leaves a key in the field | #782 (key removed from the held draft), tested by #791 | the walled-sibling line on a failed add is still skipped |
| ER11 for check, uncheck, clear done, shop start, finish | #793 (finish also #782) | by read, no tests; no `.warning` haptic or retry by design |
| K36.19 grocery names wrap | #793 | by read |
| G52(c) back from the page shows a live saved bar | #782 (close on leave), #791 (receipt survives the push), #790 (shelf back word and pop guard) | by read, no test, phone check below |
| G56 app half | #788 | key hidden until cook mode, so unreachable by tap today |
| G55 Home COOK key held back | #782 | the recipe page's own Cook key was already hidden by #765 |
| K88 13.6 swipe remove on Lists (10.9, K31.8, K31.11) | #786, #791 | first-letter-up misses; Groceries has no swipe; Core remove op absent |

## Still open

- Lists swipe receipt reads the stored text, so "rice, removed." (and "rice, back on Packing.") if typed lowercase. Fix: capitalize the first letter in `remove` (LV:224) or in `ListsCopy.removed` and `backOn`, and add a lowercase case to the test. Only miss that blocks #786 as accepted.
- Groceries rows have no swipe to remove; Core still has no dedicated remove op or `checkedAt` rule (K88 slice 1c); no count roll check.
- G43: `undoAfterFinishPutsPantryBack` (shop state returns), `finishLineNamesNoItem` and the basket-kept-on-failure test are not written; the 10 s hold is asserted nowhere.
- ER11: no `.warning` haptic and no retry tap (house map has no warning case, so the sheet row needs a ruling); a refused check still plays the strike, dab arc and light tap before the write (GV:261-278); clear-basket failure still closes the basket (GV:307).
- ER11 and #793 have no tests at all.
- Failed Groceries add skips the walled sibling's line (minor, unchanged).
- K36.2 "taken back" wording after UNDO of an add: unruled.
- G52(c): all by read; the 6-word cap on the short name is untouched. `closeUndo` is view state with no test. The Paste failure branch (PR:211-224) is still silent.
- G54 (Paste link path and silent Save), G57 (drum stops at 12, Portion drum range 1 to 12), G58 (`try?` on the Groceries send, RP:226), G59 ("Untitled recipe", RecipeParser.swift:109), G60 (decimal hours and "N days ago", RP:477, 525): untouched by these six PRs.
- G56: the refusal cannot be tapped until the Cook key returns with cook mode; Tess's phrase route already refuses. The key line is spoken by Tess, not drawn on the key.
- Recipes side (13.13), the empty-shelf row's day column, Reduce Motion and AX3 on the shelf and Lists swipe.
- Tests still missing from the 774/776/779 list: a private name in a Tess line, the 1-cook and tie cases, the shelf's once-per-visit speech, the Lists `add()` wiring, a key in the middle of a Lists line.

## Phone only

- Groceries: add "eggs, rent $1200": the band reads "Eggs, on Groceries. That stays on this phone." with UNDO for 4 s; UNDO removes eggs and leaves "rent $1200" in the field. Add "milk": "Milk, on Groceries." with UNDO.
- Groceries: start a shop, check a row, press Done: "Shopping, finished." with UNDO for 10 s and the done pattern once; UNDO brings the row and the shop back (check the shop state, not only the row). A failed Done cannot be forced by hand.
- Groceries: set Dynamic Type to AX3 and add a name over 40 characters: the row wraps in full, at 44 pt or more.
- Recipes: empty shelf shows "No recipes yet." and Tess says "Paste a link or a page and I'll read it." once; leave and return, she stays quiet.
- Paste from the empty shelf: the back word says "RECIPES" and returns to the shelf. Save, watch the "X, on Recipes." bar with UNDO hold 4 s (10 s with VoiceOver), the page opens, press its Recipes word: the shelf shows (no Paste screen, no saved bar). Repeat from Kitchen's "Paste a recipe" door: back from the page shows a fresh Paste. Save then press back inside 4 s: the recipe stays saved, no crash, no double push.
- Lists, open Packing: swipe a row left, REMOVE rises from 60 pt, tick at 96 pt, release past it: row leaves with one light tap, "Rice, removed." (check capital R with a lowercase row) with UNDO for 10 s; UNDO returns it in place, checked rows still checked, "Rice, back on Packing." Release short of 96 pt: it springs back, no haptic. A Private item row reads "Private item, removed." and "Private item, back on Packing." Vertical scroll must not trigger the swipe. VoiceOver: the Remove action exists. Reduce Motion: no rise, crossfade.
- Home: a planned cook with nothing left to buy shows no key (cook mode not built); with items left it shows GROCERIES.
- G56: not testable by hand until the Cook key returns; with a workout running, say "cook carbonara" to Tess for the engine half: "Workout running.", the rest timer and Live Activity untouched.
- Reduce Motion, Dynamic Type AX3 and VoiceOver on the shelf rows, the Add line and the Lists swipe.

# Part B: Core

# Core acceptance of #787, #792 and #783: static read

Static only, against origin/master ebffa03 (nothing built or run; no Swift toolchain). Merges read by `git diff <merge>^1 <merge>`: #787 52ef1cb, #792 41260ad, #783 41dbb68. PASS means the code at the line given meets the clause; every test named was read, none run. "By read" means no test pins it.

Specs: `kitchen-acceptance-774-776-779-oct17.md` (open lows on Lists:209 and Lists:232, recipe path), `kitchen-test-specs-wall-g40-g43-g44-oct17.md` section A (`kept()`), `kitchen-gap-hunt-8-recipes-oct17.md` (G54, G56 to G60, ruled row K87.6 for G56), `kitchen-groceries-screen-walk-oct17.md`.

Refs (all current master line numbers): Lists = `TesseraCore/Sources/TesseraCore/Lists/Lists.swift`; EW = `TesseraCore/Sources/TesseraCore/Tess/EngineWall.swift`; WS = `TesseraCore/Sources/TesseraCore/Training/WorkoutSummary.swift`; RLR = `TesseraCore/Sources/TesseraTess/RecipeLinkReader.swift`; PA = `TesseraCore/Sources/TesseraCore/Processes/ProcessActions.swift`; CK = `TesseraCore/Sources/TesseraCore/Kitchen/Cooking.swift`; TCE = `TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift`; GWT, WST, RLT, CT, KCT, HLT, SFT = the same-named files under `TesseraCore/Tests/TesseraCoreTests/` (GroceriesWallTests, WorkoutSummaryTests, RecipeLinkTests, CookingTests, KitchenCaptureTests, HomeLinesTests, SideFactsTests).

## 1. #787 (an amount like 3.49 before at, for, from, on; "Private workout" done line)

Changes: Lists measure strip and the amount-path stop list gain at, for, from, on; `EngineWall.withoutPrice` strips a trailing place phrase (first version added a lookahead strip, #792 later reworked it into the phrase-eating rules now at EW:75-82); `WorkoutSummary.doneLine(in:)` masks a private routine title; `WorkoutModeView.swift:101` calls it. Note: #787 on its own kept "at costco" in "eggs 4.99 at costco"; the merge title of #787 on master only reads fully with #792 on top (see section 2).

| Clause | Verdict | File:line | Covering test |
|---|---|---|---|
| "milk 3.49 gallon at costco": a unit followed by at/for/from/on is not "a measure with a thing", so the 3.49 stays a charge and the line becomes a private note | PASS | Lists:208-218 (the thing-after rule at Lists:213 refuses at, for, from, on) | `aWordAfterAPriceIsNeverTheThing`, GWT:178 (case "milk 3.49 gallon at costco") |
| Amount path: "1.25 lb for dinner", "from costco", "on sale" are no longer read as an amount of a thing | PASS by read (closes the Lists:232 miss) | Lists:237-250 (`neverFood` gains at, for, from, on) | no test. GWT:178 cases are all two-place amounts with no kg/lb unit, so none reaches `isAmountOfAThing` |
| Bare amount then at/for/from/on is cut as a charge: "eggs 4.99 at costco", "milk 3.49 for the week", "bread 2.50 from the bakery", "rice 5.99 on sale" keep no digits | PASS | EW:82 (final form after #792) | `aWordAfterAPriceIsNeverTheThing`, GWT:178 (asserts no `\d+[.,]\d{2}` in the kept text, not the exact text) |
| Those words never count as the thing after a measure unit on the Lists path | PASS | Lists:213 | GWT:178 (last case) |
| Currency-sign and currency-word lines: "milk $4 from target", "eggs 6 dollars at costco" | PASS (landed by #792) | EW:75, EW:77 | `thePlaceAfterAPriceGoesWithIt`, GWT:188 |
| Real item words are not eaten: "eggs at costco" and "2 lemons for the tacos" keep everything | PASS | EW:82 needs a two-place amount before the word; EW:75 and EW:77 need a currency sign or word | GWT:188 (both cases, exact text) |
| Done line: a private routine title prints "Private workout" ("Private workout done, 1 of 5 exercises.") | PASS | WS:37-42; privacy test is `PrivateWords.isPrivateTitle` (care word, currency word, health word, medicine word, private label) | `aPrivateRoutineTitleNeverPrintsInTheDoneLine`, WST:42 ("Knee rehab day" gives a line starting "Private workout done," with no "rehab") |
| A normal title still prints as before | PASS | WS:38-41 | WST:35 (`summary.doneLine(in: store) == "\(title) done, 1 of 5 exercises."`) |
| The app cannot reach the unmasked line | PASS | WS:31 (`doneLine` now internal, doc says so); the only app caller is `Features/Workout/WorkoutModeView.swift:101`, switched to `doneLine(in: model.store)` | WST:35 (still reads the internal one through the module) |
| Other surfaces that print a routine title (Home line, Live Activity, share, widget) use the mask | NOT BUILT | not in this PR; Home uses its own `PrivateFacts.isPrivateTitle` at `Home/HomeLines.swift:572` | no test |
| Done-line call site compiles under Swift 6 main-actor rules | NOT PROVABLE | WorkoutModeView.swift:101 (`doneLine(in:)` is `@MainActor`; call is in a view closure) | no build run |
| Trailing phrase eaten whole: "milk 3.49 on sale, bread" loses "bread" | NOTE (low, wanted for "at costco" but greedy to line end) | EW:82 (`.*` to end) | no test |
| "Private workout" label is not in the shared label set | NOTE (the mask is applied only in `doneLine(in:)`; `PrivateWords.labels` at `Export/PrivateWords.swift:17` does not list it, so a title already equal to "Private workout" is not re-masked, which is harmless) | WS:39 | no test |

Verdict: accepted. Rows closed: the #779 low on Lists:209 (measure path) and Lists:232 (amount path, by read only); done line for a private routine (QA on #781).

## 2. #792 (Core lows)

Changes read from the diff: `eggs 4.99 at costco` place phrase goes with the amount (EW:75-82); Lists regex rewritten in extended form; recipe-path thing-after rule (RLR:389-396); stocked tomorrow's cook keeps "tomorrow" (HomeLines); `refuseWhileWorkoutRuns` on `StartProcess` and `ResumeProcess` (PA); Bar refusal line (TCE:505-508); training loads on a set, exercise entry or equipment print in the side facts (SideFacts); `doneLine` made internal.

| Clause | Verdict | File:line | Covering test |
|---|---|---|---|
| "eggs 4.99 at costco" gives "eggs" on `withoutPrice` and on `kept` | PASS | EW:82 | `thePlaceAfterAPriceGoesWithIt`, GWT:188 (exact text, both functions) |
| Place or deal goes with a currency-sign or currency-word amount | PASS | EW:75, EW:77 | GWT:188 ("milk $4 from target", "eggs 6 dollars at costco") |
| Lists strip rewritten in extended regex, same meaning as #787 | PASS | Lists:208-218 (same unit set, same stop rule) | GWT:178, GWT:188 |
| Recipe-path guard for the #776 low: "milk 3.49 gallon", "cheese 4.99 oz at the store", "butter 2.50 sticks for two", "eggs 1.25 qt from costco", "cream 2.99 pints on sale" are no longer measures and drop from the page | PASS | RLR:389-396 (unit must be followed by whitespace then a letter that is not at/for/from/on); line dropped by `sendable` at RLR:371-376 via `isWalled` (any two-place word is amount-shaped, `PrivateFacts.swift:36-52`) | `aMeasureNeedsAThingAfterIt`, RLT:454 (asserts empty output) |
| Real measures with a thing still go to Claude: "1.25 cups flour", "1.50 pints milk", "33.00 cl beer", "1.50 sticks butter" | PASS | RLR:396-402 (amount and size bounds unchanged) | `aMeasureWithTwoDecimalsIsNotMoney` RLT:439; `moreRecipeMeasuresAreNotMoney` RLT:471 |
| kg, lb, currency sign, currency word, weigh word still stop the strip | PASS | RLR:384-388 unchanged | `moneyAndHisWeightKeepTheirAmounts`, RLT:462 |
| Fail closed: "Flour: 1.25 cups" (unit at line end) stays off the page sent to Claude | PASS (by read) | RLR:395 needs a letter after the unit; end of line has none, so the amount is not stripped and `isWalled` drops the line | no test of a unit at line end (RLT:454 cases all carry a trailing word; no case "Flour: 1.25 cups") |
| Cook-while-training for start and resume: `StartProcess` and `ResumeProcess` refuse with "Workout running." and write nothing; another workout may still take over | PASS | PA:39, PA:150, PA:247-258 (a workout subject returns early, so a workout never blocks a workout) | `nothingElseStartsOrResumesWhileAWorkoutRuns`, CT:80 (resume, start, start shop; op count unchanged; same workout restarts; other workout takes over) |
| Bar: "cook carbonara" during a workout answers "Workout running." with nothing saved | PASS | TCE:505-508 | `cookingFromTheBarWhileAWorkoutRunsSaysSo`, KCT:16 |
| Stocked cook tomorrow keeps "tomorrow" in the context | PASS | `Home/HomeLines.swift:345` (tomorrow case of nothing-to-buy) | HLT:171 block (context == "tomorrow") |
| Training loads print on a set, exercise entry, equipment; a body-weight field on any other class never prints | PASS by read | `Tess/SideFacts.swift:38-50` | `aSetWeightPrintsButABodyWeightFieldNever`, SFT:62 |
| `doneLine` unmasked made internal | PASS | WS:31 | WST:35 |
| Fail-closed cost on recipes: see "What the fail-closed rule drops" below | NOTE (QA accepted) | RLR:395 | no test |

### What the fail-closed rule drops (note only)

The strip now fires only for a two-place amount, then a unit, then whitespace, then a letter that is not at, for, from or on. A recipe line whose unit is followed by anything else keeps its two-place amount, reads as a charge to `isWalled`, and the whole line is cut from the page text sent to Claude. Real shapes that are dropped:

- Ingredient with the unit last: "Flour: 1.25 cups", "Salt - 0.50 tsp", and a quantity cell on its own line from a recipe card table ("1.25 cups" on one line, "flour" on the next).
- Punctuation after the unit: "1.25 cups, sifted", "2.50 tbsp. olive oil" (period after the unit), "1.25 cups (150 g) flour" (opening parenthesis is not a letter), "0.75 tsp; divided".
- A stop word after the unit: "1.25 cups for the dough", "2.50 tbsp at room temperature", "1.50 oz from a block", "0.50 cup on the side".
- A digit after the unit: "1.25 cups 300 ml" in dual-unit lines.

Only two-place decimals are affected. "1 cup", "1/2 cup", "1.5 cups", "2 tbsp" and every line with a whole-number or one-place amount are unaffected. Harm to reading: Claude loses that ingredient line from the page, so the ingredient may be missing or lack its quantity when the same item is not repeated elsewhere (many pages repeat ingredients in the method, which softens it). Not a privacy leak; it errs toward sending less. QA already accepted this, so no action.

Verdict: accepted. Rows closed: the recipe-path guard raised on #776 (with the fail-closed side effect above); "eggs 4.99 at costco" place phrase; G56 engine half beyond the Cook key (start and resume refuse, Bar line, QA on #783 and #788); the stocked-tomorrow context (QA on #780); training loads in side facts (QA on #785).

## 3. #783 (G56 cook guard, engine half)

Changes: `StartCooking.workoutRunningLine` and `.workoutRunningReason` ("Workout running."); `StartCooking.apply` throws before any write if any process is running whose subject is a workout.

| Clause | Verdict | File:line | Covering test |
|---|---|---|---|
| Ruled K87.6: with a workout running, the Cook key starts nothing and reads "Workout running." | PASS (engine); the line text is the constant | CK:110-112, CK:126-135 | `cookingRefusesWhileAWorkoutRuns`, CT:53 (asserts the error, `workoutRunningLine == "Workout running."`) |
| Nothing written: no cook object, op count unchanged | PASS | CK:126-135 (throw before the "already cooking" branch and before any create) | CT:53 (`store.objects(of: cookClass).isEmpty`, op count equal) |
| The workout is not suspended; its last-touched time is unchanged | PASS | same | CT:53 (`running()` still the workout, state running, `lastTouchedAt` equal) |
| Guard covers a workout subclass | PASS | CK:130-133 (`ClassResolver.isSubclass`) | no test of a subclass |
| Once the workout is set aside, cooking works as before | PASS | CK:126-135 | CT:53 (suspend, then `StartCooking` makes the running subject the cook) |
| Resuming a set-aside cook while a workout runs is also refused | NOT BUILT in #783 (the `StartCooking` guard precedes the "already cooking" resume, so it is covered there; `ResumeProcess` and `StartProcess` came in #792) | CK:126-135, PA:150 | `nothingElseStartsOrResumesWhileAWorkoutRuns`, CT:80 |
| Guard duplicated rather than shared with the #792 helper | NOTE (low; two copies of the same test, `StartCooking` inline and `refuseWhileWorkoutRuns`) | CK:126-135, PA:247-258 | none needed |
| The Cook key shows the line in the app | NOT BUILT in #783 (app half is outside this PR; present on master) | `Features/Recipes/RecipePage.swift:419-426` | no test read here |

Verdict: accepted.

## Which open rows each PR closes

| Open row (source) | #787 | #792 | #783 |
|---|---|---|---|
| Known low: at/for/from/on after a unit or an amount, measure path Lists:209 (acceptance 774-776-779) | Closes | | |
| Same, amount path Lists:232 (`neverFood` lacked for, from, on) | Closes (by read; no test) | | |
| "eggs 4.99 at costco" keeps "at costco" (coordinator note) | Partly (version in #787 left it) | Closes | |
| Recipe wall has no thing-after guard (low on #776) | | Closes (fails closed on unit-last lines) | |
| #759 `kept()` spec: sum-only "$40 at costco", "milk 4.99" -> "milk", amounts keep numbers | Unchanged, still met | Unchanged | |
| Private routine named in the done line (QA on #781) | Closes | | |
| G56 Cook key suspends a running workout, engine side | | Extends (start, resume, Bar line) | Closes |
| G56 app half (the key's line) | | | Not these PRs; code on master at RecipePage.swift:419-426 |
| Stocked cook tomorrow context (QA on #780), set-load side facts (QA on #785) | | Closes | |

## Still open

- Test gaps: no test for the Lists amount path with a unit after the amount ("1.25 lb for dinner", "1.25 lb on sale", "1.25 lb from costco"); no test for a recipe line with the unit last ("Flour: 1.25 cups") although the fail-closed behavior is intended; no subclass-of-workout test for the cook guard; no assertion on the exact kept text in `aWordAfterAPriceIsNeverTheThing` (digits-only check).
- The place phrase rule eats to the end of the line ("milk 3.49 on sale, bread" loses "bread").
- "Private workout" is applied only in the done line; other surfaces that print a routine title are not covered by this work.
- Not touched by these PRs, still open from the earlier lists: G54 (link on Paste never read), G57 (portion drum stops at 12), G58 (swipe to Groceries failure), G59 ("Untitled recipe", first line as title), G60 (decimal hours, raw day count), G43 app half, G44 stale shop, K87 Add-line receipt on Groceries if not yet merged, empty-shelf Tess line K30.1 if not yet merged.
- Recipe path: "milk 3.49 gallon" in page text is now dropped, as intended; confirm on the phone that a short ingredient list does not look thin (below).

## Phone only

- Groceries Add line: "eggs 4.99 at costco" lands as "Eggs, on Groceries." with no place in the item; "milk 3.49 gallon at costco" stays out of the list (private note); "eggs at costco" and "2 lemons for the tacos" land whole.
- Lists Add line: "1.25 lb for dinner", "1.25 lb on sale": expect the amount path to wall them; this has no test.
- Finish a workout from a routine you renamed "Knee rehab day": the done line reads "Private workout done, N of M exercises."; a plain routine name still prints.
- Cook key on a recipe page, then the Bar ("cook carbonara") with a workout running: both read "Workout running."; the rest timer and Live Activity do not change; no UNDO. Set the workout aside and the cook starts.
- Read a recipe link whose page has "Flour: 1.25 cups" and "1.25 cups flour": only the second reaches Claude; check the result still has flour.
- Reduce Motion, Dynamic Type and VoiceOver on the Cook key line.

## Verdict per PR

- #787: accepted. Two reads without a test: the amount-path stop list (Lists:247-250) and the greedy phrase strip.
- #792: accepted. The fail-closed unit-last case has no test (low).
- #783: accepted.
