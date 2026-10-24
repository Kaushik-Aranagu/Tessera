# 230 Training flow: landing, warm-up, lifts, exercise page

Board: https://claude.ai/artifact/PFDdUde9cLtYA1G6Qjrpwp (r45). Answers Kaushik's 6:06 PM Oct 23 notes. Builds on 226 (four bands) and 227 (elements), both approved.

## Colors
- Training cobalt 0B62AE light / 3B8CF2 dark (approved).
- NEW second colour "go" green 2FA24D light / 3BAC56 dark. Delta E 15 or more from Ember and every room accent. Contrast about 3 on paper, so large text and strokes only. Used lightly: the warm-up, rest countdown, the green strike when a set logs, "Done warming up" and "Skip rest".

## Flow
Home, then Training landing, then Warm up, then each lift, then Done. The landing never jumps into the workout; only the foot word "Start Push A" starts workout mode.

## Landing (not started)
- Headline: "Today", "Push A" in cobalt, "about 45 min, 4 lifts" (minutes tap through 25, 35, 45, All), "Gym or Home" knob.
- Week as day letters: done ink, today cobalt 600, rest ink 3.
- Brief: "Starts with 8 min on the rower. Bench opens at 185." (8 min in green).
- Plan: "Warm up, row 8 min" first, then each lift "3 by 5 at 185". Lifts out of the minutes or not doable at home go ink 3. Each row opens its exercise page.
- "Bench best 205, three weeks ago." opens the Bench exercise page.
- Foot: "Start Push A" bottom left, Tess bottom right. The not-started weight and bar never appear here.

## Workout
- Top band is only the current exercise: name in cobalt 34 pt (tap opens the exercise page), "Set 1 of 3", weight 80 pt, unit word in cobalt, bar on the right.
- Weight: drag the number up or down, or drag the bar (sideways or up and down), 5 lb steps; plates slide on and off the sleeve; "was 185" shows 2 s after.
- Unit: tap or swipe the unit word, digits roll, plates reload. kg uses 2.5 kg steps with the receipt "185 lb loads as 85 kg." Same rule for every unit pair.
- Sets replace "3 x 5 + three circles": target reps as thin strokes. Logging fills them one by one (55 ms each), a green strike draws across, then the set folds into a quiet trail on the right ("5 5"). Strokes for the next set drop in one at a time. Drag the strokes to log fewer reps ("Log set 2, 4 reps").
- Rest: "Rest 1:30" in green, then "Set 2 is next". Foot reads "Skip rest".
- Session strip below: done lifts ink 3 with their reps trail ("5 5 5"), next lifts ink 2 short ("3 by 6"). The current lift is not repeated there.
- Warm-up screen: "Rower, easy" in green, 8:00 countdown, "Keep it easy, about 22 strokes a minute. Bench is next.", foot "Done warming up".
- Done: "Push A", time, "warm-up and 4 lifts", "Bench held at 185. Next Push A is Friday.", foot "Finish".

## Exercise page
Slides in from the right; back by the left edge. "Works chest, shoulders and triceps", name, Gym visual loop (still frame under Reduce Motion and Low Power), best, last three sessions, next time.

## Rules kept
No bars as gauges (the barbell is the object, not a meter), no countdown lines, no fades (clip reveals), Reduce Motion lands in one step, fixed slots (224), undo 10 s on a logged set.

## Reviewer fixes (Oct 23, 6:17 PM PT)
1. Rep strokes are a count, never a gauge. Normal logging: tap "Log set N" in the foot, which logs the full target. Drag the strokes (or VoiceOver adjustable, steps of 1 rep, 0 to target) to log fewer; the foot then reads "Log set 2, 4 reps".
2. Rest end fires the Live Activity update plus a local notification; sound follows the silent switch. A private workout shows "Private workout" there.
3. The brush circles from 229 are gone everywhere; rep strokes replace the ink ring D set mark (his 6:06 PM ask to change the circles).
4. Undo 10 s on a logged set, on Done, and on a swap.
5. Measured: go green vs Lists olive dE 15.5 light / 15.3 dark, vs Money teal 16.0 / 16.6. Contrast on paper 3.0 (large text and strokes only), 7.2 on black. Green is never the only signal: rest also says "Rest", a closed set also folds into the trail. Week letters: rest days now ink 2 (6.3:1), done days ink 500, today cobalt 600, no underline (his 8:58 PM; 5.7 light, 6.2 dark; VoiceOver says "today").
6. Fixed slots: exercise name one line, Tess short form on-device past 22 chars ("Incline dumbbell press" fits; longer becomes "Incline DB press"); "Set 1 of 3" fixed width; unit word slot fits "lb" and "kg".
7. Resume: leaving mid-workout keeps it; the Training foot reads "Pick up Push A", Home's Training line and the Live Activity open the same place.
8. Foot holds one action word at a time: Start Push A, Done warming up, Log set N, Skip rest, Finish, Pick up Push A.
9. Private workout: "Private workout" in the name slot, Live Activity and Lock Screen.

## v3 (his 6:31 PM): session wheel and set animation
- The session strip is now a wheel at the bottom (5 rows of 34 pt, focus in the middle row). The lift you're on sits in focus: 22 pt, 600, cobalt, info "now". Neighbours are 16 pt ink 2, then 14 pt ink 3, at weight 400. They are smaller and lighter, never blurred or faded. Done lifts show their trail ("5 5 5"), next lifts "3 by 6", and a part-done lift "5, 2 left".
- Drag or scroll the wheel and it snaps one row at a time on a spring, with one light haptic tick per row. A tap on an unfocused row brings it into focus. A tap on the focused row opens that exercise's page. After 4 s away it springs back to now. VoiceOver reads it as a list; each row says its name and info.
- The exercise page is per lift (muscles, best, last sessions, next time). For a lift not yet done, the foot reads "Do it now": it swaps that lift in, and the one you were on goes next. The brief shows "Dips now, bench press after. Undo" for 10 s.
- Set animation: the strokes drop in one by one on a spring (55 ms apart). Log set inks them left to right with a small hop each (70 ms apart). A green strike draws across. The strokes gather to the centre and become the number (Outfit 44), which arcs to the trail at the right, shrinks to 26, and lands with a small bounce. "Set 1 of 3" rolls its digit to 2. Then the rest starts. Reduce Motion skips all of it: the trail number simply appears.

### v3 reviewer fixes (6:36 PM)
1. The wheel springs back 6 s after the last touch. Each touch resets the timer. It pauses while a finger is down, while VoiceOver focus is on the wheel, and while an exercise page is open.
2. A row you browse to shows ink 600 with no "now". Cobalt and "now" belong only to the lift you're on.
3. Gestures follow 220. Hold and scroll tracks 1:1. A flick moves exactly one row. Tapping another row centres it, and tapping the middle row opens it.
4. Hit areas for the number, the bar and the wheel are separate. Workout mode has no vertical page turn. The wheel ends above the 36 pt foot band, so Tess never covers the trails.
5. Contrast: every wheel row is ink 2 or darker (coordinator ruling, 6:37 PM). Size and weight carry the distance: 22 pt 600, then 16 pt, then 14 pt.
6. Rows stay 34 pt. At AX3 and above the wheel collapses to 3 rows.

## Title fit (his 9:11 PM, all rooms)
Big fixed titles shrink 1 pt at a time until they fit their slot, down to a floor of about 0.75 of the size: exercise name 34 to 26, Kitchen reel 46 to 34, dial focus 44 to 32, wheel focus 28 to 21, note title 28 to 21. Only past the floor does Tess's short form take over, so "Triceps pushdown" now fits whole instead of being cut. This replaces "never shrink" for big titles only. Home's sentence lines (212/216) keep their fixed size. The unit word loses its underline.

## Depth wheel on the landing (his 9:20 PM)
- The plan under the brief is a wheel of warm-up + lifts. The focused row is at the top slot (centre 62 pt into a 206 pt band; one row above may peek): 30 pt Semibold in cobalt (go green for the warm-up), value 15 pt Light.
- Rows step back with distance: 20 pt at one row, 17 at two, 15 at three or more, ink2, Regular; rows near focus are 8 pt further apart. Spacing 38 pt.
- Depth blur (overrides the old "never blur" ruling, for wheels only; coordinator agreed): 0.65 pt at one row, 1.0 pt at two or more, never more than 1 pt so every row stays readable. Reduce Motion, Reduce Transparency and Low Power: size and ink only, no blur.
- Focus: before starting = first row (warm-up). Mid-workout = the lift you're on, value "now" in cobalt. Drag/scroll snaps one row with the spring; tapping a focused lift opens its page; tapping another brings it forward.
- The session wheel in the workout uses the same blur.
- Back from the workout: left edge or Esc. The workout keeps running; the landing reads "Today, going", the brief reads "Bench press, set 2 of 3. 4 lifts to go."
- Today's letter in the week is cobalt Semibold, with no underline. The minutes value has no underline either.

## Action word gestures (his 9:20/9:21 PM, every room)
- The bottom-left action word: tap does it; drag left or right for its other options. No menus.
- The word leans up to 18 pt with the finger. Past 56 pt the text rolls to the option's name in the same slot (UISelectionFeedbackGenerator tick). Release there commits (UIImpactFeedbackGenerator .medium) with a "Thing, what happened. Undo" receipt for 10 s. Short of that it springs back (.soft tick). A side with no option moves 6 pt at most (.rigid tick at the stop).
- Left = stop/remove options; right = again/redo options. VoiceOver: each option is an accessibilityAction on the word.
- Training landing: not started = tap "Start Push A", left "Skip today" (then "Skipped today", word "Start anyway" in ink2). Started = tap "Resume Push A", left "End workout" (saves what was done), right "Start over".
- Workout word: warm-up left "Skip warm up"; lift/rest left "Skip this lift" ("End workout" on the last lift); after a set, right "Same again" logs the last count.
- Other rooms take the same rule in their own rounds (Kitchen: Add a thing, Notes: Write, and so on).

## Set slots, crossed off, dark palette study (his 9:33 PM)
- "3 by 5 at 185" is gone everywhere (landing wheel, session wheel). The value reads as the weight in ink2 Light, a 12 pt gap, then one slot per set holding its reps: "185  5 5 5". A set still to do shows its target in ink3 ExtraLight. A set you did fills in with what you actually did, in ink (cobalt at the focus) Medium: "185  5 5 4". Bodyweight lifts have no weight. VoiceOver reads "3 sets of 5 at 185, done 5, 5, 4".
- A finished lift is crossed off: a 1.5 pt go-green line through its name, still readable, with its slots filled.
- Dark palette study, with light unchanged. He says blue, green and white on black "isn't landing". The board lets him switch between four (On pure black):
  - Soft (recommended): training 8FB0EE, go 8FC9A0, ink E8E3DA, ink2 A49E96.
  - Moonlight: B0C1E6, A8CDB4, DCD7CE, 9C968E.
  - Deep: 5C88D8, 5FA87A, E3DED6, 9E9890.
  - As it was: 3B8CF2, 3BAC56, F1EEE9, ABA6A0.
  - Waiting for his pick before builders change dark tokens.

## Wheel header row (his 9:37 PM)
- Above the first item of each wheel, riding as row -1 and scrolling away: small caps 13 pt, weight 600, tracking .06 em, ink2, with no hairline. Landing: "The plan" + "4 lifts after the warm-up". Workout: "This session" + "N lifts".
- Set marks: Pulse on the board until he picks (study https://claude.ai/artifact/VrW9eWQyzZbeekpdmbWfqA). Builders hold.

## Plate stack, units, thin strikes (his 9:57/9:58 PM; replaces Pulse and all earlier set marks)
- Set mark = PLATE STACK (between his weight stack and bar picks; study https://claude.ai/artifact/Jt6S4ci43D3P5Ut4Ew3bBE):
  - A 3 pt bar stub in ink3 at 1.6 pt, then one plate per set: 8 × 21 pt (9 × 24 at the focus), corner radius 2.2, ink3 outline at 0.9 pt, plates 2.5 pt apart. Three sets take about 32 pt.
  - Inside each plate, one slat per rep, spread evenly. Planned slats are ink3 at 0.7 pt; reps done light up go green at 1.2 pt, from the bottom.
  - A finished set gets a go-green rim at 1.4 pt. A short set leaves its top slats dark (the record of what was done).
  - Logging a rep draws its slat left to right over 320 ms. Reduce Motion: it appears at once.
- The weight carries its unit at half size, for example "185 lb": the numeral is Outfit 300 at 15 pt and "lb" is Figtree 400 at 7.5 pt (renders around 8), ink2, 2 pt after the numeral. "kg" follows the unit setting.
- Strike lines are hairlines: 1 pt (was 1.5). Done lifts use go green; skipped lifts use ink3. Skips are kept and undone with the 10 s Undo.

## Stack and handle, whole sets, set editor (his 10:02-10:06 PM; replaces plate stack)
- Set mark = STACK AND HANDLE (a cable machine per set). Each set is drawn 11 pt wide and 24 pt tall (12 × 28 at the focus), with sets 5 pt apart, from the top down:
  - A grip 5.2 pt wide at 1.6 pt, on a short cable.
  - The cap: the top plate, at 1.4 pt.
  - The rod down the middle, at 0.8 pt, ink3.
  - A floor line, at 1 pt, ink3.
- Each rep is a plate line. Logged reps are lifted up under the cap in go green at 1.15 pt. Reps still to do rest on the floor in ink3 at 0.8 pt, and the bare rod between them is what's left. The cable and cap turn green once a set has reps; the grip turns green when the set is full.
- Sets log WHOLE at the planned reps; nothing logs per rep. After Log set, the brief confirms for 5 s: "Set 1, 5 reps.  −  +". Each tap steps the count (0 to planned + 10), rolls the digit and restarts the 5 s. Then it reads "Set 1, 5 reps, kept." This is a confirmation, not a question.
- Tapping a lift's stack in either wheel opens its lift page (the row tap still works for the focused row).
- The lift page has a sets block above Best:
  - The small-caps label reads "Today's sets" in a workout and "Usual sets" otherwise.
  - Three rows, Sets, Reps and Weight, each "−  value  +". Weight steps 5 lb and shows its unit at half size. Sets can't go below the sets already done.
  - In a workout, a line on the right reads "Also the usual: No/Yes". Yes copies today's numbers to the usual.
  - The wheels and the current lift update at once.
  - The history lines are cut to 2 to make room.

## v2, Oct 23 10:09-10:15 PM (his asks): landing, week, library, scroll numbers, Soft dark

Board r45 v14: https://claude.ai/artifact/PFDdUde9cLtYA1G6Qjrpwp

**Dark palette, picked (10:15 PM): Soft.** On pure black 000000: accent 8FB0EE, go 8FC9A0, ink E8E3DA, ink2 A49E96, ink3 78736D, edge 2A2A2E. Light unchanged.

**Rod (10:09 PM).** In the stack-and-handle mark, the rod runs from the cap only down to the first plate it carries (the lowest lifted plate), or to the top resting plate when none is lifted. It never reaches the floor.

**Numbers scroll; no − + anywhere (10:09 PM).** Drag a number up or down. Each 16 pt moves it one value (weight steps 5), with a selection tick. While a finger is on it, the next and previous values show at 0.42x in ink3 above and below. The scroll wheel and arrow keys work too. A tap opens the dial: a full-room depth wheel of values (46 pt rows, blur by the wheel rule) under a small-caps label, with Done bottom-left. Esc or Done keeps the value in front. Accessibility: an adjustable element with increment and decrement. Used in the 5 s set confirmation (each change restarts the 5 s, and it waits while the dial is open) and in the lift page's Sets, Reps and Weight.

**Structure (10:13 PM).** Training opens on a new landing. Today's workout (the plan wheel) is one level in. Pages slide in from the right; the left edge or Esc goes back.
- Landing, fixed slots, top down:
  - Title "Training", 40 pt.
  - Three stat lines, each 40 pt: a big light number (Outfit 200, 32 pt) and plain words. "3 of 6 this week", "5 weeks in a row on plan", "+10 lb on bench since Oct 1" (the gain in go green; tap opens the lift).
  - The today slot, 118 pt. Not started: "Today" header, "Push A" in the accent at 52 pt, then "about 45 min, 4 lifts. Starts on the rower." Tapping it opens today's workout. In progress: header "In progress" in go green, the clock, and a "Pause" word on the right; then "Push A" and where you are ("Bench press, set 2 of 3."). Tap to go back in. Paused: header "Paused" in ink2, the clock in ink3 and stopped, and the word reads "Go on". Done: "Push A" struck with a 1 px green line. Skipped: the same with an ink3 line.
  - Two doors, a 26 pt word each with one ink2 line under it: "This week" ("3 of 6 done. Pull A tomorrow.") and "Library" ("28 workouts in 6 kinds. New: hill sprints.").
  - Action word: "Start Push A" (drag left: Skip today). Mid-workout it reads "Resume Push A" (drag left: End workout; right: Pause or Go on).
- Today's workout: the old landing, minus the weekday strip. The brief moves up to 270.
- This week: title and date range, a brief slot, then the shared depth wheel, centered on today, with the header "The week / 6 sessions, 1 rest". Each row is a small day word plus the workout. Today stays in the accent even when it's away from focus. Done rows get a 1 px green strike through the name only, with their minutes in green. Rest rows are ink3. The brief follows the row in front: what was done, or what's in it. Tapping today opens it (or the live workout). Action word "Move Push A": tap makes today a rest day and slides the week a day, with Undo 10 s; drag left skips it.
- Library: the shared wheel of kinds (Push 6, Pull 5, Legs 5, Full body 4, Cardio 5, Mobility 3; header "Kinds / 28 workouts"). Tap the kind in front and the wheel refills with its workouts (right column: lifts, or minutes for cardio); left edge or Esc goes back up. The brief names what's inside. Action word: "Build a workout" at the top level, "Do it today" inside a kind (receipt with Undo).
- Shared wheel: one component for plan, session, week, library and dial (`mkWheel` on the board). 40 pt rows, focus row 30 pt, then smaller per step, blur by the wheel rule, header row as row -1, a tick on each new focus.
- Owners: Builder A (Training). The stats and week come from TrainingLedger (Core): sessions this week against the plan, weeks on plan, and the e1RM change on the headline lift.

## v3 Library grid (his 10:38 PM Oct 23)
- Title "Library" in the Training accent. Two axes, so it reads as a matrix, not a list.
- Across: a category row, one at a time on the right with its count (Everything 28, Push 6, Pull, Legs, Full body, Cardio, Mobility). Swipe sideways or up/down, 1:1. No lens (his 10:51 PM), no "N of M". "by kind" on the left is a tap word that rolls the axis to "by length" (under 20, 20-40, 40-60, an hour+) or "by day" (Monday-Sunday).
- Down: a "what" dial (Routines, Exercises, Programs, Goals) with counts for the current cell; focus 40 pt in accent, neighbours 15 pt ink2.
- Brief (2 lines) names what's in the focused item: a routine's first exercises and its days; an exercise's best and the routines it's in; a goal's progress.
- "In here" depth wheel holds that cell's items. Tap focuses; tap the focused one opens it. Routine -> routine page (title, exercises/minutes/days, brief, a wheel of its exercises with their usual sets as stack marks, tap -> exercise page; action word "Do it today"). Push A opens Today's workout. Exercise -> its page.
- Action word per what: Build a routine / Add an exercise / Start a program / Set a goal.
- Data: routines = exercise lists with sets/reps; exercises; programs (weeks of routines); goals (target, now, date).
- Board https://claude.ai/artifact/PFDdUde9cLtYA1G6Qjrpwp (v15).
- v3.1 (his 11:23-11:24 PM): no sort label ("by kind" removed). Up/down on the category row rolls the sort (kinds -> lengths -> days); across moves the category. UNITS EVERYWHERE: every weight shows its unit (lb or kg) at half the number's size, min 10 pt, Figtree 400 (the number keeps Outfit). Applies app-wide: history lines ("185 lb for 5, 5, 4"), bests, week notes, briefs, wheels.
- v3.2 color (his 11:34 PM "a little too monotonic and too much stuff"):
  - The page uses 4 roles: Training blue for titles, today and actions; go green for gains and new things; slate (34506F/A7BCD6) for small-caps labels and the streak number; ink for the rest.
  - Landing: the "Training" title is blue. Stats drop to 2 lines ("5 weeks in a row on plan" with 5 in slate, "+10 lb" in green), because "3 of 6" lives on the This week door. Under This week, "3" and "Pull A" are blue. Under Library, "New: hill sprints" is green. The blocks moved up 40 pt.
  - Inner page titles ("This week", "Library") are blue.
- Home one thing (236 v2.3, his 11:34 PM): a single hard edge runs the full height of the slot, 92 pt from the right. The big, mid and small lines all stop there, so nothing swiped runs under or below the sign. The small line also cuts at whole words.

## v3.3 Library what-colors (board v18, his 11:38 PM "too monotonic")
- Each "what" has its own color, used for the dial focus word, the category count and the focused row: Routines go (8FC9A0 dark / 25803D light, was 2FA24D at 3.02:1), Exercises gold (E2C26A / 8A6A10), Programs slate (A7BCD6 / 34506F), Goals training blue. Title and action word stay blue.
