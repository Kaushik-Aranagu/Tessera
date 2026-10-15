# Tessera v1 feature list

*Product lead, 2026-10-15. v1 = milestones M0 + M1 in `roadmap.md`, confirmed by Kaushik: Workouts plus the home page. Layout, controls and materials follow `spatial-interaction.md`. P0 ships in v1, P1 ships in v1 if it doesn't slip P0, P2 is the next release.*

## 1. Object and class system (the kernel)

| Pri | Feature | Notes |
|---|---|---|
| P0 | Classes with one parent plus traits (`Schedulable`, `Timed`, `Trackable`, `Measurable`) | Defaults override down the chain; field IDs are stable, never names |
| P0 | Typed links with backlinks, parent/child composition | "Linked from 14" is always correct; deleting a workout deletes its sets |
| P0 | Computed fields | Starts with e1RM (Epley) and weekly volume; one expression language for later filters |
| P0 | Generic object page | Path, class line, summary strip, properties (inherited marked), history, links, methods. Every class gets it free |
| P0 | Handles | Every object name is tappable; opening one zooms out of the tapped row, siblings page sideways |
| P0 | Built-in class library | Exercise tree (Exercise > StrengthExercise > BarbellLift > BenchPress…), Muscle, Equipment, Set, Workout, Routine, Task |
| P0 | Typed actions as the only write path ("syscalls"), with an op log | Shared by UI, Tess, App Intents and Undo; the ghost preview and undo depend on it |
| P1 | Plain JSON export | Trust feature for a personal OS |
| P2 | Visual class editor with code view | M3 |

## 2. Workouts

Full spec: `workouts.md`.

| Pri | Feature | Notes |
|---|---|---|
| P0 | **Live workout mode** | Foreground "process": exercises on x, sets on y, exercise page on z; weight dial with plate math, rep drum, hold to log, rest counts down on the dial |
| P0 | **Set logging** | Each set opens prefilled with its target, so one hold logs a planned set. Weight, reps, optional RPE; logging is the "Stamp" moment (number roll, haptic); edit and undo any set |
| P0 | **Personal records** | Best e1RM, best weight at each rep count, best volume; shown as a quiet hint during the set that could beat one, and on the exercise page |
| P0 | **Plans: day** | Routines (Push Day A) with exercises and set schemes; today's routine appears on Today |
| P0 | **Rest-timer Live Activity with lock-screen logging** | Lock Screen and Dynamic Island show the draining rest time and a Done button that logs the planned set, so the phone stays locked on the bench. In the app, a lit seam along the top edge (no pills). Added 2026-10-15 (Kaushik approved Research lab idea) |
| P0 | Exercise object page | Best e1RM, best set, 90-day trend, history, muscles it trains |
| P1 | **Plans: week and month** | Weekly split, weekly sets per muscle vs target, month view as a consistency heatmap |
| P1 | Progression rule | Suggests the next weight when all sets hit the top of the rep range |
| P1 | HealthKit write | Saves each workout to Apple Health |
| P2 | Apple Watch logging, cardio classes | Later |

## 3. Today (home)

| Pri | Feature | Notes |
|---|---|---|
| P0 | **Now** | One next action with its countdown; swipe right done, left "not now", pull for the next three |
| P0 | Compact day strip with a moving "now" marker | Replaces the sky/energy curve, which took too much space for too little information |
| P0 | Today's workout row | "Push Day · 0/5" as a handle; tapping starts or resumes workout mode |
| P0 | Tasks, minimal | Create, finish (the "Ink" moment), roll forward without red |
| P1 | Breathing current tile | The Mosaic glow: the current item catches light every few seconds |
| P0 | **What's running** (spec: `whats-running.md`) | Open loops shown as processes (running, paused, waiting), each with one resume control. v1 has the workout as the first process. Replaces Ready-to-Resume. Added 2026-10-15 (Kaushik approved) |
| P0 | Automatic context save | Leaving an object mid-way (quitting mid-set, leaving a task) saves where you were and the next step, shown in one line on return and in What's running |
| P2 | Full What's running (tasks, waiting-on items), Apps and Review pages, widgets, pinch-to-zoom time | M2 |

## 4. Tess

| Pri | Feature | Notes |
|---|---|---|
| P0 | **The Bar** | One field at the bottom of every screen: type or hold to talk; opens objects, runs commands, captures |
| P0 | **Quick Capture** | On-device Foundation Models turn "3x10 bench 80" or "dentist thu 3pm" into proposed actions |
| P0 | **Ghost preview, then commit** | Tess never writes directly. A capture appears as a faded ghost row (bloom in "acting") that commits on tap or after 2 s, and stays undoable through the op log. Added 2026-10-15 (Kaushik approved) |
| P0 | **Tess's soul: the paint-dab bloom** | Distinct states for idle, thinking, acting and "tap to go home"; it may travel to where she is acting |
| P0 | Personality | Brief, warm, a little dry. Speaks in counts, never guilt. Confirms what she did in one line |
| P1 | Commands | `log bench 82.5x8`, `open push day`, `what's next`, `what did I lift last week` |
| P1 | App Intents | Same actions from Siri, the Action button and Shortcuts |
| P2 | Claude API tasks | Plan my day, shutdown summary, "build me an app" (M4) |

## 5. Foundations that every feature depends on

| Pri | Feature | Notes |
|---|---|---|
| P0 | Theme and tokens | Chosen theme, a few clearly distinct type tiers with big headings and no small text, colour by meaning |
| P0 | Motion system | House spring, directional entrances for page openings, zoom-from-row for depth, Reduce Motion version for each |
| P0 | Empty, loading and error states | Designed, not defaulted |
| P1 | SwiftData + CloudKit sync | Needs the Apple Developer account |

## Build order inside v1

1. Kernel and the generic object page, together with the theme and tokens.
2. Workouts: set logging and live mode first, then PRs, then day plans.
3. Today around the workout row, Now and What's running.
4. Tess: the Bar, Quick Capture with the ghost preview, then her bloom states.
5. P1 items in the order listed.
