# Energy check-in (Design item 112)

Product rulings (huddle, Oct 19): a 1 to 5 level set on the rep drum, no words per level; asked at most once a day, at Finish of a workout or in the morning Plan line, paired with last night's sleep; shown as one quiet line in the Day log ("Energy 4, slept 7 h"); never red; never sent to Claude. Behind the Review switch `energyCheckIn`, Off (sheet 110).

## The ask
- At Finish: under "<title>, ready to finish", one line in Tess's voice, 21 pt: "Energy today?" and the rep drum (the same drum as for reps) showing 1 to 5, set to the last answer or 3. No words under the numbers. The drum is optional: Finish works without it, no extra step, nothing to skip. If he touches the drum, the level is saved on Finish.
- In the morning Plan line: the same line and drum appear once, if no level has been set today and Finish has not asked. Never both; never more than one ask per day.
- Sleep is not typed: it comes from Health (last night, rounded to the hour) when Health is allowed; with no Health access the line shows only the level.

## Where it shows
- The Day log: one quiet line in `inkSecondary` 16: "Energy 4, slept 7 h", or "Energy 4" with no sleep. A day with no level shows nothing.
- Nowhere else: not on Home, not in widgets, not in Review's week.

## Rules
- Never red or any colour: the level is ink; the drum uses the usual drum look.
- Never sent to Claude, Sent rows, logs or backups beyond the normal object copy (the level is a local object; the Health-derived sleep value is not stored: it is read live).
- One soft haptic when the level is set. Reduce Motion: the drum is the same drum.
- VoiceOver: the drum is adjustable: "Energy, 3 of 5". The Day log line reads as is.
- The switch name: "Energy check-in is **off**."
