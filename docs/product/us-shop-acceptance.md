# US shop: acceptance (K7)

*Kitchen lead, 2026-10-17. Rows for Builder B (Groceries, recipe page, paste) to test `design/kitchen/us-shop.md` against Pantry sheet 78 (`pantry-acceptance.md` screen rows S1-S17, `kitchen-sides-acceptance.md` sections 4 and 6). Where `us-shop.md` and an older Kitchen sheet differ, `us-shop.md` wins. Core owns the aisle read, units, packSize and merge; Builder B owns the words on screen. US English throughout. " · " appears only in a pack size (copy-pass rule 8, Design sheet 77).  PER 100 G stays on the Ingredient page, never here.*

| # | State / input | Pass when |
|---|---|---|
| K7.1 | Aisle names | The shop shows Meat and seafood, Pantry, Cans and jars, Dairy and eggs. Produce, Bakery, Spices, Frozen, Household, Other are unchanged. The old names (Meat and fish, Dry goods, Tins and jars, Dairy) appear nowhere on screen |
| K7.2 | Old stored aisle | An item stored under "Tins and jars" shows under "Cans and jars" with nothing lost, no migration prompt |
| K7.3 | Walk order | Top to bottom: produce, bakery, dairy and eggs, meat and seafood, cans and jars, pantry, spices, frozen, household, other. The shop's "then X" line names the next aisle in this order. A move he makes still teaches the order (starting guess only) |
| K7.4 | "2 tins tomatoes" typed or pasted | Parses as a can; the row shows "can", never "tin" |
| K7.5 | US units as written | "2 lb tomatoes", "8 oz spaghetti", "32 oz yogurt", "1 pint cream", "1 stick butter", "1 fl oz" save and show with the unit as written. Nothing converts on save. A metric line ("200 g") stays metric |
| K7.6 | Cups and spoons | "2 cups" stays "2 cups"; tbsp and tsp stay as written. A decimal "0.5 cup" shows "½ cup"; "1 1/2 tsp" shows "1½ tsp" (glyphs ½ ⅓ ⅔ ¼ ¾ ⅛, tabular figures); amount and unit are one 600-weight word |
| K7.7 | packSize | "1 (14.5 oz) can diced tomatoes" shows "1 can diced tomatoes · 14.5 oz": amount is the pack, size follows the name in `inkSecondary` after a middle dot. Same for bag, jar, box, bottle, carton ("1 bag spinach · 6 oz"). A long line wraps the dot and size together, never the size alone |
| K7.8 | "14 oz can" typed on Groceries | Keeps its numbers (decisions 2:09: packs and amounts are not prices). It is a 14 oz can, not $14 and not 14 cans |
| K7.9 | Merge, same unit | "8 oz" + "8 oz" of one ingredient becomes one row "1 lb" (weight ounces roll into pounds from 16 oz, "1 lb" or "1½ lb"). Cups add as cups, cans as cans. The amount rolls to the new total under the cobalt wash |
| K7.10 | Merge, two recipes | The same ingredient planned from two recipes is one row with the summed amount and both recipes' shares ("for tacos" and the other cook) |
| K7.11 | Merge, mixed kinds | "1 lb spinach" + "2 cups spinach" is one row "1 lb + 2 cups spinach". "200 g" + "8 oz" is one row "200 g + 8 oz". fl oz never merges with oz of weight. No conversion is ever guessed |
| K7.12 | Merge, cans | "2 cans diced tomatoes · 14.5 oz" adds same-size cans. A 14.5 oz and a 28 oz can stay separate rows in the same aisle, each with its size, ticked separately; never joined with "+" |
| K7.13 | Price drop | "milk $4", "milk 4.99" and "2 for $5 avocados" give a milk row and an avocados row. No price on the row, in a note or in the receipt. Receipt: "Milk, on Groceries." |
| K7.14 | Price vs pack | "2 lb chicken", "14 oz can", "6 eggs" keep every number. "$1.29/lb" is not a spend and not a row price |
| K7.15 | Money-only line | "rent 2100 fri" or "$40 at costco" never becomes a grocery row; it becomes a private dated note (decisions 2:09, 2:06) |
| K7.16 | Planning, in-pantry item | Planning a recipe whose line's ingredient state is in adds no row for it (skipped silently, like a staple). The peek still reads "have" on that line |
| K7.17 | Planning, low / out / unknown | Low, out and unknown lines are added, as ghost rows in their aisles with the recipe's share. The peek reads "low", "out", or nothing for unknown |
| K7.18 | ADD N TO GROCERIES key | N is the dry-run count of rows the add would make, so it equals the rows that land (D1 Paprika chicken fixture: ADD 6 TO GROCERIES). At 0 the key is absent. Receipt "Chicken, 6 added." with UNDO 10 s |
| K7.19 | Pantry OUT AND LOW key | The side's key ADD N TO GROCERIES uses the same dry run; out and low names land in their US aisles in walk order; at 0 it reads "Nothing out." with no key |
| K7.20 | Pantry swipe | Left swipe on an out or low line adds a ghost row, "Milk, on Groceries." UNDO 4 s. A name already on Groceries is not added twice; receipt "Milk, already on Groceries.", no UNDO (S10) |
| K7.21 | Amounts survive the add | An out line added from Pantry carries its last typed amount and unit as written ("2 lb" stays "2 lb") |
| K7.22 | Shop clear closes the loop | Clearing the shop sets checked ingredients to in with `lastBoughtAt`; they leave the Pantry front (S8) and the next plan skips them |
| K7.23 | Walls | No price, pantry state or `lastBoughtAt` is sent to Claude; the pack snapshot holds none (pantry-acceptance Core row 7) |

## Open, defaults taken

1. Where the older Pantry Defaults table and sheet 78 differ, sheet 78 wins (as `pantry-acceptance.md` already says). Default taken.
2. K7.10: the two-share wording is inferred from `groceries-ai-acceptance.md`'s "for tacos" ghost rows and `kitchen-sides-acceptance.md` row 7.1; `us-shop.md` does not spell it. Default taken: Kitchen's.
3. K7.21: carrying the last typed amount for an Ingredient-page "out" comes from `pantry-acceptance.md` Engine P ("out of milk"); the Pantry swipe reusing it is inferred. Default taken.
4. K7.9: the roll-up point (16 oz) is `us-shop.md`; behavior for cups to quarts or pints is not specified, so cups stay cups. Default taken.
5. `Quantities.swift` does not yet read oz, lb or pint (paste-hardening gap 1) or packSize (gap 2); K7.5, K7.7 and K7.9 wait on Core. Builder B tests the rest now.
