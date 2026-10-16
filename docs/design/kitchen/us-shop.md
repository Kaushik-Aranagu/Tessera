# The Kitchen for a US shop (Design item 25)

Kaushik shops at Trader Joe's and reads US recipes, so this sheet checks every Kitchen sheet's on-screen words and amounts against a US kitchen. It follows `upkeep-people-first.md`'s US home: dollars, US names, the phone's zone. It's for Core (the aisle names, units and merging), Builder B (Groceries, Recipes and paste screens) and Builder A (cook mode). Where it differs from an older Kitchen sheet, this sheet wins. Each of those sheets carries a pointer line.

## Words on screen
| Where | Now | For a US shop | Owner |
|---|---|---|---|
| Aisle names, `TesseraCore/.../Kitchen/Aisles.swift:6-8` | Meat and fish, Dry goods, Tins and jars, Dairy | **Meat and seafood**, **Pantry**, **Cans and jars**, **Dairy and eggs**. Produce, Bakery, Spices, Frozen, Household and Other stay. Items already stored under the old names read as the new ones, so a stored "Tins and jars" shows as "Cans and jars", and nothing is lost | Core |
| Aisle walk order (`13-groceries.md`) | produce, bakery, dairy, meat and fish, tins and jars, dry goods, spices, frozen, household, other | **produce, bakery, dairy and eggs, meat and seafood, cans and jars, pantry, spices, frozen, household, other.** It's a starting guess, and his own moves still teach it | Core |
| "tin" and "tins" typed or pasted | read as `.can` (`Quantities.swift:48`) | They still parse. What shows is always **can** | Core |
| Sheet examples | "600 g tomatoes", "200 g spaghetti", "500 g yoghurt", "red pepper", "300 g chicken thigh", "400 ml coconut milk" | "**2 lb** tomatoes", "**8 oz** spaghetti", "**32 oz** yogurt", "**1** red bell pepper", "**1 lb** chicken thighs", "**1 can** coconut milk · 13.5 oz" | Design (sheets) |
| A receipt shown to Tess (`show-and-hints.md`) | "Tesco, **£38.20**?" | "Trader Joe's, **$38.20**?" (as `money-reading-first.md` already has it) | Builder A (Money) |
| The money dial's VoiceOver (`money-dial.md`) | "Pounds, 38", "Pence, 20"; the currency cycles none → € → £ → $ | "**Dollars, 38**", "**Cents, 20**". The cycle starts with his: none → $ → € → £. Money stays currency-neutral: an amount keeps what was said, and nothing is converted or summed across currencies | Builder A |
| The basket ("All in the basket.", "Clear the basket") | | **Kept.** Trader Joe's has baskets, and "basket" is already built and reads naturally in the US | none |

## Amounts, as the recipe gives them
- **Units stay as written, and nothing is converted on save:** cups, tbsp, tsp, oz, lb, fl oz, pint, quart, stick and can. A metric recipe stays metric. (`Quantities.swift` doesn't read oz, lb or pint yet; that's paste-hardening gap 1, Core.)
- **Fractions are shown as fractions.** "1/2", "1 1/2" and "½" all show as **½** and **1½** (½ ⅓ ⅔ ¼ ¾ ⅛), with tabular figures. The amount and its unit form one 600 word: "**½ cup** parmesan, grated", "**1½ tsp** cumin". A decimal from a paste ("0.5 cup") shows as ½ when it's one of those fractions.
- **Pack sizes** (paste-hardening gap 2, `packSize`): the amount is the pack, and the size follows the name in `inkSecondary` after a middle dot: "**1 can** diced tomatoes · 14.5 oz". Butter by the stick reads "**1 stick** butter".
- **The quick flip** (`10-11-recipe-page-and-paste.md`): tapping an amount flips it to **the other system** for 3s, then it flips back. US becomes metric ("½ cup" becomes "120 ml"), and metric becomes US ("200 g" becomes "7 oz"). Before, only US amounts flipped, and only to metric.
- **Oven temperatures** are shown as written: "425°F", or "220°C" on a metric recipe. Cook mode's step text keeps them. The timer key reads only the duration.

## Merging on Groceries (`13-groceries.md`)
- **Same unit adds,** and the amount rolls to the new total under the cobalt wash: "**8 oz** + **8 oz**" gives **1 lb**. Ounces of weight roll into pounds from 16 oz, as "1 lb" or "1½ lb". Cups add as cups, and cans add as cans.
- **Fluid ounces never merge with ounces of weight,** and volume never merges with weight. "**1 lb** spinach" plus "**2 cups** spinach" stays one row, reading "**1 lb + 2 cups** spinach". It's never a guess at a conversion.
- Metric and US weights of the same thing (200 g and 8 oz) also stay as "**200 g + 8 oz**". Converting them is a guess about the recipe.

## Owners
- **Core:** the aisle names and order with the old-name read, oz, lb, pint, fl oz and stick units (gap 1), `packSize` (gap 2), fractions to glyphs on display, and the merge rule.
- **Builder B:** the amount word with fraction glyphs and the pack size after the dot, on Groceries and the recipe page. Also the quick flip in both directions.
- **Builder A:** cook mode's step text keeps °F as written, and the money dial's VoiceOver words and cycle order.
- **Research:** add US lines to the paste corpus (cups and sticks, "1 (14.5 oz) can", ½) and to `fixtures/money.md`'s examples, and check the merge rows above against the parser.
