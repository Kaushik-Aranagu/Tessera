# Ingredient color table (sheet 88)

For: Builder B (ObjectPlate wash), Core (`Ingredient.colour` default), Design
Date: 2026-10-17 (Research lab)
Inputs: Design's `imagery-88.md` (branch claude/project-thread-b3tu3f), decisions 8:37, research board 8:37, `Kitchen/Aisles.swift` and `Quantities.swift` on origin/master, `food-table-20.json`, and Design's plate rules in `imagery-88.md` (last section, Oct 16, 8:32 PM PT), applied in section 4.

## 1. Status

Draft, ready to read as a fixture. 62 foods, every one a key the app already has: all 20 keys of `food-table-20.json` plus 42 more from `AisleGuide.guide`. Names are the app's own keys (`IngredientLine.key(for:)`: lowercase, singular, "whole milk" is milk, "yellow onion" is onion). Group is the aisle name the app shows, so Core can join on the same key. Hex values are plain sRGB reads of how the raw, as-bought food looks. They are public facts about appearance, not a brand palette and not measured from any one photo. Sheet 88 asks for no legibility column (the wash is keyed to the color and Design owns its 34% light and 26% Obsidian blend), so there is none. Design's three rulings are applied (section 4).

## 2. Rules

**Several colors.** Pick the color of the outer surface as bought, raw. Where the food is always cut open before it is used, pick the flesh instead; those rows say "flesh" in the Which column. Where the food comes in more than one common color, pick the one a US shop sells first and name it in the Which column (red bell pepper, yellow onion, brown egg, green lentil, cheddar in its orange). Never average two colors and never pick a highlight.

**Foods the table lacks.** Resolve in this order, the same order `AisleGuide.aisle(for:)` uses for aisles:
1. His own pick on the ingredient (it always wins).
2. The key itself.
3. The last two words of the key ("smoked paprika" tries "smoked paprika", then "paprika").
4. The last word of the key ("baby spinach" is spinach).
5. Otherwise Kitchen green, `#12936A` (the kit token; ruling 1 in section 4).

A key that is a category or a mix (nut, cheese, stock, oil, pepper, cereal, curry paste) has no row and falls to Kitchen green, the same keys `food-table-usda.md` leaves out. "pepper" alone is Kitchen green; "bell pepper" and "black pepper" have rows. Household keys have no color. A Private object shows no pigment at all (sheet 88), whatever the table says.

**Pale foods.** Any hex with WCAG relative luminance above 0.85 (sRGB, computed from the hex) is shaded toward ink `#1B1B1F` by 12% before the 34% wash. Each channel becomes 0.88 times the hex channel plus 0.12 times the ink channel, rounded to the nearest whole value. No other floor. The Hex column stays true to the food; the result goes in the Plate hex column. Shaded? says yes or no per row, and Plate hex is "-" where the answer is no.

**Recipe fallback.** The Recipe fallback wash takes the first three ingredient lines in the recipe's own order (the author lists the main ones first). Staples are skipped. No quantity maths and nothing repeated.

**Staples.** A staple is a plain pantry base, fat or seasoning with no flavor of its own. The Staple column says yes for those rows: butter, all-purpose flour, granulated sugar, olive oil and ground black pepper. Flavored or colored items are no: brown sugar, honey, cocoa and the other spices. Salt, oil, vegetable oil, water and pepper have no row, so the recipe fallback skips them by key.

## 3. Table

| # | Food (key) | Group | Color | Hex | Which | Staple | Shaded? | Plate hex |
|---|---|---|---|---|---|---|---|---|
| 1 | onion | Produce | golden brown | #D9A55F | yellow onion skin | no | no | - |
| 2 | red onion | Produce | purple red | #8E3B5E | skin | no | no | - |
| 3 | garlic | Produce | off white | #EFE8D8 | bulb skin | no | no | - |
| 4 | ginger | Produce | tan | #C9A06A | root skin | no | no | - |
| 5 | carrot | Produce | orange | #EE7F22 | skin | no | no | - |
| 6 | celery | Produce | pale green | #A8C77B | stalk | no | no | - |
| 7 | potato | Produce | light brown | #C9A46C | russet skin | no | no | - |
| 8 | sweet potato | Produce | copper | #C0612F | skin | no | no | - |
| 9 | tomato | Produce | red | #D9361F | ripe red | no | no | - |
| 10 | cucumber | Produce | dark green | #4F8F3A | skin | no | no | - |
| 11 | zucchini | Produce | green | #4A7A33 | skin | no | no | - |
| 12 | eggplant | Produce | deep purple | #4A2D5B | skin | no | no | - |
| 13 | bell pepper | Produce | red | #D0281F | red bell | no | no | - |
| 14 | spinach | Produce | deep green | #2F6B2F | leaf | no | no | - |
| 15 | kale | Produce | dark green | #3C6B3B | leaf | no | no | - |
| 16 | broccoli | Produce | green | #3F7F3A | floret | no | no | - |
| 17 | cauliflower | Produce | cream | #EDE6D0 | floret | no | no | - |
| 18 | mushroom | Produce | beige | #CDB89E | white button cap | no | no | - |
| 19 | avocado | Produce | pale green | #A6B94B | flesh | no | no | - |
| 20 | lemon | Produce | yellow | #F3D13C | skin | no | no | - |
| 21 | lime | Produce | green | #6BA539 | skin | no | no | - |
| 22 | apple | Produce | red | #BF2A2E | red skin | no | no | - |
| 23 | banana | Produce | yellow | #F2D43E | ripe skin | no | no | - |
| 24 | strawberry | Produce | red | #D2232A | berry | no | no | - |
| 25 | blueberry | Produce | blue | #3F4E8C | skin | no | no | - |
| 26 | basil | Produce | green | #3E7D32 | leaf | no | no | - |
| 27 | parsley | Produce | green | #2E7D32 | leaf | no | no | - |
| 28 | cilantro | Produce | bright green | #4C9A3A | leaf | no | no | - |
| 29 | chicken thigh | Meat and seafood | pink | #E8B9A0 | raw meat | no | no | - |
| 30 | beef | Meat and seafood | red | #A82B2F | raw meat | no | no | - |
| 31 | pork | Meat and seafood | pale pink | #E9A19A | raw meat | no | no | - |
| 32 | bacon | Meat and seafood | red | #B5473A | raw strip, red part | no | no | - |
| 33 | salmon | Meat and seafood | coral | #F0795E | fillet flesh | no | no | - |
| 34 | shrimp | Meat and seafood | pale pink | #F2A58E | raw shell-off | no | no | - |
| 35 | milk | Dairy and eggs | white | #F5F3EA | liquid | no | yes | #DBD9D2 |
| 36 | butter | Dairy and eggs | pale yellow | #F4DE8A | block | yes | no | - |
| 37 | cheddar | Dairy and eggs | orange | #E8A33D | orange cheddar | no | no | - |
| 38 | parmesan | Dairy and eggs | straw | #EBD38C | wedge | no | no | - |
| 39 | greek yogurt | Dairy and eggs | white | #F7F4EC | plain | no | yes | #DDDAD3 |
| 40 | egg | Dairy and eggs | brown | #C9A27A | brown shell | no | no | - |
| 41 | bread | Bakery | golden | #CFA05B | crust | no | no | - |
| 42 | tortilla | Bakery | cream | #E8D3A8 | flour tortilla | no | no | - |
| 43 | rice | Pantry | white | #F1ECDD | white rice, dry | no | no | - |
| 44 | pasta | Pantry | gold | #E6C875 | dry wheat pasta | no | no | - |
| 45 | oat | Pantry | oatmeal | #D9C7A0 | rolled oats | no | no | - |
| 46 | quinoa | Pantry | sand | #DDC48F | white quinoa | no | no | - |
| 47 | flour | Pantry | white | #F4F0E6 | all-purpose | yes | yes | #DAD6CE |
| 48 | sugar | Pantry | white | #F6F3EC | granulated | yes | yes | #DCD9D3 |
| 49 | brown sugar | Pantry | caramel | #A9733F | packed | no | no | - |
| 50 | lentil | Pantry | olive brown | #8C7A4B | green lentil, dry | no | no | - |
| 51 | honey | Pantry | amber | #E0A526 | jar | no | no | - |
| 52 | cocoa | Pantry | dark brown | #5A3A28 | powder | no | no | - |
| 53 | almond | Pantry | tan | #C79A6B | skin on | no | no | - |
| 54 | chickpea | Cans and jars | beige | #D9B877 | dry or canned | no | no | - |
| 55 | black bean | Cans and jars | near black | #2B2420 | skin | no | no | - |
| 56 | peanut butter | Cans and jars | tan brown | #C48B4A | jar | no | no | - |
| 57 | olive oil | Cans and jars | green gold | #B9A93A | bottle, in the glass | yes | no | - |
| 58 | soy sauce | Cans and jars | dark brown | #3B2418 | liquid | no | no | - |
| 59 | paprika | Spices | brick red | #B5361F | ground | no | no | - |
| 60 | turmeric | Spices | golden yellow | #E1A410 | ground | no | no | - |
| 61 | cinnamon | Spices | brown | #9A5B2E | ground | no | no | - |
| 62 | black pepper | Spices | charcoal | #3A3430 | ground | yes | no | - |

Check: `grep -c '^| [0-9]' ingredient-colours.md` prints 62. Shaded? is yes for 4 rows (milk, Greek yogurt, flour, sugar). Staple is yes for 5 rows.

## 4. Rulings

From Design, sheet 88: `imagery-88.md`, last section, "Plate rules added after Research's colour table" (Oct 16, 8:32 PM PT). Applied here:

1. Kitchen green is `#12936A` (the kit token). It is the last step of the fallback in section 2. It fills the gap the draft left open.
2. Pale foods keep their own hue. Any hex with luminance above 0.85 is shaded 12% toward ink before the wash, with no other floor (rule in section 2). Milk, Greek yogurt, flour and sugar are shaded. Design's list also names garlic, rice and cauliflower as pale. They measure 0.81, 0.84 and 0.79, under the 0.85 line, so they are not shaded. The rule is the threshold, not the list.
3. The Recipe fallback wash takes the first three ingredient lines in the recipe's own order, skipping staples, with no quantity maths.

## 5. Open questions

For Product:
1. "Red onion" is its own row because the app keeps it apart from onion; should the same hold for other variants (green, brown lentil; white, brown egg)? The table picks one each.
2. About 62 of 271 food keys are covered. Is growing toward all 271 wanted, or is Kitchen green for the rest enough for v1?

For Core and Builder B:
3. Stored as the hex string on `Ingredient.colour`, no alpha. His own pick overrides the table, and the table is never written into the object.
4. Table values are facts about appearance, not nutrition data; the USDA attribution line does not apply to this file.
