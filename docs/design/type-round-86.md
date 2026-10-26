# 86. Type and colour, three options

**Kaushik's principle, in one line:** the drawn screens are close, but the type is thin and the steps between title, list and notes are too small; make it stronger and a little editorial, and let a little colour in, still subtle.

His words (Oct 16, 8:16 PM PT): "I like most of them but need some changes in the text font sizes between different types like title and list and notes. The font looks very thin but need some better and a little bit of editorial style maybe. And colors too might need more color but subtle still."

Board `mockups/type-round-86.png` (4 rows by 4 columns: Home, Notes, a routine, Review's week; columns A, B, C and C in Obsidian), recording `recordings/type-round-86.mp4` (17 s, Porcelain, the Notes screen flipping A, B, C, A, C with every token tweened), study `studies/type-round-86.html` (`?play` records). Copy is from the existing sheets (41, 81, 46/83, routine-editor, training-mode). Nothing in the app changes.

## What stays (his earlier decisions)
Inter Tight only (variable 100 to 900), no italics, 16 pt floor (the caps label stays the house label at 13), tabular figures, no cards or pills, no brush underline, no coloured dots. Titles keep sheet 72's round 2: the whole title gets bolder and shifts colour per stage, the key word leads, done strikes through. Cobalt is Tess's voice only. Colour arrives through motion and rests low. Editorial comes from weight, size contrast, tracking, small-cap labels, rules, numeral scale and ink steps, never a serif.

## Token tables (size pt / weight / tracking / line height / ink opacity)
| Token | A Heavier | B Editorial steps | C = B plus colour |
|---|---|---|---|
| Hero | 56 / 640 / -3.5% / 58 / 100% | 60 / 700 / -4% / 62 / 100% | same as B |
| Title | 44 / 650 / -3.5% / 50 / 100% | 52 / 650 / -3% / 56 / 100% | same as B |
| Section word (Home's Next) | 34 / 620 / -3% / 40 / 100% | 34 / 650 / -3% / 40 / 100%, hairline above | same as B |
| Section label (caps) | 13 / 800 / +8% / 16 / 66% | 13 / 750 / +10% / 16 / 62%, 1 pt hairline above, 11 pt gap | same as B |
| List row | 21 / 520 / -0.5% / 28 / 100% | 22 / 560 / -0.5% / 28 / 100% | same as B |
| Row detail and notes (scheme, times, week's lines) | 18 / 430 / 0 / 24 / 66% | 17 / 420 / 0 / 22 / 62%; right-hand values +140 weight | same as B |
| Context line | 21 / 480 / 0 / 28, context colour | 19 / 500 / 0 / 26, context colour, its number 27 / 700 | same as B |
| Tess's line | 19 / 500 / 0 / 25, cobalt | 20 / 500 / 0 / 25, cobalt | same as B |
| Numerals (week figures, weights, day counts) | 21 / 640 and 17 / 650 | 30 / 680 and 23 / 700, tracking -2%, hero figure 92 / 700 beside a 40 pt word | same as B |
| Key word of a title | +90 weight | +90 weight | +90 weight and the area colour at 72% |

Step ratios, title to row to detail: A 44 / 21 / 18 (2.1, 1.17); B 52 / 22 / 17 (2.4, 1.29), and the detail also drops 4 points of ink, so three levels read at a glance.

**The colour rule.**
- **A:** none. Ink hierarchy only, so the weight change is judged alone.
- **B:** none, but each section has a hairline above its label (ink 15%) and the numerals do the work of emphasis.
- **C:** the area's colour (Training `#C23A22`, Kitchen `#12936A`, Review `#5A3DAF`, Obsidian partners `#FF7D62`, `#52D3A3`, `#B8A3FF`) mixed 72% with ink goes on caps labels, the title's key word, the lead numeral and the section hairline at 34%; the page ground leans 2.5% toward the area (3% in Obsidian). Ink for rows and notes, context line unchanged, Tess still cobalt. A page takes the colour of its area; Home takes the colour of what leads (a workout in the hero leans vermilion, a run of tasks stays neutral, as 72 ruled). No coloured dots, no fills, nothing behind text.

## The four screens, what each shows
- **Home:** hero "Push A, 6 pm" with Push A leading, START PUSH A with its ink line, Next as a section word and three rows (a wrapped one, then times as values).
- **Notes (81):** Title, the count as the numeral in the context line, one line per note, times as values, the Private note row at the detail ink. The smallest steps on the board.
- **A routine (Push A):** Title with Push leading, DAYS and EXERCISES with rules, the weight as the numeral on the right and the scheme under each name.
- **Review's week:** the figure "3" as the hook beside "sessions", TRAINING, TASKS DONE, COOK, COOKED with their week figures, THE WEEK'S LINES.

## Recommendation: C
C answers all three asks: the steps are bigger, the type is heavier, and colour is present only on the small, structural things (labels, rules, one word, the ground), so a page reads as its area without a single coloured fill or dot. B is the right scale; A alone leaves the steps too close (18 against 21), so it reads like the current design in bold. C's colour is also the cheapest to take back: it is three tokens (`labmix`, `keymix`, `tint`) that go to zero and leave B. One thing to judge on his phone: the key word at 72% is the loudest colour on the board (Push A on Home); if it is too forward, the same token drops to 55% and the sheet-72 rest (ink at 50%) still applies once a thing is done. Obsidian is drawn for C on all four screens.

## Tokens in `DesignSystem` (Theme) that would change (Builder A and B; not built)
- `Theme.Type`: new sizes and weights for hero, title, sectionWord, label, row, detail, context, tess and a `numeral` role (the variable weight axis, not named weights, since 520 and 560 are used); the label gets tracking +10% and a hairline `SectionRule`.
- `Theme.Ink`: `inkSecondary` 66% to 62% for detail, a separate `inkRowDetail`.
- `Theme.Colour`: `areaLean(area)` = 72% mix with ink, used for label, key word, numeral and rule; `groundTint(area)` 2.5% (3% in Obsidian); both are no-ops in A and B so the choice is one switch (`ThemeConcept.typeRound`).
- Title key word: the existing title progress effect (72) already carries the weight and colour per stage; this only sets its resting weight (650) and the key word's +90.
- Context line size and the numeral inside it; Tess's line size and weight.

## Never
A serif, italics, a size under 16 for reading text, a coloured dot, a coloured fill or card behind text, colour on Tess's cobalt, area colour on rows or notes, a hairline on a one-section page.

## Open questions for Kaushik
1. Is the key word at 72% too forward at rest (colour should arrive through motion and rest low)? The alternative is colour only on labels and the ground, with the key word at ink until a thing is in progress.
2. B's detail at 17 and A's at 18 stay above the 16 floor; he may want 18 in B too.
3. Home's ground tint for a hero that is a task: neutral (drawn) or Today's own tone.
