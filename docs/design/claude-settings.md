# Settings: Claude, and the cloud mark (build sheet for Builder B)

This sheet follows Product's calls of 7:17 PM PT on Research's `docs/research/settings-claude.md`, and it draws all 26 states there. Every Tess line is exactly as written in Research's table. This sheet gives each state its place, type and motion. Drawn to `no-buttons.md` and `themes.md`.

Recording: `recordings/claude-settings.mp4` (source `studies/claude-settings.html`) shows the paste, the drain, the month line and the cloud mark. It predates Product's calls. **Where it differs, this sheet wins:**
- There is no $5 / $10 / $20 drum.
- There is no sleep and energy line.
- There is no auto-paste.
- REMOVE is a tap, not a hold.
- The date reads "Nov 1".

## Settings › Claude (a section in the sentence Settings, above Units)
Every line is Body 21/400 ink. Value words are 600. Label words are Label 16/700 uppercase.

**No key (S1, S22, S23):**
- "Tess thinks **on this phone** only."
- "Add a Claude key" under it, in cobalt (`tess`) at 21.
- S22 and S23 put their Tess line above it, in cobalt.

**Pasting (S2, S3, S5):**
- Tapping "Add a Claude key" opens a 0.5pt cobalt writing line under it (360ms, house curve). There's no sheet and no box.
- It's a `SecureField`. **Paste is by long press only.** Nothing reads the clipboard on its own, so no system paste banner appears.
- All whitespace is stripped (S3).
- **Text that doesn't start `sk-ant-` (S5):** the line empties and stays open. Tess's line sits under it in cobalt: "That doesn't look like a Claude key. Paste it again?"
- Tapping away with the line empty closes it.

**Testing (S4):** the test runs by itself on paste.
1. The pasted key shows for 0.5s at `inkSecondary`.
2. **Every character but the last four drains away:** each one shrinks and drops 4pt, 9ms apart, 260ms each.
3. The cloud wisps rise off the soul while the check is out, and the soul is in thinking mode.
4. Tess says "Checking it with Claude." beside her soul.

That new line is confirmed. **The key is never drawn again,** only "...a1B2".

**The answer (S6 to S14):** the key line settles as "Key ends in **...a1B2** · works". The status word after the dot is `inkSecondary`. It reads one of:
- "works"
- "not allowed"
- "not checked"
- "account paused"

Tess's line for the state shows once beside the soul, as Research gives it.
- **S6 (works):** the switch turns to **Claude**, and the sentences below unfold (40ms stagger, rising 10pt).
- **S7 (401):** the key line goes, and the writing line reopens empty with Tess's line under it.
- **S8 and S12:** add **CONSOLE**, which opens the Claude Console in Safari.

**With a key, top to bottom:**
1. "Tess can ask **Claude**." The value word cycles to **only this phone** and back. Off keeps the key (S19).
2. "This month **$1.20** of $10." **$10 is plain text:** the cap is fixed.
   - Under it is **the month line:** a 346pt `hairline` with a 6pt brushstroke painted along it to the share spent.
   - **Under 80%:** the stroke is `tess`.
   - **At 80% (S16):** the stroke turns to the look's `now` (amber). Text never takes amber, because `now` isn't a text token. The amount stays ink, and the label word "PAUSES AT $10" appears under the line in `inkSecondary`. There's no date and no notification.
   - **At the cap (S17):** the sentence reads "Paused until **Nov 1**." and the stroke is full, in `now`. It's never red. Tess says M10 once, at the blocked use.
   - **Rollover (S18):** the stroke drains back to $0.00 in `tess` (500ms, house curve).
3. "Misses go to Claude: **yes**." The value word cycles yes and no, and reads **not today** for S25.
4. "Key ends in **...a1B2** · works", with the label words **TEST · REPLACE · REMOVE** on the line under it, 22pt apart, `inkSecondary`.
   - **TEST:** the wisps rise, and the status word crossfades to the answer.
   - **REPLACE:** a writing line opens under the key line. The old key stays and keeps working until the new one passes Test (S21). A new key that fails shows its state's line, and the old one stays.
   - **REMOVE:** a tap, with no hold and no confirm (S20).
     - Every line from 1 to 5 folds away (220ms) and S1 shows.
     - Tess says "Claude key removed. Everything stays on this phone." with **UNDO** in `liveInk` for 10s.
     - UNDO says "Claude key is back." and brings the key, the switch and the lines back as they were.
     - The Keychain item is deleted only when UNDO expires.
5. "Receipts", in cobalt. It goes one layer down to the list of uses, newest first, one line each: "6:12 pm · Plan my day · Sonnet · 1.2¢". Totals are in dollars, rounded up; one call is shown in cents. Tapping a line opens its receipt.

**Timeouts read one way:** "Claude didn't answer in time." That's at Test and in use alike (it settles C15).

## The cloud mark (S2 in the model layer)
- **While a request is away from the phone,** three short cobalt wisps (2.5pt strokes, about 30pt tall) rise off the soul in the corner.
  - Each fades up and drifts 18pt over 1.1s, 220ms apart, repeating until the answer is back. The soul pulses in thinking mode.
  - On-device work never shows wisps.
  - On dark looks the wisps have no halo (themes.md: no halo near text).
- **Every answer that used Claude** carries **VIA CLAUDE** as a label word under Tess's line. It fades with the line, and it stays on any ghost row or object Tess made, in its "made by" line.
- **Tapping VIA CLAUDE** opens the receipt in place, one layer down.
  - The page dims to 20% with a 3pt blur.
  - The receipt rises 16pt at y 610:
    - "PLAN MY DAY · SONNET · 1.2¢" in labels.
    - "Sent: your 6 tasks, their times, today's date."
    - "Not sent: health, notes, anything else." in `inkSecondary`.
  - It comes from the context pack's own manifest.
  - Under it, when there was a Claude call this month: "Tess: $1.20 this month." (M7).

## Accessibility and Reduce Motion
- **The key line** reads "Claude key, ends in a1B2, works". TEST, REPLACE and REMOVE are separate buttons for VoiceOver.
- **The month line** reads "1 dollar 20 of 10 dollars this month".
- **Reduce Motion:**
  - The characters vanish without draining.
  - The month stroke appears at its length.
  - The wisps become a still cobalt mark above the soul while the request is out.

## Owners
| Part | Owner |
|---|---|
| Keychain store, `ClaudeKeyCheck`, ledger, month rollover, misses pause | Core |
| The section, the states and lines, the month line, the key line and its words, receipts, VIA CLAUDE, wisps | Builder B |
