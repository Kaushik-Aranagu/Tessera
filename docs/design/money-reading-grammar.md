# Money and Reading on the new grammar (Design item 60)

**Kaushik's principle, in one line:** one plain line per thing, the detail one tap down, nothing cut and nothing decorated; a spend is a word and an amount, a book is a title and where he is in it.

Redraws `money-reading-first.md`, `money-pages.md` and `reading.md` (which keep the engine, the copy, the currency rule and the never-lists) under sheet 41's one-line grammar, `no-dots.md`, the one-base rule, `empty-states.md` and `back-word.md`. Research's `fixtures/money.md` and `fixtures/reading.md` lines stand.

- Board: `mockups/money-reading-grammar.png` (source `studies/money-reading-grammar.html`): the month, a spend landing, a spend one tap down, the shelf (Obsidian), a book (Obsidian), the empty shelf.
- Recording: `recordings/money-reading-grammar.mp4` (12 s), Porcelain: "spent 18.90 dinner" from Home lands as the top line of today (the amount wet, drying 2 s, the count rolling), tap the line, the spend grows out of it, tap the word to retag (recent words slide in, one tap, "18.90, now takeout." with UNDO), ‹ MONEY back with the line reading its new word.

## Money, the month page
| y | Element |
|---|---|
| 58 | **‹ REVIEW** (back-word.md: Reading · Money · Upkeep · People on Review's link line) |
| 84 | **Money** at Title 44 (day-seams S4) |
| 146 | **The context line** in `context`: "October, 16 days in"; pinch out for September as before ("September, all of it") |
| 200 | **The month sentence**, Body 21 with numbers at 600, wrapping: "**7** spends. Most went to lunch, **24.80**, and coffee, **9.00**." Each other currency one line under it at `inkSecondary`: "Also **$38.20** in 1 spend." (Money decision 1: no sums across currencies) |
| then, 330 on | **One line per spend under its day label.** The day as a label word (15 OCT, Label 16/700 `inkSecondary`), then each spend on one Body 21 line: the word in ink at the left, the amount at the right at 600, tabular, **as typed** ("€8.00" keeps its sign, "12.40" gains none), never red. Lines 40 apart, days 16 apart. Other currencies follow under IN DOLLARS, IN EUROS, the same form. Newest first |
| 686 to 736 | The page fades over its last 50 pt above Tess's band; the band's ground is clear and the list scrolls under it |

What goes: the swipe-up ledger state and the month line lifting into a label (the sentence and the lines are one page now), the faint peek, the 34 Light day numerals in the margin (a day is a label word, as everywhere), the context-coloured category word (no-dots: no tinted word on every line).

**A spend logged** while the page is open (from Home, "spent 18.90 dinner"): the lines under today's label make room (40 pt, 360 ms), the new line rises in at the top of today, its amount **arrives in `tess` and dries to ink over 2 s**, the sentence's count rolls like a value word, and Tess says "Logged 18.90, dinner." with UNDO. Nothing else on the page colours.

## A spend, one tap down (‹ MONEY)
| y | Element |
|---|---|
| 84 | **The amount as the hero**, Hero 56 tabular (the fitting form: 56 → 44; a long foreign amount never cuts) |
| 156 | **The context line**: the word as a value word in ink at 600, then the time in `context`: "**lunch**, Thursday 1:10 pm" |
| 220 on | **The rest as sentences**, Body 21, 40 apart, with value words: "Typed as **spent 12.40 lunch**.", "In **no currency**." (cycles, as on the dial), "A note? **Add one**.", a shop total's "From the **5:40 shop**, on **Groceries**." |
| after them + 32 | **DELETE SPEND** as an ink-line word. Tess: "Deleted 12.40, lunch." with a 10 s UNDO. The hero's drag-left delete from `money-pages.md` stays as the shortcut |

**Retag:** tap the word and up to four recent words slide in on the line below (300 ms); the sentences make room (36 pt); one tap swaps the word with the value-word blur (`EditSpend`, `.selection`), Tess: "18.90, now takeout." with UNDO. Typing a new word makes the slot a field, as before.

The spend grows out of its line (the page fades 380 ms, the amount settles into the hero at 84); ‹ MONEY is the reverse, and the line reads its new word.

## Reading, the shelf
| y | Element |
|---|---|
| 58 | **‹ REVIEW** |
| 84 | **Reading** at Title 44 |
| 146 | **The context line**: "2 going, Dune last night"; "1 going, Dune this morning"; "Nothing on the go" |
| 200 on | **One line per book under its group word.** READING, NEXT, FINISHED, SET ASIDE as label words (32 under each the first line, 16 between groups); each book on one Body 21 line, the title in ink (600 while it is being read, 400 otherwise), and **where it is as the value at the right**, Label 16/600 `inkSecondary`: P 120 OF 612, OCT 3 (finished), AT P 88 (set aside); a queued book has none. Lines 40 apart. Reading first, most recently touched first; the queue oldest first; finished newest first |

What goes: the Title 44 rows for books being read (one line per thing, the same size as the rest), the three type sizes for the three groups, the covers and counts that were never there. A finished book's review line shows under its title on a tap, as before (fade, 220 ms).

**A book finishing** on its page: its line flies from the hero into the top of FINISHED as the page folds back (620 ms); the FINISHED group's lines step down on the settle spring. **A new book** ("read Dune") arrives as the last NEXT line, rising 10 pt.

## A book, one tap down (‹ READING)
| y | Element |
|---|---|
| 84 | **The title** at Title 44, the fitting form (44 → 34 → two lines of 34) |
| 146 | **The context line**: "p 142 of 612, started 9 days ago"; "p 142" when the pages are unknown |
| 220 | **The page drum** as the instrument (`reading.md`): 96 Light tabular, 100 pt rows, the neighbours at 14%, "of 612" at 34 Light on the baseline; a flick coasts and ticks `.selection` per page; on release `SetBookPage`, Tess: "Dune, p 168." The one glint on arrival is the look's `sheen` (Reduce Motion: `.selection` instead) |
| 480 | **FINISHED** and **SET ASIDE** as ink-line words, side by side. FINISHED is a hold (0.6 s): the line fills, `FinishBook`, `.impact(medium, 0.8)`; then the "One line on it?" writing line opens under it at Field 18 with the hairline that inks in (the Notes grammar), Return saves the review, Tess: "Finished Dune: slow start, great end." SET ASIDE: Tess "Set Dune aside." with UNDO |
| one swipe up | author, pages and the review as sentences with value words, unchanged |

What goes: the READING breadcrumb label (it is the back word now), the Title 56 hero (44, as every page one tap down), the sage stroke word (an ink-line word, its fill the only colour, as `ink-line.md`).

**On Now** a suspended book is a Home line under 41: hero "Dune, p 142", context "last night", key RESUME DUNE; the key's ink line fills with the page share once he has a page count (p 142 of 612 = 23%), as the Start key does for sets.

## Empty states (`empty-states.md`, unchanged)
Money: ‹ REVIEW, "Money", "October, nothing yet" as the context line, "Nothing logged yet." at 200, Tess: "Tell me what you spent. Try: spent 4.50 coffee." Reading: "Nothing on the go", "No books yet." at 200, Tess: "Tell me what you're reading. Try: reading Dune."

## Rules kept
1. **One base** per look; Obsidian phones are the same frame.
2. **No dots, no seams, no rows.** A day and a group are label words; the only colour at rest is the context line.
3. **Nothing cut.** A long category word or title wraps its line (74 tall, the value on the first line).
4. **An amount is never red; a count never appears on the shelf.** Both never-lists stand.
5. **Haptics,** one per moment: `.selection` on a retag and per drum page, the finish's impact, nothing for a spend landing (the capture had its own).
6. **Reduce Motion:** lines fade in place, the hero crossfades, the drum steps, the flight is a fade.

## For Builder A (Money, Reading) and Builder B (Home's book line)
- `Features/Money/`: `MonthPage` as the sentence plus `SpendLine`s under day labels (no `LedgerPage` state, no peek, no margin numerals); `SpendPage` with the amount hero, the value-word context line, the sentences, `DELETE SPEND`; ‹ REVIEW and ‹ MONEY with `EdgeSwipeBack()`.
- `Features/Reading/`: `ShelfPage` as `BookLine`s under group labels; `BookPage` with the Title 44, the context line, the drum, FINISHED and SET ASIDE as `InkLabelWord`s, the review writing line; ‹ REVIEW and ‹ READING.
- Builder B: the suspended book's Home line and RESUME key from `HomeLines`.
- Every clip ends inside the app.

## Addendum (Oct 16, Research 130 / Product 999df84)
- **RF15:** the finished-book receipt is "**Dune, finished.**" (thing first), not "Finished Dune." Wherever the sheet or the recording words the finish, this is the line.
- **RF18:** "read 20 pages" is one write: a reading record that the Read habit counts, so no second check-in that day. Nothing to draw.

## Addendum, Oct 16: receipts and bests (Design 62, `copy-pass.md`)
"Dune, set aside." joins "Dune, finished." (thing first). The full table is in `copy-pass.md`; where a clip still says the old words, the sheet wins.
