# Kitchen acceptance: engine slices 1-9 (#49-#57)

*Kitchen lead, 2026-10-15 18:30. Checked master at 6bc4a37 against `ship-list-kitchen.md`. All nine engine slices are met in substance; the gaps below are small. **Fix** = Core should fix before or with the matching screen; **Screen needs** = the engine half a screen slice will need.*

## Fix

1. **"buy" / "get" with a date stopped being a task.** `TessGrammar+Kitchen.swift` `parseKitchen`: "get haircut thu" or "buy present for mum fri" now go to groceries. Only treat "buy/get X" as groceries when `TessDates.extract` finds no date; otherwise fall through to `parseTask`.
2. **Comma lists catch lifts.** `TessGrammar.parse` runs `parseKitchen` before `parseRelativeSet` / `parseLift`, and the bare comma rule turns "bench 80x8, 82.5x6" into groceries. Move `parseKitchen` after `parseLift` (keep the pasted-recipe check first), or skip the comma rule when any part matches the set grammar. Add both phrases to `KitchenCaptureTests`.
3. **A sweet pepper is treated as a staple.** `Aisles.swift` `AisleGuide.staples` contains "pepper", so "1 pepper, sliced" never reaches groceries. Drop "pepper" from staples (keep "black pepper").
4. **Size words make new ingredients.** `Quantities.swift` `IngredientLine.parse`: "1 large onion" links to an ingredient "Large onion", so it won't merge with "2 onions" on the list. Move leading size and freshness words (large, small, medium, big, fresh, ripe) into `prep`.
5. **Cooking the same recipe twice opens two cooks.** `Cooking.swift` `StartCooking`: if an open (running or suspended) Cook for this recipe exists, resume it instead of creating a new one, so the ledger never shows two "Carbonara".
6. **GoToCookStep ignores its clock.** `Cooking.swift` `GoToCookStep.apply` uses `.now`; give it a `time` parameter like the other actions (the demo clock).

## Screen needs (build with the screen slice)

- **Slice 11, Paste a recipe:** the paint-over needs where each part sits in the pasted text. Add source ranges to `ParsedRecipe` (each line's range; within an ingredient line, the amount, unit and name ranges; each duration's range in a step). Corrections need `CreateRecipe` to accept an edited `ParsedRecipe` (or per-line overrides: ingredient / step / ignore), not only raw text.
- **Slice 10, Recipe page:** "12 to buy" and the swipe-to-groceries state need a query: `Groceries.share(of recipe:)` returning the open items that carry this recipe's share (empty = not on the list). Recipe edits beyond title and serves (fix one line, remove a step) can wait; re-paste covers it for now.
- **Slice 12, Cook mode:** a timer that ends while the app is closed needs a local notification scheduled at `endsAt` (no entitlement needed), cancelled by `StopKitchenTimer`. Cook timers should drive the existing rest Live Activity, showing the soonest timer.
- **Slice 14, Kitchen shelf:** sizing by "cooked most" needs a cheap count: `CookLog.counts()` returning `[recipeID: (count, last)]` in one pass, instead of `cooks(of:)` per recipe.
- **Slice 15, Lists app:** superseded by `ship-list-lists.md`, which adds the list actions it needs.

## Passed as written

List block and its undoable actions; ingredient line parsing (fractions, ranges, attached units, "to taste", "a pinch of"); recipe parsing with and without headings, kept source text, step timers and mentions; scaling with kitchen rounding; cooking as a process with several timers, the soonest timer on Now, and the Cook log with the finish line; groceries merging with shares that can be taken back out; aisles in walking order that learn from a move; shopping as a process with a live "9 left"; kitchen phrases and recipe pastes through the ghost row.

# Screen 13: Groceries (#58, 4d5308e)

*Checked `Features/Groceries/GroceriesView.swift` and `docs/recordings/12-groceries.mp4` against slice 13's steer.* **Pass, with four fixes.** The aisle words in the margin with the alternate inset, the ink strike and sink, the sage recipe dabs with names on long-press, the basket fold showing only a count, and at-the-shop with the hero aisle and the lit seam all match.

1. **Quantities are below the type floor.** `GroceryRow` sets the quantity with `.textRole(.data)`, which reads at about 13pt in the recording ("3 cloves", "100 g"). Nothing goes under 16pt: use Label (16/700 uppercase) or an 18pt secondary line.
2. **Singular names next to plural amounts.** "egg 3" and "lemons 2" sit side by side, because recipe items take the ingredient's singular title and typed items keep what was typed. Show the plural when the summed amount is above 1 and there is no unit ("eggs 3"). The `AddRecipeToGroceries` item text in `Groceries.swift` is the place, or the row can pluralise on display.
3. **The folding aisle overlaps the next one.** At the shop, when the last item of an aisle is checked, "Produce" slides up over "Bakery" (about 0:24 in the recording). Fold the done aisle in place by collapsing its height under a clip, then let the next aisle rise into hero; never draw two titles on top of each other.
4. **The recording opens on about 6 s of blank paper.** Trim it, so the clip starts on the page.

Not blocking: the page scrolls as a whole when the list is long. That is fine for groceries; keep the hero and writing line in place if it starts to feel long in use.

# Groceries polish (#118, a07f6a0)

*Checked the `GroceriesView.swift` diff and `docs/recordings/16-groceries-polish.mp4` against the four #58 fixes above.* **Pass. All four are fixed.**
1. Quantities now sit before the name in body type at 600 weight ("**1 tbsp** ginger"), so nothing on the list is under 16pt.
2. Plurals read correctly: "3 eggs" and "2 lemons".
3. At the shop, a finished aisle folds away and the next one rises into the hero position ("Produce", then "Bakery", then "then Meat and fish"). The two titles never overlap.
4. The clip opens on the page.

The new moments match the steer. A struck item's dab arcs into the basket fold. Holding the title starts the shop, and "Clear the basket" and "Done" are hold keys.

Two small things for Core's next kitchen pass (not blocking):
1. At the shop, the faint "then Bakery" line is set larger than the items you're picking ("2 lemons" at body size). The aisle you're in should read loudest. Set the shop items one tier up (Title), or set the peek no larger than the items.
2. The basket bar covers the last aisle's title ("Dai…" peeks above "1 in the basket"). Add a bottom content inset equal to the bar's height so the last aisle can scroll clear of it.

# Engine hotfix (#70, 63c3f90)

*Checked the diff on master against engine fixes 1-6, the seed-recipe parser notes and the failing `kitchen-phrases.md` rows.* **Pass.** All six fixes are in as asked: dated buy/get stays a task, kitchen phrases run after lifts, "pepper" is no longer a staple, size words and "cooked" go to prep, cooking an open recipe resumes it, and `GoToCookStep` takes a time. `stick`, `head`, seconds timers and the "Cook time:" / step split are also in. Phrase rows 9-12, 20, 27 and 50 are fixed. Two small misses, neither blocking:

1. **"2 garlic cloves" makes its own ingredient and lands in Other.** Unit words after the name aren't read, so the name is "garlic cloves". It doesn't merge with "3 cloves garlic", and `AisleGuide` finds no aisle for "garlic clove". In `IngredientLine.parse`, when the name's last word is a unit word (clove, sprig, stick, head, slice), move it to `unit`.
2. **One unknown item sinks a comma list.** `looksLikeGroceries` must hold for every item, so "milk, toothpaste" becomes a task because toothpaste isn't in the guide. Accept the list when at least half the items read as shopping and none looks like a set or a date. Adding the common toiletries (toothpaste, shampoo, soap, deodorant, razor) to the Household aisle also helps.

# Second engine hotfix (#80, dd8f3ca)

*Checked the diff on master against the two #70 misses and `kitchen-phrases.md`.* **Pass.** "2 garlic cloves" now reads as 2 cloves of garlic, so it merges with "3 cloves garlic" and lands in Produce. A comma list goes to groceries when one item reads as shopping and none is a set, an errand ("call mum") or a date. Toiletries are in Household. Every row of `kitchen-phrases.md` except the Lists rows (41-48, waiting on Lists slice 8) now matches. Bonus fixes checked: "buy sun cream" is no longer read as Sunday, "pancake" finds "Protein pancakes", and "dough rest timer 45" stays in minutes.

One thing to watch, not a fix: "get" with a short unknown object still goes to groceries ("get haircut" becomes a grocery item called "haircut"). It's a ghost row with undo, so let Kaushik's use decide. If it bites, treat "get X" as groceries only when X reads as shopping, as the comma rule does.

# Screens 10-11: Recipe page and Paste a recipe (#86, 25ab380)

*Checked the diff and `docs/recordings/13-recipe-and-paste.mp4` against the slice 10 and 11 steers and the "Screen needs" above, and the engine against Research's `docs/research/fixtures/recipe-paste-corpus.md`.* **Pass, merge it.**

Recipe page: the name is the hero with the context line under it, and the portion drum sits beside one 21pt ingredient column. Amounts are at 600 and names at 400, and staples ("to taste Black pepper") are dimmed. Steps show only as the "4 steps" peek over an ink Cook key. Swiping the column left leaves "4 to buy, in Groceries" with Undo, through the new `Groceries.share(of:)`. Tapping an ingredient zooms into it, and the source text and cook history sit one level deeper. No text is under 16pt, and there are no cards or pills.

Paste: the raw text stays put and the parser paints over it, with cadmium under-strokes on amounts, sage dabs on names, cadmium durations, and numerals in the margin at step breaks. The cobalt Tess line reads "Seven ingredients, three steps, two timers." Tapping a line cycles it through ingredient, step and ignore, and `CreateRecipe(corrections:)` saves those taps, which the test covers. Save leaves "Weeknight dal saved." with Undo. The saved dal reads "serves 4, 33 min".

Fixes for the paste-hardening/polish slice (none blocks):
1. On the paste screen the last step sits under the Save bar ("Stir in the coconut milk…" is cut off). Give the column a bottom inset equal to the bar's height.
2. The recording shows about 5 s of blank paper before the paste prompt (23-28 s). Either the prompt is late or the clip needs trimming.
3. The recording never turns the drum, cycles a line, zooms into an ingredient or opens the source layer. The next kitchen recording should show these four.

Corpus gaps. #86 changes how lines are classified but not how they parse, so every gap Research found on master is still here. None blocks a basic paste, because a misread line can be fixed with a tap. In priority order for Paste hardening:
1. Unknown headings and blog noise (corpus gap 4). In paste-25 every step becomes an ingredient after "Do it like this", which takes five taps to repair. This is the worst one, so do it first.
2. No oz, lb or pint, and pack sizes ("1 (14 oz) can") end up in the name. These break grocery merging on US recipes.
3. Worded and fractional durations ("half an hour", "1½ hours") give no timer.
4. "salt & pepper" links to peppers, and short mentions don't link.
