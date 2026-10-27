# Sheet 287: the transition catalog, reshaping by hand, and the quiet stage (Oct 26)

Kaushik, 12:48 PM PDT: "map out what all kinds of transitions it can... the input is so and so has changed, and the
control is that, and the data layer is basically what core would... and the UI UX element would then render it
based on the control it got from Tess or user... UI should also provide a way to do that testing internally for the
AI agents... without showing it to the user."

Board: https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp. "Deck: hold the Nav word to reshape" shows the gesture;
the other rows show the transitions named here. This sheet builds on sheets 283 (shell and diff rules), 285
(Tess's hand), 286 (looks and coming back into view), the element contract (#1434) and the look model (#1449,
`docs/ai/harness/element-looks.md`). Where it differs from sheet 286, this sheet wins.

## 1. The pipeline

Every visible change runs the same four steps, and only the last one draws.

| Step | Who owns it | What it carries |
|---|---|---|
| **Input** | Wherever the change starts | `Change`: the place, the change kind (section 2), the item ids, before and after |
| **Control** | The caller | `Control`: `.hand` (his gesture), `.tess` (her call, pending), `.system` (time, a fetch, a timer, a data job), or `.stage` (a rehearsal, never shown) |
| **Data** | Core | The op log write. `.hand` and `.tess` changes to his things get the ghost row and the 10 s Undo. Looks are settings. |
| **Render** | The place (Builders A and B) | `Transition = catalog[kind][control]`, played only if `isShown` (live-visibility.md); otherwise the place arrives changed (sheet 286, section 4) |

A place never picks its own transition from what it guesses happened. It receives `(Change, Control, isShown)` and
looks the move up in this catalog. So Tess, his hand and the system get the same move every time, which is what
makes a change readable.

## 2. The catalog: what changed, and the move it plays

These are the moves for `.hand`. Section 3 says how `.tess` and `.system` change them.

**A. Inside a place (the content changes; the place stays)**

| Change kind | The move | Per room where it differs |
|---|---|---|
| `value` (a number) | Digits roll (Outfit, 280 ms, each digit on its own) | Deck: the chalk number is rewritten. Purse: digits roll and "about" stays still. |
| `replace` (same kind, new item) | The place's own move from sheet 283: the masthead flaps, the widget goes out the top and in from below, the summary slides off right and in from the right, the action word streams | |
| `add` | The new item settles from the top (0.38 s); the others make room | Log: a word sets in the wall. Galley: a ticket hangs and swings. Deck: chalk writes. Watch: a tree is planted. |
| `done` | The Big line is struck (180 ms, then 600 ms), then the next item rises | Galley: the ticket tears off. Deck: the chalk line gets a stroke. Watch: the tree is watered, never "missed". |
| `remove` | The item lifts 8 pt and fades (220 ms); the rest close the gap (360 ms) | Deck: wiped with chalk dust. Log: the word lifts off the wall. |
| `reorder` | Items travel to their new places together (420 ms spring); nothing fades | |
| `kind` (a picture becomes words) | Collapse to a point and form again (a keystone dissolves with blur) | |

**B. The place itself changes (the content stays)**

| Change kind | The move |
|---|---|
| `form` (a reshape) | Things both forms show travel from where they were to where they go (520 ms spring), matched by item id. The rest fades out in 160 ms or in over 260 ms from 260 ms. Collapse and form only when the two forms share no item (rows to trace). The frame never moves. |
| `trait` | It eases in place over 320 ms. Density changes the spacing steps, size changes the type steps, facts lines fade in or out. |
| `motion` (calm or still) | The idle loop slows to rest over 600 ms and holds its last frame. It never stops mid-stroke. |
| `level` (landing, door, item) | Places merge and split (sheet 283). Content leaves before a merge and arrives after a split. |
| `empty` or `filled` | Only the half that exists plays. |

**C. The whole screen**

| Change kind | The move |
|---|---|
| `route` (room, door, item) | Place by place (sheet 283). Back is the edge pull. |
| `appLook` (paper or black) | A 400 ms crossfade; keystones retint from their own palettes. |
| `returnToView` | Show now, then only the differences, once (sheet 286, section 4). |

## 3. The control changes the move, never the kind of move

| Control | Tempo | Mark | Undo | Other rules |
|---|---|---|---|---|
| `.hand` | 1x, starting under his finger | None; the result is in the room's ink | "Rest today  Undo" | Always wins. |
| `.tess` | 1.15 to 1.2x | The flight and wash come first. Materials stay in her blue until they dry (sheet 285). | "Tess set today as a rest day  Undo" | A refusal moves nothing; her line says why. |
| `.system` | 1.3x, calm | None | None, unless it changed his things, which the system never does unasked | It never plays under his finger. It waits for the lift (at most 2 s), then plays. Changes on one place within 1 s play as one. While he is scrolling or reading a list, rows don't reorder until he stops. |
| `.stage` | No clock | None; nothing is shown | None | Section 5. |

Collisions: a new change on a place mid-move retargets from where things are now (sheet 283) and never queues. His
finger always beats Tess and the system.

## 4. Reshaping by hand: hold the Nav word

This settles the gesture for #1449. Their proposal was to hold the place itself. That doesn't work, because hold and
drag are already taken on most places:
- The widget's Big line: hold to strike.
- The action word: hold to start.
- The keystones: they own their drags (the Deck board takes chalk writing).
- Pinch is the fold for days, weeks and months (sheet 222).

The Nav word only takes a tap (back), so holding it is free on every screen.

1. **Hold the Nav word** for 450 ms. The screen loosens into **shape mode** over the live screen. Every place gets a
   raised-glass outline (no fill), staggered 30 ms. The Nav word becomes "Done". The action word steps aside and
   the foot turns into the shape line: "Shape" over "Tap a place to reshape it" (no full stops, sheet 289)
2. **Tap a place** to pick it. It lifts 1 pt. The foot shows its forms as words in room type, with the current one
   in the room colour, and under them its trait words ("denser", "more detail", "calmer").
3. **Swipe across inside the place**, or tap a form word, to flip its forms. Each form is drawn from his own data,
   with the glass lens under his finger (the only place the lens appears, as on every horizontal swipe). Tap a trait
   word to step it.
4. **Tap Done** to keep it. The Undo line reads "Doors as an index  Undo" for 10 s.

Settings > Layout mode opens the same mode on Bridge, so there is one surface. Tess takes the same changes in words
(#1449, section 4), and her version plays the sheet 285 wash first. The board shows this on the Deck's doors.

## 5. The quiet stage: Tess tests a change without showing it

The shell can draw any `Screen` without showing it. This is a **stage render**: no window, no clock, and only the
end frame (plus the 50% frame for moves that travel). It returns a `StageReport` for each place:

- **fits:** no clipped text, lines within their count, items within the frame.
- **floor:** no type below the room's floor (10 pt units, 13 pt lines).
- **contrast:** text against its ground at AA or better, in both looks.
- **rules:** at most 4 colours on the page; the three biggest words never share a colour; no colour within ΔE 10 of
  Ember; money never red or green and always "about".
- **touch:** every target at least 44 pt.
- **calm:** the move ends within 1 s, and a Reduce Motion version exists.

How it's used:
- Tess proposes a reshape or a new line, stages it, and only applies a change whose report passes. If it fails, she
  picks the next form from the place's list or tells him why.
- The test world scores these reports too (#1449, section 7).

Privacy: the stage draws real data on the phone and keeps the picture in memory only. The picture never reaches a
model, a log or a backup. Only the report's flags and numbers may go to Tess's rungs, and under strict they carry no
item names.

Later (not now): bigger changes, such as new forms or code, are built and tested on the Mac or an edge machine. Here
on the phone, only forms the studio already drew can be staged.

## 6. Forms per place, in #1449's words

This replaces sheet 286, section 2, and uses the forms in `ElementForms`.

| Place | Forms (designed first) | Traits | New for the forms table |
|---|---|---|---|
| Switcher | type, **roll** (the three-place roll word in the 26 pt sentence) | none | roll |
| Needs | type | count (1 or 2 lines), facts ("numbers only") | none |
| Widget | rise, stack (one and next), rows, ledger (Purse), trace (Lookout, Purse) | facts ("just names" is the Big line only, which hides the glyph), size | none |
| Glyph | the room's drawing, trace | shows (on or off) | none |
| Doors | reel, index, **sentence** | density (index: more than 5 doors become two columns of 4), count (sentence: at most 4 names, then "and N more") | sentence |
| Door summary | type, **sentence** | facts ("numbers only") | none |
| Page (level 1) | rows, **columns** (names only, two across), wall, ledger, stack | weight (ranked 1.7 to 0.84, or even), order (rank or time; by time adds a 52 pt time column), density | columns |
| Body (level 2) | the kind's own drawing (sheet 284), type ("plain") | none | none |
| Keystone | the room's material only | motion (designed, calm, still), plus chalk: shows, and tickets: count | none |
| Action word | type | shows (word only, or word and line) | none |

The new forms each need a row in `ElementForms`:
- `roll`: draws words, in the switcher.
- `sentence`: draws doors and words, in the dial and the door summary. Its trait is count. (Needs stays `type`.)
- `columns`: draws many, in the page only. (On the dial, two columns is the index form's density trait.)

### Many doors (sheet 292, drawn on the Log's eight)

- **Index, two columns:** two columns of four. Each column is right-aligned and as wide as its longest name, with a
  14 pt gap, and the pair sits on the frame's right edge (the right thumb, sheet 289). Names are 15 pt. If the pair is
  wider than the frame, the size steps down to 13 pt, then the gap narrows to 8 pt. The focus door is 600 weight.
- **Sentence, count trait:** a sentence never lists more than four doors. After the fourth, it reads "and 4 more" in
  ink2. Tapping "4 more" turns the place into the index form, with the usual travel (the four named doors move to
  their index places). There is no full stop at the end (sheet 289). If four names don't fit in 120 pt, the type steps
  down from 19 to 15 pt.
- Both pass the Bounds check (sheet 291) in paper and black. Before this, the eight-door index ran past the frame's
  left edge, and the eight-door sentence ran seven lines into the Undo line.

### Page forms (sheet 293, drawn on the Watch's Today)

- **Ranked** (designed): row weights 1.7 to 0.84. The first row is 700 in a darkened room colour.
- **Even:** every row is the same height and size. The first keeps its colour but not its weight, so nothing reads as
  ranked.
- **Columns:** names only, two across. Each column is 171 pt wide with a 12 pt gap, filled down the left column first
  (3 and 2 for five rows). Rows are 22 pt and at most 76 pt tall. Values and second lines are left out, because this
  form is for finding, not reading.
- **By time:** a 52 pt time column (Outfit), then the names, in time order. A bare clock time means the next time it
  comes after now, so at 5:10 pm, 6:00 is tonight and comes before 9:00. Rows with no time (done, thirsty) come first
  in ink2, with their word at 13 pt in their own colour, because they are already behind him. Offered only where rows
  have times (Watch, Galley, Lookout, Deck).
- **The switch:** a row's name travels from its place in one form to its place in the next (520 ms, matched by name).
  Times, values and second lines fade in at 260 ms. The Undo line reads "Page by time  Undo". Tess's version starts
  with the wash over the whole page: "Tess set the page by time  Undo".
- Every form passes Bounds (sheet 291) in paper and black. Nothing leaves the page frame and no two runs cross.

## 7. Interface changes

- **Change and control:**
  - `Change { place, kind, itemIDs, before, after }` and `Control { hand, tess, system, stage }`, handed to
    `PlaceHost` with `isShown`.
  - `TransitionCatalog.move(kind:control:place:room:)` returns the move. The table above is its data.
- **Changes from #1449:**
  - Reaction `.reshape` uses the travel move (matched by item id), not collapse to a point. Collapse is only for
    forms that share no item.
  - The gesture is the Nav word hold (section 4), not a hold on the place.
- **The stage:**
  - `ShellStage.render(screen:looks:) -> StageReport`, on the main actor, with no window.
  - `StageReport` is sendable and carries flags only. Tess's harness calls it before a pending reshape.
- **System changes:**
  - The shell holds `.system` changes while a touch is down on the place (2 s at most), and coalesces changes
    within 1 s.

## Sheet 312: only the word that changes moves (Oct 26)

Opening a door used to flap the whole masthead, the room's title with it, although only the Nav word changed
("Bridge" to "Doors", then "Doors" to the door's name). That broke the contract that a place whose identity stays
does not move.

- **Same title, no flap.** When the old and new screens share the title (a room, its doors page and a door page), the
  masthead stays exactly where it is. The title never moves.
- **The Nav word changes its letters,** as in sheet 309: shared letters (in order, same case) slide to their new
  places, the rest leave upward, and the new ones rise in after. "Bridge" to "Doors" keeps its r, "Doors" to
  "Today" keeps its o, and the same plays backwards on Back.
- **Different title, as before.** Between rooms (Deck to Galley) the masthead still flaps like the departure board.
- Reduce Motion: the word changes in place.
- Measured on the board (`t56.js`): Deck in paper and Watch in black, landing to doors to a door and back twice;
  one masthead throughout, the title never animates, and the Nav word always ends whole. `t39.js` finds no cut
  words and `t45.js` no stops.

For the builders: the masthead is one view across a room's levels, outside the level's own transition. Give the
Title `.id(room)` so it only transitions when the room changes, and let the Nav word use the letter morph from
sheet 309 keyed on its text.

## Sheet 315: the caption follows the door (Oct 26)

- On a room's doors page, swiping the door title across to the next door flipped the title and settled the rows,
  but the caption under the keystone swapped to the new door's in one frame.
- Now it eases: the old caption leaves upward by 4 pt (140 ms) and the new one rises into place (240 ms from 120 ms),
  the same move as shape mode's foot line (sheet 310). If only a number in it changed, only that number rolls
  (sheet 313).
- The first draw of the page does not animate; only a turn does.
- Reduce Motion: the caption changes in place.
- Measured on the board (`t59.js`): two turns on the Deck in paper and the Galley in black; the caption always ends
  whole; `t39.js` finds no cut words and `t45.js` no stops.

For the builders: the caption is `Text(door.caption).id(door.id)` with the same asymmetric offset-and-opacity
transition as the shape foot line, driven by the door index through `MotionPolicy`.

## Sheet 316: the action word follows the door (Oct 26)

- Found on the board: on a room's doors page, turning the door title to the next door left the action word saying
  "Add to Today" while the page showed This week, and the receipt named the wrong door. A real bug, not only a
  look.
- Now the action's object follows the page. The verb ("Add") stays still; the object changes letter by letter, as
  the Nav word does (sheet 309): "to " and any shared letters stay or slide, the rest leave upward and the new ones
  rise in. The receipt names the door now showing ("Add, to Library").
- The object line clips sideways only (sheet 298), so rising letters are never cut.
- Reduce Motion: the object changes in place.
- Measured on the board (`t60.js`): two turns on the Deck in paper and the Galley in black, then a tap; the object
  and the receipt always match the door; `t39.js` finds no cut words, `t45.js` no stops, `t51.js` Undo unchanged.

For the builders: the action's object is derived from the current door (`actions(for: door)`), never captured when
the page is built. Its `Text` uses the letter morph keyed on its string.

## Sheet 317: an item's facts change in place (Oct 27)

- On a door page, swiping the item title to the next item (Bench to Overhead press) redrew the three facts under
  it and settled them all in again, even the ones that stayed ("today", "of 4").
- Now the facts keep their frame. A fact whose number changed rolls only the number (95 lb to 110 lb, 2 of 4 to
  3 of 4, sheet 313); a fact whose words changed eases out and in (sheet 315); a fact that stayed does not move.
  When the item has a different set of facts, they settle in together as before.
- Found on the way, two real bugs:
  - The action word stayed on the first item: on Overhead press it still said "Log, set 1, 185 lb" from Bench.
    Now it follows the item. With the same verbs, only the object changes letter by letter (sheet 316); with
    different verbs, the old action word leaves left and the new one comes in from the right, as between rooms.
  - The rolling digits picked up the page's small uppercase label style. They now always inherit the line's own
    type.
- Reduce Motion: everything changes in place.
- Measured on the board (`t61.js`): three swipes on the Deck in paper and the Galley in black, then a tap; facts,
  action and receipt always match the item; `t57`, `t58`, `t60`, `t39` and `t45` still pass.

For the builders: an item page's facts are keyed by their label, so SwiftUI keeps the views that stay and runs
`numericText` on the values that change. The action row is derived from the current item, never captured when the
page is built.

## Sheet 318: units at half size on item facts (Oct 27)

- Found on the board: item pages wrote some units into the value ("110lb", "25min", "20min"), so the unit was the
  number's full 28 pt size, against the units rule (unit at about half the numeral, never under 10 pt). Units that
  were passed apart ("°", "%", "mph", "pm") were also set as their own block, which could drop them under the
  number.
- Now every fact value is split into number and unit: the number at 28 pt, the unit inline at 14 pt in the same
  colour, 2 pt after it. "about" stays small in front of money, as before.
- The number has its own place, so it still rolls alone when the next item changes it (sheet 317), with the unit
  held still.
- Checked in every room (Log, Lookout, Deck, Galley, Watch, Purse): Purse keeps "about 2,125" with no unit; Watch
  shows "6:00 pm" with the pm at half size.
- Measured on the board (`t61.js`, plus a fact probe in every room): `t39.js` finds no cut words and `t45.js` no
  stops.

For the builders: the fact view takes `value: Double?`, `unit: String?` and `prefix: String?` separately (never a
preformatted string), and draws the unit with `Theme.type.unit(for: numeralSize)`.
