# Sheet 290: small delights in every transition (Oct 26)

Kaushik, 2:14 PM PDT: "there are so many transitions... make that very smooth and you know, fun... every element...
top quality, elegance, creativity, a little bit of fun or wit... cleverness... but not in your face type of stuff. So
very subtle... small things you notice."

Board: https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp. The details marked **on the board** are built there; the
others are specified here for the builders. This sheet adds one detail to the moves in the catalog
(`transitions-287.md`, section 2). It never changes the move itself, its timing budget or its end frame.

## 1. The rule for a delight

- **Noticed on the second look.** It is never what the move is about. If he sees it the first time, it's too big.
- **It comes from the material.** Chalk leaves dust, paper sways, a pen lifts, a dial clicks. Never confetti, sparkles,
  bounces for their own sake or a mascot reaction.
- **It never costs time.** It runs inside the move's own budget, or after the move has landed while he can already
  act. It never blocks a touch and never delays the next screen.
- **Every move ends on its still frame** (the Lands check, sheet 288). A delight is a path, never a state.
- **Reduce Motion drops it** entirely. Nothing replaces it.
- **Never on money.** The Purse stays restrained: no wit in its copy, no play in its moves.
- **Once.** A delight plays once per change, never as an idle loop, and never twice in a row on the same element.
- **Template entry.** It is an optional `delight` entry on the element (sheet 288, section 3). The base default is
  none. The Timing and Lands checks cover it, so it can't break anything.

## 2. The details, move by move

Haptics use the iOS feedback names. One haptic per move at most, and none while the system plays a `.system` change.

| Move (sheet 287) | The detail | Haptic | Where |
|---|---|---|---|
| Dial turns (doors) | **A detent.** The new focus word settles 3 pt past its slot and back in 280 ms, like a real dial clicking into place. | selection, per step | on the board |
| Strike (`done` on the Big line) | **The pen lifts.** At the end of the strike a 4 pt flick angles up and to the right, as a pen leaves the paper. | rigid, light, at the end | on the board |
| Tess's change lands (sheet 285) | **Tess blinks once** as her wash spreads, the way you blink after doing something. | soft, at the wash | on the board |
| Undo line (10 s) | **The Undo word dries.** It holds full ink for 6 s, then fades to 45% by the end, so the time left is felt without a timer. | none | on the board |
| Galley: a ticket hangs (`add`) | **The rail sways.** The neighbour tickets nudge 1.6° divided by their distance, then settle; the rail dips 0.6 pt. | soft | on the board |
| Deck: a chalk line is wiped (`remove`, Undo) | **A chalk ghost.** The wiped line stays at 10% for a moment and fades over 2.6 s, like a real blackboard. | none | on the board |
| Doors change form (`form`) | **A ripple.** New words arrive in order of their distance from the right thumb's corner (up to 90 ms later). | soft, at the end | on the board |
| Galley dishes done (`empty`) | **"the sink is clear"** instead of "none waiting". | success | on the board |
| Departure board (Bridge) | **The last flap settles.** When the board stops, the final flap drops 1 pt and back, as a real split-flap does. | none | builders |
| Digits roll (`value`) | **Odometer lag.** Each digit to the left starts 18 ms after the one on its right, so a 9 to 10 carries visibly. | none | builders |
| Rest day on the Deck | **The plates come back.** The glyph's plates are set down for a rest day; next morning they are back on the bar, with no motion. He only notices that they are back. | none | builders |
| Watch: a routine done | **The water drop slides.** The drop on the watered tree runs down one leaf and is gone (420 ms). | soft | builders |
| Log: a word sets in the wall (`add`) | **The wall makes room.** The neighbouring words shuffle 1 pt aside and back as the new word presses in. | none | builders |
| Log: a list item checked | **The tick is drawn**, not shown: one stroke, 160 ms, slightly heavier at its start. | rigid, light | builders |
| Lookout: rain starts | **The first drops are few.** Rain starts at a third of its strength and reaches it over 3 s. | none | builders |
| Edge pull (back) | **The page resists at the end.** The last 8 pt of the pull is 30% stiffer, so letting go feels decided. | soft, at the commit | builders |
| Shape mode (sheet 287) | **The places loosen.** Each outline breathes once, 1.006 in scale, as the screen goes into shape mode. | soft | builders |
| Paper to black (`appLook`) | **Ink goes last.** The ground changes first and the type follows 60 ms later, as if the ink were catching up. | none | builders |

## 3. Copy for empty and quiet states

Quiet wit only where nothing is owed. Never on money, health or anything he might feel judged by.

| Where | Line |
|---|---|
| Galley, no dishes | the sink is clear |
| Galley, nothing to buy | the pantry has it all |
| Log, no notes today | a blank page, for now |
| Watch, every routine done | the woods are watered |
| Deck, rest day | Rest today, Push A tomorrow (already on the board; never "missed") |
| Lookout, a still day | not a leaf moving |
| Bridge, nothing next | nothing is waiting on you |
| Purse, nothing new | Nothing new since Friday (plain on purpose) |

No full stops at the end of any of these (sheet 289).

## 4. For the builders

- Add `delight: Delight?` to the element template (sheet 288) and `MotionPolicy.delight(_:)`, which returns nil under
  Reduce Motion. Each detail above is one case.
- The haptics go through one `TesseraHaptics.play(_:for:)` so the "one per move, none for `.system`" rule lives in one
  place.
- The copy lines go in the room's string table with the other empty states, not in the views.
