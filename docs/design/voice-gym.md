# Voice in the gym (v1 slice 17, steer)

For Builder A, on the grammar Core ships ("same", "8", "80 for 7"). This follows `no-buttons.md` and the soul modes in `tess-soul.md`. Recording: `recordings/voice-gym.mp4` (source `studies/voice-gym.html`).

**The idea:** you hold the bottom of the screen and talk, and you see your words land as the set. You never look for a mic button, because the whole Tess horizon is the button.

## Hold to talk
- **Where:** anywhere on the Tess horizon (the bottom 150pt band). The idle line in live mode reads "Hold to tell me a set" until it has been used three times, then just "Ask Tess…".
- **Touch-down, after 150ms so it doesn't catch scrolls:**
  - The soul goes to **listening**: it scales from 0.5 to 1 (360ms), and its dabs bloom out to their bloom targets, staggered by thirds (`tess-soul.md`). The bloom's amplitude follows the mic level.
  - The writing line turns light cobalt (`#9DBFE6`, 90%).
  - Tess's line reads "Listening".
  - Haptic: `.impact(light)`.
- **What you say appears above the horizon**, at Title 34 at y 560:
  - Each word fades up out of a 6pt blur at 60% as soon as the recogniser has it, a word at a time (no glyph reveal: speech is the pacing).
  - Corrections from the recogniser cross-fade the word in place.
- **Release** stops listening: the soul settles back to 0.5 and the line goes back to cream.

## From words to a set
- **The parse:** the heard words cross-fade (blur 4pt) into the parsed set in full cream: "eighty for seven" becomes "80 × 7", and "same" becomes "80 × 7 again".
- **It flies to its stroke:** the parsed text travels up and shrinks into the current set's stroke (420ms, `cubic-bezier(.5,0,.2,1)`). The weight numeral and reps drum change to it.
- **The ghost:**
  - The set's stroke paints in at **35%** (420ms), and Tess says the set back: "Set 3, 80 × 7."
  - A 1.5pt light cobalt line **draws along the writing line over 2s**. That is the ghost drying, and it is the same 2s rule as every Tess ghost row.
  - Touching anything during those 2s cancels: the ghost drains and the instruments roll back.
- **Saved:**
  - The stroke reaches full paint with a small swell (scaleY 1.25, 260ms).
  - Haptic: the normal logged-set clunk, then `.success`, exactly as a held Log set.
  - **UNDO** appears as a label word and stays until the next set.

## When it doesn't understand
- The words stay at 40% and Tess says "I heard 'eighty forty'. Try '80 for 7'." with no ghost.
- They fade after 2.5s, and nothing changes.

## Noise and privacy
- On-device speech only: `SpeechAnalyzer` with `requiresOnDeviceRecognition`. The mic permission is asked the first time you hold, never on launch.
- If the mic is denied, the hold shows Tess's line "Turn on the microphone in Settings to talk to me." once, and the horizon falls back to typing.

## Accessibility and Reduce Motion
- **VoiceOver:** the horizon has a "Talk to Tess" action, and the parsed set is announced.
- **Reduce Motion:**
  - The soul shows listening at a fixed 0.8 scale, with no bloom.
  - Words appear without the blur.
  - The parsed text cross-fades in place instead of flying.
