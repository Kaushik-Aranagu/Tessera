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
