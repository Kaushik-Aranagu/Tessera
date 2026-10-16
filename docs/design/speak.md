# Speak: the voice layer (board item 9)

For Builder B's Speak PR. It's drawn to `no-buttons.md`, `calm-capture.md`, `voice-gym.md`, `no-dots.md`, `ink-line.md` and `themes.md` (one base). It answers Research's `speak-first-use.md` (item 30), which takes its lines from here. **Research's states, pass rules and exact lines stand** except where this sheet changes them.

Recording: `recordings/speak.mp4` (source `studies/speak.html`).
- On the left: Speak from the capture surface on Home, showing listening, the words as heard, tidying, and the voice ghost drying.
- On the right: holding the soul in a live workout, where "eighty for seven" lands as the set.
- State still: `mockups/speak-states.png` (preparing, mic off, silence).

## The open questions, decided
1. **Gesture: both, one rule each.**
   - **From the surface:** tap the soul, then tap **Speak**. Listening starts at once, with no hold, because choosing Speak already says "I'll talk". A 1.2s pause or a tap on the bloom ends it.
   - **The fast path anywhere:** **hold the soul at rest**, on any screen, workout or not. It listens while held, and letting go sends it. Dragging left off the soul cancels.
   - The hint "Hold me to tell me a set" (live mode) or "Hold me to talk" (elsewhere) sits beside the soul until it has been used three times.
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
- **A thin ink line in `live`** sits between them and drains right to left over 3s (`ink-line.md` shape, 2.5pt).
- **Touching the ghost** stops the drying, and the sentence opens in the Write line to edit.
- **When it dries:**
  1. Everything gathers back into the soul (220ms).
  2. The page comes forward.
  3. Tess says the result beside the soul with UNDO in `liveInk`: "Added oat milk and eggs to Groceries."
- **A doubtful parse** (Research 2e) shows no draining line. The two guesses are value words under it ("**84 × ?** · **80 × 4**"), and nothing commits until he taps one.

## In a live workout ("80 for 7")
- **Hold the soul in the corner.** No surface and no wash: the soul swells in place (×1.4) and breathes with the level.
- **The words** stream right-aligned above the soul at Body 21 in `inkSecondary`: "eighty for seven".
- **Let go.** The words fade out (250ms), and the set block's numerals become the ghost: they turn wet cobalt at 62% and show **80 × 7**.
- **After 2s they dry into ink.**
  - The new set stroke lands under the earlier ones on the settle spring, wet in its cycle colour, then dries to `restTint`.
  - Tess says "Set 3. 80 × 7." with UNDO.
  - The rest horizon starts.
- **Touching the numerals while they're wet** stops the drying, and they become the in-place editor (`set-block.md`).
- **The workout is on the look's own base** (one base), so on Porcelain it's white with ink numerals.

## Lines (Research's, with Design's changes in bold)
| Key | Line |
|---|---|
| askMic | Tess needs the mic to hear you. |
| ready (one-time hint by the soul) | **Hold me to talk.** (live mode: "Hold me to tell me a set") |
| preparing | Getting speech ready. Needs a connection once. |
| micOff | Mic is off for Tessera. **Open Settings** (an ink word, no question mark) |
| micLimited | The mic is limited on this iPhone. **Write** still works. ("Write" is an ink word) |
| micBack | Mic is on. Hold me to talk. |
| needsConnection | Voice needs a connection once to set up. |
| noLanguage | Voice isn't available in this language yet. **Write** still works. |
| nearLanguage | Listening in English (UK). |
| callTook | Call took the mic. Nothing saved. |
| callBusy | The mic is busy with a call. |
| appTook | Another app took the mic. Nothing saved. |
| silence | Didn't hear anything. |
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
