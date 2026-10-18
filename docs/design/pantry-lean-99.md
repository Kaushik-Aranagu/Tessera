# 99. Ochre decision, one area-colour list for Builder A, private-look audit

Product's refill of Oct 17 (6:40 PM PT). Docs only; nothing in the app changes.

## 1. Pantry ochre: decided, it stays out (G175)
Pick **Reading B: no ochre. The state words are ink and OUT is heavier than LOW by weight; Kitchen's `areaLean` stays on the caps labels and the index line only.** (Corrected Oct 17, 6:55 PM PT after #917: an earlier draft put `areaLean` on the words, but sheet 92 keeps it off rows, and ink is what the app built.) (Sheet 92 section 2 already ruled this; this sheet closes G175 and retires the ochre line in `pantry.md`.)
- Pantry is a part of Kitchen. A second Kitchen-side hue would make the index say two things for one area.
- State is told by the word (OUT, LOW, IN, NOT SURE) and its place on the page (sheet 98), never by colour alone; that holds for colour-blind readers too.
- Ochre (#A4601A / #E3A857) is Plein's third dab for Tess, so using it for words would blur her voice with a state.
- Cost of the other reading: one more token per look, five more contrast checks, and a hue that must stay apart from Training's rose on Lacquer.
Sheet 98's greyed 42% for OUT and LOW stays; it is ink, not a hue.

## 2. Builder A's one list: the area-colour pass
Use `Theme` tokens, mixed 72% with the look's `ink`; the mixed value is what is drawn, never the pigment.
| Look | Training (`training`) | Kitchen (`health`) | Review (`context`) |
|---|---|---|---|
| Porcelain | #983251 | #126E52 | #463084 |
| Plein | #893E4C | #4E7049 | #654158 |
| Celadon | #8D3B4F | #1A6C53 | #2D5166 |
| Obsidian | #FC91AB | #72DCB1 | #C8BBE3 |
| Lacquer | #F4A5B3 | #A5D2AF | **#BCC8D6** (`sky`, not `context`) |
- Lacquer Review uses `sky` #BCC8D6 (hue 212, 11.49:1) because Training and Review roses were hue 349 and 348. The Review context line itself stays rose; only the label, key word and numeral go blue. Every other look keeps `context`.
- Training is `training`, never `liveInk` (that is for a running thing). Today has no area colour (cobalt is Tess's voice). Pantry = Kitchen.
- Used only on caps labels, the title's key word, the lead numeral and the section hairline at 34%. Never on rows, notes, fills, dots or Tess. Rail stays neutral (`ink` 3 pt current, `inkSecondary` 2 pt others).
- Lists, Notes, Habits, Money and Reading take the colour of the area they are opened from; from Home, Today's ink.
- Motion and test rules: sheet 97 (320 ms arrival, 150 ms crossfade under Reduce Motion, no haptic, Obsidian and Porcelain tested, largest Dynamic Type).
- Contrast of every cell is on sheet 92; all clear 4.5:1 on the look's ground.

## 3. Audit: where a private item's look differs from its label
Rule (sheet 92 section 3, G102): one string in the same type as any title, same weight and place as the real thing. No lock, no dimming, no asterisks, no reveal. Read at master `7bd6065f` plus the PR text of #885, #895, #912; Mac is locked, so nothing was run.
| # | Where | What differs | Fix | Sheet |
|---|---|---|---|---|
| P1 | Recipes shelf row (`RecipesShelfView.swift:83`, and the count line near :68) | A private recipe draws at 66% ink while every other row is 100%. The dimming is a tell. | Draw "Private recipe" at 100% like any recipe row; drop the `row.isPrivate` opacity. | 87 (the "66%" there is withdrawn), 92 s3 |
| P2 | Groceries and a list page, private row | Today the label draws the same as a row, but the hint says "Shows it" (:300, :526) and the text swaps on tap. | Covered by #885: same string, hint "Puts it in the basket" / "Checks it off". Verify no leftover style on the swapped row. | 98, 92 s3 |
| P3 | Basket (Groceries) | Basket rows are 35% ink once taken (:568). A private basket row must match a normal one, not look lighter or heavier. | Same 35% for every checked row, private or not; check in a side-by-side screenshot. | 98 |
| P4 | Home and Now hero, Review, Day log | Strings come from Core's mask (#895). Check each draws at the hero's own weight and place, with the context line as usual, and the Day log time at the right. | No new look; walk each with a private workout and a private list. | 92 s3 |
| P5 | Object page header and class line (#912) | A masked header should keep the title type, and the class line should read "object Private item : Ingredient"-free; the class name stays, the words do not. | Header same type; class line prints the class only. | 92 s3 |
| P6 | Any alignment | Masked strings are shorter than real titles, so a right-aligned time or count must stay pinned, not float inward. | Fixed trailing column; no centring on short text. | 92 s3 |
P1 is the only one I can name from the source; P2 to P6 are checks to make on the phone or simulator when the Mac is back.
