# Lists screens 9 to 12 (build sheet): values for the Kitchen lead's steers

The steers in `ship-list-lists.md` (Kitchen lead) are the design; this sheet adds exact values and settles three clashes. **It supersedes my sheet 15** (`14-15-shelf-and-lists.md`, "Lists app v0"). Folder: `Features/Lists/`. Same instrument as Groceries (`13-groceries.md`): tap strikes and sinks, no checkboxes, no separators. Lists lean lilac `#D8CBE6` and sky `#9EC3D6` in the washes.

Recording of Pick one and the reset hold: `../recordings/lists-pick-and-reset.mp4` (source `../studies/lists-pick-reset.html`).

## Three clashes, settled (my defaults)
1. **Long-press on the hero** was both "options" and "pick one". Now: **hold the hero = Pick one** (only when Pick one is on), and **tap the context line = options**. The line unfolds in place into the option words (Sections · Reusable · Run it · Pick one · Archive), with no sheet. Words rise in at a 30ms stagger, and tapping outside folds them back.
2. **"A short sheet of words"** becomes that in-place unfold. Sheets are a stock pattern, and the words fit on the page.
3. **An item's date "changed on the day strip":** the item page doesn't have the day strip. Tapping the date word opens a **day lane** in place: a single row of day words ("Today · Fri · Sat · Sun · Mon …") that scrolls on x with snap, with the carriage under the chosen one. That's the day stroke's x lane in words.

## 9 · Lists shelf
| y | Element |
|---|---|
| 58 | Rail: LISTS (one word; the shelf is the front page) |
| 112 | Context line (21/400): "6 lists, packing running" |
| 150 → 700 | The column, bounded, snapping per name, fading over its last 40pt |
| last | "Archived" at 21/400, 45%, zooms into archived lists |

- **Sizes by last touched** (like the recipe shelf's by use): the most recent at Hero 56/500, then 2 at Title 34/500, the rest at 21/500 at 75%. The state word sits under each name in labels: "3 OF 7", "RUNNING" (vermilion, plus a 2pt lit vermilion seam above the name), "REUSABLE".
- **Arrival:** names settle into their sizes (Body → tier, 25ms stagger), as on the recipe shelf.
- **Paste a block anywhere:** the lines appear as a ghost list at the bottom of the column (cobalt, wet), and Tess says "Twelve things, two sections." It dries in 2s or on tap. The new list then grows to hero size and moves to the top, because it's now the most recently touched.
- Groceries appears once, as "Groceries", and opens `GroceriesView()`.

## 10 · A list page
- Hero (list name) at y 142; context line above it at y 112; option words, once used, as one labels line under the hero ("REUSABLE · PICK ONE").
- **Items window:** y 232 to 700, 48pt rows, at 21/400 (amount or quantity first at 600, as in Groceries). Section words at 34/500 in the margin at x 22, items hanging at x 64, as aisles.
- **Strike and sink:** exactly as Groceries (strike 260ms, sink arc 520ms into the fold, Tick on the count).
- **The fold** is pinned at y 708: "**4** done". Tap it to open and restore; hold it 0.7s to clear done. On a reusable list, the fold reads "**4** done · hold to reset": while you hold, the paint drains *out* of the struck items (each strike un-paints right to left, 30ms stagger), and on release they rise back into place.
- **x between lists:** swipe pages to the sibling lists; the hero parallaxes at 0.6 of the page's travel, and the rail at the top shows the list names (scrolling on x past four).
- **Running** (slice 5): the lit vermilion seam on the top edge, "Packing, running" in the context line, and the page reads like Groceries' at-the-shop mode (64pt rows, sections fold away as they're done).

## 11 · An item, opened
- Zoom from the row (`navigationTransition(.zoom)` from the item's text). The item text becomes the hero (56/500, up to 3 lines).
- The paragraph sits at 21/400 under it, editable in place, with @links in cobalt 500. If it's empty, there's one line at 40%: "Add a note".
- **Date:** a word line ("Thursday", 21/600) that opens the day lane described above. If there's no date, "Add a day" at 40%.
- **Backlinks:** names at 21/500 at the bottom, under a labels line "LINKED FROM".
- Strike from here too: swipe right on the hero (the strike follows your finger, as in `today-on-home.md`). It checks the item and zooms back to the list.

## 12 · Pick one
- **Hold the hero for 0.6s** (paint fills the hero's underline as the hold progresses).
- The other names dim to 14% and blur 2pt (300ms), so the pick reads clear of the column behind it. One name lifts out of the column with matched geometry, grows to Hero 56 at the centre of the window (y 400), and lands in 520ms on the house curve.
- Behind it, the soul's **bloom**, small (scale 0.6, 900ms, once). `.impact(weight: .medium, intensity: 0.6)` plays when it lands.
- **Tap** it to open the item. **Swipe it left** to send it back to the column (it shrinks back into its row) and pick again after 200ms; the same motion and haptic play each time.
- Reduce Motion: a crossfade to the picked name, at the centre, with no growth.
