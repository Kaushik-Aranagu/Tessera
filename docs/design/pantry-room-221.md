# Item 221: The Pantry room (Oct 23, 4:00 PM PT)

Kaushik, 3:45 PM: "We had some beautiful designs for the pantry... take care of those again". 3:44 PM: bring in the dial, the swipes and the list decisions. 3:48 PM: design each room separately.
Board: https://claude.ai/artifact/Y2DLhH4MTswxrnADkmpAvK. Built on 118 C (places, PICKED Oct 22), 118 section 7 (places column), 123 (Pantry rail row: pinned To get, knob Show All/Low/Soon, dial Fridge/Freezer/Shelf/Counter), 161 (levels), 131 section 2b (keep every feature) and 218 (lintel rules).

## Lintel: the cupboard (168 pt)
- Each place is a run of pixel columns, one per thing, 2 tiles wide, 1 tile apart, with a 4-column gap between places, in dial order.
- A column's height is the thing's level: full is 14 tiles, low is 7, and out is one pale tile (ink 3 at 45%).
- Colour steps lighter by up to 35% toward the top.
- A thing to use soon wears one ink tile on top: 75% ink in the focused place, 40% elsewhere.
- The focused place is full ochre. Other places are at 50%. When To get is open, every place is at 50%.
- Under the columns, a 4-row shelf straddles the page in 1/16 steps at 55% accent.
- Arrival: columns rise one after another, 14 ms apart, 360 ms each.
- Used up: that column drains to nothing over 700 ms.
- Touch to read: "Fridge, eggs, low, use soon". A private item reads its shownLabel.
- No numeral. No food drawings, ever.

## Title line, pin and knob
- "Pantry" is 30 pt, weight 600. The knob word on the right is 17 pt ink 2: All, Low, Soon. Swipe it sideways or tap it to step. It is remembered.
- To get is pinned under the title: 19 pt, 600, ochre, with its count in Outfit 300.
- Tap the pin and it grows to 1.5x (0.32 s), the dial dims to 30%, and the rows become To get grouped by shop section. Section words are 13 pt ink 3, in walk order.

## The dial (118 section 7 values, tuned on the board)
- Left column, 128 pt wide. Slots are a fixed 58 pt. It shows the focus plus 2 above and 2 below, and loops.
- Focus is 19 pt at 1.2x, ink, weight 600. Neighbours are 0.78x at 70%, then 0.66x at 40%. There is a slight bow of 4 pt times the square of the distance.
- A drag follows 1:1, with one selection tick per place.
- Release springs to the nearest place in 340 ms. Tapping a place springs to it.
- The rows slip 14 pt sideways. The old rows fade in 140 ms, and the new rows come in 60 ms later, 12 ms apart.
- The list never travels up and down. VoiceOver treats the dial as an adjustable element.

## Rows (two columns stay)
- Each row is 46 pt. The name is 17 pt ink on the left.
- "soon" follows the name at 13 pt ink 2.
- On the right are the level line and the amount:
  - The level line is 1.5 pt ochre with round caps, 32 pt long for full and 16 pt for low. Out has no line.
  - The amount is Outfit 300 at 16 pt, or "out".
- Pages, not scroll:
  - Six rows per page.
  - When there are more, the last line reads "3 more, swipe up" (15 pt ink 3).
  - A swipe up turns the page: rows lift 18 pt, 30 ms apart.
  - A swipe down turns back.
- Swipe right means used up:
  - A 1.5 pt ochre strike follows the finger at 0.9x, and the row leans up to 30 pt.
  - Past 90 pt it commits: the name flies to the To get pin in 620 ms on an arc, and the pin pulses to 1.1x.
  - The receipt reads "Eggs, used up. On To get." with Undo for 10 s.
- Swipe left means Not now. It hides the "soon" nudge for today.
- On To get, swipe right means bought. The name flies to the dial, its place refills, and its column rises again. The receipt reads "Lemons, bought and put on the counter."
- Numbers are instruments: drag an amount up or down to step it, one step per 14 pt.
- Long press opens the item sheet from 118: Put it in, Add to get, Used up.
- The foot action is Cook (ochre) when a dinner is planned, otherwise Plan a meal.

## Privacy and rules
- A private item uses shownLabel in rows, the scrub, receipts and VoiceOver.
- Nothing here reaches Claude, widgets or the Lock Screen beyond what Pantry already sends.
- Reduce Motion: the dial steps plainly, rows swap, nothing flies, and columns appear at once.

## Reviewer fixes (4:00 PM, folded in; these win over the sections above)
- **Lintel, no bars:** each place is one mound of whole tiles: a cosine silhouette 55% to 100% of 14 tiles tall, as wide as its things. How stocked the place is (the mean of the levels) sets the mound's density through the 4x4 ordered dither. A full place is solid; an emptier one drops tiles. The bottom row is always drawn. There is no per-thing height and no use-soon tile.
  - Arrival: the mounds rise one after another, 90 ms apart, 420 ms each.
  - Used up: the place's density eases to its new value over 700 ms.
  - Touch to read names the place and what is out or low there, for example "Fridge, eggs and cheddar low". The sentence and the rows say which things are low.
- **No fades:** a row change is a slide and swap. The old page is removed, and the new rows slide 14 pt sideways (or 22 pt up for a page turn) under a clip, 260 ms, 12 or 30 ms apart. With To get open, the dimmed dial uses ink 3 instead of alpha. The 118 §7 dial neighbour values stay.
- **Kitchen dark accent:** D49A52 was ΔE 9.1 from Ember's gold FFA90F. It moves browner, to **C49A5E**: 11.7 from FFA90F, 15.1 from FFC23D and 13.1 from FF6B3D. Light A8701F is unchanged (14.7 or more from every Ember stop). Builders: update AppAccents.swift.
- **Privacy:** inside the room private items read normally. Use shownLabel with no level on the Lock Screen, in widgets, in Tess and Claude lines, notices, backups and the doorway wave.
- **Undo duration:** kept at 10 s, per 131 §2b, which he approved on Oct 22 ("Receipts in the Tess corner with Undo for 10 s"). If one duration is wanted everywhere, 207's 5 s should move to 10 s rather than the reverse. Design asks the coordinator to confirm with him before changing it.

## Kaushik, 4:01 PM: three places on the dial, and pinned things
- The dial shows three places: the focus, one above and one below. Slots are 64 pt. The focus is 1.2x, neighbours 0.78x. A place coming in from beyond shows as it crosses.
- Pinned things: hold a row and choose Pin in the item sheet. Pinned things stay at the top of their place on every page, under the small word "Pinned" (13 pt ink 3), with their names at weight 600. The page then holds 6 minus the pinned count. The board shows Milk and Eggs pinned in Fridge and Black beans on Shelf. The receipt reads "Milk, pinned." with Undo.
- The pinned place, To get, stays as it was.

## Reviewer ruling (4:05 PM)
- Pins are capped at 3 per place. A fourth says "Three pinned here already."
- The dial window is exactly three slots, 192 pt. Places entering from beyond come in under the window's clip and never fade.
- "Milk, pinned." uses shownLabel outside the room and carries the 10 s Undo.

## Ruling: no back word (coordinator, Oct 23, 4:16 PM)
Kaushik asked why there is a back word at all. Rooms and Today show no "< Home" or "Home" word at the top. To go back, swipe from the left edge, which plays the doorway in reverse; VoiceOver escape also works. The space the word used goes to the lintel.
