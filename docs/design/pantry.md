# 78. Pantry, an area with a front and a side

**Kaushik's principle, in one line:** Pantry is a place of its own that knows what he has, and it says only what is out and what is low (Kitchen's ruling, decisions 2:36 PM Oct 16).

Board `mockups/pantry.png`, recording `recordings/pantry.mp4` (18 s, Porcelain, ends on the full side), study `studies/pantry.html` (`?play` records). Builds on 73 (index), 75 (every screen has a side), 76 (depth). Rows come from `product/pantry-acceptance.md`, `kitchen-v2.md` P, R and W, and Research's `pantry-light.md`. The app never sums or totals nutrition, and no nutrition appears anywhere on Pantry.

## The front
- **Frame:** the area frame of 73. The name PANTRY at 52 (Label 15/700), "Friday" at 138, the context line at 186 with the side's word OUT AND LOW at its right, the hero at 212. (146 is the frame of a page one tap down; Pantry is a tab-level area, so it has no title and no back word.)
- **Context** "since Saturday's shop" (21 characters). **Hero** in digits: "4 out, 2 low". Quiet forms: "Nothing out" (known, none out or low), "Nothing yet" (nothing known).
- **Groups,** from 296: OUT, LOW, USUALLY HAVE, labels at 13/700. One plain Body 21 line per thing, 40 pt apart, the name in ink and its state word at the right (out 700, low 600, in the pantry colour mixed 72% with ink). Out lines carry the faint ring from the recipe page (11 pt, 1.3 pt stroke, ink 42%, at x 6), low lines nothing. Nothing is red.
- **USUALLY HAVE** is one line of names (Research R, cap 4): up to three names as is, and from four "Rice, coffee and 2 more" (two named, then the count). Names in ink, "and 2 more" at 55%. A tap on a name joins Groceries ("Milk, on Groceries.", UNDO), as on Groceries; a left swipe skips it until its next gap.
- **Tap a state word** to cycle in, low, out, in (kitchen-v2 P). One `.selection`, the line closes up (320 ms), the digits just change (nothing counts up), and the receipt names the thing first: "Limes, in." with UNDO in the one app-wide UNDO slot, replacing Tess's line for its window; UNDO brings the row back and her line returns. A line that becomes in leaves the page (in things are the long tail and show on their Ingredient page). A line that becomes low or out joins that group.
- **Tap a name** opens its Ingredient page. A left swipe on an out or low line adds it to Groceries as a ghost row ("Milk, on Groceries.", UNDO).
- **Empty:** "Nothing yet", then "Clear a shop or finish a cook and this fills in." at 55%; Tess: `Say "out of milk" and I'll keep it.`
- **Tess's line** is the only thing in 736 to 820: "Tacos took the cilantro and limes." (the phone's fact: what the last cook used up). Never a notification, a badge, a Home offer or "running out".

## The side: OUT AND LOW (AHEAD)
- **Kind AHEAD.** The brief offered BEFORE or FACTS; Kitchen's own ruling (`kitchen-sides-acceptance.md` section 5: "the natural one is OUT AND LOW, the pantry's AHEAD") and the coordinator's brief say AHEAD, and the side is what the next shop needs. The BEFORE part, "bought Sat", rides on each line as a fact. Nothing is forecast: no "due" dates, no stock counts.
- **Glance** (right half from x 150): label OUT AND LOW, the big fact "4" with its unit "out" at 56/21, then "2 low" and "6 to buy" at 19, the foot word ALL OF THEM. The "6" is the key's own number. Front at 30% under it.
- **Full side:** context "6 to buy" and PANTRY at its right; OUT lines then LOW lines, each with "bought Sat" (or "bought Tue") as the value; one key, ADD 6 TO GROCERIES (out and low lines, the dry run of the same add as the recipe peek). Receipt "Pantry, 6 added." with UNDO 4 s (a new add). At 0 the context reads "Nothing out." and there is no key. No state words and no other controls: states change on the front.
- **Tess's line** on both stops, the same line: "You buy milk about every 7 days." (Research's rhythm, only after 3 buys; empty otherwise.) Never summed, never nutrition.
- **Way in:** the right edge, then the word; Pantry has no run, so the middle also goes in (76). Reduce Motion: a 150 ms crossfade (MotionPolicy). `.selection` once at the full side, no haptic at the glance.

## The index, five areas (73)
- Order REVIEW, TODAY, TRAINING, KITCHEN, PANTRY (past at the top, Pantry nearest the kitchen). Same 104 pt pitch from 96. The glass grows from 600 to 700 and the hint moves from 548 to 652; it still ends above Tess's band at 736. Sheet 73's "five rows to 616" is superseded by this.
- **Pantry's line:** "4 out, 2 low" (12 characters), the hero, as Home does. Quiet lines: "Nothing out", "Nothing yet". Under the finger the word takes the pantry colour (72% mix), scaled to 1.06.
- **The pantry has no colour of its own (sheet 99, G175).** The ochre proposal is withdrawn. State words are ink; OUT reads heavier than LOW by weight alone (out 700, low 600). Kitchen's `areaLean` appears only on the caps labels and the index line, as on any Kitchen page. Cobalt stays Tess's voice only.
- The KITCHEN line is "Tacos, 7 pm": Product's 6:32 PM ruling drops "at" before any time, app-wide (copy-pass rule 6). This replaces the earlier "Tacos at 7 pm" of sheets 73 and 78.

## Copy rules the sheet follows
Digits for counts ("4 out", "6 to buy"); "best", never "record" (no best on Pantry); no "…"; times as "7 pm", with no "at" before a time (decisions 5:11); cobalt is Tess's voice only; receipts name the thing first ("Limes, in.", "Milk, on Groceries.", "Pantry, 6 added."); a private note is only ever "Private note" and no money or body fact appears here.

## Rows for Kitchen's acceptance
1. The front shows a counts hero, OUT then LOW then USUALLY HAVE, one line per thing, a ring on out lines only, nothing under 16 pt, no cards or pills.
2. Tapping a state word cycles in, low, out; one op and one UNDO per tap; "Limes, in." names the thing first; the digits change, nothing counts up.
3. USUALLY HAVE names up to three, and from four "A, B and N more".
4. The side's glance reads "4 out" big with "2 low" and "6 to buy"; the key's N equals the glance's "to buy" number; at 0 the side reads "Nothing out." with no key.
5. Out lines come before low lines on the side, each with "bought Sat" from `lastBoughtAt`; no sum and no nutrition anywhere.
6. The index has five rows and Pantry's line is the hero, 32 characters or fewer.
7. Empty state matches the sheet; Reduce Motion crossfades 150 ms; Dynamic Type one column.

## Changes to Kitchen's draft
- The IN group of `pantry-acceptance.md` is replaced on the front by USUALLY HAVE (the brief); "bought Sat" moves to the side's lines. In things are not listed on the front.
- The counts line of the acceptance is the hero, "4 out, 2 low".
- The side's kind is AHEAD, not BEFORE or FACTS as the brief offered.
- The side's glance adds "6 to buy" so the glance and the key show one number.

## Asks per builder team
- **Builder B:** PantryFront and PantrySide on the SideHost; the fifth `AreaIndex` row and the taller glass; the state-word cycle with `.selection` and the UNDO slot.
- **Core:** `Ingredient.state` and `lastBoughtAt` (acceptance P), the dry-run count for ADD N TO GROCERIES shared with the recipe peek, and the side's lines through the walls (names only).
- **Research:** fixtures for the Pantry glance, side line ("You buy milk about every 7 days.") and index lines ("4 out, 2 low", "Nothing out", "Nothing yet").
- **Kitchen:** confirm the AHEAD kind, the pantry colour and the foot word ALL OF THEM.
- **Motion lab:** none new; the side and index motion are 75's and 73's.

## Unresolved
Sheet number: the 5:47 PM decision called Pantry 78 and the rest of the sides 77; this sheet is 78. Section 6 of `kitchen-sides-acceptance.md` was not on master yet, so the side follows the coordinator's summary of it.

## UNDO lengths (Kitchen, Oct 16)
The ADD 6 TO GROCERIES receipt ("Pantry, 6 added.") is a new add, so its UNDO is 4 s. The state-word tap ("Limes, in.") is a change, so its UNDO is 10 s. Both are 10 s under VoiceOver (house rule, one app-wide UNDO slot).
