# 92. Gap lane: whose-swipe, area colour pass, private titles

Product's four asks of Oct 17 (2:15 PM PT), written as specs. No study yet; each can become one on request. Nothing in the app changes.

## 1. Sheet 90b: whose swipe, on three real screens
The rule: a vertical swipe on an element with its own vertical action runs that action; on plain text, a section word or the empty page it turns the page; a focused field never turns it.
| Screen | Runs its own action | Turns the page |
|---|---|---|
| Lists (a list page) | a row's check circle (tap only); a pick-one hold; the quantity stepper (step up and down) | an item's words, a section word, the gap between rows |
| Recipe | the portion drum (turns the serving count); a timer's number (steps minutes) | step text, ingredient names, the section words |
| Money dial | the amount dial itself (rolls the number); the date chip (steps a day) | the line's words, the month word, the empty page |
- A swipe that starts on an element never hands over mid-gesture: the element that took the first 8 pt keeps it to the end.
- An element at its limit (a stepper at 0) absorbs the swipe with its own small stop; it does not turn the page.
- VoiceOver: the element's adjustable action is the vertical one; the page turn is the Scroll gesture and the rail.

## 2. Area colour pass on sheet 86 C
`areaLean(area)` is a 72% mix with ink, used only on caps labels, the title's key word, the lead numeral and the section hairline at 34%. One value per area:
| Area | Porcelain | Obsidian |
|---|---|---|
| Training | #C23A22 | #FF7D62 |
| Kitchen | #12936A | #52D3A3 |
| Review | #5A3DAF | #B8A3FF |
| Today | none (cobalt is Tess's voice) | none |
- **Pantry ochre goes.** Pantry is part of Kitchen, so its state words take Kitchen's `areaLean` (the same 72% mix), not #A4601A / #E3A857. The index keeps one Kitchen colour. A pantry state is told apart by its word and its position, never by a second hue.
- Lists, Notes, Habits, Money and Reading take the colour of the area they are opened from; opened from Home they take Today's ink.
- Never on rows, notes, fills, dots or Tess.

## 3. Private titles: how "Private workout" reads
One string, in the same type as any title, nothing added.
- Home and Now: "Private workout" in the hero's place and weight; the context line is the time or "Today" as usual; no lock, no dimming, no asterisks.
- Day log: the line reads "Private workout" with the time at the right, as any line; its sets are not listed.
- A routine page opened from it: the title "Private workout", the same section words, set rows show numbers only.
- Receipts and Tess's line use the same string, thing first ("Private workout, done").
- Same pattern for "Private recipe", "Private list", "Private note", "Private item".

## 4. Muscle figure from reference images
Blocked: this environment's network proxy blocks the sites that hold anatomical references, so the redraw is from proportions only (sheet 91). Needs Kaushik's yes or no on the current figure, or reference images dropped into the project; then I redraw to them.

## Answers to Research #897 (Oct 17, 4:21 PM PT)
- **(a) Pigment.** The hexes in the area table are the pigments. What is drawn is the 72% mix with ink (`areaLean`): Kitchen on Porcelain #126E52, 6.22:1, which clears 4.5:1 for small caps labels. Builders use the mixed value; no pigment is drawn straight.
- **(b) Master is truth.** The Obsidian ground is #000000 and the partners are master's `liveInk` (#FF7A5C, Training), `health` (#3FD49A, Kitchen) and `context` (#B7A6E0, Review). The #121014 ground and the #FF7D62 / #52D3A3 / #B8A3FF hexes on the sheet 86 and 92 boards were board approximations, now void; areaLean on Obsidian mixes those three master pigments 72% with ink.
- **(c) The drum absorbs at its limit.** The portion drum owns every vertical drag that starts on it (a high-priority gesture, parent scroll disabled while it is down). At 1 or its top value it rubber-bands 6 pt and stops with `.bound` once per push; the drag is never handed to the page, so it cannot turn the page. A drag that starts anywhere else on the recipe page turns it. Same for the Money dial and any stepper (sheet 90b).
- **(d) The rail stays neutral.** Research's lean wins: the current segment is `ink` at 3 pt, the others `inkSecondary` at 2 pt; text carries the area colour (label, key word, numeral). Sheet 90's "current segment in the area colour" is withdrawn.
- **(e) Sheet 73 is in the folder as `area-index.md`** (title "73. No tab row: the index"); it lives under that name, not 73.md.

## Area lean per look (Oct 17, 5:05 PM PT; supersedes the table in section 2)
`areaLean` is the 72% mix of the area's token with the look's `ink`. Tokens are master's (`looks-recut.md`): Training = `training` (never `liveInk`, which is reserved for a running thing), Kitchen = `health`, Review = `context`. The earlier board hexes are void.
| Look | Training | Kitchen | Review |
|---|---|---|---|
| Porcelain | #CC3F68 → #983251 (7.22) | #12936A → #126E52 (6.22) | #5A3DAF → #463084 (10.41) |
| Plein | #B04A5E → #893E4C (6.31) | #5E8F5A → #4E7049 (4.82) | #7D4E6E → #654158 (7.36) |
| Celadon | #BF4664 → #8D3B4F (5.93) | #1F8B6A → #1A6C53 (5.14) | #3A6584 → #2D5166 (6.87) |
| Obsidian | #FF6B92 → #FC91AB (9.78) | #3FD49A → #72DCB1 (12.59) | #B7A6E0 → #C8BBE3 (11.67) |
| Lacquer | #F48BA6 → #F4A5B3 (10.10) | #86C9A0 → #A5D2AF (11.55) | #D9A6B8 → #E0B8C0 (10.94) |
Contrast in brackets, mixed colour on the look's `ground`; every cell clears 4.5:1 for small caps labels.
- **Watch:** on Lacquer, Training (#F4A5B3) and Review (#E0B8C0) are both rose and close. The word, not the hue, tells them apart there; if it reads muddy on the phone, Review gets a gold-leaning `context` on Lacquer only.
- **The 34% hairline is decoration.** It needs no 3:1 contrast because nothing is carried by the hairline alone. Meaning lives in the label, the key word and the numeral, and those pass 4.5:1 (above). The 3:1 row is dropped.
