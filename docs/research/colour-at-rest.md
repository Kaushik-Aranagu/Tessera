# Colour at rest: inventory (item 90)

Source: master at `8fc5bd3` (Merge #227, Claude settings; one step after `c5d7193`). Every line below was read at that commit.
Brief: Kaushik, Oct 15 8:07 PM PT. No coloured bullet dots anywhere ("the green, blue, or yellow... it's distracting").
Colour should be subtle at rest and arrive through motion, or be dropped if the meaning comes across without it.

## Summary

| Group | Count | Must change? |
|---|---|---|
| A. Dots, bullets, dabs (incl. Tess soul, DayDabs) | 19 | Yes, all of them (one is dead code) |
| B. Badges and tinted status words | 13 | Most: make quieter or move into motion |
| C. Always-on colour (strokes, rails, glows, voice colour, washes, tokens) | 16 | Decide per item; most can go quieter |
| D. Already arrives through motion (keep, for reference) | 11 | No |
| E. Dead or unused colour code | 5 | Delete |

Dots by screen (the highest priority):
- **Bottom chrome / Ask Tess (Builder B):** the Tess soul's three coloured dabs, always on in the corner (A1); the Speak / Write / Show mode dabs (A11).
- **Home, Today (Builder B):** queue row dabs (A3), Tess ghost row dab (A4), the breathing amber "now" dot on the day stroke (A5).
- **Home, Kitchen (Builder B):** green and amber dabs beside Groceries and Recipes (A6).
- **Home Review and Review screen (Builder B):** green DayDabs per trained day (A7).
- **Plans week and month (Builder A):** routine-coloured day dabs, vermilion today ring, the legend dabs (A8, A9, A10).
- **Exercise page (Builder A):** vermilion muscle dabs (A12), cobalt dot at the end of the trend line (A13).
- **Workout (Builder A):** the Tess soul in the live corner (A2), the amber chosen RPE stop with glow (A14).
- **Groceries, Notes, Recipe paste (Builder B):** green recipe dab (A15), cobalt composer dab (A16), cobalt link bullets (A17), sage ingredient dab (A18).

Themes: all five looks (Porcelain, Obsidian, Plein, Lacquer, Celadon) share one structure (`DesignSystem/Looks.swift:63-109`).
Each has the same roles (`live` vermilion, `tess` cobalt, `now` amber/cadmium, `health` green/sage, `training` pink
(sage on Plein), `context` violet/slate, plus a `workout` set: `signal`, `rest`, `tess`, `health`). So **every item
below shows in every look** unless the Theme column says otherwise. Only the hue changes per look.
Exceptions: `HomePaint` hex constants (`Features/Home/HomeSpatialView.swift:7-13`) are fixed Plein-like colours and
ignore the look; the Dynamic Island is always the Obsidian set (`Widgets/RestLiveActivity.swift:52`); the Lock Screen
Live Activity uses the day or night look (`Shared/LookTable.swift:37-39`).

Core: no engine-provided colour reaches a view. `SystemCatalog` gives each class a `colorRole` string
(`TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift:46`), but `Theme.Colors.classColor`
(`DesignSystem/Theme.swift:350`) is never called. Nothing for Core to own.

Owners: Builder A = training, workout, Plans, Exercise, looks, widgets, Live Activity. Builder B = Home, BottomChrome,
Ask Tess, Settings, Day log, Review. Screens that were not assigned (Notes, Groceries, Recipes, Backup, Object page) are
suggested for B (they are not training). Shared DesignSystem pieces are marked "A+B" with a suggested lead.

Suggestion key: **motion** = colour arrives only while something moves or changes, then settles to ink;
**quieter** = keep a mark but make it ink, weight, a stroke or type; **drop** = the meaning already reads without it.

---

## A. Dots, bullets, dabs (must go)

`PaintDab` (`DesignSystem/Paint.swift:147-168`) says "Never a dot" in its doc comment, but at 10 to 34 pt it reads as a
coloured bullet. That is what Kaushik means.

| # | File:line | Screen / view | Theme(s) | What it says | Kind | Suggestion | Owner |
|---|---|---|---|---|---|---|---|
| A1 | `Features/Command/BottomChrome.swift:159-168` (`TessSoul(mode: model.tessMode)`), palette `Features/Tess/TessSoul.swift:118-127`, idle saturation `Features/Tess/SoulParameters.swift:78` and `:124-127` | Bottom chrome soul key, every screen | All; multiply on light looks, screen and halo on dark | "Tess is here." Three wet dabs (live, tess, now) at 1.45 saturation, breathing | Dot cluster, always on | **Motion**: idle in ink or near-grey (the `.resting` row already uses saturation 0.35, `SoulParameters.swift:199-202`); colour blooms only for listening, thinking, done, hand-off | B |
| A2 | `Features/Workout/LiveTessCorner.swift:64`, palette `Features/Tess/TessSoul.swift:130-137` | Workout, Tess corner | All (workout palette: signal, Workout.tess, rest) | Same as A1 inside the workout | Dot cluster, always on | **Motion**: same rule as A1, so the set strokes stay the only colour at rest | A |
| A3 | `Features/Home/HomeQueue.swift:314` | Home Today, queue rows | All | Workout row (vermilion) or other item (violet) | Bullet | **Drop**: the title says what it is; if a workout cue is needed, use weight or a small ink glyph | B |
| A4 | `Features/Home/NowPage.swift:290` (`GhostRow`, struct at :278) | Home Today, Tess's ghost row | All | "Tess suggests this", cobalt dab plus cobalt title and time (:294, :299) | Bullet + tinted row | **Drop** the dab; the breathing opacity (:302) already says "proposed". Text to ink 50%; cobalt only as the row writes in | B |
| A5 | `Features/Home/DayStrip.swift:216-230` (`WetTip`, colour `HomePaint.wetTip` at `HomeSpatialView.swift:13`) | Home Today, day stroke | All (fixed hex, ignores look) | "Now" on today's stroke, 26 pt amber dot, breathing forever | Dot, always on | **Quieter**: the stroke's painted end already marks now. Drop the dot, or make it an ink tip that breathes | B |
| A6 | `Features/Home/HomeSpatialView.swift:236-237` (`KitchenPage`, struct at :224) | Home Kitchen links | All (fixed hex) | Groceries (sage) vs Recipes (amber) | Bullet | **Drop**: two titles need no key | B |
| A7 | `Features/Home/ReviewPage.swift:401-420` (`DayMarkView`), used at `ReviewPage.swift:361` and `Features/Review/ReviewView.swift:270` | Home Review week row, Review screen | All | DayDabs: trained (green 34x30), 2+ sessions (second green dab), open (hollow ink), rest (ink stroke, :425-440) | Dot row | **Quieter**: trained as an ink dab (the rest mark is already ink); green can arrive as the row pops in (:363-366), then dry to ink | B |
| A8 | `Features/Plans/WeekPage.swift:116-130` | Plans, week page | All | Done day (routine colour fill), today (routine colour outline), planned (ink outline) | Dot row | **Quieter**: ink fill for done, ink outline for today; routine colour only on press or when the week draws in | A |
| A9 | `Features/Plans/MonthPage.swift:109-121` | Plans, month grid | All | Trained days filled by routine colour, opacity by effort; today ringed vermilion | Dot grid | **Quieter**: ink dab, opacity by effort (the effort reads from size and opacity already); today as an ink ring | A |
| A10 | `Features/Plans/MonthPage.swift:158-170` (`Key`) | Plans, month legend | All | "lighter" vs "heavier" | Legend dots | Follows A9: ink dabs, or **drop** the key if A9 goes ink | A |
| A11 | `Features/Command/BottomChrome.swift:252` and `:523` (`ModeRow`), colours `SoulColor` `:490-497` | Ask Tess, Speak / Write / Show menu | All | Which mode; dab rises out of the soul | Bullet per row (motion on entry, then static) | **Motion**: let the dab rise and then fade or fold into the word's underline; at rest the words alone | B |
| A12 | `Features/Exercise/ExerciseViews.swift:243-247` (`MuscleRowView`) | Exercise page, muscles list | All | Primary vs secondary muscle (size, opacity) | Bullet | **Drop**: the role word is already on the row (:252-254); weight on the name can carry primary | A |
| A13 | `Features/Exercise/ExercisePaint.swift:57-65` | Exercise page, trend line | All | End of the e1RM trend, 18 pt cobalt blurred dot | Dot | **Motion**: show it only while the line draws in (`drawn`), then drop | A |
| A14 | `Features/Workout/Instruments/RPEStops.swift:102-108` | Workout, RPE stop slider | All (workout `rest` amber) | Chosen effort: amber circle + amber glow; others are cream 45% dots | Dots (stops are ink, chosen is coloured) | **Quieter**: chosen stop grows in cream (size already changes); amber only during the snap | A |
| A15 | `Features/Groceries/GroceriesView.swift:435-438` | Groceries, item row | All | "This item is for a recipe" | Bullet | **Drop**: the "for ..." line (:440-444) says it on reveal; or a quiet ink mark | B |
| A16 | `Features/Notes/NotesView.swift:128-130` | Notes, composer | All | Write here; 35% at rest, full cobalt while writing | Bullet, faint at rest | **Drop**: the underline already fills cobalt on focus (:141-149), which is the motion version | B |
| A17 | `Features/Notes/NoteEditor.swift:64-65` | Note editor, Links section | All | Bullet before each linked object | Bullet | **Drop**: the margin label "Links" groups them | B |
| A18 | `Features/Recipes/PasteRecipe.swift:358-361` (`IngredientPaint`) | Recipe paste, ingredient line | All | Where the name starts; sage dab appears as the brush passes | Bullet (arrives with motion, stays) | **Quieter**: let it appear and fade; the cadmium under-stroke on the amount (:353) already splits amount and name | B |
| A19 | `DesignSystem/ThinkingIndicator.swift:54-62` (`dots`) | None (no `ThinkingIndicator(` call anywhere; no concept uses `.dots`) | n/a | Thinking | Dots, dead | **Drop**: delete the `.dots` style | B |

---

## B. Badges and tinted status words

| # | File:line | Screen / view | Theme(s) | What it says | Kind | Suggestion | Owner |
|---|---|---|---|---|---|---|---|
| B1 | `Features/Workout/ExerciseStrip.swift:157-160` | Workout, exercise list | All (workout `rest` amber) | "Set N of M" on the current exercise | Tinted status word | **Quieter**: ink, with weight; the vermilion bar (:147-150) already marks current | A |
| B2 | `Features/Workout/WorkoutParts.swift:105-135` (`WorkoutLines.subline`) | Workout, subline under the numbers | All | New best, RPE, record hint (amber); editing, swapped (cobalt); else secondary | Status colour per state | **Motion**: colour when the line changes, settle to secondary | A |
| B3 | `Features/Workout/WorkoutModeView.swift:411-413` and `:436-438` | Workout, rest countdown and "Go" (72 pt) | All (amber) | Resting; time to go | Tinted numerals | **Quieter**: cream numerals; amber only for "Go" as it lands | A |
| B4 | `Features/Workout/LiveTessCorner.swift:41`, `Features/Workout/WorkoutParts.swift:298` | Workout label words | All (signal) | Action words in vermilion | Tinted action word | **Quieter**: cream; the hairline on press (`InkLabelWordStyle` pattern) is the motion | A |
| B5 | `Features/Command/BottomChrome.swift:586-603` (`InkLabelWordStyle`, 85% colour at rest), vermilion call sites `BottomChrome.swift:142`, `Features/Home/NowPage.swift:392`, `Features/Groceries/GroceriesView.swift:647`, `Features/Recipes/RecipePage.swift:224`, `Features/Recipes/PasteRecipe.swift:244`, `Features/Settings/ClaudeSection.swift:88` (liveInk) | Undo, "Start X", Replace / Remove words | All | "You can act here" | Tinted action word | **Quieter**: ink-secondary at rest (the style's default), colour and hairline on press | B (owns the style) |
| B6 | `Features/Plans/RoutineEditor.swift:225-227` and `:257`, `:261-264` | Plans, routine editor slot | All | Open slot (scheme in vermilion), "Take out" vermilion, vermilion margin rule | Tinted word + rule while open | **Quieter**: ink rule, weight on the open scheme; vermilion only on "Take out" press | A |
| B7 | `Features/Exercise/ExercisePage.swift:179-181` | Exercise page, trend span | All | Rising trend in cobalt | Tinted status word | **Drop** the colour: the "+x kg" text says it | A |
| B8 | `Features/Notes/NotesView.swift:184-186` | Notes list | All | Newest note's time in cobalt | Tinted badge | **Motion**: cobalt fades to secondary after arrival | B |
| B9 | `Features/Objects/ObjectPage.swift:329-332` | Object page header | All (`training`) | Class line in pink | Tinted label | **Drop** colour: ink-secondary, the class name says it | B |
| B10 | `Features/Review/ReviewView.swift:193-198` and `:307-309` (`ReviewLine` tint) | Review, Workouts section | All (`training`) | Section label and day words in pink | Tinted labels | **Drop** colour: secondary ink like "Put away" (:180) | B |
| B11 | `DesignSystem/Editorial.swift:89-128` (`MarginSection` color), coloured at `Features/Notes/NoteEditor.swift:60` (tess) and `Features/Recipes/RecipePage.swift:325` (now) | Note editor, recipe page | All | Section label in colour | Tinted label | **Drop** colour (default is ink-secondary) | B |
| B12 | `Features/Recipes/RecipePage.swift:101-104`, `:219-221` (health), `:122-125` (now) | Recipe page | All | "N to buy, in Groceries" green; cooking line amber | Tinted status line | **Quieter**: ink with the number in weight (already semibold); colour on arrival only | B |
| B13 | `Widgets/RestLiveActivity.swift:70-72`, `:87-89` (Tick), `:91` (`keylineTint`), `:286-295` (tick + Go glow); colours `Shared/LookTable.swift:46-48`, `:76-78` | Live Activity, Dynamic Island and Lock Screen | Island: always Obsidian; Lock Screen: day or night look | "Log the planned set"; Go time | Tinted tick, glow at Go | **Quieter**: cream tick at rest; vermilion glow only at Go (already gated by `isGo`) | A |

Also tinted, in Settings (new in #227): `Features/Settings/ClaudeSection.swift:336-339`, spend stroke cobalt, amber when
`warm` (near the $10 limit). Status colour on a bar. Suggest **quieter**: ink stroke, amber only once warm. Owner B.
(Counted in C below as C15 to keep B at 13.)

---

## C. Always-on colour (strokes, rails, glows, voice, washes, tokens)

| # | File:line | Screen / view | Theme(s) | What it says | Kind | Suggestion | Owner |
|---|---|---|---|---|---|---|---|
| C1 | Tess voice in cobalt: `Features/Command/BottomChrome.swift:135`, `:229`; `Features/Home/NowPage.swift:361`; `Features/Home/TrainingPage.swift:100`, `:194`, `:250`; `Features/Home/ReviewPage.swift:276`; `Features/Review/ReviewView.swift:209`; `Features/Groceries/GroceriesView.swift:636`, `:668`; `Features/Notes/NotesView.swift:262`; `Features/Backup/BackupView.swift:113`; `Features/Recipes/PasteRecipe.swift:36`, `:241`; `Features/Settings/ClaudeSection.swift:84`, `:120` | Home, Review, Groceries, Notes, Backup, Settings, Ask | All | "Tess said this" | Coloured type | **Quieter**: Tess already has her own face (`Theme.voice`); ink or ink-secondary at rest, cobalt only while the line writes in | B |
| C2 | Tess voice in cobalt, training side: `Features/Exercise/ExercisePage.swift:55`; `Features/Plans/MonthPage.swift:36`; `Features/Plans/RoutineEditor.swift:120`; `Features/Workout/WorkoutModeView.swift:427`, `:483`; `Features/Workout/LiveTessCorner.swift:30`; `Features/Workout/SwapPanel.swift:136` | Exercise, Plans, Workout | All | Same as C1 | Coloured type | Same as C1 | A |
| C3 | Context lines in violet: `Features/Home/NowPage.swift:91`, `:345`, `:379`, `:387`, `:411`, `:456`; `Features/Home/HomeQueue.swift:99`; `Features/Home/ReviewPage.swift:255`; `Features/Home/TrainingPage.swift:41`, `:141`, `:219`, `:361`; `Features/Review/ReviewView.swift:156`; `Features/Groceries/GroceriesView.swift:65`; `Features/Notes/NotesView.swift:65`, `:219`; `Features/Notes/NoteEditor.swift:35`, `:91`; `Features/Backup/BackupView.swift:45`, `:68`, `:93`, `:187`; `Features/Recipes/RecipePage.swift:73`, `:146`; `Features/Recipes/PasteRecipe.swift:321` | Every page's top line ("today", "trained this morning") | All (`context`: violet, slate on Celadon) | "Where you are" | Coloured type, always on | **Drop** colour: ink-secondary in the voice face reads the same | B |
| C4 | Context lines, training side: `Features/Exercise/ExercisePage.swift:111`; `Features/Plans/PlansView.swift:121`; `Features/Plans/RoutineEditor.swift:108`, `:348` | Exercise, Plans | All | Same as C3 | Coloured type | Same as C3 | A |
| C5 | `Features/Home/HomeSpatialView.swift:330-340` (`PaintedRail`, struct at :304) | Home, REVIEW / TODAY / TRAINING rail | All | Current page, vermilion carriage 64x4 | Always-on accent stroke | **Motion**: ink carriage at rest; vermilion while dragging or paging | B |
| C6 | `Features/Exercise/CarriageRail.swift:28-36`, used at `Features/Exercise/ExerciseViews.swift:37` and `Features/Plans/PlansView.swift:38` | Exercise siblings, Plans pages | All | Same as C5 | Always-on accent stroke | Same as C5 | A |
| C7 | `Features/Home/DayStrip.swift:153-160`, `:186-188` (gradient), colours `Features/Home/HomeSpatialView.swift:7-17`; workout marks `DayStrip.swift:161-168` (vermilion + glow) | Home Today, day stroke | All (fixed hex sky, sage, violet, amber, vermilion: ignores the look) | The day so far; when you trained | Five-colour stroke + coloured marks, always on | **Quieter**: one ink wash for the day; workout marks as heavier ink; the spectrum could paint in on appear (`drawn`) and dry to ink. At least route the hex through the look | B |
| C8 | `Features/Home/NowPage.swift:212-221` (`DrainBar`, struct at :202) | Home Today hero, running event | All (fixed `HomePaint.dayAmber`) | Time used of the current event | Coloured progress bar | **Quieter**: ink fill; it already moves every second | B |
| C9 | `Features/Home/NowPage.swift:534-538` (seam, vermilion + glow), `:524` ("Resume" vermilion), `:519` (fixed hex 0x6E6480) | Home Today, suspended process row | All (hex ignores look) | A paused process | Glowing line + tinted word | **Quieter**: ink seam; "Resume" in ink with weight. Route the hex through `inkSecondary` | B |
| C10 | `DesignSystem/Machined.swift:184-209` (`ProcessSeam`, vermilion + `pigmentGlow`), used at `Features/Command/BottomChrome.swift:628-640` (`RunningSeam`) and `Features/Groceries/GroceriesView.swift:182-187` | Top edge while a workout runs; Groceries while shopping | All; glow full on Obsidian, Lacquer and the workout, 30% on light looks (`DesignSystem/ThemeLayers.swift:221-234`) | "Something is running" | Glowing line, always on while running | **Motion**: the glint sweep (:193-204) can carry it; base line in ink, colour only in the glint | B |
| C11 | `DesignSystem/Paint.swift:300-324` (`PaintKey` stroke at 82% at rest, :308). Call sites: Home `NowPage.swift:114`, `:428`, `:462`; `TrainingPage.swift:85`, `:185`; `BackupView.swift:168`; `GroceriesView.swift:132`, `:607`; `RecipePage.swift:115`; `PasteRecipe.swift:249`; `ExercisePage.swift:204`; workout `WorkoutModeView.swift:569`, `:582`, `:598`, `:607`; `ExerciseStrip.swift:110`; `WorkoutFinishView.swift:78`; `WorkoutParts.swift:283` | The one primary action on each screen | All | "This is the action" | Coloured brushstroke under a word | **Motion**: dry ink stroke at rest; the paint floods in on touch (the `wet` and hold fill already animate) | A+B; B leads `Paint.swift`, A checks workout keys |
| C12 | `Features/Workout/ExerciseStrip.swift:39-57` (current segment, vermilion + glow) and `:147-150` (current row bar + glow) | Workout, progress strip and exercise list | All | Current exercise | Glowing accent | **Quieter**: cream segment; the glint (:44-52) is the motion | A |
| C13 | `Features/Workout/Instruments/WeightDial.swift:253-260` (vermilion needle + glow), `:225-251` (rest fill: amber wash with 2 pt amber edge, the in-app rest horizon) | Workout, weight dial | All | Where the weight is; rest draining | Glowing needle; coloured wash | **Quieter**: cream needle; the rest wash is already motion (drains each second) and can stay | A |
| C14 | Set strokes colour cycle: `DesignSystem/Theme.swift:451-453` (`setCycle`: signal, tess, rest, health), `Features/Workout/LiveSetStrokes.swift:78-80`, `Features/Workout/WorkoutParts.swift:283`, `Features/Workout/WorkoutModeView.swift:625`; history `Features/Exercise/ExerciseViews.swift:153-167` (`SetStrokes`, vermilion, cobalt, cadmium, sage) | Workout set row; Exercise history | All | One stroke per set; colour only means "next set" | Multicolour strokes, always on | **Quieter**: cream strokes; the fresh stroke can paint in coloured and dry to cream (it already draws in, :87-92) | A |
| C15 | `Features/Plans/WeekPage.swift:194-206` (green 16% target band, routine-colour fill stroke); `Features/Settings/ClaudeSection.swift:333-339` (spend stroke cobalt / amber) | Plans weekly sets per muscle; Settings Claude spend | All | Range and progress | Coloured bars | **Quieter**: ink band and ink fill; amber only when over (Settings `warm`) | A (Plans), B (Settings) |
| C16 | Live Activity washes: `Widgets/RestLiveActivity.swift:165-185` (`Washes`), colours `Shared/LookTable.swift:54-70` (rest: Workout.tess 35%, context 45%; go: rest 75%, signal 60%) | Lock Screen rest Live Activity | Day or night look (`LookTable.swift:14-23`, all five) | Resting vs Go | Coloured washes behind the face | **Motion**: neutral at rest; the go washes can arrive at Go time | A |

Theme tokens behind all of this (Builder A owns looks):
- `DesignSystem/Looks.swift:63-109`: per-look `live`, `tess`, `now`, `health`, `training`, `context`, `sky` and the
  `workout` set. Porcelain, Obsidian, Plein, Lacquer and Celadon all define every one of them, so a change at a call
  site above fixes all five looks at once.
- `DesignSystem/Theme.swift:376-378` (`halo`): pigment glows on dark looks (Obsidian, Lacquer) and in the workout.
  Every glow in C9, C10, C12 and C13 is brighter there.
- `DesignSystem/Paint.swift:24-49` (`PleinGround` washes): Plein's coloured washes are always on as the page field, and
  inside the workout on Plein (`DesignSystem/ThemeLayers.swift:79-80`). It is the look's ground, not a marker. Probably
  keep, but note it.
- `Features/Plans/PlanDigest.swift:7-31` and `Features/Plans/PlansView.swift:99-108` (`RoutinePaint`): Push vermilion,
  Pull violet, Legs cadmium, Upper sage. This is the source of the routine colours in A8, A9 and C15. If routine colour
  goes, this mapping is only needed for motion. Owner A.

---

## D. Already arrives through motion (keep; good models for the rest)

- `Features/Groceries/GroceriesView.swift:172-180`: struck items' dabs fly into the basket, then vanish.
- `Features/Groceries/GroceriesView.swift:300-322` (`ShopTitle`): "Groceries" fills vermilion under a hold.
- `Features/Groceries/GroceriesView.swift:360-378`: "Add" label and hairline turn green only while typing.
- `Features/Notes/NotesView.swift:141-149`: cobalt underline draws across on focus.
- `App/RootView.swift:41` (`Features/Tess/PaintFlood.swift`): colour flood when Tess opens.
- `Features/Recipes/PasteRecipe.swift:51-56`: cadmium brush band passes down as the paste is read.
- `DesignSystem/TextEffects.swift:104-106`: hero completion stroke in vermilion as a task completes.
- Sheen glints: `DesignSystem/Theme.swift:366-373`, used at `DesignSystem/Machined.swift:198`,
  `Features/Exercise/ExercisePaint.swift:180`, `Features/Workout/ExerciseStrip.swift:48`,
  `Features/Workout/LiveSetStrokes.swift:11`. Gold through letters on Porcelain and Celadon, light on the rest.
- `Features/Command/BottomChrome.swift:617` and `DesignSystem/InkActions.swift:100-101`: cobalt wash only while pressed.
- `Features/Workout/WorkoutFinishView.swift:106-115`: the set strokes gather at the finish.
- `Features/Workout/WorkoutParts.swift:209-211`: "effort" turns amber only while the slider is out.

---

## E. Dead or unused colour code (delete)

- `DesignSystem/ThinkingIndicator.swift` (whole view, including `.dots` at :54-62): never instantiated.
- `DesignSystem/Theme.swift:337-339` (`daySpectrum`): never used.
- `DesignSystem/Theme.swift:346-356` (`ClassRole`, `classColor`): never used (Core's `colorRole` is not read for colour).
- `DesignSystem/ThemeLayers.swift:99-135` (`actionBloom`): never applied.
- `Features/Tess/TessMotifs.swift:48-70` (`RoundRobin`, vermilion lit bar): only in `SoulGallery` (a debug gallery).

---

## Quick wins, in order

1. A1 / A2: soul idle uses the resting look (one row in `SoulParameters.swift:124-127`). Removes the most visible dots on every screen.
2. A3, A4, A6, A12, A15, A16, A17: delete the `PaintDab` line; nothing else changes.
3. C3 / C4: context colour to `inkSecondary` (a find-and-replace across about 33 lines).
4. A7, A8, A9: DayDabs and plan dabs to ink. One rule, three files.
5. C5 / C6: rails in ink at rest.

## Against Design's addendum (`../design/no-dots.md`, 6ef3e16)

Design's table covers every dot in section A except these:
- **A1 soul at idle.** The addendum keeps the soul as it is, but idle runs at saturation 1.45 with three coloured dabs, the loudest always-on colour on Home. One-line fix: idle reuses `.resting` (0.35). Needs Design's yes, since the soul is "not touched".
- **A10 month legend** (`MonthPage.swift:158-170`). Not named; month cells are kept, so the legend's swatches either rest at the rest tint too or become words.
- **A14 RPE stops.** Listed both as "rest quiet" (rule 2) and as "not touched"; the chosen stop's amber glow needs one answer.
- **A19 `ThinkingIndicator.dots`.** Not on screen anywhere; delete it with section E rather than leave a dot style in the kit.

Not in the addendum at all:
- **Section B, all 13 badges and tinted status words** (workout amber subline and rest numerals, vermilion label words, `InkLabelWordStyle` at 85% at rest, routine editor vermilion, Notes newest time, Object page pink class line, Review pink section label, Recipe green and amber lines, the rest Live Activity tick and Go glow).
- **Section C always-on colour:** vermilion page rails, PaintKey stroke at 82% at rest, ProcessSeam glow, the workout set-stroke colour cycle, the Live Activity and Dynamic Island washes (always the Obsidian set), and the hex colours that ignore the look (`HomeSpatialView.swift:7-13`, `NowPage.swift:519`). Cobalt voice and violet context lines are kept by the addendum on purpose.

Two wording clashes in the habit thread row (for Design and Product):
- "A gap is a miss" contradicts `habits.md`: a habit is a weekly target, so a day with no tick is never a miss. `fixtures/review-m3.md` draws the gap and calls it nothing.
- The check-in line "Read, four days running." is a streak count; Review and habits rule out streaks. Suggest "Read, 4 of 5 this week."
