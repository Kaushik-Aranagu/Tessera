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
