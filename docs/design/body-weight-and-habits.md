# Body weight and habits (build sheet, M3 slices 1 and 2)

Just enough to build the two screens on Core's engine in `docs/research/m3-1-2-brief.md` (`BodyWeight`, `Habit`, `HabitCheckIn`, `BodyWeightLedger`, `HabitLedger`, and the grammar rows). It deepens `m3-steers.md` §1 and `habits.md`. Where they differ, this sheet wins: the hero is the trend, not a 7-day average, and the count reads "of 5", the target, not "of 7". Every line of copy below is exact and uses the brief's fixture values. Drawn to `no-buttons.md`.

Recording: `recordings/m3-surfaces.mp4` (source `studies/m3-surfaces.html`):
1. The body weight page paints its trend.
2. A bare "82.4" written to Tess lands as a ghost that waits. Tapping it keeps it: the stroke steps up by its capped amount and the numeral rolls.
3. The habits week on Thu 15 Oct, with a Read check-in.

## 1 · Body weight
**Entry:** the Training page gets a label word **BODY WEIGHT** in its link line, so the page isn't DEBUG-only. "bw trend" asked of Tess opens it too. Its back word is **‹ TRAINING**.

| y | Element |
|---|---|
| 58 | ‹ TRAINING |
| 100 | **Context line** (21/400, context colour): the latest entry and the weekly rate. "78.1 yesterday, 0.3 kg less than last week". Before 7 days of entries, the rate is left out: "78.1 yesterday" |
| 136 | **The trend** as the hero numeral: Numeral 80 Light, tabular, "78.2", with "kg" at 21 on its baseline. One decimal, always the trend, never the raw weight |
| 230 | **TREND** in labels |
| 270 to 530 | **The stroke:** the last 90 days of the trend as one painted sage stroke (5pt, rough edge, `PaintedTrend`). The y range fits the trend plus 1 kg each side; there are no axes, gridlines or goal line. Each entry is a small sage dab (11×9, 70%) at its weight. An entry outside the range (the 87.4 typo) sits pinned at the top edge at 45%, with its value in labels beside it. It's still never red |
| 548 | The first day in labels on the left ("SEP 3") and **TODAY** on the right |
| 590 | **The change line** (21/400, context colour): "1.2 kg less since 3 September", from the stroke's first point. Gaining reads "0.8 kg more since 3 September", and no change reads "The same as on 3 September" |

**Copy rules:** past tense and digits, kg once per line. Change is "less" or "more", never "lost", "gained", "down", "up", "good" or "bad". There's no goal, no BMI, no colour for direction, and no praise.

### Logging (the weigh-in ghost row)
- **"82.4" with nothing running** (a bare number from 30 to 250): Tess's Write closes and the page (or Now, if he's elsewhere) shows a **ghost that waits**. A wet cobalt dab drops above today on the stroke, and the ghost line sits under the change line at Title 34, 45%: "Body weight **82.4** kg?". The number is a value word in 600. Under it in labels: "4.2 KG ABOVE TREND", shown only when the entry is more than 3 kg off the trend. Tess says "Tap to keep it." There is **no drying line and no 2s commit**: it waits.
  - **Tap the ghost:** it inks, the dab dries from cobalt to sage, and the stroke re-draws its last stretch to the new trend. The step is capped at 2 kg, so 82.4 moves the trend from 78.2 to only 78.4. The numeral rolls, and the context line swaps to "82.4 this morning, 4.2 above trend". Tess says "82.4 kg, 4.2 kg above trend." with **UNDO**. `.impact(.light)`.
  - **Tap the value word** to open the weight dial (`WeightDial`, 0.1 kg detents, starting on the ghost's value) and fix a typo before keeping.
  - **Swipe the ghost away:** nothing is written and Tess says nothing.
- **"weighed 82.4", "82.4 kg" or "bw 82.4":** these are clear, so they commit straight away with the usual 2s drying line. Tess says "Body weight 82.4 kg." with **UNDO**, adding ", 4.2 kg above trend" only when it's more than 3 kg off.
- **A second entry the same day** replaces the first. Tess says "Body weight now 78.5 kg." and UNDO puts the old value back.
- **In a workout,** "82.4" or "82.4 kg" is the next set's weight ("82.4 × 8" as the set ghost), never body weight. Only "bw 82.4" logs body weight mid-workout.
- **The living moment:** today's dab drops onto the stroke (fall 20pt, settle spring, 420ms), and the stroke's last stretch draws to it (500ms, house curve).

## 2 · Habits, x of the target
**Entry:** the Today page's foot line gains the word **Habits** (Body 21/600, `HomeLinkLine`), and a habit's name anywhere zooms in. The back word is **‹ TODAY**. The page keeps `habits.md`'s layout: hero "This week", context line "Thursday, three days to go", and one block per habit 196pt apart from y 226.

**On 15 Oct with the fixtures:**
| Habit | Name line | Count (right) | Under the name | Week row | Under the row |
|---|---|---|---|---|---|
| Read (5 a week, manual) | "Read" at 34 | "**2** of 5" | none | full dabs on M and W; T is today, in ink | none (met in 0 of the last 2 weeks, so nothing shows) |
| Train (3 a week, rule) | "Train" at 34 | "**1** of 3" | "COUNTS WHEN A WORKOUT FINISHES" in labels | a full dab on T, from Tuesday's workout | "Met in 1 of the last 3 weeks." at 21/400, 55% |

- **The count** is the habit's target, never 7: "**3** of 5". The number is 600 ink and rolls when it changes.
- **The history line** reads `HabitLedger.lastWeeks(3)` and shows only when at least one week was met: "Met in 1 of the last 3 weeks." Paused weeks are left out of the count, so Read reads "of the last 2". There are no streaks, no "best week", and nothing at all when the count is 0.
- **Dab colour** comes from the habit's class colour, not one colour per habit. A manual habit uses planning (cadmium); a habit counted by workouts uses training; one counted by cooks uses health (sage).
- **A paused week:** the label under the name reads "PAUSED THIS WEEK", every dab is faint (14%), and the count reads "paused" in place of "2 of 5". A check-in in a paused week still paints its dab.

### The copy, every case
| Moment | Tess says (cobalt, beside the soul) | UNDO |
|---|---|---|
| Tap today's dab, or "habit read", "✓ read", "read", "read 20 pages", "meditated" (for a habit called Meditate) | "Read, 3 of 5 this week." | yes |
| The check-in that reaches the target | "Read done for the week." (the stroke paints behind the dabs, per `habits.md`) | the check-in's own |
| A second check-in the same day | "Read is already in for today." (nothing new is counted) | no |
| A finished workout counts for Train | "Push day A counted for Train." | yes, the count only |
| Undo of a workout's finish | "Train, back to 1 of 3." | no |
| Hold the count to pause the week | "Read paused this week." | yes |
| A habit name Tess doesn't know ("habit sing") | nothing: it falls through to a task | |

- **Holding the count** (0.7s, a label-word hold) pauses or resumes this week. It's the only pause control, and it's rare enough to sit behind a hold.
- **A rule-counted dab**, tapped, says "Push day A, Tue 18:20" and zooms to the workout.

### Never
Streaks, flames, chains, "best", "missed", "only", red, rings on missed days, percentages, or a history chart.

## Owners
| Part | Where | Owner |
|---|---|---|
| Classes, actions, ledgers, the grammar rows (ghost that waits for a bare number, explicit prefixes, habit names) | `TesseraCore`, `TesseraTess` | Core |
| Body weight page, its ghost and the BODY WEIGHT link word | `Features/BodyWeight/`, `TrainingPage` | Builder A |
| Habits page and the Habits link word | `Features/Habits/`, `HomeLinkLine` on Today | Builder B |
