# Ship now: the rough first cut of every research brief

*Research lab, 2026-10-15. Kaushik's rule is velocity over perfection: ship rough features fast and improve them while he uses the app. This page cuts the 9 briefs down to what a build team can start today. Everything else waits until real use shows it is needed.*

## iOS build

| Ship today (rough) | Skip for now |
|---|---|
| Each set opens prefilled with its target; one hold (about 0.6 s) logs it; Undo until the next set is touched | Momentum dial physics, tick sharpening |
| A dial with plus/minus one-plate taps that snaps to loadable weights | The chamfer shader, odometer TextRenderer |
| Rest Live Activity: `Text(timerInterval:)` countdown, Done / +15s / skip buttons via `LiveActivityIntent` | Dynamic Island polish |
| Dial and drum as `accessibilityAdjustableAction` elements, targets of 60 pt or more | A full XCUITest accessibility audit |
| "What's running" concept A: rows under Now; a running workout becomes Now; resume lands on the set | Auto-archive at 3 and 7 days, lit-seam states |

## Core engine

| Ship today (rough) | Skip for now |
|---|---|
| Keep SwiftData with the generic tables as they are | The GRDB/SQLiteData switch (revisit before sync) |
| A simple op log: who, what, and how to reverse it; drives Undo | Time travel, replayable export, sync |
| A `Process` class with state, resume point and next step | Waiting-on and check-back fields |
| Seed about 30 common exercises now; grow toward the 69 list later | Variant families, fractional sets per muscle |
| Quantities stored in kg and seconds | Versioned class packages with an overlay |

## Tess

| Ship today (rough) | Skip for now |
|---|---|
| Quick Capture through `@Generable` into typed actions, shown as a ghost row that commits after 2 s | The four-step model router |
| The system prompt from `tess-voice.md`, used as written | Tone evals, the weekly read |
| A fixed grammar for `log bench 82.5x8` and "same again" | Voice shorthand through the model |

## Design studio

Give iOS build the hold-to-log haptic pattern and the look for "What's running" rows. Polish can come in a later pass. Shaders and the bloom states can follow once the screens exist.

## Product lead

Mark the "skip for now" items as fast-follow, not cut, so they come back once Kaushik has used the rough version.
