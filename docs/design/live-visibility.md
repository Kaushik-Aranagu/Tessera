# Live only when seen (visibility switches)

Kaushik, Oct 26: UI animation and rendering run only while he can see that part of the screen. Off-screen, only the
data layer updates. When a page or element comes into view it renders and animates from the current data. Each
feature declares whether it is UI-read or background-only, behind a switch.

Code: `DesignSystem/Live/` (`LiveFeature.swift`, `LiveRegistry.swift`, `LiveRegion.swift`), tests in
`TesseraTests/LiveGateTests.swift`. Not compiled yet (written off the Mac); Core or a builder runs the tests.

## The rule

A feature is **live** when its mode, its switch and what he can see all agree (`LiveGate.isLive`):

| Switch | Result |
|---|---|
| `auto` and mode `uiRead` | live only if scene is active, the region is on screen, and every enclosing `liveScope` is on |
| `auto` and mode `backgroundOnly` | never live (data only; a still is drawn from current data on appear) |
| `alwaysLive` | live always (the old behaviour; exists so one build can measure before and after) |
| `dataOnly` | never live |

Data never waits on this. Stores, the engine, Tess and weather fetches keep running. Only drawing, `TimelineView`
ticks, `repeatForever` loops, Canvas painters and per-frame tasks stop.

## The primitive (what owners use)

1. Declare the feature once in `LiveFeatures` (id, title, owner, mode, cost).
2. Wrap its root: `.liveRegion(LiveFeatures.lookoutSky)`. Descendants get `\.isLive`.
3. Replace clocks: `TimelineView(.animation(...))` becomes `LiveTimeline(minimumInterval:)`; `.periodic` becomes
   `LivePeriodic(every:)`. Paused, they hold the last frame; on return the next frame is drawn from the current
   date and data. Nothing replays or catches up.
4. Replace loops: `repeatForever` started in `onAppear` becomes `.liveTask { ... }`, which starts when live and is
   cancelled when not. Start loops from `isLive`, not from `onAppear`.
5. The shell marks pages: `.liveScope(isCurrent && !covered)` on each page in the pager and on whatever a sheet,
   Tess or the dial covers. Leaves never read the scope; they just use `liveRegion`.

Reduce Motion: `LiveTimeline` never ticks with it on (as most sites already do).

## What each owner changes

Builders A and B own the files; this thread does not edit them. Counts come from a grep of the branch.

- **Shell (Builder A):** `.liveScope` on each `PlaceHost`/page and on covers. This is the one change that makes
  all the rest correct, because `onAppear` alone is not enough in a pager that keeps pages resident.
- **Builder A (motion, looks):** Lookout sky and glass (`WeatherLanding.swift:315`, 60 fps, ungated), Deck
  blackboard (`TrainingBlackboard.swift:358`) and wall (`TrainingWallLanding.swift:221`, 60 fps, ungated),
  `LandingGlyph:316`, `WatchHandOver:30` (60 fps, ungated), Tess soul and motifs (`TessSoul`, `TessMotifs`),
  `ThinkingIndicator:20` (60 fps), `Machined:189`, `SetMark:292`, `Paint.swift:123` (repeatForever),
  `ThemeLayers:128`, Workout (`ExerciseStrip:40`, `LiveSetMarks:131,136`, `SwapPanel:137`).
- **Builder B (screens):** Watch woodland (`RoutinesWoodlandScene:51`), Galley rail and the Cook clock
  (`CookClockParts:264`, `CookClockPage:257`), the Bridge mosaic (`MosaicView:352`, `MosaicHomeLayer:490`,
  `HomeMosaicPage` which already tracks `onScreen`, `WeatherWordEffects:36`), Now, DayStrip, HomePlan.
- **Core:** nothing in the engine. If a data job exists only to feed a view, ask for a pull, not a push.

Already partly gated by hand (`scenePhase`, `onScreen`, `visible`): `HomeMosaicPage`, `DepartureBoard`,
`MosaicHomeLayer`, `CookClock*`, `WeatherWordEffects`. These move to the primitive so there is one rule.

## Data layer stays current; the view catches up

When data changes while a feature is not live, it just stores the new state. On return the view draws that state
directly, with no replay of missed changes. Entrance moves still play on arrival (the keystone's 0.94 settle), and
should key off `isLive` going true, not `onAppear`.

## Compatibility with the element contract (PR #1434, `docs/ai/harness/elements.md`)

- A place's `ElementMeaning` stays truthful whether or not the place is live. "On screen" in `TessFrame` means
  what he sees; it must read `isLive`/the scope, not what is resident. Suggested field: `ElementMeaning.isShown`
  fed from the same `liveScope` the shell sets. The frame's referent order (touch, widget, page, keystone, dial)
  should only consider shown places.
- A Tess call on an element that is not live **applies to data immediately** (the ghost row and Undo timer start)
  and the `Reaction` is skipped; the element arrives already changed. The Undo window and the Tess-blue dry-out
  run on the clock, not on rendering, so they finish correctly while unseen. If the element comes into view
  during the window, it plays the reaction's final state, not the whole move.
- Each `LiveFeature.id` is the element id for the switch. A later Tess tool can set a `LiveSwitch` (for example "stop
  animating the sky"), which is a shell call (writes nothing to user data).

## Measure before and after

Per feature and for the whole app, on the iPhone 17 simulator, same build, one run each:

1. Before: `LiveRegistry.shared.setAll(.alwaysLive)`. After: `setAll(.auto)`.
2. Script: Bridge 20 s, swipe through every landing 10 s each, open a Level 1 page, background the app 20 s.
3. Capture: Instruments Animation Hitches and Time Profiler (CPU %), Energy Log, frames drawn per second from the
   `live` signpost category (`LiveRegistry` logs one interval per live stretch), plus `liveSeconds` per feature.
4. Report: CPU and frames/s while a landing is in front, and while a different one is, before and after.

Expected: pages that are not in front go from their full tick rate to zero. The simulator is not an energy
reading; confirm Energy on the phone once.

Not measured yet. This needs the Mac.
