# Kitchen: nutrition from the reference library, build-ready rows (Oct 19)

Kitchen lead. Docs only: nothing built or run. Source is `docs/research/reference-library-spec.md` (merged in #1120): sections 2 (links), 3 (copy on edit), 4 (eight fields), 5 (exclusions) and rules R10, R16, R17, R17b, R17c, R18, R25, R28, R31, R32. Existing screen rows stay: `kitchen-sides-acceptance.md` 2.1, 2.1b, 2.1c, 2.4, `kitchen-error-states-acceptance.md` ER26, `never-sums-audit.md` N5. This page adds only what the library changes. A row marked "inferred" is my reading, not a ruling. It has had no QA read yet.

Gate: nutrition waits on his yes (Product, Oct 19). The Review switch below is Off until then; Off, the PER 100 G side reads the 271-key table as today.

Product rulings folded in: key is `fiber` (US English), so the shown word on row 2.1 changes from "fibre" to "fiber"; portion pick = match the line's unit, else no grams; private ingredients mask the library snapshot and the suggestion; R25 follows the capture-miss route.

## NU Engine rows

| ID | Clause | How checked | Owner | Depends on |
|---|---|---|---|---|
| NU-E1 | A food row holds the eight fields (`energyKcal` kcal, `protein` g, `fat` g, `carbohydrate` g, `fiber` g, `sugars` g, `sodium` mg, `saturatedFat` g) per 100 g, stored as published; a missing nutrient is null, never 0 | R16 `foodRowsHaveTheAgreedFieldsAndUnits` | Kitchen | #1120 |
| NU-E2 | The 20 fixture keys of `food-table-20.json` match the bundle after the move from the 271-key table; chicken thigh still reads 121 kcal, 19.7 g protein, 0 g carbohydrate, 4.1 g fat, 0 g fiber | R18 `foodFixtureKeysMatchTheBundle` + 2.1 | Kitchen | NU-E1 |
| NU-E3 | No row or portion carries a per-serving or total field | R17 `noFoodRowHasPerServingOrTotalFields` | Kitchen | NU-E1 |
| NU-E4 | No code multiplies a portion's `gramWeight` by a nutrient value; the side shows the per-100 g figures plus the gram conversion of the line, nothing else | R17b `noCodeMultipliesPortionGramsByNutrients`, plus the build-failing import test of the ship note | Kitchen | NU-E3 |
| NU-E5 | A food with several portions uses the one whose label matches the recipe line's unit; with no match it shows no grams and no guess | R17c `portionPickedByUnitMatchElseNoGrams` | Kitchen | NU-E4 |
| NU-E6 | Linking an ingredient to a food is one op on his object and copies no nutrient value; the match is suggested by name and confirmed by him, never silent | R10 `linkingAFoodCopiesNoFacts` | Kitchen | spec 2.4 |
| NU-E7 | A private ingredient gets no name-match suggestion and its `libraryRef` title snapshot masks with it | R31 `privateIngredientShowsNoLibraryTitleOrSuggestion` | Kitchen | NU-E6 |
| NU-E8 | A recipe scaled by `RecipeMath.scaled` changes the gram conversion of the line only; the per-100 g figures do not change (inferred) | new test `scalingChangesGramsNotPer100g` in RecipeMathTests.swift | Core | NU-E5 |
| NU-E9 | Reading a library food writes no op and nothing is sent to Claude as "his data"; an unreadable phrase about food follows the capture-miss route as any other (R25) | R3, R26, R25 | Core | #884 |

## NU Screen rows

| ID | Clause | How checked | Owner | Depends on |
|---|---|---|---|---|
| NU-S1 | The side shows the eight values in the field order of spec section 4, rounded for display only (kcal whole, grams one decimal, sodium whole mg), never "0.0 g"; a null field is left out of the list, not shown as 0 | walk: chicken thigh, a food with no sodium | Builder B | 2.1c |
| NU-S2 | The source line reads "USDA FoodData Central" under the numbers; the full line lives on the Sources page | walk, R23 | Builder B | 2.1 |
| NU-S3 | With one portion matched, the line reads its grams once ("1 cup, chopped, 130 g"), ink only; unmatched shows no grams line | walk | Builder B | NU-E5 |
| NU-S4 | A masked ingredient (Pantry, Groceries, recipe line) shows "Private item" and no library facts | R32 `maskedPantryAndGroceryItemsShowNoLibraryFacts` | Builder B | NU-E7 |
| NU-S5 | A library page's "used in" shows a private recipe as "Private recipe" | R28 `libraryBacklinksMaskPrivateObjects` | Kitchen | spec 5 |
| NU-S6 | No nutrition total on any screen: not a recipe, a day, a shop or a cook; Review and Home never mention calories | 2.4, N5 | Builder B | NU-E4 |
| NU-S7 | Switch Off: the side reads the 271-key table as today and no library mark or "Compare" control shows | walk with the switch Off | Builder B | switch |

Review switch: Nutrition from the library, default Off, before/after: Off, the side reads the 271-key table / On, the side reads the library food, eight values, with the grams of the line. Name not yet in ReviewChoices; Builder B adds it.

Open: (1) Row 2.1 and its fixture say "fibre"; rename to "fiber" with the key. (2) Whether "Compare with library" appears on the ingredient page at all (copy on edit, spec section 3): not written, left for Product. (3) Rounding of sodium (whole mg) and sugars (one decimal) is inferred.
