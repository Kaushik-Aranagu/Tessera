# Review: PR #317, haptics and reward (head c9f32a9)

QA thread, Oct 15 PT. Static review. Branch ios/haptics-reward, base 865e465. A trial merge onto master 7cae550 is clean, and master hasn't touched `Features/Workout`, `DesignSystem` or PaintKey since the base. 11 files plus clip 33 (590×1282, 60 fps, 52.6 s).

**Verdict: FIX FIRST (one word, H1).** "One haptic per moment" holds in every path I traced. H1 is a crash risk in the Core Haptics reset handler, the same kind of bug as the Speak S2. H2 (Reduce Motion) needs a device check.

## One haptic per moment: PASS
- **Log set:** PaintKey's completion plays `completionHaptic` and turns off its own selection and medium impacts when one is set (Paint.swift:297-304). `.newBest` (`.success`) or `.setLogged` (rigid), never both.
  - For a hold, the haptic lands 200 ms before `action()` (Paint.swift:431-441), so `session.isPersonalRecord` is read before the set is logged.
  - The old second tap on `lastSeated` (`celebrated`) is removed.
  - The touch-down light impact stays; it's a separate moment (the press).
- **Finish:** the key plays `.done` (three beats). `finish(early:)` plays `.done` only for the early path, which has no key, so there's one either way.
- **Rest:** rest-up on screen plays `.timeUp` once, on the rest-to-set edge only when the end time has passed, so it doesn't fire for a skip or an undo.
  - +15 from the countdown tap plays one selection. A horizon drag plays RestHorizon's own selection, and `extendRest()` plays nothing. A fling skip is one selection, and so is the Skip rest key tap.
  - There's no rest notification in the app, so no second buzz in the foreground.
- **WeightReel:** a detent plays either the plate tap (a 5 kg or heavier plate on or off) or the throttled tick, not both as before. A bound plays once per push.
- **RepsRow:** each step plays one of beat, meet or tick. The bound plays once.
- **Edit save** stays `.setLogged`, **undo** stays `.undo`, and the order sheet stays picked up plus selection. Everything goes through `.tesseraFeedback`, and no raw `.sensoryFeedback` is left in the touched files apart from PaintKey's own press.

## Quiet hours: PASS (nothing ambient yet)
- Every haptic wired here comes from a touch, apart from `.timeUp`. `.timeUp` only plays with the workout on screen, during a rest he started.
- The map has `.fleckReachesNow` but nothing plays it yet.
- Note for the PR that wires ambient cues (the fleck, kitchen timers): `Haptic` has no quiet-hours gate. Put one in the modifier, or at the call site with `TesseraDay` quiet hours (23:00-07:00), before any cue fires without a touch.

## CHHaptic lifecycle
- `DonePattern` (Haptics.swift:79-114) keeps one static engine with auto-shutdown and calls `start()` before each play. Any error drops the engine and returns false, and the modifier then plays `.success`. Hardware without haptics returns false at once. That fallback is right.
- **H1 (must fix): the reset handler may trap off the main thread.** `made.resetHandler = { Task { @MainActor in engine = nil } }` (:110) is written inside a `@MainActor` enum. Core Haptics calls the reset handler on its own queue after the haptic server resets, for example after an audio interruption. If the SDK's `ResetHandler` isn't `@Sendable`, Swift 6 infers this closure as `@MainActor` and traps when it's called. That's the same crash class as Speak S2 in review-273.
  - Fix: `made.resetHandler = { @Sendable in Task { @MainActor in engine = nil } }`. It's harmless if the SDK already marks it `@Sendable`.
  - Optionally also set `stoppedHandler` the same way. It isn't needed, because `start()` restarts a stopped engine.
- Low: `engine.start()` is synchronous on the main thread for each done. It's cheap once the engine is warm, but you could warm it with `start()` when the Finish key appears.

## H2 (should check on device): Reduce Motion may drop the Log set haptic
- With Reduce Motion on, `complete()` calls `action()` in the same update as `completions += 1`.
- `logSet()` moves the phase to rest, so the `.set` PaintKey (and the modifier that plays `completionHaptic`) leaves the hierarchy in that same update. Its `onChange(of: completions)` may never run, and if it does run, `isPersonalRecord` already describes the next set.
- This was true of the old `.sensoryFeedback` too, but `celebrated` used to cover it.
- Fix if the device check confirms it: play the set's haptic from `WorkoutContent`'s `onChange(of: session.lastSeated)` through `moment` (whether it was a record is known there), and drop `completionHaptic` from the Log set key. That also gives VoiceOver's "Log set" named action (:621-623), which skips PaintKey, its haptic.

## Visual follow-ups (Design's five): PASS
- **Logged strokes** land wet in their pigment and dry to `restTint` after 1.4 s. Reduce Motion keeps the wet-to-dry fade without the brush.
- **The best subline** lands in cadmium and dries to the context colour after 1.2 s. That closes my note in review-297 about colour at rest.
  - Low: `@Environment(\.self)` on `WorkoutContent` makes the whole workout body depend on every environment value. Pass a flag from `WorkoutLines.subline` ("is best") instead of comparing resolved colours.
- **The rest note** is `Paint.secondary` instead of Tess's colour.
- **UNDO** only shows with its line.
- **"reps"** is 16 pt (the floor).

## Data safety: PASS
- No LaunchFlags or `ProcessInfo` reads, and no UI tests were added.

## Must fix before merge
1. H1: `@Sendable` on the reset handler.

## Design's two questions (answers, not findings)
1. **Does DonePattern respect the System Haptics setting?** Not by our code: `Haptics.swift` only checks `capabilitiesForHardware().supportsHaptics`, which is about the hardware, not the user's switch. The `.sensoryFeedback` cues follow the system setting; whether a custom `CHHapticEngine` pattern is silenced by Settings > Sounds & Haptics > System Haptics I can't confirm statically (Apple docs aren't reachable from this container). Device check: turn System Haptics off, finish a task, expect no done pattern. If it still buzzes, fall back to the `.success` cue (which then stays quiet too) rather than adding our own setting.
2. **Does starting the engine on every play add first-tap latency?** Likely, after idle. With `isAutoShutdownEnabled`, the engine stops itself when nothing has played for a while, and `play()` then calls the synchronous `try engine.start()` on the main actor in the same moment as the strike, so the first done after a pause can land a little late and block a frame. Fix if the device shows it: warm the engine with `engine.start(completionHandler:)` (async) when a finishable row appears or the Finish key shows, and keep `start()` in `play()` as the cheap no-op it is when already running. Device check: leave the app idle a minute, finish a task, and watch whether the pattern trails the strike.

## Addendum: re-check at b6112e6 (Oct 15 PT): PASS once H3 is in (one word)
Rebased on bb57e78; trial merge onto master 9bdc3c7 clean. Clips 33 (52.6 s) and 34 (24 s) are 60 fps.
- **H1 closed.** `Haptics.swift`: `stoppedHandler` and `resetHandler` are `@Sendable` and hop to `@MainActor` for `engine`/`isRunning`; `prepare()`'s start completion is `@Sendable` too. Any failure in `play()` drops the engine and returns false → `.success` fallback.
- **H2 closed.** The Log set and Finish `PaintKey`s are `isSilent` (Paint.swift:300-303). The set's haptic plays from `onChange(of: session.lastSeated)` (`.setLogged`, or `.newBest` in its place), so it survives Reduce Motion and VoiceOver's "Log set" action; done plays from `finish()` for every finish, including VoiceOver's "Finish workout". The old `celebrated` soft impact is gone, so a new best is one haptic.
- **Design's latency question closed.** `DonePattern.prepare()` starts the engine asynchronously on the workout's `onAppear`; `play()` only calls `start()` when it isn't running. Note: if auto-shutdown stops the engine without calling `stoppedHandler`, `isRunning` stays true; the player start then either restarts it (auto-shutdown's normal path) or throws into the `.success` fallback. Safe either way.
- **System Haptics switch:** no public API; stays install-day check 6 (System Haptics off, finish a workout, expect nothing).
- Low closed: the wet flag drives the cadmium-to-context dry (1.2 s + 0.8 s, inside 2 s); `@Environment(\.self)` is gone.
- Data safety: no LaunchFlags, ProcessInfo, UI tests or `project.yml` changes.

### H3 (must fix, one word): "Finish here" plays two haptics
`ExerciseStrip.swift:110`, the running order's "Finish here" `PaintKey`, isn't `isSilent`. Its hold completion plays the medium impact, and its `onFinish` calls `finish(early: true)`, which now plays the done pattern: two haptics for one moment. Fix: `PaintKey(paint: Paint.live, duration: 0.7, height: 64, drift: 20, isSilent: true, action: onFinish)`.

**Verdict: PASS with H3 in.** No re-review needed beyond confirming that one line.

## Addendum 2: 1a2472d (Oct 16 PT, just after midnight): PASS
Only two lines changed since b6112e6, and the trial merge onto master is clean.
- H3 closed. `ExerciseStrip.swift:110`: "Finish here" is `isSilent: true`, so `finish(early: true)` plays the done pattern alone.
- `WorkoutParts.swift:256`: "Save set N" is `isSilent: true`. Its `onSave` bumps `saveHaptic` (WorkoutModeView.swift:615), which plays `.setLogged` (:180), so a save is one tap, not a tick plus a tap.
**Verdict: PASS. Merge-ready.**
