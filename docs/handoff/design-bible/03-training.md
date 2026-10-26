# 03 Training

Training is the first domain and one of the two rooms Kaushik uses most (with Kitchen). His Oct 23 4:09 PM verdict was that he "doesn't like it much yet" and wants it more fun so he uses it more. The current spec is **sheet 230 (training-flow-230.md), through v3.3, board v20**, plus the app-wide color roles in **sheet 241**. Board: https://claude.ai/artifact/PFDdUde9cLtYA1G6Qjrpwp (r45). Builder handoff: handoff-training-230.md, and in the repo docs/handoff/specs/builder-a-training-230.md (written before v3.3/v20; where they differ, 230's later sections and 241 win). Owner: Builder A. Code branch `ios/training-230` (head 82bc8a29) holds the wheel, scrolling numbers, action word, stack marks, workout screen, landing v2, This week and Library. It compiles but had never been viewed on a simulator as of Oct 24.

Status: v20 (split colors, what-colors) has not been reviewed by Kaushik yet. Everything below is the latest ruling unless marked "unconfirmed".

## 1. Palette

Four roles per page (241): Training blue for the title and action word; go green for done and gains; gold for best and new; slate for small-caps labels, planned and private. Ink and ink2 carry text; ink3 is for rest and disabled.

| Token | Light (paper F7F5F1) | Dark "Soft" (pure black 000000) |
|---|---|---|
| training (accent) | 0B62AE | 8FB0EE |
| go | 25803D (was 2FA24D, 3.0:1, too weak) | 8FC9A0 |
| ink | theme ink | E8E3DA |
| ink2 | theme ink2 | A49E96 |
| ink3 | theme ink3 | 78736D |
| edge | theme edge | 2A2A2E |
| gold | 7E6A1E | D9C27A (moved from 8A6A10 / E2C26A) |
| slate | 34506F | A7BCD6 |
| Push split (clay) | 9C4B2C | E2A07F |
| Pull split (teal) | 1E6E77 | 84C3C9 |
| Legs split (plum) | 8A4570 | D69CC0 |

- Soft dark was picked at 10:15 PM Oct 23 ("fine for now"; a better combination may still come up; Moonlight B0C1E6 / A8CDB4 / DCD7CE / 9C968E was his second choice). Not picked: Deep (5C88D8 / 5FA87A) and "As it was" (3B8CF2 / 3BAC56). Light values did not change.
- Go green is never the only signal: rest also says "Rest", and a done lift is also struck.
- Big type rule (v20): the 2-4 biggest words never share a color. The title "Training" and the action word are blue. A routine's name takes its split (Push A clay, Pull A teal). The streak number is gold. "+10 lb" is green. Session counts are ink.
- Library "whats": Routines go green, Exercises gold, Programs slate, Goals training blue.
- This week: today is blue (v20: today's row takes its split color), done days are green with a green strike, planned days are slate.
- Rejected: crimson / pink Training (A8203F, CC4478; his 4:27 PM Oct 23); 2-color pages ("too monotonic"); an all-blue big type ("all of it in blue, looking the same").

## 2. Training landing (room landing, not started)

For: his stats, today's workout, This week and the Library. It never jumps into the workout.

Top down, in fixed slots (230 v2, moved up 40 pt in v3.2):
1. Title "Training", 40 pt, blue.
2. Two stat lines, 40 pt each: a big light number (Outfit 200, 32 pt) plus plain words. "5 weeks in a row on plan" (5 in gold per v20; slate in v3.2) and "+10 lb on bench since Oct 1" (gain in green; a tap opens the lift). "3 of 6 this week" moved to the This week door.
3. Today slot, 118 pt. Not started: small "Today" header, "Push A" at 52 pt in its split color, then "about 45 min, 4 lifts. Starts on the rower." A tap opens Today's workout (the plan page).
4. Two doors, a 26 pt word each with one ink2 line under it: "This week" ("3 of 6 done. Pull A tomorrow.", with 3 blue and Pull A in teal) and "Library" ("28 workouts in 6 kinds. New: hill sprints.", with "New: hill sprints" in green or gold; 241 says new = gold, v3.2 says green: unconfirmed).
5. Foot: action word bottom-left, Tess bottom-right.

Action word: not started = tap "Start Push A"; drag left "Skip today" (then "Skipped today", word becomes "Start anyway" in ink2). Started = "Resume Push A"; drag left "End workout" (saves what was done); drag right "Pause" / "Go on" (v2) or "Start over" (earlier v3): unconfirmed which right option wins; v2 is later.

Data: TrainingLedger (Core): sessions this week against the plan, weeks on plan, e1RM change on the headline lift. Use sample values until Core's stats API lands.

Landing open problem: Kaushik later rejected summary-plus-door landings for rooms in general (11:52 PM) and sheets 240 and 242. The word wall is what he liked (12:43-12:53 AM, see the landings section of the bible). Training landing v2 is the one landing builders were allowed to keep building; expect it to be redone in the word-wall direction. Unconfirmed.

### In-progress strip (the today slot mid-workout)
- In progress: header "In progress" in go green, the running clock, a "Pause" word on the right; then "Push A" and where you are ("Bench press, set 2 of 3.", or "Bench press, set 2 of 3. 4 lifts to go."). A tap goes back in.
- Paused: header "Paused" in ink2, the clock in ink3 and stopped, the word reads "Go on".
- Done: "Push A" struck with a 1 px go-green line. Skipped: the same with an ink3 line.
- Resume rule: leaving mid-workout keeps it. Home's Training line, the Live Activity and this slot all open the same place. 6 h auto-finish (product decision).

## 3. Today's workout (the plan page, depth wheel)

For: what today holds before you start. This is the old 230 landing moved one level in, minus the weekday strip. Slides in from the right; the left edge (0-24 pt) or Esc goes back.

- Headline: "Today", "Push A" (split color), "about 45 min, 4 lifts". Tapping the minutes rolls 25, 35, 45, All; lifts outside the time go ink2/ink3 and never disappear; receipt "Cut to 35 min." with Undo.
- Knob word "Gym or Home" at the top right of the headline, current choice in ink 600. At Home, lifts swap to home versions; a lift with no swap reads ink3 with "not at home". Receipt "3 swapped for home." with Undo.
- Brief (moves up to 270 pt): "Starts with 8 min on the rower. Bench opens at 185 lb." ("8 min" in green).
- The plan wheel (the shared depth wheel): header row as row -1, small caps 13 pt 600, tracking .06 em, ink2, no hairline: "The plan" + "4 lifts after the warm-up". Rows: "Warm up, row 8 min" first, then each lift.
  - Focus row sits at the top slot (centre 62 pt into a 206 pt band; one row above may peek): name 30 pt Semibold in the accent (go green for the warm-up), value 15 pt Light.
  - Value = weight in ink2 Light with its unit, a 12 pt gap, then one slot per set holding reps: "185 lb  5 5 5". To-do sets: target in ink3 ExtraLight. Done sets: actual reps in ink Medium (accent at the focus): "185 lb  5 5 4". Bodyweight lifts have no weight. VoiceOver: "3 sets of 5 at 185, done 5, 5, 4". The old "3 by 5 at 185" is gone everywhere.
  - Plus each lift's stack-and-handle mark (section 5). Tapping a stack opens the lift page.
  - Before starting, focus = the warm-up. Mid-workout, focus = the current lift with value "now" in blue.
  - A finished lift is crossed off with a 1 pt go-green hairline through its name (still readable). Skipped lifts: 1 pt ink3 line, undoable for 10 s.
- "Bench best 205 lb, three weeks ago." opens the Bench exercise page.
- Swipe a lift row right: "Bench press, done."; left: "Bench press, later." (Not now). Undo 10 s. Rows 44 pt hit area.
- Foot: "Start Push A". No working weight or bar drawing on this page.

## 4. Shared depth wheel (used for plan, session, week, library and the number dial)

One component (`mkWheel` on the board). Rows 38-40 pt; rows near focus 8 pt further apart. Focus 30 pt (landing/plan), then 20 pt at one row, 17 at two, 15 at three or more, ink2 Regular. Depth blur: 0.65 pt at one row, 1.0 pt at two or more, never on the focus, never over 1 pt (Notes later allowed up to 1.8 pt on its dial: Training stays at 1 pt, unconfirmed). Reduce Motion, Reduce Transparency, Low Power: size and ink only, no blur.

Gestures (sheet 220): hold-and-scroll tracks 1:1; a flick moves exactly one row; snaps on a spring; one light haptic tick per new focus. Tap another row = bring it to focus; tap the focused row = open it. VoiceOver reads it as a list. Title fit: a big fixed title shrinks 1 pt at a time to about 0.75 of its size (wheel focus 28 to 21, exercise name 34 to 26) before Tess's short form takes over.

## 5. Live workout mode

Starts only from the foot word "Start Push A". No vertical page turn in workout mode. The number, the bar and the wheel have separate hit areas.

### Warm-up
"Rower, easy" in green, 8:00 countdown, "Keep it easy, about 22 strokes a minute. Bench is next." Foot "Done warming up" (drag left: "Skip warm up"). A routine can start with cardio (his 6:06 PM).

### Top band (the current lift only)
- Name 34 pt 600 in the accent, one-line slot, fitted 34 to 26 pt, Tess short form past that ("Incline DB press"). A tap opens the exercise page.
- "Set 1 of 3" in fixed width (see open questions: conflicts with the no "N of M" rule). "was 185 lb" in ink2 appears 2 s after a weight change.
- Weight in Outfit 200, 84 pt (80 in early 230), unit word beside it at about half size in the accent, no underline. The bar drawing on the right (the barbell is the object, not a gauge).
- Weight: drag the number up/down or drag the bar (sideways or vertical), 5 lb steps (2.5 kg); plates slide on and off the sleeve.
- Unit: tap or swipe the unit word; digits roll; plates reload. kg shows what the bar actually holds, rounded to 2.5 kg (lb x 0.4536): receipt "185 lb loads as 85 kg." with Undo. kg plates 25, 20, 15, 10, 5, 2.5, 1.25 on a 20 kg bar; 10 and up in the accent. A hung fraction shows only for .5. Kaushik's own defaults: kg, 20 kg bar, 1.25 kg plates, 2 kg dumbbell steps (product decisions).

### Set mark: stack and handle (picked 10:02-10:09 PM Oct 23)
One cable-machine drawing per set, 11 x 24 pt (12 x 28 at focus), sets 5 pt apart. Top down: a grip 5.2 pt wide at 1.6 pt on a short cable; the cap (top plate) at 1.4 pt; the rod at 0.8 pt ink3; a floor line at 1 pt ink3. Each rep is a plate line: logged reps lift up under the cap in go green at 1.15 pt; reps still to do rest on the floor in ink3 at 0.8 pt. The rod runs from the cap only down to the lowest lifted plate (or the top resting plate when none is lifted), never to the floor. Cable and cap turn green once a set has reps; the grip turns green when the set is full. Tapping a stack in either wheel opens the lift page.

Rejected set marks, never re-offer: brush circles / liquid ink drops (108, 229), static ink ring D, rep strokes with fold-to-trail (230 Part 1), tally marks, "5 5 5" as the mark, Pulse, Climb, Waves, Arrows, the plate stack (9:57 PM, replaced 5 min later), set guides and brushstrokes (training-mode, live-workout, set-block).

### Logging a set
- Sets log WHOLE at the planned reps; nothing logs per rep. Foot "Log set N" (drag right after a set: "Same again" logs the last count; drag left: "Skip this lift", or "End workout" on the last lift).
- After logging, the brief confirms for 5 s: "Set 1, 5 reps." with the count as a scrolling number (each change restarts the 5 s; it waits while the dial is open). Then "Set 1, 5 reps, kept." It is a confirmation, never a question (no yes/no asks in a live workout). Range 0 to planned + 10.
- Undo 10 s: "Set 2, logged. Undo". Also on Done and on a swap.
- Set motion (from 230 v3, unconfirmed how much survives the stack mark): marks drop in one by one on a spring 55 ms apart; logging inks left to right 70 ms apart; the set number rolls its digit; rest starts. Reduce Motion: the end state appears in one step.

### Session wheel (bottom of the workout)
5 rows of 34 pt, focus in the middle, ending above the 36 pt foot band so Tess never covers it. Header "This session" + "N lifts". Current lift: 22 pt 600 accent, info "now". Neighbours 16 pt then 14 pt, weight 400, ink2 or darker (size and weight carry distance), with depth blur. A browsed row shows ink 600, no "now". Info: done lifts show their set slots, next lifts their usual sets, part-done "5, 2 left". Springs back to now 6 s after the last touch; pauses while a finger is down, while VoiceOver is on it, and while an exercise page is open. AX3 and above: 3 rows.

### Rest
"Rest 1:30" in go green, then "Set 2 is next". Foot "Skip rest". Rest end fires the Live Activity update and a local notification; sound follows the silent switch. No countdown lines, no rings, no horizon line. Rest-dab (dry horizon stroke) is superseded.

### Done
"Push A", the time, "warm-up and 4 lifts", "Bench held at 185 lb. Next Push A is Friday." Foot "Finish" (Undo 10 s).

### Foot words, one at a time
Start Push A, Done warming up, Log set N, Skip rest, Finish, Pick up Push A / Resume Push A, Do it now. Action word drag: leans up to 18 pt with the finger; past 56 pt the text rolls to the option (selection tick); release commits (.medium impact) with a 10 s Undo receipt; short of that it springs back (.soft); a side with no option moves 6 pt max (.rigid). Left = stop/remove, right = again/redo. VoiceOver: each option is an accessibilityAction.

## 6. Numbers: scroll, tap for the wheel

Numbers never step with − or + (10:09 PM, app-wide). Drag a number up or down; every 16 pt is one value (weight steps 5 lb / 2.5 kg) with a selection tick. While a finger is on it, the next and previous values show at 0.42x in ink3 above and below. Scroll wheel and arrow keys work too. A tap opens the dial: a full-room depth wheel of values (46 pt rows, wheel blur) under a small-caps label, with "Done" bottom-left; Esc or Done keeps the value in front. Accessibility: adjustable element, increment and decrement. Used in the 5 s set confirmation and the lift page's Sets, Reps and Weight. The "Set 1, 5 reps. − +" and "− value +" rows in 230 are replaced by this.

## 7. Exercise (lift) page

Slides in from the right; back by the left edge. Top down: "Works chest, shoulders and triceps" (no Oxford comma), the name, the exercise picture loop, a sets block, Best, the last sessions (cut to 2 lines), next time.
- Sets block: small-caps label "Today's sets" in a workout, "Usual sets" otherwise; Sets, Reps, Weight as scrolling numbers (weight with unit at half size). Sets can't go below sets already done. In a workout, a right-side line "Also the usual: No/Yes"; Yes copies today's numbers to the usual. Wheels and the current lift update at once.
- For a lift not done yet, the foot reads "Do it now": it swaps that lift in and the current one goes next. Receipt "Dips now, bench press after. Undo" (10 s).
- History lines carry units: "185 lb for 5, 5, 4".

### Exercise pictures (free GIFs only)
- Gym visual GIF loops first (71 files, kept in ~/Library/Developer/TesseraBuilds/exercise-gifs, git-ignored, copied at export, never committed, never upscaled past their ~180 px source, never sent to Claude). Fallback: Workout Guide line art (Everkinetic, CC BY-SA 4.0), recolored to the theme ink as a template image, three frames played 1-2-3-2 at 0.55 s each.
- Reduce Motion and Low Power: a still middle frame. VoiceOver hides the picture. Sibling motions show "Similar motion" in ink2. A GIF that can't take the ink color sits on a flat ink-tinted ground with a hard edge, not a card.
- Credits on the About page at the foot of Settings (109): a build never ships without them.
- Never: our own drawn figures, paid videos (offered Oct 19 at about $452, he chose free only), a second picture style on one screen, pictures on Home or in the live workout's top band.

## 8. Bests (PRs)

The word is "best", never "record" or "PR". Pushing the weight past the best turns the best line into "Bench 215 lb today would be a new best." with one 3 pt rise and settle (0.5 s). Best and new wear gold (241). A best shows in the best line, not in the set mark. No confetti, no flare, no glint sweep. The custom best haptic from live-polish (two transients 90 ms apart, then a 320 ms swell, instead of the log haptic) is not restated in 230: unconfirmed.

## 9. This week

Title "This week" (blue) and the date range, a brief slot, then the shared wheel centered on today, header "The week / 6 sessions, 1 rest". Weeks start Monday. Each row: a small day word plus the workout. Today stays colored even away from focus. Done rows: 1 px green strike through the name only, minutes in green. Rest rows ink3. The brief follows the row in front (what was done, or what's in it). Tapping today opens it or the live workout. Action word "Move Push A": tap makes today a rest day and slides the week a day (Undo 10 s); drag left skips it.

Plan rules (product decisions): PPL x2 at 6 a week; a rolling plan rolls missed days; fixed days don't roll; one routine per weekday, newer pick wins; skipping or "rest day today" is a day mark, not a plan write; a planned timed workout ends a rest day.

## 10. Library

Title "Library" in blue. A matrix, not a list (v3, 10:38 PM):
- Across: a category row, one at a time on the right with its count (Everything 28, Push 6, Pull, Legs, Full body, Cardio, Mobility). Swipe sideways 1:1; up/down on that row rolls the sort (kinds, lengths: under 20, 20-40, 40-60, an hour+; days: Monday-Sunday). No sort label, no lens, no "N of M".
- Down: a "what" dial (Routines green, Exercises gold, Programs slate, Goals blue) with counts for the cell; focus 40 pt in the what's color, neighbours 15 pt ink2. The what color also goes on the category count and the focused row.
- Brief (2 lines) names what's in the focused item (a routine's first exercises and days; an exercise's best and routines; a goal's progress).
- "In here" depth wheel holds the cell's items; tap focuses, tap the focused one opens it. Routine page: title, exercises/minutes/days, brief, a wheel of its exercises with usual sets as stack marks; action word "Do it today". Push A opens Today's workout.
- Action word per what: Build a routine / Add an exercise / Start a program / Set a goal.
- Data: routines = exercise lists with sets/reps; exercises; programs = weeks of routines; goals = target, now, date.

## 11. Units rule (app-wide, 11:24 PM Oct 23)

Every weight shows lb or kg at about half the number's size, min 10 pt, Figtree 400, ink2, 2 pt after the numeral; the number stays Outfit. Applies to history lines, bests, week notes, briefs and wheels. A bare "N x M" never writes kg.

## 12. Workout Live Activity and Watch

- Live Activity behavior (current): shows the rest countdown and the current set; rest end updates it plus a local notification; tapping it opens the same place as Resume. A private workout shows only "Private workout" and the timer on the Lock Screen and Island.
- Its look (live-activity.md, Oct 15: Inter Tight, "Cobalt sky" washes, cream numerals, horizon line, red tick) predates the current rules (no Inter Tight, no countdown lines, no washes). It needs a redraw in Figtree/Outfit and the Soft palette: unconfirmed, no current sheet.
- Watch: a watchOS target is allowed after Builder A's signing check (CLAUDE.md, Oct 19); scripts/test.sh now gates "watch". The specs (watch-set-logging-105: one screen, weight and reps on the Crown, Done line, rest as in the Smart Stack; watch-quick-wins W1/W2) are spec-only, not okayed by Kaushik, and use the old Cobalt sky look. Their structure can carry; their look and the "SET 4 of 5" counter cannot.

## 13. Privacy and naming

- Workout names are made on the device, never by Claude. Workouts never go to Claude, even under lab mode (his 10:25 PM).
- A private workout reads "Private workout" in the name slot, on Home, in the Live Activity and on the Lock Screen; a private routine draws a plain outline, nothing lit. Body values, calories and health data never reach widgets, backups or logs.
- Voice in the gym (voice-gym, "80 for 7", "same") stays as a capability on-device; its soul-bloom look is superseded by the current Tess.

## 14. Rejected, one line each

- Crimson/pink accent and the 210 pixel lintel (pixels are Home-only).
- Landing that jumps straight into the workout; the not-started weight and bar on the landing.
- Weekday strip at the top of the plan page.
- Steppers (− +) anywhere.
- "3 by 5 at 185" text form.
- Brush circles, ink rings, rep strokes, plate stack and all other set marks listed in section 5.
- Countdown lines, horizon strokes, rings as gauges, the rest dab.
- Month heatmap plans page (plans.md) and the list-first Training reorg (107).
- Glass lens on swipers, "N of M" pagination, sort labels.
- Confetti or "record" wording on a best.
- Paid exercise videos and self-drawn figures.
