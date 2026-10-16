# Area index: each area's live line, by day shape (Research BA, Design 73)

Design sheet 73 (A, his pick at 2:06 PM PT Oct 16) puts all areas on one glass sheet, each word with one live line
at Body 17, "from the same grammar as Home's context line, under the caps". This file gives that line for REVIEW,
TODAY, TRAINING and KITCHEN across 15 day shapes (60 cells, plus 3 variant rows and 1 fifth-area row), names the
source on master for each, and says whether the data exists today. All values are made up. Read against
`origin/master` on Oct 16.

## 1. Rules every line follows

| Rule | Where it comes from |
|---|---|
| The **context cap** applies: at most 6 words and 32 characters, no stop. A line that fails is refused, never cut | `HomeLines.contextWords = 6, contextCharacters = 32` and `fitsContext(_:)`, `HomeLines.swift:183, 187-191` |
| The detail cap (14 words, 80 characters, one sentence with its stop) does **not** apply to the line. It applies to the VoiceOver row "Training, Push Day A is on", which must pass `fitsDetail` without the stop | `HomeLines.swift:184, 194-199`; sheet 73 VoiceOver |
| Thing first: the routine, recipe, list, task or week leads. Quiet lines ("Nothing cooking tonight", "All quiet") are the only exception, as Design drew them | sheet 73 live lines; decisions 11:50 AM |
| Never a private title. A private task reads "Private task", a private note never appears (notes are not an area). A medicine reminder keeps "Medicine" | decisions 1:06 PM, 1:48 PM, 12:30 PM (medicine); `SecretWords.title`, `SecretWords.swift:8` |
| No money and no body values. None of the four areas owns money or body facts, so no line carries an amount, a body weight or a lift weight. kg appears only on the pages one tap down | decisions 1:23 PM (Siri never says the weight), 12:02 PM, 1:00 PM ("weight down 0.4 kg" stays on the body page) |
| "best" for lifts, never "record" or "PR" | decisions "Best everywhere"; `HomeLines.swift:244` |
| Clock: 12-hour, lowercase, with a space: "8:30 pm", "7 pm" | `HouseTime.clock`, `HouseTime.swift:7`; decisions 11:50 AM |
| Trip days: clocks print in the phone's current zone; a thing files under the day of the zone it happened in | decisions 1:00 PM, trip-week.md §1 |
| Plain US English, digits in the line (the Review hero keeps its words; the index line is not the hero) | sheet 73 live lines |

**Fallback when a line fails the cap** (proposal, Q3): full line, then the Home hero alone, then the object's title,
then the area's quiet line. Never an ellipsis.

## 2. Where each line comes from

Tess's line, Home and the index must never disagree. Each area reuses one existing source and adds no new read
(sheet 73: "no new reads").

| Area | Source on master | Reuses Home? |
|---|---|---|
| TODAY | Now's top pick, `NowPage.swift:23` (`rank(now:).first`) and the heroes at `NowPage.swift:43-74`, worded by `HomeLine.widgetWords`, `HomeLines.swift:123-137`, with a bare "today" context dropped (the index row already says Today). Empty: `HomeLine.quiet`, `HomeLines.swift:157`, without its stop | **Yes, the Home line source.** Same `HomeLine` Tess's band, the widget and the Lock Screen use |
| TRAINING | The page's plan state, `TrainingPage.swift:229-244` (`markState`), `tomorrowLine` `:249-260`, done and target sets `:239-240`; rest day and the next routine from `NowPicker.restDay`, pick text `NowRanker.swift:124-128` | Partly: a scheduled or paused session reuses `HomeLines.hero`, `HomeLines.swift:282-307` |
| KITCHEN | `HomeFacts.fact(plannedCook:recipe:)` `HomeLines.swift:552-556` with `cookWhen` `:267-278` and `toBuy` `:400-406`; a running cook or shop, `fact(process:)` `:507-517`; list count `Shopping.swift:8` (`shoppingOrder`), per recipe `Groceries.swift:59` | **Yes** for cook and shop: the line is `HomeLines.text` without its stop, or the hero. The Kitchen page itself has no live line today (`HomeSpatialView.swift:357-363`, a fixed sentence) |
| REVIEW | `ReviewWeek` session count and plan rhythm, `ReviewWeek.swift:32, 45`; first-week words `ReviewPage.swift:34-47`; the plain count `sessionLine`, `ReviewPage.swift:50-52` | Same numbers as the Review hero and its VoiceOver `sessionLine`; reordered thing first |

Data marks: **Y** exists on master with these words or a direct reorder; **D** data exists, the words are new;
**N** not built yet (named in the notes).

## 3. The lines

Plan in all shapes: 6 sessions a week, Sunday rest, routines Push Day A, Pull A and Legs B. Week runs Monday to
Sunday, his day turns at 4 am.

### D01 Morning (Tue Oct 20, 8:10 am)
Push Day A planned, no time. Tacos planned at 7 pm, 6 to buy. 3 sessions done.

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `This week, 3 of 6 sessions` | ReviewWeek count | Y |
| TODAY | `Push Day A` | widgetWords, "today" dropped | Y |
| TRAINING | `Push Day A is on` | markState `.routine` | D |
| KITCHEN | `Tacos at 7 pm` | fallback: hero alone (Q12) | Y |

### D02 Mid-workout (Tue Oct 20, 6:40 pm, Push Day A live)
Bench, set 3. 7 of 20 sets logged, 13 left. No cook tonight.

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `This week, 4 of 6 sessions` | ReviewWeek count, a session with a logged set counts (Q2) | N: counts done only (`ReviewWeek.swift:45`) |
| TODAY | `Push Day A, bench set 3` | widgetWords (context "now" drops) | Y |
| TRAINING | `Push Day A, 13 sets left` | markState `.running`, total minus done | D: counted in the view only |
| KITCHEN | `Nothing cooking tonight` | quiet line | D |

### D03 Cook running (Wed Oct 21, 7:20 pm)
Chili, step 3 of 7. Pull A done at 6:05 pm with a row best.

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `This week, 4 of 6 sessions` | ReviewWeek count | Y |
| TODAY | `Chili, step 3` | widgetWords of the cook fact | N: a running cook doesn't take Now (`NowPage.swift:43-45`, SH5) |
| TRAINING | `Legs B tomorrow` | tomorrowLine | Y |
| KITCHEN | `Chili, step 3 of 7` | hero plus the SO FAR count | D |

### D04 Rest day (Sun Oct 25, 10:30 am)
Rest planned. Next is Push Day A. Groceries holds 4 rows, no cook planned.

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `This week, 6 of 6 sessions` | ReviewWeek count | Y |
| TODAY | `Rest day` | widgetWords (rest) | Y |
| TRAINING | `Rest day, Push Day A next` | NowPicker.restDay and its `next` | D |
| KITCHEN | `Groceries, 4 to buy` | shoppingOrder count | D |

### D05 Trip day (Mon Oct 26, 8:15 am in New York, phone on Eastern time)
Flew in last night. "Client lunch" at 12:30 pm local. Last week's story still stands (until Tue 4 am).

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `Last week, 5 of 6 sessions` | ReviewWeek, previous week until Tue 4 am | N: the Monday carry-over (decisions 1:00 PM) isn't on master |
| TODAY | `Client lunch, 12:30 pm` | widgetWords (timed task), clock in the phone's zone | Y |
| TRAINING | `Push Day A is on` | markState `.routine` | D |
| KITCHEN | `Nothing cooking today` | quiet line, morning word | D |

### D06 Late night (Tue Oct 20, 11:20 pm, quiet hours, day closed)
Push Day A done at 7:05 pm with a bench best. Tacos cooked at 8:40 pm. Pull A first tomorrow.

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `This week, 4 of 6 sessions` | ReviewWeek count | Y |
| TODAY | `Pull A tomorrow, first` | widgetWords (`tomorrow, first`, `HomeLines.swift:342`) | Y |
| TRAINING | `Pull A tomorrow` | tomorrowLine | Y |
| KITCHEN | `Tacos done` | widgetWords of the done cook (clock drops) | Y |

### D07 Empty and new (day one, Fri Oct 23, 9:00 am, no plan, no history)

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `Your first week starts today` | headline, first use today | Y |
| TODAY | `All quiet` | HomeLine.quiet without its stop | Y |
| TRAINING | `No routine yet` | markState with no plan | D |
| KITCHEN | `Nothing cooking today` | quiet line | D |
| (a fifth area, e.g. HABITS) | `Nothing here yet` | the area's quiet line (Q7) | N: no fifth row |

### D08 Private-only day (Sat Oct 24, 10:00 am)
Only two private notes and one private task at 9 pm. Week already full.

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `This week, 6 of 6 sessions` | ReviewWeek count (notes never counted) | Y |
| TODAY | `Private task, 9 pm` | widgetWords, title replaced | N: no "Private task" title in Sources (decisions 1:06 PM) |
| TRAINING | `Rest day, Push Day A next` | NowPicker.restDay | D |
| KITCHEN | `Nothing cooking today` | quiet line | D |

D08b (the task is a medicine reminder): TODAY `Medicine, 9 pm`. The private notes appear nowhere on the index.

### D09 Shutdown evening (Thu Oct 22, 9:15 pm)
Legs B done at 6 pm. 3 tasks moving to tomorrow. 4 rows on Groceries.

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `This week, 4 of 6 sessions` | ReviewWeek count | Y |
| TODAY | `Shutdown, 3 moving to tomorrow` | Shutdown hero and its label | N: Shutdown not built (SH1). Until then `Pull A tomorrow, first` (Y) |
| TRAINING | `Pull A tomorrow` | tomorrowLine | Y |
| KITCHEN | `Groceries, 4 to buy` | shoppingOrder count | D |

### D10 An UNDO open (Tue Oct 20, 7:06 pm, Finish on Push Day A 4 s ago, 10 s window)
Push Day A done with a bench best. Tacos at 8 pm, 6 to buy.

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `This week, 4 of 6 sessions` | ReviewWeek count; unchanged by the UNDO, the sets stay | Y |
| TODAY | `Push Day A done, bench best` | widgetWords, comma form (Q1) | D: code says "Push Day A done. Bench best" |
| TRAINING | `Pull A tomorrow` | tomorrowLine | Y |
| KITCHEN | `Tacos at 8 pm` | fallback: hero alone (Q12) | Y |

After UNDO: TODAY `Push Day A, all sets in`, TRAINING `Push Day A, all sets in`. D10b (a grocery add, "Milk, on
Groceries." with 4 s UNDO, no cook): KITCHEN `Groceries, 5 to buy`, then `Groceries, 4 to buy` if taken back.

### D11 Nov 1 fall-back night (1:40 am PST, the second 1:40; still his Saturday Oct 31)

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `This week, 5 of 6 sessions` | ReviewWeek, by calendar day and the 4 am day | Y |
| TODAY | `Pull A tomorrow, first` | widgetWords | Y |
| TRAINING | `Rest day tomorrow` | tomorrowLine (Sunday rest) | Y |
| KITCHEN | `Nothing cooking tonight` | quiet line, late word | D |

D11b (a task he typed for 1:30 am, in the repeated hour): TODAY `Trash out, 1:30 am`. It must land on Saturday
night, not a day late (DS8, Core 0ag): N until 0ag merges.

### D12 Weekend morning (Sat Oct 24, 8:30 am)
Legs B scheduled at 9 am. Pancakes planned at 10 am, nothing to buy.

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `This week, 5 of 6 sessions` | ReviewWeek count | Y |
| TODAY | `Legs B at 9 am` | widgetWords (scheduled), "today" dropped | Y |
| TRAINING | `Legs B at 9 am` | HomeLines.hero (scheduled) | Y |
| KITCHEN | `Pancakes at 10 am` | fallback: hero alone | Y |

The full Kitchen line "Pancakes at 10 am, nothing to buy" is 6 words and 33 characters: refused, so the hero stands.

### D13 Paused workout (Wed Oct 21, 8:50 pm)
Push Day A paused at incline 25 min ago, 12 of 20 sets in.

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `This week, 4 of 6 sessions` | a paused session with a set counts (decisions 1:00 PM) | N: counts done only |
| TODAY | `Push Day A, paused at incline` | widgetWords (paused context drops) | Y |
| TRAINING | `Push Day A, 8 sets left` | markState `.running` (paused session) | D |
| KITCHEN | `Nothing cooking tonight` | quiet line | D |

### D14 At the store (Sat Oct 24, 11:00 am, shop running)
6 rows left. Legs B at 5 pm.

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `This week, 5 of 6 sessions` | ReviewWeek count | Y |
| TODAY | `Groceries, 6 left` | widgetWords (shop hero) | Y |
| TRAINING | `Legs B at 5 pm` | HomeLines.hero (scheduled) | Y |
| KITCHEN | `Groceries, 6 left` | HomeLines.hero (shop) | Y |

### D15 Monday morning, no plan rhythm (Mon Oct 19, 7:30 am, plan has no sessions-a-week)
Last week had 4 sessions. Pull A is next. 9 rows on Groceries.

| Area | Line | Source | Data |
|---|---|---|---|
| REVIEW | `Last week, 4 sessions` | ReviewWeek, perWeek nil (`sessionLine` form) | N: Monday carry-over |
| TODAY | `Pull A` | widgetWords, "today" dropped | Y |
| TRAINING | `Pull A is on` | markState `.routine` | D |
| KITCHEN | `Groceries, 9 to buy` | shoppingOrder count | D |

## 4. Cap check

66 displayed lines (60 grid cells plus the variant rows), all within 6 words and 32 characters, none with a trailing stop. Longest: `Shutdown, 3 moving to
tomorrow` (30). The VoiceOver row "Training, Push Day A, 13 sets left" is 7 words and 34 characters, within the
detail cap. Refused on purpose: the full D12 Kitchen line (33 characters).

Two of Design 73's own examples break the word cap: "Tacos at 7 pm, 6 to buy" and "Push Day A, 7 of 20 sets"
are 7 words each (the comma counts no word, "pm," and "A," do). So a planned cook with a time falls back to its hero
(D01, D10, Q12), and a live session says what is left ("Push Day A, 13 sets left"). The same planned-cook row on Home,
`HomeLines.text` "Tacos at 7 pm, 6 to buy.", is 7 words against `rowWords = 6` (`HomeLines.swift:182, 225`).

## 5. Data not on master yet

1. Review counting a running or paused session that has a logged set (`ReviewWeek.swift:45` counts done only): D02, D13.
2. Review's "Last week" until Tue 4 am: D05, D15.
3. A running cook taking Now: D03 (SH5).
4. Shutdown hero: D09.
5. "Private task" title: D08.
6. DS8, the repeated-hour task: D11b (Core 0ag).
7. Comma form for a done workout with a best: D10.
8. Kitchen has no live line at all; every KITCHEN cell is new wiring from existing Home facts.
9. A fifth area row: D07.
10. Design 73's own example lines over the word cap (section 4).

## 6. Swift Testing names for Builder A

Parameterized over `AreaIndexArea.allCases` x `DayShape.allCases` (D01 to D15, fixtures built with `-demoTime` clocks
and the made-up values above):

- `@Test(arguments: AreaIndexArea.allCases, DayShape.allCases) func liveLineMatchesFixture(area:shape:)`
- `@Test(arguments: AreaIndexArea.allCases, DayShape.allCases) func liveLineFitsContextCap(area:shape:)` (uses `HomeLines.fitsContext`)
- `@Test(arguments: AreaIndexArea.allCases, DayShape.allCases) func voiceOverRowFitsDetailCap(area:shape:)`
- `@Test(arguments: AreaIndexArea.allCases, DayShape.allCases) func liveLineHasNoPrivateText(area:shape:)` (seeds a secret-word task and note, checks the title never appears)
- `@Test(arguments: AreaIndexArea.allCases, DayShape.allCases) func liveLineHasNoMoneyOrBodyValue(area:shape:)` (no currency, no kg, no body weight)
- `@Test(arguments: AreaIndexArea.allCases, DayShape.allCases) func liveLineSaysBestNeverRecord(area:shape:)`
- `@Test(arguments: AreaIndexArea.allCases, DayShape.allCases) func liveLineClockIsTwelveHourLowercase(area:shape:)`
- `@Test(arguments: DayShape.allCases) func todayLineEqualsHomeWidgetWords(shape:)` (Tess, Home and the index agree)
- `@Test(arguments: DayShape.allCases) func kitchenLineEqualsHomeCookOrShopLine(shape:)`
- `@Test(arguments: DayShape.allCases) func reviewLineUsesReviewWeekCount(shape:)`
- `@Test func overCapLineFallsBackToHero()` (D12)
- `@Test func undoRevertsTodayAndTrainingLines()` (D10)
- `@Test func tripDayClockUsesPhoneZone()` (D05)
- `@Test func fallBackNightKeepsSaturday()` (D11, D11b)

## 7. Open questions for Product (recommended answer first)

1. **Done with a best.** `widgetWords` gives "Push Day A done. Bench best", a stop inside a context-capped line.
   Recommend one shared comma form, "Push Day A done, bench best", for the index and the widget both, so they still
   agree (the comment at `HomeLines.swift:116` already writes it that way).
2. **When a live session counts on Review.** Recommend: once a set is logged, same as the decided paused rule, so the
   count doesn't jump at Finish or back on UNDO.
3. **Over-cap fallback.** Recommend full line, then hero, then title, then the quiet line; never cut.
4. **"is on" vs "today".** Recommend "is on" on TRAINING only (Design's words) and the bare hero on TODAY.
5. **Quiet hours.** Recommend the same lines after 11 pm and keep the `.selection` haptic, since he is touching it
   (a stroke while she sleeps still answers him, 12:13 PM).
6. **Private task wording.** Recommend "Private task" for every walled task, "Medicine" for a medicine reminder (as
   decided), and private notes never on the index.
7. **A new empty area.** Recommend "Nothing here yet" until it has a source of its own.
8. **No plan.** Recommend "No routine yet" on TRAINING.
9. **UNDO while the index is open.** Recommend the index is not a claim: it doesn't close or pause the window, and the
   lines update live if he taps UNDO.
10. **Lift weights.** Recommend no kg on the index at all, even "ready for 82.5 kg"; weights stay one tap down.
11. **Monday carry-over.** Recommend the index says "Last week" until Tue 4 am, to agree with Review.
12. **A timed cook with a count.** "Tacos at 7 pm, 6 to buy" is 7 words. Recommend the hero alone on the index
    ("Tacos at 7 pm") with the count one tap down; a cook with no time keeps it ("Tacos tonight, 6 to buy", 5 words).
    The Home row line has the same 7-word overflow, so Core should check `rowWords` there too.
