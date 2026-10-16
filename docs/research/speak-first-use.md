# Speak: first-use script

For: Builder B (Speak PR), Design studio (copy), Kaushik. Research lab, 2026-10-16. Board item 30.

This is the first-launch path for Speak, the voice way into Tess. Each row gives the trigger, what the screen shows, the exact line Tess shows, the fast way back, and how to pass or fail it. Builder B's Speak PR is checked against this table, row by row, on his phone.

## What is on origin/master (`15fc404`, read only)

- **Speak is a word only.** `Features/Command/BottomChrome.swift:253-258`: tapping Speak (or Show) closes the surface and Tess says "Speak comes next." There is no `SpeechAnalyzer`, `SpeechTranscriber`, `SFSpeechRecognizer`, `AVAudioEngine` or `AVAudioSession` code anywhere on master.
- **No mic or speech purpose strings.** `project.yml` (Tessera target, `settings.base`) sets only `NSHealthUpdateUsageDescription` and `NSHealthShareUsageDescription`. `App/Info.plist` is generated (`GENERATE_INFOPLIST_FILE: YES`).
- **The capture surface.** A tap on the soul raises three words, Speak, Write, Show (vermilion, cobalt, cadmium dabs). Write stretches the cobalt dab into a writing line.
- **Dry time is real code.** `dry()` (`BottomChrome.swift:381`): the text dims to a ghost and a line dries under it for 2 s (0.6 s with Reduce Motion); a touch cancels; then `commit` runs the grammar or `model.ask`, the surface closes, the soul brightens, and Tess's line sits beside the soul for 4 s (`say`, line 436).
- **The voice checker is real code.** `TessVoice.violations(in:)` (`TesseraCore/Sources/TesseraTess/TessCapturing.swift:88`) fails a line with 12 or more words, a newline, "!", emoji, or a banned word: should, must, missed, streak, great, awesome, sorry, oops. Every line below passes it by hand count.
- **"Didn't hear anything."** exists only in research docs (`speech-capture.md` section 4, `fixtures/spoken-normaliser.md` row 33 and rule 17, `speech-test-script.md` row 30). The normaliser returns empty text; the line belongs to the Speak path (Builder B), not the engine.

## Design sheet

**There is no Speak sheet from Design.** `/mnt/project-files/tessera/design/` has `voice-gym.mp4` and `tess-capture.mp4` (videos, no written spec, not watched for this file) and no Speak `.md`. `docs/design/no-buttons.md`, which `BottomChrome.swift` names as its spec, is not on master either. Every line below is proposed copy built from `speech-capture.md` section 5, `tess-voice.md` and `tess-discoverability.md` row 20. Design can change the words; the states and pass rules stand.

## API facts this script rests on

Checked against Apple's documentation JSON on 2026-10-16. "Assumed" means not in the docs; test it on the phone.

| Fact | Source | Status |
|---|---|---|
| `SpeechAnalyzer` + `SpeechTranscriber` (iOS 26+) run on device. Apple: the speech authorization flow "only applies to speech recognition using `SFSpeechRecognizer`. `SpeechAnalyzer` transcriber modules don't send audio data of the user's voice to Apple's servers." | Asking permission to use speech recognition | Verified (docs) |
| So the recommended build shows **one** system prompt (mic), not two. The speech prompt appears only if the build calls `SFSpeechRecognizer.requestAuthorization`. | Same | Verified (docs); on-device check still to do |
| `NSSpeechRecognitionUsageDescription`: "If this key is not present, your app will crash when it attempts to request authorization or use the APIs of the Speech framework." Add it anyway. | Same | Verified (docs). Whether `SpeechAnalyzer` alone crashes without it is assumed yes, to be safe |
| `NSMicrophoneUsageDescription` is needed before any mic use. `AVAudioApplication.requestRecordPermission` prompts once; "unless a user grants your app permission to record audio, it captures only silence (zeroed out audio samples)." The system never prompts again after a choice. | `requestRecordPermission(completionHandler:)` | Verified (docs) |
| `AVAudioApplication.RecordPermission` has `undetermined`, `denied`, `granted`. There is **no restricted case** for the mic. | Record permission enum | Verified (cases); how Screen Time shows up is assumed (reads as `denied`, no prompt) |
| `SFSpeechRecognizerAuthorizationStatus` has `notDetermined`, `denied`, `restricted`, `authorized`, and can be denied "if speech recognition is not supported on the device". | `authorizationStatus()` | Verified (docs). Only matters on the `SFSpeechRecognizer` path |
| `SpeechTranscriber.isAvailable`: "whether this module is available given the device's hardware". `supportedLocales` is "empty if the device does not support the transcriber". Fall back to `DictationTranscriber`, which is "compatible with older devices" and "does not support languages or locales that `SFSpeechRecognizer` only supports via network access". | SpeechTranscriber, DictationTranscriber | Verified (docs) |
| `supportedLocale(equivalentTo:)` returns an exact match, or a near match with the same language and another region ("color" vs "colour"), or nil. Apple: "your application should ideally still provide a way for the user to correct the locale". | `supportedLocale(equivalentTo:)` | Verified (docs) |
| Assets: `AssetInventory.Status` is `unsupported`, `supported`, `downloading`, `installed`. Install with `assetInstallationRequest(supporting:)` then `downloadAndInstall()`. Assets are shared between apps, persist between launches, and "the system may unsubscribe your app from assets that haven't been used in a while". | AssetInventory, AssetInventory.Status | Verified (docs) |
| Offline works once assets are installed. | WWDC25 277, via `speech-capture.md` | Verified (talk); airplane-mode run still to do |
| iOS 27 adds `CaptureInputSequenceProvider` ("reads from an AV capture device such as a microphone"), with `provider(from:in:compatibleWith:priority:)` and `providerWithSession(...)`. It could replace the `AVAudioEngine` tap. | CaptureInputSequenceProvider (iOS 27.0) | Verified exists; behaviour under interruption assumed same as a capture session |
| A call or another app interrupts the audio session: `AVAudioSession.interruptionNotification` with type `began`, later `ended`. | AVAudioSession | Verified (long-standing API) |
| Changing a privacy switch in Settings ends the app's process; the next open is a cold launch. | Not in the pages read | Assumed (long-standing iOS behaviour); row 6 checks it |
| `SpeechTranscriber` is unavailable on the Simulator. | Developer Forums, via `speech-capture.md` | Reported. Run this script on his phone, not the Simulator |

## Info.plist purpose strings

Add to `project.yml`, Tessera target, `settings.base`. The `speech-capture.md` draft says "hold the bar", but there is no bar on master any more (the soul replaced it), so the wording changes:

```yaml
INFOPLIST_KEY_NSMicrophoneUsageDescription: Tess listens only while you hold to talk, so you can log by voice. Audio stays on this iPhone.
INFOPLIST_KEY_NSSpeechRecognitionUsageDescription: Tess turns what you say into text on this iPhone. Audio is never sent anywhere.
```

Both strings are true only if no `SFSpeechRecognizer` server path is used. If the PR uses `SFSpeechRecognizer`, it sets `requiresOnDeviceRecognition = true` or the speech string is false.

## The proposed gesture

Master has no hold gesture yet, so this is the shape the rows assume (open question 1):
- Tap the soul, then **Speak**. The vermilion dab stretches into a speaking line, the way Write stretches cobalt. Tess's line sits above it.
- **Hold the soul** to listen; words stream onto the line in `inkSecondary` and settle to `ink` as they finalise. **Let go** to send. **Drag left** off the soul to cancel.
- In a live workout, holding the soul at rest skips the tap on Speak (from `speech-test-script.md`).
- Permission is asked on the **first tap on Speak**, never at launch, never on a hold.

## Before you run it

- His phone, iOS 27, `-demoTime 18:10`. Delete Tessera first so both permissions are undetermined (or Settings, General, Transfer or Reset, Reset Location and Privacy).
- Phone locale en-GB first. Rows 7 and 8 need a second pass in airplane mode and in an unsupported locale.
- Each row starts from Home with Tess at rest, unless it says otherwise.

## The script

Lines in quotes are exact, character for character. Word counts are in brackets for the checker.

### 1. First tap on Speak: the asks

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 1a | Tap the soul, tap Speak. Mic is undetermined | Speak layer opens: vermilion line, no words on it. Soul still. Tess's line above the line, then the system mic alert rises over it within 0.5 s | "Tess needs the mic to hear you." (7) | The alert's own buttons. A tap on the veil closes Tess | Pass: the alert shows the `NSMicrophoneUsageDescription` text above, word for word, and appears only after the tap on Speak. Fail: any prompt at launch, on opening the surface, or on Write; a custom screen that looks like the system alert |
| 1b | Tap Allow | Alert gone. Speak layer stays open. Soul breathes slowly once to show it is ready. Nothing recorded from this tap | "Hold me to talk. Let go to send." (8) | Tap the veil to close | Pass: no second system alert on the recommended path (`SpeechAnalyzer`); nothing captured; the line is not a ghost and nothing dries. Fail: a speech recognition alert appears (means the PR calls `SFSpeechRecognizer.requestAuthorization`; then 1c applies) |
| 1c | Only on the `SFSpeechRecognizer` path: the speech alert follows 1b | Same layer, the system speech alert over it | Line stays "Tess needs the mic to hear you." (7) until the alert closes, then 1b's line | The alert's own buttons | Pass: speech asked **after** mic, never before; the alert shows the `NSSpeechRecognitionUsageDescription` text above. Fail: speech asked first, or asked while the mic alert is up |
| 1d | First use, assets for the locale not installed, online | Layer open, the vermilion line fills left to right as progress (`AssetInventory` download progress). Holding is ignored until done | "Getting speech ready. Needs a connection once." (7) | Tap Write: typing works during the download | Pass: the download starts on the first Speak tap at the latest (ideally when the surface first opens); progress moves; on finish the line changes to 1b's. Fail: a hold during the download starts the mic; the app waits silently |

### 2. Both allowed: first phrase

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 2a | Hold the soul | Light impact haptic on touch down. Soul breathes with the mic level. Orange mic dot in the status bar | Tess's line clears. The speaking line shows words as he speaks | Drag left off the soul: cancels, `.selection` haptic, text fades, no line | Pass: listening starts within 0.2 s of the hold; first word on the line under 300 ms of speaking (target from `speech-capture.md`). Fail: starts on a tap, or a tap still opens nothing |
| 2b | Say "bench eighty for eight", let go | Soul stops breathing. Volatile words settle to the final text in under 600 ms. Mic dot goes out | Line shows "bench 80 x 8" (normalised) | Drag left before it settles | Pass: mic off within 0.5 s of release; the normalised text is shown, not the raw "eighty". Fail: mic stays on after release |
| 2c | The final text arrives | **Ghost row.** The text dims to a ghost (ink 0.45, as in Write). A thin vermilion line dries under it for 2 s (0.6 s with Reduce Motion). Under the ghost, in `inkSecondary`: the raw transcript | "Heard: bench eighty for eight" (shows the transcriber's own words, which may already be digits) | Touch the ghost: drying stops, text goes back to editable (in the Write line), nothing saved | Pass: drying is the same 2 s as Write; a touch cancels; the Heard line is the raw transcript, not the normalised text. Fail: commits at once; no Heard line; a touch commits instead of cancelling |
| 2d | Dry finishes | Surface closes, soul brightens, `.success` haptic. Tess's line beside the soul for 4 s | "Bench 8 reps at 80. Added to today." (7) (master's line for this capture, per `speech-test-script.md` row 22) | Undo under the line, as for typed captures | Pass: one Bench entry 80 x 8 for today; the line passes `TessVoice.violations`. Fail: a set written twice; a "Logged!" style line |
| 2e | Doubtful parse (a bare number over 30 in a workout, `speech-capture.md` row 4) | Ghost row with two choices as ink words under it. **No drying line**: nothing commits by itself | "Didn't catch that. 84 x ? or 80 x 4?" (8) | Touch a choice to commit it; drag left to drop | Pass: nothing saved until a touch. Fail: either choice saved on a timer |

### 3. Mic denied

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 3a | Tap Don't Allow on the mic alert in 1a | Speak layer stays open. Vermilion dab drawn with a single struck line through it. No second alert | "Mic is off for Tessera. Open Settings?" (6). "Open Settings" is an ink word | Tap "Open Settings": `UIApplication.openSettingsURLString`. Tap Write: the cobalt line opens with the keyboard (keyboard dictation still works) | Pass: no alert again, ever, from inside the app; Write opens in one tap. Fail: the app asks again; a hold starts "listening" and later says "Didn't hear anything." (the mic records zeros when denied, so the PR has to check permission first) |
| 3b | Later, any tap on Speak while denied | Same as 3a, no alert | "Mic is off for Tessera. Open Settings?" (6) | Same as 3a | Pass: same line every time, no extra words, no count of tries. Fail: anything like "still", "again" or "you need to" |
| 3c | Hold the soul at rest in a workout while denied | Soul does not breathe. Light warning haptic | "Mic is off for Tessera. Open Settings?" (6) | Tap the soul: normal capture surface | Pass: no listening state at all |

### 4. Speech denied

On the recommended `SpeechAnalyzer` path the speech alert never shows, so Settings has no Speech Recognition switch for Tessera and this case cannot happen. Row 4a checks that. Rows 4b and 4c apply only if the PR uses `SFSpeechRecognizer`.

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 4a | After 1b, open Settings, Privacy and Security, Speech Recognition | Tessera is **not** in the list | (none) | (none) | Pass: Tessera absent (proves no `SFSpeechRecognizer` authorization call). Fail: Tessera listed; then run 4b |
| 4b | `SFSpeechRecognizer` path: Don't Allow on the speech alert | Speak layer stays open, struck dab | "Speech is off for Tessera. Open Settings?" (6) | "Open Settings" ink word; Write as in 3a | Pass: mic stays granted; no alert again. Fail: falls back to sending audio anywhere |
| 4c | `SFSpeechRecognizer` path: any later tap on Speak | Same as 4b | "Speech is off for Tessera. Open Settings?" (6) | Same | Pass: same line each time |

### 5. Restricted (Screen Time, device management)

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 5a | Screen Time, Content and Privacy Restrictions, Microphone set to Don't Allow Changes, with Tessera's mic undetermined or off. Tap Speak | Assumed: `recordPermission` reads `denied` and no alert shows. Struck dab | "The mic is limited on this iPhone. Write still works." (10) if the PR can tell; otherwise 3a's line | Tap "Write" (the word in the line is an ink word that opens Write) | Pass: no alert, no listening state, Write in one tap. Fail: a loop of "Open Settings" into a greyed-out switch with nothing else offered. If iOS gives no way to tell restricted from denied, 3a's line passes too (open question 4) |
| 5b | `SFSpeechRecognizer` path only: `authorizationStatus()` is `restricted` | Struck dab | "Speech is limited on this iPhone. Write still works." (9) | Tap "Write" | Pass: no "Open Settings" link, because the user cannot change it there |

### 6. Denied, then turned on in Settings

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 6a | From 3a, tap "Open Settings" | Settings opens on Tessera's page with the Microphone switch | (none) | Back to Tessera via the top-left "Tessera" link | Pass: lands on Tessera's own page, not Settings' root |
| 6b | Turn Microphone on, go back to Tessera | Assumed: cold launch (the switch ends the process). Home, Tess at rest | (none at launch; Tess does not announce the change) | (none) | Pass: no line, no prompt at launch. Fail: Tess greets the change unasked |
| 6c | Tap the soul, tap Speak | Speak layer, plain vermilion dab (no strike). No alert | "Mic is on. Hold me to talk." (6) once, then 1b's line on later opens | Tap the veil to close | Pass: permission read fresh on every Speak tap (and on `scenePhase` active), so a warm return also works if iOS does not kill the app; asset check (1d) runs if needed. Fail: still struck until a second launch |
| 6d | Hold and say "same" in a workout | As 2a to 2d | "Same again, logged." (3) | Undo | Pass: works on the first hold |

### 7. Offline

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 7a | Airplane mode, assets **installed** (status `installed`). Hold, say "eighty for seven" in a workout | As 2a to 2d. No cloud mark | "Set N. 80 x 7." (4) | Undo | Pass: works fully offline; release to ghost under 1 s (slice V2 bar). Fail: any network wait |
| 7b | Airplane mode, assets **not installed** (`supported`, first use). Tap Speak | Speak layer, dab drawn hollow (not struck: nothing is denied). Hold does nothing | "Voice needs a connection once to set up." (7) | Tap Write | Pass: no spinner that never ends; the download starts by itself when the network returns, with 1d's line if Speak is open. Fail: a hold "listens" with no model |
| 7c | Assets removed by the system after long disuse (Apple: the system "may unsubscribe your app") | Same as 1d or 7b, by network state | 1d's or 7b's line | Same | Pass: the PR checks `AssetInventory.status` on every Speak tap, not once per install |
| 7d | Online but the transcribed phrase falls to the model layer and Claude is off or offline | Normal ghost, then the on-device model's answer or "Didn't catch that" with a guess | "Didn't catch that. Bench 80 x 8?" (6) (from `tess-voice.md`) | Touch the guess to commit | Pass: same fallbacks as typed text; speech itself never needs the network after setup |

**Is on-device recognition available?** Yes: `SpeechTranscriber` (and `DictationTranscriber`) run on device once the locale's assets are installed. If `SpeechTranscriber.isAvailable` is false (older hardware), use `DictationTranscriber`. If neither has the locale, row 8.

### 8. Language not supported

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 8a | Locale where `supportedLocale(equivalentTo: .current)` is nil for both transcribers (or `supportedLocales` is empty). Tap Speak | Speak word shown dimmed in the surface; tapping it still opens the layer once, hollow dab | "Voice isn't available in this language yet. Write still works." (10) | Tap "Write" | Pass: said once per launch at most; Write in one tap. Fail: a crash or empty listening |
| 8b | Near match: phone en-IN, transcriber returns en-GB | Normal Speak layer | "Listening in English (UK)." (4) on the first open only | A tap on the line opens the language choice (Apple asks for a way to correct the locale) | Pass: shown once, then silent; the choice persists. Fail: shown every time |

### 9. A call or another app takes the audio

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 9a | Phone call arrives while holding (`interruptionNotification` began) | Listening stops at once. Partial words drop, no ghost, no drying. Soul goes still | "Call took the mic. Nothing saved." (6) shown when he is back in the app | Hold again after the call | Pass: nothing written; no auto-resume when the interruption ends. Fail: a half phrase is committed |
| 9b | Tap Speak during a call (the session will not start) | Speak layer, hollow dab | "The mic is busy with a call." (7) | Tap Write | Pass: no listening state; no crash on `setActive` failing |
| 9c | Another app takes the mic (Voice Memos, Siri) while holding | As 9a | "Another app took the mic. Nothing saved." (7) | Hold again | Pass: same as 9a |
| 9d | Music playing in AirPods, hold and talk | Music keeps playing; input is the phone mic | Normal line from 2d | (none) | Pass: music not paused or switched to call quality (`.mixWithOthers`, no Bluetooth HFP). Fail: AirPods drop to call audio (unverified on device, `speech-capture.md`) |

### 10. Silence

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 10a | Hold for 2 s, say nothing, let go | No ghost, no drying line. Speak layer stays open | "Didn't hear anything." (3) | Hold again | Pass: nothing saved; the text after the normaliser is empty. Fail: a ghost of empty text; "Didn't catch that" (that line is for words Tess could not parse) |
| 10b | Say only "um, uh" | As 10a | "Didn't hear anything." (3) | Hold again | Pass: same as 10a (`spoken-normaliser.md` rule 17, row 33) |
| 10c | Tap the soul quickly (under 0.2 s) in the Speak layer | No listening state | (none) | (none) | Pass: a short tap never says "Didn't hear anything." |

### 11. Second launch, permissions granted

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 11a | Quit and open Tessera | Home, Tess at rest | (none) | (none) | Pass: no alert, no speech line at launch |
| 11b | Tap the soul, tap Speak | Speak layer, plain dab, ready at once (the analyzer preheats when the surface opens) | No setup line. After the first successful capture, the hint "Hold me to talk. Let go to send." (8) is gone; `tess-discoverability.md` row 20 may show one context phrase instead | Tap the veil | Pass: listening starts within 0.2 s of a hold; no 1a to 1d lines. Fail: any permission or setup line repeats |
| 11c | Hold the soul at rest in a live workout, say "eight" | Straight to listening, then 2b to 2d | "Set N. 80 x 8." (4) | Undo | Pass: no surface needed in a workout |

## Lines in one place

For Design and for a `TessVoice.violations` test table. All are proposed; none are on master except the capture results.

| Key | Line |
|---|---|
| askMic | Tess needs the mic to hear you. |
| ready | Hold me to talk. Let go to send. |
| preparing | Getting speech ready. Needs a connection once. |
| micOff | Mic is off for Tessera. Open Settings? |
| speechOff | Speech is off for Tessera. Open Settings? |
| micLimited | The mic is limited on this iPhone. Write still works. |
| speechLimited | Speech is limited on this iPhone. Write still works. |
| micBack | Mic is on. Hold me to talk. |
| needsConnection | Voice needs a connection once to set up. |
| noLanguage | Voice isn't available in this language yet. Write still works. |
| nearLanguage | Listening in English (UK). |
| callTook | Call took the mic. Nothing saved. |
| callBusy | The mic is busy with a call. |
| appTook | Another app took the mic. Nothing saved. |
| silence | Didn't hear anything. |
| heard | Heard: {raw transcript} |

## Open questions

1. **Gesture.** Hold the soul, or tap Speak then hold? `speech-capture.md` assumes a bar that no longer exists; this file assumes the soul. Design needs to decide, and whether holding the soul at rest outside a workout also listens.
2. **First hold after Allow.** Should the tap on Speak after Allow start listening at once (tap to toggle), or wait for a hold as written in 1b?
3. **Voice dry time.** Keep Write's 2 s, or give voice longer (say 3 s), since the transcript is less certain than typing?
4. **Restricted vs denied.** The mic API has no restricted state. Can iOS 27 tell a Screen Time restriction apart at all? If not, 5a uses 3a's line.
5. **Speech key.** Does `SpeechAnalyzer` alone crash without `NSSpeechRecognitionUsageDescription`? Proposed: add it anyway; confirm by removing it in a debug build.
6. **When to download assets.** On the first Speak tap (row 1d) or quietly the first time the capture surface opens on Wi-Fi? The second makes first use instant but downloads for a feature he may not use.
7. **en-IN.** Does `supportedLocale(equivalentTo:)` return en-IN, or a near match? This decides whether row 8b ever shows on his phone.
8. **Struck and hollow dabs.** Two new drawings of the vermilion dab (denied, not ready). Design to draw them through `ThemeConcept`; they replace "mic glyph struck through" in `speech-capture.md`.
9. **Settings relaunch.** Confirm on the phone that turning the mic on in Settings cold-launches the app (6b). If not, the `scenePhase` check in 6c carries it.
10. **Undo after voice.** Same Undo as typed capture, or also "say undo"? Not in this script.
