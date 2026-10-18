# Motion for board 46 (Groceries finish + Pantry state change) and 47 (CopyList receipt and open-list). Oct 17, PM; (lab) = default for Design to overrule

Sources: design/kitchen/13-groceries.md (basket strip, finish by last aisle or hold Done 0.7 s, one Tess line), tess-pantry-lean-notice-motion.md (Pantry state change), task-reward.md (done pattern). No design sheet for CopyList (#866) was found in design/; section 47 reuses list patterns and is marked assumed until Design draws it.

## 46 Groceries finish, with the Pantry state change
Finish is one moment, one haptic. Sequence (t = 0 at the finishing action):
| t | What moves | Haptic |
|---|---|---|
| 0 | Hold on Done fills a 0.7 s progress (existing); after the last aisle the finish starts by itself | `.selection` at hold armed only if held (existing PaintKey behaviour) |
| 0 to 320 | The basket strip count rolls to 0 and the strip closes (height 44 pt to 0, 320 ms house curve) | none |
| 120 | Each bought item that maps to a Pantry thing changes state out/low to in: its word crossfades 160 ms (no ring, weight to 400); the Pantry hero counts (4 out, 2 low) roll 220 ms one step at a time, in the Pantry only if open; nothing animates on a closed Pantry | none (state change by a finish is not a tap, so the tap's .selection does not play) |
| 360 | Tess's line "All 14. Basket's clear." blurs in 300 ms, in the UNDO slot with UNDO (10 s, a change) | `.success` once (the finish) |
| 4 s (lab) | Tess's line drains to the resting line | none |
- One haptic: `.success` on the finish. The pantry state changes inside it are silent (they are consequences, not moments). A state change from a tap in the Pantry still plays its own `.selection`.
- UNDO undoes the finish as one step: basket restored (strip reopens 320 ms), pantry words crossfade back 160 ms; Tess's line replaced by "Undone." in the same slot (no extra haptic).
- Private items: a Private item changes state with identical motion; the receipt count does not name it.
- Reduce Motion / Low Power: strip close, word changes and line are one 150 ms crossfade; haptic stays.
- Soul: the reward beat at the `.success` (520 ms, no haptic of hers), eyes follow the strip closing; nothing else.
Acceptance: exactly one `.success` per finish; no `.selection` from pantry words changed by the finish; UNDO restores both.

## 47 / 51 CopyList (#866) receipt and open-list, per Design's sheet 102 (as relayed by Product; the sheet file itself was not readable from the lab, so confirm values against it)
- **Receipt frame:** Tess's line "Packing, Lisbon, new list." (source, then the word he gave; thing first; decisions 3:50 PM Oct 17) arrives with a 240 ms fade and an 8 pt rise in the UNDO slot (Reduce Motion / Low Power: 150 ms crossfade, no rise). One `.made` haptic at arrival (a new thing was made); nothing else buzzes.
- **Never opens by itself.** A tap on the receipt opens the copy with the house push (380 ms spring; Reduce Motion 150 ms crossfade); the copied rows arrive with the page, no stagger; the title carries the title-progress ink at progress 0.
- **UNDO** (one slot, 10 s, a change): "Lisbon, taken back." For a private list: "Private list, taken back." The copy leaves the shelf with the 320 ms line close-up; if its page is open, it pops back over 380 ms.
- The original list is untouched and unmoved; no flight between the two lists.
- Private: a Private list copies with identical motion and haptic; the receipt reads "Private list, new list." (decisions 4:00 PM Oct 17).
