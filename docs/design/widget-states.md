# Widget states: every surface, drawn (board item 10)

This sheet is for Builder A's widgets item. It draws every state in Research's `widget-states.md` (item 22) in today's language: one base, no dots, the ink line and the type tiers. It also applies Product's widget copy calls (decisions, 5:02 PM PT Oct 15): "All quiet.", "×", "Set 3 taken back", and the `WorkoutSummary.line` text.
- **Where this differs from `widgets-and-snippets.md`, this sheet wins.** That sheet's painterly PNG grounds, its dark workout ground, its vermilion top seam and its 18pt line are gone.
- Boards (source `studies/widget-states.html`):
  - `mockups/widgets-home.png`: small and medium in Porcelain, and medium in Obsidian, for every state.
  - `mockups/widgets-large.png`: large, plus tinted mode.
  - `mockups/widgets-lock.png`: the Lock Screen accessories, the rest Live Activity and the Island.
  - `mockups/widgets-snippets.png`: the two snippets.
- Recording: `recordings/widgets-rest.mp4` shows the seam draining as the rest horizon, then the timeline flipping to "SET 4 IS UP".

## The language
- **Ground.** The active look's own `ground`: Porcelain white by day, Obsidian black by night, or the pinned look. Read it from the App Group (`look.day`, `look.night`, `look.pinned`) and the system colour scheme. Nothing changes while a workout runs, because there is one base. `containerBackground` is the ground, marked removable.
- **Type.**
  - The context line is Body 21/400 in `inkSecondary`, lowercase as on Now.
  - The hero is Title 34/500 in `ink`, one line, or two when there's no meta.
  - The meta is Label 16/700 in `inkSecondary`.
  - Numerals are 64 Light.
  - Nothing goes under 16pt. Quiet states (all quiet, a closed day, signing ended) put the hero in `inkSecondary`.
- **The seam.** One hairline (`ink` at 12%, or 16% on dark looks) between the hero and the meta. **While resting, the seam is the rest horizon.** A `ProgressView(timerInterval:)` styled as a 2pt line in `now` at 55% drains along it. The system draws it, so it moves with no reload.
- **One action word** sits at the right of the meta row: Body 21/600 on the `ink-line.md` lens (2.5pt, 75%), in the action's paint.
  - **Resume** is `liveInk` on a `live` line. **Pull A** is `ink` on a `training` line, and it opens the routine page; it doesn't start it.
  - The small size has no word: the whole widget is the tap.
  - There are no dots, dabs, pills or icons anywhere.
- **Motion between entries.** Words change with `.transition(.push(from: .bottom))`, and numbers use `.contentTransition(.numericText())`. Nothing else moves.
- **Tinted and clear modes.** The ground goes and the type stays. The one `.widgetAccentable()` element is the action's ink line, or the rest horizon while resting.

## Home Screen, every state
These use Research's running example (Thu 18:10, Push A).

| State | Context | Hero | Meta | Word |
|---|---|---|---|---|
| Running | running now, Push A | Bench, set 4 of 5 | SET 4 IS UP (NEXT EXERCISE, READY TO FINISH as the set changes) | Resume |
| Resting | running now, Push A | Bench, set 4 of 5 | RESTING **1:32** (21/600 timer), with the seam draining as the horizon. Flips to SET 4 IS UP at 18:12:30 (a second timeline entry). | Resume |
| Timed task within 15 min | next, at six | Call landlord | IN 10 MIN | none |
| Rest day | Rest day | Pull A is a tap away | none | Pull A |
| All quiet | none | All quiet. (`inkSecondary`) | none | none |
| Day done | trained this evening | Push A | 6 OF 6 · 22 SETS · 1 RECORD | none |
| Day closed (after Shutdown) | tomorrow, first | Pull A (`inkSecondary`) | 07:30 | none |
| Day closed, with his line | tomorrow, first | Reply to landlord (`inkSecondary`) | PULL A · 07:30 | none |
| 24 h before signing ends | as the state | as the state | RE-SIGN BY THU 18:10, only where the state has no meta of its own; never during a workout | as the state |
| Signing ended | paused | Run from Xcode to wake it. (`inkSecondary`) | EVERYTHING IS STILL ON THIS PHONE | none |

**Notes on the table:**
- **Day closed** uses m4-steers §7's "tomorrow, first" wording, so the widget and Now agree. It replaces fixture R24's "Tomorrow starts with…", which settles Research's question 8: ship it with Shutdown.
- **The re-sign line (Q6):** yes. It's plain, label tier, with no count of days, and it replaces the calendar reminder.

**Small:** two lines, at most.
- Running: "running now", then the hero at 34.
- Resting: "resting", then the 64 Light timer over the horizon seam.
- Day done: "trained", then "Push A".
- A hero longer than 18 characters drops to 26/500, so "Pull A is a tap away" and "Run from Xcode to wake it." fit on two or three lines.

**Large:** the medium layout on top, then the label **LATER** and up to 3 ranker rows: the title in Body 21 `ink`, and the time as a label at the right, 36pt apart.
- On a rest day, the rows are the scored items under the rest line, and they have no time.
- There's no Later window when there's nothing later, and none once signing has ended (a stale list looks like a plan).

## Lock Screen accessories
These are monochrome, in opacity tiers only. The words and the one timer carry the state.

| State | Rectangular (bold / line / dim line) | Circular | Inline |
|---|---|---|---|
| Running | Push A / Bench, set 4 of 5 / Set 4 is up | Ring at 3 of 5, "4/5" | Bench, set 4 of 5 |
| Resting | Push A / Bench, set 4 of 5 / Resting 1:32 | `ProgressView(timerInterval:)` gauge, "1:32" | Resting 1:32 |
| Timed task | Call landlord / next, at six / In 10 min | Ring, "10 min" | Call landlord at six |
| Rest day | Rest day / Pull A is a tap away | "Rest" | Rest day |
| All quiet | All quiet. | "Quiet" (not a tick: a tick would say done) | All quiet. |
| Day done | Push A / trained this evening / 6 of 6 exercises, 22 sets | Full ring, tick, "22" | Push A, done |
| Day closed | Pull A / tomorrow, first / 07:30 | "7:30" at 66% | Pull A at 7:30 |
| 24 h before | the state, plus "Re-sign by Thu 18:10" as the dim line | the state | the state |
| Signing ended | Tessera is paused / Run from Xcode | "Paused" at 66% | Tessera paused |

VoiceOver labels follow Research's list.

## The rest Live Activity
> **Item 36:** `lockscreen.md` supersedes the first sentence below: every Live Activity stays **Cobalt sky in every look**, and the Island is the system's black. It also draws every Lock Screen state and notification.

The Lock Screen face follows the look, and the Island is always Obsidian (`themes.md`). The faces on master stand. There are two new states:
- **Undo after Done (C6):** "Set 3 logged." at Body 21, with **UNDO** as a label in `liveInk` at the right, and the next rest starting under it. UNDO answers "Set 3 taken back." That's Product's undo rule; it replaces `UndoLastSetIntent`'s "Last set removed."
- **After the last set (Q4):** the face stays for 60s instead of vanishing.
  - "All 22 sets in." at Title 34.
  - "Push A, ready to finish" in `inkSecondary`, so the face agrees with Now's "Ready / to finish".
  - The horizon is full, and ENDS IN A MINUTE is a label.
  - Then it ends with the default dismissal. Finishing stays a hold in the app.

## Snippets
These sit on the system platter, with no ground: type does the work.
- **"What's now" (`ShowNowIntent`)** uses the widget's words.
  - Running: the one action word is **Same again** (`training` ink line). **Resume** is a plain `liveInk` word with no line, because a snippet has one action word.
  - Resting: the 64 Light timer over the horizon seam, then REST, THEN SET 4, with **+15** and **Skip** as plain words.
  - Rest day: **Open Pull A**.
  - All quiet: "All quiet." only.
  - Day done: the hero and the summary label.
  - Spoken lines are Research's. "All quiet." is spoken for the empty state.
- **"Log a set":**
  - Running: two 80 Light numerals with a 1pt hairline between them, KG and REPS labels, the hairline seam, "Bench, set 4 of 5", then **Same again** on its line, with **+2.5** and **+1 rep** plain in `inkSecondary`.
  - Resting: the same, with "Resting **1:32**".
  - Rest day: "Rest day. Pull A is a tap away." with **Start Pull A**.
  - Nothing running: "No workout running." with **Start Pull A**.
  - Day done: "Push A is done. 22 sets." with **UNDO SET 22** in `liveInk`, which answers "Set 22 taken back."
- **Signing ended:** nothing. The intent can't run.

## For Builder A
1. Ground and ink tiers from the look via the App Group. Delete the painterly-PNG plan.
2. The seam view, with a resting variant as `ProgressView(timerInterval:)` in `now` at 55%. Write a second timeline entry at `restEndsAt`.
3. The action word with `InkLine` (shared from `DesignSystem` into the extension) and `.widgetAccentable()` on the line only.
4. Copy from the tables above: "All quiet." everywhere; × in sets; `FinishWorkoutIntent` says "Finished. " + `WorkoutSummary.line`.
5. Live Activity: the Undo state and the 60s "All 22 sets in." face.
6. The expiry entry, and the 24h re-sign line from `embedded.mobileprovision`, as Research describes.

## Addendum, Oct 16: the widgets speak Home's lines (Design item 54)
**Kaushik's principle, in one line:** one plain Tess-written line per thing, with the detail one tap down; a widget is that line, nowhere to tap down, so it carries nothing else.

Every widget's hero is **Home's line** (`docs/ai/home-lines.md`): the hero, then the context, as one sentence with a stop. The phone writes it from the same `HomeLines` lens Home draws from, so the widget and Home never disagree; Claude's context words ride along only once they've passed Home's checks. **No counts and no marks:** the 6 OF 6 · 22 SETS · 1 RECORD meta goes, "set 4 of 5" becomes "bench set 4", the circular accessories lose their rings and tick. The one number on any face is a time or a timer. The ground and ink stay the look's; the board shows all five.
- Board: `mockups/widgets-home-lines.png` (source `studies/widgets-home-lines.html`): the medium widget in Porcelain, Plein, Celadon, Obsidian and Lacquer for six states, the small widgets, the Lock Screen accessories, the 60 s rest face.
- Recording: `recordings/widgets-home-lines.mp4` (13 s), Porcelain medium: planned, running (the words push in from below), resting with the horizon draining on the seam, set 4 up, done with a best.

### The line (Core: `HomeLines.widgetLine`)
1. Start with the hero as Home has it: "Push A", "Push A, bench set 4", "Push A done", "Tacos tonight", "Rest day", "All quiet".
2. Add the context line: a bare time word joins without a comma ("Push A today.", "Push A this evening."); a fact joins after a comma ("Push A done, a bench best.", "Tacos tonight, 2 to buy."); a context that repeats the hero's state word ("done at 7:40 pm" under "Push A done") drops, and its clock time becomes the meta ("7:40 PM").
3. End with a stop. Title 34, up to two lines on the medium and large; the small drops to 26 past 18 characters.

### Home Screen, every state, redrawn
| State | The line | Meta (label, time only) | Word |
|---|---|---|---|
| Planned | Push A today. | 6:00 PM | Push A (`training` line; opens the routine) |
| Running | Push A, bench set 4. | none | Resume |
| Resting | Push A, bench set 4. | **1:32** (21/600) on the horizon seam, draining | Resume |
| Timed task within 15 min | Call landlord at six. | IN 10 MIN | none |
| Rest day | Rest day. | none | Pull A |
| All quiet | All quiet. (`inkSecondary`) | none | none |
| Day done | Push A done, a bench best. / Push A done. | 7:40 PM | none |
| A planned cook | Tacos tonight, 2 to buy. | none | Groceries (`now` line) |
| Day closed | Pull A tomorrow, first. | 7:30 AM | none |
| 24 h before signing ends, signing ended | as before | as before | as before |

- **Small:** the line alone. Resting: "resting" at 21 `inkSecondary`, the seam, the 64 Light timer. Nothing else.
- **Large:** the medium on top, then LATER rows as before (titles and times only, 41 rule 7).
- **Motion:** the words push in from below (`.push(from: .bottom)`), numbers `.numericText()`. Unchanged.

### Lock Screen accessories, redrawn
| State | Rectangular (bold line, then the time) | Circular (one word) | Inline |
|---|---|---|---|
| Planned | Push A today. / 6:00 pm | Push A | Push A today |
| Running | Push A, bench set 4. | Set 4 | Push A, bench set 4 |
| Resting | Push A, bench set 4. / Resting 1:32 | 1:32 (`Text(timerInterval:)`, no gauge) | Push A, bench set 4 |
| Timed task | Call landlord at six. / In 10 min | 10 min | Call landlord at six |
| Rest day | Rest day. | Rest | Rest day |
| All quiet | All quiet. | Quiet | All quiet |
| Day done | Push A done, a bench best. / 7:40 pm | Done | Push A done, a bench best |
| Day closed | Pull A tomorrow, first. / 7:30 am | 7:30 | Pull A tomorrow, first |
| Re-sign, signing ended | as before | as before | as before |

The third (dim) line goes. The inline widget drops the stop (it sits next to the clock).

### Snippets
"What's now" speaks the line and keeps its action words. "Log a set" keeps its two numerals (the set is the one licensed number); its sentence under the seam is the line ("Push A, bench set 4."), and day done reads "Push A done." with UNDO SET 22 as before (the count lives in the undo word, which names the set).

### For Builder A
- `HomeLines.widgetLine(for:)` from the App Group snapshot replaces the widget's own context/hero/meta strings; delete the summary meta and the 4-of-5 forms.
- Circular: `Text` only, no `Gauge`, no ring, no tick; the resting timer as `Text(timerInterval:)`.
- Everything else on this sheet stands.
