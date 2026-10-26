# Voice in the gym (v1 slice 17, steer)

> **Sweep 16 Oct (item 19):** parts of this sheet are amended by `sweep-19.md` (no dots, one base, the context line). Where they differ, `sweep-19.md` wins.

For Builder A, on the grammar Core ships ("same", "8", "80 for 7"). This follows `no-buttons.md` and the soul modes in `tess-soul.md`. Recording: `recordings/voice-gym.mp4` (source `studies/voice-gym.html`).

**The idea:** you hold Tess's soul in the corner and talk, and you see your words land as the set. This is the hold-to-Speak fast path of the Tess capture surface (`no-buttons.md`, Tess section), with no wash and no menu, because what you say lands on what you are looking at.

## Hold to talk
- **Where:** the soul at rest in the bottom-right corner (64×64 hit area). Beside it, the hint "Hold me to tell me a set" shows in live mode until it has been used three times, then nothing.
- **Touch-down, after 150ms so it doesn't catch scrolls:**
  - The soul rises out from under the thumb to the left (translate (−150, −90), scale 0.72→1.5, 420ms) and goes to **listening**: its dabs bloom out to their bloom targets, staggered by thirds (`tess-soul.md`). The bloom's amplitude follows the mic level.
  - "Listening" shows at 21 in light cobalt (`#9DBFE6`) at y 510, and the hint beside the corner fades.
  - Haptic: `.impact(light)`.
- **What you say appears above the bloom**, at Title 34 at y 560:
  - Each word fades up out of a 6pt blur at 60% as soon as the recogniser has it, a word at a time (no glyph reveal: speech is the pacing).
  - Corrections from the recogniser cross-fade the word in place.
- **Release** stops listening: the soul flies back into the corner (380ms).

## From words to a set
- **The parse:** the heard words cross-fade (blur 4pt) into the parsed set in full cream: "eighty for seven" becomes "80 × 7", and "same" becomes "80 × 7 again".
- **It flies to its stroke:** the parsed text travels up and shrinks into the current set's stroke (420ms, `cubic-bezier(.5,0,.2,1)`). The weight numeral and reps drum change to it.
- **The ghost:**
  - The set's stroke paints in at **35%** (420ms), and Tess says the set back: "Set 3, 80 × 7."
  - Tess's line appears beside the soul, and a 1.5pt light cobalt line **draws under it, right to left, over 2s**. That is the ghost drying, and it is the same 2s rule as every Tess ghost row.
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
- If the mic is denied, the hold shows Tess's line "Turn on the microphone in Settings to talk to me." once, and holding the soul opens Write instead.

## Accessibility and Reduce Motion
- **VoiceOver:** the soul has "Talk to Tess" and "Open Tess" actions, and the parsed set is announced.
- **Reduce Motion:**
  - The soul shows listening at a fixed 0.8 scale, with no bloom.
  - Words appear without the blur.
  - The parsed text cross-fades in place instead of flying.
