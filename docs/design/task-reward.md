# Made and done (Design item 38)

**Kaushik's principle, in one line:** making a task and finishing one should take one easy gesture and feel like a small win, with motion, colour that arrives only in the moment, and a haptic on every beat. It's over in under a second and never in the way.

This sheet redraws both moments across Tess capture, Home's Next and the Day log. It also sets the haptics map for the whole app and makes the call on the set block's reps control. It builds on what's on master (`HomeQueue.swift` QueueRow, `BottomChrome` commit, `day-log-v1.md` DL58) and changes only the moments, not the layout.
- Board: `mockups/task-reward.png` (source `studies/task-reward.html`), Porcelain. It has six phones (made in three beats, done in two, the Day log line), then the haptic score for six moments.
- Recording: `recordings/task-reward.mp4` (16s). He writes "Call the bank at 4" and the ghost dries. His words fly into Next and dry to ink, and the day stroke lights 16:00. UNDO goes. He swipes the row right, the strike runs out, and a fleck of it reaches the day stroke at now. The tip blooms, the row folds, and Tess says "Call the bank done." Then the Day log opens and the line lands with its wash. The caption names each haptic as it fires.

## The rules
1. **His words are the row.** What he wrote or said never disappears and reappears somewhere else. The words travel to where they now live.
2. **Colour only moves.** A made task arrives wet in Tess's cobalt and dries to ink. A done task's strike is wet in the row's pigment (`context` for a task, `live` for a workout) and dries to ink at 45%. Nothing rests in colour, and there are no dots, marks or counts left behind.
3. **One haptic per beat, one source per moment.** When a surface plays a moment's haptic, nothing else plays one for it (see "Changes to what's built").
4. **Never in the way.** Nothing waits on the animation. A tap or a new phrase during a flight finishes it at once, and the next gesture works straight away. The row is gone in under a second.

## Made (Tess capture, Write or Speak)
| t (ms) | What moves | Haptic |
|---|---|---|
| ghost | The ghost sits on the writing line in `inkSecondary`, with the cobalt line draining (2s for Write, 3s for voice, as built) | none |
| 0 | **The ghost dries.** The surface folds (220ms) and the page comes forward (320ms). The task's own words ("Call the bank", the title Core parsed, not the whole sentence) stay and lift, turning wet cobalt in 160ms. The rows below the slot stay receded at 50% | none |
| 0–420 | **They fly to their sorted slot in Next** on an arc (house curve, 420ms), swelling to 1.04 at the top of the arc. The rows from the slot down part by 46pt on the settle spring | none |
| 420 | **They land** with a 2pt settle. The rows below come forward (300ms) | `.impact(flexibility: .soft, intensity: 0.6)` |
| 540–1240 | **The words dry from cobalt to ink, left to right** (700ms, house curve). The time ("16:00") rises out of a 6pt blur in `inkSecondary`. On the day stroke, the dashed guide at the task's time lights in cobalt for a moment and dries back over 1.4s | none |
| 420 | **Tess's line:** "Call the bank, today 4 pm." with UNDO (Research's capture pattern, "Dentist, Thursday 3 pm.") | none |

- **When the slot is below the 5-row cut** (`day-seams.md`, Plan my day rule), the words fly to the "2 MORE" word, and its count swaps like a value word (blur crossfade, 220ms). The haptic is the same.
- **When Next isn't on screen** (any other page), the words fly into the soul, which takes them with one beat (1 to 1.1 to 1, settle spring). The same soft haptic plays when they reach it, and Tess says where it went.
- **More than one task** ("Two tasks added. One had no date."): the titles fly one after another, 60ms apart, and there's one haptic for the last landing.
- **Plan kept** (Plan my day): the kept rows dry top to bottom, 60ms apart, with one soft haptic for the plan.
- **Siri and Shortcuts** write with no flight. The app isn't open, and nothing replays on the next open.
- **UNDO** ("Call the bank taken back."): the row blurs out (200ms) and the rows below close up, with `.decrease`.

## Done (a row in Next)
The gesture is the build's: swipe right, armed at 140pt. The strike follows the finger as an ink-line lens (`ink-line.md`, 2pt), wet in the row's pigment, and the time fades over the first 40pt.
| t (ms) | What moves | Haptic |
|---|---|---|
| armed (140pt) | **The strike runs itself out** to the end of the name (160ms, house curve), so the gesture meets him halfway. Pulling back under 140 retracts it (220ms ease-out, as built) | `.selection` |
| 0 (let go) | **The name dries to ink at 45%** (500ms) and the strike dries with it (700ms). **A fleck of the strike** (a 12pt lens in the pigment) leaves its end and arcs up to the day stroke's tip at now (520ms, house curve), shrinking from 1.2 to 0.7 | **the done pattern** (below) |
| 520 | **The tip blooms**: a pigment wash (radius 30pt) grows and fades over 900ms, and the travelled stroke brightens from 0.6 to 0.92 and back. The soul brightens once (1 to 1.12, settle spring, saturation up, no haptic of its own) | `.impact(flexibility: .soft, intensity: 0.4)` |
| 80–400 | **The row folds** (height to 0, 320ms, house curve) and the rows below rise on the settle spring. The op writes as the fold starts, not 1.3s later as now | none |
| 80 | **Tess's line:** "Call the bank done." with UNDO (Research M55's form) | none |

- **The done pattern** is three rising taps, played with Core Haptics (`CHHapticPattern`, three `.hapticTransient` events). If the engine can't start, `.success` plays instead.
  | t | Intensity | Sharpness |
  |---|---|---|
  | 0ms | 0.45 | 0.35 |
  | 60ms | 0.65 | 0.45 |
  | 130ms | 1.0 | 0.6 |
- **The last row of the day:** when the row leaves Next empty, the whole travelled stroke blooms instead of only the tip, and nothing else changes. Whatever Home shows with an empty Next stays as `empty-states.md` and `today-on-home.md` have it.
- **Done from anywhere else gets the same pattern:** the hero's finish, "call the bank done" said or written (the strike draws on the row if it's on screen, and if not, the fleck leaves the soul), the notification's Done (on the next open, the line only), a habit check-in, the last set of a workout finished, and the shop finished in Groceries.
- **UNDO** ("Call the bank taken back."): the row unfolds (320ms), then the strike retracts right to left (220ms) and the name comes back to ink, with `.decrease`.
- **Not now** (swipe left) stays as built: TOMORROW or NEXT WEEK, `.impact(weight: .light)`, with no fleck and no bloom. Moving a task isn't finishing it.

## The Day log
- **Lines he hasn't seen land when the page opens.** Each one rises out of a 6pt blur (320ms, house curve), with a wash of its pigment behind the text that dries over 2.8s. A done task's wash is `context`, a Tess write's is cobalt (DL58 as built), and a set's is `live`.
- It plays once per line. The page remembers when he last read it, and only lines after that wash. Lines that arrive while he's on the page land the same way (DL54 and DL58 stand).
- **No haptic.** Nothing gets one on appear.

## Reduce Motion
- There's no flight, fleck or fold slide. The words crossfade at their slot (200ms), the tip blooms in place, and the row fades out.
- Dry phases are instant.
- **The haptics stay**, beat for beat, so the reward is still felt.

## The haptics map (the whole app)
**One vocabulary, in one place.** A `Haptic` enum next to `MotionPolicy` in `DesignSystem` names each moment below and maps it to a `SensoryFeedback`, or to the done pattern. Views use `.tesseraFeedback(.done, trigger:)` and never a raw `.sensoryFeedback`, so the map is the code.

| Moment | Haptic | Where (owner) |
|---|---|---|
| **Made**: a task, note, grocery, recipe or habit lands | `.impact(flexibility: .soft, intensity: 0.6)`, once | BottomChrome commit, Groceries landed, PasteRecipe saved, Plan kept (B) |
| **Done**: a task, the hero, a habit check-in, a finished workout, the shop finished | the done pattern (`.success` fallback) | QueueRow, hero, habits, Groceries (B); workout finish (A) |
| The fleck reaches now | `.impact(flexibility: .soft, intensity: 0.4)` | QueueRow (B) |
| A swipe is armed (done or not now) | `.selection` | QueueRow (B, as built) |
| A row is picked up (press) | `.impact(weight: .light, intensity: 0.5)` | QueueRow (B, as built) |
| Not now (the row moves) | `.impact(weight: .light)` | QueueRow (B, as built) |
| **UNDO**, any | `.decrease` | BottomChrome, workout, Live Activity Undo (A, B; as built) |
| An ink word that writes, or an ask answered | `.selection` | everywhere (one-ask.md) |
| Tess opens (the surface) | `.selection` | BottomChrome (B, as built) |
| Listening starts (hold or Speak) | `.impact(flexibility: .soft, intensity: 0.5)` | BottomChrome (B) |
| **Set logged** | `.impact(flexibility: .rigid)` | WorkoutModeView (A, as built) |
| A new best (PR) | `.success`, in place of the set's tap, never both | WorkoutModeView (A) |
| **Reps, each step** | `.selection` per rep | RepsRow (A) |
| Reps meet last time | `.impact(weight: .light, intensity: 0.6)` in place of that step's tick | RepsRow (A) |
| Reps pass last time | `.impact(flexibility: .rigid, intensity: 0.8)`, once per set (as built) | RepsRow (A) |
| Reps hit 1 or 50 | `.impact(flexibility: .soft, intensity: 0.4)`, once, not repeated while pushed | RepsRow (A) |
| Weight reel, each detent | `.selection` | WeightReel (A) |
| +15 on rest | `.selection` per tap | workout, Live Activity (A) |
| Rest is up, app on screen | `.impact(weight: .heavy, intensity: 0.9)`, once | workout (A) |
| A kitchen timer ends, app on screen | `.impact(weight: .heavy, intensity: 0.9)`, once | cook mode (A) |
| Portion drum, each step | `.selection` | PortionDrum (as built) |
| A grocery aisle cleared | `.impact(weight: .medium)` | Groceries (B, as built) |
| **Shutdown complete** (the hold lands) | the done pattern. Closing the day is finishing it | Shutdown sheet (B) |
| **Plan kept** | the made haptic, once for the whole plan | Plan my day (B) |
| Weigh-in LOG | `.selection` (an ask answered); the receipt gets none | Body weight (A), one-ask (B) |
| Hold to pin a look | `.impact(weight: .medium)` when it pins | looks (A) |

**Never:** a haptic on scroll, on appear, when Tess speaks by herself, for a miss or a "Didn't catch that.", repeated while a finger pushes against a bound, or two for one moment. No `.error` or `.warning` anywhere, because nothing scolds. In quiet hours (23:00 to 07:00), only haptics under his finger and his own timers play. The System Haptics switch in iOS Settings turns all of them off.

## The reps control: keep RepsRow, the counter
Kaushik asked whether the set's rep count should be a simple counter or a richer round dial. **The call is the counter: RepsRow as built on #297, with a haptic tick on every rep.**
- **Reps are small numbers set next to the prefill.** Most sets change by 0 to 2 reps from last time, so a drag of one rep per 28pt with the neighbours floating above and below is already one-handed and exact. A round dial adds travel for no extra precision.
- **The weight reel is the rich control.** Weight has plates, steps and kg, and it earned the reel. Two rich controls side by side compete, and the eye loses which one leads.
- **A dial costs space and a second gesture.** The set block is one row of numerals. A dial needs about 160pt of circle and a circular drag he'd have to learn. It also reads as a stock picker, which the no-stock rule refuses.
- **The drama is already there:** the pop and the five ink droplets on a hand change, and the cadmium stroke when he passes last time. The haptics make it physical: `.selection` on every rep, a light tap when he meets last time, the rigid tap once when he beats it, and a soft stop at 1 and 50.
- This also answers the open question in memory: the "round dial for sets" is the reps counter, and it stays a counter.

## Changes to what's built
- **QueueRow finish** (`HomeQueue.swift`): the done pattern replaces `.impact(weight: .medium, intensity: 0.8)`. The strike runs itself out at armed. The fleck and the bloom are added. The 900ms hold before the op goes, and the op writes as the fold starts. Tess's line becomes "{title} done." (M55's form, with no comma).
- **TessSoul** stops playing `.success` on `doneCount`. The surface that finished the task plays the done pattern, so a row finish never buzzes twice.
- **BottomChrome**: the commit's `glow` success becomes the made haptic at landing, and the words fly instead of gathering into the soul when Next is on screen.
- **PasteRecipe saved** changes from `.success` to the made haptic.
- **WorkoutModeView** `celebrated`: `.success` for a new best, and the done pattern for the workout finished.

## Owners
- **Builder A:** the `Haptic` vocabulary and the done pattern in `DesignSystem` (beside `MotionPolicy`), RepsRow's ticks, meet tap and bounds, WeightReel detents, rest and timer ends, a new best, and the workout finished.
- **Builder B:** the made flight in `BottomChrome`, with the slot, the MORE count and the soul fallback. QueueRow's done (strike run-out, fleck, bloom, fold, timings, Tess's line), the soul's haptic removed, Plan kept's stagger, the Day log landing with its last-read instant, Groceries' and habits' done, Shutdown complete, and moving every haptic onto `.tesseraFeedback`.
- **Core:** nothing new. The parsed title and the queue order are already exposed.
- **Research:** please confirm the Home finish line uses M55's "{task} done." with no comma, and the receipt "Call the bank, today 4 pm."
