# Item 218: Richer lintels, and each room its own place (Oct 23, 3:25 PM PT)

Kaushik, 3:14 PM: "I like the idea of the lintel... make them a little more interesting and more informative." 3:15 PM: "I don't want all the rooms or apps to look the same way... incorporate all of those [earlier decisions]... and still maintain the vibe of the whole app."
Board: https://claude.ai/artifact/WqsDGCX3gdjG84xK4eG3Wa (Rounds 210, 217, 218). Builds on 210 (Training lintel) and 217 (Notes, Lists), and supersedes 217's room bodies.

## 1. What every room shares (the vibe)
- The lintel: 4 pt pixel pitch, 3.3 pt tiles, the bottom edge straddling into the page in 1/16 Bayer steps (as Home), one accent per room (127 table E as moved by the 2:30 PM accent rule).
- The fact line under the lintel: Figtree 16 pt, ink 2, right-aligned, numbers Outfit 300 in ink.
- Pixel numerals: 3 x 5 tiles per digit, 1 tile apart, the room's accent at full strength, centered on their column, their bottom 3 tiles above the point they name. At most one numeral per lintel.
- Touch to read (scrub): press and slide along the lintel. The column under the finger mixes 38% toward ink, and the fact line reads that point. On release it holds for 1.2 s, then the room's own fact line returns. Selection haptic tick per column crossed. VoiceOver: the lintel is an adjustable element; swipe up and down steps through the same readings.
- Back word top left; the room's landing body is sheet 131 v2, unchanged in content and order (and 2b: keep every feature).

## 2. What each room owns
| Room | Lintel height | Arrival (MotionPolicy) | Lintel information |
|---|---|---|---|
| Training | 176 pt | firm: columns re-form left to right, 9 ms apart, 260 ms each | best written over its peak; one ink tile (55% ink) 3 tiles above the ridge on every week that set a new best (not the best week itself) |
| Kitchen | 188 pt | soft: each building settles 6 tiles from above, 70 ms apart, 520 ms, cubic ease out | one window per ingredient still to get: 1 x 2 tile gaps (accent at 12%) 4 tiles under the roof, 1 tile apart, centered on the building |
| Notes | 168 pt | drift: rows write in (217) | margin mark: one 1 x 2 tile in the linked app's accent, 3 columns left of a row that is also something elsewhere (an item on a list, a lift, a recipe), fading in 200 ms after its row |
| Lists | 156 pt | the line steps in from the left over 700 ms | the count left written over today; a pixel flag (5-tile pole and a 3-tile flag, accent 80%) on the day the pace reaches zero |
The lintel height changes with a 0.42 s glide when going from room to room.

Scrub readings (exact words):
- Training: "Week of Sep 14, best 199 lb" (reps for body-weight lifts).
- Kitchen: "Friday, tacos, 4 to get"; a day with nothing to get drops the last clause.
- Notes: "The third line, also on Packing" (ordinal words; Notes shows no numbers anywhere).
- Lists: "Oct 20, 9 left"; today reads "Today, 6 left"; ahead of today "Saturday, about 3 left at this pace".

## 3. The room bodies (131 v2, drawn on the board)
- Training: sentence "Push A today, about 45 min. Bench opens at 185." (Bench in the accent, underlined); Start Push A (accent) with the place word Gym or Home at the right; the week as seven set-mark rings (done ink 1.7 pt, today accent, rest edge 1.2 pt, day letters 12 pt ink 3); today's lifts with sets; doors Plan, Library, Log, Stats each with a short value word (15 pt ink 2).
- Kitchen: sentence "Tacos tonight, start at 6:05. Lemon is short."; Pantry door (30 pt, 600); its level lines per place in a two-column grid (place name 15 pt ink 2, then a 1.5 pt accent line, round caps, up to 62 pt long by level); "2 use soon, 7 to get, covers 4 dinners"; Recipes door; the week as plain rows (16 pt; today full ink with its start time, other days ink 3, the tapped day in the accent, 600); Cook at the foot.
- Notes: the search-and-write line (18 pt, hairline under it in edge); the things field (words sized by how much he writes, 17-30 pt, 500; the open thing in violet, 600; Loose and Private 16 pt ink 3); margin sentences Running, Waiting, New (16 pt ink 2, label in ink 3, the link word ink with a 1 pt violet underline); Write at the foot. Tapping a thing word turns the lintel to its latest note.
- Lists: "Packing, done by Sunday" (name in olive, 600); the next things as large words (27 pt, 500, comma-separated); tap one: a 1.5 pt olive strike for 380 ms, then it leaves and a tile breaks off the lintel's line and falls; "6 left of 14" small with Resume (accent); every other list as a filling line (26 pt, 600, ink up to the share done and ink 3 after it); doors Shelf, Reusable, Picks, Runs.

## 4. Privacy (carries 217)
- A private or walled note shows 217's fixed generic block and no margin marks.
- A private list shows "Private list" in the lead and its words never draw; the lintel still draws its counts.
- Scrub readings use shownLabel for private things. None of this reaches widgets, the Lock Screen, Spotlight, backups or Claude.

## 5. Reduce Motion
- Arrivals appear at once.
- Scrub still works, with the column tint and no tick animation.
- The Lists strike and drop become a plain swap.

## Reviewer fixes (3:21 PM, folded in; these win over sections 1 to 4)
- One pixel numeral per lintel, as its headline: top right, its right edge 6 tiles in from the lintel's right edge (clear of the corner radius), top at row 12, level with the Back word. Never as a point or axis label. The sentence and fact line don't repeat that figure.
  - Training: the numeral is the best. The weekly new-best ticks are dropped; only the best week glints (210). The fact line reads "Bench best three weeks ago, new bests in 4 of 12 weeks".
  - Lists: the numeral is how many are left. The fact line reads "left of 14, 8 packed". The flag is dropped. Ahead of today, a pale whole tile every third column steps down toward zero. The day it gets there is in the sentence: "Packing is done by Sunday". The "6 left of 14" small line is gone; Resume stands alone.
  - Kitchen and Notes have no numeral. Notes shows no numbers anywhere.
- Notes margin marks are small tiles only, with no text. Every linked-app accent stays more than ΔE 10 from Ember.
- Kitchen windows are shapes only, never ingredient names.
- Privacy:
  - Scrub readings show only shownLabel and aggregates. A private workout's week reads "Private workout".
  - No glint on a week whose best came from a private workout.
  - Best weights stay on the phone.
  - Each VoiceOver step reads the same masked line.

## Ruling: no back word (coordinator, Oct 23, 4:16 PM)
Kaushik asked why there is a back word at all. Rooms and Today show no "< Home" or "Home" word at the top. To go back, swipe from the left edge, which plays the doorway in reverse; VoiceOver escape also works. The space the word used goes to the lintel.
