# Widgets, controls and snippets (M4 slice 10): the visual language

For iOS Builder A (owns `Widgets/`) and Core (the intents). Build order and API notes: Research's `widgets-and-snippets.md` (snippets first, then the control, then widgets once the App Group is confirmed). Board: `recordings/widgets-board.png` (source `studies/widgets.html`).

## The rule: one thing, one seam, one control
Every surface outside the app is the app's Now, reduced to its bones:
- **One thing** in a top tier: a name at Title 34/500 (−3.5%), or a numeral at 64–80 Light tabular. That's Flighty's lesson: one huge thing, and everything else is quiet.
- **One hairline seam** under it (1pt ink at 18% with a white 70% line under it on light grounds; cream at 18% on dark ones). It's the machined edge, and the only line.
- **One control,** as a text word at 21/600 on the right of the seam row: "Done", "Same again", "Undo". There are no bordered buttons, pills or icons.
- **A context line** at the top in labels (16/700 uppercase), and at most one secondary line at 18 under the seam. Nothing under 16pt.

## Grounds
- **Light widgets** use a pre-rendered painterly ground (a PNG in the widget bundle), baked from `ThemedBackground` at four times of day: morning sky, afternoon (the Home ground), dusk, and night. The timeline entry picks one by its date. Widgets can't run the shader, so the paint is an image.
- **While something runs** (a workout or a cook), the widget goes to the **dark** ground (the workout's), and a static 2pt vermilion seam sits on the top edge: the lit seam, without the travelling glint, because widgets can't loop.
- **Tinted and clear modes:** check `widgetRenderingMode`. Drop the image, mark the name or numeral and the seam `widgetAccentable()`, and keep the layout as it is. The type still carries it (see the tinted board).
- `containerBackground` is the paint image, marked removable.

## Home Screen widgets
- **Medium, Now:** context line "NOW · 14 MIN LEFT"; the name at 34/500, up to 2 lines; the seam; "then Call the dentist, 15:40" at 18; and **Done** on the right (`Button(intent:)`, finishes the task). While a workout runs: "PUSH DAY A · RESTING", the name "Bench, set 3 of 4" at 34 on the left, and the rest countdown on the right at 64 Light as `Text(timerInterval:)`, with "82.5 × 8 last" and **Same again** under the seam.
- **Small:** a numeral or a name, never both. Groceries: "12" at 80 Light with "to buy, Dairy first". Now: the name at 30–34 with the time in labels under the seam. Tapping opens the matching page.
- **Motion between entries:** names change with `.transition(.push(from: .bottom))` (y is sequence: the next thing comes up). Numbers use `.contentTransition(.numericText())`. Nothing else moves except the system timer text.
- **Relevance:** score the Now widget high around the workout's time on gym days (`TimelineEntryRelevance`).

## Lock Screen accessories
Monochrome, so they're type only. Rectangular, two lines: a label line, then one line. During rest: "BENCH · SET 3", then the countdown at 44 Light (`Text(timerInterval:)`). Otherwise: "NOW", then the name at 21/600. Inline: the Now line as written ("Call the dentist at 15:40"). No logging from a locked phone; tapping opens the app (after Face ID).

## Snippets (Siri, Shortcuts, the Action button)
The snippet draws on the system platter, so there's no paint. Type does all the work.
- **Log a set:** a context line "BENCH PRESS · SET 4"; two numerals at 80 Light, weight and reps, with a 1pt vertical hairline between them and "KG" and "REPS" in labels under each; the seam; then three words: **Same again** (ink, 600) on the left, and **+2.5** and **+1 rep** (secondary) on the right. Each tap rolls the numerals with `numericText` and logs. Snippets have no haptics, so the roll is the feedback.
- **Confirmations** (add to groceries, a capture): one sentence at 21/400 in Tess's voice ("Milk is on Groceries, under Dairy.") and **Undo** in vermilion 21/600 at the bottom right. In dark mode, Undo is a light vermilion (`#F2B8A8`).
- Never a list or a form inside a snippet. If a phrase needs a choice, Tess asks it as the intent's parameter prompt before the snippet opens.

## The control: "Tell Tess"
A `ControlWidgetButton` with a custom SF Symbol: **a paint dab with a small plus at its upper right** (draw it in the SF Symbols app from the soul's dab outline, as a template with three weights). The title is "Tell Tess". It opens the app with the ghost row focused and the keyboard up. The same intent goes on the Action button.
