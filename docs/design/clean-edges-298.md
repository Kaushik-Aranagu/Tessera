# Sheet 298: every edge is clean (Oct 26)

Kaushik, 4:34 PM PDT, after sheet 297: "yep, looks better now. we should take care of all such places. we can use
different sorts of animations but should all be clean and neat."

Board: https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp. This sheet extends sheet 294 (things roll over edges) from
the places we knew to every place, found by a check rather than by eye.

## 1. How every place was found

A new check (board test `t39.js`) plays every route between the landings and their door pages, the switcher, the
dial and the widget swipe on all seven landings, and every Tess and "you" demo. Every 25 ms it looks for text that a
clipping box slices: partly inside, partly out, not faded by a soft edge, not ending in an ellipsis. It runs in paper
and black.

Before this sheet it found four kinds of cut. After it, it finds none.

## 2. One exit per kind of place

He said different moves are fine as long as each is clean. So each kind of place gets the exit that suits what it is.

| Place | What was cut | The clean exit now |
|---|---|---|
| Widget card (one thing) | Covered by sheet 294 and 297: it rolls over the edge | Roll: soft 28 pt fade on the card, tilt, shrink |
| List rows (routine list, page rows) | Covered by sheet 297 | Roll, lighter: 18 pt fade, 10° lean |
| Widget lines arriving | Each line's own box cut the words as they rose in, mostly the second and third lines | **Lines never clip up or down.** They still clip sideways, but a word rising in is never sliced by its own line box; it arrives on its own fade and blur |
| Widget on a new page | The lines flashed fully drawn for a quarter second, vanished, then rose in | **Held back until they arrive.** The lines wait unseen until the arrival starts, so they are drawn once |
| Switcher word (every landing) | Letters leaving were sliced by the left edge of the word's box; letters arriving were sliced at its right edge | **The word owns the margin.** The switcher now reaches the screen edge, and the 24 pt margin is a soft fade, so letters leave into it and are gone by the screen edge. Its right edge fades only while it moves, never at rest |
| Galley tickets | A long word ("TOMORROW,") ran past the paper's margin | **Words fit the paper.** A line that is too wide loses its letter-spacing first, then steps down in size, to 9 pt at the least |
| A ticket being hung | Its words were squeezed and cut while the ticket opened from nothing | **The rail makes room first.** The other tickets slide apart with the new one held back; it drops in only at its full width, then the rail sways |

## 3. The rule, added to sheet 294

- **No box ever cuts a word, at rest or mid-move.** A word leaves a place by one of four exits: it rolls over the edge,
  fades through a soft margin, fits itself to the space, or waits until there is room.
- **Pick the exit from the material.** Cards roll. Rows lean. Type in a margin fades. Paper fits its words. A thing
  that is opening waits until it is open.
- **A clip on one axis only.** A line that clips sideways never clips up or down, so motion along the other axis is
  free.
- **Nothing is drawn twice.** Content that will arrive is held back until it arrives.
- **Still no blur strips or boxes** over any edge (sheet 294, v1 lesson).
- Reduce Motion: no rolls and no waits; content appears in place, already fitted.

## 4. For the builders

- `.edgeRoll(axis:depth:lean:shrink:)` from sheet 297 covers cards and rows.
- Text lines: clip with `.clipped()` only where a line can overflow sideways, and use
  `.mask { HStack-gradient }` rather than `.clipShape` when it moves. Never clip a `Text` vertically while its
  transition moves it vertically.
- Switcher: the view spans the leading margin; apply a leading gradient mask 24 pt wide. Add the trailing fade only
  while a drag or a change is live (`@State isMoving`), through `MotionPolicy`.
- Ticket text: `ViewThatFits` or `.minimumScaleFactor(0.7)` with `.tracking` reduced first; never `.truncationMode`.
- Hanging a ticket: animate the neighbours' widths first, then insert the ticket with its drop transition after the
  layout settles (`withTesseraAnimation(.layout) { … } completion: { … }`).
- Widget arrival: build the incoming lines with `.opacity(0)` and let the arrival transition reveal them; never show
  then hide.
- Keep the check: the app's UI tests should sample frames during each move and fail on any text sliced by a clip.

## 5. Sheet 319: door summaries never stack (his 1:55 AM PDT Oct 27 screenshot)

- On the Deck, turning the dial quickly left an old door summary on screen and stacked each new one below it, down
  over the action word ("Squat 275" across "Start"). Cause: on a fast turn, the summary already leaving was taken
  as the one to replace, so the summary showing never left.
- Now the one showing is always the one that leaves; anything still leaving keeps leaving; a summary is never left
  in the layout. A new board check (`t62.js`) turns the dial at several speeds in five rooms and fails if any word of
  a summary touches the action word. It finds none (the Purse's rolling digits are hidden by their own column and
  are not counted).
- For the builders: the door summary is one view keyed by the door (`.id(door)`) with a transition, never a stack of
  views appended on each change.

## 6. Sheet 320: the door summary is a ledger (his 2:02 AM note)

- He circled the Purse door summary and the dial: "keep these sections like this, so we have more space to display
  details about that door ... made better for all the rooms".
- The summary place grows to the whole space beside the dial: 192 by 116 pt from y 644, still ending above the
  action word (t62 keeps checking that).
- Its label (13 pt, ink2) says what the door holds: "Push A, 4 lifts", "Tacos for 2", "Next three hours".
- Each line is a ledger row: the name on the left in the room's text face (16/26), the number on the right edge in the
  number face (Outfit 18, tabular) with its unit at 0.55 em in ink2. "about" before money sits at 0.6 em in ink2, so the
  amounts line up on the right in every row. Lines without a number stay plain sentences.
- A quiet last line (12/16, slate) says what opening the door adds: "Then triceps, about 45 min in all",
  "Milk and eggs low", "Ahead of schedule".
- New content in every room: Lookout hours, tonight, week, air, sky; Deck today, week, library, bests, plan; Galley
  tonight, pantry, recipes, groceries, leftovers; Watch today; Purse month, kinds, saving, debts.
- For the builders: `DoorSummary(label:rows:more:)` with `Row(name:value:unit:)`; value column `.monospacedDigit()`,
  trailing aligned; the row view never truncates a word (shrink the name to 0.9 first, then drop the row).
