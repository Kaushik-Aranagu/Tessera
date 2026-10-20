# Training, reorganized (Design item 107)

Kaushik, 4:07 PM PT Oct 19: he dislikes Push A / Push B / Pull A / Pull B, finds Training disorganized for an actual workout, and wants a muscle figure on every exercise. This sheet answers Product's `product/training-reorg-brief-oct19.md`. Rulings in that brief stand (plan PPL x2, rolling and fixed days, live mode frame, privacy masks, no cards, no pills, no dots, Inter Tight only, about 3 sizes per screen). Spec only until Kaushik picks; the picks are review switches (below).

Boards (source `studies/training-reorg-107.html`, Porcelain):
- `mockups/training-reorg-107.png`: Before (release 21), After on a push day, After on a pull day, Live, Exercise page.
- `mockups/training-reorg-107-body-first.png`: the alternative layout.
- `mockups/training-reorg-107-names.png`: the three naming options with the six names each.

## What was wrong (release 21, read from the build)
1. The title says "Push A". It does not say what the day trains.
2. No muscles anywhere on the page. The figure exists only on the exercise MUSCLES view and the routine footer, and on the exercise page only the shoulders peek above the footer.
3. The strip at the top and the dashed set strokes are decoration while reading: they carry no words. A target reads "82.5 x 8" with no unit.
4. START sits between the title and the list, then the plan line sits at the foot. The order is not the order of a workout: read, check, go.

## The recommended layout: the list first, a figure on every row
Same page, same START flight, same strip. Top to bottom (390 x 844):

| y | Element |
|---|---|
| 0 | The strip, unchanged (3 pt, unlit at rest, the live seam when running) |
| 58 | The area name |
| 100 | Context line in `context`, 21: "today, 5 exercises, about 55 min" |
| 136 | The day's name at Title 44 (names below) |
| 198 | One line in `inkSecondary`, 21, at most 2 lines in a 220 pt column: "Works chest, shoulders and triceps" |
| 134 to 246, right | The day's figure pair: front at x 268, back at x 320, 112 pt tall, the union of the day's muscles (primary full tint, secondary 70%), outline at ink 40%. Tint is the routine's colour (Push vermilion, Pull cobalt, Legs cadmium), read from the routine's kind (Core's kind field, else the day's primary muscles), never from the title's words. Information only: hidden from VoiceOver, no motion, no stagger |
| 268 + 72k | One row per exercise, 70 pt: the exercise's own figure at the left (62 pt tall, ONE side: the side showing most of its primary muscles, front on a tie), the name at 21/500, under it "4 x 5-8" at 16 `inkSecondary` and today's weight at the right at 16/600 ("82.5 kg"). Hairline between rows from x 44. Tap opens the exercise (zoom as now) |
| 642 | START (label word, ink line), "Start Bench day" |
| 700 | The plan line and ROUTINES, as now |
| 736 to 820 | Tess's band, as now |

- Six or more exercises: rows keep 72 pt and the list scrolls under the fixed START; the first five and the day's figure pair stay in view at rest.
- Row figure side rule: count the exercise's primary muscles that have a region on each side (side delts ride the front delt on the front and the rear delt on the back); more on the back means the back figure. Triceps has a region only on the back, so a triceps-only exercise (rope pushdown) shows the back figure.
- The sentence under the name: top three muscles by working sets, in his label style with no Oxford comma ("Works chest, shoulders and triceps"). Fold lats, upper back and lower back into "back", and the three delts into "shoulders". This extends `MuscleWords.works` (Core, small).
- The set strokes leave the rest page. They appear as each row's second line when the workout runs: the detail line "4 x 5-8" becomes the set strokes, logged ones painted, as live mode draws them. The START flight still matches the first row's name into live mode's name (the figure fades with the sinking rows).
- Running: the day's figure pair lights muscle by muscle, a part going full tint once any set of an exercise that works it is logged; unworked parts stay 40% (information, no animation beyond the 260 ms fade the figure already has).
- Done ("Bench day done"): rows show the logged sets, the figure pair shows what was worked at full tint; START becomes the tomorrow label as in sheet 44.
- A private routine reads "Private workout" everywhere and shows no lit muscles (Product ruling, Oct 19): lit muscles would say what the hidden words hide, so the day's figure pair and the row figures draw as the plain outline only, in the Training colour, and the sentence under the name is "Private workout" only. Tess's line and the closing face follow `ObjectPrivacy.routineTitle`.

## Live mode
The exercise's figure sits at the top right, one side (same side rule), 92 pt tall at x 326, y 40, outline at ink 45%. It never carries a number. The name keeps its fitting rule (Title 44, then 34, then two lines of 34) with 56 pt kept free at the right while the figure shows. Everything else on `live-workout.md` is unchanged. Reduce Motion: the figure swaps with the exercise by a 150 ms crossfade, otherwise it slides with the name along x.

## Exercise page
The figure pair (front and back, 100 pt tall) sits beside the two summary numbers on every view of the page, at x 296 and 340, y 216. Summary numbers move to y 232 and the context line may take two lines. The MUSCLES view keeps its rows and drops its own figures (they are always visible now). The stopgap in the meantime (Design's pick to Builder A, 4:13 PM): pin the pair at the left of the MUSCLES window and scroll the rows alone on the right.

## Routine page
Keeps #1097's footer figure for the union. Each exercise row gains the small row figure at its left (22 pt wide), and the context line adds the sentence: "5 exercises, about 55 min. Works chest, shoulders and triceps."

## The alternative layout: the body first (review switch)
`mockups/training-reorg-107-body-first.png`. The same header. One big front figure at the left (140 x 308) lit for the whole day, FRONT and BACK as two ink words under it (tap to turn), the exercise list at the right in the remaining 190 pt (name 21, "4 x 5-8 - 82.5 kg" at 16). Tap a row and only that exercise's muscles stay lit, the other rows fall to 38%, a hairline runs from the row to its main muscle, and Tess says what it works. Tap it again to light the whole day. It teaches more and shows one body at a glance; it costs a tap to see any one row's muscles and the name column is narrower (long names shorten: "Incline DB press"). Not recommended: when he is about to lift he wants the list and the weights, and the list-first page gives him a figure on every row with no tap.

## The names: three options (`mockups/training-reorg-107-names.png`)
Names are only defaults and seeded titles: any routine whose title he edited keeps it (Core's migration renames only a routine whose title still equals its seeded default). Voice rename still works.

1. RECOMMENDED, by the lift the day starts with: Bench day, Overhead day, Row day, Pull-up day, Squat day, Deadlift day. Short, so it travels (Home "Bench day, 6 pm", the Live Activity, Siri, the closing face "Bench day, ready to finish", "Row day tomorrow"). The muscles go in the line under the name and in the figure, wherever there is room.
2. By the muscles: "Chest, shoulders and triceps", "Shoulders, chest and triceps", "Back, shoulders and biceps", "Back, biceps and shoulders", "Quads, glutes and hamstrings", "Hamstrings, glutes and back". Says what is trained and nothing else, but it is long for Home, the Island and the closing face, and A and B days start alike.
3. Push, Pull, Legs plus the first lift: "Push, bench first", "Push, overhead first", "Pull, rows first", "Pull, pull-ups first", "Legs, squats first", "Legs, deadlifts first". Keeps the words he knows, drops the letter; mid length.

The plan stays "Push Pull Legs" (it is the plan's name, not a routine's). Copy that changes with a name: "Bench day, no fixed days.", "Bench day, all sets in.", "Bench day, taken back.", "Bench press, added to Bench day." The plan-line "ROLLS ON" and tomorrow line follow the real plan as before.

## Review switches (Settings, Review, Workout page; sheet 100's grammar; key `review.<id>`, default = today's behavior until he picks)
- `training.layout`: List first (recommended) / Body first. Default after his pick: his pick.
- `training.names`: Bench day (recommended) / Muscles / Push, bench first / Push A (as before). Applies to the seeded defaults only.
- The figures on rows, live and the exercise page are NOT behind a switch (he asked for them).

## Builder A brief (after Kaushik picks; the figures ship regardless)
1. Row figure (`MuscleFigure` at 62 pt with `line` 2.6 and outline 50%), the day's figure pair, the sentence line via `MuscleWords.works` extended (top three by sets, fold back and shoulders), in `TrainingAtRest`'s `LaneRow` and header. Tint from the routine's colour.
2. Live: the figure at top right with the name's 56 pt gutter. Exercise page: the figure pair beside the numbers on all views.
3. Layout order (START under the list at y 642) behind `training.layout`; the body-first variant as a second layout.
4. Names: Core renames seeded routines only when the title equals the old default; names option behind `training.names`; update the Tess copy lines above.
5. Accessibility: figures hidden from VoiceOver except where a row's label already says what it works ("Bench press, 4 x 5-8, 82.5 kilograms, works chest"); AX Dynamic Type stacks the weight under the scheme and drops the day's figure pair below the sentence.
6. Tests: the side rule (chest front, rows back, curls front), the sentence for all six seeded days, a private routine shows no sentence, a title he edited is never renamed.

## Never
A drawn food or any new figure art (sheet 91 stays the base). A band at the top. Dots. Cards. A faded or diffused Tess. A new face for the day's name. A monospaced face. A fourth text size on the page.
