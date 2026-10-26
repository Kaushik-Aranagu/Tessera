# Sheet 285: when Tess makes the change (Oct 25)

Asked by the harness thread (PR #1434, `docs/ai/harness/elements.md` section 5): one look per reaction when Tess,
not his finger, makes the change. Their recommendation was the same move, played after the soul's hand-off wash
behind the place, checked on the Deck board and the Galley rail. This sheet takes that recommendation, adds one
rule, and corrects one point.

Board: https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp, using the "Tess acts" buttons under the phone.

## The one rule: Tess's ink is blue until it dries

A change Tess makes is pending (a ghost with Undo, 10 s). For that whole window it carries her blue (`tessblue`)
in the room's own material. When the window closes it dries into the room's own ink, over 0.7 s. This is the only
mark that says "Tess did this"; there is no badge, outline or toast.

| Room, material | While pending (her blue) | Dried |
|---|---|---|
| Deck, chalk | Blue chalk, 80% | White chalk, 95% |
| Galley, ticket | Blue clip on the rail | Steel clip |
| Any struck line | Blue strike | Ink strike; the line then reprints |
| Log, wall word | Word sets in blue | Ink (to draw) |
| Watch, tree | New leaves blue-green | The tree's own green (to draw) |

Her blue lives only in the keystone's material and in strikes. Type in the widget, needs and rows never carries it,
because on the Deck her blue sits too close to the room's own blue to read as a mark. "Tess" in the Undo line says
who did it.

A new change by her dries the previous one at once. Undo takes the change back with its own exit (chalk wipes,
the ticket lifts off), and the foot returns.

## The sequence (Tess)

1. **Fly.** One dab leaves the soul and arcs to the centre of the place that offered the call (x and y on different
   curves: y rises first, then x catches up). 460 ms.
2. **Spread.** The dab opens into a soft wash the size of the changing part, plus a margin (1.12 x width + 28 pt,
   1.25 x height + 24 pt), blur 10. 260 ms. The place starts playing 200 ms in.
3. **Play.** It plays the place's own move from sheet 283 at 1.15 to 1.2 x his tempo (chalk writes left to right
   in 1.08 s; the ticket drops onto the rail and swings to rest in 1.3 s; a strike draws in 0.22 s).
4. **Fade.** The wash holds about 1 s while the move plays, then fades out over 0.6 s.
5. **Undo line.** "Tess logged yesterday's walk, 32 min  Undo". "Tess" is in her blue and the rest is in ink2. The
   action word steps aside while the line holds the foot and returns after 10 s.

**His finger:** no flight and no wash. The move plays at his tempo, the result is in the room's ink straight away,
and the Undo line has no "Tess".

## Behind or over (the correction)

"Behind the place" works only where the keystone has gaps.

- **Behind** (z under the content, multiply on paper, normal on black): the Galley rail, the Log wall, the Watch
  woods, widgets, rows. The paper tickets stand clear of a blue glow.
- **Over** (screen blend at 55%): keystones that fill their slot edge to edge, which are the Deck board, the
  Lookout sky and the Purse index chart. On these the wash reads as light falling on the surface. Behind would be
  invisible.

## Refused, off screen, several at once, Reduce Motion

- **Refused** (the engine says no): the dab flies 72% of the way, swells once, and goes home in 420 ms. No wash
  appears and nothing moves. Her line says why, and the action word steps aside while she speaks.
- **Target not on screen:** she does not move him. Her line says it, with the door's word as a link.
- **Several targets** ("add limes and feta"): one flight, and the wash spans all the targets. Each target plays
  80 ms after the one before.
- **Reduce Motion:** there is no flight. The wash fades in at the place in 150 ms, the content crossfades, and it
  fades out in 150 ms. Pending blue and drying stay the same, because they are colour, not motion.

## Per reaction (elements.md section 5)

| Reaction | Tess's version |
|---|---|
| strike | The wash sits behind the widget's Big line. The strike draws in blue, dries to ink, and the next item rises. |
| next | The wash sits behind the widget. The item rises out and the next rises in, in the room's own type. |
| keystoneTakes | The wash sits behind or over the keystone part. The keystone's own arrival plays (chalk writes, a ticket hangs, a word sets, a tree is planted) in her blue until it dries. |
| reform | The wash sits behind the glyph, which collapses and forms again. No blue: a glyph never carries her ink. |
| navigate | No wash. Places change content in place, as when he taps. Her line says where she took him. |
| lines | The wash sits behind the needs or the door summary. The new line arrives in the room's way. |
| tessLine | No flight. Only her line. |

## Built and checked on the board

- **Deck:** Tess logs yesterday's walk. Blue chalk writes "Walk, 32 min, Saturday" under the week, and it whitens after 10 s. Your finger writes it white
  at once. Refused: "move Push A to tomorrow". The dab stops short and her line says Pull A is already tomorrow.
- **Galley:** Tess hangs a Dal ticket for tomorrow. The rail makes room, the ticket swings in with a blue clip, and the clip turns steel. She also does the dishes: a blue
  strike over "7 waiting", which dries and reprints as "none waiting".
- I checked both looks frame by frame and the board reported no errors.

## For builders

- Play `Reaction` on the offering place only after `TessSoul.handOff(target:)` reaches the spread (0.5 of the carry
  track). Use the place's frame centre as the target, and the wash rect as above.
- `SlotContent` needs a `pending: Bool` (set while the ghost row is open). Each place draws its pending state in
  `Theme.tess` and dries it with `withTesseraAnimation` when the ghost commits.
- Each keystone needs a `washPlacement` (`behind` or `over`), declared by the keystone kind, not by the room.

## Rest today on the Deck (asked by the harness thread)

They recommended chalk words in the widget, using the glyph's ticks. I'm keeping chalk on the board only. The widget
uses the app's own type in every room, so chalk there would blur the line between keystone and widget. The rest
goes where the week already lives, on the board:

- **Board:** tonight's line is wiped left to right, then "Rest today, Push A tomorrow" is chalked with "a walk is
  fine, nothing heavy" under it. Today's letter in the week takes the word "rest" under it, where a done day takes
  a tick. It is never a cross and never "missed".
- **Needs:** the lines flap to "Rest today" and "Push A tomorrow".
- **Widget:** "Today / Rest / Push A waits for tomorrow / A rest day never counts as missed", in type, with the
  widget's own move (out the top, in from below).
- **Glyph:** the barbell sets its plates down. The four plates come off the bar and lie flat, stacked under it.
- **By Tess:** a wash over the board, the chalk in her blue until it dries, and the Undo line "Tess set today as a
  rest day"
- **By finger:** no wash, and white chalk at once.
- **Undo:** the chalk wipes, the needs flap back, the widget returns and the plates go back on.
