# Egg/Eggs fold, lastUsedAt on staples and optional lines, PO07 ink contrast

For: Core (engine, privacy), Builder B (Groceries, Recipes, Pantry screens), QA. Docs only; nothing was built or run (no Swift toolchain). Rests on Product's 4:32 pm Oct 17 ruling (3) and the 6:39 pm and 6:45 pm Oct 17 rulings (`decisions.md` lines 965, 977, 983). Row style, ids and owners follow `pantry-v2.md` (open PR #920, branch `claude/research-pantry3`). Rows already there are referenced, not repeated: PB20, PE19, PR23 (Egg/Eggs fold), PD09, PD10, PD11 (cook finish and staples), PW19, PR28 (peek word `used`), PO07 (contrast, whose ink figure is computed here), PR29.

Status words: **traced** means I read the master line and it does what the row says; **inferred** follows from code not read in full; **gap** means master has nothing for it. Owners: Core = engine and privacy, Builder B = Groceries, Recipes and Pantry screens.

Master facts read: the Groceries normalizer is `IngredientLine.key(for:)` (`TesseraCore/Sources/TesseraCore/Kitchen/Quantities.swift:281-284`): `rawKey(for:)` lowercases and singularizes, then `aliases[key] ?? key`. So `Egg` and `Eggs` both give key `egg`. `IngredientBook.find` returns the first match (`Ingredients.swift:23`), so two rows survive today. No `lastUsedAt` exists in Swift on master.

## 1. Egg/Eggs fold (EF)

| Id | Input | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| EF01 | `IngredientLine.key(for:)` on `Egg`, `Eggs`, `eggs`, `EGGS` | all four give `egg` | `Quantities.swift:281-284` | traced | Core | `eggAndEggsShareOneKey` |
| EF02 | Backfill sees `Egg` (in, Saturday 10:00) and `Eggs` (out, Sunday 18:30) | one ingredient, key `egg`, state `out`, stateAt Sunday 18:30; later timestamp wins (extends PB20) | `find` returns first match, no fold | gap | Core | `backfillFoldsEggAndEggsToOneKey` (PB20 name, not new) |
| EF03 | Same pair, both stamped Sunday 18:30, `Egg` in and `Eggs` low | one row, state `low` (surer wins: out over low over in) | none | gap | Core | `foldTieKeepsTheSurerState` |
| EF04 | Same pair, `Eggs` older than `Egg` | newer stamp wins, the older never overwrites; tie that changes nothing writes nothing, no receipt, no haptic | none | gap | Core | `foldNeverLetsAnOlderStampWin` |
| EF05 | Fold runs a second time (second launch) | no op written; `pantryBackfilled` already set | none | gap | Core | `foldIsIdempotent` |
| EF06 | Shop clear checks a row titled `Eggs` while the folded ingredient was created as `Egg` | writes `in` and `lastBoughtAt` on the folded key, no second ingredient made | none | gap | Core | `aClearWritesTheFoldedKey` |
| EF07 | Cook finish with line "2 eggs" when `Egg` exists | `low` or `out` lands on the folded key | none | gap | Core | `aCookWritesTheFoldedKey` |
| EF08 | Phrase `we're out of eggs` (grammar PG01 style) with the folded ingredient titled `Egg` | finds it; `Egg, out. On Groceries.` (PG13 reads the title, not the typed word) | `Ingredients.swift:20-24` | traced (find) | Core | `eggsFindsEgg` (PG13 name, not new) |
| EF09 | Pantry list after the fold | one line `Egg`, never two; the surviving title is the older ingredient's | none | gap | Builder B | `pantryListsTheFoldedEggOnce` |
| EF10 | Fold when both rows carry `lastBoughtAt` and `lastUsedAt` | each field keeps its own latest value across the pair | none | gap | Core | `foldKeepsTheLatestOfEachDate` |
| EF11 | `Egg` is private-titled and `Eggs` is not | fold keeps the private wall: the folded row reads its private label, no plain word leaks | `ObjectPrivacy.isPrivateRecipeTitle` is the wall for labels (`PantryLedger.swift:166`) | inferred | Core | `foldNeverUnmasksAPrivateTitle` |
| EF12 | `Tomatoes` and `Tomato`, `Onions` and `Onion` | fold like eggs (the rule is the normalizer, not an egg special case) | `Quantities.swift:281-284` | traced (key) | Core | `anyPluralPairFoldsThroughTheNormalizer` |
| EF13 | `Whole milk` and `Milk` | fold via `aliases` ("whole milk is milk") | `Quantities.swift:280-284` comment | inferred | Core | `anAliasPairFoldsThroughTheNormalizer` |
| EF14 | `Red onion` and `Onion` | do not fold (red onion stays) | `Quantities.swift:280-281` comment | inferred | Core | `redOnionStaysSeparate` |

## 2. lastUsedAt on cook finish (LU)

Ruled 6:45 pm Oct 17: staples and optional lines get `lastUsedAt` too; it is a fact about use. They do not count toward the drop. "No drop count" means no state change and no part in the hero or the `N low` / `N out` figures. The peek word `used` reads `lastUsedAt` (6:39 pm, G178).

| Id | Input | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| LU01 | Finish the tacos (PD09 facts: salt is a staple line, "pepper to taste", "parsley for serving") | `lastUsedAt = cookedAt` on chicken, onion, tortillas, cilantro, limes (as PD09) and also on salt; state unchanged for salt | `FinishCooking` writes `cookedAt` only (`Kitchen/Cooking.swift:287-303`) | gap | Core | `aCookStampsLastUsedOnEveryLineIncludingStaples` |
| LU02 | Cook with line "jam, optional" | `lastUsedAt = cookedAt` on jam; state untouched (PD11 still holds) | `PantryLedger.swift:155` skips optional for state | gap | Core | `anOptionalLineGetsLastUsedButNoState` |
| LU03 | Cook with Aisle-guide staple "olive oil", field `isStaple` false | `lastUsedAt` set; never made low (PD10 still holds) | `PantryLedger.swift:155-156,172-175` | gap | Core | `anAisleGuideStapleGetsLastUsedButIsNeverLow` |
| LU04 | Cook with "pepper to taste" | `lastUsedAt` set, state untouched | none | gap | Core | `aToTasteLineGetsLastUsedButNoState` |
| LU05 | Same cook finish | the `lastUsedAt` writes and the state writes are one op; one UNDO restores both | none | gap | Core | `lastUsedAndStateWriteInOneCookFinishOp` |
| LU06 | Cook finish, then the 4 s receipt UNDO | `lastUsedAt` returns to its earlier value (or unset) | none | gap | Core | `undoPutsLastUsedBack` |
| LU07 | Recipe cooked twice, Sunday then Wednesday | `lastUsedAt` = Wednesday; Sunday never restored by a later cook | none | gap | Core | `theLaterCookWinsLastUsed` |
| LU08 | Cook abandoned (process ended without Finish) | `lastUsedAt` not written; only a cook finish writes it | `FinishCooking` is the only writer (`Cooking.swift:287-303`) | inferred | Core | `anAbandonedCookWritesNoLastUsed` |
| LU09 | Hero and counts after LU01 | `1 out, 2 low`-style figures count states only; staples and optional lines add nothing to any count | `PantryLedger.swift:72-79` (app-side words) | gap | Core | `lastUsedOnAStapleDoesNotMoveTheDropCount` |
| LU10 | Recipe page peek on salt after LU01 | staples show nothing (PW19 holds); the date is stored but not drawn | `Recipes.swift:96` | gap | Builder B | `aStaplePeekStaysEmptyEvenWithLastUsed` |
| LU11 | Peek on tortillas after LU01 | word `used` reads `lastUsedAt` (Sunday), per PW19 and PR28 | none | gap | Builder B | `thePeekUsedReadsLastUsedAt` |
| LU12 | Peek on an ingredient no cook has used | no `used` word (PW19) | none | gap | Builder B | `noLastUsedShowsNoUsedWord` |
| LU13 | Peek on an optional line (jam) after LU02 | no `used` drawn if the peek hides optional lines; whether the optional line shows `used` is a question for Design (see Q1) | none | gap | Builder B | `anOptionalLinePeekFollowsTheDesignAnswer` |
| LU14 | Private-titled recipe cooked | `lastUsedAt` is written (a fact), but any word built from it reads the private label, never the title | `PantryLedger.swift:166` | inferred | Core | `lastUsedNeverLeaksAPrivateRecipeTitle` |
| LU15 | Cook line "eggs" with `Egg` and `Eggs` both existing | `lastUsedAt` lands on the single folded key (joins EF07) | none | gap | Core | `lastUsedLandsOnTheFoldedKey` |
| LU16 | `lastUsedAt` on an ingredient whose state is edited by hand afterwards | `lastUsedAt` unchanged (a state tap writes `stateAt`, never `lastUsedAt`) | none | gap | Core | `aHandEditLeavesLastUsedAlone` |
| LU17 | Shop clear on a staple | writes `lastBoughtAt` as PD01 says; `lastUsedAt` untouched | `Groceries.swift:169-184` | gap | Core | `aClearNeverWritesLastUsed` |

## 3. PO07 ink contrast, computed

PO07 in `pantry-v2.md` says the ink figure "is measured by the test, no figure is claimed". Product (6:45 pm) asked Research to compute and record it. Ruling: the Pantry row state word is plain ink, not `areaLean`; `areaLean(.kitchen)` goes only on the caps labels and the index line.

Inputs, read from master `DesignSystem/Looks.swift`: Porcelain ink `0x121016`, ground `0xFFFFFF`, raised `0xF6F5F9` (line 54); Obsidian ink `0xF5F2EC`, ground `0x000000`, raised `0x0F0E12` (line 62).

Math (WCAG 2.x): each sRGB byte c/255 = s; linear = s / 12.92 if s <= 0.03928, else ((s + 0.055) / 1.055)^2.4. L = 0.2126 R + 0.7152 G + 0.0722 B. Ratio = (L_light + 0.05) / (L_dark + 0.05). Computed with a short script (Python 3, stdlib only).

| Id | Text | Ground | L text | L ground | Ratio | Bar | Status | Owner | Test |
|---|---|---|---|---|---|---|---|---|---|
| PO07a | state word, ink `#121016` | Porcelain `#FFFFFF` | 0.005571 | 1.000000 | (1.05) / (0.055571) = **18.89:1** | 4.5 | traced (hexes), computed | Core | `pantryStateWordInkContrastAtLeastFourPointFive` |
| PO07b | state word, ink `#F5F2EC` | Obsidian `#000000` | 0.889729 | 0.000000 | (0.939729) / (0.05) = **18.79:1** | 4.5 | traced, computed | Core | `pantryStateWordInkContrastAtLeastFourPointFive` |
| PO07c | caps label, `areaLean(.kitchen)` `#126E52` | Porcelain `#FFFFFF` | 0.118897 | 1.000000 | **6.22:1** | 4.5 | reused (`arealean-tokens.md` T02), recomputed, matches | Core | `areaLeanLabelContrastAtLeastFourPointFive` (AL11) |
| PO07d | caps label, `areaLean(.kitchen)` `#72DCB1` | Obsidian `#000000` | 0.579381 | 0.000000 | **12.59:1** | 4.5 | reused (T05), recomputed, matches | Core | `areaLeanLabelContrastAtLeastFourPointFive` (AL11) |
| PO07e | state word, ink `#121016` | Porcelain raised `#F6F5F9` | 0.005571 | 0.917372 | **17.41:1** | 4.5 | computed, extra | Core | `pantryStateWordInkContrastAtLeastFourPointFive` |
| PO07f | state word, ink `#F5F2EC` | Obsidian raised `#0F0E12` | 0.889729 | 0.004593 | **17.21:1** | 4.5 | computed, extra | Core | `pantryStateWordInkContrastAtLeastFourPointFive` |
| PO07g | caps label `#126E52` | Porcelain raised `#F6F5F9` | 0.118897 | 0.917372 | **5.73:1** | 4.5 | computed, extra | Core | `areaLeanLabelContrastAtLeastFourPointFive` |
| PO07h | caps label `#72DCB1` | Obsidian raised `#0F0E12` | 0.579381 | 0.004593 | **11.53:1** | 4.5 | computed, extra | Core | `areaLeanLabelContrastAtLeastFourPointFive` |

Reading: every pair clears 4.5:1 with room (lowest is 5.73:1, the Porcelain caps label on the raised surface). The ink figures are 18.89:1 on Porcelain and 18.79:1 on Obsidian. Only Porcelain and Obsidian are computed here; the other three looks are in `arealean-tokens.md` for the caps labels and are not repeated, and ink on Plein, Lacquer and Celadon is not computed (not asked). The unit test still measures live values; these figures are the expected values it should reproduce to two decimals.

## 4. Questions

- Q1 (Design): should the peek draw `used` for an optional line (jam), or only for lines that count? The data is stored either way (LU02); this is a display choice (LU13).
- Q2 (Core): name the `lastUsedAt` accessor (6:45 pm leaves the name to Core); the tests above call it only through the ingredient.

## 5. Counts and test names

14 EF rows, 17 LU rows, 8 PO07 rows: 39 rows. Status tally: EF traced 3 (EF01, EF08, EF12), inferred 3 (EF11, EF13, EF14), gap 8; LU inferred 2 (LU08, LU14), gap 15; PO07 8 computed (4 of them reuse T02 and T05 ratios or extras).

Test names (distinct, 36 new plus 3 reused, listed once):
`eggAndEggsShareOneKey`, `foldTieKeepsTheSurerState`, `foldNeverLetsAnOlderStampWin`, `foldIsIdempotent`, `aClearWritesTheFoldedKey`, `aCookWritesTheFoldedKey`, `pantryListsTheFoldedEggOnce`, `foldKeepsTheLatestOfEachDate`, `foldNeverUnmasksAPrivateTitle`, `anyPluralPairFoldsThroughTheNormalizer`, `anAliasPairFoldsThroughTheNormalizer`, `redOnionStaysSeparate`, `aCookStampsLastUsedOnEveryLineIncludingStaples`, `anOptionalLineGetsLastUsedButNoState`, `anAisleGuideStapleGetsLastUsedButIsNeverLow`, `aToTasteLineGetsLastUsedButNoState`, `lastUsedAndStateWriteInOneCookFinishOp`, `undoPutsLastUsedBack`, `theLaterCookWinsLastUsed`, `anAbandonedCookWritesNoLastUsed`, `lastUsedOnAStapleDoesNotMoveTheDropCount`, `aStaplePeekStaysEmptyEvenWithLastUsed`, `thePeekUsedReadsLastUsedAt`, `noLastUsedShowsNoUsedWord`, `anOptionalLinePeekFollowsTheDesignAnswer`, `lastUsedNeverLeaksAPrivateRecipeTitle`, `lastUsedLandsOnTheFoldedKey`, `aHandEditLeavesLastUsedAlone`, `aClearNeverWritesLastUsed`, `pantryStateWordInkContrastAtLeastFourPointFive`. Reused from `pantry-v2.md`: `backfillFoldsEggAndEggsToOneKey`, `eggsFindsEgg`, `areaLeanLabelContrastAtLeastFourPointFive`.
