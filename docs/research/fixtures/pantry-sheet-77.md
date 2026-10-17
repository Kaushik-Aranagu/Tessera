# Pantry fixtures for sheet 77, and the "never sums" rows

For: Kitchen lead, Core, Builder B
Date: 2026-10-17 · Research lab (task BV)
Inputs read: `product/pantry-acceptance.md`, `research/pantry-light.md`, `product/groceries-ai-acceptance.md` (sections 4 and 6), `product/kitchen-sides-acceptance.md`, `product/never-sums-audit.md`, `product/decisions.md` (2:36 PM and 5:47 PM Oct 16).

## 0. What could not be read

Sheet 77 is not in the Design folder. `design/` holds no sheet 77 or 78 file (only `pantry-light.mp4`, a video I did not open, and `design/kitchen/kitchen-v2.md`, which predates the sheet). `decisions.md` (5:47 PM Oct 16) says sheet 77 is the seven drawn sides that sheet 75 declares, and that Pantry as an area is sheet 78. So every screen-layout row below is built from `pantry-acceptance.md` alone and is marked **[S77?]**: the words and order are the Kitchen lead's defaults, not Design's drawing. Engine rows (marked **[engine]**) do not depend on the sheet. Rows marked **[S77 side]** assume Pantry has a side page, which `pantry-acceptance.md` does not describe; only the never-sums outcome is fixed there, not the copy.

Conventions: all times Pacific; a time, if shown, is lowercase 12-hour ("6:10 pm"). All values are made up. Money rows use an amount or a currency sign. "Leaves phone" means anything sent to Claude. For pantry facts the answer is always **nothing** (`pantry-acceptance.md`, "The one rule" and "Claude: Nothing leaves the phone").

## 1. The rules these rows test

- **Kitchen lead, pantry-acceptance.md, "The one rule":** the phone "never counts, never asks, never guesses a quantity, and never sends any of it to Claude." An unknown is shown as unknown. State is only in, low, out, unknown, and changes only on an event.
- **Kitchen lead, groceries-ai-acceptance.md section 6:** a price on an item is stripped and dropped, and the item stays; a line that is only money never lands as a row. A pack or an amount ("2 lb chicken", "6 eggs") is not a price and keeps its number.
- **Kitchen lead, never-sums-audit.md N6 and kitchen-sides-acceptance.md 2.4:** Pantry shows states and dates only; no screen sums nutrition; the app never totals a shop, a day or a recipe.
- **Rule for this fixture (derived, flagged):** no Kitchen ruling lets Pantry show a "you have 3 kg" style sum, a stock total or a money total. None was found, so the default is: never. If a ruling exists that I could not find, it overrides rows N1 to N6 and Product should say so. The only quantity the pantry may show is one read straight from a label or a typed line, unchanged, for one ingredient (rows N7, N8).
- Existing master code merges same-ingredient amounts on one open Groceries row ("600 g", `Groceries.swift:164-165`). That is a need on a list, not stock on hand, and is not shown in Pantry.

## 2. Week of logs turning into states and lines

Week of Sat 2026-10-10 to Fri 2026-10-16. Start state: every ingredient unknown unless the row says otherwise.

| # | Input history | Expected line (Pantry) | Leaves phone | Swift Testing name | Depends |
|---|---|---|---|---|---|
| W1 | Sat 10 shop clears with milk, eggs, rice checked (10:40 am) | Counts line "nothing known yet" is replaced by "0 out, 0 low"; in group lists "milk, bought Sat", "eggs, bought Sat", "rice, bought Sat" | nothing | `shopClearSetsCheckedToInWithBoughtDate` | [S77?] lines; engine part [engine] |
| W2 | W1, then Mon 12 an unchecked item (bread) is removed from the list | bread stays unknown, not listed | nothing | `removedUncheckedItemStaysUnknown` | [engine] |
| W3 | W1, then Tue 13 cook finished: tacos with chicken, onion, tortillas, cilantro, limes | chicken, onion, tortillas low; cilantro, limes out; counts line "2 out, 3 low" | nothing | `finishCookingSetsLowAndProduceOut` | [engine]; counts copy [S77?] |
| W4 | W3 with salt and oil marked staples in the recipe | staples untouched, not listed | nothing | `finishCookingLeavesStaplesAlone` | [engine] |
| W5 | W3, then Wed 14 "out of milk" typed to Tess | milk moves to out; Tess says "Milk, out. On Groceries."; Groceries gains "milk" with the last typed amount in one op | nothing | `outOfPhraseSetsOutAndAddsToGroceries` | [engine]; receipt text is the Kitchen lead's |
| W6 | W5, UNDO within 4 s | milk back to in, row removed from Groceries, both in one undo | nothing | `undoOutOfMilkRestoresStateAndList` | [engine] |
| W7 | Thu 15 "have rice" | rice in; no Groceries change | nothing | `haveRiceSetsInOnly` | [engine] |
| W8 | Thu 15 tap the state word on the rice Ingredient page, 3 taps (in, low, out, in) | one op per tap; rice reads in after the third; UNDO reverses one step | nothing | `stateCycleWritesOneOpPerTap` | [engine]; page copy [S77?] |
| W9 | Fri 16 swipe left on cilantro (out) in Pantry | ghost row "Cilantro, on Groceries." with UNDO for 4 s; no remove from Pantry | nothing | `swipeOutLineAddsGhostRowNotRemove` | [S77?] |
| W10 | Sat 17 second shop clears with cilantro, limes, milk checked (9:05 am) | all three in, `lastBoughtAt` = 2026-10-17; counts line "0 out, 3 low" if chicken, onion, tortillas still low | nothing | `secondShopResetsOutToIn` | [engine]; counts copy [S77?] |
| W11 | Milk bought weekly for 5 shops (the pantry-light fixture rows), none typed this week | Pantry still shows milk "bought Sat" (state does not expire); the USUALLY line may also name milk | nothing | `inStateNeverExpiresByTime` | [engine] (open question 1 default) |
| W12 | Six weeks pass with no event | no state moves; line unchanged | nothing | `stateNeverChangesByTimePassing` | [engine] |
| W13 | Week 5 of `pantry-light.md` section 7: eggs, bread, bananas typed, milk due | USUALLY line "milk" (label USUALLY, ink words; Pantry foot repeats Groceries) | nothing | `usuallyLineMatchesGroceriesInPantry` | [engine] cap 4; placement [S77?] |
| W14 | Five names due at once | line shows 4 names, most overdue first | nothing | `usuallyCapsAtFourNames` | [engine] |
| W15 | Planning "Paprika chicken" with chicken in, lemon low, yogurt out, rest unknown | peek reads "have", "low", "out" on those lines; key "ADD 6 TO GROCERIES", every line but chicken | nothing | `planSkipsInAddsLowAndUnknown` | [engine]; key text from acceptance |
| W16 | Recipe with one non-staple line out and one unknown | `RecipeMath.missing` gives "1 missing: lemons" and "1 to check: lemons"; unknown never adds | nothing | `missingCountsOutAndUnknownDistinctly` | [engine] |

## 3. Cases that must show nothing

| # | Input history | Expected line | Leaves phone | Swift Testing name | Depends |
|---|---|---|---|---|---|
| Z1 | Fresh install, no shop, no cook | counts line "nothing known yet" and one line "Clear a shop or finish a cook and this fills in."; no empty-state art | nothing | `emptyPantryShowsNothingKnownYet` | [S77?] copy from acceptance |
| Z2 | Ingredient never touched | not listed in Pantry (unknown is the long tail) | nothing | `unknownIngredientsAreNotListed` | [engine] |
| Z3 | Two buys only in 56 days | USUALLY empty and takes no space | nothing | `usuallyNeedsThreeBuys` | [engine] |
| Z4 | Item already on the list or in the basket | not in USUALLY | nothing | `usuallyHidesItemsAlreadyOnList` | [engine] |
| Z5 | Shop cleared with a shown name unbought | that name quiet until next buy (`usualSkippedAt`) | nothing | `skippedUsualStaysQuiet` | [engine] |
| Z6 | Any state change | no notification, badge, Home offer or Live Activity | nothing | `pantryNeverNotifies` | [engine]/[S77?] |
| Z7 | Pack snapshot built for AI-12 after W1 to W16 | holds no state and no `lastBoughtAt` | nothing | `packSnapshotHoldsNoPantryFacts` | [engine] |
| Z8 | Nutrition values exist for chicken in the food table | no nutrition word or number anywhere in Pantry, its counts line or its side | nothing | `pantryShowsNoNutrition` | [S77?] (never-sums N6) |

## 4. The "never sums" rows

None of these rows ever shows a total. The expected line is "nothing" or the single quoted value shown.

| # | Input history | Expected line | Leaves phone | Swift Testing name | Depends |
|---|---|---|---|---|---|
| N1 | Three shops this week, each with a typed total "$38.40", "$52.10", "$41.00" | Pantry shows no money at all, no weekly or monthly total, no "spent" line | nothing (money never goes to Claude) | `pantryNeverShowsMoneyTotal` | [engine] + [S77?] |
| N2 | Add line: "milk $4" | row "milk", receipt "Milk, on Groceries."; "$4" held nowhere, so Pantry cannot show it | nothing | `priceOnItemIsStrippedBeforePantry` | [engine] (groceries-ai W1) |
| N3 | "$40 at costco" typed in Groceries | never lands as a row; becomes a private dated note "Private note, kept."; Pantry unchanged | nothing | `moneyOnlyLineNeverReachesPantry` | [engine] (groceries-ai W2) |
| N4 | Ingredient "chicken" bought three times, "2 lb", "1 lb", "3 lb" | Ingredient page and Pantry say "bought Sat" only; never "6 lb" and never "you have 6 lb" | nothing | `pantryNeverSumsBoughtQuantities` | [engine] + [S77 side] |
| N5 | Rice bought as "5 kg" and "2 kg" on two shops, "have rice" typed once | state "in"; no "7 kg"; no "3 kg left" | nothing | `pantryNeverShowsKilogramSum` | [engine] + [S77 side] |
| N6 | Two milk rows, "1 l" and "2 l", merged on an open Groceries row to "3 l" | the Groceries need may read "3 l" (existing behavior); Pantry milk reads state only, never "3 l" | nothing | `groceryMergedAmountDoesNotLeakIntoPantry` | [engine] |
| N7 | A label read by the camera on a can: "14 oz" (typed from the label) | the one label amount may show unchanged, "14 oz", for that one ingredient only | nothing | `labelAmountShownUnchangedForOneIngredient` | PARKED, not a test (Kitchen lead 5:45 pm): no label-reading feature exists in any doc; wait until Kaushik asks for it |
| N8 | Same ingredient, second can label "28 oz" | each label stays its own line; no "42 oz" total | nothing | `twoLabelsNeverAddUp` | PARKED, not a test (Kitchen lead 5:45 pm); the rule stands: two labels never add up |
| N9 | Tess asked "how much rice do I have" | plain answer: she doesn't count stock; "Rice is in. Bought Sat." (state and date only) | nothing | `tessDoesNotAnswerHowMuchHave` | [engine]; line confirmed by the Kitchen lead (5:45 pm). "I don't count stock." may lead only if tess-voice.md has no shorter refusal |
| N10 | Tess asked "how much did I spend on food" | "I don't add up spending." (confirmed, Kitchen lead 5:45 pm); no number; points to nothing; no Claude call | nothing | `tessDoesNotTotalFoodSpend` | [engine]; line confirmed (5:45 pm) |
| N11 | Tess asked "how many calories is the tacos" | the plain refusal from never-sums N8; offers one ingredient's side; no number | nothing | `tessRefusesRecipeCalorieTotal` | [engine] (never-sums N8) |
| N12 | Counts line "4 out, 2 low" with 6 ingredients | counts are of states, not of amounts; no "6 items" total of stock, no "of 40" | nothing | `countsLineCountsStatesNotAmounts` | [S77?] |
| N13 | Swipe adds three out lines to Groceries (cilantro, limes, milk) | receipt names the lines ("Cilantro, on Groceries."), never a money or weight total for the add | nothing | `addOutLinesReceiptNeverTotals` | [S77?] |
| N14 | Backup or export after W1 to W16 | holds states and dates only; no derived sum | nothing | `exportHoldsNoPantrySums` | [engine] (never-sums N10) |

## 5. Counts

Rows: 16 (week) + 8 (nothing) + 14 (never sums) = **38**. Rows that need sheet 77 are every one marked [S77?] or [S77 side]; the engine-only rows can be written now.
