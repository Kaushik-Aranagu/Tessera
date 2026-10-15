# Lists screens 9-12: decisions and acceptance (Builder B)

*Kitchen lead (Lists owner), 2026-10-15. Design's sheet (c8a83ff) maps every row below and is accepted. This reads with Design's `docs/design/kitchen/lists-9-12.md` (Design branch; it supersedes sheet 15), `ship-list-lists.md`, `lists-acceptance.md` (engine slices 1-8) and Research's `docs/research/lists-daily.md`. First I settle Research's open points G1-G13, then give one pass/fail row per screen element. Product can overrule any line.*

## Decisions on Research's gaps

| G | Decision |
|---|---|
| G1 Door | Yes: a `.lists` case on `HomeLink`, and the word "Lists" on Home's Kitchen page under Groceries. "lists" in the ghost row opens the shelf too. |
| G2 Starting a run | Starting a run opens the list page already running, with the vermilion seam. Now's "X, N left" opens the same page. |
| G3 A list at the right time | Research's default: a task or workout that @links a list shows it as an ink word on Now 60 min before. Nothing more in v1. |
| G4 Packing | Yes. Packing is a third reusable starter list, with CLOTHES, TECH and PAPERS sections, added to `starter-lists.md`. |
| G5 Books | Books is a plain list until Reading ships, and nothing moves automatically after that. |
| G6 Bare phrase on a list page | On a list page, a bare item or comma list goes to that list, and "done" finishes the run. |
| G7 "buy" | It still means Groceries. Tess names the list, and "move to errands" fixes it. |
| G8 Cleaning | A cleaning round is a reusable list. It has no ages and no link to chores. |
| G9 Finished trip lists | When a non-reusable list finishes with nothing open, it is put away with Undo. Tess says "Packing, Lisbon put away." |
| G10 Shelf order | The running list comes first and largest, then lists by last touched. |
| G11 Two runs | The new run takes Now, and the old one waits in the ledger. Runs never stack. |
| G12 Pick from the shelf | Holding a shelf name that has Pick one on runs the pick over the shelf. On any other name, the hold does nothing. |
| G13 Endless skips | After the last skip, the column comes back and Tess says "That's all of them." |

## Acceptance rows

**9 · Shelf**
| # | Pass when |
|---|---|
| 9.1 | The back word "‹ KITCHEN" sits at the top, LISTS is in labels, and the context line reads "6 lists, packing running" |
| 9.2 | Names are sized by last touched (56, then two at 34, the rest at 21 at 75%), and the running list is first and largest (G10) |
| 9.3 | State words sit under the names in labels: "3 OF 7", "RUNNING" in vermilion with a lit seam, "REUSABLE", "PICK ONE" |
| 9.4 | On arrival, the names settle into their sizes with a stagger |
| 9.5 | Pasting a block anywhere gives a wet cobalt ghost list at the foot of the column with "Twelve things, two sections." It dries in 2 s or on tap, then moves to its place by last touched: to the top at 56 when nothing runs, or just under the running list at 34 when one does (G10) |
| 9.6 | Groceries appears once and opens Groceries. "Archived" sits at the foot at 45% |

**10 · A list page**
| # | Pass when |
|---|---|
| 10.1 | The hero sits at y 142 with the context line above it. Option words, once used, form one labels line under the hero |
| 10.2 | Rows are 48 pt at 21/400, with amounts at 600. Sections are margin words at 34 and items hang at x 64, with no checkboxes or separators |
| 10.3 | Tapping strikes and sinks exactly as in Groceries, and the fold counts up with Tick |
| 10.4 | Tapping the fold restores items. Holding it for 0.7 s clears done items. On a reusable list it reads "hold to reset", the strikes un-paint right to left, and the items rise back |
| 10.5 | Tapping the context line unfolds the option words in place (Sections · Reusable · Run it · Pick one · Archive). There is no sheet, and tapping outside folds them |
| 10.6 | Swiping on x pages between sibling lists, and the hero parallaxes |
| 10.7 | Running gives a lit seam, 64 pt rows, and sections that fold away as they finish. The run survives locking the phone |
| 10.8 | The ghost row on the page adds to this list (G6) |

**11 · An item, opened**
| # | Pass when |
|---|---|
| 11.1 | The item zooms open from its row, and its text is the hero at 56 |
| 11.2 | The note can be edited in place. @links are cobalt and open their object with one tap, at first sight. An empty note shows "Add a note" at 40% |
| 11.3 | Tapping the date word opens the day lane (one row of day words, snapping on x). "Add a day" shows when there is no date |
| 11.4 | LINKED FROM lists the backlinks at the bottom |
| 11.5 | Swiping right on the hero strikes the item, following the finger, then zooms back |

**12 · Pick one**
| # | Pass when |
|---|---|
| 12.1 | Holding the hero for 0.6 s fills its underline. This works only when Pick one is on, and also from the shelf (G12) |
| 12.2 | The others dim to 14% with a 2 pt blur. One name lifts out, grows to 56 at the centre and lands in 520 ms, with a small bloom and a medium haptic |
| 12.3 | Tapping opens the item. Swiping left sends it back and picks again after 200 ms. A skip writes no `pickedAt` |
| 12.4 | After the last skip comes "That's all of them." (G13) |
| 12.5 | With Reduce Motion on, it crossfades to the centre with no growth |

**Everywhere:** nothing under 16 pt, no cards, pills or sheets, and motion only through `MotionPolicy`. Each screen PR includes a recording under `docs/recordings/` that starts on the page.

## On the phone, after merge

Research's five moments, each used for a real week: leaving the house, gym bag, grocery and errands runs, film night pick, and packing for a trip. Any way in that takes more than 2 steps is a fail.
