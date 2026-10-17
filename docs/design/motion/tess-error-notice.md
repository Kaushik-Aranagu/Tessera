# The error notice (Design sheet 84, board M1)

For Builder B. Reference clips: `recordings/picks/tess-pick-error-notice.mp4` (Obsidian) and
`tess-pick-error-notice-reduce-motion.mp4`. Scene `pick-error-notice` in `prototype/tess-motion.html`
(Reduce Motion: `RM=1 node record.mjs pick-error-notice obsidian out.mp4`). The clip is 7.4 s at 9:30 am.
Sheet 84 itself was not in the repo when this was cut; the values come from the board item (M1) and the house
line, undo and haptic rules. Where Design 84 differs, the sheet wins and the scene is re-cut.

## What it is
When a save fails, the notice **replaces Tess's line in the UNDO slot** (line at y 785, action word at y 812). Nothing
else on the page moves, and she (the soul) does nothing: no beat, no colour, no mouth.

| Beat | Time in clip | Normal | Reduce Motion |
|---|---|---|---|
| Arrives | 0.6 s | Her line style (17 pt Inter Tight 500, cobalt), 300 ms blur 4 pt to 0 with opacity; "TRY AGAIN" (16 pt 700, ink, 1.5 pt underline) under it | 150 ms crossfade, no blur |
| Haptic | 0.6 s | `.warning`, once, as it lands | same |
| Tap | 3.2 s | Whole notice dims to 60% over 150 ms (house curve 0.3, 0, 0.2, 1); a 0.5 pt ink line draws left to right under the line over the same 150 ms | same (no travel, so unchanged) |
| Waiting | 3.35 to 5.0 s | Held at 60% with the 0.5 pt line; the page does not move | same |
| Success | 5.0 s | Notice and receipt crossfade over 220 ms in the same slot: "Logged bench 2 × 10 at 80." with UNDO | same, 220 ms |
| Haptic on success | none | The receipt adds no haptic (the .warning was the notice's one) | none |

Copy: error "Couldn’t save bench 2 × 10 at 80." with "TRY AGAIN"; receipt "Logged bench 2 × 10 at 80.". Never
a red, never an icon, never an alert. If the tap fails again, the notice returns to 100% over 150 ms and the line
disappears; no second `.warning` within 2 s.

## Rules held
One haptic for the moment (`.warning`, marked in the clip caption). No card, no sheet, no italics, Inter Tight. The
slot is shared in time, never in space: UNDO and the notice never show together. Reduce Motion drops only the blur;
the crossfades and the dim stay, because they are opacity.

## Build checks
1. Arrival is 300 ms (150 ms in Reduce Motion) and fires `.warning` exactly once.
2. After the tap the notice measures 60% opacity within 150 ms and the 0.5 pt line is full width by 150 ms.
3. Success crossfade is 220 ms and the receipt carries UNDO in the same position.
4. Nothing else on Home changes between 0.6 s and 7.4 s.
