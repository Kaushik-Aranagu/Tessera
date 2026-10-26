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
