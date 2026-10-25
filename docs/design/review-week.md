# Review: the week on one page (Design item 46)

**Kaushik's principle, in one line:** Review should show him his whole week at a glance, more than a sentence and seven dabs, and still be one page with no cards.

From his first review of the build (16 Oct, 11:58 PM PT): Review shows too little. This sheet redraws the REVIEW tab as the week on one page: training, tasks done, habits, body weight, money, cooking and the day log's best lines, with a tap on any day to read that day. It replaces the page in `review-week-line.md` (the week line's clause rules and the rest-dab marks stand; they move into the bands). The hero and its wording keep `review-sentence.md`.
- Board: `mockups/review-week.png` (source `studies/review-week.html`): Porcelain, Obsidian, and the page reading Tuesday.
- Recording: `recordings/review-week.mp4` (8s). The week arrives band by band; tap Tuesday and the page reads that day; tap away and the week comes back.

## The page
| y | Element |
|---|---|
| 78 | The tabs, REVIEW under the ink line |
| 138 | Context line in `context`: "the week so far" |
| 172 | Title 44: the session count, as `review-sentence.md` words it ("Three sessions", "All six sessions in", "A quiet week so far"). One line; it never carries a second count |
| 240 | **The day letters**, M to S at 49.4pt pitch from x 22, Label 16. Today in ink, past days `inkSecondary`, days ahead `inkTertiary` |
| 268 on | **The bands**, one per thing. Each is a Label 16 `inkSecondary` at the left with its week figure at the right in ink (Label 16), and under it one mark per day in the day's column. Bands and their heights: |
| 268 | TRAINING, 3 OF 6: the `rest-dab.md` marks (sage dab at the rest tint, the dry rest stroke, the faint ring for an open day, nothing ahead). 58pt |
| 326 | TASKS DONE, 14: a numeral per day, Label 16/600 tabular, "·" at 38% for a day with none. 54pt |
| 380 | One band per habit (at most 3): COOK · 2 OF 4, READ · 3 OF 5. Under each the painted thread from `review-week-line.md` (3pt, the class pigment at the rest tint, consecutive days joined). 48pt each |
| 476 | WEIGHT, 78.2 KG: one 3pt stroke in `now` at the rest tint through the weigh-ins, a 3pt point at each, the first and last values beside their points at 16. No band when there's no weigh-in this week. 70pt |
| 546 | MONEY, $161: a numeral per day with the currency sign, "·" for a day with no spend. 54pt |
| 600 | COOKED, 2: a cadmium dab on each day something was cooked. 54pt |
| 660 | **THE WEEK'S LINES**: the day log's three best lines, each "Tue  Bench 85 × 8, a best." at 16, the day in 600 `inkSecondary`. Core picks them: a best, a first, a record count, in that order |
| 736 to 820 | Tess's band, as everywhere. Her line here is forward-looking as before, and only when she has one |

- **Column, not table:** there are no rules, no hairlines and no boxes. The seven columns align by the day letters alone.
- **The week figure at the right is the clause** from `review-week-line.md` ("Cook 2 of 4"), split into its label and its number. The week line as a sentence goes; the bands say it.
- **Bands come and go with the data.** No weigh-ins, no WEIGHT band; no spend, no MONEY band; no habit, no habit band. Bands below close up (320ms, house curve). The first week shows TRAINING and TASKS DONE at least, with the rest arriving as he uses them.
- **Marks rest at the rest tint** (`no-dots.md`): 45% on light looks, 55% on dark. Nothing on this page is wet at rest. The one colour at rest is the context line.
- **Training's tap:** a dab opens that session; the rest stroke and ring do nothing.

## Tap a day
- **Tap a day letter or anywhere in its column** and the page reads that day: the other six columns recede to 30% (300ms), the context line becomes the day's name, the hero becomes the day's own line ("Bench best, 5 done"; Core: the day's best fact and its task count), and THE WEEK'S LINES becomes the day's name over that day's log lines (time, then the line, at most 4). Tess: "Tuesday was the bench best." The swap is the house blur-fade (180ms out, 260ms in), lines landing 50ms apart.
- Tap anywhere else, or the same day again, and the week comes back the same way.
- The columns don't move: this is a read of the same page, not a new page. The Day log page (`day-log-page.md`) stays one tap further, from the lines.
- Haptic: `.selection` on the tap, nothing on the return.

## Arrival
Each band lands 22ms after the one above (at most 700ms in all), rising 8pt on the settle spring; the weight stroke draws in left to right over 500ms. Reduce Motion: the page is simply there.

## Accessibility
- Each band is one element: "Training, 3 of 6 sessions. Monday trained, Tuesday trained, Wednesday rest, Thursday trained."
- Each day column is a custom action, "Read Tuesday".

## For Builder B
- `ReviewPage` becomes the bands over a seven-column layout (`DayDabs` generalises to a `WeekBand` taking a mark per day); `WeekDabs` and `ReviewLine` in `ReviewView.swift` retire with it.
- Core provides per-day counts (tasks, spend), the weigh-ins, the cooked days, the habit threads, and the three best lines plus a day's lines (`DayStory.lines` already exists for a day).

## Owners
- **Builder B:** the page, the tap, the arrival.
- **Core:** the week's per-day figures and the best lines.

## Addendum, Oct 16: Research 120's two lines
- **COOKED's line says cooks:** "cooked 3 times", because the band's dabs are the days he cooked and the line says what the marks show. Recipes are the Kitchen's count.
- **The week figure mid-week is "3 SO FAR";** "3 OF 6" only once the week is whole (Sunday, or the next 04:00). Never "to go": owed reads as a shortfall by another name.

## Addendum, Oct 16: receipts and bests (Design 62, `copy-pass.md`)
Context "Oct 12 to 18" (not "the week so far"); heroes in digits ("3 sessions", "All 6 sessions in"); no dot on an empty day; "COOK, 2 OF 4"; the pick rule reads "a best, a first, the week's top count"; VoiceOver mid-week "Training, 3 so far". The full table is in `copy-pass.md`; where a clip still says the old words, the sheet wins.
