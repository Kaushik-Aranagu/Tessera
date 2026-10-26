# The recipe page and cook mode in US units (Design item 28)

The recipe page (sheet 10) and cook mode (sheet 12), redrawn for a US kitchen to `us-shop.md` and under today's rules: the back word, the Title 44 page top (`day-seams.md` S4), Tess beside the soul (S1), the ink line, and cook mode on the look's own ground (`sweep-19.md`). Where this sheet differs from sheets 10 and 12, this sheet wins. Each of them carries a pointer.
- Board: `../mockups/kitchen-us.png` (source `../studies/kitchen-us.html`). It shows Weeknight dal at serves 4 and turned to 6, cook mode for 6 at step 2 in Porcelain with a timer running, and a Trader Joe's sheet-pan step at 425°F in Obsidian.
- Recording: `../recordings/kitchen-us.mp4` (17s, 60fps). The drum turns 4 to 6 and the amounts roll. A tap flips "2 cups" to "470 ml" for 3s. Cook raises the cover, a swipe moves to step 2, and a hold on "20 minutes" starts the horizon.

## 1 · The recipe page
| y | Element |
|---|---|
| 58 | **‹ RECIPES**, the back word (`back-word.md` row 15). It replaces the "RECIPES" path label |
| 84 | **The recipe's name** in Title 44, up to 2 lines, then 34. Tap it to go one level down (the pasted text, the link, cook history) |
| 140 | "35 min, cooked 12 days ago" in Body 21 **`inkSecondary`**. It sits under the name, not above a hero, so it isn't the context line (`sweep-19.md`). Serves moves to the drum, so the line doesn't repeat it. Missing parts are left out |
| 184 → about 600 | **Ingredients**, x 22 to 280, with the portion drum at x 300 to 368, top-aligned with the first line |
| 620 | **3 STEPS** in labels |
| 650 | **Cook** as an ink-line word (Title 34 on the line in kitchen paint), with **35 MIN** in labels 22pt after it. Tap, no hold. It ends above Tess's band (736 to 820) |

**An ingredient line:**
- The amount and its unit are one 600 word in a fixed 92pt column with tabular figures: "**1¼ cups**", "**3 cloves**", "**1 can**". The name follows at 400, and prep after a comma is in `inkSecondary` (", finely chopped").
- Fractions show as glyphs (½ ⅓ ⅔ ¼ ¾ ⅛), as `us-shop.md` says.
- A pack size follows the name after a middle dot, in `inkSecondary`: "**1 can** coconut milk · 13.5 oz". When the line is too long, the dot and the size wrap together, never alone.
- A loose amount with no unit ("a handful", "to taste") stays as written at 400.
- **Staples** (salt, oil, water, pepper) rest at `inkTertiary` with their amount at 400, as before.
- Out lines from pantry light (`kitchen-v2.md` P) are unchanged.

**Adding to Groceries** is the same swipe across the column. Tess speaks beside the soul: "Added 7 to Groceries." with **UNDO** under it. This replaces the old "12 to buy" line with "Undo" on its right.

## 2 · Turning the drum
- The drum, its roll and its haptics are unchanged (sheet 10).
- **It rounds as the build already does** (`RecipeMath.round`, `TesseraCore/.../Kitchen/RecipeMath.swift:19-33`): cups to a quarter, spoons to a half, and cloves, onions, cans and sticks to a whole. So 1¼ cups for 4 becomes **2 cups** for 6, and 1 can becomes **2 cans**. The build wins here (`day-seams.md`), and a whole can is what he'd buy anyway.
- A scaled amount shows in the same unit it was written in. It never changes unit, so 3 tsp stays 3 tsp and never becomes 1 tbsp.
- A word that counts changes with its amount: "yellow onion" becomes "yellow onions" (Core already plurals units; this extends it to the name when the line has no unit).
- Nothing about °F, times or pan sizes ever scales.

## 3 · The quick flip
- Tap an amount and it flips to the other system for 3s, then flips back: "2 cups" becomes "470 ml", and "200 g" becomes "7 oz". The flip turns on its x axis (120ms out, 160ms in).
- The metric side rounds the same way the drum does (millilitres to 10 above 100). The US side uses oz and lb for weight, and cups and spoons for volume.
- Cans, sticks and bags don't flip, because their size is already written after the dot.

## 4 · Cook mode
Cook mode stands on the look's ground, in `ink`, with the soul in its look's palette (`sweep-19.md`). There's no back word.
| y | Element |
|---|---|
| 6 | **The timer horizon**: `ink` at 2.5pt over a 1.5pt guide at 14%, burning down left to right. The label under its left end in labels, tabular: "SIMMER 17:36" |
| 56 | "Weeknight dal, for 6" in Body 21 `inkSecondary`. "2 / 3" in labels on the right |
| 100 | The previous step, one line, in `inkTertiary`. Tap it to step back |
| 150 | **This step** in Title 34, in `ink`. An amount in the sentence that belongs to one of the recipe's ingredients shows **scaled**, as a 600 word ("simmer with **4½ cups** water"), so the sentence and the list never disagree. Temperatures stay as written ("roast at 425°F") and never scale |
| 430 | This step's ingredients, scaled, in Body 21 `inkSecondary`, amounts at 600 |
| 590 | The step's key as an ink-line word: "**20 minutes**" with "HOLD · UP TO 25" in labels. Finish uses `liveInk`. Once its timer runs, the key fades (300ms); the horizon is the timer |
| 690 | "then: stir in the coconut milk, warm through…" in `inkTertiary`, one line |

- Holds, the flare, the overlay and the Live Activity are unchanged (sheet 12). The Live Activity stays Cobalt sky.
- A step's sentence is the recipe's own words. Only the amount spans tied to an ingredient line are replaced.

## 5 · The demo recipes, in US units
The `-demoKitchen` seed (`Features/Groceries/GroceriesView.swift:711-745`) is metric. For his phone's first look at the Kitchen, the seed reads:
- **Carbonara, serves 2:** 8 oz spaghetti; 4 oz guanciale, diced; 3 eggs; ½ cup pecorino, finely grated; black pepper, to taste. The steps are unchanged.
- **Weeknight dal, serves 4:** 1¼ cups red lentils; 1 yellow onion, finely chopped; 3 cloves garlic, crushed; 1 tbsp ginger, grated; 1 can coconut milk (13.5 oz); 1 tsp turmeric; a handful of cilantro. Step 2 reads "Add the lentils, turmeric and 3 cups water and simmer for 20–25 minutes."
- These need `Quantities.swift` to read oz and the "(13.5 oz)" pack size first (paste-hardening gaps 1 and 2). Until then, the seed stays metric.

## 6 · Research's four questions on `us-shop.md`
1. **Are bag, jar and box pack words?** Yes, like can. They show as the amount, with the size after the dot: "**1 bag** spinach · 6 oz", "**1 jar** salsa · 16 oz", "**1 box** spaghetti · 16 oz". "Bottle" and "carton" join them.
2. **Do cans of different sizes add into one count?** No. Same size adds ("**2 cans** diced tomatoes · 14.5 oz"). Different sizes stay as separate rows in the same aisle, each with its own size, because they're different things to pick off the shelf and he ticks them separately. Joining them with "+" would make a count he can't shop.
3. **Does a pint stay a basket unit, never shown as 473 ml?** Yes. On Groceries and in the basket it's always "1 pint". Only the recipe page's 3s flip ever shows it as millilitres.
4. **Does "bucks" mean USD?** Yes. "12 bucks" logs $12, as "dollars" does. It's the currency he said, not a conversion, so Money stays currency-neutral (`money-reading-first.md`).

## Owners
- **Builder B:** the recipe page top (back word, Title 44 name, the `inkSecondary` line, Cook as an ink-line word at 650), the amount column with glyph fractions and the pack size, the two-way flip, and Tess's Groceries line beside the soul (`Features/Recipes/RecipePage.swift`).
- **Builder A:** cook mode on the look's ground with the horizon in `ink`, the scaled amount spans in the step sentence, and the key fading once its timer runs (`Features/Cooking/`).
- **Core:** plural names for unitless counted lines, the amount spans in step text tied to ingredient lines, bag, jar, box, bottle and carton as pack words, the US seed text after gaps 1 and 2, and "bucks" as USD in the money grammar.
- **Research:** add "1 bag spinach (6 oz)" and "12 bucks lunch" to the paste and money fixtures.
