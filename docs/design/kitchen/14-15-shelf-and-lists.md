# 14 · Kitchen shelf and 15 · Lists app v0 (build sheet)

Just enough to build. Product steer: `docs/product/ship-list-kitchen.md` §14 and §15. Light ground, kitchen colours as in `13-groceries.md`.

## 14 · Kitchen shelf (`Features/Recipes/`, the RECIPES page)
The front of the kitchen and the RECIPES sibling of Groceries on the kitchen rail.

| y | Element |
|---|---|
| 58 | Kitchen rail, RECIPES · GROCERIES (`CarriageRail`) |
| 112 | **Context line** (21/400): "14 recipes, carbonara last night" |
| 150 | **Filter words** in labels, off by default: QUICK · NOT LATELY · FROM THE BASKET. A selected word gets the painted vermilion carriage under it (the same as the rail). Fixed rules for now |
| 196 → 700 | **The shelf:** a bounded vertical window with snap per name, fading at its last 40pt |
| bottom | Tess bar |

### The shelf: a typographic column, not a grid
- One recipe name per line, left aligned at x 22, **sized by use** over the last 90 days:
  - Most cooked: Hero 56/500, ink 100%.
  - Regulars: Title 34/500, ink 90%.
  - Everything else: Body 21/500, ink 70%.
  - Not cooked in 60+ days: 21/400 at 45%.
  - Keep it to about 3 hero-sized names at most, so the column has a clear top.
- Order is by most recently cooked, newest at the top.
- No rules, no rows, no counts. A recipe with a cook running shows a 2pt vermilion seam above its name, the ledger's language.
- **Tap a name** to zoom into its Recipe page (`navigationTransition(.zoom)` from the name).
- **Filters:** turning one on drops names that don't match. The rest close up, keeping their sizes (house spring, 320ms).
- **Paste:** "Paste a recipe" sits as the last line of the column, in cobalt at 21/400; it opens the paste reader (sheet 11).

### The one living moment
On arrival, the names **settle into their sizes**: each enters at Body size and grows to its tier in a quick stagger (25ms) down the column. The shelf visibly arranges itself by use.

### States
- **Empty:** the column holds one cobalt line at Title 34/400: "Paste a recipe and I'll read it." Tapping it opens the paste reader.
- **Under five recipes:** no hero-sized names until something has been cooked twice.

## 15 · Lists app v0 (`Features/Lists/`)
Any slice-1 list: packing, to read, gifts. It uses the Groceries instrument, minus aisles and the basket fold's shopping mode.

- **x: each list is a page;** lists are siblings. The rail at y 58 shows the list names in labels with the carriage (scrolling horizontally if there are more than four).
- **Hero:** the list name (Hero 56/500). **Context line** above it: "7 left, 3 done".
- **Items:** 21pt, one per 48pt row, from x 22 (or hanging 42pt under a section word when sections exist). Section words are 34/500 in the margin, exactly as aisle words.
- **Check:** the same strike and sink as Groceries, into a "**3** done" fold pinned at the bottom (tap it to see and restore; hold "Clear done").
- **Add:** the writing line at the top, or "list: packing, add charger" through the Tess bar.
- **New list:** "list: packing" through Tess, or the last page on x, "New list" in cobalt at Title 34.
- **Empty list:** "Nothing here yet." at Title 34, with "Tell me what to add." in cobalt under it.
