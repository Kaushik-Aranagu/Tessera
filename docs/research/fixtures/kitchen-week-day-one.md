# Kitchen week: the day-one walk (Product item AF)

For: Builder B (screens), Core (engine, grammar), Kitchen lead (rules), Product.
Owner: Research lab. Date: Oct 16, 2026 (Pacific). Master `4d67f94`, traced by hand, nothing was run.

**What "Kitchen week" is.** Design 67 (`docs/design/kitchen-week.md`, Design branch `claude/project-thread-b3tu3f`
at `34b6bc8`, not on master) draws it as no new page: a planned meal puts its missing lines on Groceries ("Tacos, 10
added."), the recipe page reads PLAN THURSDAY, and Home carries "Tacos tonight, 2 to buy." A week strip of dinners is
Kitchen v2 (`product/kitchen-v2-backlog.md:10`). Rules: `product/meal-plan-groceries-acceptance.md` (defaults),
`product/groceries-ai-acceptance.md` (rows 3, 5, 8, 9), G-R1 to G-R16 (#380, #383, #389), recipe clock rulings
(#419, #427, #461; Design 69 at `042c76f`): a step running over HOLDS, the bead waits, later minutes shift.
Receipts: thing first, 10 s UNDO, "X, taken back." (decisions 12:45 PM PT Oct 16).

**Setup.** Sunday Oct 18, 4:10 pm, phone. Recipes saved: "Sheet-pan chicken fajita tacos" and "Weeknight turkey
chili" (Research 123, `fixtures/groceries-recipes.md`). Groceries holds typed "onion" and "1 dozen eggs". He flies to
New York on Mon Oct 26. Status: pass, wrong (built, but not as ruled), miss (rule exists, nothing does it),
not built (the feature is absent).

| ID | He does | Expected (source) | Master today | Status | Owner |
|---|---|---|---|---|---|
| KW1 | Home, Kitchen | Groceries and Recipes words; no week page in v1 (Design 67) | Two words plus Paste a recipe (`Features/Home/HomeSpatialView.swift:357-382`) | pass | Builder B |
| KW2 | Says "cook tacos tuesday" | Task about the recipe; rows land at once: "Tacos, 10 added." UNDO 10 s (meal-plan defaults, changed Oct 16; G-AI row 3) | `CreateTask` only, receipt is the full title and day (`TesseraTess/TessCaptureEngine.swift:338-343`); `AddRecipeToGroceries` is never called on planning | miss | Core |
| KW3 | Says "cook chili thursday" | "Chili, N added."; black beans join pack first: "1 can + 15 oz black beans", "for tacos and chili · 15 oz" (G-R8) | Grammar reads it (`TessGrammar+Kitchen.swift:123-134`); join rule is in the engine (`Kitchen/Groceries.swift:335-341`) but planning never reaches it | miss | Core |
| KW4 | Opens the chili recipe | Context "Thursday, 35 min, serves 4"; PLAN THURSDAY word, COOK first once planned (Design 67) | Cook key only, "6 steps" (`Features/Recipes/RecipePage.swift:109-127`) | not built | Builder B |
| KW5 | Swipes the tacos ingredients to Groceries | "Tacos, 10 added." with UNDO for 10 s | "10 to buy, in Groceries", Undo gone after 4 s (`RecipePage.swift:184-197, 212-229`) | wrong | Builder B |
| KW6 | Watches the count | Only new rows count; a bare "onion" joins as "2 onion" silently (G-R2, G-R14) | New-row set feeds the count and the receipt (`Groceries.swift:347-363`) | pass | Core |
| KW7 | Swipes tacos again | "Tacos, nothing to add." with no UNDO (Product e1981a39) | Engine writes nothing (`Groceries.swift:312-315, 362`); page still shows "0 to buy, in Groceries" with Undo (`RecipePage.swift:189, 219-223`) | wrong | Builder B |
| KW8 | Looks for salt | Kosher salt, olive oil, "to taste", optional and "for serving" lines never land (G-R3, G-R4) | Skipped (`Groceries.swift:321-326`; `Kitchen/Aisles.swift:29-40`) | pass | Core |
| KW9 | Reads the tomato rows | Two rows, "1 can diced tomatoes" with " · 28 oz" and " · 14.5 oz", never "2 cans" (G-R1) | Engine keeps them apart (`Groceries.swift:68`, `USKitchenTests.swift:80`); the row never calls `packSize(of:)` (`Features/Groceries/GroceriesView.swift:195-196, 435-445`) | wrong | Builder B |
| KW10 | Reads under a row | "for tacos and chili", three or more "for tacos and 2 more", short names, no dab (Design 67, no-dots) | Full titles joined by commas, lowercased, plus a `PaintDab` (`GroceriesView.swift:195-196, 436-441`) | wrong | Builder B |
| KW11 | Scrolls Groceries | US aisles in walk order: Produce, Dairy and eggs, Meat and seafood, Cans and jars, Pantry, Spices (G-R7) | `Aisle` order and names (`Aisles.swift:7-25`) | pass | Core |
| KW12 | Reads the count line | "14 to get, for tacos and chili" (Design 67) | "14 to buy across 5 aisles" (`GroceriesView.swift:689-696`) | wrong | Builder B |
| KW13 | Pastes a link to a taco recipe | "Reading nytimes.com." then the recipe; private lines left out, "I left out 1 line that looked private." (PR6) | Lines cut and kept on the phone (`Kitchen/Recipes.swift:162-174`); link reader says "X saved." (`RecipeLinkReader.swift:52-54`); the paste line is not there (`docs/ops/board/ios-b.md:17`) | wrong | Builder B |
| KW14 | Tue Oct 20, 5:30 pm, Home | "Tacos tonight, 2 to buy." key GROCERIES; at zero COOK (G-AI row 8) | Words exist (`Home/HomeLines.swift:225, 266-277, 399-402`); `fact(plannedCook:)` has no caller and reads `due` while capture writes `startsAt` (`HomeLines.swift:563-567`) | not built | Core, Builder B |
| KW15 | 6:30 pm, taps COOK | Clock: step 1 lit, bead at 0, STOP "35 MIN LEFT", screen stays awake (Design 69) | `StartCooking`, "Cooking", no step minutes (`RecipePage.swift:113-127`, `Kitchen/Cooking.swift:72`) | not built | Builder B, Core |
| KW16 | Step 2 timer ends, chicken not done | Bead HOLDS at the step's end, later minutes shift (#461, decisions 12:05 PM PT) | No step minutes, steps start no timers | not built | Core, Builder B |
| KW17 | Says "next" | Bead and resume point move together to step 3 | `GoToCookStep` from the stale resume point: "Step 2." (`TessCaptureEngine.swift:363-368`) | wrong | Core |
| KW18 | Holds DONE | "Tacos, cooked." UNDO 10 s | "Sheet-pan chicken fajita tacos, done." (`TessCaptureEngine.swift:370-372`); no DONE key | wrong | Core, Builder B |
| KW19 | Puts 2 portions away | No rule: leftovers are out of v2 unless he asks (`product/kitchen-v2-scope.md:52`) | Nothing | not built | Kitchen lead |
| KW20 | Skips Wednesday's planned dal | Delete or undo the task: open rows carrying only its share go, checked rows stay (meal-plan defaults) | A share carries the recipe, not the task (`Groceries.swift:335-336`); deleting the task never touches Groceries; no "skip" word | miss | Core, Kitchen lead |
| KW21 | Says "move tacos to friday" | "Tacos, Friday."; rows already added stay (meal-plan defaults) | Task found and moved (`TessGrammar.swift:276-288`); receipt is the full task title, "Cook sheet-pan chicken fajita tacos, Friday ..." (`TessCaptureEngine.swift:360-362`) | wrong | Core |
| KW22 | Plans chili for Mon Oct 26 (trip day) | No rule for a meal on a day away | Task and rows as any day; Home would show it in New York | miss | Kitchen lead |
| KW23 | Thu, at the store: holds "Groceries", taps rows, DONE | Shop starts, one column in walk order, DONE clears the basket and ends the shop | `StartShop`, `FinishShop` (`GroceriesView.swift:265-283`; `Kitchen/Shopping.swift:50-69`); no receipt on finish | pass | Builder B |
| KW24 | Plans a frittata after checking butter | A checked row covers the line until the shop clears it (#383) | `covered` skips it (`Groceries.swift:327-334`) | pass | Core |
| KW25 | Sun Oct 25, resets the week | No rule: what clears (open rows, past plans, the basket) | Nothing resets; past cook tasks roll as tasks | miss | Kitchen lead |
| KW26 | Taps UNDO on the tacos plan | "Tacos, taken back."; exactly the 10 rows go (G-AI test 1) | Capture undo is silent (`App/AppModel.swift:298-309`, `Features/Command/BottomChrome.swift:736-745`); link undo "Chili mac taken back." with no comma (`RecipeLinkReader.swift:56-58`) | wrong | Builder B, Core |
| KW27 | VoiceOver on the recipe page | Swipe to Groceries as an action; back reads "Back to Recipes"; receipts announced (ios-b 0h) | Hint only, "Swipe left to add them to groceries" (`RecipePage.swift:273-275`); "Back to the recipes" (`:53`); no announcements | wrong | Builder B |
| KW28 | VoiceOver on Groceries | Row reads name and "for tacos"; title has a Start shopping action | Combined row with hint (`GroceriesView.swift:463-464`); action at `:346` | pass | Builder B |
| KW29 | Says "what's for dinner" | Answer from today's plan: "Tacos tonight, 2 to buy." | No grammar rule; falls to the model or nothing | not built | Core |
| KW30 | Thu, says "cook chili" | Starts the planned cook, and the plan's task closes | `StartCooking` (`TessCaptureEngine.swift:344-346`); the Thursday task stays open | miss | Kitchen lead, Core |

**Counts (30 steps):** pass 7, wrong 11, miss 6, not built 6. By owner (shared rows counted for each):
Builder B 16, Core 16, Kitchen lead 5.

## Top gaps

1. **Planning a meal never touches Groceries** (KW2, KW3, KW20, KW26): `.cook(recipe, date)` makes a task only
   (`TessCaptureEngine.swift:338-343`). Core: call `AddRecipeToGroceries` on capture, with a share carrying the task,
   so the receipt, UNDO and a later delete all work. This is the heart of Kitchen week; the engine under it passes.
2. **Home's planned-cook line is unwired** (KW14): `fact(plannedCook:)` has no caller and reads `due`, not `startsAt`.
3. **Groceries page copy is pre-Design 67** (KW9, KW10, KW12): count line, short-name recipe line, pack size, dab.
4. **Recipe page receipts** (KW5, KW7, KW26): "Tacos, 10 added." and "nothing to add." with 10 s UNDO, "taken back."
5. **The recipe clock** (KW15 to KW18) is not on master; the HOLD ruling has nothing to run on yet.

## Questions for Product

1. Kitchen week in v1 is Design 67's pattern (no page), and the week strip waits for v2. Confirm.
2. "what's for dinner": a grammar rule answering from today's plan, in these words? (KW29)
3. Short names in the reschedule and DONE receipts ("Tacos, Friday.", "Tacos, cooked.")? (KW18, KW21)
4. Kitchen lead: skipping a planned meal. Is there a "skip" word, and do its open rows go as on delete? (KW20)
5. Kitchen lead: a meal planned on a day away (Oct 26): plan as usual, or say "You're away Monday." first? (KW22)
6. Kitchen lead: the Sunday reset. What clears: past plans, open recipe rows, the basket, nothing? (KW25)
7. Kitchen lead: cooking a planned meal closes its task, and Home's line becomes the running cook? (KW30)
8. Kitchen lead: leftovers stay out of v1 and v2 unless he asks? (KW19)

## Rulings since this walk (Oct 16, 1:05 to 1:07 pm)

- Product 1:05 pm: v1 Kitchen week is Design 67 with no page of its own. "what's for dinner" becomes a grammar rule. Move and DONE receipts use short names ("Tacos, Friday.", "Tacos, cooked."). A dated cook task adds its share to Groceries, and skipping the cook takes it back. Fixes are on Core 0x and Builder B 0m.
- Kitchen lead (`product/meal-plan-groceries-acceptance.md`, last section):
  1. A skip word ("skip dal") does to Groceries what delete does: open rows carrying only this share go, and checked rows stay. The task closes as skipped so Review counts the miss. The receipt is "Dal, skipped." with UNDO for 10 s.
  2. A day away is planned like any day, and nothing is said first.
  3. There is no Sunday reset. Uncooked plans roll like tasks until they are cooked, moved or skipped.
  4. "cook chili" starts the planned cook, and Home's line becomes the running cook. The task closes on DONE, not at the start. Cooking on another day still closes the plan.
  5. Leftovers are out of v1 and v2. "put 2 portions away" is a note on the cook line, with no rows and no count kept.
- All five rest on KW2/KW3 (the share carries the plan task). AJ rechecks these rows on the 0x and 0m PRs.
