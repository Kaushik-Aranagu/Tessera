# Kitchen ship list: recipes, cooking, groceries, lists (engine-first)

*Kitchen lead, 2026-10-15 17:30. Same rules as `ship-list-m2.md`: small end-to-end slices, velocity over perfection. Engine slices come first so Core can start now. **Engine** = logic and tests only; **Feature screen** = a self-contained screen in its own `Features/<Area>/` folder, rough logic is fine but it meets the UI bar (no cards, pills, capsules or stock lists; Inter Tight tiers; painterly ground with hairline seams).*

**The idea in one line.** The kitchen is not a new kind of app; it is three building blocks we already have or are about to have, put to work: an **actionable list** (groceries, any list), **paragraphs** (a recipe's steps, a note), and a **process** (cooking and shopping run on Now like a workout does). Every recipe, ingredient, list item and cook is a linkable object.

**Progressive disclosure rule for this area.** Each screen shows one thing at full size. Everything else is one gesture away and never on screen by default: scaling, unit conversion, the original pasted text, cook history, which recipes an item is for, aisle editing, staples. Options exist; they don't crowd.

## Slices

| # | Slice | Done when | Type |
|---|---|---|---|
| 1 | **List building block** | `List` and `ListItem` classes: item text, optional quantity, done, order, optional section, links to any object. Actions: add, check, uncheck, move, reorder, rename section, clear done; all undoable through the op log. Checked items stay (with `checkedAt`) until "clear done". **This is the List class M3 slice 10's template instantiates** | Engine |
| 2 | **Quantities and ingredient lines** | Parse a line into amount, unit, ingredient, prep: "200 g flour", "2 tbsp olive oil", "1 onion, finely diced", "2–3 cloves garlic", "½ tsp salt", "salt to taste", "a handful of basil". Units metric (g, kg, ml, l) plus tsp/tbsp/cup kept as written with a metric equivalent available. Each line links to an `Ingredient` object, matched by name and plural, created when new | Engine |
| 3 | **Recipe class and paste parser** | `Recipe` (title, serves, active and total minutes, source text, ingredient lines, steps). Pasting plain text splits on "Ingredients" / "Method" headings, else by line shape (amounts → ingredients, sentences → steps). Steps are paragraphs: detect durations ("simmer 20 min", "for 1–2 hours") and ingredient mentions as links. The original text is kept verbatim. Create/edit/delete undoable | Engine |
| 4 | **Scaling** | `RecipeMath.scaled(recipe, serves:)` returns lines at a new size, rounding by kind: whole eggs and onions, g to the nearest 5 under 100 and 10 above, spoons to ½. Not stored; a cook remembers the size it used | Engine |
| 5 | **Cooking as a process** | `StartCooking(recipe, serves)` starts a process (one thing is Now); the resume point is the step index. `StartTimer(label, minutes)` from a step: several timers can run at once, each an object with `endsAt`; the Now picker shows the soonest. `FinishCooking` writes a `Cook` log entry (recipe, date, serves, optional note) so the recipe knows "last cooked 12 days ago" and how often | Engine |
| 6 | **Groceries list** | One built-in `Groceries` list (a slice 1 List) with aisle sections. `AddRecipeToGroceries(recipe, serves)` merges ingredients: same ingredient with compatible units is summed ("400 g + 200 g tomatoes" → "600 g"), each item links back to the recipes it is for. Removing the recipe takes its share back out. Staples (salt, oil, pepper; a flag on `Ingredient`) are skipped unless asked | Engine |
| 7 | **Aisles that learn** | ~150 common ingredients seeded with an aisle (produce, dairy, meat and fish, bakery, tins and jars, dry goods, spices, frozen, household). Moving an item to another aisle teaches its ingredient, so it lands there next time. Unknown items go to "Other" | Engine |
| 8 | **Shopping as a process** | `StartShop` runs the groceries list as a process: Now reads "Shopping, 9 left", items come out in aisle order, leaving the shop suspends it in the ledger. Finishing moves checked items out (clear done) | Engine |
| 9 | **Capture grammar for the kitchen** | Through the ghost row: "buy milk", "milk, eggs, 2 lemons" → grocery items; "cook carbonara" → starts cooking; "timer pasta 10" or "10 min timer" → a timer; "carbonara thursday" or "cook carbonara thu" → a dated task linking the recipe (the whole meal plan for now); "list: packing" → a new list; pasted text with an Ingredients heading → a recipe ghost | Engine |
| 10 | **Recipe page** | Object page for a recipe, see design steer | Feature screen `Features/Recipes/` |
| 11 | **Paste a recipe** | The capture surface for slice 3, see design steer | Feature screen `Features/Recipes/` |
| 12 | **Cook mode** | Full-screen process for slice 5, with cook timers on the Lock Screen via the rest Live Activity | Feature screen `Features/Cooking/` |
| 13 | **Groceries** | The list and the at-the-shop mode, see design steer | Feature screen `Features/Groceries/` |
| 14 | **Kitchen shelf** | The recipe library and the app's front page, see design steer | Feature screen `Features/Recipes/` |
| 15 | **Lists app v0** | Any slice 1 list (packing, to read, gifts) with the Groceries instrument, minus aisles | Feature screen `Features/Lists/` |

Build order: 1 → 2 → 3 → 4 → 6 → 7 → 5 → 8 → 9, screens after their engine slice (13 needs 1, 6, 7; 10 and 11 need 3, 4; 12 needs 5; 14 needs 3, 5; 15 needs 1).

## Design steers (one per screen)

Shared: the Kitchen app is light ground (Home's paper and washes), with a sage-and-cadmium lean: sage for fresh things and done, cadmium for heat and timers, vermilion only for something running, cobalt only for Tess. Sibling rail at the top like Home: **RECIPES · GROCERIES**, painted underline. Lists live in their own app with the same instrument.

**10. Recipe page.** The hero is the recipe name (Hero tier, up to 3 lines). Under it one context line in Body: "serves 2 · 35 min · cooked 12 days ago". The serving size is a **portion drum**, the reps drum's sibling: turn it and every quantity on the page re-sets itself with a tabular roll, no reload. Ingredients sit in one column at 21pt, amount in 600 and name in 400, no bullets, no separators; staples sit dimmer. Steps don't show on this page; their count peeks at the bottom ("7 steps") and the one key is **Cook** (ink key, hold not needed). z: tap an ingredient to zoom into the Ingredient object (where it's used, its aisle). The original pasted text, cook history and notes are one level deeper under the name, never on the first screen. "Add to groceries" is a swipe on the ingredient column, not a button: swipe left across it and the whole column slides into the Groceries page edge, with a count left behind ("12 to buy").

**11. Paste a recipe.** Paste and the raw text stays exactly where it lands, in Body type, and the parser **paints over it** as it reads: amounts get a cadmium under-stroke, ingredient names a sage dab, durations a cadmium tick, step breaks a hairline in the margin with a numeral. It reads top to bottom in ~600ms, like a brush passing. Misreads are fixed by tapping a word to cycle it (ingredient / step / ignore), not by forms. One line at the top in cobalt from Tess: "Eight ingredients, six steps, two timers." Save commits as a ghost row with Undo.

**12. Cook mode.** Dark ground, full-screen cover like the workout. One step at a time in the Title tier; y is sequence: swipe up for the next step, the previous one stays as a dim line above. This step's ingredient amounts sit under it, already scaled. A detected duration becomes a **hold-to-start timer key** in cadmium; a running timer is a **horizon line** across the top of the screen (the rest Live Activity's language), one per timer, stacked hairlines that burn down left to right with the label in labels. Timers run on the Lock Screen through the same Live Activity. The screen stays awake; every target is at least 64pt for wet hands. Living moment: when a timer ends its line flares cadmium and the step it belongs to slides back into view with a haptic. Finish is a hold key on the last step; it writes the Cook entry and Tess says one line ("Carbonara, third time this month."). **Idle rule (Product, 2026-10-15):** a cook process is never suspended while a timer runs or within 45 minutes of the last step change; without it `tidyProcesses` suspends a backgrounded cook after about 13 minutes. Check against `docs/research/fixtures/cook-mode-scenarios.md` (S01-S15).

**13. Groceries.** One page, sections by aisle. Aisle names are Title-tier words set in the left margin, offset and asymmetric, and items hang from them at 21pt. No checkboxes: tap an item and the **ink strike** from the task finish runs through it, then it sinks into a "basket" fold at the bottom of the page that shows only a count ("6 in the basket"). Which recipes an item is for is a sage dab beside it; long-press shows the recipe names. Adding is the ghost row: type "eggs, milk, 2 lemons" and the items fly to their aisles. **At the shop** (start from a hold on the page title, or "shop" in the ghost row): the page turns into a single column in aisle order with the current aisle at hero size, lit top seam because it's running; done aisles fold up and away.

**14. Kitchen shelf.** Not a grid. Recipe names are set as a tall typographic column, mixed sizes: the recipe you cook most is largest, the ones you haven't cooked in a while smaller and dimmer, like a well-used shelf. The page stays one screen tall; the column is a bounded vertical window with snap. Filters are words along the top, off by default ("quick", "not lately", "uses what's in the basket"). Tap a name to zoom into it. Empty state is a paste invitation in cobalt: "Paste a recipe and I'll read it."

**15. Lists app v0.** Each list is a page; lists are x siblings. Same strike-and-sink instrument as Groceries, optional sections as margin words. The list name is the hero; the ghost row adds.

## Depends on M3

- **Slice 1 here should land before M3 slice 10**, and M3 slice 10's "List" template should create a slice 1 `List` rather than a new class. Nothing else in M3 blocks the kitchen.
- M3 slice 3 (add a field) and slice 4 (saved queries) are nice-to-have: slice 14's filters ship as fixed rules first and move onto saved queries when they exist.
- Uses from master: Task (meal plan as dated tasks), Process + Now picker + ledger, Note @links, capture ghost row, undo, the rest Live Activity.

## Deferred

Web import and AI parsing, pantry inventory and "what can I cook", nutrition, photos, a weekly meal planner screen (dated tasks cover it), shared or household lists, prices, voice "next step" in cook mode, widgets.

## Defaults taken

Metric units; spoons and cups kept as written with metric on tap. One grocery list. No pantry. Recipe entry is typed or pasted text only. Staples are skipped when adding a recipe. A meal plan is just "cook X on Thursday" as a task. Tess stays grammar-only.
