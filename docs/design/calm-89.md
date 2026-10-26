# 89. Calm: one column, one lead, a budget per screen

**Kaushik's principle, in one line:** fewer things per screen, one column, and two-column data goes when there are many rows.

His words (Oct 17, 2:32 AM PT): "All of them feel still a bit cluttered to me text funny or size it style or layout wise. Do we have have to improve. And maybe two column data is a lot especially when there's a bunch of rows." He had asked in sheet 86 for bolder, more editorial type (A, B, C, still unpicked).

Board `mockups/calm-89.png` (six screens, before = sheet 86 C, after, then Obsidian or the same screen at another length, then what was cut and where it went), recording `recordings/calm-89.mp4` (18 s: Groceries, 30 rows, folds from two columns to one, the lead row moves down the run, the amounts turn up on the side), study `studies/calm-89.html` (`?play` records). This is a layout and density system, so it works with A, B or C. **The mockups use C's tokens**; only the note size changes (below). Nothing in the app changes.

## The system in five moves
1. **One column.** No right-hand value column on any list of 4 or more rows (and none on 3). A row is one line of words.
2. **The lead row.** One row per screen is the one that matters now (current, next or changed). It steps up to 28 / 650, carries a 3 pt **edge marker** in the gutter (the area colour, 72%) and is the only row with a **detail line** under it. Every other row shows its name alone.
3. **Values go three places:** run in after the words when the value is the point, under the lead, or one swipe or tap away (the sheet 75 side page, or the row's own page).
4. **Long runs read by whitespace, not columns:** a group gap of 28 pt where the data has groups (aisles, workouts), **breath** (+14 pt before every 4th row from the 5th) in a run of 8 or more, a section word only where the group needs a name, and the lead as the eye's anchor. Rows already done dim to 46%.
5. **A budget per screen** (below). Whatever breaks it is cut, and each redrawn screen says where it went.

## How long runs read (tested at 3, 12 and 30)
- **3 rows** (Home's Next, a new exercise's 3 sets, 3 notes): no breath, no section word, values may run in with a comma ("Call mom, tomorrow"); the lead still gets its detail.
- **12 rows** (an exercise's 12 sets, two workouts of 6): the value *is* the row ("100 × 5"), two section words name the workouts, the best set leads ("120 × 3", detail "A best."); the second workout has the one hairline above its word.
- **30 rows** (Groceries): aisles are 28 pt of whitespace with no word, breath quarters the 10-row Produce run, the lead is the next thing in the shop walk (detail "Produce, 6"), checked rows dim and the lead steps down the run. The amounts live in the side FOR WHAT, run in under each cook ("Limes, 4").
- **20 rows** (Notes): the writing line is the lead; this week (7) has no word; EARLIER (13) has one word, one hairline and breath. **A week of 7 days** (Review): 7 rows; the screen's one numeral ("3 sessions") is its lead, so today gets only the edge marker and its detail line ("Push A, 6 pm").
- **A glance** keeps sheet 75's rule: a count first, then two named, three named, "and N more" from 4 ("Bananas, limes and 28 more").

## RULES (a builder can check these)
### Row anatomy
| Part | Measure |
|---|---|
| Side margins | 22 pt; edge marker at x 9 to 12 (3 pt wide, radius 1.5, the lead's full height, never a dot) |
| Rest row | 22 / 560 / -0.5% / line 28, padding 8 above and below = **44 pt pitch** (the tap target) |
| Lead row | 28 / 650 / -1.2% / line 34; with a detail line it is 8 + 34 + 24 + 8 = **74 pt** |
| Detail line (the one note level) | 18 / 430 / line 24 / ink 62%; never wraps, one line, 2 to 5 words |
| One line | a name never wraps; past 321 pt it fades over its last 28 pt (no "…"); a tap opens it whole |
| Weight | one weight per row; a mention or key word never goes heavier inside a row |
| Sizes | one size per row, except a leading numeral ("3 sessions") |
| States | done 46% ink, upcoming 100% (62% on a week's future days), private 62%; colour never carries meaning |

### When a value may sit in a row
A value joins the words only if **(a)** it is the point (the row is its value: "100 × 5", "Squat, 225"), always run in with a comma or a space, same weight, same size; or **(b)** the list has 3 rows or fewer and the value is 12 characters or fewer, run in after a comma. Otherwise it is **(c)** the lead's detail line, or **(d)** on the side page or one tap in. Never right-aligned, never a different weight, never a second column.

### Section budget (per screen; the checker counts what is drawn)
| Thing | Allowed |
|---|---|
| Title | 1 (52, or Hero 60 on Home) |
| Context line | 1, 32 characters or fewer, 6 words or fewer, note level in the context colour |
| Section words | at most 2 (13 / 750 / +10%, caps, area colour), **the side word counts as one**; no section word on a list of one group |
| Emphasised thing | 1: a lead row, or one numeral at 92 (Review); never both a numeral and a bigger row |
| Hairline | at most 1 (1 pt, area colour 34%), only above the **second** section word, never on a one-section page |
| Type levels | 3: title, row (rest and lead), note (detail, context, side words) |
| Caps | section words, the back word and the side word only; never a row, a detail or a label on a value |
| Copy | one plain line per thing; a row detail never wraps to a third line |

### Theme token notes (Builder A and B, not built)
- `Theme.Type`: add `lead` (28 / 650 / -1.2% / 34), keep `row` at 22 / 560, `note` becomes **18 / 430 / 24 / 62%** (sheet 86's 17 goes to 18, answering its question 2), the detail "+140 weight right-hand value" role and the 30 pt numeral on rows are removed; `numeral` stays for Review's one figure only.
- `Theme.Layout`: `rowPitch` 44, `groupGap` 28, `breath` 14 every 4th from the 5th (runs of 8+), `edgeMarker` 3 pt at x 9, `fadeEdge` 28 pt, `maxRowLines` 1, `sectionBudget` 2, `ruleBudget` 1.
- Components: `RunList(rows:, lead:)` and `LeadRow(title:, detail:)`; a `RunRow` has no trailing-value slot, so a right column cannot be built; a DEBUG assert counts section words and rules per screen.
- `ThemeConcept.typeRound` (86) is unchanged; calm is a layout switch (`ThemeConcept.calm`) that works with A, B or C.

## The six screens: what was cut and where it went
| Screen | Cut | Went to |
|---|---|---|
| Home | the day line; the 34 pt "Next"; the wrapped long title; the right column of times | gone; a 13 pt word; fade and a tap; run-in (3 rows) and the lead's detail |
| Notes, 20 | every time; the heavier mention; "Write something. @ links a thing."; the rule under the writing line | the tap and BY THING; BY THING; the line is the lead and the hint shows on touch; one rule above EARLIER |
| A routine, 8 | 8 scheme lines; 8 weights at 30 pt; DAYS and EXERCISES words and rules; "about 55 min" | a tap and the lead's own line; LAST TIMES (sheet 71); the context line ("Mon and Thu"); the side page |
| Review's week | the day-letter strip and 4 bands; THE WEEK'S LINES; "3 SO FAR", "18", "2" | 7 day rows; a tap on a day and Tess's band; the side page THE DAYS |
| Groceries, 30 | 6 aisle words at 34 pt; 30 amounts; the "for tacos" lines | whitespace and the lead's detail; the side FOR WHAT, run in under each cook |
| Set history, 12 | 12 "Set n" labels; two numerals and labels; HISTORY, REP MAXES, MUSCLES words; the long context line | the row is the set; REP MAXES and the best set as the lead; the side word; "12 sets, in kg" |

Obsidian is drawn for Home, a routine and Review's week (same tokens, area partners `#FF7D62`, `#B8A3FF`, ink 245,242,236).

## Accessibility
One element per row ("Bench press, 4 sets of 8, 82.5 kg, next"); a dimmed row says "done". The lead is announced as "next". Dynamic Type: rows wrap in full at Accessibility sizes (the one-line rule is for the standard range) and the detail drops under its row. Reduce Motion: the lead steps with a 150 ms crossfade instead of the size spring.

## Never
A right-hand value column on 4+ rows, two weights or two sizes in one row (but the leading numeral), a row detail on any row but the lead, a caps label on a value, an "…", a card, pill or dot for the marker, a second hairline, a third type level, a section word on a one-group list, a mention heavier than its row.

## Open questions for Kaushik (each answerable with a picture)
1. **Is the lead row too loud?** Board row Notes shows it at 28 / 650; the alternative is the same size as the rest with only the edge marker and the detail line (as Review's today row is drawn). One picture of Notes, both ways.
2. **Do times belong back on Notes rows?** Drawn with none (the two groups say it); the alternative is a run-in time on the lead only. Pick from the Notes after and a Notes with "Sleep is training too, yesterday" on the lead.
3. **Breath or no breath?** Quartering a long run (+14 pt every 4th row) against a plain even run. One picture of Groceries, both ways.
