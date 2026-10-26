# Routines page, round 238 (Oct 23, 2026)

Board: https://claude.ai/artifact/VfPAA9FtH5DXrnog5f6u96 (r54). Owner: Builder B. Built from the 226 landing and 219 (Routines room). It uses the 237 Lists page as its code base.
Rules in force: no lens on any swipe (his 10:51 PM). No cards, pills, bars, rings, dots, underlines, fades or "N of M" counters. 3-4 colors per page. Titles step down 1 pt to 0.75x, then cut at whole words.

## Colors (3 + ink)
- Routines plum: 8E4A78 light (5.67:1 on F7F5F1), D59AC4 dark (9.25:1 on black). Used for the room title, the front routine, the current step, checked-step strike lines, done strokes and the action word.
- Slate labels: 34506F / A7BCD6 (small caps: "Today", "by time", "Evening", "Done").
- Wine, only for late: 9A2541 / EE8E9C (7.1:1 / 8.98:1). It marks a late routine's time and "late since 9 am". At least 32 ΔE from Ember both modes.
- Ink E8E3DA-family tokens: ink/ink2/ink3 as the app's.

## Today (slots in pt, 402 wide phone; board phone is 350)
- 50: title "Routines", Figtree 600 28 pt in plum (fit 28 -> 21).
- 94: the week as letters M T W T F S S, 15 pt, 9 pt apart. A day with every routine kept is plum 600; a day with a gap is ink2; today is 19 pt ink 600; days still ahead are ink3. Right side: the rhythm in words, 15 pt ink2, e.g. "four nights of stretch".
- 140: brief, 2 lines, 19/25 right-aligned: "3 left today." / "Water the plants is late, from 9 am." (wine on the late name) or "Stretch is next, at 8 pm."
- 206-586: depth wheel of today's routines by time. Small-caps header row "Today ... by time" sits above the first row. Rows are 38 pt; the front row is open 58 pt more, with its name in plum 600 26 pt (down to 21, then cut at a whole word). d1 (13 pt ink2): "5 steps, about 9 min". d2 (15 pt ink): the first steps, cut to whole items. Neighbors are 17 pt, dropping toward 15 pt, in ink2. Done routines are ink3 with "done 7:52 am"; skipped ones say "skipped". Blur up to 1 pt with distance, never on the front row, off under Reduce Motion or Depth off. Tap a row to bring it to the front; tap the front row to open it.
- Default front row: the first routine not done.
- 606: receipt line (Undo 10 s).
- Foot: action word on the left, Tess on the right. Tap = Start (opens the front routine and starts it). Drag left = Skip today. Drag right = Later, 9 pm. A tick when an option arms, a commit haptic when it fires, Undo 10 s.

## A routine
- 50: slate small-caps part of day ("Evening") left; "about 8 min left" right.
- 76: title in plum 28 pt (fit to 21, then whole words).
- 118: the rhythm in words, 15 pt ink2: "Fourth night in a row" (after finishing: "Fifth night in a row").
- 146: the last 14 days as stroke marks, 9 pt apart. A day done is a plum 1.6 pt stroke, 16 pt tall. A day missed is a 4 pt ink3 tick at the baseline. Today draws when done. "last two weeks" 13 pt ink2 sits at the right. Not a chart: no axis, no bars, no counts.
- 182-592: steps, 44 pt rows: the name 19 pt and "2 min" in Outfit 15 pt ink2. The current step (the first open one) is 21 pt plum 600, with one line of how-to (15 pt ink2) under it, clipping in. Done steps sit under a slate "Done" label, struck by a thin plum line (a strike, not an underline).
- Check: tap or swipe right (70 pt). The line draws in 260 ms and the step waits 1.5 s (a new check restarts the wait); then the run drops together. Tap a pending step to take it back. Swipe left (70 pt) = Not now: the step moves to the end. Undo 10 s on everything. Edge swipe or Esc goes back.
- Action word: Start, then Next step (checks the next open step), and Do it again once done. Drag left = Skip today. Drag right = Restart (unchecks all, from the top). Haptics and Undo as above.
- Receipts: "Neck rolls, done." "Hip opener, not now." "Done, fifth night running." "Evening stretch, from the top."

## Privacy
A private routine reads normally inside the room. Everywhere off the phone it is "Private routine": Lock Screen, widgets, Tess and Claude lines, backups, notices. Routine history (strokes, times) stays on the phone like other personal data; under lab mode Claude calls follow the asksClaude gate.

## Motion
Spring settles (MotionPolicy). The page slides in from the right. Text clips in, with no fades. Reduce Motion: no spring, no blur, and the drop wait is 0.6 s.

## v2 rulings (coordinator, Oct 23 night). These override the sections above.
1. Title shrink unchanged (28 -> 21 in 1 pt steps, then whole words).
2. Stroke marks follow the 227 rule: all 14 marks are one fixed length (14 pt). Only color and weight change: done = plum, 2 pt; missed = ink3, 1 pt. Never wine. No count on or beside the marks; the aria label lists done/missed per day. The rhythm words stay ("Fourth night in a row"); they are not a count of the marks.
3. Restart receipt: "<Routine name>, restarted. Undo". Undo (10 s) restores the checked steps and the done time. Skip today: a neutral ink2 receipt "Skipped today. Undo" on the Today page. The routine is recorded as skipped (row reads "skipped" in ink2), with no late state and no wine. The back edge-swipe zone stays 0 to 24 pt. The action word's touch area starts at least 28 pt in from the left edge (correction 06:14Z), so its left drag never collides with the back swipe.
4. Done routines: name and "done 7:52 am" are both ink2 (not ink3).
5. Not in this round: reminders and notices. When they come, they follow quiet hours (11 PM-7 AM PT), and a private routine reads "Private routine" in them.
6. Reduce Motion (board honors prefers-reduced-motion; tested with Playwright reducedMotion 'reduce'):
   - Wheel snap: no spring; the wheel swaps in place to the new front row.
   - Strike: the line shows at once (no 260 ms draw).
   - Drop: the checked run drops to Done after 0.6 s, swapping in place with no slide.
   - Week row "today bigger": static; today is simply drawn 19 pt, with no grow.
   - Step line (how-to): appears at once, no clip-in.
   - Action-word roll: the armed word swaps in place, no roll; the word doesn't slide back with a spring.
   - Page push: the routine page swaps in place. Depth blur off.
7. G13 tap targets (44 pt minimum each, all tested):
   | Target | Hit size | Tap does |
   | Wheel row (any) | full width x 44 | brings it to the front |
   | Front wheel row | full width x 44 (+58 open) | opens the routine |
   | Today action word | at least 44 x 44 | Start: opens the front routine, started |
   | Step row | full width x 44 | checks it (strike, 1.5 s, drops to Done); tap a pending one to take it back |
   | Routine action word | at least 44 x 44 | Start -> Next step (checks the next open step) -> Do it again |
   | Undo (receipts) | at least 44 x 44 | undoes the last action within 10 s |
   | Tess | 44 x 44 | opens Tess (not on this board) |
   Drags (not taps): action word left/right (Skip today / Restart; on Today: Skip today / Later, 9 pm); step swipe right = check, left = Not now; 0-24 pt left edge swipe = back; the action word's hit area starts at 28 pt or more.
   Test: scratchpad r54/tg.js taps each target in light and dark, with and without Reduce Motion, checks hit sizes and results. Result: "All tap tests pass", no page errors.
- Layout changes for 44 pt: wheel rows 44 apart (header 44), receipt line 44 tall at 597, foot 44 tall at bottom 22, Tess 44.

## v3 landing (his 11:27 PM Oct 23): three levels
The landing is a summary and a way in, not the list. A routine can be one thing or a run of steps. Board v4, same link. The 238 v2 rulings hold on every level. The foot action word's hit area starts 28 pt from the left edge; the back edge-swipe zone stays 0 to 24 pt.

Level 1, Routines (landing, model: Training landing r45 #home)
- 54: "Routines", Figtree 600 40 pt plum (fit 40 -> 30).
- 110: summary, 3 lines, 19/25, no wrap: "Two done, three to go." / "Water the plants is late." (wine; else "Stretch at 8 pm.") / "Stretch at 8 pm, night four." (the rhythm in words).
- 200: doors, 54 pt each (name Figtree 600 24/30, fact 15/20 ink2):
  - Today (name in plum): "three to go, evening stretch at 8 pm". Opens the today page (the v2 page, now one level in, with a "Routines" slate label above "Today").
  - Mornings: "3 routines, walk six mornings running".
  - Evenings: "2 routines, wind down at 10:30 pm".
  - Body (warm-ups, mobility, the rower, built from Training's moves): "3 routines, from Training's moves".
  - Home (chores and resets): "3 routines, the plants are late" (wine only while late).
  - Mind (reading, journaling, breathing): "3 routines, read 20 minutes any time".
  - Borrowed (lives in another room, stays linked): "3 routines, from Training, Kitchen and Lists".
- Foot: "New routine". Tap = make one (opens with Add steps chosen). Drag left = One thing (opens with Keep it one thing chosen). Drag right = From another room.

Level 2, a kind of routine
- "Routines" slate label, the kind's name 28 pt plum, one-line fact (e.g. "chores and resets").
- Depth wheel (v2 rules: 44 pt rows, front opens 58 pt, blur up to 1 pt never on the front row) under a small-caps header "<Kind> ... when" ("... from" on Borrowed).
- A one-thing routine reads as one line, with no step count. Front detail: "about 5 min, weekdays", then its how-to line. A routine with steps: "4 steps, about 12 min, training days", then its first steps.
- Right column: today's time if it's on today (wine if late), else when it repeats. On Borrowed, the source room's name in that room's accent (Training 0B62AE/8FB0EE, Kitchen 93611A/C49A5E, Lists 5E6B1F/B5BE7A). This is the one place other rooms' colors appear, only to name the source room, so the page can exceed 4 colors there.
- Tap a row to bring it front; tap the front row to open it. Foot: "New routine" (its kind preset); on Borrowed, a tap goes to From another room.

Making one (short)
- "New routine" slate label; name field 28 pt plum ("Name it" placeholder in ink3); "In <kind>": tap the kind word to cycle the kinds (not Borrowed); "Keep it one thing" / "Add steps" (the chosen one is ink 600, the other ink2, no pill or underline); with steps, a "Steps" label, the step lines, and an "Add a step" line (Return adds the next).
- Action word Save: lands on that kind's wheel with the new routine in front, receipt "<Name>, saved. Undo". Drag left = Discard.
- One thing = one step named for the routine; it checks off in one tap.

From another room
- Title "From another room"; "It stays linked: change it there and it changes here." Rows of 54 pt: name, step count beneath, source room's name in its accent at the right.
- Tap = borrow: lands on Borrowed with it in front, receipt "<Name>, borrowed from Training. Undo". Edits stay owned by the source room; a borrowed routine keeps its home room's privacy.

Tap targets added (all at least 44 pt, all tested in r54/tg.js, light/dark, with and without Reduce Motion: "All tap tests pass"): 7 doors (opens its place), landing and kind "New routine", kind wheel rows (bring front / open), "In <kind>" word (cycles), the two shape choices, Save, borrow rows. Reduce Motion: pages and wheels swap in place.

## v4 landing (his 11:39 PM: "not a list of summaries... look at how other apps have their landing pages"). REPLACES the v3 door list.
The landing follows the 226 bands and the 231 Kitchen pattern.
- Top row: "Routines", 40 pt plum, with the day word "Friday" (15 pt ink2) on the right.
- 112: "Next" slate label.
- 132: a REEL, 56 pt tall. The next routine's name is 46 pt plum (wine if late), fitting 46 -> 35. Swipe up or down, or tap "another" (ink2, right, 44 pt hit), and it rolls to the next routine. Order: by time, then late ones. The roll is a 56 pt spring and the line under it clips in. Tapping the name opens the routine.
- 190: "at 8 pm, 5 steps, about 9 min" (or "one thing"), 15 pt ink2. A late routine reads "late, from 9 am".
- 222: THE TIDE LINE, 62 pt tall. One fine line for the day, 5 am to 11 pm. Each of today's routines is a cosine swell at its time, 20 pt tall; the reel's routine is 30 pt. Passed water is plum at 2 pt, ahead is ink3 at 1.5 pt, a late swell is wine. Now is a 13 pt ink stitch. No ticks, axes, fills or dots. Each swell has a 44 pt tap that opens its routine. Reduce Motion: nothing moves.
- 300: brief, 2 lines at 17/25, right-aligned: "Morning walk and Vitamins are done." / "Water the plants is late, from 9 am." (the name in wine), or "Nothing is late."
- 372: three numbers in Outfit 200 at 44 pt, each with a 13 pt ink2 word: done (plum), to go (ink), late (wine, shown only when there is one). Tapping any number opens Today.
- 476: "Kinds" slate label. At 496: the kinds one at a time on the right, 72 pt tall: the name at 24 pt 600 with its count in plum, and a fact at 15 pt ink2 ("walk six mornings running"). Swipe across to move 1:1 between Mornings, Evenings, Body, Home, Mind and Borrowed. No lens, no counter. Tapping it opens that kind.
- Foot: "Start <reel routine>". Tap starts it. Drag left = Skip today. Drag right = New routine. With everything done, the reel reads "All done" in ink3 / "the evening is yours" and the word becomes New routine.
- Levels 2-3, Making one and From another room are unchanged from v3. The Today page opens from the numbers.
- Tests: tg.js passes in light, dark and Reduce Motion (numbers, another, reel, kind and Start, each 44 pt or more).

## v6 landing (his 11:45 PM Oct 23, replaces v4 landing)
"Somewhere in between": a summary and doors, not the reel and not a list. Board https://claude.ai/artifact/VfPAA9FtH5DXrnog5f6u96 (v6).
- Title "Routines" 40 pt plum, weekday right in ink2 (as before).
- Brief at 112, two lines of 19 pt (steps down 1 pt to 15 if long): line 1 = next routine's name (600, plum; wine if late; tap opens it, 44 pt hit) + "is next, at 8 pm."; line 2 in ink2 = the oldest late routine in wine + "is still waiting, from 9 am." or "Nothing is late."
- Tide line at 182, 62 pt (unchanged; room drawings may be revamped later).
- "Today" slate small-caps label at 268; three numbers at 288 (Outfit 200, 40 pt; done plum, to go ink, late wine; captions 13 pt ink2); each opens Today.
- "Kinds" label at 392; doors grid at 412: two columns, 62 pt rows, gap 20. Each door = name 21 pt 600 + count in plum Outfit 17, then a 13 pt ink2 fact cut at whole words: Mornings every morning; Evenings winding down; Body Training’s moves; Home chores and resets; Mind read, write, breathe; Borrowed from other rooms. Tap opens that kind's wheel.
- Removed: the 46 pt reel, "another", the kinds pager.
- Foot unchanged: "Start stretch"; drag left Skip today, right New routine; action word from 28 pt, edge 0-24.
