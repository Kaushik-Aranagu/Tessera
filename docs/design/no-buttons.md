# No buttons: ink actions (build sheet)

Kaushik, 2026-10-15 19:00: he dislikes every rectangular, oval or pill-shaped button and card, Apple's defaults included, and wants something "more elegant and subtle". This widens the old "no pills or capsules" rule.

**The rule:** nothing gets a filled or outlined geometric shape around it to make it a button, a card or a bar. That means no rounded rectangles, capsules, ovals, circles or squares, and no glass slabs. An action is shown by **type, paint and motion**. Painted marks stay as they are: dabs, the soul, day dabs, seams, the carriage, plates and strokes are paint, not containers.

Recording: `recordings/ink-actions.mp4` (source `studies/ink-actions.html`). It shows the old key and Tess bar dissolving into a stroke word and the Tess horizon, a hold on "Finish" with Undo as a label word, then rest on the dark ground with +15 and SKIP as label words and "Next exercise" as a tap word.

This sheet supersedes every "key", "Tess bar" and glass-panel description in earlier sheets. Read "key" there as a stroke word, and "Tess bar" as the Tess horizon.

## The three ways to act

### 1 · Stroke word (the one primary action on a screen)
- The action as a word at **Title 34/500** (ink on light grounds, cream on dark). It sits on a **dry brushstroke** in the action's paint: vermilion to do or finish, cobalt for Tess or to move on, sage for kitchen, cadmium for rest.
- **The stroke:** 19pt tall, starting 7pt before the word and ending 7pt after it, with its bottom 3pt below the baseline, so the lower third of the letters sits in paint. It has rough, tapered ends (no round caps) and is 82% opaque. Use `Brushstroke` in `Paint.swift` as a filled tapered shape instead of a stroked curve, with a grain displacement.
- **Meta** sits on the same baseline to the right, in Label 16/700 uppercase: "HOLD · 14 MIN LEFT", "82.5 × 5". Hold actions always say **HOLD** in their meta. The word itself never changes to "Keep holding".
- **Tap:** on touch-down the stroke **wets**: it grows to 165% height from 70% down, goes to 100% opacity, its edges bleed (blur about 1pt), and the word sinks 1pt (120ms, ease-out). The action fires on release, then the stroke **dries** back (300ms, house curve).
- **Hold:** on touch-down the stroke **empties** to a dry trace at 20% (140ms). Then it **repaints left to right** under the thumb, wet, over the hold duration (0.6s log, 0.7s finish, 0.8s workout finish), easing out. When it completes, the tip **blooms** (height ×1.9 then settles to ×1.2, 260ms) with a rigid impact, and the action fires. Letting go early drains the paint back right to left (220ms).
- **Hit area:** the full content width × 64pt, with `contentShape(Rectangle())`. The touch target is generous even though nothing is drawn.
- **Disabled:** no stroke, and the word at 40%.

### 2 · Label word (secondary actions)
- **Label 16/700 uppercase +8%** in the secondary colour: +15, SKIP, UNDO (vermilion), EDIT, CLEAR.
- **Touch:** the ink goes to full and a **1.5pt hairline draws out from the centre** under the word (180ms, house curve). It fires on release and the line fades (300ms).
- Hit area at least 44×44. Two label words sit 30pt or more apart.

### 3 · Value word (inline, inside sentences)
- The value in a sentence at 600 weight ("Weights in **kg**", "Rest **2:30**").
- **Touch:** a soft cobalt wash blooms behind the word: irregular, blurred about 5pt, 22% opacity, with no edge. Then it cycles with a 120/180ms blurred crossfade, or opens its instrument.
- **Suggestions** (the chips in `BottomChrome` today) become value words in a line, separated by " · " at Body 21 and 60% ink.

Glyph-only controls (the − and + on the weight dial, the close ✕) stand alone at Title size, with **no circle or ring** behind them. On touch they get the value-word wash.

## Surfaces that were shapes

### The Tess horizon (replaces both Tess bars)
- There is no bar. A **full-bleed band of glass** sits at the bottom, 150pt tall. It has **no top edge**: it fades in from transparent over its top 55%, using a gradient mask on `.glassEffect(.regular, in: Rectangle())`, or `.ultraThinMaterial` if the mask fights the glass.
- **The writing line:** a 0.5pt hairline from x 76 to the right gutter, at the text baseline + 6pt, in ink at 28% (cream at 30% on dark). The soul sits at x 50 to its left. "Ask Tess…" and Tess's lines sit on it at 21.
- **Undo** and other actions in the horizon are **label words** at the right end of the line.
- **Focus (typing):** the line goes to 60% and lengthens 8pt to the left. The keyboard lifts the band, and the line stays the only edge. The expanded panel is the same glass growing upward, with **no corners and no outline**.
- On dark grounds (workout, cook mode) it uses the same band over the dark ground.

### Veils (replace glass panels and cards)
- A panel that slides over content (the swap list, the exercise strip, the expanded command) is a **veil**: full-bleed glass or ground that is attached to one edge of the screen and **fades out on its open side** over 40pt. One hairline seam marks where it meets the content.
- There are no rounded corners and no floating inset panels.

### Lifted rows
- A row being reordered gets **no highlight shape**. It lifts with a soft shadow on the text itself (`.shadow` on the label), scales 1.03, and a hairline seam at 30% appears above and below it.

## Where it changes (master 23a0e10)

| Where | Today | Becomes | Owner |
|---|---|---|---|
| `DesignSystem/Paint.swift` `PaintKey` | radius-14 key, ink or cream fill, chamfer, shadow | **The stroke word**: rewrite `PaintKey`'s body and keep its API (`finish`, `paint`, `isTap`, `duration`, `drift`, `action`, `label`). `height` becomes the hit height. Apply Title 34/500 inside it. Add `meta:`. | iOS A |
| `DesignSystem/Controls.swift` `HoldToConfirm` (capsule), `Machined.swift` `HoldKey`, `GlassLens`, `machined(_:radius:)` | Unused | Delete | iOS A |
| New `DesignSystem/InkActions.swift` | | `LabelActionStyle` (label word), `ValueWash` (value-word touch), `TessHorizon` (band and writing line), `.veil(edge:)` | iOS A |
| `Features/Home/NowPage.swift:92` | "Hold to finish" key | "Finish", vermilion, meta "HOLD · 14 MIN LEFT" | iOS B |
| `NowPage.swift:437` | "Start" key | "Start", vermilion, tap | iOS B |
| `NowPage.swift:471` | Ink "Resume" key | "Resume", live vermilion, tap. The lit top seam stays | iOS B |
| `Features/Home/TrainingPage.swift:85, :178` | "Start workout" / "Resume" keys | Stroke words, vermilion, tap | iOS B |
| `Features/Command/BottomChrome.swift` | Glass rect-20 bar, rect-22 panel, rect-4 outlined suggestion chips | `TessHorizon`; the panel is the horizon growing upward; chips become value words | iOS B |
| `Features/Workout/WorkoutModeView.swift:516` | "Hold to log" cream key | "Log set", live vermilion, meta "HOLD · 82.5 × 5" | iOS A |
| `WorkoutModeView.swift:530` | "Skip rest" key | Stroke word "Skip rest" in cadmium, tap, plus **+15** and **SKIP** label words under the rest horizon (as on the Live Activity) | iOS A |
| `WorkoutModeView.swift:537` | "Next exercise" key | "Next exercise", cobalt, tap | iOS A |
| `WorkoutModeView.swift:546` | "Hold to finish" key | "Finish", vermilion, meta "HOLD" | iOS A |
| `Features/Workout/WorkoutFinishView.swift:78` | "Back to today" key | "Back to today", cobalt, tap | iOS A |
| `Features/Workout/WorkoutParts.swift:241` `WorkoutTessBar` | Dark glass rect 18 | `TessHorizon` on dark, Undo as a label word | iOS A |
| `Features/Workout/ExerciseStrip.swift:110, :122, :169` | "Hold to finish here" key; glass with 34pt bottom corners; rect-10 lifted row | "Finish here" stroke word; `.veil(edge: .top)`; lifted row as above | iOS A |
| `Features/Workout/SwapPanel.swift:51, :89` | Glass rect-18 card; picked row filled with a cobalt rect-10 | `.veil(edge: .bottom)`; the picked row has no fill: the name goes to full cream and a 3pt cobalt seam paints in at its left edge | iOS A |
| `Features/Workout/Instruments/WeightDial.swift:130` | System `.alert` to type a weight | Type **in place on the numeral**: a cobalt caret in the numeral, decimal keyboard, Return sets it. No alert | iOS A |
| `Features/Exercise/ExercisePage.swift:204` | "Log a set" key | "Log a set", vermilion, tap | iOS A |
| `Features/Plans/WeekPage.swift:195` | Rect-5 range bar | A brushstroke band, 14pt, health at 16%, rough ends | iOS A |
| `Features/Groceries/GroceriesView.swift:91` | "Done shopping" key | "Done shopping", sage, meta "HOLD" | Core |
| `Features/Tess/SoulGallery.swift:18` | Rect-18 dark swatch | Fine as is (DEBUG gallery only) | |

Specs this replaces (no edits needed, this sheet wins): `home-v1.md` (keys, Ask Tess bar), `workout-v1.md` (hold key, Tess bar), `exercise-page.md`, `kitchen/10-11` (Save recipe, Cook), `kitchen/12` (timer key, Hold to finish), `kitchen/13` (Clear the basket), `m3-steers.md` (Log today, Export everything), and `m4-steers.md` (Start with X, Focus, Shutdown complete). All of them become stroke words; holds keep their durations.

**Already right:** the rest Live Activity (type-only +15 / Skip with a hairline divider), `HandleButtonStyle` (text that dims), and the carriage and seams.

**Can't change (the system draws them):** widget and Live Activity container corners, the Dynamic Island, the keyboard, context menus and the share sheet. Inside a widget or Live Activity, the controls follow this sheet.

## Order
1. **iOS A** builds `PaintKey` as the stroke word plus `InkActions.swift`, and deletes the dead keys. Every key on screen changes in one go.
2. **iOS B**: `BottomChrome` to `TessHorizon`, then the Home call-site labels and metas.
3. **iOS A**: workout surfaces (the Tess bar, veils, the weight dial in place). **Core**: the Groceries label.
4. **QA**: grep for `RoundedRectangle|Capsule|cornerRadius|buttonBorderShape|bordered|\.alert(` in `Features/` and `DesignSystem/`. Anything left is either a painted mark under 3pt radius or a bug.

Reduce Motion: the stroke appears and disappears without wetting or blooming, and a hold fills with a plain opacity ramp instead of the left-to-right repaint. Haptics are unchanged: light impact on a hold's touch-down, rigid on completion, `.selection` on taps and label words.
