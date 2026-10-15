# Habits: x of 7 (M3 slice 2, steer)

For the builder who takes the habits screen. The engine is Core's (`Habit`, counted by query, no streaks). This is drawn to `no-buttons.md`. Recording: `recordings/habits.mp4` (source `studies/habits.html`).

## The page (TODAY › HABITS, or z from a habit's name anywhere)
- **Header:**
  - Hero: "This week" at 56.
  - Context line in words: "Thursday, three days to go".
  - Weeks start Monday. After a gap, only this week shows: there is no history row and no "best week".
- **One block per habit, 168pt apart from y 208:**
  - The name at Title 34.
  - The count on the right as a sentence: "**3** of 5" at 21.
  - A rule habit gets one label line under the name: "COUNTS WHEN A WORKOUT FINISHES".
- **The week row:** seven painted dabs (36×32, 50pt apart from x 40) in the habit's colour, with the day letters at 16 under them.
  - **A done day** is a full dab (90%).
  - **Any other day** is a faint dab (14%).
  - Future days sit at 55% of that.
  - Today's letter is in ink.
  - **Missed days are never red, never ringed and never counted against.** They just stay faint.
- **Arrival:** the dabs pop in down the page (spring, 28ms per day, 90ms per habit).

## Check in: tap today's dab
- **Paint drops into the slot:** it falls 26pt, lands wet at ×1.25 with a 2pt blur, then settles dry at ×1 (460ms).
- **Haptic:** `.impact(medium, 0.8)`, the same as a task finish.
- **The count rolls up** (380ms, house curve).
- **Tess says it beside her soul:** "Read, 3 of 7." with UNDO.
- **Tapping a done day** clears it, as the same drop played in reverse.
- Earlier days this week can be tapped too.

## The week is done
- **When a check-in reaches the target:**
  - A brushstroke in the habit's colour paints **through the marks behind the dabs**, from Monday to the day it was reached (6pt at 55%, 700ms).
  - The "of 5" turns the habit's colour.
  - Tess says "Stretch done for the week." with no UNDO line (the check-in's own Undo still works).
- **There is no confetti and no `.success`.** The stroke is the reward, and it resets on Monday.

## Counted by a rule
- **When a finished object matches the rule** (a workout for Train, a cook for Cook):
  - Its mark **flies in from where it finished** (from the top when it happened elsewhere, 700ms, `cubic-bezier(.5,0,.2,1)`), lands with a small swell, and the count rolls.
  - Tess says "Push Day A counted for Train." with UNDO, which undoes only the count, not the workout.
- **Tapping a rule-counted dab** says why ("Push Day A, 6:40 pm") and links to it (z).

## Accessibility and Reduce Motion
- **Each day is a toggle:** "Thursday, Read, not done".
- **The habit block** reads "Read, 3 of 7 this week".
- **Reduce Motion:**
  - Dabs fade in place instead of dropping.
  - The completion stroke appears whole.
  - Counts cross-fade.
