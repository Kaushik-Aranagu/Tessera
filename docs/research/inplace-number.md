# Scrubbing a number in place (board item 56)

For Builder A and Design. Kaushik's correction: the weight strip takes too much room and doesn't scroll sideways;
the numeral itself should change when you scroll on it, like the reps number. This note says how that should feel,
in numbers, checked against master (`Features/Workout/Instruments/WeightDial.swift`, "WD:line") and against
Design's sheet (`docs/design/set-block.md` on `claude/project-thread-b3tu3f`, "the sheet").
Apple API names are ones I'm confident about unless marked (unverified).

## 1. The model: one detent per load, not one per kg
- The reel moves through Core's detents (`TesseraCore/.../Training/Dial.swift:7`, from `LoadProfile.loadable`),
  never through a fixed kg step. Drag distance is per detent, so a 2.5 kg barbell step and an irregular dumbbell
  rack (12 to 12.5 to 14) feel the same under the finger. Master already works this way (WD:27, WD:381). Keep it.
- Steps from the plate setup (master, `Training/LoadProfile.swift:36`): barbell step = 2 x smallest plate.
  Starter kit (`Catalog/StarterContent.swift:60`): 20 kg bar, one pair each of 25, 20, 15, 10, 5, 2.5, 1.25, so
  every barbell detent is 2.5 kg apart. A 1.25 kg total step only exists if 0.625 kg plates are added; no code
  path makes one today. EZ bar: same plates on a 10 kg bar. Dumbbells: starter kit 2 kg steps, 2 to 50
  (`StarterContent.swift:61`); the fallback rack `FixedLoads.dumbbells` (`LoadProfile.swift:72`) is irregular
  (12, 12.5, 14, 16, 17.5 ...). Machines and cables: 5 kg. Bodyweight and band: 2.5 kg.
- The step label is never shown while scrubbing; the neighbours above and below already say it.

## 2. Drag: distance per step and acceleration
- Axis: vertical only; up is heavier. Decide the axis once, at 10 pt of travel: if |dx| > |dy| then, the whole
  gesture belongs to the exercise lane. Master re-checks on every sample until vertical wins (WD:376-378), so a
  sideways swipe that curls upward can be captured late. Change: lock the decision once.
- Base pitch: 12 pt per detent (WD:76, the sheet agrees). Nothing moves under 12 pt, so a tap never nudges.
- Acceleration (new; master is linear): apply a gain to each incremental dy, from finger speed v (pt/s,
  `DragGesture.Value.velocity`):
  - v <= 250: gain 1 (12 pt per load). This is the precise zone; most changes are 1 to 4 loads.
  - 250 < v < 1000: gain rises linearly from 1 to 2.5.
  - v >= 1000: gain 2.5 (about 5 pt per load).
  - The first 48 pt of every drag (4 loads) is always gain 1, so a quick small push stays exact.
  Because gain changes mid-drag, accumulate fractional detents per sample instead of master's
  `start + translation / pitch` (WD:381); otherwise slowing down would jump the value backwards.
- Reps: 1 rep per 28 pt, no acceleration. The sheet says 44 pt (same as master RepsDrum `Metrics.pitch`,
  RepsDrum.swift:26). Disagree mildly: 8 to 12 at 44 pt is 176 pt of thumb travel, more than the number row;
  28 pt keeps it under 120 pt and is still far from the weight's 12 pt, so the two never feel alike by accident.

## 3. Fling, momentum and settling
- Coast length: detents = clamp((predicted dy - dy) / 12 x 0.5, -24, 24), from
  `predictedEndTranslation`. That is master's formula and cap exactly (WD:389-391). Agree.
- What changes: master jumps straight to the final value on lift-off (WD:392). With the strip gone there is
  nothing to show the travel, so a +10 fling would look like a teleport. Play the coast out: n detents over
  T = min(0.25 + 0.03 n, 0.8) s, detent i shown at T x (1 - sqrt(1 - i/n)) (ease-out; fast first, slow last).
  Each shown detent rolls (sheet: 200 ms out, scale 0.82, 3 pt blur) and the last one lands with the settle
  spring (sheet: 300 ms). Commit `weight` once, at the end, so plates and plate line don't churn mid-coast.
- A touch during a coast stops it on the detent showing and starts a new drag from there.
- Bounds: rubber-band past the first or last detent: the numeral moves 0.3 pt per pt dragged, at most 16 pt,
  springs back on lift-off, one bound haptic (section 4), no value change. Bounds are the detents' ends:
  starter-kit barbell 20 to 177.5 (64 detents), default `PlateLoad` 20 to 195, dumbbells 2 to 50, fallback
  0 to 300 (`WorkoutSession.swift:300-304`). Gap: 177.5 kg is a real ceiling for a heavy deadlift; the kit lists
  one pair of each plate. Suggest the kit list two pairs of 25 and 20 (Core, not the reel).
- Reps bounds: 1 to 50. Master disagrees with itself: RepsDrum is 0...30 (RepsDrum.swift:15), the session clamps
  1...50 (`WorkoutSession.swift:345`). Pick one; 1...50 matches the logger.

## 4. Haptics
- `.sensoryFeedback(.selection, trigger:)` per detent the hand or a coast passes (WD:106; sheet agrees).
  During a fast coast skip a tick if the last one was under 30 ms ago; the Taptic Engine smears faster ticks.
- Plate haptic: the sheet says `.impact(.light)` "when a plate goes on or off". Disagree as written: on the
  starter kit the plates change on almost every step (80 = 25+5 per side, 82.5 = 25+5+1.25), so it would fire
  constantly. Fire `.impact(weight: .light)` only when a plate of 5 kg or more goes on or off. Master's version
  is `.impact(weight: .heavy)` on each 10 kg line (WD:107, WD:328); heavy is too much at scrub speed. Drop it.
- At a bound: `.impact(flexibility: .rigid, intensity: 0.6)` once per touch.
- Programmatic moves (prefill, Undo, Tess presets) stay silent; master's `tickHaptic` counter does this (WD:41).
- VoiceOver adjustments: no haptic (master passes `haptic: false`, WD:117). Keep.

## 5. Tap to type
- Tap the numeral: it becomes a field in place, same size, `.keyboardType(.decimalPad)`, text selected, with a
  keyboard toolbar "Done". On commit, snap to the nearest detent (Core `snap`, Dial.swift:26; ties go to the
  lighter load). If snapped, the numeral shows the loaded value and a label line under it says "81 isn't
  loadable; 80" for 2 s.
- Master: typing exists only as a VoiceOver action opening a system `.alert` (WD:122-126, WD:133-140); a
  sighted tap on the strip steps one load instead (WD:162-166). The sheet moves typing to a tap ("the existing
  `isTyping` path"). Agree on the tap; disagree on reusing the alert: it is a stock modal over the workout.
  Edit in place with `@FocusState`.
- Reps: tap types too (number pad). Master has none.

## 6. VoiceOver
- One element, label "Weight", trait adjustable via `.accessibilityAdjustableAction` (WD:114). Increment and
  decrement move one detent (agree with sheet). Value: "82.5 kilograms, 25, 5 and 1.25 per side" (sheet).
  Master speaks "82.5 kilograms, 31.25 per side" (`WorkoutSession.swift:318`); change `spokenLoad` to list plates.
  Dumbbells: "14 kilograms each". Bar only: "20 kilograms, bar only" (kept).
- Hint: "Swipe up or down to change by one load. Double tap to type."
  Double tap = `.accessibilityAction { }` (default action) opens the field; keep "Type value" as a named action.
- Gap: the big numeral is `.accessibilityHidden(true)` on master (`WorkoutModeView.swift:447`) because the dial
  carried the value. When `WeightDial` goes, the reel must become the element or weight disappears from VoiceOver.
- Rest copy still says "drag the dial right" (`WorkoutModeView.swift:419`); update with the horizon.
- Reps: label "Reps", value "9, one more than last time" when it beats the ghost; master has the hint only.

## 7. Reduce Motion and Dynamic Type
- Reduce Motion (`accessibilityReduceMotion`, through `MotionPolicy`): the roll becomes a crossfade, the
  neighbours appear without sliding, no pop, no droplets, no rubber-band offset. Fling still counts: the coast
  lands on the same value in one crossfade with one haptic. Master drops momentum entirely (WD:388-389);
  disagree, a flick that does nothing feels broken; Reduce Motion is about what moves on screen, not input.
- Dynamic Type: the 80 pt numeral does not grow (it is already display size). "kg", "×", the plate line and the
  neighbours scale up to `.xxLarge`, as the strip labels do (WD:196). Fit check (estimate, unverified on
  device): "177.5 kg × 12" at 80 and 56 pt is about 360 pt, the whole content width on iPhone 17 (393 - 2 x 16).
  Give the row `ViewThatFits` with a 64 pt numeral fallback, and add `.accessibilityShowsLargeContentViewer`.

## 8. Feel references
| Reference | Take | Leave |
|---|---|---|
| iOS Clock timer wheel (`UIPickerView` style) | a click per detent; the coast that slows into the last value; rubber-band at the ends | the wheel chrome, the 3-row window |
| Apple Watch Digital Crown | speed-based acceleration over a fixed detent grid; a firmer bump at the end stop | per-detent haptic at every speed (it skips some when fast, as section 4 does) |
| Figma number scrub | drag on the number itself, no separate control; tap the same number to type | horizontal scrubbing (ours is vertical so the lane keeps sideways) |
Strong and Hevy are the bar for typing speed only: one tap to an already-filled field. The reel must not be slower.

## 9. Fixtures (barbell, starter kit, start 80 kg, detents 2.5 apart)
| Gesture | Expected |
|---|---|
| tap (no drag) | field opens, 80 selected |
| drag up 11 pt, slow | 80 |
| drag up 12 pt, slow | 82.5 |
| drag up 36 pt, slow | 87.5 |
| drag down 24 pt, slow | 75 |
| drag up 30 then down 30, slow | 80 |
| drag up 100 pt, slow (< 250 pt/s) | 100 (8 detents) |
| drag up 100 pt, fast (>= 1000 pt/s throughout) | 48 pt x1 + 52 pt x2.5 = 14.8 detents, so 115 |
| drag up 24 then lift with predicted extra 240 pt | +2 then +10 coast = 110 |
| start 170, fling up for +20 | 177.5, bound haptic, rubber-band |
| start 22.5, drag down 60 pt | 20 (bar), bound haptic |
| swipe right 40 pt, drifting up 15 pt | 80, the lane pages |
| VoiceOver increment x3 | 87.5, spoken "87.5 kilograms, 25, 5, 2.5 and 1.25 per side" |
| type "81" | 80 (nearest), note "81 isn't loadable; 80" |
| type "81.3" | 82.5 |
| type "81.25" (tie) | 80 (lighter wins, Core `snap`) |
| dumbbell, starter kit, start 12, drag up 12 pt | 14 |
| reps 8, drag up 28 pt | 9 |
| reps 50, drag up 28 pt | 50, bound haptic |

Engine checks already on master: `DialTests.swift` (snap 81.4 to 82.5, step 80 by +1 = 82.5, by -2 = 75).
The drag maths above (gain, accumulation, coast schedule) should be a pure function in Core with these rows as
a Swift Testing table, so the feel is tested without a simulator.
