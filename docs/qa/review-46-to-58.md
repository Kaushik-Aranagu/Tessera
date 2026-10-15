# QA review: merged PRs #46 to #58

*Repo maintainer, 2026-10-15. This was a static read of master at fae1ce6, with no Swift toolchain, so nothing here was compiled or run. Every finding is traced to a concrete input. Lines refer to master.*

**Overlap:** K1 and K2 duplicate Fixes 1 and 2 in the Kitchen lead's `docs/product/kitchen-acceptance.md`. Everything else here is new. That file's Fixes 3–6 (pepper as a staple, size words, double cooks, GoToCookStep's clock) are not repeated here.

**Summary:** 13 bugs (5 high, 6 medium, 2 low), plus one minor screen nit. Core owns all of them except G1, which is iOS build's. The biggest risk is #57: the kitchen grammar runs before the set, lift and task parsers, so it takes over phrases those parsers used to handle.

## Core: Tess kitchen grammar (#57)

Root cause: `TessGrammar.swift:50` calls `parseKitchen` before `parseRelativeSet`, the lift parser and `parseTask`. The test change at `TessTests.swift:171` (swapping "buy chalk" for "ring the gym about chalk") hid this.

- **K1 (high): "buy …" and "get …" turn dated tasks into groceries.** `TessGrammar+Kitchen.swift:26`. *Same as Fix 1 in `docs/product/kitchen-acceptance.md`.*
  - **Failure:** "get the car serviced friday" adds a grocery item "the car serviced friday" and an Ingredient with that name, instead of a Friday task.
  - **Fix:** return nil when `TessDates.extract` finds a date in the rest. Consider dropping "get" too.
- **K2 (high): any comma phrase becomes a grocery list.** `TessGrammar+Kitchen.swift:32-39`. *Same as Fix 2 in `docs/product/kitchen-acceptance.md`.*
  - **Failure:** "bench 80, 8" (dictation adds commas) used to log 80 × 8. Now it adds a grocery item "bench 80". "felt good, slept badly" also lands on the list.
  - **Fix:** try `parseLift(normalize(phrase))` first, or move the bare-comma rule after the lift and set parsers.
- **K3 (medium): "timer" plus any number starts a kitchen timer.** `TessGrammar+Kitchen.swift:46-56`
  - **Failure:** "remind me to reset the oven timer at 9 tomorrow" starts a 9-minute timer instead of making a task.
  - **Fix:** require "timer" at the start or end, or a time unit. Bail out to the task parser when the phrase has a date or a task word.
- **K4 (medium): loose recipe matching makes dated tasks into "Cook …" tasks.** `TessGrammar+Kitchen.swift:67` and `:82`
  - **Failure:** with a recipe "Brunch pancakes", "run 7am" becomes "Cook brunch pancakes" at 7:00. The match is by substring, so "run" is found inside "brunch".
  - **Fix:** without "cook"/"make" in front, match whole words or require the title as a prefix.

## Core: recipes and ingredients (#50, #52)

- **K5 (high): steps that start with "Cook", "Prep" or "Total" and contain a duration are dropped.** `Kitchen/RecipeParser.swift:50-57`, regex at `:109`
  - **Failure:** "Cook the pasta for 10 minutes." is read as a cook-time line and discarded, even under a Method heading. "Prep the veg, about 15 min" also overwrites `activeMinutes`.
  - **Fix:** require "time" or a colon after the keyword, e.g. `^(prep|active|cook|cooking|total)(?:\s+time\s*:?|\s*:)\s*(.+)$`, or skip this check in steps mode.
- **K6 (high): plural stripping mangles names, and the mangled name becomes the Ingredient's title.** `Kitchen/Quantities.swift:165-166`, used by `Kitchen/Ingredients.swift` `key(for:)`
  - **Failure:** "2 garlic cloves" creates "Garlic clof". Olives become "Olif" and chives "Chif". The "ies" rule turns cookies into "Cooky". These titles show on recipe pages and grocery items, and AisleGuide can't match them.
  - **Fix:** limit "ves" → "f" to a short list (leaves, halves, loaves, calves). Title new Ingredients with the name as typed and keep `key` only for matching.
- **K7 (high): a range with a mixed-number top is cut short.** `Kitchen/Quantities.swift:117`
  - **Failure:** "1–1½ cups flour" parses as amount 1–1 with no unit and name "1/2 cups flour". Scaling and groceries get the wrong quantity.
  - **Fix:** add `\d+\s+\d+\/\d+` as the first option of the upper-bound group, matching the lower bound.
- **K8 (medium): "T" reads as teaspoon.** `Kitchen/Quantities.swift:43` and `:53`
  - **Failure:** "1 T butter" becomes 1 tsp, 3x too little. In recipes, capital T means tablespoon.
  - **Fix:** check case before lowercasing ("T" means tablespoon, "t" means teaspoon), or drop the single-letter forms.

## Core: lists and shopping (#49, #56)

- **K9 (medium): undoing a list delete brings back items already cleared.** `Engine/ObjectStore.swift:62-68`, undo at `Actions/ActionEngine.swift:225`
  - **Failure:** check milk, clear done, delete the list, undo. Milk comes back as a checked item. The same happens to any recipe or list child that was deleted earlier.
  - **Fix:** in `restore`, only un-delete children whose `deletedAt` equals the parent's.
- **K10 (low): "Shopping, N left" on Now goes stale.** `Kitchen/Shopping.swift:455`
  - **Failure:** mid-shop with 3 left, adding "milk" leaves Now at "3 left" until the next check-off.
  - **Fix:** call `refreshShopLine` at the end of AddGroceries, AddRecipeToGroceries, RemoveRecipeFromGroceries and ClearDoneItems.

## Core: workout engine (#47, #48)

- **K11 (high): the #48 hotfix overcorrected, so plan targets now say "First time. Start light".** `Training/Prefill.swift:44-49`, label at `Features/Workout/WorkoutSession.swift:571`
  - **What's wrong:** in the `.target` branch, `lastTime` is always empty, because a non-empty `lastTime` already returned as `.lastTime`. So `isFirstTime` is always true and "From the plan" can never show.
  - **Failure:** demo Incline DB Press opens at 26 kg with "First time. Start light". Swaps and Tess-set targets are affected the same way.
  - **Fix:** mark first-time only when the weight is the starting weight that StartRoutine filled in (`PlanActions.swift:129`). Better, have StartRoutine flag the entry, or leave `targetWeight` nil and let the no-target branch supply the starting weight.
- **K12 (medium): `-resetDemo` leaves the gym kit unconfigured on every later launch.** `Engine/ObjectStore+Lifecycle.swift:62-63` with `Features/Demo/DemoData.swift:22-27`
  - **What's wrong:** library classes survive the wipe, so no equipment objects are recreated. `configureEquipment` then runs over nothing, and the new plan blocks it from ever running again.
  - **Failure:** dumbbells use the default rack and barbells use default plates.
  - **Fix:** force `ExerciseLibraryInstaller.install` in `resetUserData` before `StarterContent.installIfNeeded`, or configure equipment whenever it's missing.
  - *Debug and reset path only.*

## iOS build: Home (#46 meets #47)

- **G1 (high): Home's Tess line presents the empty bar as an earned target.** `Features/Home/TrainingPage.swift:115-118`
  - **What's wrong:** this is the same #46/#47 mismatch that #48 didn't cover. `tessLine` assumes any `targetWeight` was earned, but since #47 StartRoutine writes the starting weight there.
  - **Failure:** on a fresh install, start today's routine and close the live cover. Home then says "Bench Press is ready for 20 today."
  - **Fix:** use the same first-time test as K11 and hide the line, or say "start light", when the weight is the starting weight.
  - *Fix it together with K11.*

## Groceries screen (#58)

No bugs. Engine calls go through `perform` with undo, the aisle order matches the engine, and the DEBUG seeding stays out of release builds. One nit:
- **G2 (low):** `Features/Groceries/GroceriesView.swift:126-127` clears the draft even when AddGroceries throws. Typing "500 g" and pressing return loses the text with no feedback. Clear the draft only when perform succeeds.

## Clean

- #51, #59 and #60 are docs only.
- #53 (scaling), #54 (groceries and aisles) and #55 (cooking timers) held up. Their timer math, step clamping, share merging and remove-a-recipe logic all read correctly.
