# The list remove gesture (Design item 65)

**Kaushik's principle, in one line:** one plain line per thing, and taking a thing away is one gesture with one line from Tess and a way back.

Product NE11 (lists get a remove: "remove rice from groceries" or a swipe on the row, with a 10 s UNDO, "Rice, removed.") and AQ15 (a removal gets 10 s). This sheet draws the gesture on Groceries (`groceries-tess.md`, 47) and it is the same on every list (`kitchen/lists-9-12.md`: Packing, any list), at the shop too. The strike (a tap: checked, into the fold) is untouched; **remove is never a tap, never a hold, never a red row.**

- Board: `mockups/list-remove.png` (source `studies/list-remove.html`), Porcelain: the swipe with REMOVE risen, the row gone with Tess's line and UNDO, the phrase, the phrase that names nothing, UNDO bringing the row back wet.
- Recording: `recordings/list-remove.mp4` (8 s): swipe ground beef left, REMOVE rises at 60 pt, let go past 96, the row leaves and the aisle word with it, the rest close up, the count rolls to 8, "Ground beef, removed." with UNDO; tap UNDO, the row slides back wet and dries, the count rolls back, "Ground beef, back on Groceries."

## The swipe
| Moment | What happens |
|---|---|
| The finger moves left | The row (its amount, name and "for" line together) slides with it, 1:1. Nothing else moves |
| 60 pt | **REMOVE** rises at the right edge in `live` (Label 16/700, on the row's baseline), fading in over the next 30 pt; `.selection` once. The word is the only colour, and it is the gesture's, not the row's: the row stays ink |
| Let go before 96 pt | The row springs back (`.settle`), REMOVE fades |
| Let go past 96 pt | **It commits.** The row slides out to the left and fades (260 ms, house curve); an aisle word left with no row goes with it; the rows under close up (320 ms); the count line under the title rolls ("9 to get" → "8 to get"); Tess: "**Ground beef, removed.**" with **UNDO** under her line for 10 s |
| UNDO | The rows make room (320 ms), the row slides back into its place on the settle spring, wet in cobalt, and dries over 2 s; the aisle word returns; the count rolls back; Tess: "Ground beef, back on Groceries." (the undo rule: the thing, then what happened) |

The receipt names the row as written, first letter up: "Ground beef, removed.", "Oat milk, removed.", "Black beans, removed." The "for tacos" link goes with the row and comes back with UNDO; the recipe is untouched.

## The phrase
"remove rice from groceries", "take rice off groceries", "rice is off the list" (Core's grammar; the list name optional when he is on a list page) does the same with the same line: "Rice, removed." with UNDO 10 s. A name not on the list: "**No rice on Groceries.**" and nothing is written. Two matches ("milk" with oat milk and whole milk on the list): "2 rows match. Swipe the one to remove." (49's shape). Never a yes/no question.

## Never
A delete word on the row, a hold, a red row or red strike, a trash can, a confirm, a count of removed things, removing by tap (the tap is the strike), a notification. Removing is not checking off: a removed row never counts in `checkedAt`, so USUALLY never learns from it.

## Reduce Motion and VoiceOver
Reduce Motion: the row crossfades out and the rest reflow in place; UNDO crossfades it back. VoiceOver: each row carries the actions "Check off" and "Remove"; "Remove" says Tess's line as its announcement.

## For Builder B and Core
- Builder B: the swipe on `GroceryRow` and `ListRow` (one gesture, shared), REMOVE in `live`, the leave, the close-up and the aisle word's exit, UNDO's return wet; the count line rolls.
- Core: `RemoveListItem` as one undoable op (row, link, aisle), the phrase grammar, "No rice on Groceries." and the two-match line.
- Every clip ends inside the app.

## Addendum, Oct 16: Product 5a2fca77
The UNDO line names the list: "Ground beef, back on Groceries." (on Packing, "…, back on Packing."), matching "No rice on Groceries."
