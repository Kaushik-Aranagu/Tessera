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
