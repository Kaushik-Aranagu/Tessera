# 228 Landing elements, Notes, Lists, Routines, Money (Oct 23, 5:55 PM PT)

Board: https://claude.ai/artifact/Fp2fkYGcx3fuE2aV5Uo2hM. This follows 226 and 227, which he approved at 5:40 PM. It uses the same rules: type and fine lines only; a line keeps a fixed length and changes only colour or weight; no ticks or marks off a line; nothing fades; Reduce Motion lands each change in one step; Undo is 10 s. For his review.

## 1 Notes, the pull quote
- The first words of the last note, in Figtree 500 at 30 pt on 34 pt lines, three lines fixed. The phone keeps the whole words that fit, then steps back past a trailing small word (and, the, a, an, of, to, by, in, on, or, for, with, at, is) and drops trailing punctuation (, ; :). No "...". A short note stays short, and the space below stays empty.
- An opening quote mark in accent 600 as the first character. Under the quote: the note's name and age (15 pt, ink 2).
- Change: the old quote is clipped away upward (0.24 s), then the new one is clipped open from the top down (0.42 s).
- Private: reads normally inside the room. Setting "Show the last note on top" (226).

## 2 Lists, the tally
- One stroke per item in groups of five: 26 pt tall, 1.6 pt, round caps, 5 pt apart, groups 30 pt apart. The tally sits under the count at left, with the list's name right-aligned on the same row. Not packed is edge; packed is ink.
- A full group gets a 2 pt accent strike from lower left to upper right, drawn in by a clip (0.3 s), with a light tick. Undo undraws it.
- Above 20 items the tally hides and the number carries it. At "14 of 14" the tally steps away (226 all-done state).
- The count's digits change in place.

## 3 Routines, the tide line
- 6 am to midnight across the width, 56 pt tall. Each routine is a swell 18 to 40 pt wide (its length) and 8 to 26 pt high (its size), with a flat line between. 1.6 pt.
- Passed: ink. Ahead: edge. The next routine's swell is accent at 2.4 pt. Time moves the ink forward by colour only; the shape never changes.
- The headline is the next routine's time and name ("8 pm, stretch"). When nothing is left it reads "All done for today".
- Touch: a finger on the line reads the nearest routine in the brief slot ("Pills, 9:15 pm") and holds 1.2 s after release.
- Private: reads normally inside the room; off the phone it's "A routine".

## 4 Money, the month line
- One full-width line, 1.6 pt, one step per day. Passed days are ink and ahead days are edge; today is where the ink stops.
- A bill's day is drawn at 4 pt with round caps: ink once paid, accent while due in the next 7 days, ink 3 later. Payday is a 4 pt ink day. Nothing sits above or below the line.
- Touch reads the day in the brief ("Oct 28. Phone, due.") and holds 1.2 s.
- Amounts show inside the room only, never on the doorway or Home. Reversing a spend reads "Reversed" (engine inverse), with a 10 s Undo.

## Reviewer fixes (coordinator relay, 5:45 PM)
1. Tally touch: a finger on the tally reads the nearest stroke's item in the brief slot ("Adapter, not yet"). That stroke goes to 2.6 pt while held (weight only) and holds 1.2 s after release. On the tide and month lines, "now" is a colour cursor only, where ink meets edge: no ring, no tick.
2. Pull quote (coordinator ruling): a private or walled note's headline shows its shownLabel ("Private note", ink 2), never its words; the headline is a standing display, not a reading view. Open notes quote normally while "Show the last note on top" is on. The app switcher snapshot masks the headline. A one-word or small-word note shows in full and is never empty. The quote mark uses the Notes accent (5B3FB8 / B9A9E0), which is well clear of Ember.
3. Routines: names read inside the room ("Pills, 9:15 pm"). In notices, widgets and backups every routine is "A routine"; lab-mode Claude calls may carry the name. Swells that would start before 6 am or end after midnight are clamped to the line's ends.
4. Money passes as written.
