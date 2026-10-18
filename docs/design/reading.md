# Reading: resume, the book page and the shelf (M5 screens 6, 5 and 7, steer)

For Builder B, after Core's `Book`, reading as a process and `Bookshelf` (ship-list-m5-reading slices 1 to 3). It is drawn to `no-buttons.md`. Recording: `recordings/reading.mp4` (source `studies/reading.html`).

Shared: vermilion only for a running book, cobalt only for Tess. There are no covers in v1, so type carries every screen. **There are no counts anywhere.**

## 6 · A book on Now and in What's running
- **On Now** (from 19:00, when nothing else is current): the NOW label, the title at Hero 56, "p 142 of 612" in Body, and **RESUME** as a label word. The top seam is unlit (14% ink) while the book is suspended.
- **In the ledger:** the title at the ledger's size, with "p 142" as its second line. It reads like any process.
- **RESUME** (or a tap on the title) zooms straight to the book page:
  - The title stays put and rises 68pt into the page's hero (460ms, house curve). Home blurs back.
  - The seam lights vermilion, drawn left to right (520ms), because the book is now running.
  - The page drum lands at eye level, and **one glint** sweeps across the numeral (760ms, soft-light white, once only). This is the "where I stopped" cue. Under Reduce Motion it is a `.selection` haptic instead.
- Leaving the page suspends the book through the existing rules.

## 5 · The book page
- **Label:** READING (the breadcrumb). **Hero:** the title at 56.
- **Context line in Body:** "p 142 of 612 · started 9 days ago", or "p 142" when the pages are unknown.
- **The page drum** is the reps drum's sibling: 96 Light tabular, 100pt rows, masked to 25% at the edges, with "of 612" at 34 Light beside it.
  - A flick coasts (ease-out cubic, about 900ms) and ticks `.selection` per page. The context line's number follows live.
  - On release it writes `SetBookPage`, and Tess says "Dune, p 168."
- **One level deeper** (swipe up): author, pages and the review as sentences with value words that edit in place, never a form. For example: "By **Frank Herbert**. **612** pages."
- **Finished** is a stroke word in sage at Title 34. **Hold it (0.6s):** it empties to a 20% trace, repaints left to right, and the tip blooms (`FinishBook`, `.done` once; a set-aside plays nothing).
  - SET ASIDE leaves, and one faint writing line opens under it: "One line on it?" at 50%, with a 1pt cobalt line. Tess asks the same.
  - What you type is a cobalt ghost. On Return it dries to ink over 600ms and saves as the review. Tess says "Finished Dune: slow start, great end."
  - Leaving it empty is fine. The line just fades when you leave.
- **SET ASIDE** is a label word on the right (`SetBookAside`). Tess says "Set Dune aside." with UNDO. There's no red, and nothing is struck.

## 7 · The reading shelf
- **Not a grid:** titles as one typographic column, at x 22.
- **Reading first:** each title at Title 44/500, with its page in Label tier under it ("P 88").
- **The queue next,** oldest first: titles at 28/500, 38pt lines.
- **Finished last,** newest first: titles at 24/400 at 45% ink, 34pt lines. Tap one to show its review line under it (fade, 220ms).
- **A book finishing** flies from its hero into the top of the finished list as it shrinks and dims (620ms, ease-out cubic), and the finished titles below step down on the settle spring.
- **Never a count** ("47 to read" never appears), no shelves, no progress bars.
- **New book:** say it ("read Dune"); it arrives as a ghost at the end of the queue.
- **Empty shelf:** one cobalt line from Tess by her soul: "Tell me what you're reading."

## Accessibility and Reduce Motion
- The page drum is an adjustable element: "Page 142 of 612". Finished reads "Finished, hold to mark Dune finished".
- Shelf titles read with their state: "Piranesi, reading, page 88"; "Dune, finished, slow start, great end".
- **Reduce Motion:** the zoom is a cross-fade, the glint becomes a haptic, the drum steps without coasting, and the title fades into the shelf instead of flying.
