# Speak: first-use script

For: Builder B (Speak PR), Design studio (copy), Kaushik. Research lab, 2026-10-16. Board item 30, merged as #243. Revised the same day against Design's Speak sheet (`design/speak.md`, board item 9, and `design/mockups/speak-states.png`), then again for item 100 after Design settled this doc's 12 disagreements (speak.md `d288c11`, "Research's walk, settled").

This is the first-launch path for Speak, the voice way into Tess. Each row gives the trigger, what the screen shows, the exact line Tess shows, the fast way back, and how to pass or fail it. Builder B's Speak PR is checked against this table, row by row, on his phone. Every step of the path (the mic and speech asks, denied, restricted, limited, assets not downloaded, offline, unsupported language) has a screen and an exact line.

## What is on origin/master (`fdcaee4`, read only)

Re-read after #241 (no dots), #248 (set guard 2) and #249 landed. Builder B builds to this list.

- **Speak is a word only.** `Features/Command/BottomChrome.swift:264-271`: Write opens its layer; tapping Speak (or Show) closes the surface and Tess says "Speak comes next." (line 270) There is no `SpeechAnalyzer`, `SpeechTranscriber`, `SFSpeechRecognizer`, `AVAudioEngine`, `AVAudioSession` or `AssetInventory` code anywhere on master.
- **No mic or speech purpose strings.** `project.yml:69-74` (Tessera target, `settings.base`) sets `GENERATE_INFOPLIST_FILE: YES` and only two privacy keys, `NSHealthUpdateUsageDescription` (line 73) and `NSHealthShareUsageDescription` (line 74).
- **Dabs no longer stay; the words are still 34 pt.** Since #241, `ModeRow` (`BottomChrome.swift:506` on) lets each `PaintDab` (line 540) rise, land into its word as a wash and fade, so at rest only the words remain. The words are still 34 pt medium (`modeFont`, lines 343-345) and the inactive ones sit at 55% ink (line 527). Design wants Speak at 21/500 (settled point 2).
- **Holding the soul opens the surface.** `soulKey` (`BottomChrome.swift:163-198`): tap opens, `.onLongPressGesture(minimumDuration: 0.4) { open() }` (line 192), double tap goes Home. VoiceOver: label "Tess", hint "Opens Tess." (line 195), action "Go home". Nothing listens.
- **Dry time is real code.** `dry()` (`BottomChrome.swift:413-430`): the text dims to a ghost and a `Theme.Colors.tess` (cobalt) line fills left to right under it for 2 s, 0.6 s with Reduce Motion (lines 311-316, 424-426); a touch cancels (`cancelDrying`, line 432); then `commit` (line 444) runs, the surface closes, the soul brightens with a `.success` haptic (line 88), and Tess's line sits beside the soul for 4 s (`say`, lines 477-485).
- **Undo is a label word.** `Button("Undo")` with `InkLabelWordStyle.undo` (`BottomChrome.swift:146-147`), which is `liveInk` and keeps its colour (lines 619-621, since #241), drawn uppercase; `undo()` (lines 121-130) fires a `.decrease` haptic (line 89). The live corner still uses `Paint.live` (`Features/Workout/LiveTessCorner.swift:40-41`).
- **Capture lines are real code, and changed in #248.** `TessCaptureEngine.swift` (`TesseraCore/Sources/TesseraTess/`): a lift outside a workout says "{name} {n} reps at {load}. Added to today." (line 213), with a plain x for more than one set ("3 x 8", line 211). A set in a workout now names first and uses ×: "Set {n} logged. {weight} × {reps}." (lines 224, 232), "Set {n} logged, same again." (line 230), "Drop set logged. {weight} × {reps}." (line 231). The 2 × 10 ask is "2 × 10: 2 sets, or 2 kg?" (`TessSetCountAsk.swift:30`).
- **× and "by" in the grammar.** `TessGrammar.normalize` turns × into x before matching (`TessGrammar.swift:508`), so a typed × parses. A set parses from `W x R` or `W for R` only (`TessGrammar.swift:286`; lift scheme line 358). "by" between two numbers parses only in the 2 × 10 ask (`TessGrammar+Live.swift:123`); spoken "by" reaches the grammar as x through the normaliser (`fixtures/spoken-normaliser.md` rule 12), but a typed "80 by 8" is not a set on master.
- **The voice checker is real code.** `TessVoice.violations(in:)` (`TesseraCore/Sources/TesseraTess/TessCapturing.swift:98`) fails a line with 12 or more words (split on whitespace), a newline, "!", emoji, or a banned word (line 95): should, must, missed, streak, great, awesome, sorry, oops. Every line below passes it; counts are whitespace words.
- **"Didn't hear anything."** is in no Swift file on master. It comes from research (`speech-capture.md` section 4, `fixtures/spoken-normaliser.md` row 33 and rule 17) and now from Design's sheet. The normaliser returns empty text; the line belongs to the Speak path (Builder B), not the engine.
- **Design's specs are not on master.** `no-buttons.md`, which `BottomChrome.swift:7` names as its spec, and `no-dots.md`, `ink-line.md`, `speak.md` live only in the project's `design/` folder.

## Design sheet

**Design's Speak sheet exists now:** `design/speak.md` (also on branch `claude/project-thread-b3tu3f` as `docs/design/speak.md`, last commit `d288c11`), with `design/recordings/speak.mp4` (not watched for this file) and the still `design/mockups/speak-states.png` (preparing, mic off, silence). The sheet says Research's states, pass rules and exact lines stand except where it changes them. Its changes are folded into the rows below and listed in "Changes after Design's sheet". Its last section, "Research's walk, settled" (`d288c11`), closes all 12 disagreements this doc raised; see "Disagreements, settled". The still matches the sheet: the Speak word is ink over a short `live` line while preparing, grey with "Mic is off for Tessera." and an ink "Open Settings" when off, and ink with "Didn't hear anything." in silence. Lines sit in cobalt at Body 21 above the three words.

## API facts this script rests on

Checked against Apple's documentation JSON on 2026-10-16. "Assumed" means not in the docs; test it on the phone.

| Fact | Source | Status |
|---|---|---|
| `SpeechAnalyzer` + `SpeechTranscriber` (iOS 26+) run on device. Apple: the speech authorization flow "only applies to speech recognition using `SFSpeechRecognizer`. `SpeechAnalyzer` transcriber modules don't send audio data of the user's voice to Apple's servers." | Asking permission to use speech recognition | Verified (docs) |
| So the recommended build shows **one** system prompt (mic), not two. The speech prompt appears only if the build calls `SFSpeechRecognizer.requestAuthorization`. | Same | Verified (docs); on-device check still to do |
| `NSSpeechRecognitionUsageDescription`: "If this key is not present, your app will crash when it attempts to request authorization or use the APIs of the Speech framework." Add it anyway. | Same | Verified (docs). Whether `SpeechAnalyzer` alone crashes without it is assumed yes; both keys go in (Design, speak.md) |
| `NSMicrophoneUsageDescription` is needed before any mic use. `AVAudioApplication.requestRecordPermission` prompts once; "unless a user grants your app permission to record audio, it captures only silence (zeroed out audio samples)." The system never prompts again after a choice. | `requestRecordPermission(completionHandler:)` | Verified (docs) |
| `AVAudioApplication.RecordPermission` has `undetermined`, `denied`, `granted`. There is **no restricted case** for the mic. | Record permission enum | Verified (cases); how Screen Time shows up is assumed (reads as `denied`, no prompt) |
| `SFSpeechRecognizerAuthorizationStatus` has `notDetermined`, `denied`, `restricted`, `authorized`, and can be denied "if speech recognition is not supported on the device". | `authorizationStatus()` | Verified (docs). Only matters on the `SFSpeechRecognizer` path |
| `SpeechTranscriber.isAvailable`: "whether this module is available given the device's hardware". `supportedLocales` is "empty if the device does not support the transcriber". Fall back to `DictationTranscriber`, which is "compatible with older devices" and "does not support languages or locales that `SFSpeechRecognizer` only supports via network access". | SpeechTranscriber, DictationTranscriber | Verified (docs) |
| `supportedLocale(equivalentTo:)` returns an exact match, or a near match with the same language and another region ("color" vs "colour"), or nil. Apple: "your application should ideally still provide a way for the user to correct the locale". | `supportedLocale(equivalentTo:)` | Verified (docs) |
| Assets: `AssetInventory.Status` is `unsupported`, `supported`, `downloading`, `installed`. Install with `assetInstallationRequest(supporting:)` then `downloadAndInstall()`. Assets are shared between apps, persist between launches, and "the system may unsubscribe your app from assets that haven't been used in a while". | AssetInventory, AssetInventory.Status | Verified (docs) |
| Offline works once assets are installed. | WWDC25 277, via `speech-capture.md` | Verified (talk); airplane-mode run still to do |
| iOS 27 adds `CaptureInputSequenceProvider` ("reads from an AV capture device such as a microphone"), with `provider(from:in:compatibleWith:priority:)` and `providerWithSession(...)`. It could replace the `AVAudioEngine` tap. | CaptureInputSequenceProvider (iOS 27.0) | Verified exists; behaviour under interruption assumed same as a capture session |
| A call or another app interrupts the audio session: `AVAudioSession.interruptionNotification` with type `began`, later `ended`. | AVAudioSession | Verified (long-standing API) |
| Changing a privacy switch in Settings ends the app's process; the next open is a cold launch. | Not in the pages read | Assumed (long-standing iOS behaviour); row 6b checks it |
| `SpeechTranscriber` is unavailable on the Simulator. | Developer Forums, via `speech-capture.md` | Reported. Run this script on his phone, not the Simulator |

## Info.plist purpose strings

Add both to `project.yml`, Tessera target, `settings.base`, after line 74 (Design, speak.md, question 7). The `speech-capture.md` draft says "hold the bar", but there is no bar on master (the soul replaced it):

```yaml
INFOPLIST_KEY_NSMicrophoneUsageDescription: Tess listens only while you talk to her, so you can log by voice. Audio stays on this iPhone.
INFOPLIST_KEY_NSSpeechRecognitionUsageDescription: Tess turns what you say into text on this iPhone. Audio is never sent anywhere.
```

The mic string said "while you hold to talk"; with tap Speak now listening without a hold (question 1), it says "while you talk to her". Both strings are true only if no `SFSpeechRecognizer` server path is used. If the PR uses `SFSpeechRecognizer`, it sets `requiresOnDeviceRecognition = true` or the speech string is false. Run `xcodegen generate` after adding them.

## The gesture (decided)

Design, speak.md, question 1. Two ways in, one rule each:
- **From the surface:** tap the soul, then tap **Speak**. Listening starts at once, no hold. A 1.2 s pause or a tap on the bloom ends it and sends it to tidying and the voice ghost.
- **The fast path, anywhere:** **hold the soul at rest** on any screen, workout or not. It listens while held; **let go** to send; **drag left** off the soul to cancel. This replaces master's hold-to-open (`BottomChrome.swift:192`).
- **The hint:** "Hold me to talk." beside the soul (live mode: "Hold me to tell me a set") until the first hold that listens, then never again (Design d288c11, point 3).
- **Cancel and limits:** a tap on the veil (outside the bloom) cancels a tap-started listen, nothing saved and no line. No word in the first 5 s ends it with "Didn't hear anything." Every listen, tap or hold, ends at 60 s and sends what it heard, as a pause would (Design d288c11, point 6).
- **Permission** is asked on the **first tap on Speak** or the **first hold of the soul**, never at launch and never on opening the surface.
- **Speak's states live on the word** (no dabs, `no-dots.md`): ready is `ink` 21/500; preparing sits on a `live` ink line at 25% that fills left to right with download progress; mic off or limited is `inkSecondary` 21/400 with no strike; no language is `inkSecondary` and the layer opens once to say so.
- **Every line** is Body 21/400 in cobalt at y 470 in the Speak layer, or beside the soul when the layer is closed. Once per event; nothing counts tries.

## Before you run it

- His phone, iOS 27, `-demoTime 18:10`. Delete Tessera first so both permissions are undetermined (or Settings, General, Transfer or Reset, Reset Location and Privacy). Speech assets are shared between apps, so to see row 1d also remove the English speech assets (or run 1d on a locale he has never used).
- Phone locale en-GB first. Rows 7 and 8 need a second pass in airplane mode, on cellular only, and in an unsupported locale.
- Each row starts from Home with Tess at rest, unless it says otherwise.

## The script

Lines in quotes are exact, character for character. **Bold** words in a line are ink words (tappable, `ink`, not cobalt, no shape around them). Word counts are in brackets for the checker.

### 1. First tap on Speak: the asks

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 1a | Tap the soul, tap Speak. Mic is undetermined | Speak layer opens: Write, Show and the question fold away (200 ms). Speak word `ink` 21/500. Soul does not travel yet. The line at y 470, then the system mic alert rises over it within 0.5 s | "Tess needs the mic to hear you." (7) | The alert's own buttons. A tap on the veil closes Tess | Pass: the alert shows the `NSMicrophoneUsageDescription` text above word for word, and only after a tap on Speak or a hold of the soul. Fail: any prompt at launch, on opening the surface, or on Write; a custom screen that looks like the system alert |
| 1a2 | First hold of the soul at rest, mic undetermined | No bloom, no listening. The line beside the soul, then the system mic alert | "Tess needs the mic to hear you." (7) | The alert's own buttons | Pass: the hold asks and does not record; after Allow he holds again to talk. Fail: audio captured before Allow |
| 1b | Tap Allow (from 1a) | Alert gone. **Listening starts at once** (Design, speak.md, question 2): soul travels to (196, 698) on the settle spring and becomes the bloom (×1.4), breathing ×1.4 to ×1.55 with the mic level. Orange mic dot in the status bar | "Listening" (1) | Drag left or tap the veil: cancels, nothing saved | Pass: no second system alert on the `SpeechAnalyzer` path; no extra tap or hold needed. Fail: a speech recognition alert (the PR calls `SFSpeechRecognizer.requestAuthorization`; then 1c applies); waiting for a hold |
| 1b2 | The first capture after Allow dries (row 2d) | Surface closed, soul at rest. The one-time hint beside the soul after the capture line's 4 s | "Hold me to talk." (4). In a live workout: "Hold me to tell me a set" (7) | (none) | Pass: shown until the first hold that listens, then never again (Design d288c11, point 3), never as a step before talking. Fail: the hint blocks listening, or shows again after a hold has listened |
| 1c | Only on the `SFSpeechRecognizer` path: the speech alert follows the mic alert | Same layer, the system speech alert over it. No listening yet | Line stays "Tess needs the mic to hear you." (7) until the alert closes, then 1b | The alert's own buttons | Pass: speech asked **after** mic, never before; the alert shows the `NSSpeechRecognitionUsageDescription` text above. Fail: speech asked first, or while the mic alert is up |
| 1d | Speak tapped (or soul held) before the quiet download (1e) has finished, online | Layer open. The Speak word sits on a `live` ink line at 25% that fills left to right with `AssetInventory` download progress (`speak-states.png`, Preparing). Holding is ignored | "Getting speech ready. Needs a connection once." (7) | Tap Write: the surface goes straight to the writing line; typing works during the download | Pass: the download starts here at the latest, on Wi-Fi or cellular; progress moves; when it finishes with the layer open, listening starts at once with 1b's line. Fail: a hold during the download starts the mic; the app waits with no line |
| 1e | First open of the capture surface on Wi-Fi, assets not installed | Nothing new: the surface looks as usual. The download runs in the background. If he looks, the Speak word sits on the 25% `live` line, filling | (none) | (none) | Pass: download starts on the first surface open on Wi-Fi only, without a line, so a later first tap on Speak is instant. Fail: a download on cellular before Speak is tapped; any line or alert |

Order when both are missing: the mic ask (1a) first, then 1d. `AssetInventory.status` is read on every Speak tap and every hold (Design, speak.md, question 4).

### 2. Both allowed: first phrase

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 2a | Tap the soul, tap Speak (granted, assets installed) | Light impact haptic. Soul travels to the bloom; other words fold away (200 ms). Mic dot on | "Listening" (1) | Tap the veil (outside the bloom): cancels, nothing saved, no line (Design d288c11, point 6) | Pass: listening within 0.2 s of the tap; first word on the line under 300 ms of speaking (`speech-capture.md`). Fail: a hold is needed |
| 2b | Say "bench eighty for eight", then pause 1.2 s (or tap the bloom) | Words stream below "Listening" at Body 21/400 `inkSecondary`, each rising out of a 6 pt blur. On the pause: tidying squeezes out fillers (width to 0, 320 ms) and the rest crossfades into the clean sentence in `ink`, the destination as a value word. Mic dot goes out | The clean sentence, e.g. "bench 80 × 8" (normalised, × on screen) | Drag left or tap the veil before the ghost | Pass: mic off within 0.5 s of the pause or tap; the normalised text is shown with ×, not "eighty" or x. Fail: listening never ends without a touch |
| 2c | The clean sentence settles | **Voice ghost.** The sentence at 45%; a thin ink line in cobalt (the `ink-line.md` lens, 2.5 pt) under it drains right to left over **3 s** (0.8 s with Reduce Motion); under that, in `inkSecondary`, the raw transcript | "Heard: bench eighty for eight" (shows the transcriber's own words, which may already be digits) | Touch the ghost: drying stops and the sentence opens in the Write line to edit; nothing saved | Pass: voice dries 3 s, not Write's 2 s (Design, speak.md, question 3); a touch cancels; the Heard line is the raw transcript. Fail: commits at once; no Heard line; a touch commits |
| 2d | Dry finishes | Everything gathers back into the soul (220 ms), the page comes forward, `.success` haptic. Tess's line beside the soul for 4 s with UNDO | "Bench 8 reps at 80. Added to today." (8) (master's line, `TessCaptureEngine.swift:108`) | UNDO under the line | Pass: one Bench entry 80 × 8 for today; the line passes `TessVoice.violations`. Fail: written twice; a "Logged!" style line |
| 2e | Doubtful parse (a bare number over 30 in a workout, `speech-capture.md` row 4) | Ghost with **no draining line**: nothing commits by itself. The guesses show once, inside Tess's line, as value words; nothing sits under it (Design d288c11, point 5) | "Didn't catch that. **84 × ?** or **80 × 4**?" (10). Bold here marks the value words | Touch a guess to commit; drag left to drop | Pass: nothing saved until a touch; the guesses appear once. Fail: either guess saved on a timer; the guesses repeated under the line |
| 2f | Hold the soul at rest on Home (not a workout), say "oat milk and eggs", let go | Soul swells in place (×1.4), breathes with the level. Words stream right-aligned above the soul in `inkSecondary`. On release: tidying, then the voice ghost as 2c (3 s) | While held: none. Then "Heard: oat milk and eggs" | Drag left off the soul: `.selection` haptic, words fade, nothing saved, no line | Pass: listens within 0.2 s of the hold, only while held. Fail: the hold opens the surface (master's behaviour) |
| 2g | Say "undo" or "take that back" as the whole phrase, right after 2d | No ghost. Same as tapping UNDO: the last capture reverts, `.decrease` haptic, the line clears (`BottomChrome.swift:121-130`) | (none) | (none) | Pass: same result as UNDO (Design, speak.md, question 9); "undo the bench" is **not** an undo. Fail: "undo" is captured as a task |
| 2h | Keep talking past 60 s (tap or hold) | Listening ends by itself at 60 s, then tidying and the voice ghost as 2b to 2c | "Heard: {raw transcript}" | Touch the ghost | Pass: ends at 60 s and sends what it heard, as a pause would (Design d288c11, point 6). Fail: listens on, or drops the words |

### 3. Mic denied

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 3a | Tap Don't Allow on the mic alert in 1a | Layer stays open. The Speak word turns `inkSecondary` 21/400, no strike (`speak-states.png`, Mic off). No second alert | "Mic is off for Tessera. **Open Settings**" (7). "Open Settings" is an ink word, no question mark | Tap "Open Settings": `UIApplication.openSettingsURLString`. Tap the veil, then Write (keyboard dictation still works) | Pass: no alert again, ever, from inside the app. Fail: the app asks again; a "listening" state that later says "Didn't hear anything." (the mic records zeros when denied, so the PR checks permission first) |
| 3b | Later, any tap on Speak while denied | Speak word already `inkSecondary` when the surface opens. Layer opens as 3a | "Mic is off for Tessera. **Open Settings**" (7) | Same as 3a | Pass: same line every time, no count of tries. Fail: "still", "again" or "you need to" |
| 3c | Hold the soul at rest while denied (any screen, workout or not) | Soul does not swell or breathe. Light warning haptic. Line beside the soul | "Mic is off for Tessera. **Open Settings**" (7) | Tap the soul: normal capture surface | Pass: no listening state at all |

### 4. Speech denied

On the recommended `SpeechAnalyzer` path the speech alert never shows, so Settings has no Speech Recognition switch for Tessera and this case cannot happen. Row 4a checks that. Rows 4b and 4c apply only if the PR uses `SFSpeechRecognizer`.

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 4a | After 1b, open Settings, Privacy and Security, Speech Recognition | Tessera is **not** in the list | (none) | (none) | Pass: Tessera absent (no `SFSpeechRecognizer` authorization call). Fail: Tessera listed; then run 4b |
| 4b | `SFSpeechRecognizer` path: Don't Allow on the speech alert | Layer stays open, Speak word `inkSecondary` 21/400 | "Speech is off for Tessera. **Open Settings**" (7) | "Open Settings" ink word; Write as in 3a | Pass: mic stays granted; no alert again. Fail: falls back to sending audio anywhere |
| 4c | `SFSpeechRecognizer` path: any later tap on Speak | Same as 4b | "Speech is off for Tessera. **Open Settings**" (7) | Same | Pass: same line each time |

### 5. Restricted and limited (Screen Time, device management)

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 5a | Screen Time, Content and Privacy Restrictions, Microphone set to Don't Allow Changes, Tessera's mic undetermined or off. Tap Speak | `recordPermission` reads `denied` (assumed), no alert. Speak word `inkSecondary` 21/400 | "Mic is off for Tessera. **Open Settings**" (7) (Design, speak.md, question 6: restricted maps to micOff) | Tap the veil, then Write | Pass: no alert, no listening state, Write two taps away. Fail: an alert, or a listening state with zeros |
| 5b | Only if iOS 27 gives the PR a way to read a mic restriction (none in the docs read) | Speak word `inkSecondary` 21/400 | "The mic is limited on this iPhone. **Write** still works." (10). "Write" is an ink word that opens the writing line | Tap "Write" | Pass: no "Open Settings", because the switch is greyed out. Kept for when a restriction becomes readable; until then 5a applies |
| 5c | `SFSpeechRecognizer` path only: `authorizationStatus()` is `restricted` (this one is readable) | Speak word `inkSecondary` 21/400 | "Speech is limited on this iPhone. **Write** still works." (9) | Tap "Write" | Pass: no "Open Settings" link |

### 6. Denied, then turned on in Settings

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 6a | From 3a, tap "Open Settings" | Settings opens on Tessera's page with the Microphone switch | (none) | Back to Tessera via the top-left "Tessera" link | Pass: lands on Tessera's own page, not Settings' root |
| 6b | Turn Microphone on, go back to Tessera | Assumed: cold launch (the switch ends the process). Home, Tess at rest | (none at launch; Tess does not announce the change) | (none) | Pass: no line, no prompt at launch. Fail: Tess greets the change unasked |
| 6c | Tap the soul, tap Speak | Speak word back to `ink` 21/500 before the tap. No alert. Listening starts at once (bloom, mic dot) | "Mic is on." (3) in place of "Listening", this once (Design d288c11, point 12); "Listening" (1) on later opens. The hold hint is left to 1b2 | Tap the veil to cancel | Pass: permission read fresh on every Speak tap and hold (and on `scenePhase` active), so a warm return also works; the asset check (1d) runs if needed. Fail: still grey until a second launch |
| 6d | In a workout, hold the soul and say "same" | As 11c: straight to listening in the corner, then the wet numerals | "Set N logged, same again." (5) (`TessCaptureEngine.swift:230`) | UNDO | Pass: works on the first hold |

### 7. Offline and assets not downloaded

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 7a | Airplane mode, assets **installed**. In a workout, hold the soul, say "eighty for seven", let go | Soul swells in place. "eighty for seven" right-aligned above the soul in `inkSecondary`. On release the words fade (250 ms) and the set block's numerals turn wet cobalt at 62%: 80 × 7. After 2 s (0.6 s Reduce Motion) they dry into ink, the set stroke lands, the rest horizon starts | "Set N logged. 80 × 7." (6) (master, `TessCaptureEngine.swift:232`; the sheet's "Set 3. 80 × 7." predates #248, see "Still open") with UNDO | Touch the wet numerals: the in-place editor (`set-block.md`) | Pass: works fully offline; release to ghost under 1 s. Fail: any network wait |
| 7b | Airplane mode, assets **not installed** (`supported`). Tap Speak | Layer opens. Speak word on the 25% `live` line, not filling. Hold and tap do nothing | "Voice needs a connection once to set up." (8) | Tap the veil, then Write | Pass: no spinner that never ends; the download starts by itself when the network returns, and with the layer open the line becomes 1d's. Fail: a "listening" state with no model. Word state settled (Design d288c11, point 7) |
| 7c | Cellular only, assets not installed, surface opened before (1e waited for Wi-Fi). Tap Speak | As 1d: the line fills with progress over cellular | "Getting speech ready. Needs a connection once." (7) | Tap Write | Pass: a tap on Speak downloads on any connection; only the quiet download (1e) waits for Wi-Fi |
| 7d | Assets removed by the system after long disuse (Apple: "may unsubscribe your app") | As 1d online, as 7b offline | 1d's or 7b's line | Same | Pass: `AssetInventory.status` checked on every Speak tap and hold, not once per install |
| 7e | Online, but the phrase falls to the model layer and Claude is off or offline | Normal voice ghost, then the on-device answer or a guess | "Didn't catch that. Bench 80 × 8?" (7) (from `tess-voice.md`). The guess is a value word | Touch the guess to commit | Pass: same fallbacks as typed text; speech itself never needs the network after setup |

**Is on-device recognition available?** Yes: `SpeechTranscriber` (and `DictationTranscriber`) run on device once the locale's assets are installed. If `SpeechTranscriber.isAvailable` is false (older hardware), use `DictationTranscriber`. If neither has the locale, section 8.

### 8. Language not supported

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 8a | `supportedLocale(equivalentTo: .current)` is nil for both transcribers, or both `supportedLocales` are empty (unsupported hardware). Tap Speak | Speak word `inkSecondary` 21/400. The layer opens this once | "Voice isn't available in this language yet. **Write** still works." (10). "Write" is an ink word | Tap "Write" | Pass: the layer opens to say it once; Write in one tap. Fail: a crash or empty listening |
| 8b | Later taps on Speak in the same unsupported locale | Speak word stays `inkSecondary`; the layer does not open again. The line beside the soul | "Voice isn't available in this language yet. **Write** still works." (10) | Tap "Write" | Pass: no listening state; the layer does not open again (Design d288c11, point 8) |
| 8c | Near match: phone en-IN, transcriber returns en-GB (Design, speak.md, question 5) | Normal Speak layer; listening starts | "Listening in English (UK)." (4) in place of "Listening", on the first open only | Tap the line: the choice opens as value words in the same line, **English (US)** · **English (UK)** | Pass: shown once, then plain "Listening"; the choice persists across launches. Fail: shown every time |

### 9. A call or another app takes the audio

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 9a | Phone call arrives while listening (`interruptionNotification` began) | Listening stops at once. Partial words drop, no ghost, no drying. Soul goes back to rest | "Call took the mic. Nothing saved." (6) shown when he is back in the app | Tap Speak or hold again after the call | Pass: nothing written; no auto-resume when the interruption ends. Fail: a half phrase is committed |
| 9b | Tap Speak during a call (the session will not start) | Layer open, Speak word `ink`, no bloom | "The mic is busy with a call." (7) | Tap the veil, then Write | Pass: no listening state; no crash on `setActive` failing |
| 9c | Another app takes the mic (Voice Memos, Siri) while listening | As 9a | "Another app took the mic. Nothing saved." (7) | Tap Speak or hold again | Pass: same as 9a |
| 9d | Music playing in AirPods, hold and talk | Music keeps playing; input is the phone mic | Normal line from 2d | (none) | Pass: music not paused or switched to call quality (`.mixWithOthers`, no Bluetooth HFP). Fail: AirPods drop to call audio (unverified on device, `speech-capture.md`) |

### 10. Silence

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 10a | Tap Speak, say nothing | Listening ends when no word has come in the first 5 s (Design d288c11, point 6). No ghost, no drying line. Layer stays open, Speak word `ink` (`speak-states.png`, Silence) | "Didn't hear anything." (3) | Tap Speak again | Pass: nothing saved; the text after the normaliser is empty. Fail: a ghost of empty text; "Didn't catch that" (that line is for words Tess could not parse) |
| 10b | Hold the soul 2 s, say nothing, let go | Soul back to rest, no ghost | "Didn't hear anything." (3) beside the soul | Hold again | Pass: as 10a |
| 10c | Say only "um, uh" | As 10a | "Didn't hear anything." (3) | Tap Speak or hold again | Pass: as 10a (`spoken-normaliser.md` rule 17, row 33) |
| 10d | Touch the soul quickly (under 0.2 s) | A tap: the surface opens (master). No listening state | (none) | (none) | Pass: a short tap never says "Didn't hear anything." |

### 11. Second launch, permissions granted

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 11a | Quit and open Tessera | Home, Tess at rest | (none) | (none) | Pass: no alert, no speech line at launch |
| 11b | Tap the soul, tap Speak | Listening at once (the analyzer preheats when the surface opens) | "Listening" (1). The hint "Hold me to talk." no longer shows once a hold has listened | Tap the veil | Pass: listening within 0.2 s; no 1a to 1e lines. Fail: any permission or setup line repeats |
| 11c | In a live workout, hold the soul at rest, say "eight" | Straight to listening in the corner, then the wet numerals as 7a | "Set N logged. 80 × 8." (6) | UNDO | Pass: no surface needed in a workout |

### 12. VoiceOver and Reduce Motion

| # | Trigger | Screen state | Exact line | Fast path back | Pass if / Fail if |
|---|---|---|---|---|---|
| 12a | VoiceOver on, focus the soul | The hint stays "Opens Tess." (`BottomChrome.swift:195`); actions add "Talk to Tess" beside "Go home" (Design d288c11, point 1). A double tap on that action starts listening, another stops it | Spoken: "Talk to Tess" | Double tap again | Pass: listening without a hold; the transcript is announced when it settles, not word by word; × is read as "by" ("80 by 7", Design d288c11, point 4) |
| 12b | VoiceOver on, focus the Speak word in each state | (as the state) | Spoken: "Speak, getting ready" (1d), "Speak, microphone off" (3a, 5a) | (none) | Pass: the state is spoken, not only shown in grey or by a line |
| 12c | Reduce Motion on, run 2a to 2d and 7a | Soul does not travel; the bloom is a still mark at 1.2×. Words fade in without blur. Tidying is a crossfade | Same lines | Same | Pass: ghost dries in 0.8 s (voice) and 0.6 s (set) |

## Lines in one place

For Design and for a `TessVoice.violations` test table. Copy as settled by Design (speak.md `d288c11`); none are on master except the capture results. Bold is an ink word, or a value word in `doubtful`. Exact-line tests use × wherever a weight and reps show (Design d288c11, point 4).

| Key | Line | Words |
|---|---|---|
| askMic | Tess needs the mic to hear you. | 7 |
| doubtful | Didn't catch that. **84 × ?** or **80 × 4**? | 10 |
| listening | Listening | 1 |
| ready (one-time hint by the soul) | Hold me to talk. | 4 |
| readyLive (one-time hint, live mode) | Hold me to tell me a set | 7 |
| preparing | Getting speech ready. Needs a connection once. | 7 |
| micOff (also restricted) | Mic is off for Tessera. **Open Settings** | 7 |
| speechOff (`SFSpeechRecognizer` path) | Speech is off for Tessera. **Open Settings** | 7 |
| micLimited (only if readable) | The mic is limited on this iPhone. **Write** still works. | 10 |
| speechLimited (`SFSpeechRecognizer` path) | Speech is limited on this iPhone. **Write** still works. | 9 |
| micBack | Mic is on. | 3 |
| needsConnection | Voice needs a connection once to set up. | 8 |
| noLanguage | Voice isn't available in this language yet. **Write** still works. | 10 |
| nearLanguage | Listening in English (UK). | 4 |
| callTook | Call took the mic. Nothing saved. | 6 |
| callBusy | The mic is busy with a call. | 7 |
| appTook | Another app took the mic. Nothing saved. | 7 |
| silence (no word in the first 5 s) | Didn't hear anything. | 3 |
| heard | Heard: {raw transcript} | 1 + transcript |

The Heard line can pass 11 words with a long transcript. It is a quote of what he said, not Tess's voice, so the test skips it (or Builder B truncates it at the line's width).

## Test-name stubs

Swift Testing, in `TesseraTests/SpeakFlowTests.swift` (flow, with a fake permission and asset source) and `TesseraCore/Tests/TesseraTessTests/SpeakLinesTests.swift` (lines). Names only; Builder B writes the bodies.

| Test | Rows |
|---|---|
| `speakLinesPassVoiceChecker()` (every line in the table except `heard`) | all |
| `micAskedOnFirstSpeakTapOrHoldOnly()` | 1a, 1a2, 11a |
| `allowStartsListeningAtOnce()` | 1b |
| `holdHintShowsUntilFirstListeningHold()` | 1b2, 11b |
| `speechAskedAfterMicOnLegacyPathOnly()` | 1c, 4a |
| `assetsDownloadQuietlyOnFirstSurfaceOpenOnWiFi()` | 1e, 7c |
| `assetStatusCheckedOnEverySpeakTap()` | 1d, 7d |
| `pauseOfOnePointTwoSecondsEndsListening()` | 2b |
| `tapOnVeilCancelsTapStartedListen()` | 2a |
| `listeningCapsAtSixtySecondsAndSends()` | 2h |
| `noWordInFiveSecondsSaysDidntHearAnything()` | 10a |
| `capturedSetLinesUseTimesSign()` (× in every shown weight and reps; x and "by" still parse) | 2b, 2d, 2e, 7a, 7e, 11c |
| `micBackShowsOnceInPlaceOfListening()` | 6c |
| `voiceGhostDriesThreeSecondsSetTwo()` (and 0.8 / 0.6 with Reduce Motion; one cobalt draining line for Write and voice) | 2c, 7a, 12c |
| `doubtfulParseNeverCommitsOnTimer()` (guesses once, inside the line) | 2e |
| `holdListensOnlyWhileHeldAndDragLeftCancels()` | 2f |
| `spokenUndoMatchesUndoWordWholePhraseOnly()` | 2g |
| `deniedMicShowsMicOffNeverAsksAgain()` | 3a to 3c |
| `restrictedMicMapsToMicOff()` | 5a |
| `legacyRestrictedSpeechShowsSpeechLimited()` | 5c |
| `permissionReadFreshOnScenePhaseActive()` | 6c |
| `offlineWithoutAssetsShowsNeedsConnection()` | 7b |
| `unsupportedLanguageOpensLayerOnceThenLineBySoul()` | 8a, 8b |
| `nearLanguageShownOnceChoicePersists()` | 8c |
| `interruptionDropsPartialAndSavesNothing()` | 9a to 9c |
| `silenceAndFillersSayDidntHearAnything()` | 10a to 10c |

## Open questions

All Design questions are closed. The phone checks stay.

1. ~~Gesture.~~ **Closed (Design, speak.md):** tap Speak starts listening; a 1.2 s pause or a tap on the bloom ends it. Holding the soul anywhere is the fast path: let go to send, drag left to cancel. Rows 1a2, 2a, 2b, 2f.
2. ~~First hold after Allow.~~ **Closed (Design, speak.md):** listening starts at once after Allow. The ready line becomes a one-time hint, "Hold me to talk." (live mode: "Hold me to tell me a set"). Rows 1b, 1b2.
3. ~~Voice dry time.~~ **Closed (Design, speak.md):** 3 s for voice with "Heard: …" under the ghost; 2 s for a live set. Reduce Motion 0.8 s and 0.6 s. Rows 2c, 7a, 12c.
4. ~~Restricted vs denied.~~ **Closed (Design, speak.md):** restricted maps to micOff. Rows 5a, 5b.
5. ~~Speech key.~~ **Closed (Design, speak.md):** add both purpose strings. Still worth one debug build without the speech key to learn whether `SpeechAnalyzer` crashes, but it no longer decides anything.
6. ~~When to download assets.~~ **Closed (Design, speak.md):** quietly on the first open of the capture surface on Wi-Fi; row 1d is the fallback; status checked on every Speak tap. Rows 1d, 1e, 7c, 7d.
7. ~~en-IN.~~ **Closed (Design, speak.md):** use `supportedLocale(equivalentTo:)`; a near match shows nearLanguage once, and the choice persists. Row 8c. Phone check: whether en-IN gets an exact match or en-GB.
8. ~~Struck and hollow dabs.~~ **Closed (Design, speak.md):** no mode dabs. The Speak word carries the state: preparing is a 25% `live` ink line that fills with download progress; mic off or limited is the word in `inkSecondary` 21/400.
9. **Settings relaunch (phone check, not a Design question).** Confirm that turning the mic on in Settings cold-launches the app (6b). If not, the `scenePhase` check in 6c carries it.
10. ~~Undo after voice.~~ **Closed (Design, speak.md):** saying "undo" or "take that back" equals tapping UNDO. Row 2g.

## Changes after Design's sheet

- Gesture decided: tap Speak listens at once and ends on a 1.2 s pause or a tap on the bloom; holding the soul on any screen is the fast path (let go sends, drag left cancels). New rows 1a2, 2f; 2a, 2b rewritten.
- After Allow, listening starts at once (1b). The old ready line is now a one-time hint by the soul, shortened to "Hold me to talk." with a live-mode form "Hold me to tell me a set" (1b2).
- New line `listening`: "Listening" (1b, 2a, 6c, 11b).
- Voice ghost dries 3 s (0.8 s Reduce Motion) on an ink line that drains right to left (cobalt since d288c11), with the Heard line under it; live sets keep 2 s (0.6 s) as wet numerals (2c, 7a, 12c).
- Asset download moved earlier: quietly on the first surface open on Wi-Fi (new row 1e); 1d is the fallback; status read on every Speak tap and hold (7c new, 7d).
- en-IN: `supportedLocale(equivalentTo:)`, nearLanguage once, choice as value words in the line, persisted (8c).
- Restricted maps to micOff (5a). micLimited kept only for a restriction iOS can report (5b).
- Both purpose strings go in; the mic string drops "hold to talk" since tap Speak needs no hold.
- No dabs: "struck dab" and "hollow dab" are gone from every row. The Speak word shows the state: ink 21/500 ready, 25% `live` line filling while preparing, `inkSecondary` 21/400 for mic off or limited and no language.
- micOff is now "Mic is off for Tessera. **Open Settings**" (ink word, no question mark). speechOff follows the same form for consistency.
- micLimited, speechLimited and noLanguage: "Write" is now an ink word that opens the writing line.
- Spoken "undo" or "take that back" equals UNDO (2g).
- New section 12 for Design's VoiceOver action ("Talk to Tess"), the spoken Speak states, and Reduce Motion.
- Research fixes made on the way: word counts recounted on whitespace, as the checker splits (the doubtful-parse line 10, the lift capture line 8); master citations moved to `3c51cdb`; test-name stubs added.

### Item 100: after Design settled the walk (d288c11)

- Master citations moved to `fdcaee4` (after #241 no dots, #248 set guard 2).
- × on screen everywhere: 2b, 2d, 2e, 7e use ×. Set lines take master's new wording, "Set N logged. 80 × 7." (6) and "Set N logged, same again." (5), in 6d, 7a, 11c.
- Hold hint: until the first hold that listens, then never again (1b2, 11b).
- Doubtful line: "Didn't catch that. **84 × ?** or **80 × 4**?" with the guesses as value words in the line, nothing under it (2e; new key `doubtful`).
- Tap on the veil cancels a tap-started listen (2a); 5 s with no word ends it with silence (10a); every listen ends at 60 s and sends (new row 2h).
- Dry line: one cobalt `ink-line.md` lens, 2.5 pt, draining right to left, 2 s Write and 3 s voice (2c).
- micBack is "Mic is on." (3), once in place of "Listening" (6c).
- VoiceOver: the soul keeps "Opens Tess." and gains "Talk to Tess"; × is read as "by" (12a).
- Purpose strings stand as written here (Design d288c11).
- Test stubs added: `tapOnVeilCancelsTapStartedListen`, `listeningCapsAtSixtySecondsAndSends`, `noWordInFiveSecondsSaysDidntHearAnything`, `capturedSetLinesUseTimesSign`, `micBackShowsOnceInPlaceOfListening`; two renamed.

## Disagreements, settled (Design d288c11)

All 12 points this doc raised are closed by speak.md "Research's walk, settled". Where master still differs, the Speak PR (Builder B) or Core changes it.

1. **Hold on master opens the surface.** Closed: the Speak PR makes the hold listen; the soul keeps "Opens Tess." as its tap hint and gains the "Talk to Tess" action. **Master still:** `BottomChrome.swift:192` opens on a 0.4 s hold. Builder B.
2. **Mode dabs and 34 pt words.** Closed: Speak goes to 21/500 with no dabs in the Speak PR. **Master still:** #241 already removed the resting dabs (they land into the word and fade, `BottomChrome.swift:540`), but `modeFont` is 34 pt medium (lines 343-345). Builder B.
3. **How long the hold hint stays.** Closed: until the first hold that listens, then never again (1b2, 11b). Not on master.
4. **x or ×.** Closed: × in everything shown or said on screen; typed or spoken x and "by" still parse; VoiceOver reads × as "by". **Master still:** set lines already use × since #248 (`TessCaptureEngine.swift:224`); the lift line keeps a plain x for more than one set (line 211; the sheet's citation `:106` is now this line, and its `:123` is done). Core.
5. **Doubtful parse.** Closed: the guesses show once, inside the line, as value words; nothing under it (2e). Not on master; the nearest is the 2 × 10 ask (`TessSetCountAsk.swift:30`).
6. **Ending and cancelling a tap-started listen.** Closed: a tap on the veil cancels (no line); no word in 5 s gives "Didn't hear anything."; every listen ends at 60 s and sends (2a, 10a, 2h). Not on master.
7. **needsConnection word state.** Closed: the 25% `live` line, not filling; 7b stands.
8. **No language, later taps.** Closed: the line beside the soul, layer stays shut; 8b stands.
9. **UNDO colour.** Closed: `liveInk` wherever UNDO is text, on every look. **Master:** done in `BottomChrome.swift:147` (`InkLabelWordStyle.undo`, lines 619-621); still `Paint.live` in `LiveTessCorner.swift:41`.
10. **Dry line.** Closed: one cobalt `ink-line.md` lens, 2.5 pt, draining right to left, 2 s for Write and 3 s for voice (2c). **Master still:** Write's line is 1.5 pt and fills left to right (`BottomChrome.swift:312-316`); it flips to drain.
11. **speechOff and speechLimited.** Closed: in the sheet's line table, `SFSpeechRecognizer` path only (4b, 4c, 5c).
12. **micBack.** Closed: "Mic is on." once in place of "Listening"; the hold hint is left to the one-time hint (6c).

## Still open

- **Set line wording.** The sheet's live-workout example is "Set 3. 80 × 7."; master since #248 says "Set 3 logged. 80 × 7." (`TessCaptureEngine.swift:232`, lines audit X1, X2). This doc uses master's line because the engine writes it; Design to update the sheet's example or ask Core to change it.
- **Typed "by".** Design says "by" still parses. Spoken "by" does, through normaliser rule 12. A typed "80 by 8" does not parse as a set on master (`TessGrammar.swift:286` takes x or for; "by" only in the 2 × 10 ask, `TessGrammar+Live.swift:123`). Core: add `by` to the set and scheme regexes, or Design accepts spoken-only.
- **Phone checks:** whether turning the mic on in Settings cold-launches the app (6b, open question 9), and whether en-IN gets an exact or near match (8c).
