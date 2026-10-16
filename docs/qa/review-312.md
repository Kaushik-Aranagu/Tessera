# Review: PR #312, Builder B's Speak fix (head dbf74be), the install gate

QA thread, Oct 15 PT. Static review plus a read of `docs/recordings/speak-first-tap.mp4`. Base ec3071c, which is on master. Files: `Features/Command/BottomChrome.swift`, `Features/Command/SpeechListener.swift`, `TesseraTests/SpokenPhraseTests.swift` and `TesseraUITests/SpeakSmokeUITests.swift` (new).

**Verdict: FIX FIRST (two one-line fixes).** S1-S3, U1 and U2 from review-273 are fixed, and the mic crash fix is right. But the new UI test would run on his phone (F1, a data-safety rule), and a refused hold now opens Tess when he lets go (F2). Fix both, and it passes the gate.

## review-273 items
- **S1, closed.** The category is now `.playAndRecord`, mode `.measurement`, options `[.duckOthers, .defaultToSpeaker]` (SpeechListener.swift:117-118). `.duckOthers` is valid with that category. The recording shows "Listening" after both Allows, not "busy".
- **S2, closed.**
  - `requestAuthorization`'s handler is `@Sendable` (:80).
  - The recognition handler is `@Sendable [weak self]` (:136). It reads the text and done flag on Speech's queue, then hops with `Task { @MainActor }`.
  - The tap block is built in a `nonisolated static func tap(appendingTo:level:)` (:191-199). The `level` closure is `@Sendable` and hops to the main actor.
  - So no closure that runs off the main thread is inferred `@MainActor`. The recording shows no crash through both prompts and into listening.
- **S3, closed.** `TessSpoken.numbers` runs only when `model.session != nil`. Elsewhere `SpokenPhrase.clean(heard)` keeps the case: "Call Mum at seven." keeps "Mum", and "Trader Joe's" keeps its capitals (BottomChrome.swift:617-620).
  - Low: outside a workout, spoken number words now depend on the recognizer's `formattedString`, which normally gives digits ("at 7"). That's fine.
- **U1, closed.** "like" is gone from the fillers, and the test "I'd like to stretch" is added.
- **U2, closed.** "undo" with nothing to undo says "Nothing to undo." It uses the same `canUndo` that shows the UNDO word.

## The two master bugs Builder B fixed
- **A single tap never opened Tess.** Taps are now read in the touch-down `DragGesture(minimumDistance: 0)`'s onEnded, when the touch moved less than 12 pt and no hold was listening (BottomChrome.swift:249-255).
  - `soulTapped()` (:525-538) holds a first tap for 260 ms. A second tap in that window cancels it and calls `onSoulDoubleTap()`, so double tap still goes Home. Otherwise `toggle()` opens or closes.
  - VoiceOver gets a default action (`toggle`) plus the "Go home" and "Talk to Tess" named actions.
  - The recording shows one tap opening Speak, Write and Show.
- **Hold to speak still works.** The 400 ms hold timer is unchanged (:237-242). It needs the finger still down and Tess closed. Letting go while listening sends, and dragging left past 60 pt cancels (:250-252).
- **SIGABRT after Allow.** `session.isInputAvailable` is checked after `setActive` and before `engine.inputNode` (:121). A missing input throws, and `start` stops the audio and returns `.busy`.
  - Low: with no input route the line reads "The mic is busy with a call.", which isn't quite true. That's rare on an iPhone. A "noInput" line could come later.

## F1: the new UI test runs on his phone (must fix)
- `SpeakSmokeUITests` subclasses `XCTestCase` (SpeakSmokeUITests.swift:6). Every other UI test subclasses `SimulatorOnlyTestCase`, which throws `XCTSkip` off the simulator (SimulatorOnly.swift:5-11).
- On his phone, this test would launch his real app, tap the soul and Speak, and tap Allow on the system prompts. It goes against the standing rule that UITests skip on device.
- Fix: `final class SpeakSmokeUITests: SimulatorOnlyTestCase`.

## F2: a refused hold opens Tess on release (must fix)
- When a hold is refused (mic or speech off, no language, busy), `speak(hold:)` sets `holdListening = false` and says the line beside the soul (BottomChrome.swift:576-584).
- When he lets go, onEnded sees `holdListening == false` and a still finger, so it calls `soulTapped()`, and 260 ms later Tess opens. speak.md and the code comment both say that from a hold "the layer doesn't open".
- Fix: a `@State var holdFired` set when the hold timer fires, and `else if !holdFired, …` in onEnded, reset on the next touch-down. A release after any hold (refused or not) is then never a tap.

## Data safety and the gate: PASS
- No LaunchFlags or `ProcessInfo` reads were added to the app. The only flag in the touched code is the existing `-speakScript`, read through `LaunchFlags.has` inside `#if DEBUG`. The `ProcessInfo` read for `UITEST_SNAPS` is in the test runner, not the app.
- `project.yml` is untouched, so the scheme args stay empty.
- Nothing here writes to the store, except through the existing capture path after he speaks.

## Recording
- 590×1282, **30 fps** (1577 frames, 52.6 s).
- It shows one tap opening Speak, Write and Show; the mic prompt with the purpose string; the speech prompt; both Allows; then "Listening"; then back to Home with "Hold me to talk." There's no crash and no "busy".
- Low: the rule for UI PRs is a 60 fps clip. This is a smoke clip, so it's Design's call.
- Note: the system speech prompt itself says "Speech data from this app will be sent to Apple". That's Apple's fixed text, shown even though every request is on-device (`requiresOnDeviceRecognition`). Our own line under it says audio is never sent. Nothing to fix, but Kaushik may ask about it on install day.

## Install-day checks (add to install-day-script.md)
1. One tap on the soul opens Tess, and two taps go Home.
2. Hold, allow both prompts, say "call Mum at 7", and expect a capture with "Mum" capitalised.
3. With Mic off in Settings, a hold says "Mic is off for Tessera. Open Settings still works." and Tess stays closed (F2).
4. Say "undo" with nothing to undo, and expect "Nothing to undo."
5. The first hold before any Allow: if the system prompt takes the touch, check the soul doesn't stay swollen and listening after the prompts. The gesture is cancelled with no onEnded. This can't be checked statically.

## Must fix before it passes the gate
1. F1: `SpeakSmokeUITests: SimulatorOnlyTestCase`.
2. F2: a hold that fired is never also a tap.
