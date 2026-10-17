# Which release carried which Kitchen feature (releases 1 to 7)

*Kitchen lead, 2026-10-17. Built from the merge log between the release SHAs in `pin-checklist.md` (line 59: 1 = 56dd028, 2 = 648d9d0b, 3 = 4757aefb, 4 = 553ad19e, 5 = ab7d3bfe, 6 = eca3c834, 7 = 26dde994). Docs-only PRs are left out. A row marked (?) was matched on its PR subject, not its files, so check it before relying on it.*

| Release | Kitchen code that shipped |
|---|---|
| 1 | The whole v1 kitchen: Ingredient class and lines, recipe scaling, pasted-text parser and paste screen, recipe page, Groceries (aisles that learn, basket fold, Done shopping, receipts "Tacos, 2 added." and "Milk, on Groceries."), cook-mode engine and timers, Lists (starter lists, Packing, "Rice, on Packing."), Tess kitchen phrases and grammar fixes, meal plan feeding Groceries (#380 with rulings #383, #389), capture-miss log, secret-word wall on paste and links, Add-line price strip (#538), command walls on paste (#544), overnight cook row finish time (#552, files in Review (?)) |
| 2 | Kitchen grammar changes for Groceries, paste, Lists and Tess (#571); Kitchen sides job cards (#563 (?)) |
| 3 | Paste screen changes (#573) |
| 4 | No Kitchen code |
| 5 | Groceries and paste edits riding the Review foot line (#583 (?)) |
| 6 | No Kitchen code |
| 7 | Groceries, Recipes, Lists and RecipeLinkReader changes (#592 (?)); Core's BuyCadence and KeepPlannedTask from the op log (#605) |

## Not in any release yet

AI-12 (Groceries that know your recipes: engine and Builder B page); recipe clock layout C with per-step start offsets; cook mode slices 12 and 12b; parallel steps in one cook; Pantry (engine and screen); Kitchen v2 slices L1 to L3, P, R and W; the bundled USDA food table and the Kitchen sides screens (sheets 75 to 78); paste hardening gaps 1, 3, 4 and 5; the recipe-link money strip (B 0z); the overnight rows' acceptance (O1 to O4, #611).

Acceptance docs for all of these are on master (`kitchen-sides-acceptance.md`, `pantry-acceptance.md`, `cook-mode-acceptance.md`, `groceries-ai-acceptance.md`, `paste-hardening-acceptance.md`, `never-sums-audit.md`).
