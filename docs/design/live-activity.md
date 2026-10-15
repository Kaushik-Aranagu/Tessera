# Rest timer Live Activity

> **On hold (2026-10-15):** Kaushik rejected this visual as basic (the fonts and the buttons). Three new directions are in `mockups/LiveRest2.dc.html`: Gesso, Horizon and Palette. Build only the behaviour below until he picks one. The research brief says: one number, one action, the system glass, cream numerals not gold, and use `staleDate` / `isStale` for the "set is up" state.

The rest timer lives on the Lock Screen and in the Dynamic Island, so the phone can stay locked on the bench. Mockup: `mockups/LiveRest.dc.html`. Feature spec: Product lead's v1-features.md (P0).

## Lock Screen (356 × about 156pt; the system clips the corners)
- **Ground:** the workout's painterly ground at 92%: base `#1C1828`, with a violet `#3B2D57` wash from the top left and a teal `#1E3D4A` wash from the bottom right.
- **Edges:** a white 14% inner top chamfer and a 0.5pt black hairline. A **lit 2pt vermilion process seam** runs along the top edge (with a glint), the same as in the app.
- **Top row:**
  - Left: the countdown in Fraunces 52/600, cadmium `#E8BD4C`, tabular, using `Text(timerInterval:countsDown:)`. "rest" follows it in italic 18, `#A79FB5`.
  - Right: the **Done** key, cream `#F3ECE0`, 112×52, radius 14, 21/600 ink.
- **The drying stroke** (time you can see): a 7pt cadmium brushstroke across the card that shortens from the right as rest runs out.
  - A 2pt guide at cream 14% shows the full length.
  - A soft wet tip (a 16pt blurred cadmium dot) rides the end of the stroke.
  - Build it with `ProgressView(timerInterval:countsDown:)` masked by a brushstroke shape. Verify that the mask renders in a Live Activity; if it doesn't, a plain 7pt rounded-rect drain is the fallback.
- **Bottom row:**
  - Left: the next set in italic 21, e.g. "Bench, 82.5 × 8".
  - Right: **+15s** and **Skip** as hairline keys, 64×40, radius 12, with a 1pt cream 32% outline and 18pt text.

## When rest is over: "Set 4 is up"
- The countdown is replaced by "Set 4" (Fraunces 52, cream) with "is up" in cadmium italic.
- The stroke is gone. The set reads "Bench, 82.5 × 8", with "rested 2:30" below it in italic 18.
- The Done key glows vermilion (a 22pt glow breathing over 2.2s) until it is pressed. Only Skip remains.
- One haptic alert plays at the moment rest ends. Never repeat it.

## Dynamic Island
- **Compact:**
  - Leading: a cadmium paint dab (soft radial, breathing scale 1↔1.15).
  - Trailing: the countdown in Fraunces 18/600, cadmium.
- **Expanded:**
  - Top row: the countdown in Fraunces 44, then the Done key 104×50.
  - Middle: the drying stroke.
  - Bottom: the next set in italic 21, with Skip on the right.
- **Minimal:** the dab only.
- The island's capsule outline is the system's. Nothing we draw inside it is a pill.

## Behaviour
- **Done** logs the next planned set (weight and reps as dialled for it) through the same typed action as hold to log, then starts the next rest.
- **+15s** extends the rest. **Skip** ends rest, or skips the set once rest is over.
- All three are `Button(intent:)` App Intents and work without unlocking.
- **Tap anywhere else** to open the live workout at that set.
- The activity starts when a set is logged in live mode and ends when the workout ends.
- **Text:** nothing smaller than 16pt. Bundle Fraunces and Hanken Grotesk in the widget extension.
