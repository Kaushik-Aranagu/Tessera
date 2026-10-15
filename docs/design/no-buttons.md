# No buttons: ink actions (build sheet)

Kaushik, 2026-10-15 19:00: he dislikes every rectangular, oval or pill-shaped button and card, Apple's defaults included, and wants something "more elegant and subtle". This widens the old "no pills or capsules" rule.

**The rule:** nothing gets a filled or outlined geometric shape around it to make it a button, a card or a bar. That means no rounded rectangles, capsules, ovals, circles or squares, and no glass slabs. An action is shown by **type, paint and motion**. Painted marks stay as they are: dabs, the soul, day dabs, seams, the carriage, plates and strokes are paint, not containers.

Recording: `recordings/ink-actions.mp4` (source `studies/ink-actions.html`). It shows the old key and Tess bar dissolving into a stroke word (its Tess horizon is superseded by the resting soul below), a hold on "Finish" with Undo as a label word, then rest on the dark ground with +15 and SKIP as label words and "Next exercise" as a tap word.

This sheet supersedes every "key", "Tess bar" and glass-panel description in earlier sheets. Read "key" there as a stroke word, and "Tess bar" or "Tess horizon" as Tess's soul at rest and her capture surface when opened.

## The screen is the resource
Kaushik, 19:18: one screen is a scarce resource. At any moment it shows **what matters most in this context**, and more options, layers and objects appear only as you go deeper. There are fast paths home and to the likely next place.

What this means in every sheet:
- **One primary action per screen** (a stroke word), at most two fast paths, and everything else one layer down: a tap, a z-zoom or an unfold in place.
- **Nothing that is always on screen without earning it.** No bars, docks or toolbars at rest. Tess is a soul in the corner, the rail is labels, and Undo appears only after something it can undo.
- **Context picks the content:** the opened Tess asks this screen's question and offers this screen's two likeliest paths. The Now hero, the queue window and the plate stack already work this way.
- **Layers open from what you touched:** a value word opens its drum in the line, a name opens its alternatives under it, Show opens Photo · Video · File in the column's place. Each layer closes back into where it came from.
- **Home is one gesture away from anywhere:** the edge back swipe walks up the z stack, and a **double tap on the soul** goes straight to Today from any depth (the soul is the one thing that is always there). There is no home button.

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

### Tess: a soul at rest, a capture surface when opened (replaces both Tess bars)
Kaushik, 19:18: "just a small element… we click on it, it will show some animations and expand into something a little bigger, which has more options." There is **no bar, band or writing line at rest**. Recording: `recordings/tess-capture.mp4` (source `studies/tess-capture.html`).

**At rest: only the soul.**
- **Where and how big:** the three dabs sit in the bottom-right thumb corner, centred at (346, 788), about 46×40pt with a 64×64 hit area. They breathe slowly (scale 1→1.08, 3.2s).
- **Nothing else is drawn,** so every page gets its full height back.
- **When Tess has something to say** ("Oat milk and eggs, on Groceries.", "Set 3, 80 × 7."):
  - Her line appears **beside the soul**, right-aligned to x 312, at 21 in cobalt (light cobalt `#9DBFE6` on dark), sliding in 12pt from the right.
  - **UNDO** sits under it as a label word.
  - The line fades after 4s. UNDO stays until the next action of the same kind.
- **On a fresh screen** a short hint can sit there instead ("Hold me to tell me a set" in live mode). After three uses it never shows again.

**Tap: Tess opens.**
- **The soul swells once** (×1.35, 260ms). Then its three colours **rise into a column**, each dab landing beside its word with a slight overshoot (`cubic-bezier(.3,1.3,.5,1)`, 480ms, staggered 40ms from the bottom):
  - **Speak** (vermilion), at y 594
  - **Write** (cobalt), at y 664
  - **Show** (cadmium), at y 734
  - The words are Title 34, right-aligned to x 314, entering from +24pt.
- **Behind them:**
  - The page recedes: opacity 0.22, a 3pt blur, scale 0.985, which is z.
  - A paint wash rises from the corner. It is the ground colour at 93–97% with a faint cobalt warmth at the corner, has **no top edge** (a mask over its top 30%), and covers the lower 470pt (460ms, house curve).
- **Above the modes,** at y 452:
  - Tess's question for this context, at 21 in cobalt ("What's next?" on Today, "Tell me a set" in live mode, "What do we need?" on Groceries).
  - Under it, **at most two fast paths** as value words. These are the two most likely things for this screen right now, for example "**Start Push Day A** · **Groceries**".
  - That is all. More appears only as you choose (see the principle below).
- **Close:** tap the page, or swipe down. Everything gathers back into the soul in reverse (420ms), and the page comes forward.

**Each mode opens its own layer.**
- **Speak:**
  - Write and Show fold away. All three dabs gather into the big **listening** bloom low in the centre (×1.4, at about (196, 698)), using the bloom from `tess-soul.md`, driven by the mic level.
  - "Listening" shows at 21 in cobalt. Heard words arrive at Title 34 and 55% ink, one at a time out of a 6pt blur.
  - A pause of 1.2s, or a tap on the bloom, ends it. **Tidying** then plays: fillers ("um", "uh") and the words the grammar drops squeeze out (width to 0, 320ms), and the rest cross-fade into the **clean sentence** in full ink ("Oat milk and eggs, on **Groceries**.").
  - The 2s ghost dries as a 1.5pt cobalt line drawing under the sentence. It saves, everything gathers back into the soul, and Tess says it beside the soul with UNDO.
  - Speech is on-device (`SpeechAnalyzer`). The tidying is the grammar first, then the on-device model where Core adds it.
- **Write:**
  - The cobalt dab smears sideways into a **writing line** (0.5pt, x 22 to 368) at y 560. Speak and Show fold away, and the keyboard rises.
  - Text sits at Title 34 on the line, and suggestions appear under it as value words.
  - Return makes the same ghost as Speak.
- **Show:**
  - The yellow dab rises to the top of the column and the column becomes the next layer: **Photo · Video · File**, in the same places, with the other dabs turning cadmium.
  - **Photo** and **Video** open the camera full-bleed with no frame. The shutter is a cadmium dab you hold.
  - **File** opens the system picker, which is exempt.
  - Whatever comes back lands as a ghost object ("A photo, on Carbonara."), and you can tap it to attach it elsewhere.

**Hold the soul, from rest: straight to Speak.** This is the fast path (the gym uses it).
- The soul rises out from under the thumb to the left (translate (−150, −90), ×1.5, 420ms) and blooms.
- No wash rises and the page stays put, because what you say lands on what you are looking at.
- Release ends listening.

**On dark grounds** (workout, cook mode) the dabs use screen blend, and the wash is the dark ground at 93%.

### Tonight's cut for Builder B (closed soul, opening to Write)
Recording: `recordings/tess-write.mp4` (source `studies/tess-write.html`): tap the soul, Write, type, Return, the ghost dries, and it closes back into the soul with the reply beside it.
Build these first; Speak and Show can follow after the install.
1. **`TessSoulKey`** (replaces `BottomChrome`'s collapsed bar):
   - The existing `TessSoul` view at 46×40, idle mode, scale 0.72.
   - Position: `.overlay(alignment: .bottomTrailing)` on the root, with 22pt trailing padding and 34pt bottom padding above the home indicator (centre about (346, 788) on a 390×844 screen). Hit area 64×64 (`contentShape(Rectangle())`).
   - A slow breath: scale 1↔1.08, 3.2s, `.easeInOut`, repeating.
   - **Tess's line** is a `Text` to the soul's left, trailing-aligned with 12pt spacing, at 21 regular in `Theme.Colors.cobalt`. It slides in from +12pt x with opacity over 300ms, house curve, and fades after 4s.
   - **UNDO** sits under the line as a label word (16/700, uppercase, vermilion).
   - Remove the glass rect, the suggestion chips and the collapsed "Ask Tess…" text.
2. **Tap → open to Write** (the default for tonight; Speak and Show sit above it as words, and are inert until their layers ship):
   - **Haptic:** `.selection` on touch-down.
   - **The soul swells** (×1.35, then back over 260ms). Then the three dabs **move with `matchedGeometryEffect`** to their mode positions, using `.spring(response: 0.48, dampingFraction: 0.68)`, staggered 40ms from the bottom.
   - **The mode words:** Title 34/500, trailing at x 314 (76pt from the right edge), 70pt apart. Show is at the bottom (y 734), then Write (664), then Speak (594). Each enters from +24pt x with opacity over 360ms.
   - **The page behind:** opacity 0.22, `.blur(radius: 3)`, `.scaleEffect(0.985)`, all over 420ms.
   - **The wash:** a bottom-anchored `Rectangle`, 470pt tall, filled with the ground colour at 0.95 and masked by a `LinearGradient` (clear → black at 30%). On light grounds add a cobalt radial at 12% from the corner. You can use `.glassEffect(.regular, in: Rectangle())` under the same mask if it reads better, but no corners. It rises 60pt with opacity over 460ms.
   - **Above the modes:** at y 452, the screen's question at 21 in cobalt. Under it, up to two fast paths as value words (21/600 ink joined by " · " at 75%).
3. **Write (tap Write, or open Tess with a hardware keyboard attached):**
   - Speak and Show fade (180ms).
   - The cobalt dab **stretches into the writing line:** scaleX 1→9 while it moves to x 22, then cross-fades to a 0.5pt hairline in cobalt at 60%, x 22 to 368, at y 600 (380ms, house curve).
   - A `TextField` sits on the line at Title 34/500 with a cobalt `tint` caret and `.textFieldStyle(.plain)`, focused immediately so the keyboard rises.
   - The question moves to sit just above it.
   - The wash and line ride up with the keyboard (`.ignoresSafeArea(.keyboard)` off).
   - **Return:** the text dims to 45% as a ghost. A 1.5pt cobalt drying line draws under it over 2s (touching cancels), then it commits through the same grammar path `BottomChrome` uses today. Everything closes back into the soul (420ms, reverse), and Tess's reply shows beside the soul with UNDO.
4. **Close:** tap the dimmed page, swipe down on the wash, or Escape. This is the reverse of opening.
5. **Reduce Motion:** no swell or spring travel. The wash and words cross-fade over 200ms, and the dab-to-line stretch becomes a fade.

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
| New `DesignSystem/InkActions.swift` | | `LabelActionStyle` (label word), `ValueWash` (value-word touch), `TessSoulKey` (the resting soul, its line and UNDO) and `TessCapture` (the opened surface and its Speak, Write and Show layers), `.veil(edge:)` | iOS A |
| `Features/Home/NowPage.swift:92` | "Hold to finish" key | "Finish", vermilion, meta "HOLD · 14 MIN LEFT" | iOS B |
| `NowPage.swift:437` | "Start" key | "Start", vermilion, tap | iOS B |
| `NowPage.swift:471` | Ink "Resume" key | "Resume", live vermilion, tap. The lit top seam stays | iOS B |
| `Features/Home/TrainingPage.swift:85, :178` | "Start workout" / "Resume" keys | Stroke words, vermilion, tap | iOS B |
| `Features/Command/BottomChrome.swift` | Glass rect-20 bar, rect-22 panel, rect-4 outlined suggestion chips | `TessSoulKey` at rest and `TessCapture` opened; chips become the two fast paths | iOS B |
| `Features/Workout/WorkoutModeView.swift:516` | "Hold to log" cream key | "Log set", live vermilion, meta "HOLD · 82.5 × 5" | iOS A |
| `WorkoutModeView.swift:530` | "Skip rest" key | Stroke word "Skip rest" in cadmium, tap, plus **+15** and **SKIP** label words under the rest line (as on the Live Activity) | iOS A |
| `WorkoutModeView.swift:537` | "Next exercise" key | "Next exercise", cobalt, tap | iOS A |
| `WorkoutModeView.swift:546` | "Hold to finish" key | "Finish", vermilion, meta "HOLD" | iOS A |
| `Features/Workout/WorkoutFinishView.swift:78` | "Back to today" key | "Back to today", cobalt, tap | iOS A |
| `Features/Workout/WorkoutParts.swift:241` `WorkoutTessBar` | Dark glass rect 18 | `TessSoulKey` on dark, Undo as a label word; holding the soul is voice (`voice-gym.md`) | iOS A |
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
