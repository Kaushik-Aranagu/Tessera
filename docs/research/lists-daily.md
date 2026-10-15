# Lists in a real week: 20 moments, the gaps, what to test first

For: Builder B, Kitchen lead, Product
Date: 2026-10-15 · Research lab
Reads with: `../product/ship-list-lists.md` (slice ids 1 to 12 below), `../product/starter-lists.md`, `../product/lists-acceptance.md`, `lists-templates.md`, `fixtures/lists-fixtures.md` (phrase rows cited as F-row), `context-packing.md`. Code: origin/master `5258866`.

## What master has today

- `TesseraCore/Sources/TesseraCore/Lists/Lists.swift` is kitchen slice 1 only: `ListContents` (`lists`, `items`, `open`, `done`, `sections`) and `CreateList`, `AddListItem`, `CheckListItem`, `MoveListItem`, `RenameListSection`, `ClearDoneItems`. None of Lists slices 1 to 8 exist yet (no reusable flag, no `StartListRun`, no `pick(from:)`, no item note or date, no paste).
- `StartShop` (`Kitchen/Shopping.swift`) is the only list run. `Features/Groceries/GroceriesView.swift` is the only list screen.
- Home reaches Groceries through `HomeLink` (`Features/Home/HomeSpatialView.swift:163`), which has no `.lists` case. There is no door to a Lists shelf yet.

## How to read the table

- **Trigger**: when and where it happens. **One screen**: the context line, then what he sees, at most 7 names. **Way in**: at most 2 steps. "Soul" means one tap on the soul to open Tess and say or write the phrase (the single tap that `screen-fast-paths.md` proposes).
- **Slices**: Lists slice ids from the ship list; K = kitchen slice; GAP = a G-number in the next section.
- Every screen follows the house rules: names as type on paper, tap strikes and sinks, no cards, no checkboxes, no key shapes.

## 20 moments in one week

| # | Moment | Trigger | One screen: line · items | Way in (max 2) | Slices |
|---|---|---|---|---|---|
| 1 | Leaving the house | Weekdays 08:10, at the front door, shoes on | "Leaving the house, 6 left" · keys, wallet, phone, headphones, lights off, windows shut | Soul, "run leaving the house" | 4, 5, 8, 10; G1, G2 |
| 2 | Gym bag before a lift | Mon, Wed, Fri ~17:30, Push, Pull or Legs on Today at 18:30 | "Gym bag, running" · CLOTHES shorts, t-shirt, socks, trainers · KIT belt, chalk, headphones, bottle | Tap the gym bag line on Today, or soul "run gym bag" | 4, 5, 10; G3 |
| 3 | After the gym, unpack | Same days ~20:00, home, bag on the floor | "Gym bag, 2 left" · AFTER towel, shower gel (the rest already struck) | Tap Now's line "Gym bag, 2 left" | 5; finish resets (4) |
| 4 | Something runs out | Any time: chalk is low mid-set, shower gel empty | No list screen. Tess's cobalt line: "Chalk is on Gym bag." | Soul, "gym bag: chalk" (F-row 44 shape) | 8; G6 |
| 5 | Grocery run | Tue ~18:30, in the supermarket | "Shopping, 9 left" · items in aisle order, aisle words in the margin | Soul, "shop"; or Home Kitchen, Groceries | K8, K13; shelf shows it once (9) |
| 6 | Errands run, not food | Sat ~11:00, high street: pharmacy, hardware, post | "Errands, 4 left" · plasters, 4 mm screws, return parcel, stamps | Soul, "run errands" | 5, 8; G7 |
| 7 | Weekly reset | Sun ~18:00, at home | "Sunday reset, 7 left" · laundry, bins out, change sheets, charge watch, plan the week, empty bag, water plants | Soul, "run sunday reset" | 4, 5; G1, G8 |
| 8 | Cleaning round | Sat ~10:00, one room at a time | "Clean, 8 left" · KITCHEN hob, sink, floor · BATHROOM mirror, loo, shower | Shelf, tap "Clean" (or soul "run clean") | 4, 5, 10; G8 |
| 9 | Meal prep | Sun ~15:00, kitchen | "Meal prep, running" · rice on, @Chilli con carne, roast veg, portion 5 boxes, label lids | Soul, "run meal prep" | 2, 5, 11; K10 cook timers |
| 10 | What to cook tonight | Wed ~18:45, tired, fridge open | One name at hero size: "Weeknight dal" (an item that links the recipe) | Shelf, hold "Dinners" | 7, 12; 2 for the link |
| 11 | Film night | Fri ~21:00, sofa | One name at hero size: "Past Lives" | Soul, "pick a film" (F-row 20) | 7, 12 |
| 12 | What to read next | Any night ~22:15, finished a book | One title at hero size: "Piranesi" | Soul, "pick from books" | 7, 12; G5 |
| 13 | Plan a trip's packing | Thu ~21:00, one week before Lisbon | "Packing, Lisbon" (new) · CLOTHES 5 socks, 3 t-shirts · TECH charger, adaptor · passport | Soul, "copy packing for lisbon" | 4, 8, 10; G4, G9 |
| 14 | Pack the night before | The night before the flight, bedroom | "Packing, Lisbon, 14 left" · the same, struck as he packs | Soul, "run packing, lisbon" | 5, 10 |
| 15 | Repack to come home | Last morning, hotel room | "Packing, Lisbon, 14 left" again (all unchecked) | Soul, "reset packing, lisbon" (F-row 17: on a list that is not reusable this is uncheck all) | 1, 8, 10; G9 |
| 16 | Someone sends a list | Any time: a friend texts a camping kit list | Change preview: "Twelve things, two sections" over the parsed names | Copy in Messages, hold the shelf, paste | 3, 9 |
| 17 | A gift idea in passing | Walk or a call, someone mentions a thing | Tess's line: "Mug for Anu is on Gifts." Later the item opened: note "the blue one, @Anu" | Soul, "gifts: mug for anu" | 2, 8, 11 |
| 18 | A dated list item | Mon morning: "return parcel by Thursday" | Today shows "Return parcel" Thursday; tapping it opens the item on Errands | Soul, "errands: return parcel thu" (F-row 60) | 2, 6, 11 |
| 19 | Exercises to try | Wed evening, after watching a lifting video | "Try, 3 open" · @Bulgarian split squat, @Pendlay row, @Cable fly | Soul, "try: bulgarian split squat" | 2, 8, 11; G6 |
| 20 | Five spare minutes | Any day, waiting for the kettle or a call | One name at hero size: "Reply to landlord" from Small jobs | Shelf, hold "Small jobs" | 7, 12 |

Coverage: 18 of 20 moments run on slices 1 to 12 plus kitchen. The weak spots are getting there at the right moment (G1 to G3) and the edges with Reading and Upkeep (G5, G8).

## What the moments ask of each screen

**Screen 9, the shelf.** Reached in moments 8, 10, 16 and 20, always to start something, never to browse. So the biggest name is what he is about to do: the running list (G10), then the last touched. The state word under each name carries the moment: "RUNNING", "5 LEFT", "REUSABLE", "PICK ONE". Paste anywhere on the page (16) is the only way to make a list from here besides the ghost row.

**Screen 10, a list page.** 14 of 20 moments end here, most of them running. The page must work one-handed, at a door or in a shop aisle: items at 21pt in the lower two thirds where the thumb is, the context line at the top only for reading. A run must survive the phone locking and coming back (moments 1, 5, 14). Sections are margin words, and in moments 2 and 8 the section is how he moves through the list, so the next open section scrolls up as the last one empties.

**Screen 11, an item opened.** Moments 9, 17, 18 and 19 open an item to follow a link (a recipe, a person, an exercise) or to see a date. The link is the reason to open it, so the cobalt @link must be tappable at first sight, not after scrolling the note. Tapping one zooms into that object; dragging down comes back.

**Screen 12, pick one.** Moments 10, 11, 12 and 20 are all evenings or idle minutes when choosing feels heavy. One name, no reasons, no list behind it. A skip is a swipe and costs nothing (slice 7); what happens after many skips is G13.

## Gaps to decide before Builder B builds screens 9 to 12

| G | Gap | Why it matters for the screens | Recommended default |
|---|---|---|---|
| G1 | **Where is the door to Lists?** `HomeLink` has no Lists case | Screen 9 needs a way in that is not a phrase | Add `.lists` to `HomeLink` and the word "Lists" on Home's Kitchen page under Groceries. "lists" in the ghost row also opens it (F-row 32). |
| G2 | **Where does starting a run land?** Slice 5 says Now, the moments want the list | Screen 10 needs the running state to be its first state | Starting a run from the ghost row or the context line opens the list page with the vermilion seam; Now's line "X, N left" opens the same page in one tap. |
| G3 | **No list offers itself at the right time.** Context packing has no list candidate; ADHD means he won't remember to open it | Decides whether screen 10 has a "planned" state | No new scoring in v1. A task or workout that @links a list (for example the gym bag from Push Day A) shows "Gym bag" as an ink word on Now 60 min before; tapping runs it. Revisit after a week on the phone. |
| G4 | **Packing is not a starter list,** but the fixtures and moments 13 to 15 assume it | Screen 9's day-one shelf and the Copy test | Add Packing as a third reusable starter (CLOTHES, TECH, PAPERS, sections only from the paste rules). |
| G5 | **Books list vs Reading's queue** (M5 Reading owns a queued state) | Screen 9 must not show two homes for books | Until Reading ships, Books is a plain list. When Reading lands, its shelf owns books; a "Books" list stays as he made it, no auto-move. |
| G6 | **What a bare phrase does on a list page** (F-rows 38, 39, 42 are ASSUMED) | Screen 10's ghost row is the main way to add | On a list page, a bare item or comma list goes to that list; "done" finishes the running list. Elsewhere, the F-row rules hold. |
| G7 | **"buy" always means Groceries** (F-row 48), so errands get misfiled | Screen 10 copy and Tess's line | Keep it. Tess's line names the list ("Plasters are on Groceries.") so he can say "move to errands" later; no guessing. |
| G8 | **Cleaning round vs Upkeep chores** (chores have ages, lists have checks) | Whether screen 10 shows "last done" | A cleaning round is a reusable list with no ages. No link to chores in v1. Upkeep may link items to chores later. |
| G9 | **What happens to a copied trip list after the trip** | The shelf fills with dead "Packing, X" lists | Finishing a run of a non-reusable list with nothing open archives it, undoable, Tess says "Packing, Lisbon put away." Uncheck all (slice 1) still works before that. |
| G10 | **Shelf order when a list is running** | Screen 9's biggest name | Running list first and largest, then last touched (slice 1). No time-of-day ranking in v1. |
| G11 | **Two runs at once** (leaving the house while packing runs) | Screen 10's seam and the ledger | As slice 5: the new run takes Now, the old one suspends into the ledger with "Packing, 4 left". No stacked runs. |
| G12 | **Where Pick one lives when the list is closed** (moments 10, 20 start on the shelf) | Screen 12 is specced only from the list hero | Holding a name on the shelf of a list with Pick one on runs the same moment over the shelf. Otherwise it does nothing. |
| G13 | **Endless skips** (moments 11, 12 at night) | Screen 12 has no end state | After the last open item is skipped, the column comes back and Tess says "That's all of them." No count, no nudge. |

## Test these 5 on the phone first

1. **Leaving the house (1).** Daily, short and timed. It proves the run, the strike and sink, the reset on finish and the 2-step way in. Fail if it takes longer than walking out without it.
2. **Gym bag before a lift (2, with 3).** Ties Lists to Training and tests G3: does the line show up on Now before 18:30 without him asking?
3. **Grocery and errands run (5, 6).** The same run, with and without aisles; checks G7 and that Groceries appears once on the shelf.
4. **Film night pick (11).** The only moment that is about choosing, not doing; tests screen 12's hold, bloom, skip and the 7-day rule.
5. **Pack for a trip (13 to 15).** Copy, run, uncheck all and archive (G9) over 3 days; the longest life a list has.

Use each for one real week on the phone (not demo data) and count any way in over 2 steps as a fail.
