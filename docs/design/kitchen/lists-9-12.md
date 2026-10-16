# Lists screens 9 to 12 (build sheet): values for the Kitchen lead's steers

> **Sweep 16 Oct (item 19):** parts of this sheet are amended by `sweep-19.md` (no dots, one base, the context line). Where they differ, `sweep-19.md` wins.

The steers in `ship-list-lists.md` (Kitchen lead) are the design; this sheet adds exact values and settles three clashes. **It supersedes my sheet 15** (`14-15-shelf-and-lists.md`, "Lists app v0"). Folder: `Features/Lists/`. Same instrument as Groceries (`13-groceries.md`): tap strikes and sinks, no checkboxes, no separators. Lists lean lilac `#D8CBE6` and sky `#9EC3D6` in the washes.

Recordings:
- **Pick one and the reset hold:** `../recordings/lists-pick-and-reset.mp4` (source `../studies/lists-pick-reset.html`).
- **The door, the shelf, a pasted block, and Pick one from the shelf through to "That's all of them.":** `../recordings/lists-shelf.mp4` (source `../studies/lists-shelf.html`).

Checked against the Kitchen lead's `docs/product/lists-screens-acceptance.md` (rows 9.1 to 12.5, decisions G1 to G13). Row numbers are in brackets below; the last section maps every row.

## Three clashes, settled (my defaults)
1. **Long-press on the hero** was both "options" and "pick one". Now: **hold the hero = Pick one** (only when Pick one is on), and **tap the context line = options**. The line unfolds in place into the option words (Sections · Reusable · Run it · Pick one · Put away), with no sheet. Words rise in at a 30ms stagger, and tapping outside folds them back.
2. **"A short sheet of words"** becomes that in-place unfold. Sheets are a stock pattern, and the words fit on the page.
3. **An item's date "changed on the day strip":** the item page doesn't have the day strip. Tapping the date word opens a **day lane** in place: a single row of day words ("Today · Fri · Sat · Sun · Mon …") that scrolls on x with snap, with the carriage under the chosen one. That's the day stroke's x lane in words.

## 9 · Lists shelf
| y | Element |
|---|---|
| 58 | Back word **‹ KITCHEN** (`back-word.md`) |
| 96 | **LISTS** in labels, in ink: the shelf's name (9.1) |
| 124 | Context line (21/400): "6 lists, packing running" (9.1) |
| 172 → 700 | The column, bounded, snapping per name, fading over its last 40pt |
| last | "Put away" at 21/400, 45%, zooms into the lists he put away |

- **The door (G1):** on Home's Kitchen page, **Lists** sits under Groceries as a Title 34 word with its dab (planning colour), and Recipes moves down one. While a list runs, its state rides beside it in vermilion labels: "PACKING · 9 LEFT". Tap zooms into the shelf from the word (scale 0.94 → 1, 420ms) while the Kitchen page lifts away. "lists" typed in the ghost row opens the shelf too.
- **Order and sizes (9.2, G10):** a running list is always first and at Hero 56/500, with a 2pt lit vermilion seam over its name (150pt, drawn in left to right on arrival, 300ms). Then lists by last touched: two at Title 34/500, the rest at 21/500 at 75%. Spacing: 108pt after a 56, 80 after a 34, 58 after a 21. With nothing running, the most recently touched list takes the 56.
- **State words (9.3)** under each name in labels, 8pt below it: "RUNNING · 9 LEFT" in vermilion, "3 OF 7", "REUSABLE", "PICK ONE", "EMPTY" for a list with nothing on it, "14 TO BUY" for Groceries.
- **Arrival (9.4):** every name starts at Body 21 and settles into its tier and place, 25ms apart (420ms each, house curve).
- **Paste a block anywhere (9.5):** the lines appear as a ghost list at the foot of the column, where Put away was, in wet cobalt at 55% with its state word ("12 THINGS · 2 SECTIONS"). Tess says "Twelve things, two sections." It dries over 2s (cobalt to ink) or on tap. Then it moves up to its place by last touched and grows into that tier. That's the top and 56 when nothing runs; under the running list, at 34, when one does (G10 wins over "moves to the top"). The context line counts up as a value word ("7 lists, packing running").
- **Groceries appears once (9.6)** in the order, as "Groceries", and opens `GroceriesView()`. **Put away** sits at the foot at 21/400, 45%.

## 10 · A list page
- Hero (list name) at y 142; context line above it at y 112; option words, once used, as one labels line under the hero ("REUSABLE · PICK ONE").
- **Items window:** y 232 to 700, 48pt rows, at 21/400 (amount or quantity first at 600, as in Groceries). Section words at 34/500 in the margin at x 22, items hanging at x 64, as aisles.
- **Strike and sink:** exactly as Groceries (strike 260ms, sink arc 520ms into the fold, Tick on the count).
- **The fold** is pinned at y 708: "**4** done". Tap it to open and restore; hold it 0.7s to clear done. On a reusable list, the fold reads "**4** done. Hold to reset.": while you hold, the paint drains *out* of the struck items (each strike un-paints right to left, 30ms stagger), and on release they rise back into place.
- **x between lists:** swipe pages to the sibling lists; the hero parallaxes at 0.6 of the page's travel, and the rail at the top shows the list names (scrolling on x past four).
- **Running (10.7, G2):** **Run it** (an option word) or Now's "Packing, 9 left" opens the page already running. The lit vermilion seam draws across the top edge (300ms), the context line reads "Packing, running", rows grow from 48 to 64pt (320ms, house curve), and the page reads like Groceries' at-the-shop mode: each section folds away as its last item strikes. The run is a process, so it survives locking the phone and shows on Now.
- **Two runs (G11):** starting a second run takes Now; the first waits in Home's ledger with its RESUME label word (`home-labels.md`). The shelf shows both with RUNNING, the newer first.
- **A trip list finishing (G9):** when a list that isn't reusable strikes its last item, the page zooms back out to the shelf, its name sinks into Put away (fading to 45%, 420ms), and Tess says "Packing, Lisbon put away." with **UNDO**.
- **Bare words on this page (10.8, G6):** the ghost row adds to this list: "passport, adapter" lands as two wet cobalt rows in their section, and Tess says "Passport and adapter, added to Packing." with UNDO for 4 s (one thing: "Rice, added to Packing."). "done" finishes the run; on a reusable list it asks before anything resets (addendum below). "buy milk" still goes to Groceries, and Tess names it (G7).
- **On Now (G3):** a task or workout that @links a list shows the list as an ink label word under its meta, 60 min before: "GYM BAG". Tapping it opens the page.

## 11 · An item, opened
- Zoom from the row (`navigationTransition(.zoom)` from the item's text). The item text becomes the hero (56/500, up to 3 lines).
- The paragraph sits at 21/400 under it, editable in place, with @links in cobalt 500. If it's empty, there's one line at 40%: "Add a note".
- **Date:** a word line ("Thursday", 21/600) that opens the day lane described above. If there's no date, "Add a day" at 40%.
- **Backlinks:** names at 21/500 at the bottom, under a labels line "LINKED FROM".
- Strike from here too: swipe right on the hero (the strike follows your finger, as in `today-on-home.md`). It checks the item and zooms back to the list.

## 12 · Pick one
- **Hold the hero for 0.6s** (12.1): a 3pt ink underline fills left to right under the name as the hold progresses. Only when Pick one is on. **From the shelf (G12):** the same hold on a name whose state word is PICK ONE runs the pick over the shelf. The shelf dims, and the picked item lifts out of the name. On any other shelf name the hold does nothing (no haptic).
- The other names dim to 14% and blur 2pt (300ms), so the pick reads clear of the column behind it. One name lifts out of the column with matched geometry, grows to Hero 56 at the centre of the window (y 400), and lands in 520ms on the house curve.
- Behind it, the soul's **bloom**, small (scale 0.6, 900ms, once). `.impact(weight: .medium, intensity: 0.6)` plays when it lands.
- **Tap** it to open the item. **Swipe it left** to send it back to the column (it shrinks back into its row) and pick again after 200ms; the same motion and haptic play each time.
- **Skips write no `pickedAt`** (12.3); only opening one does.
- **After the last skip (12.4, G13):** the item shrinks back like the others, the column (or the shelf) comes back to full in 300ms, and Tess says "That's all of them." The next hold starts the round again.
- Reduce Motion: a crossfade to the picked name, at the centre, with no growth (12.5).

## Every acceptance row
| Row | Where above | Recording |
|---|---|---|
| 9.1 to 9.4, 9.6 | §9 table, order and sizes, state words, arrival, Groceries | lists-shelf |
| 9.5 | §9 paste | lists-shelf |
| 10.1, 10.2 | §10 hero and items window | lists-pick-and-reset |
| 10.3, 10.4 | §10 strike and sink, the fold and reset | lists-pick-and-reset |
| 10.5 | Clash 1 and 2: the context line unfolds the option words | not recorded |
| 10.6 | §10 x between lists | not recorded |
| 10.7, 10.8 | §10 running, bare words | not recorded |
| 11.1 to 11.5 | §11 | not recorded |
| 12.1 to 12.5 | §12 | both |
| G1, G10, G12, G13 | §9 door, order; §12 | lists-shelf |
| G2, G3, G6, G7, G9, G11 | §10 | not recorded |
| G4, G5, G8 | Engine and starter lists only; nothing new on screen | |

**Everywhere:** nothing under 16pt; no cards, pills or sheets; motion only through `MotionPolicy`. Each screen PR includes its own recording, starting on the page.

## Addendum, Oct 16 (Kitchen lead's Lists acceptance refresh)
The Kitchen lead found three places where this sheet predates Product's words, and named the defaults it took where the sheet was silent. The word swaps are made above: Archive is now "put away" everywhere, EMPTY is a state word, and the bare-words receipt names the things first.

**"done" on a reusable list asks; it never resets on its own.**
- He says or types "done" on a reusable list. The run finishes as any run does: the seam undraws and the rows shrink back to 48 pt. The struck items **stay struck**.
- Tess: "Packing, done. Reset it for next time?" Under her line are two label words: **RESET**, which is a hold of 0.7 s (the ink line fills under the word as he holds, like FINISH on Home), and **NOT NOW**, a tap.
- **RESET held:** the reset plays as the fold's hold does. The paint drains out of each struck item, right to left with a 30 ms stagger, and the items rise back into place. Tess: "Packing, reset." with UNDO for 10 s (a change). The context line rolls to "11 to pack" (the Packing starter, `product/starter-lists.md`).
- **NOT NOW,** or nothing for 10 s: her line goes and nothing changes. The fold still reads "**12** done. Hold to reset.", so the reset is still one hold away.
- One haptic: the hold's completion tick. A tap on RESET does nothing but show the ink line start to fill, so he learns that it's a hold.

**Empty states (these supersede sheet 14-15's "Nothing here yet.").**
- **An empty list page:**
  - the hero is the name;
  - the context line, in `context`, reads "nothing on it yet";
  - the items window is empty, with no placeholder rows;
  - on the shelf, its state word is EMPTY.
  Typing or pasting on the page adds to it, as bare words already do.
- **An empty shelf** (Groceries is the only list): Groceries takes the 56. Under it, one line at Body 21 `inkSecondary`: "Paste a list anywhere to make one." Put away is absent until something has been put away.

**The Kitchen lead's defaults, adopted as drawn:**
- A left swipe that starts on a row is the row's remove (sheet 71, rule 3).
- Paging on x starts on the hero, the context line or a section word.
- Removing the last open row in a run finishes its section as a check would. It never puts a list away.
- The remove phrase on a list page needs no list name. A name that isn't on the list gets "No rice on Packing."
- The back words are "‹ LISTS" on a list page and "‹ PACKING" on an opened item.
- An opened item has no remove. The strike is its only swipe.
- The shelf's pick dims the other names to the same 14% as the page.
- At accessibility sizes there is one column everywhere.
