# Spec: Workouts v1 (live mode, set logging, PRs, plans)

*Product lead, 2026-10-15. Builds on `v1-features.md` and `spatial-interaction.md`, and adopts ideas from `../research/fitness-and-workouts.md`. Kaushik confirmed the overnight defaults on 2026-10-15 (see `morning-questions.md`): kg, Push / Pull / Legs × 2, 20 kg bar with 1.25 kg plates and 2 kg dumbbell steps, plans roll on after a missed day, 6-hour auto-finish, equipment as a trait. Smaller items still marked **(default)** are product calls.*

## 0. Goal and success measure

Kaushik logs every gym session in Tessera for two weeks without opening another app. Each planned set takes **one hold, about 2 seconds**, to log. Nothing is ever lost.

## 1. Objects (what Core engine models)

**Exercise catalog.** Follows `../research/exercise-catalog.md`:
- **Movement pattern is the inheritance spine:** HorizontalPush > BenchPress family, VerticalPull, Hinge, and so on.
- **Variants are their own Exercise objects** linked by `variantOf`, with their own history and PRs. Paused, tempo, belt and straps are set tags, not new exercises.
- **A family subclass** exists only when 3 or more variants share a swap pool and a progression rule.
- **Muscle links** carry a role: primary 1.0, secondary 0.5, with an optional contribution override.
- **Equipment is a trait** (Barbell, Dumbbell, Cable, Machine…), not a class: BenchPress sits under HorizontalPush. Decided by Kaushik, 2026-10-15. The trait brings plate math, load increment, bar weight and e1RM rules.

| Class | Parent / traits | Key fields | Notes |
|---|---|---|---|
| `Exercise` | StrengthExercise subtree · Trackable | aliases, muscles (role, contribution), equipment, mechanic, laterality, logType, loadIncrement, e1rmEligible, variantOf, angle/grip/stance, repRange, rest, progressionRule, source/license | Defaults inherit: compound rest 150 s, isolation 90 s |
| `Muscle` | Thing · Measurable | group (e.g. Shoulders), weeklySetTarget (default 10–20) | 18 muscles; computed: sets this week (fractional) |
| `Equipment` | Thing | bar weight, plates available (pairs), smallest increment, dumbbell set | Drives dial detents |
| `Gym` | Thing | equipment list | v1 has one gym, seeded with a 20 kg bar, 1.25 kg smallest plate and dumbbells in 2 kg steps |
| `Routine` | Thing | ordered `Slot`s | e.g. Push Day A |
| `Slot` | Thing | exercise, setScheme (sets × rep range, optional RPE target), progressionRule (overrides exercise), rest | A routine position; the rule lives here |
| `Plan` | Thing · Schedulable | cycle of routines, start date, length in weeks (optional) | Week and month views read from it |
| `Workout` | Thing · Schedulable · Timed | routine (optional), entries, note | Its open state is a `Process` (see `whats-running.md`) |
| `ExerciseEntry` | Thing | exercise, slot (optional), sets | Created from a Slot or ad hoc |
| `Set` | Thing | weight (kg canonical), reps, rpe?, kind (warm-up / working / drop / failure), tags, loggedAt, source (hold / dial / lock screen / Tess) | Computed: e1RM, volume |
| `Record` | projection, not hand-edited | exercise, kind, value, set, date | Recomputed from sets |

All writes go through typed actions with an op log (`v1-features.md`). Records, weekly muscle sets and trends are projections rebuilt when any set changes, so editing an old set fixes everything downstream.

## 2. Live mode

**Entering.** From the workout row on Now, from the routine's page, or by Tess ("start push day"). The workout rises as a cover (foreground process); the rest of Tessera dims. Starting an unplanned workout picks the next routine in the plan **(default)**, with a swipe to choose another.

**Layout (one screen, no scrolling page).**
- **x: exercises.** The current exercise fills the screen. A thin exercise strip along the top seam shows done / current / remaining as machined segments, not dots. Swipe sideways to move between exercises; order can be changed by dragging in the strip.
- **y: sets.** The current set sits at eye level, large. Done sets stack above it (compressed, with their stamp), upcoming sets below (ghosted with targets).
- **z: depth.** Tap the exercise name for the Exercise page; tap a muscle there for the Muscle page. Coming back returns to the exact set.

**The current set.**
- Opens **prefilled with the target**: the progression rule's suggestion, else last time's weight and reps for this slot, else the scheme's lower rep bound with an empty weight.
- **Hold to log** commits exactly what's shown. Most sets need nothing else.
- Change weight with the **dial** (detents on loadable values for the gym's equipment; plate math beside it, per side), reps with the **drum** (last time's reps as a ghost), RPE with the stop-slider (hidden until pulled, optional).
- Set kind defaults to working; warm-ups are added with a pull above the first set **(default: no auto warm-ups in v1)**.

**After logging.**
- The set seats into the stack (Stamp moment, firm haptic).
- **Rest starts on the same dial**, draining; the Live Activity mirrors it. Rest length comes from the slot, else the exercise, else 2 min. +15 s and skip are drags on the dial, not buttons.
- At rest end: a soft haptic and the next set rises to eye level, already prefilled.
- After the last set of an exercise, the strip advances to the next exercise automatically after rest **(default)**.

**Top-set check.** If the first working set's RPE is 2 or more above the slot target, Tess offers one quiet line inside the set area: "Drop to 77.5 for the rest?" One tap accepts. No other prompts or surveys between sets.

**Swap within the pattern.** Pull down on the exercise name to see alternatives: first the same family, then the same movement pattern, ranked by primary-muscle overlap and then by equipment the gym has. Picking one keeps the slot, scheme and rule for this session only **(default)**, and converts the load where a mapping exists (marked as an estimate).

**Voice (P1).** Hold the Bar: "same", "8", "80 for 7 at 8", "drop to 70 for 10", "swap to dumbbell press", "skip". A deterministic grammar first, the on-device model as fallback. Each shows as a ghost set that commits on its own after 2 s, with Undo.

**Leaving and resuming.**
- Every set is saved the moment it's logged. Killing the app loses nothing.
- Swiping the cover down minimises the workout: it keeps running as a process (lit seam at the top, What's running row on Now, Live Activity).
- Background for longer than the rest time plus 10 minutes suspends the workout. After 6 hours suspended it is wrapped up with the sets already logged ("Saved Push Day, 3 of 5 exercises"). Resuming lands on the set at eye level with the dial preset (see `whats-running.md`).

**Finishing.** Hold the finish control at the end of the last exercise (or Tess: "done"). The session stack compresses into one Workout object and drops into today's history on Now. A one-line summary appears in Tess's voice (`../research/tess-voice.md`): "6 exercises, 22 sets. New best: 85 × 5." A half session still counts as a session.

## 3. Lock screen (Live Activity, P0)

- Shows: current exercise, next set (weight × reps), draining rest time.
- **Done** logs the next set exactly as prefilled (same action as hold to log, source = lock screen).
- **+15 s** and **Skip rest** as secondary actions.
- Dynamic Island compact: rest time and set number. Expanded: the same as the Lock Screen.
- Works without unlocking; everything is offline.

## 4. Personal records

**Kinds tracked per exercise:** best e1RM; best weight at each rep count from 1 to 10 (rep maxes); best single-session volume.

**Honest e1RM.** Epley for 1–10 reps only. When RPE is logged, use effective reps = reps + (10 − RPE), so 5 @ RPE 8 counts as a 7-rep effort. Sets above 12 reps and warm-ups are not used for e1RM or rep maxes, and the exercise page says so.

**During the set.** When the prefilled or dialled weight and reps would beat a record, a quiet hint appears beside the set: "beats 5RM". No hint otherwise.

**When it happens.** The one bigger celebration: a light sweep across the machined edge plus Tess's bloom, and a firm haptic. At most one celebration per exercise per session, even if several kinds are beaten.

**Where records live.** On the Exercise page summary strip (best e1RM, best set, 90-day trend), as a rep-max table one level deeper, and as handles back to the exact set and workout.

## 5. Plans: day, week, month

**Day (P0).**
- A routine is an ordered list of slots. Editing is direct: drag to reorder, pull a slot open to change its scheme or rule, swipe to remove, add by typing an exercise name into the Bar.
- Today's routine shows on Now as the workout row ("Push Day A · 0 of 6") and in What's running once started.

**Progression (P1, defaults to on for strength slots).**
- Double progression: `dp(+2.5 kg, 8, 12)`. When every working set hits the top of the rep range, the next session's target adds the increment and drops to the bottom of the range.
- The increment snaps to the gym's smallest loadable step (dumbbells use the next dumbbell).
- "Why this weight" is one tap deep on the set.
- Rules inherit as defaults by equipment (barbell +2.5 kg, dumbbell +2 kg per hand) and can be overridden on the exercise or slot.

**Week (P1).**
- A plan is a repeating pattern of routines over the week (e.g. Push / Pull / Legs / rest / Upper / Lower / rest).
- The week view is one screen: days across (x), and under each day its routine and state (planned, done, moved).
- Missing a day doesn't create debt. The plan simply continues with the next routine (decided: rolling sequence, not fixed weekdays).
- **Weekly sets per muscle:** fractional counting (primary 1, secondary 0.5) against the muscle's target range. Shown as a compact strip of muscles with a fill level. Below range is neutral, never red.

**Month (P1).**
- A consistency heatmap of the month: one tile per day, filled by the session's volume relative to typical.
- Counts, never streaks: "Session 6 of 14 this month" (planned count from the plan).
- Tapping a day zooms into that day's workout.

## 6. Exercise page (P0)

Generic object page with this summary strip: best e1RM, best set, 90-day e1RM trend (a sparkline drawn as a machined groove, not a chart card). Below: rep maxes, history (sessions as compressed set stacks), muscles with their roles, the routines that use it, and methods (Log a set, Add to routine, Edit).

## 7. Seed content

v1 ships with the 69-exercise seed from `../research/exercise-catalog.md`, written in our own words with no third-party images, and Kaushik's plan: Push / Pull / Legs twice a week. Units default to kg.

## 8. Out of v1

Apple Watch logging, cardio and conditioning classes, supersets and circuits (P2; the model allows them as grouped entries), auto rep detection, social anything, programs from a store.
