# Item 219: The Routines room, the day as a tide line (Oct 23, 3:40 PM PT)

Board: https://claude.ai/artifact/WqsDGCX3gdjG84xK4eG3Wa, Routines room (and its Quiet day toggle). Follows 218 (shared lintel rules, one numeral at most, touch to read) and its reviewer fixes.

## Accent move (needed for the rooms to sit side by side)
Routines light A4505F was ΔE 8.3 from Training's new crimson A8203F, under the 10 limit. Routines light moves to plum **8E4A78**:
- 10.3 from Training, 14.9 from Notes 5B3FB8, 24.7 from Ember;
- contrast 5.7:1 on paper F7F5F1, 6.2:1 on white.
Dark stays D79AA6 (17.6 from Training dark). Builders: update AppAccents.swift.

## Lintel (196 pt, arrival "calm")
- The day from 5 am to 11 pm across the width.
- Each routine is a swell at its usual start (cosine shape), as wide as it usually runs, scaled so even a 10 min routine is about 2 hours of width. Low water is 8 tiles; a swell's crest is 24 tiles below the lintel's bottom.
- What has passed is water in the routine accent, with the 1/16 Bayer edge into the page, like the other rooms.
- What is ahead is only its surface: pale whole tiles (ink 3 at 50%), joined vertically so the line is continuous, never dotted, and still.
- Now is one ink stitch (70% ink, 3 tiles) standing on the water; the 3 tiles under it are left open.
- The running routine's swell breathes (1.1 tile amplitude, 1.6 rad/s) and is 17% deeper in colour. Passed water lies flat with a slow 0.45 tile swell. Reduce Motion: no movement.
- Arrival: the tide comes in from below over 900 ms, ease out cubic.
- Tap a routine's line and its swell glints once (700 ms, up to 50% toward ink).
- No numeral on this lintel. Counts live in the rows.
- Touch to read: "Morning, usually 6:40, 22 min"; between swells "11 am, nothing runs".

## Room body (sheet 131 v2, Routines)
- Running: "Evening reset is running" (name in the accent, 600, 16 pt); the step in large words (Figtree 500, 38 pt, "Dishes away"); "4 min on this step, then wipe the counter" (15 pt ink 2); Pick up (accent action word).
- Quiet day: "Nothing is running"; "A quiet evening." at 34 pt; the three most used routines as Start words (20 pt).
- One line per routine: name 17 pt ink, then "14 days, usually 6:40, 22 min" at 15 pt ink 2 on the right. Counts show only after 7 runs. Nothing can fall: no streaks, no missed.
- The fact line is "Night next, at 10:15 pm".
- Browse at the foot opens the index.

## Privacy and rules
- A routine's name is its shownLabel everywhere, scrub and VoiceOver included.
- Routine times never reach Claude when the routine links health or calendar items.
- Lintel and rows never reach widgets, the Lock Screen or backups beyond what Routines already sends.

## Reviewer fixes (3:32 PM, folded in; these win over the sections above)
- The lintel has no hour ticks, grid or axis labels.
- Passed water is four whole-tile colour steps from the surface down, not a smooth ramp. The 1/16 Bayer edge at the bottom stays, as in every room.
- Private routines, and routines linked to health or body data, are drawn as a generic swell, 2.5 hours wide, at a fixed place that is not their real time, with no real length. Their scrub and VoiceOver read "Private routine" only, and their row uses shownLabel with no time or length.
- Other scrubs and rows give the time with am or pm: "Morning, usually 6:40 am, 22 min".
- Plum 8E4A78 is ΔE 24.7 from Ember FF5A26. Dark D79AA6 is 14.0 from Ember dark FF6B3D.
- Reduce Motion: the breathing swell holds still.

## Ruling: no back word (coordinator, Oct 23, 4:16 PM)
Kaushik asked why there is a back word at all. Rooms and Today show no "< Home" or "Home" word at the top. To go back, swipe from the left edge, which plays the doorway in reverse; VoiceOver escape also works. The space the word used goes to the lintel.
