# Groceries with recipes: five real meals (board item 123)

For: Core, Builder B, the Kitchen lead, Design and the AI thread. Owner: Research lab.
Date: Oct 16, 2026 (Pacific). The rows follow `docs/product/groceries-ai-acceptance.md` (sections 2, 3 and 5), Design 47
`groceries-tess.md` and Design 25 `kitchen/us-shop.md` (branch `claude/project-thread-b3tu3f`), and U1 to U7 in
`recipe-paste-corpus.md`.

The "Today" column is a hand trace of `origin/master` at f2f10f9 (`Quantities.swift`, `Ingredients.swift`, `Aisles.swift`,
`Groceries.swift`, `Recipes.swift`, `RecipeMath.swift`, `HomeLines.swift`). There is no Swift toolchain here, so nothing was
run. The add on planning, `linkItems`, KEEP and NOT NOW are not on master yet, so a planned meal is traced through
`AddRecipeToGroceries(recipe:, serves: nil)`, the path the plan will call.

**Summary:**
- The week should give **36 rows**. Master gives **44**: 9 extra rows (staples, optional lines, prep words, variety
  words, no link) and 1 wrong sum: 28 oz + 14.5 oz cans of diced tomatoes from two recipes add to "2 cans" (U5 again),
  because a recipe line never keeps its pack size (G-R1). So no recipe row on master ever shows " · 15 oz".
- 16 gaps, G-R1 to G-R16, each with an owner and a proposed default.

## The week

Kaushik, single, US Pacific, shops at Trader Joe's on Monday evening. Before planning, he has typed four bare rows:
`eggs`, `milk`, `scallions`, `bananas`. He plans the five meals below on Monday, in this order. After the tacos land, he
types `limes`.

| Handle | Meal | Planned for | Serves | Exercises |
|---|---|---|---|---|
| r1 | Sheet-pan chicken fajita tacos | Tue | 4 | shared rows, staples, "to taste", can + 15 oz, cups + tbsp, a typed bare row joining |
| r2 | Weeknight turkey chili | Wed | 6 | pack sizes, an optional line, cloves of garlic |
| r3 | Chickpea coconut curry | Thu | 4 | two can sizes of one thing, prep words |
| r4 | Sausage, white bean and spinach pasta | Sat | 4, then 2 | scaling from the recipe page, a head of garlic, a bag size |
| r5 | Spinach and feta frittata | Sun | 4 | bare rows joining, the scallions ask, a variety word |

## r1 · Sheet-pan chicken fajita tacos (Tue)

```text
1 1/2 lb boneless skinless chicken thighs, sliced
2 bell peppers, sliced
1 large yellow onion, sliced
2 tbsp olive oil
1 tbsp chili powder
1 tsp ground cumin
1 tsp kosher salt
15 oz black beans, rinsed
8 small flour tortillas
1/2 cup chopped fresh cilantro
1 lime, cut into wedges
1/2 cup sour cream
Hot sauce, to taste
```

| Line | Expected | Today |
|---|---|---|
| chicken thighs | new row, Meat and seafood, **1½ lb** | same |
| 2 bell peppers | joins r2: **3** bell peppers, Produce | same |
| 1 large yellow onion | joins r2, r3: **3** onions, Produce (proposed, G-R6) | a separate row "1 yellow onion" (`key` keeps "yellow") |
| 2 tbsp olive oil | not listed (staple) | same |
| 1 tbsp chili powder | joins r2: **4 tbsp** chili powder, Spices | right amount, but in **Other** (G-R7) |
| 1 tsp ground cumin | joins r2: **3 tsp** ground cumin, Spices | same |
| 1 tsp kosher salt | not listed (staple) | listed, Spices, "1 tsp kosher salt" (G-R3) |
| 15 oz black beans | joins r2's can: **1 can + 15 oz** black beans, "for tacos and chili · 15 oz" (proposed, G-R8) | one row "15 oz + 1 can", no pack line (G-R1) |
| 8 small flour tortillas | new row, Bakery, **8** flour tortillas | same |
| 1/2 cup chopped fresh cilantro | joins r3: **½ cup + 2 tbsp** cilantro, Produce | a separate ingredient "Chopped fresh cilantro" (G-R5) |
| 1 lime | joins r3 and the typed `limes`: **2** limes | same; typed `limes` joins and leaves the count alone |
| 1/2 cup sour cream | new row, Dairy and eggs, **½ cup** | same |
| Hot sauce, to taste | not listed | same |

Tess on planning: "Added 10 for tacos." with UNDO. Today 11 rows land (kosher salt). Home on Tuesday, before shopping:
"10 to buy" over "Tacos tonight", key GROCERIES.

## r2 · Weeknight turkey chili (Wed)

```text
1 tbsp vegetable oil
1 lb ground turkey
1 medium onion, diced
4 garlic cloves, minced
1 bell pepper, diced
3 tbsp chili powder
2 tsp ground cumin
1 (28 oz) can diced tomatoes
1 (15 oz) can kidney beans, drained and rinsed
1 (15 oz) can black beans, drained and rinsed
1 cup chicken broth
Salt and pepper, to taste
Shredded cheddar, for serving (optional)
```

| Line | Expected | Today |
|---|---|---|
| vegetable oil; salt and pepper | not listed | same |
| 1 lb ground turkey | new row, Meat and seafood, **1 lb** | same |
| 4 garlic cloves | **4 cloves** garlic (trailing "cloves" read as the unit) | same |
| 1 (28 oz) can diced tomatoes | **1 can** diced tomatoes, Cans and jars, "for chili · 28 oz" | parsed with packSize "28 oz", but the recipe line drops it: no pack line, and r3's 14.5 oz can adds in (G-R1) |
| 1 (15 oz) can kidney beans | **1 can**, "for chili · 15 oz" | "1 can", no pack line (G-R1) |
| 1 cup chicken broth | **1 cup** chicken broth, Cans and jars | in **Other** (G-R7) |
| Shredded cheddar (optional) | not listed (proposed, G-R4) | a row "shredded cheddar" with no amount, Dairy and eggs, "for chili" |

## r3 · Chickpea coconut curry (Thu)

```text
2 tbsp coconut oil
1 onion, chopped
3 cloves garlic, minced
1 tbsp grated ginger
2 tbsp Thai red curry paste
1 tsp garam masala
1 (15 oz) can chickpeas, drained
1 (13.5 oz) can coconut milk
1 (14.5 oz) can diced tomatoes
4 cups baby spinach
1 cup jasmine rice
1 lime, juiced
2 tbsp cilantro, chopped
```

| Line | Expected | Today |
|---|---|---|
| 2 tbsp coconut oil | listed, Cans and jars (not a staple; he can mark it `isStaple`) | same |
| 1 tbsp grated ginger | **1 tbsp** ginger, Produce | right aisle, but the ingredient is "Grated ginger" (G-R5) |
| 1 (15 oz) can chickpeas | **1 can**, "for curry · 15 oz" | no pack line (G-R1) |
| 1 (13.5 oz) can coconut milk | **1 can**, "for curry · 13.5 oz" | no pack line (G-R1) |
| 1 (14.5 oz) can diced tomatoes | its own row: **1 can**, "for curry · 14.5 oz". Never added to r2's 28 oz can (U5) | **wrong sum:** joins r2's row as "2 cans diced tomatoes" (G-R1) |
| 4 cups baby spinach | joins r4 and r5 (see r4) | joins |

## r4 · Sausage, white bean and spinach pasta (Sat; serves 4, then 2 from the recipe page)

```text
12 oz orecchiette
1 lb sweet Italian sausage, casings removed
1 tbsp extra-virgin olive oil
1 head garlic, cloves thinly sliced
1/4 tsp red pepper flakes
1 (15 oz) can cannellini beans, rinsed
1 bag baby spinach (6 oz)
1/2 cup heavy cream
1/2 cup grated parmesan, plus more to serve
Kosher salt and black pepper
```

Planning adds it at serves 4. On Friday he swipes the recipe page to 2: `AddRecipeToGroceries(serves: 2)` takes the
serves-4 share out first, then adds the new one, so nothing doubles. Rows below are at serves 2.

| Line | Expected at 2 | Today |
|---|---|---|
| 12 oz orecchiette | **6 oz**, Pantry | 6 oz, but in **Other** (G-R7) |
| 1 lb sausage | **8 oz** (0.5 lb rounds to a quarter, shown in oz under 16 oz) | same |
| extra-virgin olive oil; kosher salt and black pepper | not listed (staples) | both listed: "½ tbsp extra-virgin olive oil" (Cans and jars) and "kosher salt and black pepper" with no amount (Spices) (G-R3) |
| 1 head garlic | 0.5 head rounds to **1 head**. Garlic row: **7 cloves + 1 head** (r2, r3, r4) | same (G-R15 asks Design to confirm) |
| 1/4 tsp red pepper flakes | **½ tsp** (spoons round to a half, floor ½), Spices | ½ tsp, but in **Other** (G-R7, G-R16) |
| 1 (15 oz) can cannellini beans | 0.5 can rounds to **1 can**, "for pasta · 15 oz" | no pack line (G-R1) |
| 1 bag baby spinach (6 oz) | one spinach row: **1 bag + 6 cups**, "for curry and two more · 6 oz" (proposed, G-R8, G-R9) | one row "6 cups + 1 bag", no pack line |
| 1/2 cup heavy cream | **¼ cup**, Dairy and eggs | same |
| 1/2 cup grated parmesan, plus more to serve | **¼ cup** parmesan, Dairy and eggs | ¼ cup, ingredient "Grated parmesan" (G-R5); "to serve" is cut off and the line still adds, which is right here |

## r5 · Spinach and feta frittata (Sun)

```text
8 large eggs
1/4 cup whole milk
1 tbsp butter
2 cups baby spinach
4 green onions, thinly sliced
1/2 cup crumbled feta (2 oz)
1/2 tsp salt
1/4 tsp black pepper
Everything bagel seasoning, optional
```

| Line | Expected | Today |
|---|---|---|
| 8 large eggs | joins the typed bare `eggs` row: **8** eggs, "for frittata" (G-R2) | same: the share lands on the bare row and its quantity reads "8" |
| 1/4 cup whole milk | joins the typed `milk` row silently (same key, G-R6) | a new row "¼ cup whole milk" beside "milk" |
| 1 tbsp butter | new row, **1 tbsp**, Dairy and eggs | same |
| 4 green onions | ghost row, then the ask "Scallions, for the frittata?" On KEEP the green onions row folds into `scallions`, which keeps its typed amount, reads "for frittata" and moves to Produce | two rows: "4 green onions" (Produce) and "scallions" (**Other**). No ask (G-R10, G-R11) |
| 1/2 cup crumbled feta (2 oz) | **½ cup** feta, Dairy and eggs. "(2 oz)" is a note, not a pack (no pack word) | ½ cup, ingredient "Crumbled feta" (G-R5) |
| salt; black pepper | not listed | same |
| Everything bagel seasoning, optional | not listed (proposed, G-R4) | a row with no amount, Other |

Tess on planning: "Added 3 for frittata." (butter, green onions, feta are new; eggs, milk and spinach join rows already there,
G-R14). Home on Sunday after the Monday shop, with everything checked: "tonight" over "Frittata tonight", key COOK.

## The week's list, expected (36 rows)

| Aisle (walk order) | Rows |
|---|---|
| Produce (9) | 3 bell peppers · 3 onions · 7 cloves + 1 head garlic · ½ cup + 2 tbsp cilantro · 2 limes · 1 tbsp ginger · 1 bag + 6 cups baby spinach · scallions · bananas |
| Bakery (1) | 8 flour tortillas |
| Dairy and eggs (7) | ½ cup sour cream · 8 eggs · milk (with ¼ cup, G-R2) · 1 tbsp butter · ¼ cup heavy cream · ¼ cup parmesan · ½ cup feta |
| Meat and seafood (3) | 1½ lb boneless skinless chicken thighs · 1 lb ground turkey · 8 oz sweet Italian sausage |
| Cans and jars (10) | 1 can + 15 oz black beans · 1 can kidney beans · 1 can diced tomatoes (28 oz) · 1 can diced tomatoes (14.5 oz) · 1 can chickpeas · 1 can coconut milk · 1 can cannellini beans · 2 tbsp Thai red curry paste · 1 cup chicken broth · 2 tbsp coconut oil |
| Pantry (2) | 1 cup jasmine rice · 6 oz orecchiette |
| Spices (4) | 4 tbsp chili powder · 3 tsp ground cumin · 1 tsp garam masala · ½ tsp red pepper flakes |

The line under the title: "36 to get, for tacos and four more". Master: 44 rows, with the curry's and chili's tomatoes as one.

## Gaps

| # | Where | What happens today | Proposed default | Owner |
|---|---|---|---|---|
| G-R1 | `Recipes.swift`, `CreateRecipe.write` and `RecipeBook.lines(of:)` | The parse reads `packSize`, but the recipe line never stores it and `lines(of:)` never reads it. Every recipe share has no size: no " · 15 oz" on any recipe row, and 28 oz + 14.5 oz diced tomatoes add to "2 cans" (U5) | Store `packSize` on the recipe line and read it back; a test with r2 + r3 gives two tomato rows | Core |
| G-R2 | `AddRecipeToGroceries.apply`, `addGroceryShare` | Section 3 says skip a **covered** ingredient (open or checked); section 2 says a same-key row is linked, "a merge the list already does". Master always adds a share, and skips checked rows, so a checked "eggs" in the basket gets a new "8 eggs" row | A same-key **open** row takes the share: a bare row shows the recipe's amount ("8 eggs"), a row with an amount sums as today. A same-key **checked** row covers the line and nothing is added | Kitchen lead (rule), Core |
| G-R3 | `AisleGuide.staples` (`Aisles.swift`) | Exact keys only. "kosher salt", "extra-virgin olive oil", "kosher salt and black pepper" are listed | Add kosher salt, extra-virgin olive oil, canola oil, avocado oil, cooking spray, freshly ground black pepper. A line naming only staples joined by "and" or "&" is a staple | Core |
| G-R4 | `IngredientLine.parse` (`Quantities.swift`) | "(optional)" is dropped as a note and ", optional" becomes prep, so the line is added. "for serving" is not read at all | An `optional` flag (optional, for serving, for garnish) skipped like "to taste" on the list; the recipe page still shows the line | Core; Kitchen lead confirms |
| G-R5 | `IngredientLine.parse`, the size-word loop | Only size words move to prep. "chopped fresh cilantro", "grated ginger", "grated parmesan", "crumbled feta" become new ingredients that never merge (corpus gap 8) | Add chopped, grated, crumbled, shredded, minced, diced, sliced, packed and freshly to the loop | Core |
| G-R6 | `IngredientLine.key` | It only lowercases and makes plurals singular. The acceptance doc says it folds "semi skimmed milk" into "milk": it does not. "whole milk" and "yellow onion" stay apart | A short alias table in `key`: whole, 2%, skim, semi skimmed milk to milk; yellow onion to onion (red onion stays). Fix the doc's sentence | Core; Kitchen lead (doc) |
| G-R7 | `AisleGuide.guide` | US words missing: chili powder (and the seed's "chilli powder"), red pepper flakes, chicken broth, orecchiette and other shapes, scallion. All land in Other | Add them: Spices, Spices, Cans and jars, Pantry, Produce | Core |
| G-R8 | `addGroceryShare`, the U5 merge key | Design has no rule for a sized pack plus a loose amount. Once G-R1 lands, the U5 key (`packSize` equal) splits "1 can black beans" from "15 oz black beans", and the spinach bag from the cups | A loose share joins the pack's row with "+" (never converted, pack first, the pack's size on the line). Only two different pack sizes stay apart. G-R1 and G-R8 land together | Design, then Core |
| G-R9 | Design 47, `GroceriesView` | The recipe line is drawn only for one recipe ("for tacos · 15 oz") | Two: "for tacos and chili". Three or more: "for curry and two more", sooner meal first, as the count line | Design, Builder B |
| G-R10 | not on master | No add on planning, no `groceriesAddedAt`, no `linkItems`, no KEEP or NOT NOW. Rows come only from the recipe page | As the acceptance doc, Core rows 1 to 6 | Core, AI |
| G-R11 | the KEEP write (acceptance section 2) | KEEP copies the recipe ingredient's **learned** aisle only. "Green onions" has none (it comes from the guide), so `scallions` stays in Other after KEEP | Copy the aisle as shown (learned, else the guide) when the kept row sits in Other | Kitchen lead (rule), Core |
| G-R12 | the pack; `Transaction.ingredient(named:)` | The pack sends the ingredient's title "so brands stay home", but a new ingredient is titled as typed: "TJ's red curry sauce" makes an ingredient with that title | Leave a candidate out of the pack when its title holds a shop name (Trader Joe's, TJ's); add it to the snapshot test | AI |
| G-R13 | `HomeLines.toBuy` | At 0 it says "nothing to buy". The acceptance wants the time ("tonight") and the key COOK. The key was not traced | At 0 the context is the day word and the key COOK | Core |
| G-R14 | `AddRecipeToGroceries.apply` | It returns every row it touched, joined rows included, so "Added N" would say 7 for the frittata | N counts new rows only; joined rows still get the recipe line | Core, Builder B |
| G-R15 | `GroceryShare.quantity` | "7 cloves + 1 head garlic" in first-added order. Matches us-shop (no guessing), but nobody has said whether a head covers cloves | Keep the "+"; Design confirms | Design |
| G-R16 | `RecipeMath.round` | Spoons floor at ½, so ¼ tsp halved is ½ tsp, twice the recipe | Floor teaspoons at ⅛ (the glyph exists) | Core |

## Probes for Claude's part (`linkItems`)

The week above. Typed rows go in as candidates; the pack holds the planned recipes' uncovered ingredients. Same rules as
`groceries-link-eval.md`: **must** pairs in every run, **never** gets no pair in any run, **either** may be the named pair or
nothing.

| # | Typed row | Expect | Pair | Note |
|---|---|---|---|---|
| L1 | scallions | must | green onions (r5) | Ask: "Scallions, for the frittata?" |
| L2 | canned black beans | must | black beans (r1, r2) | Shared handle; the ask names the sooner meal, tacos |
| L3 | chicken stock | must | chicken broth (r2) | |
| L4 | parmigiano | must | parmesan (r4) | Today the pack title is "Grated parmesan" (G-R5); still must |
| L5 | spinach | either | baby spinach (r3, r4, r5) | |
| L6 | red pepper | either | bell peppers (r1, r2) | "red pepper flakes" (r4) is a false pair |
| L7 | coconut cream | never | | Not coconut milk |
| L8 | ground beef | never | | Not ground turkey |
| L9 | lime juice | never | | A bottle is not a lime |
| L10 | Greek yogurt | never | | Not sour cream |
| L11 | beans | never | | Four kinds this week; can't be sure |
| L12 | TJ's red curry sauce | never | | And not in the pack at all (G-R12) |
| L13 | garlic, tortillas, eggs; milk once G-R6 lands | not in the pack | | Same key: the phone links them. Until G-R6, milk is a candidate: either, whole milk (r5) |

Checks on each run: at most 6 pairs and one per row; no text, amount or aisle returned; no call while shopping (hold the
title) or in a live workout; NOT NOW on L1 keeps it out of the next pack until Sunday passes. Groceries never notifies:
the only reminder is the cook's Home line.
