# Speak: the voice layer (board item 9)

For Builder B's Speak PR. It's drawn to `no-buttons.md`, `calm-capture.md`, `voice-gym.md`, `no-dots.md`, `ink-line.md` and `themes.md` (one base). It answers Research's `speak-first-use.md` (item 30, merged as #243), which takes its lines from here. **Research's states, pass rules and exact lines stand** except where this sheet changes them. Research's 12 open disagreements are settled in "Research's walk, settled" at the end (16 Oct).

Recording: `recordings/speak.mp4` (source `studies/speak.html`). Redrawn 16 Oct (item 30) on the build's frames: Home is the build's Today (tabs, day label, day stroke, "today", Rest day, Next), the workout is the build's set screen (Push A, 0:24, Bench Press, the numeral row, plates, Log set), the soul sits at the build's centre, and Tess's line trails beside it with UNDO under it (`day-seams.md` S1, S2, S5, S6). The listening and tidying motion is unchanged. The recording plays the Home half, then the workout half.
- On the left: Speak from the capture surface on Home, showing listening, the words as heard, tidying, and the voice ghost drying.
- On the right: holding the soul in a live workout, where "eighty for seven" lands as the set.
- State still: `mockups/speak-states.png` (preparing, mic off, silence).

## The open questions, decided
1. **Gesture: both, one rule each.**
   - **From the surface:** tap the soul, then tap **Speak**. Listening starts at once, with no hold, because choosing Speak already says "I'll talk". A 1.2s pause or a tap on the bloom ends it.
   - **The fast path anywhere:** **hold the soul at rest**, on any screen, workout or not. It listens while held, and letting go sends it. Dragging left off the soul cancels.
   - The hint "Hold me to tell me a set" (live mode) or "Hold me to talk" (elsewhere) sits beside the soul **until the first hold that listens**, then never again.
   - **Cancel:** a tap on the veil (outside the bloom) cancels a tap-started listen. Nothing is saved and there's no line.
   - **Limits:** if no word comes in the first 5s, listening ends with "Didn't hear anything." Any listen ends at 60s and sends what it heard, as a pause would.
2. **First tap after Allow:** listening starts right away. He tapped Speak to talk, so a second gesture would be friction. Research's `ready` line becomes the one-time hint by the soul, not a step.
3. **Dry time:**
   - **3s for voice outside a workout.** The transcript is less certain than typing, and the Heard line needs a moment to read.
   - **2s for a set in a live workout,** where the set guard already asks when a set is doubtful.
   - Reduce Motion: 0.8s and 0.6s.
4. **Speech assets:** download quietly the first time the capture surface opens on Wi-Fi, so first use is instant. Row 1d stays as the fallback when Speak is tapped before that finishes. Check `AssetInventory.status` on every Speak tap.
5. **en-IN:** use `supportedLocale(equivalentTo: .current)`. If it's a near match, show `nearLanguage` once. Tapping that line opens the language choice as value words in the same line (for example **English (US)** · **English (UK)**), and the choice persists.
6. **Restricted vs denied:** use `micOff` unless iOS can tell them apart.
7. **The speech key:** add both purpose strings, as Research wrote them.
8. **"Struck and hollow dabs" aren't needed.** There are no dabs beside the mode words any more (`no-dots.md`). States show on the **Speak word itself**:
   - **Ready:** `ink`, 21/500.
   - **Preparing** (assets downloading): the word sits on an ink line in `live` at 25%, and the paint fills left to right as download progress.
   - **Mic off or limited:** the word is `inkSecondary` at 21/400, with no strike.
   - **No language:** the word is `inkSecondary`, and the layer opens once to say so.
9. **Saying "undo":** "undo" or "take that back", said as the whole phrase, does the same as tapping UNDO on the last line.

## Listening (from the surface)
- **The soul moves.** It travels from the corner to (196, 698) on the settle spring and becomes the listening bloom (×1.4). The bloom breathes with the mic level, between ×1.4 and ×1.55.
- **The other words fold away:** Write, Show and the question fade (200ms).
- **"Listening"** shows at Body 21 in cobalt at y 470.
- **Words as heard** stream onto the line below at **Body 21/400 in `inkSecondary`**, each one rising out of a 6pt blur (calm-capture's tier, not Title 34).
- **The end:** a 1.2s pause, or a tap on the bloom, ends it.
  - Tidying squeezes out fillers and dropped words (width to 0, 320ms).
  - The rest crossfades into the **clean sentence** in `ink`, with the destination as a value word: "Oat milk and eggs, on **Groceries**."

## The voice ghost
- **The clean sentence sits at 45%** with the **Heard line** under it in `inkSecondary`: "Heard: oat milk and um eggs". That's the transcriber's raw words.
- **A thin ink line in cobalt** sits between them and drains right to left over 3s (`ink-line.md` shape, 2.5pt). Write's ghost uses the same line over its 2s, so a drying ghost reads one way everywhere.
- **Touching the ghost** stops the drying, and the sentence opens in the Write line to edit.
- **When it dries:**
  1. Everything gathers back into the soul (220ms).
  2. The page comes forward.
  3. Tess says the result beside the soul with UNDO in `liveInk` (the text-safe live, `Looks.swift:44`): "Added oat milk and eggs to Groceries."
- **A doubtful parse** (Research 2e) shows no draining line. Tess's line names the guesses, and **the guesses in the line are the value words**: "Didn't catch that. **84 × ?** or **80 × 4**?" Nothing sits under it, and nothing commits until he taps one.

## In a live workout ("80 for 7")
- **Hold the soul in the corner.** No surface and no wash: the soul swells in place (×1.4) and breathes with the level.
- **The words** stream right-aligned above the soul at **Field 18** in `inkSecondary` (his words, one step under her voice: `calm-capture.md` addendum; item 56): "eighty for seven".
- **Let go.** The words fade out (250ms), and the set block's numerals become the ghost: they turn wet cobalt at 62% and show **80 × 7**.
- **After 2s they dry into ink.**
  - The new set stroke lands under the earlier ones on the settle spring, wet in its cycle colour, then dries to `restTint`.
  - Tess says "Set 3 logged. 80 × 7." with UNDO.
  - The rest horizon starts.
- **Touching the numerals while they're wet** stops the drying, and they become the in-place editor (`set-block.md`).
- **The workout is on the look's own base** (one base), so on Porcelain it's white with ink numerals.

## Lines (Research's, with Design's changes in bold)
| Key | Line |
|---|---|
| askMic | Tess needs the mic to hear you. |
| doubtful | Didn't catch that. **84 × ?** or **80 × 4**? (the guesses are value words) |
| ready (one-time hint by the soul) | **Hold me to talk.** (live mode: "Hold me to tell me a set") |
| preparing | Getting speech ready. Needs a connection once. |
| micOff | Mic is off for Tessera. **Open Settings** (an ink word, no question mark) |
| micLimited | The mic is limited on this iPhone. **Write** still works. ("Write" is an ink word) |
| speechOff (`SFSpeechRecognizer` path only) | Speech is off for Tessera. **Open Settings** |
| speechLimited (`SFSpeechRecognizer` path only) | Speech is limited on this iPhone. **Write** still works. |
| micBack | **Mic is on.** (in place of "Listening", once; the hold hint is left to the one-time hint) |
| needsConnection | Voice needs a connection once to set up. (The Speak word sits on the 25% `live` line, not filling.) |
| noLanguage | Voice isn't available in this language yet. **Write** still works. (The layer opens for it once. Later taps show the line beside the soul without opening the layer.) |
| nearLanguage | Listening in English (UK). |
| callTook | Call took the mic. Nothing saved. |
| callBusy | The mic is busy with a call. |
| appTook | Another app took the mic. Nothing saved. |
| silence | Didn't hear anything. (no word in the first 5s) |
| heard | Heard: {raw transcript} |
| listening | **Listening** |

**Placement:** all of these are Body 21/400 in cobalt at y 470 in the Speak layer, or beside the soul when the layer is closed. They show once per event, and nothing counts tries.

## Accessibility and Reduce Motion
- **Holding the soul** has a VoiceOver action, "Talk to Tess", that starts and stops listening with a double tap. The live transcript is announced when it settles, not word by word.
- **The Speak word** says its state: "Speak, getting ready", "Speak, microphone off".
- **Reduce Motion:**
  - The soul doesn't travel; the bloom is a still mark at 1.2×.
  - The words fade in without blur.
  - Tidying is a crossfade.
  - The ghost dries in 0.8s (0.6s in a workout).

## Research's walk, settled (16 Oct, `speak-first-use.md` #243)
1. **Hold on master opens the surface** (`BottomChrome.swift:192`). The Speak PR makes the hold listen. The soul keeps "Opens Tess." as its tap hint and gains the "Talk to Tess" action. Builder B, already in the Speak work.
2. **Mode dabs and 34pt mode words on master** (`ModeRow`, `BottomChrome.swift:528`, `modeFont` 343-347). These go to 21/500 with no dabs in the Speak PR. Builder B.
3. **How long the hold hint stays:** until the first hold that listens, then never again.
4. **× or x: × app-wide** in everything shown or said on screen: Tess lines, set lines, the doubtful line, the Day log. Typing or saying "x" or "by" still parses. Change `TessCaptureEngine.swift:106` and `:123` to ×, and the tests follow. VoiceOver reads × as "by" ("80 by 7").
5. **The doubtful-parse guesses** show once, inside Tess's line as value words. Nothing sits under it.
6. **Ending a tap-started listen:** a tap on the veil cancels (nothing saved, no line). No word in the first 5s ends with "Didn't hear anything." Every listen, tap or hold, ends at 60s and sends.
7. **needsConnection:** the Speak word sits on the 25% `live` line, not filling. Research's 7b stands.
8. **No language, later taps:** the line shows beside the soul, and the layer doesn't open. Research's 8b stands.
9. **UNDO colour:** `liveInk` wherever UNDO is text, on every look. `Theme.Colors.live` at `BottomChrome.swift:147` (via `InkLabelWordStyle.undo`) and `Paint.live` at `LiveTessCorner.swift:41` move to `liveInk`. On Porcelain that's #C23A22, which passes contrast at 16/700 where #E2432A doesn't.
10. **Dry line:** one line for every drying ghost. It's the `ink-line.md` lens at 2.5pt in cobalt, draining right to left: 2s for Write, 3s for voice. Master's Write line (`BottomChrome.swift:312-316`, cobalt, filling left to right) flips to drain.
11. **speechOff and speechLimited** are in the line table above, for the `SFSpeechRecognizer` path only.
12. **micBack** is now "Mic is on." It shows once in place of "Listening", and the hold hint is left to the one-time hint.

**Purpose strings:** Research's stand, including the mic string's "while you talk to her".
