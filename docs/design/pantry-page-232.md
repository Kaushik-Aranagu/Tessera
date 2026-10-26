# 232 Pantry page

Board: https://claude.ai/artifact/PnzKN8FtQ2MrLqyTBYsTcM (r47). Landing is 231 (https://claude.ai/artifact/P8MtexZsp5T39K6X5PSZnr). Opened from the landing's three numbers. Builds on 226 bands, 118 C places, 161 levels, 221 pins, 131 dial (3 places).

## Bands
- Top row: "Pantry"; right "5 to get" (tap jumps the dial to To get). Left edge goes back to the landing.
- Headline (196 pt): the place dial. Three 64 pt slots: the place above and below at 17 pt ink 2 with counts, the focus at 44 pt 600 in Kitchen colour with its count in Outfit 200. Places loop: To get, Fridge, Freezer, Shelf, Counter. Drag tracks 1:1 and snaps one place on a spring; a flick moves one place; tapping a small place centres it. One haptic tick per place.
- Brief: two lines for this place, made from the data: "Low on milk and eggs. Spinach wants using by Sunday." Freezer "All good in here."; To get "Feta makes Shakshuka work. Nothing else is urgent."
- Section line (13 pt ink 2): "2 low, 1 to use soon" / "Nothing low" / "1 for a recipe"; right "1 of 2" when there are pages.
- Body: five 44 pt rows per page. Name left; right is the amount ("half", "1 bunch", "6") or "low" in Kitchen text shade 600, or "by Sunday". Pinned rows sit first, name in 600, with "pinned".
- Pages turn up and down (drag or scroll, one page per gesture) on a spring.
- Receipt line (26 pt, fixed) above the foot; Undo 10 s.
- Foot: "Add a thing", Tess. Add says "Say it or type it. Tess puts it in the right place."

## Gestures on a row
- Swipe right (90 pt): used up. The row slides off and collapses; its name arcs up to "to get", which rolls its number up. Receipt "Milk, used up. On To get. Undo". On To get, swipe right means got it: back to its place as in. "Feta, got it. Back in the fridge."
- Swipe left: not now. A low thing stops asking for today. "Spinach, not now. Asks again tomorrow."
- Tap: in or low. "Eggs, running low." Undo.
- Hold (0.5 s): pin to the top of its place; three pins per place at most ("Three pins already. Unpin one first.").
- A vertical drag never pins or swipes.

## Rules kept
No cards, bars, dots or fades; clip reveals and springs; Reduce Motion lands each in one step (no arc, number just changes). Fixed slots: names one line (Tess short form past 20), amount slot 12 chars. VoiceOver: rows are buttons with actions Used up, Not now, Low, Pin. Private items show shownLabel outside the room only.

## Reviewer fixes (Oct 23, 6:51 PM PT)
- Regions: a drag belongs to the region where it starts. A vertical drag in the 196 pt headline moves the dial. A vertical drag in the body turns the page and never moves the dial. Row swipes are horizontal. Any movement (3 pt or more) cancels the 0.5 s pin hold.
- Private items (coordinator ruling): inside the room a private item shows its real name. That name never reaches the brief, the "to get" count text, notices, widgets, the Live Activity, Siri or backup text. Briefs are made on the phone from templates, never by Claude.
1. Receipts: the newest replaces the line. Older actions stay reversible from Tess's room, where they read "Reversed".
2. Pin gives "Milk, pinned. Undo". Unpin gives "Milk, unpinned. Undo". Add gives "Basil, added to the fridge. Undo". The Add input is exempt from fixed slots.
3. Tap gives "Eggs, running low. Undo", on a 44 pt hit area. Tap does nothing on To get rows (and out items are never in a place).
4. VoiceOver: the dial is an adjustable element, one place per step, read as "Fridge, 8 things"; the rows keep their actions.
5. Colors: "low" in 93611A at 600 measures 4.9:1. The 44 pt focus place in the Kitchen colour passes as large text.
