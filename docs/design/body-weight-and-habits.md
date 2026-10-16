# Body weight and habits (build sheet, M3 slices 1 and 2)

Just enough to build the two screens on Core's engine in `docs/research/m3-1-2-brief.md` (`BodyWeight`, `Habit`, `HabitCheckIn`, `BodyWeightLedger`, `HabitLedger`, and the grammar rows). It deepens `m3-steers.md` §1 and `habits.md`. Where they differ, this sheet wins: the hero is the trend, not a 7-day average, and the count reads "of 5", the target, not "of 7". Every Tess line and empty state is in Research's `docs/research/m3-lines.md` (#204), and that file wins on copy. This sheet places the lines and gives them their motion. Drawn to `no-buttons.md`.

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
| 590 | **The change line** (21/400, context colour): "1.2 kg less since Sep 3", from the stroke's first point. Gaining reads "0.8 kg more since Sep 3", and no change reads "The same as on Sep 3". With one entry it reads "The trend starts here." |

**Copy rules:** past tense and digits, kg once per line. Change is "less" or "more", never "lost", "gained", "down", "up", "good" or "bad". There's no goal, no BMI, no colour for direction, and no praise.

### Logging (the weigh-in ghost row)
- **"82.4" with nothing running** (a bare number from 30 to 250): Tess's Write closes and the page (or Now, if he's elsewhere) shows a **ghost that waits**. A wet cobalt dab drops above today on the stroke, and the ghost line sits under the change line at Title 34, 45%: "Body weight **82.4** kg?". The number is a value word in 600. Under it in labels: "4.2 KG ABOVE TREND", shown only when the entry is more than 3 kg off the trend. Tess says "Tap to keep it." There is **no drying line and no 2s commit**: it waits.
  - **Tap the ghost:** it inks, the dab dries from cobalt to sage, and the stroke re-draws its last stretch to the new trend. The step is capped at 2 kg, so 82.4 moves the trend from 78.2 to only 78.4. The numeral rolls, and the context line swaps to "82.4 this morning, 4.2 above trend". Tess says "Body weight logged. 82.4 kg, 4.2 above trend." with **UNDO** (4s, "Body weight taken back."). Without the note it says "Body weight logged. 82.4 kg." `.impact(.light)`.
  - **Tap the value word** to open the weight dial (`WeightDial`, 0.1 kg detents, starting on the ghost's value) and fix a typo before keeping.
  - **Swipe the ghost away:** nothing is written and Tess says nothing.
- **"weighed 82.4", "82.4 kg" or "bw 82.4":** these are clear, so they commit straight away with the usual 2s drying line. Tess says "Body weight logged. 82.4 kg." with **UNDO**, adding ", 4.2 above trend" only when it's more than 3 kg off. The unit is said once per line.
- **A second entry the same day** replaces the first. Tess says "Body weight now 78.5 kg." and UNDO puts the old value back.
- **In a workout (the 7:24 PM S701 call):** a bare number never becomes body weight, and it never writes the next set by itself.
  - Only "bw 82.4" logs body weight mid-workout.
  - A bare number counts as reps only from 1 to 50, and only when it isn't close to the last weight.
  - Anything else ("82.4", or "8" right after a set at 8 kg) goes to the model.
  - What comes back is a **set ghost that waits**, never one that dries by itself: "**82.5** × 8?" at Title 34, 45%, in the set slot.
  - A spoken weight snaps to the nearest loadable weight, ties going lighter. When it snapped, a label sits under the ghost: "SNAPPED FROM 82.4".
  - Tap to keep it. Then the line reads "Set 4 logged. 82.5 × 8." with the set's own UNDO.
  - Swipe the ghost away to drop it.
  - The value word opens the weight reel at the ghost's value.
- **The living moment:** today's dab drops onto the stroke (fall 20pt, settle spring, 420ms), and the stroke's last stretch draws to it (500ms, house curve).

## 2 · Habits, x of the target
**Entry:** the Today page's foot line gains the word **Habits** (Body 21/600, `HomeLinkLine`), and a habit's name anywhere zooms in. The back word is **‹ TODAY**. The page keeps `habits.md`'s layout: hero "This week", context line "Thursday, 3 days to go" ("Monday, a new week", "Sunday, the last day"), and one block per habit 196pt apart from y 226.

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
| A finished workout counts for Train | "Push A counted for Train, 2 of 3." | the finish's own |
| Undo of a workout's finish | "Push A taken back. Train 1 of 3." | no |
| Hold the count to pause the week | "Read paused this week." | yes |
| A habit name Tess doesn't know ("habit sing") | nothing: it falls through to a task | |

- **Holding the count** (0.7s, a label-word hold) pauses or resumes this week. It's the only pause control, and it's rare enough to sit behind a hold.
- **A rule-counted dab**, tapped, says "Push A, Tuesday 6:20 pm" and zooms to the workout.

### Never
Streaks, flames, chains, "best", "missed", "only", red, rings on missed days, percentages, or a history chart.

## 2a · Page order and the rule label word (Design item 18)
Research's `habits-first-use.md` gaps 4 and 5. Board `mockups/habits-page-order.png` and recording `recordings/habits-page-order.mp4` (source `studies/habits-page-order.html`).

**Page order.** Habits sit in the order he made them, oldest first:
- **Rule habits aren't lifted.** Review lifts them, but Review is a summary and this page is his list.
- A paused habit stays in its place.
- A new habit rises in at the bottom (10pt, 360ms).
- Nothing re-sorts by count or progress.

**The context line** follows Research's plural rule: "Thursday, 3 days to go", "Saturday, 1 day to go", "Sunday, the last day", "Monday, a new week".

**The rule label word.** Under every name there is one label word, Label 16/700 in `inkSecondary`, 50pt under the name's top. It reads **COUNTS BY HAND**, **COUNTS WHEN A WORKOUT FINISHES** or **COUNTS WHEN A COOK FINISHES**.
- **A tap cycles it** in that order, with the value-word swap (blur 3pt out 120ms, then in on the settle spring) and `.selection`.
- **Each step commits.** Tess says it once: "Train now counts workouts." / "Train now counts cooks." / "Train counts by hand again." It comes with a **4s UNDO** (`liveInk`, under her line), which answers "Train rule taken back."
- **This week recounts at once.** Under a rule, this week's finished workouts (or cooks) paint in on their days in the class pigment: they drop wet 26pt at ×1.25 and dry to the rest tint, 120ms apart. The count rolls like a value word (0 → 2). Hand check-ins already made stay. Taking the rule back fades only the days the rule added (220ms), and the count rolls back.
- **The dab colour follows the rule:** planning (cadmium) by hand, training for workouts, health for cooks.
- **The count stays `ink`** at rest (G8). Colour arrives only in the moment the target is met, as the brushstroke paints behind the week.
- **VoiceOver:** "Counts by hand. Double-tap to count workouts instead." (V-rule).

## Owners
| Part | Where | Owner |
|---|---|---|
| Classes, actions, ledgers, the grammar rows (ghost that waits for a bare number, explicit prefixes, habit names) | `TesseraCore`, `TesseraTess` | Core |
| Body weight page, its ghost and the BODY WEIGHT link word | `Features/BodyWeight/`, `TrainingPage` | Builder A |
| Habits page and the Habits link word | `Features/Habits/`, `HomeLinkLine` on Today | Builder B |

## Empty states, firsts and VoiceOver (from `m3-lines.md`)
- **Body weight with no entries:**
  - The context line reads "No weigh-ins yet."
  - There's no hero, no TREND label and no stroke. The writing placeholder is "bw 78.4".
- **One entry:**
  - The hero shows that weight.
  - One sage dab sits above TODAY, with no stroke.
  - Tess says "Body weight logged. 78.1 kg, the trend starts here."
- **The second weigh-in** says the trend once: "Body weight logged. 78.3 kg, trend 78.1."
- **A gap of more than 30 days:**
  - The stroke breaks.
  - The lines count from the reseed day, with "The trend starts again here."
- **Habits with no habits:**
  - "No habits yet." sits under the hero.
  - The placeholder is "new habit read 5 a week".
  - Creating one says "Read added, 5 times a week."
- **Past the target:** it reads "**6** of 5", with no badge and no colour change.
- **Deleting a habit:**
  - Tess says "Read deleted." with a 10s UNDO.
  - The UNDO says "Read is back."
- **VoiceOver:**
  - Use `m3-lines.md` §6 as written. The stroke gets an `AXChartDescriptor`.
  - The ghost has Keep, Change weight and Dismiss actions.
  - The count has Pause this week and Resume this week actions.
