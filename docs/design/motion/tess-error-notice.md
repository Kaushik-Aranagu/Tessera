# The error notice (Design sheet 84, board M1)

For Builder B. Reference clips: `recordings/picks/tess-pick-error-notice.mp4` (Obsidian) and
`tess-pick-error-notice-reduce-motion.mp4`. Scene `pick-error-notice` in `prototype/tess-motion.html`
(Reduce Motion: `RM=1 node record.mjs pick-error-notice obsidian out.mp4`). The clip is 7.4 s at 9:30 am.
Corrected to sheet 84 (docs/design/errors-84.md); where they differ, the sheet wins.

## What it is
When a save fails, the notice **replaces Tess's line in the UNDO slot** (sentence at y 785). Nothing else on the page
moves, and she (the soul) does nothing: no beat, no colour, no mouth. The failure line is **ink** (Body 19 (Inter Tight 500), right-aligned beside the soul where her line sits (use the token name Body, not a pt number)),
not cobalt: cobalt is only what Tess herself says. No coloured word. There is no "TRY AGAIN" word: the sentence is the
instruction, and the whole band is the tap target (44 pt minimum).

| Beat | Time in clip | Normal | Reduce Motion |
|---|---|---|---|
| Arrives | 0.6 s | Ink sentence, 300 ms blur 4 pt to 0 with opacity | 150 ms crossfade, no blur, no rise |
| Haptic | 0.6 s | `.warning`, once, as it lands | same (the haptic stays) |
| Tap | 3.2 s | Whole band dims to 60% over 150 ms (curve 0.3, 0, 0.2, 1); a 0.5 pt ink line draws left to right under the sentence over 150 ms (the only line) | 150 ms crossfade dim, no ink line |
| Waiting | 3.35 to 5.0 s | Held at 60% with the 0.5 pt line; the page does not move | same, no line |
| Success | 5.0 s | Crossfade 150 ms to the area's own receipt, "Set 4 logged." with UNDO | same, 150 ms |
| Haptic on success | none | The area's own success haptic, never both | same |

Copy: "Didn't save. Try again." everywhere; the live workout names the set: "Set 4 didn't save. Try again."; the
receipt is the area's own, "Set 4 logged." with UNDO. Never a red, never an icon, never an alert.

**Failing again:** the line returns to full ink and there is no second `.warning` at all.

**Windows:** the notice holds 10 s (10 s under VoiceOver). "Kept it for later." holds 4 s and is not tappable.

## Rules held
One haptic for the moment (`.warning`, marked in the clip caption). No card, no sheet, no italics, Inter Tight. The
slot is shared in time, never in space: UNDO and the notice never show together. Reduce Motion drops the rise, the blur and the ink line;
the line, the dim and the receipt are 150 ms crossfades.

## Build checks
1. Arrival is 300 ms (150 ms crossfade in Reduce Motion) and fires `.warning` exactly once.
2. After the tap the notice measures 60% opacity within 150 ms and the 0.5 pt line is full width by 150 ms (none in Reduce Motion).
3. Success crossfade is 150 ms and the receipt carries UNDO in the same position.
4. Nothing else on Home changes between 0.6 s and 7.4 s.
