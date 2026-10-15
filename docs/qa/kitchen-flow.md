# Kitchen flow check

A written end-to-end check for a Mac lead to run on the simulator before a kitchen PR merges. Parts A and B work today. Run the rest of each part once its screen lands (see the ship list, `docs/product/ship-list-kitchen.md`). Write down anything that fails, with the step number.

## Setup

1. Run `scripts/test.sh`. Both the package and the app must be green.
2. Launch a DEBUG build with `-groceries -demoKitchen` on a fresh install. This seeds Carbonara (serves 2) and Weeknight dal (serves 4).

## A. Groceries screen (#58)

1. Type `eggs, milk, 2 lemons` and press return. Expect three items, each under its aisle (dairy, dairy, produce), and the field clears.
2. Type `500 g` and press return. Expect no item. Today the field also clears with no feedback (known bug G2).
3. Tap `milk`. Expect the ink strike, then the item sinks into the basket and the count reads "1 in the basket".
4. Undo. Expect milk back in Dairy and unchecked.
5. Long-press `lemons` and move it to another aisle. Add `lemons` again later. Expect it to land in the new aisle (aisles learn).
6. Hold the page title to start the shop. Expect one column in aisle order, the current aisle at hero size, and Now reading "Shopping, N left".
7. Check two items. Expect Now's count to drop by two.
8. While shopping, type `butter`. Expect Now's count to go up by one. Today it doesn't until the next check-off (known bug K10).
9. Leave the shop (background the app, then reopen). Expect the shop suspended in What's running, not lost.
10. Resume and finish. Expect the checked items cleared and the shop ended.

## B. Tess phrases in the ghost row (#57)

Each phrase should land where the right column says. The first four rows are the expected behavior, and the rest are regression checks for known bugs K1–K4, so they fail on master today.

| Phrase | Expected |
| --- | --- |
| `buy milk` | Groceries: milk |
| `milk, eggs, 2 lemons` | Groceries: three items |
| `timer pasta 10` | A 10-minute timer called "Pasta" |
| `cook carbonara thu` | A Thursday task "Cook carbonara" linked to the recipe |
| `bench 80, 8` | A Bench set of 80 × 8, not a grocery item (K2) |
| `get the car serviced friday` | A Friday task, not a grocery item (K1) |
| `remind me to reset the oven timer at 9 tomorrow` | A task for 9:00 tomorrow, not a timer (K3) |
| `run 7am` (with a recipe called "Brunch pancakes") | A task "Run" at 7:00, not a cook task (K4) |

## C. Paste a recipe (slices 3 and 11)

1. Paste the carbonara text from `KitchenDemo` in `Features/Groceries/GroceriesView.swift`.
2. Expect title "Spaghetti carbonara", serves 2, total 25 min, 5 ingredients and 4 steps, with timers detected at 10 min and 5–6 min.
3. Edit step 1 to start with "Cook the spaghetti for 10 minutes." and paste again. Expect it to stay a step (K5).
4. Paste a line `2 garlic cloves` and `1–1½ cups flour`. Expect the ingredients "Garlic" (2 cloves) and "Flour" (1 to 1½ cups) (K6, K7).
5. Undo the save. Expect the recipe gone.

## D. Recipe page and scaling (slices 4 and 10)

1. Open Carbonara and turn the portion drum from 2 to 3. Expect 300 g spaghetti, 150 g guanciale and 5 eggs (whole eggs rounded), with no reload.
2. Turn it to 1. Expect 100 g spaghetti and 2 eggs (not 1.5).
3. Swipe the ingredient column into Groceries at 3 servings. Expect the count left behind, the items in Groceries, staples (pepper) skipped, and each item linked back to Carbonara.
4. Add Weeknight dal too. Expect shared ingredients summed, not duplicated.
5. Remove Carbonara from Groceries. Expect only its share removed, and dal's items untouched.

## E. Cook mode (slices 5 and 12)

1. Tap Cook on Carbonara. Expect a dark full-screen cover on step 1 with the scaled amounts, and Now reading the cooking process.
2. Hold the 10-minute timer key on step 1. Swipe to step 2 and hold the 5-minute timer key. Expect two horizon lines, and Now showing the soonest timer.
3. Lock the phone. Expect both timers on the Lock Screen through the rest Live Activity.
4. Kill the app and relaunch. Expect cook mode to resume on step 2 with both timers still counting down.
5. When the 5-minute timer ends, expect a cadmium flare, a haptic, and its step sliding back into view.
6. Hold Finish on the last step. Expect a Cook entry (recipe, today, serves 3), Tess's one line, and the recipe page reading "cooked today".

## F. Wrap-up

1. Undo through the whole session. Every step should undo cleanly, with no orphaned items or timers.
2. Export JSON and check the recipes, lists, cooks and ingredients are all present.
3. Repeat A1, A3 and E2 with Reduce Motion on. Expect no slide or flare, but the same results.
