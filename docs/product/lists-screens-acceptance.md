# Lists screens 9-12: decisions and acceptance (Builder B)

*Kitchen lead (Lists owner), 2026-10-15; refreshed 2026-10-16 against Design's `lists-9-12.md` as amended, Design 65 `list-remove.md` and Product's decisions (put away, UNDO lengths, the reusable "done" ask). Design's sheet (c4b019f, with its addendum adopting the eight defaults below) maps every row below and is accepted. This reads with Design's `docs/design/kitchen/lists-9-12.md` (Design branch; it supersedes sheet 15), `ship-list-lists.md`, `lists-acceptance.md` (engine slices 1-8) and Research's `docs/research/lists-daily.md`. First I settle Research's open points G1-G13, then give one pass/fail row per screen element. Product can overrule any line.*

## Decisions on Research's gaps

| G | Decision |
|---|---|
| G1 Door | Yes: a `.lists` case on `HomeLink`, and the word "Lists" on Home's Kitchen page under Groceries. "lists" in the ghost row opens the shelf too. |
| G2 Starting a run | Starting a run opens the list page already running, with the vermilion seam. Now's "X, N left" opens the same page. |
| G3 A list at the right time | Research's default: a task or workout that @links a list shows it as an ink word on Now 60 min before. Nothing more in v1. |
| G4 Packing | Yes. Packing is a third reusable starter list, with CLOTHES, TECH and PAPERS sections, added to `starter-lists.md`. |
| G5 Books | Books is a plain list until Reading ships, and nothing moves automatically after that. |
| G6 Bare phrase on a list page | On a list page, a bare item or comma list goes to that list, with the receipt thing first ("Rice, on Packing.", UNDO 4 s; Product 12:27 PM Oct 16). "done" finishes the run on a plain list; on a reusable list it does not reset, it asks, with a hold to reset (Product decisions.md). |
| G7 "buy" | It still means Groceries. Tess names the list, and "move to errands" fixes it. |
| G8 Cleaning | A cleaning round is a reusable list. It has no ages and no link to chores. |
| G9 Finished trip lists | When a non-reusable list finishes with nothing open, it is put away with UNDO for 10 s. Tess says "Packing, Lisbon put away." and the name sinks into the put-away word at the foot. Removing the last open row does not put a list away; only finishing does. |
| G10 Shelf order | The running list comes first and largest, then lists by last touched. |
| G11 Two runs | The new run takes Now, and the old one waits in the ledger. The shelf shows both with RUNNING, the newer first. |
| G12 Pick from the shelf | Holding a shelf name that has Pick one on runs the pick over the shelf. On any other name, the hold does nothing. |
| G13 Endless skips | After the last skip, the column comes back and Tess says "That's all of them." |

## Acceptance rows

**9 · Shelf**
| # | Pass when |
|---|---|
| 9.1 | The back word "‹ KITCHEN" sits at the top, LISTS is in labels, and the context line reads "6 lists, packing running" |
| 9.2 | Names are sized by last touched (56, then two at 34, the rest at 21 at 75%), and the running list is first and largest; two running lists both read RUNNING, the newer first (G10, G11) |
| 9.3 | State words sit under the names in labels: "3 OF 7", "RUNNING, 9 LEFT" in vermilion with a lit seam, "REUSABLE", "PICK ONE", "EMPTY" for a list with nothing on it, and "14 TO BUY" under Groceries |
| 9.4 | On arrival, the names settle into their sizes with a stagger |
| 9.5 | Pasting a block anywhere gives a wet cobalt ghost list at the foot of the column with its state word "12 THINGS, 2 SECTIONS" at 55% and Tess's "12 things, 2 sections." with UNDO for 4 s (a new capture); the context line counts up ("7 lists, packing running"). It dries in 2 s or on tap, then moves to its place by last touched: to the top at 56 when nothing runs, or just under the running list at 34 when one does (G10) |
| 9.6 | Groceries appears once and opens Groceries. "Put away" sits at the foot at 21/400, 45%; the word is never "Archived" (Product) |
| 9.7 | The door: "Lists" at Title 34 on Home's Kitchen page under Groceries with "PACKING, 9 LEFT" in vermilion labels; it opens with a zoom from 0.94 to 1 over 420 ms (G1) |

**10 · A list page**
| # | Pass when |
|---|---|
| 10.1 | The hero sits at y 142 with the context line above it. Option words, once used, form one labels line under the hero |
| 10.2 | Rows are 48 pt at 21/400, with amounts at 600. Sections are margin words at 34 and items hang at x 64, with no checkboxes or separators |
| 10.3 | Tapping strikes and sinks exactly as in Groceries, and the fold counts up with Tick |
| 10.4 | Tapping the fold restores items. Holding it for 0.7 s clears done items. On a reusable list it reads "4 done. Hold to reset." (no dot), the strikes un-paint right to left, and the items rise back |
| 10.5 | Tapping the context line unfolds the option words in place (Sections · Reusable · Run it · Pick one · Put away). There is no sheet, and tapping outside folds them |
| 10.6 | Swiping on x from the hero, the context line or a section word pages between sibling lists, and the hero parallaxes; a rail of list names scrolls on x past four. A swipe that starts on a row is the row's (10.9), never a page |
| 10.7 | Running gives a lit seam, the context line "Packing, running", 64 pt rows, and sections that fold away as they finish (a removed last row finishes its section the same way). The run survives locking the phone. A task or workout that @links a list shows it as an ink word on Now 60 min before (G3) |
| 10.8 | The ghost row on the page adds to this list: "Rice, on Packing."; several, "Passport and adapter, on Packing." (Product's ruling, decisions.md); UNDO for 4 s (G6) |
| 10.9 | Remove (Design 65): a left swipe on a row, the row following the finger with REMOVE in `live` at 60 pt; let go past 96 pt commits, short of it springs back. Never a tap, a hold or a red row. Tess: "Ground beef, removed." (the row as written, first letter up) with UNDO for 10 s; UNDO: "Ground beef, back on Groceries." (on Packing, "…, back on Packing."). A removed row never counts in `checkedAt`, so USUALLY never learns from it. Reduce Motion: a crossfade. VoiceOver: the actions "Check off" and "Remove" |
| 10.10 | Remove by phrase: "remove rice from groceries", "take rice off groceries", "rice is off the list" remove the row with the same line and UNDO; on a list page the list name is optional and the line names that list. No match: "No rice on Groceries." Two matches: "2 rows match. Swipe the one to remove." and nothing is removed |
| 10.11 | "done" on a reusable list finishes the run with the strikes kept and asks: "Packing, done. Reset it for next time?" with RESET (a 0.7 s hold, the ink line filling) and NOT NOW; holding RESET drains the paint, "Packing, reset." with UNDO for 10 s; NOT NOW or 10 s of silence changes nothing. On a plain list "done" finishes the run, and a non-reusable list with nothing open is put away: "Packing, Lisbon put away." with UNDO for 10 s (G9). Clear done and reset carry a 10 s UNDO; the fold's hold stays 0.7 s |
| 10.12 | Back word "‹ LISTS" at the top; an empty list reads EMPTY on the shelf, its page's context line reads "nothing on it yet" over an empty window, and an empty shelf shows Groceries at 56 with "Paste a list anywhere to make one."; the put-away word is absent until something has been put away (lists-9-12.md c4b019f, which supersedes "Nothing here yet.") |

**11 · An item, opened**
| # | Pass when |
|---|---|
| 11.1 | The item zooms open from its row, and its text is the hero at 56, up to 3 lines; back word "‹ PACKING" (the list's name). No remove from here: the strike (11.5) is the hero's only swipe |
| 11.2 | The note can be edited in place. @links are ink with an underline (never cobalt, decisions 10:06) and open their object with one tap, at first sight. An empty note shows "Add a note" at 40% |
| 11.3 | The date word at 21/600; tapping it opens the day lane (one row of day words, snapping on x). "Add a day" shows when there is no date |
| 11.4 | LINKED FROM lists the backlinks at the bottom at 21/500 |
| 11.5 | Swiping right on the hero strikes the item, following the finger, then zooms back |

**12 · Pick one**
| # | Pass when |
|---|---|
| 12.1 | Holding the hero for 0.6 s fills its underline. This works only when Pick one is on, and also from the shelf, where the shelf dims to the same 14% and the picked item lifts out of the name (G12) |
| 12.2 | The others dim to 14% with a 2 pt blur. One name lifts out, grows to 56 at the centre and lands in 520 ms, with a small bloom and a medium haptic |
| 12.3 | Tapping opens the item. Swiping left sends it back and picks again after 200 ms. A skip writes no `pickedAt` |
| 12.4 | After the last skip comes "That's all of them." (G13) |
| 12.5 | With Reduce Motion on, it crossfades to the centre with no growth |

**Everywhere:** nothing under 16 pt, no cards, pills or sheets, nothing red, UNDO 4 s for a new capture and 10 s for a remove or a change, and motion only through `MotionPolicy`. Dynamic Type at AX sizes gives one column with no clipping on the shelf, the page and the pick. Each screen PR includes a recording under `docs/recordings/` that starts on the page.

## On the phone, after merge

Research's five moments, each used for a real week: leaving the house, gym bag, grocery and errands runs, film night pick, and packing for a trip. Any way in that takes more than 2 steps is a fail.
