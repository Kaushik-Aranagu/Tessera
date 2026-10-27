# Sheet 284: level 1 (door pages) and level 2 (item pages), every room (Oct 25)

Kaushik, 7:44 PM PDT: "design should start working level 1 and level 2 parts of the UI and how we want to
display various stuff, elegant, and how we want to design those screens and what we want to display and
organize them as."

Board: https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp (turn a room's dial, tap the focused door).
Builds on `landings-283.md` (places, v5 shell) and `shell-contract-283.md` (diff rules, merges).

## The frame (same for every room, every door, every item)

| Place | Level 0 (landing) | Level 1 (door page) | Level 2 (item page) |
|---|---|---|---|
| Title 24,50 | Room name | Room name, untouched | Room name, untouched |
| Nav word 300,50 | Bridge | "Doors" | The door's name |
| 24,106 354x70 | Switcher + Needs | **Door title**: door name 34 pt bold ink, one line 15 pt | **Item title**: item name, one line |
| Keystone 24,196 354x182 | Live | Live, untouched (same identity) | Live, untouched |
| Caption 24,378 | Keystone hint | The door's keystone hint | The door's keystone hint |
| 24,412 354x364 | Widget, Glyph, Dial, Summary | **Page**: the door's rows | **Facts** 24,412 354x64 + **Body** 24,484 354x292 |
| Foot | Action word, Tess | Action word (Add, Ask), Tess | The item's verbs, Tess |

- Across on the Door title goes to the next door; across on the Item title goes to the next item. Only the
  words change: the title flaps, rows leave softly and settle from the top (0.38 s, 45 ms apart).
- Same content on both sides is never animated (the Title, the Caption when equal, the keystone).
- Back runs the same moves the other way and restores the door and item you were on.

## The Page (level 1): rows fill the block exactly

- Rows split the 364 pt block by rank weights 1.7, 1.3, 1.08, 1, 0.94, 0.88, 0.84 (normalised), so the block is
  always full, the first row is always the biggest, and no two rows are equal.
- Title size = 0.36 x row height, clamped 17 to 34 pt; first row bold in the room colour mixed 58% with ink
  (so the three biggest words, Title, Door title, first row, never share a colour); others ink unless a state
  colour applies (done green, late or thirsty wine, best and new gold, planned or automatic slate).
- Value right-aligned in Outfit Light at 0.82 x the title size, unit at half size. Money always "about".
- Sub line 13 pt ink2 directly under the title, only when the row is taller than 40 pt.
- Tap a row: its item page. Swipe right Done, left Not now (gesture rules unchanged; not drawn yet).

## Facts and Body (level 2)

- Facts: three columns 1.2 : 1 : 1. Number Outfit Light 28 pt (first in the room colour), unit at half size,
  label 10.5 pt small caps tracked in slate. "about" sits small before money.
- Body by kind (one per item type, all in the same 354x292 block):
  - checks (lists): rows split the block evenly, a thin tick drawn in green when done, done words struck in ink2.
  - tess (from Tess): Newsreader italic 21/31 in Tess blue. Only Tess's own words use Newsreader.
  - text (notes): Figtree 18/28 ink.
  - hours (Lookout): time, word, temperature; the hour you opened in the room colour; one advice line.
  - sets (Deck): warm-up and sets, done in green, the next set in the room colour; last time underneath.
  - steps (Galley): numbered steps, the current one in ink and the number in the room colour; tap to move.
  - week (Watch): seven days, tended green, rested ink3, today in the room colour; never "missed" or "failed".
  - ledger (Purse): date, what, about amount. Never red or green.
  - siblings (any row without its own page yet): the door's rows with this one in the room colour.

## Every room

| Room | Doors (level 1) | Item pages drawn (level 2) |
|---|---|---|
| Log | All notes, Ideas, From Tess, Voice memos, Pinned, Mentions, Private (locked, a count only), Archive | Trip packing (checks), Run plan (tess), Garden (text) |
| Lookout | Hours, Tonight, This week, Air, Sky | 7 PM (hours) |
| Deck | Today, This week, Library, Bests, Plan | Bench (sets); private workouts stay "Private workout" |
| Galley | Tonight, Pantry, Recipes, Groceries, Leftovers | Tacos (steps) |
| Watch | Today, Body, Mind, Home, Weekly | Walk, Journal (week) |
| Purse | This month, Kinds, Saving, Investing, Debts, Mine | Food (ledger) |

Every other row opens the siblings body until its own page is drawn.

## Open for the next round

- Swipe right/left on rows (Done, Not now) and the 10 s undo line at level 1.
- Item pages for the remaining rows, and level 3 where an item has parts (a set, a step, a note's paragraph).
- How the keystone points at the item at level 2 (a highlighted word on the wall, the ticket pulled forward,
  the lift chalked on the board, the hour's sky, the tree, the index line).
