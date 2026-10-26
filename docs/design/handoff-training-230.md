# Builder A handoff: Training landing, workout wheel, set animation (230)

Board https://claude.ai/artifact/PFDdUde9cLtYA1G6Qjrpwp (r45). Sheet training-flow-230.md in this folder wins on any doubt. Files: Features/Landing (Training landing), Features/Workout/WorkoutModeView.swift, LiveSetMarks.swift, SetMarkModel.swift, ExerciseStrip.swift (becomes the wheel), ExerciseSwaps.swift, Features/Exercise (exercise page).

## Part 1: colors, rep strokes, set animation (no new data)
- Colors: cobalt 0B62AE light / 3B8CF2 dark (name, unit word, today). Go green 2FA24D / 3BAC56 for large text and strokes only: warm-up, rest countdown, the set strike, "Done warming up", "Skip rest". Green is never the only signal.
- Rep strokes replace the ink ring D set mark and every 229 brush circle. One thin vertical stroke per target rep, ink2. They are a count, never a gauge.
- Log a set: the foot "Log set N" logs the full target. To log fewer, drag across the strokes (VoiceOver adjustable, 0 to target, 1 rep steps); the foot then reads "Log set 2, 4 reps".
- Animation in order:
  1. Strokes drop in one by one on a spring, 55 ms apart.
  2. Logging inks them left to right with a small hop each, 70 ms apart.
  3. A green strike draws across.
  4. The strokes gather to the centre and become the rep number (Outfit 200, 44 pt).
  5. It arcs to the trail on the right, shrinks to 26 pt, and lands with a small bounce. The trail is Outfit 300 26 pt ("5 5").
  6. "Set 1 of 3" rolls its digit to 2, then rest starts.
- Reduce Motion: the trail number simply appears, with no arc.
- Undo 10 s on a logged set: "Set 2, logged. Undo".

## Part 2: workout top band and rest
- The top band is only the current lift.
  - Name 34 pt 600 cobalt in a one-line slot; Tess short form past 22 chars ("Incline DB press"). A tap opens the exercise page.
  - "Set 1 of 3" in a fixed width, then a "was 185" span in ink2 that appears 2 s after a weight change.
  - Weight Outfit 200 84 pt, with the unit word (22 pt 600 cobalt) in a flex row beside it.
- Weight: drag the number up or down in 5 lb steps (2.5 kg). Tap or swipe the unit to switch: the digits roll, and the receipt reads "185 lb loads as 85 kg."
- The number, the bar and the wheel each have their own hit area. No vertical page turn in workout mode.
- Rest: "Rest 1:30" in green, then "Set 2 is next". The foot reads "Skip rest". The end of rest updates the Live Activity and posts a local notification; sound follows the silent switch.
- Warm-up: "Rower, easy" green, 8:00 countdown, "Keep it easy, about 22 strokes a minute. Bench is next.", foot "Done warming up".
- Done: "Push A", time, "warm-up and 4 lifts", "Bench held at 185. Next Push A is Friday.", foot "Finish" (Undo 10 s).
- The foot always holds one word: Start Push A, Done warming up, Log set N, Skip rest, Finish, Pick up Push A.

## Part 3: session wheel and exercise page
- The wheel sits at the bottom above the 36 pt foot band. 5 rows of 34 pt; the focus is the middle row.
  - The lift you're on: 22 pt 600 cobalt, with info "now".
  - Neighbours: 16 pt ink2, then 14 pt ink2, weight 400.
  - Every row is ink2 or darker; size and weight carry distance. Never blurred or faded.
  - Info: done lifts show their trail ("5 5 5"), next lifts "3 by 6", part-done "5, 2 left".
  - A browsed row (not the current lift) shows ink 600 with no "now"; cobalt and "now" are only for the current lift.
- Gestures (220): hold and scroll tracks 1:1; a flick moves exactly one row; it snaps on a spring with one light haptic per row. A tap on another row centres it; a tap on the focused row opens its exercise page.
- Spring-back to now 6 s after the last touch. Each touch resets the timer. It pauses while a finger is down, while VoiceOver focus is on the wheel, and while an exercise page is open.
- VoiceOver reads it as a list (name plus info). At AX3+ it has 3 rows.
- The exercise page slides in from the right; back by the left edge.
  - Content: "Works chest, shoulders and triceps", the name, a Gym visual GIF loop (still frame under Reduce Motion or Low Power), best, the last three sessions, next time.
  - For a lift not done yet, the foot reads "Do it now": it swaps that lift in, and the current lift goes next. Receipt "Dips now, bench press after. Undo" (10 s).

## Part 4: landing (not started) and accept checks
- Headline: "Today", then "Push A" in cobalt.
- "about 45 min, 4 lifts": a tap on the minutes steps 25, 35, 45, All.
- "Gym or Home" knob.
- Week as day letters: done ink 500, today cobalt 600 with no underline (VoiceOver says "today"), rest days ink2.
- Brief: "Starts with 8 min on the rower. Bench opens at 185." ("8 min" in green).
- Plan rows: "Warm up, row 8 min", then each lift "3 by 5 at 185". Lifts that don't fit the minutes or can't be done at home go ink2 at weight 300. Each row opens its exercise page.
- "Bench best 205, three weeks ago." opens Bench.
- Foot "Start Push A". The landing never jumps into the workout; no weight or bar shows here.
- Resume: leaving mid-workout keeps it. The foot reads "Pick up Push A", and Home and the Live Activity open the same place.
- Private workout: "Private workout" in the name slot, Live Activity and Lock Screen.

Accept checks:
1. No ring, circle or ink D remains anywhere in workout mode.
2. Strokes ink left to right at 70 ms and land as a trail number.
3. Reduce Motion: no movement, only the trail number appearing.
4. A flick moves one wheel row; a vertical drag on the number never moves the wheel.
5. Spring-back waits 6 s and pauses on an open exercise page.
6. Green only on large text and strokes, always paired with words.
7. Every foot shows one word, and Tess never covers the trail.
8. Undo restores a set, a swap and Done within 10 s.
9. AX3 wheel 3 rows; a name past 22 chars uses the short form.
