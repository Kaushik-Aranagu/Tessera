# No dots: colour arrives through motion and moments

Kaushik, Oct 15, about 8:08 PM PT:
- He doesn't want the green, blue and yellow "bullet point" dots. They distract.
- He wants colour in subtler ways, and no sudden high-contrast pops.
- He still wants action, drama and things happening.
- What matters is that the meaning gets across. Where a dot isn't needed, remove it.
- **Clarified at 8:19 PM PT:** Tess herself, the soul, is fine and he likes her. This is only about bullet points. The soul's colours, blends, states and motion stay exactly as they are.

Recording: `recordings/no-dots.mp4` (source `studies/no-dots.html`), Porcelain, before on the left and after on the right. Stills: `mockups/no-dots-home.png` and `mockups/no-dots-review.png`.

## The rule (one line for every builder)
**Colour arrives through motion and moments; resting colour stays low-contrast.**

It works out as four rules.

1. **No coloured mark sits before or after a line of text.** A row is its words, its weight, its ink tier and its time. No dab, dot or bullet goes on either side of the words. This covers rows, links, list items, ingredient lines and section entries.
2. **Marks that are the data stay, but they rest quiet.** These are day marks, habit threads, month cells, the day stroke, plates, trend dabs and the chosen RPE stop. Each one lands **wet** at full pigment, then **dries** to its rest tint.
   - **The rest tint** is the pigment at 45% on light looks and 55% on dark looks.
   - **The timing:** the mark holds wet for 400ms, then dries over 1.1s on the house curve.
3. **A moment carries the colour.** When something happens, its colour shows for that moment, then settles. The moments are listed in the table below. There's at most one moment on screen at a time, and none of them loops, except the existing breathing wet tips.
4. **These are unchanged:**
   - The soul, which is Tess herself, not a marker.
   - Cobalt text for Tess's own words.
   - `liveInk` for UNDO and Finish.
   - `context` for context lines.
   - Stroke words under the action of the moment.

**Reduce Motion:** marks appear at their rest tint with no wet phase. Each moment becomes a 200ms crossfade straight to its resting state. A strike draws in ink.

**Contrast:** a resting tint never sits under text. Where a numeral used to sit on a strong dab (the month), the numeral stays `ink`.

## Every place, and what replaces it (master 388a37f)
| Place | Today | After | The moment that carries the colour |
|---|---|---|---|
| **Home queue rows**, `Features/Home/HomeQueue.swift:314` | 18×15 dab, `live` for a workout and `context` otherwise | **Nothing.** The name and time carry it. The next row is 21/500 and the rest are 21/400, as today. | **Finishing:** the strike paints in the row's class colour (`live` for a workout, the class pigment otherwise), 420ms. Then it dries to ink at 45%, along with the name, over 1s. **Becoming next:** the row that moves up gets one faint wash of its class colour behind the name (radial, 16% at peak, scale 0.7 to 1.08, 1.5s), then rests in ink. |
| **Now's ghost rows** (Tess's proposals), `NowPage.swift:290` | Blurred cobalt dab plus cobalt text | **No dab.** The text stays wet cobalt and keeps breathing (0.5 to 0.66). | **Accepting:** the words dry from cobalt into ink, left to right (clip sweep, 700ms, house curve). The time follows 250ms later. Tess's line says it once. This replaces "the dab takes the area colour" in `home-v1.md`. |
| **Kitchen links** (Groceries, Recipes, and Lists when it lands), `HomeSpatialView.swift:236` | Sage and amber dabs before each Title 34 word | **Nothing.** The words alone, in ink. | **The tap:** the zoom floods from the word in its class pigment at 12%, then the next page's ground takes over. |
| **Grocery rows: "for a recipe"**, `GroceriesView.swift:436` | 12×10 sage dab at the end of the row | The recipe's first word as a label word at the end of the row in `inkSecondary` (**PASTA**). With two or more recipes it reads **2 RECIPES**. A long press still lists them. | **Striking:** the sage fold that arcs into the basket (`GroceriesView.swift:173`) stays. It's motion, not a resting mark. |
| **Pasted ingredient lines**, `PasteRecipe.swift:346` | Sage dab before the name, plus a cadmium under-stroke under the amount | **No dab.** | **Reading in:** the amount's under-stroke paints in `now`, then dries to 35%. The name arrives in sage and dries to ink, 400ms later. |
| **Notes writing line**, `NotesView.swift:128` | Cobalt dab, 35% at rest | **No dab.** The hairline is the writing line. | **Writing:** the hairline inks in from the left in cobalt while you type, as today, and settles back to `hairline` on submit. |
| **Note links**, `NoteEditor.swift:64` | Cobalt dab before each link | **No dab.** Each link line is 600 ink, and the LINKS label is `inkSecondary` (B11 below). | none |
| **Capture modes** (Write, Speak, Show), `BottomChrome.swift:494` and `calm-capture.md` | 22×18 dabs (16×14 in calm-capture) rising out of the soul and **staying** beside each word | **The words alone** at rest, in ink. | **Opening:** the soul's three pigments still rise out of it on the same spring. Each one lands **into** its word as a wash behind the first letters, then dries away over 500ms, leaving ink. Write's cobalt still stretches into the writing line. |
| **Muscle rows**, `ExerciseViews.swift:243` | Vermilion dab sized by role | **No dab.** A primary muscle is 600 ink and a secondary is 400 `inkSecondary`. The role word stays. | none |
| **Month key** (the only legend of dots), `MonthPage.swift:158` | A small dab "lighter" and a big dab "heavier than usual" | **The words alone:** BIGGER IS HEAVIER THAN USUAL, as a label word in `inkSecondary`. | none |
| **Month cells**, `MonthPage.swift:96` | Dab in the routine paint, opacity by volume, numeral in `paper` when strong | Kept, because they're the data. The size still says volume. The dabs rest at the rest tint (the volume opacity × 0.45 on light looks, × 0.55 on dark). The **numeral is always `ink`**, and today's ring stays `live`. | **Arrival:** the cells land wet, 20ms apart, then dry. |
| **Week page dabs**, `WeekPage.swift:116` | Done is a filled routine dab, and today is a `live` ring | Kept. Done rests at the rest tint, and today's ring stays. | **Finishing a workout:** that day's dab lands wet, then dries. |
| **Review week dabs**, `ReviewPage.swift:405` and `rest-dab.md` | Sage dab at 92% | Kept, with the rest stroke and the miss ring unchanged. A trained day rests at the rest tint. | **Arrival:** the dabs land wet, 90ms apart (scale 0.6 to 1, settle spring), and dry 1.1s later. |
| **The day stroke**, `DayStrip.swift:150` | Five-pigment stroke at 85%, with session marks in `live` and a glow | The stroke rests at 60%, and the session marks lose their glow. The 26pt amber **wet tip dot goes**. Now is marked by the stroke's own end: the last 14pt are 2pt thicker, with a sheen that breathes (opacity 0.6 to 1, 3.6s). The five pigments come from the look's `daySpectrum`, not `HomePaint` hex. | **A session finishing:** its mark lands wet in `live`, then dries. |
| **Habits page week row**, `habits.md` | Done dab at 90%, other days at 14% | A done day rests at the rest tint. Other days are an **ink** dab at 10%: still the tap target, but no longer coloured. | **Check-in:** today's dab lands wet and dries. The brushstroke behind the dabs at the target stays the drama. |
| **Habit lines on Review** (Research item 83: "a line of dots under the dabs") | (proposed) a row of seven dots per habit | **One painted thread per habit** under the week. The label is "READ · 4 OF 5" at Label 16 in `inkSecondary`, and under it a 3pt rough stroke aligned to the day columns. Consecutive done days join into one stroke. **A gap means nothing:** it's only a day without it. A habit is a weekly target, so no day is a miss (`habits.md`, `fixtures/review-m3.md`). Future days show nothing. The thread uses the habit's class pigment (as in `body-weight-and-habits.md`), resting at the rest tint. 64pt per habit, max 3; more fold into "and 2 more" (z into the habits page). | **Check-in:** today's stretch paints on wet from the previous day (500ms), the count ticks (settle spring), and Tess says it once ("Read, 4 of 5 this week." Never a streak.). Then it dries. |
| **Habit block check-ins**, `body-weight-and-habits.md` | Class-coloured dabs | Same as the habits page row above. | same |
| **Day log page**, `day-log-page.md` | 13×11 class dab at x 78 on every line | **No dab.** Time, then text. An unfinished workout says "not finished" in words, as it already does. | none |
| **What Tess did** (m3-steers item 9) | Cobalt dab per op row | **No dab.** UNDO words in `liveInk` stay. | Undoing: the row's words dry back from ink to `muted` and fold. |
| **Rolling on** (m4-steers) | Small cobalt dab, "going with you" | The time column reads **TOMORROW**. Tapping the row to keep it today strikes that word. | **Day close:** the rows' TOMORROW words lift off toward the day stroke's end, 80ms apart (this replaces flying dabs). |
| **The paint spine** (m4-steers, not built) | One dab per headline item, stacked in the margin | One continuous 3pt margin stroke per date. Its colour shifts by segment, at the rest tint. | none |
| **Themes preview** (artifact v5) | Dabs before Home rows | Removed. | The strike moment, as above. |

**Not touched:**
- The soul (`Features/Tess/*`), including its idle saturation. Kaushik likes her as she is.
- The workout's signal strokes.
- Plates.

These are instruments or Tess. None of them is a bullet. The RPE stops, the exercise chart's tip and `ThinkingIndicator` are decided in the Research item 90 section below.

## Tokens (for Builder A's Looks work)
- **New:** `Theme.Colors.restTint(_ pigment: Color) -> Color`, which returns the pigment at 45% opacity on light looks and 55% on dark looks.
  - Resolve it per look. The workout always uses 55%.
- **New:** `Theme.Motion.dry`, an ease of 1.1s on the house curve with a 0.4s delay.
  - Use it for every wet-to-rest change.
  - Under Reduce Motion it becomes `nil` (the change is instant).
- **Retire `PaintDab` in rows.** Keep the type for data marks only, and add a doc line: "never before or after text".
- **Who does what:**
  - Ownership follows Research's split in `colour-at-rest.md`.
  - Builder A: training, workout, Plans, Exercise, looks, widgets and the Live Activity.
  - Builder B: Home, BottomChrome, Ask Tess, Settings, Review, Notes, Groceries, Recipes and the Object page.
  - Each PR's recording shows one moment from its own rows.

## Research item 90 (`../research/colour-at-rest.md`): every remaining place, decided
Research's ids are used here: A for dots, B for badges and tinted words, C for always-on colour, E for dead code. The one-line rule above still decides anything not listed.

**Dots Research found beyond the table**
| Id | Place | Decision | Owner |
|---|---|---|---|
| A1, A2 | The soul, on Home and in the workout corner | **Unchanged**, including idle saturation 1.45. Kaushik, 8:19 PM: the soul is fine. | none |
| A10 | Month legend, `MonthPage.swift:158-170` | Words only: BIGGER IS HEAVIER THAN USUAL, a label in `inkSecondary` (the table row above). | A |
| A13 | Exercise trend tip, `ExercisePaint.swift:57-65` | **Motion:** the cobalt tip shows only while the line draws in. Then it settles to a 6pt `ink` mark at 51%. | A |
| A14 | Chosen RPE stop, `RPEStops.swift:102-108` | **Rests quiet:** the chosen stop grows in workout `ink` (its size already says it). Amber and the glow show only during the snap (400ms), then dry. | A |
| A19 and E | `ThinkingIndicator` (whole file), `daySpectrum`'s unused twin in Theme if it remains, `ClassRole` / `classColor`, `actionBloom` | **Delete** as dead code. Exception: `daySpectrum` is now used by the day stroke (row above), so it stays. `RoundRobin` stays in the debug gallery. | B (DesignSystem lead) |

**Badges and tinted status words.** The rule: a status word rests in an ink tier, and its colour comes only when the state changes (it holds 1.5s, then dries over `Theme.Motion.dry`). The exceptions are `liveInk` UNDO and Finish, Tess's cobalt voice, and context lines.
| Id | Place | Decision | Owner |
|---|---|---|---|
| B1 | "Set N of M", `ExerciseStrip.swift:157-160` | Workout `ink` at 600 weight. | A |
| B2 | Workout subline, `WorkoutParts.swift:105-135` | **Motion:** amber or cobalt when the line changes, then it dries to workout `inkSecondary`. | A |
| B3 | Rest countdown and "Go", `WorkoutModeView.swift:411-438` | The countdown is in workout `ink`; the rest horizon already carries the amber. "Go" lands in amber, then dries. | A |
| B4 | Workout label words in signal, `LiveTessCorner.swift:41`, `WorkoutParts.swift:298` | Workout `ink`. The signal colour shows on press only. Finish stays `liveInk`. | A |
| B5 | `InkLabelWordStyle` at 85% colour at rest | Rests in `ink` at 600 weight, with colour on press. UNDO, Finish and Resume while something runs keep `liveInk`. | B |
| B6 | Routine editor open slot, `RoutineEditor.swift:225-264` | An `ink` margin rule, with weight on the open scheme. "Take out" turns vermilion on press only. | A |
| B7 | Exercise trend span in cobalt, `ExercisePage.swift:179-181` | `ink`. Cobalt is for Tess only. | A |
| B8 | Newest note's time, `NotesView.swift:184-186` | Arrives in cobalt, then dries to `inkSecondary`. | B |
| B9 | Object page class line, `ObjectPage.swift:329-332` | `inkSecondary`. | B |
| B10 | Review's WORKOUTS label and day words in `training`, `ReviewView.swift:193-198`, `:307-309` | `inkSecondary`, like "Put away". | B |
| B11 | `MarginSection` colour, `NoteEditor.swift:60`, `RecipePage.swift:325` | The default, `inkSecondary`. | B |
| B12 | Recipe page "N to buy" and the cooking line, `RecipePage.swift:101-125`, `:219-221` | `ink`, with the number in 600 weight. Colour on arrival only. | B |
| B13 | Live Activity tick and Go glow | The tick rests in ink. Go is a moment: it glows as it lands, then settles. | A |

**Always-on colour**
| Id | Place | Decision | Owner |
|---|---|---|---|
| C1, C2 | Tess's voice in cobalt | **Keep.** It's Tess. | none |
| C3, C4 | Context lines in `context` | **Keep.** It's the one quiet accent at rest, the "colour in other ways" he asked for. | none |
| C5, C6 | Page rails' vermilion carriage, `HomeSpatialView.swift:330-340`, `CarriageRail.swift:28-36` | **Motion:** the carriage rests in `ink`. It turns vermilion while dragging or paging and dries once settled. | B (Home), A (Exercise, Plans) |
| C7 | Day stroke hex, `HomeSpatialView.swift:7-17` | Route it through the look's `daySpectrum`, resting at 60% (the table row above). | B |
| C8 | Now's drain bar, `NowPage.swift:212-221` | The fill is `ink` at 51%, and only its moving leading edge (8pt) is amber. Read `now` from the look, not `HomePaint.dayAmber`. | B |
| C9 | Suspended process row, `NowPage.swift:519-538` | A paused thing isn't running: an `ink` hairline seam with no glow, and "Resume" in `ink` at 600 weight. Route hex 0x6E6480 through `inkSecondary`. | B |
| C10 | `ProcessSeam` while a workout or shop runs | **Keep vermilion,** because it marks a running thing, but drop the glow at rest. The glint passing along it is the life. | B |
| C11 | `PaintKey` stroke at 82% at rest, `Paint.swift:308` | It paints in at 100% when it appears, dries to 60% at rest, and goes back to 100% on press. The action of the moment still leads, just more quietly. | B (shared) |
| C12 | Workout current-exercise segment and row bar | Keep the signal colour, because it's the running exercise, but drop the glow at rest. | A |
| C13 | WeightDial needle and rest wash | Superseded by `set-block.md` (the weight is the numeral). The rest horizon stays. | A |
| C14 | Set-stroke colour cycle | Data marks: each set stroke lands wet in its cycle colour, then dries to `restTint` (55% in the workout). The finish gather stays a full-colour moment. | A |
| C15 | Plans weekly sets band and fill, `WeekPage.swift:194-206` | The band is `ink` at 8%, and the fill rests at `restTint` and lands wet. The Claude spend stroke keeps `claude-settings.md`'s cobalt, turning amber at 80%: it's a meter he reads. | A, B |
| C16 | Live Activity washes | **Keep.** It's the approved rest sky, and the Dynamic Island stays on the Obsidian set. | none |
| Hex | `HomePaint` (`HomeSpatialView.swift:7-13`) and `NowPage.swift:519` | Every colour comes from the look. Delete `HomePaint` once C7, C8 and the Kitchen dabs are gone. | B |
