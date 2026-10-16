# Money and Reading: the first screens, with real copy (board item 8)

This sheet deepens `money-pages.md`, `money-dial.md` and `reading.md` for whichever builder takes them. Where they differ, this sheet wins.
- Drawn to `no-buttons.md`, `themes.md` (one base), `no-dots.md` and `ink-line.md`.
- The data is the shared eval store: Thu 15 Oct 2026, 18:00.
- The copy is from Research's `fixtures/money.md`, `fixtures/reading.md` and `fixtures/show-photos.md`.
- Still: `mockups/money-reading-first.png` (source `studies/money-reading-first.html`).

## The HomeLink words (the doors)
- **Review's link line becomes two lines.** Line 1 is The week · Day log · Notes. Line 2 holds the life areas: **Reading · Money · Upkeep · People**.
- It's `HomeLinkLine` at Body 21/600 ink, where a tap zooms in. This supersedes the one-line order in `upkeep-people-first.md`.
- Add the cases `.reading` and `.money` to `HomeLink`. The back word on both pages is **‹ REVIEW**.
- When a book is running, it's also on Now and in the ledger (`reading.md` §6), so Reading has two ways in.

## Money

**Currency-neutral copy (Money decision 1: no home currency).**
- An amount is shown exactly as typed. "12.40" never gains a symbol, and "$38.20" keeps its own.
- The month sentence covers spends with no currency. Each currency said gets one line under it.
- **Never sum across currencies,** and never pick a symbol from the phone's locale.
- The examples use Kaushik's own shops and dollars. Fixture amounts with no symbol stay unmarked.

### The month page (screen 7): the first screen
- **MONEY**, then the hero **"October, logged"** at Title 44.
- **The sentence** is Body 21, with numbers at 600: "**7** spends. Most went to lunch, **24.80**, and coffee, **9.00**."
- **Each other currency** gets a line right under it, 32pt apart:
  - "Also **$38.20** in 1 spend."
  - "Also **€8.00** in 1 spend."
- **The peek:** the first ledger line sits at the foot of the page at 45%. It's a hint, not text he needs to read.
- **Empty month:** the hero reads "October: nothing logged yet", and Tess says "Tell me what you spent. Try: spent 4.50 coffee."
- **The moment:** when a new spend is logged while the page is open, the sentence's count and the touched category tick on the settle spring, with a faint `now` wash behind the number that dries. There's no other colour on the page.

### The ledger (one swipe up)
These are changes to `money-pages.md`, to meet the type tiers and the colour rules:
- **The label** is "OCTOBER · 9 SPENDS". The count includes every currency, because it counts spends, not money.
- **The day numerals** are 34 Light in `inkTertiary`, in the margin.
- **Each spend:**
  - The amount is Body 21/600, tabular, right-aligned in a 96pt column.
  - The word is 21/400 in `inkSecondary`, not the context colour: no tinted word on every line (`no-dots.md`).
  - Lines are 36pt apart, and day blocks are 22pt apart.
- **Other currencies** sit under their own label (IN DOLLARS, IN EUROS) as a short ledger in the same form.

### A receipt shown to Tess (the receipt ghost, from `show-photos.md`)
This is decided: photo reads never commit by themselves, so the receipt ghost **waits for a tap**. That settles Research's question 1.

**The ghost row** sits in the queue window, the same as any Tess ghost:
- The line is Title 34 in wet cobalt, breathing: "Trader Joe's, **$38.20**?". The amount is as read, with the symbol only if the receipt has one.
- Under it are the route words TOTAL · RECIPE · NOTE as labels. The chosen route is `ink` and sits on the ink line in `now`; the others are `inkSecondary`.
- **For a shop total,** a Body line in `inkSecondary` follows: "From the 5:40 shop on Groceries."

**Taps:**
- **Tapping the row or TOTAL** commits it.
  - The words dry from cobalt into ink, left to right (700ms).
  - The ink line under TOTAL gives its tip bead.
  - Tess says "Groceries, $38.20. Logged." for a shop total, or "Logged $38.20, Trader Joe's." for a plain spend.
- **Tapping RECIPE or NOTE** moves the ink line to that word (240ms, house curve), and the line rewrites as that route's ghost ("A note: Trader Joe's receipt").
- **Swiping the ghost away** writes nothing.

**Low confidence** (fixture rows 5 to 9):
- The ghost reads "Is the total **$12.35**?".
- The amount dial opens under it at that amount (`money-dial.md`), and turning it edits the ghost live.

**Nothing found:**
- Tess says "Couldn't find a total. **Type it?**", where "Type it?" opens the dial.
- A card photo gets "That looks like a card. Nothing kept." No ghost appears, and nothing is stored.

### The spend page (screen 6)
`money-pages.md` stands, with two changes:
- The word in the context line is `ink` at 600 (a value word), not the context colour.
- Delete is the swipe with UNDO, as written.

## Reading

### The shelf (screen 7): the first screen
These are changes to `reading.md`, to meet the type tiers:
- **READING, then the books being read,** most recently touched first.
  - Each title is Title 44/500, with its page as a label line in `inkSecondary`.
  - Fixture: **Dune** "P 120 OF 612", **Project Hail Mary** "P 88 OF 476".
- **NEXT** (label), then the queue, oldest first, at **Body 21/500 ink**: Dune Messiah, It, Atomic Habits, 1984, The Sun Also Rises. (`reading.md` had 28, which isn't a tier.)
- **FINISHED** (label), then Body 21/400 in `inkSecondary`, newest first: Educated. A tap shows its review line under it.
- **SET ASIDE** (label), then the same style, with where it stopped as a label: "Catch-22 AT P 88". A tap offers RESUME as a label word.
- **Never a count.** No covers, no grid, no progress bar.
- **The moment:** when a book finishes, its title flies from the hero into FINISHED (`reading.md`), and the ink line under "Finished" gives its bead first.
- **Empty:** Tess says "Tell me what you're reading."

### A book on Now, and the book page (screens 6 and 5)
`reading.md` stands, with these changes:
- "Finished" is the stroke word, now on the thin ink line in `health`.
- The page drum's glint is the look's sheen.
- Under "Finished", the "One line on it?" writing line is the 0.5pt cobalt hairline, as in Notes.

## Accessibility and Reduce Motion
As in the source sheets, plus:
- **The receipt ghost** reads "Trader Joe's, 38 dollars 20, total. Double tap to log. Actions: recipe, note, dismiss."
- **A ledger line** reads "15 October, 12.40, lunch", and a currency line reads "In dollars, 14 October, 38 dollars 20, groceries".
- **Reduce Motion:** the ghost dries as a crossfade, and the route move is a fade.
