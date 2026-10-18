# Capture-miss lines: offline walled line and the 8 s "Asking Claude" wait (ruling index N14, N16)

Docs only, lab default where marked; Product to overrule. Sources: DEC:1071 (1:12 AM Oct 18, offline walled phrase), DEC:1077 items 2, 3, 4, 7 and 8 (1:20 AM, Kitchen hunt 26; project file `product/decisions.md`, the repo copy lags). Shape follows `tess-error-notice.md`: the line lives in the shared Ask-slot / UNDO position, nothing else on the page moves, the soul does nothing.

## One slot, one source (DEC:1077 item 2)
The Ask-slot line and the UNDO line read from one source and always name the same op; newest wins. Two lines are never on screen together. A newer op replaces the older line with the 150 ms crossfade below; the older op's UNDO is gone with it (it is not queued behind).

## Rows
| Moment | Normal | Reduce Motion / Low Power | VoiceOver | Haptic |
|---|---|---|---|---|
| Offline, walled phrase (money, body, secret words): "Couldn't read that offline. Try again online." (DEC:1071) | ink line enters the slot, 300 ms blur 4 pt to 0 with opacity (same as the error notice); his text stays in the box untouched; nothing is queued or logged | 150 ms crossfade, no blur | spoken once on arrival | none (a miss plays none, DEC:1077 item 7) |
| Offline, no wall, retry inbox not wired: "No connection." (DEC:1077 item 3) | same entrance | same | same | none |
| Holds, then leaves | holds 10 s (10 s under VoiceOver), 150 ms fade out; not tappable (no UNDO, nothing to undo); a new keystroke in the box does not clear it | same | not re-announced | none |
| Claude wait: "Asking Claude" with Cancel (DEC:1077 item 8) | ink line in the slot, entrance as above; Cancel is a plain ink word at the line's right edge, 44 pt tap band, no underline until pressed (0.5 pt line draws over 150 ms, the error notice's tap treatment); no spinner, no pulse, no dots; the soul follows `tess-motion.md:140`: she gathers to the corner (220 ms), then enters the work state; no readers; Reduce Motion / Low Power keep full opacity and halo (M1), position and size carry "working". The no-roam rule at :141 is for a one-ask only | 150 ms crossfade, no line draw | "Asking Claude. Cancel." as one element, spoken once | none |
| Cancel | line crossfades out over 150 ms; the soul leaves the work state the same 300 ms as leaving an ask; the text stays in the box; no UNDO (nothing was written) | same | "Cancelled." not required; focus returns to the box | none |
| 8 s cap reached with no answer | same 150 ms crossfade to "No connection." only when offline is the cause; otherwise the line leaves and his text stays; the call is cancelled, never retried by itself | same | one announcement | none |
| Claude answers in time | the wait line crossfades 150 ms into the area's own receipt (named thing first) with its UNDO | same | receipt announced | the area's own `.made`, once (DEC:1077 item 7) |
| "Sent ... to Claude" notice (DEC:1077 item 4) | shows on send, not on success; ink sentence in the slot, 4 s, same entrance; it is replaced by "Asking Claude" only if the wait line is not already showing (one slot) | same | spoken once | none |

Private text in the notice and the receipt goes through the one private-text function (DEC:1077 item 5), so a masked title reads the same on both.

## Rules held
One slot in time, never in space. No haptic for a miss or a cancel; the only haptic is the area's `.made` when a Claude write lands. No spinner, no card, no sheet, no coloured word (cobalt is Tess's own voice; these are the system's lines in ink). The 8 s cap is a hard stop, not a fade.

## Build checks
1. The offline line arrives in 300 ms (150 ms in Reduce Motion / Low Power) and fires no haptic.
2. His text is byte-identical in the box before and after the line.
3. Nothing is written to TessInbox or the op log for a walled phrase offline.
4. Cancel ends the call within one frame of the tap; the line is gone by 150 ms.
5. At 8.0 s with no reply the call is cancelled and the line leaves; there is no second attempt.
6. Slot and UNDO never overlap; the newer op's line wins in the same frame.

## Asks
1. Product: confirm the 10 s hold for the offline line (lab default, matches the error notice window).
2. Product: does Cancel need a spoken confirmation? Lab default: focus returns to the box, nothing spoken.
