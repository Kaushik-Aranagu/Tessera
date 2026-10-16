# Groceries on master: a check against 123 (board item 142)

For: Core, Kitchen lead, QA. Owner: Research lab. Date: Oct 16, 2026 (Pacific).
Master `5601a24` (#380 merged as `1698cf7`). Traced by hand, nothing was run. QA's `docs/qa/review-380.md` (PASS at
`6b4553b`) is taken as read; this note does not redo F1 to F3 or N1 to N4. Files are under
`TesseraCore/Sources/TesseraCore/Kitchen/` unless named. Made-up values only.

**Summary:** the five meals now give what 123 expects, except "green onions" beside his typed "scallions" (37 rows, not
36) until AI-12's KEEP lands. 9 gaps fixed, 1 superseded by a Kitchen ruling, 6 open. The engine knows each row's pack
size, but the page never draws it.

## The five meals

| Meal | 123 expects | Master writes now | Receipt |
|---|---|---|---|
| r1 tacos | 10 new rows; salt, olive oil, hot sauce off | the same 10 (GroceriesWeekTests:161) | "Tacos, 10 added." (:162) |
| r2 chili | 5 new rows; 5 join; 28 oz can its own row; cheddar off | the same; black beans "1 can + 15 oz" (:171) | "Chili, 5 added." (traced, not asserted) |
| r3 curry | 9 new rows; 14.5 oz can apart from 28 oz | the same; two "1 can" tomato rows (:178-182) | "Curry, 9 added." (traced) |
| r4 pasta, 4 then 2 | 6 new rows; red pepper flakes ½ tsp | 6 rows; flakes **⅛ tsp** (G-R16 replaced 123's own ½ tsp, :192) | "Pasta, 6 added.", then **"Pasta, 6 added." again** on the resize (new item 1) |
| r5 frittata | 3 new; eggs, milk, spinach join | the same; eggs "8", milk "¼ cup" (:202-210) | "Frittata, 3 added." (:203) |
| Week | 36 rows | **37**: "green onions" (Produce) beside "scallions" (:213) | |

Every other row in 123's table matches (garlic "7 cloves + 1 head", spinach "1 bag + 6 cups", cilantro "½ cup + 2 tbsp").

## The gaps

| # | Status | Where (master) |
|---|---|---|
| G-R1 | Fixed | stored at Recipes.swift:209-214, read back at :70-71; scaling keeps it (RecipeMath.swift:12) |
| G-R2 | Superseded by Kitchen (acceptance :22, #383, #389): a typed amount stands, a checked row covers until the shop clears it. Built that way | Groceries.swift:211-218, :248-250, :305-309, :328-334 |
| G-R3 | Fixed | Aisles.swift:30-43 |
| G-R4 | Fixed ("plus more to serve" still adds, QA F1) | Quantities.swift:146-155; Groceries.swift:324 |
| G-R5 | Fixed (pack contents keep "diced") | Quantities.swift:216-232 |
| G-R6 | Fixed in code; the doc sentence is still stale (new item 5) | Quantities.swift:250-253, :283-297 |
| G-R7 | Fixed | Aisles.swift:71, :92, :102, :107 |
| G-R8 | Fixed in the engine; acceptance :23 still says "Design to confirm" | Groceries.swift:219-234, packs first :149-154 |
| G-R9 | **Open** (Builder B): recipe line is full titles joined by ", ", and the dab is still drawn | Features/Groceries/GroceriesView.swift:196, :435-441 |
| G-R10 | **Open** (AI-12): no add on planning, no `linkItems`, no KEEP or NOT NOW on master | nothing to cite |
| G-R11 | **Open** (AI-12): ruled at acceptance :56, no code yet | |
| G-R12 | **Open** (AI-12): ruled at acceptance :38 and docs/ai/architecture.md:169, no pack code yet | |
| G-R13 | **Open**: at 0 Home still says "nothing to buy"; ruled at acceptance :83 | Home/HomeLines.swift:401 |
| G-R14 | Fixed; short name per decisions.md:27 | Groceries.swift:347-351, :359-363; Recipes.swift:33-49 |
| G-R15 | **Open** (Design): no ruling found on master; code keeps the "+" | Groceries.swift:176-180; test :191 |
| G-R16 | Fixed, with a new display gap (new item 2) | RecipeMath.swift:26-28 |

Count: 9 fixed (G-R1, 3 to 8, 14, 16), 1 superseded (G-R2), 6 open (G-R9 to 13, G-R15).

## New since #380, not in 123

1. **A resize reads as new rows.** Groceries.swift:316-317 takes the recipe's open rows out before `before` is taken,
   so rows only that recipe holds are made again and counted. r4 at 4 then 2 says "Pasta, 6 added." twice, though
   nothing new reached the list. The rows also get new ids. Proposal: on a re-add, count against the set before
   `RemoveRecipeFromGroceries`, and say "Pasta, now for 2." (Product to word it). Owner Core.
2. **⅜, ⅝ and ⅞ tsp show as decimals.** G-R16 rounds teaspoons to eighths (RecipeMath.swift:28), but
   `kitchenNumber` has glyphs only for ⅛, ¼, ⅓, ½, ⅔, ¾ (:74-82). ¾ tsp cumin halved is "0.38 tsp". Proposal: add
   ⅜ ⅝ ⅞, or round to eighths only under ¼ tsp. Owner Core; add a test for 0.375.
3. **A checked row covers any pack size.** The covered check (Groceries.swift:305-308, :328-331) matches the
   ingredient only. If he checks the 28 oz tomatoes, a later curry's 14.5 oz can is skipped, though U5 keeps the two
   apart. Proposal: a checked row covers only when its pack size matches, or Kitchen rules it's fine (it follows L3).
4. **Re-add after partial check-off.** `RemoveRecipeFromGroceries` touches open rows only (:383), and checked rows
   skip as covered. So checked rows keep the old size's share while open rows take the new one. Harmless; QA N2 is the
   all-checked case. Note only.
5. **Stale doc line.** groceries-ai-acceptance.md:31 still says the key "only lowercases and singularises". Kitchen lead.
6. **Recipes pasted before v8 keep the old behavior.** Their lines have no `packSize` or `optional` (QA: "nothing
   changes"), so an old "(optional)" line still lands and old cans still sum. Re-pasting fixes it. Kitchen to decide if
   that needs a one-time re-parse of `original`.
7. **The pack size is never drawn.** `Groceries.packSize(of:)` (:68-70) has no caller under Features/, so no row shows
   " · 28 oz" yet. Builder B row, with G-R9.
8. **lb vs oz pack names.** `size()` (Quantities.swift:270-278) normalizes the word, not the amount: "1 (16 oz) bag" and
   "1 (1 lb) bag" of one thing are two rows. Loose lb and oz do sum (Groceries.swift:134-136). Rare; note only.
9. **"Tacos, 0 added." can't happen.** Zero says "Tacos, nothing to add." (Groceries.swift:362), per Product.
