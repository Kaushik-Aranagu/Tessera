# 102. CopyList receipt frame (#866), for Motion lab item 47

Product ruled (Oct 17, 8:15 PM PT): the copy does not open by itself. The receipt opens it on tap, and one UNDO slot removes it. A small frame, not a screen; the Lists front and run pages are unchanged (sheets 87, 94).

## The two receipts
- **Public:** "Packing, Lisbon, new list." The source list first, then the new list's name, then "new list". Digits for any count; no ellipsis; sentence case; a full stop.
- **Private source or private new name:** "Private list, new list." The label replaces the private name wherever it would print (G102), so "Packing, Private list, new list." never appears: if either name is private, the whole line is the private form and names neither list.
- Same type and place as every Tess receipt: Tess's line in the bottom band, Body 19/500 in cobalt (Tess's voice), 10 s with UNDO (a change), UNDO in vermilion at the right, 10 s for VoiceOver users. Information, not an error: no `.warning`.

## What a tap does
- **The line is the handle.** A tap on the receipt text opens the new list's page (the zoom out of the line, 420 ms, the same transition any list opening uses). The copy never opens by itself, so a wrong copy costs nothing.
- **UNDO** removes the new list through the one app-wide UNDO slot (`DeleteObject` on the copy). The line becomes "Lisbon, taken back." (private: "Private list, taken back."), which reads as the existing taken-back receipts do. If the page was already opened, UNDO closes it first with the back transition, then removes.
- Opening it cancels the UNDO slot's countdown display but not its window; the slot lives while the copy page is the top page, then the 10 s starts from leaving.

## Motion (all through MotionPolicy)
- The line arrives as every receipt does: fade and 8 pt rise, 240 ms; the old line leaves first. A tap target hint is not drawn; the line's underline is not used (no underlines). VoiceOver hint: "Opens the new list."
- No fly-out of items from the source list (it would imply moving). The only motion is the line and, on tap, the page zoom.
- Reduce Motion: the line crossfades in 150 ms, and the page opens with the 150 ms crossfade.
- One haptic: `.made`, once, when the copy is written. Not on the tap, not on UNDO's removal beyond the standard UNDO cue.

## Acceptance (for the Mac pass)
1. Copy "Packing" to "Lisbon": the line reads "Packing, Lisbon, new list." and the Lists front gains Lisbon only after a swipe or tap; nothing opens.
2. Tap the line: the Lisbon page opens; back returns to Lists with the line gone.
3. UNDO within 10 s: Lisbon is gone, the line reads "Lisbon, taken back."
4. A private source or name: the line reads "Private list, new list." and neither name appears in the line, VoiceOver or the op log summary.
5. Reduce Motion on: crossfade only, no rise.
