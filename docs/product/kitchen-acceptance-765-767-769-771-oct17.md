# Kitchen acceptance of #769, #770, #771, #765 and #767: static read

Static only, against origin/master c333e0e (nothing built or run; no Swift toolchain). All five PRs are on master: #769 f81c2ab, #770 c40f96c, #771 0c0261e, #765 84624b0, #767 c333e0e. "PASS" means the clause is met by the code at the line given; every test named was read, none was run. Section 3 is read row by row against `docs/product/kitchen-test-specs-wall-g40-g43-g44-oct17.md` (B1 to B3); section 4 against `docs/product/kitchen-gap-hunt-8-recipes-oct17.md` (G51 to G61), `docs/product/lists-acceptance.md` section 13 (sheet 87: Lists and Recipes fronts) and K30.1; section 5 against G52 and G61 (K87.2, K87.11). Sheet 87's own file is not in the repo; rows 13.11 to 13.15 are its stand-in.

Refs: GV = `Features/Groceries/GroceriesView.swift`, GW = `Features/Groceries/GroceriesWall.swift`, GT = `TesseraTests/GroceriesWallTests.swift` (struct `GroceriesAddWallTests`), Core = `TesseraCore/Sources/TesseraCore`, Tess = `TesseraCore/Sources/TesseraTess`, CT = `TesseraCore/Tests/TesseraCoreTests/GroceriesWallTests.swift`, LL = `TesseraCore/Tests/TesseraCoreTests/ListLookupTests.swift`, SI = `.../ShoppingIdleTests.swift`, ST = `.../ShoppingTests.swift`, RS = `Features/Recipes/RecipesShelf.swift`, RV = `Features/Recipes/RecipesShelfView.swift`, RE = `Features/Recipes/RecipesEntry.swift`, RP = `Features/Recipes/RecipePage.swift`, PR = `Features/Recipes/PasteRecipe.swift`, PK = `TesseraTests/PasteKeyTests.swift`.

## 1. #769 (Groceries Add line follow-up)

| Clause | Verdict | Evidence | Covering test |
|---|---|---|---|
| Strongest reason is spoken (key, then secret, then money) | PASS | GW:`Reason: Int, Comparable` (money < secret < key), `spoken` = `reasons.max()` GW:53-55; used GV:238-239 | `theStrongestReasonIsSpokenAndAKeyNeverReturnsToTheDraft` (GT:38; asserts key line, then secret line with no key). Money-only strongest is covered by `aBareWeightStaysOnThePhone` (GT:54). The test checks `spoken`, not that `add()` calls `say` |
| Closes: mixed-reason block speaks only the first reason | PASS (closed) | GV used `walled.first.reason`; now `spoken(split.walled)` | as above |
| A key line is cleared from the draft for good | PASS on the success path | `heldDraft` drops `.key` lines GW:48-50; GV:235 | same test (draft is "rent $1200, wifi password hunter2"); `theDraftRoundTrips` (GT:62) proves held lines re-split to themselves |
| Key line cleared even when the add fails | FAIL (edge) | GV:228-232 returns before `draft = heldDraft(...)`, so on a failed add the whole typed draft, a key line included, stays in the field | no test |
| A failed add says "Didn't save that. Try again." | PASS (string, draft kept) | GV:229-231 `TessVoice.shared.say(...)` then return; exact text; no clock, no "at" | no test (a throw cannot be forced from a test; `add()` is still private) |
| Closes: ER11 failed add silent | PASS (add only) | as above. check / uncheck / clear / shop start / finish untouched by the diff: still silent | no test |
| Failed add skips the wall line for walled siblings | STILL OPEN (minor) | return precedes GV:238; the draft is unchanged so nothing is lost, but only the failure line is spoken | no test |
| Draft keeps money and secret lines as typed | PASS | GW:49 | `theStrongestReason...`, `theDraftRoundTrips` |
| Sum-only and medicine lines | PASS | `$40 at costco` walled `.money`, `advil` kept (goes on as Private item where shown) | `sumOnlyAndMedicineLines` (GT:48) |
| Bare weight stays on the phone ("82.4" after a weigh-in note) | PASS | walled `.money`, line "That stays on this phone." | `aBareWeightStaysOnThePhone` (GT:54) |
| Closes: add() private so no tests | PARTIAL | the decisions are now two tested static functions (`heldDraft`, `spoken`); `add()` itself, the `say` call, the failure branch and the empty-draft case still have no test | n/a |
| Kept lines: receipt and UNDO ("Milk, on Groceries." with UNDO) | STILL NOT BUILT | GV:223-241 speaks only for walled lines or failure; a successful add says nothing | no test |

## 2. #770 (Core: #763 lows plus G41)

| Clause | Verdict | Evidence | Covering test |
|---|---|---|---|
| '1.25 lb chicken' no longer reads as money | PASS (closed) | `isAmountOfAThing` Core Lists/Lists.swift:174-181: number, unit (kg, lb, g, oz, ml, l), then a word that is not a day, body or weigh word; used at :163-166 so money and bare-weight checks are skipped | `moreAmountsLand` ("1.25 lb chicken", "1.50 lb apples", "2 kg rice"), CT:110 |
| '2 for 1 crackers' tested | PASS (closed) | no sign, word or two-place decimal, so unchanged by `withoutPrice` | `moreAmountsLand` case, CT:110 (asserts one row and `kept` equals the line) |
| Amount kept on the share (`GroceryShare.amount`/`unit`) | STILL WEAK | the new test asserts `rows().count == 1` and the kept string, not amount/unit | no stronger test |
| A weigh-in line is still walled | PASS | "82.4 kg this morning": regex captures "this", a day word, so not an amount | `aWeighInIsStillWalled`, CT:123. A bare "82.4 kg" has no following word so it stays walled by read |
| 'milk 4.99.' (trailing full stop) strips | PASS | EngineWall.swift:75 `[.!]?` | `moreAmountsLand` ("milk 4.99." gives "milk"), CT:110 |
| Second medicine is still "Private item" | PASS | TessCaptureEngine.swift hidden check before the already-on line (lines ~247-250, ~362-382) | `aSecondMedicineIsStillAPrivateItem`, CT:93 ("Private item, already on Groceries.") |
| An ingredient he already has goes through the wall by name (Pantry swipe), said as "Private item" | PASS | `AddGroceries.kept` Core Kitchen/Groceries.swift:502-513, `shown` :494-497 | `aWalledIngredientHeAlreadyHasGoesBackOn`, CT:100 (also asserts an empty store keeps nothing) |
| Note: UI split vs Core kept | NOTE | GW:27 calls `AddListItem.kept`, not `AddGroceries.kept`, so typing such a name on the Add line is still walled; only the Pantry-swipe route gets the exception. UI is stricter, nothing leaks | no test |
| G41: check and move receipts and summaries never name a medicine | PASS (closed) | `AddListItem.shownTitle` Lists.swift:228-229; used by `CheckListItem` summary :262 and receipt :269, `MoveListItem` summary :313 and receipt :317 | `checkingOrMovingAMedicineNeverNamesIt`, CT:127 (no "lexapro" in summary or receipt; receipt "Private item, got"). Move receipt text ("Private item, moved to Pharmacy") is not asserted exactly |
| G41 ruled copy "Private item, got." | PASS | receipt "Private item, got" (the Bar adds the stop) | same test |
| Copy rules in new strings | PASS | "Private item, got", "..., on Groceries", "..., already on Groceries", "Didn't save that. Try again.": thing first with "on", no "at" before a clock. Comments carry "8:55 am", "8:40 am PT" (source only, never shown) | n/a |

## 3. #771 (Core: Lists G40, G43, G44)

Files read: Core `Lists/Lists.swift`, `Kitchen/Shopping.swift`, `Processes/ProcessTable.swift`, `Tess/ObjectPrivacy.swift`; Tess `TessCaptureEngine.swift`, `TessTools.swift`; tests LL, SI, ST (plus the two lines changed in `KitchenCaptureTests.swift` and `KitchenRestoreTests.swift`). #771 touches no app file: `GroceriesView.finishShop` is unchanged.

### 3a. G40, list lookup and repeat name (spec B1)

| Clause | Verdict | Evidence | Covering test |
|---|---|---|---|
| Two lists with the same name: nothing written, "More than one list like packing." | PASS | Tess `TessTools.swift:337-344` (`exact.count > 1` throws `ListLookupLine.moreThanOne`), line text `:392-394` with the full stop | `twoListsWithTheSameNameRefuse`, LL:52 (asserts the text, no item, op and object counts unchanged) |
| Two prefix matches: "More than one list like trip." (ruled wording) | PASS | `TessTools.swift:345-348` | `twoPrefixMatchesRefuse`, LL:63 |
| An exact name wins only when it is one list | PASS | `TessTools.swift:339-342` | `exactNameWinsWhenItIsOneList`, LL:73 (receipt "Adapter, on Trip"; the stop is the Bar's) |
| One prefix match lands; a one- or two-letter prefix never matches; three letters do | PASS | `listPrefixMinimum = 3` `TessTools.swift:354`, used `:345`; miss text "no list called p" `:349` | `onePrefixMatchLands` LL:84, `shortPrefixNeverMatches` LL:91, `uniqueThreeLetterPrefixStillMatches` LL:99 |
| "groceries" keeps meaning the built-in | PASS | one exact match, so `:341` returns it | `groceriesWordKeepsMeaningBuiltIn`, LL:106 |
| His own list titled "Groceries" next to the built-in | NOT PROVABLE | by read it refuses (two exact matches, `:342-344`); the spec says Product has not ruled whether the built-in wins | `hisOwnGroceriesList` LL:113 is `.disabled("G29 vs G40 not ruled")`, so nothing asserts it |
| The refusal never echoes a private word | PASS | `shown` is "that" when `ObjectPrivacy.isPrivateWord` is true, `TessTools.swift:337`; new helper `ObjectPrivacy.swift:74-79` (secret, medicine or body fact). The "no list called ..." line uses the same `shown` | `refusalNamesNoPrivateWord`, LL:121 ("More than one list like that."). Only a medicine word is tried; a secret word has no case |
| Create on a repeat name opens the existing list: same id, no second list, items intact, no create op | PASS | Core `Lists.swift:99-110` (`existing`, case and spaces aside, deleted lists skipped because `ListContents.lists()` drops them), `:126-130` | `repeatListNameOpensTheExistingList`, LL:132 |
| Repeat receipt is not "made" | PASS (wording unruled) | `Lists.swift:141-143`: "Packing, already a list" (the Bar adds the stop). The spec marks this line "Product to rule"; it was built as proposed | `repeatListReceiptIsNotMade`, LL:147 |
| A new name keeps "Packing, made" and the Bar says "Packing, new list." | PASS (closes the 13.2 wording drift) | `Lists.swift:143`; Tess `TessCaptureEngine.swift:417-421` (was "New list: Packing.") | `repeatListReceiptIsNotMade` LL:147, `barNewListSaysNewList` LL:184, `KitchenCaptureTests` line changed to "Packing, new list." |
| A deleted list's name can be made again | PASS | `existing` only sees live lists | `deletedListNameCanBeMadeAgain`, LL:156 |
| Create "Groceries" opens the built-in | PASS | `Lists.swift:105-107` and `:131-133` | `groceriesNameOpensTheBuiltIn`, LL:165 (receipt "Groceries, already a list"). `KitchenRestoreTests` now builds his own "Groceries" through a transaction, as a Shortcut would |
| Bar "new list: packing" twice: no second list, line "Packing, already a list.", no UNDO | PASS | `TessCaptureEngine.swift:349-361` returns a capture with no ops (so no UNDO), and `:417-420` covers the pending path | `barNewListRepeatOpensIt`, LL:173 (asserts empty ops, the line, one list) |
| The `createList` tool puts items on the existing list | PASS (not in the spec) | `TessTools.swift:208-221` | no test |
| New list receipt gets UNDO 4 s (13.2) | NOT PROVABLE | the capture is pending-aware but the hold is the app's | no test |
| Repeat-list line and the Bar line echo the typed name even if private | NOTE | `TessCaptureEngine.swift:359,419` use the typed name; the refusal masks it. 13.9 says a list's own name stays his words, so this is consistent with the sheet, inconsistent with the refusal | no test |
| App test `repeatListLineNamesTheList` in `ListsCopyTests.swift` | NOT BUILT | no app caller of the create action exists, so nothing in the app can say the repeat line today | none |

### 3b. G43, Done shopping (spec B2)

| Clause | Verdict | Evidence | Covering test |
|---|---|---|---|
| One UNDO after Finish brings back the 14 checked rows (same ids, same checked times) and the running shop (same process, next step "Shopping, all in the basket") | PASS | Core `Shopping.swift:61-70` (clear then end, both in one op) | `finishShopUndoBringsBackTheBasketAndTheShop`, ST:59 |
| Pantry's inputs return: cleared rows are soft-deleted, then undeleted | PASS (the data Pantry reads; the Pantry read itself is not asserted) | same | `finishShopUndoRestoresPantryStates`, ST:84. The spec's app-side `undoAfterFinishPutsPantryBack` is not built |
| Receipt "Shopping, finished" (Bar and Voice add the stop); summary unchanged | PASS (wording was a proposal in hunt 7; the spec lists it as not ruled) | `Shopping.swift:76-79` | `finishShopReceiptNamesTheShopFirst`, ST:95 |
| Nothing checked still finishes | PASS | same | `finishShopWithNothingCheckedStillFinishes`, ST:102 |
| Failure writes nothing and throws; no list is made just to finish on | PASS | `Shopping.swift:61-64` guard on the built-in list | `finishShopFailureWritesNothing`, ST:115 (object and op counts unchanged, no running process) |
| The Done key says "Shopping, finished." with UNDO 10 s | NOT BUILT | GV:327-334 is unchanged: `_ = try? model.engine.perform(FinishShop(), by: .user)`, no `TessVoice` line, no op kept for UNDO | none (spec B2 app tests `finishSaysShoppingFinishedWithUndo` not written) |
| A failed Finish says "Didn't save that. Try again." and keeps the basket open | NOT BUILT | GV:329-333 swallows the error, closes the basket (`basketOpen = false`) and bumps `finished` (the finish haptic fires) on a failure too | none (`finishFailureSaysDidntSaveAndKeepsTheBasket` not written) |
| Finish line names no Private item | NOT PROVABLE | nothing is spoken yet | none |
| Bar phrase for Finish | NOT BUILT (not in the spec) | no `FinishShop` use in Tess | none |

### 3c. G44, a shop goes idle (spec B3)

| Clause | Verdict | Evidence | Covering test |
|---|---|---|---|
| Idle length is a named constant, 12 h | PASS | Core `ProcessTable.swift:16` (`Limits.idleShop`) | `idleLimitIsTwelveHours`, SI:25 |
| A running shop untouched past 12 h is suspended by the system, at its last real touch | PASS | `ProcessTable.swift:89-103` (the shop is the process whose subject is the built-in list; the suspend uses `running.lastTouchedAt`, actor `.system`) | `runningShopGoesIdleOvernight`, SI:29 |
| Just under 12 h stays running | PASS | `:101` strict `>` | `shopTouchedRecentlyStaysRunning`, SI:41 |
| Checking a row resets the idle clock | PASS | `Shopping.swift:84-95` and `Lists.swift` (`CheckListItem` passes `time ?? .now`) | `checkingARowResetsTheShopIdleClock`, SI:47 |
| The basket is kept (checked, not deleted, same shop line) | PASS | suspend touches only the process | `idleShopKeepsItsBasket`, SI:56 |
| Start Shop resumes the same process | PASS | existing path | `idleShopResumesWithStartShop`, SI:66 |
| Workout idle rule unchanged (rest-based limit) | PASS | `ProcessTable.swift:92-94` | `workoutIdleRuleUnchanged`, SI:74 |
| Put away after 7 days with a basket: "Shopping moved to Later. 12 in the basket." (ruled), no UNDO, no item name | PASS | `ProcessTable.swift:118-146` (count taken before the end; `shopBasketCount` `:148-151`), line at `:132` | `putAwayShopNoteCountsTheBasket`, SI:86 |
| Put away with nothing checked keeps "One thing moved to Later." | PASS | `:131-135` | `putAwayShopWithNothingCheckedKeepsTheGenericNote`, SI:96 |
| Put-away rows are not dropped (still checked, still live) | PASS (whether the basket counts as bought is unruled) | `EndProcess` only | `putAwayShopKeepsRowsForPantry`, SI:103 |
| The app calls the idle check with the shop in mind | PASS by read | App `AppModel.swift:381-391` (`tidyProcesses` on launch and foreground; Core picks the shop limit itself, so the workout's rest-based limit is not passed to a shop). It is skipped while the workout cover is up, which cannot hide a shop because only one process runs | no test (`idleCheckRunsOnForegroundAndLaunch` not written) |
| Home reads an idle shop as "paused", not "at the store" | PASS by read (existing code) | Core `Home/HomeLines.swift:335-336` ("A paused shop is him at home") | no test for a shop (`idleShopReadsPausedNotAtTheStore`, `runningShopStillReadsAtTheStore`, `idleShopLineNamesNoPrivateItem` are not in `HomeDataTests`) |
| Home shows the day word with "paused" and lowercase clocks | NOT PROVABLE | needs a run with the demo clock past 12 h | no test |

### 3d. Other #771 checks

| Clause | Verdict | Evidence | Covering test |
|---|---|---|---|
| No key-shaped literal in the new tests or sources; no key fixture needed | PASS | a search of LL, SI, ST and every changed source for the Claude key prefix finds nothing. #771 adds no key case (the wall's key case is in section 1's area, built at run time elsewhere) | n/a |
| Copy rules in new strings ("Shopping, finished", "..., already a list", "..., new list.", "Shopping moved to Later. 12 in the basket.", "More than one list like trip.") | PASS | thing first, no "at" before a clock, no banned words | n/a |
| Two KitchenCapture and KitchenRestore test edits are only wording and fixture changes | PASS | diff of both files | those tests |

## 4. #765 (Recipes shelf, sheet 87)

Files read: RS, RV, RE, RP (its changed lines), PR (changed line), HomeSpatialView (`.recipes` now opens the shelf, `:357`); tests `TesseraTests/RecipesShelfTests.swift` (RST) and `RecipeTitleWallTests.swift` (RTW). The shelf is data in RS and a view in RV.

| Clause | Verdict | Evidence | Covering test |
|---|---|---|---|
| G51 / K87.1: Recipes opens a shelf of all recipes, newest first; a row opens its page | PASS | RS:28-29 (live recipes, `createdAt` descending); RV:55-56 (`NavigationLink` per row), RV:11 (destination `RecipePage`); `HomeSpatialView.swift:357` | `aPrivateRecipeIsOnlyPrivateRecipeAndCounted`, RST:34 (asserts the order) |
| Private recipe reads exactly "Private recipe" in its row | PASS | RS:30-33 uses the recipe-title wall and the shared label; RV:60 draws it at 66% ink | RST:34 ("Rent 1200 stew" becomes "Private recipe", no "1200" in any row) |
| Private recipe is counted but never named: "38 recipes, 2 private" | PASS | RS:40-44 | `contextCounts` RST:51, RST:34 ("2 recipes, 1 private") |
| Private recipe in Tess's line | PASS by read | RS:46-54 use the masked row name | no test for a private name in a Tess line |
| Private recipe in VoiceOver | PASS by read | RV:75 label is the masked name plus the day | no test |
| The recipe page for a private recipe opened from the shelf still reads "Private recipe" | PASS by read (closed earlier by #752) | `RecipeCopy.shownTitle` in RP | RTW `aPrivateTitleIsMaskedUntilShown` |
| ‹ KITCHEN back word, title "Recipes", context line | PASS | RV:27-42; the back word is uppercased in the view only | none |
| A name over 30 characters wraps, never cut; rows at least 44 pt | PASS by read | RV:61-62 (`fixedSize` vertical), RV:66 (`minHeight: 48`) | no test; AX3 is phone only |
| Day at the right of each row | NOT PROVABLE | RS:34 writes the day of the last cook ("today", "Tue", "Oct 3"); a recipe never cooked shows none. Neither the sheet text nor decisions say whether the day is the last cook or the day saved, so the rows cannot be judged | none for `day` |
| Empty: context "None yet" and "No recipes yet." at 66% | PASS | RS:41, RV:47-49 | `emptyIsNoneYet`, RST:30 |
| Empty: Tess says "Paste a link or a page and I'll read it." (K30.1, 13.12) | NOT BUILT | RS:46-54 returns nil with no recipes, so RV:87-89 says nothing | RST:30 asserts `tess == nil` on an empty shelf, which pins the opposite of K30.1 |
| One recipe: "1 recipe" and Tess "Tacos, cooked 2 times." | PASS | RS:47-49 | `tessLines` RST:42; `contextCounts` RST:51 |
| Many recipes: "X is the one you cook most." only for a clear top with more than 1 cook | PASS (wording is the builder's; the sheet text is not in the repo) | RS:50-53 | `tessLines` RST:42 (Tacos 2, Dal 0). The 1-cook and tie cases have no test |
| Top-left "Recipes" on the page returns to the shelf; "Back to the list" on a gone recipe returns to the shelf | PASS by read | the page is pushed on the shelf's stack, so `dismiss()` (RP:51, RP:168) pops one level | no test |
| Close stays the only exit to Home | NOT PROVABLE | the shelf's "‹ Kitchen" also closes the cover (RV:27); the cover's own Close is in `HomeSpatialView` | none |
| Other doors to Recipes still use the old single-page opener | NOTE | `App/TesseraApp.swift:61` and `RecipeView` (RE:7-46) remain; the Home link no longer reaches them | `RecipesOpeningTests` cover only the opener |
| 13.7 shelf and recipe rows have no swipe | PASS | RV:55-76 has no swipe action | none |
| 13.13 Recipes side (ITS OBJECTS: newest, most used, kept private count) | NOT BUILT | RV header comment says it waits on the side host | none |
| 13.14 Reduce Motion crossfade, haptic, AX3 one column | NOT PROVABLE | rows use `.entrance`; nothing checked beyond RV:66 | none |
| 13.15 copy sweep for the new strings | PASS | "None yet", "No recipes yet.", "1 recipe", "Private recipe", "..., cooked 2 times.": no "at" before a clock, digits for counts | n/a |
| G52 / K87.2: the receipt names the short thing first ("Sheet-pan paprika chicken, on Recipes.") | PASS for the cut words; PARTIAL against the proposed rule | RP:432-446 (`shortName` cuts at " with ", ", ", ": ", " (" and dashes; the proposed rule's 6-word cap is not built, so a long title with none of those stays whole) | `pastesReceiptNamesTheThingFirst`, RTW:44-52 ("Chili con carne" and "Mac and cheese" stay whole) |
| Private recipe paste receipt: "Private recipe, on Recipes." | PASS | PR:28-31 masks before `saved`; PR:106 | RTW:44-52 (title "Rent 1200 stew"). A secret-word title has no case |
| G52(b): UNDO holds 4 s (10 s under VoiceOver) before the page moves on | PASS by read | PR:232 (`TessVoice.hold(undo: true, holds: .seconds(4))`, `HomeQueue.swift:45-51`) | no test (a timer in the view) |
| G52(a): the first recipe pasted keeps its receipt and UNDO | PASS by read (#765 changed RE) | RE:14, RE:24-36: the page stays on Paste until Paste says it is done | no test |
| G52(c): after the page opens, back never shows the paste screen's saved bar | FAIL (still open, by read) | `PasteRecipeView` (RE:76-87) still pushes the page on the paste stack and the paste view keeps its `saved` state, so "Recipes" on the page pops back to the paste screen with "X, on Recipes." and a live UNDO that deletes a recipe he has read | no test |

Rows from `kitchen-gap-hunt-8-recipes-oct17.md` not touched by #765 (read, unchanged on master): G54 (RP and PR: no link path), G56 (no "Workout running."), G57 (`PortionDrum.swift:9` still 1 to 12), G58 (`RecipePage.swift:221` still `try?`), G59 ("Untitled recipe" still `RecipeParser.swift:109`), G60 (`RecipePage.swift:492` decimal hours, `:502` "N days ago"). G53 stays closed (#752, #760). G55's ruled part stays closed (#752); the Tess phrase route is still open.

## 5. #767 (G52 and G61, key cut from a recipe paste, the rest kept)

Files read: PR, `TesseraCore/.../Diagnostics/ClaudeKeyGuard.swift`, PK. `TessTools.swift` is not in #767; it has no key code and the Bar's key line (`claudeKeyLine`) is the same shared constant the Paste screen now uses.

| Clause | Verdict | Evidence | Covering test |
|---|---|---|---|
| The line points at Review, not Settings (G61 first half) | PASS | PR:37 draws `claudeKeyLine` ("That looks like a Claude key. It goes in Review, under Claude." from `ClaudeKeyGuard.swift:4`); the old Settings sentence is gone | `theLineSaysReview`, PK:20 (asserts "Review") |
| A key inside a long recipe is cut out and the rest kept (G61 second half, ruled 8:20 am) | PASS | PR:123-130 (`.cut(kept)` assigns the kept text); cutter PR:423-426 over Core `withoutClaudeKeys` | `theKeyGoesAndTheRecipeStays`, PK:12 (title, ingredient and step lines survive; no key run left) |
| A key alone leaves an empty box | PASS | PR:423-426 | `aKeyAloneLeavesNothing`, PK:17 |
| A key wrapped across lines comes out whole, tail included | PASS | `ClaudeKeyGuard.swift:28-30` (`keyWithTail`) | `aKeyWrappedAcrossALineComesOutWhole`, PK:36 |
| Anything still key-shaped after the cut empties the box rather than leaks | PASS (this wipes the rest, an accepted edge) | PR:423-426 | not isolated by a test |
| The line stays up across the cut's own change, and the kept recipe is read | PASS (state machine) | `PasteKeyFilter` PR:394-418: `.cut`, then `.keptAfterCut(read: !new.isEmpty)`, then `.plain` | `theKeyLineSurvivesTheCutsOwnChange`, PK:26. The `onChange` wiring at PR:123-141 is not under test |
| The key is never read: no read() on the cut itself | PASS | PR:123-130 (`.cut` does not call `read()`) | no wiring test |
| The key is never saved, logged or placed in the original text or a capture-miss row | PASS by read | `save()` (PR:210-238) and the miss row take `text`, which is the cut text; `CaptureMissLog` also refuses key-shaped text in Core | no test |
| The key never shows in the box | NOT PROVABLE | the box holds the pasted text for the frame before `text = kept` lands | phone only |
| Hold the save while a key is in the box | PASS (taken as: the key is gone at once, so a save always sees clean text) | PR:123-130 | no test |
| Key fixtures are built at run time, no key-shaped literal in any file | PASS | PK:9-10 and PK:37 join two short strings; a search of every #765 and #767 file for the Claude key prefix finds nothing; the fixtures do match `looksLikeClaudeKey` only once joined (PK:12 asserts the guard sees the pasted shape) | PK |
| G52(b) UNDO window and short-name receipt | PASS (counted in section 4) | see section 4 | |
| G52(c) back from the page shows the paste screen's saved bar | FAIL, still open | see section 4 | none |

## 6. Earlier open items, updated

Closed by #769: mixed-reason block speaks one reason (now the strongest); key line cleared for good (success path); ER11 failed add silent (add only).
Closed by #770: '1.25 lb chicken'; '2 for 1 crackers' tested; G41 check/move receipts.
Closed by #771: G40 (lookup refusal, prefix floor, repeat list opens the existing one, Bar "Packing, new list."); G43 and G44 in Core.
Closed by #765: G51 (the shelf and its door, "Back to the list" to the shelf by read); the shelf's private row, count and Tess line.
Closed by #767: G61 (Review line, key cut, rest kept); G52(a) and (b) (the first recipe keeps its receipt and UNDO, 4 s, short name).

Still open:
- App half of G43: the Done key is silent, has no UNDO and no failure line (GV:327-334); the app tests `finishSaysShoppingFinishedWithUndo`, `finishFailureSaysDidntSaveAndKeepsTheBasket`, `undoAfterFinishPutsPantryBack`, `finishLineNamesNoItem` are not written.
- G44 app tests (`idleShopReadsPausedNotAtTheStore`, `runningShopStillReadsAtTheStore`, `idleShopLineNamesNoPrivateItem`, the wiring test) are not written; the behavior is read as correct.
- G40 leftovers: his own "Groceries" next to the built-in is unruled and its test is disabled; the repeat-list line "Packing, already a list." and "Shopping, finished." are built as proposals; no app test for the repeat line.
- G52(c): back from the recipe page shows the paste screen's saved bar with a live UNDO (PasteRecipeView); the 6-word cap on the short name.
- #765 gaps: empty-shelf Tess line (K30.1, and the test pins nil); the Recipes side (13.13); which day the row shows; Reduce Motion and AX3 unproved; shelf has no test for the day, a private name in Tess, or a 1-cook shelf.
- Receipt and UNDO for kept Add-line rows (K87, K36.2); `add()` has no outcome test; failed add leaves a key line in the field and skips the walled sibling line; ER11 for check, uncheck, clear done and shop start; amount/unit assertion on the share.
- G54, G56 to G60 untouched (see section 4).

## 7. Gap rows

| Gap | Status | Why |
|---|---|---|
| G40 | CLOSED in Core (two unruled lines noted) | sections 3a; app has no create caller |
| G41 | CLOSED (#770) | section 2 |
| G43 | OPEN: Core done, app NOT BUILT | Done key unchanged, GV:327-334 |
| G44 | CLOSED in Core and by read in Home; app tests missing | section 3c |
| G51 | CLOSED for the shelf and the door; empty Tess line and the side open | section 4 |
| G52 | PARTLY CLOSED: (a) and (b) done, (c) FAIL | sections 4 and 5 |
| G53 | CLOSED (#752, #760) | earlier docs |
| G54, G56, G57, G58, G59, G60 | OPEN | untouched |
| G55 | ruled part CLOSED; Tess phrase route OPEN | earlier docs |
| G61 | CLOSED | section 5 |

## Phone only

- Strongest reason: Groceries Add, paste "rent $1200", then a wifi password line, then a key-shaped line on three lines, press Done: the line reads the Claude key line, the key is gone from the field, the other two stay.
- Without the key: the same two lines say "That one stays out of Groceries."
- Amounts: add "1.25 lb chicken" and "2 for 1 crackers": both land as rows; "82.4 kg this morning" stays in the field with "That stays on this phone."
- G41: add "lexapro" to a list, check it, move it to an aisle: the receipts read "Private item, got" and "Private item, moved to ...".
- Failed add cannot be forced by hand; leave it to a test.
- Lists: say "new list: packing" twice: first "Packing, new list." with UNDO 4 s, then "Packing, already a list." with no UNDO. Make two lists named alike through a Shortcut, then "add sunscreen to packing": "More than one list like packing."
- Groceries: start a shop, check a row, leave the app 13 h (or move the demo clock): Home reads "paused" with a weekday word, not "at the store". Put it away at 7 days: "Shopping moved to Later. 12 in the basket." appears once.
- Groceries: press Done with a full basket: today nothing is said and no UNDO exists (G43 app half).
- Recipes: Kitchen page, Recipes: the shelf lists newest first; a private recipe reads "Private recipe" at 66%; a title over 30 characters wraps; the page's Recipes word returns to the shelf; "Recipe gone." returns to the shelf; the empty shelf shows no Tess line (K30.1 wants one).
- Paste: save the first recipe, then the fifth: "Shakshuka, on Recipes." with UNDO holding 4 s (10 s with VoiceOver), then the page opens. From "Paste a recipe", save, let the page open, press its Recipes word: the paste screen shows the old saved bar with UNDO (G52(c) FAIL).
- Paste a 20-line recipe with a key-shaped string in the middle: the string vanishes, the recipe stays and reads, the line says "It goes in Review, under Claude."; check the key never shows in the box for even a frame.
- Reduce Motion, Dynamic Type AX3 and VoiceOver on the shelf rows (13.14).
