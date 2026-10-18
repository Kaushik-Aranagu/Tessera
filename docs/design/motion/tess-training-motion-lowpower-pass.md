# Training motion pass: live workout, set logged, new best, rest end (board 63)

Status: lab spec with Normal / Reduce Motion (RM) / Low Power (LP) columns and haptics. Code facts read at master `e8757a6f`
(paths below are relative to `Features/` unless they start with `DesignSystem/`). Rules used: LP = RM everywhere in the
app (D5, a 150 ms crossfade); the soul keeps her own LP form; one haptic per moment, always through `tesseraFeedback`;
his own touches and his own timers play in LP and quiet hours (23:00 to 07:00); the map in `Haptics.swift` wins.

## 1. What the code does today (so the columns are honest)

1. Low Power is read only inside the soul (`Tess/TessSoul.swift:66,109,163,177,200`). The workout corner never enters those
   states, so LP changes nothing in the training flows. No shared flag reaches the workout.
2. A logged set buzzes twice, a new best twice (1.2 s apart), a finish twice. Cause: raw `.sensoryFeedback(.success, trigger: doneCount)`
   at `Tess/TessSoul.swift:143` stacks on the workout's own cue (`Workout/WorkoutModeView.swift:202`, `:706`). Sheet 38:111 says remove it.
3. The rest-end haptic exists once, `moment.play(.timeUp)` at `Workout/WorkoutModeView.swift:140`. It runs in a view's `onChange`, so it
   cannot fire while locked or suspended, and it has no "seen live within 2 s" guard, so it buzzes late on return to the app.
4. The Live Activity flips to Go silently by `staleDate`. The alert sound (`RestActivityController.swift:141-154`) is sent from an
   in-process `Task.sleep`, so a locked phone gets no sound. In the foreground he can get the in-app haptic and the alert sound together.
5. The 1 Hz tick (`WorkoutModeView.swift:85`) is not aligned to `restEndsAt`, so the visible end and the haptic can lag the true end by up to 1 s.
6. The rest-end glint (`Glint`, period 3 s, 1.2 s window) misses entirely in about 36% of rest ends (computed from `TessMotifs.swift:19-21`
   and the 1.2 s window).
7. Not built though sheeted: the set stamp (press 0.94, carry), the new-best sweep, `.bouncy`, the last-10-seconds brighten, the rising
   "+15" label, the finish hero strike and 4 s drain, strip segments that grow per set. `WorkoutLines.subline` never returns `wet: true`,
   so the dry-pigment path is dead code.
8. Raw bypasses of the policy: `DesignSystem/Paint.swift:303` (early-release drain, no RM), `Editorial.swift:77`, `WeightReel.swift:88`.

## 2. Live workout: resting motion

| Element | Normal | RM | LP | Haptic |
|---|---|---|---|---|
| Weight reel scrub | numericText + spring(.3, .8), a detent per 12 pt | opacity content, neighbours off, lands in one step | as RM | `.selection` per detent (30 ms floor); `.plateOnOff` replaces that tick on a plate change |
| Reel at the end | band up to 16 pt, return spring(.3, .7) | no band | as RM | `.bound` once per touch |
| Reps scrub | numericText, 28 pt per rep, pop and 5 droplets | no pop, no droplets | as RM | `.selection` per rep; `.repsMeetLast` once; `.repsBeatLast` once per set (today every re-crossing: fix) |
| Beat-last stroke | 260 ms ease out | 150 ms fade | as RM | `.repsBeatLast` |
| Exercise strip glint | every 4.5 s, 60 fps | no sweep | **no sweep, and the timeline pauses** (today 60 fps always) | none |
| Current-set guide breath | 2.4 s, 20 fps | static 0.9 | static 0.9, timeline paused | none |
| Tess corner breath | 3.2 s, scale 1 to 1.08 | one 150 ms settle | as RM | none |
| Workout body tick | 1 Hz | 1 Hz | 1 Hz; drop to the nearest second boundary of `restEndsAt` (see section 5) | none |

LP rule for the corner: the only continuous things are the strip glint, the guide breath and the corner breath. Under LP all
three stop. The soul keeps her own LP form.

## 3. Set logged (the landing)

Order: hold 0.7 s (PaintKey, silent) → bead → 200 ms → `logSet()` in the house spring (0.42, bounce .12) → stroke paints → numeral turns to
the countdown → horizon draws → Tess line.

| Beat | Normal | RM | LP | Haptic |
|---|---|---|---|---|
| Hold begins | line empties to a trace and repaints under the thumb, 0.7 s | linear fill | as RM | none (today a raw light impact, `Paint.swift:306`, no map row: remove for silent holds) |
| Early release | drains back, 0.22 s ease in | linear, 150 ms | as RM | none (today ignores RM: route through the policy) |
| Seat | stroke paints in, 700 ms; bead lands | stroke appears whole, 150 ms fade | as RM | **`.setLogged`** once (rigid), at the seat |
| Stamp (sheeted, not built) | press 0.94, carry, dissolve | none | none | none; the seat's `.setLogged` is the only cue |
| Numeral to countdown | 320 ms crossfade | 150 ms | 150 ms | none |
| Rest horizon | draws 500 ms, drains | 150 ms, drain steps once a second | as RM | none |
| Tess line "Set 3 logged. 80 x 5." | slides 12 pt in, holds 4 s, UNDO word while `canUndo` | no slide | no slide | none |
| Soul | Done one-shot 1.8 s | still frame | LP form | **none** (remove the raw `.success`) |

Fix for the double buzz: delete `TessSoul.swift:143`; the workout's cue is the only haptic.

## 4. New best (PR)

A best replaces the set's tap with `.newBest` (`.success`), never both (38:81). It is not "the record pattern": that phrase in
live-workout:32 means this cue.

| Beat | Normal | RM | LP | Haptic |
|---|---|---|---|---|
| Before the set (a best is possible) | numeral glint, 3 s period, 30 fps; subline "beats 5RM, was ..." | no glint | no glint | none |
| Logged | stroke paints in cadmium; rule: same 700 ms | whole, 150 ms | as RM | **`.newBest`** once, instead of `.setLogged` |
| Sweep, `.bouncy`, scale 1.06 (sheeted, not built) | one light sweep over the stroke, 900 ms | static cadmium under-stroke for 2 s | as RM | none beyond the one cue |
| Tess line | "New best: 85 x 5." 4 s with UNDO | no slide | no slide | none |
| Soul | one Done, no second chain | still frame | LP form | none (today `.success` 1.2 s later: remove) |
| UNDO within 4 s | the stroke and line leave together | fade | fade | `.undo` once |

Build note: the sweep and bounce are optional; ship the cadmium stroke and the single `.newBest` first. A custom
`CHHapticPattern` for a best is not a map case; the sheet's "record pattern" is retired in favor of `.success`.

## 5. Rest timer end (`.timeUp`)

`.timeUp` is heavy 0.9 and is both the rest end and the kitchen timer end. His own timer: plays in LP and in quiet hours.

| Moment | Normal | RM | LP | Haptic |
|---|---|---|---|---|
| Rest drains | horizon drains once a second linear | steps once a second | steps once a second | none |
| Last 10 s (sheeted, not built) | numeral brightens, wet tip | none | none | none |
| T0, app in front | phase flips at the second boundary of `restEndsAt`; one glint sweep over the numeral, 900 ms; "Go" face rises | no glint; Go fades in 150 ms | as RM | **`.timeUp`** once at T0 |
| T0, locked or backgrounded | face flips to Go by `staleDate` | same | same | notification alert (below), no in-app haptic |
| Back in front after T0 | numeral already Go; no glint | same | same | `.timeUp` only if returned within 2 s of T0; otherwise none |
| Skip (key or fling) | Go shows 0.9 s, horizon leaves | fade | fade | `.selection` only (Skip is not a time-up) |
| +15 (tap or drag) | horizon grows; label rises 10 pt over 900 ms | label fades in place | as RM | `.selection` |

Two rules to build:

1. Drive the flip from `restEndsAt`, not from the 1 Hz tick: schedule the boundary so the visible Go and the haptic land within
   one frame of T0 (today they can lag up to 1 s). Make the glint start at the flip and run once so it never misses (today it misses about 36% of the time).
2. Rest end while locked needs a local notification at `restEndsAt` (title "Set 3 is up", the default sound), because the in-process alert
   cannot fire when the app is suspended. In the foreground, suppress the alert and play `.timeUp` only: never both.
   Quiet hours: his own rest timer rings at any hour (live-workout:52), so the notification is not held.

## 6. Finish and start

| Moment | Normal | RM | LP | Haptic |
|---|---|---|---|---|
| Hold FINISH | fill 0.8 s | linear | as RM | none during the hold |
| Cross to finish view | easeOut(.4), opacity | fade | fade | **`.done`** once at t = 0 (or `.newBest` when the last set was a best) |
| Hero and day line | rise, blur out | fade, no rise | as RM | none |
| Gather strokes | 1.9 s, 22 ms stagger | strokes not drawn; mark fades | as RM | none |
| Soul on gather | one Done | still frame | LP form | none (today a second `.success` ~2.3 s in: remove) |
| UNDO within 10 s | line "<title>, back on." 4 s | fade | fade | `.undo` once |
| START tap | line lifts from the word to the first segment, 520 ms; plan sinks; cover rises on the zoom | no flight; plain cover | no flight; plain cover | **`.made`** once at the tap |

## 7. Tests the build should carry

1. A set logged plays exactly one haptic: `.setLogged`, or `.newBest` on a best, never both; the soul adds none.
2. Finish plays exactly one: `.done` or `.newBest`.
3. Rest end in front plays `.timeUp` once within one frame of `restEndsAt`; returning within 2 s plays it, returning later does not.
4. Locked rest end schedules one local notification at `restEndsAt`; in the foreground it is cancelled.
5. LP on: strip glint, guide breath, corner breath and the PR glint stop; set seat, countdown and Go are 150 ms fades.
6. Early release of the log hold animates through the policy (no raw `withAnimation`).
7. `.repsBeatLast` plays once per set.

## 8. Code gaps, in the order the build should take them

1. Delete the raw `.success` (`TessSoul.swift:143`). Two to three buzzes become one.
2. Drive the rest flip and haptic from `restEndsAt`, add the 2 s guard and the local notification.
3. Read the shared reduced flag in the workout corner (strip glint, guide breath, corner breath).
4. Route `Paint.swift:303` and the silent-hold press tick through the policy.
5. Optional later: stamp, new-best sweep, last-10-seconds brighten, "+15" label, per-set strip segments, finish hero strike and 4 s drain.

## 9. Open for Product

Default taken, change on a word: the local rest-end notification (item 2 of section 5) is built; it is a new outward surface,
so flag it for the build lead before it ships.
