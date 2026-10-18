# Pantry v2 fixtures (Kitchen gap hunt 12, PR #896, rulings R1 to R20)

For: Core (state, events, grammar, missing), Builder B (Pantry and Recipes screens), Design and Product (questions at the end), QA. Docs only; nothing was built or run (no Swift toolchain). Written Sat Oct 17 (revised Sat Oct 17, PDT) from `docs/product/kitchen-gap-hunt-12-pantry-v2-spec-oct17.md` (the spec, 410 lines, merged by #896), `qa/review-896.md`, the decisions entry "4:30 pm PT Oct 17 (Kitchen #896 gap hunt 12, Pantry v2 spec: R1-R20)" (decisions.md line 957), and origin/master at `0d81f1a3` (read with `git show origin/master:<path>`; the worktree's own checkout is one merge older and no Pantry file differs).

Revision 3 (Sat Oct 17 PDT, Kitchen walk script gaps G172, G173, G175, G180 and Product's 6:39 pm rulings of Oct 17): rows PD33 to PD35 added (the three spec tests that had no row); the 118 distinct test names (116 tests plus 2 pointers) are published in section 13; PE is the eighth group (acceptance, run after the seven); a tie that changes nothing writes nothing and shows no receipt; the peek word `used` reads `lastUsedAt`; the ochre is gone from Pantry (the state word is plain ink; Reading B `areaLean` `#126E52` on Porcelain and `#72DCB1` on Obsidian only on the caps labels and index line, per the 6:43 pm correction); wording slips and skipped ids fixed. Rows PD09, PD31, PE15, PW19, PO01, PO02, PO06, PO07, PP08 and PE18 (wording) changed; PR26 to PR29 added. No receipt string changed.

Revision 2 (Oct 17, after QA's PASS WITH NOTES on #902): QA's four notes fixed and Product's 4:32 pm rulings applied (tie rule, `pantryBackfilled`, Egg/Eggs fold, 118 names, test rewrite). No receipt, hero or other user-facing expected string changed; only the logic and marker wording of rows PB06, PB08, PB09, PB13, PE15, PE19 moved. The new boundary row PP17 and the new rows PD31, PD32, PB19, PB20 are additions.

Status words: **traced** means I read the master line and it does what the row says; **inferred** means the row follows from the spec or from code I did not read in full; **gap** means master has nothing for it (not built) or contradicts it. Owners: **Core**, **Builder B**, **Design**, **Product**, **QA**. All names, amounts and dates are made up. No key-shaped value appears in this file; where a secret tail is needed the row says "a Claude-key-shaped tail" and the test builds it at run time.

## 0. What the rows rest on

| Fact | Evidence |
|---|---|
| The catalog package is version 9. The ruling puts the Pantry fields on the bump AFTER v10 ("v11 with the Habit/imagery work, one bump, never a renumber"). v10 is not on master, so a test must not hard-code 10 or 11 until the numbers land; it asserts "greater than the previous package version, and the Pantry fields exist". | `TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift:350` (`version: 9`); decisions.md:957 |
| `Ingredient` has only `aisle` and `isStaple`. No `state`, `stateAt`, `lastBoughtAt` (on the Ingredient), `usualSkippedAt`, `PantryBook`, `PantryState` or `hasAnyState` exists in Swift on master (grep). | `SystemCatalog.swift:280-284`; grep of `*.swift` |
| `PantryLedger` is app-side, `@MainActor`, read-only. It derives state from `Groceries.shopClears()` plus `putAwayBasket()` (`.have`) and from every finished cook (`.low`, Produce `.out`); latest event wins, at the same instant the surer state wins (out, low, in). | `Features/Kitchen/PantryLedger.swift:115-143`, `:146-161`, `:131-133` |
| Ledger staple test is the field OR `AisleGuide.isStaple`; the recipe page line reads only the field. | `PantryLedger.swift:172-175`; `Recipes.swift:96` |
| `AddRecipeToGroceries` skips staples, to-taste and optional lines and a line covered by a checked row. | `TesseraCore/Sources/TesseraCore/Kitchen/Groceries.swift:454-462`, `:487-500` |
| `FinishShop` and the generic `ClearDoneItems` both go through `Transaction.clearDone(in:)`, which has no pantry hook. `FinishCooking` writes `cookedAt`, ends the process, stops timers; nothing about ingredients. | `Kitchen/Shopping.swift:60-70`; `Lists/Lists.swift:456-505`; `Kitchen/Cooking.swift:287-303` |
| Words built app-side: hero, context line, Tess cook line, `Milk, on Groceries.` and the already lines. | `PantryLedger.swift:72-79`; `PantryCopy.swift:8-39`; `PantryFront.swift:36-43` |
| The swipe receipt holds 4 s with UNDO; one app-wide UNDO slot (`TessVoice`); a note with UNDO holds 10 s unless `holds` is given; under VoiceOver any UNDO is a flat 10 s. `UndoCopy.takenBack` cuts the receipt at the first ", ". | `PantryView.swift:119`; `Features/Home/HomeQueue.swift:43-52`; `Features/Command/BottomChrome.swift:763-767` |
| `parseKitchen` has no out-of, low-on, have or pantry rule; the task guard is at line 34, the for-groceries rule at 43, buy/get at 49. | `TesseraCore/Sources/TesseraTess/TessGrammar+Kitchen.swift:17-76` |
| Before #917 (be05f0b6) the ochre was still in the app: `light = 0xA4601A`, `dark = 0xE3A857`, `stateWord = ochre.mix(with: ink, by: 0.28)`, used at the state word. `areaLean` does not exist on master. | `Features/Kitchen/PantryColour.swift:8-18`; `PantryView.swift:196`; swipe-lean fixtures section 4 (AL15, AL16, AN08) |
| Master still carries tap-to-reveal code (`ShopTrip.revealed`) and its hint copy on Groceries, Lists and the recipe page. The 4:20 and 4:25 pm Oct 17 ruling (G102) removes tap-to-reveal on all four surfaces: a private row always reads its "Private ..." label and one tap does the row's normal action. Pantry never had a reveal. | `Features/Groceries/ShopTrip.swift:15,24,43`; `GroceriesView.swift:526`; `ListsView.swift:364`; `RecipePage.swift:81,471` |
| Product's 4:32 pm Oct 17 rulings on this file (decisions.md, line 965), applied here: (1) tie rule, one rule for backfill and live writes: at an equal timestamp the surer state wins (out over low over in), and an older timestamp never overwrites a newer one; the spec's "neither overwrites an equal timestamp" line is replaced. (2) The backfill marker is the Settings key `pantryBackfilled`, set when the one-time backfill finishes, never inferred from "any ingredient has state". (3) Duplicate keys (Egg/Eggs) fold to one key through the normalizer Groceries uses (`IngredientLine.key(for:)`, `Quantities.swift:283`); the latest timestamp wins, ties by rule (1). (4) 118 distinct test names, not 124. (5) `PantryLedgerTests`, `PantryFrontTests` and `GroceriesFinishTests.undoAfterFinishPutsPantryBack` are rewritten for stored state when Core builds it; no test hard-codes a catalog number. | decisions.md:965 |
| Pantry's own wall is `ObjectPrivacy.isPrivateRecipeTitle(title, lastWeightKg:)`, the call the ledger makes for labels. | `PantryLedger.swift:166`; composed text rule `Export/PrivateWords.swift:21` |

Cross-reference: the swipe-lean fixtures are merged (#897) at `docs/research/fixtures/gaps-92-swipe-lean.md`. Row-id prefixes: **PD** derivation, **PB** backfill, **PG** grammar, **PW** state words, **PP** private items, **PO** ochre, **PR** ruling index, **PE** edge cases. The seven groups are PD, PB, PG, PW, PP, PO and PR; PE is an eighth group and is acceptance, run after the seven (Product, 6:39 pm Oct 17, G177). The ids are not contiguous: in PG the ids PG28, PG29, PG38 and PG39 were never issued (the numbering jumped when 3a, 3b and 3c were split and no row was written under them; nothing was deleted), and PP17 sits above PP16 because it was added late. Nothing is renumbered, so ids quoted in reviews and the Kitchen walk script stay valid. They never collide with the spec's clause ids (S, E, V, U, M, C, F, P) or `pantry-78.md` (P1 to P14).

**Reading the last column.** #896 is docs only (4 files: the spec, a Lists walk, and one-line edits to two acceptance docs; no Swift test code). "The 124 tests" (a count the spec printed; see section 13 for the 118 names) are names the spec lists in its section (e) for Core to write. So "named" below means the spec already gives this row a test name (Core still writes it) and **NEW** means the spec has no name for it, so Core adds one. "Existing" means a test already on master. Product ruled at 4:32 pm Oct 17 that the count is 118 distinct names, not 124 (Q1); the spec's count is corrected and Core writes those 118.

Columns: id | input in plain words | exact expected output | master today (file:line) | status | owner | Swift Testing name | PR #896 spec (clause, named or NEW).

## 1. Derivation: what the pantry computes from groceries, cooks and lists

The v2 pantry stores state, so "derivation" means what each event writes. After the backfill the ledger derivation is deleted, so history edits can no longer rewrite Pantry (fixes G46).

| Id | Input | Expected | Master today | Status | Owner | Test | PR #896 |
|---|---|---|---|---|---|---|---|
| PD01 | Shop clear on Groceries; milk, eggs, rice checked Saturday 10:00 | each ingredient: `state = in`, `stateAt = lastBoughtAt = Saturday 10:00` (the check date, not the clear time) | derived at read time: `PantryLedger.swift:123-126`; `Groceries.swift:169-184` | gap | Core | `aShopClearSetsEachCheckedIngredientIn` | E1, named |
| PD02 | Done shopping (`FinishShop`) with the same three checked | same as PD01, inside the same op as the clear, so one UNDO takes both | `FinishShop` clears only: `Shopping.swift:60-70` | gap | Core | `finishShopSetsCheckedIngredientsInInTheSameOp` | NEW (E1 names only the clear) |
| PD03 | Clear on a Packing list (not Groceries), 3 checked | no ingredient written, no `lastBoughtAt` | `clearDone` has no pantry hook; Groceries test is `list.id == Groceries.listID` at `Lists.swift:501` | gap | Core | `clearingPackingSetsNoPantryState` | E2, named (P-F8) |
| PD04 | Clear: milk was cooked out Sunday 18:00, checked Saturday 10:00 | milk stays `out`; `lastBoughtAt` becomes Saturday 10:00; `stateAt` stays Sunday 18:00 | ledger agrees (latest wins): `PantryLedger.swift:131-133` | gap | Core | `aClearKeepsANewerCookState`, `aClearStillUpdatesLastBoughtAt` | E3, named |
| PD05 | Clear of a backdated row (checked Saturday) when `lastBoughtAt` is already Monday | `lastBoughtAt = max(old, checkedAt)` = Monday | ledger `max`: `PantryLedger.swift:125` | gap | Core | `lastBoughtAtNeverMovesBack` | NEW |
| PD06 | UNDO of a shop clear | `state`, `stateAt`, `lastBoughtAt` return to the values before, with the rows | `finishShopUndoRestoresPantryStates` asserts rows only: `ShoppingTests.swift:84-93`; app test `GroceriesFinishTests.swift:59` | gap | Core | `undoingAClearRestoresPantryState`, `undoingDoneShoppingRestoresPantryState` | E4, named |
| PD07 | Basket put away to Later with 2 checked rows | both ingredients `in`, `lastBoughtAt` = their check dates (counts as bought, Product 9:45 am ruling 5) | `Groceries.swift:135`; ledger `PantryLedger.swift:142` | gap | Core | `aPutAwayBasketSetsTheItemsIn` | E5, named |
| PD08 | A checked row deleted another way (Tess "delete milk", swipe remove), never cleared | no state, no `lastBoughtAt` (not buying) | `shopClears` requires `cleared.contains(item.id)`: `Groceries.swift:177`; test `PantryLedgerTests.swift:139` | traced (read) | Core | `aRemovedCheckedRowWritesNoPantryState` | NEW (write side) |
| PD09 | Finish cooking the tacos (chicken, onion, tortillas, cilantro, limes, salt, "parsley for serving", "pepper to taste") | chicken, onion, tortillas `low`; cilantro, limes `out` (Produce); salt, parsley, pepper untouched; `stateAt = cookedAt`; `lastUsedAt = cookedAt` on each ingredient the cook used up (written in the same cook-finish op, 6:39 pm ruling; whether a staple or an optional line also gets `lastUsedAt` is for Core to say) | ledger: `PantryLedger.swift:146-161`; test `PantryLedgerTests.swift:48` | gap (write) | Core | `finishingTheTacosSetsLowAndOut` | E6, named |
| PD10 | Cook whose only non-staple line is an Aisle-guide staple ("olive oil"), ingredient field `isStaple` false | untouched (one helper: field OR `AisleGuide.isStaple`) | ledger uses both: `PantryLedger.swift:155-156,172-175` | traced (ledger) | Core | `aStapleIsNeverMadeLowByCooking` | E6, named |
| PD11 | Optional line ("jam, optional") and to-taste line in a finished cook | not used up | `PantryLedger.swift:155`; test `PantryLedgerTests.swift:97` | traced (ledger) | Core | `anOptionalLineIsNotUsedUp` | E6, named |
| PD12 | Limes already `out` from a phrase at 20:00; a cook finished at 19:00 is recorded later | limes stay `out`; the older cook does not write (an older timestamp never overwrites a newer one, ruling 1) | ledger latest wins | gap | Core | `anOlderCookDoesNotOverrideANewerPhrase` | NEW |
| PD13 | Cook, then edit the recipe (remove limes) or delete it | stored states unchanged | ledger re-derives from recipe lines, so today an edit CHANGES Pantry (G46): `PantryLedger.swift:149-153` | gap | Core | `editingARecipeDoesNotRewritePantry` | E7, named |
| PD14 | Private recipe finished | state still written; Tess says nothing | read side: `PantryLedgerTests.swift:123`, `PantryLedger.swift:97-100` | traced (read) / gap (write) | Core | `aPrivateCookWritesStateAndSaysNothing` | E8, named |
| PD15 | Cook whose recipe link was deleted | nothing written | `cookUses` skips a deleted recipe: `PantryLedger.swift:151` | inferred | Core | `aCookWithADeletedRecipeWritesNothing` | NEW |
| PD16 | 90 days pass with nothing said | every state, `stateAt`, `lastBoughtAt` identical | time never changes state: `PantryLedger.swift:4-7` | traced (concept) | Core | `nothingChangesNinetyDaysLater` | S5, named |
| PD17 | An ingredient no event has touched | unknown; stored as no value; never written as "unknown" | no field | gap | Core | `anUntouchedIngredientIsUnknown`, `unknownIsNeverWritten` | S2, named |
| PD18 | An ingredient is deleted while `out` | not listed on Pantry; `missing` reads it as unknown | ledger filters `isDeleted`: `PantryLedger.swift:51` | traced (list) / gap (missing) | Core | `aDeletedIngredientIsNotListed`, `aDeletedIngredientIsUnknownToMissing` | S6, named |
| PD19 | Hero for 3 out (one private), 1 low | `3 out, 1 low`; the private line counts as a number | `PantryLedger.swift:72-79`; private lines not filtered `:49-51` | traced | Core | `theHeroCountsPrivateLinesAsANumber` | NEW (P-F2 default keep) |
| PD20 | Hero when things are known but none is out or low; when nothing is known | `Nothing out`; `Nothing yet` | `:78`; test `PantryFrontTests.swift:26` covers `Nothing yet` only | traced | Builder B | `heroIsNothingOutThenNothingYet` | NEW |
| PD21 | "salt" with the ingredient field false on the recipe page | dimmed like Groceries skips it (one helper) | page reads the field only: `Recipes.swift:96` | gap (P-F1) | Core | `saltIsAStapleOnTheRecipePageToo`, `groceriesAndMissingAgreeOnStaples` | S11, named |
| PD22 | `missing` for tacos: chicken in, onion low, tortillas out, cilantro and limes unknown, salt out | out: tortillas; unknown: cilantro, limes; low and in not counted; staple skipped; score 3 | no `RecipeMath.missing` | gap | Core | `missingGivesZeroOneAndOneToCheck` (PA Core 5 seed cases, not re-read here) | M1, named |
| PD23 | Same ingredient on two lines (butter in sauce and topping), butter out | counted once | none | gap | Core | `aRepeatedIngredientCountsOnce` | M5, named |
| PD24 | A line with no linked ingredient | skipped (Groceries does the same) | `Groceries.swift:454` | gap | Core | `aLineWithNoIngredientIsSkipped` | M5, named |
| PD25 | Recipe scaled 4 to 8 serves | `missing` identical | none | gap | Core | `scalingNeverChangesWhatIsMissing` | M6, named |
| PD26 | Planning a recipe: chicken in, lemon low, yogurt out, 4 others unknown (7 wanted lines) | 6 rows added (every wanted line except chicken); peek key `ADD 6 TO GROCERIES` equals the dry run | no in-skip: `Groceries.swift:454-462` | gap | Core | `paprikaChickenWithThreeKnownStatesGivesAdd6`, `theKeyCountEqualsTheRowsAdded` | F1, named |
| PD27 | Planning a recipe where every non-staple line is in | no write, no UNDO (the nothing-to-add path) | `Groceries.swift:465-467` | gap | Core | `planningWhenEverythingIsInAddsNothing` | NEW |
| PD28 | A line that is both in and covered by a checked row | skipped once; the in-rule sits after the covered and checked-row rules | `Groceries.swift:458-462` | gap | Core | `theInRuleComesAfterTheCheckedRowRule` | F2, named |
| PD29 | CAN COOK with 3 recipes scoring 0, 0, 2 | `2 you can cook now` (score 0 only) | none | gap | Core | `theCanCookCountIsScoreZero` | C2, named |
| PD30 | CAN COOK sort: A one unknown (never cooked), B one out (cooked last week), C one out (never cooked) | order A, C, B: (score, out.count, oldest cook; never cooked first) | none; no `lastCooked` helper | gap | Core | `oneUnknownOutranksOneOut`, `neverCookedComesFirstInATie`, `canCookRanksByMissingThenNotCookedLately` | C1, named |
| PD31 | Live write on an equal timestamp: milk is `in` at Saturday 10:00 (a clear), a cook or phrase says `out` at Saturday 10:00; and the reverse order | milk is `out` both ways; at an equal instant the surer state wins (out over low over in), whatever the arrival order; `stateAt` unchanged. Second case, a tie that changes nothing: milk is `low` at Saturday 10:00 and a phrase says `in` at Saturday 10:00 (or the reverse of any pair where the stored state is already the surer one): milk stays `low`, no write, no op, no receipt, no haptic, no UNDO slot taken, `stateAt` unchanged (Product 6:39 pm Oct 17, G178; closes the open part of Q4) | live writes were "nil or earlier" in the spec (neither overwrites an equal time); ledger `PantryLedger.swift:131-133` already gives the surer state | gap | Core | `anEqualTimestampGoesToTheSurerStateInAnyOrder` | NEW (4:32 pm ruling 1 and 6:39 pm G178; replaces the spec E3 equal-time line) |
| PD32 | Live write that is surer but older: milk `low` at Sunday 18:00, a clear checked Saturday 10:00 says `in` | milk stays `low`; the older timestamp never overwrites the newer, even when the older state would be surer (a backdated `out` over a newer `in` also does not write) | idea mirrored at `Shopping.swift:93-94` | gap | Core | `anOlderTimestampNeverOverwritesANewerState` | NEW (4:32 ruling 1) |
| PD33 | Receipt order for `out of milk` with the row added, and for `out of oat milk` | the thing comes first, then the state, then `On Groceries.` with "on", never "at", the title as stored: `Milk, out. On Groceries.` and `Oat milk, out. On Groceries.`; not `On Groceries: milk` and not `milk is out`; 4 s UNDO (it adds a row) | no rule: falls to `parseCook` / model; compare the swipe wording `PantryCopy.swift:37` | gap | Core | `theReceiptNamesTheThingFirstWithOn` | V8, named (G172; strings copied from the spec receipts table) |
| PD34 | A recipe whose lines are chicken `in`, onion `low`, limes `in`, salt out (staple) | `low` is never missing: out `[]`, unknown `[]`, score 0; the recipe counts in `N you can cook now`; no `1 missing` sub-line and no `1 to check` for the onion; the onion stays `low` on Pantry | no `RecipeMath.missing` | gap | Core | `lowIsNeverMissing` | M4, named (G172; spec M4: "low and in are not counted") |
| PD35 | Plan a recipe with 7 wanted lines: chicken `in`, lemon `low`, yogurt `out`, 4 others unknown | the `in` line (chicken) is skipped; the `low` line (lemon), the `out` line (yogurt) and the 4 unknown lines are added: 6 rows; peek key `ADD 6 TO GROCERIES`; no row named chicken (PD26 checks the count and the key, this row checks which lines) | no in-skip: `Groceries.swift:454-462` | gap | Core | `planningSkipsInLinesAndAddsLowAndUnknown` | F1, named (G172; counts from the spec F1 case D1) |

## 2. Backfill: existing data at first launch of v2

R1 (accepted): backfill once, `.system`, no UNDO. R2: `stateAt` and `usualSkippedAt` ride the same catalog bump. The migration is additive: the catalog seeder adds missing fields to existing classes (`SystemCatalog.swift:385-389`, "Adds fields introduced in later versions"); no GRDB migration is added (v1 to v3 stay, `TesseraDatabaseSchema.swift:34-80`, per the spec). The catalog number is whatever is next after v10 (section 0).

Fixture "tacos week" (the same facts as `PantryLedgerTests.swift:48-70`): Saturday Oct 10, 10:00 a shop clear checks corn tortillas, limes, ground beef, salt; Sunday Oct 11, 18:30 Tacos is cooked (lines: corn tortillas, ground beef, limes, salt, "cilantro to taste", "jam, optional"). Ledger answer: limes out, corn tortillas low, ground beef low, salt in; hero `1 out, 2 low`; `lastBoughtAt` Oct 10 10:00 on all four.

| Id | Input | Expected | Master today | Status | Owner | Test | PR #896 |
|---|---|---|---|---|---|---|---|
| PB01 | Store written by the current build (catalog 9) opened by v2 | the four Ingredient fields exist; every old ingredient keeps its id and every value | seeder refresh `SystemCatalog.swift:385-389` | gap | Core | `theCatalogBumpAddsThePantryFieldsToAnOldStore`, `theBumpKeepsEveryOldIngredientValueAndId` | S1, named |
| PB02 | Same store | `TesseraDatabaseSchema.migrator` unchanged (v1, v2, v3) | `TesseraDatabaseSchema.swift:34-80` | traced (today) | Core | `noGRDBMigrationIsAddedForPantry` | S1, named |
| PB03 | An older build opens a store at the new catalog number | refused, nothing dropped (`MAX(packageVersion)` check) | `TesseraDatabaseSchema.swift:10-23`; pattern `BackupTests.swift:83` | gap | Core | `anOlderBuildRefusesTheNewCatalog` | S3, named |
| PB04 | First launch of v2 on tacos week | limes `out` (stateAt Oct 11 18:30), tortillas and ground beef `low`, salt `in` (stateAt Oct 10 10:00; the cook skips staples); `lastBoughtAt` Oct 10 10:00 on all four; hero `1 out, 2 low` equals the ledger's | none | gap | Core | `theBackfillMatchesTheLedgerOnTheTacosFixture` | S4, named |
| PB05 | Parity | `PantryBook` (the lifted reader) gives the same entries, order and labels as the app `PantryLedger` on the same fixture | `PantryLedger.swift:49-63` | gap | Core | `theLiftedLedgerGivesTheAppLedgersAnswers` | S10, named |
| PB06 | Second launch | the Settings key `pantryBackfilled` is set, so nothing runs again; no extra op | none | gap | Core | `theBackfillRunsOnce` | S4, named |
| PB07 | Milk tapped to out after v2, then restart | milk stays `out`; the backfill never overwrites a later change | none | gap | Core | `theBackfillKeepsALaterStateIntact` | S4, named |
| PB08 | The backfill op | one `.system` op that also sets the Settings key `pantryBackfilled` when the backfill finishes; no receipt, nothing spoken, no UNDO | none | gap | Core | `theBackfillIsNotUndoable` | S4, named |
| PB09 | Phone with no shops and no cooks | no state written, yet the Settings key `pantryBackfilled` is set, so a later first shop is a live event, not a backfill (an empty Pantry never reruns it) | ledger says `Nothing yet`: `PantryLedger.swift:78` | gap | Core | `anEmptyBackfillStillSetsTheMarker` | NEW (marker ruled at 4:32 pm, Q2) |
| PB10 | Same fresh phone | Pantry reads `Nothing yet`; CAN COOK greyed | `PantryLedger.swift:78` | gap | Core | `backfillOnAFreshStoreWritesNothing` | NEW |
| PB11 | Private recipe cook in history | its ingredients get state; no Tess line | ledger `:97-100` | gap | Core | `backfillIncludesAPrivateCook` | NEW |
| PB12 | Undone clear and a checked row deleted another way in history | neither counts (G45) | `Groceries.swift:166-181` | traced (read) | Core | `backfillIgnoresUndoneClearsAndOtherDeletes` | NEW |
| PB13 | A shop clear and a cook at the same instant on one ingredient | the surer state wins (out, then low, then in), as the ledger does; the live writes use the same rule (PD31) | `PantryLedger.swift:132` | traced (read) | Core | `backfillTieGoesToTheSurerState` | NEW (one rule for backfill and live, ruled at 4:32 pm, Q4) |
| PB14 | After the backfill, a cook's note is edited or its recipe deleted | stored state unchanged | derived today (G46) | gap | Core | `historyEditsNoLongerRewritePantry` | E7 covers recipe edit only; NEW for cook edits |
| PB15 | `usualSkippedAt` after the backfill | empty; the R slice's quiet rule starts clean | field not on master (grep) | gap | Core | `usualSkippedAtStartsEmpty` | NEW |
| PB16 | Shared export of a backfilled store; full backup of the same | shared: none of `state`, `stateAt`, `lastBoughtAt` (R18); backup keeps them | export masks by object only: `TesseraExport.swift:158-171` | gap | Core | `theSharedExportHoldsNoPantryState`, `theBackupKeepsPantryState` | S7, named |
| PB17 | AI packs (Kitchen, Capture, Home) after v2 | no state, no `lastBoughtAt`, no Pantry ingredient names | no pack mentions Pantry today (grep) | traced (today) | Core | `thePackSnapshotsCarryNoPantryFields` | S8, named |
| PB18 | Backfill on the 5-year scale fixture | inside the read budget the existing scale test uses | `GroceryScaleTests.swift:12` | inferred | Core | `backfillOnTheScaleFixtureStaysFast` | NEW |
| PB19 | Marker is not inferred: one store where the backfill found nothing and no ingredient has state, one where the key is unset but an ingredient already has state | the first has the Settings key `pantryBackfilled` set and does not rerun; the second (key unset) still runs the backfill, which never overwrites a newer state (PB07) | none | gap | Core | `theBackfillMarkerIsTheSettingsKeyNotIngredientState` | NEW (4:32 ruling 2) |
| PB20 | History holds both `Egg` and `Eggs` with states (Egg `in` from a clear Saturday 10:00, Eggs `out` from a cook Sunday 18:30) | folded to one key through the Groceries normalizer; the later timestamp wins (`out`, stateAt Sunday 18:30); at an equal instant the surer state wins; Pantry lists one line | `IngredientBook.find` returns the first match: `Ingredients.swift:23` | gap | Core | `backfillFoldsEggAndEggsToOneKey` | NEW (4:32 ruling 3) |

## 3. Grammar rows: phrases, exact parses and receipts

Where it sits: `parseKitchen` after the `todo/task/remind` guard (`TessGrammar+Kitchen.swift:34`) and before the for-groceries rule (`:43`) and buy/get (`:49`); the walls run first. A phrase with a day or time (`hasDate`, `:22`) is not ours. Receipts are thing first, "on" not "at", digits for counts, **no em-dashes in any string**, names as stored ("Oat milk"). UNDO: 4 s when the op adds a row; 10 s for a pure state change; VoiceOver 10 s on both; "none" is a no-write plain line.

### 3a. OUT phrases (state out plus a Groceries row, one op) (R7, R8, R17)

| Id | Phrase | Parse | Receipt, UNDO | Master today | Status | Owner | Test | PR #896 |
|---|---|---|---|---|---|---|---|---|
| PG01 | `out of milk` | Milk out; row `milk` added | `Milk, out. On Groceries.` 4 s | no rule: falls to `parseCook` / model | gap | Core | `outOfMilkSetsOutAndAddsARow` | V1, named |
| PG02 | `we're out of eggs`, `we are out of eggs`, `i'm out of eggs`, `i am out of eggs`, `all out of eggs`, `just out of eggs` | Eggs out (key `egg`) | `Eggs, out. On Groceries.` 4 s | none | gap | Core | `weAreOutOfEggsAndRanOutOfRiceAreRead` | V1, named |
| PG03 | `ran out of rice`, `we ran out of rice`, `we've run out of rice` | Rice out | `Rice, out. On Groceries.` 4 s | none | gap | Core | same as PG02 | V1, named |
| PG04 | `no more rice` | Rice out | `Rice, out. On Groceries.` 4 s | none | gap | Core | `noMoreRiceIsRead` | V1, named |
| PG05 | `no rice left` | Rice out | `Rice, out. On Groceries.` 4 s | none | gap | Core | `noRiceLeftIsRead` | NEW |
| PG06 | `milk is gone`, `milk's gone`, `eggs are gone` | Milk out / Eggs out | `Milk, out. On Groceries.` | none | gap | Core | `milkIsGoneIsRead` | V1, named |
| PG07 | `milk is out`, `milk's out`, `eggs are out` | Milk out / Eggs out | `Milk, out. On Groceries.` | none | gap | Core | `milkIsOutIsRead`, `eggsAreOutIsRead` | NEW |
| PG08 | `OUT OF MILK.` (caps, final period) | same as PG01 (lowercase, trim, drop final punctuation) | `Milk, out. On Groceries.` | none | gap | Core | `outPhrasesIgnoreCaseAndFinalPunctuation` | NEW |
| PG09 | `out of the milk`, `out of our milk`, `out of some milk again` | Milk out (leading the/our/some, trailing again stripped) | `Milk, out. On Groceries.` | none | gap | Core | `outOfStripsFillerWords` | NEW (M-rule 1 has no test) |
| PG10 | `out of 2% milk`, `out of whole milk`, `out of skim milk` | Milk out (keys all equal `milk`) | `Milk, out. On Groceries.` | `IngredientBook.find` `Ingredients.swift:20-24` | gap | Core | `outOfTwoPercentMilkFindsMilk` | V2, named |
| PG11 | `out of oat milk`, an ingredient Milk exists | finds or creates `Oat milk`; Milk untouched (key `oat milk` is not `milk`); admitted because the aisle guide knows the head noun | `Oat milk, out. On Groceries.` 4 s | admission via last words `Aisles.swift:50-59` | gap | Core | `outOfOatMilkLeavesMilkAlone` | V2, named |
| PG12 | `out of milk chocolate` | Milk untouched; no substring match; claimed only if the guide knows the head noun `chocolate` | `Milk chocolate, out. On Groceries.` if admitted, else not claimed | `Aisles.swift:45-60` | gap | Core | `outOfMilkChocolateLeavesMilkAlone` | V2, named |
| PG13 | `out of eggs` when the ingredient is titled `Egg` | finds `Egg` (per-word singular) | `Egg, out. On Groceries.` | `Ingredients.swift:20-24` | traced (find) | Core | `eggsFindsEgg` | V2, named |
| PG14 | `out of milk, eggs and rice` | three items, one op | `Milk and 2 more, out. On Groceries.` 4 s | `GroceryLines.split` exists | gap | Core | `threeItemsReadMilkAnd2More` | V8, named |
| PG15 | `out of milk and eggs` | two items, one op | `Milk and eggs, out. On Groceries.` 4 s | none | gap | Core | `outOfMilkAndEggsIsOneOp`, `twoItemsReadMilkAndEggs` | V3 and V8, named |
| PG16 | `out of mac and cheese` | one item | `Mac and cheese, out. On Groceries.` | split keeps it whole | inferred | Core | `macAndCheeseIsOneItem` | V3, named |
| PG17 | `out of milk $4` | price stripped; state and row written; no amount stored or spoken | `Milk, out. On Groceries.` | `EngineWall.withoutPrice` (named by the spec, not re-read here) | inferred | Core | `aPriceTailIsStrippedAndNeverSpoken` | V11, named |
| PG18 | `out of advil` (a medicine, R7) | state and row written; item reads `Private item` | `Private item, out. On Groceries.` 4 s | row-side wall: `GroceriesWall.swift:24` | gap | Core | `aMedicineOutPhraseReadsPrivateItem` | V11, named |
| PG19 | `out of milk`, a row `milk` already open | state out; no second row | `Milk, out. Already on Groceries.` 10 s | swipe wording `PantryFront.swift:38` | gap | Core | `anAlreadyOnLineReadsAlreadyOnGroceries` | V8, named |
| PG20 | milk already `out` and its row open, said again | no write | `Milk, already on Groceries.` none | swipe says `Milk, already on Groceries.` `PantryFront.swift:38` | traced (swipe) / gap (phrase) | Core | `alreadyOutAndOnGroceriesAddsNoSecondRow`, `alreadyOnGroceriesHasNoUndo` | V7 and U5, named |
| PG21 | milk already `out`, row gone | row added | `Milk, on Groceries.` 4 s | `PantryCopy.added` `:37` | traced (swipe) / gap (phrase) | Core | `alreadyOutButGoneFromGroceriesAddsTheRow` | V7, named |
| PG22 | milk checked in the basket, `out of milk` said (R20) | no write | `Milk, in the basket.` none | `PantryFront.swift:40,52-61` | traced (swipe) / gap (phrase) | Core | `anItemInTheBasketIsLeftAlone` | V7, named |
| PG23 | Last typed milk row was `2 L` (cleared) | new row `milk` with quantity `2 L` | n/a | none | gap | Core | `theRowCarriesTheLastTypedAmount` | V6, named |
| PG24 | Newest milk row came from a recipe share | not a typed amount; the older typed one (or none) is used | n/a | `shares` field `SystemCatalog.swift:277` | gap | Core | `aRecipeShareIsNotATypedAmount` | V6, named |
| PG25 | No typed amount ever | row has no quantity; nothing guessed | n/a | none | gap | Core | `noTypedAmountMeansNoAmount` | V6, named |
| PG26 | `out of 5`, `no more 2`, `out of 2 lemons` (a digit, R17) | not ours; the rest of the grammar decides | n/a | none | gap | Core | `outOfFiveIsNotClaimed` | V4, named (the other two NEW) |
| PG27 | `out of milk and advil` | first item names the receipt; the private one reads `Private item` wherever it falls | `Milk and Private item, out. On Groceries.` | none | gap | Core | `aPrivateItemReadsPrivateWhereverItFalls` | NEW |

### 3b. LOW, IN, OPEN phrases (R9, R10, R11)

| Id | Phrase | Parse | Receipt, UNDO | Master today | Status | Owner | Test | PR #896 |
|---|---|---|---|---|---|---|---|---|
| PG30 | `low on rice`, `running low on rice`, `rice is low`, `rice's low` | Rice low; state only, no Groceries row (R9) | `Rice, low.` 10 s | none | gap | Core | `lowOnRiceSetsLowAndAddsNoRow` | V9, named |
| PG31 | `have rice`, `i have rice`, `we have rice`, `have some rice`, `have more rice` | Rice in; `stateAt = now`; `lastBoughtAt` untouched (R10) | `Rice, in.` 10 s | none | gap | Core | `haveRiceSetsIn`, `haveRiceDoesNotTouchTheBoughtDay` | V5, named |
| PG32 | `got milk`, `bought milk`, `picked up milk`, `restocked milk` | Milk in; `stateAt = lastBoughtAt = now` (R10) | `Milk, in.` 10 s | none | gap | Core | `gotMilkSetsInAndTheBoughtDay` | V5, named |
| PG33 | `bought milk sat` | not ours (dated note) | n/a | dated-note rule `PrivateFacts.swift:7-10` per spec | gap | Core | `boughtMilkWithADayIsNotClaimed` | NEW (`gotAHaircutSatIsNotClaimed` is V4) |
| PG34 | `have chalk`, `have quinoa flour` (not a known Ingredient or aisle-table name) | not claimed (IN is stricter than OUT: no head-noun admission) | n/a | none | gap | Core | `haveAnUnknownThingIsNotClaimed` | NEW |
| PG35 | `pantry`, `open pantry`, `show pantry`, `what's out`, `what am i out of`, `what do i have` | opens Pantry (R11) | no receipt | none | gap | Core, Builder B | `pantryOpensPantry`, `whatDoIHaveOpensPantry` | V10, named (two phrases named) |
| PG36 | `what do i have tomorrow` | the schedule, not Pantry | n/a | no Pantry rule today, so the schedule path stands | traced | Core | `whatDoIHaveTomorrowIsTheSchedule` | V10, named |
| PG37 | `what do i have in the fridge`, `what do i have on friday` | exact match only; not R11's | n/a | none | gap | Core | `whatDoIHaveWithTrailingWordsIsNotPantry` | NEW |

### 3c. Must NOT be claimed (the G92 holes), walls, UNDO, receipts

| Id | Phrase or input | Expected | Master today | Status | Owner | Test | PR #896 |
|---|---|---|---|---|---|---|---|
| PG40 | `out of breath`, `bed`, `time`, `range`, `town`, `office`, `ideas`, `luck`, `order`, `touch`, `shape`, `energy`, `control`, `reach`, `sight`, `practice` | none claimed (name not known, rule 4); `out of range` is also a kit-range word, `TessGrammar.swift:112` | n/a | gap | Core | `outOfBreathBedAndTimeAreNotClaimed` | V4, named (one name for sixteen) |
| PG41 | `out of stock` | not claimed ("stock" alone is on a stoplist); `out of chicken stock` is claimed | n/a | gap | Core | `outOfStockIsNotClaimedButChickenStockIs` | NEW |
| PG42 | `no more reps`, `sets`, `meetings`, `emails`, `excuses` | not claimed | n/a | gap | Core | `noMoreRepsIsNotClaimed` | V4, named |
| PG43 | `out of chalk` | not claimed; stays a Gym bag matter | n/a | gap | Core | `outOfChalkIsNotClaimed` | V4, named |
| PG44 | `have a call at 3`, `have a lemon`, `have 2 lemons` | not claimed (article, count, time) | n/a | gap | Core | `haveACallAt3IsNotClaimed` | V4, named (the other two NEW) |
| PG45 | `got a haircut sat` | not claimed | dated-note rule | inferred | Core | `gotAHaircutSatIsNotClaimed` | V4, named |
| PG46 | `the milk is out`, `my milk is out` | not claimed (non-bare subject can mean left on the counter) | n/a | gap | Core | `theMilkIsOutIsNotClaimed` | V4, named |
| PG47 | `remind me we're out of milk`, `todo out of milk`, `task out of milk` | stay tasks | `TessGrammar+Kitchen.swift:34-36` | traced | Core | `remindMeWeAreOutOfMilkStaysATask` | V4, named |
| PG48 | `out of milk thursday`, `we'll be out of milk thu` | stays a task (`hasDate`) | `:22` | traced (guard) | Core | `outOfMilkThursdayStaysATask` | V4, named |
| PG49 | `spent $4 on milk` | not this rule (`isMoney`) | `:81-87` | traced | Core | `aSpendingPhraseIsNotThisRule` | V11, named |
| PG50 | `out of` plus a Claude-key-shaped tail; `out of milk, the password is` plus a value | nothing written; the existing wall line; never sent anywhere | wall runs first per spec | inferred | Core | `aKeyShapedTailWritesNothing`, `aSecretValueWritesNothing` | V11, named |
| PG51 | A pantry-shaped phrase the rule cannot place (`we are fresh out of the good olive oil situation`) | stays on the phone; never goes to Claude | miss route exists for other phrases | gap | Core | `aPantryShapedMissStaysOnThePhone` | S9, named |
| PG52 | `buy milk` (no state word) | unchanged: Groceries row only, no state change | buy/get `:49-66` | traced | Core | `buyMilkLeavesPantryStateAlone` | NEW |
| PG53 | UNDO windows: new-row receipt, pure state change, VoiceOver | 4 s, 10 s, 10 s on both | `HomeQueue.swift:43-52` | traced (hold fn) / gap (receipts) | Core | `aNewRowReceiptHolds4Seconds`, `aStateChangeHolds10Seconds`, `voiceOverMakesBothTenSeconds` | U1, named |
| PG54 | UNDO of `out of milk` | state, `stateAt`, `lastBoughtAt` and the added row all reversed in one step | n/a | gap | Core | `undoTakesBackTheStateAndTheRowTogether` | U2, named |
| PG55 | A second receipt replaces the first note and its UNDO | first UNDO gone; first op stays done and in the log | one slot (`TessVoice`) | traced (slot) | Core | `aSecondReceiptReplacesTheFirstUndo`, `theFirstOpStaysInTheLog` | U3, named |
| PG56 | takenBack after the new receipts | `Milk, taken back.`; three items `Milk and 2 more, taken back.` (no inner commas, so the cut at the first ", " keeps it whole); private `Private item, taken back.` | `UndoCopy.takenBack` `BottomChrome.swift:763-767` | traced (fn) | Core | `takenBackReadsMilkTakenBack`, `takenBackForThreeItemsReadsMilkAnd2MoreTakenBack`, `takenBackForAPrivateItem` | U4, named |
| PG57 | Every receipt string in this section | no em-dash, no en-dash, no ellipsis | n/a | gap | QA | `pantryReceiptsHaveNoDashesOrEllipsis` | NEW |

## 4. State words (the tap, the Ingredient page, the hero, USUALLY HAVE)

The state word is the right-hand word on each Pantry line (`out` weight 700, `low` 600) and the word on the Ingredient page and recipe peek. R15 (accepted): an unknown ingredient has no state word and no tap target; its first state comes from Tess, a clear or a cook.

| Id | Input | Expected | Master today | Status | Owner | Test | PR #896 |
|---|---|---|---|---|---|---|---|
| PW01 | Tap `out` on Limes (Ingredient page word) | cycle in, low, out, in: out goes to `in`; receipt `Limes, in.`; one op; UNDO 10 s | no stored state, no cycle: `PantryView.swift:11-12` says "waiting on Core" | gap | Core | `theStateWordCyclesInLowOutIn`, `eachCycleTapIsOneOpWithItsUndo` | E9, named |
| PW02 | Tap `in`, then `low`, then `out` | `Limes, low.` then `Limes, out.` then `Limes, in.`, each its own op | none | gap | Core | `theStateWordCyclesInLowOutIn` | E9, named |
| PW03 | Any cycle tap | `stateAt = now`; `lastBoughtAt` never touched | none | gap | Core | `aCycleTapNeverTouchesTheBoughtDay` | NEW |
| PW04 | UNDO after a tap | row returns; Tess's line "Tacos took the cilantro and limes." returns | `speak` never overwrites an open UNDO: `PantryView.swift:92-95` | traced (guard) / gap (cycle) | Builder B | `undoRestoresRowAndTessLine` | NEW (it is P7 in `pantry-78.md`) |
| PW05 | Unknown ingredient on its page (R15) | no state word, no sentence, no tap target | KV2 P8 | gap | Builder B | `anUnknownIngredientHasNoStateWordToTap` | NEW |
| PW06 | Hero strings | `4 out, 2 low`, `1 out`, `2 low`, `Nothing out`, `Nothing yet`; never `0 out`; "out" and "low" never take an s | `PantryLedger.swift:72-79`; tests `PantryFrontTests.swift:26,32` | traced | Builder B | `heroNeverSaysZeroOrPluralOutLow` | NEW |
| PW07 | Context line | `since today's shop`, `since yesterday's shop`, `since Saturday's shop`, `since the Oct 3 shop`; at most 22 characters; hidden before any shop; small hours belong to the day before | `PantryCopy.swift:8-25`; `PantryCopyTests.swift:18`; `PantryDayWordTests.swift:18` | traced | Builder B | `contextNamesTheShopsDay` | existing |
| PW08 | Group labels | `OUT`, `LOW`, `USUALLY HAVE`; an empty group draws nothing, not even its label | `PantryView.swift:62-77` (OUT and LOW only) | traced (OUT, LOW) / gap (USUALLY HAVE) | Builder B | `anEmptyGroupDrawsNoLabel` | NEW |
| PW09 | USUALLY HAVE with 3 names | `Rice, coffee, eggs` | none (Research R engine not built) | gap | Core, Builder B | `usuallyHaveListsThreeNames` | NEW |
| PW10 | USUALLY HAVE with exactly 4 names (R14) | all four if they fit one line, else `Rice, coffee and 2 more` (two named, then the count; "and 2 more" at 55%) | `PantryCopy.list` gives `rice, coffee and 2 more` for 4: `PantryCopyTests.swift:32` | traced ("and N more" form) | Builder B | `usuallyHaveWithExactlyFourFitsOrFolds` | NEW |
| PW11 | USUALLY HAVE with 7 due names | cap 4, so `Rice, coffee and 2 more` | cap per Research rules 1-9 | gap | Core | `usuallyHaveCapsAtFour` | F4 re-runs the 20-week test |
| PW12 | Empty page | hero `Nothing yet`; under it `Clear a shop or finish a cook and this fills in.` (51 characters, 55% ink); Tess: `Say "out of milk" and I'll keep it.` (36 characters) only once the phrase ships | body `PantryCopy.swift:34`; Tess line withheld `PantryView.swift:96` | traced (body) / gap (Tess line) | Builder B | `emptyPageShowsBodyAndTessInvite` | NEW |
| PW13 | Tess cook line | `Tacos took the cilantro and limes.`; 4 or more names `Tacos took 5 things.`; recipe by `shortName` (P-F3) | `PantryCopy.swift:28-31`; full title used `PantryLedger.swift:99` | traced (strings) / gap (shortName) | Builder B | `tessLineUsesTheShortRecipeName` | NEW |
| PW14 | Swipe receipts | `Milk, on Groceries.` (4 s; VoiceOver 10 s), `Milk, already on Groceries.` and `Milk, in the basket.` (none) | `PantryFront.swift:36-43`; `PantryView.swift:109-119` | traced | Builder B | `aThingAlreadyOnGroceriesIsNotAddedTwice` | existing (`PantryFrontTests.swift:42`) |
| PW15 | A failed write | `Didn't save that. Try again.`; one soft warning haptic, only when a write did not save, once per failure, not on an immediate repeat | `PantryView.swift:115`; haptic ruling decisions 12:45 pm | traced (copy) | Builder B | `aFailedPantryWriteSaysDidntSaveThat` | NEW |
| PW16 | Ingredient page sentences | `Out since you cooked dal on Tuesday.`, `Low, after dal on Tuesday.`, `In since Saturday's shop.`, `In, as of now.`; proposed for told states: `Out, since you said so on Tuesday.`, `In, since you got it on Tuesday.` | none | gap | Builder B | `theIngredientPageSentencesNameTheEvent` | NEW |
| PW17 | Rhythm line | `Bought 4 times, about every 12 days.` only from 3 buys, read from the shop-clear ops, not the field | `Groceries.swift:169` | gap | Core | `theRhythmReadsTheShopClears` | S12, named |
| PW18 | VoiceOver | label `Limes, out`; custom action `Add to Groceries`; hint `Opens Limes`; a walled line reads `Private item, out` | `PantryView.swift:145,151-152` | traced | Builder B | `pantryLineVoiceOverLabels` | NEW |
| PW19 | Recipe page ingredient peek | words `have` (42% ink), `low`, `out` (ink), `used`; nothing for unknown; staples show nothing. `used` reads `lastUsedAt`, the last time a cook finish used the ingredient (written in the cook-finish op, not read from an open Cook process); an ingredient no cook has used shows no `used` (6:39 pm Oct 17, G178; Core names the accessor) | none; `lastUsedAt` is not a field on master (section 0) | gap | Builder B | `thePeekShowsStateWordsOnly` | NEW |
| PW20 | Accessibility Dynamic Type sizes | the state word goes under the name, one column, nothing clipped | `PantryView.swift:180-184` | traced | Builder B | `stateWordWrapsUnderTheNameAtAccessibilitySizes` | NEW |

## 5. Private items (masked "Private item")

Rules: the ledger label is `Private item` whenever `ObjectPrivacy.isPrivateRecipeTitle(title, lastWeightKg:)` hits (`PantryLedger.swift:163-169`). R12 follows G102: a private Pantry line has no reveal and no tap target. R13: a private recipe is counted in CAN COOK with no names. R7: a body or medicine item said as out writes state and a `Private item` row.

| Id | Input | Expected | Master today | Status | Owner | Test | PR #896 |
|---|---|---|---|---|---|---|---|
| PP01 | Ingredient `Advil` in state out | line reads `Private item`, `out`; the name appears in no string | `PantryLedgerTests.swift:85-94` | traced | Builder B | `aWalledThingReadsPrivateItem` | existing |
| PP02 | Tap the private line (R12, G102) | nothing opens and the row keeps reading `Private item`; there is no reveal state and no hint copy | `PantryLine.opens` is false for private: `PantryView.swift:134` | traced | Builder B | `aPrivateLineHasNoTapTarget` | NEW |
| PP03 | Swipe a private line | adds a row; receipt `Private item, on Groceries.`; a row, not a note | `GroceriesWallTests.swift:140`; `PantryCopyTests.swift:37` | traced | Core | `aPantrySwipeOnAWalledIngredientMakesARowNotANote` | existing |
| PP04 | Private line already listed | `Private item, already on Groceries.` / `Private item, in the basket.` | `PantryFrontTests.swift:68` | traced | Builder B | `aWalledThingAlreadyListedStaysPrivateItemOnBothLines` | existing |
| PP05 | VoiceOver on a private line | `Private item, out`; no "Opens" hint | hint sits inside the `opens` branch: `PantryView.swift:142-146` | traced | Builder B | `aPrivateLineHasNoOpensHint` | NEW |
| PP06 | `missing` on a recipe with a private ingredient | counted like any other; its label in every string is `Private item` | none | gap | Core | `aPrivateIngredientReadsPrivateItemInMissing` | M7, named |
| PP07 | An ingredient used only by private recipes | itself private (the one shared rule, core.md decision 5:16) | none | gap | Core | `anIngredientUsedOnlyByPrivateRecipesIsPrivate` | M7, named (G37) |
| PP08 | A private recipe in CAN COOK (R13) | row reads `Private recipe`; counts only, `names` empty; sub-line in count form, no name, no tap-to-add; still part of "N you can cook now"; the private recipe row is drawn at 100% ink like other rows (master dims it to 66% at `RecipesShelfView.swift:83`, a tell; sheet 87's 66% is withdrawn, Design sheet 99) | none | gap | Core | `aPrivateRecipeGivesCountsAndNoNames` | M8, named |
| PP09 | Shelf sub-line on a recipe with a walled missing ingredient | `1 missing: Private item` | none | gap | Builder B | `theSubLineNamesPrivateItem` | NEW |
| PP10 | Tess cook line after a private cook | silent, even "Private recipe took ..." | `PantryLedger.swift:97-100`; test `PantryLedgerTests.swift:111` | traced | Builder B | `aPrivateRecipeGetsNoCookLineAtAll` | existing |
| PP11 | Tess cook line where one used ingredient is walled | the walled name is left out of the names | `!$0.isPrivate` filter `PantryLedger.swift:102` | traced | Builder B | `aCookLineLeavesOutAPrivateIngredient` | NEW |
| PP12 | Receipts, Tess lines, hero, VoiceOver labels, widgets, log summaries | none carries a walled name, a price or a body word | partial | gap | Core | `noPantrySurfaceCarriesAWalledName` | P1, named |
| PP13 | Op summaries for pantry ops | thing first and masked (`Private item, out`), also in the export's op rewrite | `TesseraExport.swift:169-171` masks by touched object | gap | Core | `pantryOpSummariesAreMasked` | P2, named |
| PP14 | Boundaries from decisions 4:22, 4:35 and the 4:50 trim | `blood orange`, `hearts of palm`, `energy drink`, `sleep tea`, `drained tuna`, `sleepy time tea`, `Dr Pepper`, `Rent car`, `flour 5 kg`, `ground beef 2 lb`, `pain au chocolat`, `recovery shake`, `Weight Watchers chili` stay raw, no `Private item` (`slept`, `sleepy`, `drained` left titleWords at 4:50) | whether code has the trims is not read here | inferred | Core | `foodWordsAreNeverMaskedOnPantry` | NEW |
| PP15 | A real medicine or body ingredient (`Advil`, `insulin`) | masks | `ObjectPrivacy.isPrivateRecipeTitle` | inferred | Core | `medicineIngredientsMask` | NEW |
| PP16 | Shared export | pantry state left out (R18), so no private fact rides on it | see PB16 | gap | Core | `theSharedExportHoldsNoPantryState` | S7, named |
| PP17 | A name with a plural masking word (4:50 ruling 3) | `dentists` masks (matching tolerates a plural) and reads `Private item`; `dentist-appt` (joined words) stays raw | whether code has the trim is not read here | inferred | Core | `aPluralMaskingWordMasksOnPantry` | NEW (QA note 2 on #902) |

## 6. The pre-existing ochre removal

Decision (Product and Design, Oct 17; sheet 92, then G175 closed by Design in gaps-98, sheet 99, corrected sheet 99 section 4 at 6:43 pm Oct 17 and built in #917, be05f0b6): there is no ochre in Pantry, and the Pantry row STATE WORD is plain ink (`Theme.Colors.ink`; `PantryColour` is deleted). Kitchen's `areaLean` (the 72% mix, Reading B: the hex is the pigment, 72% pigment plus 28% ink) applies only to the caps labels and to the index line. `areaLean(.kitchen)` is `#126E52` on Porcelain (6.22:1) and `#72DCB1` on Obsidian (12.59:1 on the Obsidian ground `#000000`; both figures are from `arealean-tokens.md`, T02 and T05). The Reading A hex `#12936A` (3.88:1, fails 4.5:1 for small text) is never the answer, and the sheet 99 ruling retires the ochre line in `pantry.md`. The index line is ink today and takes Kitchen's `areaLean` once Builder A's area-colour pass lands. State is never carried by colour alone. `areaLean` does not exist on master, so the caps-label and index-line rows wait on the resolver (AL03 and AL04 in the swipe-lean fixtures). An earlier revision of this file put `#126E52` and `#72DCB1` on the state word; that was superseded by the 6:43 pm correction.

| Id | Input | Expected | Master today | Status | Owner | Test | PR #896 |
|---|---|---|---|---|---|---|---|
| PO01 | Pantry state word, Porcelain | plain ink (`Theme.Colors.ink`, built in #917): no ochre, no `areaLean` on the row; `#126E52` is not the state word colour | was `ochre.mix(with: ink, by: 0.28)`; now ink since be05f0b6 | traced (#917) | Builder B | `pantryStateWordIsInk` (AL15) | not in the 118 |
| PO02 | Pantry state word, Obsidian | plain ink (`Theme.Colors.ink`): no ochre, no `areaLean` on the row; `#72DCB1` is not the state word colour | same | traced (#917) | Builder B | `pantryStateWordIsInkOnObsidian` | NEW |
| PO03 | Search the app target for the old values | `0xA4601A` and `0xE3A857` appear nowhere; `PantryColour.swift` is deleted or holds no ochre | `PantryColour.swift:8-9` | gap | Builder B | `noOchreLiteralRemains` (AN08) | NEW |
| PO04 | Weights | out stays 700, low 600; colour change only | `PantryView.swift:195` | traced | Builder B | `stateWordKeepsItsWeights` | NEW |
| PO05 | Where lean may appear | resting colour of text only, never a fill, ring or ground; the out ring stays ink at 42% | ring `PantryView.swift:202` | traced (ring) | Builder B | `leanIsNeverAFill` (AN03) | NEW |
| PO06 | The index line "Pantry" | expect ink now; Kitchen's `areaLean` (`#126E52` on Porcelain, `#72DCB1` on Obsidian) once Builder A's area-colour pass lands. Until then ink is a pending note, not a failure | `PantryColour.swift` is gone (#917); the line is ink | pending (Builder A pass) | Builder A | `pantryIndexLineColourFollowsSheet92` | NEW |
| PO07 | Small text against the ground, every look | at least 4.5:1 for ink (the state word) and for the Kitchen caps label and index line; the caps label on Porcelain `#126E52` measures 6.22:1 and on Obsidian `#72DCB1` 12.59:1 (`arealean-tokens.md` T02, T05); the ink ratio is measured by the test, no figure is claimed here | no check | gap | Core | `areaLeanLabelContrastAtLeastFourPointFive` (AL11) | not in the 118 |
| PO08 | Low versus out | still told apart by weight and position, not by colour alone | `PantryView.swift:195` | traced | Builder B | `stateWordsDifferByWeightNotColourAlone` | NEW |

## 7. One row per ruling (R1 to R20)

R1 to R20 were accepted at decisions.md line 957 "as written"; PR21 to PR25 are Product's 4:32 pm rulings (line 965); PR26 to PR29 are Product's 6:39 pm rulings (decisions.md lines 977 and 979). "Row" is where the detail lives.

| Id | Ruling | Input | Expected | Row | Status | Owner | Test | PR #896 |
|---|---|---|---|---|---|---|---|---|
| PR01 | R1 backfill once, `.system`, no UNDO | first launch of v2 on tacos week | state as the ledger gave; once; no UNDO | PB04, PB06, PB08 | gap | Core | `theBackfillMatchesTheLedgerOnTheTacosFixture` | S4, named |
| PR02 | R2 `stateAt` and `usualSkippedAt` in the same bump | fresh catalog | both fields exist beside `state` and `lastBoughtAt`; one bump | PB01, PB15 | gap | Core | `theCatalogBumpAddsThePantryFieldsToAnOldStore` | S1 (`usualSkippedAt` in prose only) |
| PR03 | R3 staples skipped in `missing` | tacos with salt out | salt not missing; a staple-only recipe is cookable | PD22 | gap | Core | `aStapleOutDoesNotCount`, `aStapleOnlyRecipeIsCookable`, `anAisleGuideStapleIsAStapleOnTheRecipePage` | M2, named |
| PR04 | R4 optional and "as needed" skipped | `parsley, for garnish` out; `olive oil, as needed` | neither makes a missing; "as needed" reads as to-taste once parsed (G113) | PD22 | gap | Core | `anOptionalLineNeverMakesAMissing`, `aToTasteLineNeverMakesAMissing`, `asNeededReadsAsToTaste` | M3, named |
| PR05 | R5 unknown counts toward the drop | recipe with 2 unknown lines, 0 out | score 2; fades down the shelf | PD29, PD30 | gap | Core | `twoUnknownLinesFadeARecipeDown` (plus `unknownIsToCheckNotMissing`) | M4 named; the drop itself NEW |
| PR06 | R6 greyed with no state | no ingredient has any state | CAN COOK word greyed (42%); tap says `Clear a shop or finish a cook and this fills in.` (4 s, no UNDO); shelf does not re-sort; no per-row "N to check" | PE01, PE02 | gap | Core, Builder B | `withNoStateTheFilterIsGreyedAndNothingResorts` | C3, named |
| PR07 | R7 body or medicine out: state plus `Private item` row | `out of advil` | `Private item, out. On Groceries.` | PG18 | gap | Core | `aMedicineOutPhraseReadsPrivateItem` | V11, named |
| PR08 | R8 admission by known ingredient or aisle guide | `out of oat milk` / `out of chalk` | claimed / not claimed | PG11, PG43 | gap | Core | `outOfOatMilkLeavesMilkAlone`, `outOfChalkIsNotClaimed` | V2, V4, named |
| PR09 | R9 low phrases, state only | `low on rice` | `Rice, low.` no row | PG30 | gap | Core | `lowOnRiceSetsLowAndAddsNoRow` | V9, named |
| PR10 | R10 got/bought set `lastBoughtAt`, have does not | `got milk`, `have rice` | as stated | PG31, PG32 | gap | Core | `gotMilkSetsInAndTheBoughtDay`, `haveRiceDoesNotTouchTheBoughtDay` | V5, named |
| PR11 | R11 exact `what do i have` opens Pantry | with and without a day word | Pantry / schedule | PG35 to PG37 | gap | Core | `whatDoIHaveOpensPantry`, `whatDoIHaveTomorrowIsTheSchedule` | V10, named |
| PR12 | R12 private Pantry line has no reveal and no tap target (G102) | tap a `Private item` line | nothing | PP02, PP05 | traced (Pantry) | Builder B | `aPrivateLineHasNoTapTarget` | NEW |
| PR13 | R13 private recipe counted, no names | CAN COOK with one private recipe at score 0 | counted in `N you can cook now`; row `Private recipe`; no names, no add | PP08 | gap | Core | `aPrivateRecipeGivesCountsAndNoNames` | M8, named |
| PR14 | R14 exactly 4 USUALLY HAVE names | rice, coffee, eggs, tea | all four if they fit one line, else `Rice, coffee and 2 more` | PW10 | gap | Builder B | `usuallyHaveWithExactlyFourFitsOrFolds` | NEW |
| PR15 | R15 no tap target for an unknown ingredient | open an unknown ingredient | no word, no sentence | PW05 | gap | Builder B | `anUnknownIngredientHasNoStateWordToTap` | NEW |
| PR16 | R16 recipe with no ingredient lines | CAN COOK | listed after the rest, never cookable | PE03 | gap | Core | `aRecipeWithNoLinesIsNeverCookable` | C4, named |
| PR17 | R17 a digit means not ours (except `2%`) | `out of 5`, `have 2 lemons`, `out of 2% milk` | not claimed, not claimed, claimed (Milk) | PG26, PG10 | gap | Core | `outOfFiveIsNotClaimed`, `outOfTwoPercentMilkFindsMilk` | V4, V2, named |
| PR18 | R18 pantry state out of the shared export, in the backup | export both ways | as stated | PB16 | gap | Core | `theSharedExportHoldsNoPantryState`, `theBackupKeepsPantryState` | S7, named |
| PR19 | R19 in-cover on a bigger-size re-add still skips in lines | planned at 4, re-added at 8, chicken in | chicken still skipped (amounts never compared) | PE05 | gap | Core | `aBiggerSizeStillSkipsInLines` | F2, named |
| PR20 | R20 `out of milk` with milk checked in the basket | said | no write; `Milk, in the basket.` | PG22 | gap | Core | `anItemInTheBasketIsLeftAlone` | V7, named |
| PR21 | 4:32 (1) tie rule, backfill and live | equal timestamp; older versus newer | surer state wins (out, low, in); older never overwrites newer | PD31, PD32, PB13, PE15, PE16 | gap | Core | `anEqualTimestampGoesToTheSurerStateInAnyOrder`, `anOlderTimestampNeverOverwritesANewerState` | NEW |
| PR22 | 4:32 (2) backfill marker | an empty Pantry, a restart | Settings key `pantryBackfilled`, set when the backfill finishes; never inferred from ingredient state | PB06, PB08, PB09, PB19 | gap | Core | `theBackfillMarkerIsTheSettingsKeyNotIngredientState` | NEW |
| PR23 | 4:32 (3) duplicate keys | `Egg` and `Eggs` | one key via the Groceries normalizer; latest timestamp wins, ties by rule (1) | PB20, PE19 | gap | Core | `backfillFoldsEggAndEggsToOneKey`, `duplicateKeyIngredientsFoldToOneKey` | NEW |
| PR24 | 4:32 (4) test count | the spec's section (e) | 118 distinct names; the spec count is corrected | section 9, Q1 | ruled | Core | n/a | spec corrected |
| PR25 | 4:32 (5) existing app tests | `PantryLedgerTests`, `PantryFrontTests`, `GroceriesFinishTests.undoAfterFinishPutsPantryBack` | rewritten for stored state when Core builds it; no catalog number hard-coded | section 9, Q3 | ruled | Core | n/a | n/a |
| PR26 | 6:39 pm (G177) PE is acceptance | the PE group, 24 rows | an eighth group, run after the seven | PE01 to PE24 | ruled | Product | n/a | n/a |
| PR27 | 6:39 pm (G178) a tie that changes nothing | PD31, PE15 (and the PW19 `used` case below) | writes nothing; no receipt, no haptic, no UNDO | PD31, PE15 | gap | Core | `anEqualTimestampGoesToTheSurerStateInAnyOrder`, `aTieBetweenAClearAndAPhraseGoesToTheSurerState` | NEW |
| PR28 | 6:39 pm (G178) peek word `used` | recipe page peek after a cook | `used` reads `lastUsedAt`, written at cook finish; Core names the accessor | PW19, PD09 | gap | Core, Builder B | `thePeekShowsStateWordsOnly` | NEW |
| PR29 | 6:39 pm (G175, sheet 99), corrected 6:43 pm: no ochre in Pantry | state word; caps labels and index line, Porcelain and Obsidian | state word plain ink (#917); `areaLean(.kitchen)` only on the caps labels and the index line (`#126E52` on Porcelain 6.22:1, `#72DCB1` on Obsidian 12.59:1), never `#12936A`; index line ink until Builder A's pass; a private recipe row at 100% ink | PO01, PO02, PO06, PO07, PP08 | traced (state word); gap (lean) | Builder B, Builder A | `pantryStateWordIsInk`, `pantryStateWordIsInkOnObsidian` | NEW |

## 8. Edge cases

| Id | Input | Expected | Master today | Status | Owner | Test | PR #896 |
|---|---|---|---|---|---|---|---|
| PE01 | Fresh phone, first run of v2 | `hasAnyState` is false; Core exposes it, Builder B reads it | none | gap | Core | `hasAnyStateIsFalseOnAFreshStore` | C3 (prose only) |
| PE02 | CAN COOK on day one, tap on the greyed word | Tess empty line, 4 s, no UNDO; word stays greyed; nothing re-sorts | none | gap | Builder B | `aTapOnTheGreyedWordSpeaksTheEmptyLine` | NEW |
| PE03 | Recipe with no ingredient lines | not judged; listed after the rest | none | gap | Core | `aRecipeWithNoLinesIsNeverCookable` | C4, named |
| PE04 | CAN COOK filter across launches | not stored; off each session | none | gap | Builder B | `theFilterIsNotStored` | C5, named |
| PE05 | Plan at 4 serves, re-add at 8, chicken in | chicken skipped both times | bigger size replaces the share: `Groceries.swift:470` | gap | Core | `aBiggerSizeStillSkipsInLines` | F2, named |
| PE06 | Out staple on the recipe page, planned | never added whatever its state | `Groceries.swift:462` | traced | Core | `outStaplesAreNeverAdded` | F3, named |
| PE07 | "1 missing" sub-line tap, out item | `Lemons, on Groceries.` 4 s; already there reads `Lemons, already on Groceries.` | none | gap | Builder B | `theMissingSubLineAddsOneRow` | NEW |
| PE08 | "1 to check" sub-line tap | opens the Ingredient page; adds nothing | none | gap | Builder B | `aToCheckTapAddsNothing` | NEW |
| PE09 | Two items in one phrase, one already `out` | one op; state written only for the new one; receipt names the first item; no double row | n/a | gap | Core | `aMixedPhraseIsOneOpWithNoDoubleRow` | NEW |
| PE10 | `out of milk and whole milk` (same key twice) | one item | key equality | gap | Core | `aRepeatedNameInOnePhraseIsOneItem` | NEW |
| PE11 | 12 names in one phrase | `Milk and 11 more, out. On Groceries.` (digits) | n/a | gap | Core | `manyItemsReadFirstNameAndTheCount` | V8 covers 3 |
| PE12 | `out of half-and-half`, `out of ketchup!` | admitted via key; punctuation trimmed | key rules | inferred | Core | `outOfHalfAndHalfIsAdmitted` | NEW |
| PE13 | `out of the really good extra virgin olive oil` (more than 4 words after stripping) | not claimed | n/a | gap | Core | `outOfFiveWordsIsNotClaimed` | NEW |
| PE14 | `out of`, `out of the` | not claimed | n/a | gap | Core | `outOfWithNoThingIsNotClaimed` | NEW |
| PE15 | A shop clear and a phrase on the same instant | the surer state wins (out over low over in), the same rule as the backfill (PD31, PB13); the spec's "neither overwrites an equal timestamp" line is replaced (4:32 pm ruling 1, Q4). When the tie leaves the state unchanged (milk `low`, a phrase says `in` at the same instant) nothing is written and no receipt, haptic or UNDO appears (6:39 pm G178) | spec E3 vs `PantryLedger.swift:132` | gap | Core | `aTieBetweenAClearAndAPhraseGoesToTheSurerState` | NEW |
| PE16 | A backdated check older than the stored `stateAt` | state kept (an older timestamp never overwrites a newer one, PD32); `lastBoughtAt` only moves forward | idea mirrored at `Shopping.swift:93-94` | inferred | Core | `aBackdatedCheckNeverWinsOverANewerState` | NEW |
| PE17 | A clear at 02:30 (small hours, DST day) | `lastBoughtAt` and the context word belong to the day before | `PantryDayWordTests.swift:18` | traced | Core | `aSmallHoursCheckBelongsToTheDayBefore` | existing |
| PE18 | Ingredient renamed (Milk to Whole milk) | state and `lastBoughtAt` stay on the object | stored on the ingredient | inferred | Core | `renamingAnIngredientKeepsItsState` | NEW |
| PE19 | Both `Egg` and `Eggs` exist | fold to one key through the Groceries normalizer; the latest timestamp wins, ties by the surer state; a phrase, clear or cook reads and writes the folded key (4:32 ruling 3, Q7) | `find` returns the first today: `Ingredients.swift:23`; normalizer `Quantities.swift:283` | gap | Core | `duplicateKeyIngredientsFoldToOneKey` | NEW |
| PE20 | UNDO of a phrase after a newer clear | restores the values the op captured; the newer clear is not clobbered (Q8) | engine undo | inferred | Core | `undoingAPhraseAfterANewerClearKeepsTheClear` | NEW |
| PE21 | `out` becomes `in` while the page is open | the line leaves with `.tesseraAnimation` | `PantryView.swift:81` | traced | Builder B | `aLineLeavesWhenItGoesIn` | NEW |
| PE22 | Reduce Motion on the swipe and the leave | no spring; value just changes | `PantryView.swift:175` | traced | Builder B | `pantryHonoursReduceMotion` | NEW |
| PE23 | 400 pantry lines | hero and list inside the read budget | `GroceryScaleTests.swift:12` | inferred | Core | `fourHundredIngredientsStayFast` | NEW |
| PE24 | A shop clear touching 50 items | one op, one UNDO, one summary `Finished shopping` | `Shopping.swift:72-79` | traced (receipt) | Core | `aBigClearIsOneOp` | NEW |

## 9. What the 118 already cover, and what is new

- Section (e) of the spec names tests by clause: S1 to S12, E1 to E9, V1 to V11, U1 to U5, M1 to M8, C1 to C5, F1 to F4, P1 and P2. Rows marked "named" are covered by a spec name (Core still writes the code).
- NEW rows (no spec name) cluster in: finish-shop as its own op (PD02), the tie and older-versus-newer rules and the no-change tie (PD31, PD32, PE15), the backfill marker (PB09, PB19), duplicate-key folding (PB20, PE19), grammar shapes the spec lists but does not name (`no X left`, `X is out`, filler words, IN admission, `what do i have` with trailing words), state-word screen behaviour (R12, R14, R15, VoiceOver, sentences), and the ochre removal (not in the spec at all). Rows PD33 to PD35 are not NEW: they carry spec names that had no row (G172).
- Existing master tests that stay valid: `PantryCopyTests`, `PantryDayWordTests`, `PantryFrontTests`, `PantryLedgerTests` (all derive-at-read; the three derive-at-read tests below are rewritten for stored state when Core builds it, ruled at 4:32 pm, Q3), `ShopClearsTests`, `GroceriesWallTests.aPantrySwipeOnAWalledIngredientMakesARowNotANote`. `ShoppingTests.finishShopUndoRestoresPantryStates` checks rows only and needs a state assertion; `GroceriesFinishTests.undoAfterFinishPutsPantryBack` reads the ledger. The rewrite of `PantryLedgerTests`, `PantryFrontTests` and `undoAfterFinishPutsPantryBack` rides Core's build; the new tests hard-code no catalog number.

## 10. Gaps by owner

**Core**
- Stored fields `state`, `stateAt`, `lastBoughtAt`, `usualSkippedAt`, `lastUsedAt` (written at cook finish, PD09, PW19; Core names the accessor) and the catalog bump after v10 (PB01 to PB03, PR02); no test hard-codes the number.
- Event writes inside the causing op: clear, finish shop, cook, phrase, cycle tap (PD01 to PD15, PW01 to PW03).
- The backfill with the Settings key `pantryBackfilled` and a once-only guarantee (PB04 to PB15, PB19, PB20); the tie rule (surer wins, older never overwrites newer) for backfill and live writes (PD31, PD32); the Egg/Eggs fold through `IngredientLine.key(for:)`; rewrite `PantryLedgerTests`, `PantryFrontTests` and `GroceriesFinishTests.undoAfterFinishPutsPantryBack`; delete the app `PantryLedger` derivation or reduce it to a wrapper; parity test PB05.
- `PantryBook`, `PantryState` (`unknown, inStock, low, out`), `hasAnyState`, `RecipeMath.missing`, `RecipeBook.lastCooked`, the one staple helper (PD21 to PD30).
- Grammar rules for out, low, in and open-Pantry with the M-rules, admission, stoplist, price stripping, wall order and receipts (section 3).
- Export: filter the three fields from the shared export, keep them in the backup (PB16); packs carry none (PB17).
- Planning skip for `in` lines and the all-in no-write path (PD26 to PD28).

**Builder B**
- State-word tap and cycle on the Ingredient page, VoiceOver, Tess cook line with `shortName`, USUALLY HAVE (R14), the OUT AND LOW side, the CAN COOK word and its greyed state, the shelf sub-line, the peek words.
- Ochre removal (done in #917) and `areaLean` use on the caps labels and index line only (section 6; Reading B ruled, no ochre in Pantry, state word ink), the lean part blocked on the resolver.
- Remove the remaining tap-to-reveal code and hint copy on Groceries, Lists and the recipe page (4:20 and 4:25 pm ruling, G102); each private row keeps its "Private ..." label and one tap does the row's normal action. Pantry itself has no reveal.

**Design**
- Reading B for `areaLean` is ruled (G175): `#126E52` Porcelain, `#72DCB1` Obsidian, on the caps labels and the index line only; the state word is ink; no ochre. The index line takes Kitchen lean once Builder A's pass lands (PO06, Q6). Still open: the Ingredient-page sentences marked proposed (PW16).

**Product**
- Nothing open from the 4:32 pm or 6:39 pm rulings (Q1 to Q4, Q7 and Q10 are ruled; a no-change tie shows no receipt). Still open: rename behaviour (PE18).

**QA**
- Dash and ellipsis audit of every pantry string (PG57); split the sixteen not-ours "out of X" phrases (PG40) into separate rows if a regression needs it.

## 11. Open questions

1. **124 versus 118. Ruled 4:32 pm:** 118 distinct names; the spec's count is corrected to 118 and Core writes those.
2. **Backfill marker. Ruled 4:32 pm:** the Settings key `pantryBackfilled`, set when the backfill finishes; never inferred from ingredient state (PB09, PB19).
3. **Existing app tests.** `PantryLedgerTests`, `PantryFrontTests` and `GroceriesFinishTests.undoAfterFinishPutsPantryBack` assert derive-at-read behaviour. **Ruled 4:32 pm:** they are rewritten for stored state when Core builds it, and hard-code no catalog number.
4. **Tie at the same instant. Ruled 4:32 pm:** one rule for backfill and live writes: the surer state wins (out over low over in) and an older timestamp never overwrites a newer one; the spec's equal-timestamp line is replaced (PD31, PD32). **No-change tie ruled 6:39 pm (G178):** when the tie leaves the state unchanged (a phrase says `in`, the state stays `low`), nothing is written and there is no receipt, haptic or UNDO (PD31, PE15).
5. **Catalog number.** The ruling says v11 after v10; master is still 9. Does the Habit/imagery work land first, or does Core write the bump now and risk a renumber ("never a renumber")?
6. **Ochre on the index line.** `PantryColour` also served "the index line". Answered by the 6:43 pm correction (sheet 99 section 4): ink today, Kitchen's `areaLean` once Builder A's area-colour pass lands (PO06, a pending note, not a failure).
7. **Duplicate ingredient keys. Ruled 4:32 pm:** `Egg` and `Eggs` fold to one key through the Groceries normalizer; the latest timestamp wins, ties by rule 1, the surer state (PB20, PE19).
8. **Undoing an older phrase after a newer event.** The one-slot UNDO makes it rare, but "What Tess did" can undo older ops. Per-op capture (PE20) or recompute?
9. **All lines low.** Low is not counted as missing (R5), so a recipe whose every line is low is "can cook now". Intended, but worth Product's eyes.
10. **Peek word `used`. Ruled 6:39 pm (G178):** it reads `lastUsedAt`, the last time a cook finish used the ingredient, written at cook finish; Core names the accessor (PW19, PD09). Still for Core: whether staples and optional lines get `lastUsedAt`.
11. **Spec line numbers.** The spec cites `Gr:168-182` for `shopClears`; on master it is `:169-184`. Rows here use master's numbers; other spec anchors were not re-checked line by line.

## 12. Sources read

Spec lines 1 to 330 (Part 1 in full; Part 2, the paste and scale edge cases, is out of scope here), `qa/review-896.md` (all), decisions.md lines 940 to 1000, `research/fixtures/gaps-92-swipe-lean.md` (the Pantry and areaLean sections), `qa/review-902.md`, decisions.md line 965 (the 4:32 pm rulings), `docs/research/fixtures/pantry-78.md` (style and P-rows), origin/master files named in the evidence columns, the four `TesseraTests/Pantry*Tests.swift`, and the PR file list from the GitHub MCP (4 files, all docs).

## 13. The 118 distinct test names, 116 tests (G173)

Method (so Core can diff its own count): take section (e) of `docs/product/kitchen-gap-hunt-12-pantry-v2-spec-oct17.md` (clauses S1 to P2), take every backticked name after "Tests:" on each clause line, drop repeats. That gives **118 distinct names**, the number Product ruled at 4:32 pm Oct 17. They are listed once each, in clause order, one per line. Two of the 118 are not tests: `hasAnyState` (C3: the accessor Core exposes) and `usually` (F4: it points at the existing 20-week test, "existing `usually` 20-week test, re-run"). Product ruled to publish 116 tests: the list holds 118 distinct names, of which 116 are tests Core writes or reruns and two are pointers, which Kitchen's walk script dropped to count 116 (G173). Both numbers stand: 118 distinct names, 116 tests. All 118 are on the list below, none is added by this fixture.

Every name on the list now has a fixture row (PD33 to PD35 closed the last three: `theReceiptNamesTheThingFirstWithOn`, `lowIsNeverMissing`, `planningSkipsInLinesAndAddsLowAndUnknown`), except the two pointers. Names in the Test column that are not on the list are the NEW rows' names (this fixture proposes them; the spec gives them none): 89 distinct names. `twoUnknownLinesFadeARecipeDown` (PR05) is one of them, and `theInRuleComesAfterTheCheckedRowRule` (PD28) is on the list.

```
theCatalogBumpAddsThePantryFieldsToAnOldStore
theBumpKeepsEveryOldIngredientValueAndId
noGRDBMigrationIsAddedForPantry
anUntouchedIngredientIsUnknown
unknownIsNeverWritten
anOlderBuildRefusesTheNewCatalog
theBackfillMatchesTheLedgerOnTheTacosFixture
theBackfillRunsOnce
theBackfillKeepsALaterStateIntact
theBackfillIsNotUndoable
nothingChangesNinetyDaysLater
aDeletedIngredientIsNotListed
aDeletedIngredientIsUnknownToMissing
theSharedExportHoldsNoPantryState
theBackupKeepsPantryState
thePackSnapshotsCarryNoPantryFields
aPantryShapedMissStaysOnThePhone
theLiftedLedgerGivesTheAppLedgersAnswers
saltIsAStapleOnTheRecipePageToo
groceriesAndMissingAgreeOnStaples
theRhythmReadsTheShopClears
aShopClearSetsEachCheckedIngredientIn
clearingPackingSetsNoPantryState
aClearKeepsANewerCookState
aClearStillUpdatesLastBoughtAt
undoingAClearRestoresPantryState
undoingDoneShoppingRestoresPantryState
aPutAwayBasketSetsTheItemsIn
finishingTheTacosSetsLowAndOut
aStapleIsNeverMadeLowByCooking
anOptionalLineIsNotUsedUp
editingARecipeDoesNotRewritePantry
aPrivateCookWritesStateAndSaysNothing
theStateWordCyclesInLowOutIn
eachCycleTapIsOneOpWithItsUndo
outOfMilkSetsOutAndAddsARow
weAreOutOfEggsAndRanOutOfRiceAreRead
milkIsGoneIsRead
noMoreRiceIsRead
outOfOatMilkLeavesMilkAlone
outOfTwoPercentMilkFindsMilk
outOfMilkChocolateLeavesMilkAlone
eggsFindsEgg
outOfMilkAndEggsIsOneOp
macAndCheeseIsOneItem
outOfBreathBedAndTimeAreNotClaimed
noMoreRepsIsNotClaimed
haveACallAt3IsNotClaimed
gotAHaircutSatIsNotClaimed
theMilkIsOutIsNotClaimed
remindMeWeAreOutOfMilkStaysATask
outOfMilkThursdayStaysATask
outOfFiveIsNotClaimed
outOfChalkIsNotClaimed
haveRiceSetsIn
gotMilkSetsInAndTheBoughtDay
haveRiceDoesNotTouchTheBoughtDay
theRowCarriesTheLastTypedAmount
aRecipeShareIsNotATypedAmount
noTypedAmountMeansNoAmount
alreadyOutAndOnGroceriesAddsNoSecondRow
alreadyOutButGoneFromGroceriesAddsTheRow
anItemInTheBasketIsLeftAlone
theReceiptNamesTheThingFirstWithOn
twoItemsReadMilkAndEggs
threeItemsReadMilkAnd2More
anAlreadyOnLineReadsAlreadyOnGroceries
lowOnRiceSetsLowAndAddsNoRow
pantryOpensPantry
whatDoIHaveOpensPantry
whatDoIHaveTomorrowIsTheSchedule
aKeyShapedTailWritesNothing
aSecretValueWritesNothing
aPriceTailIsStrippedAndNeverSpoken
aMedicineOutPhraseReadsPrivateItem
aSpendingPhraseIsNotThisRule
aNewRowReceiptHolds4Seconds
aStateChangeHolds10Seconds
voiceOverMakesBothTenSeconds
undoTakesBackTheStateAndTheRowTogether
aSecondReceiptReplacesTheFirstUndo
theFirstOpStaysInTheLog
takenBackReadsMilkTakenBack
takenBackForThreeItemsReadsMilkAnd2MoreTakenBack
takenBackForAPrivateItem
alreadyOnGroceriesHasNoUndo
missingGivesZeroOneAndOneToCheck
aStapleOutDoesNotCount
aStapleOnlyRecipeIsCookable
anAisleGuideStapleIsAStapleOnTheRecipePage
anOptionalLineNeverMakesAMissing
aToTasteLineNeverMakesAMissing
asNeededReadsAsToTaste
unknownIsToCheckNotMissing
lowIsNeverMissing
aLineWithNoIngredientIsSkipped
aRepeatedIngredientCountsOnce
scalingNeverChangesWhatIsMissing
aPrivateIngredientReadsPrivateItemInMissing
anIngredientUsedOnlyByPrivateRecipesIsPrivate
aPrivateRecipeGivesCountsAndNoNames
canCookRanksByMissingThenNotCookedLately
oneUnknownOutranksOneOut
neverCookedComesFirstInATie
theCanCookCountIsScoreZero
withNoStateTheFilterIsGreyedAndNothingResorts
hasAnyState
aRecipeWithNoLinesIsNeverCookable
theFilterIsNotStored
planningSkipsInLinesAndAddsLowAndUnknown
theKeyCountEqualsTheRowsAdded
paprikaChickenWithThreeKnownStatesGivesAdd6
theInRuleComesAfterTheCheckedRowRule
aBiggerSizeStillSkipsInLines
outStaplesAreNeverAdded
usually
noPantrySurfaceCarriesAWalledName
pantryOpSummariesAreMasked
```

Count: 118 lines, 118 distinct names (116 tests plus the pointers `hasAnyState` and `usually`).
