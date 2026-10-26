# 217 The Notes room and the Lists room (Oct 23, 3:10 PM PT)

These follow the 210 pattern: the doorway lands, the mosaic becomes the room's lintel (176 pt, 4 pt grid, 3.3 pt tiles, bottom edge in 1/16 Bayer steps), and below it are the fact line, the 23 pt sentence, one plain line per thing, and the action at the bottom.
- Board: https://claude.ai/artifact/WqsDGCX3gdjG84xK4eG3Wa (v3; use the Notes room and Lists room buttons).
- Proposal, ON by default once built. Builder A builds the lintels and Builder B builds the pages, following his sequence: after the phone push and his bug list.

## Notes: the latest page as written rows
- **Lintel:** the latest note, drawn as rows of tiles. Each line of the note is one row (2 tiles tall, 1 tile apart). Each word is a run of tiles, about 0.62 tiles per letter, and each space is a gap. You see the note's shape, not its words.
  - The longest line fills 92% of the width.
  - Rows sit 22 tiles from the top, below "Home".
  - Older lines are drawn at 72% toward the page. The newest line is full Notes accent.
- **On arrival:** the rows write themselves in, row by row (90 ms apart) and tile by tile (12 ms apart), each tile growing from half size over 90 ms. Then one pale ink3 tile breathes at the end of the newest line, where the next word goes.
- **Picking another note:** tapping one turns the page. The rows write in again from the top.
- **Page:**
  - Fact line: "4 notes, the last this morning".
  - Sentence: "Trip packing, / written this morning, / 6 lines." The title is a 205 keyword in the Notes accent.
  - One line per note: the title on the left, the time on the right (Outfit 300).
  - Action: "Write a note".
- **Privacy:** words never reach the lintel, only lengths, so the lintel is safe to show even for a private note. Inside the room, titles read normally. A private note's title follows ObjectPrivacy.shownLabel everywhere outside the room.

## Lists: what is left, as a falling line
- **Lintel:** the list's remaining count over time, as a stepped line in the Lists accent.
  - It starts high on the left, where the list began (14), and steps down at each item done, out to "now" at 68% of the width. Below the line, the fill fades to the page in steps, the same as the Training ridge.
  - Past now, a quiet dotted line of pale ink3 tiles (every other column) runs down toward zero on the day it should reach zero.
- **Ticking an item:** that step drops, and one tile breaks off the line at "now". It falls away under gravity, drifting 6 pt to the side and fading toward the page, over 900 ms. Reduce Motion: no fall.
- **Page:**
  - Fact line: "9 of 14 packed".
  - Sentence: "Packing, / 5 left, / done by Sunday."
  - One line per item: an ink ring on the left (done: 1.6 pt in the Lists accent; to do: 1.3 pt in the edge color; never filled), then the item. A done item takes ink3 with a 1 pt strike.
  - Action: "Add to Packing".
- **Swiping items:** swipe right is Done everywhere, and swipe left is Not now, the same as ticking the ring.

## Next rooms
- Routines: the day's hours as a tide line.
- Money: shapes only, never amounts.

## Reviewer fixes (3:00 PM, folded in; board v4)

**Privacy**
- A private or walled note never shows its real shape. Its lintel is a fixed, generic block of rows, the same size every time.
- Its keyword is its masked label (ObjectPrivacy.shownLabel) everywhere: in the sentence, the fact line, the rows and VoiceOver.
- On a private note, the pale tile is a plain idle pulse and never reacts to typing.
- The lintel and note text never reach widgets, the Lock Screen, Spotlight, backups or Claude.

**Look**
- **Lists projection:** the dotted projection is gone. Past "now", the line continues as a few whole pale tiles in steps (whole counts) toward zero. There are no axes or ticks, and the count lives only in the sentence.
- **Reduce Motion:** the falling tile becomes a plain swap of the step.
- **Done items:** a done item is drawn in ink2 with a 1 pt strike, not ink3. Ink3 was about 3.3:1 on Paper; ink2 is about 6:1.

## Ruling: no back word (coordinator, Oct 23, 4:16 PM)
Kaushik asked why there is a back word at all. Rooms and Today show no "< Home" or "Home" word at the top. To go back, swipe from the left edge, which plays the doorway in reverse; VoiceOver escape also works. The space the word used goes to the lintel.
