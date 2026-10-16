# The Kitchen week, drawn (Design item 67)

**Kaushik's principle, in one line:** Groceries should sort itself and know which meal each thing is for, without ever nagging; a planned meal puts what is missing on the list and says so in one line.

Checks Core's Kitchen slice (#380 at 79475ed: Research 123's five meals with the Kitchen lead's G-R1 to G-R16 rulings) against Design 47 (`groceries-tess.md`, with its 7d16c88 recipe-line addendum and `copy-pass.md`), and draws the recipe page in layout C (`recipe-layouts.md`, the default while he picks). For Builder B and the Kitchen lead. Every screen below is 47's frame: ‹ KITCHEN at 58, "Groceries" at 84, the count line at 140, the aisle window from 200 fading over its last 50, USUALLY at the foot, Tess's band.

- Board: `mockups/kitchen-week.png` (source `studies/kitchen-week.html`), Porcelain: before planning, tacos planned, chili planned (the joins), frittata planned (a typed amount stays, a checked row covers), everything already there, the recipe page in layout C.
- Recording: `recordings/kitchen-week.mp4` (12 s): tacos planned, 10 rows fly in from Tess's corner 60 ms apart and dry over 1.4 s while the count rolls and "Tacos, 10 added." lands with UNDO; frittata planned, 3 rows and "for frittata" landing under the eggs he typed; tacos again with everything there, "Tacos, nothing to add." and no UNDO.

## What Core's rules look like on the page
| Rule (#380) | On the page |
|---|---|
| The planned meal's missing lines (G-R3, G-R14): staples, "to taste" and optional lines never land | Wet cobalt ghost rows in their aisles, each with "for tacos" under it, flying in from Tess's corner 60 ms apart, drying to ink over 1.4 s after landing; the rows below make room first (320 ms). Kosher salt, olive oil, hot sauce and "cheddar, optional" never appear |
| The receipt | **"Tacos, 10 added."** with UNDO 10 s (Product 3:15 AM, thing first). One row: "Tacos, added." The **short name**: the title's last word, capitalised ("Tacos", "Pasta", "Chili"; Kitchen lead #389), the full title only when two planned recipes share one. The same word lower-cased is the recipe line ("for tacos"), the count line and the Home line |
| Nothing missing | **"Tacos, nothing to add."** (Product e1981a39). No UNDO (nothing was written), no ghost rows, the count line unchanged |
| A same-key row joins silently (G-R2, G-R6): the bare row takes the recipe's amount | "onion" (typed bare) becomes "**2** onion" with "for tacos" under it. A row he typed **with** an amount keeps it: "1 dozen eggs" stays "1 dozen eggs" and "for frittata" lands under it (Kitchen lead, #389). The changed amount or new line turns wet with the landing and dries with the rest; no second row, no line from Tess about the join |
| A pack and a weight join pack first (G-R8, 7d16c88) | "**1 can + 15 oz** black beans" with "for tacos and chili · 15 oz" |
| Two pack sizes are two rows (G-R1, U5) | "**1 can** diced tomatoes / for chili · 28 oz" and "**1 can** diced tomatoes / for curry · 14.5 oz", never "2 cans" |
| A checked row covers the line (G-R2, #383) | A checked "butter" in the fold means the frittata adds no butter; the fold reads "**1** done" and nothing lands |
| Two meals share a row | "for tacos and chili"; three or more "for tacos and 2 more" (digits, 62) |
| The count line | "12 to get, for tacos"; "14 to get, for tacos and chili"; "17 to get, for tacos and 2 more". Never a count of what was covered or skipped |
| Aliases and prep words (G-R5, G-R6) | The row is the ingredient's key: "cilantro" not "chopped fresh cilantro", "ginger" not "grated ginger", "onion" for the yellow onion. The recipe page keeps the prep words |
| US aisles (G-R7) | Produce, Dairy and eggs, Meat and seafood, Cans and jars (broth too), Spices, Pantry, in `us-shop.md`'s walk order; "green onions" in Produce |

## The recipe page, layout C (the default until he picks)
‹ RECIPES at 58; the title at Title 44 in the fitting form (two lines for "Sheet-pan chicken fajita tacos", the context line moving to 186); the context line "Thursday, 35 min, serves 4" (the planned day first, when planned; else "35 min, serves 4"); y is time: the ink stroke from the first step to the last, each step at its minute with the lines it uses under it at 16; **optional and "for serving" lines sit on the page at 38% ink, marked as written ("cheddar, optional", "hot sauce, for serving"), and never on the list.** PLAN THURSDAY as the ink-line word (a tap plans it; a planned page reads COOK first); the clock, the shopping swipe and Core's start-minutes are `recipe-layouts.md` §C. When he picks A or B, only this page changes; nothing on Groceries does.

## Home (47 §5, 62)
The planned cook's Home line carries the open count: context "2 to buy" over the hero "Tacos tonight" with GROCERIES as the key; at zero the context is the time ("at 7 pm") and the key reads COOK. Never a badge, a dot or a notification.

## For Builder B and the Kitchen lead
- Builder B: the ghost-row landing and dry (47 §3) with #380's rows; the count line's roll; the receipt from the short name; "nothing new to buy" as a line with no UNDO; the joined row's amount turning wet; the fold's "N done" covering; the recipe page's optional lines at 38%.
- Kitchen lead / Core: the short name is the title's last word capitalised (#389); the rest as #380 built it.
- Every clip ends inside the app.
