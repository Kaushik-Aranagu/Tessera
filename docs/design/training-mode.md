# Training in workout mode, routines and fixed days (Design item 44)

**Kaushik's principle, in one line:** the Training page should already be the workout, resting; starting it should feel like the page waking, not a new screen; and he should be able to make his own routines and pin them to days.

From his first review of the build (16 Oct, 11:58 PM PT): training needs routines, fixed days and today's plan in workout mode; the Start workout underline should change. This sheet redraws the TRAINING tab, the Start mark, and adds the Routines page and the days line to `routine-editor.md`. The live workout itself (`workout-v1.md`, `set-block.md`, `live-polish.md`) doesn't change.
- Board: `mockups/training-mode.png` (source `studies/training-mode.html`), Obsidian. Before (the build), Training at rest, the Start tap mid-flight, live mode, the Routines page, a routine with its days.
- Recording: `recordings/training-mode.mp4` (13s). Tap START: the ink line lifts off the word, travels up into the strip and lights the first segment, the first set's guide wakes, Tess's line changes, the word becomes PAUSE; live mode rises on the first exercise. Then a routine's DAYS line: tap it, the week unfolds, pick Mon and Thu, Tess confirms with UNDO.

## Training at rest is the workout at rest
The page uses the live workout's own drawing, so nothing new appears when he starts.

| y | Element |
|---|---|
| 0 | **The strip**: one segment per exercise, its length its sets, 3pt, unlit (ink 14%). It's the live workout's process seam (`workout-v1.md`, "The strip") before anything has run |
| 78 | The tabs, TRAINING under the ink line |
| 138 | Context line in `context`: "today, 5 exercises, about 55 min". On a rest day: "rest day, Push A tomorrow" |
| 172 | Title 44: the routine's name ("Push A"). Tap opens the routine (`routine-editor.md`) |
| 236 | **The Start mark**: `START PUSH A`, Label 16/700, with the ink line under it (full) |
| 300 + 72k | **The plan as lanes**: each exercise at Body 21/500, its target at the right in Label 16/600 `inkSecondary` ("82.5 × 8"), and under the name its sets as strokes at 48pt pitch: dashed guides at 22%, exactly as the live page draws future sets. Five rows end at 660 |
| 688 | The plan line: `PUSH PULL LEGS, ROLLS ON` in `inkSecondary`, and `ROUTINES` at the right as an ink action |
| 779 | Tess: "Bench press is ready for 82.5 today." (the build's line; AI architecture may reword) |

- No "Plan →" word beside the context line; the plan is the line at 688 and the Routines page.
- Six or more exercises: rows keep their 72pt and the page scrolls under the fixed Start mark; the strip and the first five stay in view at rest.
- **Trained today:** the hero reads "Push A done", the strokes under each exercise are the logged sets in their pigments (dried to `restTint`), the Start mark reads `PULL A TOMORROW` with no line (a label, not an action), and the plan line stays.
- **Paused:** the Start mark reads `RESUME PUSH A` with the line filled to the sets done, as on Home (`home-first-review.md`). The strip keeps its lit segments.

## The Start mark (replaces the paint stroke)
The build's "Start workout" is a vermilion paint stroke word (`PaintKey`, the 19pt stroke from `no-buttons.md`). It's the one thick underline left on the app's first screens, and he called it out. It becomes the ink-line label word that Home uses, and the line is what changes state:

| State | The word | The line |
|---|---|---|
| Ready | `START PUSH A` | Full ink |
| Tapped (0 to 520ms) | Fades to 35% | **Lifts off the word** and travels up to the strip on the house curve, narrowing to the first segment's length, wetting from ink to `live` with its halo. It lands as the first segment, lit. Haptic: `.impact(.soft, 0.6)` at the tap |
| Running (520ms on) | `PAUSE`, with a short ink line | The strip is the line now: the lit segment grows with each logged set, in `live` |
| Paused | `RESUME PUSH A` | Filled to the sets done, dry ink, over the 22% track |
| Done | `PULL A TOMORROW` (a label, 72%) | None. The strip stays lit, dried |
| Done, on the eve of his rest weekday | `REST DAY TOMORROW` (QA's #337 note, 16 Oct); after a missed-day roll the label names the routine the roll lands on | None |

- At the landing, the first exercise's first guide wakes from 22% to 90% and breathes (the live page's current-set guide), and Tess's line changes: "Push A running. Bench press first."
- **Then live mode rises** (480ms, house curve) with the first exercise's name and its strokes matched from the plan row to the lane (`ZoomSource`), so the plan row becomes the set block. The rest of the plan sinks away at 0.96 and fades.
- Reduce Motion: the line crossfades out and the segment crossfades in; live mode crossfades.
- Live mode's layout is unchanged. Leaving it (swipe down, or the finish) returns to this page in its running or done state.

## Routines
One tap from the plan line (`ROUTINES`), or ‹ TRAINING back.
- **Title 44 "Routines"**, context line "Push Pull Legs, rolls on" (or "fixed days").
- **One row per routine** at 62pt: the name at Body 21/500, under it "5 exercises, about 55 min" at 16 `inkSecondary`. On fixed days the second line reads the days first: "Mon, Thu · 5 exercises, about 55 min". Tap opens the routine.
- **"Make a routine"** at Body 21, ink 70%, after the last row. Tap: it becomes the cobalt writing line with a caret (the pattern from `routine-editor.md`, "Add an exercise"); he writes the name, and the new routine opens empty with "Add an exercise" ready. Tess: "Push C made." with UNDO.
- **The plan's mode** at 668: `ROLLS ON` and `FIXED DAYS` as two value words, the current one in ink, the other at 38%. Tap the other to switch; Tess says "Push Pull Legs on fixed days." with UNDO. No flood, no sheet.
- Hold a row to reorder the cycle (the routine editor's hold-and-drag, on y); swipe left to drop a routine (`DROP` rises in `liveInk`; Tess "Push C dropped." with UNDO). A routine that was trained is never deleted from history, only from the cycle.

## A routine's days (added to `routine-editor.md`)
Under the context line, before EXERCISES:
- **`DAYS`** label, then one line at Body 21/600. Rolling plan: "rolls on" at `inkSecondary`, not tappable. Fixed days: the chosen days as words, "Mon, Thu".
- **Tap the line** (on a fixed-days plan) and the seven day words unfold in place at 49pt pitch, Mon to Sun, each 40ms after the last, chosen days in ink and the rest at 38%. The exercises below make room (10pt, 320ms).
- **Tap a day** to pick it: it wets in `tess` with the settle spring (1 to 1.08 to 1) and `.selection`, then dries to ink over 900ms. Tap again to unpick (it dries to 38%). Tess: "Push A on Mondays." then "Push A on Mondays and Thursdays." with UNDO.
- A day another routine already has: it picks here, and that routine loses it. Tess says so: "Thursday was Pull A's. Push A has it now." with UNDO. One routine per day, never two.
- Tap away or leave: the words fold back to "Mon, Thu".
- Everything else on the routine page stays as `routine-editor.md` has it (hold to reorder, swipe to drop, value words open drums, tap a name to change it, Add an exercise).

## What fixed days mean for Today (Product to confirm; this is the default)
- A fixed day shows that routine on Training and Home, as today's rolling plan does.
- **A missed fixed day doesn't roll on.** The week shows it faint (the `rest-dab.md` past mark) and the next fixed day comes as planned. The rolling plan keeps Product's rule (missed day rolls on).
- A day with no routine is a rest day: "Rest day" on Now, the next routine one tap away (decisions, 3:37 PM PT).
- The rest weekday question (`restWeekday`) applies only to the rolling plan.

## For Builder A
- `TrainingPage.swift`: `WorkoutPlan` and `RoutinePlan` become one page drawn as above (strip, lanes with `LiveSetStrokes` guides, the Start mark). `PaintKey` goes from this page; the mark is the Home start key with a `state` (ready, lifting, running, paused, done).
- The lift: the ink line is a `Shape` that animates its frame from under the word to the strip's first segment (matched geometry on the `InkLine`), fill `ink` to `live`, with the halo on dark looks only.
- Routines page: new, under `Features/Plans/`. The mode words write the plan's `scheduleMode` (rolling, fixed); Core owns the field and the week (`WeekView.swift`).
- `RoutineEditor.swift`: the DAYS line, writing `fixedWeekdays` on the routine through a Core action with an op-log row (UNDO).
- The week on Plans (`plans.md`) reads fixed days as planned days.

## Owners
- **Builder A:** Training page, the Start mark, Routines, the DAYS line.
- **Core:** `scheduleMode`, `fixedWeekdays`, the week with fixed days, the missed-fixed-day rule.
- **Product:** confirm the missed-fixed-day default and the one-routine-per-day rule.

## Addendum, Oct 16: skip and rest today, by voice (Research 122, V10)

Research's words are kept, with one default added for what Home does after he says it.

| He says | Rolling plan | Fixed days |
|---|---|---|
| "skip legs today" | "Legs A waits for tomorrow." | "Legs A waits for next Wednesday." |
| "rest day today" | "Rest today. Legs A is next." | "Rest today. Legs A is next Wednesday." |
| "Push A tomorrow" | "Pull A is tomorrow. Push A is after it." | "Pull A is tomorrow. Push A is Thursday's." |
| "rest day Sunday" / "make Sunday my rest day" | "Sunday is your rest day." + **UNDO** (a write) | the same |

- **A skip is a day mark, not a plan write.** Saying "skip legs today" or "rest day today" marks today as rested, so Home agrees with her line: the hero reads "Rest today", the context line "Legs A waits for tomorrow" (or "Legs A waits for next Wednesday"), and the Start key is gone until 04:00. Without the mark, Home would keep offering START LEGS A under a line that says it waits, so the two must move together. The mark is undoable for 10 s (**UNDO** under her line: "Legs A, back on today."), then it stands; the 04:00 turn clears it. The Training page's Start line shows the same rest state. Product to confirm; this is the default.
- **"Push A tomorrow" writes nothing,** as Research says: the plan decides the day, and her line only says where it falls. No UNDO.
- **In a live workout** "skip" stays the workout's own word: "Skip is on the workout screen." (decided Oct 15, 8:58 PM PT).
- **Owners:** Core (the day mark, `WeekFacts` counts it as rest, not a miss), Builder A (Home and the Training page in the rested state), Product (confirm the mark).
