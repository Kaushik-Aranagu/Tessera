# Speech capture for Ask Tess

For: Product lead, Core engine, Builder B (the Bar). Research lab, 2026-10-15.
Board task: on-device speech to text for the Ask Tess capture surface. Closes v1 slice 17 ("Voice in the gym", audit: missing).

## What exists on origin/master (`215f70e`, read only)

- No Speech, `SFSpeechRecognizer`, `SpeechAnalyzer` or `AVAudioEngine` code anywhere. `BottomChrome.swift` says "No mic glyph until voice ships (slice 17)".
- `project.yml` sets only the two HealthKit usage strings. No `NSMicrophoneUsageDescription`, no `NSSpeechRecognitionUsageDescription`. `App/Tessera.entitlements` holds HealthKit only.
- `TessGrammar.normalize` lowercases, maps `×` to `x`, splits `80kg` to `80 kg`, and nothing else. Every number must already be digits: `Double(token)`. No number words, fillers or homophones, which is why eval rows 45 to 52 in `tess-eval-claude.md` all fail the grammar today.
- `TessCapture.Source` is `grammar`, `model`, `none`. The model layer brief adds `claude`.
- Aliases already cover `rdl`, `squats`, `bench`, `dl`; the library has "Ab Wheel Rollout" with aliases "Ab Rollout", "Ab Wheel".

## 1. Recommendation

**Use `SpeechAnalyzer` with `SpeechTranscriber` (iOS 26+, on device), hold-to-talk on the Bar, and a spoken-text normaliser in TesseraTess before the grammar. Fall back to `DictationTranscriber` when `SpeechTranscriber.isAvailable` is false.** Reasons: it is Apple's current model, transcription never leaves the phone, it works offline once the locale asset is installed, it needs no entitlement under free signing, and it streams volatile text so the Bar can show words while he is still speaking. Skip the legacy `SFSpeechRecognizer`: on-device mode is opt-in, Apple says it is less accurate, and its permission prompt exists only because it can send audio to Apple's servers.

| Question | Answer | Status |
|---|---|---|
| Runs offline | Yes once the model is installed. WWDC25 277: "transcription is entirely on device but the models need to be fetched." The models live in system storage, not the app | Verified (on device). Airplane-mode run on his phone still to do |
| Asset download | `AssetInventory.assetInstallationRequest(supporting:)` then `downloadAndInstall()`, one time per locale, needs network. Apps can hold a limited number of locales | Verified |
| Locale | Use `SpeechTranscriber.supportedLocale(equivalentTo: .current)`, never raw equality (forum reports `en_GB` vs `en-GB` mismatches). en-GB is reported as supported; **en-IN is unverified**, check `supportedLocales` on his phone | Partly verified |
| Volatile vs final | `reportingOptions: [.volatileResults]` gives fast rough guesses that are replaced; `result.isFinal` marks the final text. Without the option you only get finals | Verified |
| Latency | Apple gives no numbers ("low latency", "very little startup time"). `prepareToAnalyze(in:)` preheats. Targets to measure: first volatile word under 300 ms, final text under 600 ms after release | **Unverified**, measure |
| Custom vocabulary | `AnalysisContext.contextualStrings` (up to 100 short phrases) is documented **for `DictationTranscriber` only**, plus `SFSpeechLanguageModel` custom models and a `.shortForm` hint. Nothing documented for `SpeechTranscriber` | Verified (docs). Whether `SpeechTranscriber` honours it is unverified |
| Simulator | `SpeechTranscriber.isAvailable` is false and `supportedLocales` is empty on the Simulator (forum, Xcode 26.1) | Reported, not Apple doc. Test on device |
| Hardware | "certain hardware requirements" for `SpeechTranscriber`, not listed. `DictationTranscriber` covers older devices | Partly verified |
| Keyboard dictation | Zero code: the Bar's text field already gets the keyboard mic. The text arrives as typed input and goes through the same normaliser. Whether it stays on device depends on system settings and language | Works today; on-device status **unverified** |

**Vocabulary trade-off.** Exercise names are the only words where `DictationTranscriber` might win (contextual strings for "RDL", "OHP", "Ab Wheel Rollout"). Slice V3 runs both modules on the same 30 phrases in his gym and keeps the winner. Until then the normaliser's spoken alias table carries vocabulary ("are DL" to `rdl`, "roll out" to `rollout`).

## Gym noise

The API gives no noise control: no gain, no noise floor, no confidence threshold on `SpeechTranscriber` results (unverified whether `Result.alternatives` exists; do not rely on it). Apple calls `SpeechTranscriber` "accurate even at longer distances". What we control:
- **Push-and-hold, not always-listening.** Always-listening in a gym hears music, other people and plates, keeps the mic on (orange dot) and drains battery. Holding the Bar puts the phone near his mouth and gives a hard start and stop, so there is no end-of-speech detection to tune.
- **Keep his music playing.** Audio session `.playAndRecord`, mode `.spokenAudio`, options `[.mixWithOthers, .allowBluetoothA2DP]`, and no Bluetooth HFP, so input is the phone mic and AirPods stay on high-quality playback. Unverified on device: route behaviour with AirPods connected.
- **Optional:** `inputNode.setVoiceProcessingEnabled(true)` adds Apple's echo cancellation and noise suppression but ducks other audio. Try it in V3 only.
- **Plausibility, not trust.** The ghost row shows "Heard: ..." under every voice parse, voice sets go through the same loadable-weight and 1 to 30 rep checks as the dial, and anything doubtful shows alternatives instead of auto-committing (`grammar-collisions.md` rule 9).

## Permissions and free signing

- `NSMicrophoneUsageDescription` is required (the app crashes without it on mic access). Prompt with `AVAudioApplication.requestRecordPermission()` on the first hold, never at launch.
- Apple: the speech authorization flow "only applies to speech recognition using `SFSpeechRecognizer`. `SpeechAnalyzer` transcriber modules don't send audio data of the user's voice to Apple's servers." So no `SFSpeechRecognizer.requestAuthorization` call and no second prompt. Still add `NSSpeechRecognitionUsageDescription`, because an older note says a missing key crashes "APIs of the Speech framework" (unverified for `SpeechAnalyzer`; the key costs nothing).
- **Free signing: no entitlement or capability is needed** for Speech or the mic (neither appears in the capabilities list). Only the Info.plist strings. The 7-day Personal Team re-sign does not affect installed speech assets (system storage). Asset download is a system service, not an app capability.

Add to `project.yml`, Tessera target, `settings.base`:
```yaml
INFOPLIST_KEY_NSMicrophoneUsageDescription: Tess listens while you hold the bar, so you can log sets by voice. Audio stays on this iPhone.
INFOPLIST_KEY_NSSpeechRecognitionUsageDescription: Tess turns what you say into text on this iPhone. Audio is never sent anywhere.
```

## 2. Swift sketch

An actor in the app (Features/Command), not in TesseraCore. Not compiled; signatures from the Speech docs.

```swift
import AVFoundation
import Speech

actor TessListener {
    private let audio = AVAudioEngine()
    private var analyzer: SpeechAnalyzer?
    private var input: AsyncStream<AnalyzerInput>.Continuation?
    private var results: Task<String, any Error>?

    /// Press: start the mic and stream volatile text to the Bar.
    func start(locale: Locale, onVolatile: @escaping @Sendable (String) -> Void) async throws {
        let transcriber = SpeechTranscriber(locale: locale, transcriptionOptions: [],
                                            reportingOptions: [.volatileResults], attributeOptions: [])
        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
        else { throw TessListenerError.assetsMissing } // prepare() installs them ahead of time
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        try await analyzer.prepareToAnalyze(in: format)
        let (stream, continuation) = AsyncStream.makeStream(of: AnalyzerInput.self)
        let converter = AnalyzerInputConverter(analyzerFormat: format)
        let node = audio.inputNode
        node.installTap(onBus: 0, bufferSize: 1024, format: node.outputFormat(forBus: 0)) { buffer, _ in
            for item in (try? converter.convert(buffer, at: nil)) ?? [] { continuation.yield(item) }
        }
        results = Task {
            var final = ""
            for try await result in transcriber.results {
                let text = String(result.text.characters)
                if result.isFinal { final += text } else { onVolatile(final + text) }
            }
            return final
        }
        try await analyzer.start(inputSequence: stream)
        try audio.start()
        (self.analyzer, input) = (analyzer, continuation)
    }

    /// Release: stop the mic, finalize, and hand the final text to the router.
    func stop() async throws -> String {
        audio.inputNode.removeTap(onBus: 0); audio.stop()
        input?.finish()
        try await analyzer?.finalizeAndFinishThroughEndOfInput()
        return try await results?.value ?? "" // results end when the analyzer finishes
    }
}
```
A `prepare()` on the same actor runs `AssetInventory.assetInstallationRequest` when the Bar first appears (not at launch), and the Bar model calls `router.capture(TessSpokenNormalizer.normalize(text), modality: .voice)` with the returned text. Swift 6 will flag the non-Sendable converter in the tap closure; wrap it in a small `@unchecked Sendable` box. A cancel (drag off the Bar) calls `cancelAndFinishNow()` and drops the text. iOS 27 adds `CaptureInputSequenceProvider`, which could replace the `AVAudioEngine` tap; its exact use is unverified, so the sketch keeps the documented iOS 26 path.

## 3. The normaliser

`TessSpokenNormalizer.normalize(_:) -> String` in TesseraTess: pure, Sendable, idempotent on typed text, so it runs on every capture (voice, keyboard dictation and typing). Order:
1. **Skip notes.** A leading `note`/`note:` keeps the body exactly as heard. Strip sentence punctuation (`.` `?` `!`) and commas the transcriber invented, except inside numbers.
2. **Fillers.** Drop `um`, `uh`, `erm`, `er`, `hmm`; `like` only when next to a number or at the start ("I'd like to swim" keeps it); leading `so`, `okay`, `right`.
3. **Number words to digits.** "eighty" 80, "a hundred and two point five" 102.5, "eighty two and a half" 82.5, "one forty" 140 (two-part weights, 100 to 300), "thirty twos" 32. `and` inside a number run joins it. Fix transcriber time formats in a lift: `1:40 for 4` becomes `140 for 4` when followed by `for`/`x`/`by`.
4. **Self-correction.** `no wait`, `sorry`, `i mean`, `actually` followed by a number replaces the last number before it.
5. **Units.** `kilos`, `kilo`, `kilograms`, `kgs`, `k` after a number become `kg`; `pounds` becomes `lb`.
6. **Operators.** `for`, `by`, `times` between two numbers become `x`. `set of N` becomes `N`; `N sets of M` becomes `NxM`; a trailing `reps`/`rep` is dropped.
7. **Homophones, only in a fixed position.** `for` after a number and before nothing or another `for` becomes `4` ("140 for for" to `140 x 4`); `two` after `remind me`, `need`, `have` becomes `to`; `to` between two numbers becomes `x` except after `drop`; a leading `by` (not before a number) becomes `buy`.
8. **Spoken aliases.** `are dl`/`r d l` to `rdl`, `o h p` to `ohp`, `dead lift` to `deadlift`, `roll out` to `rollout`, `pull ups` stays (grammar alias).

What the normaliser never does: split run-ons (grammar rule 3), guess a domain, or touch a note. Whatever the grammar still cannot parse goes to the on-device model, then Claude, unchanged from `tess-model-layer.md` section 5, with the voice transcript as the phrase.

## 4. Thirty spoken phrases

Context W = live workout, Bench Press in focus, last set 80 x 8. I = idle, Thu 18:00. C = cooking. "Raw" is a likely transcript, not measured. G = grammar takes it, M = model layer (on-device, then Claude), GC n = `grammar-collisions.md` rule or row.

| # | Ctx | He says | Raw transcript (likely) | Normalised | Expected parse or tool |
|---|---|---|---|---|---|
| 1 | W | eighty for seven | 80 for 7 | 80 x 7 | G: set Bench 80 x 7 |
| 2 | W | same | Same. | same | G: set 80 x 8 |
| 3 | W | eight | Eight. | 8 | G: set 80 x 8 (reps only) |
| 4 | W | eighty for four | 84 | 84 | **Trap.** Voice rule: a bare number over 30 is never reps; ambiguous "84 x ?" or "80 x 4", no auto-commit |
| 5 | W | a hundred and two point five for five | 102.5 for 5 | 102.5 x 5 | G: set 102.5 x 5 |
| 6 | W | eighty two and a half for six | 82 and a half for 6 | 82.5 x 6 | G: set 82.5 x 6 |
| 7 | W | drop to seventy for ten | Drop to 70 for 10. | drop to 70 x 10 | G: drop set 70 x 10 ("to" kept after drop) |
| 8 | W | uh like eighty for like seven | Uh, like 80 for like 7. | 80 x 7 | G: set 80 x 7 |
| 9 | I | um squats um hundred for five | Um, squats, um, 100 for 5. | squats 100 x 5 | G: Back Squat 100 x 5 (eval 47) |
| 10 | I | deadlift one forty for for | Deadlift 1:40 for four | deadlift 140 x 4 | G: Deadlift 140 x 4. **Trap:** raw 1:40 reads as a time (eval 48) |
| 11 | I | RDL sixty for ten | Are DL 60 for 10 | rdl 60 x 10 | G: Romanian Deadlift 60 x 10 |
| 12 | I | ab wheel rollout three sets of ten | Ab wheel roll out 3 sets of 10 | ab wheel rollout 3x10 | M: `logSet` Ab Wheel Rollout 0 x 10, sets 3 (no weight, grammar needs one) |
| 13 | I | three by ten bench at eighty | 3 by 10 bench at 80 | 3x10 bench at 80 | G: Bench 3 x 10 at 80 |
| 14 | I | thirty twos times ten on the incline | 32s times 10 on the incline | 32 x 10 on the incline | M: Incline Dumbbell Press 32 x 10 (eval 49) |
| 15 | I | squat a hundred for five, no wait, four | Squat 100 for 5. No, wait, 4. | squat 100 x 4 | G: Back Squat 100 x 4 |
| 16 | W | eighty k for eight | 80K for 8 | 80 kg x 8 | G: set 80 x 8 |
| 17 | W | rest ninety | Rest 90. | rest 90 | Rest 90 s (needs GC rule 4 rest grammar; today kitchen timer risk, GC 34) |
| 18 | I | remind me to call the plumber | Remind me two call the plumber. | remind me to call the plumber | G: task "Call the plumber" (eval 52) |
| 19 | I | call mum at seven | Call mum at 7. | call mum at 7 | G: task 19:00 today (needs GC rule 7 fix, GC 45) |
| 20 | I | move dentist to friday | Move dentist to Friday. | move dentist to friday | M: `rescheduleTask` Dentist Fri. "to" untouched (no numbers) |
| 21 | I | I'd like to swim on saturday | I'd like to swim on Saturday. | i'd like to swim on saturday | G: task, Sat. **Trap:** "like" is not a filler here |
| 22 | I | buy milk and bread | By milk and bread. | buy milk and bread | G: groceries milk, bread (eval 50) |
| 23 | I | buy sun cream | Buy sun cream. | buy sun cream | Groceries. **Trap:** "sun" as Sunday (GC 22) |
| 24 | C | set a timer for ten minutes | Set a timer for 10 minutes. | set a timer for 10 minutes | G: timer 10 min. **Trap:** "for" stays, no number before it |
| 25 | I | cook the dal tonight | Cook the dal tonight. | cook the dal tonight | G: cook task Weeknight dal, 20:00 |
| 26 | I | add tent to packing | Add tent to packing. | add tent to packing | M: `addToList` Packing [tent] (GC 40) |
| 27 | I | two tins of tomatoes and four onions | 2 tins of tomatoes and for onions | 2 tins of tomatoes and for onions | M: `addGroceries` ["2 tins of tomatoes", "4 onions"]. **Trap:** "for" without a number before it stays |
| 28 | I | note four ideas for the app | Note: 4 ideas for the app. | note: 4 ideas for the app | G: note, body as heard |
| 29 | I | how many sets of bench this week | How many sets of bench this week? | how many sets of bench this week | Question guard (GC rule 2), no write |
| 30 | I | log bench eighty for eight and remind me to call mum tomorrow | Log bench 80 for 8 and remind me to call mum tomorrow. | log bench 80 x 8 and remind me to call mum tomorrow | Split (GC rule 3): set Bench 80 x 8 + task tomorrow; M until split lands (GC 24) |

Silence or only fillers ("um") gives an empty string: no capture, the Bar goes back to idle with "Didn't hear anything."

## 5. What Builder B needs

The gesture: press and hold the collapsed Bar (about 0.2 s before listening starts, so a tap still opens the panel). Release sends. Drag left off the Bar cancels, like Messages. All motion through `MotionPolicy`, colours and type from `Theme`.

| State | Bar shows | Haptic |
|---|---|---|
| Idle | "Ask Tess, or log a set" plus a mic glyph (reinstated) | none |
| Listening | The soul glyph breathes with the mic level (RMS from the tap); volatile text streams in `inkSecondary`, final words settle to `ink` | `.start` (light impact) on press |
| Transcribing | Text holds, soul stops breathing, under 600 ms; "Cancel" hint if dragged | none |
| Sent | Normal ghost row with "Heard: ..." under the parse, then the usual 2 s commit or alternatives | `.success` on a parse, `.warning` on "Didn't catch that" |
| Cancelled | Text fades out, back to idle | `.selection` |
| Getting ready | "Getting speech ready. Needs a connection once." with progress | none |

- **VoiceOver.** Label "Ask Tess or log something" (as today). Hint "Double-tap and hold to talk." Add an `accessibilityAction(named: "Talk to Tess")` that toggles listening (start, then stop on the second activation), because a hold is awkward with VoiceOver. Post the final transcript as an announcement only if no ghost row line follows.
- **Reduce Motion.** No breathing or wave: the soul shows the level as 3 opacity steps; volatile text replaces in place with no slide.
- **Permission flow.** First hold: request the mic in place; while the alert is up, the Bar says "Tess needs the mic to hear you." Granted: "Hold to talk." and nothing is captured from that first hold.
- **Denied or restricted.** Mic glyph struck through. Holding shows "Mic is off for Tessera. Open Settings?" with a link to `UIApplication.openSettingsURLString`. Typing and keyboard dictation keep working. Never ask again in-app.
- **Unavailable** (no supported locale, device or assets offline): hide the glyph and say so once, "Voice needs a connection once to set up." or "Voice isn't available here. Keyboard mic still works."
- **Test hooks.** Inject a fake `TessListener` that replays scripted volatile and final strings, since the Simulator has no `SpeechTranscriber`. Record the states with `-demo`.

## 6. Privacy

- Audio stays on the iPhone: buffers go from the tap into the analyzer and are dropped. Never written to disk, never logged, never sent. Apple's model download carries no user data.
- Only text continues. The final normalised line enters the same router as typed text, so the existing rules apply unchanged: grammar, on-device, then Claude only when switched on, online and under the cap, with the phrase in its own `<phrase>` data block and the capture context pack from `tess-model-layer.md` section 6. The cloud mark shows when it leaves.
- The raw "heard" line is kept locally on the op (for the ghost row and normaliser debugging); Claude gets the normalised phrase plus the raw heard line, both the same utterance. No audio, timings or confidence values leave.

## 7. Slices

| # | Slice | Done when | Owner |
|---|---|---|---|
| V1 | **Spoken normaliser** | `TessSpokenNormalizer` runs before `TessGrammar.parse` on every capture; the 30 rows above are a Swift Testing table (rows marked G parse in the grammar, M rows reach the model step unchanged); eval rows 45 to 48 and 52 pass on the grammar route (49 and 51 stay model rows, 50 needs "bred" fixed by the model); all existing grammar tests still pass | Core engine |
| V2 | **Hold the Bar to talk** | Info.plist keys in `project.yml`; on his phone in airplane mode (assets installed once), holding the Bar in a live workout and saying "eighty for seven" shows a ghost 80 x 7 under 1 s after release; permission, denied and unavailable states match section 5; VoiceOver action and Reduce Motion work; music in AirPods keeps playing | Builder B + Core |
| V3 | **Gym tuning** | A debug switch picks `SpeechTranscriber` or `DictationTranscriber` (`.shortForm` + contextual strings: his exercise names, max 100); he says the 30 phrases once per module in the gym; the debug log (heard vs expected, release-to-final ms) picks the default; trap rows 4, 10, 27 never auto-commit a wrong set | Research + Core |

## Unverified

Latency numbers; en-IN support; whether `SpeechTranscriber` honours contextual strings; whether `NSSpeechRecognitionUsageDescription` is needed with `SpeechAnalyzer`; AirPods routing with `.playAndRecord`; keyboard dictation staying on device; every "raw transcript" cell.

## Sources

- [WWDC25 277: Bring advanced speech-to-text to your app with SpeechAnalyzer](https://developer.apple.com/videos/play/wwdc2025/277/)
- [Speech framework](https://developer.apple.com/documentation/speech), [SpeechAnalyzer](https://developer.apple.com/documentation/speech/speechanalyzer), [SpeechTranscriber](https://developer.apple.com/documentation/speech/speechtranscriber), [DictationTranscriber](https://developer.apple.com/documentation/speech/dictationtranscriber), [ContentHint](https://developer.apple.com/documentation/speech/dictationtranscriber/contenthint), [AnalysisContext.contextualStrings](https://developer.apple.com/documentation/speech/analysiscontext/contextualstrings), [CaptureInputSequenceProvider (iOS 27)](https://developer.apple.com/documentation/speech/captureinputsequenceprovider)
- [Asking permission to use speech recognition](https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition), [NSSpeechRecognitionUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nsspeechrecognitionusagedescription), [requiresOnDeviceRecognition](https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition)
- Developer Forums: [SpeechAnalyzer sample app](https://developer.apple.com/forums/thread/790108), [SpeechTranscriber on Simulator](https://developer.apple.com/forums/thread/802969)
