# Exercise page (an object page)

> **Sweep 16 Oct (item 19):** parts of this sheet are amended by `sweep-19.md` (no dots, one base, the context line). Where they differ, `sweep-19.md` wins.

Every exercise is a class object you can zoom into from its name (in live mode, on Training, in history). This is the generic object page with an exercise's summary on it. Light painterly ground, one screen tall, nothing scrolls except one bounded window. Mockup: `mockups/ExercisePage.dc.html` (Bench press). Data rules follow Product's `workouts.md` (honest e1RM, rep maxes, where records live).

## Top to bottom
| y | Element |
|---|---|
| 58 | **Path** in labels: "EXERCISES  ›  BARBELL LIFTS". Each part is a link one level up the class tree |
| 90 | **Hero:** the name, "Bench press" (hero tier, 56) |
| 156 | **Context line** (21, violet): what it works, in words: "chest, with triceps and front delts" |
| 206 | **Summary:** two numbers side by side at 44 (numeral style): best e1RM "104.5" and best set "85 × 6", each with its label under it ("BEST E1RM, KG", "BEST SET") |
| 292 | **The trend:** a 90-day e1RM line painted as one cobalt brushstroke (4pt, round caps) over a hairline baseline, drawn in over 1.1s. A wet cobalt tip breathes at today. No axes, no gridlines, no chart box |
| 368 | Under the trend in labels: "90 DAYS" on the left, "+6.5 SINCE JULY" in cobalt on the right |
| 424 | **Three sibling views (x):** HISTORY · REP MAXES · MUSCLES in labels, with a painted vermilion carriage (64×4) gliding under the active one (300ms) |
| 470 | **The window:** 196pt tall, bounded, fading at the bottom. Only this scrolls |
| 684 | **Methods:** an ink key "Log a set" (200×56) and "Add to routine" as a text action beside it |
| 762 | **Tess bar** with one forward-looking line: "Next time: 82.5 for 9, then 85." |

## The three views
- **History:** one 52pt row per session: the date (18, secondary), the session's sets as small brushstrokes (one 30×12 stroke per set, cycling vermilion, cobalt, cadmium, sage), and the top set on the right at 21. Each row is a handle back to that workout.
- **Rep maxes:** a 5 × 2 grid, 1RM to 10RM: "5RM" in labels over "87.5" at 24. Under it at 18: "Warm-ups and sets over 12 reps don’t count here."
- **Muscles:** one 56pt row per muscle: a vermilion dab sized by role (30pt primary, 22pt at 70% secondary), the name at 21, and the role in words on the right ("primary", "half a set each"). Each row links to the muscle's page.

## Motion
- Entering: the hero comes in from the right (18pt, blur 4→0, 340ms), the trend paints in, and rows rise in with a 30ms stagger.
- Switching views: the carriage glides, and the new rows rise in (10pt, 300ms).
- A record set in history carries the glint motif once on arrival.
