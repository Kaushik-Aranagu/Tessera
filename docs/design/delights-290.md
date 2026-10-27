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
| Departure board (Bridge) | **The last flap settles.** When the board stops, the final flap drops 1 pt and back, as a real split-flap does. | none | on the board (291) |
| Digits roll (`value`) | **Odometer lag.** Each digit to the left starts 18 ms after the one on its right, so a 9 to 10 carries visibly. | none | on the board (291) |
| Rest day on the Deck | **The plates come back.** The glyph's plates are set down for a rest day; next morning they are back on the bar, with no motion. He only notices that they are back. | none | builders |
| Watch: a routine done | **The water drop slides.** The drop on the watered tree runs down one leaf and is gone (420 ms). | soft | builders |
| Log: a word sets in the wall (`add`) | **The wall makes room.** The neighbouring words shuffle 1 pt aside and back as the new word presses in. | none | on the board (303) |
| Log: a list item checked | **The tick is drawn**, not shown: one stroke, 160 ms, slightly heavier at its start. The line through the words follows once the pen lifts; unchecking lets the ink fade back to the faint mark. | rigid, light | on the board (300) |
| Lookout: rain starts | **The first drops are few.** Rain starts at a third of its strength and reaches it over 3 s. | none | on the board (304) |
| Edge pull (back) | **The page resists at the end.** The last 8 pt of the pull is 30% stiffer, so letting go feels decided. | soft, at the commit | on the board (302) |
| Shape mode (sheet 287) | **The places loosen.** Each outline breathes once, 1.006 in scale, as the screen goes into shape mode. | soft | on the board (291) |
| Paper to black (`appLook`) | **Ink goes last.** The ground changes first and the type follows 60 ms later, as if the ink were catching up. The old ink keeps its own colours while it leaves, and the page never replays its arrivals for a look change. | none | on the board (299) |

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

## 5. Ink goes last, as built (sheet 299)

- The old page stays on top with its old colours pinned. Its ground fades away over 200 ms, showing the new ground
  under it.
- 60 ms in, the old ink fades out over 220 ms while the new ink fades in over 260 ms. The swap is over by 320 ms.
- Nothing arrives again: the widget's words, the torn ticket and every other arrival are skipped, because the page
  hasn't changed, only its look.
- The old page takes no touches while it leaves. Reduce Motion: an instant swap.
- For the builders: `appLook` changes go through `withTesseraAnimation(.look)`. Pin the outgoing palette in a
  snapshot layer (`.drawingGroup()` of the old palette), cross-fade the ground first, then the foreground with a 60 ms
  delay. Arrival transitions check `MotionPolicy.isLookChange` and stay still.

## 6. The drawn tick, as built (sheet 300)

- Where: any checkable list (Log lists are checkable notes), on the board in Trip packing.
- Checking: the tick's stroke draws from its short arm to its long arm in 160 ms, easing out, so it lands quickly
  and slows into the end. A short 1.7 pt segment at the start is drawn 0.7 pt heavier and stays, where the pen
  pressed. At 170 ms the words take their line through.
- Unchecking: the tick fades back to the faint mark (18%) in 160 ms. It never draws backwards.
- Reduce Motion: the tick and the line appear at once.
- For the builders: a `Path` with `.trim(from: 0, to: progress)` animated by `withTesseraAnimation(.tick)`, plus a
  short heavier `Path` for the start. The strikethrough waits for the trim's completion.

## 7. The pull resists, as built (sheet 302)

- The back pull lets go at 80 pt. From 72 to 80 pt the page answers at 70%, so the loosening and the nav word's
  growth slow just before the commit. Past 80 it follows the finger again, 2.4 pt behind.
- Letting go short of 80 settles back as before; the resistance never moves the commit point.
- Measured on the board (`t46.js`): the nav word grows 0.006 per 4 pt before 72, 0.004 per 4 pt from 72 to 80, and
  0.006 again past 80.
- For the builders: map the drag translation through the same curve before it drives the pull effect, and play the
  soft haptic once as it crosses 80. Reduce Motion: no pull effect at all, so there is nothing to resist.

## 8. The wall makes room, as built (sheet 303)

- On the board: the demo "Log: a new note joins the wall" adds Plant care.
- The new word joins the wall's last row, and only that row changes. Its words step aside and shrink together just
  enough for the new word to fit (the wall's own row fit, 3 pt gaps), over 650 ms. Every other word stays exactly
  where it was, so the wall never reshuffles under him.
- Once there is space (380 ms in), the new word presses in: from 112% and clear, to 98.5%, to rest, in 480 ms. Its
  nearest neighbour gives 1 pt and comes back as it lands.
- Undo: the word lifts out (fades to 92% size in 220 ms) and the row returns to where it was.
- Found and fixed on the way: the wall's letter scramble moment could make a word wider than itself, so it
  touched its neighbour. A scrambling word now keeps its own width.
- Checked (`t47.js`): no two words overlap and none leaves the wall, after the add and after Undo, in paper and
  black.
- For the builders: the wall view keeps its packed rows; `add` refits only the last row with
  `withTesseraAnimation(.layout)`, then inserts the word with a scale-and-fade transition after a 380 ms delay.
  A full repack happens only on the next visit, never under his eyes.

## 9. The first drops are few, as built (sheet 304)

- When the Lookout sky starts to rain (on the board, open a rain hour such as 8 PM), the streaks start at a third of
  their count and reach full over 3 s on a smoothstep, so the shower thickens instead of switching on. The beads on
  the glass gather at the same pace.
- Measured on the board (`t48.js`): about half the streak pixels at 0.2 s, full from about 1.5 s on, in paper and
  black.
- Reduce Motion: full strength at once.
- For the builders: the rain emitter's birth rate is multiplied by the same ramp from the moment the condition turns
  to rain, never on every view of a sky that is already raining.

## 10. Chalk dust, a new detail (sheet 305)

| Move (sheet 287) | The detail | Haptic | Where |
|---|---|---|---|
| Deck: a chalk line is written (`add`) | **The chalk sheds a little dust.** As the line writes, a few specks fall from the writing tip, drift down a few points and fade in 0.9 s. A dozen at most, never on a wipe. | none | on the board (305) |

- The dust is the chalk's own colour at 42% and fading, 1 to 1.6 pt square, falling 5 to 9 pt. It never crosses into
  the next line.
- Reduce Motion: no dust.
- Fixed on the way: a line logged on the Deck ("Walk, 32 min, Saturday") was written over the week's ticks. It now
  sits in the gap between the ticks and the lifts (baseline 334, 17 pt), and Tess's hand covers that gap only.
- For the builders: a `Canvas` overlay on the board fed by the write progress, spawning a speck every 6% of the line,
  at most 12.

## 11. The zero notch, a new detail (sheet 306)

| Move (sheet 287) | The detail | Haptic | Where |
|---|---|---|---|
| Dial turns past its last door back to the first | **The zero notch.** The usual detent (3 pt past and back in 280 ms) clicks twice as deep, 6 pt, and settles in 380 ms, like a dial passing its zero mark. He can feel he has gone all the way round without looking. | rigid, medium, once, instead of the selection tick | on the board (306) |

- Only on the wrap, in either direction, and only for dials with three doors or more.
- Measured on the board (`t50.js`): Galley and Deck dials, five turns each; the fifth (back to the first door) is the
  deep one.
- Reduce Motion: no detent at all, as before.
- For the builders: `DoorsDial` knows when its index wraps; pass `.wrap` to `MotionPolicy.delight(.detent)` and to
  `TesseraHaptics.play`.

## 12. Undo rewinds its own line (sheet 307)

- Tapping Undo no longer just swaps the line away. The "Undo" line rewinds from its trailing edge over 220 ms (eased
  in, fading to 60%) while the change it undoes reverses, so the line visibly takes itself back.
- The action word ("Cook", "Start") returns only after the line is gone, never under it.
- When the 10 s window runs out without a tap, the line simply fades over 260 ms; only a tap rewinds.
- The undo itself happens at once; only the line's exit is animated.
- Reduce Motion: the line goes at once and the action word returns in place.
- Measured on the board (`t51.js`): Galley in paper and Deck in black, frames every 20 ms; the line clips from the right,
  the action word comes back at full strength, no overlap.
- For the builders: a trailing-edge `.mask` that animates its width to zero through `MotionPolicy`, then the action
  word's own transition in the completion.

## 13. A routine's minutes count down (sheet 313)

- On a routine's steps page the line above the steps ("5 steps, about 10 min left") used to be redrawn whole each time
  a step was checked. Now only the number that changed moves, like a counter: a number going down drops in from
  above while the old one falls away below; one going up (an undo) rises from below.
- Every other word stays still. The number's own width eases from old to new, so "min left" slides over instead
  of jumping when 10 becomes 8.
- When the words change too (the last step makes it "All 5 steps done"), the old line eases out upward and the new
  one rises in, never a swap.
- Timing: the old number goes in 160 ms; the new one arrives over 300 ms from 60 ms with a little overshoot; the
  width eases over 280 ms from 90 ms. Numbers 40 ms apart if more than one changes.
- Reduce Motion: the line changes in place.
- Measured on the board (`t57.js`): the Stretch routine checked step by step to "All 5 steps done" in paper and
  black; the line always ends whole; `t39.js` finds no cut words and `t45.js` no stops.
- For the builders: `Text` with `.contentTransition(.numericText(countsDown: true))` on the number alone, inside an
  `HStack` with the unchanged words, animated through `MotionPolicy`. The same helper fits every "N left" line in the
  app (Lists "6 of 14", Purse "about 2,125 still yours" keeps its "about").
