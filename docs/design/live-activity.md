# Rest timer Live Activity

> **Sweep 16 Oct (item 19):** parts of this sheet are amended by `sweep-19.md` (no dots, one base, the context line). Where they differ, `sweep-19.md` wins.

The rest timer lives on the Lock Screen and in the Dynamic Island, so the phone can stay locked on the bench. Mockup: `mockups/LiveFinal.dc.html`. Earlier rounds are in LiveRest, LiveRest2 and LiveType; they were superseded.

**Kaushik's picks (2026-10-15):**
- The layout merges Gesso and Horizon.
- The typeface is **Inter Tight**.
- **No italics anywhere.**
- Colour mood: **Cobalt sky** (final, 2026-10-15).

Principles, from research: one number, one action, the system's own glass, cream numerals.

## Lock Screen (about 366 × 150pt)
- **Background:** the system's own Live Activity material, not a colour field.
  - Two soft blurred washes sit inside it, top left and top right (see Colour moods). In code they are blurred `RadialGradient`s at 40–75% opacity.
- **Countdown:**
  - Inter Tight 48, weight 250 (Light), tracking −2%, tabular figures.
  - The colon is at 55% opacity.
  - Cream `#F6EFE4`.
  - Use `Text(timerInterval:countsDown:)` in a fixed frame.
- **Right column** (from x 206, after a 1px hairline at cream 16%). This is **the Done button**: tapping the set logs it.
  - "Bench" in 17/400 at 62%.
  - "82.5 × 8" in 24/400.
  - A red brush tick (`#E2603F`, 2.6pt stroke) at the top right.
  - The whole column is one `Button(intent: LogPlannedSet)`.
- **Horizon line (the timer):**
  - A 2.5pt cream stroke over a full-width 1.5pt guide at 14%.
  - It drains toward the left as rest runs out.
  - A soft wet tip (14pt, blurred) rides the end.
  - Build it with `ProgressView(timerInterval:)` masked by the curved stroke shape. If the mask can't render, use a straight 2.5pt line.
- **Bottom row:**
  - Left: "Rest, then set 4" in 17/400 at 58%.
  - Right: "+15" and "Skip" in 18/500, split by a hairline. Each is a `Button(intent:)`.
- **No text below 16pt.** Bundle Inter Tight in the widget extension.

## When rest is over: Go
Trigger this with `staleDate` = the end of rest, and branch on `context.isStale`.
- "Go" replaces the countdown. In the activity, use `.transition(.push(from: .bottom))` only; the timing is the system's (an activity runs no explicit animation, so no 14pt, blur or 700ms of ours).
- **The sky warms:** the washes switch to cadmium `rgba(232,189,76,.75)` and vermilion `rgba(226,96,63,.6)` with the system's content transition. No cross-fade of ours.
- The line empties.
- A soft vermilion glow sits behind the tick, still, saying "tap the set". It does not breathe: an activity cannot run the animation.
- "+15" dims to 25%, and the bottom left reads "Rested 2:30".
- **The rest activity carries no alert.** The rest-up signal is notification N2: title "Rest is up", body "Set 3 is next." (or "Next set is ready." when the exercise name is private or empty). If notifications are off, N2 is skipped and the flip by `staleDate` is the only signal. Never both, never repeated.
- **Set aside:** a rest left alone stays on the ready face for 10 min, then the face reads "<title>" over "set aside" (a private title reads "Private workout") and the activity ends. Nothing rings for it.

## Reduce Motion and Low Power on these surfaces
Both are the system's: it simplifies its own transitions and throttles updates. The app authors and tests nothing for either (every clock derives from `endsAt`, and the face flips by `staleDate`). The only app-side rule is **Always-On drops the washes and the horizon**, keeping the word and the time.

## Colour mood: Cobalt sky (final)
| Wash 1 (top left) | Wash 2 (top right) | Line | Tick |
|---|---|---|---|
| cobalt `rgba(63,127,192,.75)` | violet `rgba(122,92,160,.45)` | cream `#F6EFE4` | vermilion `#E2603F` |

Dusk, Sage and Ink were explored on the `LiveFinal` board and not chosen; don't build them.

## Dynamic Island
- **Compact:**
  - Leading: the red tick.
  - Trailing: the time, in Inter Tight 17/400, tabular.
- **Expanded:**
  - The countdown in Inter Tight 40 Light on the left.
  - "Bench" (16) and "82.5 × 8" (21) on the right. This is the Done button.
  - The horizon line along the bottom.
- **Minimal:** the tick.
- The island's capsule outline is the system's. Nothing we draw inside it is a pill.

## Behaviour
- **Done** (tapping the set) logs the next planned set (weight and reps as dialled for it) through the same typed action as hold to log, then starts the next rest.
- **Undo after Done** (a wet palm can tap it): until that rest ends, the right column shows "Set 3 logged" (17/400 at 62%) over **"Undo"** (24/400 in `#FFB896`), and a small curved return arrow replaces the tick. The column is one `Button(intent: UndoLastSet)`. The new rest starts full; the bottom left reads "Rest, then set 4". Undo removes the set through the op log (one undo stack with the app) and returns to the Go state, with "Set 3 taken back" bottom left. When the rest ends, Undo leaves the lock screen. Mockup: `mockups/LiveDetails.dc.html`, moment 7.
- **+15** extends the rest. **Skip** ends rest, or skips the set once rest is over.
- All of these work without unlocking.
- **Tap anywhere else** to open the live workout at that set.
- The activity starts when a set is logged in live mode and ends when the workout ends.

## Constraints
- **Explicit animations are ignored.** Motion comes from the system timers and from transitions up to 2s when the content changes.
- **Always-On:** no ticking. Use `isLuminanceReduced` to show a still "Ready at 18:26" instead of the countdown.
- **StandBy:** the view is scaled 2× and Night Mode tints it red, so check contrast there.
