# Sheet sweep: no dots, one base, no evening wash (Design item 19)

Design checked every earlier sheet in `docs/design/` against three rules:
- `no-dots.md` (Kaushik 8:07 PM): no coloured bullet dots; resting colour stays low-contrast; colour arrives through motion.
- `themes.md`'s fourth addendum (8:22 and 8:25 PM): one base for the whole app, so the workout and cook mode stand on the look's own ground.
- `evening-on-now.md`: the ground never turns to evening.

Each sheet that conflicts now carries a one-line note at its top pointing here. **Where an older sheet and this table differ, this table wins.** The rows `no-dots.md` already settles (Home queue rows, ghost rows, Kitchen links, grocery rows, pasted lines, notes, capture modes, muscle rows, the month key and cells, week dabs, Review dabs, the day stroke) are only pointed to, not repeated.

## One rule made exact: the context line
`no-dots.md` C3/C4 keeps "context lines in `context`" as the one quiet accent at rest. Builds and sheets have drifted both ways, so here is the exact rule.
- **The context line** is the single Body 21 line directly above a page's or Now's hero ("today", "this evening", "the week so far", "Saturday, 1 day to go", "trained this evening", "tomorrow, first"). It rests in `context`. There's one per page at most.
- **Every other resting line is `ink` or `inkSecondary`.** That covers sub-lines under a hero ("Push A is a tap away."), empty-state lines ("Nothing else today.", "This note is gone."), hints, failure lines and explanations.
- `themes.md`'s "Only `tess`, `context` and `liveInk` are ever text" now reads: `tess` when Tess speaks, `context` only for the context line, and `liveInk` for UNDO and moments.

This corrects three of Design's own recent calls:
- `review-week-line.md` put "the week so far" in `inkSecondary`. It goes back to `context`.
- The #264 review asked for the rest hero's "today" in `inkSecondary`. It goes back to `context`. "Push A is a tap away." stays `inkSecondary`.
- `evening-on-now.md` and the habits page drew their context lines in `inkSecondary`. Both now say `context`.

## The table
| Sheet | What conflicts | Now |
|---|---|---|
| `themes.md` | "Only `tess`, `context` and `liveInk` are ever text." `PaintFlood` starts from Tess's soul | As above. The flood takes an origin point, and Settings passes the tapped look name (`settings-place.md`) |
| `materials.md` | "Painterly ground"; "Dark ground: Workout" with cream text; "small markers are paint dabs, not dots" | The look's ground everywhere. The workout section is retired. **No markers at all**: a mark exists only when it's the data |
| `home-v1.md` | A 20pt stroke; a dab on each row; the ghost row's cobalt dab; "the row's dab takes the area colour" | The 6pt day stroke (`ink-line.md`, `no-dots.md`). Rows have no dab. Ghost rows dry cobalt to ink left to right (`no-dots.md`) |
| `today-on-home.md` | The 18×15 row dab; on a fling to TOMORROW "the row's dab lifts out and flies"; "Nothing else today." in `context` | No row dab. On the fling, the row's **TOMORROW** label word lifts out and flies the same arc to the day stroke's end (620ms). "Nothing else today." is `inkSecondary` |
| `day-strip.md` | Timed tasks as dabs on the stroke; an unfinished past item "stays as a faint dab at 40%" | Item marks on the stroke stay, because they're the data, but they rest at the rest tint and land wet. An unfinished past item rests at the rest tint like the rest, with no separate faint state. The soak stays as the moment |
| `home-labels.md` | The ghost row's "wet cobalt dab"; Kitchen words "with their dab"; "the workout's dark ground rises" | No dabs (`no-dots.md`). The workout rises **on the look's ground** |
| `workout-v1.md` | "A dark painterly ground"; every "cream"; the cream key | The look's ground, `ink` and `inkSecondary` (#266). The key is the ink-line stroke word. The RPE stop follows `no-dots.md` A14 |
| `kitchen/12-cook-mode.md` | A dark ground from `WorkoutPalette`; cream ink; the soul always in screen blend | Cook mode stands on the look's ground, in `ink`, with the soul's palette by look. The timer horizon is `ink` at 2.5pt over a 1.5pt guide at 14% |
| `live-activity.md` | Cream numerals and its own palette | The Lock Screen uses the day or night look's base. The Island stays Obsidian (#266). `widget-states.md` governs the layout |
| `back-word.md` | "Cream at 60% on the dark workout ground" | `inkSecondary` in every look, the workout included |
| `no-buttons.md` | "Cream on dark"; "on dark grounds (workout, cook mode) … the wash is the dark ground at 93%"; the 34pt stroke word | Ink on the look's ground. The wash is the look's ground at 92% (the veil). The stroke word's size and paint come from `ink-line.md` |
| `m4-steers.md` §8 | The focus timer, "a 2.5pt cream-on-ink stroke" | `ink` on the look's ground. The §7 evening wash was already withdrawn by `evening-on-now.md` |
| `voice-gym.md` | The parsed set "in full cream" | In full `ink` |
| `set-block.md` | Droplets in cream at 55% | `ink` at 55%. Plate colours stay, because they're the data |
| `live-polish.md` | The PR sweep in screen blend "on the dark ground" | On dark looks, as written. On light looks the same band is in multiply at 20%, so it still reads on white |
| `plans.md`, `exercise-page.md` | "Light painterly ground" | The look's ground. Plans' dabs and key and the exercise muscle rows follow `no-dots.md` (month cells kept and resting, key in words, no muscle dab) |
| `m3-steers.md` §9 | "A cobalt dab" per op on What Tess did | No dab (`no-dots.md`) |
| `kitchen/lists-9-12.md` | "Lists … as a Title 34 word with its dab" | The word alone, in ink |
| `kitchen/kitchen-v2.md` | The brush pass gives names "a sage dab" | Names arrive in sage and dry to ink. Amounts keep the under-stroke, drying to 35% (`no-dots.md`, `ink-line.md`) |
| `object-model.md` | "A handle is underlined with dots" | A handle has **no mark at rest**: names in `ink`, linked names at 600. On press, the ink line draws under it (150ms, `ink-line.md`), then the object zooms in |
| `widgets-and-snippets.md`, `habits.md`, `day-log-page.md` | Already marked superseded or amended | none |

## Left as they are
- Tess's soul in every sheet: three dabs, liked as she is.
- Motion dabs that land and leave: groceries' sage fold, cobalt arcs to aisles, the soul's pigments rising into the mode words.
- Data marks that rest at the rest tint: month cells, week and Review dabs, plates, the RPE stop, habit threads, and the habits page week row.

## Owners
These are design-text changes. The build rows they imply are already in `no-dots.md`'s tables, in the #266 and #264 reviews, and in the context-line correction above.
- **Builder B:** put the rest hero's "today" and Review's "the week so far" back to `context`. Move HomeQueue:101, BackupView:83, :118, :212, NoteEditor:91 and NotesView:222 to `inkSecondary`.
- **Builder A:** cook mode on the look's ground, and the back word on the workout.
