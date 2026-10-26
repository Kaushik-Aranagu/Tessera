# 207 Next, by hand (Oct 23, 11:10 AM PT)

Board: https://claude.ai/artifact/1aLhfDtkLbG2dFYbjUFVmp. Swipe the Next lines on the phone. Builds on 197 part 4 (three swipe rows), 164 (one Undo), 199 (a finished tile is laid into today) and 201 (finished moment). On by default.

- Next shows three lines: name left, why right (Core's Pick.why), 40 pt rows. No dividers.
- Swipe right (Done):
  - The row follows the finger at 0.9x, and an ink strike (1.5 pt, through the name at 55% height) grows with the drag.
  - Past 90 pt, letting go marks it done. The row settles, the strike completes, and after 420 ms the row closes up (height to 0 over 260 ms).
  - At the same moment a 3.2 pt ink tile leaves the end of the name. It arcs up 60 pt and lands on a tile of today's mosaic in 700 ms, turning half a turn and shrinking from 2.6x to 1x.
  - Landing plays the "finished" moment and a rigid haptic.
- Swipe left (Not now):
  - The row dims to ink 3 while dragged. Past 90 pt it slides out to the left in 260 ms and the rest close up. Soft haptic.
- Undo: one line under the list for 5 s, "Groceries, done. Undo" or "Stretch, not now. Undo". Undo is the only colored word (vermilion, the 164 Undo), and it runs the op-log inverse.
- Under the threshold, the row springs back on the house spring and the strike retracts.
- Private or walled items swipe the same way, and their tile is ink, never an accent.
- Reduce Motion: no follow or arc. The strike shows at once, the tile is laid directly and the row is removed.
- The mosaic's shield covers the whole Next block.
- Lanes:
  - Builder B: swipe rows, Undo line, haptics.
  - Builder A: the tile flight from a screen point into MosaicScreenEngine.lay (already exists), plus the finished moment.
  - Core: op-log Undo for done and not now (exists).

## Reviewer notes (11:07 AM)
- Swipe left is a postpone, never a delete. The item comes back later (Core's Not now rules), and it gets the same Undo line.
- The Undo word uses `Theme.Colors.liveInk` (B83C28 light, FF8466 dark), the existing "UNDO and every vermilion word" token. It is a text word with an underline only, never a pill. No new accent.
- Haptics: one per gesture. Done plays the rigid haptic on landing, and the finished moment plays none of its own when started from Next. Not now plays soft. Undo plays `.undo`.
