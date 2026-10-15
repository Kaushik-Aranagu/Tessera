# 13 · Groceries (build sheet)

Just enough to build. Product steer: `docs/product/ship-list-kitchen.md` §13. Engine: slices 1, 6, 7 (list, groceries merge, aisles) and 8 (shopping as a process). Folder: `Features/Groceries/`.

Light ground (`ThemedBackground`, Home's paper and washes). Kitchen colours: **sage** `Theme.Colors.health` for fresh things and done, **cadmium** `Theme.Colors.now` for heat and timers, **vermilion** only for something running, **cobalt** `Theme.Colors.tess` only for Tess. No checkboxes, no cards, no pills, no stock `List`.

## The page (one screen tall)
| y | Element |
|---|---|
| 58 | **Kitchen rail:** `CarriageRail` with RECIPES · GROCERIES. Swipe between them on x |
| 112 | **Context line** (Body 21/400, context colour): "14 to get, for carbonara and two more" · "Nothing to get" |
| 142 | **Hero:** "Groceries" (Hero 56/500). **Press and hold it to start shopping** (see At the shop). A faint label under it on first use only: "HOLD TO SHOP" |
| 232 → 700 | **The aisle window:** bounded, scrolls vertically, fades out over its last 40pt. The only thing that scrolls |
| 708 | **The basket fold** (see below) |
| bottom | The Tess bar (`BottomChrome`), unchanged |

### Aisles and items
- **Aisle word:** Title tier at **34/500**, ink at 85%, at x 22. Its items hang **below and to the right**, starting at x 64. That 42pt step is the asymmetry; don't centre or right-align anything.
- The aisle word **pins** at the top of the window while its items scroll under it, then is pushed off by the next aisle word. Sticky section headers, but set as words, not bars.
- Aisle order is the shop's walk order: produce, bakery, dairy, meat and fish, tins and jars, dry goods, spices, frozen, household, other. Empty aisles are hidden.
- **Item row:** 48pt tall, full width from x 64. One line: the amount in **21/600** and the name in **21/400** ("**600 g** tomatoes", "**2** lemons"; a bare name has no amount). It must fit on one line, so truncate the name, never the amount.
- **Which recipes it's for:** a sage `PaintDab` (12×10) at the row's trailing edge (x 346), only when the item links to a recipe. **Press and hold the item** and a sage line slides out under it at 18/400: "for carbonara, shakshuka" (row grows by 24pt, 260ms, house spring). While held, the item is lifted: drag it onto another aisle word to move it, which also teaches its ingredient that aisle.
- 24pt between aisles; no separators between items, no rules between aisles.

### Checking an item: strike and sink (the one living moment)
1. Tap the row. An ink strike runs through the text (`StrikeRenderer`, 320ms), and the text dims to 40%. Light impact haptic at the end of the strike.
2. After 450ms the struck text **folds into a small sage dab**, which drops along an arc into the basket fold. Use separate x and y easing like the soul's travel: x `cubic(.55,0,.15,1)`, y `cubic(.3,0,.25,1)`, 520ms. The row closes behind it (height to 0, 280ms).
3. The basket count rolls up by one (`Tick`), and the fold breathes once (its wash goes from 10% to 18% and back, 400ms).
- Under Reduce Motion: strike, then crossfade the row out; the count still ticks.
- **Undo:** the Tess bar reads "Eggs in the basket." with **Undo** on the right until the next item is touched.

### The basket fold
- A strip 44pt tall at y 708, full width. A `Seam` along its top edge, a sage wash at 10% below it, and "**6** in the basket" at Body 21 (count in 600) at x 22.
- **Tap** it: the basket rises as a sheet (to y 300, house spring) listing checked items, still struck, in the same layout. Tap one to put it back (it un-strikes and flies to its aisle). At the bottom is a hold key, "Clear the basket" (`PaintKey`, hold 0.7s).
- Empty basket: the fold shows nothing and takes no space.

### Adding (the ghost row)
- Through the Tess bar: "eggs, milk, 2 lemons". Each item is a **wet cobalt ghost row** in its own aisle, drying over 2s (the existing ghost pattern).
- Before they land, one small cobalt dab per item arcs from the bar to its aisle (the same arc easing, staggered by 60ms). The window scrolls to the first new item if it's off screen.
- Items merged into an existing one ("400 g + 200 g") don't add a row; the existing amount rolls to the new total (`Tick`) under a cobalt wash that fades over 2.8s.

## At the shop (a running process)
Start by holding the hero for 0.7s (a vermilion paint fill spreads through the word, like the hold key), or by telling Tess "shop". This starts the shopping process: Now on Home reads "Shopping, 9 left", and the lit `ProcessSeam` runs along the top edge.
- The kitchen rail and the basket fold go away. The screen stays awake. **Every target is at least 64pt.**
- y 70: **Context line**, "shopping, 9 left".
- y 104: **The current aisle at hero size:** "Produce" (56/500).
- y 190 → 640: **This aisle's items only,** 64pt rows, same type as above (21/600 amount, 21/400 name), from x 22 now (no hang). Strike and sink still apply, but the dab drops off the bottom edge.
- y 660: **The next aisle peeks:** "then Dairy" at 34/500 at 35%.
- **When an aisle empties, it folds up and away:** the hero word and its emptied list tilt back about the top edge (`rotation3DEffect` x −65°, anchor top) and fade, 420ms. The next aisle rises into the hero slot (14pt up, blur 4→0, 340ms). Medium impact haptic.
- **Swipe up** on the hero to skip an aisle (it goes to the end). **Swipe down** to go back.
- **Finishing:** after the last aisle, or by holding "Done" (a `PaintKey` pinned at the bottom, hold 0.7s), the basket is cleared, the process ends, and Tess says one line, e.g. "All 14. Basket's clear."
- **Leaving the shop:** backgrounding suspends it into Home's ledger as "Shopping, 9 left, in Dairy"; resume lands on that aisle.
- Reduce Motion: aisles crossfade instead of folding.

## States
- **Empty:** the hero stays. The context line reads "Nothing to get". In the window, one cobalt line: "Tell me “milk, eggs”, or swipe a recipe's ingredients here."
- **Everything checked:** the window is empty apart from the context line "All in the basket", and the fold shows its count.
- **Long lists:** only the window scrolls; the aisle word pins as above.
- **Dynamic Type at accessibility sizes:** the hang becomes a 20pt indent, and the amount moves onto its own line above the name.
