# 10 · Recipe page and 11 · Paste a recipe (build sheet)

> **US shop (item 25):** aisle names, amounts, fractions, pack sizes and merging for a US kitchen are in `us-shop.md`, which wins over this sheet's metric and UK examples.

Just enough to build. Product steer: `docs/product/ship-list-kitchen.md` §10 and §11. Recording of the brush read, save, the portion drum rolling amounts and the swipe to Groceries: `../recordings/recipe-and-paste.mp4` (source `../studies/recipe-and-paste.html`). Engine: slices 3 (recipe and parser) and 4 (scaling). Folder: `Features/Recipes/`. Light ground, kitchen colours as in `13-groceries.md`.

## 10 · Recipe page (an object page)
| y | Element |
|---|---|
| 58 | **Path** in labels: "RECIPES" (a link back to the shelf) |
| 90 | **Hero:** the recipe name (Hero 56/500, up to 3 lines; then step down to 44, then 34). **Tap it** to go one level deeper: the original pasted text, cook history and notes |
| below hero, +14 | **Context line** (21/400, context colour): "serves 2, 35 min, cooked 12 days ago". Leave out any part that's missing; never "never cooked" |
| 256 → 650 | **Ingredients**, in a bounded window that scrolls only if it must, with the portion drum on its right |
| 666 | **"7 steps"** in labels at x 22. A small peek of what's below, not a list |
| 690 | **Cook**: an ink `PaintKey` (220×58) **on tap**, no hold. Beside it in labels: "35 MIN" |
| bottom | Tess bar |

### Ingredients
- One column from x 22 to x 280, 44pt rows, no bullets, no separators.
- Each line: the amount in **21/600**, then the ingredient in **21/400** ("**200 g** spaghetti"). Prep after a comma at 21/400 in `inkSecondary` (", finely diced"). Wrap to two lines at most.
- **Staples** (salt, oil, pepper) sit at 45%, and their amounts at 400.
- **Tap** an ingredient to zoom into the Ingredient object (where it's used, its aisle).
- Amounts that aren't metric (tsp, tbsp, cup) stay as written; tap the amount to flip it to metric for a moment (it flips back after 3s).

### The portion drum (sibling of the reps drum)
- At the right (x 300 → 368, top aligned with the first ingredient), reuse `RepsDrum`'s look: three numbers visible at a 44pt pitch, the centre at **48 Light**, neighbours at 21 and 35%, with "serves" at 18 under it.
- **Turning it rescales every amount on the page** through `RecipeMath.scaled`. Each amount that changes rolls to its new value (`numericText` content transition, 220ms, staggered 15ms down the column). No reload, and the layout must not jump: amounts sit in a fixed-width tabular column.
- Selection haptic per step. The size goes back to the recipe's own on leaving, unless a cook is started (the cook remembers it).

### Add to groceries: a swipe, not a button
- **Swipe left across the ingredient column.** The whole column follows the finger; past 40% of the width, it releases and slides off the left edge toward the Groceries page (360ms), in rows staggered 20ms.
- It leaves behind one line where the column was: "**12** to buy, in Groceries" (21, count in 600, sage), with "Undo" on the right. After 4s the column slides back in place.
- Staples are skipped (dim rows stay put while the rest slide).
- One-tap twin: the same action sits in the menu under the hero ("Add to groceries").

### The one living moment
The **amounts rolling** when the drum turns. Make it feel like the whole recipe re-sets itself: tabular figures, a short stagger down the column, no fade.

### States
- **No servings in the source:** the drum shows "–" and is disabled; the context line leaves out "serves".
- **Very long ingredient lists (over 9):** the window scrolls with a fade at the bottom; the drum stays put.
- **Just pasted:** the page arrives from the paste reader with the hero entering from the right (18pt, blur 4→0, 340ms).

## 11 · Paste a recipe (the capture surface)
Open from the shelf's empty state, the shelf's "Paste" action, or by pasting into the Tess bar text with an "Ingredients" heading.

- **The paste lands as it is:** the raw text, in Body 21/400, ink at 85%, laid out exactly as pasted from y 150 in a scrolling column, 22pt gutters.
- **y 70, a cobalt line from Tess** (21/400, appears once the read finishes): "Eight ingredients, six steps, two timers."
- **The read is a brush passing over the text,** top to bottom over about 600ms (a soft cadmium-to-clear gradient band, 80pt tall, moves down the column, multiply blend at 25%). As it passes, marks paint in under it:
  - **Amounts:** a cadmium under-stroke (`Brushstroke`, 3pt, drawn in 180ms).
  - **Ingredient names:** a sage `PaintDab` (10×8) just before the word.
  - **Durations:** a small cadmium tick mark after the phrase ("simmer 20 min ✓").
  - **Step breaks:** a hairline in the left margin (x 8 → 16) with the step numeral at 16/700 in labels.
  - **The title:** the first line is promoted to Title 34/500 in place (a crossfade of size, 300ms).
- **Fixing a misread:** tap a word or line to cycle it: ingredient → step → ignore. Its mark repaints, and ignored text dims to 35%. No forms, no fields.
- **Save:** a `PaintKey` "Save recipe" pinned at the bottom (tap). It commits as a ghost row (Tess bar: "Carbonara saved." with Undo) and zooms into the new Recipe page.
- **Leave without saving:** swipe down; nothing is written.

### The one living moment
**The brush passing.** It's the whole point: the text you pasted is visibly read, never replaced.

### States
- **Nothing recognised:** no marks; Tess says "I couldn't find ingredients. Tap a line to mark one." The text stays.
- **Very long pastes:** the brush pass is capped at 900ms, and anything below the fold is marked on arrival as you scroll.
- **Reduce Motion:** no moving band; all marks fade in together over 200ms.
