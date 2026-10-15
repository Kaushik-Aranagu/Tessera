# Settings: Claude, and the cloud mark (model layer S1 and S2, steer)

For Core (S1 and S2 sit with T3 and T4). The product calls are in `docs/product/tess-model-layer.md`: a $10 monthly hard stop, the line amber at 80%, the key in the Keychain only, and a cloud mark whenever data leaves the phone. This is drawn to `no-buttons.md`. Recording: `recordings/claude-settings.mp4` (source `studies/claude-settings.html`).

## Settings › Claude (a section in the sentence Settings, above Units)
**No key:**
- "Tess thinks **on this phone** only."
- "Add a Claude key" under it, in cobalt at 21.

**Adding the key, in place:**
- Tapping "Add a Claude key" opens a 0.5pt cobalt writing line under it (360ms, house curve). No sheet, no box.
- Paste with the normal long-press, or automatically on open when the clipboard holds a string starting `sk-ant-`. Use `UIPasteControl` semantics, so there's no system paste banner surprise.
- The pasted key shows for 0.5s at 60%. Then **every character but the last four drains away** (each one shrinks and drops 4pt, 9ms apart, 260ms each).
- What's left cross-fades into "Key saved. Ends in **x7Qa**." in cobalt.
- **The key is never drawn again** after that. Only its last four characters are shown.

**With a key, the sentences unfold** in place of the "this phone only" line (40ms stagger, rising 10pt):
- "Tess can ask **Claude**." The value word cycles to "**only this phone**" and back, which turns Claude off without forgetting the key.
- "This month **$0.42** of **$10**."
  - Under it is **the month line**: a 346pt hairline at 18% with a 6pt cobalt brushstroke painted along it to the share spent.
  - At **80%** the stroke and the amount turn amber (stroke `#D08A36`, text `#B8742A`), and a label appears under it: "PAUSES AT $10 UNTIL 1 NOV".
  - At the cap the sentence reads "Paused until **1 Nov**." and Tess says it once beside her soul.
  - **$10** is a value word that opens a drum: $5 / $10 / $20.
- "Sees sleep and energy: **no**." This is a value word, from the huddle question.
- "Misses go to Claude: **yes**." This is a value word.
- "Key ends in **x7Qa**." **Hold it** (0.7s, the stroke-word hold) to forget the key. Tess says "Key forgotten." with UNDO for 10s, and the Keychain item is only deleted once Undo expires.
- "Receipts" in cobalt. It goes one layer down to the list of uses, newest first, one line each: "6:12 pm · Plan my day · Sonnet · 1.2¢". Tapping one opens its receipt.

## The cloud mark (S2)
- **While a request is away from the phone,** three short cobalt wisps (2.5pt strokes, about 30pt tall) rise off the soul in the corner.
  - Each fades up and drifts 18pt over 1.1s, 220ms apart, repeating until the answer is back.
  - The soul pulses in **thinking** mode at the same time.
- On-device work never shows wisps, so wisps mean exactly "this left the phone".
- **Every answer that used Claude** carries **VIA CLAUDE** as a label word under Tess's line beside the soul. It fades with the line, and stays on any ghost row or object Tess made, in its "made by" line.
- **Tapping VIA CLAUDE opens the receipt in place, one layer down:**
  - The page dims to 20% with a 3pt blur.
  - The receipt rises 16pt at y 610:
    - A label line: "PLAN MY DAY · SONNET · 1.2¢"
    - "Sent: your 6 tasks, their times, today's date."
    - "Not sent: health, notes, anything else." at 60%
  - The sentences come from the context pack's own manifest, so they are always true.

## Accessibility and Reduce Motion
- **The key line** has the label "Claude key" and is announced only as "ends in x7Qa".
- **The month line** reads as "42 cents of 10 dollars this month".
- **Reduce Motion:**
  - The key characters vanish without draining.
  - The month stroke appears at its length without being painted along.
  - The wisps become a static cobalt mark above the soul while the request is out.
