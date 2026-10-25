# Habits on the new grammar (Design item 59)

**Kaushik's principle, in one line:** one plain line per thing, the detail one tap down, nothing cut and nothing decorated; a habit is a name and a count, and the week's marks under it are the data.

Redraws `body-weight-and-habits.md` §2 and §2a (which keep the copy, the engine and the never-list) under sheet 41's one-line grammar, `no-dots.md` (rule 2: marks that are the data stay, land wet and dry), the one-base rule and `back-word.md`. Research's `m3-lines.md` H1 to H12 and A1 to A20 stand as the copy; nothing here changes a line of Tess's.

- Board: `mockups/habits-grammar.png` (source `studies/habits-grammar.html`): the page, a check-in, the week met, a habit one tap down (Obsidian), a rule count arriving (Obsidian), the empty page.
- Recording: `recordings/habits-grammar.mp4` (12 s), Porcelain: tap Thursday's stroke on Read (it lands wet and dries, the count rolls, Tess's line with UNDO), tap Train, cycle COUNTS BY HAND to COUNTS WHEN A WORKOUT FINISHES (Tuesday's Push A paints in, the count rolls, "Train now counts workouts." with UNDO), ‹ HABITS back with Train's Tuesday in the training pigment.

## The page
| y | Element |
|---|---|
| 58 | **‹ REVIEW** (see "Where it opens from") |
| 84 | **Habits** at Title 44 |
| 146 | **The context line** in `context`, Body 21, Research's H2: "Thursday, 3 days to go", "Monday, a new week", "Sunday, the last day". The only resting colour on the page besides the marks |
| 200 | **The writing line** at Field 18 `inkSecondary`: "new habit read 5 a week" (H1). The hairline at 232 inks in while he types, as on Notes. No dab |
| 280 + 112k | **One line per habit**, creation order (§2a): the name at Body 21 ink, left; the count at the right as "**2** of 5", the number 600, always ink (H3, H4: "**6** of 5" past the target, "paused" in a paused week). Nothing under the name: no label word, no history line |
| +40 | **The week's seven strokes**, 40 × 12 at 48 pitch from x 22, Monday to Sunday: a done day is the painted stroke in the habit's class pigment at the rest tint (`now` by hand, `training` for workouts, `health` for cooks); any other day is a dashed ink guide at 14%, today's at 38%. **The only marks on the page.** Missed days are never red, ringed or counted against: they stay a guide |
| +60 | **The day letters**, Label 16/600 at 38% centred under each stroke, today's in ink |
| 736 to 820 | **Tess's band**, fixed, the soul at (323, 759), her line at 270 wide with UNDO under it in `liveInk` |

Four habits fit above the band; more scroll under it. A paused habit: every stroke a guide, the count reads "paused".

## The moments
- **Check in: tap today's stroke.** Paint falls 26 pt into the slot, lands wet at ×1.25 with a 2 pt blur, settles (460 ms, settle spring), then **dries to the rest tint over 2 s**. `.impact(medium, 0.8)`, once. The count rolls like a value word. Tess: "Read, 3 of 5 this week." with a 4 s UNDO (A2). Earlier days this week can be tapped too; a done day tapped clears it, the drop in reverse (A17, 10 s UNDO).
- **The week met.** On the check-in that reaches the target, the done strokes **join into one painted stroke** from Monday to that day (700 ms, left to right), in the class pigment at the rest tint. The count stays ink ("**5** of 5"). Tess: "Read done for the week." (A4). No confetti, no `.success`; the joined stroke is the reward and it resets on Monday.
- **Counted by a rule.** When a workout or a cook finishes, its stroke flies in from the top (700 ms, `cubic-bezier(.5,0,.2,1)`), lands wet in the class pigment and dries. Tess: "Push A counted for Train, 2 of 3." (A8). Tapping a rule stroke: "Push A, Tuesday 6:20 pm" and the zoom to the workout (A14).
- **A new habit** typed on the writing line lands as a new line at the bottom (10 pt rise, 360 ms) with seven guides and "**0** of 5" (H11). Tess: "Read added, 5 times a week." (A1).
- **Her lines never break a count:** "2 of 3" is one unbreakable unit, so a wrapped line ends "…for Train," / "2 of 3." and never leaves "3." alone.

## A habit, one tap down (‹ HABITS)
| y | Element |
|---|---|
| 58 | **‹ HABITS** (new back-word row 26) |
| 84 | **The name** at Title 44 |
| 146 | **The context line**: "Thursday, 1 of 3 this week" (or "paused this week") |
| 200 | **The week's strokes** and letters, the same marks, tappable the same way |
| 276 | **The rule as a label word**: COUNTS BY HAND, COUNTS WHEN A WORKOUT FINISHES, COUNTS WHEN A COOK FINISHES, Label 16/700 `inkSecondary`. A tap cycles it (§2a: value-word swap, `.selection`), Tess says it ("Train now counts workouts.") with a 4 s UNDO, and this week's finished workouts paint in on their days, 120 ms apart, the count rolling with them. Taking it back fades only the days the rule added |
| 316 | **The history line**, Body 21 `inkSecondary`, only when it has something to say (H6, H12): "Met in 1 of the last 3 weeks.", "Met last week." |
| 380 | **PAUSE THIS WEEK** (or RESUME THIS WEEK) as an ink-line word. Tess: "Read paused this week." with UNDO (A10, A11). This replaces the hold on the count: the hold stays as a shortcut on the list for anyone who finds it, but the word is where it lives |
| 440 | **DELETE HABIT** as an ink-line word. Tess: "Read deleted." with a 10 s UNDO, "Read is back." (A13) |

The habit grows out of its line (the page fades 380 ms, the words settle at 84), and ‹ HABITS is the reverse. The strokes keep their place across the two pages, so the week never jumps.

## Where it opens from
Under 41, Home is the day word, the hero, the key and Next; it has no foot line, so the Habits word of `m3-entry-points.md` has no place on it. The page opens from **Review**: a tap on a habit band (`review-week.md`, "READ · 3 OF 5") opens it, and Review's link line carries **HABITS** beside NOTES. The back word is therefore ‹ REVIEW, and `back-word.md` row 24 changes from ‹ TODAY. A habit's name anywhere (a Tess line, Review) still zooms to the habit itself (‹ HABITS). Checking in from Home stays what it is: typing "read" or "meditated" (A2, A3). Product to confirm the move; this is the default.

## Rules kept
1. **One base** per look; the Obsidian phones are the same frame.
2. **No dots, no dabs, no seams.** The strokes are the data (no-dots rule 2) and rest at the tint; the only other resting colour is the context line.
3. **Nothing cut.** A long habit name wraps the line to two (74 tall, the count on the first); the marks move down with it.
4. **The count stays ink** (G8) at rest and when the week is met.
5. **Haptics,** one per moment: the check-in's impact, `.selection` on the rule cycle, nothing for a rule count (the finish had its own).
6. **Reduce Motion:** strokes fade in place, the joined stroke appears whole, counts crossfade.
7. **Never:** streaks, flames, chains, "best", "missed", red, rings, percentages, a chart (§2).

## For Builder B
- `Features/Habits/`: the list as `HabitLine` (name, count) over `WeekStrokes` (seven `InkLine`-style lenses in the class pigment, the dashed guide for the rest, letters under); drop the per-habit label word and the history line from the list; `HabitPage` one tap down with the rule word, the history line, PAUSE THIS WEEK and DELETE HABIT as `InkLabelWord`s; ‹ REVIEW and ‹ HABITS with `EdgeSwipeBack()`.
- Review: the habit band's tap opens the Habits page; HABITS on the link line beside NOTES.
- Every clip ends inside the app, on the Habits page.

## Addendum, Oct 16: the check-in ask (Research 131, AQ12)
A hand-counted habit with no check-in today gets one ask in Tess's band at Shutdown, after the opener dries, one habit at a time: "**Read today?**" with two ink-line words under her line, **DONE** and **NOT TODAY** (the one-ask shape). DONE writes the check-in: "Read, done." with UNDO 10 s, the day's stroke lands wet on the Habits page. NOT TODAY writes nothing and the ask fades. Unanswered, it lapses with the hold (no mark, nothing counted). Never asked on a day that already has a record the habit counts (Product RF18), never while a workout runs, never more than once per habit per day, never on a paused week. On the Habits page the same ask is the habit's own line held (the hold is the check-in), so the band ask is the only place the words appear.
