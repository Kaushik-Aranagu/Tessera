# QA review 273: Speak (#273)

Merge 5dff9f8, head 1313275, 9 files (+801/-289, plus docs/recordings/speak.mp4). Static review; no toolchain here, and no real speech on the Simulator.

**Verdict: PASS for data safety and the install.** No reverts against the first parent. Nothing here can touch his data.

**Speak itself has two should-fixes that will likely stop it working on the phone (S1, S2), plus one visible copy regression (S3).** One Simulator tap of Speak, without `-speakScript`, checks S1 and S2 before Oct 22.

## Confirmed (the coordinator's list)
- **`-speakScript` is simulator-only:**
  - It is read through `LaunchFlags.has` at both reads (BottomChrome.swift:112 and :542), inside `#if DEBUG`, and LaunchFlagsTests covers it.
  - `SpeechListener.playScript` only sets `heard` and `level`; it touches no mic or data.
  - No `ProcessInfo` reads were added.
- **On-device only:**
  - `request.requiresOnDeviceRecognition = true` is set on every request (SpeechListener.swift:118).
  - A recognizer without `supportsOnDeviceRecognition`, or one that isn't available, returns `.noLanguage` before any audio is captured. Audio never leaves the phone.
- **Purpose strings** (project.yml:75-76) are true to the code:
  - Mic: "Tess listens only while you talk to her … Audio stays on this iPhone."
  - Speech: "Tess turns what you say into text on this iPhone. Audio is never sent anywhere."
  - Info.plist is generated, so they ship.
- **Refusal lines** match speak.md:
  - "Mic is off for Tessera." and "Speech is off for Tessera." come with **Open Settings** (`UIApplication.openSettingsURLString`).
  - "Voice isn't available in this language yet." and "The mic is busy with a call." come with **Write**, which opens the Write line focused.
  - From a hold, the line shows beside the soul as "… Write still works."
  - Tested in `SpokenPhraseTests.refusalsSayWhatStillWorks`.
- **"undo" by voice:** only the whole phrase "undo" or "take that back" counts (punctuation and case ignored), so "undo the bench set" is a capture. It calls the same `undo()` as the UNDO word: Home's last op first, else the last capture.
- **Dated-lift Log / Not now** go through `AppModel.answer(_: TessDatedLiftAsk.Choice)`, then `TessCaptureEngine.answer`, then `land` (AppModel.swift:183-193). That is the same path as a capture, so ghost rows and drying behave the same. An empty line says nothing.
- **Closes review-264:**
  - C1: `ValueWordStyle` is gone.
  - C2: an empty answer line is never said.
  - C3: `setAsk` clears when the workout ends (BottomChrome.swift:99-103).
  - C5: Log / Not now words exist.
- **Listening limits** match speak.md: 1.2 s pause, 5 s first word (tap only), 60 s cap. A veil tap or a drag off the soul cancels and sends nothing.
- **Recording:** 872 of 911 frame gaps are 15.7 ms (about 64 fps). The two long gaps are still screens. Pass.

## Should-fix
- **S1: `.duckOthers` isn't allowed with `.record`** (SpeechListener.swift:114).
  - Apple's docs for `duckOthers`: "You can set this option only if the audio session category is playAndRecord, playback, or multiRoute."
  - With `.record`, I expect `setCategory` to fail with a parameter error. `begin` throws, and every listen then ends in the `.busy` refusal: "The mic is busy with a call."
  - Fix: `try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])`, or `.record` with no options.
- **S2: callbacks off the main thread inside a `@MainActor` class** (SpeechListener.swift:77, :123, :131).
  - Three callbacks are written inside `@MainActor` methods: `SFSpeechRecognizer.requestAuthorization`'s handler, `installTap`'s block (the audio thread) and `recognitionTask`'s result handler.
  - Apple's declarations for all three are plain, non-`@Sendable` closures (`AVAudioNodeTapBlock = (AVAudioPCMBuffer, AVAudioTime) -> Void`).
  - In Swift 6 mode, closures like these are inferred `@MainActor`, and the runtime checks the isolation when they're called. Speech and AVAudio call them on background queues, so this is the well-known `_dispatch_assert_queue_fail` crash, on the first Speak.
  - Fix:
    - Mark each closure `@Sendable`: `{ @Sendable status in … }`, and `{ @Sendable [weak self] result, error in … }`, which already hops to the main actor with `Task { @MainActor … }`.
    - For the tap, build the block in a `nonisolated static func tap(for request:) -> AVAudioNodeTapBlock` so the non-Sendable request isn't captured from main-actor code.
- **S3: every spoken capture is lowercased** (BottomChrome.swift:585).
  - `TessSpoken.numbers` lowercases the whole phrase, turns hyphens into spaces and drops a trailing full stop (TessSpoken.swift:9-11).
  - It's now applied to every voice capture, not only to live set phrases, so "Call Mum at seven." lands as "call mum at 7", and Trader Joe's as "trader joe's".
  - The grammar already normalises live set phrases itself (TessGrammar.swift:117).
  - Fix: use `TessSpoken.numbers` here only while a workout is running (`model.session != nil`), and pass `SpokenPhrase.clean(heard)` otherwise. Longer term, Core could give `numbers()` a case-preserving mode.

## Lows
- **U1:** "like" is in the filler list, so "things I'd like to do" becomes "things I'd to do". Drop "like", or only drop it when it stands alone between commas.
- **U2:** "undo" by voice with nothing to undo says nothing. The undo rule wants "name the thing, then what happened", so say "Nothing to undo." when neither a Home op nor a capture is there.
- **U3:** `stop(send:)` is guarded on `.listening`/`.asking`, but `playScript` sets `.listening` again before its own stop. That's harmless and debug only.

## Install-day checks (add to install-day-script.md)
1. **Simulator, before Oct 22:** launch without `-speakScript` and tap Speak. Expect the two permission prompts and then "Listening" (the Simulator uses the Mac's mic). A crash means S2. "The mic is busy with a call." means S1.
2. **Phone:** tap Speak, allow both prompts, say "bench 80 for 8" in a workout, and expect a set. Then say "undo" and expect the set to go. Turn the mic off in Settings and expect "Mic is off for Tessera." with Open Settings.
